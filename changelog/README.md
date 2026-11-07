# Unreleased changelog entries

Every PR with user-facing changes adds a file `changelog/<PR number>.md` containing one or more entries:

```md
- Fixed `foo` erroring on empty input.
- Added the `bar` attribute to `baz`.
  - Indented lines continue the entry above.
```

Entries can optionally be grouped under the sections `## Breaking`, `## Added`, `## Changed`, `## Deprecated`, `## Removed` and `## Fixed`:

```md
## Breaking

- Removed the deprecated `qux` keyword.

## Fixed

- Fixed `foo` erroring on empty input.
```

Each entry starts with `- `, indented lines continue the previous entry, and blank lines are ignored. Nothing else is allowed. Entries before the first heading are unsectioned. Do not add the PR link, it is appended automatically.

When a new version is tagged, `tooling/bump_versions.jl` collects all entries, newest PR first, into a new section of `CHANGELOG.md` and deletes the files. Unsectioned entries come first, followed by one `###` subsection per section in the order listed above. CI checks that a PR adds a file named after its own number unless the `skip-changelog` label is set, and validates all entries with `julia tooling/changelog.jl check`.
