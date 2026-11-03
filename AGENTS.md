# AGENTS.md

Guidance for agents working in this repository.

## Purpose

This repository publishes `coproduct_location`, an opt-in Flutter add-on
that supplies the `device_location` attribute for GPS geo-fence targeting in
[Coproduct](https://coproduct.app). It depends on
[`coproduct`](https://pub.dev/packages/coproduct) (the main Flutter SDK,
published from
[`coproduct-client-sdks`](https://github.com/coproducthq/coproduct-client-sdks))
and on `geolocator`. It exists as a separate package, not as part of the main
SDK, so that an app that only reads feature flags never links any
location-permission code — see the README for why.

## Repository layout

- `lib/` — the published package. `coproduct_location.dart` is the public
  barrel; everything under `lib/src/` is implementation detail.
- `example/` — a source-linked (`path:` dependency) demo app, the dev inner
  loop. Not a release gate.
- `test/` — unit tests, pure-Dart logic only (interval clamping). The
  package's `geolocator` calls are exercised manually through `example/`,
  the way the equivalent code was tested before this split, since mocking
  `Geolocator`'s static methods buys little over a device/simulator check.

## Code style

These apply to comments, prose, and commit messages. Code blocks keep their
own syntax.

- **No em-dashes (—).** Use commas, periods, or parentheticals depending on
  what reads naturally. Don't mechanically swap `—` for `-`. Restructure if
  needed.
- **No semicolons (;) in prose.** Use periods or commas plus a connector word
  ("and", "but", "so", "because").
- **No trailing period at the end of a comment block.** Mid-block periods
  that separate sentences are fine.
- **No time-bound phrasing.** Avoid "currently", "today", "as of Phase X",
  "for now". Write durable facts that won't rot.
- **No reassurance bloat.** If the surrounding code already proves the
  property, don't add "works either way", "the flow still works", "no harm
  done".
- **No passive constructions** where active reads better. Avoid "X is
  written by Y". Say "Y writes X".
- **No file-path header comments** at the top of source files. The editor
  and git show the path.
- **American English.** Use -ize, -or, -er. Not -ise, -our, -re.
- **Plain prose.** One thought per sentence beats one long sentence with
  three commas.

## Commit conventions

Follow Conventional Commits: `<type>: <subject>`.

- **Type** is one of `feat`, `fix`, `chore`, `docs`, `refactor`, `test`,
  `perf`, `style`, `build`, `ci`. A scope is rarely needed in a
  single-package repo; omit it unless a change is genuinely scoped to one
  area (`feat(example): ...`).
- **Subject** is lowercase, imperative ("add", "fix", not "added", "fixes"),
  under ~70 characters.
- **Body** explains the why and the non-obvious how.
- **No Co-Authored-By trailers.**
- Don't amend, prefer a new commit, unless the user explicitly asks for an
  amend.
- When a hook fails, fix the cause. Don't pass `--no-verify`.

**The PR title is the commit message.** Merges squash, so title it with a
Conventional Commit type: that's what decides the version bump (see Release
below). Everything else in this section applies to the PR title too.

## Release identity

Versioning is fully automated by `release-please`, triggered by
`.github/workflows/release-please.yml` on every push to `main`.
`.github/.release-please-manifest.json` holds the single source of truth for
the current version of the one package this repo publishes, at `.`
(repo root). Release PRs are the only changes that move it.

Contributors need exactly one thing: **title the PR with a Conventional
Commit type.** It decides the version bump:

- `fix` → patch
- `feat` → minor
- `!` after the type (`feat!:`, `fix!:`) → major
- `refactor`, `test`, `chore`, `docs`, `build`, `ci`, and `style` release
  nothing

A README fix that must reach the published pub.dev page uses `fix:`.

Never, by hand:

- edit `version:` in `pubspec.yaml`, the manifest, or `CHANGELOG.md`
- create a release tag
- run `dart pub publish`

When a release PR merges, `release-please` tags the commit and
`.github/workflows/publish.yml` runs: tests and analysis, then an OIDC
trusted publish to pub.dev on that tag. Unlike `coproduct-client-sdks`'s
Flutter SDK, this package has no native/Rust core to compile, so there is no
separate manual release runbook. One step stays human-only regardless: pub.dev
requires a package's *first* publish, and the trusted-publisher configuration
pointing at this repo and workflow, to be set up by a person with publish
rights before the OIDC step in `publish.yml` can succeed. Every release after
that first one is unattended.
