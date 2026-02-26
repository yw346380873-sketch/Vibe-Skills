param()

$ErrorActionPreference = "Stop"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if ($Condition) {
        Write-Host "[PASS] $Message"
        return $true
    }

    Write-Host "[FAIL] $Message" -ForegroundColor Red
    return $false
}

function Invoke-Route {
    param(
        [string]$Prompt,
        [string]$Grade,
        [string]$TaskType,
        [string]$RequestedSkill
    )

    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
    $resolver = Join-Path $repoRoot "scripts\router\resolve-pack-route.ps1"

    $routeArgs = @{
        Prompt = $Prompt
        Grade = $Grade
        TaskType = $TaskType
    }
    if ($RequestedSkill) {
        $routeArgs["RequestedSkill"] = $RequestedSkill
    }

    $json = & $resolver @routeArgs
    return ($json | ConvertFrom-Json)
}

$cases = @(
    [pscustomobject]@{
        Name = "L planning orchestration"
        Prompt = "create implementation plan and task breakdown with milestones"
        Grade = "L"
        TaskType = "planning"
        RequestedSkill = $null
        ExpectedPack = "orchestration-core"
        ExpectedProfile = "full"
        ExpectedEnforcement = "confirm_required"
    },
    [pscustomobject]@{
        Name = "L planning aios-core"
        Prompt = "create PRD and user story backlog with quality gate"
        Grade = "L"
        TaskType = "planning"
        RequestedSkill = $null
        ExpectedPack = "aios-core"
        ExpectedProfile = "full"
        ExpectedEnforcement = "confirm_required"
    },
    [pscustomobject]@{
        Name = "XL planning confirm scope"
        Prompt = "plan a multi-agent refactor for data layer and integration boundaries"
        Grade = "XL"
        TaskType = "planning"
        RequestedSkill = $null
        ExpectedPack = $null
        ExpectedProfile = "full"
        ExpectedEnforcement = "confirm_required"
    },
    [pscustomobject]@{
        Name = "L non-planning outside scope"
        Prompt = "investigate recent OpenAI model release notes and summarize findings"
        Grade = "L"
        TaskType = "research"
        RequestedSkill = $null
        ExpectedPack = $null
        ExpectedProfile = "full"
        ExpectedEnforcement = "none"
    },
    [pscustomobject]@{
        Name = "M planning lite profile"
        Prompt = "small module implementation plan without architecture change"
        Grade = "M"
        TaskType = "planning"
        RequestedSkill = $null
        ExpectedPack = "orchestration-core"
        ExpectedProfile = "lite"
        ExpectedEnforcement = "advisory"
    },
    [pscustomobject]@{
        Name = "Requested skill bypass"
        Prompt = "run code review and security scan"
        Grade = "M"
        TaskType = "review"
        RequestedSkill = "code-review"
        ExpectedPack = "code-quality"
        ExpectedProfile = "lite"
        ExpectedEnforcement = "none"
    }
)

$results = @()

Write-Host "=== VCO OpenSpec Governance Gate ==="
foreach ($case in $cases) {
    $route = Invoke-Route -Prompt $case.Prompt -Grade $case.Grade -TaskType $case.TaskType -RequestedSkill $case.RequestedSkill

    $results += Assert-True -Condition ($null -ne $route.selected) -Message "[$($case.Name)] selected route exists"
    if ($case.ExpectedPack) {
        $results += Assert-True -Condition ($route.selected.pack_id -eq $case.ExpectedPack) -Message "[$($case.Name)] selected pack unchanged ($($case.ExpectedPack))"
    }
    $results += Assert-True -Condition ($null -ne $route.openspec_advice) -Message "[$($case.Name)] openspec_advice exists"
    $results += Assert-True -Condition ($route.openspec_advice.enabled -eq $true) -Message "[$($case.Name)] openspec advice enabled"
    $results += Assert-True -Condition ($route.openspec_advice.profile -eq $case.ExpectedProfile) -Message "[$($case.Name)] profile is $($case.ExpectedProfile)"
    $results += Assert-True -Condition ($route.openspec_advice.enforcement -eq $case.ExpectedEnforcement) -Message "[$($case.Name)] enforcement is $($case.ExpectedEnforcement)"
    $results += Assert-True -Condition ($route.openspec_advice.preserve_routing_assignment -eq $true) -Message "[$($case.Name)] preserve routing assignment"
}

$governance = & (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..\..")) "scripts\governance\invoke-openspec-governance.ps1") `
    -Prompt "small module implementation plan without architecture change" `
    -Grade "M" `
    -TaskType "planning" `
    -NoAutoCreateLite
$governanceObj = $governance | ConvertFrom-Json
$results += Assert-True -Condition ($governanceObj.status -in @("lite_exists", "lite_missing", "advisory_only")) -Message "[governance script] lite profile handling status"
$results += Assert-True -Condition ($governanceObj.selected_pack -eq "orchestration-core") -Message "[governance script] selected pack preserved"

$passCount = ($results | Where-Object { $_ }).Count
$failCount = ($results | Where-Object { -not $_ }).Count
$total = $results.Count

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Total assertions: $total"
Write-Host "Passed: $passCount"
Write-Host "Failed: $failCount"

if ($failCount -gt 0) {
    exit 1
}

Write-Host "OpenSpec governance gate passed."
exit 0
