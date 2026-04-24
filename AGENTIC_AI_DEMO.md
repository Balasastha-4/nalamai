# Proving agentic AI (Nalamai)

This demo is designed for **non-technical reviewers**: they should see **tool names**, **parameters**, and **real JSON** coming from your Spring Boot API—not a canned paragraph.

## What “agentic” means here

1. **Orchestrator** reads the user message and decides which **tools** to call (or Gemini proposes tools when `GOOGLE_API_KEY` is set).
2. Each tool runs **HTTP requests to the Java backend** (vitals, appointments, risk, history, etc.).
3. The Flutter chat shows an **“Agentic AI Actions”** card listing each tool and a **truncated live result**—that is your proof.

Two modes:

| Mode | When | What reviewers see |
|------|------|----------------------|
| **Full** | `GOOGLE_API_KEY` set, Gemini loads | LLM + real tool executions |
| **Tool-only** | No key or Gemini init fails | Same real tools; reply explains “live backend tools” |

## Preconditions (5 minutes)

1. **PostgreSQL** running; **Spring Boot** on `:8080` (`server.address=0.0.0.0`).
2. **AI service** on `:8000` (`cd ai_service && uvicorn main:app --host 0.0.0.0 --port 8000` or your Docker command).
3. `ai_service` `.env`: **`BACKEND_API_URL`** must reach the API (e.g. `http://localhost:8080` if AI runs on the same PC). The AI app enables **`allow_private_network`** CORS so Chrome does not reject `OPTIONS` with **400** when Flutter web calls `127.0.0.1:8000`.
4. **Log in** in the app so the agent sends a **JWT** (tools call secured endpoints).

## Demo script (say this aloud while you tap)

1. Open **Chat** (Agentic AI).
2. Type: **“Show my vitals and my upcoming appointments.”**  
   - Expect: `get_patient_vitals` and `get_appointments` in the actions card; values match what is in the DB (or empty arrays if none).
3. Type: **“What is my health risk?”**  
   - Expect: `get_health_risk` (or related predictive path).
4. Type: **“Summarize my medical history.”**  
   - Expect: `get_medical_history`.
5. Optional with Gemini: set **`GOOGLE_API_KEY`**, restart AI service, ask the same questions—replies become conversational **but** the tool card should still appear when the model invokes tools.

## If the actions card is empty

- Confirm **AI service** logs show `POST /api/ai/agent` **200**.
- Confirm Flutter **`AppConfig`** points the phone/emulator at the machine running AI + API.
- Confirm you are **logged in** (401s from backend will produce empty or error payloads).

## Optional “wow” for a live audience

- Pre-seed one appointment and one vital in the DB, then run step 2—the UI jumps from empty to **real rows** in the tool result snippet.
- Screen-record: split view **IDE logs** (HTTP to `/api/vitals/...`) + **phone chat** with the actions card.
