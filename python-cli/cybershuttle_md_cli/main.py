import base64
import json
import logging
import os
import time
import webbrowser
import wsgiref.simple_server
from pathlib import Path
from urllib.parse import parse_qs, urlparse

import jwt
import requests
import typer
from rich import print

app = typer.Typer()

CUSTOS_CLIENT_ID = "custos-zxyrf1p8cdqgocemryez-10000000"
CUSTOS_CLIENT_SEC = "G5Vp0X5FEPUwVUUZP5w1Jo0bwyHf3OAPOUDZNKwZ"
CUSTOS_API_URL = "http://localhost:10000"
CUSTOS_TOKEN_ENDPOINT = f"{CUSTOS_API_URL}/identity-management/v1.0.0/token"

TOKEN_FILE = (
    Path(os.path.expanduser("~")) / ".config" / "cybershuttle" / "md_cli_token.json"
)

logger = logging.getLogger(__name__)


def get_authorization_url(redirect_uri: str) -> str:
    well_known_url = (
        f"{CUSTOS_API_URL}/identity-management/v1.0.0/.well-known/"
        f"openid-configuration?client_id={CUSTOS_CLIENT_ID}"
    )
    r = requests.get(well_known_url)
    r.raise_for_status()
    openid_config = r.json()
    authorization_endpoint = openid_config["authorization_endpoint"]
    # TODO: url encode query parameters
    authorization_url = (
        f"{authorization_endpoint}?response_type=code&client_id={CUSTOS_CLIENT_ID}"
        f"&redirect_uri={redirect_uri}&scope=openid"
    )
    return authorization_url


class _WSGIRequestHandler(wsgiref.simple_server.WSGIRequestHandler):
    """Custom WSGIRequestHandler.

    Uses a named logger instead of printing to stderr.
    """

    def log_message(self, format, *args):
        logger.info(format, *args)


class _RedirectWSGIApp(object):
    """WSGI app to handle the authorization redirect.

    Stores the request URI and displays the given success message.
    """

    def __init__(self, success_message):
        """
        Args:
            success_message (str): The message to display in the web browser
                the authorization flow is complete.
        """
        self.last_request_uri = None
        self._success_message = success_message

    def __call__(self, environ, start_response):
        """WSGI Callable.

        Args:
            environ (Mapping[str, Any]): The WSGI environment.
            start_response (Callable[str, list]): The WSGI start_response
                callable.

        Returns:
            Iterable[bytes]: The response body.
        """
        start_response("200 OK", [("Content-type", "text/plain; charset=utf-8")])
        self.last_request_uri = wsgiref.util.request_uri(environ)
        return [self._success_message.encode("utf-8")]


def get_authorization_code(request_uri: str) -> str:
    parsed_url = urlparse(request_uri)
    parsed_qs = parse_qs(parsed_url.query)
    return parsed_qs["code"][0]


def fetch_token(authorization_code: str, redirect_uri: str) -> dict:
    client_auth = get_client_auth_base64()

    r = requests.post(
        CUSTOS_TOKEN_ENDPOINT,
        headers={"Authorization": f"Bearer {client_auth}"},
        json={
            "grant_type": "authorization_code",
            "code": authorization_code,
            "redirect_uri": redirect_uri,
        },
        verify=False,
    )
    r.raise_for_status()
    return r.json()


def get_client_auth_base64() -> str:
    return base64.b64encode(f"{CUSTOS_CLIENT_ID}:{CUSTOS_CLIENT_SEC}".encode()).decode()


def refresh_token() -> dict | None:
    if not TOKEN_FILE.exists():
        return None
    token_data = read_token_file()
    refresh_token_value = token_data["refresh_token"]
    refresh_token_decoded = jwt.decode(
        refresh_token_value, options={"verify_signature": False}
    )
    if refresh_token_decoded["exp"] < time.time():
        # refresh token is expired
        return None

    r = requests.post(
        CUSTOS_TOKEN_ENDPOINT,
        headers={"Authorization": f"Bearer {get_client_auth_base64()}"},
        json={"grant_type": "refresh_token", "refresh_token": refresh_token_value},
        verify=False,
    )
    r.raise_for_status()
    return r.json()


def read_token_file() -> dict | None:
    if not TOKEN_FILE.exists():
        return None
    else:
        with open(TOKEN_FILE, "r") as f:
            return json.load(f)


def write_token_file(token_data: dict):
    TOKEN_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(TOKEN_FILE, "w") as f:
        json.dump(token_data, f)


def do_authorization_flow() -> dict:
    """Logs in user through browser and returns token response."""
    wsgi_app = _RedirectWSGIApp("Login was successful. You may close this window.")

    # Fail fast if the address is occupied
    wsgiref.simple_server.WSGIServer.allow_reuse_address = False
    host = "localhost"
    # TODO: have a pool of ports that can be tried and used
    port = 3000
    local_server = wsgiref.simple_server.make_server(
        host, port, wsgi_app, handler_class=_WSGIRequestHandler
    )

    redirect_uri = f"http://{host}:{port}/callback"
    authorization_url = get_authorization_url(redirect_uri)
    webbrowser.open(authorization_url, new=2)

    local_server.handle_request()

    # TODO: handle error responses. This assumes that last_request_uri has the
    # authorization code
    authorization_code = get_authorization_code(wsgi_app.last_request_uri)
    token_response = fetch_token(authorization_code, redirect_uri)

    # This closes the socket
    local_server.server_close()
    return token_response


@app.command()
def login():
    refreshed_token = refresh_token()
    if refreshed_token is not None:
        print("[green]You are already logged in.[/green]")
        write_token_file(refreshed_token)
    else:
        new_token = do_authorization_flow()
        print("[green]You are now logged in.[/green]")
        write_token_file(new_token)


@app.command()
def logout():
    print("Logout")


if __name__ == "__main__":
    app()
