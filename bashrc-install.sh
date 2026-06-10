#!/bin/bash

# 1. Define dependencies
PACKAGES="neofetch bc bsdmainutils iproute2"

echo "Step 1: Installing dependencies..."
sudo apt update
sudo apt install -y $PACKAGES

# 2. Define the Dashboard code block
DASHBOARD_CODE=$(cat << 'INNER_EOF'

# --- START OF CUSTOM DASHBOARD ---
# Run neofetch if installed
if command -v neofetch >/dev/null 2>&1; then
    neofetch
fi
echo ""

# Update check
if [ -f /var/lib/update-notifier/updates-available ]; then
    cat /var/lib/update-notifier/updates-available
else
    updates=$(apt list --upgradable 2>/dev/null | grep -vc "Listing...")
    if [ "$updates" -gt 0 ]; then
        echo -e "\e[1;33mPackages to upgrade: $updates\e[0m"
        echo "Run 'sudo apt upgrade' to install them."
    else
        echo -e "\e[1;32mYour system is up to date.\e[0m"
    fi
fi

# Human-readable Uptime
uptime_seconds=$(cat /proc/uptime | awk '{print $1}')
up_h=$(echo "$uptime_seconds/3600" | bc)
up_m=$(echo "($uptime_seconds%3600)/60" | bc)
echo -e "PC-Uptime: ${up_h}h ${up_m}m"

echo ""
echo -e "\e[1;34m------------------------- Network Overview --------------------------\e[0m"
(
  echo "INTERFACE IPv4-ADDRESS IPv6-ADDRESS(Global)";
  ip -br addr show up | grep -v '^lo' | awk '{
    iface=$1; ipv4="-"; ipv6="-";
    for(i=3;i<=NF;i++){
        if($i ~ /\./ && ipv4 == "-"){ sub(/\/.*/, "", $i); ipv4=$i }
        else if($i ~ /:/ && $i !~ /^fe80/ && ipv6 == "-"){ sub(/\/.*/, "", $i); ipv6=$i }
    }
    if (ipv4 != "-" || ipv6 != "-") { print iface, ipv4, ipv6 }
  }'
) | column -t
echo -e "\e[1;34m---------------------------------------------------------------------\e[0m"
# --- END OF CUSTOM DASHBOARD ---
INNER_EOF
)

# 3. Inject into .bashrc if not already present
if grep -q "START OF CUSTOM DASHBOARD" ~/.bashrc; then
    echo "Check: Dashboard is already in .bashrc. Skipping injection."
else
    echo "Step 2: Deploying dashboard to ~/.bashrc..."
    echo "$DASHBOARD_CODE" >> ~/.bashrc
    echo "Success: Dashboard deployed."
fi

echo "Step 3: Reloading configuration..."
source ~/.bashrc

echo "All done! Open a new terminal or type 'bash' to see it."
