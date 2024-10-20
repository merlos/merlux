# Nenuquito web

# Setup 

```sh
# go to main folder (where this README)
cd nenuquito-web 
# Create venv
python -m venv venv

# use the vcenv
source venv/bin/activate
# install requirements
pip install -r requirements.txt



# Bin setup

As root

```sh
cd bin
# change ownership (replace <user-grp>) with the user group
chown root:<user-grp> *

# ensure permissions only read and x
chmod 750 *
```

## Allow run as root the scripts
Edit the sudo
```sh
visudo 
```

This allows the <user> that runs the server to execute the scripts. Replace <user>

```
<user> ALL=(ALL) NOPASSWD: /<path>/nenuquito-web/bin/tv-internet.sh, /<path>/nenuquito-web/bin/motion.sh
```

## Add service

Replace `<user>` and `<path>`

```conf
[Unit]
Description=Gunicorn instance to serve nenuquit-web Flask app
After=network.target

[Service]
User=<user>
Group=<user>
WorkingDirectory=/
Environment="PATH=/usr/bin/;/<path</nenuquito-web/venv/bin"
ExecStart=/<path>/nenuquito-web/venv/bin/gunicorn --workers 3 --bind <ip-address>:<port> app:app

[Install]
WantedBy=multi-user.target
```