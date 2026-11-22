# GH-600 as this project's working method

Syllabus, not a study guide. The exam is **GH-600: Developing in Agentic AI Systems** (GitHub
Certified: Agentic AI Developer), 120 minutes, sat **Thu 2026-12-17**. Everything below uses the
exam's own wording for objectives so practice and exam language match.

Source of truth for the outline:
<https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/gh-600>
(verified 2026-11-22).

**Scope decision (Able, 2026-11-22): no GitHub Copilot.** Able's agent is Odin and GitHub is used
in full. Section 3a translates the Copilot vocabulary the exam uses into the mechanism we actually
run, so a Copilot-worded item stays answerable.

## 1. What is actually measured

Six domains, with the weights published in the study guide:

| domain | name | weight |
|---|---|---|
| D1 | Prepare agent architecture and SDLC processes | 15–20% |
| D2 | Implement tool use and environment interaction | 20–25% |
| D3 | Manage memory, state, and execution | 10–15% |
| D4 | Perform evaluation, error analysis, and tuning | 15–20% |
| D5 | Orchestrate multi-agent coordination | 15–20% |
| D6 | Implement guardrails and accountability | 10–15% |

The exam expects *experience*, not recall: "develop, deploy, operate, and manage agents that
operate within the software development lifecycle (SDLC)", "workflows in GitHub and controls",
"code quality, security, and review practices", and hands-on use of "GitHub Copilot, MCP servers
and agent customization such as custom instructions, custom agents, tools, and Copilot setup
steps."

## 2. What the track already contains

Prin's GH-600 track (`a8le.com/learn/prin/gh-600/`) maps one-to-one to the published objective
list: **65 objectives** encoded as `D<domain>.<group>.<item>` in `objectives.json`, and

| set | files | items |
|---|---|---|
| L0 resources | `gh600-l0-resources.json` | 5 sections of free links, checked 2026-11-21 |
| L1 quizzes | `gh600-q01` … `gh600-q20` | 20 × 5 MCQ = 100 |
| L2 exams | `gh600-e1`, `e2`, `e3` | 20 (diagnostic) + 22 (hard third) + 18 (integrative) |
| L3 mock | `gh600-l3-mock.json` | 20 items, 120 minutes, mixed `mcq`/`multi`/`blanks` |

The questions are scenario-based and well built — e.g. *"A team wants the agent to prepare changes
but not land them. Which split keeps GitHub as the control plane?"* — which is the same judgement
the exam asks for. What the track cannot give you is the thing the exam actually tests: **having
done it in a repository you own**. That is what this project is for.

## 3. The idea: the repository is the curriculum

synkty is not a toy for the course. It is a real product whose architecture is, almost line for
line, the GH-600 syllabus: agents are first-class users, every write is attributed, grants are
scoped and expiring, MCP is the agent interface, and the plan enforces plan-before-action. So
each domain is practised by shipping the artifact that domain describes, through GitHub's normal
mechanism — issue, branch, pull request, review, checks, merge.

Each week has the same shape: **read the domain's objectives → answer Prin's 3–4 quizzes for it →
open an issue that states the artifact → implement it on a branch → open a PR that a human merges
→ record what the agent did and what it got wrong.**

| week | dates | domain | Prin's sets | artifact shipped in synkty | GitHub skill learned |
|---|---|---|---|---|---|
| 1 | 11-23 → 11-29 | **D1** architecture + SDLC, planning distinct from execution | q01–q03, e1 diagnostic | `CONTRIBUTING.md`, `.github/ISSUE_TEMPLATE/agent-task.yml`, plan-before-action rule, `docs/decisions/0001-*.md` | issues as units of intent, labels, milestone, first PR review |
| 2 | 11-30 → 12-06 | **D2** tools, MCP, execution context | q04–q07, e1 retake | GitHub MCP server wired to Odin behind an allow list, `.github/workflows/agent.yml` with scoped `GITHUB_TOKEN`, retry/rollback job, `docs/traceability.md` | Actions syntax, job permissions, environments, branch-based scope, MCP registries |
| 3 | 12-07 → 12-13 | **D3 + D4** state/durable artifacts, evaluation and root-cause | q08–q13 | ADR folder as resumable state, issue-comment handoff protocol, `tools/eval/` + a CI job that emits a requirement→test report | artifacts as evidence, check runs, status gates, required checks |
| 4 | 12-14 → 12-17 | **D5 + D6** orchestration, guardrails, accountability | q14–q20, e2, e3, mock | two agents on isolated branches with conflict detection; `CODEOWNERS`, branch protection, least-privilege matrix, audit note | protected branches, required reviews, CODEOWNERS, merge queue discipline |
| — | after 12-17 | finish 0.1.0 Welcoming | — | real code | the same loop, now as the product's own process |

