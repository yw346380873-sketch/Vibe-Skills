# Local Windows VM Proof Host

## Scope

This document covers the local Ubuntu host setup needed to run a Windows VM for Claude platform-proof work.

It does not mean the Windows Claude lane is already promoted.

## What This Unlocks

- a reproducible local hypervisor path on Ubuntu
- a repo-owned Windows VM launch command
- honest fallback to software emulation when `/dev/kvm` is unavailable

## What This Does Not Prove

- fresh-machine Windows install proof inside the guest
- fresh-machine Windows check proof inside the guest
- real Claude CLI smoke proof on Windows
- any macOS proof

## Host Install

```bash
bash ./scripts/setup/install-local-vm-host.sh
```

Expected tools:

- `qemu-system-x86_64`
- `qemu-img`
- `ovmf` firmware assets
- `swtpm`

KVM readiness check:

```bash
bash ./scripts/setup/check-kvm-host-readiness.sh
```

## Windows ISO

The launch script requires a user-supplied Windows ISO.

Official download entry:

- `https://www.microsoft.com/en-us/software-download/windows10iso`
- `https://aka.ms/Win11E-ISO-25H2-en-us`
- `https://developer.microsoft.com/en-us/windows/downloads/virtual-machines/`

Repository helper for the Microsoft evaluation ISO:

```bash
bash ./scripts/setup/fetch-windows11-eval-iso.sh --download-dir ~/Downloads
```

Official media decision helper:

```bash
bash ./scripts/setup/show-windows-proof-media-options.sh
```

Download truth:

- the helper downloads to `*.part` first
- it renames to the final `.iso` only after completion
- the VM launch script refuses to boot from media that is still downloading

Readiness check:

```bash
bash ./scripts/setup/check-windows-eval-iso-readiness.sh
```

Expected states:

- `status=downloading`
- `status=missing`
- `status=size-mismatch`
- `status=writer-open`
- `status=ready`

The repository does not vendor Windows media.

## Launch

```bash
bash ./scripts/setup/run-windows-proof-vm.sh --iso /absolute/path/Windows.iso
```

If you already have a prepared Windows disk image, you can boot it directly:

```bash
bash ./scripts/setup/run-windows-proof-vm.sh --disk-image /absolute/path/Windows.vhdx
```

Useful flags:

- `--vm-root /absolute/path/to/vm-root`
- `--memory-mb 8192`
- `--cpus 4`
- `--cpu-model max`
- `--machine-type q35`
- `--firmware uefi|bios`
- `--disk-gb 80`
- `--vnc-display 5`
- `--boot-key ret,spc`
- `--boot-key-rounds 60`
- `--boot-key-interval-ms 1000`
- `--legacy-ide`
- `--with-tpm`
- `--require-kvm`
- `--foreground`

Helper scripts added for proof debugging:

- `python3 ./scripts/setup/send-qmp-boot-keys.py <qmp.sock> ret,spc 60 1000`
- `python3 ./scripts/setup/send-qmp-text.py <qmp.sock> 'fs0:'`

Accepted disk-image formats depend on `qemu-img info`, but the intended paths are:

- `qcow2`
- `raw` / `img`
- `vhdx`
- `vmdk`

Default behavior:

- uses KVM if available
- falls back to `tcg` if KVM is unavailable
- creates a qcow2 system disk if missing when `--disk-image` is not supplied
- exposes VNC on `127.0.0.1:5900 + display`
- writes pid, monitor, qmp, and serial artifacts into the VM root

## Stop

```bash
bash ./scripts/setup/stop-windows-proof-vm.sh
```

Or target a specific VM root:

```bash
bash ./scripts/setup/stop-windows-proof-vm.sh --vm-root /absolute/path/to/vm-root
```

## Current Host Truth

On the current Ubuntu machine:

- sudo is available
- QEMU tooling was not preinstalled
- `/dev/kvm` is currently absent
- `systemd-detect-virt` reports `kvm`, which means this session is itself already running inside a KVM-backed virtual machine

That means the first runnable path is honest slow-path emulation unless host acceleration is added later.
It also means the host switch cannot be completed from inside this current guest unless nested KVM passthrough is enabled upstream.

## KVM Rerun Gate

