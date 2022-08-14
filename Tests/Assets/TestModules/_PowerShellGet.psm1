function _Compare-PrereleaseVersions{
}
function _DeSerialize-PSObject{
}
function _Find-Command{
    _Find-Module
}
function _Find-DscResource{
    _Find-Module
}
function _Find-Module{
    _Find-Package
    _Get-PSRepository
    _Install-NuGetClientBinaries
    _Log-ArtifactNotFoundInPSGallery
    _New-PSGetItemInfo
    _Test-WildcardPattern
    _Validate-VersionParameters
}
function _Find-RoleCapability{
    _Find-Module
}
function _Find-Script{
    _Find-Package
    _Get-PSRepository
    _Install-NuGetClientBinaries
    _Log-ArtifactNotFoundInPSGallery
    _New-PSGetItemInfo
    _Test-WildcardPattern
    _Validate-VersionParameters
}
function _Get-AvailableRoleCapabilityName{
    _Join-PathUtility
}
function _Get-AvailableScriptFilePath{
    _Test-WildcardPattern
}
function _Get-CredsFromCredentialProvider{
}
function _Get-DynamicParameters{
    _Get-PackageProvider
    _Get-PackageSource
    _Get-LocationString
    _Get-PackageManagementProviderName
    _Resolve-Location
}
function _Get-EntityName{
}
function _Get-EnvironmentVariable{
}
function _Get-ExportedDscResources{
    _Join-PathUtility
    _Get-DscResource
}
function _Get-ExternalModuleDependencies{
}
function _Get-First{
}
function _Get-InstallationScope{
    _Test-RunningAsElevated
}
function _Get-InstalledModule{
    _Get-Package
    _New-PSGetItemInfo
    _Validate-VersionParameters
}
function _Get-InstalledScript{
    _Get-Package
    _New-PSGetItemInfo
    _Validate-VersionParameters
}
function _Get-InstalledScriptFilePath{
    _Get-AvailableScriptFilePath
    _Test-ScriptInstalled
}
function _Get-LocationString{
}
function _Get-ManifestHashTable{
}
function _Get-ModuleDependencies{
    _Get-ManifestHashTable
    _ValidateAndGet-RequiredModuleDetails
}
function _Get-OrderedPSScriptInfoObject{
}
function _Get-PackageManagementProviderName{
    _Get-PackageProvider
    _Get-PackageSource
    _Get-LocationString
}
function _Get-ParametersHashtable{
}
function _Get-PrivateData{
}
function _Get-ProviderName{
}
function _Get-PSRepository{
    _Get-PackageSource
    _New-ModuleSourceFromPackageSource
}
function _Get-PSScriptInfoString{
}
function _Get-PublishLocation{
}
function _Get-RequiresString{
}
function _Get-ScriptCommentHelpInfoString{
}
function _Get-ScriptSourceLocation{
}
function _Get-SourceLocation{
    _Set-ModuleSourcesVariable
}
function _Get-SourceName{
    _Set-ModuleSourcesVariable
    _Test-EquivalentLocation
}
function _Get-UrlFromSwid{
}
function _HttpClientApisAvailable{
}
function _Install-Module{
    _Install-Package
    _Get-ProviderName
    _Get-PSRepository
    _Install-NuGetClientBinaries
    _New-PSGetItemInfo
    _Test-ModuleInstalled
    _Test-RunningAsElevated
    _ThrowError
    _Validate-VersionParameters
}
function _Install-NuGetClientBinaries{
    _Get-PackageProvider
    _Import-PackageProvider
    _Install-PackageProvider
    _Get-ParametersHashtable
    _Test-RunningAsElevated
    _ThrowError
}
function _Install-Script{
    _Install-Package
    _Get-ProviderName
    _Get-PSRepository
    _Install-NuGetClientBinaries
    _New-PSGetItemInfo
    _Test-RunningAsElevated
    _Test-ScriptInstalled
    _ThrowError
    _Validate-VersionParameters
    _ValidateAndSet-PATHVariableIfUserAccepts
}
function _Join-PathUtility{
}
function _Log-ArtifactNotFoundInPSGallery{
    _Test-WildcardPattern
}
function _New-ModuleSourceFromPackageSource{
}
function _New-NugetPackage{
}
function _New-NuspecFile{
}
function _New-PSGetItemInfo{
    _Get-EntityName
    _Get-First
    _Get-SourceLocation
    _Get-SourceName
    _Get-UrlFromSwid
}
function _New-PSScriptInfoObject{
}
function _New-ScriptFileInfo{
    _Get-EnvironmentVariable
    _Get-PSScriptInfoString
    _Get-RequiresString
    _Get-ScriptCommentHelpInfoString
    _Test-ScriptFileInfo
    _ThrowError
    _Validate-ScriptFileInfoParameters
    _ValidateAndGet-VersionPrereleaseStrings
}
function _nuget{
}
function _Ping-Endpoint{
    _HttpClientApisAvailable
}
function _Publish-Module{
    _Compare-PrereleaseVersions
    _Find-Module
    _Find-Script
    _Get-ProviderName
    _Get-PSRepository
    _Install-NuGetClientBinaries
    _Join-PathUtility
    _Publish-PSArtifactUtility
    _Resolve-PathHelper
    _Test-WebUri
    _ThrowError
    _Validate-VersionParameters
    _ValidateAndGet-VersionPrereleaseStrings
}
function _Publish-NugetPackage{
}
function _Publish-PSArtifactUtility{
    _Get-AvailableRoleCapabilityName
    _Get-ExportedDscResources
    _Get-ManifestHashTable
    _Get-ModuleDependencies
    _Install-NuGetClientBinaries
    _Join-PathUtility
    _New-NugetPackage
    _New-NuspecFile
    _Publish-NugetPackage
    _ThrowError
    _ValidateAndGet-ScriptDependencies
}
function _Publish-Script{
    _Compare-PrereleaseVersions
    _Find-Module
    _Find-Script
    _Get-ProviderName
    _Get-PSRepository
    _Install-NuGetClientBinaries
    _Publish-PSArtifactUtility
    _Resolve-PathHelper
    _Test-ScriptFileInfo
    _Test-WebUri
    _ThrowError
    _ValidateAndGet-VersionPrereleaseStrings
}
function _Register-PSRepository{
    _nuget
    _Get-PackageProvider
    _Register-PackageSource
    _Get-CredsFromCredentialProvider
    _Get-DynamicParameters
    _Get-LocationString
    _Get-PackageManagementProviderName
    _Install-NuGetClientBinaries
    _Ping-Endpoint
    _Resolve-Location
    _ThrowError
}
function _Resolve-Location{
    _Ping-Endpoint
    _Test-WebUri
    _ThrowError
}
function _Resolve-PathHelper{
    _ThrowError
}
function _Save-Module{
    _Save-Package
    _Get-ProviderName
    _Get-PSRepository
    _Install-NuGetClientBinaries
    _Resolve-PathHelper
    _ThrowError
    _Validate-VersionParameters
}
function _Save-ModuleSources{
}
function _Save-PSGetSettings{
}
function _Save-Script{
    _Save-Package
    _Get-ProviderName
    _Get-PSRepository
    _Install-NuGetClientBinaries
    _Resolve-PathHelper
    _ThrowError
    _Validate-VersionParameters
}
function _Send-EnvironmentChangeMessage{
}
function _Set-EnvironmentVariable{
    _Send-EnvironmentChangeMessage
    _ThrowError
}
function _Set-ModuleSourcesVariable{
    _DeSerialize-PSObject
    _Get-PublishLocation
    _Get-ScriptSourceLocation
    _Save-ModuleSources
    _Set-PSGalleryRepository
}
function _Set-PSGalleryRepository{
}
function _Set-PSGetSettingsVariable{
    _DeSerialize-PSObject
}
function _Set-PSRepository{
    _Get-PackageProvider
    _Set-PackageSource
    _Get-DynamicParameters
    _Get-LocationString
    _Get-ProviderName
    _Get-PSRepository
    _Install-NuGetClientBinaries
    _Resolve-Location
    _ThrowError
}
function _Test-EquivalentLocation{
}
function _Test-ItemPrereleaseVersionRequirements{
    _Compare-PrereleaseVersions
    _ValidateAndGet-VersionPrereleaseStrings
}
function _Test-ModuleInstalled{
    _Test-ItemPrereleaseVersionRequirements
    _Test-ModuleSxSVersionSupport
}
function _Test-ModuleSxSVersionSupport{
}
function _Test-RunningAsElevated{
}
function _Test-ScriptFileInfo{
    _Get-OrderedPSScriptInfoObject
    _New-PSScriptInfoObject
    _Resolve-PathHelper
    _ThrowError
    _ValidateAndAdd-PSScriptInfoEntry
    _ValidateAndGet-VersionPrereleaseStrings
}
function _Test-ScriptInstalled{
    _New-PSScriptInfoObject
    _Test-ScriptFileInfo
    _ValidateAndGet-VersionPrereleaseStrings
}
function _Test-WebUri{
}
function _Test-WildcardPattern{
}
function _ThrowError{
}
function _Uninstall-Module{
    _Uninstall-Package
    _ThrowError
    _Validate-VersionParameters
}
function _Uninstall-Script{
    _Uninstall-Package
    _ThrowError
    _Validate-VersionParameters
}
function _Unregister-PSRepository{
    _nuget
    _Unregister-PackageSource
    _Test-WildcardPattern
}
function _Update-Module{
    _Get-Package
    _Install-Package
    _Get-InstallationScope
    _Get-ProviderName
    _Install-NuGetClientBinaries
    _New-PSGetItemInfo
    _Test-RunningAsElevated
    _Test-WildcardPattern
    _ThrowError
    _Validate-VersionParameters
}
function _Update-ModuleManifest{
    _Get-ManifestHashTable
    _Get-PrivateData
    _ThrowError
    _ValidateAndGet-VersionPrereleaseStrings
}
function _Update-Script{
    _Install-Package
    _DeSerialize-PSObject
    _Get-AvailableScriptFilePath
    _Get-InstallationScope
    _Get-InstalledScriptFilePath
    _Get-ProviderName
    _Install-NuGetClientBinaries
    _New-PSGetItemInfo
    _Test-WildcardPattern
    _Validate-VersionParameters
}
function _Update-ScriptFileInfo{
    _Get-EnvironmentVariable
    _Get-PSScriptInfoString
    _Get-RequiresString
    _Get-ScriptCommentHelpInfoString
    _Resolve-PathHelper
    _Test-ScriptFileInfo
    _ThrowError
    _Validate-ScriptFileInfoParameters
    _ValidateAndGet-VersionPrereleaseStrings
}
function _Validate-ScriptFileInfoParameters{
}
function _Validate-VersionParameters{
    _Compare-PrereleaseVersions
    _Test-WildcardPattern
    _ThrowError
    _ValidateAndGet-VersionPrereleaseStrings
}
function _ValidateAndAdd-PSScriptInfoEntry{
    _Test-WebUri
    _ThrowError
    _ValidateAndGet-VersionPrereleaseStrings
}
function _ValidateAndGet-NuspecVersionString{
    _ThrowError
}
function _ValidateAndGet-RequiredModuleDetails{
    _Find-Module
    _Get-ExternalModuleDependencies
    _ThrowError
}
function _ValidateAndGet-ScriptDependencies{
    _Find-Module
    _Find-Script
    _ThrowError
    _ValidateAndGet-NuspecVersionString
}
function _ValidateAndGet-VersionPrereleaseStrings{
    _ThrowError
}
function _ValidateAndSet-PATHVariableIfUserAccepts{
    _Get-EnvironmentVariable
    _Save-PSGetSettings
    _Set-EnvironmentVariable
    _Set-PSGetSettingsVariable
}

