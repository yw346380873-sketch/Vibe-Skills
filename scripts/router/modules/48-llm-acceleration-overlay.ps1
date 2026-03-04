# LLM Acceleration Overlay (GPT‑5.2 via OpenAI Responses API)
#
# Goals:
# - Only runs when user explicitly invokes /vibe or $vibe (prefix_detected).
# - Advice-first: safe abstain when API is unavailable.
# - Optional: promote confirm_required in soft/strict (does not change selected pack by default).

function Get-LlmAccelerationPolicyDefaults {
    return [pscustomobject]@{
        enabled = $false
        mode = "off" # off|shadow|soft|strict
        activation = [pscustomobject]@{
            explicit_vibe_only = $true
        }
        scope = [pscustomobject]@{
            grade_allow = @("M", "L", "XL")
            task_allow = @("planning", "coding", "review", "debug", "research")
            route_mode_allow = @("legacy_fallback", "confirm_required", "pack_overlay")
        }
        trigger = [pscustomobject]@{
            top_k = 3
            always_on_explicit_vibe = $false
            max_top1_top2_gap = 0.08
            max_confidence_for_llm = 0.55
        }
        provider = [pscustomobject]@{
            type = "openai" # openai|mock
            model = "gpt-5.2-codex"
            base_url = ""
            timeout_ms = 2500
            max_output_tokens = 900
            temperature = 0.2
            top_p = 1.0
            store = $false
            mock_response_path = ""
        }
        context = [pscustomobject]@{
            mode = "prompt_only" # none|prompt_only|diff_snippets_ok
            include_git_status = $true
            include_git_diff = $true
            max_git_status_lines = 80
            max_diff_chars = 9000
            vector_diff = [pscustomobject]@{
                enabled = $false
                embedding_model = "text-embedding-3-small"
                min_diff_chars_for_vector = 6000
                max_chunks = 12
                chunk_max_chars = 1400
                max_selected_chunks = 3
                cache_relpath = "outputs/runtime/llm-accel-vector-cache.jsonl"
                max_cache_entries = 250
                max_cache_file_kb = 8192
            }
        }
        safety = [pscustomobject]@{
            fallback_on_error = $true
            require_candidate_in_top_k = $true
            min_override_confidence = 0.75
            allow_confirm_escalation = $true
            allow_route_override = $false
        }
        rollout = [pscustomobject]@{
            apply_in_modes = @("soft", "strict")
            max_live_apply_rate = 1.0
        }
    }
}

function Get-LlmAccelerationPolicy {
    param([object]$Policy)

    $defaults = Get-LlmAccelerationPolicyDefaults
    if (-not $Policy) { return $defaults }

    $enabled = if ($Policy.enabled -ne $null) { [bool]$Policy.enabled } else { [bool]$defaults.enabled }
    $mode = if ($Policy.mode) { [string]$Policy.mode } else { [string]$defaults.mode }
    $activation = if ($Policy.activation) { $Policy.activation } else { $defaults.activation }
    $scope = if ($Policy.scope) { $Policy.scope } else { $defaults.scope }
    $trigger = if ($Policy.trigger) { $Policy.trigger } else { $defaults.trigger }
    $provider = if ($Policy.provider) { $Policy.provider } else { $defaults.provider }
    $context = if ($Policy.context) { $Policy.context } else { $defaults.context }
    $safety = if ($Policy.safety) { $Policy.safety } else { $defaults.safety }
    $rollout = if ($Policy.rollout) { $Policy.rollout } else { $defaults.rollout }
    $vectorDiff = if ($context -and $context.vector_diff) { $context.vector_diff } else { $defaults.context.vector_diff }

    return [pscustomobject]@{
        enabled = $enabled
        mode = $mode
        activation = [pscustomobject]@{
            explicit_vibe_only = if ($activation.explicit_vibe_only -ne $null) { [bool]$activation.explicit_vibe_only } else { [bool]$defaults.activation.explicit_vibe_only }
        }
        scope = [pscustomobject]@{
            grade_allow = if ($scope.grade_allow) { @($scope.grade_allow) } else { @($defaults.scope.grade_allow) }
            task_allow = if ($scope.task_allow) { @($scope.task_allow) } else { @($defaults.scope.task_allow) }
            route_mode_allow = if ($scope.route_mode_allow) { @($scope.route_mode_allow) } else { @($defaults.scope.route_mode_allow) }
        }
        trigger = [pscustomobject]@{
            top_k = if ($trigger.top_k -ne $null) { [int]$trigger.top_k } else { [int]$defaults.trigger.top_k }
            always_on_explicit_vibe = if ($trigger.always_on_explicit_vibe -ne $null) { [bool]$trigger.always_on_explicit_vibe } else { [bool]$defaults.trigger.always_on_explicit_vibe }
            max_top1_top2_gap = if ($trigger.max_top1_top2_gap -ne $null) { [double]$trigger.max_top1_top2_gap } else { [double]$defaults.trigger.max_top1_top2_gap }
            max_confidence_for_llm = if ($trigger.max_confidence_for_llm -ne $null) { [double]$trigger.max_confidence_for_llm } else { [double]$defaults.trigger.max_confidence_for_llm }
        }
        provider = [pscustomobject]@{
            type = if ($provider.type) { [string]$provider.type } else { [string]$defaults.provider.type }
            model = if ($provider.model) { [string]$provider.model } else { [string]$defaults.provider.model }
            base_url = if ($provider.base_url) { [string]$provider.base_url } else { [string]$defaults.provider.base_url }
            timeout_ms = if ($provider.timeout_ms -ne $null) { [int]$provider.timeout_ms } else { [int]$defaults.provider.timeout_ms }
            max_output_tokens = if ($provider.max_output_tokens -ne $null) { [int]$provider.max_output_tokens } else { [int]$defaults.provider.max_output_tokens }
            temperature = if ($provider.temperature -ne $null) { [double]$provider.temperature } else { [double]$defaults.provider.temperature }
            top_p = if ($provider.top_p -ne $null) { [double]$provider.top_p } else { [double]$defaults.provider.top_p }
            store = if ($provider.store -ne $null) { [bool]$provider.store } else { [bool]$defaults.provider.store }
            mock_response_path = if ($provider.mock_response_path) { [string]$provider.mock_response_path } else { [string]$defaults.provider.mock_response_path }
        }
        context = [pscustomobject]@{
            mode = if ($context.mode) { [string]$context.mode } else { [string]$defaults.context.mode }
            include_git_status = if ($context.include_git_status -ne $null) { [bool]$context.include_git_status } else { [bool]$defaults.context.include_git_status }
            include_git_diff = if ($context.include_git_diff -ne $null) { [bool]$context.include_git_diff } else { [bool]$defaults.context.include_git_diff }
            max_git_status_lines = if ($context.max_git_status_lines -ne $null) { [int]$context.max_git_status_lines } else { [int]$defaults.context.max_git_status_lines }
            max_diff_chars = if ($context.max_diff_chars -ne $null) { [int]$context.max_diff_chars } else { [int]$defaults.context.max_diff_chars }
            vector_diff = [pscustomobject]@{
                enabled = if ($vectorDiff -and $vectorDiff.enabled -ne $null) { [bool]$vectorDiff.enabled } else { [bool]$defaults.context.vector_diff.enabled }
                embedding_model = if ($vectorDiff -and $vectorDiff.embedding_model) { [string]$vectorDiff.embedding_model } else { [string]$defaults.context.vector_diff.embedding_model }
                min_diff_chars_for_vector = if ($vectorDiff -and $vectorDiff.min_diff_chars_for_vector -ne $null) { [int]$vectorDiff.min_diff_chars_for_vector } else { [int]$defaults.context.vector_diff.min_diff_chars_for_vector }
                max_chunks = if ($vectorDiff -and $vectorDiff.max_chunks -ne $null) { [int]$vectorDiff.max_chunks } else { [int]$defaults.context.vector_diff.max_chunks }
                chunk_max_chars = if ($vectorDiff -and $vectorDiff.chunk_max_chars -ne $null) { [int]$vectorDiff.chunk_max_chars } else { [int]$defaults.context.vector_diff.chunk_max_chars }
                max_selected_chunks = if ($vectorDiff -and $vectorDiff.max_selected_chunks -ne $null) { [int]$vectorDiff.max_selected_chunks } else { [int]$defaults.context.vector_diff.max_selected_chunks }
                cache_relpath = if ($vectorDiff -and $vectorDiff.cache_relpath) { [string]$vectorDiff.cache_relpath } else { [string]$defaults.context.vector_diff.cache_relpath }
                max_cache_entries = if ($vectorDiff -and $vectorDiff.max_cache_entries -ne $null) { [int]$vectorDiff.max_cache_entries } else { [int]$defaults.context.vector_diff.max_cache_entries }
                max_cache_file_kb = if ($vectorDiff -and $vectorDiff.max_cache_file_kb -ne $null) { [int]$vectorDiff.max_cache_file_kb } else { [int]$defaults.context.vector_diff.max_cache_file_kb }
            }
        }
        safety = [pscustomobject]@{
            fallback_on_error = if ($safety.fallback_on_error -ne $null) { [bool]$safety.fallback_on_error } else { [bool]$defaults.safety.fallback_on_error }
            require_candidate_in_top_k = if ($safety.require_candidate_in_top_k -ne $null) { [bool]$safety.require_candidate_in_top_k } else { [bool]$defaults.safety.require_candidate_in_top_k }
            min_override_confidence = if ($safety.min_override_confidence -ne $null) { [double]$safety.min_override_confidence } else { [double]$defaults.safety.min_override_confidence }
            allow_confirm_escalation = if ($safety.allow_confirm_escalation -ne $null) { [bool]$safety.allow_confirm_escalation } else { [bool]$defaults.safety.allow_confirm_escalation }
            allow_route_override = if ($safety.allow_route_override -ne $null) { [bool]$safety.allow_route_override } else { [bool]$defaults.safety.allow_route_override }
        }
        rollout = [pscustomobject]@{
            apply_in_modes = if ($rollout.apply_in_modes) { @($rollout.apply_in_modes) } else { @($defaults.rollout.apply_in_modes) }
            max_live_apply_rate = if ($rollout.max_live_apply_rate -ne $null) { [double]$rollout.max_live_apply_rate } else { [double]$defaults.rollout.max_live_apply_rate }
        }
    }
}

