function minorversionstring(folder::String)
    v = try
        VersionNumber(folder)
    catch
        folder
    end
    if v isa VersionNumber
        return "v$(v.major).$(v.minor)"
    else
        return folder
    end
end

function deployparameters(; repo, push_preview, devbranch, devurl)
    cfg = Documenter.GitHubActions()
    deploy_decision = Documenter.deploy_folder(cfg; repo, push_preview, devbranch, devurl)
    (;
        all_ok = deploy_decision.all_ok,
        branch = deploy_decision.branch,
        repo = deploy_decision.repo,
        subfolder = minorversionstring(deploy_decision.subfolder), # this is the main change from Documenter's version
        is_preview = deploy_decision.is_preview,
        config = cfg,
    )
end

function deploy(params; root = Documenter.Utilities.currentdir(), target)
    if !params.all_ok
        @warn "Deploy decision status not all ok. Not deploying."
        return
    end

    deploy_branch = params.branch
    deploy_repo = params.repo

    # Change to the root directory and try to deploy the docs.
    cd(root) do
        sha = readchomp(`$(Documenter.git()) rev-parse --short HEAD`)
        
        @debug "pushing new documentation to remote: '$deploy_repo:$deploy_branch'."
        mktempdir() do temp
            push_build(;
                root,
                temp,
                target,
                params.repo,
                params.branch,
                params.subfolder,
                params.is_preview,
                sha,
                params.config,
            )
        end
    end
end

function push_build(;
        root, temp, repo,
        branch="gh-pages", dirname="", target="site", sha="",
        config, subfolder,
        is_preview::Bool
    )
    dirname = isempty(dirname) ? temp : joinpath(temp, dirname)
    isdir(dirname) || mkpath(dirname)

    target_dir = abspath(target)

    git = Documenter.git

    NO_KEY_ENV = Dict(
        "DOCUMENTER_KEY" => nothing,
        "DOCUMENTER_KEY_PREVIEWS" => nothing,
    )

    # Generate a closure with common commands for ssh and https
    function git_commands(sshconfig=nothing)
        # Setup git.
        run(`$(git()) init`)
        run(`$(git()) config user.name "Documenter.jl"`)
        run(`$(git()) config user.email "documenter@juliadocs.github.io"`)
        if sshconfig !== nothing
            run(`$(git()) config core.sshCommand "ssh -F $(sshconfig)"`)
        end

        # Fetch from remote and checkout the branch.
        run(`$(git()) remote add upstream $upstream`)
        try
            run(`$(git()) fetch upstream`)
        catch e
            @error """
            Git failed to fetch $upstream
            This can be caused by a DOCUMENTER_KEY variable that is not correctly set up.
            Make sure that the environment variable is properly set up as a Base64-encoded string
            of the SSH private key. You may need to re-generate the keys with DocumenterTools.
            """
            rethrow(e)
        end

        try
            run(`$(git()) checkout -b $branch upstream/$branch`)
        catch e
            @info """
            Checking out $branch failed, creating a new orphaned branch.
            This usually happens when deploying to a repository for the first time and
            the $branch branch does not exist yet. The fatal error above is expected output
            from Git in this situation.
            """
            @debug "checking out $branch failed with error: $e"
            run(`$(git()) checkout --orphan $branch`)
            run(`$(git()) commit --allow-empty -m "Initial empty commit for docs"`)
        end

        # Copy docs to `subfolder` directory.
        deploy_dir = subfolder === nothing ? dirname : joinpath(dirname, subfolder)
        gitrm_copy(target_dir, deploy_dir)

        open(joinpath(deploy_dir, "siteinfo.js"), "w") do io
            println(io, """
            var DOCUMENTER_CURRENT_VERSION = "$subfolder";
            """)
        end

        max_version = sort!(filter([x for x in readdir(dirname) if isdir(joinpath(dirname, x))]) do x
            tryparse(VersionNumber, x) !== nothing
        end, by = VersionNumber)[end]

        open(joinpath(dirname, "versions.js"), "w") do io
            println(io, """
            var DOCUMENTER_NEWEST = "$max_version";
            var DOCUMENTER_STABLE = "stable";
            """)
        end

        stablelink = joinpath(dirname, "stable")
        if isfile(stablelink)
            rm(stablelink)
        end
        symlink(joinpath(dirname, max_version), stablelink, dir_target = true)

        # Add, commit, and push the docs to the remote.
        run(`$(git()) add -A .`)
        if !success(`$(git()) diff --cached --exit-code`)
            run(`$(git()) commit -m "build based on $sha"`)
            run(`$(git()) push -q upstream HEAD:$branch`)
        else
            @debug "new docs identical to the old -- not committing nor pushing."
        end
    end

    # Get the parts of the repo path and create upstream repo path
    user, host, upstream = Documenter.user_host_upstream(repo)

    keyfile = abspath(joinpath(root, ".documenter"))
    try
        keycontent = Documenter.documenter_key(config)
        write(keyfile, Documenter.base64decode(keycontent))
    catch e
        @error """
        Documenter failed to decode the DOCUMENTER_KEY environment variable.
        Make sure that the environment variable is properly set up as a Base64-encoded string
        of the SSH private key. You may need to re-generate the keys with DocumenterTools.
        """
        rm(keyfile; force=true)
        rethrow(e)
    end
    chmod(keyfile, 0o600)

    try
        mktemp() do sshconfig, io
            print(io,
            """
            Host $host
                StrictHostKeyChecking no
                User $user
                HostName $host
                IdentityFile "$keyfile"
                IdentitiesOnly yes
                BatchMode yes
            """)
            close(io)
            chmod(sshconfig, 0o600)
            # git config core.sshCommand requires git 2.10.0, but
            # GIT_SSH_COMMAND works from 2.3.0 so define both.
            withenv("GIT_SSH_COMMAND" => "ssh -F $(sshconfig)", NO_KEY_ENV...) do
                cd(() -> git_commands(sshconfig), temp)
            end
        end
        Documenter.post_status(config; repo=repo, type="success", subfolder=subfolder)
    catch e
        @error "Failed to push:" exception=(e, catch_backtrace())
        Documenter.post_status(config; repo=repo, type="error")
        rethrow(e)
    finally
        # Remove the unencrypted private key.
        isfile(keyfile) && rm(keyfile)
    end
end