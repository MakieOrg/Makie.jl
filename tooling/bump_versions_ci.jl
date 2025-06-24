#!/usr/bin/env julia

"""
CI script for bumping package versions via GitHub Actions.

Usage:
    julia bump_versions_ci.jl <bump_type> [packages] [update_changelog]

Arguments:
    bump_type: "patch", "minor", or "major"
    packages: Comma-separated list of packages (optional, defaults to auto-detection)
    update_changelog: "true" or "false" (optional, defaults to "true")

Examples:
    julia bump_versions_ci.jl patch
    julia bump_versions_ci.jl minor "Makie,CairoMakie" true
    julia bump_versions_ci.jl major "" false
"""

include("bump_versions.jl")

function run_git_command(cmd::Cmd; capture_output::Bool = false, allow_failure::Bool = false)
    println("🔧 Running: $cmd")
    return try
        if capture_output
            return read(cmd, String)
        else
            run(cmd)
            return nothing
        end
    catch e
        if allow_failure
            @warn "Git command failed (allowed): $cmd"
            @warn "Error: $e"
            return capture_output ? "" : nothing
        else
            error("Git command failed: $cmd\nError: $e")
        end
    end
end

function create_feature_branch(bump_type::String)
    # Generate branch name with timestamp
    timestamp = Dates.format(Dates.now(), "yyyymmdd-HHMMSS")
    branch_name = "bump-versions-$bump_type-$timestamp"

    println("🌿 Creating feature branch: $branch_name")
    run_git_command(`git checkout -b $branch_name`)

    return branch_name
end

function check_for_changes()
    # Check if there are any changes
    diff_output = run_git_command(`git diff --name-only`; capture_output = true)
    has_changes = !isempty(strip(diff_output))

    if has_changes
        println("📝 Changes detected:")
        changed_files = String.(split(strip(diff_output), '\n'))  # Convert to Vector{String}
        for file in changed_files
            println("  - $file")
        end
    else
        println("ℹ️  No changes detected")
        changed_files = String[]  # Empty Vector{String}
    end

    return has_changes, changed_files
end

function commit_and_push_changes(branch_name::String, bump_type::String, packages_str::String, update_changelog::Bool)
    println("💾 Committing changes...")

    # Add all changes from repository root (not just current directory)
    run_git_command(`git add -A`)

    # Create commit message
    packages_desc = isempty(packages_str) ? "auto-detected" : packages_str
    commit_msg = """Bump package versions ($bump_type)

    - Bump type: $bump_type
    - Packages: $packages_desc
    - Update changelog: $update_changelog

    🤖 Generated with GitHub Actions"""

    # Commit changes
    run_git_command(`git commit -m $commit_msg`)

    # Push branch
    println("📤 Pushing branch to origin...")
    return run_git_command(`git push origin $branch_name`)
end

function create_pull_request(branch_name::String, bump_type::String, packages_str::String, update_changelog::Bool, changed_files::Vector{String})
    println("🔄 Creating pull request...")

    # Get commit SHA for PR body (for potential future use)
    # commit_sha = strip(run_git_command(`git rev-parse HEAD`; capture_output=true))

    # Create PR title
    pr_title = "Bump package versions ($bump_type)"

    # Create PR body
    packages_desc = isempty(packages_str) ? "auto-detected based on git changes" : packages_str
    files_list = join(["- $file" for file in changed_files], "\n")

    pr_body = """## Version Bump: $bump_type

    This PR automatically bumps package versions using the bump_versions.jl script.

    ### Configuration
    - **Bump Type**: $bump_type
    - **Packages**: $packages_desc
    - **Update Changelog**: $update_changelog

    ### Files Modified
    $files_list

    ---
    🤖 This PR was automatically created by GitHub Actions

    **Review checklist:**
    - [ ] Version numbers are correct
    - [ ] CHANGELOG.md is properly updated (if enabled)
    - [ ] All package dependencies are consistent
    - [ ] No unintended changes were made"""

    # Check if gh CLI is available
    gh_token = get(ENV, "GITHUB_TOKEN", "")
    if isempty(gh_token)
        @warn "GITHUB_TOKEN not found, cannot create PR automatically"
        println("📋 PR details that would be created:")
        println("Title: $pr_title")
        println("Branch: $branch_name")
        println("Body:")
        println(pr_body)
        return nothing
    end

    # Create PR using gh CLI
    try
        # Write PR body to temp file to handle multiline content
        temp_file = tempname()
        open(temp_file, "w") do io
            write(io, pr_body)
        end

        run_git_command(`gh pr create --title $pr_title --body-file $temp_file --head $branch_name --base master`)

        # Clean up temp file
        rm(temp_file)

        # Get PR URL
        pr_url = strip(run_git_command(`gh pr view --json url --jq .url`; capture_output = true))
        println("✅ Pull request created: $pr_url")

        return pr_url
    catch e
        @warn "Failed to create PR automatically: $e"
        println("📋 You can create the PR manually with these details:")
        println("Title: $pr_title")
        println("Branch: $branch_name")
        println("Body:")
        println(pr_body)
        return nothing
    end
