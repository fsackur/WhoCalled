#requires -Modules @{ModuleName = 'Pester'; ModuleVersion = '5.3.3'}

[Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingInvokeExpression', '')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    # Generate test modules from the mermaid markdown
    $AssetPath = $PSCommandPath | Split-Path | Join-Path -ChildPath Assets
    . (Join-Path $AssetPath Parse-Mermaid.ps1)
    $TestCasePaths = Parse-Mermaid
}

Describe "<_.BaseName>" -ForEach $TestCasePaths {

    BeforeDiscovery {
        $TestCases = $_.FullName | ForEach-Object {. $_} | Write-Output
    }

    BeforeEach {
        # Clear call cache in the SUT
        & (Get-Module FindFunctionCalls) {if ($CACHE) {$CACHE.Clear()}}

        $ModulePath | Import-Module

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
