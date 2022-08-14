function _Export-Configuration{
    _Export-Metadata
    _Get-ConfigurationPath
    _ParameterBinder
}
function _Get-ConfigurationPath{
    _ParameterBinder
}
function _Import-Configuration{
    _Get-ConfigurationPath
    _Import-Metadata
    _ParameterBinder
    _Update-Object
}
function _Import-ParameterConfiguration{
    _Import-Metadata
}
function _ParameterBinder{
}

