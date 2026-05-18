# nvidia-580-kernel7.patch

Source patch for NVIDIA driver 580.x to fix compilation failures on Linux kernel 7.0.

## The problem

NVIDIA driver 580.x fails to compile on Linux kernel 7.0 due to VMA API changes:

- `VMA_LOCK_OFFSET` removed, replaced by `VM_REFCNT_EXCLUDE_READERS_FLAG`
- `__is_vma_write_locked()` signature changed from 2 arguments to 1

```
error: 'VMA_LOCK_OFFSET' undeclared
error: too many arguments to function '__is_vma_write_locked'
```

## Affected

| Component | Version |
|-----------|---------|
| nvidia-kernel-dkms | 580.x |
| GPUs | Maxwell and older (GTX 900 series and below) |
| Kernels | 6.19.x, 7.0.x |

**Not affected:** newer GPU generations (GTX 10xx and above) — the affected code
path is only compiled for Maxwell and older.

## Apply the patch

```bash
NVIDIA_VER=$(dkms status 2>/dev/null | grep -oP 'nvidia/\K[0-9.]+' | head -1)
sudo patch -p1 -d /usr/src/nvidia-${NVIDIA_VER} < nvidia-580-kernel7.patch
```

Then rebuild and reinstall the DKMS module:

```bash
sudo dkms build nvidia/${NVIDIA_VER} -k $(uname -r)
sudo dkms install nvidia/${NVIDIA_VER} -k $(uname -r)
```

## Tested on

- Linux 6.19.13 ✓
- Linux 7.0.0 ✓
- Linux 7.0.4+deb14-amd64 ✓
- Linux 7.0.5+deb14-amd64 ✓

## Notes

- The patch adds backward-compatible preprocessor macros — it does not change
  driver behaviour on kernels that already define `VM_REFCNT_EXCLUDE_READERS_FLAG`.
- On Debian kernels >= 7.0.4, apply this patch together with the appropriate
  fix from `scripts/debian-7.0.4/` to resolve the DKMS build failure first.
