# The built-in assistant

A panel beside the viewport where you type what you want ("a 40 × 30 × 10 mm
block with rounded edges", "add a 6 mm hole through the top") and an AI model
builds it in the open design. It is on iPad, iPhone and Mac, and in the web
app at app.openshape3d.com. Open it with the **Assistant** button (the
sparkles) in the top bar.

There are two ways to give it a model, and the panel offers both:

- **An API key of your own**, for whichever provider you use: Claude
  (Anthropic), ChatGPT's models (OpenAI) or Gemini (Google). The model then
  answers in the panel. The app has no key of its own and no server of its
  own in between.
- **An assistant app you already have**, over MCP, with no key: Claude Desktop
  or ChatGPT on the same Mac connects to OpenShape 3D and builds in the open
  design from its own window. This is the Mac app only. The panel's
  **Connect Claude Desktop or ChatGPT…** opens the same controls as
  Settings ▸ AI Assistant ([AI_MODELING_SETUP.md](AI_MODELING_SETUP.md)).

The two are independent: the panel needs neither the MCP switch nor a pairing
code, and an assistant app needs no API key.

## Using it with a key

1. Tap **Assistant** in the top bar.
2. Choose Claude, ChatGPT or Gemini. The panel shows what will be sent and to
   whom (below). Paste an API key and tap **Save Key and Start**. Keys are
   made at:
   - Claude: <https://platform.claude.com/settings/keys>
   - OpenAI: <https://platform.openai.com/api-keys>
   - Gemini: <https://aistudio.google.com/apikey>
3. Type a request and send it. The panel lists each step as it happens, and
   the view follows what is built.
4. Every step is an ordinary feature: it is in History and Undo takes it back.
   **Stop** ends the turn after the step that is running.

The "…" menu in the panel switches provider, picks the model, starts a new
chat, shows the tokens the chat has used, and removes the provider's key. You
can keep a key for each provider. Switching provider starts a new chat,
because a conversation cannot be handed from one provider to another.

## What is sent, and where

When you send a message, this device sends to the provider you chose
(`api.anthropic.com`, `api.openai.com` or
`generativelanguage.googleapis.com`), under your key:

- what you typed, and the conversation so far;
- the modelling guide and tool description that ship with the app;
- what the assistant reads from the design to do the work: body sizes and
  volumes, face and edge lists, sketches, and pictures of the viewport when it
  asks for one.

That provider bills your key for the usage, under its own terms for API use.
Nothing is sent to OpenShape 3D or to anyone else, nothing is sent to a
provider you did not choose, and nothing is sent until you send a message.

Each key is stored in the device's Keychain (this device only, not iCloud) and
leaves it only as a header of requests to its own provider. It is not written
to preferences, to a design file or to a log, and never put in a URL.

A conversation lasts as long as the design is open. It is not saved with the
design.

## What it can do

The same things as an assistant connected from outside: the one `os3d` tool
from `Agent/MCPTools.json`, with the modelling guide (`Agent/ModelingGuide.md`)
as its instructions. Reads (`state`, `faces`, `edges`, `check`, `screenshot`),
every recorded feature, views, undo and redo. All three providers get the same
tool and the same instructions.

One difference: on iPad and iPhone `document.export` is refused, because the
folder it writes to is inside the app where you cannot open it. The assistant
is told to point you at the Export menu. On a Mac it saves to Downloads as it
does for Claude Desktop.

## How it is built

| File | What it holds |
|---|---|
| `Assistant/AssistantProvider.swift` | The three providers and the switchboard between them: build a request, read a stream, put tool answers into a conversation, word a failure. `AssistantReply` is one reply in terms the loop understands. |
| `Assistant/AssistantWire.swift` | Claude: the Messages API as pure values. |
| `Assistant/OpenAIWire.swift` | OpenAI: the Responses API as pure values. |
| `Assistant/GeminiWire.swift` | Gemini: `streamGenerateContent` as pure values. |
| `Assistant/AssistantSession.swift` | One conversation and the request → tool calls → request loop, with Stop and retries. The same loop for every provider. |
| `Assistant/AssistantTools.swift` | Runs a tool call on this device: where an export lands, the one op an iPad cannot serve, and the words shown while a call runs. |
| `Agent/AgentLocalCall.swift` | The call itself. It phrases the call as the MCP `tools/call` it is and sends it through `AgentMCP.plan` → `AgentRouter` → `AgentBridge`, so the panel and outside assistants share one implementation. |
| `Assistant/AssistantPrompt.md` | Who the assistant is in this app; sent ahead of the modelling guide. |
| `Assistant/AssistantKeyStore.swift` | One key per provider in the Keychain. |
| `UI/AssistantPanelView.swift` | The panel: provider choice, notice and key entry, the MCP offer, transcript, message box. |

The app speaks each HTTP API directly, with a streamed reply read as
server-sent events. (Anthropic and OpenAI publish no Swift SDK, and Google's
comes as part of Firebase.) Every
event of all three is one JSON object on one `data:` line.

Rules that hold for all three:

- **A reply goes back as it came.** Each provider attaches something to a
  reply that only it can read and that it checks on the next request:
  Claude's thinking blocks (a signature), OpenAI's reasoning items (encrypted
  content), Gemini's `thoughtSignature` on a function call. The loop appends
  `AssistantReply.history` to the conversation untouched.
- **Every tool call is answered** before anything else is said, including the
  calls that were not run (Stop was pressed, or the reply was cut off).
- **Tool inputs are checked here** (`AssistantToolCall.problem`): a call
  whose input is not valid JSON, or has no `op`, is answered with an error and
  never run.
- **A conversation belongs to its provider.** The shapes differ, so changing
  provider starts a new chat.

Per provider:

- **Claude** (`POST /v1/messages`). Opus 5.5 by default; Sonnet 5.5, Haiku 5.5
  and Fable 5.2 in the menu. Adaptive thinking, effort `high`. The system
  block and the growing conversation are cached (`cache_control`), and bodies
  are serialised with sorted keys so the same conversation is the same bytes.
  Requests opt in to the API retrying a declined reply on another Claude model
  (`fallbacks: "default"`), except on Haiku 5.5; if a key cannot use the
  feature the app drops it and sends again. Roles alternate, so a message
  typed after a stopped turn joins the pending one.
- **OpenAI** (`POST /v1/responses`). GPT-6.2 Sol by default; GPT-6.2 Astra,
  GPT-6.1 Terra and GPT-6 Luna in the menu. The Responses API and not Chat
  Completions, because the flagship models only call tools through it.
  `store: false`: the conversation is kept on the device and sent whole each
  time. The tool is declared with `strict: false`, because its `args` is a
  free-form object. A tool answer has no error flag, so a failure that is not
  already JSON is prefixed `Error:`. A picture goes back as an `input_image`
  part of the `function_call_output`.
- **Gemini** (`POST …/models/{model}:streamGenerateContent?alt=sse`). Gemini 4
  Hydrogen by default; Gemini 4 Carbon, 3.8 Flash and 3.5 Flash-Lite in the
  menu. The key goes in `x-goog-api-key`. The tool's own JSON Schema is passed
  as `parametersJsonSchema`. Whether every model accepts its free-form `args`
  object is not settled by Google's reference, so if a request is refused over
  the tool's schema the app sends it again with `args` declared as text, and a
  call whose `args` arrives as text is read as the object it means. All the
  answers to one reply's calls go back together in one message; a picture goes
  back in the answer's `parts`. Google now calls `generateContent` a legacy
  API (its Interactions API is the default for new work); it is still
  supported, and is what this uses.

The model lists and request shapes were taken from each provider's reference
on 2026-11-26. Model names change; when one is retired, update the list in its
wire file and in the web app's matching file.

## The web app

The web app has the same panel (openshape-cloud `web/src/lib/assistant/`).
It is the same assistant, not a second one:

- The tool list, the modelling guide and `AssistantPrompt.md` are copied word
  for word by openshape-cloud's `core/scripts/sync_ios_sources.py`.
- `AgentExec`, `AgentRouter`, `AgentHTTP`, `AgentMCP`, `AgentBridge` and
  `AgentLocalCall` are compiled unchanged into the browser engine and reached
  through its `ed.agent` op. That is why the bridge's routes that need UIKit
  or the device live apart, in `Agent/AgentBridgeDevice.swift`: the web
  engine supplies its own `handleDeviceRoute`. Keep new device-only code in
  that file, or the web engine stops building.
- The loop and the three providers are ported one for one: `engine.ts`,
  `provider.ts`, `anthropic.ts` + `wire.ts`, `openai.ts`, `gemini.ts`. Claude
  goes through Anthropic's TypeScript SDK; OpenAI and Gemini are plain
  `fetch`, as here. A change to a provider's rules belongs on both sides.

What differs is the browser: a key is held in memory and saved to the site's
storage only if the person ticks "Remember on this browser"; the viewport
picture is drawn by the page; an export is downloaded. A browser tab cannot
accept connections, so the MCP route is not offered there; the panel says
where it lives.

## Testing

- `openshape3dTests/AssistantWireTests.swift`: Claude's wire layer.
- `openshape3dTests/AssistantProviderTests.swift`: OpenAI's and Gemini's wire
  layers and the switchboard. Both without a network or an editor.
- `openshape3dUITests/AssistantPanelUITests.swift`: the panel in the live app
  against a stand-in for the provider's API that runs inside the test. It
  speaks each provider's real streaming shape, builds a block through the
  real tool path once per provider, and fails the test if any request breaks
  that provider's rules (a tool call left unanswered, an answer in the wrong
  shape, something that had to go back unchanged missing).

DEBUG builds read three environment variables for that test:
`OS3D_ASSISTANT_URL` (where to send requests), `OS3D_ASSISTANT_KEY` (a key
that is not stored) and `OS3D_ASSISTANT_PROVIDER` (`anthropic`, `openai` or
`google`). Release builds ignore all three.

Not covered by an automated test: a conversation with any real API. That
needs a real key for each provider.
