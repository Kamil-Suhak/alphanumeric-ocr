from pathlib import Path
import json
import sys
import time
import torch

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(PROJECT_ROOT))

from src.models.cnn import AlphanumericCNN
from src.config import RUNS_DIR, RESULTS_DIR

def benchmark_latency(model: torch.nn.Module, device: torch.device, batch_size: int = 1, iterations: int = 1000) -> float:
    """Pomiar średniego czasu inferencji w milisekundach z rozgrzewką (warm-up)."""
    model.eval()
    dummy_input = torch.randn(batch_size, 1, 32, 32, device=device)

    # Faza rozgrzewki
    with torch.no_grad():
        for _ in range(30):
            _ = model(dummy_input)
        if device.type == "cuda":
            torch.cuda.synchronize()

        start_time = time.perf_counter()
        for _ in range(iterations):
            _ = model(dummy_input)
        if device.type == "cuda":
            torch.cuda.synchronize()
        total_time = time.perf_counter() - start_time

    return (total_time / iterations) * 1000.0

def main() -> None:
    print("--- Benchmark praktyczności modelu (Sekcja 36 planu) ---\n")
    model = AlphanumericCNN(num_classes=62)

    total_params = sum(p.numel() for p in model.parameters())
    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)

    print(f"Liczba parametrów (ogółem):       {total_params:,}")
    print(f"Liczba parametrów (trenowalnych): {trainable_params:,}")

    # Rozmiar samych wag FP32 (do wdrożenia produkcyjnego / embedded)
    pure_weights_mb = (total_params * 4) / (1024 * 1024)
    print(f"Rozmiar wag FP32 (inference only):{pure_weights_mb:.2f} MB")

    # Sprawdzenie rozmiaru pełnego pliku checkpointu na dysku (wagi + stan optymalizatora)
    ckpt_path = RUNS_DIR / "EXP-001" / "best.pt"
    ckpt_size_mb = ckpt_path.stat().st_size / (1024 * 1024) if ckpt_path.exists() else pure_weights_mb
    if ckpt_path.exists():
        print(f"Rozmiar checkpointu (best.pt):    {ckpt_size_mb:.2f} MB (wagi + stany optymalizatora)")

    # Pomiar na CPU
    cpu_device = torch.device("cpu")
    model_cpu = model.to(cpu_device)
    cpu_lat_1 = benchmark_latency(model_cpu, cpu_device, batch_size=1)
    cpu_lat_32 = benchmark_latency(model_cpu, cpu_device, batch_size=32)
    print(f"\nCzas inferencji CPU (batch=1):    {cpu_lat_1:.3f} ms / znak")
    print(f"Czas inferencji CPU (batch=32):   {cpu_lat_32:.3f} ms (średnio {cpu_lat_32/32:.3f} ms / znak)")

    gpu_lat_1 = None
    gpu_lat_32 = None
    # Pomiar na GPU (jeśli dostępne)
    if torch.cuda.is_available():
        gpu_device = torch.device("cuda")
        model_gpu = model.to(gpu_device)
        gpu_lat_1 = benchmark_latency(model_gpu, gpu_device, batch_size=1)
        gpu_lat_32 = benchmark_latency(model_gpu, gpu_device, batch_size=32)
        print(f"\nCzas inferencji GPU (batch=1):    {gpu_lat_1:.3f} ms / znak")
        print(f"Czas inferencji GPU (batch=32):   {gpu_lat_32:.3f} ms (średnio {gpu_lat_32/32:.3f} ms / znak)")

    # Zapis raportu do tabel wyników
    tables_dir = RESULTS_DIR / "tables"
    tables_dir.mkdir(parents=True, exist_ok=True)
    report = {
        "total_parameters": total_params,
        "trainable_parameters": trainable_params,
        "pure_weights_size_mb": round(pure_weights_mb, 2),
        "checkpoint_size_mb": round(ckpt_size_mb, 2),
        "cpu_latency_batch_1_ms": round(cpu_lat_1, 3),
        "cpu_latency_batch_32_ms": round(cpu_lat_32, 3),
        "cpu_throughput_chars_per_sec": round(32000.0 / cpu_lat_32, 1),
    }
    if gpu_lat_1 is not None:
        report["gpu_latency_batch_1_ms"] = round(gpu_lat_1, 3)
        report["gpu_latency_batch_32_ms"] = round(gpu_lat_32, 3)
        report["gpu_throughput_chars_per_sec"] = round(32000.0 / gpu_lat_32, 1)

    json_path = tables_dir / "practicality.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
    print(f"\nZapisano parametry wydajnościowe do: {json_path}")

if __name__ == "__main__":
    main()
