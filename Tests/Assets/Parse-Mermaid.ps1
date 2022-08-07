function Parse-Mermaid
{
    <#
        .SYNOPSIS
        Self-testing-documentation parser.

        .DESCRIPTION
        Parse markdown containing mermaid function call diagrams and example usage code blocks;
        generate PS module files that declare functions and test cases for use in unit tests.

        .NOTES
        Each test case generates a module and defines one or more sub-test-cases.

        The test case must start with an h2 heading (i.e. `## <title>'). The title is the name of
        the generated module.

        The test cases are defined by fenced code blocks. The first block must be a mermaid graph.
        Following blocks must start with one or more PS invocations, which begin with `>`, followed
        by any number of empty lines, then the expected output.

        NB: the expected output will be processed again, to handle difference in output rendering on
        different systems.

        Trailing whitespace is not allowed.
    #>

    [OutputType([IO.FileInfo])]
    [CmdletBinding()]
    param
    (
        [string]$Path = 'mermaid.md',

        [string]$OutPath
    )

    if (-not [IO.Path]::IsPathRooted($Path))
    {
        $Path = $PSCommandPath |
            Split-Path |
            Join-Path -ChildPath $Path |
            Resolve-Path -ErrorAction Stop
    }

    if (-not [IO.Path]::IsPathRooted($OutPath))
    {
        $OutPath = $PSCommandPath |
            Split-Path |
            Join-Path -ChildPath $OutPath
        $null = New-Item $OutPath -ItemType Directory -Force -ErrorAction Stop
    }



    $Content = Get-Content $Path -Raw
    $Chunks  = $Content -split '(?<=\n)## ' | Select-Object -Skip 1

    # Match mermaid code block, dropping the `graph TD` directive, or any other code block with
    # optional PS or plaintext languge directive
    $Pattern = '(?<=```(mermaid\r?\ngraph (TD|LR);?|powershell|pwsh|plaintext|)\r?\n).*?(?=\r?\n```)'
    $Regex   = [regex]::new($Pattern, 'Singleline')
    foreach ($Chunk in $Chunks)
    {
        $Title, $Chunk = $Chunk -split '\n', 2 | ForEach-Object Trim

        $MermaidChunk, $Chunks = $Regex.Matches($Chunk).Value | Where-Object Length

        $MermaidItems = $MermaidChunk -split '\r?\n' -replace '^\s*' -replace '[\s;]$'

        $SourceVersions = @{}
        $MermaidItems -match 'Module\d\(' | ForEach-Object {
            $Name, $Version = $_ -replace 'Module\d\(' -replace '\);?' -split ' '
            $SourceVersions[$Name] = $Version
        }

        $Sources = [ordered]@{}
        foreach ($MermaidItem in ($MermaidItems -notmatch 'Module\d\('))
        {
            $Caller, $Call = $MermaidItem -split '-->', 2
            $CallerName, [string]$CallerSource = ($Caller -split '\\')[1,0]
            $CallName, [string]$CallSource = ($Call -split '\\')[1,0]

            if (-not $Sources[$CallerSource])
            {
                $Sources[$CallerSource] = @{}
            }
            if (-not $Sources[$CallSource])
            {
                $Sources[$CallSource] = @{}
            }

            $Sources[$CallerSource][$CallerName] += @($CallName)
            $Sources[$CallSource][$CallName] += @()
        }

        $Builder = [Text.StringBuilder]::new()

        #region $TestCases
        # Output something roughly equivalent to:
        #     $TestCases = @(
        #         @{
        #             Invocation = "'f1' | Find-Call"
        #             Expected   = "<output>"
        #         }, ...etc...
        #
        [void]$Builder.
            AppendLine('$TestCases = @(').
            Append('    ')

        $Chunks | ForEach-Object {
            $Lines      = $_ -split '\r?\n'
            $Invocation = $Lines.Where({$_ -notmatch '^>'}, 'Until') -replace '^>\s*'
            $Output     = $Lines.Where({$_ -match '^[^>]'}, 'SkipUntil')

            [void]$Builder.
                AppendLine('@{').
                AppendLine("        Invocation = @'").
                AppendLine($Invocation -join '; ').
                AppendLine("'@").
                AppendLine("        Expected   = @'").
                AppendLine($Output -join "`n").
                AppendLine("'@").
                Append('    }, ')
        }

        $Builder.Length = $Builder.Length - 2   # Drop the trailing comma and space
        [void]$Builder.
            AppendLine().
            AppendLine(')').
            AppendLine()
        #endregion $TestCases

        #region function definitions for test input
        [void]$Builder.
            AppendLine('$Modules = @{}').
            AppendLine()

        [void]$Builder.
            AppendLine('$ModuleVersions = @{')

        foreach ($Kvp in $SourceVersions.GetEnumerator())
        {
            [void]$Builder.
                Append('    ').
                Append($Kvp.Key).
                Append(" = '").
                Append($Kvp.Value).
                AppendLine("'")
        }

        [void]$Builder.
            AppendLine('}').
            AppendLine()

        foreach ($Kvp in ($Sources.GetEnumerator() | Sort-Object Key))
        {
            $Source, $Functions = $Kvp.Key, $Kvp.Value

            [void]$Builder.
                Append("`$Modules['").
                Append($Source).
                AppendLine("'] = {")

            foreach ($Kvp in ($Functions.GetEnumerator() | Sort-Object Key))
            {
                $Name, $Calls = $Kvp.Key, $Kvp.Value
                [void]$Builder.
                    Append('    function ').
                    Append($Name).
                    AppendLine(' {')
                $Calls | ForEach-Object {
                    [void]$Builder.
                        Append('        ').
                        AppendLine($_)
                }
                [void]$Builder.
                    AppendLine('    }')
            }

            [void]$Builder.
                AppendLine('}').
                AppendLine()
        }
        #endregion function definitions for test input

        [IO.FileInfo]$_OutPath = Join-Path $OutPath "$Title.psm1"
        $Builder.ToString() | Out-File $_OutPath -Encoding utf8 -Force
        $_OutPath
    }
}
