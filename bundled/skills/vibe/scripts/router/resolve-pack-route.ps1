param(
    [Parameter(Mandatory = $true)]
    [string]$Prompt,
    [ValidateSet("M", "L", "XL")]
    [string]$Grade = "M",
    [ValidateSet("planning", "coding", "review", "debug", "research")]
    [string]$TaskType = "planning",
    [string]$RequestedSkill
)

$ErrorActionPreference = "Stop"
$routerModuleRoot = Join-Path $PSScriptRoot "modules"
$routerModules = @(
    "00-core-utils.ps1",
    "10-observability.ps1",
    "20-routing-rules.ps1",
    "30-openspec.ps1",
    "31-gsd-overlay.ps1",
    "32-prompt-overlay.ps1",
    "33-memory-governance.ps1",
    "34-data-scale-overlay.ps1",
    "35-quality-debt-overlay.ps1",
    "36-framework-interop-overlay.ps1",
    "37-ml-lifecycle-overlay.ps1",
    "38-python-clean-code-overlay.ps1",
    "39-system-design-overlay.ps1",
    "40-cuda-kernel-overlay.ps1",
    "41-candidate-selection.ps1",
    "42-ai-rerank-overlay.ps1"
)

foreach ($routerModule in $routerModules) {
    $routerModulePath = Join-Path $routerModuleRoot $routerModule
    if (-not (Test-Path -LiteralPath $routerModulePath)) {
        throw "Router module missing: $routerModulePath"
    }
    . $routerModulePath
}
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$configRoot = Join-Path $repoRoot "config"

$packManifestPath = Join-Path $configRoot "pack-manifest.json"
$aliasMapPath = Join-Path $configRoot "skill-alias-map.json"
$thresholdPath = Join-Path $configRoot "router-thresholds.json"
$skillKeywordIndexPath = Join-Path $configRoot "skill-keyword-index.json"
$routingRulesPath = Join-Path $configRoot "skill-routing-rules.json"
$openSpecPolicyPath = Join-Path $configRoot "openspec-policy.json"
$gsdOverlayPolicyPath = Join-Path $configRoot "gsd-overlay.json"
$promptOverlayPolicyPath = Join-Path $configRoot "prompt-overlay.json"
$memoryGovernancePolicyPath = Join-Path $configRoot "memory-governance.json"
$dataScaleOverlayPolicyPath = Join-Path $configRoot "data-scale-overlay.json"
$qualityDebtOverlayPolicyPath = Join-Path $configRoot "quality-debt-overlay.json"
$frameworkInteropOverlayPolicyPath = Join-Path $configRoot "framework-interop-overlay.json"
$mlLifecycleOverlayPolicyPath = Join-Path $configRoot "ml-lifecycle-overlay.json"
$pythonCleanCodeOverlayPolicyPath = Join-Path $configRoot "python-clean-code-overlay.json"
$systemDesignOverlayPolicyPath = Join-Path $configRoot "system-design-overlay.json"
$cudaKernelOverlayPolicyPath = Join-Path $configRoot "cuda-kernel-overlay.json"
$observabilityPolicyPath = Join-Path $configRoot "observability-policy.json"
$aiRerankPolicyPath = Join-Path $configRoot "ai-rerank-policy.json"

