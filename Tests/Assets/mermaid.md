# Test declarations

_Developed in `VS Code` with the `bierner.markdown-mermaid` extension._

<!-- See Parse-Mermaid.ps1 for formatting guidance and limitations -->

## Diamond

```mermaid
graph LR;
    f1-->f2;
    f1-->f3;
    f2-->f4;
    f3-->f4;
```

```
> 'f1' | Find-Call

CommandType Name   Version Source
----------- ----   ------- ------
Function    f1     0.0     Diamond
Function      f2   0.0     Diamond
Function        f4 0.0     Diamond
Function      f3   0.0     Diamond
Function        f4 0.0     Diamond
```

```
> 'f4' | Find-Caller -Module Diamond

CommandType Name   Version Source
----------- ----   ------- ------
Function    f4     0.0     Diamond
Function      f2   0.0     Diamond
Function        f1 0.0     Diamond
Function      f3   0.0     Diamond
Function        f1 0.0     Diamond
```

## Three Modules

```mermaid
graph LR;
    Module1(Plugz 0.2.0);
    Module2(Configuration 1.5.1);
    Module3(Metadata 1.5.3);
    Plugz\Export-PlugzProfile-->Plugz\Get-PlugzConfig;
    Plugz\Get-PlugzConfig-->Configuration\Import-Configuration;
    Configuration\Import-Configuration-->Configuration\Get-ConfigurationPath;
    Configuration\Import-Configuration-->Metadata\Import-Metadata;
    Configuration\Import-Configuration-->Configuration\ParameterBinder;
    Configuration\Import-Configuration-->Metadata\Update-Object;
    Configuration\Get-ConfigurationPath-->Configuration\ParameterBinder;
    Metadata\Import-Metadata-->Metadata\ConvertFrom-Metadata;
    Metadata\Import-Metadata-->Metadata\ThrowError;
    Metadata\Import-Metadata-->Metadata\WriteError;
    Metadata\ConvertFrom-Metadata-->Metadata\Add-MetadataConverter;
    Metadata\ConvertFrom-Metadata-->Metadata\Test-PSVersion;
    Metadata\ConvertFrom-Metadata-->Metadata\ThrowError;
    Plugz\Import-Plugz-->Plugz\Get-PlugzConfig;
    Plugz\Import-Plugz-->Plugz\Test-CalledFromProfile;
    Plugz\Save-PlugzConfig-->Configuration\Export-Configuration;
    Configuration\Export-Configuration-->Metadata\Export-Metadata;
    Configuration\Export-Configuration-->Configuration\Get-ConfigurationPath;
    Configuration\Export-Configuration-->Configuration\ParameterBinder;
    Metadata\Export-Metadata-->Metadata\ConvertTo-Metadata;
    Metadata\ConvertTo-Metadata-->Metadata\Add-MetadataConverter;
    Metadata\Add-MetadataConverter-->Metadata\WriteError;
    Metadata\Get-Metadata-->Metadata\ConvertFrom-Metadata;
    Metadata\Get-Metadata-->Metadata\FindHashKeyValue;
    Metadata\Get-Metadata-->Metadata\WriteError;
    Metadata\Update-Metadata-->Metadata\ConvertTo-Metadata;
    Metadata\Update-Metadata-->Metadata\Get-Metadata;
    Configuration\Import-ParameterConfiguration-->Metadata\Import-Metadata;
```

```
> Find-Call Import-Plugz -Depth 5

CommandType Name                            Version Source
----------- ----                            ------- ------
Function    Import-Plugz                    0.2.0   Plugz
Function      Get-PlugzConfig               0.2.0   Plugz
Function        Import-Configuration        1.5.1   Configuration
Function          Get-ConfigurationPath     1.5.1   Configuration
Function            ParameterBinder         1.5.1   Configuration
Function          Import-Metadata           1.5.3   Metadata
Function            ConvertFrom-Metadata    1.5.3   Metadata
Function              Add-MetadataConverter 1.5.3   Metadata
Function              Test-PSVersion        1.5.3   Metadata
Function              ThrowError            1.5.3   Metadata
Function            ThrowError              1.5.3   Metadata
Function            WriteError              1.5.3   Metadata
Function          ParameterBinder           1.5.1   Configuration
Function          Update-Object             1.5.3   Metadata
Function      Test-CalledFromProfile        0.2.0   Plugz
```

