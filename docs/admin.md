# Admin Documentation

## User Management

We offer the custom command `userctl` to manage users on the server.
Please do **not** use the standard Linux commands (e.g., `useradd`, `adduser`, ...)!
The script allows to add, remove, and edit users.
Please run `sudo userctl --help` for more information.

Users on this server are identified by their university email address.
Thus, `userctl` expects the full email address as argument.
When creating student accounts, please provide `--expire-date` to automatically disable login after their project is finished.
We recommend to set the date to nine months after the account creation, this should cover most use cases.

## Process Management

Some users may forget to stop their processes or block all GPUs at once.
In such cases, you can use the tool `gpustat -p` to list all processes and their corresponding process id.
You can then kill the process using `sudo kill $PID`.
Use this with caution, as it will kill the process immediately without any warning.
