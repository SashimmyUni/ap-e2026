# Step by step to the AP exam

One step at a time, in order. Every step says what to read, what to watch where there is
a video, what to do, and how you know you are done. Nothing here assumes you remember a
lecture.

**Run the plan from the terminal** (from the repo root):

```bash
python "Exam Prep/study/study.py" next
```

| Command | What it does |
|---|---|
| `next` | prints the one step you are on |
| `run 1` | shows stage 1's expressions, waits while you predict, then runs them |
| `repl 1` | opens GHCi in the right project with the import line on your clipboard |
| `done 1.3` | ticks step 1.3 off in this file |
| `status` | progress per stage and days left |
| `show 4` | the whole of stage 4 |
| `build` | `cabal build` in all eight projects (do this once, in stage 0) |
| `doctor` | checks GHC, cabal and every project |

All of them take the same prefix: `python "Exam Prep/study/study.py" <command>`.

## The shape of it

Nine stages. Seven days, Mon 2 Nov to Sun 8 Nov, because the exam is **Mon 9 November
2026**. This is one day tighter per topic than [STUDY-PLAN.md](STUDY-PLAN.md) assumed, so
stages 5+6 and 7+8 share a day.

| Day | Date | Stages | Hours |
|---|---|---|---|
| 1 | Mon 2 Nov | 0 Setup · 1 Haskell + A1 | 6 |
| 2 | Tue 3 Nov | 2 Monads + A2 | 5 |
| 3 | Wed 4 Nov | 3 Parsing + A3 | 5 |
| 4 | Thu 5 Nov | 4 Free monads + A4 | 6 |
| 5 | Fri 6 Nov | 5 Testing + A5 · 6 Concurrency + A6 | 6 |
| 6 | Sat 7 Nov | 7 Week 7 · 8 Mock exam | 6 |
| 7 | Sun 8 Nov | 9 Final day | 2.5 |

If you are starting later than Mon 2 Nov, keep the stage order and drop work inside each
stage in this order: the **Extra** steps first, then the videos, then the ★ drill
questions. **Never drop a whole stage.** The lecturer's own advice (`week7/7b.pdf`, slide
40) is that breadth across the learning goals beats depth in one of them, and the exam
marks you down for wrong content, not for a thin answer.

**Two rules that matter more than the schedule:**

1. **Hard stop.** When a stage's hours are gone, move to the next stage even if this one
   is half clear. A rough grasp of all seven topics beats a solid grasp of four.
2. **Predict before you run.** Every `run` command pauses so you can write down what you
   expect. A wrong guess is the most useful thing that can happen in a day's study —
   stop and find out why before you move on.

Stuck for 15 minutes? Ask Claude ("explain line 40 of `a1/handin/src/APL/Eval.hs`") or
mark it and move on. AI is only banned *in* the exam.

## Where everything lives

