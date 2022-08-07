#requires -Modules @{ModuleName = 'InvokeBuild'; ModuleVersion = '5.9.1'}

# Synopsis: Run PSSA, excluding Tests folder and *.build.ps1
task PSSA {
    $Files = Get-ChildItem -File -Recurse -Filter *.ps*1 | Where-Object FullName -notmatch '\bTests\b|\.build\.ps1$'
    $Files | ForEach-Object {
        Invoke-ScriptAnalyzer -Path $_.FullName -Recurse -Settings .\.vscode\PSScriptAnalyzerSettings.psd1
    }
}

task Clean {
    remove Build
}

task Build {
    $ManifestName = "FindFunctionCalls.psd1"
    $Manifest = Invoke-Expression "DATA {$(Get-Content -Raw $ManifestName)}"
    $Version = $Manifest.ModuleVersion
    $BuildFolder = New-Item "Build/FindFunctionCalls/$Version" -ItemType Directory -Force
    $BuiltManifestPath = Join-Path $BuildFolder $ManifestName
    $BuiltRootModulePath = Join-Path $BuildFolder $Manifest.RootModule
    Copy-Item $ManifestName $BuildFolder
    Copy-Item "README.md" $BuildFolder
    Copy-Item "LICENSE" $BuildFolder
    Copy-Item "FindFunctionCalls.Format.ps1xml" $BuildFolder

    'Classes', 'Private', 'Public' | ForEach-Object {
        "",
        "#region $_",
        ($_ | Get-ChildItem | Get-Content),
        "#endregion $_",
        ""
    } |
        Write-Output |
        Out-File $BuiltRootModulePath -Encoding utf8NoBOM
}

Task Import {
    Import-Module "$BuildRoot/Build/FindFunctionCalls" -ErrorAction Stop
}

task Test {
    Invoke-Pester
}

task . Clean, Build, Import, Test
