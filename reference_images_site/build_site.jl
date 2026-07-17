using ReferenceUpdater
using Bonito
using BonitoSites

pr_number = parse(Int, get(ENV, "PR_NUMBER", "1"))
@info "Building reference images review page for PR $pr_number"

root_path = joinpath(@__DIR__, "..", "reference_images_data")
if !isdir(root_path)
    @error "Reference images directory not found at $root_path"
    exit(1)
end

build_dir = joinpath(@__DIR__, "build")
mkpath(build_dir)

app = ReferenceUpdater.serve_update_page_from_dir(root_path)
Bonito.export_static(joinpath(build_dir, "index.html"), app)
@info "Self-contained review page written to $build_dir"

BonitoSites.deploy(
    ENV["GITHUB_REPOSITORY"];
    target = build_dir,
    subfolder = "reference_images/PR$pr_number",
    push_preview = true,
    devbranch = "master",
)

coverage = ReferenceUpdater.approval_coverage(root_path)
state = coverage.n_approved == coverage.n_changed ? "success" : "failure"
@info "Approval coverage: $(coverage.n_approved)/$(coverage.n_changed) new/changed images approved via manifest (state=$state)"
if haskey(ENV, "GITHUB_OUTPUT")
    open(ENV["GITHUB_OUTPUT"], "a") do io
        println(io, "n_changed=", coverage.n_changed)
        println(io, "n_approved=", coverage.n_approved)
        println(io, "state=", state)
    end
end
