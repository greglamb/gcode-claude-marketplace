---
description: Setup the development environment
---
Before continuing, do the following exactly once:

1. Create the .worktrees directory in the project root and add it to gitignore
2. Create the _reference directory in the project root and add it to gitignore
3. Create the TODO.md file in the project root
4. Create the CHANGELOG.md file in the project root
5. Set up vibecode-workflow using the vibecode-workflow skill
6. Make sure the following skills are available - if they are not then notify the user how to obtain them:
  - superpowers
    - Obtain it by running:
     - /plugin marketplace add obra/superpowers-marketplace
     - /plugin install superpowers@superpowers-marketplace
  - episodic-memory
    - Obtain it by running:
      - /plugin marketplace add obra/superpowers-marketplace
      - /plugin install episodic-memory@superpowers-marketplace
  - project-standards
    - Obtain it by running:
      - /superpowers:writing-skills Create the project-standards skill in this project's .claude/skills/project-standards folder. It should apply best practices for developing [your application description here]
