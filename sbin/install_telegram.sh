#!/bin/bash
set -e

# Default installation base directory
DEFAULT_BASE_DIR="/opt"

# Parse command line arguments
BASE_DIR=${1:-$DEFAULT_BASE_DIR}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

echo "Installing telegram script to $BASE_DIR..."

# Create necessary directories if they don't exist
mkdir -p "$BASE_DIR/bin"
mkdir -p "$BASE_DIR/etc"

# Check if telegram user exists, create if it doesn't
if ! id -u telegram &>/dev/null; then
    echo "Creating telegram system user..."
    useradd -r -s /sbin/nologin telegram
fi

# Check if telegram group exists, create if it doesn't
if ! getent group telegram &>/dev/null; then
    echo "Creating telegram group..."
    groupadd -r telegram
fi

# Create telegram_users group for authorized users
if ! getent group telegram_users &>/dev/null; then
    echo "Creating telegram_users group..."
    groupadd telegram_users
fi

echo "Installing telegram.conf configuration file..."
# Only copy if it doesn't exist to avoid overwriting configuration
if [ ! -f "$BASE_DIR/etc/telegram.conf" ]; then
    cp -f "../etc/telegram.conf" "$BASE_DIR/etc/telegram.conf"
    chmod 400 "$BASE_DIR/etc/telegram.conf"  # Only owner can read
    chown telegram:telegram "$BASE_DIR/etc/telegram.conf"
    echo "Configuration file installed."
else
    echo "Configuration file already exists, not overwriting."
    # Ensure proper permissions anyway
    chmod 400 "$BASE_DIR/etc/telegram.conf"  # Only owner can read
    chown telegram:telegram "$BASE_DIR/etc/telegram.conf"
fi

# Create a wrapper script that will call the original telegram.sh
echo "Creating secure wrapper script..."
cat > "$BASE_DIR/bin/telegram-wrapper" << 'EOF'
#!/bin/bash
set -eu -o pipefail

# This wrapper executes the real telegram.sh script with the telegram user's permissions
# It ensures the config file can only be read by the telegram user

# Check if user is in the telegram_users group
if ! id -Gn | grep -qw "telegram_users"; then
    echo "Error: You are not authorized to use this command." >&2
    echo "Ask your system administrator to add you to the telegram_users group." >&2
    exit 1
fi

# Security check: Require exactly one argument
if [ $# -ne 1 ]; then
    echo "Usage: $(basename "$0") <message>" >&2
    exit 1
fi

# Use array to prevent word splitting and properly handle arguments with spaces or special characters
MESSAGE=("$1")

# Use an array with sudo to prevent any potential command injection
# -n = non-interactive, -u = user
# -- signifies end of sudo options
exec /usr/bin/sudo -n -u telegram -- "$BASE_DIR/bin/telegram.sh" "${MESSAGE[@]}"
EOF

# Copy the original telegram.sh script
echo "Installing telegram.sh script..."
cp -f "./telegram.sh" "$BASE_DIR/bin/telegram.sh"
chmod 500 "$BASE_DIR/bin/telegram.sh"  # Only owner can read/execute
chown telegram:telegram "$BASE_DIR/bin/telegram.sh"

# Set permissions for the wrapper script
chmod 755 "$BASE_DIR/bin/telegram-wrapper"  # Everyone can execute
chown root:root "$BASE_DIR/bin/telegram-wrapper"

# Create a symbolic link to the wrapper script in /usr/local/bin for easy access
if [ -L "/usr/local/bin/telegram" ]; then
    rm -f "/usr/local/bin/telegram"
fi
ln -sf "$BASE_DIR/bin/telegram-wrapper" "/usr/local/bin/telegram"

# Configure sudo access for the wrapper
SUDO_CONF="/etc/sudoers.d/telegram"
echo "Configuring sudo access..."
echo "%telegram_users ALL=(telegram) NOPASSWD: $BASE_DIR/bin/telegram.sh" > "$SUDO_CONF"
chmod 440 "$SUDO_CONF"

echo "Installation complete."
echo ""
echo "Usage Instructions:"
echo "-------------------"
echo "1. Add users to the telegram_users group to grant access:"
echo "   sudo usermod -aG telegram_users USERNAME"
echo ""
echo "2. Authorized users can send messages with:"
echo "   telegram \"Your message here\""
echo ""
echo "Installation directory: $BASE_DIR"