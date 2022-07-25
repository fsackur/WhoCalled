function Find-FunctionCall
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

        .PARAMETER Function
        Provide a function object as input. This will be the output of Get-Command.

        .PARAMETER Depth
        Maximum level of nesting to analyse. If this depth is exceeded, a warning will be emitted.

        .PARAMETER ResolveAlias
        Specifies to resolve aliases to the aliased command.

        .PARAMETER All
        Specifies to return all commands. By default, built-in modules are excluded.

        .INPUTS

        [System.Management.Automation.FunctionInfo]

        .OUTPUTS

        [CallInfo]

        This command outputs an object similar to System.Management.Automation.FunctionInfo. Note
        that this is not a child class of FunctionInfo.

        .EXAMPLE
        Find-FunctionCall Install-Module

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
        Find-FunctionCall Import-Plugz -Depth 2 -ResolveAlias -All

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
    [CmdletBinding(DefaultParameterSetName = 'FromFunction', PositionalBinding = $false)]
    param
    (
        [Parameter(ParameterSetName = 'ByName', Mandatory, ValueFromPipeline, Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'FromFunction', Mandatory, ValueFromPipeline, Position = 0)]
        [Management.Automation.FunctionInfo]$Function,

        [int]$Depth = 4,

        [switch]$ResolveAlias,

        [switch]$All,

        [Parameter(DontShow, ParameterSetName = 'Recursing', Mandatory, ValueFromPipeline)]
        [CallInfo]$CallingFunction,

        [Parameter(DontShow, ParameterSetName = 'Recursing')]
        [int]$_CallDepth = 0,

        [Parameter(DontShow, ParameterSetName = 'Recursing')]
        [Collections.Generic.ISet[Management.Automation.FunctionInfo]]$_SeenFunctions = [Collections.Generic.HashSet[Management.Automation.FunctionInfo]]::new()
    )

    process
    {
        if ($_CallDepth -ge $Depth)
        {
            Write-Warning "Resulting output is truncated as call tree has exceeded the set depth of $Depth."
            return
        }


        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            $Function = Get-Command $Name -CommandType Function -ErrorAction Stop
        }

        if ($PSCmdlet.ParameterSetName -eq 'Recursing')
        {
            $Function = $CallingFunction.Command
        }
        else
        {
            $CallingFunction = [CallInfo]$Function
        }

        # Returns false if already in set
        if (-not $_SeenFunctions.Add($Function))
        {
            return
        }

        if (-not $_CallDepth)
        {
            $CallingFunction
        }


        #region Parse
        $Def = "function $($Function.Name) {$($Function.Definition)}"
        $Tokens = @()
        [void][Management.Automation.Language.Parser]::ParseInput($Def, [ref]$Tokens, [ref]$null)


        $CommandTokens = $Tokens | Where-Object {$_.TokenFlags -band 'CommandName'}
        $CalledCommandNames = $CommandTokens.Text | Sort-Object -Unique
        if (-not $CalledCommandNames)
        {
            return
        }
        #endregion Parse

        #region Resolve commands
        $Resolver = {
            param ([string[]]$CommandNames, [string]$ModuleName, [switch]$ResolveAlias)

            foreach ($CommandName in $CommandNames)
            {
                try
                {
                    $ResolvedCommand = Get-Command $CommandName -ErrorAction Stop

                    if ($ResolveAlias -and $ResolvedCommand.CommandType -eq 'Alias')
                    {
                        [CallInfo]$ResolvedCommand.ResolvedCommand
                    }
                    else
                    {
                        [CallInfo]$ResolvedCommand
                    }
                }
                catch [Management.Automation.CommandNotFoundException]
                {
                    [CallInfo]$CommandName

                    $_.ErrorDetails = "Command resolution failed for command '$CommandName'$(if ($ModuleName) {" in module '$ModuleName'"})."
                    Write-Error -ErrorRecord $_
                }
                catch
                {
                    Write-Error -ErrorRecord $_
                }
            }
        }

        [CallInfo[]]$CalledCommands = if ($Function.Module)
        {
            $Function.Module.Invoke($Resolver, @($CalledCommandNames, $Function.Module.Name, $ResolveAlias))
        }
        else
        {
            & $Resolver $CalledCommandNames '' $ResolveAlias
        }


        if (-not $All)
        {
            $CalledCommands = $CalledCommands | Where-Object Source -notmatch '^Microsoft.PowerShell'
        }

        if (-not $CalledCommands)
        {
            return
        }
        #endregion Resolve commands

        #region Recurse
        $RecurseParams = [hashtable]$PSBoundParameters
        $RecurseParams.Remove('Name')
        $RecurseParams.Remove('Function')
        $RecurseParams.Remove('CallingFunction')
        $RecurseParams.Depth = $Depth
        $RecurseParams._CallDepth = ++$_CallDepth
        $RecurseParams._SeenFunctions = $_SeenFunctions

        $CalledCommands | ForEach-Object {
            $_.Depth = $_CallDepth
            $_.CalledBy = $CallingFunction
            $CallingFunction.Calls.Add($_)

            [CallInfo[]]$CallsOfCalls = $_ |
                Where-Object CommandType -eq 'Function' |
                Find-FunctionCall @RecurseParams |
                Where-Object Name

            $_ | Write-Output
            $CallsOfCalls | Write-Output
        }
        #endregion Recurse
    }
}
