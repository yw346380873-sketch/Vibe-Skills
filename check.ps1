param(
  [ValidateSet("minimal", "full")]
  [string]$Profile = "full",
  [string]$TargetRoot = (Join-Path $env:USERPROFILE ".codex"),
  [switch]$Deep
)

$requiredSkills = @('vibe', 'dialectic', 'local-vco-roles', 'spec-kit-vibe-compat', 'superclaude-framework-compat', 'ralph-loop', 'cancel-ralph', 'tdd-guide', 'think-harder')
$requiredWorkflow = @('brainstorming', 'writing-plans', 'subagent-driven-development', 'systematic-debugging')
$optionalWorkflow = @('requesting-code-review', 'receiving-code-review', 'verification-before-completion')

$pass = 0
$fail = 0
$warn = 0

function Check-Path {
  param([string]$Label, [string]$Path, [bool]$Required = $true)
  if (Test-Path -LiteralPath $Path) {
    Write-Host "[OK] $Label"
    $script:pass++
  } elseif ($Required) {
    Write-Host "[FAIL] $Label -> $Path" -ForegroundColor Red
    $script:fail++
  } else {
    Write-Host "[WARN] $Label -> $Path" -ForegroundColor Yellow
    $script:warn++
  }
}

function Invoke-DeepGate {
  param(
    [string]$Label,
    [string]$ScriptPath,
    [string[]]$Arguments = @()
  )

  if (-not (Test-Path -LiteralPath $ScriptPath)) {
    Write-Host "[WARN] deep gate/$Label -> missing script: $ScriptPath" -ForegroundColor Yellow
    $script:warn++
    return
  }

  $runner = $null
  if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    $runner = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
  } elseif (Get-Command powershell -ErrorAction SilentlyContinue) {
    $runner = (Get-Command powershell -ErrorAction SilentlyContinue).Source
  }

  if (-not $runner) {
    Write-Host "[WARN] deep gate/$Label -> no PowerShell runner found (pwsh/powershell)" -ForegroundColor Yellow
    $script:warn++
    return
  }

  try {
    $argList = @("-NoProfile", "-File", $ScriptPath) + $Arguments
    & $runner @argList | Out-Host
    if ($LASTEXITCODE -eq 0) {
      Write-Host "[OK] deep gate/$Label"
      $script:pass++
    } else {
      Write-Host "[FAIL] deep gate/$Label (exit=$LASTEXITCODE)" -ForegroundColor Red
      $script:fail++
    }
  } catch {
    Write-Host "[FAIL] deep gate/$Label -> $($_.Exception.Message)" -ForegroundColor Red
    $script:fail++
  }
}

Write-Host "=== VCO Codex Health Check ===" -ForegroundColor Cyan
Write-Host "Target: $TargetRoot"

Check-Path -Label "settings.json" -Path (Join-Path $TargetRoot 'settings.json')
Check-Path -Label "plugins manifest" -Path (Join-Path $TargetRoot 'config\plugins-manifest.codex.json')
Check-Path -Label "upstream lock" -Path (Join-Path $TargetRoot 'config\upstream-lock.json')
Check-Path -Label "skills lock" -Path (Join-Path $TargetRoot 'config\skills-lock.json')

foreach ($name in $requiredSkills) {
  Check-Path -Label "skill/$name" -Path (Join-Path $TargetRoot "skills\$name\SKILL.md")
}