Exam day is Thursday of week 4. The mock paper should be sat **before** 12-14, timed, closed book:
120 minutes, same as the real thing.

## 3a. Copilot is not in this repo — the translation table

The exam's vocabulary is Copilot's. We practise each objective with our own tooling, and you learn
the noun as well as the mechanic, so the wording does not cost you marks.

| exam says | we run | where |
|---|---|---|
| custom instructions | the agent brief in `CONTRIBUTING.md` plus `docs/agent-rules.md` | W1 |
| custom agents | Odin's subagents, each with one written role and a scope | W4 |
| tools and tool permissions | MCP servers with an explicit allow list and a scoped token | W2 |
| add an MCP server as a tool | the GitHub MCP server, wired to Odin | W2 |
| GitHub remote MCP server | the same server over its remote endpoint, not a local stdio shim | W2 |
| MCP registries / allow lists | a checked-in `mcp.json` naming only permitted servers | W2 |
| Copilot setup steps | the workflow steps that provision the agent before it runs | W2 |
| branch-based scope | the agent works only on the issue branch; `main` is protected | W2, W4 |
| agent creates branches and pull requests | Odin does it, with the PR labelled `agent-authored` | W1 onward |

Rule of thumb: if an item names a Copilot screen you have never opened, answer the *principle* —
scope, permission, plan-before-action, review, evidence — because the four options almost always
differ on the principle, not the menu path.

## 4. Operating rules (the "GitHub philosophy" part)

These are stated once and then followed, because the exam tests judgement about exactly these:

1. **The issue is the unit of intent.** No branch without an issue; the issue states inputs,
   outputs and success criteria (D1.1.3) before any code exists.
2. **Plan before action.** An agent writes a structured plan into the issue, and a human approves
   it, before it touches a file (D1.2.1–D1.2.4). This is what makes "the agent checked and
   approved" real rather than rhetorical.
3. **`main` is protected.** PR-only, at least one human review, no force-push, no self-merge, and
   agent-authored PRs are labelled as such (D2.4.5, D6.2.3).
4. **Small PRs.** One objective per PR. If a PR covers two domains it is two PRs.
5. **Checks are the gate, not the reviewer's optimism.** Format, clippy, tests, and the
   requirement→test matrix must be green before review is requested.
6. **Artifacts over narration.** Plans, traces, evaluation reports and decisions live in files the
   next person can read (D3.2.1, D5.2.1).
7. **Failures get classified.** When an agent misses, the issue records the root cause — reasoning
   error, tool misuse, or context/environment — because that classification is D4.2.2 and it is
   how tuning actually happens.
8. **Autonomy is assigned, not assumed.** Each agent task carries a level (propose / prepare /
   land-with-review / land-autonomously) chosen by risk, not by convenience (D6.1.1–D6.1.2).

## 5. What the track does not cover, and what we do about it

- **Copilot-specific surfaces.** Nothing here uses Copilot, by your call; the translation table in
  3a maps each noun the exam uses onto the mechanism we run, and nothing else is needed.
- **No repository to break.** Everything is safe in theory; that is why week 1 starts by giving
  the repo protection, labels, and a real PR.
- **No evaluation tooling.** D4.1.4 wants automated scanning; the track has no lab for it. Week 3
  builds one in this repo instead of reading about it.
- **No multi-agent conflict.** D5.1.3 is about overlapping code changes and duplicated effort; you
  cannot learn that from a quiz. Week 4 runs two agents on two branches and resolves the collision.

## 6. State of play

Approved 2026-11-22: one domain per week, no Copilot, GitHub used in full. Still open:

1. **Cadence** — which evenings this week, and whether the mock is Sat 12-12 or Sun 12-13.
2. **Branch protection on `main`** — a click in Settings → Branches that only the owner can make.
   Without it, rule 3 is a promise, not a control.
3. **GitHub MCP server for Odin in week 2** — I will propose the exact config before anything is
   enabled, because it hands an agent a GitHub token and that is your decision, not mine.

Nothing in the repository has been restructured yet. When you say go, the first action is
deliberately small: create the labels and milestone, open issue #1 ("D1: state the agent task
contract"), and take it through branch → PR → review → merge with you driving.
