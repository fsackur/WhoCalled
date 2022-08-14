#requires -Modules @{ModuleName = 'InvokeBuild'; ModuleVersion = '5.9.1'}

param
(
    [version]$NewVersion
)

# Synopsis: Update manifest version
task UpdateVersion {
    $ManifestPath = "WhoCalled.psd1"
    $ManifestContent = Get-Content $ManifestPath -Raw
    $Manifest = Invoke-Expression "DATA {$ManifestContent}"

    if ($NewVersion -le [version]$Manifest.ModuleVersion)
    {
        throw "Can't go backwards: $NewVersion =\=> $($Manifest.ModuleVersion)"
    }

    $ModuleVersionPattern = "(?<=\n\s*ModuleVersion\s*=\s*(['`"]))(\d+\.)+\d+"

    $ManifestContent = $ManifestContent -replace $ModuleVersionPattern, $NewVersion
    $ManifestContent | Out-File $ManifestPath -Encoding utf8
}

# Synopsis: Run PSSA, excluding Tests folder and *.build.ps1
task PSSA {
    $Files = Get-ChildItem -File -Recurse -Filter *.ps*1 | Where-Object FullName -notmatch '\bTests\b|\.build\.ps1$|install-build-dependencies\.ps1'
    $Files | ForEach-Object {
        Invoke-ScriptAnalyzer -Path $_.FullName -Recurse -Settings .\.vscode\PSScriptAnalyzerSettings.psd1
    }
}

# Synopsis: Clean build folder
task Clean {
    remove Build
}

# Synopsis: Build module at manifest version
task Build {
    $ManifestPath = "WhoCalled.psd1"
    $ManifestContent = Get-Content $ManifestPath -Raw
    $Manifest = Invoke-Expression "DATA {$ManifestContent}"

    $Version = $Manifest.ModuleVersion
    $BuildFolder = New-Item "Build/WhoCalled/$Version" -ItemType Directory -Force
    $BuiltManifestPath = Join-Path $BuildFolder $ManifestPath
    $BuiltRootModulePath = Join-Path $BuildFolder $Manifest.RootModule

    Copy-Item $ManifestPath $BuildFolder
    Copy-Item "README.md" $BuildFolder
    Copy-Item "LICENSE" $BuildFolder
    Copy-Item "WhoCalled.Format.ps1xml" $BuildFolder

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

# Synopsis: Import latest version of module from build folder
task Import {
    Import-Module "$BuildRoot/Build/WhoCalled" -Force -Global -ErrorAction Stop
}

task Test Clean, Build, Import, {
    Invoke-Pester
}

task . Clean, Build, Import, PSSA, Test
