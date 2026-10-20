# Changelog — nvidia-patches

All notable changes to this project will be documented in this file.

> This changelog was reconstructed on 2026-08-28 from the repository's
> existing file dates and the fix history already documented in
> `README.md` — there was no changelog before this one. Dates before
> today reflect file timestamps, not commit history (git is not used to
> inspect this repo's history).

## 1.4.0 — 2026-10-20

### Added

- **Fix 5** — `dmem_cgroup_register_region()` new signature on Soplos kernel 7.3+
  (`patches/nvidia-dmem-kernel7.3.patch`).
  Kernel commit `e11640b9cea4` changed the first argument from a bare `u64 size`
  to `const struct dmem_cgroup_init *`; NVIDIA 610 (open driver) passes `size`
  directly, which GCC rejects with `-Wint-conversion`. The fix wraps the call
  site with `#if LINUX_VERSION_CODE >= KERNEL_VERSION(7, 3, 0)` and fills
  `struct dmem_cgroup_init { .size = size, .ops = NULL, .reclaim_priv = NULL }`.
  Field name `.size` confirmed against the real header
  (`linux-headers-7.3.0-soplos-bore-ntsync-v4/include/linux/cgroup_dmem.h`).
  Only affects NVIDIA 610 with the open driver (Turing / RTX 2000+); branches
  550/580/590 and the proprietary driver do not define `NV_USE_DMEM_CGROUP_API`
  and are completely unaffected.
- Same logic added to `core/nvidia_dkms_patch.py` in `soplos-kernel-installer`
  (`NV_DMEM_CGROUP_INIT_PATCH`), applied automatically at kernel install time.

## 1.3.0 — 2026-08-17

### Added

- **Fix 4** — missing `#include <linux/string.h>` in `nvidia/os-interface.c`
  on Soplos kernel 7.2+ (`patches/nvidia-string-h-kernel7.2.patch`).
  `os_get_current_process_name()` calls `strncpy()` without including the
  header directly; some kernel header that used to pull it in
  transitively stopped doing so starting with kernel 7.2, and GCC treats
  the resulting implicit declaration as a hard error. Version-independent
  — same fix regardless of NVIDIA driver branch (550/580/590/610), unlike
  Fix 1.

### Verified

- **Fix 1** confirmed unaffected by kernel 7.2: `VM_REFCNT_EXCLUDE_READERS_FLAG`
  (`include/linux/mm_types.h`) and the single-argument `__is_vma_write_locked()`
  (`include/linux/mmap_lock.h`) are byte-identical between kernel 7.1 and 7.2 —
  no patch update needed for that fix on 7.2.

## 1.2.0 — 2026-07-08

### Added

- NVIDIA 590 and 610 support for **Fix 1** (`patches/nvidia-590-kernel7.patch`,
  `patches/nvidia-610-kernel7.patch`) and **Fix 2**
  (`scripts/debian-7.0.4/nvidia-590-deb14-pahole-fix.sh`,
  `nvidia-610-deb14-pahole-fix.sh`).
- **Fix 3** — BTF module generation fix for Debian kernels 7.0.7+ and
  7.0.13+ (`scripts/debian-7.0.7/`, `scripts/debian-7.0.13/`), all four
  driver branches (550/580/590/610) from the start.

## 1.1.0 — 2026-06-03

### Added

- NVIDIA 590 support for **Fix 1** (`patches/nvidia-590-kernel7.patch`).

## 1.0.0 — 2026-05-18

### Added

- **Fix 1** — VMA locking API fix (`VMA_LOCK_OFFSET` →
  `VM_REFCNT_EXCLUDE_READERS_FLAG`, `__is_vma_write_locked()` argument
  change) for NVIDIA 550 and 580 on Soplos kernel 7.x.
- **Fix 2** — pahole/BTF `awk` quoting fix for NVIDIA 550 and 580 on
  Debian kernel 7.0.4+ (`scripts/debian-7.0.4/`).