## PowerShellGet

```mermaid
graph LR;
    PowerShellGet\Set-ModuleSourcesVariable-->PowerShellGet\Get-PublishLocation;
    PowerShellGet\Add-PackageSource-->PowerShellGet\Get-PublishLocation;
    PowerShellGet\Get-InstalledModuleAuthenticodeSignature-->PowerShellGet\Get-AuthenticodePublisher;
    PowerShellGet\Get-ModuleDependencies-->PowerShellGet\Get-ManifestHashTable;
    PowerShellGet\Get-ModuleDependencies-->PowerShellGet\ValidateAndGet-RequiredModuleDetails;
    PowerShellGet\ValidateAndGet-AuthenticodeSignature-->PowerShellGet\Get-AuthenticodePublisher;
    PowerShellGet\Publish-Module-->PowerShellGet\Compare-PrereleaseVersions;
    PowerShellGet\Publish-Module-->PowerShellGet\Find-Module;
    PowerShellGet\Publish-Module-->PowerShellGet\Find-Script;
    PowerShellGet\Publish-Module-->PowerShellGet\Get-ProviderName;
    PowerShellGet\Publish-Module-->PowerShellGet\Get-PSRepository;
    PowerShellGet\Publish-Module-->PowerShellGet\Install-NuGetClientBinaries;
    PowerShellGet\Publish-Module-->PowerShellGet\Join-PathUtility;
    PowerShellGet\Publish-Module-->PowerShellGet\Publish-PSArtifactUtility;
    PowerShellGet\Publish-Module-->PowerShellGet\Resolve-PathHelper;
    PowerShellGet\Publish-Module-->PowerShellGet\Test-WebUri;
    PowerShellGet\Publish-Module-->PowerShellGet\ThrowError;
    PowerShellGet\Publish-Module-->PowerShellGet\Validate-VersionParameters;
    PowerShellGet\Publish-Module-->PowerShellGet\ValidateAndGet-VersionPrereleaseStrings;
    PowerShellGet\Publish-PSArtifactUtility-->PowerShellGet\Get-AvailableRoleCapabilityName;
    PowerShellGet\Publish-PSArtifactUtility-->PowerShellGet\Get-ExportedDscResources;
    PowerShellGet\Publish-PSArtifactUtility-->PowerShellGet\Get-ManifestHashTable;
    PowerShellGet\Publish-PSArtifactUtility-->PowerShellGet\Get-ModuleDependencies;
    PowerShellGet\Publish-PSArtifactUtility-->PowerShellGet\Install-NuGetClientBinaries;
    PowerShellGet\Publish-PSArtifactUtility-->PowerShellGet\Join-PathUtility;
    PowerShellGet\Publish-PSArtifactUtility-->PowerShellGet\New-NugetPackage;
    PowerShellGet\Publish-PSArtifactUtility-->PowerShellGet\New-NuspecFile;
    PowerShellGet\Publish-PSArtifactUtility-->PowerShellGet\Publish-NugetPackage;
    PowerShellGet\Publish-PSArtifactUtility-->PowerShellGet\ThrowError;
    PowerShellGet\Publish-PSArtifactUtility-->PowerShellGet\ValidateAndGet-ScriptDependencies;
    PowerShellGet\Publish-Script-->PowerShellGet\Compare-PrereleaseVersions;
    PowerShellGet\Publish-Script-->PowerShellGet\Find-Module;
    PowerShellGet\Publish-Script-->PowerShellGet\Find-Script;
    PowerShellGet\Publish-Script-->PowerShellGet\Get-ProviderName;
    PowerShellGet\Publish-Script-->PowerShellGet\Get-PSRepository;
    PowerShellGet\Publish-Script-->PowerShellGet\Install-NuGetClientBinaries;
    PowerShellGet\Publish-Script-->PowerShellGet\Publish-PSArtifactUtility;
    PowerShellGet\Publish-Script-->PowerShellGet\Resolve-PathHelper;
    PowerShellGet\Publish-Script-->PowerShellGet\Test-ScriptFileInfo;
    PowerShellGet\Publish-Script-->PowerShellGet\Test-WebUri;
    PowerShellGet\Publish-Script-->PowerShellGet\ThrowError;
    PowerShellGet\Publish-Script-->PowerShellGet\ValidateAndGet-VersionPrereleaseStrings;
```