function Test-LlmAccelerationScope {
    param(
        [object]$Policy,
        [object]$PromptNormalization,
        [string]$Grade,
        [string]$TaskType,
        [string]$RouteMode
    )

    $resolved = Get-LlmAccelerationPolicy -Policy $Policy
    if (-not $resolved.enabled) {
        return [pscustomobject]@{ enabled = $false; mode = "off"; scope_applicable = $false; reasons = @("policy_disabled") }
    }

    $mode = if ($resolved.mode) { [string]$resolved.mode } else { "off" }
    if ($mode -eq "off") {
        return [pscustomobject]@{ enabled = $false; mode = "off"; scope_applicable = $false; reasons = @("mode_off") }
    }

    $reasons = @()

    if ($resolved.activation.explicit_vibe_only) {
        $prefixDetected = [bool]($PromptNormalization -and $PromptNormalization.prefix_detected)
        if (-not $prefixDetected) {
            $reasons += "explicit_vibe_only"
        }
    }

    if ($resolved.scope.grade_allow.Count -gt 0 -and -not ($resolved.scope.grade_allow -contains $Grade)) { $reasons += "grade_not_allowed" }
    if ($resolved.scope.task_allow.Count -gt 0 -and -not ($resolved.scope.task_allow -contains $TaskType)) { $reasons += "task_not_allowed" }
    if ($resolved.scope.route_mode_allow.Count -gt 0 -and -not ($resolved.scope.route_mode_allow -contains $RouteMode)) { $reasons += "route_mode_not_allowed" }

    return [pscustomobject]@{
        enabled = $true
        mode = $mode
        scope_applicable = ($reasons.Count -eq 0)
        reasons = if ($reasons.Count -eq 0) { @("scope_match") } else { @($reasons) }
    }
}

function Get-LlmAccelerationTrigger {
    param(
        [object]$PolicyResolved,
        [string]$RouteMode,
        [double]$TopGap,
        [double]$Confidence
    )

    $trigger = $PolicyResolved.trigger
    $reasons = @()

    if ([bool]$trigger.always_on_explicit_vibe) {
        $reasons += "always_on"
    } else {
        if ($RouteMode -eq "confirm_required") { $reasons += "route_mode_confirm_required" }
        if ($TopGap -le [double]$trigger.max_top1_top2_gap) { $reasons += "top_gap_low" }
        if ($Confidence -le [double]$trigger.max_confidence_for_llm) { $reasons += "confidence_low" }
    }

    return [pscustomobject]@{
        active = ($reasons.Count -gt 0)
        reasons = @($reasons | Select-Object -Unique)
        top_k = [int]$trigger.top_k
    }
}

function Get-VcoTextSha256Hex {
    param([string]$Text)

    if ($null -eq $Text) { return $null }

    $bytes = [System.Text.Encoding]::UTF8.GetBytes([string]$Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha.ComputeHash($bytes)
    } finally {
        $sha.Dispose()
    }

    return ([System.BitConverter]::ToString($hashBytes)).Replace("-", "").ToLowerInvariant()
}

