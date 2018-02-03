using Documenter, Makie
cd(Pkg.dir("Makie", "docs"))
makedocs(
    modules = [Makie],
    format = :html,
    sitename = "Plotting in pure Julia",
    pages = [
        "Home" => "index.md",
        "Basics" => [
            "scene.md",
            "conversions.md",
            "functions.md",
            "documentation.md",
            "backends.md",
            "extending.md",
            "themes.md",
            "interaction.md",
            "axis.md",
            "legends.md",
            "output.md",
            "reflection.md",
            "layout.md"
        ],
        "Developper Documentation" => [
            "devdocs.md",
        ],
    ]
)

ENV["TRAVIS_BRANCH"] = "latest"
ENV["TRAVIS_PULL_REQUEST"] = "false"
ENV["TRAVIS_REPO_SLUG"] = "github.com/SimonDanisch/MakieDocs.git"
ENV["TRAVIS_TAG"] = "tag"
ENV["TRAVIS_OS_NAME"] = "linux"
ENV["TRAVIS_JULIA_VERSION"] = "0.6"

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math", "mkdocs-cinder"),
    repo   = "github.com/SimonDanisch/MakieDocs.git",
    julia  = "0.6",
    target = "build",
    osname = "linux",
    make = nothing
)

function sortperm_int_range2(a, rangelen, minval)
    cnts = fill(0, rangelen)

    # create a count first
    @inbounds for ai in a
        cnts[ai - minval + 1] +=  1
    end

    # create cumulative sum
    cumsum!(cnts, cnts)
end
    la = length(a)
    res = Vector{Int}(la)
    @simd for i in la:-1:1
        @inbounds begin
            ai = a[i] - minval + 1
            c = cnts[ai]
            cnts[ai] -= 1
            res[c] = i
        end
    end
    res
end

# to test the code
rangelen = 1_000_000
minval = 1
a = rand(1:rangelen, 100_000_000)
@time x = sortperm_int_range2(a, rangelen, 1); # 20 seconds; TOO SLOW
