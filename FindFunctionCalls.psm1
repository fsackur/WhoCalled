
Join-Path $PSScriptRoot Public |
    Get-ChildItem -Filter *.ps1 |
    ForEach-Object {. $_.FullName}
