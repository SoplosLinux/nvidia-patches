#!/bin/bash
# nvidia-550-deb14-pahole-fix.sh
#
# Fix: NVIDIA DKMS 550.x fails to build on Debian testing kernels with CONFIG_DEBUG_INFO_BTF_MODULES=y
#
# Root cause:
#   The NVIDIA Makefile checks for scripts/pahole-flags.sh to decide whether to wrap
#   pahole with an awk command stored in a variable (PAHOLE="awk 'BEGIN {...}'").
#   Debian 7.0.4+ kernels don't ship pahole-flags.sh (they use Makefile.btf instead),
#   so NVIDIA injects its awk wrapper. The new gen-btf.sh script invokes ${PAHOLE}
#   directly in the shell — shell expansion does NOT re-parse quotes, so awk receives
#   'BEGIN (with a literal apostrophe) as its program and errors out.
#
# Fix:
#   Create a stub pahole-flags.sh so NVIDIA detects the kernel handles pahole itself.
#   PAHOLE then defaults to the system pahole binary, which works correctly with
#   the PAHOLE_FLAGS already exported by Makefile.btf.
#
# Affected:  nvidia-dkms 550.x, Debian testing kernels >= 7.0.4 with BTF_MODULES=y
# Not affected: custom kernels without CONFIG_DEBUG_INFO_BTF_MODULES=y
#
# Differences vs 580.x fix:
#   - Targets nvidia-dkms 550.x (drivers de soporte extendido / legacy-next)
#   - La rama 550 es más conservadora; si tienes Turing o Ampere y no necesitas
#     las últimas features de 580, 550 es la opción estable recomendada por Debian.
#   - La causa raíz y el fix son idénticos: el bug está en el Makefile de NVIDIA,
#     no en los módulos del driver en sí.
#
# Usage: sudo bash nvidia-550-deb14-pahole-fix.sh [kernel-version]
#   kernel-version defaults to the newest installed 7.0.4+deb14 headers

set -e

KERNEL="${1:-}"

# Auto-detect kernel if not given
if [ -z "$KERNEL" ]; then
    KERNEL=$(ls /usr/src/ | grep -E '^linux-headers-[0-9].*deb[0-9]+-common$' \
        | sed 's/linux-headers-//;s/-common//' \
        | sort -V | tail -1)
    if [ -z "$KERNEL" ]; then
        echo "ERROR: No Debian kernel headers found in /usr/src/" >&2
        exit 1
    fi
    echo "Auto-detected kernel: $KERNEL"
fi

HEADERS_COMMON="/usr/src/linux-headers-${KERNEL}-common"
PAHOLE_FLAGS_SH="${HEADERS_COMMON}/scripts/pahole-flags.sh"

if [ ! -d "$HEADERS_COMMON" ]; then
    echo "ERROR: Headers not found: $HEADERS_COMMON" >&2
    exit 1
fi

if [ -f "$PAHOLE_FLAGS_SH" ]; then
    echo "pahole-flags.sh already exists, nothing to do."
else
    echo "Creating stub: $PAHOLE_FLAGS_SH"
    cat > "$PAHOLE_FLAGS_SH" << 'EOF'
#!/bin/sh
# SPDX-License-Identifier: GPL-2.0
# Stub: pahole flags are exported by scripts/Makefile.btf in this kernel.
# This file exists so DKMS modules (nvidia) do not override PAHOLE with an
# awk wrapper that breaks under the gen-btf.sh invocation model (>= 7.0.4).
exit 0
EOF
    chmod +x "$PAHOLE_FLAGS_SH"
    echo "Created."
fi

# Find nvidia 550.x version in dkms — filtra explícitamente la rama 550
NVIDIA_VER=$(dkms status 2>/dev/null | grep -oP 'nvidia/\K550[0-9.]+' | head -1)

# Fallback: si solo hay un nvidia en dkms y es 550.x tómalo igualmente
if [ -z "$NVIDIA_VER" ]; then
    NVIDIA_VER=$(dkms status 2>/dev/null | grep -oP 'nvidia/\K[0-9.]+' | grep '^550' | head -1)
fi

if [ -z "$NVIDIA_VER" ]; then
    echo "WARNING: Could not detect nvidia 550.x version in dkms, skipping rebuild."
    echo "Check with: dkms status | grep nvidia"
    echo "Run manually: sudo dkms install nvidia/<version> -k ${KERNEL}-amd64"
    exit 0
fi

KERNEL_FULL="${KERNEL}-amd64"
echo "Rebuilding nvidia/${NVIDIA_VER} for kernel ${KERNEL_FULL}..."
dkms remove "nvidia/${NVIDIA_VER}" -k "$KERNEL_FULL" 2>/dev/null || true
dkms install "nvidia/${NVIDIA_VER}" -k "$KERNEL_FULL"

echo ""
echo "Done. Check output above for errors."
echo "If successful, load the module with:"
echo "  sudo modprobe nvidia"
