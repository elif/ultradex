#!/bin/bash

# Script to install Redis Stack Server on Ubuntu

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting Redis Stack Server installation for Ubuntu..."

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo." >&2
  exit 1
fi

# 1. Add Redis repository GPG key
echo "Adding Redis GPG key..."
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
if [ $? -ne 0 ]; then
    echo "Failed to add Redis GPG key." >&2
    exit 1
fi
echo "GPG key added successfully."

# 2. Add Redis repository
echo "Adding Redis repository..."
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list
if [ $? -ne 0 ]; then
    echo "Failed to add Redis repository." >&2
    exit 1
fi
echo "Redis repository added successfully."

# 3. Update package list
echo "Updating package list..."
apt-get update -y
if [ $? -ne 0 ]; then
    echo "Failed to update package list." >&2
    exit 1
fi
echo "Package list updated successfully."

# 4. Install redis-stack-server
echo "Installing redis-stack-server..."
apt-get install -y redis-stack-server
if [ $? -ne 0 ]; then
    echo "Failed to install redis-stack-server." >&2
    exit 1
fi
echo "redis-stack-server installed successfully."

# 5. Enable redis-stack-server to start on boot
echo "Enabling redis-stack-server service..."
systemctl enable redis-stack-server
if [ $? -ne 0 ]; then
    echo "Failed to enable redis-stack-server service. You may need to do this manually." >&2
    # Not exiting on failure here as the installation itself succeeded.
else
    echo "redis-stack-server service enabled successfully."
fi

# 6. Start redis-stack-server service
echo "Starting redis-stack-server service..."
systemctl start redis-stack-server
if [ $? -ne 0 ]; then
    echo "Failed to start redis-stack-server service. Check status with 'systemctl status redis-stack-server'." >&2
    exit 1
fi

# Verify service is active
if systemctl is-active --quiet redis-stack-server; then
  echo "redis-stack-server service started and is active."
else
  echo "redis-stack-server service may not have started correctly. Please check status." >&2
  # Not exiting, but warning user.
fi

echo ""
echo "Redis Stack Server installation completed."
echo "You can check the status by running: systemctl status redis-stack-server"
echo "Default port is 6379."
echo "To use redis-cli with Redis Stack features, you might need to install redis-tools or use the one bundled with Redis Stack."

exit 0
