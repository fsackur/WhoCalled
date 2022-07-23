class FunctionCallInfo
{
    <#
        .SYNOPSIS
        A pseudo-child of System.Management.Automation.FunctionInfo that's also a tree node.

        We can't inherit because all the constructors of FunctionInfo are marked internal.
    #>

    # Hot path - we'll implement directly
    [string]$Name
    [string]$Source
    [psmoduleinfo]$Module

    # This class is a tree node
    [FunctionCallInfo]$CalledBy
    [System.Collections.Generic.IList[FunctionCallInfo]]$Calls
    [int]$Depth

    # Inner object; we'll delegate calls to this
    hidden [Management.Automation.FunctionInfo]$Function
    hidden static [string[]]$_InheritedProperties = (
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


    FunctionCallInfo ([Management.Automation.FunctionInfo]$Function)
    {
        $this.Function = $Function
        $this.Name = $Function.Name
        $this.Source = $Function.Source
        $this.Module = $Function.Module
        $this.Calls = [Collections.Generic.List[FunctionCallInfo]]::new()

        [FunctionCallInfo]::_InheritedProperties | ForEach-Object {
            Add-Member ScriptProperty -InputObject $this -Name $_ -Value (
                [scriptblock]::Create("`$this.Function.`$_")
            ) -SecondValue (
                [scriptblock]::Create("`$this.Function.`$_ = `$args[0]")
            )
        }
    }

    [bool] Equals([object]$obj)
    {
        return $this.Function.Equals($obj)
    }

    [Management.Automation.ParameterMetadata] ResolveParameter([string]$name)
    {
        return $this.Function.ResolveParameter($name)
    }

    [string] ToString()
    {
        return $_.Function.ToString()
    }
}