$packManifest = Get-Content -LiteralPath $packManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$aliasMap = Get-Content -LiteralPath $aliasMapPath -Raw -Encoding UTF8 | ConvertFrom-Json
$thresholds = Get-Content -LiteralPath $thresholdPath -Raw -Encoding UTF8 | ConvertFrom-Json
$skillKeywordIndex = if (Test-Path -LiteralPath $skillKeywordIndexPath) {
    Get-Content -LiteralPath $skillKeywordIndexPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    $null
}
$routingRules = if (Test-Path -LiteralPath $routingRulesPath) {
    Get-Content -LiteralPath $routingRulesPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    $null
}
$openSpecPolicy = if (Test-Path -LiteralPath $openSpecPolicyPath) {
    Get-Content -LiteralPath $openSpecPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    $null
}
$gsdOverlayPolicy = if (Test-Path -LiteralPath $gsdOverlayPolicyPath) {
    Get-Content -LiteralPath $gsdOverlayPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    $null
}
$promptOverlayPolicy = if (Test-Path -LiteralPath $promptOverlayPolicyPath) {
    Get-Content -LiteralPath $promptOverlayPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    $null
}
$memoryGovernancePolicy = if (Test-Path -LiteralPath $memoryGovernancePolicyPath) {
    Get-Content -LiteralPath $memoryGovernancePolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    $null
}
$dataScaleOverlayPolicy = if (Test-Path -LiteralPath $dataScaleOverlayPolicyPath) {
    Get-Content -LiteralPath $dataScaleOverlayPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    $null
}
$qualityDebtOverlayPolicy = if (Test-Path -LiteralPath $qualityDebtOverlayPolicyPath) {
    Get-Content -LiteralPath $qualityDebtOverlayPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    $null
}
$frameworkInteropOverlayPolicy = if (Test-Path -LiteralPath $frameworkInteropOverlayPolicyPath) {
    Get-Content -LiteralPath $frameworkInteropOverlayPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    $null
}
$mlLifecycleOverlayPolicy = if (Test-Path -LiteralPath $mlLifecycleOverlayPolicyPath) {
    Get-Content -LiteralPath $mlLifecycleOverlayPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    $null
}
$pythonCleanCodeOverlayPolicy = if (Test-Path -LiteralPath $pythonCleanCodeOverlayPolicyPath) {
    Get-Content -LiteralPath $pythonCleanCodeOverlayPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    $null
}
$systemDesignOverlayPolicy = if (Test-Path -LiteralPath $systemDesignOverlayPolicyPath) {
    Get-Content -LiteralPath $systemDesignOverlayPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    $null
}
$cudaKernelOverlayPolicy = if (Test-Path -LiteralPath $cudaKernelOverlayPolicyPath) {
    Get-Content -LiteralPath $cudaKernelOverlayPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    $null
}
$observabilityPolicy = if (Test-Path -LiteralPath $observabilityPolicyPath) {
    try {
        Get-Content -LiteralPath $observabilityPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        $null
    }
} else {
    $null
}
$aiRerankPolicy = if (Test-Path -LiteralPath $aiRerankPolicyPath) {
    try {
        Get-Content -LiteralPath $aiRerankPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        $null
    }
} else {
    $null
}

$weights = $thresholds.weights
$rules = $thresholds.safety
$th = $thresholds.thresholds
$weightSkillSignal = if ($weights.skill_keyword_signal -ne $null) { [double]$weights.skill_keyword_signal } else { 0.25 }
$candidateSelectionConfig = if ($thresholds.candidate_selection) { $thresholds.candidate_selection } else { $null }
$minTopGap = if ($th.min_top1_top2_gap -ne $null) { [double]$th.min_top1_top2_gap } else { 0.0 }
$minCandidateSignalForConfirmOverride = if ($th.min_candidate_signal_for_confirm_override -ne $null) { [double]$th.min_candidate_signal_for_confirm_override } else { 0.0 }

$aliasResult = Resolve-Alias -Skill $RequestedSkill -AliasMap $aliasMap
$requestedCanonical = [string]$aliasResult.canonical
$promptLower = $Prompt.ToLowerInvariant()
$openSpecAdvice = Get-OpenSpecGovernanceAdvice -PromptLower $promptLower -Grade $Grade -TaskType $TaskType -RequestedCanonical $requestedCanonical -OpenSpecPolicy $openSpecPolicy
$gsdOverlayAdvice = Get-GsdOverlayAdvice -PromptLower $promptLower -Grade $Grade -TaskType $TaskType -GsdOverlayPolicy $gsdOverlayPolicy
$promptOverlayAdvice = Get-PromptOverlayAdvice -PromptLower $promptLower -Grade $Grade -TaskType $TaskType -PromptOverlayPolicy $promptOverlayPolicy
$memoryGovernanceAdvice = Get-MemoryGovernanceAdvice -Grade $Grade -TaskType $TaskType -MemoryGovernancePolicy $memoryGovernancePolicy

