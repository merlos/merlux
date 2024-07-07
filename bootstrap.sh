#!/bin/bash

#
# A script to add stuff I like on a new Debian installation
#

# Run as root

DEBUG=false

######################################################################
#  Supporting functions 
#  From https://github.com/unicef/magasin/blob/main/installer/install-magasin.sh
######################################################################


# Function to display messages in red
echo_debug() {
  if [ "$DEBUG" = true ]; then
    printf "\033[38;5;208m%s\033[0m\n" "$@"
  fi
}


# Function to display a line of dashes with the width of the terminal window.
echo_line() {
    local width=$(tput cols)  # Get the width of the terminal window
    printf "%${width}s\n" | tr ' ' '-'  # Print dashes to fill the width
}

# Function to display messages prepending [ v ] (v = check)
echo_success() {
  printf "\033[32m[ \xE2\x9C\x93 ]\033[0m %s\n" "$@"
}


# Information message prepended  by [ i ]
echo_info() {
  printf "\033[34m[ i ]\033[0m %s\n" "$@"
}


# Function to display failure to comply with a condition.
# Prepends and x. 
echo_fail() {
    printf "\033[31m[ \xE2\x9C\x97 ]\033[0m %s\n" "$@" # \e[31m sets the color to red, \e[0m resets the color
}


# Function to display warning messages.
# Prepends two !! in orangish color.
echo_warning() {
    printf "\033[38;5;208m[ W ]\033[0m %s\n" "$@" 
}


# Function to display error messages in red. Prepends ERROR
echo_error() {
    printf "\033[31mERROR:\033[0m %s\n" "$@"
}


# Exit displaying how to debug
exit_error() {
  local code=$1
  echo_error "$code" 
  echo_error "You may get more information about the issue by running the script including the debug option (-d):"
  echo_error "       $script_name -d "
  echo ""
  exit $code
}

#
# End of supporting functions 
#

#################################################
# Main Script
#################################################

#
# Install basic packages
#
echo_info "Installing preferred packages..."
apt update
#apt install -y nmap jed iperf3 iptables-persistent
echo_success "Basic packages installed"

#
# Display the hostname in a cool way
#
echo_line
echo_info "Adding cool letters to /etc/profile..."
#apt install -y lolcat toilet figlet
#echo "toilet -f smmono12 `hostname` | /usr/games/lolcat" >> /etc/profile

#
# Launch the uptime records
#
echo_line
echo_info "Setting up uptime records..."
#apt install -y uptimed
echo_info "Starting uptimed..."
#systemctl enable uptimed
#systemctl start uptimed

#
# Create the bin folder and add it to the path
#
echo_line
echo_info "Creating ~bin folder and adding it to path..."
cd ~
#mkdir -p bin
#chmod 700 bin
#echo "export PATH=$PATH:~/bin" >> .bash_profile
echo_success "Created ~bin folder and added it to path."

#
# Setup wireguard
#
echo_line
echo_info "Downloading wireguard..."
apt install -y wireguard wireguard-tools

echo_info "Crearing the folder /etc/wireguard, and assigning permissiosn"
#mkdir -p /etc/wireguard
#chown root:root /etc/wireguard
#chmod 700 /etc/wireguard
echo_success "Base setup of wireguard completed"
echo_info "Create a new config file in the server using the command"
HOSTNAME=`hostname`
echo_info "pivpn add --name $HOSTNAME"

#
#
#