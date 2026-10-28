#!/usr/bin/env python3
"""Summary-of-changes report generator (sentence level, from git).

Compares every content/**/*.tex file in the working tree against a git ref
(default: tag `examined`). The thesis keeps one sentence per source line, so
a line is a sentence. Adjacent changed sentences are grouped into one row,
and groups never cross a foldable boundary.
Each row shows the original and revised text, with deleted words in red
strikethrough and inserted words in blue underline, a change score, and the
page where the change appears in the Editorial Version.

Score: word-level Levenshtein distance on normalized word forms (lowercase,
punctuation stripped, plural/-ed/-ing endings stripped). Insert, delete or swap
of a word costs 1. A stopword costs 0.25. Equal normalized forms cost 0.

Usage (from papers/2026-thesis):
    python others/diff-workflow/changes_report.py [--ref examined] [--min-words X]
        [--keep-spelling] [--diff-pdf main-diffexamined.pdf]
        [--diff-aux main-diffexamined.aux] [--out others/diff-workflow/summary-of-changes]

--ref            git ref of the version the examiners saw (default: tag `examined`).
--min-words X    drop rows with a score below X (default 1.0).
--keep-spelling  also report British -> American spelling changes (default: ignore).
--diff-pdf/-aux  Editorial Version PDF and its .aux (page lookup, section numbers).
--metric count   old whole-word count instead of the Levenshtein score.
--stopword-weight W  cost of a stopword (default 0.25).
--new-ref REF    compare against a git ref instead of the working tree.
Outputs <out>.tex and <out>-stats.tex. Compile with pdflatex (twice).
Full guide: others/diff-workflow/README.md
"""
import argparse
import difflib
import glob
import os
import re
import subprocess

BS = chr(92)
RBS = re.escape(BS)

# ---- spelling normalization (British -> American), same rules as the revision pass
EXCL = re.compile(r"^(supervis\w*|pointwise|pairwise|piecewise|raising|comprising|compromis\w*|otherwise|\w*wise|rais\w*|analogue)$", re.I)
FIXED = {"centre": "center", "behaviour": "behavior", "behaviours": "behaviors", "favour": "favor", "favours": "favors",
         "artefact": "artifact", "artefacts": "artifacts", "modelling": "modeling", "modelled": "modeled",
         "programme": "program", "towards": "toward", "labelled": "labeled", "labelling": "labeling"}
OKW = set("otherwise precise exercise promise premise raise raises rise rises arise arises noise wise likewise expertise "
          "surprise comprise comprises compromise advise revise supervise devise enterprise concise disguise praise premises".split())
SPELL = re.compile(r"\b(\w+?)(isation|isations|ised|ises|ising|ise|iser|isers|ysing|ysed|yse)\b|"
                   r"\b(centre|behaviours?|favours?|artefacts?|modelling|modelled|programme|towards|labelled|labelling)\b", re.I)


def _conv(m):
    w = m.group(0)
    lw = w.lower()
    if lw in OKW or EXCL.match(w):
        return w
    if m.group(3):
        r = FIXED.get(lw, lw)
        return r[0].upper() + r[1:] if w[0].isupper() else r
    stem, suf = m.group(1), m.group(2)
    if stem.lower() + suf.lower() in OKW:
        return w
    if suf.lower().startswith("ys"):
        return stem + suf.replace("ys", "yz")
    if suf.lower() == "yse":
        return stem + "yze"
    return stem + suf.replace("is", "iz", 1)


def americanize(s):
    return SPELL.sub(_conv, s)


# ---- LaTeX -> plain text for display
MATH = re.compile(r"\$[^$]*\$")
STRUCT = re.compile(r"^\s*\\(begin|end|label|centering|setlength|toprule|midrule|bottomrule|addlinespace|section|subsection|subsubsection|chapter|include|input|usepackage|newcommand)\b")


def is_prose(line):
    s = line.strip()
    if not s or s.startswith("%"):
        return False
    if STRUCT.match(s):
        return False
    if " & " in s or s.endswith(BS + BS):
        return False
    return True


