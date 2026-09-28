---
name: adair-code-audit
description: >
  tapd-specific additions to the root adair-code-audit skill (Flutter code
  review / pre-commit checklist). Same triggers as the root skill; always
  follow the root skill first, then apply these tapd rules.
---

# adair-code-audit — tapd additions

**This file is not a standalone skill.** Read and follow the root skill at
`/Users/cohen/Documents/flutter-projects/.claude/skills/adair-code-audit/SKILL.md`,
and apply the additions below wherever tapd is in scope.

## Step 1 — Scope

- The Flutter root is `tapd/mobile/`, not `tapd/`. It has its own
  `gen_mocks.sh` and `l10n.yaml`. Run every `flutter`/`dart` command from
  there.

## Step 4 — False positives

- **`tap` + `pumpAndSettle(duration)` in tapd tests** — tapd's own
  `tapAndSettle` (`tapd/mobile/test/test_utils/test_utils.dart`) takes no
  duration argument, unlike adair-flutter-lib's, so the two-liner is required
  there when a settle duration is needed.
- **"Reuse the lib's `StubbedManagers` / `mocks.mocks.dart` in tapd"** — the
  sibling apps import `../../../adair-flutter-lib/test/mocks/mocks.mocks.dart`
  by relative path, but tapd resolves build_runner 2.16.1 (siblings: 2.10.4),
  which throws `Package name contains invalid characters: "adair-flutter-lib"`
  on that import. Leave tapd's own lib mocks (`MockSpec<lib.X>(as:
  #MockLibX)` in `test/mocks/mocks.dart`) in place.
- **"Unreachable" claims about tapd board geometry** — tapd's two
  `TargetBoard`s start fully *above* the screen (`position.y =
  -verticalStartFactor * size.y`, origin at the screen's top-left) and scroll
  in, so "the boards always cover the screen" is false early in a run. Check
  it empirically (print `absolutePosition` in a `tapd_world_test` pump)
  before accepting that a board-lookup miss branch is dead.

## Step 5 / Step 8 — Regenerating mocks

- Regenerate with `./gen_mocks.sh` from `tapd/mobile/`. Never hand-edit
  `test/mocks/mocks.mocks.dart`. `build.yaml` limits mockito's builder to
  `test/mocks/mocks.dart`. Without it, build_runner 2.16+ fails with "Cannot
  recurse at later or equal phase", so don't remove it.

## Step 10 — ARB locale rules

| Base | Requires full coverage | Skip (spelling variants only) |
|------|------------------------|-------------------------------|
| `mobile/lib/l10n/app_en.arb` | *(no other locales)* | `app_en_CA.arb`, `app_en_GB.arb`, `app_en_AU.arb` |
