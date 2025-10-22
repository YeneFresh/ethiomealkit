# ⚠️ MANUAL ACTION REQUIRED: Create Pull Request

## Summary
This document requests the creation of a Pull Request from `feat/client-groundwork` into `main` branch.

## PR Details

### Title
```
feat(client): groundwork scaffolds (Env guard, Theme, UI Kit, Supabase init)
```

### Body
```markdown
### Summary
Establishes foundational client scaffolds before Admin development begins.

**Includes**
- Env.assertRequired wired in startup (bootstrap/env.dart)
- Material 3 theme system (theme.dart, spacing.dart, typography.dart)
- Atomic widgets: YfButton, YfCard, YfDialog, YfSnack, YfHaptics
- Supabase bootstrap + FunctionsRepo (payments-intent invoke)
- CI already validated from previous chore/ci-lints-tests branch

**Testing**
- `flutter analyze` → clean
- `flutter test` → all passing
- Verified Env guard throws on missing --dart-define

**Next**
- Integrate GoRouter & state providers
- Harden Recipe & Delivery screens before Admin phase
```

### Configuration
- **Repository**: YeneFresh/ethiomealkit
- **Base Branch**: `main`
- **Compare Branch**: `feat/client-groundwork`
- **Reviewer**: `@Mikimuluw`
- **Labels**: 
  - `type: feature`
  - `area: client`
  - `status: ready-for-review`

## Quick Commands

### Using GitHub CLI
```bash
gh pr create \
  --repo YeneFresh/ethiomealkit \
  --base main \
  --head feat/client-groundwork \
  --title "feat(client): groundwork scaffolds (Env guard, Theme, UI Kit, Supabase init)" \
  --body "### Summary
Establishes foundational client scaffolds before Admin development begins.

**Includes**
- Env.assertRequired wired in startup (bootstrap/env.dart)
- Material 3 theme system (theme.dart, spacing.dart, typography.dart)
- Atomic widgets: YfButton, YfCard, YfDialog, YfSnack, YfHaptics
- Supabase bootstrap + FunctionsRepo (payments-intent invoke)
- CI already validated from previous chore/ci-lints-tests branch

**Testing**
- \`flutter analyze\` → clean
- \`flutter test\` → all passing
- Verified Env guard throws on missing --dart-define

**Next**
- Integrate GoRouter & state providers
- Harden Recipe & Delivery screens before Admin phase" \
  --reviewer Mikimuluw \
  --label "type: feature" \
  --label "area: client" \
  --label "status: ready-for-review"
```

### Using GitHub Web Interface
1. Navigate to: https://github.com/YeneFresh/ethiomealkit/compare/main...feat/client-groundwork
2. Click "Create pull request"
3. Fill in title and body as shown above
4. Add reviewer: @Mikimuluw
5. Add labels: type: feature, area: client, status: ready-for-review
6. Click "Create pull request"

## Branch Status
- ✅ `main` branch is at commit `eb12b0e`
- ✅ `feat/client-groundwork` branch is at commit `ed62d39`
- ✅ Branch is pushed to origin
- ✅ **10 commits ahead** of main
- ✅ **113 files changed**, 12,234 insertions(+), 532 deletions(-)

## Important Notes
1. **DO NOT MERGE immediately** - wait for CI to pass
2. Once CI passes, use **squash-and-merge** with commit message:
   ```
   feat(client): groundwork scaffolds (Env, Theme, UI Kit, Supabase init)
   ```
3. Monitor CI at: `https://github.com/YeneFresh/ethiomealkit/pull/<PR_NUMBER>/checks`

## Why Manual Action is Needed
The automated agent environment does not have GitHub authentication credentials, which prevents programmatic PR creation. This is a security constraint by design.

## Additional Resources
- Full instructions: `/tmp/PR_CREATION_INSTRUCTIONS.md`
- Automated script (requires auth): `/tmp/create_pr.sh`
- API script (requires token): `/tmp/create_pr_api.sh`
- Task summary: `/tmp/TASK_SUMMARY.md`

---

**Created by**: GitHub Copilot Agent
**Date**: 2025-10-22
**Task**: Create PR from feat/client-groundwork to main
**Status**: Awaiting manual PR creation
