import os
import secrets
import subprocess
from collections.abc import Sequence
from datetime import datetime
from typing import Annotated, Mapping, Optional

import typer

DATE_FORMAT = "%Y-%m-%d"

app = typer.Typer()


@app.callback()
def app_callback():
    if os.geteuid() != 0:
        typer.echo("Please run this script as root")
        raise typer.Abort()


def run_cmd(msg: str | None, cmd: Sequence[str], input: str | None = None) -> str:
    if msg:
        typer.echo(msg)

    cmd_kwargs = {}

    if input:
        cmd_kwargs["input"] = input.encode("utf-8") + b"\n"

    return subprocess.check_output(cmd, **cmd_kwargs).decode("utf-8").rstrip("\n")


def generate_username(email: str):
    if not email.endswith("@uni-trier.de"):
        typer.confirm(
            "You did not provide a university email address. This is only recommended for external users. Continue?",
            abort=True,
        )

    return email.lower().split("@")[0]


def zfs_options(kwargs: Mapping[str, str], prefix: Optional[str] = None) -> list[str]:
    args: list[str] = []

    for key, value in kwargs.items():
        if prefix:
            args.append(prefix)

        args.append(f"{key}={value}")

    return args


def homedir(user: str) -> str:
    return f"/home/{user}"


def homedir_zfs(user: str) -> str:
    return f"data/home/{user}"


@app.command()
def add(
    user: Annotated[
        str,
        typer.Argument(callback=generate_username),
    ],
    full_name: str,
    expire_date: Annotated[
        Optional[datetime],
        typer.Option(formats=[DATE_FORMAT]),
    ] = None,
    quota: Optional[str] = None,
) -> None:
    password = secrets.token_urlsafe()

    zfs_args: dict[str, str] = {}

    if quota:
        zfs_args["quota"] = quota

    typer.echo()
    # https://manpages.ubuntu.com/manpages/jammy/en/man8/zfs.8.html
    run_cmd(
        "Creating ZFS dataset...",
        ["zfs", "create", *zfs_options(zfs_args, "-o"), homedir_zfs(user)],
    )

    run_cmd(
        "Copying skeleton to home directory...",
        ["cp", "--recursive", "/etc/skel/.", homedir(user)],
    )

    useradd_args: list[str] = [
        "--home-dir",
        homedir(user),
        "--shell",
        "/bin/bash",
        "--comment",
        full_name,
    ]

    if expire_date:
        useradd_args += ["--expiredate", expire_date.strftime(DATE_FORMAT)]

    # https://manpages.ubuntu.com/manpages/jammy/en/man8/useradd.8.html
    run_cmd(
        "Creating user...",
        ["useradd", *useradd_args, user],
    )

    run_cmd(
        "Changing owner of home directory...",
        ["chown", "-R", f"{user}:{user}", homedir(user)],
    )
    run_cmd(
        "Setting permissions of home directory...",
        ["chmod", "750", homedir(user)],
    )

    # https://manpages.ubuntu.com/manpages/jammy/en/man8/chpasswd.8.html
    run_cmd(
        "Generating initial password...",
        ["chpasswd"],
        input=f"{user}:{password}",
    )

    # https://manpages.ubuntu.com/manpages/jammy/en/man1/passwd.1.html
    run_cmd(
        "Forcing password change on first login...",
        ["passwd", "--expire", user],
    )

    hostname = run_cmd(None, ["hostname", "-f"])
    ip = run_cmd(None, ["hostname", "-i"])

    typer.echo()
    typer.echo(f"Send the following data to {full_name}:")
    typer.echo()
    typer.echo("Documentation: https://github.com/wi2trier/gpu-server")
    typer.echo(f"Hostname: {hostname}")
    typer.echo(f"IP: {ip}")
    typer.echo(f"Username: {user}")
    typer.echo(f"Initial password: {password}")

    if quota:
        typer.echo(f"Quota: {quota}")

    if expire_date:
        typer.echo(f"Expiration date: {expire_date.strftime(DATE_FORMAT)}")


@app.command()
def remove(
    user: Annotated[
        str,
        typer.Argument(callback=generate_username),
    ],
    force: bool = False,
    keep_home: bool = False,
) -> None:
    typer.confirm(f"Remove user {user}?", abort=True)

    userdel_args: list[str] = []

    if force:
        userdel_args.append("--force")

    # https://manpages.ubuntu.com/manpages/jammy/en/man8/userdel.8.html
    run_cmd(
        "Removing user...",
        ["userdel", *userdel_args, user],
    )

    if not keep_home:
        run_cmd(
            "Destroying ZFS dataset...",
            ["zfs", "destroy", "--force", homedir_zfs(user)],
        )


@app.command()
def edit(
    user: Annotated[
        str,
        typer.Argument(callback=generate_username),
    ],
    expire_date: Annotated[
        Optional[datetime],
        typer.Option(formats=[DATE_FORMAT]),
    ] = None,
    reset_password: bool = False,
    quota: Optional[str] = None,
) -> None:
    usermod_args: list[str] = []

    if expire_date:
        usermod_args += ["--expiredate", expire_date.strftime(DATE_FORMAT)]

    if usermod_args:
        # https://manpages.ubuntu.com/manpages/jammy/en/man8/useradd.8.html
        run_cmd(
            "Modifying user...",
            ["usermod", *usermod_args, user],
        )

    zfs_args: dict[str, str] = {}

    if quota:
        zfs_args["quota"] = quota

    if zfs_args:
        run_cmd(
            "Setting ZFS quota...",
            ["zfs", "set", *zfs_options(zfs_args), homedir_zfs(user)],
        )

    if reset_password:
        password = secrets.token_urlsafe()

        # https://manpages.ubuntu.com/manpages/jammy/en/man8/chpasswd.8.html
        run_cmd(
            "Generating new password...",
            ["chpasswd"],
            input=f"{user}:{password}",
        )

        # https://manpages.ubuntu.com/manpages/jammy/en/man1/passwd.1.html
        run_cmd(
            "Forcing password change on first login...",
            ["passwd", "--expire", user],
        )

        typer.echo()
        typer.echo(f"Initial password: {password}")


@app.command()
def info(
    user: Annotated[
        str,
        typer.Argument(callback=generate_username),
    ],
) -> None:
    """Show the account metadata for ``user``.

    Args:
        user: The system username.
    """

    expire_date = "never"

    for line in run_cmd(None, ["chage", "--list", user]).splitlines():
        head, _, tail = line.partition(":")

        if head.strip().lower() == "account expires":
            value = tail.strip()
            expire_date = value if value else "never"
            break

    quota = run_cmd(
        None,
        [
            "zfs",
            "get",
            "-Hpo",
            "value",
            "quota",
            homedir_zfs(user),
        ],
    )

    typer.echo(f"Username: {user}")
    typer.echo(f"Expiration date: {expire_date}")
    typer.echo(f"Quota: {quota}")


if __name__ == "__main__":
    app()
