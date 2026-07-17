# ReferenceUpdater

This module contains functions to inspect test image artifacts from PRs and commits, as well as update reference images.

You can compare images from the last commit in a PR, or a specific commit.
You need to have the environment variable `GITHUB_TOKEN` set to a token that has the correct access rights in the Makie repository to read and write artifacts.

```julia
ReferenceUpdater.serve_update_page(commit = "a1b2c3")
ReferenceUpdater.serve_update_page(pr = 1234)
```

## Updating reference images via the manifest (recommended)

A PR that changes rendering should not upload to the release tarball directly (that turns master and every other open PR red until it lands). Instead it records the images it intends to update in `ReferenceTests/refimage_updates/`, a directory holding one small fragment file per image: `<Backend>/<name>.png.pin`, whose content is the pin (the sha256 of the reference it replaces, or `new`/`delete`). One file per image means concurrent PRs touching different images never edit the same file, so they don't conflict on merge (a shared single-file manifest would). A CairoMakie-only change writes only `CairoMakie/...` fragments. CI exempts a listed image from the score/missing checks while the pinned hash still matches, so the PR goes green for exactly its declared changes. When the PR merges through the GitHub merge queue, the `merge_group` CI run promotes the recorded images into the `refimages-vX.Y` release; the entries then go inert, and generating a new manifest prunes them (deletes the stale fragment files).

Add entries in one of three ways (none require running the backend tests locally):

- Viewer button: run `ReferenceUpdater.serve_update_page(pr = 1234)`, select the images, and click "Add selection to update manifest".
- Headless (agents): `ReferenceUpdater.add_pr_updates_to_manifest(1234)` picks every image whose score exceeds the threshold plus every new image; pass `select = ["CairoMakie/foo.png", ...]` to choose explicitly. Pins come from the current release tarball, the changed/new classification from the PR's CI artifact.
- CLI: `reference_updater manifest pr 1234` (or `manifest commit <sha>`).

To promote into a different release tag (e.g. `refimages-v0.26` for a breaking-release branch), enable the merge queue on that branch and add its ref to the `promote-refimages` allowlist in `.github/workflows/ci.yml`; the tag follows `Makie/Project.toml`, and the branch should have its `refimages-vX.Y` release seeded (e.g. copied from the previous minor).

The direct-upload button below remains for maintainers who need to overwrite a release tarball immediately.

You can also install ReferenceUpdater as an app in Julia 1.12 and up using `]app dev path/to/ReferenceUpdater`. Then you can access the functionality directly from the command line (given that the Julia app binary folder is on your path) via:

```
reference_updater commit a1b2c3
reference_updater pr 1234
```

Locally, tests are recorded inside the backends test folder, which can also be used to server a reference page.
E.g., to see the results after running `]test WGLMakie` you can run:

```julia
using ReferenceUpdater
ReferenceUpdater.serve_update_page_from_dir("Makie/WGLMakie/test/reference_images/")
```
`ReferenceUpdater` is an unregistered package which is located in the Makie monorepo.  To add it, run `Pkg.dev(joinpath(dirname(dirname(pathof(Makie))), "ReferenceUpdater"))`, assuming that you've `dev`'ed Makie.
You should be given a choice of different backend workflow runs.
Choose one (usually GLMakie when updating reference images) and confirm.
If reference images can be found for this run, they will be downloaded and extracted to a temp directory.
(You can run `ReferenceUpdater.serve_update_page_from_dir(joinpath(the_temp_dir, reference_set_name))` to restart the process without reloading the zip file.)
A server should start at localhost:8000 and when you open this page in the browser, you should see a list of new reference images (which can be empty), and a list of updated images.
The updated images can be compared with the reference via button press.
Checking the box next to an image marks this image for a reference image update.

Once you have checked all images you want to update, you can press the update button at the top.
You will be asked for a tag to store the reference images under, by default this will be the last major tag of Makie and overwrite the old images without undo, so be sure you really want to update them.
Once you press confirm, you should go back to the Julia REPL and check that the upload finishes correctly.
After that (or if you want to abort the process somewhere in between) you need to ctrl+c to quit the web server.

Note that the reference images are updated with the reference image set used for comparison in the specific PR run with whatever new images you selected.
However, if the PR run is older than the latest set of reference images, you would overwrite the new images with the old ones.
You should rerun CI first so you compare against the latest set of reference images.
