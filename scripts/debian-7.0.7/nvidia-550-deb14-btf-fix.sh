#!/bin/bash
# nvidia-550-deb14-btf-fix.sh
#
# Fix: NVIDIA DKMS fails to build on Debian kernel 7.0.7+deb14 with CONFIG_DEBUG_INFO_BTF_MODULES=y
#
# Root cause:
#   Debian kernel 7.0.7 ships with CONFIG_DEBUG_INFO_BTF_MODULES=y, which causes
#   the kernel build system to invoke gen-btf.sh via a make rule in Makefile.modfinal.
#   The make variable expansion of cmd_btf_ko passes an awk program through the
#   escsq/make-cmd machinery, which generates a command-line awk invocation with
#   a quote character that awk rejects as invalid:
#
#     awk: cmd. line:1: 'BEGIN
#     awk: cmd. line:1: ^ invalid char ''' in expression
#
#   This is a build system incompatibility between the Debian 7.0.7 kernel headers
#   and the NVIDIA DKMS build — it does not affect the driver functionality itself,
#   nor custom kernels built without CONFIG_DEBUG_INFO_BTF_MODULES=y.
#
# Fix:
#   Pass CONFIG_DEBUG_INFO_BTF_MODULES= (empty) to the NVIDIA DKMS make invocation
#   by patching the MAKE[0] line in /usr/src/nvidia-<version>/dkms.conf.
#   This disables BTF module generation only for the NVIDIA build, which does not
#   need it — nvidia modules do not expose BTF type information.
#
# Nota: en Debian el paquete 550 se registra en dkms como "nvidia-current",
#       no como "nvidia". El script detecta ambas formas.
#
# Affected:  nvidia-kernel-dkms 550.x, Debian kernel >= 7.0.7+deb14-amd64
# Not affected: custom kernels without CONFIG_DEBUG_INFO_BTF_MODULES=y
#
# Usage: sudo bash nvidia-550-deb14-btf-fix.sh [nvidia-version]
#   nvidia-version defaults to the newest installed nvidia DKMS version

set -e

NVIDIA_VER="${1:-}"

# Auto-detect nvidia version if not given
if [ -z "$NVIDIA_VER" ]; then
    DKMS_ENTRY=$(dkms status 2>/dev/null | grep -E '^nvidia(-current)?/' | grep '/550\.' | head -1)
    if [ -z "$DKMS_ENTRY" ]; then
        echo "ERROR: Could not detect nvidia 550.x in dkms." >&2
        echo "Pass the version manually: sudo bash $0 550.163.01" >&2
        exit 1
    fi
    NVIDIA_NAME=$(echo "$DKMS_ENTRY" | grep -oP '^nvidia(-current)?')
    NVIDIA_VER=$(echo "$DKMS_ENTRY"  | grep -oP '^nvidia(-current)?/\K[0-9.]+')
else
    NVIDIA_NAME="nvidia"
fi

echo "Auto-detected: ${NVIDIA_NAME}/${NVIDIA_VER}"

DKMS_CONF="/usr/src/nvidia-${NVIDIA_VER}/dkms.conf"

if [ ! -f "$DKMS_CONF" ]; then
    echo "ERROR: dkms.conf not found: $DKMS_CONF" >&2
    exit 1
fi

if grep -q "CONFIG_DEBUG_INFO_BTF_MODULES=" "$DKMS_CONF"; then
    echo "Fix already applied in $DKMS_CONF, nothing to do."
else
    echo "Patching $DKMS_CONF ..."
    sed -i 's/IGNORE_XEN_PRESENCE=1 modules/IGNORE_XEN_PRESENCE=1 CONFIG_DEBUG_INFO_BTF_MODULES= modules/' "$DKMS_CONF"
    echo "Patched."
fi

# Auto-detect kernel
KERNEL=$(ls /usr/src/ | grep -E '^linux-headers-[0-9].*deb[0-9]+-amd64$' \
    | sed 's/linux-headers-//' \
    | sort -V | tail -1)

if [ -z "$KERNEL" ]; then
    echo "WARNING: Could not detect Debian kernel headers, skipping rebuild."
    echo "Run manually: sudo dkms install ${NVIDIA_NAME}/${NVIDIA_VER} -k <kernel-version>"
    exit 0
fi

echo "Auto-detected kernel: $KERNEL"
echo "Rebuilding ${NVIDIA_NAME}/${NVIDIA_VER} for kernel ${KERNEL}..."

dkms remove "${NVIDIA_NAME}/${NVIDIA_VER}" -k "$KERNEL" 2>/dev/null || true
dkms build  "${NVIDIA_NAME}/${NVIDIA_VER}" -k "$KERNEL"
dkms install "${NVIDIA_NAME}/${NVIDIA_VER}" -k "$KERNEL"

echo ""
echo "Done. Check output above for errors."
echo "If successful, reboot to load the new kernel and driver."
