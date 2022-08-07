[Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingInvokeExpression', '')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    # Generate test modules from the mermaid markdown
    $AssetPath = $PSCommandPath | Split-Path | Join-Path -ChildPath Assets
    . (Join-Path $AssetPath Parse-Mermaid.ps1)
    . (Join-Path $AssetPath Import-TestCase.ps1)

    $ModulePaths = Parse-Mermaid
    $TestCases   = $ModulePaths | Import-TestCase
}

Describe "<Name>" -ForEach $TestCases {

    BeforeEach {
        # Clear call cache in the SUT
        & (Get-Module FindFunctionCalls) {if ($CACHE) {$CACHE.Clear()}}

        $Modules = $Modules | Import-Module -PassThru

        # Fix up the version properties on the module commands
        $VersionField = [Management.Automation.CommandInfo].GetField('_version', 'Instance, NonPublic')
        $Modules | ForEach-Object {
            $Module = $_
            $ModuleCommands = Get-Command -Module $Module
            $ModuleCommands | ForEach-Object {$VersionField.SetValue($_, $Module.Version)}
        }

        # Do the thing
        $Output = Invoke-Expression "$Invocation -Debug:`$false" | Out-String | ForEach-Object Trim

        # Strip ANSI control codes
        $Output = $Output -replace "$([char]27).*?m" -replace '\r'
        $Expected = $Expected  -replace "$([char]27).*?m" -replace '\r'
    }

    It "<Invocation>" {
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
