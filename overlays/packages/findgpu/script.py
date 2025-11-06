# https://gist.github.com/afspies/7e211b83ca5a8902849b05ded9a10696
# https://discuss.pytorch.org/t/it-there-anyway-to-let-program-select-free-gpu-automatically/17560/13

import random
import subprocess


def run_cmd(cmd: str) -> str:
    return (subprocess.check_output(cmd, shell=True)).decode("utf-8").rstrip("\n")


def get_free_gpu_indices():
    out = run_cmd("nvidia-smi -q -d Memory | grep -A4 GPU")
    out = (out.split("\n"))[1:]
    out = [line for line in out if "--" not in line]

    total_gpu_num = int(len(out) / 5)
    gpu_bus_ids = []
    for i in range(total_gpu_num):
        gpu_bus_ids.append(
            [line.strip().split()[1] for line in out[(i * 5) : (i * 5 + 1)]][0]
        )

    out = run_cmd("nvidia-smi --query-compute-apps=gpu_bus_id --format=csv")
    gpu_bus_ids_in_use = (out.split("\n"))[1:]
    gpu_ids_in_use = []

    for bus_id in gpu_bus_ids_in_use:
        gpu_ids_in_use.append(gpu_bus_ids.index(bus_id))

    return [i for i in range(total_gpu_num) if i not in gpu_ids_in_use]


if __name__ == "__main__":
    free_gpus = get_free_gpu_indices()

    # remove GPU 0 from the list
    free_gpus = [gpu for gpu in free_gpus if gpu != 0]

    if len(free_gpus) == 0:
        print("100")
    else:
        print(random.choice(free_gpus))
