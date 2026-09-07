#!/usr/bin/env bash

# ==============================================================================
# 📱 Wireless ADB Auto-Connector for Flutter / Android
# ==============================================================================
# Fixes Flutter & scrcpy duplicate/mDNS device conflicts by switching to
# a single clean TCP/IP (IP:5555) connection and disconnecting TLS mDNS endpoints.
#
# Usage:
#   ./connect_wireless.sh            → auto-detect device
#   ./connect_wireless.sh 192.168.x.x → connect to specific IP
#
# Returns: exports ANDROID_DEVICE_ID env var with the connected IP:port
# Exit codes:
#   0 → connected successfully
#   1 → device not found / offline
# ==============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info()    { echo -e "${CYAN}$1${NC}"; }
log_success() { echo -e "${GREEN}$1${NC}"; }
log_warn()    { echo -e "${YELLOW}$1${NC}"; }
log_error()   { echo -e "${RED}$1${NC}"; }

if ! command -v adb &> /dev/null; then
    log_error "❌ ADB command not found in PATH. Please install or export Android Platform Tools."
    exit 1
fi

TARGET_IP="$1"

cleanup_mdns() {
    local mdns_devices
    mdns_devices=$(adb devices | grep -E '^adb-.*' | awk '{print $1}')
    for mdev in $mdns_devices; do
        log_warn "🧹 Disconnecting mDNS TLS endpoint: ${mdev}"
        adb disconnect "$mdev" 2>/dev/null || true
    done
}

verify_online() {
    local ip_port="$1"
    # Check if device is actually online (not offline/unauthorized)
    local state
    state=$(adb devices | grep "^${ip_port}" | awk '{print $2}')
    if [ "$state" = "device" ]; then
        return 0
    fi
    return 1
}

connect_and_verify() {
    local ip="$1"
    log_info "🌐 Connecting to ${ip}:5555..."
    adb connect "${ip}:5555" 2>/dev/null || true
    sleep 1

    if verify_online "${ip}:5555"; then
        cleanup_mdns
        log_success "✨ Android device ready: ${ip}:5555"
        # Export device ID for Makefile usage
        echo "${ip}:5555"
        return 0
    else
        log_error "❌ Device ${ip}:5555 is offline or unreachable."
        log_warn "   → Make sure phone is unlocked and on same Wi-Fi."
        log_warn "   → Run 'make wireless' again after unlocking the phone."
        return 1
    fi
}

# 1. If manual IP provided as argument
if [ -n "$TARGET_IP" ]; then
    log_info "➡️ Connecting to provided IP: ${TARGET_IP}:5555..."
    connect_and_verify "$TARGET_IP"
    exit $?
fi

# 2. Get list of active devices from adb
DEVICES=$(adb devices | grep -v "List of devices" | grep -v "^$" | awk '{print $1}')

IP_CONNECTED=""
MDNS_CONNECTED=""
USB_CONNECTED=""

for dev in $DEVICES; do
    if [[ "$dev" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
        IP_CONNECTED="$dev"
    elif [[ "$dev" =~ ^adb-.* ]]; then
        MDNS_CONNECTED="$dev"
    else
        USB_CONNECTED="$dev"
    fi
done

FOUND_IP=""

if [ -n "$USB_CONNECTED" ]; then
    log_info "🔌 Found USB device: ${USB_CONNECTED}"
    FOUND_IP=$(adb -s "$USB_CONNECTED" shell "ip -f inet addr show wlan0 2>/dev/null | grep -oE 'inet [0-9.]+' | cut -d' ' -f2" | tr -d '\r\n')
    log_info "⚙️ Enabling TCP/IP mode on port 5555..."
    adb -s "$USB_CONNECTED" tcpip 5555
    sleep 2

elif [ -n "$MDNS_CONNECTED" ]; then
    log_info "📶 Found mDNS Wireless device: ${MDNS_CONNECTED}"
    FOUND_IP=$(adb -s "$MDNS_CONNECTED" shell "ip -f inet addr show wlan0 2>/dev/null | grep -oE 'inet [0-9.]+' | cut -d' ' -f2" | tr -d '\r\n')
    log_info "⚙️ Enabling TCP/IP mode on port 5555..."
    adb -s "$MDNS_CONNECTED" tcpip 5555 2>/dev/null || true
    sleep 2

elif [ -n "$IP_CONNECTED" ]; then
    FOUND_IP="${IP_CONNECTED%:*}"
    log_info "🔍 Checking existing TCP/IP device: ${IP_CONNECTED}"
fi

if [ -n "$FOUND_IP" ]; then
    connect_and_verify "$FOUND_IP"
    exit $?
fi

log_warn "⚠️ No active Android device found."
log_info "👉 Tips:"
log_info "   1. Connect phone via USB once and run: ${GREEN}make wireless${CYAN}"
log_info "   2. Or specify IP manually:             ${GREEN}make wireless IP=192.168.x.x${CYAN}"
log_info "   3. Enable 'Wireless Debugging' in Developer Options on phone."
exit 1