$packResults = @()
foreach ($pack in $packManifest.packs) {
    $gradeAllowed = ($pack.grade_allow -contains $Grade)
    $taskAllowed = ($pack.task_allow -contains $TaskType)

    if ($rules.enforce_grade_boundary -and -not $gradeAllowed) { continue }
    if ($rules.enforce_task_boundary -and -not $taskAllowed) { continue }

    $intent = Get-IntentScore -PromptLower $promptLower -PackId $pack.id -Candidates $pack.skill_candidates
    $trigger = Get-TriggerKeywordScore -PromptLower $promptLower -Keywords $pack.trigger_keywords
    $workspace = Get-WorkspaceSignalScore -PromptLower $promptLower -RequestedCanonical $requestedCanonical -Candidates $pack.skill_candidates
    $skillSignal = Get-PackSkillSignalScore -PromptLower $promptLower -Candidates $pack.skill_candidates -SkillKeywordIndex $skillKeywordIndex
    $prior = [double]$pack.priority / 100.0
    $conflictInverse = if ($gradeAllowed -and $taskAllowed) { 1.0 } else { 0.0 }

    $score =
        ([double]$weights.intent_match * $intent) +
        ([double]$weights.trigger_keyword_match * $trigger) +
        ([double]$weights.workspace_signal_match * $workspace) +
        ($weightSkillSignal * $skillSignal) +
        ([double]$weights.recent_success_prior * $prior) +
        ([double]$weights.conflict_penalty_inverse * $conflictInverse)

    $selection = Select-PackCandidate -PromptLower $promptLower -Candidates $pack.skill_candidates -TaskType $TaskType -RequestedCanonical $requestedCanonical -SkillKeywordIndex $skillKeywordIndex -RoutingRules $routingRules -Pack $pack -CandidateSelectionConfig $candidateSelectionConfig
    $candidateSignal = ([double]$selection.score * 0.75) + ([double]$selection.top1_top2_gap * 0.25)
    $candidateSignal = [Math]::Round([Math]::Min(1.0, [Math]::Max(0.0, $candidateSignal)), 4)

    $packResults += [pscustomobject]@{
        pack_id = [string]$pack.id
        score = [Math]::Round($score, 4)
        intent = [Math]::Round($intent, 4)
        trigger = [Math]::Round($trigger, 4)
        workspace = [Math]::Round($workspace, 4)
        skill_signal = [Math]::Round($skillSignal, 4)
        prior = [Math]::Round($prior, 4)
        grade_allowed = $gradeAllowed
        task_allowed = $taskAllowed
        candidates = @($pack.skill_candidates)
        selected_candidate = $selection.selected
        candidate_selection_reason = $selection.reason
        candidate_selection_score = [Math]::Round([double]$selection.score, 4)
        candidate_ranking = @($selection.ranking)
        candidate_top1_top2_gap = [Math]::Round([double]$selection.top1_top2_gap, 4)
        candidate_signal = $candidateSignal
        candidate_filtered_out_by_task = @($selection.filtered_out_by_task)
    }
}

$ranked = $packResults | Sort-Object -Property @(
    @{ Expression = "score"; Descending = $true },
    @{ Expression = "pack_id"; Descending = $false }
)
$top = $ranked | Select-Object -First 1
$confidence = if ($top) { [double]$top.score } else { 0.0 }

# Soft-migration behavior: explicit legacy/canonical skill request mapped to a pack
# is treated as a strong routing signal to avoid unnecessary legacy fallback.
if ($top -and $requestedCanonical -and ($top.candidates -contains $requestedCanonical)) {
    $confidence = [Math]::Max($confidence, ([double]$th.confirm_required + 0.05))
}

$topGap = if ($top) { [double]$top.candidate_top1_top2_gap } else { 0.0 }
$candidateSignal = if ($top) { [double]$top.candidate_signal } else { 0.0 }
$canOverrideLegacyFallback = $false
if ($top -and ($top.candidate_selection_reason -in @("keyword_ranked", "requested_skill")) -and ($candidateSignal -ge $minCandidateSignalForConfirmOverride)) {
    $canOverrideLegacyFallback = $true
}
$routeReason = ""
if (-not $top) {
    $routeMode = "legacy_fallback"
    $routeReason = "no_eligible_pack"
} elseif ($confidence -lt [double]$th.fallback_to_legacy_below) {
    if ($canOverrideLegacyFallback) {
        $routeMode = "confirm_required"
        $routeReason = "candidate_signal_override"
        $confidence = [Math]::Max($confidence, [double]$th.confirm_required)
    } else {
        $routeMode = "legacy_fallback"
        $routeReason = "confidence_below_fallback"
    }
} elseif ($topGap -lt $minTopGap) {
    $routeMode = "confirm_required"
    $routeReason = "top_candidates_too_close"
} elseif ($confidence -lt [double]$th.auto_route) {
    $routeMode = "confirm_required"
    $routeReason = "confidence_requires_confirmation"
} else {
    $routeMode = "pack_overlay"
    $routeReason = "auto_route"
}

$aiRerankAdvice = Get-AiRerankAdvice `
    -PromptText $Prompt `
    -PromptLower $promptLower `
    -Grade $Grade `
    -TaskType $TaskType `
    -RouteMode $routeMode `
    -RequestedCanonical $requestedCanonical `
    -Ranked $ranked `
    -TopGap $topGap `
    -Confidence $confidence `
    -AiRerankPolicy $aiRerankPolicy

