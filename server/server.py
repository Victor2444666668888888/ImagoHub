"""ImagoHub: local account service and Unsplash API gateway. Python 3.11+."""
from __future__ import annotations

import argparse
import base64
import hashlib
import hmac
import json
import os
from pathlib import Path
import re
import secrets
import smtplib
import sqlite3
import threading
import time
from collections import defaultdict, deque
from email.message import EmailMessage
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from http.cookies import SimpleCookie
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, urlencode, urlparse
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent
for line in (ROOT / '.env').read_text().splitlines() if (ROOT / '.env').exists() else []:
    if '=' in line and not line.lstrip().startswith('#'):
        key, value = line.split('=', 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))

DATA = Path(os.environ.get('IMAGOHUB_DATA_DIR', str(ROOT / 'data')))
DATA.mkdir(parents=True, exist_ok=True)
DB = DATA / 'accounts.sqlite3'
ACCESS_KEY = os.environ.get('UNSPLASH_ACCESS_KEY', '')
PRODUCTION = os.environ.get('APP_ENV', 'development') == 'production'
ALLOWED_ORIGINS = set(filter(None, os.environ.get('ALLOWED_ORIGINS', '').split(',')))
CACHE: dict[str, tuple[float, object]] = {}
CACHE_LOCK = threading.Lock()
ATTEMPTS: dict[str, deque] = defaultdict(deque)
ATTEMPTS_LOCK = threading.Lock()


def connection():
    conn = sqlite3.connect(DB, timeout=15)
    conn.row_factory = sqlite3.Row
    return conn


def initialize():
    with connection() as db:
        db.executescript('''
        PRAGMA journal_mode=WAL;
        CREATE TABLE IF NOT EXISTS accounts (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL, created_at REAL NOT NULL,
            username TEXT NOT NULL DEFAULT '');
        CREATE TABLE IF NOT EXISTS sessions (
            digest TEXT PRIMARY KEY, account_id TEXT NOT NULL, expires REAL NOT NULL);
        CREATE TABLE IF NOT EXISTS resets (
            digest TEXT PRIMARY KEY, account_id TEXT NOT NULL, expires REAL NOT NULL);
        ''')
        # Existing installations keep their accounts, passwords and sessions.
        if 'username' not in {row['name'] for row in db.execute('PRAGMA table_info(accounts)')}:
            db.execute("ALTER TABLE accounts ADD COLUMN username TEXT NOT NULL DEFAULT ''")


def password_hash(password: str, salt: bytes | None = None):
    salt = salt or secrets.token_bytes(16)
    result = hashlib.scrypt(password.encode(), salt=salt, n=16384, r=8, p=1, dklen=32)
    return base64.b64encode(salt + result).decode()


def password_valid(password, stored):
    raw = base64.b64decode(stored)
    return hmac.compare_digest(password_hash(password, raw[:16]), stored)


def digest(token):
    return hashlib.sha256(token.encode()).hexdigest()


def public_user(row):
    return {key: row[key] for key in ('id', 'name', 'email', 'username')}


class ApiError(Exception):
    def __init__(self, status, message):
        self.status, self.message = status, message


def validate_email(value):
    email = str(value or '').strip().lower()
    if len(email) > 254 or not re.fullmatch(r'[^\s@]+@[^\s@]+\.[^\s@]+', email):
        raise ApiError(400, 'Digite um e-mail válido.')
    return email


def validate_password(value):
    if not isinstance(value, str) or len(value) < 8 or len(value) > 256:
        raise ApiError(400, 'A senha deve ter entre 8 e 256 caracteres.')
    return value


def validate_username(value):
    username = str(value or '').strip()
    if len(username) > 100:
        raise ApiError(400, 'Use até 100 caracteres no nome de usuário.')
    return username


