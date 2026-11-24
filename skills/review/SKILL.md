---
name: code-review
description: |
  Comprehensive code review guidance for C/C++ and Qt: correctness, safety, load, tests,
  performance, and lean code. Load the language sub-skill before reading the change:
  C++ -> references/cpp-review/SKILL.md, C -> references/c-review/SKILL.md,
  Qt -> references/qt-review/SKILL.md. Use when reviewing pull requests, a branch, the last
  commit, or uncommitted work; when judging over-engineering; or when setting review standards.
---

# Code Review Skill

Transform code reviews from gatekeeping to knowledge sharing through constructive feedback, systematic analysis, and collaborative improvement.

## Load the language guide first

Before reading the diff, open exactly one guide and apply it together with this file:

| Change contains | Read |
|---|---|
| C++ (any standard, any size) | [references/cpp-review/SKILL.md](references/cpp-review/SKILL.md) |
| C (C89–C23) | [references/c-review/SKILL.md](references/c-review/SKILL.md) |
| Qt (QObject, signals/slots, widgets, QML, models) | [references/qt-review/SKILL.md](references/qt-review/SKILL.md) |

A Qt change is also C++, so load `qt-review` plus `cpp-review` when both apply.

## When to Use This Skill

- Reviewing pull requests and code changes
- Reviewing uncommitted work, a branch, or the last commit ("review this", "review my PR")
- Judging whether a change is over-engineered ("is this over-engineered")
- Establishing code review standards for teams
- Mentoring junior developers through reviews
- Conducting architecture reviews
- Creating review checklists and guidelines
- Improving team collaboration
- Reducing code review cycle time
- Maintaining code quality standards

## Order of Importance

Review like the senior developer who will be paged when this change breaks. When two goals conflict, the earlier one wins:

1. **Correct** - wrong result, crash, a caller broken by the change.
2. **Safe** - security holes, data loss.
3. **Holds under load** - fine for one user, wrong for many.
4. **Tested** - risky logic has a test that fails when it breaks.
5. **Fast** - real slowdowns; small wins are suggestions.
6. **Lean** - every extra line must later be read, tested and fixed.

Lean is a review goal, not a matter of taste: dead code, unused options, speculative features and duplicate helpers are findings, not preferences. This review is a report the user asked for, so give it in full.

## Core Principles

### 1. The Review Mindset

**Goals of Code Review:**
- Catch bugs and edge cases
- Ensure code maintainability
- Share knowledge across team
- Enforce coding standards
- Improve design and architecture
- Build team culture

**Not the Goals:**
- Show off knowledge
- Nitpick formatting (use linters)
- Block progress unnecessarily
- Rewrite to your preference

### 2. Effective Feedback

**Good Feedback is:**
- Specific and actionable
- Educational, not judgmental
- Focused on the code, not the person
- Balanced (praise good work too)
- Prioritized (critical vs nice-to-have)

```markdown
❌ Bad: "This is wrong."
✅ Good: "This could cause a race condition when multiple users
         access simultaneously. Consider using a mutex here."

❌ Bad: "Why didn't you use X pattern?"
✅ Good: "Have you considered the Repository pattern? It would
         make this easier to test. Here's an example: [link]"

❌ Bad: "Rename this variable."
✅ Good: "[nit] Consider `userCount` instead of `uc` for
         clarity. Not blocking if you prefer to keep it."
```

### 3. Review Scope

**What to Review:**
- Logic correctness and edge cases
- Security vulnerabilities
- Performance implications
- Test coverage and quality
- Error handling
- Documentation and comments
- API design and naming
- Architectural fit
- Whether it still holds under the load the project expects
- Whether every line is needed (code to delete, reuse or merge)

**What Not to Review Manually:**
- Code formatting (use clang-format)
- Import organization
- Linting violations
- Simple typos

## Review Process

### Phase 1: Context Gathering (2-3 minutes)

