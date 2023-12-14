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

> [!warning]
> Even users with sudo permissions shall not install additional software through `apt` or other package managers.
> The server is declaratively managed through Nix, so this may interfere with the configuration.
> Instead, refer to the section _consuming packages_ in this document.

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

### Consuming Packages

We use the [Nix package manager](https://nixos.org) to declaratively manage the server configuration.
This allows you to spawn a temporary shell with additional packages easily.
For instance, to create a shell with Node.js and Python 3, execute:

```shell
nix-shell -p nodejs python3
```

You may also provide a command that shall be run in the shell:

```shell
nix-shell -p python3 --run "python --version"
```

You can search for available packages on [search.nixos.org](https://search.nixos.org/packages).
This is useful to quickly test a new package before using it in production in a containerized environment like Apptainer.
If you would like to install a package permanently, please open a pull request on GitHub.

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

### GPU Selection

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

### [File Access](https://apptainer.org/docs/user/main/bind_paths_and_mounts.html)

By default, Apptainer mounts both (i) your home directory and (ii) your current working directory into the container, so no additional configuration is needed.
In case you only need your working directory and not your home folder, pass the option `--no-home` to the Apptainer command.
When needing access to other file locations, you can use the `--bind source:target` option to mount them into the container.

### Port Forwarding

When starting a server in a container, it is directly accessible without the need to forward ports.
This also means that in case two users want to run two instances of the same app on the server, you are responsible for choosing different ports.
Please consult the documentation of the corresponding app for more details on how to change the default port.

**Please note:** As a regular user, you can only use ports above 1024.

### [Image Caching](https://apptainer.org/docs/user/main/cli/apptainer_cache.html)

Apptainer caches images on the server to speed up subsequent runs.
They are stored in your home folder, so you may want to clean them up from time to time:

```shell
apptainer cache clean --days $DAYS
```

All images not accessed within the last `$DAYS` days will be deleted.

### [Running Services](https://apptainer.org/docs/user/main/running_services.html)

If starting a service like a Jupyter notebook, you need to keep the terminal open.
To mitigate this, you may either use the `tmux` command (see above) or start the container as an _instance_:

```shell
apptainer instance start --nv docker://$IMAGE $INSTANCE_NAME [$ARGS...]
```

To see a list of all running instances, execute

```shell
apptainer instance list
```

While an instance is running, you can execute code in it via

```shell
apptainer instance exec $INSTANCE_NAME $COMMAND [$ARGS...]
```

To stop an instance, execute

```shell
apptainer instance stop $INSTANCE_NAME
# or, to stop all instances
apptainer instance stop --all
```

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

## Ready-to-Use Container Images

We provide a number of ready-to-use container images for common use cases.
They are updated regularly, so we require you to store a copy of them in your home folder before using them.
To do so, execute the following command:

```shell
build-container IMAGE_NAME [OUTPUT_FOLDER]
```

where `OUTPUT_FOLDER` is your current working directory by default and `IMAGE_NAME` is one of the following:

- `jupyter`: A Jupyter Lab server with common NLP dependencies: numpy, scipy, spacy, nltk, torch, openai, transformers, sentence-transformers.
- `poetry`: An image for managing Python dependencies and virtual environments with Poetry.

> [!info]
> These images install their dependencies in a virtual environment in your current working directory (i.e., `./.venv`).
> This allows to cache the dependencies and reuse them across multiple runs.
> Please make sure to add the virtual environment to your `.gitignore` file and always start the container in the same working directory.

For instance, when running `build-container jupyter`, a new file called `jupyter.tar.gz` will be created in your current working directory.
The images are stored in the `docker-archive` format, so you can load them into Apptainer or Podman as follows:

```shell
apptainer run --nv docker-archive:./IMAGE_NAME.tar.gz
# or
podman run --rm --device nvidia.com/gpu=0 docker-archive:./IMAGE_NAME.tar.gz
```

Since Apptainer converts the images to its SIF format anyway, we offer a streamlined integration:

```shell
build-apptainer IMAGE_NAME [OUTPUT_FOLDER]
# then
apptainer run --nv ./IMAGE_NAME.sif
```

This will make subsequent loads significantly faster since Apptainer does not need to parse the Docker image every time.

## Additional Docs

- [Administration](./docs/admin.md)
- [Setup instructions](./docs/setup.md)
- [PyCharm integration](./docs/pycharm.md)
