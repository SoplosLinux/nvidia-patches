# NVIDIA Patches for Soplos Linux kernels

Collection of NVIDIA DKMS fixes and patch files for Soplos Linux kernels (7.x) and Debian testing kernels.

## When do you need these patches?

| Situation | Fix needed |
|-----------|-----------|
| NVIDIA DKMS fails on Soplos kernel 7.x (`VMA_LOCK_OFFSET` / `__is_vma_write_locked` errors) | `patches/nvidia-*-kernel7.patch` |
| NVIDIA DKMS fails on Debian kernel 7.0.4+ (`awk: invalid char '''` in BTF build) | `scripts/debian-7.0.4/` |
| NVIDIA DKMS fails on Debian kernel 7.0.7+ (same BTF error, different path) | `scripts/debian-7.0.7/` |
| NVIDIA DKMS fails on Debian kernel 7.0.13+ (same BTF error) | `scripts/debian-7.0.13/` |

> Soplos kernel installer applies `patches/` automatically when installing or updating kernels.
> The `scripts/debian-*/` fixes are for users running **Debian stock kernels** alongside NVIDIA drivers.

---

## Repository structure

```
patches/
  nvidia-550-kernel7.patch      — VMA locking API fix for NVIDIA 550.x on kernel 7.x
  nvidia-580-kernel7.patch      — VMA locking API fix for NVIDIA 580.x on kernel 7.x
  nvidia-590-kernel7.patch      — VMA locking API fix for NVIDIA 590.x on kernel 7.x
  nvidia-610-kernel7.patch      — VMA locking API fix for NVIDIA 610.x on kernel 7.x

scripts/
  debian-7.0.4/
    nvidia-550-deb14-pahole-fix.sh   — pahole/BTF fix for NVIDIA 550 on Debian 7.0.4+
    nvidia-580-deb14-pahole-fix.sh   — pahole/BTF fix for NVIDIA 580 on Debian 7.0.4+
    nvidia-590-deb14-pahole-fix.sh   — pahole/BTF fix for NVIDIA 590 on Debian 7.0.4+
    nvidia-610-deb14-pahole-fix.sh   — pahole/BTF fix for NVIDIA 610 on Debian 7.0.4+

  debian-7.0.7/
    nvidia-550-deb14-btf-fix.sh      — BTF module generation fix for NVIDIA 550 on Debian 7.0.7+
    nvidia-580-deb14-btf-fix.sh      — BTF module generation fix for NVIDIA 580 on Debian 7.0.7+
    nvidia-590-deb14-btf-fix.sh      — BTF module generation fix for NVIDIA 590 on Debian 7.0.7+
    nvidia-610-deb14-btf-fix.sh      — BTF module generation fix for NVIDIA 610 on Debian 7.0.7+

  debian-7.0.13/
    nvidia-550-deb14-btf-fix.sh      — BTF module generation fix for NVIDIA 550 on Debian 7.0.13+
    nvidia-580-deb14-btf-fix.sh      — BTF module generation fix for NVIDIA 580 on Debian 7.0.13+
    nvidia-590-deb14-btf-fix.sh      — BTF module generation fix for NVIDIA 590 on Debian 7.0.13+
    nvidia-610-deb14-btf-fix.sh      — BTF module generation fix for NVIDIA 610 on Debian 7.0.13+
```

---

## Fix 1 — VMA locking API (Soplos kernels 7.x)

**Error in DKMS make.log:**
```
error: 'VMA_LOCK_OFFSET' undeclared
error: too many arguments to function '__is_vma_write_locked'
```

**Root cause:** Linux 7.0 removed `VMA_LOCK_OFFSET` (replaced by `VM_REFCNT_EXCLUDE_READERS_FLAG`)
and changed `__is_vma_write_locked()` from two arguments to one. NVIDIA 550/580/590/610 sources
reference the old API.

**Fix:** Apply the corresponding patch to the NVIDIA DKMS source tree before rebuilding.

```bash
# Auto-detect installed NVIDIA version and apply the right patch
NVIDIA_VER=$(dkms status 2>/dev/null | grep -oP 'nvidia/\K[0-9.]+' | head -1)
NVIDIA_MAJOR=$(echo "$NVIDIA_VER" | cut -d. -f1)

case "$NVIDIA_MAJOR" in
    550) sudo patch --fuzz=5 -p1 -d /usr/src/nvidia-${NVIDIA_VER} < patches/nvidia-550-kernel7.patch ;;
    580) sudo patch --fuzz=5 -p1 -d /usr/src/nvidia-${NVIDIA_VER} < patches/nvidia-580-kernel7.patch ;;
    590) sudo patch --fuzz=5 -p1 -d /usr/src/nvidia-${NVIDIA_VER} < patches/nvidia-590-kernel7.patch ;;
    610) sudo patch --fuzz=5 -p1 -d /usr/src/nvidia-${NVIDIA_VER} < patches/nvidia-610-kernel7.patch ;;
    *)   sudo patch --fuzz=5 -p1 -d /usr/src/nvidia-${NVIDIA_VER} < patches/nvidia-580-kernel7.patch ;;
esac
```

The patch uses `#ifndef` guards so it is safe to apply on any kernel version — it is a no-op
on kernels where the old symbols still exist.

---

## Fix 2 — pahole/BTF awk quoting (Debian 7.0.4+)

**Error in DKMS build log:**
```
awk: line 1: 'BEGIN
awk: line 1: ^ invalid char «'» in expression
```

Run the script matching your NVIDIA version:

```bash
# NVIDIA 550:
sudo bash scripts/debian-7.0.4/nvidia-550-deb14-pahole-fix.sh
# NVIDIA 580:
sudo bash scripts/debian-7.0.4/nvidia-580-deb14-pahole-fix.sh
# NVIDIA 590:
sudo bash scripts/debian-7.0.4/nvidia-590-deb14-pahole-fix.sh
# NVIDIA 610:
sudo bash scripts/debian-7.0.4/nvidia-610-deb14-pahole-fix.sh
```

See `scripts/debian-7.0.4/README.md` for full explanation.

---

## Fix 3 — BTF module generation (Debian 7.0.7+)

**Error in DKMS build log:**
```
awk: cmd. line:1: 'BEGIN
awk: cmd. line:1: ^ invalid char ''' in expression
make[4]: *** [scripts/Makefile.modfinal:62: nvidia-modeset.ko] Error 1
```

Run the script matching your NVIDIA version. Use the folder that matches your Debian kernel:

```bash
# Debian 7.0.7 — 7.0.12:
sudo bash scripts/debian-7.0.7/nvidia-550-deb14-btf-fix.sh   # NVIDIA 550
sudo bash scripts/debian-7.0.7/nvidia-580-deb14-btf-fix.sh   # NVIDIA 580
sudo bash scripts/debian-7.0.7/nvidia-590-deb14-btf-fix.sh   # NVIDIA 590
sudo bash scripts/debian-7.0.7/nvidia-610-deb14-btf-fix.sh   # NVIDIA 610

# Debian 7.0.13+:
sudo bash scripts/debian-7.0.13/nvidia-550-deb14-btf-fix.sh  # NVIDIA 550
sudo bash scripts/debian-7.0.13/nvidia-580-deb14-btf-fix.sh  # NVIDIA 580
sudo bash scripts/debian-7.0.13/nvidia-590-deb14-btf-fix.sh  # NVIDIA 590
sudo bash scripts/debian-7.0.13/nvidia-610-deb14-btf-fix.sh  # NVIDIA 610
```

See `scripts/debian-7.0.7/README.md` or `scripts/debian-7.0.13/README.md` for full explanation.

---

## License

MIT
