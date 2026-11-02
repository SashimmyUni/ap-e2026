"""Drive the step-by-step exam plan from the terminal.

    python "Exam Prep/study/study.py" next        # the one step you are on
    python "Exam Prep/study/study.py" run 1       # run stage 1's code, predict first
    python "Exam Prep/study/study.py" repl 1      # open GHCi in the right project
    python "Exam Prep/study/study.py" done 1.3    # tick a step off
    python "Exam Prep/study/study.py" status      # progress and days left

Only the standard library is needed. `run` and `repl` shell out to cabal, so the
projects have to build first: `build` does that for all of them in one go.
"""

import argparse
import re
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

HERE = Path(__file__).resolve().parent
PREP = HERE.parent
REPO = PREP.parent
PLAN = PREP / "STEP-BY-STEP.md"
STAGES = HERE / "stages"
EXAM = date(2026, 11, 9)

STEP = re.compile(r"^- \[([ xX])\] \*\*(\d+\.\d+)\*\*\s*(.*)$")
STAGE_HEAD = re.compile(r"^## (Stage (\d+)[^\n]*)$")
MARK_OUT = re.compile(r"<<<(\d+)>>>")


def mark(n):
    return "<<<%d>>>" % n


# The plan file is UTF-8 but a Windows console often is not, which turns every
# em dash into a question mark. Fall back to ASCII rather than to noise.
ASCII_FALLBACK = {
    "—": "--",
    "–": "-",
    "·": "-",
    "→": "->",
    "★": "*",
    "…": "...",
    "‘": "'",
    "’": "'",
    "“": '"',
    "”": '"',
    "≠": "/=",
    "×": "x",
    "✅": "[ok]",
    "\U0001f7e1": "[~]",
    "❌": "[X]",
}


def out(text=""):
    enc = sys.stdout.encoding or "ascii"
    try:
        text.encode(enc)
    except UnicodeEncodeError:
        for uni, plain in ASCII_FALLBACK.items():
            text = text.replace(uni, plain)
        text = text.encode(enc, "replace").decode(enc)
    sys.stdout.write(text + "\n")


# --- the plan file ----------------------------------------------------------


class Step:
    def __init__(self, sid, title, stage, line_no):
        self.sid = sid
        self.title = title
        self.stage = stage
        self.line_no = line_no
        self.done = False
        self.body = []

    def text(self):
        box = "x" if self.done else " "
        return "\n".join([f"- [{box}] **{self.sid}** {self.title}"] + self.body)


def read_plan():
    """Return (lines, steps, stage titles) parsed out of STEP-BY-STEP.md."""
    if not PLAN.exists():
        sys.exit(f"not found: {PLAN}\nThe plan file is the input to this script.")
    lines = PLAN.read_text(encoding="utf-8").splitlines()
    steps, titles, stage = [], {}, 0
    for i, line in enumerate(lines):
        head = STAGE_HEAD.match(line)
        if head:
            stage = int(head.group(2))
            titles[stage] = head.group(1)
            continue
        m = STEP.match(line)
        if m:
            step = Step(m.group(2), m.group(3), stage, i)
            step.done = m.group(1).lower() == "x"
            steps.append(step)
        elif steps and line.startswith("  ") and line.strip():
            steps[-1].body.append(line)
    return lines, steps, titles


def set_done(sid, done):
    lines, steps, _ = read_plan()
    for step in steps:
        if step.sid == sid:
            box = "x" if done else " "
            lines[step.line_no] = re.sub(
                r"^- \[[ xX]\]", f"- [{box}]", lines[step.line_no]
            )
            PLAN.write_text("\n".join(lines) + "\n", encoding="utf-8")
            out(f"{'[x]' if done else '[ ]'} {sid} {step.title}")
            return
    sys.exit(f"no step {sid} in {PLAN.name}. Try: status")


def cmd_next(args):
    _, steps, titles = read_plan()
    todo = [s for s in steps if not s.done]
    if not todo:
        out("Every step is ticked off. Good luck on Monday.")
        return
    step = todo[0]
    out(f"\n{titles.get(step.stage, 'Stage ?')}\n")
    out(step.text())
    out(f"\n({len(todo) - 1} steps after this one. Tick it off with: done {step.sid})\n")


def cmd_show(args):
    _, steps, titles = read_plan()
    out(f"\n{titles.get(args.stage, 'Stage ?')}\n")
    for step in steps:
        if step.stage == args.stage:
            out(step.text() + "\n")


def cmd_status(args):
    _, steps, titles = read_plan()
    days = (EXAM - date.today()).days
    done = sum(s.done for s in steps)
    out(f"\nExam: Mon 9 Nov 2026 - {days} day(s) away")
    out(f"Steps: {done}/{len(steps)} done\n")
    for stage in sorted(titles):
        group = [s for s in steps if s.stage == stage]
        if not group:
            continue
        d = sum(s.done for s in group)
        bar = "#" * d + "." * (len(group) - d)
        out(f"  {bar:<16} {d}/{len(group)}  {titles[stage]}")
    todo = [s for s in steps if not s.done]
    if todo:
        out(f"\nNext: {todo[0].sid} {todo[0].title}\n")


# --- the GHCi stage files ---------------------------------------------------


class Part:
    def __init__(self, title):
        self.title = title
        self.dir = None
        self.load = []
        self.items = []  # (expression, note) pairs


