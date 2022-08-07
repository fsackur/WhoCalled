function Find-Caller
{
    <#
        .SYNOPSIS
        For a given function, find functions that call it.

        .DESCRIPTION
        For the purposes of working out dependencies, it may be good to know what depends on a
        function at the function scale.

        This command takes a function and builds a tree of functions that call it.

        .INPUTS

        [string]

        [System.Management.Automation.CommandInfo]

        .OUTPUTS

        [CallInfo]

        This command outputs an object similar to System.Management.Automation.CommandInfo. Note
        that this is not a child class of CommandInfo.

        .EXAMPLE
        Find-Caller Get-ModuleDependencies -Module PowerShellGet

        CommandType Name                        Version Source
        ----------- ----                        ------- ------
        Function    Get-ModuleDependencies      2.2.5   PowerShellGet
        Function      Publish-PSArtifactUtility 2.2.5   PowerShellGet
        Function        Publish-Module          2.2.5   PowerShellGet
        Function        Publish-Script          2.2.5   PowerShellGet

        Find all calls made to the 'Get-ModuleDependencies' command from commands in the
        PowerShellGet module.

        Note that the 'Get-ModuleDependencies' command is not exported; it is a private command in
        the PowerShellGet module. This command will import modules in order to resolve private
        commands.

        .EXAMPLE
        Find-Caller Import-* -Module Plugz, Metadata, Configuration -Depth 2 -IncludeCurrentScope

        CommandType Name                            Version Source
        ----------- ----                            ------- ------
        Function    Import-Configuration            1.5.1   Configuration
        Function      Get-PlugzConfig               0.2.0   Plugz
        Function        Export-PlugzProfile         0.2.0   Plugz
        Function        Import-Plugz                0.2.0   Plugz
        Function    Import-Metadata                 1.5.3   Metadata
        Function      Import-Configuration          1.5.1   Configuration
        Function        Get-PlugzConfig             0.2.0   Plugz
        Function      Import-ParameterConfiguration 1.5.1   Configuration
        Function    Import-Plugz                    0.2.0   Plugz
        Function    Import-ParameterConfiguration   1.5.1   Configuration
        Function    Import-GitModule

        Find calls made to any commands matching 'Import-*' from commands in the Plugz, Metadata, or
        Configuration modules, or from commands in the current scope that are not exported from any
        module. Depth is limited to 2.

        Note that the modules will be imported.
    #>

    param
    (
        # The name of a command to find callers of.
        [Parameter(ParameterSetName = 'ByName', Mandatory, ValueFromPipeline, Position = 0)]
        [string]$Name,

        # The command object to find callers of.
        [Parameter(ParameterSetName = 'FromCommand', Mandatory, ValueFromPipeline, Position = 0)]
        [Management.Automation.CommandInfo]$Command,

        # Modules to search for callers.
        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Module,

        # Include functions from the parent scope.
        # Note that this will not include module functions when this command is called from a module
        # that did not import this command's module.
        [switch]$IncludeCurrentScope,

        # Maximum level of nesting to analyse. If this depth is exceeded, a warning will be emitted.
        [ValidateRange(0, 100)]
        [int]$Depth = 4
    )

    begin
    {
        $ToImport = @()
        [psmoduleinfo[]]$Modules = $Module | ForEach-Object {
            $_Module = Get-Module $_ -ErrorAction Ignore
            if ($_Module) {$_Module} else {$ToImport += $_}
        }

        if ($ToImport)
        {
            $i = 0
            $Activity = "Importing modules"
            Write-Progress -Activity $Activity -PercentComplete 0
            $ToImport | ForEach-Object {
                $Percent = 100 * $i++ / $ToImport.Count
                Write-Progress -Activity $Activity -Status $_ -PercentComplete $Percent
                $Modules += Import-Module $_ -PassThru
            }
            Write-Progress -Activity $Activity -Completed
        }

        $Commands = $Modules | ForEach-Object {
            $_.Invoke({Get-Command -Module $args[0]}, $_)
        }

        if ($IncludeCurrentScope)
        {
            $Commands += Get-Command -CommandType Function | Where-Object Module -eq $null
        }

        $Params = @{
            NoOutput        = $true     # Only populate cache
            ResolveAlias    = $true
            Depth           = $Depth
            WarningAction   = 'SilentlyContinue'
            WarningVariable = 'Warnings'
        }

        $i = 0
        $Activity = "Finding function calls"
        $Commands | ForEach-Object {
            $Percent = 100 * $i++ / $Commands.Count
            Write-Progress -Activity $Activity -Status $_ -PercentComplete $Percent
            Find-Call $_ @Params
        } -End {
            Write-Progress -Activity $Activity -Completed
        }

        if ($Warnings)
        {
            $Warnings | Sort-Object -Unique | Write-Warning
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'FromCommand')
        {
            $Calls = [CallInfo]$Command
        }
        else
        {
            if ($Name -match '(?<Source>.*)\\(?<Name>.*?)')
            {
                $Name = $Matches.Name
                $Source = $Matches.Source
            }
            else {$Source = ''}

            $CallIds = $Script:CACHE.Keys -like "*$Name"
            if ($Source)
            {
                $CallIds = @($CallIds) -like "$Source`:*"
            }
            $Calls = $Script:CACHE[$CallIds]
        }

        if (-not $Calls)
        {
            Write-Error "Could not find command '$_'." -ErrorAction Stop
        }
        $Calls | ForEach-Object {
            $_.AsList(0, 'CalledBy') | Where-Object Depth -le $Depth
        }
    }
}
