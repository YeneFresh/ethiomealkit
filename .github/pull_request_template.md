# Grand Image PR Template

**Title:** <Imperative — e.g., "Guard weekly menu behind readiness; add views/RPC; add golden + smoke tests">

## PLAN

- [ ] Keep registry stable; add weekly_menu smoke test
- [ ] Add/refresh app views and RPC
- [ ] Gate provider + overlay
- [ ] Seeds + verify.sql
- [ ] Golden + route tests
- [ ] Lint/Test pass

## CHANGES

* Bullet diffs across `sql/`, `lib/`, `test/`

## TESTS

* Output from CI, golden added/updated

## HOW TO RUN

* Commands, feature flags, test notes

## DoD

- [ ] Screens unchanged unless flagged
- [ ] All CTAs respond
- [ ] Readiness lock works
- [ ] DB verify OK
- [ ] Visuals match theme

---

## Grand Image Compliance

This PR follows the Grand Image Guardrails:

- [ ] No structural UI changes without flags
- [ ] All routes registered in `screen_registry.yaml`
- [ ] Feature flags used for experimental changes
- [ ] Database migrations are idempotent
- [ ] All tests pass (golden, smoke, gate integrity)
- [ ] No dead buttons or broken CTAs
- [ ] Visual consistency maintained

## Refusal Notice

If this PR attempts to change UI/UX beyond flags or registry, it should be rejected with:

> "Refused structural UI change: violates Grand Image Guardrails (screen_registry.yaml / flags). Propose a design RFC instead."





