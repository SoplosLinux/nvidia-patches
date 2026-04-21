# NVIDIA 580 patches for Linux kernel 7.0

Patches to fix NVIDIA driver 580 DKMS build failures on Linux kernel 7.0.
Compatible with kernel 6.19.x and 7.0.x.

## Problem

NVIDIA driver 580.126.20 fails to compile on Linux kernel 7.0 due to VMA API changes:

- `VMA_LOCK_OFFSET` removed, replaced by `VM_REFCNT_EXCLUDE_READERS_FLAG`
- `__is_vma_write_locked()` signature changed from 2 arguments to 1

## Affected

- Driver: nvidia-kernel-dkms 580.126.20-1
- GPUs: Maxwell and older (GTX 900 series and below) — last supported by driver 580
- Kernels: 7.0+ (patch is backwards compatible with 6.19.x)

## Apply patch

```bash
sudo patch -p0 -d /usr/src/nvidia-580.126.20 < nvidia-580-kernel7.patch
sudo dkms build nvidia/580.126.20 -k $(uname -r)
sudo dkms install nvidia/580.126.20 -k $(uname -r)
```

## Tested on

- Linux 6.19.13 ✓
- Linux 7.0.0 ✓

## License

MIT
