# openshape3d

Open-source iOS direct-modeling CAD app: SwiftUI + custom Metal renderer +
Euclid mesh-CSG kernel + parametric feature graph (topological naming).

**Start here: `docs/STATUS_AND_NEXT_STEPS.md`** — current phase status, the
prioritized next missions, dev workflow (simulator UDID, test commands,
UI-test helpers), and the gotchas list (SwiftData-in-XCTest crash, a11y
container collapse, bottom-overlay stacking, nonisolated defaults, …).
Update it at the end of each mission.

Spec/design companions: `docs/PARITY_SPEC.md`,
`docs/IMPLEMENTATION_PLAN.md`, `docs/PHASE_D_DESIGN.md`.
AI assistants (Claude Desktop / MCP) driving the app: `docs/AI_MODELING_SETUP.md`
(user tutorial `docs/CLAUDE_DESKTOP_TUTORIAL.md`, protocol `docs/AGENT_CONTROL.md`).
Modeling-core roadmap (sketch + solid parity, ordered with acceptance
criteria): `docs/MODELING_PARITY_GOALS.md`. Kernel strategy:
`docs/OCCT_BREP_PORT_DESIGN.md`.

Architecture seams (never bypass): geometry ops via `KernelOps`, mutations via
`DocumentCommand` (undoable), all state through `EditorViewModel`. Run tests
with `-parallel-testing-enabled NO`; unit-test geometry as pure values —
never instantiate `DocumentSession`/`ModelContainer` in tests.