def unsplash(path, params=None, cache=True):
    if not ACCESS_KEY:
        raise ApiError(503, 'A busca de imagens ainda não está configurada no servidor.')
    url = 'https://api.unsplash.com' + path
    if params:
        url += '?' + urlencode(params)
    now = time.time()
    if cache:
        with CACHE_LOCK:
            stored = CACHE.get(url)
        if stored and stored[0] > now:
            return stored[1]
    try:
        request = Request(url, headers={'Authorization': 'Client-ID ' + ACCESS_KEY,
                                       'Accept-Version': 'v1', 'User-Agent': 'ImagoHub/1.0'})
        with urlopen(request, timeout=25) as response:
            result = json.load(response)
    except HTTPError as e:
        message = {401: 'A chave da Unsplash foi recusada.',
                   403: 'O limite da Unsplash foi atingido. Tente novamente mais tarde.',
                   404: 'Esta foto não está mais disponível.',
                   429: 'O limite da Unsplash foi atingido. Tente novamente mais tarde.'}.get(
                       e.code, 'A Unsplash não conseguiu concluir a solicitação.')
        raise ApiError(e.code if e.code in (404, 429) else 502, message) from e
    except (URLError, TimeoutError, OSError, json.JSONDecodeError) as e:
        raise ApiError(502, 'Não foi possível conectar à Unsplash. Tente novamente.') from e
    if cache:
        with CACHE_LOCK:
            if len(CACHE) > 256:
                CACHE.clear()
            CACHE[url] = (now + 300, result)
    return result


