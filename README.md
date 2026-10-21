# NVIDIA Patches for Soplos Linux kernels

Collection of NVIDIA DKMS fixes and patch files for Soplos Linux kernels (7.x) and Debian testing kernels.

## When do you need these patches?

| Situation | Fix needed |
|-----------|-----------|
| NVIDIA DKMS fails on Soplos kernel 7.x (`VMA_LOCK_OFFSET` / `__is_vma_write_locked` errors) | `patches/nvidia-*-kernel7.patch` |
| NVIDIA DKMS fails on Soplos kernel 7.2+ (`implicit declaration of function 'strncpy'` in `os-interface.c`) | `patches/nvidia-string-h-kernel7.2.patch` |
| NVIDIA DKMS fails on Soplos kernel 7.3+ (`-Wint-conversion` en `dmem_cgroup_register_region`, `os-interface.c`) | `patches/nvidia-dmem-kernel7.3.patch` |
| NVIDIA 550 (Debian `nvidia-kernel-dkms`) fails on kernel 7.2+ (`linux/of_gpio.h` missing, `strncpy` undeclared, `drm_atomic_state` errors in `nvidia-drm`) | `patches/nvidia-550-kernel7.2-compat.patch` |
| NVIDIA 590 (open modules, `nvidia-open-590`) fails on kernel 7.2+ (`linux/of_gpio.h` missing, `strncpy` undeclared, `drm_atomic_state` errors, `page_free` / `zone_device_page_init` errors in `nvidia-uvm`) | `patches/nvidia-590-kernel7.patch` and `patches/nvidia-590-kernel7.2-compat.patch` |
| NVIDIA DKMS fails on Debian kernel 7.0.4+ (`awk: invalid char '''` in BTF build) | `scripts/debian-7.0.4/` |
| NVIDIA DKMS fails on Debian kernel 7.0.7+ (same BTF error, different path) | `scripts/debian-7.0.7/` |
| NVIDIA DKMS fails on Debian kernel 7.0.13+ (same BTF error) | `scripts/debian-7.0.13/` |

> `soplos-kernel-installer` does **not** fetch from this repo — it carries its own embedded copy
> of the Fix 1 patch in `core/nvidia_dkms_patch.py` (applied automatically to `/usr/src/nvidia-*/`
> at kernel install time, `#ifndef`-guarded so it's a safe no-op on kernels that don't need it).
> This repo's `patches/` files are the reference copy for manual/standalone use — if you touch the
> logic, keep both in sync by hand, there is no code linking them together. Same applies to Fix 4
> below (`os-interface.c` / `NV_STRING_H_PATCH` in `core/nvidia_dkms_patch.py`).
> The `scripts/debian-*/` fixes are for users running **Debian stock kernels** alongside NVIDIA drivers.

---

## Repository structure

```
patches/
  nvidia-550-kernel7.patch      — VMA locking API fix for NVIDIA 550.x on kernel 7.x
  nvidia-580-kernel7.patch      — VMA locking API fix for NVIDIA 580.x on kernel 7.x
  nvidia-590-kernel7.patch      — VMA locking API fix for NVIDIA 590.x on kernel 7.x
  nvidia-610-kernel7.patch      — VMA locking API fix for NVIDIA 610.x on kernel 7.x
  nvidia-string-h-kernel7.2.patch — missing <linux/string.h> fix for os-interface.c on kernel 7.2+
                                     (version-independent, applies to any NVIDIA driver branch)
  nvidia-dmem-kernel7.3.patch   — dmem_cgroup_register_region() API fix for NVIDIA 610 (open)
                                     on kernel 7.3+ (only affects the open driver, Turing/RTX and newer)
  nvidia-550-kernel7.2-compat.patch — of_gpio.h, strncpy and DRM atomic commit fixes for NVIDIA 550
                                     (Debian) on kernel 7.2+, compile-tested on 7.3
  nvidia-590-kernel7.2-compat.patch — of_gpio.h, strncpy, DRM atomic commit and nvidia-uvm fixes for the
                                     NVIDIA 590 open modules on kernel 7.2+, compile-tested on 7.2.11 and 7.3

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

Verified 2026-08-17: `VM_REFCNT_EXCLUDE_READERS_FLAG` (`include/linux/mm_types.h`) and
`__is_vma_write_locked()` (`include/linux/mmap_lock.h`, single-argument form) are byte-identical
between kernel 7.1 and 7.2 — no update needed for 7.2.

---

## Fix 4 — missing `<linux/string.h>` (Soplos kernel 7.2+)

**Error in DKMS make.log:**
```
nvidia/os-interface.c: In function 'os_get_current_process_name':
nvidia/os-interface.c:732:5: error: implicit declaration of function 'strncpy' [-Wimplicit-function-declaration]
  732 |     strncpy(buf, current->comm, len - 1);
