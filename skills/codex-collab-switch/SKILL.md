---
name: codex-collab-switch
description: Enable or exit collaboration in the current chat on explicit request; select available executor models and reasoning efforts with shorthand recognition and typo confirmation.
---

# Switch chat collaboration

## Route the request

Use the Codex skill picker or `$codex-collab-switch` with an action, or an explicit request such as “开启协同” / “退出协同” once this skill is loaded. Installing, loading, mentioning, comparing or quoting this skill is not activation. Do not delegate merely because a task is complex.

- “退出协同” / “恢复单模型”: immediately follow [exit.md](references/exit.md). This takes precedence over activation or pending selection. Do not run model selection. Exiting while already independent is harmless.
- “开启协同”: follow the activation and execution rules below.
- A bare invocation without an action: ask whether to enable or exit, or report current status when requested; do not change mode or spawn an executor.
- A request to change or save the executor pair: use [selection.md](references/selection.md); saving alone never activates collaboration.

## Chat scope

The default is independent execution by the model selected in the current chat. Never switch that model or its reasoning effort. Collaboration lasts only in this chat, until the user exits. Never persist activation to AGENTS.md, other project guidance, global instructions, configuration, preferences or memory. A new chat starts independent; when a copied/forked chat is identifiable, require fresh activation. If chat identity is unavailable, disclose that inherited history cannot be reliably distinguished; do not promise client-enforced isolation.

Before activation, read [selection.md](references/selection.md). Resolve both the executor's full model ID and supported reasoning effort. Pending selection is not activation: do not spawn an executor until missing choices and corrections are confirmed. If already active, a requested change stays pending and pauses new delegation until resolved; cancellation preserves the previous confirmed combination. An exit request always takes precedence over pending selection.

Confirm the full executor ID and effort and current-chat scope. Identify the primary model only from exposed metadata; otherwise say “当前对话模型”, never infer it from a repository name or old config. Retain the confirmed state in the chat, including context-compaction summaries, not project files.

## Execution

The primary model owns the plan, task boundaries, acceptance criteria and final review. Honor explicit requests to delegate. By default, delegate substantial implementation that can proceed from a concise, self-contained brief. Keep small, already-understood changes and tasks that would require the executor to repeat substantial exploration in the primary chat.

Use one executor with the confirmed full model ID and effort explicitly passed to the runtime's supported delegation tool. Use a fresh context (`fork_turns: none` where supported) and a concise brief covering the goal, relevant files and decisions, constraints, acceptance criteria and validation. Do not rely on full-history inheritance or create custom-agent/config files. Never silently use a runtime default instead of the selected combination. If explicit model/effort selection is unsupported, report the blocker and keep work independent; do not claim collaboration is active.

- Before handoff, read only enough to set scope, acceptance criteria, and key constraints. Have the executor locate the code, implement the change, and run targeted checks plus any required validation. Use the runtime's wait tool for completion or blockers when available. Check status as required by the runtime, to diagnose a stall, or to answer a user request.
- Include the return format and retry rule in the executor's brief. Ask for the main change, relevant files, check commands and outcomes, and remaining risks. Request log excerpts only as needed. If an attempted fix reproduces the same failure, try a targeted diagnostic or a different fix supported by the evidence. If blocked, return the failure and what was tried. Apply the same rule before delegating another correction.
- Group related files and steps for one user deliverable into one assignment. Across that deliverable, default to one primary review and, if corrections are needed, one focused recheck. Count any mid-task review toward the same budget. Start with the diff and check evidence. Verify the main user flow or execution path, acceptance criteria, and affected interfaces or material risks. Inspect surrounding code or rerun a check when needed to resolve a gap in the evidence.
- Batch blocking findings into one follow-up to the same executor when possible. Recheck the correction and affected checks. Before exceeding the review budget, identify the unresolved acceptance criterion, material risk, or user-requested verification and limit the extra pass to what resolves it.

Avoid simultaneous writing agents. Report the actual executor model/effort, verification, review result and limitations. Revalidate availability before a new spawn; if a selected model disappears, pause delegation and ask for a replacement. Preserve completed work and do not automatically retry a task that may already have produced side effects.

## Exit

An explicit “退出协同”, “恢复单模型” or `$codex-collab-switch 退出协同` ends collaboration. Follow [exit.md](references/exit.md) immediately, including during an ongoing task. Do not interpret a discussion of exit commands as an exit request.