```
> Find-Call Install-Module

CommandType Name                                          Version Source
----------- ----                                          ------- ------
Function    Install-Module                                2.2.5   PowerShellGet
Function      Get-ProviderName                            2.2.5   PowerShellGet
Function      Get-PSRepository                            2.2.5   PowerShellGet
Cmdlet          Get-PackageSource                         1.4.7   PackageManagement
Function        New-ModuleSourceFromPackageSource         2.2.5   PowerShellGet
Function      Install-NuGetClientBinaries                 2.2.5   PowerShellGet
Cmdlet          Get-PackageProvider                       1.4.7   PackageManagement
Function        Get-ParametersHashtable                   2.2.5   PowerShellGet
Cmdlet          Import-PackageProvider                    1.4.7   PackageManagement
Cmdlet          Install-PackageProvider                   1.4.7   PackageManagement
Function        Test-RunningAsElevated                    2.2.5   PowerShellGet
Function        ThrowError                                2.2.5   PowerShellGet
Cmdlet        Install-Package                             1.4.7   PackageManagement
Function      New-PSGetItemInfo                           2.2.5   PowerShellGet
Function        Get-EntityName                            2.2.5   PowerShellGet
Function        Get-First                                 2.2.5   PowerShellGet
Function        Get-SourceLocation                        2.2.5   PowerShellGet
Function          Set-ModuleSourcesVariable               2.2.5   PowerShellGet
Function            DeSerialize-PSObject                  2.2.5   PowerShellGet
Function            Get-PublishLocation                   2.2.5   PowerShellGet
Function            Get-ScriptSourceLocation              2.2.5   PowerShellGet
Function            Save-ModuleSources                    2.2.5   PowerShellGet
Function            Set-PSGalleryRepository               2.2.5   PowerShellGet
Function        Get-SourceName                            2.2.5   PowerShellGet
Function          Set-ModuleSourcesVariable               2.2.5   PowerShellGet
Function          Test-EquivalentLocation                 2.2.5   PowerShellGet
Function        Get-UrlFromSwid                           2.2.5   PowerShellGet
Function      Test-ModuleInstalled                        2.2.5   PowerShellGet
Function        Test-ItemPrereleaseVersionRequirements    2.2.5   PowerShellGet
Function          Compare-PrereleaseVersions              2.2.5   PowerShellGet
Function          ValidateAndGet-VersionPrereleaseStrings 2.2.5   PowerShellGet
Function            ThrowError                            2.2.5   PowerShellGet
Function        Test-ModuleSxSVersionSupport              2.2.5   PowerShellGet
Function      Test-RunningAsElevated                      2.2.5   PowerShellGet
Function      ThrowError                                  2.2.5   PowerShellGet
Function      Validate-VersionParameters                  2.2.5   PowerShellGet
Function        Compare-PrereleaseVersions                2.2.5   PowerShellGet
Function        Test-WildcardPattern                      2.2.5   PowerShellGet
Function        ThrowError                                2.2.5   PowerShellGet
Function        ValidateAndGet-VersionPrereleaseStrings   2.2.5   PowerShellGet
```

```
> Find-Caller Get-ModuleDependencies -Module PowerShellGet, PackageManagement

CommandType Name                        Version Source
----------- ----                        ------- ------
Function    Get-ModuleDependencies      2.2.5   PowerShellGet
Function      Publish-PSArtifactUtility 2.2.5   PowerShellGet
Function        Publish-Module          2.2.5   PowerShellGet
Function        Publish-Script          2.2.5   PowerShellGet
```
