# 9-day plan: from zero to passing the AP exam (Mon 9 Nov 2026)

**Who this is for:** someone who has not studied the course and has never used Haskell. Nothing here assumes you remember a lecture or solved an assignment.

**Dates:** Sat 31 Oct → Sun 8 Nov. **Time:** about 5 hours a day (6 on Days 1 and 4, less on Day 9).

**The goal is a pass, and that shapes the plan:**
- The exam asks you to **read code and explain it**: "what does this evaluate to, and why?", "what changes if this line changes?". It has no substantial code writing (course `README.md`). So you are learning to *trace* Haskell, not to write programs in it.
- It is open book. You get `ap-notes.pdf` and `compendium.pdf` on the exam computer and bring printed `EXAM-NOTES`. You need to understand things and know where they are, not memorise them.
- The lecturer's advice (`week7/7b.pdf`, slide 40): **breadth across the learning goals matters more than depth in one topic.** So **every day has a hard stop: move on to the next topic even if today's is only half clear.** A rough grasp of all seven topics beats a solid grasp of four.

| Day | Date | Topic | Hours |
|---|---|---|---|
| 1 | Sat 31 Oct | Haskell from scratch + A1 evaluator | 6 |
| 2 | Sun 1 Nov | Monads + A2 | 5 |
| 3 | Mon 2 Nov | Parsing + A3 | 5 |
| 4 | Tue 3 Nov | Free monads + A4 (the hardest day) | 6 |
| 5 | Wed 4 Nov | Property-based testing + A5 | 5 |
| 6 | Thu 5 Nov | Concurrency + A6 | 5 |
| 7 | Fri 6 Nov | Week 7: everything combined | 5 |
| 8 | Sat 7 Nov | Mock exam B, timed; mark it; fix the notes | 5 |
| 9 | Sun 8 Nov | Dummy exam as a speed test; logistics; stop early | 2.5 |

## The daily routine (Days 1–7)

The order matters: **learn first, test last.** `EXAM-NOTES.md` is a summary, so it only makes sense after you have met the idea.

| Step | Time | What you do |
|---|---|---|
| 1. Learn | 2 h | Read the day's **Read** pages of `week7/ap-notes.pdf` with the code open beside them. Glance at the **Skim** pages so you know what is there. Don't take notes yet. |
| 2. Run | 30 min | Use the day's GHCi commands. **Write down what you expect before you press Enter.** A wrong guess is the most useful thing that can happen: find out why before moving on. Then change the expression and try again. |
| 3. Assignment | 30 min | Read the assignment text in `week7/compendium.pdf`, mainly the report questions at the end (★). You aren't solving it, only learning what it asks. Those questions are the best predictor of the exam. |
| 4. Exam notes | 30 min | Read the day's section of `EXAM-NOTES.md`. It should now make sense. Mark anything that doesn't and ask about it. |
| 5. Drill | 90 min | Answer the day's **Must** questions from `QUESTION-BANK.md` in `answers/dayN.md`, 3–5 min each, using the notes. Then mark them ✅ / 🟡 / ❌ (see `answers/README.md`), and write one line on why for each ❌. |

- **Stuck on something for 15 minutes?** Ask Claude ("explain line 40 of `Eval.hs`") or mark it and move on. AI is only banned *in* the exam.
- **"Your" code in a ★ question** means your group's hand-in. Where there is none (A2, A6), use the week's solution.
- In GHCi, ignore the warnings that scroll past, and quit with `:q`.

**If you fall behind:** drop things in this order: Skim pages → unmarked questions → the ★ questions. Never skip a topic, and never skip the mock. If you lose a whole day, do only steps 1 and 4 for that day's topic and carry on with the schedule.

---

## Day 1: Haskell from scratch + A1

The course never teaches basic syntax, so today has an extra first block.