Check-Path -Label "vibe router script" -Path (Join-Path $TargetRoot "skills\vibe\scripts\router\resolve-pack-route.ps1")
Check-Path -Label "vibe router modules dir" -Path (Join-Path $TargetRoot "skills\vibe\scripts\router\modules")
Check-Path -Label "vibe router core module" -Path (Join-Path $TargetRoot "skills\vibe\scripts\router\modules\00-core-utils.ps1")
Check-Path -Label "vibe memory governance config" -Path (Join-Path $TargetRoot "skills\vibe\config\memory-governance.json")
Check-Path -Label "vibe data scale overlay config" -Path (Join-Path $TargetRoot "skills\vibe\config\data-scale-overlay.json")
Check-Path -Label "vibe quality debt overlay config" -Path (Join-Path $TargetRoot "skills\vibe\config\quality-debt-overlay.json")
Check-Path -Label "vibe framework interop overlay config" -Path (Join-Path $TargetRoot "skills\vibe\config\framework-interop-overlay.json")
Check-Path -Label "vibe ml lifecycle overlay config" -Path (Join-Path $TargetRoot "skills\vibe\config\ml-lifecycle-overlay.json")
Check-Path -Label "vibe python clean code overlay config" -Path (Join-Path $TargetRoot "skills\vibe\config\python-clean-code-overlay.json")
Check-Path -Label "vibe system design overlay config" -Path (Join-Path $TargetRoot "skills\vibe\config\system-design-overlay.json")
Check-Path -Label "vibe cuda kernel overlay config" -Path (Join-Path $TargetRoot "skills\vibe\config\cuda-kernel-overlay.json")
Check-Path -Label "vibe observability policy config" -Path (Join-Path $TargetRoot "skills\vibe\config\observability-policy.json")
Check-Path -Label "vibe ai rerank policy config" -Path (Join-Path $TargetRoot "skills\vibe\config\ai-rerank-policy.json")

foreach ($name in $requiredWorkflow) {
  Check-Path -Label "workflow skill/$name" -Path (Join-Path $TargetRoot "skills\$name\SKILL.md")
}

if ($Profile -eq 'full') {
  foreach ($name in $optionalWorkflow) {
    Check-Path -Label "optional workflow skill/$name" -Path (Join-Path $TargetRoot "skills\$name\SKILL.md") -Required:$false
  }
}

Check-Path -Label "rules/common" -Path (Join-Path $TargetRoot 'rules\common\agents.md')
Check-Path -Label "hooks/write-guard.js" -Path (Join-Path $TargetRoot 'hooks\write-guard.js')
Check-Path -Label "mcp template" -Path (Join-Path $TargetRoot 'mcp\servers.template.json')

if (Get-Command npm -ErrorAction SilentlyContinue) {
  Write-Host "[OK] npm"
  $pass++
} else {
  Write-Host "[WARN] npm not found (needed for claude-flow)" -ForegroundColor Yellow
  $warn++
}

if ($Deep) {
  Write-Host ""
  Write-Host "=== Deep Verification ===" -ForegroundColor Cyan
  $repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  $verifyRoot = Join-Path $repoRoot "scripts\verify"
  if (-not (Test-Path -LiteralPath $verifyRoot)) {
    Write-Host "[WARN] deep verification skipped (scripts/verify not found at $verifyRoot)" -ForegroundColor Yellow
    $warn++
  } else {
    Invoke-DeepGate -Label "vibe-pack-regression-matrix" -ScriptPath (Join-Path $verifyRoot "vibe-pack-regression-matrix.ps1")
    Invoke-DeepGate -Label "vibe-offline-skills-gate" -ScriptPath (Join-Path $verifyRoot "vibe-offline-skills-gate.ps1")
    Invoke-DeepGate -Label "vibe-router-contract-gate" -ScriptPath (Join-Path $verifyRoot "vibe-router-contract-gate.ps1")
    Invoke-DeepGate -Label "vibe-routing-stability-gate-strict" -ScriptPath (Join-Path $verifyRoot "vibe-routing-stability-gate.ps1") -Arguments @("-Strict")
    Invoke-DeepGate -Label "vibe-config-parity-gate" -ScriptPath (Join-Path $verifyRoot "vibe-config-parity-gate.ps1")
    Invoke-DeepGate -Label "vibe-observability-gate" -ScriptPath (Join-Path $verifyRoot "vibe-observability-gate.ps1")
    Invoke-DeepGate -Label "vibe-ai-rerank-gate" -ScriptPath (Join-Path $verifyRoot "vibe-ai-rerank-gate.ps1")
  }
}

Write-Host ""
Write-Host "Result: $pass passed, $fail failed, $warn warnings"
if ($fail -gt 0) { exit 1 }
