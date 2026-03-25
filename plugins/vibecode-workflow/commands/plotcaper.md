---
description: Plots a plan using multiple skills
argument-hint: [request]
---
Before continuing, do the following exactly once:

1. Remind the user to not forget to run these periodically:
  - claude update
  - claude plugin update superpowers@superpowers-marketplace
  - claude plugin update episodic-memory@superpowers-marketplace
2. Use the AskUserQuestion tool to confirm if the user is ready to proceed or if they need to stop and run compact first
3. episodic-memory sync runs automatically via PreToolUse hook — confirm it completed successfully
4. Re-read superpowers:using-superpowers
5. Re-read project-standards and follow all of its conventions and guidelines while designing and developing
6. Use episodic-memory to remember any relevant details regarding this request
7. Announce which step of the plan you are on before resuming work

Starting with brainstorming, use the full superpowers workflow to assist me with the following: $ARGUMENTS
