This module contains functions for running reference image tests, computing image different scores, and comparing as well as updating newly created images.

To compare images from the last commit in a PR, or a specific commit, you can use `ReferenceImages.serve_update_page()`.
You need to have the environment variable `GITHUB_TOKEN` set to a token that has the correct access rights in the Makie repository to read and write artifacts.

Here's an example:

```julia
using Pkg
Pkg.activate("MAKIE_FOLDER/ReferenceTests")

using ReferenceTests

ReferenceTests.serve_update_page(pr = 1234)
# or ReferenceTests.serve_update_page(commit = "a1b2c3")
```

You should be given a choice of different backend workflow runs.
Choose one (usually GLMakie when updating reference images) and confirm.
If reference images can be found for this run, they will be downloaded and extracted to a temp directory.
(You can run `ReferenceTests.serve_update_page_from_dir(joinpath(the_temp_dir, reference_set_name))` to restart the process without reloading the zip file.)
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
