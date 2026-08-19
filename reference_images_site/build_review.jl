using ReferenceUpdater
using Bonito

root_path = joinpath(@__DIR__, "..", "reference_images_data")
if !isdir(root_path)
    @error "Reference images directory not found at $root_path"
    exit(1)
end

build_dir = joinpath(@__DIR__, "review")
rm(build_dir; force = true, recursive = true)
mkpath(build_dir)

backends = ["GLMakie", "CairoMakie", "WGLMakie"]
thresholds = [0.05, 0.03, 0.01]

inert = ReferenceUpdater.classify_entries(
    ReferenceUpdater.read_manifest(joinpath(root_path, "refimage_updates")),
    joinpath(root_path, "reference")
).inert
isempty(inert) || @info "Ignoring $(length(inert)) inert pin file(s) (their reference changed since the pin was taken):\n" *
    join(("  " * e.path for e in inert), '\n')

app = Bonito.App(_ -> ReferenceUpdater.review_content(root_path, backends, thresholds))
Bonito.export_static(joinpath(build_dir, "index.html"), app)
@info "Self-contained review page written to $build_dir"

coverage = ReferenceUpdater.approval_coverage(root_path)
state = coverage.n_approved == coverage.n_changed ? "success" : "failure"
@info "Approval coverage: $(coverage.n_approved)/$(coverage.n_changed) approved (state=$state)"
if haskey(ENV, "GITHUB_OUTPUT")
    open(ENV["GITHUB_OUTPUT"], "a") do io
        println(io, "n_changed=", coverage.n_changed)
        println(io, "n_approved=", coverage.n_approved)
        println(io, "state=", state)
    end
end
