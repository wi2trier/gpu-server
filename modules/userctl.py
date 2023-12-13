import os
import secrets
import subprocess
from typing import Annotated, Optional, Sequence

import typer

DATE_FORMAT = "%Y-%m-%d"

app = typer.Typer()


@app.callback()
def app_callback():
    if os.geteuid() != 0:
        typer.echo("Please run this script as root")
        raise typer.Abort()


def run_cmd(cmd: Sequence[str], **kwargs) -> str:
    return subprocess.check_output(cmd, **kwargs).decode("utf-8").rstrip("\n")


def check_email(user: str):
    if not user.endswith("@uni-trier.de"):
        raise typer.BadParameter("Only university mail addresses are allowed")

    return user.split("@")[0]


@app.command()
def add(
    user: Annotated[
        str,
        typer.Option(prompt=True, callback=check_email),
    ],
    full_name: Annotated[
        str,
        typer.Option(prompt=True),
    ],
    expire_date: Annotated[
        str,
        typer.Option(prompt=True),
    ],
) -> None:
    password = secrets.token_urlsafe()

    args: list[str] = [
        "--create-home",
        "--base-dir",
        "/home",
        "--gid",
        "100",
        "--shell",
        "/bin/bash",
        "--comment",
        full_name,
    ]

    if expire_date:
        args += ["--expiredate", expire_date]

    # https://manpages.ubuntu.com/manpages/jammy/en/man8/useradd.8.html
    run_cmd(["useradd", *args, user])

    # https://manpages.ubuntu.com/manpages/jammy/en/man1/passwd.1.html
    run_cmd(
        ["passwd", "--expire", "--stdin", user],
        input=password.encode("utf-8"),
    )

    typer.echo(f"Password for {user}: {password}")


@app.command()
def remove(
    user: Annotated[
        str,
        typer.Option(prompt=True, callback=check_email),
    ],
    force: bool = False,
    keep_home: bool = False,
) -> None:
    typer.confirm(f"Remove user {user}?", abort=True)

    args: list[str] = []

    if force:
        args.append("--force")

    if not keep_home:
        args.append("--remove")

    # https://manpages.ubuntu.com/manpages/jammy/en/man8/userdel.8.html
    run_cmd(["userdel", *args, user])


@app.command()
def edit(
    user: Annotated[
        str,
        typer.Option(prompt=True, callback=check_email),
    ],
    expire_date: Annotated[
        Optional[str],
        typer.Option(default=None),
    ],
) -> None:
    args: list[str] = []

    if expire_date:
        args += ["--expiredate", expire_date]

    # https://manpages.ubuntu.com/manpages/jammy/en/man8/useradd.8.html
    run_cmd(["usermod", *args, user])


if __name__ == "__main__":
    app()
