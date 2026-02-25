param(
    [switch]$SkipPrecheck,
    [switch]$EnableEmergencyRollbackOnFailure,
    [ValidateSet("off", "shadow", "soft-lxl-planning", "strict-lxl-planning")]
    [string]$RollbackStage = "shadow",
    [switch]$MainOnly,
    [string]$OutputDirectory
)

$ErrorActionPreference = "Stop"

function Resolve-PowerShellExe {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        return $pwsh.Source
    }

    $powershell = Get-Command powershell -ErrorAction SilentlyContinue
    if ($powershell) {
        return $powershell.Source
    }

    throw "No PowerShell executable found in PATH (pwsh/powershell)."
}

function Invoke-ScriptStep {
    param(
        [string]$Name,
        [string]$ScriptPath,
        [string[]]$Arguments = @(),
        [string]$PowerShellExe
    )

    $start = Get-Date
    Write-Host "=== Step: $Name ==="
    Write-Host "$PowerShellExe -NoProfile -File $ScriptPath $($Arguments -join ' ')"

    $rawOutput = @()
    $exitCode = 0
    try {
        $rawOutput = & $PowerShellExe -NoProfile -File $ScriptPath @Arguments 2>&1
        $exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
    } catch {
        $exitCode = -1
        $rawOutput += $_.Exception.Message
    }

    $output = @()
    foreach ($line in $rawOutput) {
        $text = [string]$line
        $output += $text
        Write-Host $text
    }

    $end = Get-Date
    $duration = [Math]::Round(($end - $start).TotalSeconds, 3)
    $passed = ($exitCode -eq 0)

    if ($passed) {
        Write-Host "[PASS] $Name`n"
    } else {
        Write-Host "[FAIL] $Name (exit_code=$exitCode)`n" -ForegroundColor Red
    }

    return [pscustomobject]@{
        name = $Name
        script = $ScriptPath
        arguments = $Arguments
        started_at = $start.ToString("s")
        ended_at = $end.ToString("s")
        duration_sec = $duration
        exit_code = $exitCode
        passed = $passed
        output_excerpt = @($output | Select-Object -First 80)
    }
}

function Read-PolicySummary {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $policy = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    return [pscustomobject]@{
        path = $Path
        mode = $policy.mode
        preserve_routing_assignment = [bool]$policy.preserve_routing_assignment
        profile_by_grade = $policy.profile_by_grade
        required_task_types_by_profile = $policy.required_task_types_by_profile
        soft_confirm_scope = $policy.soft_confirm_scope
        updated = $policy.updated
    }
}

