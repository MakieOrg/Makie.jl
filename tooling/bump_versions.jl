using REPL.TerminalMenus
using TOML
using Pkg
using Dates

dictmap(f, d) = Dict(key => f(key, value) for (key, value) in d)

bump_patch(v::VersionNumber) = VersionNumber(v.major, v.minor, v.patch + 1)
bump_minor(v::VersionNumber) = VersionNumber(v.major, v.minor + 1, 0)
bump_major(v::VersionNumber) = VersionNumber(v.major + 1, 0, 0)

function update_changelog(new_version::VersionNumber, root::String)
    changelog_path = joinpath(root, "CHANGELOG.md")

    # Read all lines
    all_lines = readlines(changelog_path)

    # Find the index of "## Unreleased"
    unreleased_idx = findfirst(line -> startswith(line, "## Unreleased"), all_lines)
    if unreleased_idx === nothing
        @warn "Could not find '## Unreleased' section in CHANGELOG.md"
        return
    end

    # Create new version header with current date
    current_date = Dates.format(Dates.today(), "yyyy-mm-dd")
    new_version_header = "## [$new_version] - $current_date"

    # Replace "## Unreleased" with the new version header and add new "## Unreleased"
    new_lines = copy(all_lines)
    new_lines[unreleased_idx] = new_version_header
    insert!(new_lines, unreleased_idx, "## Unreleased")
    insert!(new_lines, unreleased_idx + 1, "")  # Add empty line after "## Unreleased"

    # Find link section and update it
    link_start_idx = findfirst(i -> match(r"^\[[\d\.]+\]:\s*https://", all_lines[i]) !== nothing, 1:length(all_lines))
    if link_start_idx !== nothing
        # Find the most recent version from existing links to create the new diff link
        existing_versions = String[]
        for i in link_start_idx:length(all_lines)
            link_match = match(r"^\[(\d+\.\d+\.\d+)\]:", all_lines[i])
            if link_match !== nothing
                push!(existing_versions, link_match.captures[1])
            end
        end

        if !isempty(existing_versions)
            # The first version in the list should be the previous version
            prev_version = existing_versions[1]
            new_link = "[$new_version]: https://github.com/MakieOrg/Makie.jl/compare/v$prev_version...v$new_version"

            # Insert the new link at the beginning of the link section
            new_link_idx = findfirst(i -> match(r"^\[[\d\.]+\]:\s*https://", new_lines[i]) !== nothing, 1:length(new_lines))
            if new_link_idx !== nothing
                insert!(new_lines, new_link_idx, new_link)
            end
        end
    end

    # Update the [Unreleased] link to point to the new version
    unreleased_link_idx = findfirst(i -> match(r"^\[Unreleased\]:\s*https://", new_lines[i]) !== nothing, 1:length(new_lines))
    if unreleased_link_idx !== nothing
        new_lines[unreleased_link_idx] = "[Unreleased]: https://github.com/MakieOrg/Makie.jl/compare/v$new_version...HEAD"
    end

    # Write the updated changelog
    open(changelog_path, "w") do io
        for line in new_lines
            println(io, line)
        end
    end

    return println("Updated CHANGELOG.md with version $new_version")
end