end

function parse_packages_arg(packages_str::String)
    if isempty(packages_str) || packages_str == "\"\""
        return String[]
    end

    # Remove quotes if present
    packages_str = strip(packages_str, ['"', '\''])

    # Split by comma and clean up whitespace
    packages = String[]
    for pkg in split(packages_str, ',')
        pkg_clean = strip(pkg)
        if !isempty(pkg_clean)
            push!(packages, pkg_clean)
        end
    end

    return packages
end

function parse_bool_arg(bool_str::String, default::Bool = true)
    bool_str = lowercase(strip(bool_str))
    if bool_str in ["true", "1", "yes", "y"]
        return true
    elseif bool_str in ["false", "0", "no", "n"]
        return false
    else
        @warn "Invalid boolean value '$bool_str', using default: $default"
        return default
    end
end

function main()
    if length(ARGS) < 1
        println(stderr, "Error: bump_type is required")
        println(
            stderr, """
            CI script for bumping package versions via GitHub Actions.

            Usage:
                julia bump_versions_ci.jl <bump_type> [packages] [update_changelog]

            Arguments:
                bump_type: "patch", "minor", or "major"
                packages: Comma-separated list of packages (optional, defaults to auto-detection)
                update_changelog: "true" or "false" (optional, defaults to "true")

            Examples:
                julia bump_versions_ci.jl patch
                julia bump_versions_ci.jl minor "Makie,CairoMakie" true
                julia bump_versions_ci.jl major "" false
            """
        )
        exit(1)
    end

    # Parse arguments
    bump_type = ARGS[1]
    packages_str = length(ARGS) >= 2 ? ARGS[2] : ""
    update_changelog_str = length(ARGS) >= 3 ? ARGS[3] : "true"

    # Validate bump_type
    if bump_type ∉ ["patch", "minor", "major"]
        println(stderr, "Error: bump_type must be 'patch', 'minor', or 'major', got: '$bump_type'")
        exit(1)
    end

    # Parse packages
    packages = parse_packages_arg(packages_str)

    # Parse update_changelog
    update_changelog = parse_bool_arg(update_changelog_str)

    # Print configuration
    println("🚀 Running version bump workflow with configuration:")
    println("  bump_type: $bump_type")
    println("  packages: $(isempty(packages) ? "auto-detected" : join(packages, ", "))")
    println("  update_changelog: $update_changelog")
    println()

    return try
        # Step 1: Create feature branch
        branch_name = create_feature_branch(bump_type)

        # Step 2: Run version bump
        println("📦 Running version bump...")
        bump_versions(
            bump_type,
            packages = packages,
            up_changelog = update_changelog
        )

        # Step 3: Check for changes
        println()
        has_changes, changed_files = check_for_changes()

        if !has_changes
            println("ℹ️  No version changes were needed.")
            println("   This typically means no packages have source changes since the last version tag.")
            return
        end

        # Step 4: Commit and push changes
        commit_and_push_changes(branch_name, bump_type, packages_str, update_changelog)

        # Step 5: Create pull request
        pr_url = create_pull_request(branch_name, bump_type, packages_str, update_changelog, changed_files)

        # Final summary
        println()
        println("✅ Version bump workflow completed successfully!")
        println("🌿 Branch: $branch_name")
        if pr_url !== nothing
            println("📝 Pull Request: $pr_url")
        end
        println()
        println("Next steps:")
        println("  1. Review the created pull request")
        println("  2. Ensure all version numbers are correct")
        println("  3. Verify CHANGELOG.md updates (if enabled)")
        println("  4. Merge the PR when ready")

    catch e
        println(stderr, "❌ Error during version bump workflow:")
        println(stderr, e)
        if isa(e, InterruptException)
            println(stderr, "Process was interrupted")
        else
            # Print stack trace for debugging
            println(stderr, "Stack trace:")
            for (exc, bt) in Base.catch_stack()
                showerror(stderr, exc, bt)
                println(stderr)
            end
        end
        exit(1)
    end
end

# Run main function if script is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
