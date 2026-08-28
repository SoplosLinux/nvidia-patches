# Changelog — nvidia-patches

All notable changes to this project will be documented in this file.

> This changelog was reconstructed on 2026-08-28 from the repository's
> existing file dates and the fix history already documented in
> `README.md` — there was no changelog before this one. Dates before
> today reflect file timestamps, not commit history (git is not used to
> inspect this repo's history).

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
