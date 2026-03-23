---
description: Show me the todo list
---
FIRST Use the askquestion tool to determine if the user wants us to open the todo list in vscode or show it here
IF the user wants us to open the todo list in vscode THEN run !code TODO.md
OTHERWISE print the full contents of TODO.md in your reply verbatim inside a code block. Do not use a tool call to read it — use bash to cat the file and then repeat the full contents in your reply.