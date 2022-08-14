function Find-CallNameFromDefinition
{
    <#
        .DESCRIPTION
        Parse a function definition to find all commands called from the function.
    #>

    [OutputType([string[]])]
    [CmdletBinding(DefaultParameterSetName = 'FromFunction')]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Management.Automation.FunctionInfo]$Function,

        [Management.Automation.Language.TokenFlags]$TokenFlags = 'CommandName'
    )

    process
    {
        $Tokens = @()
        [void][Management.Automation.Language.Parser]::ParseInput($Function.Definition, [ref]$Tokens, [ref]$null)

        $CommandTokens = $Tokens | Where-Object {$_.TokenFlags -band $TokenFlags}
        $CommandTokens.Text | Sort-Object -Unique
    }
}
