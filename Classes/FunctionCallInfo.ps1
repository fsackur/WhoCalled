class IFunctionCallInfo
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
    [IFunctionCallInfo]$CalledBy
    [System.Collections.Generic.IList[IFunctionCallInfo]]$Calls
    [int]$Depth

    # Inner object; we'll delegate calls to this
    hidden [Management.Automation.CommandInfo]$Command


    IFunctionCallInfo()
    {
        if (-not (Get-PSCallStack).FunctionName -match '^(Unresolved)?FunctionCallInfo$')
        {
            throw [Management.Automation.MethodException]::new("Cannot instantiate interface 'IFunctionCallInfo'.")
        }

        $this.Calls = [Collections.Generic.List[IFunctionCallInfo]]::new()

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

    [Management.Automation.ParameterMetadata] ResolveParameter([string]$name)
    {
        throw [InvalidOperationException]::new("Cannot resolve parameter for unresolved comand '$Name'.")
    }
}


class FunctionCallInfo : IFunctionCallInfo
{
    FunctionCallInfo([Management.Automation.CommandInfo]$Command) : base()
    {
        $this.Command = $Command
        $this.Name = $Command.Name
        $this.Source = $Command.Source
        $this.Module = $Command.Module
    }

    [int] GetHashCode()
    {
        return $this.Command.GetHashCode()
    }

    [bool] Equals([object]$obj)
    {
        return $this.Command.Equals($obj.Command)
    }

    [Management.Automation.ParameterMetadata] ResolveParameter([string]$name)
    {
        return $this.Command.ResolveParameter($name)
    }

    [string] ToString()
    {
        return $_.Command.ToString()
    }
}


class UnresolvedFunctionCallInfo : IFunctionCallInfo
{
    UnresolvedFunctionCallInfo([string]$Name) : base()
    {
        $this.Name = $Name
    }
}
