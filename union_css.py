# Union resolver for the recurring default.css collision: the branch (HEAD)
# and main (theirs) both appended component @layer blocks at the same anchor,
# sharing the closing braces after the conflict. Emits main's accumulated
# blocks first, an explicit closure computed from their own brace imbalance,
# then the branch's block, which the shared suffix closes. Asserts one
# region only and whole-file brace balance afterwards.
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "assets/default.css"
lines = open(path).read().split("\n")

starts = [i for i, l in enumerate(lines) if l.startswith("<<<<<<<")]
mids = [i for i, l in enumerate(lines) if l == "======="]
ends = [i for i, l in enumerate(lines) if l.startswith(">>>>>>>")]
assert len(starts) == len(mids) == len(ends) == 1, (starts, mids, ends)
s, m, e = starts[0], mids[0], ends[0]

head = lines[s + 1 : m]
theirs = lines[m + 1 : e]

def imbalance(block):
    text = "\n".join(block)
    return text.count("{") - text.count("}")

hi, ti = imbalance(head), imbalance(theirs)
assert hi == ti and hi >= 0, f"asymmetric imbalance head={hi} theirs={ti}"
closure = ["  " * (hi - 1 - k) + "}" for k in range(hi)]

resolved = lines[:s] + theirs + closure + [""] + head + lines[e + 1 :]
text = "\n".join(resolved)
assert text.count("{") == text.count("}"), "whole-file brace imbalance"
open(path, "w").write(text)
print(f"unioned: theirs({len(theirs)}) + closure({hi}) + head({len(head)})")
