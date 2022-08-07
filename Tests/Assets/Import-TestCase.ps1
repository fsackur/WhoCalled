function Import-TestCase
{
    <#
        .SYNOPSIS
        Imports test cases from generated test modules. Fixes up command versions.

        .INPUTS
        [IO.FileInfo]

        Pipe paths from Parse-Mermaid.

        .OUTPUTS
        [hashtable]

        Outputs test case data for Pester.
    #>

    [OutputType([hashtable])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [IO.FileInfo]$Path
    )

    process
    {
        $Name = $Path.BaseName
        $Output = @{
            Name = $Name
            Path = $Path
        }

        # Exports $TestCases, $Modules, $ModuleVersions
        . $Path

        $Output.Modules = $Modules.GetEnumerator() | ForEach-Object {
            $Params = @{Scriptblock = $_.Value}
            $Name = $_.Key  # may be empty string
            if ($Name) {$Params.Name = $Name}

            $Module = New-Module @Params
            $Version = $ModuleVersions[$Name]
            if ($Version)
            {
                $Module | Add-Member -Force -NotePropertyMembers @{Version = [version]$Version}
            }
            $Module
        }

        $TestCases | ForEach-Object {$_ + $Output}
    }
}
