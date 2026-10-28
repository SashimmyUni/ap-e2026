# 7-day plan: pass the AP exam (Mon 9 Nov 2026)

**The idea:** the exam is open book, has short answers, and asks you to reason about code you have already seen. So you do not need to memorise the course. You need three skills:
1. **Find** the right answer in your notes in under a minute → `EXAM-NOTES.md` is already written. Print it and learn its layout.
2. **Understand** each topic well enough to **adapt** a model answer to a new expression → the daily drills.
3. **Write** short answers under time pressure → the two mock exams.

**When:** 7 consecutive days. The default is **Mon 2 Nov → Sun 8 Nov**. If you start earlier, keep the same order and use the spare days to repeat Days 6–7.

**Time:** about 4 hours a day (Day 7 is shorter). If a day runs short, do the **Must** items and skip the rest.

## The daily routine (Days 1–5)

| Step | Time | What you do |
|---|---|---|
| 1. Read | 45 min | Read the day's sections of `EXAM-NOTES.md`. For every compendium page it mentions, **open the page** in `week7/compendium.pdf` and look at the code. This trains the lookups you will do in the exam. |
| 2. Drill | 90 min | Answer the day's `QUESTION-BANK.md` questions **in writing**, 3–5 min each, as in the exam. Allowed: notes + compendium. **Must:** every ★ and (D) question. Then the unmarked ones if time remains. Write in `answers/dayN.md`. |
| 3. Check | 30 min | Compare each answer with the notes and mark it ✅ / 🟡 / ❌ (see `answers/README.md`). For every ❌, write one line on **why**: didn't find it? didn't understand? misread the code? |
| 4. Fix the notes | 20 min | Add anything you were missing to `EXAM-NOTES.md`, **in your own words**. Short handwritten notes in the margin of the printed copy also count. |
| 5. (optional) GHCi | 20 min | Predict, then run, 2–3 of the day's expressions (commands below). |

```
cd a1/handin && cabal repl          # also works for a3, a4, a5 hand-ins
ghci> import APL.AST
ghci> eval envEmpty (Add (CstInt 1) (CstInt 2))
```

Tip: while you prepare, ask Claude to quiz you on a section or to mark your `answers/dayN.md`. AI is only banned *in* the exam.

---

## Day 1: exam format + A1 (evaluator)
- [ ] **Diagnostic (75 min, Must):** do `week7/exam-dummy.pdf` **cold**, before reading the notes, with only the compendium. This is your baseline, and it shows you the exam format.
- [ ] Mark it with `week7/exam-dummy-solutions.pdf` → `answers/day1-diagnostic.md`. Note your 3 weakest topics.
- [ ] Read `EXAM-NOTES.md` **§0, §G and §A1**. Practise the two lookup tables: find 5 random pages from them in the compendium.
- [ ] Drill: `QUESTION-BANK.md` §0 and §1.
- Understand: static scope and closures, eager `Let` and arguments, the loop bound evaluated in the **outer** scope, which error wins, and why a `ForLoop` always terminates.

## Day 2: A2 (monads) + A3 (parsing)
- [ ] Read **§A2 and §A3**.
- [ ] **Must:** write these **by hand** until you can do them without looking, because they are the only real code the exam may ask for:
  - `>>=` for both `EvalM` variants (§A2);
  - the fixed `catch` (D 2.2.3);
  - removing left recursion plus the `chain` parser (§G3);
  - the right-associative `**` parser (§A3).
- [ ] Drill: `QUESTION-BANK.md` §2 and §3.
- Understand: `(Either Error a, State)` keeps effects and `Either Error (a, State)` rolls them back; `try` = rewind after consuming input; ordered `choice`; keywords vs names.

## Day 3: A4 (free monads), the hardest topic
- [ ] Read **§A4** and the course notes p.79–92 (free monads, "the recipe for other effects").
- [ ] **Must:** explain *out loud* in 3 sentences each:
  - why `e` must be a `Functor`;
  - why `KvGetOp` has `Val -> a`;
  - why `TryCatchOp a a` is wrong;
  - why `break` is dynamically scoped.
- [ ] Drill: `QUESTION-BANK.md` §4 and §0.1, §0.7.
- Understand: one program, many interpreters; pure state vs database file; transaction = roll back on error but keep prints.

## Day 4: A5 (QuickCheck) + A6/W6 (concurrency)
- [ ] Read **§A5 and §A6**.
- [ ] **Must:** for SPC, draw the message flow on paper for: `jobAdd` → job runs → `jobWait` reply; a timeout (ticker → `checkTimeouts` → `killThread`); `jobCancel`.
- [ ] Drill: `QUESTION-BANK.md` §5 and §6.
- Understand: `sized`/halving, `cover` vs `classify`, round-trip properties, where to fix a counterexample; sync vs async, why all state lives in one server thread, and catching exceptions in the job thread.

## Day 5: Week 7 (tuples, `&&`/`||`, three interpreters, KVDB)
- [ ] Read **§W7** and the compendium p.215–216 (pure + simulated interpreters, side by side) and p.226 (KVDB).
- [ ] **Must:** cover the "Pure / Sim / Concurrent" columns of the §W7 table and predict each row, then uncover it. Repeat until you get them all.
- [ ] Drill: `QUESTION-BANK.md` §7.
- Understand: `step` stops at the next `StepOp`; ties go to the left; the loser's effects stay; a `get` blocks in sim/concurrent but is an error in pure; deterministic vs not.

## Day 6: mock exam under exam conditions
- [ ] **Print `EXAM-NOTES.md` today** (the version with your additions).
- [ ] **Mock exam B** (`MOCK-EXAM.md`): 2 hours, printed notes + `ap-notes.pdf` + compendium only. No IDE, no GHCi.
- [ ] Mark it with `MOCK-EXAM-SOLUTIONS.md` → `answers/day6-mock.md`. For every miss, write *why*.
- [ ] Fix the notes for every miss. Then re-drill your weakest section from the question bank.

## Day 7: consolidate (≈2.5 h, stop early)
- [ ] Redo the dummy exam (`week7/exam-dummy.pdf`) quickly, **with the notes**: aim for under 45 minutes. Compare with Day 1.
- [ ] Re-read every ❌ / 🟡 line in `answers/`.
- [ ] Final print of `EXAM-NOTES.md`. Tab or colour the section edges (G, A1–A6, W7) so you can flip to them quickly.
- [ ] Logistics: start time and room at Eksamenshuset (Absalon), ID card, whether you can bring digital files to the exam PC or only paper, and how the Word file is handed in.
- [ ] Evening: no studying. Sleep.

## Exam day
1. Skim all questions first (5 min). Answer the ones you recognise from the notes first.
2. For each question: section → model answer/variant → adapt → **value + one reason**, 1–3 sentences.
3. Stuck for more than 5 minutes? Write the concept you think applies, and move on. Come back at the end.
4. Last 10 minutes: make sure that **every question has some answer**.

---

### If you lose a day
Merge Days 4 and 5 (keep the **Must** items only), and keep Day 6 (the mock) no matter what. The mock and the printed notes matter more than finishing every drill.
