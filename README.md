# Qwen3.8 Flash Next on Jetson Thor

Serve Qwen3.8 Flash Next NVFP4 on Jetson Thor with vLLM and MTP=3.

Benchmark using this recipe gives 33.11 tokens per second on speedbench across writing and summarization category.

## Run on Jetson Thor

Pull the image:

```bash
docker pull ghcr.io/nvidia-ai-iot/vllm:qwen3.8-next-jetson-thor
```

Run this in a terminal you keep running. Use a separate terminal to interact with it.

```bash
docker run --rm --name qwen3.8-next-thor \
  --runtime nvidia --gpus all --ipc=host -p 8000:8000 \
  -v "$HOME/.cache/huggingface:/root/.cache/huggingface" \
  ghcr.io/nvidia-ai-iot/vllm:qwen3.8-next-jetson-thor \
  local-inference-lab/Qwen3.8-Flash-Next-NVFP4 \
  --served-model-name Qwen3.8-Flash-Next \
  --gpu-memory-utilization 0.93 \
  --max-num-seqs 1 \
  --mamba-ssm-cache-dtype bfloat16 \
  --enable-auto-tool-choice --tool-call-parser qwen3_xml \
  --reasoning-parser qwen3 \
  --hf-overrides '{"architectures":["Qwen4ExpForConditionalGeneration"],"model_type":"qwen4_exp"}' \
  --speculative-config '{"method":"mtp","num_speculative_tokens":3,"model":"/opt/qwen38-mtp-model"}'
```

## Build locally

From this repository on Thor:

```bash
docker build -t qwen3.8-next-thor .
```

Use `qwen3.8-next-thor` as the image in the run command above.

## Upstream PRs

These PRs need to merge and ship in the base vLLM image before the corresponding local workarounds are no longer needed:

- [#56102: Thor cooperative top-k fallback](https://github.com/vllm-project/vllm/pull/56102)
- [#54223: MXFP8 kernel selection](https://github.com/vllm-project/vllm/pull/54223)
- Native NVFP4 PLE table support. Upstream PR still needed.
