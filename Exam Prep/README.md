# AP 2026 — Exam Prep

Everything for the Advanced Programming exam lives in this folder.

| File | What it is |
|---|---|
| [STUDY-PLAN.md](STUDY-PLAN.md) | Day-by-day plan from 27 Oct to the exam, with checkboxes |
| [QUESTION-BANK.md](QUESTION-BANK.md) | Practice questions in the dummy-exam style, grouped by week/assignment |
| [CHEAT-SHEET.md](CHEAT-SHEET.md) | Your own notes, filled in as you go; bring a printed copy |
| `answers/` | Your written answers, one file per study day (e.g. `answers/day2-a1.md`) |

## The exam: facts

- **When / where:** 9 November 2026, Eksamenshuset (from the course `README.md`, section *Time and place*).
  > You mentioned 4 October, but that date has already passed and the course page says 9 November. The plan is built around **9 November**. Check Absalon for the start time and length; neither is in the repo.
- **Format:** written, on-site, with invigilation. Answers go in a **Word document** (`week7/answer-sheet.docx` is the template).
- **Aids:** everything is allowed **except generative AI and the internet**. On the exam computer you get the course notes PDF (`week7/ap-notes.pdf`) and the **compendium** (`week7/compendium.pdf`). The compendium holds every exercise, assignment text and code handout, **including the week 1–7 exercise solutions**.
- **Question style** (see `week7/exam-dummy-solutions.pdf`): short answers of 1–4 sentences, almost no code writing. Most questions refer to a specific assignment or exercise:
  - *"What does this expression evaluate to, and why?"*
  - *"What changes if `EvalM`/`catch`/the grammar is defined like this instead?"*
  - *"Name an advantage/disadvantage of design X vs Y."*
  - Small code edits, e.g. rewriting `catch` or removing left recursion from a grammar.
- **Best predictor of the questions:** the "numbered questions" in each assignment's report section. The dummy exam reuses their ideas almost directly. All of them are in the question bank.

## Compendium index (page numbers in `week7/compendium.pdf`)

Being able to open the right page in 10 seconds is worth a lot in an open-book exam. Print this table or copy it into your cheat sheet.

| Topic | Exercise text | Exercise solution code | Assignment text | Assignment handout code |
|---|---|---|---|---|
| W1 Haskell / interpreters, A1 | 1–6 | 7–12 | A1: 13–20 | 21–27 |
| W2 Monads, A2 | 28–32 | 33–39 | A2: 40–46 | 47–55 |
| W3 Parsing, A3 | 56–65 | 66–73 (Parser.hs 70–71) | A3: 74–80 | 81–88 |
| W4 Free monads, A4 | 89–96 | 97–108 (Monad.hs 105–106) | A4: 109–120 | 121–133 |
| W5 QuickCheck, A5 | 134–137 | 138–147 (Tests.hs 146–147) | A5: 148–152 | 153–165 (Parser 161–163, Tests 164–165) |
| W6 Concurrency / SPC, A6 | 166–179 | 180–188 (SPC.hs 182–186) | A6: 189–194 | 195–201 |
| W7 exam exercises | 202–208 | 209–239 | — | — |

Week 7 solution files: AST 210 · Eval 211–212 · InterpConcurrent 213–214 · InterpPure 215 · **InterpSim 216** · InterpStep 217 · Monad 218–219 · Parser 220–223 · GenServer 224–225 · **KVDB 226** · SPC 227–230 · Tests 231–239.

## Your own material in this repo

- Your group's hand-ins: `a1/handin` … `a5/handin`. Submitted reports: `a1/AssignmentReportSubmissions/` (A1–A3) and `a4/REPORT.md`, `a5/REPORT.md`.
- **`a2/handin/src/APL/` is empty.** Only the submitted A2 report (`a2-1.pdf`) and the handout `a2/a2-handout` are here. For day 2, use the handout plus `week2/solution`, or copy your group's code in.
- **There is no A6 hand-in in this repo.** If your group solved A6 somewhere else, copy it into `a6/handin` before 3 November. If not, plan day 8 covers it from the handout and the week 6 solution.
- The Absalon feedback from your TAs on each assignment is high-value: note every point they made in `CHEAT-SHEET.md`.