def to_plain(s):
    s = re.sub(RBS + r"(?:cite\w*)\*?(?:\[[^\]]*\])?\{[^}]*\}", "[cit.]", s)
    s = re.sub(RBS + r"S" + RBS + r"ref\{[^}]*\}", "§#", s)
    s = re.sub(RBS + r"(?:eqref|ref|autoref|cref)\{[^}]*\}", "#", s)
    s = re.sub(RBS + r"(?:ac|acl|acs|acf|Ac|Acl|acp|Acp|Acf)\*?\{([^}]*)\}", r"\1", s)
    s = re.sub(RBS + r"Acp?\{([^}]*)\}", r"\1", s)
    s = s.replace(BS + "%", "%").replace(BS + "&", "&").replace(BS + "_", "_").replace(BS + "#", "#")
    s = s.replace("~", " ")
    return s


def protect_math(s):
    mats = []

    def keep(m):
        mats.append(m.group(0))
        return "\x01%d\x02" % (len(mats) - 1)
    return MATH.sub(keep, s), mats


def strip_cmds(s):
    s = re.sub(RBS + r"[a-zA-Z]+\*?", "", s)
    s = s.replace("{", "").replace("}", "").replace(BS, "")
    return re.sub(r"\s+", " ", s).strip()


def esc(t):
    out = []
    for ch in t:
        if ch in "&%#_":
            out.append(BS + ch)
        elif ch == "^":
            out.append(BS + "textasciicircum{}")
        elif ch == "<":
            out.append(BS + "textless{}")
        elif ch == ">":
            out.append(BS + "textgreater{}")
        else:
            out.append(ch)
    return "".join(out)


def display_tokens(text):
    """Return list of plain tokens (math kept whole, marked with leading \\x03)."""
    prot, mats = protect_math(text)
    plain = strip_cmds(to_plain(prot))
    toks = []
    for t in plain.split(" "):
        if not t:
            continue
        m = re.search("\x01(\\d+)\x02", t)
        if m:
            toks.append(("math", re.sub("\x01(\\d+)\x02", lambda x: mats[int(x.group(1))], t)))
        else:
            toks.append(("txt", t))
    return toks


def render(tokens, marks, kind):
    """marks: set of token indices to highlight; kind: 'del' or 'ins'."""
    parts = []
    for i, (typ, t) in enumerate(tokens):
        body = t if typ == "math" else esc(t)
        if i in marks:
            if kind == "del":
                body = BS + "textcolor{red}{" + BS + "sout{" + body + "}}"
            else:
                body = BS + "textcolor{blue}{" + BS + "uwave{" + body + "}}"
        parts.append(body)
    return " ".join(parts)


def norm_word(t):
    """Normalized word form: lowercase, no punctuation, light suffix stripping."""
    if "#" in t:
        return "#"  # a cross-reference counts as one word
    w = re.sub(r"[^0-9a-z]", "", t.lower())
    for suf in ("ing", "ed", "es", "s", "ly"):
        if len(w) > len(suf) + 3 and w.endswith(suf):
            return w[: -len(suf)]
    return w


def lev(a, b):
    if a == b:
        return 0
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb)))
        prev = cur
    return prev[-1]


def sub_cost(a, b):
    """Word-level substitution cost: 0 if the normalized word forms are equal, else 1."""
    return 0.0 if a == b else 1.0


STOPWORDS = set(norm_word(w) for w in """the a an of to in on for and or that which is are be been being was were by with as at from it its
this these those there their than then so such also can could may might will would should do does did has have had
into over under between within across among via per upon while whereas where when whether how what who whom whose
we our us you your they them he she his her i my me""".split())
STOP_WEIGHT = 0.25


def w_cost(w):
    return STOP_WEIGHT if w in STOPWORDS else 1.0


def lev_score(a, b):
    """Weighted word-level edit distance. Insert/delete cost 1 (0.25 for a stopword).
    Substituting a word costs 1 (0 when the normalized forms are equal; 0.25 when both
    words are stopwords)."""
    n, m = len(a), len(b)
    prev = [0.0] * (m + 1)
    for j in range(1, m + 1):
        prev[j] = prev[j - 1] + w_cost(b[j - 1])
    for i in range(1, n + 1):
        cur = [prev[0] + w_cost(a[i - 1])] + [0.0] * m
        for j in range(1, m + 1):
            sc = sub_cost(a[i - 1], b[j - 1])
            if a[i - 1] in STOPWORDS and b[j - 1] in STOPWORDS:
                sc *= STOP_WEIGHT
            cur[j] = min(prev[j] + w_cost(a[i - 1]), cur[j - 1] + w_cost(b[j - 1]), prev[j - 1] + sc)
        prev = cur
    return prev[m]


