[Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingInvokeExpression', '')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    # Generate test modules from the mermaid markdown
    $AssetPath = $PSCommandPath | Split-Path | Join-Path -ChildPath Assets
    . (Join-Path $AssetPath Parse-Mermaid.ps1)
    $ModulePaths = Parse-Mermaid

    # Read test cases from the generated test modules
    $TestCases   = $ModulePaths | ForEach-Object {
        @{
            Name = $_.BaseName
            Path = $_
        }
    }
}

Describe "<Name>" -ForEach $TestCases {

    BeforeDiscovery {
        $ModuleTestCases = $_ | ForEach-Object {
            $Module = Import-Module $Path -PassThru -Force
            & $Module {$TestCases}
        }
    }

    BeforeEach {
        $Output = Invoke-Expression "$Invocation -Debug:`$false" | Out-String | ForEach-Object Trim
        $Output = $Output -replace "$([char]27).*?m" -replace '\r'
        $Expected = $Expected  -replace "$([char]27).*?m" -replace '\r'
    }

    It "<Invocation>" -ForEach $ModuleTestCases {
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
