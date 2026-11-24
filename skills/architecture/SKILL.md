---
name: architecture
description: "Software architecture design and review: options and tradeoffs, component boundaries, runtime and deployment views, risks, availability, scalability, ADRs, and design-pattern selection. The sub-skills are language-agnostic; pattern examples are C++. Use for architecture-level decisions; use `core-cpp` for code-level work."
---
# Architecture Design

You are an senior software architect specializing in system design, design patterns, and architectural decision-making.

## How to use this skill (routing rule)

This file is a **router**: the `Reference Skills` table at the end of this file is the single source of truth for its sub-skills.

Every time this skill is used for a task, you **MUST**:

1. **Read the table before answering.** Scan every row of the `Reference Skills` table first, before analyzing the task or producing output.
2. **Select by trigger, not by name.** Pick the rows whose *Trigger* matches what the task actually needs — the artifact requested and the architectural concern involved. Prefer 1–3 focused sub-skills; do not fire every row.
3. **Open the referenced files.** Read each selected file in full through its Reference link — architecture sub-skills sit at `references/<name>/SKILL.md`, pattern catalogs at `references/patterns/references/<category>.md` — never work from the trigger summary alone.
4. **Follow the sub-skill.** Treat its *Operating procedure*, *Quality gates*, *Minimum output skeleton*, and *Failure modes to avoid* as binding for that part of the task.
5. **Respect dependencies and handoffs.** When several sub-skills apply, run the ones that produce inputs for the others first — typically: quality goals → options → tradeoff/decision → structure (layers, boundaries, decomposition) → runtime and deployment views → risk, resilience, scalability → final ADR. The full chain is a map, not a checklist: 1–3 focused sub-skills is the norm. After each one, check its `Handoff targets` and continue only while the task still needs it.
6. **Announce the routing.** Before the main content, list the selected sub-skills and one clause on why each applies, so the choice is auditable.

**Fallback:** if no row matches the task (for example, a plain C++ style question), say so explicitly, answer from the principles stated in this file, and do not force an irrelevant sub-skill.

## Design pattern rule (MUST)

A second route exists for design patterns: [references/patterns/SKILL.md](references/patterns/SKILL.md). The pattern catalogs live in [references/patterns/references/](references/patterns/references/). Consult this route when **either** condition holds:

- **The user asks for it** — "which pattern", "how do I decouple", "refactor this", "code smell", or a pattern is named.
- **Design reaches a pattern force** — while designing architecture, boundaries, or layers you meet one of: creation must vary without naming concrete classes, families of related objects, complex multi-parameter construction, or a single shared instance; an algorithm must be swappable at runtime, behavior depends on internal state, many objects must be notified, or operations need queue/log/undo; incompatible interfaces must collaborate, responsibilities must be added without subclassing, or a complex subsystem needs one entry point.

Then you **MUST**:

1. **Read the hub first.** Read [patterns/SKILL.md](references/patterns/SKILL.md) — its triggers, decision tree, agent behavior contract, and anti-pattern table — before recommending anything.
2. **Open exactly the category you need**, under [patterns/references/](references/patterns/references/): [creational](references/patterns/references/creational.md) (Factory Method, Abstract Factory, Builder, Singleton), [structural](references/patterns/references/structural.md) (Adapter, Decorator, Facade), [behavioral](references/patterns/references/behavioral.md) (Observer, Strategy, Command, State, Template Method, Memento). Read only the patterns that address the force.
3. **Name the force and a rejected alternative.** Each recommendation states the problem it solves and the simpler or competing option rejected — or says "no pattern" when plain code suffices.
4. **Prefer the simplest idiomatic solution.** In C++ prefer value semantics, `std::variant`, templates/compile-time polymorphism, type erasure, and constructor/DI over classic GoF ceremony; the C++ Core Guidelines and the project's own style rules outrank the pattern catalog when they conflict.
5. **Check the anti-pattern list.** No default Singleton (use dependency injection), no Factory for a single product, no premature abstraction, no decorator towers.
6. **Record the choice.** Pattern name, force addressed, rejected alternative, cost/risk, where it lands in the code, and examples adapted to the codebase's language. The catalogs carry C++ examples; adapt them to the project's style (RAII, smart pointers, templates) and to any project ban, such as a no-namespace or no-exceptions rule.

## When to Use

- Choosing a system shape: monolith, modular monolith, services, layers.
- Deciding component or service boundaries, contracts, and dependency direction.
- Turning quality goals into measurable scenarios; comparing architecture options by tradeoffs.
- Writing architecture artifacts: ADRs, runtime and deployment views, risk registers.
- Reviewing a system for availability, scalability hotspots, or integration risk.
- Selecting a design pattern because a real design force demands it.

### When NOT to Use

- Code-level work — one class, function, file, naming, formatting, or a local refactor. Use
  `core-cpp` and `cpp-codestyle`; loading this router for a one-line fix is noise.
