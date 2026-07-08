# VMA locking API patches for NVIDIA DKMS on kernel 7.x

Patches for NVIDIA DKMS source trees that fail to compile on Linux kernel 7.0+.

## The problem

Linux 7.0 changed the VMA locking API in `mm/vma.c`:

- `VMA_LOCK_OFFSET` removed — replaced by `VM_REFCNT_EXCLUDE_READERS_FLAG`
- `__is_vma_write_locked()` signature changed from two arguments to one

NVIDIA driver sources (550.x through 610.x) reference the old API, causing DKMS build
failures with errors like:

```
error: 'VMA_LOCK_OFFSET' undeclared (first use in this function)
error: too many arguments to function '__is_vma_write_locked'
make[2]: *** [nvidia/nv-mmap.o] Error 1
```

## Patches

| File | Driver | Notes |
|------|--------|-------|
| `nvidia-550-kernel7.patch` | NVIDIA 550.x | Legacy — Maxwell to Ada Lovelace (GTX 900 – RTX 40xx) |
| `nvidia-580-kernel7.patch` | NVIDIA 580.x | Production — Maxwell to Blackwell (GTX 900 – RTX 50xx) |
| `nvidia-590-kernel7.patch` | NVIDIA 590.x | Stable — Turing and above (GTX 1650/1660, RTX 20xx–50xx) |
| `nvidia-610-kernel7.patch` | NVIDIA 610.x | Latest — Blackwell and above (RTX 50xx/60xx) |

All patches apply the same fix using `#ifndef` guards so they are backward-compatible —
safe to apply on any kernel version.

## How to apply

```bash
# Auto-detect installed NVIDIA version
NVIDIA_VER=$(dkms status 2>/dev/null | grep -oP 'nvidia/\K[0-9.]+' | head -1)
NVIDIA_MAJOR=$(echo "$NVIDIA_VER" | cut -d. -f1)

case "$NVIDIA_MAJOR" in
    550) PATCH="nvidia-550-kernel7.patch" ;;
    580) PATCH="nvidia-580-kernel7.patch" ;;
    590) PATCH="nvidia-590-kernel7.patch" ;;
    610) PATCH="nvidia-610-kernel7.patch" ;;
    *)   PATCH="nvidia-580-kernel7.patch" ;;
esac

sudo patch --fuzz=5 -p1 -d /usr/src/nvidia-${NVIDIA_VER} < ${PATCH}
```

Then rebuild the DKMS module:

```bash
sudo dkms build nvidia/${NVIDIA_VER} -k $(uname -r)
sudo dkms install nvidia/${NVIDIA_VER} -k $(uname -r)
```

## Affected kernels

| Kernel | Status |
|--------|--------|
| Linux <= 6.18 | Not affected — old VMA API still present |
| Linux 6.19 | Affected |
| Linux 7.0.x | Affected |
| Linux 7.1.x | Affected |

## Notes

- `--fuzz=5` is needed for 590.x and 610.x due to minor line offset differences
  in the source compared to 580.x. Safe to use for all versions.
- The patch is idempotent — the `#ifndef VM_REFCNT_EXCLUDE_READERS_FLAG` guard
  prevents double-application.
- On Debian stock kernels >= 7.0.4, also apply the appropriate fix from
  `../scripts/debian-7.0.4/` or `../scripts/debian-7.0.7/` before rebuilding.
- Soplos kernel installer applies these patches automatically when installing
  or updating kernels on systems with an NVIDIA GPU.
