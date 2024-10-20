# Merlux - Debian linux for merlos

Some scripts that I use on my linux life.

## Usage

```
sudo su
cd 
# Install git 
apt install -y git
# clone this repo
git clone https://github.com/merlos/merlux
cd merlux
# Run the bootstrap script
./bootstrap.sh
```

## etc configuration

Copy etc-sample to etc and setup

```
cp -R etc-sample etc
```

## user crontab

```sh
# Checks if VPN is up every min
0 * * * * cd;cd bin;./check-vpn-status.sh

# Log every 10 min what is the ping
0,10,20,30,40,50 * * * * cd;cd bin;./ping_logs.sh
```

## root Crontab

```
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin/

#m  h dom mon dow command

# Every day update openssh-server
0 0 * * * apt install -y openssh-server

# Restart VPN if it is down
* * * * * /root/merlux/sbin/restart_openvpn.sh
* * * * * /root/merlux/sbin/restart_wireguard.sh

# Check macs in the network to detect unknown
# because uses an nmap option that requires super user
0,10,20,30,40,50 * * * * cd; cd merlux/sbin;./check-macs.sh
```


## Repo Contents

* `boostrap.sh` Basic things to install on a fresh debian instance
* `/bin` commands run by the regular user (may require some setup)
* `/sbin` commands to be run by root (may require some setup)



