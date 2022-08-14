function Resolve-Command
{
    <#
        .DESCRIPTION
        Find commands. Aliases are optionally resolved to the command they alias.

        If a module is provided, and it is not null, command resolution is done in the module's
        scope. This allows resolution of private commands.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', 'ResolveAlias', Justification = "It's used in a scriptblock")]

    [OutputType([CallInfo[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [SupportsWildcards()]
        [string]$Name,

        [AllowNull()]
        [psmoduleinfo]$Module,

        [switch]$ResolveAlias
    )

    begin
    {
        $Resolver = {
            param ([string]$Name, [string]$ModuleName, [switch]$ResolveAlias)

            try
            {
                return Get-Command $Name -ErrorAction Stop |
                    ForEach-Object {if ($ResolveAlias -and $_.CommandType -eq 'Alias') {$_.ResolvedCommand} else {$_}}
            }
            catch [Management.Automation.CommandNotFoundException]
            {
                Write-Warning "Command resolution failed for command '$Name'$(if ($ModuleName) {" in module '$ModuleName'"})."
            }
            catch
            {
                Write-Error -ErrorRecord $_
            }
            return $Name
        }
    }

    process
    {
        [CallInfo[]]$Calls = if ($Module)
        {
            # Running Get-Command for a non-imported module gives an uninitialised module object
            $Module = Import-Module $Module -PassThru

            $Module.Invoke($Resolver, @($Name, $Module.Name, $ResolveAlias))
        }
        else
        {
            & $Resolver $Name '' $ResolveAlias
        }
        $Calls
    }
}
