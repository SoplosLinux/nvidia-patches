# nvidia-deb14-btf-fix (kernel 7.0.7)

Fix for NVIDIA DKMS failing to build on Debian kernel 7.0.7+deb14.

## The problem

After installing `linux-headers-7.0.7+deb14-amd64`, DKMS fails to build the nvidia module:

```
Building module(s)........................(bad exit status: 2)
Error! Bad return status for module build on kernel: 7.0.7+deb14-amd64 (x86_64)
```

The actual error buried in the build log:

```
BTF [M] nvidia-modeset.ko
awk: cmd. line:1: 'BEGIN
awk: cmd. line:1: ^ invalid char ''' in expression
make[4]: *** [scripts/Makefile.modfinal:62: nvidia-modeset.ko] Error 1
```

## Root cause

Debian kernel 7.0.7 ships with `CONFIG_DEBUG_INFO_BTF_MODULES=y`, which causes
the kernel build system to invoke `gen-btf.sh` via a make rule in `Makefile.modfinal`.
The make variable expansion of `cmd_btf_ko` passes an awk program through the
`escsq/make-cmd` machinery, which generates a command-line awk invocation with
a quote character that awk rejects as invalid.

This is a build system incompatibility between the Debian 7.0.7 kernel headers
and the NVIDIA DKMS build. It does not affect driver functionality, nor custom
kernels built without `CONFIG_DEBUG_INFO_BTF_MODULES=y`.

## The fix

Patch `dkms.conf` to pass `CONFIG_DEBUG_INFO_BTF_MODULES=` (empty) to the NVIDIA
DKMS make invocation. This disables BTF generation only for the NVIDIA build.
NVIDIA modules do not expose BTF type information, so this has no functional impact.

## Usage

```bash
# For NVIDIA 580:
sudo bash nvidia-580-deb14-btf-fix.sh

# For NVIDIA 550:
sudo bash nvidia-550-deb14-btf-fix.sh
```

Auto-detects the installed NVIDIA version. Or specify explicitly:

```bash
sudo bash nvidia-580-deb14-btf-fix.sh 580.126.20
sudo bash nvidia-550-deb14-btf-fix.sh 550.163.01
```

Or apply manually:

```bash
# For NVIDIA 580:
sudo sed -i 's/IGNORE_XEN_PRESENCE=1 modules/IGNORE_XEN_PRESENCE=1 CONFIG_DEBUG_INFO_BTF_MODULES= modules/' \
    /usr/src/nvidia-580.x.x/dkms.conf

sudo dkms build nvidia/580.x.x -k $(uname -r)
sudo dkms install nvidia/580.x.x -k $(uname -r)
```

## Affected

| Component | Version |
|-----------|---------|
| nvidia-kernel-dkms | 550.x, 580.x |
| Kernel | Debian testing 7.0.7+deb14 with `CONFIG_DEBUG_INFO_BTF_MODULES=y` |

**Not affected:** custom kernels compiled without `CONFIG_DEBUG_INFO_BTF_MODULES=y`.

## Tested on

- Linux 7.0.7+deb14-amd64 ✓

## Notes

- The `dkms.conf` patch survives kernel upgrades but not driver reinstalls.
  Re-run the script if the NVIDIA driver is reinstalled.
- This is a workaround until NVIDIA fixes their DKMS build to handle kernels
  that use `Makefile.modfinal` BTF generation with the new `escsq` quoting.
