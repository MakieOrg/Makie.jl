# Contribution guidelines for Makie

## Issues

Issues should be used to report bugs, regressions, missing documentation or other things we can act on. 
For questions, feature requests, planning and other open ended posts, please use [Discussions](https://github.com/MakieOrg/Makie.jl/discussions).

Before filing an issue please
- check that there are no similar existing issues already (feel free to bump an existing one)
- check that your versions are up to date
  - you can do this by forcing the latest version using `]add Makie@newest-version`, where `newest-version` can be found on the [releases page](https://github.com/MakieOrg/Makie.jl/releases).

When filing an issue, please use one of the templates we provide and follow the given instructions.

## Pull requests

We always appreciate pull requests that fix bugs, add tests, improve documentation or add new features.
Please describe the intent of your pull request clearly and keep a clean commit history as far as possible.

For each feature you want to contribute, please file a separate PR to keep the complexity down and time to merge short.
Add PRs in draft mode if you want to discuss your approach first.

Please add tests for any new functionality that you want to add.
Makie uses both reference tests that check for visual regressions, and unit tests that check correctness of functions etc.
It is also appreciated if you add docstrings or documentation, and add an entry to the NEWS file.

### Tests

Please ensure locally that your feature works by running the tests.
To be able to run the tests, you have to `dev` the helper package `ReferenceTests` that is part of the Makie monorepo.
`ReferenceTests` is not a registered package, so you have to do `]dev path/to/ReferenceTests`.

After that you should be able to run the tests via the usual `]test` commands.

## Seeking Help

If you get stuck, here are some options to seek help:

- Use the REPL `?` help mode.
- Click this link to open a preformatted topic on the [Julia Discourse Page](https://discourse.julialang.org/new-topic?title=Makie%20-%20Your%20question%20here&category=domain/viz&tags=Makie&body=You%20can%20write%20your%20question%20in%20this%20space.%0A%0ABefore%20asking%2C%20please%20take%20a%20minute%20to%20make%20sure%20that%20you%20have%20installed%20the%20latest%20available%20versions%20and%20have%20looked%20at%20%5Bthe%20most%20recent%20documentation%5D(http%3A%2Fmakie.juliaplots.org%2Fstable%2F)%20%3Ainnocent%3A). If you do this manually, please use the category Domain/Visualization and tag questions with `Makie` to increase their visibility.
- For casual conversation about Makie and its development, have a look at the `#makie` channel in the [Julia Slack group](https://julialang.org/slack/). Please direct your usage questions to [Discourse](https://discourse.julialang.org/new-topic?title=Makie%20-%20Your%20question%20here&category=domain/viz&tags=Makie&body=You%20can%20write%20your%20question%20in%20this%20space.%0A%0ABefore%20asking%2C%20please%20take%20a%20minute%20to%20make%20sure%20that%20you%20have%20installed%20the%20latest%20available%20versions%20and%20have%20looked%20at%20%5Bthe%20most%20recent%20documentation%5D(http%3A%2Fmakie.juliaplots.org%2Fstable%2F)%20%3Ainnocent%3A) and not to Slack, to make questions and answers accessible to everybody.