Before diving into code, understand:
1. Review what the user names: uncommitted or staged changes, a branch, a PR link, or files. Nothing named: the uncommitted changes, or the last commit if there are none.
2. Read the PR description and linked issue
3. Check PR size (>400 lines? Ask to split)
4. Review CI/CD status (tests passing?)
5. Understand the business requirement
6. Note any relevant architectural decisions

Then read the code, not only the diff:
- Read every file the diff touches end to end, plus the callers of every changed function, the functions it calls, the tests, and the README.
- Trace the real flow: where data comes in, what is stored, what goes out.
- A change can break code it does not touch. When a signature, return value or behavior changes, grep every caller.
- Find the expected load in the repo (README, deploy config, service description): one person running a script, or many users and processes at once. Judge scale against that, and say which load you assumed.

> For large diffs, split the review by file or ask for a smaller change; there is no bundled
> analyzer script in this workspace.

### Phase 2: High-Level Review (5-10 minutes)

1. **Architecture & Design** - Does the solution fit the problem?
   - Check: SOLID principles, coupling/cohesion, anti-patterns
2. **Performance Assessment** - Are there performance concerns?
   - Check: Algorithm complexity, N+1 queries, memory usage
3. **File Organization** - Are new files in the right places?
4. **Testing Strategy** - Are there tests covering edge cases?

### Phase 3: Line-by-Line Review (10-20 minutes)

For each file, check:
- **Logic & Correctness** - Edge cases, off-by-one, null checks, race conditions
- **Security** - Input validation, injection risks, XSS, sensitive data
- **Performance** - N+1 queries, unnecessary loops, memory leaks
- **Maintainability** - Clear names, single responsibility, comments
- **Reuse** - Before accepting new code, search for existing utilities/helpers that could replace it. Check adjacent files and shared modules for similar patterns.

