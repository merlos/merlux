from flask import Flask, render_template, request, Response, redirect
from flask_wtf.csrf import CSRFProtect
import subprocess
import base64
import hmac

# configuration
from config import config


def get_status(command):
    status = ''
    try:
        command = ['/usr/bin/sudo', config['BIN_PATH'] + command + '.sh', 'status']
        result = subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        status = result.stdout.strip()
    except subprocess.CalledProcessError as e:
        status = f"Error: {e.stderr}"
    return status


def get_uptime():
    uptime = ''
    try:
        command = ['/usr/bin/uptime']
        result = subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        uptime = result.stdout.strip()
    except subprocess.CalledProcessError as e:
        uptime = f"Error: {e.stderr}"
    return uptime

app = Flask(__name__)
app.config.update(config)

csrf = CSRFProtect(app)


def _is_https_request() -> bool:
    """Return True when request is already using HTTPS."""
    if request.is_secure:
        return True

    forwarded_proto = request.headers.get('X-Forwarded-Proto', '')
    proto = forwarded_proto.split(',', 1)[0].strip().lower()
    return proto == 'https'


def _require_basic_auth():
    """Validate Authorization header against configured basic auth credentials."""
    expected_user = app.config.get('BASIC_AUTH_USERNAME', '')
    expected_pass = app.config.get('BASIC_AUTH_PASSWORD', '')

    # If credentials are not configured, disable auth enforcement.
    if not expected_user or not expected_pass:
        return None

    auth_header = request.headers.get('Authorization', '')
    if not auth_header.startswith('Basic '):
        return Response(
            'Authentication required',
            401,
            {'WWW-Authenticate': 'Basic realm="Login Required"'}
        )

    try:
        decoded = base64.b64decode(auth_header.split(' ', 1)[1]).decode('utf-8')
        username, password = decoded.split(':', 1)
    except Exception:
        return Response(
            'Invalid authentication header',
            401,
            {'WWW-Authenticate': 'Basic realm="Login Required"'}
        )

    user_ok = hmac.compare_digest(username, expected_user)
    pass_ok = hmac.compare_digest(password, expected_pass)
    if not (user_ok and pass_ok):
        return Response(
            'Invalid credentials',
            401,
            {'WWW-Authenticate': 'Basic realm="Login Required"'}
        )

    return None


@app.before_request
def enforce_security():
    https_only = app.config.get('HTTPS_ONLY', False)

    if https_only and not _is_https_request():
        https_url = request.url.replace('http://', 'https://', 1)
        return redirect(https_url, code=301)

    # Allow static and CSRF routes without explicit auth challenge.
    if request.endpoint in {'static'}:
        return None

    return _require_basic_auth()

@app.errorhandler(400)
def handle_csrf_error(e):
    return render_template('error.html', message="CSRF token is missing or invalid"), 400


@app.route('/', methods=['GET', 'POST'])
def index():
    type=''
    message=''
    # Based on the type of action, execute the corresponding script
    # no inputs from form are used directly to prevent command injection
    if request.method == 'POST':
        if 'internet_on' in request.form:
            type='tv-internet'
            script='tv-internet.sh'
            args='on'
        elif 'internet_off' in request.form:
            type='tv-internet'
            script='tv-internet.sh'
            args='off'
        elif 'motion_on' in request.form:
            type='motion'
            script='motion.sh'
            args='on'
        elif 'motion_off' in request.form:
            type='motion'
            script='motion.sh'
            args='off'
        else:
            message = "Invalid action."
            return render_template('index.html', 
                                   type='invalid', 
                                   message=message, 
                                   config=config)

        try:
            command = ['/usr/bin/sudo', config['BIN_PATH'] + script, args]
            print(command)
            result = subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            message = result.stdout
        except subprocess.CalledProcessError as e:
            message = f"Error: {e.stderr}"

    # Get the status
    tv_status = get_status('tv-internet')
    motion_status = get_status('motion') 
    uptime = get_uptime()

    # Render the template
    return render_template('index.html', 
                           type=type,
                           message=message, 
                           tv_status=tv_status, 
                           motion_status=motion_status,
                           uptime=uptime,
                           config=config)

if __name__ == '__main__':
    #app.run(host='192.168.2.1', port=5000, debug=True)
    ssl_enabled = app.config.get('SSL_ENABLED', False)
    ssl_cert = app.config.get('SSL_CERT_FILE', '')
    ssl_key = app.config.get('SSL_KEY_FILE', '')

    ssl_context = None
    if ssl_enabled:
        if ssl_cert and ssl_key:
            ssl_context = (ssl_cert, ssl_key)
        else:
            ssl_context = 'adhoc'

    app.run(
        host=app.config.get('HOST', '127.0.0.1'),
        port=app.config.get('PORT', 5000),
        debug=app.config.get('DEBUG', True),
        ssl_context=ssl_context,
    )