- [ ] **Absalon check (10 min), today, not later:** that you qualify for the exam (at least 12 assignment points and at least 1 point in each of A1–A5), the start time and length, and whether you may bring digital files.
- [ ] **See the target (10 min):** read `week7/exam-dummy.pdf`. Don't answer it. Just see what the questions look like.
- [ ] **Haskell syntax (2 h):** *Programming in Haskell* chapters 2, 3, 4, 6, 7 and 8, or the matching Hutton video lectures (both linked in the course `README.md`). Read for recognition and don't do the book's exercises. Then read `week1/lec-tue/lecture.hs`.
- [ ] **Build the evaluator (1 h):** follow `week1/README.md` from *Getting started* to *Adding Variables*, with `week1/solution/src/APL/Eval.hs` open. This shows you what the course is doing: writing an interpreter for a small language called APL.
- [ ] **Read:** notes p.1–2, 7–12. **Skim:** p.3–6, 13–17.
- [ ] **Run:**
  ```
  cd week1/solution
  cabal repl
  ghci> :m + APL.AST APL.Eval
  ghci> eval envEmpty (Add (CstInt 1) (CstInt 2))
  ghci> eval envEmpty (Div (CstInt 1) (CstInt 0))
  ```
  Then the full A1 language, in `a1/handin` (same `:m` line):
  ```
  ghci> eval envEmpty (ForLoop ("p", CstInt 1) ("i", CstInt 3) (Mul (Var "p") (CstInt 2)))
  ghci> eval envEmpty (Apply (Lambda "x" (Add (Var "x") (CstInt 1))) (CstInt 41))
  ```
- [ ] **Assignment:** A1 text, compendium p.13–20 (★ p.18–19); code p.24–25 or `a1/handin/src/APL/Eval.hs`.
- [ ] **Exam notes:** §0 (practise: find 5 pages from its lookup tables), §A1, G4, G7, G8.
- [ ] **Must drill:** §1 ★ and (D) questions, §0 Q4.

**Done when** you can read a line like `eval env (Var v) = case envLookup v env of …` aloud in plain words, and explain: `data` constructors, pattern matching, `Either`/`Left`/`Right`, why a closure keeps its own environment, which error wins in `Add`, and why a `ForLoop` always terminates.

## Day 2: Monads + A2

Everything after today builds on this. A monad here is just a way to hide the plumbing you saw yesterday: passing `env` around and checking for `Left` after every step.

- [ ] **Read:** notes p.23–39. **Skim:** the first section of `week2/essence-of-functional-programming.pdf` if monads still feel abstract.
- [ ] **Run:** compare `week2/solution/src/APL/Eval.hs` with yesterday's: same language, much less plumbing.
  ```
  cd week2/solution
  cabal repl
  ghci> :m + APL.AST APL.Eval
  ghci> runEval (eval (Let "x" (CstInt 2) (Add (Var "x") (CstInt 1))))
  ghci> runEval (eval (Div (CstInt 1) (CstInt 0)))
  ```
- [ ] **Write by hand** until you can do it without looking. This is small code the exam may ask for: `>>=` for both `EvalM` variants (§A2) and the fixed `catch` (D 2.2.3).
- [ ] **Assignment:** A2 text, compendium p.40–46 (★ p.45–46). Your group has no A2 code in this repo, so use the handout at p.47–55.
- [ ] **Exam notes:** §A2, G5, G6.
- [ ] **Must drill:** §2 ★ and (D) questions, §0 Q5–6.

**Done when** you can explain: what `>>=` does in one sentence; what `askEnv`/`localEnv` hide; and why `(Either Error a, State)` keeps effects after a failure while `Either Error (a, State)` rolls them back.

## Day 3: Parsing + A3

- [ ] **Read:** notes p.40–48, 55–63. **Skim:** p.49–54 (whitespace), 64–67 (Megaparsec, which A3 uses), 71–72 (comments, a ★ question).
- [ ] **Run:** use `a3/handin`, because the week 3 parser has no function application.
  ```
  cd a3/handin
  cabal repl
  ghci> :m + APL.Parser
  ghci> parseAPL "" "1 + 2 * 3"
  ghci> parseAPL "" "f x y"
  ghci> parseAPL "" "get x"
  ghci> parseAPL "" "getx"
  ```
  Read `a3/handin/src/APL/Parser.hs` side by side with the grammar in the assignment.