function Write-ReportArtifacts {
    param(
        [object]$Summary,
        [string]$Directory
    )

    New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $jsonPath = Join-Path $Directory "openspec-soft-rollout-publish-$stamp.json"
    $mdPath = Join-Path $Directory "openspec-soft-rollout-publish-$stamp.md"

    $Summary | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

    $lines = @()
    $lines += "# OpenSpec Soft Rollout Publish Report"
    $lines += ""
    $lines += "- generated_at: ``$($Summary.generated_at)``"
    $lines += "- result: ``$($Summary.result)``"
    $lines += "- target_stage: ``$($Summary.target_stage)``"
    $lines += "- precheck_passed: ``$($Summary.precheck_passed)``"
    $lines += "- postcheck_passed: ``$($Summary.postcheck_passed)``"
    $lines += "- rollback_executed: ``$($Summary.rollback_executed)``"
    $lines += "- rollback_succeeded: ``$($Summary.rollback_succeeded)``"
    $lines += ""
    $lines += "## Prechecks"
    $lines += ""
    foreach ($row in $Summary.prechecks) {
        $lines += "- ``$($row.name)``: passed=``$($row.passed)`` exit=``$($row.exit_code)``"
    }
    $lines += ""
    $lines += "## Postchecks"
    $lines += ""
    foreach ($row in $Summary.postchecks) {
        $lines += "- ``$($row.name)``: passed=``$($row.passed)`` exit=``$($row.exit_code)``"
    }
    $lines += ""
    $lines += "## Switch"
    $lines += ""
    $lines += "- ``$($Summary.switch_step.name)``: passed=``$($Summary.switch_step.passed)`` exit=``$($Summary.switch_step.exit_code)``"
    if ($Summary.rollback_step) {
        $lines += "- ``$($Summary.rollback_step.name)``: passed=``$($Summary.rollback_step.passed)`` exit=``$($Summary.rollback_step.exit_code)``"
    }

    $lines -join "`n" | Set-Content -LiteralPath $mdPath -Encoding UTF8

    return [pscustomobject]@{
        json = $jsonPath
        markdown = $mdPath
    }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$powerShellExe = Resolve-PowerShellExe

$mainPolicyPath = Join-Path $repoRoot "config/openspec-policy.json"
$policyBefore = Read-PolicySummary -Path $mainPolicyPath

$prechecks = @()
if (-not $SkipPrecheck) {
    $prechecks += Invoke-ScriptStep `
        -Name "pre.pack-regression-matrix" `
        -ScriptPath (Join-Path $repoRoot "scripts/verify/vibe-pack-regression-matrix.ps1") `
        -PowerShellExe $powerShellExe

    $prechecks += Invoke-ScriptStep `
        -Name "pre.routing-stability-strict" `
        -ScriptPath (Join-Path $repoRoot "scripts/verify/vibe-routing-stability-gate.ps1") `
        -Arguments @("-Strict") `
        -PowerShellExe $powerShellExe
}

$precheckPassed = ($prechecks.Count -eq 0) -or (($prechecks | Where-Object { -not $_.passed }).Count -eq 0)

$switchArgs = @("-Stage", "soft-lxl-planning")
if ($MainOnly) {
    $switchArgs += "-MainOnly"
}

$switchStep = $null
$postchecks = @()
$rollbackStep = $null

if ($precheckPassed) {
    $switchStep = Invoke-ScriptStep `
        -Name "switch.soft-lxl-planning" `
        -ScriptPath (Join-Path $repoRoot "scripts/governance/set-openspec-rollout.ps1") `
        -Arguments $switchArgs `
        -PowerShellExe $powerShellExe

    if ($switchStep.passed) {
        $postchecks += Invoke-ScriptStep `
            -Name "post.pack-regression-matrix" `
            -ScriptPath (Join-Path $repoRoot "scripts/verify/vibe-pack-regression-matrix.ps1") `
            -PowerShellExe $powerShellExe

        $postchecks += Invoke-ScriptStep `
            -Name "post.routing-stability-strict" `
            -ScriptPath (Join-Path $repoRoot "scripts/verify/vibe-routing-stability-gate.ps1") `
            -Arguments @("-Strict") `
            -PowerShellExe $powerShellExe

        $postchecks += Invoke-ScriptStep `
            -Name "post.openspec-governance-gate" `
            -ScriptPath (Join-Path $repoRoot "scripts/verify/vibe-openspec-governance-gate.ps1") `
            -PowerShellExe $powerShellExe
    }
}

$postcheckPassed = ($postchecks.Count -gt 0) -and (($postchecks | Where-Object { -not $_.passed }).Count -eq 0)

if ($precheckPassed -and $switchStep -and $switchStep.passed -and -not $postcheckPassed -and $EnableEmergencyRollbackOnFailure) {
    $rollbackArgs = @("-Stage", $RollbackStage)
    if ($MainOnly) {
        $rollbackArgs += "-MainOnly"
    }

    $rollbackStep = Invoke-ScriptStep `
        -Name "rollback.$RollbackStage" `
        -ScriptPath (Join-Path $repoRoot "scripts/governance/set-openspec-rollout.ps1") `
        -Arguments $rollbackArgs `
        -PowerShellExe $powerShellExe
}

$policyAfter = Read-PolicySummary -Path $mainPolicyPath

$result = "failed"
if (-not $precheckPassed) {
    $result = "precheck_failed"
} elseif (-not $switchStep -or -not $switchStep.passed) {
    $result = "switch_failed"
} elseif (-not $postcheckPassed) {
    $result = "postcheck_failed"
} else {
    $result = "passed"
}

$summary = [pscustomobject]@{
    generated_at = (Get-Date).ToString("s")
    result = $result
    target_stage = "soft-lxl-planning"
    precheck_skipped = [bool]$SkipPrecheck
    precheck_passed = [bool]$precheckPassed
    postcheck_passed = [bool]$postcheckPassed
    emergency_rollback_enabled = [bool]$EnableEmergencyRollbackOnFailure
    rollback_requested_stage = $RollbackStage
    rollback_executed = [bool]($null -ne $rollbackStep)
    rollback_succeeded = [bool]($null -ne $rollbackStep -and $rollbackStep.passed)
    main_only = [bool]$MainOnly
    policy_before = $policyBefore
    policy_after = $policyAfter
    prechecks = $prechecks
    switch_step = $switchStep
    postchecks = $postchecks
    rollback_step = $rollbackStep
}

if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $repoRoot "outputs/governance"
}
$artifacts = Write-ReportArtifacts -Summary $summary -Directory $OutputDirectory

$summaryWithArtifacts = [pscustomobject]@{
    summary = $summary
    artifacts = $artifacts
}
$summaryWithArtifacts | ConvertTo-Json -Depth 30

switch ($result) {
    "passed" { exit 0 }
    "precheck_failed" { exit 10 }
    "switch_failed" { exit 11 }
    default { exit 12 }
}
