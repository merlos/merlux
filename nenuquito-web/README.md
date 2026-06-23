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
Description=Gunicorn instance to serve nenuquito-web Flask app
After=network.target

[Service]
User=<user>
Group=<user>
WorkingDirectory=/<path>/nenuquito-web
Environment="PATH=/<path>/nenuquito-web/venv/bin:/usr/bin"
ExecStart=/<path>/nenuquito-web/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
```

Important:

- Keep `ExecStart` on a single line in systemd.
- Do not write `\app:app` (that becomes `\x07pp` internally because `\a` is an escape sequence).

## Running with Gunicorn

When using Gunicorn, the `app.run(...)` block in [app.py](app.py) is not used.
So `SSL_ENABLED`, `SSL_CERT_FILE`, and `SSL_KEY_FILE` from [config.py](config.py)
apply only to `python app.py` local runs.

### Option 1: Gunicorn handles TLS directly

```sh
cd nenuquito-web
./venv/bin/gunicorn --workers 3 --bind 0.0.0.0:8443 --certfile /path/to/nenuquito.crt --keyfile /path/to/nenuquito.key app:app
```

Recommended config values for this mode:

```python
config['HTTPS_ONLY'] = True
config['SSL_ENABLED'] = False  # ignored by Gunicorn anyway
```

### Option 2: Reverse proxy TLS (Nginx/Caddy) + Gunicorn HTTP upstream

Run Gunicorn on localhost HTTP:

```sh
cd nenuquito-web
./venv/bin/gunicorn --workers 3 --bind 127.0.0.1:5000 app:app
```

Set your proxy to send:

```txt
X-Forwarded-Proto: https
```

Recommended config values for this mode:

```python
config['HTTPS_ONLY'] = True
config['SSL_ENABLED'] = False
```

If your proxy does not send `X-Forwarded-Proto: https`, `HTTPS_ONLY=True` will
cause redirect loops.

### Troubleshooting

If you see:

```txt
ModuleNotFoundError: No module named '\x07pp'
```

Your Gunicorn app target was parsed as `\app:app` instead of `app:app`.
Use `app:app` exactly, with no leading backslash.

### Basic Auth with Gunicorn

Basic authentication is handled in Flask middleware, so it works the same with
Gunicorn. Keep these set in [config.py](config.py):

```python
config['BASIC_AUTH_USERNAME'] = 'your-user'
config['BASIC_AUTH_PASSWORD'] = 'strong-password'
```