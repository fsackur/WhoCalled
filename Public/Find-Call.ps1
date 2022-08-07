function Find-Call
{
    <#
        .SYNOPSIS
        For a given function, find what functions it calls.

        .DESCRIPTION
        For the purposes of working out dependencies, it may be good to know what a function depends
        on at the function scale.

        This command takes a function and builds a tree of functions called by that function.

        .PARAMETER Name
        Provide the name of a function to analyse.

        .PARAMETER Command
        Provide a command object as input. This will be the output of Get-Command.

        .PARAMETER Depth
        Maximum level of nesting to analyse. If this depth is exceeded, a warning will be emitted.

        .PARAMETER ResolveAlias
        Specifies to resolve aliases to the aliased command.

        .PARAMETER All
        Specifies to return all commands. By default, built-in modules are excluded.

        .INPUTS

        [System.Management.Automation.CommandInfo]

        .OUTPUTS

        [CallInfo]

        This command outputs an object similar to System.Management.Automation.CommandInfo. Note
        that this is not a child class of CommandInfo.

        .EXAMPLE
        Find-Call Install-Module

        CommandType Name                                          Version Source
        ----------- ----                                          ------- ------
        Function    Install-Module                                2.2.5   PowerShellGet
        Function      Get-ProviderName                            2.2.5   PowerShellGet
        Function      Get-PSRepository                            2.2.5   PowerShellGet
        Function        New-ModuleSourceFromPackageSource         2.2.5   PowerShellGet
        Cmdlet          Get-PackageSource                         1.4.7   PackageManagement
        Function      Install-NuGetClientBinaries                 2.2.5   PowerShellGet
        Function        Get-ParametersHashtable                   2.2.5   PowerShellGet
        Cmdlet          Get-PackageProvider                       1.4.7   PackageManagement
        Cmdlet          Import-PackageProvider                    1.4.7   PackageManagement
        Cmdlet          Install-PackageProvider                   1.4.7   PackageManagement
        Function        Test-RunningAsElevated                    2.2.5   PowerShellGet
        Function        ThrowError                                2.2.5   PowerShellGet
        Function      New-PSGetItemInfo                           2.2.5   PowerShellGet
        Function        Get-EntityName                            2.2.5   PowerShellGet
        Function        Get-First                                 2.2.5   PowerShellGet
        Function        Get-SourceLocation                        2.2.5   PowerShellGet

        For the 'Install-Module' command from the PowerShellGet module, determine the call tree.

        .EXAMPLE
        Find-Call Import-Plugz -Depth 2 -ResolveAlias -All

        WARNING: Resulting output is truncated as call tree has exceeded the set depth of 2.
        CommandType Name                     Version   Source
        ----------- ----                     -------   ------
        Function    Import-Plugz             0.2.0     Plugz
        Cmdlet        Export-ModuleMember    7.2.5.500 Microsoft.PowerShell.Core
        Function      Get-PlugzConfig        0.2.0     Plugz
        Cmdlet          Add-Member           7.0.0.0   Microsoft.PowerShell.Utility
        Function        Import-Configuration 1.5.1     Configuration
        Cmdlet        Join-Path              7.0.0.0   Microsoft.PowerShell.Management
        Cmdlet        New-Module             7.2.5.500 Microsoft.PowerShell.Core
        Cmdlet        Select-Object          7.0.0.0   Microsoft.PowerShell.Utility
        Cmdlet        Set-Alias              7.0.0.0   Microsoft.PowerShell.Utility
        Cmdlet        Set-Item               7.0.0.0   Microsoft.PowerShell.Management
        Cmdlet        Set-Variable           7.0.0.0   Microsoft.PowerShell.Utility
        Function      Test-CalledFromProfile 0.2.0     Plugz
        Cmdlet          Get-PSCallStack      7.0.0.0   Microsoft.PowerShell.Utility
        Cmdlet          Select-Object        7.0.0.0   Microsoft.PowerShell.Utility
        Cmdlet          Where-Object         7.2.5.500 Microsoft.PowerShell.Core
        Cmdlet        Test-Path              7.0.0.0   Microsoft.PowerShell.Management
        Cmdlet        Where-Object           7.2.5.500 Microsoft.PowerShell.Core
        Cmdlet        Write-Error            7.0.0.0   Microsoft.PowerShell.Utility
        Cmdlet        Write-Verbose          7.0.0.0   Microsoft.PowerShell.Utility

        Find calls made by the 'Import-Plugz' command. Depth is limited to 2. Built-in commands are
        included. Aliases are resolved to the resolved commands.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', 'All', Justification = "It's used in a scriptblock")]

    [OutputType([CallInfo[]])]
    [CmdletBinding(DefaultParameterSetName = 'FromCommand', PositionalBinding = $false)]
    param
    (
        [Parameter(ParameterSetName = 'ByName', Mandatory, ValueFromPipeline, Position = 0)]
        [SupportsWildcards()]
        [string]$Name,

        [Parameter(ParameterSetName = 'FromCommand', Mandatory, ValueFromPipeline, Position = 0)]
        [Management.Automation.CommandInfo]$Command,

        [int]$Depth = 4,

        [switch]$ResolveAlias,

        [switch]$All,

        [Parameter(DontShow, ParameterSetName = 'Recursing', Mandatory, ValueFromPipeline)]
        [CallInfo]$Caller,

        [Parameter(DontShow, ParameterSetName = 'Recursing')]
        [int]$_CallDepth = 0,

        [Parameter(DontShow, ParameterSetName = 'Recursing')]
        [Collections.Generic.ISet[string]]$_StackSeen = [Collections.Generic.HashSet[string]]::new()
    )

    begin
    {
        if (-not $Script:CACHE)
        {
            $Script:CACHE = [Collections.Generic.Dictionary[string, CallInfo]]::new()
        }
    }

    process
    {
        #region Unify parameter sets
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            $Params = [hashtable]$PSBoundParameters
            $Params.Remove('Name')
            return Get-Command $Name -ErrorAction Stop | Find-Call @Params
        }

        if ($PSCmdlet.ParameterSetName -eq 'Recursing')
        {
            $Command = $Caller.Command
        }
        else
        {
            $Caller = [CallInfo]$Command
        }
        #endregion Unify parameter sets

        #region Early exit conditions
        $_StackSeen = [Collections.Generic.HashSet[string]]::new($_StackSeen)
        if (-not $_StackSeen.Add($Caller.Id))
        {
            Write-Debug "Already seen: $Caller"
            return
        }

        if ($_CallDepth -ge $Depth)
        {
            Write-Warning "Resulting output is truncated as call tree has exceeded the set depth of $Depth`: $Caller"
            return
        }

        if (-not ($Command -as [Management.Automation.FunctionInfo]))
        {
            $Message = if ($Command) {"Not a function, cannot parse for calls: $Caller"} else {"Command not found: $Caller"}
            Write-Verbose $Message
            Write-Debug $Message
            return
        }
        #endregion Early exit conditions

        #region Cache hit or parse and cache
        # The call may have bottomed out on depth when it was first cached.
        # A cache hit saves parsing; it doesn't save recursion.
        $Found = $Script:CACHE[$Caller.Id]
        if ($Found)
        {
            Write-Debug "$Caller`: cache hit"
            $Caller.CalledBy | ForEach-Object {[void]$Found.CalledBy.Add($_)}
            $Caller = $Found
        }
        else
        {
            $CallNames = $Command |
                Where-Object Name |
                Find-CallNameFromDefinition

            $CallNames |
                Resolve-Command -Module $Command.Module -ResolveAlias:$ResolveAlias |
                Write-Output |
                Where-Object Id -NE $Caller.Id |     # Don't include recursive calls
                ForEach-Object {
                    [void]$_.CalledBy.Add($Caller)
                    $Caller.Calls.Add($_)
                }

            Write-Debug "$Caller`: caching"
            $Script:CACHE[$Caller.Id] = $Caller
        }
        #endregion Cache hit or parse and cache

        #region Recurse
        $Calls = $Caller.Calls
        if (-not $All)
        {
            $Calls = $Calls | Where-Object Source -notmatch '^Microsoft.PowerShell'
        }

        if ($Calls)
        {
            $RecurseParams = @{
                Depth        = $Depth
                ResolveAlias = $ResolveAlias
                All          = $All
                _CallDepth   = $_CallDepth + 1
                _StackSeen   = $_StackSeen
            }
            $Calls | Find-Call @RecurseParams
        }
        #endregion Recurse

        #region Output
        if ($PSCmdlet.ParameterSetName -ne 'Recursing')
        {
            $Caller.AsList(0, 'Calls') | Where-Object {
                $_.Depth -le $Depth -and
                ($All -or $_.Source -notmatch '^Microsoft.PowerShell')
            }
        }
        #endregion Output
    }
}
