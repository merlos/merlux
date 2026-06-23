config = {}

# Server runtime configuration
config['HOST'] = '127.0.0.1'
config['PORT'] = 5000
config['DEBUG'] = True

# Secret key for CSRF protection
config['SECRET_KEY'] = 'Set your custom secret key here'

# Basic authentication credentials. Set both values to enable auth.
config['BASIC_AUTH_USERNAME'] = 'user'
config['BASIC_AUTH_PASSWORD'] = 'change-me-password'

# HTTPS controls
# When True, HTTP requests are redirected to HTTPS.
config['HTTPS_ONLY'] = True

# SSL context for local Flask server (python app.py)
config['SSL_ENABLED'] = True
config['SSL_CERT_FILE'] = '../etc/ssl/nenuquito.crt'
config['SSL_KEY_FILE'] = '../etc/ssl/nenuquito.key'

# Cloud address
config['CLOUD_URL']='http://cloud.lan/'

# DNS link
config['DNS_ADMIN_URL']='http://dns.lan/admin/'

# Cloud address
config['MOTION_URL']='http://motion/'

# Motion URL
config['MONITORING_URL']='http://monitoring/'


# Path to the bin folder
config['BIN_PATH']='./tests/bin/'

