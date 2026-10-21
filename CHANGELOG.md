# Changelog — nvidia-patches

All notable changes to this project will be documented in this file.

> This changelog was reconstructed on 2026-08-28 from the repository's
> existing file dates and the fix history already documented in
> `README.md` — there was no changelog before this one. Dates before
> today reflect file timestamps, not commit history (git is not used to
> inspect this repo's history).

## 1.5.0 — 2026-10-21

### Added

- **Fix 6** — NVIDIA 550 (Debian `nvidia-kernel-dkms`, 550.163.01) on kernels 7.2+
  (`patches/nvidia-550-kernel7.2-compat.patch`). Three independent kernel changes broke it:
  `linux/of_gpio.h` was removed (present in 7.0, absent from 7.1), `strncpy()` was removed from
  `linux/string.h` (present in 7.1, absent from 7.2), and `struct drm_atomic_state` was renamed
  `struct drm_atomic_commit` in 7.2 together with its helpers. The patch adds the `of_gpio.h`
  compatibility block that NVIDIA 610 already carries, replaces the five `strncpy()` calls, maps the
  renamed DRM names, and forces five `nvidia-drm` configure-time probes that look for the old struct
  and therefore report the pre-7.2 behavior. All of it is version-guarded or behavior-preserving.
  Compile-tested only: Debian `nvidia-kernel-source 550.163.01-5.1` builds all five modules against the
  headers of `7.3.0-soplos-bore-ntsync-v4` and of `7.2.11-soplos-bore-ntsync-v4` (unpatched it fails on
  both), and the patch applies cleanly to the original sources with `patch --fuzz=5 -p1`. Not loaded on
  hardware, and kernel 7.1 was not tested.

- **Fix 7** — NVIDIA 590 open modules (590.48.01, `nvidia-open-590`) on kernels 7.2+
  (`patches/nvidia-590-kernel7.2-compat.patch`, applied from `kernel-open/` after Fix 1). It carries the
  Fix 6 changes (`of_gpio.h` block, five `strncpy()` replacements, renamed DRM names and five forced
  `nvidia-drm` probes) and backports two `nvidia-uvm` fixes that NVIDIA 610 already has: the `page_free`
  to `folio_free` callback rename in `struct dev_pagemap_ops` and the three-argument
  `zone_device_page_init()`, through two new `conftest.sh` probes. Compile-tested only: it builds all five
  modules against `7.3.0-soplos-bore-ntsync-v4` and `7.2.11-soplos-bore-ntsync-v4`; the unpatched sources fail.
  Not loaded on hardware, and 590.44.01 and the proprietary 590 package were not tested.

### Changed

- README: Fix 4 now carries a correction. The `strncpy()` failure on 7.2+ is not a missing
  `#include <linux/string.h>`: the prototype itself was removed from the kernel header, so adding the
  include does not help sources that still call `strncpy()` (550.163.01 and 590.48.01 do; 610 already
  uses `strscpy()`).

## 1.4.1 — 2026-10-21

### Fixed

- **Fix 5** (`patches/nvidia-dmem-kernel7.3.patch`) never applied. Its hunk header
  declared `-2818,7 +2818,17` (7 old and 17 new lines) while the body has 6 and 15,
  so `patch` stopped with `malformed patch at line 18` and nothing was changed. The
  same text was embedded in Soplos Welcome 2.x and 3.0, Soplos Kernel Installer and
  its dev tool, and the install scripts only print a warning when a patch fails, so
  nobody noticed. The header is now `@@ -2818,6 +2818,15 @@` in this file and in the
  four embedded copies.
- Verified against the real NVIDIA 610.57.04 sources (the function is at line 2818 of
  `kernel-open/nvidia/os-interface.c`) and the Linux 7.3 headers
  (`struct dmem_cgroup_init` has `size`, `ops` and `reclaim_priv`): the patch applies
  cleanly, and the whole module builds with gcc 16.2 against
  `7.3.0-soplos-bore-ntsync-v4`. The unpatched sources reproduce the DKMS failure
  users reported: `os-interface.c:2820: passing argument 1 of
  'dmem_cgroup_register_region' makes pointer from integer without a cast
  [-Wint-conversion]`.

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
