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
#* * * * * /root/bin/restart_openvpn.sh
* * * * * /root/bin/restart_wireguard.sh

# Check macs in the network to detect unknown
0,10,20,30,40,50 * * * * cd; cd bin;./check-macs.sh
```


## 
Contents:

* `boostrap.sh` Basic things to install on a just installed
* `/bin` commands run by regular users.
* `/sbin` commands to be run by root.



