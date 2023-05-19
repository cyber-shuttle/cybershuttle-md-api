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

app = typer.Typer()

CUSTOS_CLIENT_ID = "custos-ovwdqan5re9sxdr8bkvw-10000000"
CUSTOS_CLIENT_SEC = "puuwK8j8j8vYfquTZsuGcnxFfAdP8NsthDhC5B1E"
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
    token_data = r.json()
    write_token_file(token_data)
    return token_data


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
    write_token_file(token_response)

    # This closes the socket
    local_server.server_close()
    return token_response


def is_access_token_expired(token_data: dict) -> bool:
    access_token_expired = True
    if token_data is not None:
        access_token_value = token_data["access_token"]
        access_token_decoded = jwt.decode(
            access_token_value, options={"verify_signature": False}
        )
        # 60 second buffer so we don't return an access token that is about to expire
        access_token_expired = access_token_decoded["exp"] + 60 < time.time()
    return access_token_expired


def get_access_token(force_refresh=False) -> str | None:
    token_data = read_token_file()
    if token_data is None:
        return None

    # If access token is expired, we'll need to refresh it
    access_token_expired = is_access_token_expired(token_data)

    if force_refresh or access_token_expired:
        refreshed_token = refresh_token()
        if refreshed_token is not None:
            return refreshed_token["access_token"]
        else:
            return None
    else:
        return token_data["access_token"]
