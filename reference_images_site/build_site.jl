using Revise
using ReferenceUpdater
using Bonito
using BonitoSites

# Get the PR number from environment
pr_number = parse(Int, get(ENV, "PR_NUMBER", "1"))
@info "Building reference images site for PR $pr_number"

# Path to the downloaded artifact data
root_path = joinpath(@__DIR__, "..", "reference_images_data")
@info "Using reference images from: $root_path"

# Verify the data exists
if !isdir(root_path)
    @error "Reference images directory not found at $root_path"
    exit(1)
end
# Create the ReferenceUpdater app
@info "Creating ReferenceUpdater app..."
app = ReferenceUpdater.serve_update_page_from_dir(root_path)

# Set up output directory
build_dir = joinpath(@__DIR__, "build")
mkpath(build_dir)

# Create routes for the app
routes = Routes("/" => app)
# Export the static site
@info "Exporting static site..."
Bonito.export_static(build_dir, routes)

BonitoSites.deploy(
    ENV["GITHUB_REPOSITORY"];
    target = build_dir,
    subfolder = "reference_images/PR$pr_number",
    push_preview = true,
    devbranch = "master",
)