function Get-VcoEvenlySpacedIndices {
    param(
        [int]$Count,
        [int]$MaxItems
    )

    if ($Count -le 0 -or $MaxItems -le 0) { return @() }
    if ($Count -le $MaxItems) { return @(0..($Count - 1)) }

    $indices = @()
    $step = ([double]$Count / [double]$MaxItems)
    for ($i = 0; $i -lt $MaxItems; $i++) {
        $idx = [int][Math]::Floor($i * $step)
        if ($idx -ge $Count) { $idx = $Count - 1 }
        $indices += $idx
    }

    return @($indices | Select-Object -Unique)
}

function Split-VcoGitDiffIntoVectorChunks {
    param(
        [string]$DiffText,
        [int]$MaxChunks,
        [int]$ChunkMaxChars
    )

    if (-not $DiffText) { return @() }

    $maxChunksSafe = [Math]::Max(1, [int]$MaxChunks)
    $chunkMaxSafe = [Math]::Max(200, [int]$ChunkMaxChars)

    $lines = @(([string]$DiffText) -split "`n")
    $fileHeader = @()
    $current = @()
    $chunks = @()

    foreach ($line in $lines) {
        if ($line -match '^diff --git ') {
            if ($current.Count -gt 0) {
                $chunks += ($current -join "`n")
                $current = @()
            }
            $fileHeader = @($line)
            continue
        }

        if ($line -match '^(index |--- |\+\+\+ |new file mode|deleted file mode|similarity index|rename from|rename to|Binary files )') {
            $fileHeader += $line
            continue
        }

        if ($line -match '^@@') {
            if ($current.Count -gt 0) {
                $chunks += ($current -join "`n")
            }

            $current = @()
            if ($fileHeader.Count -gt 0) { $current += $fileHeader }
            $current += $line
            continue
        }

        if ($current.Count -gt 0) {
            $current += $line
        } else {
            if ($line) { $fileHeader += $line }
        }
    }

    if ($current.Count -gt 0) { $chunks += ($current -join "`n") }
    if ($chunks.Count -eq 0 -and $fileHeader.Count -gt 0) { $chunks += ($fileHeader -join "`n") }

    $clean = @()
    foreach ($chunk in $chunks) {
        if (-not $chunk) { continue }
        $text = ([string]$chunk).TrimEnd()
        if (-not $text) { continue }
        if ($text.Length -gt $chunkMaxSafe) { $text = $text.Substring(0, $chunkMaxSafe) }
        $clean += $text
    }

    if ($clean.Count -le $maxChunksSafe) { return @($clean) }

    $indices = Get-VcoEvenlySpacedIndices -Count $clean.Count -MaxItems $maxChunksSafe
    $selected = @()
    foreach ($i in $indices) {
        if ($i -ge 0 -and $i -lt $clean.Count) {
            $selected += $clean[$i]
        }
    }

    return @($selected)
}

function Get-VcoVectorCachePath {
    param(
        [string]$VcoRepoRoot,
        [string]$CacheRelPath
    )

    if (-not $VcoRepoRoot -or -not $CacheRelPath) { return $null }

    if ([System.IO.Path]::IsPathRooted($CacheRelPath)) {
        return $CacheRelPath
    }

    return (Join-Path $VcoRepoRoot $CacheRelPath)
}

function Read-VcoVectorCache {
    param(
        [string]$CachePath,
        [int]$MaxEntries
    )

    $table = @{}
    if (-not $CachePath) { return $table }
    if (-not (Test-Path -LiteralPath $CachePath)) { return $table }

    try {
        $tail = [Math]::Max(1, [int]$MaxEntries)
        $lines = @(Get-Content -LiteralPath $CachePath -Tail $tail -ErrorAction Stop)
        foreach ($line in $lines) {
            if (-not $line) { continue }

            $obj = $null
            try { $obj = ($line | ConvertFrom-Json) } catch { }
            if (-not $obj) { continue }

            $model = if ($obj.model) { [string]$obj.model } else { $null }
            $sha = if ($obj.sha256) { [string]$obj.sha256 } else { $null }
            $embedding = $obj.embedding

            if ($model -and $sha -and $embedding) {
                $key = "{0}|{1}" -f $model, $sha
                $table[$key] = @($embedding)
            }
        }
    } catch { }

    return $table
}

function Append-VcoVectorCacheEntries {
    param(
        [string]$CachePath,
        [object[]]$Entries,
        [int]$MaxEntries,
        [int]$MaxFileKb
    )

    if (-not $CachePath -or -not $Entries -or $Entries.Count -eq 0) { return }

    try {
        $dir = Split-Path -Parent $CachePath
        if ($dir -and -not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
        }

        foreach ($entry in $Entries) {
            $line = ($entry | ConvertTo-Json -Depth 20 -Compress)
            Add-Content -LiteralPath $CachePath -Value $line -Encoding UTF8
        }

        $maxEntriesSafe = [Math]::Max(10, [int]$MaxEntries)
        $maxKbSafe = [Math]::Max(64, [int]$MaxFileKb)

        $needTrim = $false
        try {
            $kb = [double]((Get-Item -LiteralPath $CachePath).Length) / 1024.0
            if ($kb -gt $maxKbSafe) { $needTrim = $true }
        } catch { }

        if ($needTrim) {
            $keep = @(Get-Content -LiteralPath $CachePath -Tail $maxEntriesSafe)
            $keep | Set-Content -LiteralPath $CachePath -Encoding UTF8
        }
    } catch { }
}

function Get-VcoCosineSimilarity {
    param(
        [object[]]$A,
        [object[]]$B
    )

    if (-not $A -or -not $B) { return 0.0 }

    $n = [Math]::Min($A.Count, $B.Count)
    if ($n -le 0) { return 0.0 }

    $dot = 0.0
    $na = 0.0
    $nb = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $ai = [double]$A[$i]
        $bi = [double]$B[$i]
        $dot += ($ai * $bi)
        $na += ($ai * $ai)
        $nb += ($bi * $bi)
    }

    if ($na -le 0.0 -or $nb -le 0.0) { return 0.0 }
    return ($dot / ([Math]::Sqrt($na) * [Math]::Sqrt($nb)))
}

