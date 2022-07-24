
'Classes', 'Private', 'Public' |
    ForEach-Object {Join-Path $PSScriptRoot $_} |
    Get-ChildItem -Filter *.ps1 |
    ForEach-Object {. $_.FullName}
