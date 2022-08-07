enum CallDirection
{
    Calls = 0
    CalledBy = 1
}

class CallInfo
{
    <#
        .SYNOPSIS
        A pseudo-child of System.Management.Automation.CommandInfo that's also a node in a graph of
        calls.

        We can't inherit because all the constructors of CommandInfo are marked internal.
    #>

    # Hot path - we'll implement directly
    [string]$Name
    [string]$Source
    [psmoduleinfo]$Module

    # This class is a tree node
    [Collections.Generic.ISet[CallInfo]]$CalledBy
    [Collections.Generic.IList[CallInfo]]$Calls
    hidden [int]$Depth
    hidden [bool]$HasNoCalls    # to distinguish from 'not checked yet'

    # Inner object; we'll delegate calls to this
    hidden [Management.Automation.CommandInfo]$Command

    hidden [string]$Id

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

        $this.CalledBy = [Collections.Generic.HashSet[CallInfo]]::new()
        $this.Calls = [Collections.Generic.List[CallInfo]]::new()
        $this.HasNoCalls = $false

        $this.Id = switch ($this.CommandType)
        {
            $null
            {
                '<not found>'
            }

            'Function'
            {
                $Qualifier = if ($this.Module)
                {
                    # https://github.com/PowerShell/PowerShell/blob/8cc39848bcd4fb98517adc79cdbe60234b375c59/src/System.Management.Automation/engine/Modules/PSModuleInfo.cs#L1596-L1599
                    $this.Module.Name, $this.Module.Guid, $this.Module.Version -join ':' -replace '::'
                }
                else
                {
                    $this.Command.Scriptblock.GetHashCode()
                }
                $Qualifier, $this.Name -join '\'
            }

            'Cmdlet'
            {
                $Qualifier = $this.Command.ImplementingType.FullName
                $Qualifier, $this.Name -join '\'
            }

            'Alias'
            {
                'Alias', $this.Name -join ':\'
            }

            'Application'
            {
                $this.Command.Path
            }

            default
            {
                throw [NotImplementedException]::new("No implementation for '$_'.")
            }
        }
    }
    #endregion Constructors


    hidden [System.Collections.Generic.IList[CallInfo]] AsList([int]$Depth, [CallDirection]$Direction)
    {
        [CallDirection]$OtherDirection = [int](-not $Direction)

        $Cloned = if ($this.Command) {[CallInfo]$this.Command} else {[CallInfo]$this.Name}
        $Cloned.HasNoCalls = $this.HasNoCalls
        $Cloned.Depth = $Depth

        $List = [System.Collections.Generic.List[CallInfo]]::new()
        $List.Add($Cloned)
        $Depth++
        foreach ($Call in $this.$Direction)
        {
            $RecursedList = $Call.AsList($Depth, $Direction)

            [void]$Cloned.$Direction.Add($Call)
            [void]$RecursedList[0].$OtherDirection.Add($Cloned)

            $List.AddRange($RecursedList)
        }
        return $List
    }


    #region Overrides
    [string] ToString()
    {
        return $this.Name
    }

    [bool] Equals([object]$obj)
    {
        return $obj -is [CallInfo] -and $obj.Id -eq $this.Id
    }

    [int] GetHashCode()
    {
        return $this.Id.GetHashCode()
    }

    [Management.Automation.ParameterMetadata] ResolveParameter([string]$name)
    {
        if ($null -eq $this.Command)
        {
            throw [InvalidOperationException]::new("Cannot resolve parameter '$Name' for unresolved comand '$($this.Name)'.")
        }
        return $this.Command.ResolveParameter($name)
    }
    #endregion Overrides
}
