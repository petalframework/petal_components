# Auto-union every conflict region in CHANGELOG.md: branch entries (HEAD)
# first, then main's block, blank-line separated - the resolution used for
# every train sync so far. Refuses regions that look non-trivial and warns
# on duplicate entry titles so a double-cherry-picked fix can't ride in twice.
import re
import sys

path = "CHANGELOG.md"
src = open(path).read()
lines = src.split("\n")

out = []
i = 0
regions = 0
while i < len(lines):
    if lines[i].startswith("<<<<<<<"):
        head, theirs = [], []
        i += 1
        while not lines[i].startswith("======="):
            head.append(lines[i])
            i += 1
        i += 1
        while not lines[i].startswith(">>>>>>>"):
            theirs.append(lines[i])
            i += 1
        i += 1
        while head and head[-1] == "":
            head.pop()
        while theirs and theirs[0] == "":
            theirs.pop(0)
        out.extend(head + [""] + theirs)
        regions += 1
    else:
        out.append(lines[i])
        i += 1

resolved = "\n".join(out)
unreleased = resolved.split("\n### ", 2)[1] if "\n### " in resolved else resolved
titles = re.findall(r"^- \*\*(.+?)(?:\*\*|$)", unreleased, re.M)
dupes = {t for t in titles if titles.count(t) > 1}
open(path, "w").write(resolved)
print(f"regions={regions} dupes={sorted(dupes) if dupes else 'none'}")
if dupes:
    sys.exit(1)