For the next host, use the repo-owned guardrail so the Windows proof does not silently fall back to `tcg` again:

```bash
bash ./scripts/setup/check-kvm-host-readiness.sh
bash ./scripts/setup/run-windows-proof-vm.sh \
  --require-kvm \
  --iso /absolute/path/Windows.iso \
  --boot-key spc \
  --boot-key-rounds 90 \
  --boot-key-interval-ms 1000
```

Expected readiness on the target host:

- `status=ready`
- `reason=kvm-available`
- `/dev/kvm` is readable and writable

If the readiness script reports `virtualized-guest-without-kvm-passthrough`, that machine is still the wrong place to continue the Windows Claude lane.

## Practical Media Sources

The repo currently assumes you bring one of these into the host manually:

- a Microsoft Windows ISO
- a Microsoft-sourced virtual disk image such as `vhdx`

The repo does not currently claim a fully automated official-media download flow.

Additional official fallback truth:

- Microsoft developer virtual machines are an official path and are packaged for Hyper-V (Gen2), Parallels, VirtualBox, and VMware
- Microsoft marked those developer-VM downloads as temporarily unavailable on October 23, 2024
- if that lane reopens, the current repo launch script can already consume a prepared disk image through `--disk-image`

## Current Empirical State On This Host

The current Ubuntu host can now reproducibly:

- install and resolve the QEMU, OVMF, and swtpm dependencies
- download and validate the Microsoft Windows 11 Enterprise Evaluation ISO
- launch a Windows guest in truthful `tcg` mode when `/dev/kvm` is absent
- expose serial, QMP, monitor, VNC, RDP-forward, and SSH-forward surfaces for repeatable debugging

The current Ubuntu host still cannot honestly claim a successful Windows fresh-machine proof.

Observed matrix on this host:

- `q35 + ahci + cpu=max + Win11 ISO`:
  the VM reaches `Press any key to boot from CD or DVD...` when a boot key is injected
- `q35 + ahci + cpu=max + Win11 ISO`, with or without TPM:
  the Windows installer path advances past optical boot and then crashes in WinPE with stop code `SYSTEM_THREAD_EXCEPTION_NOT_HANDLED (0x7E)`
- `pc + legacy-ide + Win11 ISO`:
  firmware fell back into PXE / TianoCore loops and did not yield a stable installer handoff
- `q35 + ahci + cpu=qemu64 + Win11 ISO`:
  the guest dropped into the UEFI shell instead of auto-booting the installer
- `q35 + ahci + cpu=qemu64 + Win11 ISO`, once inside the shell:
  `FS0:\EFI\BOOT\BOOTX64.EFI` and `FS0:\EFI\Microsoft\Boot\cdboot_noprompt.efi` are both visible on the ISO, but the guest still does not hand off into the installer
- `q35 + ahci + cpu=qemu64 + Win11 ISO`, EFI app execution probe:
  `FS0:\EFI\Microsoft\Boot\memtest.efi` returns `Command Error Status: Unsupported` on this host, which is strong evidence that the no-KVM TCG path is rejecting at least some Windows EFI programs after the shell stage
- `pc + legacy-ide + bios + cpu=max + Win11 ISO`:
  SeaBIOS does start, but the guest falls through to `iPXE` with `Press ESC for boot menu.` instead of handing off to the installer
- `q35 + ahci + bios + cpu=max + Win11 ISO`:
  bypassing OVMF does not unblock the host; the guest still reaches a Windows crash screen with stop code `SYSTEM_THREAD_EXCEPTION_NOT_HANDLED (0x7E)`

What that means:

- host-side proof scaffolding is materially better than before
- adding a BIOS / SeaBIOS branch increases coverage, but it does not unblock guest usability on this host
- Windows guest proof is still blocked by a real guest-boot instability on the current no-KVM TCG path
- the remaining blocker is no longer "can QEMU start" but "can Windows EFI / WinPE execute successfully under this host's TCG-only path"
- the next most credible official fallback is a Microsoft developer VM image or other Microsoft virtual-disk lane, not another round of blind Win11 ISO parameter churn on this host
- the Claude Windows platform lane must remain below promotion until a real guest install/check/smoke artifact exists
