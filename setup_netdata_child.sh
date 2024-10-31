#!/bin/bash

# Variables
PARENT_IP="172.210.31.187"  # Replace with your parent's public IP
PARENT_API_ENDPOINT="http://$PARENT_IP:5000/add_child"

# Get the public IP of this instance
PUBLIC_IP=$(curl -s ifconfig.me)

# Function to install Netdata
install_netdata() {
    echo "Installing Netdata..."
    # Update package lists and install required dependencies
    sudo apt update
    sudo apt install -y netdata

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
response=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"public_ip\":\"$PUBLIC_IP\"}" $PARENT_API_ENDPOINT)
api_key=$(echo $response | jq -r '.api_key')

if [ "$api_key" = "null" ]; then
    echo "Failed to obtain API key. Response: $response"
    exit 1
fi

echo "Received API key: $api_key for public IP: $PUBLIC_IP"

# Configure stream.conf on the child node
STREAM_CONF="/etc/netdata/stream.conf"
sudo mkdir -p /etc/netdata

# Update stream.conf
sudo tee $STREAM_CONF > /dev/null <<EOL
[stream]
enabled = yes
destination = $PARENT_IP:19999
api key = $api_key  # Child public IP: $PUBLIC_IP
EOL

# Update netdata.conf to allow network access
NETDATA_CONF="/etc/netdata/netdata.conf"
sudo sed -i 's/bind socket to IP = 127.0.0.1/bind socket to IP = 0.0.0.0/' $NETDATA_CONF

# Restart Netdata to apply changes
sudo systemctl restart netdata

echo "Child node setup complete and streaming to parent at $PARENT_IP."
