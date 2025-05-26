from flask import Flask, request, session, redirect, url_for, render_template_string
import logging
from logging.handlers import RotatingFileHandler
from functools import wraps
import os

app = Flask(__name__)
app.secret_key = 'cle_secrete'

os.makedirs('/var/log', exist_ok=True)

formatter = logging.Formatter('%(asctime)s [%(name)s] %(levelname)s: %(message)s')
handler = RotatingFileHandler('/var/log/auth.log', maxBytes=10000000, backupCount=5)
handler.setFormatter(formatter)
handler.setLevel(logging.INFO)

logger = logging.getLogger('auth')
logger.setLevel(logging.INFO)
logger.addHandler(handler)

USERS = {
    'admin': 'password123',
    'user': 'userpass'
}

LOGIN_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head>
    <title>Secure Login</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Inter', sans-serif;
        }

        body {
            min-height: 100vh;
            display: flex;
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
        }

        .container {
            position: relative;
            width: 100%;
            max-width: 400px;
            margin: auto;
            padding: 20px;
        }

        .login-box {
            background: rgba(255, 255, 255, 0.97);
            padding: 40px;
            border-radius: 16px;
            box-shadow: 0 8px 30px rgba(0, 0, 0, 0.1);
            backdrop-filter: blur(10px);
        }

        .header {
            text-align: center;
            margin-bottom: 30px;
        }

        .header h1 {
            color: #1e3c72;
            font-size: 28px;
            font-weight: 600;
            margin-bottom: 8px;
        }

        .header p {
            color: #666;
            font-size: 14px;
        }

        .form-group {
            margin-bottom: 24px;
        }

        .form-group label {
            display: block;
            color: #333;
            font-size: 14px;
            font-weight: 500;
            margin-bottom: 8px;
        }

        .form-group input {
            width: 100%;
            padding: 12px 16px;
            border: 2px solid #e1e1e1;
            border-radius: 8px;
            font-size: 14px;
            transition: all 0.3s ease;
        }

        .form-group input:focus {
            border-color: #2a5298;
            outline: none;
            box-shadow: 0 0 0 3px rgba(42, 82, 152, 0.1);
        }

        .error {
            background: #fee;
            color: #e41749;
            padding: 12px;
            border-radius: 8px;
            font-size: 14px;
            margin-bottom: 24px;
            border: 1px solid #fcc;
        }

        button {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 500;
            cursor: pointer;
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }

        button:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(42, 82, 152, 0.3);
        }

        button:active {
            transform: translateY(0);
            box-shadow: none;
        }

        .security-note {
            text-align: center;
            margin-top: 24px;
            color: #666;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="login-box">
            <div class="header">
                <h1>Secure Access</h1>
                <p>Please authenticate to continue</p>
            </div>
            {% if error %}
            <div class="error">
                {{ error }}
            </div>
            {% endif %}
            <form method="post">
                <div class="form-group">
                    <label for="username">Username</label>
                    <input type="text" id="username" name="username" required autocomplete="username">
                </div>
                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" required autocomplete="current-password">
                </div>
                <button type="submit">Sign In</button>
            </form>
            <div class="security-note">
                🔒 Protected by fail2ban - Multiple failed attempts will result in IP ban
            </div>
        </div>
    </div>
</body>
</html>
'''

PRIVATE_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head>
    <title>Secure Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Inter', sans-serif;
        }

        body {
            min-height: 100vh;
            background: #f5f7fa;
        }

        .navbar {
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            padding: 16px 24px;
            color: white;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }

        .navbar h1 {
            font-size: 20px;
            font-weight: 600;
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .avatar {
            width: 36px;
            height: 36px;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 500;
            text-transform: uppercase;
        }

        .username {
            font-size: 14px;
            font-weight: 500;
        }

        .content {
            max-width: 800px;
            margin: 40px auto;
            padding: 0 24px;
        }

        .welcome-card {
            background: white;
            border-radius: 16px;
            padding: 32px;
            text-align: center;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
        }

        .welcome-card h2 {
            color: #1e3c72;
            font-size: 24px;
            margin-bottom: 16px;
        }

        .welcome-card p {
            color: #666;
            font-size: 16px;
            line-height: 1.6;
            margin-bottom: 24px;
        }

        .logout-btn {
            display: inline-block;
            padding: 12px 24px;
            background: #e41749;
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 500;
            transition: all 0.3s ease;
        }

        .logout-btn:hover {
            background: #c01540;
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(228, 23, 73, 0.3);
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <h1>Secure Dashboard</h1>
        <div class="user-info">
            <div class="avatar">{{ username[0] }}</div>
            <span class="username">{{ username }}</span>
        </div>
    </nav>
    <div class="content">
        <div class="welcome-card">
            <h2>Welcome to the Private Area</h2>
            <p>You have successfully authenticated and accessed the secure content. This area is protected and only accessible to authorized users.</p>
            <a href="/logout" class="logout-btn">Sign Out</a>
        </div>
    </div>
</body>
</html>
'''

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'username' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        if username in USERS and USERS[username] == password:
            session['username'] = username
            logger.info(f'Authentication success from {request.remote_addr} for user {username}')
            return redirect(url_for('private'))
        else:
            logger.warning(f'Authentication failure from {request.remote_addr} for user {username}')
            error = 'Invalid username or password'
    
    return render_template_string(LOGIN_TEMPLATE, error=error)

@app.route('/private')
@login_required
def private():
    return render_template_string(PRIVATE_TEMPLATE, username=session['username'])

@app.route('/logout')
def logout():
    session.pop('username', None)
    return redirect(url_for('login'))

@app.route('/')
def index():
    return redirect(url_for('login'))

if __name__ == '__main__':
    os.system('touch /var/log/auth.log')
    os.system('chmod 666 /var/log/auth.log')
    app.run(host='0.0.0.0', port=5000) 