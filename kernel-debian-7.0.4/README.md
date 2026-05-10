# nvidia-deb14-pahole-fix

Fix for NVIDIA DKMS failing to build on Debian testing kernels >= 7.0.4.

## The problem

After installing `linux-headers-7.0.4+deb14-amd64`, DKMS fails to build the nvidia module:

```
Building module(s)........................(bad exit status: 2)
Error! Bad return status for module build on kernel: 7.0.4+deb14-amd64 (x86_64)
```

The actual error buried in the build log:

```
BTF [M] nvidia-modeset.ko
awk: line 1: 'BEGIN
awk: line 1: ^ invalid char «'» in expression
```

## Root cause

The NVIDIA Makefile wraps `pahole` with an awk one-liner stored in a variable:

```makefile
PAHOLE_VARIABLES=$(if $(wildcard $(KERNEL_SOURCES)/scripts/pahole-flags.sh),,\
  "PAHOLE=$(AWK) '$(PAHOLE_AWK_PROGRAM)'")
```

When `scripts/pahole-flags.sh` **does not exist** in the kernel tree, NVIDIA sets
`PAHOLE` to `awk 'BEGIN {...}'` — a shell command embedded in a make variable.

Debian kernels >= 7.0.4 ship a new `scripts/gen-btf.sh` (with `CONFIG_DEBUG_INFO_BTF_MODULES=y`)
that invokes `${PAHOLE}` directly in the shell. Shell variable expansion does **not**
re-parse quotes, so awk receives `'BEGIN` — the literal apostrophe is part of the
argument — and fails.

Debian kernels moved pahole flag handling from `pahole-flags.sh` to `Makefile.btf`,
so the file no longer exists and NVIDIA's detection logic goes down the wrong path.

## The fix

Create a stub `pahole-flags.sh` in the kernel headers. NVIDIA detects the file,
leaves `PAHOLE_VARIABLES` empty, and `PAHOLE` defaults to the system `pahole` binary.
The kernel's `Makefile.btf` already exports `PAHOLE_FLAGS` correctly, so
`gen-btf.sh` works without the awk wrapper.

## Usage

```bash
sudo bash nvidia-deb14-pahole-fix.sh
```

Auto-detects the newest installed Debian testing kernel. Or specify explicitly:

```bash
sudo bash nvidia-deb14-pahole-fix.sh 7.0.4+deb14
```

## Affected

| Component | Version |
|-----------|---------|
| nvidia-dkms | 580.x |
| Kernel | Debian testing >= 7.0.4 with `CONFIG_DEBUG_INFO_BTF_MODULES=y` |
| pahole | 1.31 |

**Not affected:** custom kernels compiled without `CONFIG_DEBUG_INFO_BTF_MODULES=y`
(BTF module generation is never triggered, so `gen-btf.sh` is never called).

## Notes

- The stub `pahole-flags.sh` will be overwritten the next time the kernel headers
  package is reinstalled/upgraded. Re-run the script if that happens.
- This is a workaround until NVIDIA fixes their Makefile to handle kernels that
  use `Makefile.btf` instead of `pahole-flags.sh`.
