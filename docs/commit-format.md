# Commit Message Format Guide

Keep commits clean and meaningful for tracking paper evolution.

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Types

- **feat**: New manuscript, new section, new shared resource
- **fix**: Bug fixes, corrections in text
- **docs**: Updates to README or documentation
- **refactor**: Restructure content, reorganize files
- **style**: Formatting, whitespace, preamble tweaks
- **perf**: Optimization of build process or package usage
- **chore**: Dependencies, build scripts, setup

## Scope

- `<paper-name>`: for example, `2026-neural-attention`, `preamble`, `build`
- `repo`: repository-level changes

## Subject

- Use imperative mood ("add" not "adds" or "added")
- Don't capitalize first letter
- No period at the end
- Limit to 50 characters

## Body (optional)

- Explain what and why, not how
- Wrap at 72 characters
- Separate from subject with blank line

## Footer (optional)

```
Closes #123
Related-to: 2026-paper-topic
```

## Examples

```
feat(2026-neural-attention): add attention mechanism section

Implemented theoretical background for self-attention with
mathematical derivations and implementation notes.

Related-to: machine-learning-project
```

```
fix(2025-systems): correct timing diagram in figure 3

The previous diagram showed incorrect state transitions.
Updated based on actual execution traces.
```

```
docs(repo): update build instructions in README
```

```
style(preamble): update margin defaults and spacing
```

```
feat(repo): add shared bibliography template
```

## Tips

- Use present tense in subject: "add section" not "added section"
- Reference paper names in scope for clarity
- Keep commits atomic (one logical change per commit)
- Use `git log --oneline` to review your commit history
