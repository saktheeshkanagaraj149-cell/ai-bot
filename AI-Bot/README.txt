================================================================================
  AI Bot — Offline Qwen Chatbot (README)
================================================================================

A fully offline, portable AI chatbot that runs from a USB pendrive.
Double-click start.bat (Windows) or start.sh (Linux/macOS) and the bot
opens in your browser. No installation, no admin rights, no internet
required after setup.

================================================================================
1. FOLDER STRUCTURE (copy this onto your pendrive)
================================================================================

/AI-Bot
  start.bat            <- double-click to run (Windows)
  start.sh             <- Linux/macOS
  README.txt           <- this file
  /app
    index.html         <- single-file chat UI (HTML + CSS + JS, no CDN)
  /bin                 <- llama-server binaries (you add these)
  /models              <- .gguf model files (you add these)

================================================================================
2. DOWNLOAD CHECKLIST (exact filenames and sizes)
================================================================================

You must download two things yourself (they are too large to bundle):

A. llama.cpp server binary (CPU build)  --- place in /AI-Bot/bin/
   ------------------------------------------------------------------------
   Go to: https://github.com/ggerganov/llama.cpp/releases
   Pick a recent release (e.g. b4248 or later).
   Download the CPU-only server binary for your platform:

   Windows:  llama-server.exe            (~40–70 MB)  -> bin/llama-server.exe
   Linux:    llama-server                (~40–70 MB)  -> bin/llama-server
   macOS:    llama-server                (~40–70 MB)  -> bin/llama-server

   Optional Vulkan (GPU) build: llama-server-vulkan.exe

B. Qwen GGUF models  --- place in /AI-Bot/models/
   ------------------------------------------------------------------------
   Go to: https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF
     File: qwen2.5-1.5b-instruct-q4_k_m.gguf     (~0.94 GB)

   Go to: https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF
     File: qwen2.5-3b-instruct-q4_k_m.gguf       (~1.94 GB)

   Optional (16 GB RAM PCs only):
   Go to: https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF
     File: qwen2.5-7b-instruct-q4_k_m.gguf       (~4.70 GB)

Total pendrive usage with both required models:
  llama-server.exe   ~0.06 GB
  1.5B model         ~0.94 GB
  3B model           ~1.94 GB
  index.html         ~0.05 GB
  ----------------------------
  TOTAL              ~3.0 GB   (well under the 6.5 GB limit)

================================================================================
3. SETUP STEPS (copy everything onto the pendrive)
================================================================================

Step 1: Create the folder structure on your pendrive:
  E:\AI-Bot\
    start.bat, start.sh, README.txt
    app/index.html
    bin/          (empty)
    models/       (empty)

Step 2: Download llama-server.exe and put it in bin/.

Step 3: Download both GGUF models and put them in models/.

Step 4: Double-click start.bat (Windows) or run ./start.sh (Linux/macOS).
  - The script detects your RAM and picks 1.5B (< 6 GB) or 3B (>= 6 GB).
  - To override: Windows: set AI_BOT_MODEL=1.5B && start.bat
                 Linux/macOS: AI_BOT_MODEL=1.5B ./start.sh

Step 5: The bot opens in your default browser at the local UI.
  llama-server runs in the background on http://127.0.0.1:8080.
  Close the command window to stop the server.

================================================================================
4. HOW TO USE THE BOT
================================================================================

- Chat: type in the bottom box and press Enter (Shift+Enter for newline).
- Model: pick 1.5B (fast) or 3B (quality) from the dropdown. Note: the
  server only has ONE model loaded at a time (the one start.bat started).
  To switch models, restart start.bat with the other model.
- Temperature: slider controls creativity (0 = deterministic, 2 = random).
- System prompt: editable box that sets the assistant's behavior.
- Dark/light mode: toggle in the top bar.
- Agent mode: toggle ON to let the model use built-in tools. When ON, the
  model can output JSON tool calls and the app will execute them:
    * calculator        - evaluate math expressions
    * current_datetime  - current date and time
    * read_file         - pick a text/PDF/CSV file to read
    * save_note         - save a note to local storage
    * search_files      - search within loaded files
  Each tool call appears as a collapsible step in the chat.
- History: saved automatically in IndexedDB. New chat, rename, delete,
  and export to JSON/Markdown are all available.
- Status bar: shows whether the server is running and tokens/sec.

================================================================================
5. HOW TO ADD QWEN2.5-7B (16 GB RAM PCs ONLY)
================================================================================

1. Download qwen2.5-7b-instruct-q4_k_m.gguf (~4.70 GB) from the
   Qwen/Qwen2.5-7B-Instruct-GGUF page on Hugging Face.
2. Place it in /AI-Bot/models/.
3. Restart start.bat. The script does not auto-pick 7B (it stays at 3B
   unless you override). To force it: set AI_BOT_MODEL=7B ... but note
   start.bat only maps 1.5B and 3B. To use 7B, edit start.bat and add a
   case for "7B" pointing to the 7B filename, or manually run
   llama-server.exe with the 7B model and open app/index.html.

================================================================================
6. TROUBLESHOOTING
================================================================================

Q: "llama-server not found"
A: Place the CPU build of llama-server.exe in /AI-Bot/bin/ (see section 2).

Q: "Model file not found"
A: Download the GGUF file(s) and place them in /AI-Bot/models/ with the
   exact filenames from section 2.

Q: Server does not become ready / port 8080 in use
A: Another program is using port 8080. Close it, or change the port in
   start.bat (the --port 8080 argument) and re-run.

Q: Out of memory / slow on low-RAM PC
A: Use the 1.5B model (set AI_BOT_MODEL=1.5B). Lower the context size
   (change -c 4096 to -c 2048 in start.bat) and reduce threads (-t).

Q: Browser says "Server not running"
A: Make sure start.bat is running in the background. Check the log at
   %TEMP%\ai-bot-server.log (Windows) or ai-bot-server.log (Linux/macOS).

Q: Chat history not saving
A: Your browser may have IndexedDB disabled or in private/incognito mode.
   Use a normal browser window.

Q: PDF text extraction returns little or nothing
A: The built-in PDF extractor handles uncompressed and FlateDecode PDFs.
   Encrypted or image-only PDFs may not extract text.

Q: Agent tool calls don't work
A: Make sure Agent mode is ON. The model must output valid JSON like
   {"tool":"calculator","args":{"expression":"2+2"}}. Add instructions
   to the system prompt encouraging tool use.

================================================================================
7. SUGGESTED IMPROVEMENTS (for later versions)
================================================================================

1. RAG over documents — index loaded files locally (e.g. with a small
   vector search or keyword index) and let the model answer from them
   without re-reading each time.
2. Voice input — use the Web Speech API (window.webkitSpeechRecognition)
   to dictate messages instead of typing.
3. Multi-turn file context — keep loaded files in memory across chats
   so the model can reference them without re-picking.
4. Model auto-switching — detect which GGUF files are present and let
   the user switch models without restarting the server (llama-server
   supports multiple models via --model alias).
5. Conversation summarization — automatically summarize older messages
   when the context window fills up, to keep chatting within 4096 tokens.

================================================================================
  End of README
================================================================================