function Get-VcoEmbeddingsForTextsWithCache {
    param(
        [string]$EmbeddingModel,
        [string[]]$Texts,
        [object]$PolicyResolved,
        [string]$VcoRepoRoot
    )

    if (-not $EmbeddingModel -or -not $Texts -or $Texts.Count -eq 0) {
        return [pscustomobject]@{ ok = $false; abstained = $true; reason = "missing_inputs"; vectors = @() }
    }

    $vectorCfg = if ($PolicyResolved -and $PolicyResolved.context -and $PolicyResolved.context.vector_diff) { $PolicyResolved.context.vector_diff } else { $null }
    $cacheRel = if ($vectorCfg -and $vectorCfg.cache_relpath) { [string]$vectorCfg.cache_relpath } else { "" }
    $maxEntries = if ($vectorCfg -and $vectorCfg.max_cache_entries -ne $null) { [int]$vectorCfg.max_cache_entries } else { 250 }
    $maxFileKb = if ($vectorCfg -and $vectorCfg.max_cache_file_kb -ne $null) { [int]$vectorCfg.max_cache_file_kb } else { 8192 }

    $cachePath = if ($cacheRel) { Get-VcoVectorCachePath -VcoRepoRoot $VcoRepoRoot -CacheRelPath $cacheRel } else { $null }
    $cache = if ($cachePath) { Read-VcoVectorCache -CachePath $cachePath -MaxEntries $maxEntries } else { @{} }

    $vectors = New-Object object[] $Texts.Count
    $missingTexts = @()
    $missingMeta = @()

    for ($i = 0; $i -lt $Texts.Count; $i++) {
        $text = [string]$Texts[$i]
        $sha = Get-VcoTextSha256Hex -Text $text
        $key = "{0}|{1}" -f $EmbeddingModel, $sha

        if ($cache.ContainsKey($key)) {
            $vectors[$i] = $cache[$key]
        } else {
            $missingTexts += $text
            $missingMeta += [pscustomobject]@{ idx = $i; sha = $sha; len = $text.Length }
        }
    }

    if ($missingTexts.Count -gt 0) {
        $timeoutMs = 2500
        $embeddingProvider = $null
        $embeddingProviderType = "openai"
        $embeddingProviderBaseUrl = ""
        $embeddingProviderEndpointPath = ""
        $embeddingProviderApiKeyEnv = ""
        try {
            if ($vectorCfg -and $vectorCfg.embedding_provider) { $embeddingProvider = $vectorCfg.embedding_provider }
        } catch { }
        try {
            if ($embeddingProvider -and $embeddingProvider.type) { $embeddingProviderType = [string]$embeddingProvider.type }
        } catch { }
        try {
            if ($embeddingProvider -and $embeddingProvider.base_url) { $embeddingProviderBaseUrl = [string]$embeddingProvider.base_url }
        } catch { }
        if (-not $embeddingProviderBaseUrl) {
            try { $embeddingProviderBaseUrl = [string]$PolicyResolved.provider.base_url } catch { }
        }
        try {
            if ($embeddingProvider -and $embeddingProvider.endpoint_path) { $embeddingProviderEndpointPath = [string]$embeddingProvider.endpoint_path }
        } catch { }
        try {
            if ($embeddingProvider -and $embeddingProvider.api_key_env) { $embeddingProviderApiKeyEnv = [string]$embeddingProvider.api_key_env }
        } catch { }

        $timeoutHint = $null
        try {
            if ($embeddingProvider -and $embeddingProvider.timeout_ms -ne $null) { $timeoutHint = [int]$embeddingProvider.timeout_ms }
        } catch { }
        if ($timeoutHint -ne $null) {
            $timeoutMs = [Math]::Max(1000, [int][Math]::Min(15000, $timeoutHint))
        } else {
            try {
                $timeoutMs = [Math]::Max(1000, [int][Math]::Min(8000, [int]$PolicyResolved.provider.timeout_ms))
            } catch { }
        }

        $result = $null
        try {
            switch ($embeddingProviderType) {
                "openai" {
                    $result = Invoke-OpenAiEmbeddingsCreate `
                        -Model $EmbeddingModel `
                        -Input @($missingTexts) `
                        -TimeoutMs $timeoutMs `
                        -BaseUrl $embeddingProviderBaseUrl
                }
                "volc_ark" {
                    $endpointPath = if ($embeddingProviderEndpointPath) { $embeddingProviderEndpointPath } else { "/embeddings/multimodal" }
                    $apiKeyEnv = if ($embeddingProviderApiKeyEnv) { $embeddingProviderApiKeyEnv } else { "ARK_API_KEY" }
                    $items = foreach ($t in $missingTexts) {
                        [ordered]@{ type = "text"; text = [string]$t }
                    }

                    $result = Invoke-VolcArkEmbeddingsCreate `
                        -Model $EmbeddingModel `
                        -Input @($items) `
                        -TimeoutMs $timeoutMs `
                        -BaseUrl $embeddingProviderBaseUrl `
                        -EndpointPath $endpointPath `
                        -ApiKeyEnv $apiKeyEnv
                }
                default {
                    return [pscustomobject]@{ ok = $false; abstained = $true; reason = "unknown_embedding_provider"; vectors = @() }
                }
            }
        } catch {
            return [pscustomobject]@{ ok = $false; abstained = $true; reason = "embeddings_invoke_error"; vectors = @() }
        }

        if (-not [bool]$result.ok -or [bool]$result.abstained) {
            return [pscustomobject]@{ ok = $false; abstained = $true; reason = [string]$result.reason; vectors = @() }
        }

        $returned = @($result.vectors)
        if ($returned.Count -ne $missingTexts.Count) {
            return [pscustomobject]@{ ok = $false; abstained = $true; reason = "embeddings_size_mismatch"; vectors = @() }
        }

        $entries = @()
        for ($j = 0; $j -lt $missingMeta.Count; $j++) {
            $meta = $missingMeta[$j]
            $vec = $returned[$j]
            $vectors[[int]$meta.idx] = $vec

            if ($cachePath) {
                $entries += [ordered]@{
                    ts = (Get-Date).ToString("o")
                    model = $EmbeddingModel
                    sha256 = [string]$meta.sha
                    len = [int]$meta.len
                    embedding = $vec
                }
            }
        }

        if ($cachePath -and $entries.Count -gt 0) {
            Append-VcoVectorCacheEntries -CachePath $cachePath -Entries $entries -MaxEntries $maxEntries -MaxFileKb $maxFileKb
        }
    }

    return [pscustomobject]@{ ok = $true; abstained = $false; reason = "ok"; vectors = @($vectors) }
}

