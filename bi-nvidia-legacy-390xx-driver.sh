#!/bin/bash

set -euo pipefail

# ============================================================
# Debian 13.7 Trixie
# NVIDIA Legacy 390xx
# Architecture: amd64 ONLY
# Mirror: mirrors.tuna.tsinghua.edu.cn
#
# IMPORTANT:
# - No apt upgrade
# - No i386
# - Sid is used ONLY for downloading source packages
# - Original /etc/apt/sources.list is restored before reboot
# - GRUB gets nvidia_drm.modeset=1
# ============================================================

MIRROR="https://mirrors.tuna.tsinghua.edu.cn/debian"
SOURCES="/etc/apt/sources.list"
SOURCES_BACKUP="/etc/apt/sources.list.nvidia390xx.backup"

DRIVER_DIR="$HOME/nvidia-390xx"
SETTINGS_DIR="$HOME/nvidia-settings"

PB_RESULT="/var/cache/pbuilder/result"

LOCAL_REPO_LINE="deb [trusted=yes] file:${PB_RESULT} ./"

echo
echo "============================================================"
echo " NVIDIA 390xx installer for Debian 13 / amd64"
echo "============================================================"
echo

# ------------------------------------------------------------
# Root check
# ------------------------------------------------------------

if [ "$EUID" -eq 0 ]; then
    echo "Please run this script as a normal user, not directly as root."
    echo "The script will use sudo when necessary."
    exit 1
fi

if ! sudo -v; then
    echo "sudo authentication failed."
    exit 1
fi

# ------------------------------------------------------------
# Architecture check
# ------------------------------------------------------------

ARCH="$(dpkg --print-architecture)"

if [ "$ARCH" != "amd64" ]; then
    echo "ERROR: This script is for amd64 only."
    echo "Detected architecture: $ARCH"
    exit 1
fi

echo "[OK] Architecture: amd64"

# ------------------------------------------------------------
# Debian version check
# ------------------------------------------------------------

if [ ! -r /etc/os-release ]; then
    echo "ERROR: /etc/os-release not found."
    exit 1
fi

. /etc/os-release

if [ "${ID:-}" != "debian" ]; then
    echo "ERROR: This script is for Debian."
    exit 1
fi

echo "[OK] Debian detected: ${VERSION_ID:-unknown}"

# ------------------------------------------------------------
# 1. Backup sources.list
# ------------------------------------------------------------

echo
echo "== 1. Backup and configure sources.list =="

if [ ! -f "$SOURCES_BACKUP" ]; then
    sudo cp -a "$SOURCES" "$SOURCES_BACKUP"
    echo "[OK] Backup created:"
    echo "     $SOURCES_BACKUP"
else
    echo "[OK] Backup already exists:"
    echo "     $SOURCES_BACKUP"
fi

sudo tee "$SOURCES" > /dev/null <<EOF
deb ${MIRROR}/ trixie main contrib non-free non-free-firmware
deb ${MIRROR}/ trixie-updates main contrib non-free non-free-firmware
deb ${MIRROR}-security trixie-security main contrib non-free non-free-firmware
deb-src ${MIRROR}/ unstable main contrib non-free non-free-firmware
EOF

echo "[OK] TUNA mirror configured."
echo "[OK] contrib enabled."
echo "[OK] Temporary Sid deb-src enabled."

# ------------------------------------------------------------
# 2. Install required packages
# ------------------------------------------------------------

echo
echo "== 2. Install required packages =="

sudo apt update -y

sudo apt install -y \
    pbuilder \
    linux-headers-amd64

# ------------------------------------------------------------
# 3. Create directories and download source
# ------------------------------------------------------------

echo
echo "== 3. Download NVIDIA 390xx source packages =="

mkdir -p "$DRIVER_DIR"
mkdir -p "$SETTINGS_DIR"

echo
echo "-- NVIDIA 390xx driver source --"

cd "$DRIVER_DIR"

apt source --download-only nvidia-legacy-390xx-driver

echo
echo "-- NVIDIA 390xx settings source --"

cd "$SETTINGS_DIR"

apt source --download-only nvidia-settings-legacy-390xx

echo
echo "[OK] Source packages downloaded."

# ------------------------------------------------------------
# 4. Remove Sid source immediately
# ------------------------------------------------------------

echo
echo "== 4. Remove temporary Sid source =="

sudo cp -a "$SOURCES" "${SOURCES}.with-sid"

sudo sed -i \
    '\|^deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ unstable |d' \
    "$SOURCES"

sudo apt update -y

echo "[OK] Sid source removed."

# ------------------------------------------------------------
# 5. Create amd64 pbuilder environment
# ------------------------------------------------------------

echo
echo "== 5. Create amd64 pbuilder environment =="

sudo pbuilder create \
    --distribution trixie \
    --architecture amd64

echo "[OK] amd64 pbuilder environment created."

# ------------------------------------------------------------
# 6. Compile NVIDIA 390xx driver
# ------------------------------------------------------------

echo
echo "== 6. Compile NVIDIA 390xx driver =="

cd "$DRIVER_DIR"