def word_diff(old_toks, new_toks, metric="lev"):
    a = [norm_word(t) if k == "txt" else t for k, t in old_toks]
    b = [norm_word(t) if k == "txt" else t for k, t in new_toks]
    sm = difflib.SequenceMatcher(a=a, b=b, autojunk=False)
    dmarks, imarks, count = set(), set(), 0
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            continue
        dmarks.update(range(i1, i2))
        imarks.update(range(j1, j2))
        count += max(i2 - i1, j2 - j1)
    if metric == "lev":
        count = lev_score([w for w in a if w], [w for w in b if w])
    return dmarks, imarks, count


def git_show(ref, path):
    r = subprocess.run(["git", "show", "%s:%s" % (ref, path)], capture_output=True, text=True, encoding="utf8", errors="replace")
    return r.stdout if r.returncode == 0 else None


SENT = "\x00FOLD"  # sentinel emitted at each \begin{foldable}: groups never cross it


def prose_lines(text, american):
    out = []
    for n, line in enumerate(text.replace("\r", "").split("\n"), 1):
        s = line.strip()
        if s.startswith(BS + "begin{foldable}"):
            out.append((n, SENT))
        elif is_prose(line):
            out.append((n, americanize(s) if american else s))
    return out


def split_segments(block):
    """Split a list of (lineno, text) at sentinels; drop empty segments."""
    segs, cur = [], []
    for item in block:
        if item[1] == SENT:
            if cur:
                segs.append(cur)
            cur = []
        else:
            cur.append(item)
    if cur:
        segs.append(cur)
    return segs


def span(seg):
    if not seg:
        return "-"
    a, b = seg[0][0], seg[-1][0]
    return "%d" % a if a == b else "%d--%d" % (a, b)


# ---- headings, labels, pages
HEAD = re.compile(r"^\s*" + RBS + r"(chapter|section|subsection|subsubsection)\*?\{(.*?)\}\s*(?:" + RBS + r"label\{([^}]*)\})?\s*$")


def read_headings(path):
    """[(lineno, level, title, label)] for a content file (titles stripped of macros)."""
    out = []
    if not os.path.exists(path):
        return out
    for n, line in enumerate(open(path, encoding="utf8", newline="").read().replace("\r", "").split("\n"), 1):
        m = HEAD.match(line)
        if m:
            out.append((n, m.group(1), strip_cmds(to_plain(m.group(2))), m.group(3)))
    return out


def read_labels(aux):
    labels = {}
    if os.path.exists(aux):
        txt = open(aux, encoding="utf8", errors="replace").read()
        for m in re.finditer(RBS + r"newlabel\{([^}]*)\}\{\{([^}]*)\}\{([^}]*)\}", txt):
            labels[m.group(1)] = (m.group(2), m.group(3))
    return labels


def read_pages(pdf):
    if not os.path.exists(pdf):
        return []
    r = subprocess.run(["pdftotext", "-layout", pdf, "-"], capture_output=True, text=True, encoding="utf8", errors="replace")
    return [re.sub(r"[^a-z0-9]", "", p.lower()) for p in r.stdout.split("\f")]


def read_printed(pdf):
    """Page number printed at the foot of each page (arabic or roman), or None."""
    if not os.path.exists(pdf):
        return []
    r = subprocess.run(["pdftotext", "-layout", pdf, "-"], capture_output=True, text=True, encoding="utf8", errors="replace")
    out = []
    for p in r.stdout.split("\f"):
        lines = [l.strip() for l in p.split("\n") if l.strip()]
        last = lines[-1] if lines else ""
        out.append(last if re.fullmatch(r"[ivxlcdm]{1,8}|[0-9]{1,3}", last) else None)
    return out


def snippet(tokens, marks):
    """Letters-only text of the longest unchanged run (up to 6 words) in the revised text."""
    best, cur = [], []
    for i, (kind, t) in enumerate(tokens):
        if i in marks or kind == "math":
            cur = []
            continue
        cur.append(re.sub(r"[^a-z0-9]", "", t.lower()))
        cur_ok = [w for w in cur if w]
        if len(cur_ok) > len(best):
            best = list(cur_ok)
    if len(best) < 4:
        # little or no unchanged text (for example a new sentence): search for the inserted words
        ins = [re.sub(r"[^a-z0-9]", "", t.lower()) for i, (kind, t) in enumerate(tokens) if i in marks and kind != "math"]
        ins = [w for w in ins if w]
        if len(ins) > len(best):
            best = ins
    return "".join(best[:6])


