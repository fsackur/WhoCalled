#requires -Modules @{ModuleName = 'Pester'; ModuleVersion = '5.3.3'}

[Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingInvokeExpression', '')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    $AssetPath = $PSCommandPath | Split-Path | Join-Path -ChildPath Assets
    $Script:ModulePath = Join-Path $AssetPath TestModules

    # Generate test cases from the mermaid markdown
    . (Join-Path $AssetPath Import-TestCase.ps1)
    $TestCasePath = Import-TestCase -OutPath 'Generated/TestCases.ps1'

    $TestCases = & $TestCasePath
}

Describe "Examples from documentation" {

    BeforeAll {
        # Clear call cache in the SUT
        & (Get-Module WhoCalled) {if ($CACHE) {$CACHE.Clear()}}

        $ModulePaths = Get-ChildItem $ModulePath -Filter *.psd1
        $TestModules = $ModulePaths | Import-Module -PassThru -Force -DisableNameChecking
    }

    AfterAll {
        $TestModules | Remove-Module
    }

    BeforeEach {
        # Do the thing
        $Output = Invoke-Expression "$Invocation -Debug:`$false" | Out-String | ForEach-Object Trim

        # Strip ANSI control codes
        $Output = $Output -replace "$([char]27).*?m" -replace '\r'
        $Expected = $Expected  -replace "$([char]27).*?m" -replace '\r'
    }

    It "<Invocation>" -TestCases $TestCases {
        try
        {
            $Output | Should -Be $Expected
        }
        catch
        {
            Write-Host "`e[34m$Expected`e[0m`n"
            Write-Host "`e[31m$Output`e[0m`n"

            Write-Error -ErrorRecord $_ -ErrorAction Stop
        }
    }
}
