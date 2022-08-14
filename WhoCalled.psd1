@{
    Description          = 'Build a tree of function calls.'
    ModuleVersion        = '1.4.5'
    HelpInfoURI          = 'https://pages.github.com/fsackur/WhoCalled'

    GUID                 = '7b5c6e30-13b1-4ff8-a3ca-f1151b346066'

    Author               = 'Freddie Sackur'
    CompanyName          = 'DustyFox'
    Copyright            = '(c) 2022 Freddie Sackur. All rights reserved.'

    RootModule           = 'WhoCalled.psm1'

    AliasesToExport      = @()
    FunctionsToExport    = @(
        'Find-Call',
        'Find-Caller'
    )

    FormatsToProcess     = @(
        'WhoCalled.Format.ps1xml'
    )

    PrivateData          = @{
        PSData = @{
            LicenseUri = 'https://raw.githubusercontent.com/fsackur/WhoCalled/main/LICENSE'
            ProjectUri = 'https://github.com/fsackur/WhoCalled'
            Tags       = @(
                'AST',
                'Dependency',
                'Function',
                'Parse',
                'Parsing',
                'Refactor',
                'Refactoring',
                'Analysis',
                'CodeAnalysis',
                'StaticAnalysis',
                'Find-Call',
                'Find-Caller'
            )
        }
    }
}
