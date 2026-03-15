param(
    [switch]$WriteArtifacts
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$gateScript = Join-Path $repoRoot "scripts\verify\runtime_neutral\router_bridge_gate.py"

if (-not (Test-Path -LiteralPath $gateScript)) {
    throw "runtime-neutral router bridge gate missing: $gateScript"
}

$args = @($gateScript)
if ($WriteArtifacts) {
    $args += "--write-artifacts"
}

& python @args
exit $LASTEXITCODE
