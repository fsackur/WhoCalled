function Import-TestCase
{
    <#
        .SYNOPSIS
        Self-testing-documentation parser.

        .DESCRIPTION
        Parse markdown containing example usage code blocks; generate unit test cases.

        .NOTES
        Each test case generates a module and defines one or more sub-test-cases.

        The test cases are defined by fenced code blocks. Blocks must start with one or more PS
        invocations, which begin with `>`, followed by any number of empty lines, then the expected
        output.

        The expected output will be processed again, to handle difference in output rendering on
        different systems.

        The command and module names will be prepended with an underscore, to prevent name clash
        with common modules.
    #>

    [OutputType([IO.FileInfo])]
    [CmdletBinding()]
    param
    (
        [string]$Path = 'mermaid.md',

        [string]$OutPath = 'TestCases.ps1'
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
        $null = New-Item -ItemType Directory -Force -ErrorAction Ignore (Split-Path $OutPath)
    }

    $Builder = [Text.StringBuilder]::new()
    $Content = Get-Content $Path -Raw
    $Chunks  = $Content -split '(?<=\n)## ' | Select-Object -Skip 1

    # Match mermaid code block, dropping the `graph TD` directive, or any other code block with
    # optional PS or plaintext languge directive
    $Pattern = '(?<=```((mermaid)\r?\ngraph (TD|LR);?|powershell|pwsh|plaintext|)\r?\n).*?(?=\r?\n```)'
    $Regex   = [regex]::new($Pattern, 'Singleline')
    foreach ($Chunk in $Chunks)
    {
        $CodeBlocks = $Regex.Matches($Chunk) |
            Where-Object {
                $_.Value.Length -and
                -not ($_.Groups.Value -eq 'mermaid')
            } |
            ForEach-Object Value

        # Output hashtables with Invocation and Expected keys
        $CodeBlocks | ForEach-Object {
            $Lines      = $_ -split '\r?\n'
            $Invocation = $Lines.Where({$_ -notmatch '^>'}, 'Until') -replace '^>\s*'
            $Expected   = $Lines.Where({$_ -match '^[^>]'}, 'SkipUntil')

            $Invocation = $Invocation -replace '\b(?<!-)(?!Find-Call)(?=[a-z])', '_' -join '; '
            $Expected   = (
                ($Expected[0] -replace 'Name', 'Name '),
                ($Expected[1] -replace '(?<=^-+ +-+) ', '  '),
                (
                    $Expected[2..$Expected.Count] -replace '(?<=^\w+\s+)(?=[a-z])', '_' -replace '(?<=\s)(?=\w+$)', '_'
                )
            ) | Out-String | ForEach-Object Trim

            [void]$Builder.
                AppendLine().
                AppendLine('@{').
                AppendLine("    ModulePath = '$($ModulePaths -join "', '")'").
                AppendLine("    Invocation = @'").
                AppendLine($Invocation).
                AppendLine("'@").
                AppendLine("    Expected   = @'").
                AppendLine($Expected).
                AppendLine("'@").
                Append('},')
        }
    }
    $Builder.Length = $Builder.Length - 1   # Drop the trailing comma

    $Builder.ToString() | Out-File $OutPath -Encoding utf8 -Force

    [IO.FileInfo]$OutPath
}
