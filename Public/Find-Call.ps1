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

    [OutputType([CallInfo[]])]
    [CmdletBinding(DefaultParameterSetName = 'FromCommand', PositionalBinding = $false)]
    param
    (
        [Parameter(ParameterSetName = 'ByName', Mandatory, ValueFromPipeline, Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'FromCommand', Mandatory, ValueFromPipeline, Position = 0)]
        [Management.Automation.CommandInfo]$Command,

        [int]$Depth = 4,

        [switch]$ResolveAlias,

        [switch]$All,

        [Parameter(DontShow, ParameterSetName = 'Recursing', Mandatory, ValueFromPipeline)]
        [CallInfo]$Caller,

        [Parameter(DontShow, ParameterSetName = 'Recursing')]
        [int]$_CallDepth = 0
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
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            $Command = Get-Command $Name -ErrorAction Stop
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Recursing')
        {
            $Command = $Caller.Command
        }

        if ($PSCmdlet.ParameterSetName -ne 'Recursing')
        {
            $Caller = [CallInfo]$Command
        }

        if (-not ($Command -as [Management.Automation.FunctionInfo]))
        {
            $Message = if ($Command) {"Not a function, cannot parse for calls: $_"} else {"Command not found: $_"}
            Write-Verbose $Message
            Write-Debug $Message
            return
        }


        if ($_CallDepth -ge $Depth)
        {
            Write-Warning "Resulting output is truncated as call tree has exceeded the set depth of $Depth`: $_"
            return
        }

        if ($_CallDepth -eq 0)
        {
            $Caller
        }

        $_CallDepth++
        $RecurseParams = @{}
        'Depth', 'ResolveAlias', 'All', '_CallDepth' | Get-Variable | ForEach-Object {$RecurseParams.Add($_.Name, $_.Value)}


        [CallInfo[]]$Calls = @()

        $Found = $Script:CACHE[$Caller.Id]
        if ($Found)
        {
            Write-Debug "$Caller`: cache hit"

            if ($Found.HasNoCalls)
            {
                $Caller.HasNoCalls = $true
                return
            }
            # The call may have bottomed out on depth when it was first cached.
            # Absence of calls doesn't mean the command doesn't call anything.
            $Calls = $Found.Calls | Where-Object {$_ -ne $Caller}   # Don't include recursive calls
            $Caller.Calls.Clear()
        }
        else
        {
            Write-Debug "$Caller`: caching"
            $Script:CACHE[$Caller.Id] = $Caller

            $CallNames = $Command |
                Where-Object {$_} |
                Find-CallNameFromDefinition

            $Calls = $CallNames |
                Resolve-Command -Module $Command.Module -ResolveAlias:$ResolveAlias |
                Write-Output |
                Where-Object {$_ -ne $Caller} |     # Don't include recursive calls
                Where-Object {$All -or $_.Source -notmatch '^Microsoft.PowerShell'}
        }

        if (-not $Calls)
        {
            $Caller.HasNoCalls = $true
            return
        }


        $Calls | ForEach-Object {
            $_.Depth = $_CallDepth
            if ($Caller -notin $_.CalledBy) {$_.CalledBy.Add($Caller)}
            $Caller.Calls.Add($_)

            $_
            $_ | Find-Call @RecurseParams
        }
    }
}
