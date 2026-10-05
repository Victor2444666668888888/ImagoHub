"""Account and API behavior tests. No external network requests."""
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch
from urllib.error import HTTPError
from urllib.request import Request, urlopen

spec = importlib.util.spec_from_file_location('imago_server', Path(__file__).parents[1] / 'server.py')
server = importlib.util.module_from_spec(spec)
spec.loader.exec_module(server)


class QuietHandler(server.Handler):
    def log_message(self, *_):
        pass


class ServerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.previous_db = server.DB
        server.DB = Path(self.temp.name) / 'accounts.sqlite3'
        server.ATTEMPTS.clear()
        server.initialize()
        self.http = server.ThreadingHTTPServer(('127.0.0.1', 0), QuietHandler)
        self.thread = threading.Thread(target=self.http.serve_forever, daemon=True)
        self.thread.start()
        self.base = f'http://127.0.0.1:{self.http.server_port}'

    def tearDown(self):
        self.http.shutdown()
        self.http.server_close()
        self.thread.join()
        server.DB = self.previous_db
        self.temp.cleanup()

    def request(self, path, body=None, token=None, headers=None, method=None):
        hdr = {'Content-Type': 'application/json', **(headers or {})}
        if token:
            hdr['Authorization'] = 'Bearer ' + token
        request = Request(self.base + path, data=None if body is None else json.dumps(body).encode(),
                          headers=hdr, method=method)
        try:
            with urlopen(request, timeout=5) as response:
                return response.status, json.load(response), response.headers
        except HTTPError as e:
            return e.code, json.load(e), e.headers

    def register(self, email='victor@example.com'):
        return self.request('/auth/register', {'name': 'Victor Bonissoni', 'email': email, 'password': 'password123'})

    def login(self, email='victor@example.com', password='password123', remember=False):
        return self.request('/auth/login', {'email': email, 'password': password, 'remember': remember})

    def test_register_duplicate_and_password_storage(self):
        self.assertEqual(self.register()[0], 200)
        self.assertEqual(self.register()[0], 409)
        with server.connection() as db:
            value = db.execute('SELECT password_hash FROM accounts').fetchone()[0]
        self.assertNotIn('password123', value)
        self.assertTrue(server.password_valid('password123', value))
        self.assertFalse(server.password_valid('wrong', value))

    def test_username_accepts_spaces_accents_symbols_and_is_persisted(self):
        nickname = 'Victor • fotógrafo 🚗'
        status = self.request('/auth/register', {
            'name': 'Victor Bonissoni', 'email': 'victor@example.com',
            'password': 'password123', 'username': nickname})[0]
        self.assertEqual(status, 200)
        _, data, _ = self.login()
        self.assertEqual(data['user']['username'], nickname)
        token = data['token']
        new_nickname = 'V! c tor ♥'
        response = self.request('/auth/profile', {
            'name': 'Victor', 'email': 'victor@example.com', 'username': new_nickname},
            token, method='PATCH')
        self.assertEqual(response[0], 200)
        self.assertEqual(response[1]['user']['username'], new_nickname)
        self.assertEqual(self.request('/auth/me', token=token)[1]['user']['username'], new_nickname)
        self.assertEqual(self.login()[1]['user']['username'], new_nickname)

    def test_old_database_migrates_without_losing_existing_credentials(self):
        hashed = server.password_hash('password123')
        with server.connection() as db:
            db.execute('DROP TABLE accounts')
            db.execute('''CREATE TABLE accounts (
                id TEXT PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL, created_at REAL NOT NULL)''')
            db.execute('INSERT INTO accounts VALUES(?,?,?,?,?)',
                       ('legacy', 'Victor', 'victor@example.com', hashed, 1))
        server.initialize()
        status, data, _ = self.login()
        self.assertEqual(status, 200)
        self.assertEqual(data['user']['id'], 'legacy')
        self.assertEqual(data['user']['username'], '')
        with server.connection() as db:
            self.assertEqual(db.execute('SELECT password_hash FROM accounts').fetchone()[0], hashed)

    def test_password_can_be_corrected_after_registration_rejection(self):
        body = {'name': 'Victor', 'email': 'victor@example.com', 'username': 'V'}
        self.assertEqual(self.request('/auth/register', {**body, 'password': '🔑' * 4})[0], 400)
        self.assertEqual(self.request('/auth/register', {**body, 'password': '🔑' * 8})[0], 200)
        self.assertEqual(self.login(password='🔑' * 8)[0], 200)

    def test_validation_rejects_bad_email_short_password_and_empty_name(self):
        for name, email, password in [('Victor', 'invalid', 'password123'), ('Victor', 'v@example.com', 'short'),
                                      ('', 'v@example.com', 'password123')]:
            self.assertEqual(self.request('/auth/register', {'name': name, 'email': email, 'password': password})[0], 400)

    def test_login_me_logout_and_cookie_behavior(self):
        self.register()
        self.assertEqual(self.login(password='wrong')[0], 401)
        self.assertEqual(self.login(email='unknown@example.com')[0], 401)
        status, data, headers = self.login(remember=True)
        self.assertEqual(status, 200)
        self.assertIn('HttpOnly', headers['Set-Cookie'])
        self.assertIn('Max-Age=', headers['Set-Cookie'])
        token = data['token']
        self.assertEqual(self.request('/auth/me', token=token)[1]['user']['email'], 'victor@example.com')
        cookie = headers['Set-Cookie'].split(';', 1)[0]
        self.assertEqual(self.request('/auth/me', headers={'Cookie': cookie})[0], 200)
        self.assertEqual(self.request('/auth/logout', {}, token=token)[0], 200)
        self.assertEqual(self.request('/auth/me', token=token)[0], 401)

    def test_profile_update_and_email_uniqueness(self):
        self.register()
        self.register('other@example.com')
        token = self.login()[1]['token']
        self.assertEqual(self.request('/auth/profile', {'name': 'Victor', 'email': 'other@example.com'}, token, method='PATCH')[0], 409)
        self.assertEqual(self.request('/auth/profile', {'name': 'Victor', 'email': 'new@example.com'}, token, method='PATCH')[0], 200)
        self.assertEqual(self.login(email='new@example.com')[0], 200)
        self.assertEqual(self.login()[0], 401)

    def test_reset_code_single_use_and_session_invalidation(self):
        self.register()
        token = self.login()[1]['token']
        with patch.object(server, 'PRODUCTION', False), patch.dict(server.os.environ, {'SMTP_HOST': ''}):
            status, result, _ = self.request('/auth/password-reset', {'email': 'victor@example.com'})
        self.assertEqual(status, 200)
        self.assertIn('local_code', result)
        body = {'email': 'victor@example.com', 'password': 'newpassword123', 'code': result['local_code']}
        self.assertEqual(self.request('/auth/password-reset/confirm', {**body, 'code': 'wrong'})[0], 400)
        self.assertEqual(self.request('/auth/password-reset/confirm', body)[0], 200)
        self.assertEqual(self.request('/auth/password-reset/confirm', body)[0], 400)
        self.assertEqual(self.request('/auth/me', token=token)[0], 401)
        self.assertEqual(self.login(password='newpassword123')[0], 200)

    def test_production_reset_requires_email_transport(self):
        with patch.object(server, 'PRODUCTION', True), patch.dict(server.os.environ, {'SMTP_HOST': ''}):
            status = self.request('/auth/password-reset', {'email': 'unknown@example.com'})[0]
        self.assertEqual(status, 503)

    def test_origin_policy_and_body_limits(self):
        self.assertEqual(self.request('/health', headers={'Origin': 'https://unauthorized.example'})[0], 403)
        status, _, headers = self.request('/health', headers={'Origin': 'http://localhost:8080'})
        self.assertEqual(status, 200)
        self.assertEqual(headers['Access-Control-Allow-Origin'], 'http://localhost:8080')
        self.assertEqual(headers['Access-Control-Allow-Credentials'], 'true')
        self.assertEqual(self.request('/auth/register', {'extra': 'x' * 40000})[0], 413)

    def test_filters_download_and_id_validation(self):
        with patch.object(server, 'unsplash', return_value={'results': [], 'total': 0}) as api:
            status = self.request('/search/photos?query=woman%20with%20balloon&orientation=portrait&color=green&content_filter=high&page=2')[0]
            self.assertEqual(status, 200)
            args = api.call_args.args
            self.assertEqual(args[0], '/search/photos')
            self.assertEqual(args[1]['query'], 'woman with balloon')
            self.assertEqual(args[1]['page'], 2)
            self.assertEqual(args[1]['content_filter'], 'high')
            self.assertEqual(self.request('/search/photos?query=test&color=invalid')[0], 400)
            self.assertEqual(self.request('/photos/photo-id/download?ixid=tracking')[0], 200)
            self.assertEqual(api.call_args.kwargs['cache'], False)
            self.assertEqual(api.call_args.args[1], {'ixid': 'tracking'})
            self.assertEqual(self.request('/photos/https://external.example')[0], 404)

    def test_feed_is_cached_download_events_are_not(self):
        server.CACHE.clear()
        with patch.object(server, 'ACCESS_KEY', 'test-key'), patch.object(server, 'urlopen',
              side_effect=lambda *_args, **_kwargs: io.BytesIO(b'{"ok":true}')) as upstream:
            server.unsplash('/photos', {'page': 1})
            server.unsplash('/photos', {'page': 1})
            self.assertEqual(upstream.call_count, 1)
            server.unsplash('/photos/test/download', cache=False)
            server.unsplash('/photos/test/download', cache=False)
            self.assertEqual(upstream.call_count, 3)
        server.CACHE.clear()


if __name__ == '__main__':
    unittest.main()