nvidia/os-interface.c:39:1: note: 'strncpy' is defined in header '<string.h>'; this is probably fixable by adding '#include <string.h>'
```

**Root cause:** `os_get_current_process_name()` in `nvidia/os-interface.c` calls `strncpy()` but
the file never includes `<linux/string.h>` directly — it relied on some other kernel header
(reached transitively through `nv-linux.h`) to pull it in. Starting with kernel 7.2 that header
no longer does so, and GCC treats an implicit function declaration as a hard error, not a warning.
Unrelated to the VMA locking issue in Fix 1 — different file, different API, different kernel
version boundary (7.2, not 7.0).

**Fix:** Add `#include <linux/string.h>` to `nvidia/os-interface.c`.

```bash
sudo patch --fuzz=5 -p1 -d /usr/src/nvidia-${NVIDIA_VER} < patches/nvidia-string-h-kernel7.2.patch
```

Version-independent — the missing include is the same regardless of NVIDIA driver branch
(550/580/590/610), so there is only one patch file for this fix, unlike Fix 1.

**Correction (2026-10-21):** the diagnosis above is incomplete. `strncpy()` is not just
undeclared because of a missing include: its prototype was removed from `include/linux/string.h`
between kernel 7.1 (`extern char * strncpy(...)` is there) and 7.2 (it is not). Adding the include
therefore does not make `strncpy()` available on 7.2+ for sources that still call it
(550.163.01 and 590.48.01 do; 610 already uses `strscpy()`). See Fix 6.

---

## Fix 5 — `dmem_cgroup_register_region()` nueva firma (Soplos kernel 7.3+)

**Afecta a:** NVIDIA 610 con el **driver abierto** (`nvidia-open`), tarjetas Turing / RTX 2000 en adelante. El driver propietario y las ramas 550/580/590 no usan esta ruta de código.

**Error en DKMS make.log:**
```
nvidia/os-interface.c:2820:48: error: passing argument 1 of 'dmem_cgroup_register_region'
  makes pointer from integer without a cast [-Wint-conversion]
```

