# Cairn — Claude working notes

## Code hygiene

### Never ignore warnings

Warnings are defects in waiting. Treat every compiler / analyzer / linter
warning as something to fix, not filter out.

- `flutter analyze` must be clean before declaring a task done — zero
  `info`, `warning`, or `error` lines attributable to code I touched.
- Do not silence warnings with `// ignore:` comments unless there is a
  concrete, documented reason (and the reason goes in the comment).
- Do not tell the user "that's just a warning, ignore it." If a warning
  appears in output I surface, fix it or explain *specifically* why it
  is safe to leave (with a plan to remove it).
- This applies to deprecation warnings too — `withOpacity`, etc. Migrate
  to the replacement API rather than leaving the deprecation in place.
- C/C++ warnings inside third-party Pods (e.g. sqlite3) are the one
  exception — those are upstream and not under our control. Still, scan
  for real errors among them rather than dismissing the whole block.
