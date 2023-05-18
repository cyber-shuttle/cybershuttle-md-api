import webbrowser

import requests
import typer

app = typer.Typer()

CUSTOS_CLIENT_ID = "custos-zxyrf1p8cdqgocemryez-10000000"
CUSTOS_CLIENT_SEC = "G5Vp0X5FEPUwVUUZP5w1Jo0bwyHf3OAPOUDZNKwZ"
CUSTOS_API_URL = "http://localhost:10000"
CUSTOS_REDIRECT_URI = "http://localhost:8080/callback"


def get_authorization_url():
    well_known_url = (
        f"{CUSTOS_API_URL}/identity-management/v1.0.0/.well-known/"
        f"openid-configuration?client_id={CUSTOS_CLIENT_ID}"
    )
    r = requests.get(well_known_url)
    r.raise_for_status()
    openid_config = r.json()
    authorization_endpoint = openid_config["authorization_endpoint"]
    authorization_url = (
        f"{authorization_endpoint}?response_type=code&client_id={CUSTOS_CLIENT_ID}"
        f"&redirect_uri={CUSTOS_REDIRECT_URI}&scope=openid"
    )
    return authorization_url


@app.command()
def login():
    authorization_url = get_authorization_url()
    webbrowser.open(authorization_url)


@app.command()
def logout():
    print("Logout")


if __name__ == "__main__":
    app()
