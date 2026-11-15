import os
import random
from typing import Callable
import numpy as np
import torch


def set_seed(seed: int = 123) -> None:
    """Inicjalizacja ziarna generatorów liczb losowych dla powtarzalności wyników."""
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    os.environ["PYTHONHASHSEED"] = str(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)
        torch.backends.cudnn.deterministic = True
        torch.backends.cudnn.benchmark = False


def make_worker_init_fn(base_seed: int) -> Callable[[int], None]:
    """Tworzy funkcję inicjującą niezależne ziarna dla procesów roboczych DataLoader."""

    def _init_worker(worker_id: int) -> None:
        worker_seed = base_seed + worker_id
        random.seed(worker_seed)
        np.random.seed(worker_seed)
        torch.manual_seed(worker_seed)

        worker_info = torch.utils.data.get_worker_info()
        if worker_info is None:
            return
        transform = getattr(worker_info.dataset, "transform", None)
        for sub_tf in getattr(transform, "transforms", []):
            if hasattr(sub_tf, "rng"):
                sub_tf.rng = np.random.default_rng(worker_seed)

    return _init_worker
