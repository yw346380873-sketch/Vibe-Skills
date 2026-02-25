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

function Normalize-Key {
    param([string]$InputText)
    if (-not $InputText) { return "" }
    return ($InputText.Trim().Replace("\", "/")).ToLowerInvariant()
}

function Resolve-Alias {
    param(
        [string]$Skill,
        [object]$AliasMap
    )

    if (-not $Skill) {
        return [pscustomobject]@{
            input = $null
            normalized = $null
            canonical = $null
            alias_hit = $false
        }
    }

    $normalized = Normalize-Key -InputText $Skill
    $canonical = $normalized
    $aliasHit = $false

    $keys = $AliasMap.aliases.PSObject.Properties.Name
    if ($keys -contains $normalized) {
        $canonical = [string]$AliasMap.aliases.$normalized
        $aliasHit = $true
    } else {
        $leaf = $normalized.Split("/")[-1]
        if ($keys -contains $leaf) {
            $canonical = [string]$AliasMap.aliases.$leaf
            $aliasHit = $true
        } elseif ($leaf -match "^(.+)/skill\.md$") {
            $trimmed = $Matches[1]
            if ($keys -contains $trimmed) {
                $canonical = [string]$AliasMap.aliases.$trimmed
                $aliasHit = $true
            }
        }
    }

    return [pscustomobject]@{
        input = $Skill
        normalized = $normalized
        canonical = $canonical
        alias_hit = $aliasHit
    }
}

function Test-KeywordHit {
    param(
        [string]$PromptLower,
        [string]$Keyword
    )

    if (-not $PromptLower -or -not $Keyword) { return $false }
    $needle = $Keyword.ToLowerInvariant()
    if (-not $needle) { return $false }

    # CJK terms are best handled as substring matches.
    if ([Regex]::IsMatch($needle, "[\p{IsCJKUnifiedIdeographs}]")) {
        return $PromptLower.Contains($needle)
    }

    # ASCII-like terms should match on token boundaries to reduce cross-pack noise.
    if ([Regex]::IsMatch($needle, "[a-z0-9]")) {
        $escaped = [Regex]::Escape($needle)
        return [Regex]::IsMatch($PromptLower, "(?<![a-z0-9])$escaped(?![a-z0-9])")
    }

    return $PromptLower.Contains($needle)
}

function Get-KeywordRatio {
    param(
        [string]$PromptLower,
        [string[]]$Keywords
    )

    if (-not $Keywords -or $Keywords.Count -eq 0) { return 0.0 }
    $matched = 0
    foreach ($k in $Keywords) {
        if (Test-KeywordHit -PromptLower $PromptLower -Keyword $k) {
            $matched++
        }
    }

    if ($matched -le 0) { return 0.0 }
    $denominator = [Math]::Min([double]$Keywords.Count, 4.0)
    if ($denominator -le 0) { return 0.0 }
    return [Math]::Min(1.0, ($matched / $denominator))
}

function Get-TriggerKeywordScore {
    param(
        [string]$PromptLower,
        [string[]]$Keywords
    )

    return Get-KeywordRatio -PromptLower $PromptLower -Keywords $Keywords
}

function Get-IntentScore {
    param(
        [string]$PromptLower,
        [string]$PackId,
        [string[]]$Candidates
    )

    $score = 0.0
    $packTokens = $PackId.Split("-")
    foreach ($token in $packTokens) {
        if ($token.Length -ge 3 -and (Test-KeywordHit -PromptLower $PromptLower -Keyword $token)) {
            $score += 0.35
        }
    }

    foreach ($c in $Candidates) {
        if (Test-KeywordHit -PromptLower $PromptLower -Keyword $c) {
            $score += 0.25
        }
    }

    return [Math]::Min(1.0, $score)
}

function Get-WorkspaceSignalScore {
    param(
        [string]$PromptLower,
        [string]$RequestedCanonical,
        [string[]]$Candidates
    )

    if ($RequestedCanonical -and ($Candidates -contains $RequestedCanonical)) {
        return 1.0
    }

    $hits = 0
    foreach ($c in $Candidates) {
        if (Test-KeywordHit -PromptLower $PromptLower -Keyword $c) {
            $hits++
        }
    }
    if ($hits -gt 0) { return 0.6 }
    return 0.0
}

function Get-CandidateNameMatchScore {
    param(
        [string]$PromptLower,
        [string]$Candidate
    )

    if (-not $Candidate) { return 0.0 }
    $variants = @(
        $Candidate,
        $Candidate.Replace("-", " "),
        $Candidate.Replace("-", ""),
        $Candidate.Replace("_", " ")
    ) | Select-Object -Unique

    foreach ($v in $variants) {
        if ($v -and (Test-KeywordHit -PromptLower $PromptLower -Keyword $v)) {
            return 1.0
        }
    }

    return 0.0
}

function Get-SkillKeywordScore {
    param(
        [string]$PromptLower,
        [string]$Candidate,
        [object]$SkillKeywordIndex
    )

    if (-not $SkillKeywordIndex -or -not $SkillKeywordIndex.skills) { return 0.0 }
    $keys = @($SkillKeywordIndex.skills.PSObject.Properties.Name)
    if (-not ($keys -contains $Candidate)) { return 0.0 }

    $entry = $SkillKeywordIndex.skills.$Candidate
    if (-not $entry -or -not $entry.keywords) { return 0.0 }

    return Get-KeywordRatio -PromptLower $PromptLower -Keywords @($entry.keywords)
}

function Get-PackSkillSignalScore {
    param(
        [string]$PromptLower,
        [string[]]$Candidates,
        [object]$SkillKeywordIndex
    )

    if (-not $Candidates -or $Candidates.Count -eq 0) { return 0.0 }

    $maxScore = 0.0
    foreach ($candidate in $Candidates) {
        $score = Get-SkillKeywordScore -PromptLower $PromptLower -Candidate $candidate -SkillKeywordIndex $SkillKeywordIndex
        if ([double]$score -gt [double]$maxScore) {
            $maxScore = [double]$score
        }
    }

    return [Math]::Min(1.0, $maxScore)
}

function Get-RoutingRuleForCandidate {
    param(
        [string]$Candidate,
        [object]$RoutingRules
    )

    if (-not $RoutingRules -or -not $RoutingRules.skills -or -not $Candidate) {
        return $null
    }

    $keys = @($RoutingRules.skills.PSObject.Properties.Name)
    if ($keys -contains $Candidate) {
        return $RoutingRules.skills.$Candidate
    }

    return $null
}

function Test-RuleTaskAllowed {
    param(
        [object]$Rule,
        [string]$TaskType
    )

    if (-not $Rule -or -not $Rule.task_allow) { return $true }
    $allowed = @($Rule.task_allow)
    if ($allowed.Count -eq 0) { return $true }
    return ($allowed -contains $TaskType)
}

function Get-CanonicalForTaskHit {
    param(
        [object]$Rule,
        [string]$TaskType
    )

    if (-not $Rule -or -not $Rule.canonical_for_task) { return 0.0 }
    $canonical = @($Rule.canonical_for_task)
    if ($canonical -contains $TaskType) { return 1.0 }
    return 0.0
}

function Get-PackDefaultCandidate {
    param(
        [object]$Pack,
        [string]$TaskType,
        [string[]]$PreferredCandidates,
        [string[]]$AllCandidates
    )

    if (-not $Pack -or -not $Pack.defaults_by_task) { return $null }

    $taskKeys = @($Pack.defaults_by_task.PSObject.Properties.Name)
    if (-not ($taskKeys -contains $TaskType)) { return $null }

    $defaultSkill = [string]$Pack.defaults_by_task.$TaskType
    if (-not $defaultSkill) { return $null }

    if ($PreferredCandidates -and ($PreferredCandidates -contains $defaultSkill)) {
        return $defaultSkill
    }

    if ($AllCandidates -and ($AllCandidates -contains $defaultSkill)) {
        return $defaultSkill
    }

    return $null
}

function Get-OpenSpecTaskId {
    param(
        [string]$PromptLower,
        [string]$Grade,
        [string]$TaskType
    )

    $raw = "{0}|{1}|{2}" -f $Grade, $TaskType, $PromptLower
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($raw)
        $hashBytes = $sha1.ComputeHash($bytes)
        $hash = ($hashBytes | ForEach-Object { $_.ToString("x2") }) -join ""
        if ($hash.Length -ge 12) {
            return $hash.Substring(0, 12)
        }
        return $hash
    } finally {
        $sha1.Dispose()
    }
}

function Get-OpenSpecGovernanceAdvice {
    param(
        [string]$PromptLower,
        [string]$Grade,
        [string]$TaskType,
        [string]$RequestedCanonical,
        [object]$OpenSpecPolicy
    )

    if (-not $OpenSpecPolicy) {
        return [pscustomobject]@{
            enabled = $false
            mode = "off"
            profile = "none"
            task_applicable = $false
            enforcement = "none"
            reason = "policy_missing"
            bypass_due_to_requested_skill = $false
            preserve_routing_assignment = $true
            task_id = $null
            recommended_artifact = $null
            should_upgrade_to_full = $false
            upgrade_trigger_matches = @()
        }
    }

    $mode = if ($OpenSpecPolicy.mode) { [string]$OpenSpecPolicy.mode } else { "off" }
    if ($mode -eq "off") {
        return [pscustomobject]@{
            enabled = $false
            mode = "off"
            profile = "none"
            task_applicable = $false
            enforcement = "none"
            reason = "policy_off"
            bypass_due_to_requested_skill = $false
            preserve_routing_assignment = $true
            task_id = $null
            recommended_artifact = $null
            should_upgrade_to_full = $false
            upgrade_trigger_matches = @()
        }
    }

    $profile = "none"
    if ($OpenSpecPolicy.profile_by_grade) {
        $gradeKeys = @($OpenSpecPolicy.profile_by_grade.PSObject.Properties.Name)
        if ($gradeKeys -contains $Grade) {
            $profile = [string]$OpenSpecPolicy.profile_by_grade.$Grade
        }
    }

    $taskApplicable = $false
    if ($profile -ne "none" -and $OpenSpecPolicy.required_task_types_by_profile) {
        $profileKeys = @($OpenSpecPolicy.required_task_types_by_profile.PSObject.Properties.Name)
        if ($profileKeys -contains $profile) {
            $requiredTasks = @($OpenSpecPolicy.required_task_types_by_profile.$profile)
            $taskApplicable = ($requiredTasks -contains $TaskType)
        }
    }

    $bypassDueToRequestedSkill = $false
    if ($RequestedCanonical -and $OpenSpecPolicy.exemptions -and $OpenSpecPolicy.exemptions.requested_skill_bypass) {
        $bypassDueToRequestedSkill = $true
    }

    $taskId = Get-OpenSpecTaskId -PromptLower $PromptLower -Grade $Grade -TaskType $TaskType
    $recommendedArtifact = $null
    if ($profile -eq "lite") {
        $liteDir = if ($OpenSpecPolicy.m_lite -and $OpenSpecPolicy.m_lite.directory) {
            [string]$OpenSpecPolicy.m_lite.directory
        } else {
            "openspec/micro"
        }
        $recommendedArtifact = "{0}/{1}.md" -f $liteDir.TrimEnd("/"), $taskId
    } elseif ($profile -eq "full") {
        $changesDir = if ($OpenSpecPolicy.full -and $OpenSpecPolicy.full.changes_dir) {
            [string]$OpenSpecPolicy.full.changes_dir
        } else {
            "openspec/changes"
        }
        $recommendedArtifact = "{0}/{1}" -f $changesDir.TrimEnd("/"), $taskId
    }

    $softScopeHit = $true
    if ($OpenSpecPolicy.soft_confirm_scope) {
        $scopeGrades = @()
        $scopeTasks = @()
        if ($OpenSpecPolicy.soft_confirm_scope.grades) {
            $scopeGrades = @($OpenSpecPolicy.soft_confirm_scope.grades)
        }
        if ($OpenSpecPolicy.soft_confirm_scope.task_types) {
            $scopeTasks = @($OpenSpecPolicy.soft_confirm_scope.task_types)
        }

        if ($scopeGrades.Count -gt 0 -and -not ($scopeGrades -contains $Grade)) {
            $softScopeHit = $false
        }
        if ($scopeTasks.Count -gt 0 -and -not ($scopeTasks -contains $TaskType)) {
            $softScopeHit = $false
        }
    }

    $enforcement = "none"
    $reason = "task_not_applicable"
    if ($taskApplicable -and -not $bypassDueToRequestedSkill) {
        if ($profile -eq "lite") {
            $enforcement = "advisory"
            $reason = "m_lite_card"
        } elseif ($profile -eq "full") {
            switch ($mode) {
                "strict" {
                    $enforcement = "required"
                    $reason = "full_required_strict"
                }
                "soft" {
                    if ($softScopeHit) {
                        $enforcement = "confirm_required"
                        $reason = "full_confirm_soft"
                    } else {
                        $enforcement = "advisory"
                        $reason = "full_advisory_soft_outside_scope"
                    }
                }
                default {
                    $enforcement = "advisory"
                    $reason = "full_advisory_shadow"
                }
            }
        } else {
            $enforcement = "advisory"
            $reason = "profile_none"
        }
    } elseif ($bypassDueToRequestedSkill) {
        $reason = "requested_skill_bypass"
    }

    $upgradeMatches = @()
    if ($profile -eq "lite" -and $OpenSpecPolicy.upgrade_triggers) {
        foreach ($trigger in @($OpenSpecPolicy.upgrade_triggers)) {
            if (Test-KeywordHit -PromptLower $PromptLower -Keyword ([string]$trigger)) {
                $upgradeMatches += [string]$trigger
            }
        }
    }

    $preserveRoutingAssignment = $true
    if ($OpenSpecPolicy.preserve_routing_assignment -ne $null) {
        $preserveRoutingAssignment = [bool]$OpenSpecPolicy.preserve_routing_assignment
    }

    return [pscustomobject]@{
        enabled = $true
        mode = $mode
        profile = $profile
        task_applicable = $taskApplicable
        enforcement = $enforcement
        reason = $reason
        bypass_due_to_requested_skill = $bypassDueToRequestedSkill
        preserve_routing_assignment = $preserveRoutingAssignment
        task_id = $taskId
        recommended_artifact = $recommendedArtifact
        should_upgrade_to_full = ($upgradeMatches.Count -gt 0)
        upgrade_trigger_matches = @($upgradeMatches)
    }
}

function Get-GsdOverlayAdvice {
    param(
        [string]$PromptLower,
        [string]$Grade,
        [string]$TaskType,
        [object]$GsdOverlayPolicy
    )

    if (-not $GsdOverlayPolicy) {
        return [pscustomobject]@{
            enabled = $false
            mode = "off"
            task_applicable = $false
            grade_applicable = $false
            scope_applicable = $false
            enforcement = "none"
            reason = "policy_missing"
            preserve_routing_assignment = $true
            preflight_should_apply = $false
            wave_contract_should_apply = $false
            should_apply_hook = $false
            artifacts = [pscustomobject]@{
                brownfield_directory = $null
                assumption_artifact = $null
                wave_artifact = $null
            }
        }
    }

    $enabled = $true
    if ($GsdOverlayPolicy.enabled -ne $null) {
        $enabled = [bool]$GsdOverlayPolicy.enabled
    }

    $mode = if ($GsdOverlayPolicy.mode) { [string]$GsdOverlayPolicy.mode } else { "off" }
    if ((-not $enabled) -or ($mode -eq "off")) {
        return [pscustomobject]@{
            enabled = $false
            mode = "off"
            task_applicable = $false
            grade_applicable = $false
            scope_applicable = $false
            enforcement = "none"
            reason = "policy_off"
            preserve_routing_assignment = $true
            preflight_should_apply = $false
            wave_contract_should_apply = $false
            should_apply_hook = $false
            artifacts = [pscustomobject]@{
                brownfield_directory = $null
                assumption_artifact = $null
                wave_artifact = $null
            }
        }
    }

    $taskAllow = @("planning")
    if ($GsdOverlayPolicy.task_allow) {
        $taskAllow = @($GsdOverlayPolicy.task_allow)
    }

    $gradeAllow = @("L", "XL")
    if ($GsdOverlayPolicy.grade_allow) {
        $gradeAllow = @($GsdOverlayPolicy.grade_allow)
    }

    $taskApplicable = ($taskAllow -contains $TaskType)
    $gradeApplicable = ($gradeAllow -contains $Grade)
    $scopeApplicable = ($taskApplicable -and $gradeApplicable)

    $preflightApply = $scopeApplicable

    $waveEnabled = $false
    $waveXlOnly = $true
    if ($GsdOverlayPolicy.wave_contract) {
        if ($GsdOverlayPolicy.wave_contract.enabled -ne $null) {
            $waveEnabled = [bool]$GsdOverlayPolicy.wave_contract.enabled
        }
        if ($GsdOverlayPolicy.wave_contract.xl_only -ne $null) {
            $waveXlOnly = [bool]$GsdOverlayPolicy.wave_contract.xl_only
        }
    }

    $waveTaskAllowed = ($TaskType -in @("planning", "coding"))
    $waveGradeAllowed = (($Grade -eq "XL") -or (-not $waveXlOnly))
    $waveApply = ($scopeApplicable -and $waveEnabled -and $waveTaskAllowed -and $waveGradeAllowed)

    $enforcement = "none"
    $reason = "outside_scope"
    if ($scopeApplicable) {
        $confirmGrades = @("XL")
        if ($GsdOverlayPolicy.assumption_gate -and $GsdOverlayPolicy.assumption_gate.confirm_required_for) {
            $confirmGrades = @($GsdOverlayPolicy.assumption_gate.confirm_required_for)
        }

        switch ($mode) {
            "shadow" {
                $enforcement = "advisory"
                $reason = "shadow_advisory"
            }
            "soft" {
                if ($confirmGrades -contains $Grade) {
                    $enforcement = "confirm_required"
                    $reason = "soft_confirm_scope_hit"
                } else {
                    $enforcement = "advisory"
                    $reason = "soft_advisory_outside_confirm_grade"
                }
            }
            "strict" {
                $enforcement = "required"
                $reason = "strict_required"
            }
            default {
                $enforcement = "advisory"
                $reason = "unknown_mode_advisory"
            }
        }
    }

    $preserveRoutingAssignment = $true
    if ($GsdOverlayPolicy.preserve_routing_assignment -ne $null) {
        $preserveRoutingAssignment = [bool]$GsdOverlayPolicy.preserve_routing_assignment
    }

    $brownfieldDirectory = $null
    if ($GsdOverlayPolicy.brownfield_context -and $GsdOverlayPolicy.brownfield_context.directory) {
        $brownfieldDirectory = [string]$GsdOverlayPolicy.brownfield_context.directory
    }

    $assumptionArtifact = if ($GsdOverlayPolicy.assumption_gate -and $GsdOverlayPolicy.assumption_gate.artifact) {
        [string]$GsdOverlayPolicy.assumption_gate.artifact
    } else {
        "assumptions.md"
    }

    $waveArtifact = if ($GsdOverlayPolicy.wave_contract -and $GsdOverlayPolicy.wave_contract.artifact) {
        [string]$GsdOverlayPolicy.wave_contract.artifact
    } else {
        "waves.json"
    }

    return [pscustomobject]@{
        enabled = $true
        mode = $mode
        task_applicable = $taskApplicable
        grade_applicable = $gradeApplicable
        scope_applicable = $scopeApplicable
        enforcement = $enforcement
        reason = $reason
        preserve_routing_assignment = $preserveRoutingAssignment
        preflight_should_apply = $preflightApply
        wave_contract_should_apply = $waveApply
        should_apply_hook = ($preflightApply -or $waveApply)
        artifacts = [pscustomobject]@{
            brownfield_directory = $brownfieldDirectory
            assumption_artifact = $assumptionArtifact
            wave_artifact = $waveArtifact
        }
    }
}

function Select-PackCandidate {
    param(
        [string]$PromptLower,
        [string[]]$Candidates,
        [string]$TaskType,
        [string]$RequestedCanonical,
        [object]$SkillKeywordIndex,
        [object]$RoutingRules,
        [object]$Pack,
        [object]$CandidateSelectionConfig
    )

    if (-not $Candidates -or $Candidates.Count -eq 0) {
        return [pscustomobject]@{
            selected = $null
            score = 0.0
            reason = "no_candidates"
            ranking = @()
            top1_top2_gap = 0.0
            filtered_out_by_task = @()
        }
    }

    if ($RequestedCanonical -and ($Candidates -contains $RequestedCanonical)) {
        return [pscustomobject]@{
            selected = $RequestedCanonical
            score = 1.0
            reason = "requested_skill"
            ranking = @(
                [pscustomobject]@{
                    skill = $RequestedCanonical
                    score = 1.0
                    keyword_score = 1.0
                    name_score = 1.0
                    positive_score = 1.0
                    negative_score = 0.0
                    canonical_for_task_hit = 1.0
                }
            )
            top1_top2_gap = 1.0
            filtered_out_by_task = @()
        }
    }

    $weightKeyword = 0.8
    $weightName = 0.2
    $fallbackMin = 0.2
    if ($SkillKeywordIndex -and $SkillKeywordIndex.selection -and $SkillKeywordIndex.selection.weights) {
        if ($SkillKeywordIndex.selection.weights.keyword_match -ne $null) {
            $weightKeyword = [double]$SkillKeywordIndex.selection.weights.keyword_match
        }
        if ($SkillKeywordIndex.selection.weights.name_match -ne $null) {
            $weightName = [double]$SkillKeywordIndex.selection.weights.name_match
        }
    }
    if ($SkillKeywordIndex -and $SkillKeywordIndex.selection -and $SkillKeywordIndex.selection.fallback_to_first_when_score_below -ne $null) {
        $fallbackMin = [double]$SkillKeywordIndex.selection.fallback_to_first_when_score_below
    }

    $positiveBonus = 0.2
    $negativePenalty = 0.25
    $canonicalBonus = 0.12
    if ($CandidateSelectionConfig) {
        if ($CandidateSelectionConfig.rule_positive_keyword_bonus -ne $null) {
            $positiveBonus = [double]$CandidateSelectionConfig.rule_positive_keyword_bonus
        }
        if ($CandidateSelectionConfig.rule_negative_keyword_penalty -ne $null) {
            $negativePenalty = [double]$CandidateSelectionConfig.rule_negative_keyword_penalty
        }
        if ($CandidateSelectionConfig.canonical_for_task_bonus -ne $null) {
            $canonicalBonus = [double]$CandidateSelectionConfig.canonical_for_task_bonus
        }
    }

    $filteredCandidates = @()
    $blockedByTask = @()
    foreach ($candidate in $Candidates) {
        $rule = Get-RoutingRuleForCandidate -Candidate $candidate -RoutingRules $RoutingRules
        if (Test-RuleTaskAllowed -Rule $rule -TaskType $TaskType) {
            $filteredCandidates += $candidate
        } else {
            $blockedByTask += $candidate
        }
    }

    $defaultCandidate = Get-PackDefaultCandidate -Pack $Pack -TaskType $TaskType -PreferredCandidates $filteredCandidates -AllCandidates $Candidates

    if ($filteredCandidates.Count -eq 0) {
        if ($defaultCandidate) {
            return [pscustomobject]@{
                selected = $defaultCandidate
                score = 0.0
                reason = "fallback_task_default_after_task_filter"
                ranking = @()
                top1_top2_gap = 0.0
                filtered_out_by_task = @($blockedByTask)
            }
        }

        return [pscustomobject]@{
            selected = $Candidates[0]
            score = 0.0
            reason = "fallback_first_candidate_after_task_filter"
            ranking = @()
            top1_top2_gap = 0.0
            filtered_out_by_task = @($blockedByTask)
        }
    }

    $scored = @()
    for ($i = 0; $i -lt $filteredCandidates.Count; $i++) {
        $candidate = [string]$filteredCandidates[$i]
        $rule = Get-RoutingRuleForCandidate -Candidate $candidate -RoutingRules $RoutingRules

        $keywordScore = Get-SkillKeywordScore -PromptLower $PromptLower -Candidate $candidate -SkillKeywordIndex $SkillKeywordIndex
        $nameScore = Get-CandidateNameMatchScore -PromptLower $PromptLower -Candidate $candidate

        $positiveScore = 0.0
        $negativeScore = 0.0
        $equivalentGroup = $null
        if ($rule) {
            $positiveScore = Get-KeywordRatio -PromptLower $PromptLower -Keywords @($rule.positive_keywords)
            $negativeScore = Get-KeywordRatio -PromptLower $PromptLower -Keywords @($rule.negative_keywords)
            if ($rule.equivalent_group) {
                $equivalentGroup = [string]$rule.equivalent_group
            }
        }

        $canonicalHit = Get-CanonicalForTaskHit -Rule $rule -TaskType $TaskType

        $score =
            ($weightKeyword * $keywordScore) +
            ($weightName * $nameScore) +
            ($positiveBonus * $positiveScore) -
            ($negativePenalty * $negativeScore) +
            ($canonicalBonus * $canonicalHit)

        $score = [Math]::Max(0.0, [Math]::Min(1.0, $score))

        $scored += [pscustomobject]@{
            skill = $candidate
            score = [Math]::Round($score, 4)
            keyword_score = [Math]::Round($keywordScore, 4)
            name_score = [Math]::Round($nameScore, 4)
            positive_score = [Math]::Round($positiveScore, 4)
            negative_score = [Math]::Round($negativeScore, 4)
            canonical_for_task_hit = [Math]::Round($canonicalHit, 4)
            equivalent_group = $equivalentGroup
            ordinal = $i
        }
    }

    $ranked = $scored | Sort-Object -Property @(
        @{ Expression = "score"; Descending = $true },
        @{ Expression = "keyword_score"; Descending = $true },
        @{ Expression = "positive_score"; Descending = $true },
        @{ Expression = "ordinal"; Descending = $false }
    )

    $top = $ranked | Select-Object -First 1
    if (-not $top) {
        $fallback = if ($defaultCandidate) { $defaultCandidate } else { $filteredCandidates[0] }
        $fallbackReason = if ($defaultCandidate) { "fallback_task_default" } else { "fallback_first_candidate" }
        return [pscustomobject]@{
            selected = $fallback
            score = 0.0
            reason = $fallbackReason
            ranking = @()
            top1_top2_gap = 0.0
            filtered_out_by_task = @($blockedByTask)
        }
    }

    $second = $ranked | Select-Object -Skip 1 -First 1
    $gap = if ($second) { [double]$top.score - [double]$second.score } else { [double]$top.score }
    $gap = [Math]::Max(0.0, [Math]::Round($gap, 4))

    if ([double]$top.score -lt $fallbackMin) {
        if ($defaultCandidate) {
            $defaultInRank = $ranked | Where-Object { $_.skill -eq $defaultCandidate } | Select-Object -First 1
            $defaultScore = if ($defaultInRank) { [double]$defaultInRank.score } else { [double]$top.score }
            return [pscustomobject]@{
                selected = $defaultCandidate
                score = $defaultScore
                reason = "fallback_task_default"
                ranking = @($ranked | Select-Object -First 3)
                top1_top2_gap = $gap
                filtered_out_by_task = @($blockedByTask)
            }
        }

        return [pscustomobject]@{
            selected = $filteredCandidates[0]
            score = [double]$top.score
            reason = "fallback_first_candidate"
            ranking = @($ranked | Select-Object -First 3)
            top1_top2_gap = $gap
            filtered_out_by_task = @($blockedByTask)
        }
    }

    return [pscustomobject]@{
        selected = [string]$top.skill
        score = [double]$top.score
        reason = "keyword_ranked"
        ranking = @($ranked | Select-Object -First 3)
        top1_top2_gap = $gap
        filtered_out_by_task = @($blockedByTask)
    }
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
    selected = if ($top) {
        [pscustomobject]@{
            pack_id = $top.pack_id
            skill = $top.selected_candidate
            selection_reason = $top.candidate_selection_reason
            selection_score = $top.candidate_selection_score
            top1_top2_gap = $top.candidate_top1_top2_gap
            candidate_signal = $top.candidate_signal
            filtered_out_by_task = @($top.candidate_filtered_out_by_task)
        }
    } else {
        $null
    }
    ranked = @($ranked | Select-Object -First 3)
}

$result | ConvertTo-Json -Depth 10
