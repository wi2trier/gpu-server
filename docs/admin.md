# Admin Documentation

## User Management

User accounts shall use the following naming scheme: `first initial + lastname`.
A user with the name `John Doe` would thus have the username `jdoe`.

## Process Management

Some users may forget to stop their processes or block all GPUs at once.
In such cases, you can use the tool `gpustat -p` to list all processes and their corresponding process id.
You can then kill the process using `sudo kill $PID`.
Use this with caution, as it will kill the process immediately without any warning.