function Select-VcoVectorDiffSnippets {
    param(
        [object]$PolicyResolved,
        [string]$VcoRepoRoot,
        [string]$QueryText,
        [string]$DiffText
    )

    if (-not $PolicyResolved -or -not $DiffText -or -not $QueryText) {
        return [pscustomobject]@{ ok = $false; abstained = $true; reason = "missing_inputs"; diff = $null; diff_truncated = $false; selected_chunks = 0 }
    }

    $cfg = $PolicyResolved.context.vector_diff
    if (-not $cfg -or -not [bool]$cfg.enabled) {
        return [pscustomobject]@{ ok = $false; abstained = $true; reason = "vector_diff_disabled"; diff = $null; diff_truncated = $false; selected_chunks = 0 }
    }

    $embeddingModel = if ($cfg.embedding_model) { [string]$cfg.embedding_model } else { "text-embedding-3-small" }
    $maxChunks = [Math]::Max(1, [int]$cfg.max_chunks)
    $chunkMaxChars = [Math]::Max(200, [int]$cfg.chunk_max_chars)
    $maxSelected = [Math]::Max(1, [int]$cfg.max_selected_chunks)

    $chunks = Split-VcoGitDiffIntoVectorChunks -DiffText $DiffText -MaxChunks $maxChunks -ChunkMaxChars $chunkMaxChars
    if ($chunks.Count -eq 0) {
        return [pscustomobject]@{ ok = $false; abstained = $true; reason = "no_chunks"; diff = $null; diff_truncated = $false; selected_chunks = 0 }
    }

    $texts = @([string]$QueryText) + @($chunks | ForEach-Object { [string]$_ })
    $emb = Get-VcoEmbeddingsForTextsWithCache -EmbeddingModel $embeddingModel -Texts $texts -PolicyResolved $PolicyResolved -VcoRepoRoot $VcoRepoRoot
    if (-not [bool]$emb.ok -or [bool]$emb.abstained) {
        return [pscustomobject]@{ ok = $false; abstained = $true; reason = [string]$emb.reason; diff = $null; diff_truncated = $false; selected_chunks = 0 }
    }

    $vecs = @($emb.vectors)
    if ($vecs.Count -ne $texts.Count) {
        return [pscustomobject]@{ ok = $false; abstained = $true; reason = "vector_count_mismatch"; diff = $null; diff_truncated = $false; selected_chunks = 0 }
    }

    $queryVec = @($vecs[0])
    $scores = @()
    for ($i = 1; $i -lt $vecs.Count; $i++) {
        $score = Get-VcoCosineSimilarity -A $queryVec -B @($vecs[$i])
        $scores += [pscustomobject]@{ idx = ($i - 1); score = [Math]::Round([double]$score, 6) }
    }

    $top = @($scores | Sort-Object -Property score -Descending | Select-Object -First ([Math]::Min($maxSelected, $scores.Count)))
    if ($top.Count -eq 0) {
        return [pscustomobject]@{ ok = $false; abstained = $true; reason = "no_scores"; diff = $null; diff_truncated = $false; selected_chunks = 0 }
    }

    $parts = @()
    $rank = 0
    foreach ($row in $top) {
        $rank++
        $header = "[vector_diff rank={0} score={1}]" -f $rank, $row.score
        $parts += $header
        $parts += $chunks[[int]$row.idx]
        $parts += ""
    }

    $joined = ($parts -join "`n").TrimEnd()

    $limit = [Math]::Max(1000, [int]$PolicyResolved.context.max_diff_chars)
    $truncated = $false
    if ($joined.Length -gt $limit) {
        $joined = $joined.Substring(0, $limit)
        $truncated = $true
    }

    return [pscustomobject]@{
        ok = $true
        abstained = $false
        reason = "ok"
        diff = $joined
        diff_truncated = [bool]$truncated
        selected_chunks = [int]$top.Count
    }
}

function Get-VcoGitContextSnippet {
    param(
        [object]$PolicyResolved,
        [string]$VcoRepoRoot,
        [string]$QueryText
    )

    $contextMode = if ($PolicyResolved -and $PolicyResolved.context -and $PolicyResolved.context.mode) { [string]$PolicyResolved.context.mode } else { "none" }
    if ($contextMode -eq "none") {
        return [pscustomobject]@{ git_present = $false; repo_root = $null; status = $null; diff = $null; diff_truncated = $false; diff_mode = "none"; diff_selected_chunks = 0; diff_vector_reason = $null }
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        return [pscustomobject]@{ git_present = $false; repo_root = $null; status = $null; diff = $null; diff_truncated = $false; diff_mode = "none"; diff_selected_chunks = 0; diff_vector_reason = $null }
    }

    $gitRepoRoot = $null
    try {
        $gitRepoRoot = (git rev-parse --show-toplevel 2>$null).Trim()
    } catch { }
    if (-not $gitRepoRoot) {
        return [pscustomobject]@{ git_present = $false; repo_root = $null; status = $null; diff = $null; diff_truncated = $false; diff_mode = "none"; diff_selected_chunks = 0; diff_vector_reason = $null }
    }

    $statusText = $null
    $diffText = $null
    $diffTruncated = $false
    $diffMode = "none"
    $diffSelectedChunks = 0
    $diffVectorReason = $null

    if ([bool]$PolicyResolved.context.include_git_status) {
        try {
            $maxLines = [Math]::Max(10, [int]$PolicyResolved.context.max_git_status_lines)
            $lines = @(git status --porcelain=v1 2>$null | Select-Object -First $maxLines)
            if ($lines.Count -gt 0) { $statusText = ($lines -join "`n").TrimEnd() }
        } catch { }
    }

    if ($contextMode -eq "diff_snippets_ok" -and [bool]$PolicyResolved.context.include_git_diff) {
        try {
            $raw = (git diff --patch --unified=0 2>$null | Out-String)
            $raw = $raw.TrimEnd()
            $diffMode = "full"

            $vectorCfg = if ($PolicyResolved.context.vector_diff) { $PolicyResolved.context.vector_diff } else { $null }
            $vectorEnabled = [bool]($vectorCfg -and $vectorCfg.enabled)
            $minChars = if ($vectorCfg -and $vectorCfg.min_diff_chars_for_vector -ne $null) { [int]$vectorCfg.min_diff_chars_for_vector } else { 0 }

            if ($vectorEnabled -and $raw -and $raw.Length -ge $minChars -and $QueryText) {
                $embProv = $null
                $embProvType = "openai"
                try {
                    if ($vectorCfg -and $vectorCfg.embedding_provider) { $embProv = $vectorCfg.embedding_provider }
                } catch { }
                try {
                    if ($embProv -and $embProv.type) { $embProvType = [string]$embProv.type }
                } catch { }

                $keyOk = $false
                $keyReason = $null

                switch ($embProvType) {
                    "openai" {
                        if (Get-OpenAiApiKey) { $keyOk = $true } else { $keyReason = "missing_openai_api_key" }
                    }
                    "volc_ark" {
                        $keyEnv = "ARK_API_KEY"
                        try {
                            if ($embProv -and $embProv.api_key_env) { $keyEnv = [string]$embProv.api_key_env }
                        } catch { }

                        if (Get-VolcArkApiKey -EnvName $keyEnv) { $keyOk = $true } else { $keyReason = "missing_ark_api_key" }
                    }
                    default {
                        $keyReason = "unknown_embedding_provider"
                    }
                }

                if ($keyOk) {
                    $vec = Select-VcoVectorDiffSnippets -PolicyResolved $PolicyResolved -VcoRepoRoot $VcoRepoRoot -QueryText $QueryText -DiffText $raw
                    if ([bool]$vec.ok -and (-not [bool]$vec.abstained) -and $vec.diff) {
                        $diffText = [string]$vec.diff
                        $diffTruncated = [bool]$vec.diff_truncated
                        $diffMode = "vector_selected"
                        $diffSelectedChunks = [int]$vec.selected_chunks
                        $diffVectorReason = "ok"
                    } else {
                        $diffVectorReason = if ($vec -and $vec.reason) { [string]$vec.reason } else { "vector_abstained" }
                    }
                } else {
                    $diffVectorReason = $keyReason
                }
            }

            if (-not $diffText) {
                $limit = [Math]::Max(1000, [int]$PolicyResolved.context.max_diff_chars)
                if ($raw.Length -gt $limit) {
                    $diffText = $raw.Substring(0, $limit)
                    $diffTruncated = $true
                    $diffMode = "head_truncate"
                } else {
                    $diffText = $raw
                    $diffMode = "full"
                }
            }
        } catch { }
    }

    return [pscustomobject]@{
        git_present = $true
        repo_root = $gitRepoRoot
        status = $statusText
        diff = $diffText
        diff_truncated = [bool]$diffTruncated
        diff_mode = [string]$diffMode
        diff_selected_chunks = [int]$diffSelectedChunks
        diff_vector_reason = $diffVectorReason
    }
}

