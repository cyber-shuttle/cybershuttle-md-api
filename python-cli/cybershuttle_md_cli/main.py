import logging

import rich
import typer

from . import auth

app = typer.Typer()

logger = logging.getLogger(__name__)


@app.command()
def login():
    refreshed_token = auth.refresh_token()
    if refreshed_token is not None:
        rich.print("[green]You are already logged in.[/green]")
    else:
        # If we weren't able to refresh, we'll need to do the authorization flow
        auth.do_authorization_flow()
        rich.print("[green]You are now logged in.[/green]")


@app.command()
def logout():
    rich.print("TODO Logout")


if __name__ == "__main__":
    app()
