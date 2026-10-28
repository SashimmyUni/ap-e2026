# Study plan: 27 Oct → exam on Mon 9 Nov 2026

13 study days. The course follows a single thread (one APL interpreter that grows each week), so the plan follows the same order: **evaluator → monads → parser → free monads → testing → concurrency → week 7**. After that come the mock exams.

The exam asks you to *reason about code you have seen*, not to write new code. Every day is therefore built around reading code and predicting what it does, then checking your prediction.

## The daily routine (≈4–5 h)

1. **Read** (45 min): the course-notes chapter for the day (`week7/ap-notes.pdf`, or https://diku-dk.github.io/ap-notes), then the week's README.
2. **Re-open your own code** (60 min): your group's `aN/handin` and the week's `weekN/solution`. For each file, say in one sentence what it does and why it is designed that way. Diff your solution against the official one where one exists, and note any differences.
3. **Answer the assignment's report questions from memory** (45 min) in `answers/dayN-*.md`. Only then compare with your submitted report and the TA feedback on Absalon.
4. **Question bank** (60 min): that day's section of `QUESTION-BANK.md`. Write short, precise answers, like on the exam. For every "what does X evaluate to" question, **predict first, then check in GHCi**:
   ```
   cd aN/handin && cabal repl
   ghci> import APL.AST
   ghci> eval envEmpty (Add (CstInt 1) (CstInt 2))
   ```
5. **Cheat sheet** (20 min): add the 5–10 facts you would otherwise have to search for to `CHEAT-SHEET.md`.

Tip: ask Claude to quiz you on a day's section, or to check your `answers/` file. That is fine while you prepare; AI is banned only *in* the exam.

---

## Week 1 of revision: the sequential interpreter

### Day 1 · Tue 27 Oct: Haskell basics + A1 (interpreting APL)
- [ ] Notes ch. 1 · `week1/README.md` · compendium pp. 1–27
- [ ] Re-read `a1/handin/src/APL/Eval.hs`, `AST.hs` (printExp), and `a1/NOTES.md`
- [ ] A1 report questions 1–8 from memory → `answers/day1-a1.md`
- [ ] Question bank §1 (W1/A1)
- Key ideas: environments and **static (lexical) scope**, closures (`ValFun env v body`), **evaluation order** and which error comes first, `ForLoop` semantics (the bound is evaluated in the *outer* scope), eager `Let`, `TryCatch`, printer parenthesisation and its complexity.

### Day 2 · Wed 28 Oct: Monads + A2
- [ ] Notes ch. 2 · `week2/README.md` · Wadler's *Essence of FP* (skim §1–2) · compendium pp. 28–55
- [ ] Re-read `a2/handin/src/APL/Eval.hs` (`EvalM`, `catch`, Print, KvPut/KvGet) and `Check.hs`
- [ ] A2 report questions 1–4 → `answers/day2-a2.md`
- [ ] Question bank §2
- Key ideas: writing `>>=` for a Reader+State+Error monad, **`(Either Error a, State)` vs `Either Error (a, State)`** (do effects survive an error?), Functor/Applicative from Monad, monad laws, `mapM`/`sequence` order, the O(n²) cost of `++ [x]`.

### Day 3 · Thu 29 Oct: Parsing + A3
- [ ] Notes ch. 3 · `week3/parsernotes.pdf` · compendium pp. 56–88
- [ ] Re-read `a3/handin/src/APL/Parser.hs` line by line. For each `try`, say why it is there.
- [ ] A3 report questions 1–5 → `answers/day3-a3.md`
- [ ] Question bank §3
- Key ideas: **removing left recursion** (`E ::= T E'`) while keeping left associativity via an accumulator (`chain`/`pExp'`), precedence levels as a grammar hierarchy, lexeme style (whitespace after each token), `lKeyword` + `notFollowedBy`, keyword rejection in `lVName`, **`try` = backtrack after consuming input**, ordered `choice` (`**` before `*`), application as `Atom+` folded left.

### Day 4 · Fri 30 Oct: Free monads + A4
- [ ] Notes ch. 4 · `week4/README.md` · compendium pp. 89–133
- [ ] Re-read `a4/handin/src/APL/Monad.hs`, `InterpPure.hs`, `InterpIO.hs` and `a4/REPORT.md` (incl. the `break` bug you found)
- [ ] A4 report questions 1–3 → `answers/day4-a4.md`
- [ ] Question bank §4
- Key ideas: `Free e a = Pure a | Free (e (Free e a))`, why `e` must be a `Functor`, `>>=` pushes the continuation into the leaves, effects with continuations (`KvGetOp Val (Val -> a)`), **one program, many interpreters** (pure vs IO), `TryCatchOp m1 m2 k` vs `TryCatchOp a a`, `TransactionOp (EvalM ()) a`, `looping`/`breakLoop` = **dynamic** scope.

### Day 5 · Sat 31 Oct: Property-based testing + A5
- [ ] Notes ch. 5 · `week5/QuickCheckTestingforFunandProfit.pdf` · compendium pp. 134–165
- [ ] Re-read `a5/handin/src/APL/Tests.hs` (genExp, shrink, expCoverage, parsePrinted, onlyCheckedErrors) and `a5/REPORT.md`
- [ ] A5 report questions 1–5 → `answers/day5-a5.md`
- [ ] Question bank §5
- Key ideas: `Gen`, `sized`/`resize`, halving size for recursion, `oneof` vs `frequency`, generating variables from a small pool so that `Var` hits bound names, `shrink`, `cover`/`checkCoverage`/`classify`, round-trip `parse . print`, why a passing property can be meaningless, non-terminating generated programs.

### Day 6 · Sun 1 Nov: Checkpoint (lighter day)
- [ ] **Timed half-mock:** dummy exam (`week7/exam-dummy.pdf`, *not* the solutions) sections 1 and 2.1–2.5, in `week7/answer-sheet.docx`. Allow 60 minutes.
- [ ] Mark it against `exam-dummy-solutions.pdf`. For every miss, write *why* in `answers/day6-checkpoint.md`
- [ ] Redo the weakest day's question-bank section
- [ ] Update milestones / rest

## Week 2 of revision: concurrency, week 7, mocks

### Day 7 · Mon 2 Nov: Concurrency + SPC (week 6)
- [ ] Notes ch. 6 · `week6/README.md` · *Concurrent Haskell* paper (skim) · compendium pp. 166–188
- [ ] Re-read `week6/solution` `GenServer.hs` and `SPC.hs`: `SPCM`, `handleMsg`, `checkTimeouts`, job states, `spcWaiting`
- [ ] Question bank §6 (first half: GenServer/SPC)
- Key ideas: threads + channels (`forkIO`, `Chan`, `MVar`), server loop with state, **sync vs async API** (`requestReply` vs `sendTo`), reply channels, why the server owns all state (sequential message handling = atomicity), timeouts via a ticker thread, `killThread`, catching exceptions in jobs, "blocked indefinitely on MVar".

### Day 8 · Tue 3 Nov: A6 (SPC with workers)
- [ ] A6 text (compendium pp. 189–201) and `a6/a6-handout`
- [ ] If your group has an A6 hand-in, re-read it. If not, sketch the protocol on paper: which messages SPC↔worker, who holds which state.
- [ ] A6 report questions 1–5 → `answers/day8-a6.md`
- [ ] Question bank §6 (second half: workers)
- Key ideas: job queue + idle workers, **central vs decentral timeouts** (dummy 2.6.1), cancel/timeout/crash must leave the worker idle, what happens if a worker thread dies, the race between `jobCancel` (async) and `jobStatus`, `workerStop` on a busy worker.

### Day 9 · Wed 4 Nov: Week 7 exercises A–C (tuples, while/step, `&&`/`||`)
- [ ] `week7/README.md` tasks A–C · compare `week7/handout` vs `week7/solution` (`Parser.hs`, `Eval.hs`, `InterpPure.hs`)
- [ ] Run the examples in the README in `cabal repl` inside `week7/solution`
- [ ] Question bank §7 (A–C)
- Key ideas: `"(" Exp ")"` vs tuple (the `try`), `x.i` projection as an Atom suffix, extending the grammar with `&&`/`||` precedence levels, where `evalStep` is inserted (loop bodies + function application), pure `OneOf` = left first, fall back to right on error.

### Day 10 · Thu 5 Nov: Week 7 exercises D–F (simulated + concurrent interpreters, KVDB)
- [ ] `week7/solution/src/APL/InterpSim.hs`, `KVDB.hs`, `InterpConcurrent.hs` (compendium pp. 213–226)
- [ ] Trace by hand: `(1+2) || (3+4+5+6)`, `(loop p = 0 while true do p) || 1`, `get 0 && put 0 true` in pure vs sim vs concurrent
- [ ] Question bank §7 (D–F)
- Key ideas: `step` runs up to the next `StepOp` and no further, **interleaving** = round-robin stepping, a blocked `get` in the simulator (and what happens when *everything* is blocked), determinism of sim vs nondeterminism of the concurrent interpreter, IORefs to collect SPC job results, cancelling the loser in `||`, KVDB as a GenServer with a list of blocked readers.

### Day 11 · Fri 6 Nov: Full mock exam #1
- [ ] Whole dummy exam, timed, in the Word template, using **only** the PDFs you will have at the exam (notes + compendium + your cheat sheet). No IDE.
- [ ] Mark it. Write down what slowed you down (finding pages? not knowing?) → `answers/day11-mock1.md`
- [ ] Ask Claude for a fresh mock in the same style (new expressions, same assignments)

### Day 12 · Sat 7 Nov: Mock #2 + weak spots
- [ ] Take the fresh mock under exam conditions, then mark it
- [ ] Spend the rest of the day on your two weakest topics only
- [ ] Re-read all of `answers/`: every "I got this wrong because…" line

### Day 13 · Sun 8 Nov: Consolidate (half day)
- [ ] Finish and print `CHEAT-SHEET.md` + the compendium index from `README.md`
- [ ] Logistics: start time, room at Eksamenshuset, ID, what is allowed on paper, whether the answer must be uploaded as .docx
- [ ] Light skim of the dummy-exam solutions. Stop by the early evening and sleep properly.

### Mon 9 Nov: Exam
- Read every question first and do the easy ones first. Answer briefly; the dummy answers are 1–3 sentences.
- If a question asks "what does X evaluate to", **state the value and give a one-line reason** (e.g. "the bound is evaluated in the outer scope").
- Look things up in the compendium; you don't need to remember the code by heart.
