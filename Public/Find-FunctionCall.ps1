function Find-FunctionCall
{
    [CmdletBinding()]
    param
    (
        [Parameter(ParameterSetName = 'Ast', Mandatory, ValueFromPipeline)]
        [Management.Automation.Language.Ast]$FunctionAst,

        [Parameter(ParameterSetName = 'Name', Mandatory, ValueFromPipeline)]
        [string]$Name,

        [Parameter(ParameterSetName = 'Token', Mandatory, ValueFromPipeline)]
        [Management.Automation.Language.Token]$Token,

        [Parameter()]
        [psmoduleinfo]$Module
    )

    begin
    {
        if (-not $_BuiltInCommands)
        {
            $_BuiltInCommands = [Collections.Generic.HashSet[string]]::new()
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'Name')
        {
            $Resolver = {Get-Command $args[0] -CommandType Function -ErrorAction Stop}
            $Command = if ($Module)
            {
                & $Module $Resolver $Name
            }
            else
            {
                & $Resolver $Name
            }

            Write-Verbose "Resolved command '$Name' from '$($Command.Source)'"
            $Def = "function $Name {$($Command.Definition)}"
            # $ScriptblockAst = [Management.Automation.Language.Parser]::ParseInput($Def, [ref]$Tokens, [ref]$null)
            # $FunctionAst = $ScriptblockAst.EndBlock.Statements[0]
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Ast')
        {
            $Def = $FunctionAst.Extent.Text
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Token')
        {
            $Tokens = @($Token)
        }

        if ($PSCmdlet.ParameterSetName -ne 'Token')
        {
            $Tokens = @()
            [void][Management.Automation.Language.Parser]::ParseInput($Def, [ref]$Tokens, [ref]$null)
        }

        $CommandTokens = $Tokens | Where-Object {$_.TokenFlags -band 'CommandName'}

        $CalledCommandNames = $CommandTokens.Text | Sort-Object -Unique | Where-Object {$_ -notin $_BuiltInCommands}

        $Resolver = {$args | Get-Command}

        $CalledCommands = if ($Module)
        {
            & $Module $Resolver $CalledCommandNames
        }
        else
        {
            & $Resolver $CalledCommandNames
        }

        $Splat = [hashtable]$PSBoundParameters
        $Splat.Remove('FunctionAst')
        $Splat.Remove('Name')

        $CalledCommands
    }
}
