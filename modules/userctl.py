import os
import secrets
import subprocess
from collections.abc import Sequence
from datetime import datetime
from typing import Annotated, Mapping, Optional

import typer

DATE_FORMAT = "%Y-%m-%d"
ZFS_TANK = "data"

app = typer.Typer()


@app.callback()
def app_callback():
    if os.geteuid() != 0:
        typer.echo("Please run this script as root")
        raise typer.Abort()


def run_cmd(cmd: Sequence[str], input: str | None = None) -> str:
    cmd_kwargs = {}

    if input:
        cmd_kwargs["input"] = input.encode("utf-8") + b"\n"

    return subprocess.check_output(cmd, **cmd_kwargs).decode("utf-8").rstrip("\n")


def check_email(user: str):
    if not user.endswith("@uni-trier.de"):
        raise typer.BadParameter(
            "Please provide the university email address, the script determines the username automatically"
        )

    return user.lower().split("@")[0]


def zfs_options(kwargs: Mapping[str, str]) -> list[str]:
    args: list[str] = []

    for key, value in kwargs.items():
        args += ["-o", f"{key}={value}"]

    return args


@app.command()
def add(
    user: Annotated[
        str,
        typer.Argument(callback=check_email),
    ],
    full_name: Annotated[str, typer.Option()],
    expire_date: Annotated[
        Optional[datetime],
        typer.Option(formats=[DATE_FORMAT]),
    ] = None,
    quota: Annotated[Optional[str], typer.Option()] = None,
) -> None:
    password = secrets.token_urlsafe()
    homedir = f"/home/{user}"

    zfs_args: dict[str, str] = {}

    if quota:
        zfs_args["quota"] = quota

    # https://manpages.ubuntu.com/manpages/jammy/en/man8/zfs.8.html
    run_cmd(["zfs", "create", *zfs_options(zfs_args), f"{ZFS_TANK}/{homedir}"])

    # copy skeleton
    run_cmd(["cp", "--recursive", "/etc/skel/.", homedir])

    useradd_args: list[str] = [
        "--home-dir",
        homedir,
        "--shell",
        "/bin/bash",
        "--comment",
        full_name,
    ]

    if expire_date:
        useradd_args += ["--expiredate", expire_date.strftime(DATE_FORMAT)]

    # https://manpages.ubuntu.com/manpages/jammy/en/man8/useradd.8.html
    run_cmd(["useradd", *useradd_args, user])

    # set permissions
    run_cmd(["chown", "-R", f"{user}:{user}", homedir])
    run_cmd(["chmod", "750", homedir])

    # https://manpages.ubuntu.com/manpages/jammy/en/man8/chpasswd.8.html
    run_cmd(["chpasswd"], input=f"{user}:{password}")

    # https://manpages.ubuntu.com/manpages/jammy/en/man1/passwd.1.html
    run_cmd(["passwd", "--expire", user])

    typer.echo("Login data for new user:")
    typer.echo(f"Username: {user}")
    typer.echo(f"Password: {password}")
    typer.echo("The initial password has to be changed on the first login.")


@app.command()
def remove(
    user: Annotated[
        str,
        typer.Argument(callback=check_email),
    ],
    force: bool = False,
    keep_home: bool = False,
) -> None:
    typer.confirm(f"Remove user {user}?", abort=True)

    userdel_args: list[str] = []

    if force:
        userdel_args.append("--force")

    # https://manpages.ubuntu.com/manpages/jammy/en/man8/userdel.8.html
    run_cmd(["userdel", *userdel_args, user])

    if not keep_home:
        run_cmd(["zfs", "destroy", "--force", f"{ZFS_TANK}/home/{user}"])


@app.command()
def edit(
    user: Annotated[
        str,
        typer.Argument(callback=check_email),
    ],
    expire_date: Annotated[
        Optional[datetime],
        typer.Option(formats=[DATE_FORMAT]),
    ] = None,
    quota: Annotated[Optional[str], typer.Option()] = None,
) -> None:
    usermod_args: list[str] = []

    if expire_date:
        usermod_args += ["--expiredate", expire_date.strftime(DATE_FORMAT)]

    if usermod_args:
        # https://manpages.ubuntu.com/manpages/jammy/en/man8/useradd.8.html
        run_cmd(["usermod", *usermod_args, user])

    zfs_args: dict[str, str] = {}

    if quota:
        zfs_args["quota"] = quota

    if zfs_args:
        run_cmd(["zfs", "set", *zfs_options(zfs_args), f"{ZFS_TANK}/home/{user}"])


if __name__ == "__main__":
    app()
