class CallInfo
{
    <#
        .SYNOPSIS
        A pseudo-child of System.Management.Automation.CommandInfo that's also a tree node.

        We can't inherit because all the constructors of CommandInfo are marked internal.
    #>

    # Hot path - we'll implement directly
    [string]$Name
    [string]$Source
    [psmoduleinfo]$Module

    # This class is a tree node
    [CallInfo]$CalledBy
    [System.Collections.Generic.IList[CallInfo]]$Calls
    [int]$Depth

    # Inner object; we'll delegate calls to this
    hidden [Management.Automation.CommandInfo]$Command


    #region Constructors
    CallInfo([string]$Name)
    {
        $this.Name = $Name
        $this.Initialise()
    }

    CallInfo([Management.Automation.CommandInfo]$Command)
    {
        $this.Command = $Command
        $this.Name = $Command.Name
        $this.Source = $Command.Source
        $this.Module = $Command.Module
        $this.Initialise()
    }

    hidden [void] Initialise()
    {
        $this.Calls = [Collections.Generic.List[CallInfo]]::new()

        $InheritedProperties = (
            'CmdletBinding',
            'CommandType',
            'DefaultParameterSet',
            'Definition',
            'Description',
            'HelpFile',
            # 'Module',
            'ModuleName',
            # 'Name',
            'Noun',
            'Options',
            'OutputType',
            'Parameters',
            'ParameterSets',
            'RemotingCapability',
            'ScriptBlock',
            # 'Source',
            'Verb',
            'Version',
            'Visibility',
            'HelpUri'
        )

        $InheritedProperties | ForEach-Object {
            Add-Member ScriptProperty -InputObject $this -Name $_ -Value ([scriptblock]::Create("`$this.Command.$_"))
        }
    }
    #endregion Constructors

    #region Overrides
    [string] ToString()
    {
        return $this.Name
    }

    [Management.Automation.ParameterMetadata] ResolveParameter([string]$name)
    {
        if (-not $this.Command)
        {
            throw [InvalidOperationException]::new("Cannot resolve parameter '$Name' for unresolved comand '$($this.Name)'.")
        }
        return $this.Command.ResolveParameter($name)
    }
    #endregion Overrides
}