- [ ] **Write by hand:** remove left recursion and write the `chain` parser (§G3); the right-associative `**` parser (§A3).
- [ ] **Assignment:** A3 text, compendium p.74–80 (★ p.79–80).
- [ ] **Exam notes:** §A3, G3.
- [ ] **Must drill:** §3 ★ and (D) questions, §0 Q3.

**Done when** you can explain: why left recursion breaks a parser; what `try` does (rewinds after consuming input); why the order in `choice` matters; and how keywords are kept apart from variable names.

## Day 4: Free monads + A4 (6 hours)

The hardest topic. It only has to click far enough to answer "what would this interpreter do?". Don't try to master the type-level details.

- [ ] **Read:** notes p.79–94, then p.109–116. **Skim:** p.73–78, 95–96.
- [ ] **Run:** the same `eval` runs under an interpreter, which is the whole idea.
  ```
  cd a4/handin
  cabal repl
  ghci> :m + APL.AST APL.Eval APL.InterpPure
  ghci> runEval (eval (Print "hello" (CstInt 1)))
  ghci> runEval (eval (Let "x" (KvPut (CstInt 0) (CstInt 7)) (KvGet (CstInt 0))))
  ```
  Read `a4/handin/src/APL/Monad.hs`, then `InterpPure.hs`, then `InterpIO.hs`. Your group's `Break` is known to be partly wrong (`a4/REPORT.md`, Task 4), so trust §A4 for `Break` rather than running it.
- [ ] **Say out loud, 3 sentences each:** why `e` must be a `Functor`; why `KvGetOp` has `Val -> a`; why `TryCatchOp a a` is wrong; why `break` is dynamically scoped.
- [ ] **Assignment:** A4 text, compendium p.109–120 (★ p.119).
- [ ] **Exam notes:** §A4, G1.
- [ ] **Must drill:** §4 ★ and (D) questions, §0 Q1 and Q7.

**Done when** you can explain: one program with many interpreters; the pure key-value store versus the database file; and why a transaction rolls back on error but keeps prints.

## Day 5: Property-based testing + A5

A lighter day after Day 4, and the code is easier to read.

