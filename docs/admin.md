# Admin Documentation

## User Management

We offer the custom command `userctl` to manage users on the server.
Please do **not** use the standard Linux commands (e.g., `useradd`, `adduser`, ...)!
In addition to adding, removing, and editing users, `userctl` also manages the ZFS dataset for the user.
Run `sudo userctl --help` for more information.

Users on this server are identified by their university email address.
Thus, `userctl` expects the full email address as argument.
For users without a university email address, use the pattern `FIRST_INITIAL + LASTNAME` (e.g., `jdoe` for John Doe).

### Adding Users

Please also provide `--expire-date` to automatically disable login after their project is finished.
We recommend to set the date to nine months after the account creation, this should cover most use cases.
Also consider adding a quota to the user, e.g., `--quota 100G`.

```shell
sudo userctl add username@uni-trier.de "Full Name" --expire-date 2022-12-31 --quota 100G
```

### Removing Users

When removing users, you can choose to keep the data by adding `--keep-home`.

```shell
sudo userctl remove s9name@uni-trier.de
```

### Editing Users

You may change the expiration date and the quota of a user at any time.

```shell
sudo userctl edit s9name@uni-trier.de --expire-date 2022-12-31 --quota 100G
```

If one of these options is not provided, the current value will be kept.

## Process Management

Some users may forget to stop their processes or block all GPUs at once.
In such cases, you can use the tool `gpustat -p` to list all processes and their corresponding process id.
You can then kill the process using `sudo kill $PID`.
Use this with caution, as it will kill the process immediately without any warning.

## Systemd Service Management

The server uses `systemd` to manage the background services `ollama` and `open-webui`.
Ollama is declared as a dependency of Open-WebUI, so restarting Ollama will also restart Open-WebUI.
You can use the following commands to manage these services:

```shell
sudo systemctl TASK SERVICE_NAME
# for example:
sudo systemctl restart ollama
```

To view the logs of a service, use:

```shell
sudo journalctl -u SERVICE_NAME -f
# for example:
sudo journalctl -u ollama -f
```
