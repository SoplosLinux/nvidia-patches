# NVIDIA 580 patches for Linux kernel 7.0

Patches and fixes to resolve NVIDIA driver 580 DKMS build failures on Linux kernel 7.0.
Compatible with kernel 6.19.x and 7.0.x.

## Affected

- Driver: nvidia-kernel-dkms 580.126.20-1
- GPUs: Maxwell and older (GTX 900 series and below) — last supported by driver 580
- Kernels: Debian testing (forky) 7.0.x

---

## Fix 1 — VMA API changes (kernel 7.0.4 and 7.0.5)

### Problem

NVIDIA driver 580.126.20 fails to compile on Linux kernel 7.0 due to VMA API changes:

- `VMA_LOCK_OFFSET` removed, replaced by `VM_REFCNT_EXCLUDE_READERS_FLAG`
- `__is_vma_write_locked()` signature changed from 2 arguments to 1

### Apply patch

Download `nvidia-580-kernel7.patch` and from the directory where you saved it run:

```
sudo patch -p1 -d /usr/src/nvidia-580.126.20 < nvidia-580-kernel7.patch
```

Then rebuild and reinstall the DKMS module for your running kernel:

```
sudo dkms build nvidia/580.126.20 -k $(uname -r)
sudo dkms install nvidia/580.126.20 -k $(uname -r)
```

### Tested on

- Linux 6.19.13 ✓
- Linux 7.0.0 ✓
- Linux 7.0.4+deb14-amd64 ✓
- Linux 7.0.5+deb14-amd64 ✓

---

## Fix 2 — BTF module generation failure (kernel 7.0.7)

### Problem

NVIDIA driver 580.126.20 fails to build on Debian kernel 7.0.7+deb14 with
`CONFIG_DEBUG_INFO_BTF_MODULES=y`. The kernel build system invokes `gen-btf.sh`
via a make rule in `Makefile.modfinal`, and the `escsq/make-cmd` variable
expansion generates an `awk` invocation with a quote character that awk rejects:

```
BTF [M] nvidia-modeset.ko
awk: cmd. line:1: 'BEGIN
awk: cmd. line:1: ^ invalid char ''' in expression
make[4]: *** [scripts/Makefile.modfinal:62: nvidia-modeset.ko] Error 1
```

This is a build system incompatibility between the Debian 7.0.7 kernel headers
and the NVIDIA DKMS build. It does not affect driver functionality, nor custom
kernels built without `CONFIG_DEBUG_INFO_BTF_MODULES=y`.

### Apply fix

Run the fix script from the `kernel-debian-7.0.7` directory:

```
sudo bash nvidia-580-deb14-btf-fix.sh
```

The script patches `dkms.conf` to pass `CONFIG_DEBUG_INFO_BTF_MODULES=` (empty)
to the NVIDIA DKMS make invocation, disabling BTF generation only for the NVIDIA
build. NVIDIA modules do not expose BTF type information, so this has no functional
impact.

Or apply manually:

```
sudo sed -i 's/IGNORE_XEN_PRESENCE=1 modules/IGNORE_XEN_PRESENCE=1 CONFIG_DEBUG_INFO_BTF_MODULES= modules/' \
    /usr/src/nvidia-580.126.20/dkms.conf

sudo dkms build nvidia/580.126.20 -k $(uname -r)
sudo dkms install nvidia/580.126.20 -k $(uname -r)
```

### Tested on

- Linux 7.0.7+deb14-amd64 ✓

---

## License

MIT
