# Documenting a Codebase with an AI Agent

A generalized, battle-tested method for using an AI coding agent to produce comprehensive documentation for any codebase you didn't write. Distilled from documenting a ~200-file monorepo across three tech stacks.

---

## The Core Idea

Work **bottom-up**: inventory → per-file cards → feature diagrams → architecture overview → verify against source. Never skip a level. Each layer feeds the next.

---

## Step 0 — Prepare

1. Create a `docs/` tree: `classes/`, `features/`, `architecture/`, and a future `_index.md`.
2. Define exclusions: generated code, build output, platform boilerplate, binaries, lock files, `node_modules/`.
3. If the project has multiple components (frontend, backend, admin), create subdirectories under `classes/` for each.

## Step 1 — Inventory

Have the agent walk every source file and produce a structured inventory (JSON or markdown table) listing:
- File path
- Classes / types / components defined
- Superclasses, interfaces, mixins
- Internal imports (skip stdlib / framework imports)
- Notable third-party packages

**Do not document anything yet** — just map what exists and how many files per folder.

## Step 2 — Per-File Documentation (the bulk of the work)

### The non-negotiable rule

**One folder at a time.** Never batch the entire codebase into a single prompt. Large passes produce shallow, hallucinated docs. Small passes let you spot-check and course-correct.

### Triage: cards vs. summaries

Not every file deserves a full page. Before each folder, have the agent read the files and classify:

- **Card** — file has meaningful logic, state, or branching (controllers, services, models with validation, complex widgets). Gets its own markdown file.
- **Summary** — file is a thin data class, config wrapper, or layout-only component. Group several into one `summary_*.md`.

This keeps the doc set navigable instead of drowning in 200 near-empty pages.

### Card template

```markdown
# ClassName
**File:** `path/to/file`  
**Type:** class | enum | interface | mixin  
**Extends / Implements:** …

## Purpose
1-3 sentences. What does it do? What role does it play in the system?

## Fields / State
| Field | Type | Description |

## Key Methods
| Method | Description |

## Dependencies
- Other project classes this directly uses, with one-line reason.

## Notes
- Code smells, TODOs, SRP violations, surprising behaviour.
```

### After each folder
1. Spot-check 3-5 cards against actual source code.
2. Fix systematic prompt issues before the next folder.
3. Mark the folder done in a progress tracker.

## Step 3 — Feature Diagrams

Identify the logical features of the application (usually 5-15). For each, produce a single markdown file containing:

1. **Class diagram** (Mermaid) — which classes participate and how they relate, cutting across all layers / stacks.
2. **Sequence diagram** (Mermaid) — the primary user-facing flow end-to-end.
3. **Prose summary** — one paragraph: what the feature does, its entry points, and cross-feature dependencies.
4. **Improvement observations** — note coupling issues, missing error handling, security gaps.

Also produce a **features overview** file with a matrix of features × stacks showing coverage.

Consolidate improvement observations into a standalone **improvement proposals** doc, prioritized (P0 critical → P3 nice-to-have).

## Step 4 — Dependency Map

Produce `architecture/dependency_map.md` containing:

1. Feature-to-feature dependency graph (Mermaid).
2. Shared services heat map — which classes appear across 3+ features.
3. Circular dependencies (distinguish compile-time vs. runtime — they need different fixes).
4. Coupling hotspots — files with the most inbound or outbound dependencies.

## Step 5 — Architecture Overview

Produce `architecture/overview.md` synthesizing everything into:

1. Architecture style characterization.
2. System-level deployment diagram.
3. Layer diagram (UI → controllers → services → data → external).
4. Navigation / routing structure.
5. State management patterns.
6. Representative data-flow sequence.
7. Tech debt summary (aggregated from per-file notes).
8. Glossary of domain terms.

## Step 6 — Infrastructure (if applicable)

Document the deployment and operational layer:

- Container orchestration (Docker Compose / K8s): services, ports, volumes, networks, health checks.
- Dockerfiles: build stages, base images.
- Database schemas: tables, foreign keys, indexes, divergences between server and client schemas.
- Reverse proxy / web server config.
- Secrets and environment variables (catalogue them, flag plaintext secrets).
- External services (TURN/STUN, third-party APIs).

## Step 7 — Master Index

Generate `_index.md` linking every document, organized by: architecture → features → classes (grouped by component/folder) → infrastructure → meta.

## Step 8 — Verification

Have the agent cross-check architecture docs against source code:

- Validate route strings, port numbers, DI registrations.
- Confirm collection types, class hierarchies, method signatures.
- Verify import/usage counts for shared services.
- Check that all cross-reference links resolve.

Fix inaccuracies immediately. This step consistently catches 3-5 errors per project.

---

## Principles

| Principle | Why |
|-----------|-----|
| **Bottom-up, never top-down** | Architecture docs written without reading every file are fiction. |
| **One folder per pass** | Prevents hallucination, enables course-correction. |
| **Cards + summaries, not cards for everything** | Keeps docs useful. A 5-line data class doesn't need a full page. |
| **Read source, don't infer from names** | File names lie. `MigrationController` might do auth. Always read. |
| **Verify at the end** | AI agents make confident-sounding mistakes. A dedicated verification pass catches them. |
| **Track progress explicitly** | A plan/progress file is essential. You will lose your place otherwise. |
| **Commit after each step** | You will want to diff and rollback. |

## Estimated Effort

| Codebase size | Approx. passes | Wall time |
|--------------|----------------|-----------|
| Small (< 50 files) | 10-15 | 1-2 hours |
| Medium (50-200 files) | 25-40 | 3-6 hours |
| Large (200-500 files) | 40-80 | 1-2 days |

The per-file documentation step (Step 2) takes ~60% of total effort. Everything after that synthesizes what's already written.

---

## Output Checklist

```
docs/
├── _index.md                    # Master table of contents
├── improvement_proposals.md     # Consolidated arch improvements
├── plan.md                      # Progress tracker
├── classes/
│   ├── {component}/
│   │   ├── ClassName.md         # Per-class cards
│   │   └── summary_*.md         # Grouped simple files
├── features/
│   ├── _overview.md             # Feature × stack matrix
│   └── {feature_name}.md        # Class diagram + sequence + prose
└── architecture/
    ├── overview.md              # System architecture
    ├── dependency_map.md        # Cross-feature dependencies
    └── infrastructure.md        # Deployment, schemas, secrets
```
