# NVIDIA Patches for Linux kernel 7.0

Collection of NVIDIA 550/580/590 DKMS fixes and patch files for Linux 6.19 / 7.0 kernels.

## Repository structure

- `patches/`
  - Standalone patch files for NVIDIA DKMS sources.
- `scripts/debian-7.0.4/`
  - Debian 7.0.4+ fixes for NVIDIA 550/580 DKMS build failures.
- `scripts/debian-7.0.7/`
  - Debian 7.0.7+ fixes for NVIDIA 550/580 DKMS builds with `CONFIG_DEBUG_INFO_BTF_MODULES=y`.

## Files

- `patches/nvidia-580-kernel7.patch`
  - Patch for NVIDIA 580 against Linux kernel 7.0.
- `patches/nvidia-590-kernel7.patch`
  - Patch for NVIDIA 590 against Linux kernel 7.0. Same VMA locking API fixes as the 580 patch, applies with `--fuzz=5` due to minor line offset differences in the 590 source.
- `scripts/debian-7.0.4/nvidia-550-deb14-pahole-fix.sh`
  - Fixes the Debian 7.0.4+ `pahole`/BTF interaction for NVIDIA 550.x DKMS.
- `scripts/debian-7.0.4/nvidia-580-deb14-pahole-fix.sh`
  - Fixes the Debian 7.0.4+ `pahole`/BTF interaction for NVIDIA 580.x DKMS.
- `scripts/debian-7.0.7/nvidia-550-deb14-btf-fix.sh`
  - Patches NVIDIA 550 DKMS to disable BTF module generation on Debian 7.0.7+.
- `scripts/debian-7.0.7/nvidia-580-deb14-btf-fix.sh`
  - Patches NVIDIA 580 DKMS to disable BTF module generation on Debian 7.0.7+.

## Usage

1. Apply the patch directly (replace the version with your installed one):

```bash
NVIDIA_VER=$(dkms status 2>/dev/null | grep -oP 'nvidia/\K[0-9.]+' | head -1)
sudo patch --fuzz=5 -p1 -d /usr/src/nvidia-${NVIDIA_VER} < patches/nvidia-580-kernel7.patch
# For NVIDIA 590:
sudo patch --fuzz=5 -p1 -d /usr/src/nvidia-${NVIDIA_VER} < patches/nvidia-590-kernel7.patch
```

2. Run the Debian 7.0.4 fix script for your driver version:

```bash
sudo bash scripts/debian-7.0.4/nvidia-580-deb14-pahole-fix.sh
# or for NVIDIA 550:
sudo bash scripts/debian-7.0.4/nvidia-550-deb14-pahole-fix.sh
```

3. Run the Debian 7.0.7 BTF fix for your driver version:

```bash
sudo bash scripts/debian-7.0.7/nvidia-580-deb14-btf-fix.sh
# or for NVIDIA 550:
sudo bash scripts/debian-7.0.7/nvidia-550-deb14-btf-fix.sh
```

## License

MIT
