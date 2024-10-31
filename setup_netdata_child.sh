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
    sudo apt install -y curl netcat jq netdata
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

# Configure stream.conf on the child node
STREAM_CONF="/etc/netdata/stream.conf"

# Ensure the [stream] section exists
if ! sudo grep -q "\[stream\]" "$STREAM_CONF"; then
    echo "[stream]" | sudo tee -a "$STREAM_CONF" > /dev/null
fi

# Append or update settings under the [stream] section
{
    # Check if each setting exists; if not, print it
    if ! sudo grep -q "^enabled = yes" "$STREAM_CONF"; then
        echo "enabled = yes"
    fi
    if ! sudo grep -q "^destination = $PARENT_IP:19999" "$STREAM_CONF"; then
        echo "destination = $PARENT_IP:19999"
    fi
    if ! sudo grep -q "^ssl skip certificate verification = yes" "$STREAM_CONF"; then
        echo "ssl skip certificate verification = yes"
    fi
    if ! sudo grep -q "^api key = " "$STREAM_CONF"; then
        echo "api key = $api_key"
    fi
} | sudo tee -a "$STREAM_CONF" > /dev/null

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
