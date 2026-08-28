# TOKEN OPTIMIZATION PROTOCOL

1. CONTEXT RETRIEVAL:
   - Read `graphify-out/GRAPH_REPORT.md` for architectural mapping and entry points.
   - For specific lookups, use AST queries (`graphify query "<topic>" --terse`, `graphify explain "<entity>"`).
   - Never perform recursive repository dumps (`grep -r`, `find .`) or read files >100 lines completely.
   - Inspect files strictly via bounded line ranges (`sed -n '<start>,<end>p' <file>`).

2. SURGICAL CODE EDITS:
   - Output code updates strictly as SEARCH/REPLACE blocks with 3–5 lines of unique surrounding context.
   - Never emit full-file replacements for localized modifications.

3. EXECUTION & LOG HYGIENE:
   - Pipe noisy test/build/lint commands through log filters (e.g., `tail -n 20`, `grep -E -i "error|fail|warn"`).
   - Batch dependent commands using `&&`.

4. GIT OPERATIONS & SAFETY (STRICT):
   - NEVER execute `git commit` or `git push` autonomously.
   - Stage and commit changes ONLY when the user explicitly commands it.
   - Keep conversational output concise (1–2 sentence rationales max, zero pleasantries).