**Causa raíz:** El commit del kernel `e11640b9cea4` ("cgroup/dmem: Introduce struct dmem_cgroup_init
for region initialization") cambió el primer argumento de `dmem_cgroup_register_region()`:

- **Antes (kernel ≤ 7.2):** `dmem_cgroup_register_region(u64 size, const char *name_fmt, ...)`
- **Ahora (kernel ≥ 7.3):** `dmem_cgroup_register_region(const struct dmem_cgroup_init *init, const char *name_fmt, ...)`

La estructura (confirmada en `include/linux/cgroup_dmem.h` de kernel 7.3):
```c
struct dmem_cgroup_init {
    u64 size;
    const struct dmem_cgroup_ops *ops;
    void *reclaim_priv;
};
```

NVIDIA 610 pasa `size` directamente como primer argumento; GCC lo rechaza con `-Wint-conversion` en kernel 7.3+.

**Fix:** Aplicar el parche, que envuelve la llamada en un guard `LINUX_VERSION_CODE`:

```bash
sudo patch --fuzz=5 -p1 -d /usr/src/nvidia-${NVIDIA_VER}/kernel-open < patches/nvidia-dmem-kernel7.3.patch
```

La rama `#else` conserva la llamada original intacta para kernel ≤ 7.2, por lo que el parche es seguro en cualquier versión. Las ramas 550/580/590 no se ven afectadas porque el bloque `#if defined(NV_USE_DMEM_CGROUP_API)` no existe en esas fuentes.

---

## Fix 6 — NVIDIA 550 on kernels 7.1 to 7.3 (`of_gpio.h`, `strncpy`, DRM atomic commit)

**Affects:** NVIDIA 550.163.01 as shipped by Debian (`nvidia-kernel-dkms`, proprietary kernel modules).
NVIDIA 590.48.01 has the same problems plus two more in `nvidia-uvm`; see Fix 7. NVIDIA 610 already
carries all of these fixes upstream.

**Errors in DKMS make.log:**
```
common/inc/nv-linux.h: fatal error: linux/of_gpio.h: No such file or directory
nvidia/os-interface.c: error: implicit declaration of function 'strncpy' [-Wimplicit-function-declaration]
nvidia-drm/nvidia-drm-drv.c:224: error: initialization of 'struct drm_atomic_commit * (*)(struct drm_device *)'
  from incompatible pointer type 'struct drm_atomic_state * (*)(struct drm_device *)'
```

**Root cause:** three independent kernel changes.

1. `include/linux/of_gpio.h` was removed: it exists in 7.0 and not in 7.1, 7.2 or 7.3.
   NVIDIA 610 handles it with a compatibility block for `of_get_named_gpio()`; 550 includes the header unconditionally.
2. `strncpy()` was removed from `include/linux/string.h` between 7.1 and 7.2 (see the correction under Fix 4).
   550.163.01 calls it in five places (`os-interface.c`, `linux_nvswitch.c` twice, `nvidia-modeset-linux.c`, `uvm_pmm_gpu.c`).
3. `struct drm_atomic_state` was renamed `struct drm_atomic_commit` in 7.2, together with `drm_atomic_state_alloc()`,
   `_get()`, `_put()`, `_clear()`, `_init()`, `_default_clear()` and `_default_release()`.
   NVIDIA's configure-time probes (`conftest.sh`) look for the old struct, so they report the pre-7.2
   behavior; five of them are forced for 7.2+: `NV_DRM_PLANE_ATOMIC_CHECK_HAS_ATOMIC_STATE_ARG`,
   `NV_DRM_CRTC_ATOMIC_CHECK_HAS_ATOMIC_STATE_ARG`, `NV_DRM_ATOMIC_STATE_REF_COUNTING_PRESENT`,
   `NV_DRM_ATOMIC_HELPER_SWAP_STATE_HAS_STALL_ARG` and `NV_DRM_ATOMIC_HELPER_SWAP_STATE_RETURN_INT`.

**Fix:** apply the patch from the root of the DKMS source tree of the NVIDIA 550 package (the directory under
`/usr/src` that contains `Kbuild`, `common/` and `nvidia/`):

```bash
sudo patch --fuzz=5 -p1 -d /usr/src/<nvidia-550-source-dir> < patches/nvidia-550-kernel7.2-compat.patch
```

The `strncpy()` replacements keep its behavior (copy up to `n` characters and pad with zeros), the
`of_gpio.h` block is selected with `__has_include()` and the DRM block is guarded by
`LINUX_VERSION_CODE >= KERNEL_VERSION(7, 2, 0)`, so the patch does not change the build on older kernels.

**Verified 2026-10-21 (compile only):** Debian forky `nvidia-kernel-source 550.163.01-5.1` built with gcc 16.2
against the headers of `7.3.0-soplos-bore-ntsync-v4` and of `7.2.11-soplos-bore-ntsync-v4`.
Unpatched, the build fails on both (on 7.3 with thousands of errors, the first one being `of_gpio.h`; on 7.2.11 it
stops at the first failing object, `strncpy()` in `os-interface.c`); patched, it builds `nvidia.ko`,
`nvidia-modeset.ko`, `nvidia-drm.ko`, `nvidia-uvm.ko` and `nvidia-peermem.ko` on both. The patch applies cleanly to the
original sources with `printf '%s' | patch --fuzz=5 -p1 -d <dir>`, as the Soplos tools do. The modules were not loaded on
hardware, and kernel 7.1 was not tested.

---

## Fix 7 — NVIDIA 590 open modules on kernels 7.2+ (`of_gpio.h`, `strncpy`, DRM atomic commit, `nvidia-uvm`)

**Affects:** NVIDIA 590.48.01 open kernel modules (`nvidia-open-590`, from the NVIDIA CUDA repository, sources under
`kernel-open/`). It also needs Fix 1 (`patches/nvidia-590-kernel7.patch`), which is a separate patch.

**Errors in DKMS make.log:**
```
common/inc/nv-linux.h:1717: fatal error: linux/of_gpio.h: No such file or directory
nvidia-uvm/uvm_pmm_gpu.c:3063: error: 'const struct dev_pagemap_ops' has no member named 'page_free'
nvidia-uvm/uvm_hmm.c:2143: error: too few arguments to function 'zone_device_page_init'; expected 3, have 1
```

**Root cause:** the three kernel changes described under Fix 6 (the `of_gpio.h` removal, the `strncpy()` removal and
the `drm_atomic_state` rename), plus two changes in `nvidia-uvm` that NVIDIA 610 already handles upstream:

1. `struct dev_pagemap_ops` renamed the `page_free` callback to `folio_free`, which takes a `struct folio *`.
2. `zone_device_page_init()` now takes the `dev_pagemap` and an order in addition to the page.

The patch adds the `of_gpio.h` compatibility block, replaces the five `strncpy()` calls, maps the renamed DRM names and
forces the five `nvidia-drm` probes, exactly as in Fix 6. For `nvidia-uvm` it backports the two `conftest.sh` probes that
610 ships (`dev_pagemap_ops_has_folio_free` and `zone_device_page_init_has_pgmap_and_order_args`), registers them in
`nvidia-uvm.Kbuild`, adds the `folio_free` wrappers for the three pagemap operation tables in `uvm_pmm_gpu.c`, and
wraps `zone_device_page_init()` in `uvm_hmm.c`. All of it is selected by the probes or by `LINUX_VERSION_CODE`, so the
build does not change on older kernels.

**Fix:** apply Fix 1 and then this patch from the `kernel-open/` directory of the DKMS source tree:

```bash
sudo patch --fuzz=5 -p1 -d /usr/src/nvidia-590.48.01/kernel-open < patches/nvidia-590-kernel7.patch
sudo patch --fuzz=5 -p1 -d /usr/src/nvidia-590.48.01/kernel-open < patches/nvidia-590-kernel7.2-compat.patch
```

**Verified 2026-10-22 (compile only):** `nvidia-kernel-open-dkms 590.48.01-1` from the CUDA `debian13` repository,
patched from the original sources with Fix 1 and this patch exactly as above, built with gcc 16.2 against
`7.3.0-soplos-bore-ntsync-v4` and `7.2.11-soplos-bore-ntsync-v4`: `nvidia.ko`, `nvidia-modeset.ko`, `nvidia-drm.ko`,
`nvidia-uvm.ko` and `nvidia-peermem.ko` on both. Unpatched, the build fails on 7.3. The modules were not loaded on
hardware, 590.44.01 was not tested, and neither was the proprietary (non-open) 590 package.

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
