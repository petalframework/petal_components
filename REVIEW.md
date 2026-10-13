# How Claude reviews a PR here

The automatic review (`.github/workflows/claude-code-review.yml`) and any `@claude review` comment follow this file. Edit it freely; it's the reviewer's whole brief.

- Review only the lines this PR changes. A bug in code the PR didn't touch goes in one line at the end under "Seen nearby, not in scope", never as a request to fix it here.
- Report correctness, security and data-loss problems. Skip style, naming and anything the formatter, Credo or CI already checks.
- At most 5 findings, most serious first. If there are none, say "No blocking issues" in one line and stop.
- Each finding: what breaks, for whom, and the smallest fix. Two or three sentences in plain English.
- Never suggest opening a new PR, issue, task or follow-up session.
- This is a public Hex library. Flag a changed or removed attr, slot or CSS class that breaks existing apps, and a user-visible change with no CHANGELOG entry.
