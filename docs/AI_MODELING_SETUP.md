# Ask Claude or ChatGPT for a part

> New here? The illustrated, step-by-step version is
> [CLAUDE_DESKTOP_TUTORIAL.md](CLAUDE_DESKTOP_TUTORIAL.md). This page is the
> reference: every client, the safety details, and the developer setup.

Describe what you want in plain English — "a flowerpot I can 3D print, about
11 cm wide, with a saucer" — and an AI assistant on your Mac models it in
OpenShape 3D while you watch, checks that it will print, and saves an STL to
your Downloads folder. No CAD experience and no terminal.

You need OpenShape 3D on a Mac, and Claude Desktop or the ChatGPT desktop app.

## 1. Switch it on

In OpenShape 3D: **Settings ▸ AI Assistant ▸ Let AI Assistants Build Here**.
It shows *Ready for Claude and ChatGPT* and a **pairing code**. It is off until
you turn it on, and you can turn it off again at any time.

## 2. Connect your assistant (once)

**Claude Desktop** — click **Add to Claude Desktop…**. Claude comes forward
with the extension: click **Install**, confirm, paste the pairing code (the
button already copied it), **Save**, and switch the extension to **Enabled**.
If nothing opens, double-click *OpenShape 3D.mcpb* in Downloads. The first
time Claude uses each OpenShape tool it asks; choose *Always allow*.

**ChatGPT (Codex)** — click **Copy Address for ChatGPT**. In ChatGPT's
settings add an MCP server with that address (it looks like
`http://127.0.0.1:8787/mcp`) and the pairing code as its bearer token.

Any other MCP client connects the same way: streamable HTTP at that address,
`Authorization: Bearer <pairing code>`.

## 3. Ask

Open or create a design in OpenShape 3D, then ask your assistant:

> Make me a flowerpot I can 3D print: about 11 cm wide at the top and 10 cm
> tall, with a hole in the bottom for water, and a saucer to go under it.
> Save the files so I can print them.

The part appears in the app step by step. When it is done, the STL files are
in **Downloads** — open them in your printer's slicer (Bambu Studio, Cura,
PrusaSlicer, …) and print. Everything the assistant did is ordinary, undoable
modelling: keep editing by hand, or ask for changes ("make it 15 cm tall").

## Is this safe?

- The app listens only on this Mac (`127.0.0.1`), only while the switch is on.
- It answers only callers that present your pairing code. Web pages are
  refused outright, code or not. *New Pairing Code* cuts off everything paired
  so far.
- An assistant can model in the open design, look at it, and save exports
  into Downloads (never over an existing file). It cannot open other files or
  reach anything else on your Mac through OpenShape 3D.
- OpenShape 3D itself sends nothing anywhere. What you type to Claude or
  ChatGPT goes to that assistant under its own privacy terms, along with the
  dimensions and screenshots of the model it asks the app for.

Details for the curious: `docs/AGENT_CONTROL.md`.

## For developers

The same channel has a development mode: launch a DEBUG build with
`OS3D_AGENT=1` (no pairing code; adds `/v1/capture` and `document.import`) and
drive it with `curl`, the Claude Code skills in `.claude/skills/`, or the
stdlib Python MCP server:

```bash
claude mcp add openshape3d -- /usr/bin/python3 /ABSOLUTE/PATH/TO/openshape3d/scripts/mcp_openshape3d.py
```

Claude Code can also use the app's own endpoint:

```bash
claude mcp add --transport http openshape3d http://127.0.0.1:8787/mcp --header "Authorization: Bearer <pairing code>"
```

Where things live:

| Piece | File |
|---|---|
| The switch, the pairing code, the Downloads writer | `openshape3d/Agent/AIControl.swift`, `UI/AIAssistantSettingsSection.swift` |
| The listener and who it answers | `Agent/AgentServer.swift`, `AgentRouter.refusal` |
| MCP in the app (`POST /mcp`) | `Agent/AgentMCP.swift`, `Agent/MCPTools.json` |
| The modelling guide (one source) | `.claude/skills/model-openshape3d/SKILL.md` → `Agent/ModelingGuide.md` |
| Claude Desktop extension | `integrations/claude-desktop/` → `OpenShape3D.mcpb` |
| Keep the copies identical, rebuild the extension | `python3 scripts/sync_ai_resources.py [--check]` |

Tests:

```bash
python3 scripts/test_mcp_openshape3d.py            # Python server: protocol, errors, export — no app needed
python3 scripts/test_mcp_openshape3d.py --live     # + models the flowerpot on a running, empty design
OS3D_TEST_SERVER_CMD="node integrations/claude-desktop/server/index.js" OS3D_PAIRING_CODE=<code> \
  python3 scripts/test_mcp_openshape3d.py --live LiveFlowerpot   # the same, through the Claude extension and /mcp
```

`AgentMCPTests` covers the in-app endpoint and the guard as pure values: no
answer without the code, no answer to a browser with it, export names that
cannot leave Downloads.
