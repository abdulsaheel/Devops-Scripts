#!/bin/bash

# Variables
PARENT_IP="172.210.31.187"  # Replace with your parent's public IP
PARENT_API_ENDPOINT="http://$PARENT_IP:5000/add_child"

# Get the public IP of this instance
PUBLIC_IP=$(curl -s ifconfig.me)

# Function to install required packages
install_dependencies() {
    echo "Installing required packages..."
    sudo apt update
    sudo apt install -y netdata
}

# Function to install Netdata
install_netdata() {
    echo "Installing Netdata..."
    install_dependencies

    # Ensure the service is enabled and started
    sudo systemctl enable netdata
    sudo systemctl start netdata

    echo "Netdata installation completed."
}

# Function to get the path of stream.conf
get_stream_files_location() {
    # Define the stock configuration directory
    STOCK_CONFIG_DIR="/usr/lib/netdata/conf.d"

    # Find and return the location of stream configuration files
    local stream_files
    stream_files=$(find "$STOCK_CONFIG_DIR" -name "stream.conf")

    # Check if any stream files were found
    if [ -z "$stream_files" ]; then
        echo "No stream configuration files found in $STOCK_CONFIG_DIR."
        return 1
    fi

    echo "$stream_files"
    return 0
}

# Check if Netdata is already installed
if ! command -v netdata > /dev/null; then
    install_netdata
else
    echo "Netdata is already installed."
fi

# Request a new API key from the parent node
response=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"public_ip\":\"$PUBLIC_IP\"}" "$PARENT_API_ENDPOINT")
api_key=$(echo "$response" | jq -r '.api_key')

if [ "$api_key" = "null" ]; then
    echo "Failed to obtain API key. Response: $response"
    exit 1
fi

echo "Received API key: $api_key for public IP: $PUBLIC_IP"

# Get the path of stream.conf
STREAM_CONF=$(get_stream_files_location)

# Check if the STREAM_CONF variable is set
if [ -z "$STREAM_CONF" ]; then
    echo "Could not find stream.conf. Exiting."
    exit 1
fi

# Function to update settings in stream.conf
update_stream_conf() {
    local setting="$1"
    local value="$2"
    local conf_file="$3"

    # Use sed to update the setting directly
    sudo sed -i "s/^\s*$setting =.*/$setting = $value/" "$conf_file"
    echo "Updated: $setting = $value"
}

# Update or add settings under the [stream] section
update_stream_conf "enabled" "yes" "$STREAM_CONF"
update_stream_conf "destination" "$PARENT_IP:19999" "$STREAM_CONF"
update_stream_conf "ssl skip certificate verification" "yes" "$STREAM_CONF"
update_stream_conf "api key" "$api_key" "$STREAM_CONF"

# Update netdata.conf to allow network access
NETDATA_CONF="/etc/netdata/netdata.conf"
sudo sed -i 's/bind socket to IP = 127.0.0.1/bind socket to IP = 0.0.0.0/' "$NETDATA_CONF"

# Restart Netdata to apply changes
if sudo systemctl restart netdata; then
    echo "Netdata restarted successfully."
else
    echo "Failed to restart Netdata. Check the service status for more details."
    exit 1
fi

echo "Child node setup complete and streaming to parent at $PARENT_IP."