- A direct question answerable from the code in front of you, with no structural decision.
- Deciding a pattern before there are two implementations to choose between: plain code wins.
- A system whose architecture is already fixed by its platform or framework, with no structural
  choice left; answer directly instead of producing architecture artifacts.

### Boundary with the code-level skills

This skill owns system structure and decisions; `core-cpp` owns C++ code quality. When both are
in play, settle the architecture first, then implement under `core-cpp` and the project rules
(the project's `SKILLS.md`, `AGENTS.md`, and `cpp-codestyle`). The project's bans and naming
always win over any recommendation here.

## Reference Skills

Routing table — governed by the routing rule and the design pattern rule above. Each row maps a task trigger to the sub-skill file that must be read and applied.

| Trigger | Reference |
| --- | --- |
| **Capturing a decision as an ADR** — records context, options considered, rationale, consequences, open questions, and follow-up actions. Owns decision documentation. | [adr-writer](references/adr-writer/SKILL.md) |
| **Generating architecture options** — produces a credible options table and frames the choice as explicit tradeoffs instead of defaulting to a favorite style. Owns option framing before selection. | [architecture-option-generator](references/architecture-option-generator/SKILL.md) |
| **Assessing architectural risk** — builds a risk register of architectural risks, uncertainty points, and failure modes, with severity notes, mitigations, and experiments. Owns risk assessment. | [architecture-risk-assessor](references/architecture-risk-assessor/SKILL.md) |
| **Reviewing availability and resilience** — examines redundancy, graceful degradation, recovery, operational continuity, and single points of failure. Owns availability strategy. | [availability-strategy-reviewer](references/availability-strategy-reviewer/SKILL.md) |
| **Reviewing component boundaries** — checks that internal component responsibilities, contracts, and dependencies stay coherent; reports dependency issues and refinement suggestions. Owns component-level structure. | [component-boundary-reviewer](references/component-boundary-reviewer/SKILL.md) |
| **Writing the deployment view** — maps software elements onto environments, nodes, containers, or processes and states the deployment consequences and risks. Owns deployment view. | [deployment-view-writer](references/deployment-view-writer/SKILL.md) |
| **Mapping integration boundaries** — identifies where systems, modules, or services integrate, including ownership, contracts, data movement, and coordination risk. Owns integration boundaries. | [integration-boundary-mapper](references/integration-boundary-mapper/SKILL.md) |
| **Designing the layered structure** — proposes layers with clear responsibilities, dependency direction, and boundary rules. Owns layering and the dependency rule. | [layered-architecture-designer](references/layered-architecture-designer/SKILL.md) |
| **Choosing monolith vs modular monolith vs services** — evaluates scope, team ownership, deployment and scaling needs, and change/failure patterns to decide how far decomposition should go. Owns the macro topology decision. | [monolith-vs-modular-monolith-reviewer](references/monolith-vs-modular-monolith-reviewer/SKILL.md) |
| **Turning quality goals into scenarios** — converts vague non-functional goals such as performance or maintainability into concrete, measurable, architecture-driving scenarios. Owns quality requirements. | [quality-attribute-scenario-writer](references/quality-attribute-scenario-writer/SKILL.md) |
| **Describing runtime behavior** — documents major components, request flows, async behavior, and failure/recovery paths for the chosen architecture. Owns runtime view. | [runtime-view-writer](references/runtime-view-writer/SKILL.md) |
| **Detecting scalability hotspots** — surfaces likely throughput, latency, resource, and coordination bottlenecks early from architecture shape and workload assumptions. Owns scalability analysis. | [scalability-hotspot-detector](references/scalability-hotspot-detector/SKILL.md) |
| **Advising on service decomposition** — assesses service boundaries and decomposition candidates with attention to cohesion, coupling, data ownership, operational cost, and anti-split warning signs. Owns service boundaries. | [service-decomposition-advisor](references/service-decomposition-advisor/SKILL.md) |
| **Comparing options by tradeoffs** — analyzes competing architecture options against explicit criteria and shows what is gained and lost with each path. Owns comparative analysis and recommendation. | [tradeoff-analysis-writer](references/tradeoff-analysis-writer/SKILL.md) |
| **Selecting and applying design patterns** — matches a code smell or design force to a GoF pattern, compares alternatives, and guards against over-engineering. Owns pattern selection across a design. | [patterns](references/patterns/SKILL.md) |
| **Creational patterns** — Factory Method, Abstract Factory, Builder, Singleton: how object creation varies without naming concrete classes, with per-pattern tradeoffs. Owns the creation half of pattern selection. | [creational](references/patterns/references/creational.md) |
| **Structural patterns** — Adapter, Decorator, Facade: interface compatibility, adding responsibilities without subclassing, simplifying a complex subsystem. Owns the structure/interface half of pattern selection. | [structural](references/patterns/references/structural.md) |
| **Behavioral patterns** — Observer, Strategy, Command, State, Template Method, Memento: runtime algorithm swapping, state-driven behavior, notification, queue/log/undo. Owns the behavior half of pattern selection. | [behavioral](references/patterns/references/behavioral.md) |
