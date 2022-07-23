# $Function = gcm Invoke-GitRebase

#     [string] get_Definition()
#     {
#         return 'foo'
#     }

#     [System.Collections.ObjectModel.ReadOnlyCollection[Management.Automation.PSTypeName]] get_OutputType()
#     {
#         return [System.Collections.ObjectModel.ReadOnlyCollection[Management.Automation.PSTypeName]]::new()
#     }
# }
        # $this.CopyFieldsFromOther($Function)
        # '_commandMetadata',
        # '_description',
        # '_helpFile',
        # '_noun',
        # '_options',
        # '_scriptBlock',
        # '_verb' | ForEach-Object {
        #     $Field = [Management.Automation.FunctionInfo].GetField($_, 'Instance, NonPublic')
        #     $Value = $Field.GetValue($Function)
        #     $this.$_ = $Value
        # }



# Add-Type '
# public class FunctionCallInfo : System.Management.Automation.FunctionInfo
# {
#     public FunctionCallInfo (System.Management.Automation.FunctionInfo function)
#     {
#         CopyFieldsFromOther(function);
#     }
# }
# '

class FunctionCallInfo
{
    [string]$Name
    [string]$Source
    [psmoduleinfo]$Module
    [FunctionCallInfo]$CalledBy
    [System.Collections.Generic.IList[FunctionCallInfo]]$Calls

    hidden [Management.Automation.FunctionInfo]$Function
    hidden [int]$Depth

    FunctionCallInfo ([Management.Automation.FunctionInfo]$Function)
    {
        $this.Function = $Function
        $this.Name = $Function.Name
        $this.Source = $Function.Source
        $this.Module = $Function.Module
        $this.Calls = [System.Collections.Generic.List[FunctionCallInfo]]::new()
    }
}

function Find-FunctionCall
{
    [OutputType([FunctionCallInfo[]])]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param
    (
        [Parameter(ParameterSetName = 'Default', Mandatory, ValueFromPipeline)]
        [Management.Automation.FunctionInfo]$Function,

        [Parameter()]
        [int]$Depth = 4,

        [Parameter(DontShow, ParameterSetName = 'Recursing', Mandatory, ValueFromPipeline)]
        [FunctionCallInfo]$CallingFunction,

        [Parameter(DontShow, ParameterSetName = 'Recursing')]
        [int]$_CallDepth = 0,

        [Parameter(DontShow, ParameterSetName = 'Recursing')]
        [Collections.Generic.HashSet[Management.Automation.FunctionInfo]]$_SeenFunctions = [Collections.Generic.HashSet[Management.Automation.FunctionInfo]]::new()
    )

    process
    {
        if ($_CallDepth -ge $Depth)
        {
            Write-Warning "Resulting output is truncated as call tree has exceeded the set depth of $Depth."
            return
        }


        if ($PSCmdlet.ParameterSetName -eq 'Default')
        {
            $CallingFunction = [FunctionCallInfo]$Function
        }
        else
        {
            $Function = $CallingFunction.Function
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


        $Def = "function $($Function.Name) {$($Function.Definition)}"
        $Tokens = @()
        [void][Management.Automation.Language.Parser]::ParseInput($Def, [ref]$Tokens, [ref]$null)


        $CommandTokens = $Tokens | Where-Object {$_.TokenFlags -band 'CommandName'}
        $CalledCommandNames = $CommandTokens.Text | Sort-Object -Unique
        if (-not $CalledCommandNames)
        {
            return
        }


        $CalledCommands = if ($Function.Module)
        {
            & $Function.Module {$args | Get-Command} $CalledCommandNames
        }
        else
        {
            Get-Command $CalledCommandNames
        }
        [FunctionCallInfo[]]$CalledFunctions = $CalledCommands | Where-Object CommandType -eq 'Function'

        $CalledFunctions
        # $Calls = $CalledFunctions | Find-FunctionCall -Depth $Depth -_CallDepth ($_CallDepth + 1) -_SeenFunctions $_SeenFunctions

        # $Calls | ForEach-Object {$_.CalledBy = $CallingFunction}
    }
}
