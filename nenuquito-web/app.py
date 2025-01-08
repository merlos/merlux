from flask import Flask, render_template, request, current_app
from flask_wtf.csrf import CSRFProtect
import subprocess

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
    app.run(debug=True)