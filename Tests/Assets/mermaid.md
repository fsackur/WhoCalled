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
