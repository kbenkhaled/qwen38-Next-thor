# vllm/vllm-openai:nightly, vLLM 0.28.1rc1.dev580+g385dce36b, 2026-09-09 UTC
FROM vllm/vllm-openai@sha256:b0501f99fec5136f248f78d5850977a2ec32d55cd9a665f4a9ffef24cbdf7fe5

COPY qwen38-thor.patch /opt/qwen38-thor.patch
RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/* \
    && cd /usr/local/lib/python3.12/dist-packages \
    && git apply --check /opt/qwen38-thor.patch \
    && git apply /opt/qwen38-thor.patch

ENV VLLM_DISABLED_KERNELS=FlashInferCutlassMxfp8LinearKernel \
    PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# MTP does not inherit the target's dictionary --hf-overrides in this nightly.
# Download metadata only; link weights to the Hugging Face cache mounted at run time.
RUN python3 - <<'PY'
import json
from pathlib import Path
from huggingface_hub import model_info, snapshot_download

model = "local-inference-lab/Qwen3.8-Flash-Next-NVFP4"
revision = model_info(model).sha
draft = Path(snapshot_download(
    model, revision=revision, local_dir="/opt/qwen38-mtp-model",
    allow_patterns=["config.json", "model.safetensors.index.json"],
))
config_path = draft / "config.json"
config = json.loads(config_path.read_text())
config.update(model_type="qwen4_exp", architectures=["Qwen4ExpForConditionalGeneration"])
config_path.write_text(json.dumps(config) + "\n")
cache = Path("/root/.cache/huggingface/hub") / ("models--" + model.replace("/", "--"))
index = json.loads((draft / "model.safetensors.index.json").read_text())
for filename in set(index["weight_map"].values()):
    (draft / filename).symlink_to(cache / "snapshots" / revision / filename)
PY
