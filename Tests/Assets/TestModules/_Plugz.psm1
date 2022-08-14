function _Export-PlugzProfile{
    _Get-PlugzConfig
}
function _Get-PlugzConfig{
    _Import-Configuration
}
function _Import-Plugz{
    _Get-PlugzConfig
    _Test-CalledFromProfile
}
function _Save-PlugzConfig{
    _Export-Configuration
}
function _Test-CalledFromProfile{
}

