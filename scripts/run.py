"""Run the API and Flutter together; stop only the processes started here."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
from urllib.request import ProxyHandler, build_opener
import json

ROOT = Path(__file__).resolve().parents[1]

def command(binary, arguments):
    if os.name == 'nt' and str(binary).lower().endswith(('.bat', '.cmd')):
        return ['cmd.exe', '/c', binary, *arguments]
    return [binary, *arguments]

def main():
    parser = argparse.ArgumentParser(description='Inicia o ImagoHub com a API local.')
    parser.add_argument('--device', default='chrome', help='chrome, edge, windows ou ID de flutter devices')
    parser.add_argument('--api-url', default='http://127.0.0.1:8787')
    args = parser.parse_args()
    flutter = shutil.which('flutter')
    if not flutter:
        raise SystemExit('Flutter não encontrado. Instale o SDK e adicione flutter/bin ao PATH. Veja LEIA-ME.md.')
    env = {**os.environ, 'CI': 'true', 'FLUTTER_SUPPRESS_ANALYTICS': 'true'}
    setup = subprocess.run(command(flutter, ['pub', 'get']), cwd=ROOT, env=env)
    if setup.returncode:
        raise SystemExit(setup.returncode)
    opener = build_opener(ProxyHandler({}))
    def ready():
        try:
            with opener.open('http://127.0.0.1:8787/health', timeout=1) as response:
                return json.load(response).get('ok') is True
        except (OSError, ValueError):
            return False
    api = None
    app = None
    code = 1
    try:
        if not ready():
            api = subprocess.Popen([sys.executable, '-u', str(ROOT / 'server/server.py')], cwd=ROOT, env=env)
            deadline = time.monotonic() + 15
            while not ready():
                if api.poll() is not None or time.monotonic() > deadline:
                    raise SystemExit('A API não iniciou. Confira server/.env e a porta 8787.')
                time.sleep(.2)
        tool_args = ['run', '-d', args.device, '--dart-define=API_BASE_URL=' + args.api_url]
        if args.device in ('chrome', 'edge', 'web-server'):
            tool_args.extend(['--web-hostname', '127.0.0.1', '--web-port', '8080'])
        app = subprocess.Popen(command(flutter, tool_args), cwd=ROOT, env=env)
        code = app.wait()
    except KeyboardInterrupt:
        code = 0
    finally:
        for process in (app, api):
            if process is not None and process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
    raise SystemExit(code)

if __name__ == '__main__':
    main()

