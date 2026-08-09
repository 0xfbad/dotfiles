---
name: cleanup
description: Launches a code review and cleanup of slop (deduplication, dead code, etc) using multiple subagents, use after a large revisions or feature drop/add.
---

Improve code quality in an existing codebase through a careful, low-risk cleanup pass.

Work in 8 focused tracks, but coordinate findings before making broad changes. For each track:

1. Inspect the relevant code and tooling
2. Write a brief critical assessment of issues found
3. Propose recommended changes, ranked by confidence and risk
4. Implement only high-confidence, low-regret changes
5. After changes, run all relevant checks and report results

Tracks:

1. Deduplicate and consolidate code where it reduces complexity without obscuring intent
2. Consolidate shared type definitions where duplication causes drift or inconsistency
3. Identify unused code with tools such as knip, then verify manually before removing anything
4. Detect and untangle circular dependencies with tools such as madge, prioritizing cycles that affect maintainability or correctness
5. Strengthen typing where appropriate by replacing unsafe any usage and narrowing overly broad types, while preserving legitimate boundary types such as unknown where they are correct
6. Review error handling and remove only unnecessary or misleading defensive patterns. Keep try/catch where it serves a real boundary, recovery, logging, cleanup, or user-facing error-handling purpose
7. Identify deprecated, dead, fallback, or legacy paths and remove only those that are clearly obsolete and not required for compatibility, migration, configuration, or active users
8. Remove low-value AI-generated artifacts such as stubs, placeholder logic (unless its a intentional coming soon feature, ask the users about these before removing), redundant comments, misleading TODO-style narration, and comments that describe edit history instead of intent. Keep or improve comments that help a new engineer understand why the code exists

Rules:

- Do not do speculative rewrites
- Do not change public behavior unless the change is clearly intended and justified
- Prefer small, reviewable commits or patches grouped by concern
- Before removing anything, verify that it is not used dynamically, via configuration, reflection, registration, hooks, code generation, or framework conventions
- Preserve compatibility unless you can prove it is safe to remove
- Flag medium- and high-risk findings separately instead of auto-implementing them
- For each implemented change, explain why it is safe
- For any questions for the user, use questions tooling, give options, examples, why you would pick one over the other, etc
- Do not commit unless the user has given prior authorization, let the user review functionality and changes

Validation after each track:

- Run tests
- Run type checks
- Run linting
- Run build
- Report failures, risks, and anything requiring manual review

Final output:

- tokei rundown of the repo before/after the cleanup
- Summary of issues found
- Changes implemented
- Changes intentionally not implemented
- Risks or follow-up items
- Any assumptions that need human verification
