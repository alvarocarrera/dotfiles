#!/usr/bin/env python3
"""Read-only candidate source for the local Hermes zsh completion extension.

Usage:
  hermes-complete.py sessions <state.db>
  hermes-complete.py kanban <kanban.db>

Prints one "value:description" line per candidate (zsh _describe format),
most recent first. Never writes: the DB is opened with mode=ro, and any
error yields no output so TAB never shows tracebacks.
"""
import re
import sqlite3
import sys

LIMIT = 150
TITLE_MAX = 70
_CTRL = re.compile(r"[\x00-\x1f\x7f-\x9f  ]+")
_WS = re.compile(r"\s+")


def clean(text, maxlen=TITLE_MAX):
    text = _WS.sub(" ", _CTRL.sub(" ", str(text or ""))).strip()
    if len(text) > maxlen:
        text = text[: maxlen - 1].rstrip() + "…"
    return text


def value(text):
    # _describe splits on the first unescaped colon.
    return str(text).replace("\\", "\\\\").replace(":", "\\:")


def connect(path):
    uri = "file:" + path.replace("?", "%3f").replace("#", "%23") + "?mode=ro"
    conn = sqlite3.connect(uri, uri=True, timeout=0.5)
    conn.execute("PRAGMA query_only = 1")
    return conn


def sessions(path):
    rows = connect(path).execute(
        """
        SELECT id, source, title, display_name, archived
        FROM sessions
        ORDER BY COALESCE(last_activity_at, ended_at, started_at) DESC
        LIMIT ?
        """,
        (LIMIT,),
    )
    for sid, source, title, display_name, archived in rows:
        desc = clean(source) or "?"
        label = clean(title or display_name)
        if label:
            desc += " — " + label
        if archived:
            desc += " [archived]"
        yield value(sid), desc


def kanban(path):
    rows = connect(path).execute(
        """
        SELECT id, status, assignee, title
        FROM tasks
        ORDER BY COALESCE(completed_at, started_at, created_at) DESC
        LIMIT ?
        """,
        (LIMIT,),
    )
    for tid, status, assignee, title in rows:
        desc = " — ".join((clean(status, 20) or "?", clean(assignee, 30) or "-", clean(title)))
        yield value(tid), desc


def main():
    if len(sys.argv) != 3:
        return
    kind, path = sys.argv[1], sys.argv[2]
    source = {"sessions": sessions, "kanban": kanban}.get(kind)
    if source is None:
        return
    try:
        out = [f"{v}:{d}" for v, d in source(path)]
    except Exception:
        return
    sys.stdout.write("\n".join(out) + ("\n" if out else ""))


if __name__ == "__main__":
    main()