function bump_versions(
        bump_type::String = "patch";

        packages::Vector{String} = String[],
        custom_bumps::Dict{String, String} = Dict{String, String}(),
        up_changelog::Bool = true
    )
    names = ["ComputePipeline", "Makie", "CairoMakie", "GLMakie", "WGLMakie", "RPRMakie"]
    paths = names

    package_paths = Dict(names .=> paths)
    root = normpath(joinpath(@__DIR__, ".."))
    return cd(root) do
        tomlpaths = dictmap(package_paths) do _, dir
            normpath(joinpath(root, dir, "Project.toml"))
        end
        tomls = dictmap(tomlpaths) do _, tomlfile
            TOML.parsefile(tomlfile)
        end

        versions = dictmap(tomls) do _, toml
            VersionNumber(toml["version"])
        end

        # Determine which packages to bump
        if isempty(packages)
            # Auto-detect based on git changes
            current_version = versions["Makie"]
            current_tag = "v$current_version"

            # Check if we're in a git repository and tag exists
            println("Checking for changes since tag: $current_tag")

            # First verify the tag exists
            tag_verify_cmd = `git rev-parse --verify $current_tag`
            try
                run(tag_verify_cmd)
            catch e
                error("Git tag verification failed. Command: $tag_verify_cmd\nError: $e\n\nPlease ensure the tag '$current_tag' exists in your repository.")
            end

            src_changes = dictmap(package_paths) do _, dir
                srcdir = joinpath(root, dir, "src")
                diff_cmd = `git diff $current_tag HEAD --stat -- $srcdir`
                try
                    println("Running: $diff_cmd")
                    read(diff_cmd, String)
                catch e
                    error("Git diff command failed. Command: $diff_cmd\nError: $e\n\nYou can run this command manually to debug.")
                end
            end

            has_changed_src = dictmap((key, changes) -> !isempty(changes), src_changes)

            packages = names[
                findall(
                    map(names) do name
                        if has_changed_src["Makie"]
                            name != "ComputePipeline"
                        else
                            has_changed_src[name]
                        end
                    end
                ),
            ]
        end

        # Apply dependency rules
        if "ComputePipeline" in packages
            if !isempty(setdiff(names[2:end], packages))
                @warn "Because ComputePipeline is bumped, all other packages will be bumped as well."
                packages = names
            end
        elseif "Makie" in packages
            if !isempty(setdiff(names[4:end], packages))
                @warn "Because Makie is bumped, all backend packages will be bumped as well."
                packages = union(packages, names[3:end])
            end
        end

        # Calculate new versions
        new_versions = Dict{String, VersionNumber}()
        for package in packages
            current_version = versions[package]

            # Use custom bump type if specified, otherwise use default
            package_bump_type = get(custom_bumps, package, bump_type)

            new_version = if package_bump_type == "patch"
                bump_patch(current_version)
            elseif package_bump_type == "minor"
                bump_minor(current_version)
            elseif package_bump_type == "major"
                bump_major(current_version)
            else
                error("Invalid bump type: $package_bump_type. Must be patch, minor, or major")
            end

            new_versions[package] = new_version
        end

        # Update TOML files
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

        # Update CHANGELOG.md if Makie version was bumped and update_changelog is true
        if up_changelog && haskey(new_versions, "Makie")
            update_changelog(new_versions["Makie"], root)
        end
        println("Done")
        return
    end
end

function bump_versions_interactive()
    names = ["ComputePipeline", "MakieCore", "Makie", "CairoMakie", "GLMakie", "WGLMakie", "RPRMakie"]
    paths = map(names) do name
        name == "Makie" ? "." : name
    end

    package_paths = Dict(names .=> paths)
    root = joinpath(@__DIR__, "..")

    tomlpaths = dictmap(package_paths) do _, dir
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

    # First verify the tag exists
    tag_verify_cmd = `git rev-parse --verify $current_tag`
    try
        run(tag_verify_cmd)
    catch e
        error("Git tag verification failed. Command: $tag_verify_cmd\nError: $e\n\nPlease ensure the tag '$current_tag' exists in your repository.")
    end

    src_changes = dictmap(package_paths) do _, dir
        srcdir = joinpath(root, dir, "src")
        diff_cmd = `git diff $current_tag HEAD --stat -- $srcdir`
        try
            println("Running: $diff_cmd")
            read(diff_cmd, String)
        catch e
            error("Git diff command failed. Command: $diff_cmd\nError: $e\n\nYou can run this command manually to debug.")
        end
    end

    has_changed_src = dictmap((key, changes) -> !isempty(changes), src_changes)

    selected = findall(
        map(names) do name
            if has_changed_src["MakieCore"]
                true
            elseif has_changed_src["Makie"]
                name != "MakieCore"
            else
                has_changed_src[name]
            end
        end
    )

    println("Which packages' versions do you want to bump? All packages with nonempty git diffs in their `src` directory are preselected, or those who depend on others that have changes.")
    bumps_requested = request(MultiSelectMenu(names; selected))
    selected_packages = names[bumps_requested]

    println("How do you want to bump the versions:")
    version_selection = request(RadioMenu(["All patch", "All minor", "All major", "Custom"]))

    if version_selection == 4
        # Custom bumping
        custom_bumps = Dict{String, String}()
        for package in selected_packages
            version = versions[package]
            v_patch = bump_patch(version)
            v_minor = bump_minor(version)
            v_major = bump_major(version)
            println("How do you want to bump $package (currently $version)?")
            bump_choice = request(RadioMenu(["Patch ($v_patch)", "Minor ($v_minor)", "Major ($v_major)"]))
            custom_bumps[package] = ["patch", "minor", "major"][bump_choice]
        end

        return bump_versions(packages = selected_packages, custom_bumps = custom_bumps)
    else
        # Uniform bumping
        bump_type = ["patch", "minor", "major"][version_selection]
        return bump_versions(bump_type; packages = selected_packages)
    end
end

# bump_versions_interactive()

# bump_versions()
