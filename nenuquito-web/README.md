# Nenuquito web

## Setup 

```sh
# go to main folder (where this README)
cd nenuquito-web 
# Create venv
python -m venv venv

# use the venv
source venv/bin/activate
# install requirements
pip install -r requirements.txt

# run the app (debug mode)
python app.py
```

## Security configuration

Update [config.py](config.py) with your desired values:

```python
# Enable basic auth by setting both values
config['BASIC_AUTH_USERNAME'] = 'admin'
config['BASIC_AUTH_PASSWORD'] = 'change-me'

# Redirect all HTTP requests to HTTPS when True
config['HTTPS_ONLY'] = True

# TLS for local Flask app execution
config['SSL_ENABLED'] = True
config['SSL_CERT_FILE'] = '/path/to/nenuquito.crt'
config['SSL_KEY_FILE'] = '/path/to/nenuquito.key'
```

Notes:

- If `SSL_ENABLED` is `True` and cert/key are empty, Flask uses an ad-hoc self-signed certificate.
- `HTTPS_ONLY` is useful behind a reverse proxy too (it honors `X-Forwarded-Proto: https`).
- If basic auth username/password are empty, auth is disabled.

## /bin folder setup

The bin folder has some scripts that need to be run with root permissions.

As root

```sh
cd bin
# change ownership (replace <user-grp>) with the user group
chown root:<user-grp> *

# Ensure permissions only read and execute for group
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