class Handler(BaseHTTPRequestHandler):
    server_version = 'ImagoHub/1.0'

    def log_message(self, fmt, *args):
        # Do not print passwords, authorization headers, reset tokens or query strings.
        print(f'{self.client_address[0]} {self.command} {urlparse(self.path).path}')

    def origin_allowed(self):
        origin = self.headers.get('Origin')
        if not origin:
            return True
        if origin in ALLOWED_ORIGINS:
            return True
        parsed = urlparse(origin)
        return not PRODUCTION and parsed.hostname in ('localhost', '127.0.0.1', '10.0.2.2')

    def reply(self, status, data):
        body = json.dumps(data, ensure_ascii=False).encode()
        self.send_response(status)
        origin = self.headers.get('Origin')
        if origin and self.origin_allowed():
            self.send_header('Access-Control-Allow-Origin', origin)
            self.send_header('Access-Control-Allow-Credentials', 'true')
            self.send_header('Vary', 'Origin')
        if getattr(self, 'pending_cookie', None):
            self.send_header('Set-Cookie', self.pending_cookie)
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PATCH, OPTIONS')
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.reply(200 if self.origin_allowed() else 403, {})

    def body(self):
        size = int(self.headers.get('Content-Length', 0))
        if size > 32768:
            raise ApiError(413, 'Solicitação muito grande.')
        try:
            value = json.loads(self.rfile.read(size))
        except (ValueError, UnicodeError) as e:
            raise ApiError(400, 'Dados inválidos.') from e
        if not isinstance(value, dict):
            raise ApiError(400, 'Dados inválidos.')
        return value

    def rate_limit(self):
        key = self.client_address[0]
        now = time.time()
        with ATTEMPTS_LOCK:
            attempts = ATTEMPTS[key]
            while attempts and attempts[0] < now - 300:
                attempts.popleft()
            if len(attempts) >= 30:
                raise ApiError(429, 'Muitas tentativas. Aguarde alguns minutos.')
            attempts.append(now)

    def account(self):
        token = self.headers.get('Authorization', '').removeprefix('Bearer ')
        if not token:
            cookie = SimpleCookie(self.headers.get('Cookie', ''))
            token = cookie['imagohub_session'].value if 'imagohub_session' in cookie else ''
        with connection() as db:
            row = db.execute('''SELECT a.* FROM accounts a JOIN sessions s
                ON a.id=s.account_id WHERE s.digest=? AND s.expires>?''',
                (digest(token), time.time())).fetchone()
        if not row:
            raise ApiError(401, 'Sua sessão expirou. Entre novamente.')
        return row

    def do_GET(self):
        self.handle_request('GET')

    def do_POST(self):
        self.handle_request('POST')

    def do_PATCH(self):
        self.handle_request('PATCH')

    def handle_request(self, method):
        self.pending_cookie = None
        try:
            if not self.origin_allowed():
                raise ApiError(403, 'Origem não autorizada.')
            path = urlparse(self.path).path.rstrip('/')
            query = {key: values[0] for key, values in parse_qs(urlparse(self.path).query).items()}
            if path.startswith('/api/'):
                path = path[4:]
            result, status = self.route(method, path, query), 200
        except ApiError as e:
            result, status = {'error': e.message}, e.status
        except sqlite3.IntegrityError:
            result, status = {'error': 'Este e-mail já está cadastrado.'}, 409
        except (ValueError, TypeError, KeyError):
            result, status = {'error': 'Confira os dados enviados.'}, 400
        except Exception as e:
            print('Internal error:', type(e).__name__)
            result, status = {'error': 'O servidor não conseguiu concluir a solicitação.'}, 500
        self.reply(status, result)

    def route(self, method, path, query):
        if method == 'GET' and path == '/health':
            return {'ok': True, 'unsplash_configured': bool(ACCESS_KEY), 'environment':
                    'production' if PRODUCTION else 'development'}
        if method == 'GET' and path in ('/photos', '/search/photos'):
            params = {'page': max(1, min(int(query.get('page', 1)), 1000)),
                      'per_page': max(1, min(int(query.get('per_page', 20)), 30))}
            if path == '/search/photos':
                keyword = query.get('query', '').strip()
                if not keyword or len(keyword) > 200:
                    raise ApiError(400, 'Digite uma palavra ou frase para buscar.')
                params['query'] = keyword
                for key, allowed in {
                    'orientation': ('portrait', 'landscape', 'squarish'),
                    'color': ('black_and_white', 'black', 'white', 'yellow', 'orange', 'red',
                              'purple', 'magenta', 'green', 'teal', 'blue'),
                    'content_filter': ('low', 'high'), 'order_by': ('relevant', 'latest'),
                }.items():
                    if key in query:
                        if query[key] not in allowed:
                            raise ApiError(400, 'Um dos filtros de busca é inválido.')
                        params[key] = query[key]
            else:
                params['order_by'] = query.get('order_by', 'popular')
                if params['order_by'] not in ('latest', 'popular', 'oldest'):
                    raise ApiError(400, 'Ordenação inválida.')
            return unsplash(path, params)
        match = re.fullmatch(r'/photos/([A-Za-z0-9_-]+)(/download)?', path)
        if method == 'GET' and match:
            params = {'ixid': query['ixid']} if 'ixid' in query else None
            return unsplash(path, params, cache=not bool(match[2]))
        if method == 'GET' and path == '/auth/me':
            return {'user': public_user(self.account())}
        if method in ('POST', 'PATCH') and path.startswith('/auth/'):
            self.rate_limit()
            body = self.body()
            if path == '/auth/register':
                email, password = validate_email(body.get('email')), validate_password(body.get('password'))
                name = str(body.get('name', '')).strip()
                if len(name) < 2 or len(name) > 100:
                    raise ApiError(400, 'Digite seu nome completo.')
                username = validate_username(body.get('username', name))
                with connection() as db:
                    db.execute('''INSERT INTO accounts
                        (id,name,email,password_hash,created_at,username) VALUES(?,?,?,?,?,?)''',
                        (secrets.token_hex(16), name, email, password_hash(password), time.time(), username))
                return {'message': 'Conta criada.'}
            if path == '/auth/login':
                email, password = validate_email(body.get('email')), str(body.get('password', ''))
                if len(password) > 256:
                    raise ApiError(400, 'Senha inválida.')
                with connection() as db:
                    row = db.execute('SELECT * FROM accounts WHERE email=?', (email,)).fetchone()
                    # Equal-cost hashing even when the account does not exist.
                    expected = row['password_hash'] if row else password_hash('invalid-account')
                    valid = password_valid(password, expected)
                    if not row or not valid:
                        raise ApiError(401, 'E-mail ou senha incorretos.')
                    token = secrets.token_urlsafe(32)
                    duration = 30 * 86400 if body.get('remember') else 86400
                    db.execute('INSERT INTO sessions VALUES(?,?,?)',
                               (digest(token), row['id'], time.time() + duration))
                self.pending_cookie = f'imagohub_session={token}; HttpOnly; Path=/; '
                self.pending_cookie += 'SameSite=None; Secure' if PRODUCTION else 'SameSite=Lax'
                if body.get('remember'):
                    self.pending_cookie += f'; Max-Age={duration}'
                return {'token': token, 'user': public_user(row)}
            if path == '/auth/logout':
                token = self.headers.get('Authorization', '').removeprefix('Bearer ')
                if not token:
                    cookie = SimpleCookie(self.headers.get('Cookie', ''))
                    token = cookie['imagohub_session'].value if 'imagohub_session' in cookie else ''
                with connection() as db:
                    db.execute('DELETE FROM sessions WHERE digest=?', (digest(token),))
                self.pending_cookie = 'imagohub_session=; HttpOnly; Path=/; Max-Age=0; SameSite=Lax'
                return {'message': 'Você saiu da conta.'}
            if path == '/auth/profile':
                row = self.account()
                name, email = str(body.get('name', '')).strip(), validate_email(body.get('email'))
                if len(name) < 2 or len(name) > 100:
                    raise ApiError(400, 'Digite um nome válido.')
                username = validate_username(body.get('username', row['username']))
                with connection() as db:
                    db.execute('UPDATE accounts SET name=?,email=?,username=? WHERE id=?',
                               (name, email, username, row['id']))
                return {'user': {'id': row['id'], 'name': name, 'email': email, 'username': username}}
            if path == '/auth/password-reset':
                email = validate_email(body.get('email'))
                with connection() as db:
                    row = db.execute('SELECT * FROM accounts WHERE email=?', (email,)).fetchone()
                    token = secrets.token_urlsafe(32)
                    if row:
                        db.execute('DELETE FROM resets WHERE account_id=?', (row['id'],))
                        db.execute('INSERT INTO resets VALUES(?,?,?)',
                                   (digest(token), row['id'], time.time() + 1800))
                smtp_host = os.environ.get('SMTP_HOST')
                if row and smtp_host:
                    message = EmailMessage()
                    message['Subject'] = 'Redefinir sua senha no ImagoHub'
                    message['From'] = os.environ.get('SMTP_FROM', os.environ.get('SMTP_USER', ''))
                    message['To'] = email
                    message.set_content('Seu código de recuperação (válido por 30 minutos):\n\n' + token +
                                        '\n\nAbra o ImagoHub > Esqueci minha senha > Já tenho um código.')
                    try:
                        with smtplib.SMTP(smtp_host, int(os.environ.get('SMTP_PORT', 587)), timeout=20) as smtp:
                            smtp.starttls()
                            if os.environ.get('SMTP_USER'):
                                smtp.login(os.environ['SMTP_USER'], os.environ['SMTP_PASSWORD'])
                            smtp.send_message(message)
                    except (OSError, smtplib.SMTPException) as e:
                        raise ApiError(503, 'O envio do e-mail falhou. Tente novamente mais tarde.') from e
                if PRODUCTION and not smtp_host:
                    raise ApiError(503, 'A recuperação por e-mail está indisponível no momento.')
                response = {'message': 'Se o e-mail estiver cadastrado, você receberá um código de recuperação.'}
                if not PRODUCTION and not smtp_host:
                    # Local development only: no claim that an email was sent.
                    response = {'message': 'Recuperação local: use o código abaixo para redefinir a senha.',
                                'local_code': token if row else ''}
                return response
            if path == '/auth/password-reset/confirm':
                email = validate_email(body.get('email'))
                password = validate_password(body.get('password'))
                with connection() as db:
                    row = db.execute('''SELECT a.id FROM accounts a JOIN resets r ON a.id=r.account_id
                        WHERE a.email=? AND r.digest=? AND r.expires>?''',
                        (email, digest(str(body.get('code', ''))), time.time())).fetchone()
                    if not row:
                        raise ApiError(400, 'Código inválido ou expirado. Solicite um novo código.')
                    db.execute('UPDATE accounts SET password_hash=? WHERE id=?', (password_hash(password), row['id']))
                    db.execute('DELETE FROM sessions WHERE account_id=?', (row['id'],))
                    db.execute('DELETE FROM resets WHERE account_id=?', (row['id'],))
                return {'message': 'Senha alterada. Entre com a nova senha.'}
        raise ApiError(404, 'Rota não encontrada.')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', default=os.environ.get('HOST', '127.0.0.1'))
    parser.add_argument('--port', type=int, default=int(os.environ.get('PORT', 8787)))
    args = parser.parse_args()
    if not PRODUCTION and args.host not in ('127.0.0.1', 'localhost', '::1'):
        raise SystemExit('Para acesso de outro dispositivo, use APP_ENV=production e configure ALLOWED_ORIGINS/SMTP.')
    initialize()
    print(f'ImagoHub API pronta em http://{args.host}:{args.port}')
    print('Unsplash configurada:', bool(ACCESS_KEY))
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == '__main__':
    main()
