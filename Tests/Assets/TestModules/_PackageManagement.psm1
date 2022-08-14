$CmdletsToExport = (
    '_Find-Package',
    '_Get-Package',
    '_Get-PackageProvider',
    '_Get-PackageSource',
    '_Import-PackageProvider',
    '_Install-Package',
    '_Install-PackageProvider',
    '_Register-PackageSource',
    '_Save-Package',
    '_Set-PackageSource',
    '_Uninstall-Package',
    '_Unregister-PackageSource'
)

# https://seeminglyscience.github.io/powershell/2017/04/13/cmdlet-creation-with-powershell
#region Define cmdlets
class TestCmdlet : Management.Automation.PSCmdlet {[void] ProcessRecord() {}}

$SessionState = [Management.Automation.SessionState].
    GetProperty('Internal', [Reflection.BindingFlags]'Instance, NonPublic').
    GetValue($ExecutionContext.SessionState)

foreach ($Cmdlet in $CmdletsToExport)
{
    $CmdletEntry = [Management.Automation.Runspaces.SessionStateCmdletEntry]::new($Cmdlet, [TestCmdlet], $null)
    $SessionState.GetType().InvokeMember(
        'AddSessionStateEntry',
        [Reflection.BindingFlags]'InvokeMethod, Instance, NonPublic',
        $null,
        $SessionState,
        @($CmdletEntry, $true)
    )
}
#endregion Define cmdlets
