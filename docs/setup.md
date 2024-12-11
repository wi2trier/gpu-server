# Server Setup

- [Updates](#updates)
- [Initial Setup](#initial-setup)
  - [Ubuntu](#ubuntu)
  - [Nix](#nix)
  - [CUDA](#cuda)
  - [Verify Installation](#verify-installation)
  - [Create Containers User](#create-containers-user)
- [Uninstall](#uninstall)

## Updates

To apply changes to the config, run the following:

```shell
sudo nix run github:wi2trier/gpu-server
```

## Initial Setup

### Ubuntu

First, install the dependencies for nix and the CUDA installation.
The package(s) `uidmap` are needed for rootless podman.

```shell
sudo apt update
sudo apt upgrade -y
sudo apt install -y git curl wget uidmap
```

### Nix

Then install nix using the [DeterminateSystems installer](https://github.com/DeterminateSystems/nix-installer).

```shell
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Afterwards, open a new shell to apply the changes (e.g., exit and reconnect via ssh).
Then we can apply the system manager configuration for the first time.

```shell
sudo /nix/var/nix/profiles/default/bin/nix run github:wi2trier/gpu-server
```

Again open a new shell to apply the changes.

### CUDA

First install the [CUDA Toolkit](https://developer.nvidia.com/cuda-downloads) and the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).
Make sure to update the keyring url when changing the distro!

```shell
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
rm cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y cuda-drivers-555 cuda-toolkit-12-5 nvidia-container-toolkit
```

Restart the server to load the new driver.

```shell
sudo reboot
```

### Verify Installation

Correctly setting up the CUDA drivers is crucial, so please verify that the following commands work as expected.

```shell
CUDA_VISIBLE_DEVICES=0 apptainer run --nv docker://ubuntu nvidia-smi
podman run --rm --device nvidia.com/gpu=0 ubuntu nvidia-smi
```

In addition, you may test the setup using the `pytorch` image:

```shell
CUDA_VISIBLE_DEVICES=0 apptainer run --nv docker://pytorch/pytorch python -c "import torch; print(torch.cuda.is_available())"
podman run --rm --device nvidia.com/gpu=0 pytorch/pytorch python -c "import torch; print(torch.cuda.is_available())"
```

The new Apptainer runtime using `nvidia-container-cli` currently does not work:

```shell
CUDA_VISIBLE_DEVICES=0 apptainer --debug run --nvccli docker://ubuntu nvidia-smi
```

### Create Containers User

To create a user for running containers, run the following:

```shell
sudo useradd --system --home-dir /var/empty --shell /sbin/nologin --comment "Containers User" containers
```

To allow the user to run containers, run the following:

```shell
echo "containers:2147483647:2147483648" | sudo tee -a /etc/subuid
echo "containers:2147483647:2147483648" | sudo tee -a /etc/subgid
```

## Uninstall

```shell
sudo nix run github:wi2trier/gpu-server#system-uninstall
```
