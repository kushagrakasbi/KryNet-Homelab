# 🤖 AI Stack Documentation

**KryNet AI Hub | OpenWebUI + Ollama + LiteLLM | Legion Compute Node (192.168.0.150)**

The AI stack provides a unified chat, embedding, and API platform for both **local GPU LLMs** (via Ollama on RTX 3060 6GB CUDA) and **cloud APIs** (Claude, GPT, Gemini via LiteLLM), accessible at `https://ow.krynet.cc` and serving terminal agents fleet-wide.

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Why Legion Compute Node](#why-legion-compute-node)
3. [Component Roles](#component-roles)
4. [Docker Compose Configuration](#docker-compose-configuration)
5. [Local Models on RTX 3060 (Ollama)](#local-models-on-rtx-3060-ollama)
6. [LiteLLM Gateway & Cloud API Proxy](#litellm-gateway--cloud-api-proxy)
7. [OpenWebUI Configuration](#openwebui-configuration)
8. [OpenCode Fleet Agent Integration](#opencode-fleet-agent-integration)
9. [Immich Machine Learning Coexistence](#immich-machine-learning-coexistence)
10. [Maintenance & Operations Runbook](#maintenance--operations-runbook)
11. [Port & Endpoint Reference](#port--endpoint-reference)

---

## 🏗️ Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                    USERS & FLEET CODING AGENTS                       │
│    (OpenWebUI via ow.krynet.cc | OpenCode CLI on Agni/Prime/Legion)  │
└────────────────────────────┬─────────────────────────────────────────┘
                             │
                   ┌─────────▼──────────┐
                   │     OpenWebUI       │
                   │    :3999 (8080)     │
                   │   Chat Interface    │
                   └────────┬───────────┘
                            │
               ┌────────────┴────────────┐
               │                         │
     ┌─────────▼─────────┐    ┌─────────▼─────────┐
     │      Ollama        │    │     LiteLLM       │
     │   :11434 (11434)   │    │   :4000 (4000)    │
     │   Local Models     │    │   API Gateway     │
     │                    │    │                    │
     │  • qwen2.5-coder:7b│    │  • Claude Opus     │
     │  • deepseek-r1:7b  │    │    4.6 / Sonnet    │
     │  • nomic-embed     │    │  • GPT 5.3 / 5.2   │
     │  🎮 RTX 3060 6GB   │    │  • Gemini 3 Flash  │
     └────────────────────┘    └───────────────────┘
```

---

## 📍 Why Legion Compute Node

| Factor | Legion (Yes) | Prime (No) | Agni (No) |
|--------|---------|---------|--------|
| **GPU** | RTX 3060 6GB (CUDA Ampere) | GTX 1060 3GB (Legacy Pascal) | No GPU |
| **RAM** | 16GB DDR5 High-Speed | 32GB DDR4 (ZFS ARC/Media) | 16GB DDR5 |
| **Ollama** | Full GPU offload (7B/8B models) | Limited by 3GB VRAM | CPU-only |
| **Role fit** | Dedicated AI & GPU Compute | Storage vault & streaming | Network core |

---

## 🧩 Component Roles

| Component | Port | What It Does | Why You Need It |
|-----------|------|-------------|-----------------|
| **Ollama** | `11434` | Runs local LLMs with CUDA GPU acceleration | Free, private, zero-latency inference for coding & sysadmin agents. |
| **LiteLLM** | `4000` | Unified API proxy for local & cloud models | Single OpenAI-compatible endpoint with auth keys, fallback routing, and spend tracking. |
| **OpenWebUI**| `3999` | ChatGPT-style web interface | Unified multi-model chat accessible at `https://ow.krynet.cc`. |

---

## 🛠️ Docker Compose Configuration

**Path on Legion:** `/home/legion/home-server/stacks/legion/ai-stack.yml`

```yaml
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - /home/legion/apps/docker/ollama:/root/.ollama
    environment:
      - OLLAMA_KEEP_ALIVE=24h
      - OLLAMA_FLASH_ATTENTION=1
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    networks:
      - legion_net

  litellm:
    image: ghcr.io/berriai/litellm:main-latest
    container_name: litellm
    restart: unless-stopped
    ports:
      - "4000:4000"
    volumes:
      - /home/legion/apps/docker/litellm/config.yaml:/app/config.yaml
    environment:
      - LITELLM_MASTER_KEY=${LITELLM_MASTER_KEY}
    command: ["--config", "/app/config.yaml", "--port", "4000"]
    networks:
      - legion_net

  openwebui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: openwebui
    restart: unless-stopped
    ports:
      - "3999:8080"
    volumes:
      - /home/legion/apps/docker/openwebui:/app/backend/data
    environment:
      - OPENAI_API_BASE_URL=http://litellm:4000/v1
      - OPENAI_API_KEY=${LITELLM_MASTER_KEY}
      - OLLAMA_BASE_URL=http://ollama:11434
    networks:
      - legion_net

networks:
  legion_net:
    name: legion_net
    external: true
```

---

## 🚀 Local Models on RTX 3060 (Ollama)

```bash
# 1. Primary Coding & Terminal Agent (Qwen 2.5 Coder 7B - ~4.7GB VRAM)
docker exec -it ollama ollama pull qwen2.5-coder:7b

# 2. Deep Reasoning & Troubleshooting Model (DeepSeek R1 7B - ~4.7GB VRAM)
docker exec -it ollama ollama pull deepseek-r1:7b

# 3. Fast Vector Embedding Model (for document search in OpenWebUI)
docker exec -it ollama ollama pull nomic-embed-text
```

---

## 🤖 OpenCode Fleet Agent Integration

All nodes across the KryNet fleet use **OpenCode CLI** connected to LiteLLM on Legion:

**Repository Configuration:** [`opencode.json`](../opencode.json)

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "litellm": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "KryNet LiteLLM Gateway",
      "options": {
        "baseURL": "http://192.168.0.150:4000/v1"
      },
      "models": {
        "qwen2.5-coder": {
          "name": "Qwen 2.5 Coder (Local GPU)"
        },
        "deepseek-r1": {
          "name": "DeepSeek R1 7B (Local Reasoning)"
        },
        "gemini-3-flash": {
          "name": "Gemini 3 Flash (Google AI Cloud)"
        },
        "claude-opus-4.6": {
          "name": "Claude Opus 4.6 (Anthropic Cloud)"
        }
      }
    }
  }
}
```

---

## 🖼️ Immich Machine Learning Coexistence

Legion also hosts the remote **Immich Machine Learning CUDA node** on port `3003` (`stacks/legion/immich-ml.yml`).
* Both Ollama and Immich ML share the RTX 3060 GPU dynamically.
* Immich ML models (`mobile_face`, `yunet`, `ViT-B-16__laion2b_s34b_b88k`) load into VRAM on demand during facial recognition or photo scans and release memory when idle.

---

## 🛠️ Maintenance & Operations Runbook

### Check GPU VRAM and Utilization
```bash
ssh legion@192.168.0.150 "nvidia-smi"
```

### LiteLLM Gateway Health Check
```bash
curl http://192.168.0.150:4000/health/liveliness
```

### OpenCode Quick Test
```bash
opencode "Check system memory and GPU temperature on this node"
```

---

## 🌐 Port & Endpoint Reference

| Service | Node IP | Internal Port | Ingress URL | Auth |
| :--- | :--- | :--- | :--- | :--- |
| **OpenWebUI** | `192.168.0.150` | `3999` | `https://ow.krynet.cc` | Web Login |
| **LiteLLM Gateway**| `192.168.0.150` | `4000` | `https://litellm.krynet.cc` | Master Key |
| **Ollama API** | `192.168.0.150` | `11434` | `https://ollama.krynet.cc` | Direct / LAN |
| **Immich ML Node** | `192.168.0.150` | `3003` | `http://192.168.0.150:3003`| Internal LAN |
