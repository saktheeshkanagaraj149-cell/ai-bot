# AI Bot Coder: an offline coding assistant that runs from a USB drive

Plug in a pendrive, double-click **`start.bat`**, and get a private AI coding assistant in your browser.
It needs no internet, no installation, no admin rights and no Python. The model runs entirely on the computer's CPU.

![platform](https://img.shields.io/badge/platform-Windows%2010%2F11%20x64-blue)
![offline](https://img.shields.io/badge/internet-not%20required-brightgreen)
![model](https://img.shields.io/badge/model-Qwen2.5--3B%20fine--tuned-purple)
![engine](https://img.shields.io/badge/engine-llama.cpp-orange)

---

## Features

- **Fully offline and private.** Prompts and code never leave the machine.
- **Portable.** Everything (engine, models, UI) lives in one folder on the USB drive, and it works from any drive letter.
- **Fine-tuned coding model.** Qwen2.5-3B-Instruct, trained with QLoRA to give focused, correct code answers.
- **Modern chat UI** in a single HTML file with no CDN:
  - streaming answers with a Stop button (or <kbd>Esc</kbd>)
  - code blocks with syntax highlighting and a copy button
  - attach code or text files to a question (📎)
  - chat history saved in the browser, with search, rename, delete and export to `.md` / `.json`
  - Regenerate, tokens/s stats, light and dark themes, works on phone-sized screens
  - Settings: Precise / Balanced / Creative, temperature, answer length, system prompt
- **Automatic model choice.** It uses the coding model by default and falls back to a smaller model on PCs with little RAM.

## Quick start

1. Copy this folder to a USB drive (about 5 GB including the models).
2. On any Windows 10/11 PC, open **`AI-Bot`** and double-click **`start.bat`**.
3. Your browser opens **http://127.0.0.1:8080/**. Wait for the green status pill and start chatting.
4. **Keep the black window open** while you chat. Press any key in it to stop the bot.

> First run on a new PC: if Windows SmartScreen warns about `llama-server.exe`, click **More info → Run anyway**.

### Picking a model manually

```bat
cd AI-Bot
set AI_BOT_MODEL=3B && start.bat      REM CODER (default) | 3B | 1.5B
```

## Models

| Name | File | Size | Use |
|---|---|---|---|
| **CODER** (default) | `qwen2.5-3b-coder-ft-q4_k_m.gguf` | 1.8 GB | Fine-tuned for code chat |
| 3B | `qwen2.5-3b-instruct-q4_k_m.gguf` | 2.0 GB | General chat |
| 1.5B | `qwen2.5-1.5b-instruct-q4_k_m.gguf` | 1.0 GB | Auto-selected on PCs with under 6 GB RAM |

The model files are stored with **Git LFS**. Run `git lfs install` before cloning, or `git lfs pull` afterwards.

## Benchmark

10 Python coding tasks. Each generated answer was executed against unit tests (temperature 0, CPU only, Ryzen 7 7435HS):

| | Fine-tuned CODER | Original Qwen2.5-3B |
|---|---|---|
| Tests passed | **9 / 10** | 8 / 10 |
| Avg time per answer | **20.5 s** | 35.5 s |
| Avg answer length | 264 tokens | 462 tokens |
| Generation speed | 13.2 tok/s | 13.2 tok/s |

The fine-tuned model solved the LRU-cache task, which the base model failed, and answers about **40% faster** because its replies are shorter and to the point.

## How the model was fine-tuned

- **Base model:** `Qwen/Qwen2.5-3B-Instruct`
- **Method:** QLoRA (4-bit NF4, LoRA r=16, α=32, all attention and MLP projections) with 🤗 `transformers`, `peft` and `trl`, trained on one RTX 4060 Laptop GPU (8 GB)
- **Data (about 6.1k examples):**
  - 5,000 samples from [Magicoder-Evol-Instruct-110K](https://huggingface.co/datasets/ise-uiuc/Magicoder-Evol-Instruct-110K)
  - about 1,100 examples mined from personal projects (function implementation and code continuation), capped per project, with files that look like they contain secrets skipped
- **Training:** 1 epoch, LR 1e-4 cosine, seq len 2048, effective batch 16. Eval loss went from 0.99 to 0.97.
- **Export:** LoRA merged into fp16, converted with llama.cpp `convert_hf_to_gguf.py`, then quantized to **Q4_K_M**

## Project structure

```
.
├── start-server.bat          # shortcut → AI-Bot\start.bat
└── AI-Bot/
    ├── start.bat             # Windows launcher (auto RAM / model detection)
    ├── start.sh              # Linux/macOS launcher (needs that OS's llama-server build)
    ├── QUICK-START.txt       # one-page guide for end users
    ├── app/index.html        # chat UI (served by llama-server at /)
    ├── bin/                  # llama.cpp b12102 CPU build (llama-server.exe + DLLs)
    └── models/               # GGUF models (Git LFS)
```

## How it works

`start.bat` detects the PC's RAM and picks a model. It starts `llama-server` on `127.0.0.1:8080` with `--path app`, so the same local server hosts both the chat page and the OpenAI-compatible API (`/v1/chat/completions`), then opens the browser. Nothing listens on the network, only on localhost.

## Requirements

- Windows 10/11, 64-bit, and a CPU with AVX2 (most PCs from 2015 onward)
- 8 GB RAM recommended (6 GB minimum for the 3B models)
- About 5 GB of space on the USB drive. A USB 3 port makes the model load faster.

## Troubleshooting

| Problem | Fix |
|---|---|
| Red **Offline** pill | The `start.bat` window was closed. Run `start.bat` again. |
| No reply after an update | Hard refresh the page with <kbd>Ctrl</kbd>+<kbd>F5</kbd>. |
| Yellow **Loading model…** | Wait 10 to 60 seconds. Loading from USB is slow on the first run. |
| Slow answers | It's normal on older CPUs. Try `AI_BOT_MODEL=1.5B`. |
| Port 8080 already in use | Close other apps using it. `start.bat` stops old `llama-server` processes automatically. |

## Licenses and credits

- [llama.cpp](https://github.com/ggml-org/llama.cpp): MIT
- [Qwen2.5](https://huggingface.co/Qwen) models: subject to the Qwen license of each model (the 3B models use the Qwen Research License, **non-commercial use**)
- Training data: [Magicoder-Evol-Instruct-110K](https://huggingface.co/datasets/ise-uiuc/Magicoder-Evol-Instruct-110K)

Answers can be wrong. Review and test generated code before you use it.
