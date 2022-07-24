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
        [string[]]$Module
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

        $null = $Commands | Find-Call -Depth 10 -WarningAction Ignore
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            $Command = Get-Command $Name -ErrorAction Stop
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