function Get-LlmAccelerationJsonSchema {
    $schema = [ordered]@{
        type = "object"
        additionalProperties = $false
        required = @("abstain", "confidence", "confirm_required", "confirm_questions", "rerank", "qa")
        properties = [ordered]@{
            abstain = [ordered]@{ type = "boolean" }
            confidence = [ordered]@{ type = "number"; minimum = 0; maximum = 1 }
            confirm_required = [ordered]@{ type = "boolean" }
            confirm_questions = [ordered]@{
                type = "array"
                maxItems = 3
                items = [ordered]@{ type = "string" }
            }
            rerank = [ordered]@{
                type = "object"
                additionalProperties = $false
                required = @("abstain", "suggested_pack_id", "suggested_skill", "confidence", "reason")
                properties = [ordered]@{
                    abstain = [ordered]@{ type = "boolean" }
                    suggested_pack_id = [ordered]@{ type = @("string", "null") }
                    suggested_skill = [ordered]@{ type = @("string", "null") }
                    confidence = [ordered]@{ type = "number"; minimum = 0; maximum = 1 }
                    reason = [ordered]@{ type = "string" }
                }
            }
            qa = [ordered]@{
                type = "object"
                additionalProperties = $false
                required = @("recommendations")
                properties = [ordered]@{
                    recommendations = [ordered]@{
                        type = "array"
                        maxItems = 8
                        items = [ordered]@{ type = "string" }
                    }
                    focus = [ordered]@{
                        type = "array"
                        maxItems = 6
                        items = [ordered]@{ type = "string" }
                    }
                }
            }
            notes = [ordered]@{ type = "string" }
        }
    }

    return $schema
}