- [ ] **Read:** notes p.128–141, 148–153. **Skim:** p.124–127, 142–147, 154–156 (shrinking), 157–176 (stateful testing: A5 doesn't use it, but it is a learning goal).
- [ ] **Run:**
  ```
  cd week5/solution
  cabal repl
  ghci> :m + APL.AST APL.Tests Test.QuickCheck
  ghci> generate (genExp 4)
  ghci> printExp (Add (CstInt 1) (CstInt 2))
  ghci> quickCheck (\x -> x + 0 == (x :: Int))
  ```
  Run `generate` several times and notice how often the output is useless. That is why coverage exists. Then read `a5/handin/src/APL/Tests.hs`.
- [ ] **Assignment:** A5 text, compendium p.148–152 (★ p.151).
- [ ] **Exam notes:** §A5, G2.
- [ ] **Must drill:** §5 ★ and (D) questions, §0 Q2.

**Done when** you can explain: `sized` and halving; `cover` versus `classify`; round-trip properties such as `parse (printExp e) == Right e`; and where you would fix a counterexample (implementation, generator or property).

## Day 6: Concurrency + A6

- [ ] **Read:** notes p.177–201. **Skim:** p.97–102 (exceptions).
- [ ] **Run:**
  ```
  cd week6/solution
  cabal repl
  ghci> :m + SPC
  ghci> s <- startSPC
  ghci> j <- jobAdd s (Job (putStrLn "hi from job") 1)
  ghci> jobWait s j
  ```
  Then read `week6/solution/src/SPC.hs`. It has no workers yet; A6 adds them. Your group has no A6 code.
- [ ] **Draw on paper** the message flow for: `jobAdd` → job runs → `jobWait` reply; a timeout (ticker → `checkTimeouts` → `killThread`); `jobCancel`.
- [ ] **Assignment:** A6 text, compendium p.189–194 (★ p.193–194).
- [ ] **Exam notes:** §A6, G9, G10.
- [ ] **Must drill:** §6 ★ and (D) questions.

**Done when** you can explain: synchronous versus asynchronous calls; why all state lives in one server thread; and why a job's exception must be caught in the job's own thread.

## Day 7: Week 7: everything combined

No new concepts, and the course says exam questions may reference it. It uses free monads, parsing and SPC all at once, so it also revises the week.

- [ ] **Read:** notes p.202–214. **Skim:** p.103 (IORef), 117–123. Then the exercises in compendium p.202–208.
- [ ] **Read the code:** compendium p.215–216 (pure and simulated interpreters side by side) and p.226 (KVDB), or `week7/solution/src/`.
- [ ] **Run:**
  ```
  cd week7/solution
  cabal repl
  ghci> :m + APL.Parser APL.Eval
  ghci> import qualified APL.InterpPure as Pure
  ghci> import qualified APL.InterpSim as Sim
  ghci> let try_ run s = either id (show . run . eval) (parseAPL "" s)
  ghci> try_ Pure.runEval "(1+2) || (3+4+5+6)"
  ghci> try_ Sim.runEval "(1+2) || (3+4+5+6)"
  ghci> try_ Sim.runEval "(loop p = 0 while true do p) || 1"
  ```
- [ ] **Cover** the "Pure / Sim / Concurrent" columns of the §W7 table and predict each row, then uncover it. Repeat until you get them all.
- [ ] **Exam notes:** §W7, G9.
- [ ] **Must drill:** §7 Q2, Q5, Q6, Q8, Q14.

**Done when** you can explain: `step` stops at the next `StepOp`; ties go to the left; the loser's effects stay; a `get` blocks in sim/concurrent but is an error in pure; and which interpreters are deterministic.

## Day 8: Mock exam B under exam conditions

- [ ] **Print `EXAM-NOTES.pdf` first**, rebuilding it if you edited the notes (`python "Exam Prep/print/build.py"` from the repo root).
- [ ] **Mock exam B** (`MOCK-EXAM.md`): 2 hours, printed notes + `ap-notes.pdf` + compendium only. No IDE, no GHCi, no Claude. Use `week7/answer-sheet.docx` or `answers/day8-mock.md`.
- [ ] **Mark it** with `MOCK-EXAM-SOLUTIONS.md`. For every miss, write *why*.
- [ ] **Fix the notes** for every miss, in your own words. Then re-drill your 2 weakest sections from the question bank.

## Day 9: Consolidate (≈2.5 h, stop early)

- [ ] **Speed test:** `week7/exam-dummy.pdf` with the notes, in under 45 minutes, in `answers/day9-dummy.md`. You've already seen these questions in the drills, so the point here is finding answers quickly. Mark it with `week7/exam-dummy-solutions.pdf`.
- [ ] Re-read every ❌ / 🟡 line in `answers/`.
- [ ] Final print of the notes. Tab or colour the section edges (G, A1–A6, W7) so you can flip to them quickly.
- [ ] Logistics: start time and room at Eksamenshuset, ID card, how the Word file is handed in.
- [ ] Evening: no studying. Sleep.

## Exam day

1. Skim all questions first (5 min). Answer the ones you recognise from the notes first.
2. For each question: section → model answer/variant → adapt → **value + one reason**, 1–3 sentences.
3. **Don't pad.** You are also judged on what you write that is wrong (`7b.pdf`, slide 40). If a question is unclear, state your assumption and answer based on it.
4. Stuck for more than 5 minutes? Write the concept you think applies, and move on. Come back at the end.
5. Last 10 minutes: make sure that **every question has some answer**. Breadth counts.
