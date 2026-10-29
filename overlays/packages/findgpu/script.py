import os
import sys

import pynvml

__all__ = ["main"]

SENTINEL = "-1"


def _free_gpu() -> str | None:
    try:
        pynvml.nvmlInit()
    except pynvml.NVMLError:
        return None

    try:
        # NVML enumerates the GPUs by ascending PCI bus id, like nvidia-smi.
        for index in range(pynvml.nvmlDeviceGetCount()):
            handle = pynvml.nvmlDeviceGetHandleByIndex(index)

            if not pynvml.nvmlDeviceGetComputeRunningProcesses(handle):
                return str(index)

        return None
    finally:
        pynvml.nvmlShutdown()


def _select_devices() -> str:
    devices = os.environ.get("CUDA_VISIBLE_DEVICES") or SENTINEL

    if devices != SENTINEL:
        return devices

    if gpu := _free_gpu():
        return gpu

    print("findgpu: no free GPU available", file=sys.stderr)
    return SENTINEL


def main() -> None:
    """Select GPUs and print them, or run a command on them.

    Usage: findgpu [COMMAND [ARGS...]]

    An explicit CUDA_VISIBLE_DEVICES is kept as is. If it is unset or the
    sentinel -1 (an invalid device id meaning no GPU), the lowest free GPU is
    selected instead, or the sentinel if none is free. Picking the lowest index
    packs jobs onto as few NVLink groups as possible, keeping whole groups free
    for multi-GPU jobs. Exclusive compute mode turns a race between concurrent
    launches into a loud CUDA error instead of silent sharing.

    The always-on llama.cpp models keep a compute process on their GPUs, so
    those cards already report as used and need no extra reservation here.
    """
    devices = _select_devices()
    command = sys.argv[1:]

    if not command:
        print(devices)
        sys.exit(1 if devices == SENTINEL else 0)

    variables = {"CUDA_VISIBLE_DEVICES": devices, "CUDA_DEVICE_ORDER": "PCI_BUS_ID"}
    # The APPTAINERENV_ copies survive apptainer's --cleanenv and --containall.
    os.environ |= variables | {f"APPTAINERENV_{k}": v for k, v in variables.items()}
    os.execvp(command[0], command)


if __name__ == "__main__":
    main()
