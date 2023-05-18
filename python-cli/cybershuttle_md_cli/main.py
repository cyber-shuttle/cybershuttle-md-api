import base64
import webbrowser
import wsgiref.simple_server
from urllib.parse import parse_qs, urlparse

import requests
import typer

app = typer.Typer()

CUSTOS_CLIENT_ID = "custos-zxyrf1p8cdqgocemryez-10000000"
CUSTOS_CLIENT_SEC = "G5Vp0X5FEPUwVUUZP5w1Jo0bwyHf3OAPOUDZNKwZ"
CUSTOS_API_URL = "http://localhost:10000"


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
    token_endpoint = f"{CUSTOS_API_URL}/identity-management/v1.0.0/token"
    client_auth = base64.b64encode(
        f"{CUSTOS_CLIENT_ID}:{CUSTOS_CLIENT_SEC}".encode()
    ).decode()

    r = requests.post(
        token_endpoint,
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


def write_token(token_data: dict):
    # TODO
    pass


@app.command()
def login():
    wsgi_app = _RedirectWSGIApp("Login was successful. You may close this window.")

    # Fail fast if the address is occupied
    # TODO: have a pool of ports that can be tried and used
    wsgiref.simple_server.WSGIServer.allow_reuse_address = False
    host = "localhost"
    # port = 8080
    port = 3000
    local_server = wsgiref.simple_server.make_server(host, port, wsgi_app)

    redirect_uri = f"http://{host}:{port}/callback"
    authorization_url = get_authorization_url(redirect_uri)
    webbrowser.open(authorization_url, new=2)

    local_server.handle_request()

    # TODO: handle error responses. This assumes that last_request_uri has the
    # authorization code
    authorization_code = get_authorization_code(wsgi_app.last_request_uri)
    token_response = fetch_token(authorization_code, redirect_uri)
    print(token_response)

    # This closes the socket
    local_server.server_close()


@app.command()
def logout():
    print("Logout")


if __name__ == "__main__":
    app()
