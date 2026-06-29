import random
import subprocess
from collections.abc import Sequence

__all__ = ["main"]


def _run_nvidia_smi(arguments: Sequence[str]) -> list[str]:
    result = subprocess.run(
        ["nvidia-smi", *arguments],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def _query_gpu_bus_ids() -> dict[str, int]:
    lines = _run_nvidia_smi(
        [
            "--query-gpu=index,pci.bus_id",
            "--format=csv,noheader,nounits",
        ]
    )
    return {
        bus_id.strip(): int(index)
        for index, bus_id in (line.split(",", 1) for line in lines)
    }


def _query_used_gpu_bus_ids() -> set[str]:
    lines = _run_nvidia_smi(
        [
            "--query-compute-apps=gpu_bus_id",
            "--format=csv,noheader,nounits",
        ]
    )
    return set(lines)


def _available_gpu_indices() -> list[int]:
    gpu_bus_ids = _query_gpu_bus_ids()
    used_bus_ids = _query_used_gpu_bus_ids()
    used_indices = {
        gpu_bus_ids[bus_id] for bus_id in used_bus_ids if bus_id in gpu_bus_ids
    }
    return [
        index for index in sorted(gpu_bus_ids.values()) if index not in used_indices
    ]


def main() -> None:
    """Print a free GPU index, or the sentinel 100 if none are free.

    The sentinel is a non-existent device id meaning no GPU is selected. The
    shell defaults and container wrappers rely on it.

    The always-on llama.cpp models keep a compute process on their GPUs, so
    those cards already report as used and need no extra reservation here.
    """
    available_gpus = _available_gpu_indices()
    print(random.choice(available_gpus) if available_gpus else "100")


if __name__ == "__main__":
    main()
