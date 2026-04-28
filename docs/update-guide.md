---
name: Update Guide
description: How to manage scaffold and main branches
type: guide
---

# Update Guide

## Branch Architecture

- **scaffold** - Tools, templates, shared resources (everything except papers)
- **main** - Paper manuscripts in `./papers/`

**Core Rule**: When scaffold changes, rebase main on top of scaffold. **Before rebasing, create a backup branch:** `git branch main-backup`

## Workflows

### Updating Scaffold

```bash
git checkout scaffold
# Make changes to tools, templates, shared resources
git commit -m "feat(tools): ..."
git push origin scaffold

# Rebase main on new scaffold
git checkout main
git rebase origin/scaffold
git push -f origin main
```

⚠️ **If rebase conflicts occur**: Conflicts should be rare since scaffold and main have different scopes. If they happen, review carefully—likely a paper accidentally modified scaffold files.

### Adding New Papers

```bash
git checkout main
git rebase origin/scaffold  # get latest scaffold
./tools/new-paper.sh --paper=2026-your-topic
git commit -m "feat(2026-your-topic): ..."
git push origin main
```

### Pulling Colleague's Scaffold Updates

```bash
git fetch origin scaffold
git checkout main
git rebase origin/scaffold
git push -f origin main
```

### Collaborating on Papers (Main Branch)

If multiple people push papers to main without rebasing scaffold changes:

```bash
# Pull latest main (has colleague's papers)
git fetch origin main
git checkout main
git rebase origin/scaffold  # ensure latest scaffold
git merge origin/main       # incorporate colleague's papers
git push origin main
```

## Edge Cases

1. Papers committed to scaffold
   - **Root cause**: Someone worked on papers while on scaffold branch instead of main.
   - **Solution**: Manual—move commits to main, clean scaffold history.

2. Main diverges from scaffold history
   - **Root cause**: Scaffold was rebased or force-pushed after main was created from it.
   - **Solution**: Manual—reconstruct main by applying paper commits on top of new scaffold.

3. Force-push to main causes lost work
   - **Root cause**: Someone force-pushed without pulling latest changes first.
   - **Solution**: Manual—recover from backups or reflog if available.

4. Rebase conflicts on main
   - **Root cause**: Paper modified scaffold files, or scaffold and papers have overlapping changes.
   - **Solution**: Manual—review conflicts carefully, resolve based on intent.
