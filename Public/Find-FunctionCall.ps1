function Find-FunctionCall
{
    [CmdletBinding()]
    param
    (
        [Parameter(ParameterSetName = 'Ast', Mandatory, ValueFromPipeline)]
        [Management.Automation.FunctionInfo]$Function,

        [Parameter()]
        [int]$Depth = 4,

        [Parameter(DontShow)]
        [int]$_CallDepth = 0,

        [Parameter(DontShow)]
        [Collections.Generic.HashSet[Management.Automation.FunctionInfo]]$_SeenFunctions = [Collections.Generic.HashSet[Management.Automation.FunctionInfo]]::new()
    )

    process
    {
        # Returns false if already in set
        if (-not $_SeenFunctions.Add($Function))
        {
            return
        }

        $Function

        if ($_CallDepth -ge $Depth)
        {
            Write-Warning "Resulting output is truncated as call tree has exceeded the set depth of $Depth."
            return
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
        $CalledFunctions = $CalledCommands | Where-Object CommandType -eq 'Function'


        $CalledFunctions | Find-FunctionCall -Depth $Depth -_CallDepth ($_CallDepth + 1) -_SeenFunctions $_SeenFunctions
    }
}
