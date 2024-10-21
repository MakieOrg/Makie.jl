using REPL.TerminalMenus
using TOML
using Pkg

dictmap(f, d) = Dict(key => f(key, value) for (key, value) in d)

bump_patch(v::VersionNumber) = VersionNumber(v.major, v.minor, v.patch+1)
bump_minor(v::VersionNumber) = VersionNumber(v.major, v.minor+1, 0)
bump_major(v::VersionNumber) = VersionNumber(v.major+1, 0, 0)

function bump_versions()

    names = ["MakieCore", "Makie", "CairoMakie", "GLMakie", "WGLMakie", "RPRMakie"]
    paths = map(names) do name
        name == "Makie" ? "." : name
    end

    packages = Dict(names .=> paths)

    root = joinpath(@__DIR__, "..")

    tomlpaths = dictmap(packages) do _, dir
        joinpath(root, dir, "Project.toml")
    end

    tomls = dictmap(tomlpaths) do _, tomlfile
        TOML.parsefile(tomlfile)
    end

    versions = dictmap(tomls) do _, toml
        VersionNumber(toml["version"])
    end
    current_version = versions["Makie"]
    current_tag = "v$current_version"

    src_changes = dictmap(packages) do _, dir
        srcdir = joinpath(root, dir, "src")
        read(`git diff $current_tag HEAD --stat -- $srcdir`, String)
    end

    has_changed_src = dictmap((key, changes) -> !isempty(changes), src_changes)

    selected = findall(map(names) do name
        if has_changed_src["MakieCore"]
            true
        elseif has_changed_src["Makie"]
            name != "MakieCore"
        else
            has_changed_src[name]
        end
    end)

    println("Which packages' versions do you want to bump? All packages with nonempty git diffs in their `src` directory are preselected, or those who depend on others that have changes.")
    bumps_requested = request(MultiSelectMenu(names; selected))

    if 1 in bumps_requested
        if !isempty(setdiff(2:6, bumps_requested))
            @warn "Because MakieCore is bumped, all other packages will be bumped as well."
            union!(bumps_requested, 2:6)
        end
    elseif 2 in bumps_requested
        if !isempty(setdiff(3:6, bumps_requested))
            @warn "Because Makie is bumped, all backend packages will be bumped as well."
            union!(bumps_requested, 3:6)
        end
    end

    println("How do you want to bump the versions:")
    version_selection = request(RadioMenu(["All patch", "All minor", "All major", "Custom"]))

    version_types = map(sort(collect(bumps_requested))) do i
        if version_selection == 4
            name = names[i]
            version = versions[name]
            v_patch = bump_patch(version)
            v_minor = bump_minor(version)
            v_major = bump_major(version)
            println("How do you want to bump $(names[i]) (currently $version)?")
            request(RadioMenu(["Patch ($v_patch)", "Minor ($v_minor)", "Major ($v_major)"]))
        else
            version_selection
        end
    end

    new_versions = Dict(map(zip(bumps_requested, version_types)) do (i, vtype)
        name = names[i]
        version = versions[name]
        new_version = (bump_patch, bump_minor, bump_major)[vtype](version)
        name => new_version
    end)

    for (name, new_version) in new_versions
        new_toml = deepcopy(tomls[name])
        new_toml["version"] = new_version

        compat = new_toml["compat"]
        if haskey(new_versions, "Makie") && haskey(compat, "Makie")
            compat["Makie"] = "=$(new_versions["Makie"])"
        end
        if haskey(new_versions, "MakieCore") && haskey(compat, "MakieCore")
            compat["MakieCore"] = "=$(new_versions["MakieCore"])"
        end

        println("Writing $(tomlpaths[name])")
        open(tomlpaths[name], "w") do io
            Pkg.Types.write_project(io, new_toml)
        end
    end
    println("Done")
end

bump_versions()