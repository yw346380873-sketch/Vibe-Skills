#!/usr/bin/env bash
set -euo pipefail

PROFILE="full"
TARGET_ROOT="${HOME}/.codex"
DEEP="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --target-root) TARGET_ROOT="$2"; shift 2 ;;
    --deep) DEEP="true"; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

PASS=0
FAIL=0
WARN=0

check_path() {
  local label="$1"; local path="$2"; local required="${3:-true}"
  if [[ -e "$path" ]]; then
    echo "[OK] $label"
    PASS=$((PASS+1))
  elif [[ "$required" == "true" ]]; then
    echo "[FAIL] $label -> $path"
    FAIL=$((FAIL+1))
  else
    echo "[WARN] $label -> $path"
    WARN=$((WARN+1))
  fi
}

run_deep_gate() {
  local label="$1"
  local script_path="$2"
  shift 2

  if [[ ! -f "$script_path" ]]; then
    echo "[WARN] deep gate/$label -> missing script: $script_path"
    WARN=$((WARN+1))
    return
  fi

  if ! command -v pwsh >/dev/null 2>&1; then
    echo "[WARN] deep gate/$label -> pwsh not found"
    WARN=$((WARN+1))
    return
  fi

  if pwsh -NoProfile -File "$script_path" "$@"; then
    echo "[OK] deep gate/$label"
    PASS=$((PASS+1))
  else
    echo "[FAIL] deep gate/$label"
    FAIL=$((FAIL+1))
  fi
}

check_path "settings.json" "${TARGET_ROOT}/settings.json"
for n in vibe dialectic local-vco-roles spec-kit-vibe-compat superclaude-framework-compat ralph-loop cancel-ralph tdd-guide think-harder; do
  check_path "skill/${n}" "${TARGET_ROOT}/skills/${n}/SKILL.md"
done
check_path "vibe router script" "${TARGET_ROOT}/skills/vibe/scripts/router/resolve-pack-route.ps1"
check_path "vibe router modules dir" "${TARGET_ROOT}/skills/vibe/scripts/router/modules"
check_path "vibe router core module" "${TARGET_ROOT}/skills/vibe/scripts/router/modules/00-core-utils.ps1"
check_path "vibe memory governance config" "${TARGET_ROOT}/skills/vibe/config/memory-governance.json"
check_path "vibe data scale overlay config" "${TARGET_ROOT}/skills/vibe/config/data-scale-overlay.json"
check_path "vibe quality debt overlay config" "${TARGET_ROOT}/skills/vibe/config/quality-debt-overlay.json"
check_path "vibe framework interop overlay config" "${TARGET_ROOT}/skills/vibe/config/framework-interop-overlay.json"
check_path "vibe ml lifecycle overlay config" "${TARGET_ROOT}/skills/vibe/config/ml-lifecycle-overlay.json"
check_path "vibe python clean code overlay config" "${TARGET_ROOT}/skills/vibe/config/python-clean-code-overlay.json"
check_path "vibe system design overlay config" "${TARGET_ROOT}/skills/vibe/config/system-design-overlay.json"
check_path "vibe cuda kernel overlay config" "${TARGET_ROOT}/skills/vibe/config/cuda-kernel-overlay.json"
check_path "vibe observability policy config" "${TARGET_ROOT}/skills/vibe/config/observability-policy.json"
check_path "vibe ai rerank policy config" "${TARGET_ROOT}/skills/vibe/config/ai-rerank-policy.json"
for n in brainstorming writing-plans subagent-driven-development systematic-debugging; do
  check_path "workflow/${n}" "${TARGET_ROOT}/skills/${n}/SKILL.md"
done
if [[ "${PROFILE}" == "full" ]]; then
  for n in requesting-code-review receiving-code-review verification-before-completion; do
    check_path "optional/${n}" "${TARGET_ROOT}/skills/${n}/SKILL.md" false
  done
fi
check_path "rules/common" "${TARGET_ROOT}/rules/common/agents.md"
check_path "hooks/write-guard" "${TARGET_ROOT}/hooks/write-guard.js"
check_path "mcp template" "${TARGET_ROOT}/mcp/servers.template.json"

if [[ "${DEEP}" == "true" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  VERIFY_DIR="${SCRIPT_DIR}/scripts/verify"
  if [[ ! -d "${VERIFY_DIR}" ]]; then
    echo "[WARN] deep verification skipped (scripts/verify missing)"
    WARN=$((WARN+1))
  else
    run_deep_gate "vibe-pack-regression-matrix" "${VERIFY_DIR}/vibe-pack-regression-matrix.ps1"
    run_deep_gate "vibe-router-contract-gate" "${VERIFY_DIR}/vibe-router-contract-gate.ps1"
    run_deep_gate "vibe-routing-stability-gate-strict" "${VERIFY_DIR}/vibe-routing-stability-gate.ps1" -Strict
    run_deep_gate "vibe-config-parity-gate" "${VERIFY_DIR}/vibe-config-parity-gate.ps1"
    run_deep_gate "vibe-observability-gate" "${VERIFY_DIR}/vibe-observability-gate.ps1"
    run_deep_gate "vibe-ai-rerank-gate" "${VERIFY_DIR}/vibe-ai-rerank-gate.ps1"
  fi
fi

echo "Result: ${PASS} passed, ${FAIL} failed, ${WARN} warnings"
[[ ${FAIL} -eq 0 ]]
