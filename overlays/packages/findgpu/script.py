import random
import subprocess
from collections.abc import Iterable, Sequence

__all__ = ["main"]


def _run_nvidia_smi(arguments: Sequence[str]) -> list[str]:
    result = subprocess.run(
        ["nvidia-smi", *arguments],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    return [
        line.strip()
        for line in result.stdout.splitlines()
        if line.strip()
    ]


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


def _available_gpu_indices(excluded_indices: Iterable[int]) -> list[int]:
    excluded = set(excluded_indices)
    gpu_bus_ids = _query_gpu_bus_ids()
    used_bus_ids = _query_used_gpu_bus_ids()
    used_indices = {
        gpu_bus_ids[bus_id] for bus_id in used_bus_ids if bus_id in gpu_bus_ids
    }
    return [
        index
        for index in sorted(gpu_bus_ids.values())
        if index not in used_indices and index not in excluded
    ]


def main() -> None:
    """Print an available GPU index for CUDA_VISIBLE_DEVICES."""
    available_gpus = _available_gpu_indices(excluded_indices=(0,))
    if available_gpus:
        print(random.choice(available_gpus))
    else:
        print("100")


if __name__ == "__main__":
    main()