def find_page(pages, snip, start):
    if not pages or len(snip) < 12:
        return None
    for p in range(max(start - 1, 0), len(pages)):
        if snip in pages[p]:
            return p + 1
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ref", default="examined")
    ap.add_argument("--min-words", type=float, default=1.0)
    ap.add_argument("--metric", choices=["lev", "count"], default="lev")
    ap.add_argument("--stopword-weight", type=float, default=0.25, help="cost of a stopword (default 0.25)")
    ap.add_argument("--new-ref", default="", help="git ref of the revised version (default: the working tree)")
    ap.add_argument("--keep-spelling", action="store_true")
    ap.add_argument("--diff-pdf", default="main-diffexamined.pdf")
    ap.add_argument("--diff-aux", default="main-diffexamined.aux")
    ap.add_argument("--link-prefix", default="../main-diffexamined.pdf")
    ap.add_argument("--out", default="others/diff-workflow/summary-of-changes")
    args = ap.parse_args()
    global STOP_WEIGHT
    STOP_WEIGHT = args.stopword_weight

    prefix = subprocess.run(["git", "rev-parse", "--show-prefix"], capture_output=True, text=True).stdout.strip()
    labels = read_labels(args.diff_aux)
    pages = read_pages(args.diff_pdf)
    printed = read_printed(args.diff_pdf)
    rows, dropped, total_groups = [], 0, 0
    last_page = 1
    for path in sorted(glob.glob("content/**/*.tex", recursive=True)):
        gpath = (prefix + path).replace(os.sep, "/")
        old = git_show(args.ref, gpath) or ""
        if args.new_ref:
            new = git_show(args.new_ref, gpath) or ""
        else:
            new = open(path, encoding="utf8", newline="").read()
        ol = prose_lines(old, not args.keep_spelling)
        nl = prose_lines(new, False)
        heads = read_headings(path)
        folder = os.path.dirname(path)
        chap = [h for h in read_headings(os.path.join(folder, os.path.basename(folder) + ".tex")) if h[1] == "chapter"]
        chap_title = chap[0][2] if chap else "Front matter"
        chap_num = labels.get(chap[0][3], ("", ""))[0] if chap and chap[0][3] else ""
        sm = difflib.SequenceMatcher(a=[t for _, t in ol], b=[t for _, t in nl], autojunk=False)
        for tag, i1, i2, j1, j2 in sm.get_opcodes():
            if tag == "equal":
                continue
            oseg, nseg = split_segments(ol[i1:i2]), split_segments(nl[j1:j2])
            if len(oseg) == len(nseg):
                pairs = list(zip(oseg, nseg))
            elif not oseg or not nseg:
                pairs = [(s, []) for s in oseg] + [([], s) for s in nseg]
            else:
                pairs = [([x for s in oseg for x in s], [x for s in nseg for x in s])]
            for os_, ns_ in pairs:
                total_groups += 1
                ot = display_tokens(" ".join(t for _, t in os_))
                nt = display_tokens(" ".join(t for _, t in ns_))
                dm, im, cnt = word_diff(ot, nt, args.metric)
                if cnt < args.min_words:
                    dropped += 1
                    continue
                ref_line = ns_[0][0] if ns_ else (os_[0][0] if os_ else 0)
                cur = [h for h in heads if h[0] <= ref_line and h[1] != "chapter"]
                sec = [h for h in cur if h[1] == "section"][-1:] or [None]
                sub = [h for h in cur if h[1] in ("subsection", "subsubsection") and (sec[0] is None or h[0] > sec[0][0])][-1:] or [None]

                def hd(h):
                    if not h:
                        return None
                    num = labels.get(h[3], ("", ""))[0] if h[3] else ""
                    return (num + " " if num else "") + h[2]
                pg = None
                if ns_:
                    pg = find_page(pages, snippet(nt, im), last_page)
                if pg is None:
                    pg = last_page if pages else None
                if pg is not None:
                    last_page = max(last_page, pg)
                loc = path.replace("\\", "/").replace("content/", "")
                rows.append(((chap_num + " " if chap_num else "") + chap_title, hd(sec[0]), hd(sub[0]), loc, span(os_), span(ns_),
                             render(ot, dm, "del") if ot else BS + "textit{(new text)}",
                             render(nt, im, "ins") if nt else BS + "textit{(deleted)}", cnt, pg))

    L = []
    L.append(BS + "documentclass[10pt,a4paper]{article}")
    L.append(BS + "usepackage[landscape,margin=1.5cm]{geometry}")
    L.append(BS + "usepackage[T1]{fontenc}")
    L.append(BS + "usepackage{amsmath,amssymb}")
    L.append(BS + "usepackage[normalem]{ulem}")
    L.append(BS + "usepackage{xcolor,longtable,booktabs,array}")
    L.append(BS + "setlength{" + BS + "tabcolsep}{4pt}")
    L.append(BS + "renewcommand{" + BS + "arraystretch}{1.15}")
    L.append(BS + "pagestyle{empty}")
    L.append(BS + "setlength{" + BS + "parindent}{0pt}")
    L.append(BS + "setlength{" + BS + "parskip}{3pt}")
    L.append(BS + "begin{document}")
    L.append(BS + "section*{Summary of Changes}")
    L.append("Each row lists one changed sentence, or several adjacent changed sentences, from the version you examined to the Editorial Version. "
             "Deleted words appear in " + BS + "textcolor{red}{" + BS + "sout{red strikethrough}} and inserted words in "
             + BS + "textcolor{blue}{" + BS + "uwave{blue underline}}.")
    L.append(BS + "par " + BS + "textit{Score}: word-level Levenshtein distance on normalized word forms. "
             "Inserting, deleting, or replacing a word costs 1, a common function word costs 0.25, and words with the same normalized form cost 0. "
             "The score of a row is the sum over its words.")
    L.append(BS + "par " + BS + "textit{Page}: the page number printed on the page of the Editorial Version where the change appears.")
    L.append(BS + "par Rows with a score below %g are omitted (%d rows listed, %d omitted).%s"
             % (args.min_words, len(rows), dropped, "" if args.keep_spelling else " British-to-American spelling changes are not listed."))
    L.append(BS + "par" + BS + "medskip")
    col = ">{" + BS + "raggedright" + BS + "arraybackslash}"
    L.append(BS + "begin{longtable}{" + col + "p{0.7cm} " + col + "p{10.8cm} " + col + "p{10.8cm} p{0.9cm} p{1.2cm}}")
    head = "No. & Original & Revised & Score & Page " + BS + BS
    L.append(BS + "toprule " + head + BS + "midrule " + BS + "endfirsthead")
    L.append(BS + "toprule " + head + BS + "midrule " + BS + "endhead")
    L.append(BS + "bottomrule " + BS + "endfoot")
    L.append(BS + "bottomrule " + BS + "endlastfoot")
    prev = (None, None, None)
    for k, (ch, sec, sub, loc, lo, ln, o, n, c, pg) in enumerate(rows, 1):
        if ch != prev[0]:
            L.append(BS + "midrule " + BS + "multicolumn{5}{l}{" + BS + "textbf{" + BS + "large " + esc(ch) + "}}" + BS + BS)
            L.append(BS + "midrule")
        if (sec, sub) != (prev[1], prev[2]) or ch != prev[0]:
            sep = " $" + BS + "rightarrow$ "
            t = sep.join(esc(x) for x in (sec, sub) if x) if (sec or sub) else "(chapter opening)"
            L.append(BS + "multicolumn{5}{l}{" + BS + "textbf{" + t + "}}" + BS + BS + "[2pt]")
        prev = (ch, sec, sub)
        link = (printed[pg - 1] if pg and pg - 1 < len(printed) and printed[pg - 1] else "--")
        L.append("%d & " % k + o + " & " + n + " & %.2f & " % c + link + " " + BS + BS)
        L.append(BS + "addlinespace[3pt]")
    L.append(BS + "end{longtable}")
    L.append(BS + "end{document}")
    with open(args.out + ".tex", "w", encoding="utf8", newline="\n") as f:
        f.write("\n".join(L) + "\n")
    with open(args.out + "-stats.tex", "w", encoding="utf8", newline="\n") as f:
        f.write(BS + "newcommand{" + BS + "nrowslisted}{%d}\n" % len(rows))
        f.write(BS + "newcommand{" + BS + "nrowsdropped}{%d}\n" % dropped)
        f.write(BS + "newcommand{" + BS + "mincutoff}{%g}\n" % args.min_words)
    print("groups total %d, listed %d, below cutoff %d -> %s.tex" % (total_groups, len(rows), dropped, args.out))


if __name__ == "__main__":
    main()