$aiRerankRouteOverride = [bool]($aiRerankAdvice -and $aiRerankAdvice.route_override_applied)
$effectiveTop = $top
if ($aiRerankRouteOverride -and $aiRerankAdvice -and $aiRerankAdvice.override_target_pack) {
    $overridePackId = [string]$aiRerankAdvice.override_target_pack
    $overrideTop = $ranked | Where-Object { [string]$_.pack_id -eq $overridePackId } | Select-Object -First 1
    if ($overrideTop) {
        $effectiveTop = $overrideTop
        if ($routeMode -eq "pack_overlay") {
            $routeReason = "ai_rerank_override"
        }
    }
}

$promptOverlayRouteOverride = $false
if ($routeMode -eq "pack_overlay" -and $promptOverlayAdvice -and $promptOverlayAdvice.scope_applicable -and $promptOverlayAdvice.confirm_required) {
    $routeMode = "confirm_required"
    $routeReason = "prompt_overlay_confirm_required"
    $confidence = [Math]::Max($confidence, [double]$th.confirm_required)
    $promptOverlayRouteOverride = $true
}

$dataScaleAdvice = Get-DataScaleOverlayAdvice `
    -Prompt $Prompt `
    -PromptLower $promptLower `
    -Grade $Grade `
    -TaskType $TaskType `
    -RouteMode $routeMode `
    -SelectedPackId $(if ($effectiveTop) { [string]$effectiveTop.pack_id } else { $null }) `
    -SelectedSkill $(if ($effectiveTop) { [string]$effectiveTop.selected_candidate } else { $null }) `
    -PackCandidates $(if ($effectiveTop) { @($effectiveTop.candidates) } else { @() }) `
    -DataScaleOverlayPolicy $dataScaleOverlayPolicy

$dataScaleRouteOverride = $false
$effectiveSelectedSkill = if ($effectiveTop) { [string]$effectiveTop.selected_candidate } else { $null }
$effectiveSelectionReason = if ($effectiveTop) { [string]$effectiveTop.candidate_selection_reason } else { $null }
$effectiveSelectionScore = if ($effectiveTop) { [double]$effectiveTop.candidate_selection_score } else { 0.0 }

if ($effectiveTop -and $dataScaleAdvice -and $dataScaleAdvice.scope_applicable -and $dataScaleAdvice.override_candidate_allowed -and $dataScaleAdvice.recommended_skill -and ($dataScaleAdvice.recommended_skill -ne $effectiveSelectedSkill)) {
    if ($dataScaleAdvice.auto_override) {
        $effectiveSelectedSkill = [string]$dataScaleAdvice.recommended_skill
        $effectiveSelectionReason = "data_scale_overlay_override"
        $effectiveSelectionScore = [Math]::Round([Math]::Max([double]$effectiveSelectionScore, [double]$dataScaleAdvice.confidence), 4)
        $dataScaleRouteOverride = $true
        if ($routeMode -eq "pack_overlay") {
            $routeReason = "data_scale_auto_override"
        }
    } elseif ($dataScaleAdvice.confirm_required -and $routeMode -eq "pack_overlay") {
        $routeMode = "confirm_required"
        $routeReason = "data_scale_confirm_required"
        $confidence = [Math]::Max($confidence, [double]$th.confirm_required)
        $dataScaleRouteOverride = $true
    }
}

$qualityDebtAdvice = Get-QualityDebtOverlayAdvice `
    -Prompt $Prompt `
    -PromptLower $promptLower `
    -Grade $Grade `
    -TaskType $TaskType `
    -RouteMode $routeMode `
    -SelectedPackId $(if ($effectiveTop) { [string]$effectiveTop.pack_id } else { $null }) `
    -SelectedSkill $effectiveSelectedSkill `
    -PackCandidates $(if ($effectiveTop) { @($effectiveTop.candidates) } else { @() }) `
    -QualityDebtOverlayPolicy $qualityDebtOverlayPolicy

$frameworkInteropAdvice = Get-FrameworkInteropOverlayAdvice `
    -Prompt $Prompt `
    -PromptLower $promptLower `
    -Grade $Grade `
    -TaskType $TaskType `
    -RouteMode $routeMode `
    -SelectedPackId $(if ($effectiveTop) { [string]$effectiveTop.pack_id } else { $null }) `
    -SelectedSkill $effectiveSelectedSkill `
    -PackCandidates $(if ($effectiveTop) { @($effectiveTop.candidates) } else { @() }) `
    -FrameworkInteropOverlayPolicy $frameworkInteropOverlayPolicy

$mlLifecycleAdvice = Get-MlLifecycleOverlayAdvice `
    -Prompt $Prompt `
    -PromptLower $promptLower `
    -Grade $Grade `
    -TaskType $TaskType `
    -RouteMode $routeMode `
    -SelectedPackId $(if ($effectiveTop) { [string]$effectiveTop.pack_id } else { $null }) `
    -SelectedSkill $effectiveSelectedSkill `
    -PackCandidates $(if ($effectiveTop) { @($effectiveTop.candidates) } else { @() }) `
    -MlLifecycleOverlayPolicy $mlLifecycleOverlayPolicy