| What | Where |
|---|---|
| Course notes, the main reading | `week7/ap-notes.pdf`, or [online](https://diku-dk.github.io/ap-notes) |
| Compendium: assignment texts, exercises, solutions, code | `week7/compendium.pdf` |
| The notes you bring to the exam | [EXAM-NOTES.md](EXAM-NOTES.md) → [EXAM-NOTES.pdf](EXAM-NOTES.pdf) |
| Drill questions | [QUESTION-BANK.md](QUESTION-BANK.md) |
| Your written answers | `Exam Prep/answers/dayN.md` |
| Haskell book | [Programming in Haskell](https://www.cs.nott.ac.uk/~pszgmh/pih.html), Hutton |
| Video: the book's early chapters | [Functional Programming in Haskell](https://www.youtube.com/playlist?list=PLF1Z-APd9zK7usPMx3LGMZEHrECUGodd3) |
| Video: monads, parsers, the later chapters | [Advanced Functional Programming in Haskell](https://www.youtube.com/playlist?list=PLF1Z-APd9zK5uFc8FKr_di9bfsYv8-lbc) |

Both playlists are Graham Hutton's, linked from the course [README.md](../README.md). They
are organised by book chapter — match the chapter number in the video title. Watch at
1.5× and don't pause to take notes; you are after recognition, not mastery.

---

## Stage 0 — Setup (Day 1, 40 min)

- [x] **0.1** Confirm on Absalon that you may sit the exam
  **Do** · You need at least 12 assignment points in total and at least 1 point in each
  of A1–A5. While you are there, note the **start time**, the **length**, and whether you
  may bring **digital files**.
  **Done when** · `Exam Prep/answers/logistics.md` is filled in. Nothing else in this
  plan matters if the first line of that file is not a yes.
- [x] **0.2** Build everything once
  **Do** · `python "Exam Prep/study/study.py" build`, then `doctor`.
  It compiles eight projects and takes a few minutes. Do it now so that no later step
  waits on a compile.
  **Done when** · `doctor` prints `All good.`
- [ ] **0.3** See the target
  **Material** · `week7/exam-dummy.pdf`
  **Do** · Read it. **Do not answer it** — you will use it as a timed test on Day 7.
  Notice the shape: 1–3 sentences per answer, almost no code writing, and questions of
  the form "what does this evaluate to, and why?"
  **Done when** · You can say in one sentence what kind of answer the exam wants.
- [ ] **0.4** Learn to navigate the notes
  **Material** · [EXAM-NOTES.md](EXAM-NOTES.md) §0
  **Do** · §0 is a page index into the compendium and the course notes. Pick five entries
  and actually open those pages in the PDFs.
  **Done when** · You can find any assignment's text and code in under 20 seconds. This
  is a graded skill: the exam is open book and short on time.

## Stage 1 — Haskell from scratch, and the A1 evaluator (Day 1, 5 h)

The course never teaches Haskell syntax, so this stage does. You are learning to **read**
Haskell and trace it by hand, not to write it.

- [ ] **1.1** Haskell syntax, part one: the basics
  **Video** · [Functional Programming in Haskell](https://www.youtube.com/playlist?list=PLF1Z-APd9zK7usPMx3LGMZEHrECUGodd3)
  — chapters **2** (first steps), **3** (types and classes), **4** (defining functions)
  **Material** · the same chapters of *Programming in Haskell* if you prefer reading
  **Do** · Skip the book's exercises. Watch for: function type signatures, guards,
  `where`, and how a function is defined by several equations.
  **Done when** · You can read `f :: Int -> Int -> Bool` aloud and say what it means.
- [ ] **1.2** Haskell syntax, part two: the parts the course actually uses
  **Video** · same playlist — chapters **6** (recursion), **7** (higher-order functions),
  **8** (declaring types and classes)
  **Do** · **Chapter 8 is the important one.** `data` declarations, constructors and
  pattern matching are what every single exam question is written in. If you only half
  understand one of these three, make it 6 or 7, not 8.
  **Done when** · You can write out a `data` type with three constructors, one of which
  holds two fields, and pattern match on it.
- [ ] **1.3** Read real Haskell for the first time
  **Material** · `week1/lec-tue/lecture.hs`
  **Do** · Read it top to bottom. Expect not to follow all of it. For each definition,
  say out loud what its type signature promises.
  **Done when** · You have stopped being surprised by the syntax.
- [ ] **1.4** Meet APL, the language the whole course builds
  **Material** · `week1/README.md`, from *Getting started* to *Adding Variables*, with
  `week1/solution/src/APL/Eval.hs` open beside it
  **Do** · Follow it as a reading exercise. APL is a tiny expression language; the course
  writes interpreters for it six times over, each time with a better technique.
  **Done when** · You can name the two types that matter — `Exp` (syntax) and `Val`
  (results) — and say why they are separate.
- [ ] **1.5** Read the evaluator with `Either`
  **Material** · `week1/README.md` and `a1/handin/src/APL/Eval.hs` (your group's code)
  **Do** · Trace `eval` by hand on `Add (CstInt 1) (CstInt 2)` on paper. Then on
  `Let "x" (CstInt 2) (Add (Var "x") (CstInt 1))`, writing down what `env` holds at each
  step.
  **Done when** · You can read `eval env (Var v) = case envLookup v env of …` aloud in
  plain words.
- [ ] **1.6** Run it, predicting first
  **Do** · `python "Exam Prep/study/study.py" run 1` — twelve expressions in two
  projects. Write your prediction for each one *before* pressing Enter.
  **Done when** · You have run it and understood every answer you got wrong. For
  exploring further: `repl 1`.
- [ ] **1.7** Read the notes for this topic
  **Material** · `week7/ap-notes.pdf` **read** p.1–2 and 7–12; **skim** p.3–6, 13–17
  **Done when** · Nothing in the read pages is new to you after steps 1.4–1.6.
- [ ] **1.8** Read what A1 asked for
  **Material** · `week7/compendium.pdf` p.13–20, especially the **★ report questions** on
  p.18–19
  **Do** · You are not solving it. The ★ questions are the single best predictor of exam
  questions, so read them as exam questions.
  **Done when** · You have read all of them once.
- [ ] **1.9** Read the exam notes, which should now make sense
  **Material** · [EXAM-NOTES.md](EXAM-NOTES.md) §A1, §G4, §G7, §G8
  **Done when** · You have marked anything that still does not make sense, and asked.
- [ ] **1.10** Drill (90 min)
  **Material** · [QUESTION-BANK.md](QUESTION-BANK.md) §1 and §0 Q4
  **Do** · Answer **§1 Q1, Q2, Q7–Q13** and **§0 Q4** in `Exam Prep/answers/day1.md`,
  3–5 minutes each, with the notes open. Then mark each ✅ / 🟡 / ❌ against §A1 and write
  one line on *why* for every ❌.
  **Done when** · Every Must question has an answer and a mark.
- [ ] **1.11** Say the stage out loud
  **Do** · Explain, without looking: `data` constructors and pattern matching;
  `Either`/`Left`/`Right`; why a closure carries its own environment; which error wins in
  `Add`; why a `ForLoop` always terminates.
  **Done when** · All five, out loud, no notes.

## Stage 2 — Monads, and A2 (Day 2, 5 h)

Everything after today builds on this. A monad here is just a way to hide the plumbing you
traced yesterday: threading `env` through every call and checking for `Left` after every
step.

- [ ] **2.1** Watch the monad lecture
  **Video** · [Advanced Functional Programming in Haskell](https://www.youtube.com/playlist?list=PLF1Z-APd9zK5uFc8FKr_di9bfsYv8-lbc)
  — the **Monads** videos (book chapter 12)
  **Do** · Ignore `Functor` and `Applicative` for now. You want `>>=` and `do`.
  **Done when** · You can say what `>>=` does in one sentence.
- [ ] **2.2** Read the notes
  **Material** · `week7/ap-notes.pdf` p.23–39
  **Extra** · If monads still feel abstract, the first section of
  `week2/essence-of-functional-programming.pdf` is the paper the course notes follow.
  **Done when** · You can explain what the `EvalM` type *is*, as a function type.
- [ ] **2.3** Compare the two evaluators side by side
  **Material** · `week2/solution/src/APL/Eval.hs` against `a1/handin/src/APL/Eval.hs`
  **Do** · Same language, much less code. Find the `Add` case in both and put them next to
  each other. Every `case … of Left e -> Left e` that disappeared is now inside `>>=`.
  **Done when** · You can point at the line that does the error checking now.
- [ ] **2.4** Run it, predicting first
  **Do** · `python "Exam Prep/study/study.py" run 2`
  **Done when** · You can explain why the *answers* are the same as stage 1's while the
  code is not.
- [ ] **2.5** Write `>>=` from memory
  **Do** · On paper, twice: for `newtype EvalM a = EvalM (Env -> Either Error a)`, and
  then for the state-carrying version in §A2. Then the fixed `catch` from dummy-exam
  question 2.2.3. This is the small amount of code the exam may ask you to write.
  **Done when** · You can do both without looking.
- [ ] **2.6** Read what A2 asked for
  **Material** · `week7/compendium.pdf` p.40–46, **★** on p.45–46; the code handout on
  p.47–55
  **Do** · Your group has no A2 code in this repo, so the handout and
  `week2/solution` are your reference.
  **Done when** · You have read the ★ questions once.
- [ ] **2.7** Notes, then drill (90 min)
  **Material** · [EXAM-NOTES.md](EXAM-NOTES.md) §A2, §G5, §G6, then
  [QUESTION-BANK.md](QUESTION-BANK.md)
  **Do** · Answer **§2 Q1, Q2, Q3, Q8–Q11** and **§0 Q5–Q6** in `answers/day2.md`, then
  mark them.
  **Done when** · You can explain why `(Either Error a, State)` keeps effects after a
  failure while `Either Error (a, State)` rolls them back. That single contrast is the
  most asked question in this topic.

## Stage 3 — Parsing, and A3 (Day 3, 5 h)

- [ ] **3.1** Watch the parser lecture
  **Video** · [Advanced Functional Programming in Haskell](https://www.youtube.com/playlist?list=PLF1Z-APd9zK5uFc8FKr_di9bfsYv8-lbc)
  — the **Functional parsers** videos (book chapter 13)
  **Done when** · You know what a parser combinator is: a parser is a function from input
  to a result plus the rest of the input.
- [ ] **3.2** Read the notes
  **Material** · `week7/ap-notes.pdf` **read** p.40–48 and 55–63; **skim** p.49–54
  (whitespace), p.64–67 (Megaparsec, which A3 uses), p.71–72 (comments — a ★ question)
  **Done when** · You can say why **left recursion** makes a recursive-descent parser loop
  forever.
- [ ] **3.3** Remove left recursion by hand
  **Do** · On paper, rewrite `E ::= E "+" E | E "*" E | int` so `*` binds tighter than `+`
  and both are left-associative. Then write the `chain` helper from §G3. Check against
  §A3's final grammar.
  **Done when** · Your grammar matches, and you can explain which level gives which
  precedence.
- [ ] **3.4** Read the real parser
  **Material** · `a3/handin/src/APL/Parser.hs`, beside the grammar in the assignment text
  **Do** · Use `a3/handin`, not `week3`, because the week 3 parser has no function
  application. Find: where whitespace is consumed, where `try` appears, where `eof` is.
  **Done when** · You can name the three grammar levels and what sits at each.
- [ ] **3.5** Run it, predicting first
  **Do** · `python "Exam Prep/study/study.py" run 3` — nine inputs, including `getx`
  versus `get x` and `2 ** 3 ** 2`.
  **Done when** · You predicted the `getx` and `**` cases correctly, or know why not.
- [ ] **3.6** Read what A3 asked for
  **Material** · `week7/compendium.pdf` p.74–80, **★** on p.79–80
  **Done when** · Read once.
- [ ] **3.7** Notes, then drill (90 min)
  **Material** · [EXAM-NOTES.md](EXAM-NOTES.md) §A3 and §G3, then
  [QUESTION-BANK.md](QUESTION-BANK.md)
  **Do** · Answer **§3 Q1, Q9–Q13** and **§0 Q3** in `answers/day3.md`, then mark them.
  **Done when** · You can explain what `try` does (rewinds after consuming input), why the
  order inside `choice` matters, and how keywords are kept apart from variable names.

## Stage 4 — Free monads, and A4 (Day 4, 6 h)

The hardest topic, and the longest day. It only has to click far enough to answer "what
would *this* interpreter do with this program?". Do not chase the type-level details.

- [ ] **4.1** Read the notes, first half
  **Material** · `week7/ap-notes.pdf` p.79–94; **skim** p.73–78
  **Do** · The idea in one line: instead of *doing* an effect, `eval` returns a **data
  structure describing** the effects, and a separate interpreter executes it.
  **Done when** · You can say why that is useful, in terms of testing.
- [ ] **4.2** Write `Free` from memory
  **Do** · On paper: `data Free e a`, its `Functor` instance, and `>>=`. Then answer: why
  must `e` be a `Functor`? Check against §A4.
  **Done when** · You can write all three and answer the question.
- [ ] **4.3** Read the effect type
  **Material** · `a4/handin/src/APL/Monad.hs`
  **Do** · Work out for each constructor why it carries what it carries: `KvGetOp` has
  `(Val -> a)`, `KvPutOp` has a plain `a`, `ErrorOp` has no `a` at all.
  **Done when** · You can explain all three, and why `TryCatchOp a a` would be wrong.
- [ ] **4.4** Read two interpreters for the same program
  **Material** · `a4/handin/src/APL/InterpPure.hs`, then `InterpIO.hs`
  **Do** · Read the same effect's case in both. The pure one threads a list; the IO one
  touches a real file.
  **Done when** · You can say what differs if the program **crashes halfway**.
- [ ] **4.5** Read the notes, second half
  **Material** · `week7/ap-notes.pdf` p.109–116; **skim** p.95–96
  **Done when** · You can explain `Transaction` and why `Break` is *dynamically* scoped.
- [ ] **4.6** Run it, predicting first
  **Do** · `python "Exam Prep/study/study.py" run 4` — prints, the key-value store,
  transactions, and `Break` out of a lambda.
  **Caution** · Your group's `Break` is partly wrong (`a4/REPORT.md`, task 4). For `Break`
  trust §A4, not what the REPL prints — and be ready to explain the bug in two sentences.
  **Done when** · You predicted the transaction rollback correctly.
- [ ] **4.7** Read what A4 asked for
  **Material** · `week7/compendium.pdf` p.109–120, **★** on p.119
  **Done when** · Read once.
- [ ] **4.8** Notes, then drill (90 min)
  **Material** · [EXAM-NOTES.md](EXAM-NOTES.md) §A4 and §G1, then
  [QUESTION-BANK.md](QUESTION-BANK.md)
  **Do** · Answer **§4 Q6, Q8, Q9, Q10, Q11** and **§0 Q1 and Q7** in `answers/day4.md`,
  then mark them.
  **Done when** · You can explain: one program with many interpreters; the pure store
  versus the database file; and why a transaction rolls back on error but keeps its prints.

## Stage 5 — Property-based testing, and A5 (Day 5, 3 h)

A lighter stage, and the code is the easiest to read in the course. Two stages share
today, so keep to three hours.

- [ ] **5.1** Read the notes
  **Material** · `week7/ap-notes.pdf` **read** p.128–141 and 148–153; **skim** p.124–127,
  p.142–147, p.154–156 (shrinking), p.157–176 (stateful testing — A5 does not use it, but
  it is a learning goal)
  **Done when** · You can define `sized`, `cover`, `classify` and shrinking in a sentence
  each.
- [ ] **5.2** Run it, predicting first
  **Do** · `python "Exam Prep/study/study.py" run 5`. Pay attention to how many of the
  generated expressions are useless. That is *why* `cover` exists.
  **Done when** · You have seen a shrunk counterexample and understood it.
- [ ] **5.3** Read the generator and the properties
  **Material** · `a5/handin/src/APL/Tests.hs`
  **Do** · Find: where the size is halved, where the variable-name pool is, and the
  round-trip property `parse (printExp e) == Right e`.
  **Done when** · You can say why that one property catches printer bugs *and* parser bugs.
- [ ] **5.4** Read what A5 asked for, then drill (75 min)
  **Material** · `week7/compendium.pdf` p.148–152, **★** on p.151;
  [EXAM-NOTES.md](EXAM-NOTES.md) §A5 and §G2; then
  [QUESTION-BANK.md](QUESTION-BANK.md)
  **Do** · Answer **§5 Q6–Q11** and **§0 Q2** in `answers/day5.md`, then mark them.
  **Done when** · You can say, for a given counterexample, whether you would fix the
  implementation, the generator or the property — and why there.

## Stage 6 — Concurrency, and A6 (Day 5, 3 h)

- [ ] **6.1** Read the notes
  **Material** · `week7/ap-notes.pdf` p.177–201; **skim** p.97–102 (exceptions)
  **Done when** · You can describe a server loop: state, message type, `receive`, recurse.
- [ ] **6.2** Read SPC
  **Material** · `week6/solution/src/SPC.hs`, then `GenServer.hs`
  **Do** · Your group has no A6 hand-in, so this is the reference. The week 6 version has
  **no workers yet** — A6 adds them. Find where *all* the mutable state lives, and why
  there.
  **Done when** · You can tell the synchronous functions from the asynchronous ones and
  say how each is implemented with a `Chan` and a reply channel.
- [ ] **6.3** Run it, predicting first
  **Do** · `python "Exam Prep/study/study.py" run 6` — you will see all four outcomes a
  job can have: `Done`, `DoneCrashed`, `DoneTimeout` and `DoneCancelled`.
  **Done when** · You can explain why the crash did not take the server down.
- [ ] **6.4** Draw the message flows on paper
  **Do** · Three diagrams: `jobAdd` → the job runs → the `jobWait` reply; a timeout
  (ticker → `checkTimeouts` → `killThread`); `jobCancel`.
  **Done when** · You can draw all three from memory. Exam answers about SPC are mostly
  "which message goes where, in what order".
- [ ] **6.5** Read what A6 asked for, then drill (75 min)
  **Material** · `week7/compendium.pdf` p.189–194, **★** on p.193–194;
  [EXAM-NOTES.md](EXAM-NOTES.md) §A6, §G9, §G10; then
  [QUESTION-BANK.md](QUESTION-BANK.md)
  **Do** · Answer **§6 Q7–Q12** in `answers/day6.md`, then mark them.
  **Done when** · You can explain why a job's exception must be caught in the job's own
  thread, and why catching `SomeException` is dangerous next to `killThread`.

## Stage 7 — Week 7, everything at once (Day 6, 3 h)

No new concepts. Week 7 uses free monads, parsing and SPC together, so it doubles as
revision — and the course says exam questions may reference it.

- [ ] **7.1** Read the notes
  **Material** · `week7/ap-notes.pdf` p.202–214; **skim** p.103 (`IORef`), p.117–123
  **Done when** · You can list the three interpreters and what makes each one different.
- [ ] **7.2** Read the three interpreters side by side
  **Material** · `week7/compendium.pdf` p.215–216 and p.226 (KVDB), or
  `week7/solution/src/APL/InterpPure.hs`, `InterpSim.hs`, `InterpConcurrent.hs`
  **Do** · Read the `OneOf` case in all three.
  **Done when** · You can explain why `step` must stop *at* the next `StepOp` rather than
  running to completion.
- [ ] **7.3** Run it, predicting first
  **Do** · `python "Exam Prep/study/study.py" run 7` — the same programs under the pure and
  simulated interpreters.
  **Done when** · You predicted which side wins a tie, and what happens to the loser's
  effects.
- [ ] **7.4** Drill the interpreter table until it is automatic
  **Material** · [EXAM-NOTES.md](EXAM-NOTES.md) §W7 and §G9
  **Do** · Cover the "Pure / Sim / Concurrent" columns, predict each row, uncover. Repeat
  until you get every row right. Then answer **§7 Q2, Q5, Q6, Q8, Q14** in
  `answers/day7.md`.
  **Done when** · Every row right, from memory.

## Stage 8 — Mock exam under exam conditions (Day 6, 3 h)

- [ ] **8.1** Print the notes
  **Do** · Rebuild them first if you have edited the notes:
  `python "Exam Prep/print/build.py"` from the repo root. Then print
  [EXAM-NOTES.pdf](EXAM-NOTES.pdf).
  **Done when** · You are holding 19 pages of paper. You cannot do the mock properly
  without them, and this rehearses Day 7's final print.
- [ ] **8.2** Sit the mock, 2 hours, no interruptions
  **Material** · [MOCK-EXAM.md](MOCK-EXAM.md)
  **Do** · Printed notes, `week7/ap-notes.pdf` and the compendium only. **No IDE, no
  GHCi, no Claude.** Answer in `week7/answer-sheet.docx` or `answers/day8-mock.md`.
  **Done when** · Two hours are up, with something written for every question.
- [ ] **8.3** Mark it honestly
  **Material** · [MOCK-EXAM-SOLUTIONS.md](MOCK-EXAM-SOLUTIONS.md)
  **Do** · For every miss write *why*: misread the code, didn't know the concept, or
  couldn't find the page.
  **Done when** · Every question has a mark and every miss has a reason.
- [ ] **8.4** Fix the notes where they failed you
  **Do** · "Couldn't find the page" → improve §0's index or the headings. "Didn't know the
  concept" → add a line in your own words to that section. Then re-drill your two weakest
  sections from the question bank.
  **Done when** · Every miss has changed something in [EXAM-NOTES.md](EXAM-NOTES.md).

## Stage 9 — The last day (Day 7, 2.5 h, then stop)

- [ ] **9.1** Speed test on the dummy exam
  **Material** · `week7/exam-dummy.pdf`, marked with `week7/exam-dummy-solutions.pdf`
  **Do** · With the notes, in under **45 minutes**, in `answers/day9-dummy.md`. You have
  met these questions in the drills, so this is about *finding answers fast*, not about
  knowing them.
  **Done when** · Done inside 45 minutes and marked.
- [ ] **9.2** Re-read only your mistakes
  **Do** · Every ❌ and 🟡 line in `Exam Prep/answers/`. Nothing else.
  **Done when** · You have read them all once. Do not start new material today.
- [ ] **9.3** Final print, and tab it
  **Do** · Rebuild and print [EXAM-NOTES.pdf](EXAM-NOTES.pdf). Tab or colour the section
  edges — G, A1–A6, W7 — so you can flip straight to one.
  **Done when** · The printout is tabbed and in your bag.
- [ ] **9.4** Logistics
  **Material** · `Exam Prep/answers/logistics.md`, which you filled in at step 0.1
  **Do** · Re-read it: start time, room at Eksamenshuset, ID card, and how the Word file
  is handed in. Pack the printout tonight.
  **Done when** · Bag packed, alarm set.
- [ ] **9.5** Stop
  **Do** · No studying this evening. Sleep.
  **Done when** · You are asleep.

---

## In the exam room

1. Skim every question first, 5 minutes. Answer the ones you recognise from the notes
   first.
2. For each question: find the section → find the model answer or variant → adapt it →
   write **the value plus one reason**, in 1–3 sentences.
3. **Do not pad.** You are also judged on what you write that is wrong (`week7/7b.pdf`,
   slide 40). If a question is unclear, state your assumption and answer under it.
4. Stuck more than 5 minutes? Write down the concept you think applies and move on. Come
   back at the end.
5. Last 10 minutes: make sure **every question has some answer**. Breadth counts.