if ! ls ./*.dsc >/dev/null 2>&1; then
    echo "ERROR: No .dsc file found in:"
    echo "       $DRIVER_DIR"
    exit 1
fi

sudo pbuilder build ./*.dsc

echo "[OK] NVIDIA 390xx driver build finished."

# ------------------------------------------------------------
# 7. Compile NVIDIA settings
# ------------------------------------------------------------

echo
echo "== 7. Compile NVIDIA 390xx settings =="

cd "$SETTINGS_DIR"

if ! ls ./*.dsc >/dev/null 2>&1; then
    echo "ERROR: No .dsc file found in:"
    echo "       $SETTINGS_DIR"
    exit 1
fi

sudo pbuilder build ./*.dsc

echo "[OK] NVIDIA settings build finished."

# ------------------------------------------------------------
# 8. Check build results
# ------------------------------------------------------------

echo
echo "== 8. Check build results =="

if [ ! -d "$PB_RESULT" ]; then
    echo "ERROR: pbuilder result directory does not exist:"
    echo "       $PB_RESULT"
    exit 1
fi

echo
echo "Built packages:"
echo "------------------------------------------------------------"

find "$PB_RESULT" \
    -maxdepth 1 \
    -type f \
    -name '*.deb' \
    -printf '%f\n' | sort

echo "------------------------------------------------------------"

DEB_COUNT="$(find "$PB_RESULT" -maxdepth 1 -type f -name '*.deb' | wc -l)"

if [ "$DEB_COUNT" -eq 0 ]; then
    echo "ERROR: No .deb packages were produced."
    exit 1
fi

echo
echo "[OK] Found $DEB_COUNT Debian package(s)."

# ------------------------------------------------------------
# 9. Create local APT repository
# ------------------------------------------------------------

echo
echo "== 9. Configure local APT repository =="

cd "$PB_RESULT"

sudo dpkg-scanpackages . | sudo tee Packages > /dev/null
sudo gzip -kf Packages

# Remove an old identical local repo line if present.
sudo sed -i \
    '\|^deb \[trusted=yes\] file:/var/cache/pbuilder/result ./|d' \
    "$SOURCES"

echo "$LOCAL_REPO_LINE" | sudo tee -a "$SOURCES" > /dev/null

sudo apt update -y

echo "[OK] Local APT repository configured."

# ------------------------------------------------------------
# 10. Check NVIDIA packages, kernel and headers
# ------------------------------------------------------------

echo
echo "== 10. Check NVIDIA packages, kernel and headers =="

echo
echo "-- NVIDIA driver package --"
apt-cache policy nvidia-legacy-390xx-driver

echo
echo "-- NVIDIA settings package --"
apt-cache policy nvidia-settings-legacy-390xx

echo
echo "-- Current kernel --"
uname -r

echo
echo "-- Installed kernels --"
dpkg -l | grep '^ii' | grep linux-image || true

echo
echo "-- Installed headers --"
dpkg -l | grep '^ii' | grep linux-headers || true

echo
echo "-- Current kernel headers --"

KERNEL="$(uname -r)"
HEADER_LINK="/lib/modules/${KERNEL}/build"

if [ -e "$HEADER_LINK" ]; then
    echo "[OK] Headers found:"
    echo "     $HEADER_LINK"
else
    echo "[ERROR] Headers missing:"
    echo "        $HEADER_LINK"
    echo
    echo "Do not continue."
    exit 1
fi

# ------------------------------------------------------------
# 11. Install NVIDIA 390xx
# ------------------------------------------------------------

echo
echo "== 11. Install NVIDIA 390xx driver =="

sudo apt install -y \
    nvidia-legacy-390xx-driver \
    nvidia-settings-legacy-390xx

echo "[OK] NVIDIA 390xx packages installed."

# ------------------------------------------------------------
# 12. Backup GRUB and configure modeset
# ------------------------------------------------------------

echo
echo "== 12. Backup and configure GRUB =="

GRUB="/etc/default/grub"
GRUB_BACKUP="/etc/default/grub.nvidia390xx.backup"

if [ ! -f "$GRUB_BACKUP" ]; then
    sudo cp -a "$GRUB" "$GRUB_BACKUP"
    echo "[OK] GRUB backup created:"
    echo "     $GRUB_BACKUP"
else
    echo "[OK] GRUB backup already exists."
fi

echo
echo "Current GRUB command line:"
grep '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB" || true

# Remove an existing nvidia_drm.modeset parameter first.
sudo sed -i \
    's/[[:space:]]*nvidia_drm\.modeset=[^" ]*//g' \
    "$GRUB"

# Add modeset while preserving the existing command-line parameters.
CURRENT_CMDLINE="$(sudo sed -n 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/\1/p' "$GRUB")"

if [ -z "$CURRENT_CMDLINE" ]; then
    NEW_CMDLINE="nvidia_drm.modeset=1"
else
    NEW_CMDLINE="${CURRENT_CMDLINE} nvidia_drm.modeset=1"
fi

sudo sed -i \
    's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="'"${NEW_CMDLINE}"'"/' \
    "$GRUB"

echo
echo "New GRUB command line:"
grep '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB"

sudo update-grub

echo "[OK] GRUB updated."

# ------------------------------------------------------------
# 13. RESTORE ORIGINAL sources.list BEFORE REBOOT
# ------------------------------------------------------------

echo
echo "== 13. Restore original sources.list before reboot =="

if [ ! -f "$SOURCES_BACKUP" ]; then
    echo "ERROR: Original sources.list backup not found:"
    echo "       $SOURCES_BACKUP"
    echo
    echo "NOT rebooting."
    exit 1
fi

sudo cp -a "$SOURCES_BACKUP" "$SOURCES"

echo "[OK] Original sources.list restored."

echo
echo "Current sources.list:"
echo "------------------------------------------------------------"
grep -v '^#' "$SOURCES" || true
echo "------------------------------------------------------------"

# ------------------------------------------------------------
# Final verification
# ------------------------------------------------------------

echo
echo "============================================================"
echo " Installation completed."
echo "============================================================"
echo
echo "Original APT sources have been restored BEFORE reboot."
echo
echo "GRUB:"
grep '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB" || true
echo
echo "The system will reboot in 10 seconds."
echo "Press Ctrl+C now if you want to stop."
echo

sleep 10

sudo reboot

