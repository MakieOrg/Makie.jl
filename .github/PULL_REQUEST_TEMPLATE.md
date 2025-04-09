<!--
* Any PR that is not ready for review should be created as a draft PR.
* Please don't force push to PRs, it removes the history, creates bad notifications, and we will squash and merge in the end anyways.
* Feel free to ping for a review when it passes all tests after a few days (@simondanisch, @ffreyer). We can't guarantee a review in a certain time frame, but we can guarantee to forget about PRs after a while.
* Allowing write access on the PR makes things more convenient, since we can make edits to the PR directly and update it if it gets out of sync with `master` (should be automatic if not disabled).
* Please understand, that some PRs will take very long to get merged. You can do a few things to optimize the time to get it merged:
    * The more tests you add, the easier it is to see that your change works without putting the work on us.
    * The clearer the problem being solved the easier. A PR best only addresses one bug fix or feature.
    * The more you explain the motivation or describe your feature (best with pictures), the easier it will be for us to priorize the PR.
    * Changes with more ambigious benefits are best discussed in a github [discussion](https://github.com/MakieOrg/Makie.jl/discussions) before a PR.
* What deserves a unit test or a reference image test isn't easy to decide, but here are a few pointers:
   * Makie unit tests are preferable, since they're fast to execute and easy to maintain, so if you can add tests to `Makie/src/test`
   * For new recipes or any changes that may get rendered differently by the backends, one should add a reference image test to the best fitting file in `Makie\ReferenceTests\src\tests\**` looking like this:
   ```julia 
   @reference_test "name of test" begin
        # code of test
        ...
        # make sure the last line is a Figure, FigureAxisPlot or Scene
    end
    ``` 
    Adding a reference image test will let your PR fail with the status "n reference images missing", which a maintainer will need to approve and fix. 
    Ideally, a comment with a screenshot of the expected output of the reference image test should be added to the PR.
    We prefer one reference image test with many subplots over multiple reference image tests.
-->
# Description

Fixes # (issue)

Add a description of your PR here.

## Type of change

Delete options that do not apply:

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)

## Checklist

- [ ] Added an entry in CHANGELOG.md (for new features and breaking changes)
- [ ] Added or changed relevant sections in the documentation
- [ ] Added unit tests for new algorithms, conversion methods, etc.
- [ ] Added reference image tests for new plotting functions, recipes, visual options, etc.