The detailed finding categories are in [What to Look For](#what-to-look-for) below.

### Phase 4: Summary & Decision (2-3 minutes)

1. Summarize key concerns
2. Highlight what you liked
3. Make clear decision:
   - ✅ Approve
   - 💬 Comment (minor suggestions)
   - 🔄 Request Changes (must address)
4. Offer to pair if complex

Write the review as described in [The Review Report](#the-review-report) - the three decision options above become the `Verdict:` line.

## What to Look For

Six kinds of finding, in the order of importance above. Each is a finding only with a concrete case, and each names the file and line.

1. **Bug** - wrong result, crash, missed edge case (empty container, zero, last element, rounding, time zones, integer overflow, `npos` compared against a real index), a caller broken by the change, or a fix applied in one caller while the shared function stays broken.

2. **Risk** - security holes (injection into a shell or SQL string, weak randomness, secrets in the source, unvalidated input from users or the network), data loss (errors swallowed, writes in the wrong order, no transaction).

3. **Scale** - fine for one user, wrong for many: check-then-write races, the same work repeated by every process, containers that only grow, a query or a file opened per item, O(n²) on big input, per-process state that must be shared.

4. **Missing test** - risky new logic (a branch, a parser, money, security, data writes, a bug fix) with no test that fails when it breaks. One good test, not coverage.

5. **Speed** - big slowdowns are problems. Small wins (work repeated in a hot loop, a needless copy of a big container) are suggestions; some software counts every millisecond.

6. **Lean** - code that should not exist or should be smaller:
   - **delete:** dead code, unused options, speculative features
   - **reuse:** the project already has this helper - name the path
   - **standard library:** `std::` or the platform already does it; a new dependency for a few lines
   - **yagni:** abstraction with one implementation, config nobody sets, a template parameter used by a single type
   - **merge:** near-copies that must change together
   - **split:** one function doing several unrelated jobs, so it is hard to read or test. Split by job, never by line count, and never into helpers that exist only to make a function shorter.

## Check Before You Report

- The project is the standard. Where `SKILLS.md`, `AGENTS.md`, or `cpp-codestyle` fixes naming, formatting, error strategy, or bans a mechanism (namespaces, exceptions, file-scope entities), a deviation from that rule is the finding; compliance with it is never a finding, even when an external guide prefers otherwise. If the project has no test harness, its verification recipe (build, end-to-end run, leak check) is the evidence; do not demand a unit test the project cannot run.
- Every finding needs a concrete case: "this input or situation leads to this wrong result". No case, no finding.
- Re-read the lines and confirm: the caller exists, the value can really be empty, the code really is unused. Grep instead of guessing.
- A shortcut marked with a `shortcut:` (or older `ponytail:`) comment that names its limit is a decision, not a finding - unless the expected load already crosses that limit.
- Propose the smallest fix that works. Prefer fixes that delete code. Never add layers, frameworks or config the problem does not need.
- No style taste, no "consider", no vague worries. Formatting and linting belong to clang-format and the static analyzer, not to a review comment.
- The language sub-skill supplies the language checks; this file supplies the process and report. `core-cpp/references/code-review.md` is a short summary of the same method, not a third standard.

## Review Techniques

### Technique 1: The Checklist Method

Use checklists for consistent reviews, walking the [What to Look For](#what-to-look-for) categories in order.

### Technique 2: The Question Approach

Instead of stating problems, ask questions:

```markdown
❌ "This will fail if the list is empty."
✅ "What happens if `items` is an empty array?"

❌ "You need error handling here."
✅ "How should this behave if the API call fails?"
```

### Technique 3: Suggest, Don't Command

Use collaborative language:

```markdown
❌ "You must change this to use async/await"
✅ "Suggestion: async/await might make this more readable. What do you think?"

❌ "Extract this into a function"
✅ "This logic appears in 3 places. Would it make sense to extract it?"
```

### Technique 4: Differentiate Severity

Use labels to indicate priority:

- 🔴 `[blocking]` - Must fix before merge
- 🟡 `[important]` - Should fix, discuss if disagree
- 🟢 `[nit]` - Nice to have, not blocking
- 💡 `[suggestion]` - Alternative approach to consider
- 📚 `[learning]` - Educational comment, no action needed
- 🎉 `[praise]` - Good work, keep it up!

**Severity levels:** 🔴 / 🟡 / 🟢 are the three severity tiers used as the standard across all guides in this skill - 🔴 blocks the merge, 🟡 should be addressed, 🟢 is optional. The remaining markers (💡 / 📚 / 🎉) are non-blocking annotations.

## The Review Report

Very simple English: short sentences, everyday words. Explain a technical term the first time you use it - the reader may never have seen this code.

Start with `What this change does:` in two or three sentences.

Then the findings in three groups, mapped onto the severity tiers above; skip empty groups:

- **Must fix** (🔴) - bug, security, data loss, breaks at the expected load.
- **Should fix** (🟡) - risky code without a test, real slowness, duplication, a function that mixes jobs, code that should not exist.
- **Nice to have** (🟢) - small speed-ups, shorter forms.

Number findings across all groups, so the user can answer "fix 2 and 5". Every finding has all four parts, each one or two short sentences:

```markdown
2. **Orders land on the wrong day** (`src/billing/close_day.cpp:L40-L52`)
   - **What this is:** At midnight this job closes the day and bills all orders of that day.
   - **Problem:** It takes "today" from the system clock, which runs in UTC. An order placed
     at 00:30 in Berlin is billed on the day before.
   - **Fix:** Compute the day once in the shop's time zone:
     `zoned_time{ "Europe/Berlin", system_clock::now() }.get_local_time()`.
     One line, nothing else changes.
   - **If we skip it:** Late orders show the wrong date, and accounting fixes them by hand.
```

End with:
- `Verdict: Ship.` or `Verdict: fix 1 and 3 first.`
- `Lean: -<N> lines possible.` when lean findings exist.
- `Not checked:` one line, if something mattered and you could not check it.

Nothing found: `What this change does:`, then `Looks good. Ship.` and one line on what you checked.

Lists findings, changes no code. Offer to fix them as a separate step.