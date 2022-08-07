function Resolve-Command
{
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
            $Module.Invoke($Resolver, @($Name, $Module.Name, $ResolveAlias))
        }
        else
        {
            & $Resolver $Name '' $ResolveAlias
        }
        $Calls
    }
}
