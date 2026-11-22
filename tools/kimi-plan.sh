#!/usr/bin/env bash
# Run one planning pass on Kimi K3.1-Pro, as its own job.
#
# Per-job model pin: this never touches ~/.hermes/config.yaml, never moves my
# subagents off deepseek-v4.1-flash, and leaves nothing running. Each call is
# its own process, its own session, and appends one line to docs/plan-log.md.
#
#   tools/kimi-plan.sh docs/plan-x.md "TASK TEXT" docs/a.md docs/b.md
#
# Model id and rates are the ones Skyy verified on CommandCode (2026-11-22).
set -euo pipefail

MODEL="moonshotai/Kimi-K3.1-Pro"
PROVIDER="commandcode"
RATE_IN="2"    # $ per 1M input tokens
RATE_OUT="10"  # $ per 1M output tokens

if [ $# -lt 2 ]; then
  echo "usage: $0 <out.md> \"<task>\" [doc ...]" >&2
  exit 2
fi

OUT="$1"; TASK="$2"; shift 2
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Assemble the prompt: task first, then each document verbatim.
python3 - "$TASK" "$TMP/prompt.txt" "$@" <<'PY'
import sys, pathlib
task, dest, docs = sys.argv[1], sys.argv[2], sys.argv[3:]
parts = [task.strip(), ""]
for d in docs:
    p = pathlib.Path(d)
    parts += [f"\n=== {p.name} ===", p.read_text(encoding="utf-8")]
pathlib.Path(dest).write_text("\n".join(parts), encoding="utf-8")
PY

echo "kimi-plan: model=$MODEL docs=$# input_chars=$(wc -c <"$TMP/prompt.txt")" >&2

hermes -z "$(cat "$TMP/prompt.txt")" \
  -m "$MODEL" --provider "$PROVIDER" \
  --usage-file "$TMP/usage.json" > "$TMP/answer.md" 2>"$TMP/err.txt" || {
    echo "kimi-plan: hermes exited non-zero" >&2; tail -5 "$TMP/err.txt" >&2; exit 1; }

python3 - "$TMP/usage.json" "$TMP/answer.md" "$OUT" "$MODEL" "$RATE_IN" "$RATE_OUT" "$TASK" <<'PY'
import json, sys, pathlib, datetime, os
usage_p, answer_p, out_p, model, rin, rout, task = sys.argv[1:8]
u = json.load(open(usage_p))
tin, tout = u.get("input_tokens", 0), u.get("output_tokens", 0)
cost = tin * float(rin) / 1e6 + tout * float(rout) / 1e6
stamp = datetime.datetime.now().astimezone().strftime("%a %Y-%m-%d %H:%M %Z")
body = pathlib.Path(answer_p).read_text(encoding="utf-8").strip()
head = (f"# Kimi planning pass\n\nprovenance: `{model}` over commandcode, one-shot, {stamp}\n"
        f"task: {task.strip().splitlines()[0][:160]}\n"
        f"usage: in {tin:,} tok / out {tout:,} tok = **${cost:.3f}**\n\n---\n\n")
out = pathlib.Path(out_p); out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(head + body + "\n", encoding="utf-8")
log = out.parent / "plan-log.md"
new = not log.exists()
with log.open("a", encoding="utf-8") as f:
    if new:
        f.write("# Planning passes (per-job Kimi)\n\n| when | output | in | out | cost |\n|---|---|---|---|---|\n")
    f.write(f"| {stamp} | `{out.name}` | {tin:,} | {tout:,} | ${cost:.3f} |\n")
print(f"kimi-plan: wrote {out_p}  in={tin:,} out={tout:,}  cost=${cost:.3f}")
PY
