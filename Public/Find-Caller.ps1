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

        # Maximum level of nesting to analyse. If this depth is exceeded, a warning will be emitted.
        [ValidateRange(0, 100)]
        [int]$Depth = 4
    )

    begin
    {
        $Modules = $Module | ForEach-Object {
            $_Module = Get-Module $_ -ErrorAction Ignore
            if ($_Module) {$_Module} else {Import-Module $_ -PassThru}
        }

        $Commands = $Modules | ForEach-Object {
            $_.Invoke({Get-Command -Module $args[0]}, $_)
        }

        $Commands | Find-Call -NoOutput -Depth $Depth -WarningAction Ignore
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            $Source, $_Name = $Name -split '\\', 2
            if ($_Name) {$Name = $_Name} else {$Source = ''}

            $Message = "Command '$Name' was not found."
            $QualifyTip = "Try qualifying the command name, e.g. 'PowerShellGet\Find-Module'."
            try
            {
                $_Command = Get-Command $Name -Module $Source -ErrorAction Stop

                # Get-Command does not error on wildcards
                if (-not $_Command)
                {
                    Write-Error -Exception ([Management.Automation.CommandNotFoundException]::new($Message)) -ErrorAction Stop
                }
            }
            catch [Management.Automation.CommandNotFoundException]
            {
                $_Command = $Commands | Where-Object {
                    $_.Name -eq $Name -and
                    (-not $Source -or $_.Source -eq $Source)
                }

                if (-not $_Command)
                {
                    $SourceModules = if ($Source)
                    {
                        Get-Module $Source -ListAvailable -ErrorAction Stop | Import-Module -PassThru -ErrorAction Stop
                    }
                    else
                    {
                        $Modules
                    }

                    $_Command = $SourceModules |
                        ForEach-Object {$Name | Resolve-Command -Module $_ -ResolveAlias -ErrorAction Ignore} |
                        Write-Output |
                        Select-Object -ExpandProperty Command |
                        Where-Object {(-not $Source) -or $_.Source -eq $Source}
                }
            }

            if ($_Command.Count -ne 1)
            {
                if ($_Command) {$Message = "Multiple commands found with name '$Name'."}
                if (-not $Source) {$Message = $Message, $QualifyTip -join ' '}
                Write-Error -Exception ([Management.Automation.CommandNotFoundException]::new($Message)) -ErrorAction Stop
            }

            $Command = $_Command
        }

        $Call = [CallInfo]$Command
        $Found = $Script:CACHE[$Call.Id]
        if (-not $Found)
        {
            Write-Error "Could not find '$Call'." -ErrorAction Stop
        }
        $Found.AsList(0, 'CalledBy') | Where-Object Depth -le $Depth
    }
}
