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
        the generated test case.

        The test cases are defined by fenced code blocks. The first block must be a mermaid graph.
        Following blocks must start with one or more PS invocations, which begin with `>`, followed
        by any number of empty lines, then the expected output.

        Versions of the test modules are defined in the mermaid block by defining a member with
        module name and version inside round brackets, as follows: `Module1(Foo, 1.2.3)`. The
        `Module1` label does nothing; it's a necessary bit of mermaid syntax.

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

        #region Build function map
        $Sources = [ordered]@{}
        $SourceVersions = @{}
        foreach ($MermaidItem in $MermaidItems)
        {
            if ($MermaidItem -match 'Module\d\((?<Name>\S+)\s*(?<Version>(\d+\.)+\d+)')
            {
                $SourceVersions[$Matches.Name] = $Matches.Version
                continue
            }

            $Caller, $Call = $MermaidItem -split '-->', 2
            $CallerName, $CallerSource = ($Caller -split '\\')[1,0]
            $CallName, $CallSource = ($Call -split '\\')[1,0]
            $CallerSource, $CallSource = $CallerSource, $CallSource -replace '^$', $Title

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
        #endregion Build function map

        $Builder = [Text.StringBuilder]::new()
        $ModulePaths = @()

        #region test module definitions
        foreach ($Kvp in ($Sources.GetEnumerator() | Sort-Object Key))
        {
            $Source, $Functions = $Kvp.Key, $Kvp.Value

            foreach ($Kvp in ($Functions.GetEnumerator() | Sort-Object Key))
            {
                $Name, $Calls = $Kvp.Key, $Kvp.Value
                [void]$Builder.Append("function $Name").AppendLine('{')
                $Calls | ForEach-Object {[void]$Builder.AppendLine("    $_")}
                [void]$Builder.AppendLine('}')
            }

            [IO.FileInfo]$RootModulePath = Join-Path $OutPath "$Source.psm1"
            $Builder.ToString() | Out-File $RootModulePath -Encoding utf8 -Force
            [void]$Builder.Clear()


            [version]$Version = $SourceVersions[$Source]
            if (-not $Version)
            {
                $Version = '0.0'
            }
            [IO.FileInfo]$ManifestPath = Join-Path $OutPath "$Source.psd1"
            New-ModuleManifest -Path $ManifestPath -ModuleVersion $Version -RootModule "$Source.psm1"

            $ModulePaths += $ManifestPath
        }
        #endregion test module definitions

        #region $TestCases
        # Output hashtables with Invocation, Expected and ModulePath keys
        $Chunks | ForEach-Object {
            $Lines      = $_ -split '\r?\n'
            $Invocation = $Lines.Where({$_ -notmatch '^>'}, 'Until') -replace '^>\s*'
            $Expected   = $Lines.Where({$_ -match '^[^>]'}, 'SkipUntil')

            [void]$Builder.
                AppendLine().
                AppendLine('@{').
                AppendLine("    ModulePath = '$($ModulePaths -join "', '")'").
                AppendLine("    Invocation = @'").
                AppendLine($Invocation -join '; ').
                AppendLine("'@").
                AppendLine("    Expected   = @'").
                AppendLine($Expected -join "`n").
                AppendLine("'@").
                Append('},')
        }
        $Builder.Length = $Builder.Length - 1   # Drop the trailing comma

        [IO.FileInfo]$_OutPath = Join-Path $OutPath "$Title.ps1"
        $Builder.ToString() | Out-File $_OutPath -Encoding utf8 -Force

        $_OutPath
        #endregion $TestCases
    }
}
