@echo off
cd /d "E:\USB AI BOT\AI-Bot"
start "" "bin\llama-server.exe" -m "models\qwen2.5-3b-instruct-q4_k_m.gguf" -c 4096 -t 8 --host 127.0.0.1 --port 8080
