# nvidia-deb14-btf-fix (kernel 7.0.13+)

Fix for NVIDIA DKMS failing to build on Debian kernel 7.0.13+deb14 and later.

## The problem

After installing `linux-headers-7.0.13+deb14-amd64`, DKMS fails to build the nvidia module:

```
Building module(s)........................(bad exit status: 2)
Error! Bad return status for module build on kernel: 7.0.13+deb14-amd64 (x86_64)
```

The actual error buried in the build log:

```
BTF [M] nvidia-modeset.ko
awk: cmd. line:1: 'BEGIN
awk: cmd. line:1: ^ invalid char ''' in expression
make[4]: *** [scripts/Makefile.modfinal:62: nvidia-modeset.ko] Error 1
```

## Root cause

Same as 7.0.7: Debian kernel ships with `CONFIG_DEBUG_INFO_BTF_MODULES=y`, causing a build
system incompatibility between the kernel headers and the NVIDIA DKMS build. The `cmd_btf_ko`
make variable expansion generates a quoted awk invocation that awk rejects.

## The fix

Patch `dkms.conf` to pass `CONFIG_DEBUG_INFO_BTF_MODULES=` (empty) to the NVIDIA DKMS
make invocation. This disables BTF generation only for the NVIDIA build — NVIDIA modules
do not expose BTF type information, so there is no functional impact.

## Usage

Run the script matching your NVIDIA driver version:

```bash
# NVIDIA 550:
sudo bash nvidia-550-deb14-btf-fix.sh

# NVIDIA 580:
sudo bash nvidia-580-deb14-btf-fix.sh

# NVIDIA 590:
sudo bash nvidia-590-deb14-btf-fix.sh

# NVIDIA 610:
sudo bash nvidia-610-deb14-btf-fix.sh
```

All scripts auto-detect the installed NVIDIA version. To specify explicitly:

```bash
sudo bash nvidia-580-deb14-btf-fix.sh 580.126.20
```

Or apply manually:

```bash
sudo sed -i 's/IGNORE_XEN_PRESENCE=1 modules/IGNORE_XEN_PRESENCE=1 CONFIG_DEBUG_INFO_BTF_MODULES= modules/' \
    /usr/src/nvidia-<version>/dkms.conf

sudo dkms build nvidia/<version> -k $(uname -r)
sudo dkms install nvidia/<version> -k $(uname -r)
```

## Affected

| Component | Version |
|-----------|---------|
| nvidia-kernel-dkms | 550.x, 580.x, 590.x, 610.x |
| Kernel | Debian testing 7.0.13+ with `CONFIG_DEBUG_INFO_BTF_MODULES=y` |

**Not affected:** Soplos custom kernels compiled without `CONFIG_DEBUG_INFO_BTF_MODULES=y`.

## Notes

- The `dkms.conf` patch survives kernel upgrades but not driver reinstalls.
  Re-run the script if the NVIDIA driver is reinstalled or updated.
- This is a workaround until NVIDIA fixes their DKMS build to handle the BTF generation
  quoting introduced in Debian's `Makefile.modfinal`.
