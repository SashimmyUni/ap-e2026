"""Build EXAM-NOTES.pdf from EXAM-NOTES.md with headless Microsoft Edge.

    python "Exam Prep/print/build.py"

Needs markdown-it-py and pypdf (pip install markdown-it-py pypdf). Each `##` section
starts on a new page with its own running header. The cover lists the sections with
their page numbers: the PDF is printed once, the start pages are read back from it,
and then it is printed again with the numbers filled in.
"""

import html
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import date
from pathlib import Path

from markdown_it import MarkdownIt
from pypdf import PdfReader, PdfWriter

HERE = Path(__file__).resolve().parent
NOTES = HERE.parent / "EXAM-NOTES.md"
CSS = HERE / "print.css"
OUT = HERE.parent / "EXAM-NOTES.pdf"

EDGE_CANDIDATES = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
]

SUBTITLE = "Written exam · Mon 9 November 2026 · Eksamenshuset"
PRINTING_TIP = (
    "<strong>Printing:</strong> A4, single-sided, scale 100% (“Actual size”), "
    "and staple top-left. Every section starts on a new page, so you can put a "
    "sticky tab on the first page of each one."
)
# Writing lines under each "My additions" item; an empty item gets the long block.
# 6 x 2 + 9 fills exactly one page.
RULED_LINES, RULED_LINES_EMPTY = 2, 9

md = MarkdownIt("commonmark").enable("table")


def plain(inline):
    return "".join(c.content for c in inline.children if c.type in ("text", "code_inline"))