$pythonCleanCodeAdvice = Get-PythonCleanCodeAdvice `
    -Prompt $Prompt `
    -PromptLower $promptLower `
    -Grade $Grade `
    -TaskType $TaskType `
    -RouteMode $routeMode `
    -SelectedPackId $(if ($effectiveTop) { [string]$effectiveTop.pack_id } else { $null }) `
    -SelectedSkill $effectiveSelectedSkill `
    -PackCandidates $(if ($effectiveTop) { @($effectiveTop.candidates) } else { @() }) `
    -PythonCleanCodeOverlayPolicy $pythonCleanCodeOverlayPolicy

$systemDesignAdvice = Get-SystemDesignOverlayAdvice `
    -Prompt $Prompt `
    -PromptLower $promptLower `
    -Grade $Grade `
    -TaskType $TaskType `
    -RouteMode $routeMode `
    -SelectedPackId $(if ($effectiveTop) { [string]$effectiveTop.pack_id } else { $null }) `
    -SelectedSkill $effectiveSelectedSkill `
    -PackCandidates $(if ($effectiveTop) { @($effectiveTop.candidates) } else { @() }) `
    -SystemDesignOverlayPolicy $systemDesignOverlayPolicy

$cudaKernelAdvice = Get-CudaKernelOverlayAdvice `
    -Prompt $Prompt `
    -PromptLower $promptLower `
    -Grade $Grade `
    -TaskType $TaskType `
    -RouteMode $routeMode `
    -SelectedPackId $(if ($effectiveTop) { [string]$effectiveTop.pack_id } else { $null }) `
    -SelectedSkill $effectiveSelectedSkill `
    -PackCandidates $(if ($effectiveTop) { @($effectiveTop.candidates) } else { @() }) `
    -CudaKernelOverlayPolicy $cudaKernelOverlayPolicy

$result = [pscustomobject]@{
    prompt = $Prompt
    grade = $Grade
    task_type = $TaskType
    route_mode = $routeMode
    route_reason = $routeReason
    confidence = [Math]::Round($confidence, 4)
    top1_top2_gap = [Math]::Round($topGap, 4)
    candidate_signal = [Math]::Round($candidateSignal, 4)
    thresholds = [pscustomobject]@{
        auto_route = [double]$th.auto_route
        confirm_required = [double]$th.confirm_required
        fallback_to_legacy_below = [double]$th.fallback_to_legacy_below
        min_top1_top2_gap = [double]$minTopGap
        min_candidate_signal_for_confirm_override = [double]$minCandidateSignalForConfirmOverride
    }
    alias = $aliasResult
    openspec_advice = $openSpecAdvice
    gsd_overlay_advice = $gsdOverlayAdvice
    prompt_overlay_advice = $promptOverlayAdvice
    memory_governance_advice = $memoryGovernanceAdvice
    prompt_overlay_route_override = $promptOverlayRouteOverride
    ai_rerank_advice = $aiRerankAdvice
    ai_rerank_route_override = $aiRerankRouteOverride
    data_scale_advice = $dataScaleAdvice
    data_scale_route_override = $dataScaleRouteOverride
    quality_debt_advice = $qualityDebtAdvice
    framework_interop_advice = $frameworkInteropAdvice
    ml_lifecycle_advice = $mlLifecycleAdvice
    python_clean_code_advice = $pythonCleanCodeAdvice
    system_design_advice = $systemDesignAdvice
    cuda_kernel_advice = $cudaKernelAdvice
    selected = if ($effectiveTop) {
        [pscustomobject]@{
            pack_id = $effectiveTop.pack_id
            skill = $effectiveSelectedSkill
            selection_reason = $effectiveSelectionReason
            selection_score = $effectiveSelectionScore
            top1_top2_gap = $effectiveTop.candidate_top1_top2_gap
            candidate_signal = $effectiveTop.candidate_signal
            filtered_out_by_task = @($effectiveTop.candidate_filtered_out_by_task)
        }
    } else {
        $null
    }
    ranked = @($ranked | Select-Object -First 3)
}

$null = Write-ObservabilityRouteEvent -PromptText $Prompt -Result $result -ObservabilityPolicy $observabilityPolicy -RepoRoot $repoRoot

$result | ConvertTo-Json -Depth 10

