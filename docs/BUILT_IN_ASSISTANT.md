# The built-in assistant

A panel beside the viewport where you type what you want ("a 40 × 30 × 10 mm
block with rounded edges", "add a 6 mm hole through the top") and Claude
models it in the open design. It is on iPad, iPhone and Mac, and in the web
app at app.openshape3d.com. Open it with the **Assistant** button (the
sparkles) in the top bar.

It needs an API key from your own Anthropic account. The app has no key of its
own and no server of its own in between.

This is separate from Settings ▸ AI Assistant, which lets *other* apps on a
Mac (Claude Desktop, ChatGPT) connect to OpenShape 3D
([AI_MODELING_SETUP.md](AI_MODELING_SETUP.md)). The panel needs neither that
switch nor a pairing code.

## Using it

1. Tap **Assistant** in the top bar.
2. The first time, the panel shows what will be sent and where (below). Paste
   an API key and tap **Save Key and Start**. Keys are made at
   <https://platform.claude.com/settings/keys>.
3. Type a request and send it. The panel lists each step as it happens, and
   the view follows what is built.
4. Every step is an ordinary feature: it is in History and Undo takes it back.
   **Stop** ends the turn after the step that is running.

The "…" menu in the panel picks the model, starts a new chat, shows the tokens
the chat has used, and removes the key.

## What is sent, and where

When you send a message, this device sends to `api.anthropic.com`, under your
key:

- what you typed, and the conversation so far;
- the modelling guide and tool description that ship with the app;
- what the assistant reads from the design to do the work: body sizes and
  volumes, face and edge lists, sketches, and pictures of the viewport when it
  asks for one.

Anthropic bills your key for the usage, under Anthropic's terms for API use.
Nothing is sent to OpenShape 3D or to anyone else, and nothing is sent until
you send a message.

The key is stored in the device's Keychain (this device only, not iCloud) and
leaves it only as the `x-api-key` header of those requests. It is not written
to preferences, to a design file or to a log.

A conversation lasts as long as the design is open. It is not saved with the
design.

## What it can do

The same things as an assistant connected from outside: the one `os3d` tool
from `Agent/MCPTools.json`, with the modelling guide (`Agent/ModelingGuide.md`)
as its instructions. Reads (`state`, `faces`, `edges`, `check`, `screenshot`),
every recorded feature, views, undo and redo.

One difference: on iPad and iPhone `document.export` is refused, because the
folder it writes to is inside the app where you cannot open it. The assistant
is told to point you at the Export menu. On a Mac it saves to Downloads as it
does for Claude Desktop.

## How it is built

| File | What it holds |
|---|---|
| `Assistant/AssistantWire.swift` | The Messages API as pure values: request body and headers, the streamed reply put back together, what is sent back, tool answers, error wording. |
| `Assistant/AssistantSession.swift` | One conversation and the request → tool calls → request loop, with Stop and retries. |
| `Assistant/AssistantTools.swift` | Runs a tool call on this device: where an export lands, the one op an iPad cannot serve, and the words shown while a call runs. |
| `Agent/AgentLocalCall.swift` | The call itself. It phrases the call as the MCP `tools/call` it is and sends it through `AgentMCP.plan` → `AgentRouter` → `AgentBridge`, so the panel and outside assistants share one implementation. |
| `Assistant/AssistantPrompt.md` | Who the assistant is in this app; sent ahead of the modelling guide. |
| `Assistant/AssistantKeyStore.swift` | The key in the Keychain. |
| `UI/AssistantPanelView.swift` | The panel: notice and key entry, transcript, message box. |

Swift has no official Anthropic SDK, so the app speaks the HTTP API directly:
`POST /v1/messages` with `stream: true`, read as server-sent events.

Choices worth knowing before changing it:

- **Models.** Claude Opus 5.5 by default; Sonnet 5.5, Haiku 5.5 and Fable 5.2
  in the menu. Thinking is adaptive and effort is `high` on all of them.
- **Caching.** The guide and tool are the same on every request, so the
  system block carries `cache_control`, and a top-level `cache_control` caches
  the conversation as it grows. Bodies are serialised with sorted keys so the
  same conversation is the same bytes.
- **Replies go back unchanged.** Thinking blocks carry a signature that only
  verifies if the block is returned exactly as received. The two exceptions
  the API asks for are in `AnthropicWire.echo`.
- **Tool inputs are checked here.** They stream as they are written
  (`eager_input_streaming`), which means the API does not validate them. A
  call whose input is not valid JSON, or has no `op`, is answered with an
  error and never run.
- **Declined requests.** Requests opt in to the API retrying a declined reply
  on another Claude model (`fallbacks: "default"`), except on Haiku 5.5, which
  has no such retry. If a key cannot use the feature the app drops it and
  sends again.
- **Roles alternate.** If a turn is stopped before the model replies, the next
  message joins the pending one instead of adding a second user message.

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
- Requests go through Anthropic's TypeScript SDK there; the loop and the
  rules in `AssistantWire.swift` are ported one for one (`engine.ts`,
  `wire.ts`). A change to either side's rules belongs on both.

What differs is the browser: the key is held in memory and saved to the
site's storage only if the person ticks "Remember on this browser"; the
viewport picture is drawn by the page; an export is downloaded.

## Testing

- `openshape3dTests/AssistantWireTests.swift`: the wire layer, with no network
  and no editor.
- `openshape3dUITests/AssistantPanelUITests.swift`: the panel in the live app
  against a stand-in for the API that runs inside the test. It speaks the real
  streaming shape, builds a block through the real tool path, and fails the
  test if any request breaks the API's rules (roles out of order, a tool call
  left unanswered, an empty text block).

DEBUG builds read two environment variables for that test:
`OS3D_ASSISTANT_URL` (where to send requests) and `OS3D_ASSISTANT_KEY` (a key
that is not stored). Release builds ignore both.

Not covered by an automated test: a conversation with the real API. That
needs a real key.
