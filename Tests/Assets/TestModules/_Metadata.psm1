function _Add-MetadataConverter{
    _WriteError
}
function _ConvertFrom-Metadata{
    _Add-MetadataConverter
    _Test-PSVersion
    _ThrowError
}
function _ConvertTo-Metadata{
    _Add-MetadataConverter
}
function _Export-Metadata{
    _ConvertTo-Metadata
}
function _FindHashKeyValue{
}
function _Get-Metadata{
    _ConvertFrom-Metadata
    _FindHashKeyValue
    _WriteError
}
function _Import-Metadata{
    _ConvertFrom-Metadata
    _ThrowError
    _WriteError
}
function _Test-PSVersion{
}
function _ThrowError{
}
function _Update-Metadata{
    _ConvertTo-Metadata
    _Get-Metadata
}
function _Update-Object{
}
function _WriteError{
}

