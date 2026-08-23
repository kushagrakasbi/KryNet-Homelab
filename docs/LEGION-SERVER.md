# ⚡ Legion Server Documentation

**KryNet AI, GPU & Supercomputing Engine | Ubuntu Server 26.04 LTS (Headless) | 192.168.0.150**

Legion is the **high-performance GPU compute node** of the KryNet 3-node homelab fleet. It provides hardware-accelerated LLM inference (CUDA), facial recognition and vector tagging for Immich, distributed 4K video transcoding for Tdarr, and hosts the universal AI gateway for autonomous fleet agents.

---

## 📋 Table of Contents

1. [Server Overview](#server-overview)
2. [Hardware Specifications](#hardware-specifications)
3. [OS & Hardware Hardening](#os--hardware-hardening)
4. [Service Architecture](#service-architecture)
5. [AI Supercomputing Stack](#ai-supercomputing-stack)
6. [Immich Machine Learning Offload](#immich-machine-learning-offload)
7. [Distributed Tdarr GPU Transcoder](#distributed-tdarr-gpu-transcoder)
8. [Monitoring & Portainer Agent](#monitoring--portainer-agent)
9. [OpenCode Fleet Agent Integration](#opencode-fleet-agent-integration)
10. [Maintenance & Operations Runbook](#maintenance--operations-runbook)
11. [Port & Network Reference](#port--network-reference)

---

## 🎯 Server Overview

### Role in KryNet Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     ⚡ LEGION COMPUTE NODE                       │
│                   (AI, GPU & Heavy Processing)                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│   │   AI Hub        │  │  Immich ML Node │  │  Tdarr Worker   │ │
│   │                 │  │                 │  │                 │ │
│   │ • Ollama (CUDA) │  │ • Face Detection│  │ • NVENC Transcode│ │
│   │ • LiteLLM (:4000│  │ • CLIP Tagging  │  │ • NFS Mount     │ │
│   │ • OpenWebUI     │  │ • Port 3003     │  │   from Prime    │ │
│   └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│   │   Agent Core    │  │   Monitoring    │  │    Storage      │ │
│   │                 │  │                 │  │                 │ │
│   │ • OpenCode CLI  │  │ • Node Exporter │  │ • Fast NVMe /tmp│ │
│   │ • Qwen 2.5 Coder│  │ • cAdvisor      │  │ • 1TB Storage   │ │
│   │ • DeepSeek R1   │  │ • Portainer Agt │  │ • NFS Client    │ │
│   └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🖥️ Hardware Specifications

| Component | Specification |
| :--- | :--- |
| **Model** | Lenovo Legion Gaming Laptop |
| **CPU** | Intel Core i7-12700H (14 Cores / 20 Threads, up to 4.7GHz) |
| **RAM** | 16GB DDR5 High-Speed Memory |
| **GPU** | NVIDIA GeForce RTX 3060 6GB Laptop GPU (Mobile GDDR6) |
| **Driver / CUDA** | NVIDIA 595.71.05 Server Open Driver / CUDA 13.2 |
| **Storage** | 1TB High-Speed NVMe PCIe 4.0 SSD |
| **Network** | Gigabit Ethernet (Static IP: `192.168.0.150`) |
| **OS** | Ubuntu Server 26.04 LTS (Headless, 64-bit) |

---

## 🛡️ OS & Hardware Hardening

Because Legion is a performance gaming laptop running as a 24/7 headless server, three critical protections are configured at the OS level:

### 1. Lid-Closed Server Operation
Prevents the system from sleeping or shutting down when the laptop lid is closed:
* **Configuration:** `/etc/systemd/logind.conf`
  ```ini
  HandleLidSwitch=ignore
  HandleLidSwitchExternalPower=ignore
  ```
* Applied via: `sudo systemctl restart systemd-logind`

### 2. Lenovo Battery Conservation Mode (60% Threshold)
Caps battery charge at ~60% directly in the Lenovo hardware controller (`VPC2004:00/conservation_mode`) to prevent battery degradation and thermal swelling.
* **Systemd Service:** `/etc/systemd/system/battery-conservation.service`
  ```ini
  [Unit]
  Description=Enable Lenovo Battery Conservation Mode
  After=multi-user.target

  [Service]
  Type=oneshot
  ExecStart=/bin/sh -c 'echo 1 > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode || true'
  RemainAfterExit=yes

  [Install]
  WantedBy=multi-user.target
  ```
* Enabled via: `sudo systemctl enable --now battery-conservation.service`

### 3. NVIDIA Container Toolkit
Configures Docker daemon with NVIDIA runtime:
```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

---

## 🤖 AI Supercomputing Stack

**Location:** `stacks/legion/ai-stack.yml`

```
┌──────────────────────────────────────────────────────────┐
│                      LITELLM GATEWAY                     │
│                  http://192.168.0.150:4000               │
├────────────────────────────┬─────────────────────────────┤
│   Local GPU Workloads      │     Cloud Fallbacks         │
│   (Ollama CUDA Engine)     │     (Anthropic / Google)    │
│   • qwen2.5-coder:7b       │     • claude-opus-4.6       │
│   • deepseek-r1:7b         │     • gemini-3-flash        │
│   • nomic-embed-text       │     • gpt-5.3               │
└────────────────────────────┴─────────────────────────────┘
```

### Containers
1. **`ollama`**: NVIDIA GPU passthrough (`reservations: devices: [driver: nvidia]`), running models in VRAM.
2. **`litellm`**: Unified OpenAI-compatible proxy gateway with master API key authentication, request routing, and load balancing.
3. **`openwebui`**: Web chat UI available at **`https://ow.krynet.cc`**.

---

## 🖼️ Immich Machine Learning Offload

**Location:** `stacks/legion/immich-ml.yml`

* **Container:** `immich-machine-learning:release-cuda`
* **Port:** `3003`
* **Role:** Offloads facial recognition (`mobile_face`), facial detection (`yunet`), and semantic image search (`ViT-B-16__laion2b_s34b_b88k`) from Prime to Legion's GPU.
* **Prime Connection:** Prime's `stack.env` contains `IMMICH_MACHINE_LEARNING_URL=http://192.168.0.150:3003`.

---

## 🎬 Distributed Tdarr GPU Transcoder

**Location:** `stacks/legion/tdarr-node.yml`

* **Node ID:** `LegionNode-RTX3060`
* **Server Connection:** `serverIP=192.168.0.100`, `serverPort=8266`
* **NFS Media Mount:** `/mnt/prime-media` (mounted from `192.168.0.100:/mnt/orion/data`)
* **Local Temp Cache:** `/home/legion/apps/docker/tdarr/temp` (utilizes Legion's ultra-fast NVMe for scratch encoding chunks)
* **Hardware Encoder:** NVENC HEVC / H.265 at 200–500+ FPS.

---

## 📊 Monitoring & Portainer Agent

**Location:** `stacks/legion/monitoring-sensors.yml`

| Container | Port | Purpose |
| :--- | :--- | :--- |
| **`portainer-agent`** | `9001` | Connects Legion to Portainer Server on Agni (`https://portainer.krynet.cc`) |
| **`node-exporter`** | `9100` | Exposes CPU, RAM, disk, and host metrics to Agni Prometheus |
| **`cadvisor`** | `8087` | Exposes container resource usage metrics |
| **`dozzle`** | `8088` | Real-time container log viewer (`https://logs3.krynet.cc`) |
| **`tailscale`** | Host Net | Secure remote VPN access to Legion |

---

## 🤖 OpenCode Fleet Agent Integration

Every node in the fleet (Agni, Prime, Legion) has OpenCode CLI installed, configured via **[`opencode.json`](../opencode.json)** to query Legion's LiteLLM gateway:

```bash
# Run sysadmin tasks via local GPU agent
opencode "Check Docker container health and restart any failed stacks"
```

---

## 🛠️ Maintenance & Operations Runbook

### Check GPU Utilization & Thermals
```bash
nvidia-smi
# Or CSV one-liner:
nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu --format=csv
```

### Pull a New Model into Ollama
```bash
docker exec -it ollama ollama pull <model-name>
```

### Inspect Container Logs
* **Web UI:** `https://logs3.krynet.cc`
* **CLI:** `docker logs -f <container_name> --tail 100`

### Verify Battery Conservation
```bash
cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
# Should return 1
```

---

## 📦 Stack Management & Portainer Architecture

Legion is integrated into the master Portainer server on **Agni (`https://portainer2.krynet.cc`)** via the Portainer Agent (`192.168.0.150:9001`).

| Stack / Service | Compose Source in Repo | Management Mode | Purpose |
| :--- | :--- | :--- | :--- |
| **`portainer_agent`** | [`stacks/legion/portainer-agent.yml`](../stacks/legion/portainer-agent.yml) | Docker Compose (Host Bootstrap) | Lightweight agent daemon connecting to Agni master |
| **`ai-stack`** | [`stacks/legion/ai-stack.yml`](../stacks/legion/ai-stack.yml) | Portainer Stack | Ollama CUDA, LiteLLM Gateway, OpenWebUI |
| **`immich-ml`** | [`stacks/legion/immich-ml.yml`](../stacks/legion/immich-ml.yml) | Portainer Stack | Immich ML CUDA acceleration for Prime |
| **`tdarr-node`** | [`stacks/legion/tdarr-node.yml`](../stacks/legion/tdarr-node.yml) | Portainer Stack | GPU video transcode worker |
| **`tailscale`** | [`stacks/legion/tailscale.yml`](../stacks/legion/tailscale.yml) | Portainer Stack | Tailscale Mesh VPN (`100.117.26.106`) |
| **`monitoring-sensors`** | [`stacks/legion/monitoring-sensors.yml`](../stacks/legion/monitoring-sensors.yml) | Portainer Stack | Node Exporter, cAdvisor, Dozzle |

---

## 🌐 Port & Network Reference

| Port | Service | Protocol | Notes |
| :--- | :--- | :--- | :--- |
| **22** | SSH | TCP | Headless admin access (`legion:legion`) |
| **3003** | Immich ML Node | HTTP | Internal API for Prime Immich Server |
| **3999** | OpenWebUI | HTTP | Reverse proxied to `https://ow.krynet.cc` |
| **4000** | LiteLLM Gateway | HTTP | Reverse proxied to `https://litellm.krynet.cc` |
| **8088** | Dozzle Logs | HTTP | Reverse proxied to `https://logs3.krynet.cc` |
| **8087** | cAdvisor | HTTP | Scraped by Agni Prometheus |
| **9001** | Portainer Agent | TCP | Connected to Agni Portainer Server |
| **9100** | Node Exporter | HTTP | Scraped by Agni Prometheus |
| **11434**| Ollama API | HTTP | Reverse proxied to `https://ollama.krynet.cc` |
| **-** | Tailscale | WireGuard | Tailnet IP: `100.117.26.106` (`legion-server`) |