function New-LlmAccelerationInputText {
    param(
        [string]$PromptText,
        [object]$PromptNormalization,
        [string]$Grade,
        [string]$TaskType,
        [string]$RouteMode,
        [string]$RouteReason,
        [object[]]$Ranked,
        [int]$TopK,
        [object]$GitContext
    )

    $rankedTop = @()
    if ($Ranked) {
        foreach ($row in @($Ranked | Select-Object -First ([Math]::Max(1, $TopK)))) {
            $rankedTop += [ordered]@{
                pack_id = [string]$row.pack_id
                score = if ($row.score -ne $null) { [double]$row.score } else { 0.0 }
                selected_candidate = if ($row.selected_candidate) { [string]$row.selected_candidate } else { $null }
                candidate_top1_top2_gap = if ($row.candidate_top1_top2_gap -ne $null) { [double]$row.candidate_top1_top2_gap } else { 0.0 }
                candidates = @($row.candidates | Select-Object -First 12)
            }
        }
    }

    $context = [ordered]@{
        vco = [ordered]@{
            grade = $Grade
            task_type = $TaskType
            route_mode = $RouteMode
            route_reason = $RouteReason
            prompt_prefix_detected = [bool]($PromptNormalization -and $PromptNormalization.prefix_detected)
        }
        prompt = [ordered]@{
            original = $PromptText
            normalized = if ($PromptNormalization -and $PromptNormalization.normalized) { [string]$PromptNormalization.normalized } else { $PromptText }
        }
        top_candidates = $rankedTop
        git = [ordered]@{
            present = [bool]($GitContext -and $GitContext.git_present)
            repo_root = if ($GitContext) { $GitContext.repo_root } else { $null }
            status = if ($GitContext) { $GitContext.status } else { $null }
            diff = if ($GitContext) { $GitContext.diff } else { $null }
            diff_truncated = if ($GitContext) { [bool]$GitContext.diff_truncated } else { $false }
            diff_mode = if ($GitContext) { $GitContext.diff_mode } else { $null }
            diff_selected_chunks = if ($GitContext) { $GitContext.diff_selected_chunks } else { 0 }
            diff_vector_reason = if ($GitContext) { $GitContext.diff_vector_reason } else { $null }
        }
    }

    $json = ($context | ConvertTo-Json -Depth 12 -Compress)

    $text = @()
    $text += "You are generating VCO LLM Acceleration advice."
    $text += ""
    $text += "Constraints:"
    $text += "- Output MUST be valid JSON that matches the provided JSON Schema."
    $text += "- If you suggest a pack/skill override, it MUST be one of the provided top_candidates pack_id and skill candidates."
    $text += "- If unsure, set abstain=true and rerank.abstain=true."
    $text += "- Always include QA recommendations (testing department can help at any stage)."
    $text += ""
    $text += "Context(JSON):"
    $text += $json

    return ($text -join "`n")
	}

	function Invoke-LlmAccelerationProvider {
	    param(
	        [object]$PolicyResolved,
	        [string]$RepoRoot,
	        [string]$InputText
	    )

	    $providerType = if ($PolicyResolved -and $PolicyResolved.provider -and $PolicyResolved.provider.type) { [string]$PolicyResolved.provider.type } else { "openai" }

	    if ($providerType -eq "mock") {
        $mockRel = if ($PolicyResolved.provider.mock_response_path) { [string]$PolicyResolved.provider.mock_response_path } else { "" }
        if (-not $mockRel) {
            return [pscustomobject]@{
                ok = $false
                abstained = $true
                reason = "mock_missing_path"
                latency_ms = 0
                output_text = $null
                error = $null
            }
        }

        $path = if ([System.IO.Path]::IsPathRooted($mockRel)) { $mockRel } else { Join-Path $RepoRoot $mockRel }
        if (-not (Test-Path -LiteralPath $path)) {
            return [pscustomobject]@{
                ok = $false
                abstained = $true
                reason = "mock_file_not_found"
                latency_ms = 0
                output_text = $null
                error = $path
            }
        }

        $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        return [pscustomobject]@{
            ok = $true
            abstained = $false
            reason = "mock_ok"
            latency_ms = 0
            output_text = $raw
            error = $null
	        }
	    }

	    $schema = Get-LlmAccelerationJsonSchema
	    $textFormat = [ordered]@{
	        type = "json_schema"
	        name = "vco_llm_acceleration"
	        strict = $true
	        schema = $schema
	    }

	    $input = @(
	        [ordered]@{
	            role = "user"
            content = @(
                [ordered]@{
                    type = "input_text"
                    text = $InputText
                }
            )
        }
	    )

	    $instructions = "Return ONLY JSON that matches the JSON Schema. No markdown. No extra keys."

	    $model = [string]$PolicyResolved.provider.model
	    $baseUrl = if ($PolicyResolved.provider.base_url) { [string]$PolicyResolved.provider.base_url } else { "" }
	    $timeoutMs = [int]$PolicyResolved.provider.timeout_ms

	    $chatResponseFormat = [ordered]@{
	        type = "json_schema"
	        json_schema = [ordered]@{
	            name = "vco_llm_acceleration"
	            strict = $true
	            schema = $schema
	        }
	    }

	    $chatMessages = @(
	        [ordered]@{ role = "system"; content = $instructions },
	        [ordered]@{ role = "user"; content = $InputText }
	    )

	    $preferChat = $false
	    if ($baseUrl -and ($baseUrl -notmatch "openai\.com")) {
	        # For most OpenAI-compatible gateways, /chat/completions is the safest baseline.
	        $preferChat = $true
	    }

	    $invokeResponses = {
	        $r = Invoke-OpenAiResponsesCreate `
	            -Model $model `
	            -BaseUrl $baseUrl `
	            -Input $input `
	            -TextFormat $textFormat `
	            -Instructions $instructions `
	            -MaxOutputTokens ([int]$PolicyResolved.provider.max_output_tokens) `
	            -Temperature ([double]$PolicyResolved.provider.temperature) `
	            -TopP ([double]$PolicyResolved.provider.top_p) `
	            -TimeoutMs $timeoutMs `
	            -Store:([bool]$PolicyResolved.provider.store)
	        $r | Add-Member -NotePropertyName api -NotePropertyValue "responses" -Force
	        return $r
	    }

	    $invokeChat = {
	        $r = Invoke-OpenAiChatCompletionsCreate `
	            -Model $model `
	            -BaseUrl $baseUrl `
	            -Messages $chatMessages `
	            -ResponseFormat $chatResponseFormat `
	            -MaxTokens ([int]$PolicyResolved.provider.max_output_tokens) `
	            -Temperature ([double]$PolicyResolved.provider.temperature) `
	            -TopP ([double]$PolicyResolved.provider.top_p) `
	            -TimeoutMs $timeoutMs
	        $r | Add-Member -NotePropertyName api -NotePropertyValue "chat_completions" -Force
	        return $r
	    }

	    $primary = $null
	    $fallback = $null

	    if ($preferChat) {
	        $primary = & $invokeChat
	        if ([bool]$primary.ok -and (-not [bool]$primary.abstained) -and $primary.output_text) { return $primary }
	        $fallback = & $invokeResponses
	        if ([bool]$fallback.ok -and (-not [bool]$fallback.abstained) -and $fallback.output_text) { return $fallback }
	        return $primary
	    }

	    $primary = & $invokeResponses
	    if ([bool]$primary.ok -and (-not [bool]$primary.abstained) -and $primary.output_text) { return $primary }
	    if ([string]$primary.reason -eq "missing_openai_api_key") { return $primary }
	    $fallback = & $invokeChat
	    if ([bool]$fallback.ok -and (-not [bool]$fallback.abstained) -and $fallback.output_text) { return $fallback }
	    return $primary
	}

function Get-DeterministicSampleValueForLlm {
    param([string]$SeedText)
    return Get-DeterministicSampleValue -SeedText $SeedText
}

