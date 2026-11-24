---
name: main-skill
description: "Entry point for C++/Qt-related work: load this skill first, then select a specialized skill based on it. It references address-sanitizer, architecture, ci-cd-best-practices, codestyle, core-cpp, docker, grpc-expert, code-review, ui-ux-design, and sql-postgresql, with explanations on when each should be used."
---

# Main skill — Entry Point

This skill should be loaded first for any task within this workspace. It does not replace
specialized skills; rather, it is used to select 1–3 of them. An explicit instruction from the user
takes precedence over any entry in the table.

## How to Use

1. Identify the type of task and select the rows that match the "When" criterion.
2. Load the selected skills—using their exact names—via the `skill` tool. If a skill is not in the catalog, refer to the file linked.
3. Before providing an answer, state which skills have been loaded and why.
4. Do not load all rows at once; doing so adds unnecessary context and may lead to conflicting advice.

## Overriding Rules

- Project rules (`SKILLS.md`, `AGENTS.md`) and the `cpp-codestyle` take precedence over any skill.
- The use of namespaces, exceptions, and file-level entities is prohibited; variables must follow `snake_case` naming conventions.
- If a skill contradicts the project rules, the project rules prevail.

| Exact Skill Name | File | When to Use |
|---|---|---|
| `core-cpp` | [../core-cpp/SKILL.md](../core-cpp/SKILL.md) | Any C++ work at the code level: writing, refactoring, reviewing, or defining standards. Not for system design. |
| `codestyle` | [../codestyle/SKILL.md](../codestyle/SKILL.md) | For minimal, complete diffs, YAGNI, and lean code; a general approach applicable to any task. Does not replace `core-cpp`. |
| `architecture` | [../architecture/SKILL.md](../architecture/SKILL.md) | System design: monoliths/services, boundaries, trade-offs, ADRs, runtime/deployment, risks, and patterns. Not for individual functions. |
| `code-review` | [../review/SKILL.md](../review/SKILL.md) | Reviewing PRs, branches, commits, or uncommitted changes. Loads `cpp-review`, `c-review`, and `qt-review`. |
| `address-sanitizer` | [../address-sanitizer/SKILL.md](../address-sanitizer/SKILL.md) | Memory corruption, fuzzing, and ASan/LSan on Linux/Clang. For memory leaks in Windows-Qt environments, use `leak-check-crt` first. |
| `sql-postgresql` | [../sql-postgresql/SKILL.md](../sql-postgresql/SKILL.md) | SQL and PostgreSQL: queries, indexes, execution plans, JSONB, and transactions. Existing schema takes precedence over style. |
| `grpc-expert` | [../gRPC/SKILL.md](../gRPC/SKILL.md) | `.proto` files, streaming, channels, deadlines, and status codes. | Do not modify existing, functional components unless requested. |
| `ci-cd-best-practices` | [../ci-cd/SKILL.md](../ci-cd/SKILL.md) | Pipelines, deployment, IaC, CI testing. Do not apply to C++ code. |
| `docker` | [../docker/SKILL.md](../docker/SKILL.md) | Only if the project is genuinely containerizable. Not applicable to a Qt client. |
| `ui-ux-design` | [../ui-ux-design/SKILL.md](../ui-ux-design/SKILL.md) | Web UI/UX only. Do not apply to Qt Widgets/QML; use `code-review` with `qt-review` instead. |


## Common mistakes

- Uploading `architecture` for just a single line of code.
- Confusing `core-cpp` with `codestyle`: `codestyle` refers to a methodology, while `core-cpp` refers to C++ rules.
- Applying `docker`, `ui-ux-design`, or `ci-cd` to a Qt client without an explicit request.
- Uploading all skills at once.