def read_stage(stage):
    path = STAGES / f"stage{stage}.ghci"
    if not path.exists():
        have = ", ".join(sorted(p.stem[5:] for p in STAGES.glob("stage*.ghci")))
        sys.exit(f"no code set for stage {stage} (stages with code: {have})")
    parts, note = [], None
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.startswith("# part:"):
            parts.append(Part(line[7:].strip()))
        elif line.startswith("# dir:"):
            parts[-1].dir = REPO / line[6:].strip()
        elif line.startswith("# load:"):
            parts[-1].load.append(line[7:].strip())
        elif line.startswith("?"):
            note = line[1:].strip()
        else:
            parts[-1].items.append((line, note))
            note = None
    return parts


def indent(text):
    return "\n".join("        " + line for line in text.splitlines())


def run_part(part, quiz):
    out(f"\n=== {part.title}")
    out(f"    {part.dir.relative_to(REPO).as_posix()}\n")
    for n, (expr, note) in enumerate(part.items, 1):
        if note:
            out(f"  {note}")
        out(f"  [{n}] {expr}\n")
    if quiz:
        try:
            input("  Write down what you expect, then press Enter for the answers... ")
        except (EOFError, KeyboardInterrupt):
            out()
            return

    stdin = list(part.load)
    for n, (expr, _) in enumerate(part.items, 1):
        stdin.append('putStrLn "%s"' % mark(n))
        stdin.append(expr)
    proc = subprocess.run(
        ["cabal", "repl", "-v0"],
        cwd=part.dir,
        input="\n".join(stdin) + "\n",
        capture_output=True,
        text=True,
    )
    show_results(part, proc.stdout + proc.stderr)


def show_results(part, repl_output):
    chunks = MARK_OUT.split(repl_output)
    preamble = chunks[0].strip()
    if preamble:
        out("\n  before the first expression:\n" + indent(preamble))
    results = {}
    for i in range(1, len(chunks) - 1, 2):
        results[int(chunks[i])] = chunks[i + 1].strip()
    out()
    for n, (expr, _) in enumerate(part.items, 1):
        body = results.get(n)
        if body is None:
            body = "(nothing - did the REPL fail to start? try: build)"
        out(f"  [{n}] {expr}")
        out(indent(body or "(no output)") + "\n")


def cmd_run(args):
    for part in read_stage(args.stage):
        run_part(part, quiz=not args.go)


def cmd_repl(args):
    parts = read_stage(args.stage)
    part = parts[min(args.part, len(parts)) - 1]
    out(f"\n{part.title}\n  {part.dir.relative_to(REPO).as_posix()}")
    out("\nPaste this first (it is on your clipboard too):\n")
    for line in part.load:
        out(f"  {line}")
    out("\nQuit GHCi with :q\n")
    to_clipboard("\n".join(part.load))
    sys.stdout.flush()  # or cabal's own output arrives before the lines above
    subprocess.call(["cabal", "repl"], cwd=part.dir)


def to_clipboard(text):
    clip = shutil.which("clip") or shutil.which("pbcopy")
    if not clip:
        return
    try:
        subprocess.run([clip], input=text, text=True, check=False)
    except OSError:
        pass


def stage_dirs():
    dirs = []
    for path in sorted(STAGES.glob("stage*.ghci")):
        for part in read_stage(path.stem[5:]):
            if part.dir not in dirs:
                dirs.append(part.dir)
    return dirs


def cmd_build(args):
    failed = []
    for d in stage_dirs():
        out(f"=== cabal build {d.relative_to(REPO).as_posix()}")
        if subprocess.call(["cabal", "build"], cwd=d) != 0:
            failed.append(d)
    if failed:
        sys.exit("\nFailed: " + ", ".join(d.name for d in failed))
    out("\nEverything builds.")


def cmd_doctor(args):
    ok = True
    for tool in ("ghc", "cabal", "python"):
        found = shutil.which(tool)
        out(f"  {'ok' if found else 'MISSING':<9} {tool}  {found or ''}")
        ok = ok and bool(found)
    for d in stage_dirs():
        cabal = any(d.glob("*.cabal"))
        built = (d / "dist-newstyle").is_dir()
        state = "ok" if cabal and built else ("not built" if cabal else "MISSING")
        out(f"  {state:<9} {d.relative_to(REPO).as_posix()}")
        ok = ok and cabal
    out(f"  {'ok' if PLAN.exists() else 'MISSING':<9} {PLAN.name}")
    if not ok:
        sys.exit("\nSomething above is missing.")
    out("\nAll good. Start with: next")


def main():
    p = argparse.ArgumentParser(prog="study", description=__doc__.splitlines()[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("next", help="show the step you are on").set_defaults(fn=cmd_next)
    sub.add_parser("status", help="progress and days left").set_defaults(fn=cmd_status)
    sub.add_parser("build", help="cabal build every project used").set_defaults(fn=cmd_build)
    sub.add_parser("doctor", help="check the toolchain and projects").set_defaults(fn=cmd_doctor)

    show = sub.add_parser("show", help="show a whole stage")
    show.add_argument("stage", type=int)
    show.set_defaults(fn=cmd_show)

    run = sub.add_parser("run", help="run a stage's code, predicting first")
    run.add_argument("stage")
    run.add_argument("--go", action="store_true", help="skip the pause to predict")
    run.set_defaults(fn=cmd_run)

    repl = sub.add_parser("repl", help="open GHCi in the stage's project")
    repl.add_argument("stage")
    repl.add_argument("--part", type=int, default=1)
    repl.set_defaults(fn=cmd_repl)

    for name, flag in (("done", True), ("undo", False)):
        c = sub.add_parser(name, help=f"{'tick' if flag else 'untick'} a step, e.g. 1.3")
        c.add_argument("sid")
        c.set_defaults(fn=lambda a, flag=flag: set_done(a.sid, flag))

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
