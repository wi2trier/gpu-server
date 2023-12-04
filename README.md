# WI2 GPU Server

Our GPU server is provided for research in the field of machine learning and deep learning.
Please do not run/host CPU-based applications, we will happily provide you with a virtual machine for that.
It shall also not be used as a development machine, please test your code locally and only use the server for training and evaluation.

The server has the following hardware configuration:

- CPU: 2x Intel Xeon Gold 6138 @ 2.00GHz (20 cores, 40 threads)
- GPU: 8x NVIDIA Tesla V100 (32 GB VRAM)
- RAM: 12x Micron 64 GB DDR4-2666 ECC

To run your code on the server, we provide two container runtimes:
[Podman](https://podman.io) (a general-purpose Docker replacement) and [Apptainer](https://apptainer.org) (aimed specifically at scientific computing).
Due to its ease of use, we generally recommend Apptainer for users unfamiliar with container engines like Docker.
Among others, it automatically forwards ports form your applications and makes sure that your files on the server are accessible in the container without any configuration (unlike Podman).

## Access

The server can only be accessed when connected to the VPN of Trier University.
To start, open a terminal and execute:

```shell
ssh USERNAME@IP
```

After your first login, please change your password using the command `passwd` (if not prompted anyway).

**Note for Windows users:**
Recent versions of Windows 10 and 11 already contain an SSH client, so you can use Microsoft's new Windows Terminal to connect.
Please find more details on the corresponding [help page](https://learn.microsoft.com/en-us/windows/terminal/tutorials/ssh).

## General Usage

For an introduction to the Linux command line, we refer to [Mozilla's command line crash course](https://developer.mozilla.org/en-US/docs/Learn/Tools_and_testing/Understanding_client-side_tools/Command_line).
We found the following utilities to be useful for everyday use:

- `htop`: Show the active processes on the server.
- `nvidia-smi` and `gpustat`: Show the active processes on the GPUs.
- `tmux`: Create a new terminal session that can be detached and reattached later.

### GPU Selection

All GPUs of the server are set to exclusive compute mode, meaning that only one process can use a GPU at a time.
To select a GPU, you can set the `CUDA_VISIBLE_DEVICES=$GPU_ID` environment variable.
Please use the aforementioned `nvidia-smi` command to check which GPUs are currently in use.

### `tmux`

The `tmux` command allows you to spawn a "virtual" shell that persists even after you disconnect from the server.
Among others, this allows you to start a long-running process and then close the session without interrupting it.
To create a new session, simply execute `tmux`.
You can then start your process and close the terminal if needed.
To reattach to the session later, execute `tmux attach`.
The tmux session can be closed by running `exit` or `tmux kill-session` in the shell.

## Apptainer Usage

There are three main commands in Apptainer:

- `apptainer shell`: Open an interactive shell in the container.
- `apptainer run [$ARGS...]`: Run the default command of the container. You may optionally add one or more arguments to the command.
- `apptainer exec $COMMAND [$ARGS...]`: Run a custom command inside the container. You may optionally add one or more arguments to the command.

Some images (e.g., `nvidia/cuda` or `ubuntu`) provide no default command, meaning it will do nothing by default.
In this special case, `apptainer run` and `apptainer exec` are equivalent and can be used interchangeably.

To access the GPUs from within the container, you need to set the `CUDA_VISIBLE_DEVICES` environment variable and pass the `--nv` flag to the Apptainer command.
Here is the general call signature for the `apptainer exec` command:

```shell
CUDA_VISIBLE_DEVICES=$GPU_ID apptainer exec --nv docker://$IMAGE $COMMAND
```

You may omit the `CUDA_VISIBLE_DEVICES` environment variable, in which case Apptainer will automatically select a GPU that is currently not in use.
For example, to run the `nvidia-smi` command on any available GPU, execute

```shell
apptainer exec --nv docker://nvidia/cuda nvidia-smi
```

### File Access

By default, Apptainer mounts your home directory into the container at the same location, so no additional configuration is needed.

### Port Forwarding

When starting a server in a container, it is directly accessible without the need to forward ports.
This also means that in case two users want to run two instances of the same app on the server, you are responsible for choosing different ports.
Please consult the documentation of the corresponding app for more details on how to change the default port.

### Image Caching

Apptainer caches images on the server to speed up subsequent runs.
They are stored in your home folder, so you may want to clean them up from time to time:

```shell
apptainer cache clean --days $DAYS
```

All images not accessed within the last `$DAYS` days will be deleted.

## Podman Usage

We recommend Apptainer for most users, so we will only provide some notes about the particularities of our GPU-based Podman setup.
For more details, please refer to the [official documentation](https://docs.podman.io/en/latest/).
Please keep in mind that in order to work correctly, Podman requires more configuration (e.g., port forwarding and volume mounting) than is shown here.

### GPU Selection

We provide support for accessing the GPUs via the officlal [Container Device Interface](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html).
Consequently, you can use the `--device` flag to access the GPUs from within the container like so:

```shell
podman run --rm --device nvidia.com/gpu=$GPU_ID $IMAGE $COMMAND
```

### Image Caching

Similar to Apptainer, Podman caches images in your home folder to speed up subsequent runs.
You may delete the entire cache as follows:

```shell
podman system reset
```
