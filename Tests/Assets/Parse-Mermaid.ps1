function Parse-Mermaid
{
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
    $Chunks = $Content -split '(?<=\n)## '
    foreach ($Chunk in $Chunks)
    {
        $Title, $Chunk = $Chunk -split '\n', 2 | ForEach-Object Trim
        if ($Title -match '^#') {continue}  # Get rid of the introduction

        $Functions = [ordered]@{}

        $MermaidBlock = $Chunk -replace '(?s)```\s*mermaid\r?\n\s*graph[^\n]+\n' -replace '(?s)\s*```.*'
        $MermaidItems = $MermaidBlock -split '\r?\n' -replace '[\s;]'
        foreach ($MermaidItem in $MermaidItems)
        {
            $Caller, $Call = $MermaidItem -split '-->', 2
            $Functions[$Caller] += @($Call)
            $Functions[$Call] += @()
        }

        $Builder = [Text.StringBuilder]::new()
        foreach ($Kvp in $Functions.GetEnumerator())
        {
            $Name, $Calls = $Kvp.Key, $Kvp.Value
            [void]$Builder.Append('function ').Append($Name).AppendLine(' {')
            $Calls | ForEach-Object {[void]$Builder.Append('    ').AppendLine($_)}
            [void]$Builder.AppendLine('}')
        }
        [IO.FileInfo]$_OutPath = Join-Path $OutPath "$Title.psm1"
        $Builder.ToString() | Out-File $_OutPath -Encoding utf8 -Force
        $_OutPath
    }
}
