# WI2 GPU Server

## Overview

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

> [!important]
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

### Installing/Using Packages

We use the [Nix package manager](https://nixos.org) to declaratively manage the server configuration.
This allows you to spawn a temporary shell with additional packages easily.
For instance, to create a shell with Python, execute:

```shell
nix shell pkgs#python3
```

Multiple packages can be specified as follows:

```shell
nix shell pkgs#{python3,nodejs}
```

You may also provide a command that shall be run in the shell:

```shell
nix shell pkgs#python3 --command python --version
```

You can search for available packages on [search.nixos.org](https://search.nixos.org/packages).

These temporary shells are useful to quickly test a new package before using it in production in a containerized environment like Apptainer.
If you would like to install a package permanently, please open an issue on GitHub.

### GPU Selection

All GPUs of the server are set to exclusive compute mode, meaning that only one process can use a GPU at a time.
To select a GPU, you can set the `CUDA_VISIBLE_DEVICES=$GPU_ID` environment variable.
Please use the aforementioned `nvidia-smi` command to check which GPUs are currently in use.

> [!important]
> The system has eight GPUs, but two NUMA nodes with 4 GPUs each: GPUs 0,1,2,3 are connected with NVLink and GPUs 5,6,7,8 are connected with NVLink.
> For performance reasons, we **strongly** recommend to stay within one of these nodes when selecting GPUs.


### tmux

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

### Image Selection

Apptainer supports a variety of container image formats, including Docker and its own SIF format.
To run a container from a Docker registry, use the `docker://` prefix:

```shell
apptainer run docker://$IMAGE [$ARGS...]
```

It is recommended to convert such images to the SIF format, which is more efficient and allows for faster loading.

```shell
apptainer build $IMAGE.sif docker://$IMAGE
```

In later runs, you can then use the SIF image directly:

```shell
apptainer run $IMAGE.sif [$ARGS...]
```

### GPU Selection

To access the GPUs from within the container, you need to set the `CUDA_VISIBLE_DEVICES` environment variable and pass the `--nv` flag to the Apptainer command.
Here is the general call signature for the `apptainer exec` command:

```shell
CUDA_VISIBLE_DEVICES=$GPU_ID apptainer exec --nv $IMAGE $COMMAND
```

You may omit the `CUDA_VISIBLE_DEVICES` environment variable, in which case Apptainer will automatically select a GPU that is currently not in use.
For example, to run the `nvidia-smi` command on any available GPU, execute

```shell
apptainer exec --nv docker://ubuntu nvidia-smi
```

### [File Access](https://apptainer.org/docs/user/main/bind_paths_and_mounts.html)

By default, Apptainer mounts both (i) your home directory and (ii) your current working directory into the container, so no additional configuration is needed.
In case you only need your working directory and not your home folder, pass the option `--no-home` to the Apptainer command.
When needing access to other file locations, you can use the `--bind source:target` option to mount them into the container.

### Port Forwarding

When starting a server in a container, it is directly accessible without the need to forward ports.
This also means that in case two users want to run two instances of the same app on the server, you are responsible for choosing different ports.
Please consult the documentation of the corresponding app for more details on how to change the default port.

> [!important]
> Regular users are allowed to use ports above `1024`.
> If connecting via the university VPN, only ports in the range `6000-8000` will be accessible!

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
apptainer instance start --nv $IMAGE $INSTANCE_NAME [$ARGS...]
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

where `OUTPUT_FOLDER` is your current working directory by default.
The images are stored in the `docker-archive` format (ending in `.tar.gz`).
Since Apptainer converts the images to its SIF format anyway, we offer a streamlined integration:

```shell
build-apptainer IMAGE_NAME [OUTPUT_FOLDER]
```

The image can then be run as follows:

```shell
apptainer run --nv IMAGE_NAME.sif
# or
podman run --rm --device nvidia.com/gpu=0 docker-archive:IMAGE_NAME.tar.gz
```

> [!note]
> These images install their dependencies in a virtual environment in your current working directory (i.e., `./.venv`).
> This allows to cache the dependencies and reuse them across multiple runs.
> Please make sure to add the virtual environment to your `.gitignore` file and always start the container in the same working directory.

### Poetry

The image `poetry` contains Python 3 together with the package manager Poetry.
This image allows proper dependency specification via `pyproject.toml` and `poetry.lock` files.
Using `apptainer run IMAGE ARGS...` executes `poetry ARGS...`, so you could execute a Python script via `apptainer run IMAGE run python SCRIPT.py`.

### uv

The image `uv` contains Python 3 together with the package manager uv.
This image allows proper dependency specification via `pyproject.toml` and `uv.lock` files.
Using `apptainer run IMAGE ARGS...` executes `uv ARGS...`, so you could execute a Python script via `apptainer run IMAGE run SCRIPT.py`.

### Jupyter

The image `jupyter` contains a Jupyter Lab server with common NLP dependencies (numpy, scipy, spacy, nltk, torch, openai, transformers, sentence-transformers).
It allows easy interaction with the server through a browser-based interface.
Jupyter by default listens on port `8888` which is not accessible from the outside.
Thus, choose a different port within the range `6000-8000` by passing the `--port $PORT` option to the `apptainer run` command.

You may install arbitrary Python packages by running `!pip install NAME` in a notebook.
Alternatively, open a Terminal and execute `pip install NAME` there.
Please note that the binaries installed in the virtual environment are only available in the Terminal when your working directory contains the `.venv` folder (i.e., using `cd` to change the folder removes `.venv/bin` from your `$PATH`).

## Ollama Usage

The server is equipped with the [Ollama](https://ollama.com) library for serving LLMs.
It automatically selects one free GPU, but you can override this behavior by setting the `CUDA_VISIBLE_DEVICES` environment variable (just like with Apptainer).
By default, Ollama does not allow remote requests and uses a fixed port (potentially conflicting with other users).
To change this, you need to modify the `OLLAMA_HOST` environment variable:

- Accessing from your computer: `OLLAMA_HOST=0.0.0.0:PORT`.
  `PORT` must be in the range `6000-8000`).
- Accessing from the server only: `OLLAMA_HOST=127.0.0.1:PORT`.
  `PORT` can be arbitrarily chosen `>1024`.

```shell
OLLAMA_HOST=SEE_ABOVE ollama serve
```

In another terminal, pull the models before performing API requests:

```shell
OLLAMA_HOST=SEE_ABOVE ollama pull MODEL_NAME
```

To make requests, either use the `ollama` library or the `openai` library.
Remember to modify their respective endpoints to point to the IP of the GPU server and the chosen port.

## LMDeploy Setup

Alternatively, you can use [LMDeploy](https://github.com/InternLM/lmdeploy) to deploy and run LLMs.
LMDeploy offers a higher throughput than Ollama due to its CUDA Kernels for the given GPUs. It also allow easy batching.

To run LMDeploy, use podman: 

```shell
podman run -d --gpus $GPUS \
  -p PORT:PORT \
  docker.io/openmmlab/lmdeploy:latest-cu12 \
  lmdeploy serve api_server $HF_LLM_NAME
```
This will start an OpenAI-compatible endpoint at the corresponding port. More options can be found [in the documentation](https://lmdeploy.readthedocs.io/en/latest/llm/api_server.html).

As an example, this command runs Qwen/Qwen3-32B on four GPUs with 32K context on port 23333:

```shell
docker run -d --gpus 0,1,2,3 \
  -p 23333:23333 \
  docker.io/openmmlab/lmdeploy:latest-cu12 \
  lmdeploy serve api_server Qwen/Qwen3-32B \
      --tp 4 \
      --session-len 32768 \
      --cache-max-entry-count 0.85
```


## Editor Integrations

### Visual Studio Code

- Install the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension.
- Connect to the server by clicking on the green icon in the bottom left corner of the window and selecting `Remote-SSH: Connect to Host...`.
- Enter the connection string of the server: `USER@IP` and add it as a new host.
- You now have access to the server's file system and can edit files directly on the server.

> [!important]
> VSCode currently does not use a login shell by default, meaning that some commands like Apptainer will be missing.
> You can track this issue on [GitHub](https://github.com/microsoft/vscode-remote-release/issues/1671).
> As a workaround, open the command palette (Ctrl+Shift+P), select `Preferences: Open Remote Settings`, and paste the following snippet:

```json
{
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "bash",
      "icon": "terminal-bash",
      "args": ["-l"]
    }
  }
}
```

### PyCharm

- Go to `Settings > Tools > SSH Configurations` and create a new connection using the credentials provided to you via mail. The server uses the default SSH port 22.
- Go to `Settings > Build, Execution, Deployment > Deployment`. Choose `SFTP` as the connection type and select the connection you created in the previous step. Set your home path to `/home/<username>`. The option `Mappings` allows to configure where your local project is uploaded to on the server. For instance, setting `Deployment Path` to `projects/thesis` will upload your project to `/home/<username>/projects/thesis`. Adding excluded paths allows to exclude files from the upload. For instance, adding `.venv` will exclude the virtual environment from the upload.

## Additional Docs

- [Administration](./docs/admin.md)
- [Setup instructions](./docs/setup.md)
