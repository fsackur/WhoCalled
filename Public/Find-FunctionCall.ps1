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

        $_CallDepth++


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

        if (-not $CalledFunctions)
        {
            return
        }


        $CalledFunctions | ForEach-Object {
            $_.Depth = $_CallDepth
            $_.CalledBy = $CallingFunction

            # Recurse
            [FunctionCallInfo[]]$CallsOfCalls = $_ |
                Find-FunctionCall -Depth $Depth -_CallDepth $_CallDepth -_SeenFunctions $_SeenFunctions

            $_ | Write-Output

            if ($CallsOfCalls)
            {
                $_.Calls.AddRange($CallsOfCalls)

                $CallsOfCalls | Write-Output
            }
        }
    }
}
