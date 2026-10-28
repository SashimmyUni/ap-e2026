# AP 2026: exam preparation

Goal: **pass the written exam on Mon 9 Nov 2026** with one week of study, using the Exam Notes as the main tool.

| File | What it is | When |
|---|---|---|
| [STUDY-PLAN.md](STUDY-PLAN.md) | The 7-day plan, with checkboxes | Start here |
| [EXAM-NOTES.md](EXAM-NOTES.md) | **The notes you bring to the exam**: page index, facts and model answers for every assignment and the dummy exam | Read daily; print on Day 6–7 |
| [EXAM-NOTES.pdf](EXAM-NOTES.pdf) | The print version of the notes: a cover with section page numbers, every section starting on a new page, and a ruled page for your own additions | Print this on Day 6–7 |
| [QUESTION-BANK.md](QUESTION-BANK.md) | Practice questions per assignment (★ = official report question, D = dummy exam) | Daily drill, Days 1–5 |
| [MOCK-EXAM.md](MOCK-EXAM.md) | A fresh full mock exam (variants, not copies) | Day 6, under exam conditions |
| [MOCK-EXAM-SOLUTIONS.md](MOCK-EXAM-SOLUTIONS.md) | Answer key for the mock | After the mock |
| `answers/` | Your written answers, one file per day | Daily |

**Rebuilding the PDF** after you edit the notes: `python "Exam Prep/print/build.py"` from the repo root (needs Edge, and `pip install markdown-it-py pypdf`). It takes a few seconds and overwrites `EXAM-NOTES.pdf`. The footer shows the build date and commit, so you can tell whether a printout is current.

## The exam: facts

- **When / where:** Mon 9 November 2026, Eksamenshuset (course `README.md`, *Time and place*). Check Absalon for the start time and length; neither is in the repo.
- **Format:** written, on-site, with invigilation. Answers go in a **Word document**; the template is `week7/answer-sheet.docx`.
- **Aids:** "All aids allowed except Generative AI and Internet access." The exam computer has the course notes (`week7/ap-notes.pdf`) and the **compendium** (`week7/compendium.pdf`), which holds every exercise, the solutions, the assignment texts and the code handouts. **Bring `EXAM-NOTES.md` printed.** Check on Absalon whether you may also bring digital files.
- **Question style** (`week7/exam-dummy-solutions.pdf`):
  - 1 general section (3 questions), then 1–3 questions per assignment A1–A6, plus week 7;
  - answers are 1–3 sentences, with almost no code writing;
  - typical questions: "What does this evaluate to, and why?", "What changes if `catch`/`EvalM`/the grammar were defined like this?", "Advantage/disadvantage of X vs Y?", plus small code edits (rewrite `catch`, remove left recursion).
- **Best predictor of the questions:** the numbered report questions in each assignment text (★) and the dummy exam. All of them have model answers in `EXAM-NOTES.md`.

## Why this plan should get you a pass

1. **Coverage:** every assignment and week 7 has a section in the notes. In the exam you never face a topic with nothing to write.
2. **Lookup speed:** the notes start with a page index for the compendium and the course notes, and the plan makes you practise lookups every day.
3. **Adaptation:** the question bank and the mock use *new* expressions, so you practise turning a model answer into an answer for the question in front of you.
4. **Exam conditions** are rehearsed twice: the dummy exam on Day 1 (cold) and Day 7 (with notes), and the mock exam on Day 6.

## Your own material in this repo

- Group hand-ins: `a1/handin`, `a3/handin`, `a4/handin`, `a5/handin`. Submitted reports: `a1/AssignmentReportSubmissions/` (A1–A3), `a4/REPORT.md`, `a5/REPORT.md`. Their answers are folded into `EXAM-NOTES.md`.
- `a2/handin/src/APL/` is **empty** and there is **no A6 hand-in**. The notes cover A2 from the handout and the week 2 solution, and A6 from the week 6 solution with generic design answers.
- The Absalon feedback from your TAs on each assignment is high-value. Add every point they made to the matching notes section.
