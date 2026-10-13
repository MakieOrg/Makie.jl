# Unreleased changelog entries

Every PR with user-facing changes adds a file `changelog/<PR number>.md` containing one or more entries:

```md
- Fixed `foo` erroring on empty input.
- Added the `bar` attribute to `baz`.
  - Indented lines continue the entry above.
```

Each entry starts with `- `, indented lines continue the previous entry, and nothing else is allowed (no headers, no blank lines between entries). Do not add the PR link, it is appended automatically.

When a new version is tagged, `tooling/bump_versions.jl` collects all entries, newest PR first, into a new section of `CHANGELOG.md` and deletes the files. CI checks that a PR adds a file named after its own number unless the `skip-changelog` label is set, and validates all entries with `julia tooling/changelog.jl check`.