def css_string(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


class Section:
    def __init__(self, inline, tokens):
        text = plain(inline)
        m = re.match(r"(§\w+(?:\s*/\s*\w+)?)\s+(.*)", text)
        if m:
            self.tab = re.sub(r"\s+", "", m.group(1))
            prefix = m.group(1)
        else:
            self.tab, prefix = "+", ""
        self.slug = "sec-" + (re.sub(r"[^a-z0-9]+", "-", self.tab.lower()).strip("-") or "plus")
        self.extra = self.tab == "+"
        self.heading = text
        self.title = text[len(prefix):].strip()
        self.short = self.title.split(" (")[0]
        title_html = md.renderInline(inline.content[len(prefix):].strip())
        main, sep, note = title_html.partition(" (")
        self.toc_html = main + (f' <span class="note">({note}</span>' if sep else "")
        self.body = md.renderer.render(tokens, md.options, {})


def split(src):
    tokens = md.parse(src)
    intro, sections, current = [], [], None
    for i, t in enumerate(tokens):
        if t.type == "heading_open" and t.tag == "h2":
            current = [tokens[i + 1], []]
            sections.append(current)
        if current is None:
            intro.append(t)
        else:
            current[1].append(t)
    title = next(plain(tokens[i + 1]) for i, t in enumerate(intro)
                 if t.type == "heading_open" and t.tag == "h1")
    h1 = next(i for i, t in enumerate(intro) if t.type == "heading_open" and t.tag == "h1")
    intro = intro[:h1] + intro[h1 + 3:]
    return title, md.renderer.render(intro, md.options, {}), [Section(*s) for s in sections]


def build_stamp():
    def git(*args):
        r = subprocess.run(["git", *args], cwd=NOTES.parent, capture_output=True, text=True)
        return r.stdout.strip() if r.returncode == 0 else ""

    commit = git("log", "-1", "--format=%h", "--", NOTES.name)
    dirty = git("status", "--porcelain", "--", NOTES.name)
    src = f"{NOTES.name} @ {commit}" + (" + local edits" if dirty else "") if commit else NOTES.name
    return f"Built {date.today():%d %b %Y} from {src}"


def page_css(sections, stamp):
    rules = [f"@page {{ @bottom-left {{ content: {css_string(stamp)}; "
             'font: 7.5pt "Segoe UI", sans-serif; color: #666; } }']
    for s in sections:
        head = f"{s.tab} · {s.short}" if not s.extra else s.short
        rules.append(
            f"@page {s.slug} {{ @top-left {{ content: {css_string(head)}; "
            'font: 600 8pt "Segoe UI", sans-serif; color: #333; } }\n'
            f"#{s.slug} {{ page: {s.slug}; }}")
    return "\n".join(rules)


def with_lines(body):
    def item(m):
        n = RULED_LINES if m.group(1).strip() else RULED_LINES_EMPTY
        return f'<li>{m.group(1)}<div class="ruled">{"<div></div>" * n}</div></li>'
    return re.sub(r"<li>(.*?)</li>", item, body, flags=re.S)


def render(title, intro, sections, pages, stamp):
    rows = "\n".join(
        f'<tr><td class="tab">{html.escape(s.tab)}</td>'
        f'<td><a href="#{s.slug}">{s.toc_html}</a></td>'
        f'<td class="pg">{pages.get(s.slug, "–")}</td></tr>'
        for s in sections)
    body = []
    for s in sections:
        cls, content = ("sec sec-plus", with_lines(s.body)) if s.extra else ("sec", s.body)
        body.append(f'<section class="{cls}" id="{s.slug}">\n{content}</section>')
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>{html.escape(title)}</title>
<style>
{CSS.read_text(encoding="utf-8")}
{page_css(sections, stamp)}
</style></head><body>
<section class="cover">
<h1>{html.escape(title)}</h1>
<p class="subtitle">{SUBTITLE}</p>
{intro}
<table class="toc"><tbody>
{rows}
</tbody></table>
<p class="printing-tip">{PRINTING_TIP}</p>
</section>
{chr(10).join(body)}
</body></html>"""


def find_browser():
    for p in EDGE_CANDIDATES:
        if Path(p).exists():
            return p
    for name in ("msedge", "chrome", "chromium"):
        if shutil.which(name):
            return shutil.which(name)
    sys.exit("No Edge/Chrome found; edit EDGE_CANDIDATES in build.py.")


def print_pdf(browser, page, out, workdir):
    profile = workdir / "profile"
    out.unlink(missing_ok=True)
    subprocess.run([browser, "--headless", "--disable-gpu", "--no-first-run",
                    "--disable-extensions", f"--user-data-dir={profile}",
                    "--no-pdf-header-footer", f"--print-to-pdf={out}", page.as_uri()],
                   check=True, capture_output=True, timeout=180)
    if not out.exists():
        sys.exit(f"{browser} did not write {out}")


def start_pages(pdf, sections):
    """1-based page on which each section's heading appears (the cover is page 1)."""
    squash = lambda s: re.sub(r"\s+", "", s)
    texts = [squash(p.extract_text() or "") for p in PdfReader(pdf).pages]
    pages, at = {}, 1
    for s in sections:
        key = squash(s.heading)[:40]
        at = next((i for i in range(at, len(texts)) if key in texts[i]), None)
        if at is None:
            sys.exit(f"Could not find the heading of {s.tab} in the PDF")
        pages[s.slug] = at + 1
    return pages


def main():
    title, intro, sections = split(NOTES.read_text(encoding="utf-8"))
    stamp = build_stamp()
    browser = find_browser()
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        page, pdf = tmp / "notes.html", tmp / "notes.pdf"
        pages = {}
        for _ in range(3):
            page.write_text(render(title, intro, sections, pages, stamp), encoding="utf-8")
            print_pdf(browser, page, pdf, tmp)
            found = start_pages(pdf, sections)
            if found == pages:
                break
            pages = found
        else:
            sys.exit("Page numbers did not settle after 3 passes")

        writer = PdfWriter(clone_from=PdfReader(pdf))
        writer.add_metadata({"/Title": title})
        for s in sections:
            writer.add_outline_item(f"{s.tab}  {s.title}" if not s.extra else s.title,
                                    pages[s.slug] - 1)
        with open(OUT, "wb") as f:
            writer.write(f)
    n = len(PdfReader(OUT).pages)
    print(f"Wrote {OUT} ({n} pages)")
    for s in sections:
        print(f"  p.{pages[s.slug]:>3}  {s.tab:<7} {s.short}")


if __name__ == "__main__":
    main()
