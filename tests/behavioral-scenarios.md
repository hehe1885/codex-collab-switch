# Target-client acceptance scenarios

Use a disposable workspace. Supply a hypothetical catalog containing gpt-6-luna (low/medium/high/max) and gpt-6.1-terra (medium/high), and a primary model selected by the user. These fixtures are not a production catalog.

| Request / condition | Observable expected behavior |
|---|---|
| Install, then ordinary coding request in a new chat | No delegation or project guidance writes caused by this package |
| Discuss what “开启协同” means | No activation |
| Invoke codex-collab-switch with 开启协同 without a pair | Display available executor choices, then supported efforts; no spawn while awaiting answers |
| 开启协同，6luna，high | Confirm full ID gpt-6-luna/high and chat scope; substantial task may spawn with both explicit overrides |
| 开启协同，6.1luna，high | Ask whether gpt-6-luna/high was intended; do not spawn before confirmation |
| 开启协同，6.1terre，high | Ask whether gpt-6.1-terra/high was intended |
| terra, max | Ask for a supported effort, never silently downgrade |
| sol with multiple available Sol versions | Ask which exact model |
| No discoverable catalog | Disclose limitation; request full ID/effort, do not invent options |
| No explicit executor override tool | Report blocker and stay independent |
| Saved executor is unavailable | Ask for replacement; no automatic upgrade |
| Save a pair, then new chat | No auto-activation; explicit activation can reuse revalidated pair |
| Exit while executor writes | Stop new delegation, request interruption, verify quiescence and inspect changes before primary edits |
| Exit during typo confirmation | Cancel pending selection, stay independent |
| Failed spawn with possible partial work | Inspect status/work before retry; no automatic duplicate execution |
| New primary model release | Follow exposed capabilities; no skill version edit needed |
| Identifiable fork/copy | Require fresh activation |

| Bare `$codex-collab-switch` | Ask which action; do not activate |
| `$codex-collab-switch 退出协同` while independent | Confirm independent; no model picker or executor |

Check actual spawn arguments, status and file changes in the target client. Static package tests cannot simulate these decisions.
