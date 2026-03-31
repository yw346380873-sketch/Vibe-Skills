#!/usr/bin/env bash
set -euo pipefail

ISO_PATH="${HOME}/Downloads/windows11-eval.iso"
INTERVAL_SECONDS="60"
WITH_TPM="1"
VM_ROOT=""
VNC_DISPLAY=""
MEMORY_MB=""
CPUS=""
DISK_GB=""

usage() {
  cat <<'EOF'
Usage: bash ./scripts/setup/wait-and-run-windows-proof-vm.sh [options]

Options:
  --iso PATH                Final ISO path to wait for
  --interval-seconds N      Poll interval in seconds (default: 60)
  --without-tpm             Launch without TPM
  --vm-root PATH            Forwarded to run-windows-proof-vm.sh
  --vnc-display N           Forwarded to run-windows-proof-vm.sh
  --memory-mb N             Forwarded to run-windows-proof-vm.sh
  --cpus N                  Forwarded to run-windows-proof-vm.sh
  --disk-gb N               Forwarded to run-windows-proof-vm.sh
  --help                    Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --iso)
      ISO_PATH="${2:-}"
      shift 2
      ;;
    --interval-seconds)
      INTERVAL_SECONDS="${2:-}"
      shift 2
      ;;
    --without-tpm)
      WITH_TPM="0"
      shift
      ;;
    --vm-root)
      VM_ROOT="${2:-}"
      shift 2
      ;;
    --vnc-display)
      VNC_DISPLAY="${2:-}"
      shift 2
      ;;
    --memory-mb)
      MEMORY_MB="${2:-}"
      shift 2
      ;;
    --cpus)
      CPUS="${2:-}"
      shift 2
      ;;
    --disk-gb)
      DISK_GB="${2:-}"
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

READYNESS_SCRIPT="$(dirname "$0")/check-windows-eval-iso-readiness.sh"
RUN_SCRIPT="$(dirname "$0")/run-windows-proof-vm.sh"

RUN_ARGS=(--iso "${ISO_PATH}")
if [[ "${WITH_TPM}" == "1" ]]; then
  RUN_ARGS+=(--with-tpm)
fi
if [[ -n "${VM_ROOT}" ]]; then
  RUN_ARGS+=(--vm-root "${VM_ROOT}")
fi
if [[ -n "${VNC_DISPLAY}" ]]; then
  RUN_ARGS+=(--vnc-display "${VNC_DISPLAY}")
fi
if [[ -n "${MEMORY_MB}" ]]; then
  RUN_ARGS+=(--memory-mb "${MEMORY_MB}")
fi
if [[ -n "${CPUS}" ]]; then
  RUN_ARGS+=(--cpus "${CPUS}")
fi
if [[ -n "${DISK_GB}" ]]; then
  RUN_ARGS+=(--disk-gb "${DISK_GB}")
fi

echo "[INFO] Waiting for Windows ISO readiness at ${ISO_PATH}"
echo "[INFO] Poll interval: ${INTERVAL_SECONDS}s"

while true; do
  if ! STATUS_OUTPUT="$(bash "${READYNESS_SCRIPT}" --iso "${ISO_PATH}" 2>&1)"; then
    echo "[ERROR] readiness probe failed for ${ISO_PATH}" >&2
    printf '%s\n' "${STATUS_OUTPUT}" >&2
    exit 1
  fi
  STATUS="$(printf '%s\n' "${STATUS_OUTPUT}" | awk -F= '/^status=/{print $2}' | tail -n 1)"
  CURRENT_BYTES="$(printf '%s\n' "${STATUS_OUTPUT}" | awk -F= '/^current_bytes=/{print $2}' | tail -n 1)"

  if [[ -n "${STATUS}" ]]; then
    echo "[INFO] readiness status=${STATUS} current_bytes=${CURRENT_BYTES:-unknown}"
  else
    echo "[WARN] readiness probe returned no status"
  fi

  if [[ "${STATUS}" == "ready" ]]; then
    echo "[INFO] ISO is ready. Launching VM."
    bash "${RUN_SCRIPT}" "${RUN_ARGS[@]}"
    exit 0
  fi

  sleep "${INTERVAL_SECONDS}"
done