function Get-LlmAccelerationAdvice {
    param(
        [string]$PromptText,
        [object]$PromptNormalization,
        [string]$Grade,
        [string]$TaskType,
        [string]$RouteMode,
        [string]$RouteReason,
        [object[]]$Ranked,
        [double]$TopGap,
        [double]$Confidence,
        [object]$LlmAccelerationPolicy,
        [string]$RepoRoot
    )

    $policyResolved = Get-LlmAccelerationPolicy -Policy $LlmAccelerationPolicy
    $scope = Test-LlmAccelerationScope -Policy $policyResolved -PromptNormalization $PromptNormalization -Grade $Grade -TaskType $TaskType -RouteMode $RouteMode
    $trigger = Get-LlmAccelerationTrigger -PolicyResolved $policyResolved -RouteMode $RouteMode -TopGap $TopGap -Confidence $Confidence

    $providerSummary = [pscustomobject]@{
        type = [string]$policyResolved.provider.type
        api = "none"
        model = [string]$policyResolved.provider.model
        abstained = $true
        reason = "not_invoked"
        latency_ms = 0
        error = $null
    }

    $parsed = $null
    $parseError = $null

    if (-not [bool]$scope.scope_applicable) {
        return [pscustomobject]@{
            enabled = [bool]$scope.enabled
            mode = [string]$scope.mode
            scope_applicable = $false
            scope_reasons = @($scope.reasons)
            trigger_active = $false
            trigger_reasons = @()
            provider = $providerSummary
            abstained = $true
            reason = "outside_scope"
            confirm_required = $false
            confirm_questions = @()
            qa_recommendations = @()
            confidence = 0.0
            override_target_pack = $null
            override_target_skill = $null
            would_override = $false
            route_override_applied = $false
            parse_error = $null
        }
    }

    $topK = [Math]::Max(1, [int]$trigger.top_k)

    if ([bool]$trigger.active) {
        $providerType = [string]$policyResolved.provider.type
        $providerInvokable = $true

        if ($providerType -eq "openai" -and (-not (Get-OpenAiApiKey))) {
            $providerInvokable = $false
            $providerSummary = [pscustomobject]@{
                type = [string]$policyResolved.provider.type
                api = "none"
                model = [string]$policyResolved.provider.model
                abstained = $true
                reason = "missing_openai_api_key"
                latency_ms = 0
                error = $null
            }
        }

        if (-not $providerInvokable) {
            # Safe abstain: do not waste time on git/diff context if provider is unavailable.
        } else {
            $queryText = if ($PromptNormalization -and $PromptNormalization.normalized) { [string]$PromptNormalization.normalized } else { [string]$PromptText }
            $gitContext = Get-VcoGitContextSnippet -PolicyResolved $policyResolved -VcoRepoRoot $RepoRoot -QueryText $queryText

        $inputText = New-LlmAccelerationInputText `
            -PromptText $PromptText `
            -PromptNormalization $PromptNormalization `
            -Grade $Grade `
            -TaskType $TaskType `
            -RouteMode $RouteMode `
            -RouteReason $RouteReason `
            -Ranked $Ranked `
            -TopK $topK `
            -GitContext $gitContext

        $providerResult = Invoke-LlmAccelerationProvider -PolicyResolved $policyResolved -RepoRoot $RepoRoot -InputText $inputText

        $providerSummary = [pscustomobject]@{
            type = [string]$policyResolved.provider.type
            api = if ($providerResult.api) { [string]$providerResult.api } else { "unknown" }
            model = [string]$policyResolved.provider.model
            abstained = [bool]$providerResult.abstained
            reason = [string]$providerResult.reason
            latency_ms = if ($providerResult.latency_ms -ne $null) { [int]$providerResult.latency_ms } else { 0 }
            error = if ($providerResult.error) { [string]$providerResult.error } else { $null }
        }

        if (-not [bool]$providerResult.abstained -and $providerResult.output_text) {
            try {
                $parsed = ($providerResult.output_text.Trim() | ConvertFrom-Json)
            } catch {
                $parseError = $_.Exception.Message
                $parsed = $null
            }
        }
        }
    }

    $abstained = $true
    $reason = "no_result"
    $confirmRequired = $false
    $confirmQuestions = @()
    $qaRecommendations = @()
    $overridePack = $null
    $overrideSkill = $null
    $suggestionConfidence = 0.0

    if ($parsed) {
        $abstained = [bool]$parsed.abstain
        $reason = if ($parsed.notes) { "model_notes" } else { "model_output" }
        $confirmRequired = [bool]$parsed.confirm_required
        $confirmQuestions = @($parsed.confirm_questions | Where-Object { $_ } | Select-Object -First 3)
        $qaRecommendations = @($parsed.qa.recommendations | Where-Object { $_ } | Select-Object -First 8)

        if ($parsed.rerank -and -not [bool]$parsed.rerank.abstain) {
            $overridePack = if ($parsed.rerank.suggested_pack_id) { [string]$parsed.rerank.suggested_pack_id } else { $null }
            $overrideSkill = if ($parsed.rerank.suggested_skill) { [string]$parsed.rerank.suggested_skill } else { $null }
            $suggestionConfidence = if ($parsed.rerank.confidence -ne $null) { [double]$parsed.rerank.confidence } else { 0.0 }
            $suggestionConfidence = [Math]::Round([Math]::Min(1.0, [Math]::Max(0.0, $suggestionConfidence)), 4)
        }
    } elseif ($parseError) {
        $reason = "parse_error"
    } elseif (-not $trigger.active) {
        $reason = "trigger_inactive"
    } elseif ($providerSummary.reason -ne "ok") {
        $reason = "provider_abstained"
    }

    $topPackIds = @()
    if ($Ranked) {
        $topPackIds = @($Ranked | Select-Object -First $topK | ForEach-Object { [string]$_.pack_id })
    }

    $constraintsPassed = $false
    if ($overridePack -and (-not $abstained)) {
        $inTopK = (-not $policyResolved.safety.require_candidate_in_top_k) -or ($topPackIds -contains $overridePack)
        $confidencePassed = ([double]$suggestionConfidence -ge [double]$policyResolved.safety.min_override_confidence)
        $constraintsPassed = $inTopK -and $confidencePassed
    }

    $mode = [string]$policyResolved.mode
    $applyModes = @($policyResolved.rollout.apply_in_modes)
    $applyModeAllowed = ($applyModes -contains $mode)
    $sampleRate = [Math]::Max(0.0, [Math]::Min(1.0, [double]$policyResolved.rollout.max_live_apply_rate))
    $sampleSeed = "{0}|{1}|{2}|{3}|{4}" -f $PromptText, $Grade, $TaskType, $RouteMode, $mode
    $sampleValue = Get-DeterministicSampleValueForLlm -SeedText $sampleSeed
    $samplePassed = ($sampleValue -le $sampleRate)

    $allowRouteOverride = [bool]$policyResolved.safety.allow_route_override
    $applyEligible = $allowRouteOverride -and $applyModeAllowed -and $samplePassed -and $constraintsPassed
    $wouldOverride = $false
    if ($mode -eq "shadow" -and $constraintsPassed) {
        $wouldOverride = $true
    } elseif ($applyEligible) {
        $wouldOverride = $true
    }

    $routeOverrideApplied = $applyEligible

    return [pscustomobject]@{
        enabled = [bool]$scope.enabled
        mode = [string]$scope.mode
        scope_applicable = $true
        scope_reasons = @($scope.reasons)
        trigger_active = [bool]$trigger.active
        trigger_reasons = @($trigger.reasons)
        provider = $providerSummary
        abstained = [bool]$abstained
        reason = [string]$reason
        confirm_required = if ([bool]$policyResolved.safety.allow_confirm_escalation) { [bool]$confirmRequired } else { $false }
        confirm_questions = @($confirmQuestions)
        qa_recommendations = @($qaRecommendations)
        confidence = [double]$suggestionConfidence
        constraints = [pscustomobject]@{
            top_k = [int]$topK
            require_candidate_in_top_k = [bool]$policyResolved.safety.require_candidate_in_top_k
            in_top_k = if ($overridePack) { [bool]($topPackIds -contains $overridePack) } else { $false }
            min_override_confidence = [double]$policyResolved.safety.min_override_confidence
            confidence_passed = ([double]$suggestionConfidence -ge [double]$policyResolved.safety.min_override_confidence)
            passed = [bool]$constraintsPassed
        }
        rollout = [pscustomobject]@{
            apply_mode_allowed = [bool]$applyModeAllowed
            sample_rate = [Math]::Round([double]$sampleRate, 4)
            sample_value = [Math]::Round([double]$sampleValue, 6)
            sample_passed = [bool]$samplePassed
            apply_eligible = [bool]$applyEligible
            would_override = [bool]$wouldOverride
            route_override_applied = [bool]$routeOverrideApplied
        }
        override_target_pack = $overridePack
        override_target_skill = $overrideSkill
        would_override = [bool]$wouldOverride
        route_override_applied = [bool]$routeOverrideApplied
        parse_error = $parseError
    }
}
