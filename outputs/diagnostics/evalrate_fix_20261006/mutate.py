import sys
path, frm, to = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(path, encoding="utf-8").read()
n = s.count(frm)
if n != 1:
    sys.exit(f"pattern found {n} times, need exactly 1")
open(path, "w", encoding="utf-8").write(s.replace(frm, to))
