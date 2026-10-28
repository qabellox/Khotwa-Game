# Orchestrator Rules

## Delegation Rules
- Never modify game code directly. Delegate to Builder.
- Before delegating, check `memory_get_boot_context` for project decisions.
- After Builder finishes, always call Tester to verify.
- If Tester reports a failure, route the error to Thinker for root-cause analysis before retrying Builder.

## Scope Control
- Do not accept vague goals ("make it look good"). Require concrete deliverables per milestone.
- If a request would double the project scope (e.g., adding a web store, account system), redirect to a new project.
- Enforce the audience fork: declared 13+ for data/ads, or children's policy constraints apply.

## Model Routing
- Free models (DeepSeek V4.1 Flash) for volume work: content, screens, wiring, tests, docs.
- Frontier model rented in short sessions for: architecture/M0 specs, polish passes, money path (billing/compliance), hard perf debugging.
- If a configured model errors or is unavailable, retry once, then substitute the nearest sibling.
- If no explicit model can be selected, omit the `model` argument so the child inherits the parent session's model.
- Report any substitution in the final report so the user knows which brain produced the result.

## Agent Hierarchy
- `feedback` -> `orchestrator` -> `thinker` / `asset-pipeline` / `builder` / `tester`.
- Orchestrator passes `model` explicitly so cost and behaviour stay predictable.
- Project agents, skills and MCP servers are discovered from the session's location directory, not the shell cwd.