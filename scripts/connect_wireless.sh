#!/usr/bin/env bash

# ==============================================================================
# 📱 Wireless ADB Auto-Connector for Flutter / Android
# ==============================================================================
# Fixes Flutter & scrcpy duplicate/mDNS device conflicts by switching to
# a single clean TCP/IP (IP:5555) connection and disconnecting TLS mDNS endpoints.
# ==============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔍 Checking ADB & Connected Devices...${NC}"

if ! command -v adb &> /dev/null; then
    echo -e "${RED}❌ ADB command not found in PATH. Please install or export Android Platform Tools.${NC}"
    exit 1
fi

TARGET_IP="$1"

cleanup_mdns() {
    local mdns_devices
    mdns_devices=$(adb devices | grep -E '^adb-.*' | awk '{print $1}')
    for mdev in $mdns_devices; do
        echo -e "${YELLOW}🧹 Disconnecting duplicate mDNS TLS endpoint: ${mdev}${NC}"
        adb disconnect "$mdev" 2>/dev/null || true
    done
}

# 1. If manual IP provided as argument
if [ -n "$TARGET_IP" ]; then
    echo -e "${CYAN}➡️ Connecting directly to provided IP: ${TARGET_IP}:5555...${NC}"
    adb connect "${TARGET_IP}:5555"
    cleanup_mdns
    exit 0
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

# Try to extract Wi-Fi IP from available connections
if [ -n "$USB_CONNECTED" ]; then
    echo -e "${CYAN}🔌 Found USB device: ${USB_CONNECTED}${NC}"
    FOUND_IP=$(adb -s "$USB_CONNECTED" shell "ip -f inet addr show wlan0 2>/dev/null | grep -oE 'inet [0-9.]+' | cut -d' ' -f2" | tr -d '\r\n')
    echo -e "${CYAN}⚙️ Enabling TCP/IP mode on port 5555...${NC}"
    adb -s "$USB_CONNECTED" tcpip 5555
    sleep 1
elif [ -n "$MDNS_CONNECTED" ]; then
    echo -e "${CYAN}📶 Found mDNS Wireless device: ${MDNS_CONNECTED}${NC}"
    FOUND_IP=$(adb -s "$MDNS_CONNECTED" shell "ip -f inet addr show wlan0 2>/dev/null | grep -oE 'inet [0-9.]+' | cut -d' ' -f2" | tr -d '\r\n')
    echo -e "${CYAN}⚙️ Enabling TCP/IP mode on port 5555...${NC}"
    adb -s "$MDNS_CONNECTED" tcpip 5555 2>/dev/null || true
    sleep 1
elif [ -n "$IP_CONNECTED" ]; then
    echo -e "${GREEN}✅ Already connected via TCP/IP: ${IP_CONNECTED}${NC}"
    FOUND_IP="${IP_CONNECTED%:*}"
fi

if [ -n "$FOUND_IP" ]; then
    echo -e "${CYAN}🌐 Connecting to ${FOUND_IP}:5555...${NC}"
    adb connect "${FOUND_IP}:5555"
    
    # Clean up all mDNS duplicates
    cleanup_mdns

    echo -e "${GREEN}✨ Successfully configured wireless device: ${FOUND_IP}:5555${NC}"
    echo ""
    echo -e "${CYAN}📱 Flutter Device Status:${NC}"
    flutter devices
    exit 0
fi

echo -e "${YELLOW}⚠️ No active Android device found automatically.${NC}"
echo -e "${CYAN}👉 Tips to connect:${NC}"
echo -e "   1. Connect phone via USB once and run: ${GREEN}make wireless${NC}"
echo -e "   2. Or if phone is on Wi-Fi, provide its IP: ${GREEN}make wireless IP=192.168.x.x${NC}"
echo -e "   3. Enable 'Wireless Debugging' in Developer Options -> Pair device if needed."
exit 1
