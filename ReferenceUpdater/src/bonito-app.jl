using Bonito, DelimitedFiles

include("cross_backend_score.jl")

# ============================================================================
# Global Styles
# ============================================================================

# Color palette
const PRIMARY_COLOR = "#4A90E2"
const SUCCESS_COLOR = "#27AE60"
const WARNING_COLOR = "#F39C12"
const DANGER_COLOR = "#E74C3C"
const BORDER_COLOR = "#E0E0E0"
const BG_LIGHT = "#F8F9FA"
const TEXT_DARK = "#2C3E50"

# Define global CSS classes
const REFIMG_STYLES = Styles(
    # Spinner animation
    CSS(
        "@keyframes spin",
        CSS("from", "transform" => "rotate(0deg)"),
        CSS("to", "transform" => "rotate(360deg)"),
    ),
    # Loading overlay
    CSS(
        ".loading-overlay",
        "position" => "fixed",
        "top" => "0",
        "left" => "0",
        "width" => "100%",
        "height" => "100%",
        "background-color" => "rgba(0,0,0,0.5)",
        "display" => "none",
        "justify-content" => "center",
        "align-items" => "center",
        "z-index" => "9999"
    ),
    CSS(
        ".loading-overlay.active",
        "display" => "flex"
    ),
    CSS(
        ".loading-content",
        "text-align" => "center",
        "background-color" => "white",
        "padding" => "32px 48px",
        "border-radius" => "12px",
        "box-shadow" => "0 8px 32px rgba(0,0,0,0.3)",
        "min-width" => "300px"
    ),
    CSS(
        ".loading-text",
        "color" => TEXT_DARK,
        "font-size" => "18px",
        "font-weight" => "600",
        "margin-bottom" => "24px",
        "margin-top" => "0"
    ),
    # Spinner
    CSS(
        ".spinner",
        "border" => "8px solid #f3f3f3",
        "border-top" => "8px solid $PRIMARY_COLOR",
        "border-radius" => "50%",
        "width" => "60px",
        "height" => "60px",
        "animation" => "spin 1s linear infinite",
        "margin" => "0 auto"
    ),
    # Reference image card
    CSS(
        ".ref-card[data-hidden='true']",
        "display" => "none"
    ),
    # Page header
    CSS(
        ".page-header",
        "padding" => "32px 24px",
        "background" => "linear-gradient(135deg, $PRIMARY_COLOR 0%, #357ABD 100%)",
        "color" => "white",
        "border-radius" => "12px",
        "margin-bottom" => "24px",
        "box-shadow" => "0 4px 16px rgba(0,0,0,0.12)"
    ),
    CSS(
        ".page-title",
        "color" => TEXT_DARK,
        "font-size" => "32px",
        "font-weight" => "800",
        "margin" => "0 0 8px 0"
    ),
    CSS(
        ".page-subtitle",
        "color" => "#546E7A",
        "font-size" => "16px",
        "margin" => "0 0 24px 0"
    ),
    # Section styles
    CSS(
        ".section",
        "padding" => "24px",
        "margin" => "16px 0",
        "background-color" => "white",
        "border-radius" => "12px",
        "box-shadow" => "0 2px 12px rgba(0,0,0,0.06)"
    ),
    CSS(
        ".section-header",
        "color" => TEXT_DARK,
        "font-size" => "24px",
        "font-weight" => "700",
        "margin" => "0 0 12px 0",
        "padding-bottom" => "8px",
        "border-bottom" => "3px solid $PRIMARY_COLOR"
    ),
    CSS(
        ".section-description",
        "color" => "#546E7A",
        "font-size" => "14px",
        "line-height" => "1.6",
        "margin" => "0 0 16px 0"
    ),
    # Filter and controls
    CSS(
        ".filter-label",
        "font-size" => "15px",
        "color" => TEXT_DARK,
        "font-weight" => "600",
        "display" => "flex",
        "align-items" => "center",
        "padding" => "12px",
        "background-color" => BG_LIGHT,
        "border-radius" => "8px",
        "margin-bottom" => "16px"
    ),
    CSS(
        ".filter-label-text",
        "margin-right" => "8px",
        "font-weight" => "600"
    ),
    CSS(
        ".filter-help-text",
        "margin-left" => "8px",
        "color" => "#546E7A",
        "font-size" => "13px"
    ),
    CSS(
        ".sort-controls",
        "margin-top" => "12px",
        "margin-bottom" => "12px"
    ),
    CSS(
        ".sort-info-row",
        "font-size" => "15px",
        "color" => TEXT_DARK,
        "font-weight" => "600",
        "margin-bottom" => "8px",
        "display" => "flex",
        "align-items" => "center"
    ),
    CSS(
        ".sort-button-row",
        "display" => "grid",
        "grid-template-columns" => "1fr 1fr 1fr",
        "gap" => "8px"
    ),
    CSS(
        ".sort-cell",
        "display" => "flex",
        "justify-content" => "center",
        "align-items" => "center"
    ),
    # Upload section
    CSS(
        ".upload-controls",
        "margin" => "16px 0"
    ),
    CSS(
        ".upload-list-header",
        "font-size" => "18px",
        "margin" => "16px 0 8px 0"
    ),
    CSS(
        ".upload-list-header.success",
        "color" => SUCCESS_COLOR
    ),
    CSS(
        ".upload-list-header.danger",
        "color" => DANGER_COLOR
    ),
    CSS(
        ".upload-list",
        "padding-left" => "24px"
    ),
    CSS(
        ".upload-list-item",
        "margin" => "4px 0"
    ),
    # Score badge
    CSS(
        ".score-badge",
        "font-size" => "13px",
        "font-weight" => "600",
        "padding" => "6px 12px",
        "border-radius" => "4px",
        "background-color" => BG_LIGHT,
        "color" => TEXT_DARK,
        "margin" => "4px",
        "display" => "inline-block",
        "float" => "right"
    ),
    # Media elements
    CSS(
        ".media-img",
        "max-width" => "100%",
        "border-radius" => "8px",
        "box-shadow" => "0 2px 6px rgba(0,0,0,0.1)"
    ),
    CSS(
        ".media-video",
        "max-width" => "100%",
        "border-radius" => "8px",
        "box-shadow" => "0 2px 6px rgba(0,0,0,0.1)"
    ),
    # Checkbox styles
    CSS(
        ".checkbox-input",
        "transform" => "scale(1.2)",
        "margin" => "4px 8px 4px 0",
        "cursor" => "pointer"
    ),
    CSS(
        ".checkbox-label",
        "font-size" => "13px",
        "color" => TEXT_DARK,
        "font-weight" => "500",
        "display" => "flex",
        "align-items" => "center",
        "margin-bottom" => "8px"
    ),
    CSS(
        ".checkbox-label-text",
        "margin-left" => "4px"
    ),
    CSS(
        ".toggle-all-checkbox",
        "font-size" => "15px",
        "color" => TEXT_DARK,
        "font-weight" => "600",
        "display" => "flex",
        "align-items" => "center",
        "padding" => "12px",
        "background-color" => BG_LIGHT,
        "border-radius" => "8px",
        "margin-bottom" => "16px"
    ),
    # Text field styles
    CSS(
        ".textfield",
        "width" => "5rem",
        "font-size" => "14px",
        "padding" => "6px 10px",
        "border" => "2px solid $BORDER_COLOR",
        "border-radius" => "6px",
        "margin" => "4px",
        "transition" => "border-color 0.2s ease"
    ),
    CSS(
        ".textfield-tag",
        "width" => "10rem",
        "font-size" => "14px",
        "padding" => "8px 12px",
        "border" => "2px solid $BORDER_COLOR",
        "border-radius" => "6px",
        "margin" => "8px 4px"
    ),
    # Card styles
    CSS(
        ".card-base",
        "margin" => "8px",
        "padding" => "12px",
        "border" => "1px solid $BORDER_COLOR",
        "border-radius" => "12px",
        "color" => TEXT_DARK,
        "min-width" => "280px",
        "box-shadow" => "0 2px 8px rgba(0,0,0,0.08)",
        "transition" => "all 0.2s ease",
        "background-color" => "white"
    ),
    # Score threshold styles (0.05, 0.03, 0.01)
    CSS(
        ".ref-card.score-high",
        "background-color" => "#FFE5E5",
        "border-left" => "4px solid $DANGER_COLOR"
    ),
    CSS(
        ".ref-card.score-medium",
        "background-color" => "#FFF3E0",
        "border-left" => "4px solid $WARNING_COLOR"
    ),
    CSS(
        ".ref-card.score-low",
        "background-color" => "#FFFDE7",
        "border-left" => "4px solid #FDD835"
    ),
    CSS(
        ".ref-card.score-minimal",
        "background-color" => "#F5F5F5",
        "border-left" => "4px solid #9E9E9E"
    ),
    # Media container - stack images on top of each other
    CSS(
        ".media-container",
        "position" => "relative",
        "width" => "100%",
        "min-height" => "200px",
        "display" => "grid"
    ),
    CSS(
        ".media-img, .media-video",
        "width" => "100%",
        "height" => "auto",
        "grid-area" => "1 / 1"
    ),
    # Main container
    CSS(
        ".main-container",
        "font-family" => "system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif",
        "max-width" => "1400px",
        "margin" => "0 auto",
        "padding" => "24px",
        "background-color" => BG_LIGHT
    )
)

# Button styles
const BUTTON_STYLE = Styles(
    CSS(
        "font-size" => "14px",
        "font-weight" => "500",
        "padding" => "8px 16px",
        "border-radius" => "6px",
        "border" => "none",
        "background-color" => PRIMARY_COLOR,
        "color" => "white",
        "cursor" => "pointer",
        "transition" => "all 0.2s ease",
        "box-shadow" => "0 2px 4px rgba(0,0,0,0.1)",
        "margin" => "4px",
        "width" => "220px",
        "text-align" => "center"
    ),
    CSS(
        ":hover",
        "background-color" => "#357ABD",
        "box-shadow" => "0 4px 8px rgba(0,0,0,0.2)"
    ),
    CSS(
        ":active",
        "transform" => "translateY(1px)"
    )
)

const UPLOAD_BUTTON_STYLE = Styles(
    CSS(
        "font-size" => "16px",
        "font-weight" => "600",
        "padding" => "12px 24px",
        "border-radius" => "8px",
        "border" => "none",
        "background-color" => SUCCESS_COLOR,
        "color" => "white",
        "cursor" => "pointer",
        "transition" => "all 0.2s ease",
        "box-shadow" => "0 3px 6px rgba(0,0,0,0.15)",
        "margin" => "8px 4px",
        "width" => "auto"
    ),
    CSS(
        ":hover",
        "background-color" => "#229954",
        "box-shadow" => "0 5px 12px rgba(0,0,0,0.25)"
    ),
    CSS(
        ":active",
        "transform" => "translateY(1px)"
    ),
    CSS(
        ":disabled",
        "background-color" => "#95A5A6",
        "cursor" => "not-allowed",
        "opacity" => "0.6"
    )
)

# ============================================================================
# Helper Functions
# ============================================================================

function media_element(img_name, local_path, additional_classes = ""; kw...)
    filetype = split(img_name, ".")[end]
    css_class = additional_classes == "" ? "" : " $additional_classes"
    dom = if filetype == "png"
        DOM.img(; src = local_path, class = "media-img $css_class", kw...)
    else
        src = DOM.source(; src = local_path, type = "video/mp4")
        DOM.video(
            src;
            autoplay = false, controls = true, class = "media-video $css_class", kw...
        )
    end
    return dom
end


"""
    build_card_grid(img_names, backends, should_include, card_builder)

Unified function to build a grid of cards for multiple images and backends.

# Arguments
- `img_names`: Iterator of image names
- `backends`: Vector of backend names (e.g., ["GLMakie", "CairoMakie", "WGLMakie"])
- `should_include`: Function `(current_file) -> Bool` to determine if a card should be created
- `card_builder`: Function `(img_name, backend, current_file) -> Card` to create the card

# Returns
Vector of cards (with empty DOM.div() for missing entries)
"""
function build_card_grid(img_names, backends, should_include, card_builder)
    cards = Any[]
    for img_name in img_names
        for backend in backends
            current_file = backend * "/" * img_name
            if should_include(current_file)
                card = card_builder(img_name, backend, current_file)
                push!(cards, card)
            else
                push!(cards, DOM.div())
            end
        end
    end
    return cards
end

function create_simple_grid_content(root_path, filename, image_folder, backends)
    files = readlines(joinpath(root_path, filename))
    refimages = unique(
        map(files) do img
            replace(img, r"(GLMakie|CairoMakie|WGLMakie)/" => "")
        end
    )

    # Card builder for simple cards
    function simple_card_builder(img_name, backend, current_file)
        # Plain HTML checkbox (no observables)
        cb = DOM.div(
            DOM.input(type = "checkbox", class = "checkbox-input"),
            " $current_file",
            class = "checkbox-label"
        )
        local_path = Bonito.Asset(normpath(joinpath(root_path, image_folder, backend, img_name)))
        media = media_element(img_name, local_path)
        return Card(
            DOM.div(cb, media),
            class = "ref-card card-base score-minimal",
            dataFilepath = current_file,
            dataHidden = "false"
        )
    end

    return build_card_grid(
        refimages,
        backends,
        file -> file in files,
        simple_card_builder
    )
end

"""
    get_score(lookup, backends, img_name)

Get the maximum score for an image across all backends.
"""
function get_score(lookup::Dict, backends::Vector{String}, img_name::String)
    scores = map(backends) do backend
        name = backend * "/" * img_name
        if haskey(lookup, name)
            return lookup[name]
        else
            return -Inf
        end
    end
    return maximum(scores)
end

"""
    get_score_class(score, thresholds)

Get the CSS class name for a score based on thresholds.
"""
function get_score_class(score::Real, thresholds::Vector{Float64})
    if score > thresholds[1]
        return "score-high"
    elseif score > thresholds[2]
        return "score-medium"
    elseif score > thresholds[3]
        return "score-low"
    else
        return "score-minimal"
    end
end

"""
    BackendCard(img_name, backend, score, root_path, score_thresholds)

Create a reference image card for a specific backend.
"""
function BackendCard(
        img_name::String,
        backend::String,
        score::Float64,
        root_path::String,
        score_thresholds::Vector{Float64}
    )
    current_file = backend * "/" * img_name

    # Checkbox (plain HTML, selection handled in JS)
    cb = DOM.div(
        DOM.input(type = "checkbox", class = "checkbox-input"),
        " $current_file"
    )

    # Create all three media paths
    recorded_path = Bonito.Asset(normpath(joinpath(root_path, "recorded", backend, img_name)))
    reference_path = Bonito.Asset(normpath(joinpath(root_path, "reference", backend, img_name)))
    glmakie_ref_path = Bonito.Asset(normpath(joinpath(root_path, "reference", "GLMakie", img_name)))

    # Create three media elements (identical CSS and positioning)
    media_recorded = media_element(img_name, recorded_path; style = "z-index: 3")
    media_reference = media_element(img_name, reference_path; style = "z-index: 2")
    media_glmakie = media_element(img_name, glmakie_ref_path; style = "z-index: 1")

    # Button container (for JS to find and update)
    path_button = Bonito.Button("Showing: recorded", style = BUTTON_STYLE)
    button_container = DOM.div(
        path_button,
        DOM.div("Score: $score", class = "score-badge"),
        class = "card-controls"
    )

    # Media container
    media_container = DOM.div(
        media_recorded,
        media_reference,
        media_glmakie,
        class = "media-container"
    )

    # Get CSS class for score
    score_class = get_score_class(score, score_thresholds)

    # Setup button handler using JSHelper module
    handle_button = js"""
    $(JSHelper).then(mod => {
        mod.setupImageCycleButton(
            $(button_container),
            $(media_recorded),
            $(media_reference),
            $(media_glmakie)
        );
    });
    """

    card = Card(
        DOM.div(
            cb,
            button_container,
            media_container,
            # JS handler for button clicks via JSHelper
            handle_button,
        ),
        class = "ref-card card-base $score_class",
        dataScore = string(score),
        dataBackend = backend,
        dataImgname = img_name,
        dataFilepath = current_file,
        dataHidden = "false"
    )

    return card
end

"""
    upload_selection(tag, marked_for_upload, marked_for_deletion, root_path)

Upload selected reference images.
"""
function upload_selection(
        tag::String,
        marked_for_upload::Set{String},
        marked_for_deletion::Set{String},
        root_path::String
    )
    recorded_path = joinpath(root_path, "recorded")

    @info "Downloading latest reference image folder for $tag"
    tmpdir = try
        download_refimages(tag)
    catch e
        @error "Failed to download refimg folder. Is the tag $tag correct? Exiting without upload." exception = (e, catch_backtrace())
        return
    end

    @info "Updating files in $tmpdir"

    try
        for image in marked_for_upload
            @info "Overwriting or adding $image"
            target = joinpath(tmpdir, normpath(image))
            mkpath(splitdir(target)[1])
            source = joinpath(recorded_path, normpath(image))
            cp(source, target, force = true)
        end
    catch e
        @error "Failed to overwrite/add images. Exiting without upload." exception = (e, catch_backtrace())
        return
    end

    try
        for image in marked_for_deletion
            @info "Deleting $image"
            target = joinpath(tmpdir, normpath(image))
            if isfile(target)
                rm(target)
            else
                @warn "Cannot delete $image - does not exist."
            end
        end
    catch e
        @error "Failed to remove images. Exiting without upload." exception = (e, catch_backtrace())
        return
    end

    try
        @info "Uploading..."
        upload_reference_images(tmpdir, tag)
        @info "Upload successful."
    catch e
        @error "Upload failed: " exception = (e, catch_backtrace())
    finally
        @info "Deleting temp directory..."
        rm(tmpdir; force = true, recursive = true)
        @info "Done. You can ctrl+c out now."
    end
    return
end

# ============================================================================
# Main App Creation
# ============================================================================
const JSHelper = Bonito.ES6Module(normpath(joinpath(@__DIR__, "JSHelper.js")))

"""
    create_app_content(session, root_path)

Creates the main ReferenceUpdater app content.
"""
function create_app_content(session::Session, root_path::String)
    # Constants
    backends = ["GLMakie", "CairoMakie", "WGLMakie"]
    score_thresholds = [0.05, 0.03, 0.01]

    # Newly added Images
    new_cards = create_simple_grid_content(root_path, "new_files.txt", "recorded", backends)

    # Deleted/Missing Images
    missing_cards = create_simple_grid_content(root_path, "missing_files.txt", "reference", backends)

    # Updated images
    scores_imgs = readdlm(joinpath(root_path, "scores.tsv"), '\t')
    scores = scores_imgs[:, 1]
    imgs = scores_imgs[:, 2]
    lookup = Dict(imgs .=> scores)

    imgs_with_score = unique(
        map(imgs) do img
            replace(img, r"(GLMakie|CairoMakie|WGLMakie)/" => "")
        end
    )

    sort!(imgs_with_score; by = img -> get_score(lookup, backends, img), rev = true)

    # Filter controls
    filter_textfield = Bonito.TextField("0", class = "textfield")
    filter_label = DOM.div(
        DOM.span("Filter by Score ≥ ", class = "filter-label-text"),
        filter_textfield,
        DOM.span(" (0 = show all)", class = "filter-help-text"),
        class = "filter-label"
    )

    # Build updated cards with data attributes using unified builder
    function backend_card_builder(img_name, backend, current_file)
        score = round(lookup[current_file]; digits = 3)
        return BackendCard(
            img_name,
            backend,
            score,
            root_path,
            score_thresholds
        )
    end

    updated_cards = build_card_grid(
        imgs_with_score,
        backends,
        file -> haskey(lookup, file),
        backend_card_builder
    )

    # Upload section
    tag_textfield = Bonito.TextField("$(last_major_version())", class = "textfield-tag")
    upload_button = Bonito.Button("Update reference images with selection", style = UPLOAD_BUTTON_STYLE)

    # Loading overlay
    loading_overlay = DOM.div(
        DOM.div(
            DOM.p("Uploading reference images...", class = "loading-text"),
            DOM.div(class = "spinner"),
            class = "loading-content"
        ),
        class = "loading-overlay"
    )

    # Observable to trigger upload with collected selections
    upload_trigger = Observable(Dict{Any, Any}("upload_files" => String[], "delete_files" => String[]))

    # Check if we're in a session (not static export)
    is_static = (session.connection isa Bonito.NoConnection)
    if is_static
        upload_button.attributes[:disabled] = true
    else
        # Handle upload trigger from JS
        on(upload_trigger) do selections
            Threads.@async begin
                try
                    Bonito.evaljs(session, js"const overlay = $(loading_overlay); overlay.classList.add('active')")
                    upload_for_upload_set = Set{String}(selections["upload_files"])
                    marked_for_deletion_set = Set{String}(selections["delete_files"])
                    @time upload_selection(tag_textfield.value[], upload_for_upload_set, marked_for_deletion_set, root_path)
                catch e
                    @error "Upload process failed." exception = e
                finally
                    try
                        Bonito.evaljs(session, js"const overlay = $(loading_overlay); overlay.classList.remove('active')")
                    catch e
                        @warn "Could not hide loading overlay" exception = e
                    end
                end
            end
        end
    end

    # JS handler for upload button - collects all checked items via JSHelper
    upload_handler = is_static ? DOM.div() : js"""
        $(upload_button.value).on(clicked => {
            $(JSHelper).then(mod => {
                const { uploadFiles, deleteFiles } = mod.collectCheckedFiles();
                $(upload_trigger).notify({upload_files: uploadFiles, delete_files: deleteFiles});
            });
        });
        """

    # JS to update selection counts on checkbox changes via JSHelper
    update_counts_js = is_static ? DOM.div() : js"""
        $(JSHelper).then(mod => {
            mod.setupSelectionCountUpdates();
        });
        """

    # Compare to GLMakie - JS-based view mode
    compare_backend = Observable("")  # Empty = show all, otherwise compare selected backend to GLMakie
    compare_buttons = map(["GLMakie", "CairoMakie", "WGLMakie", "Reset"]) do backend
        to_update = backend == "Reset" ? "" : backend
        name = backend == "Reset" ? backend : "Only $(backend)"
        button = Bonito.Button(name; style = BUTTON_STYLE)
        onjs(session, button.value, js"""(x)=> $(compare_backend).notify($(to_update))""")
        return button
    end

    # Main grid
    main_grid = Grid(updated_cards, columns = "1fr 1fr 1fr")

    # Setup JS filtering
    onjs(
        session, filter_textfield.value, js"""
        function(threshold) {
            $(JSHelper).then(mod => mod.filterByScore(threshold));
        }
        """
    )

    # Sort controls with unified observable
    sort_backend = Observable("")  # Empty string = reset, otherwise backend name
    sort_buttons = map(["GLMakie", "CairoMakie", "WGLMakie", "Reset"]) do backend
        to_update = backend == "Reset" ? "" : backend
        button = Bonito.Button(backend, style = BUTTON_STYLE)
        onjs(session, button.value, js"""(x)=> $(sort_backend).notify($(to_update))""")
        return button
    end
    # Single unified sorting JS function
    onjs(
        session, sort_backend, js"""
        function(backend) {
            const grid = $(main_grid);
            $(JSHelper).then(mod => mod.sortByBackend(grid, backend));
        }
        """
    )

    # Comparison mode JS handler
    onjs(
        session, compare_backend, js"""
        function(backend) {
            const grid = $(main_grid);
            $(JSHelper).then(mod => mod.compareToGLMakie(grid, backend));
        }"""
    )

    sort_button_html = map(x -> DOM.div(x; class = "sort-cell"), sort_buttons[1:3])
    sort_controls = DOM.div(
        DOM.div(
            DOM.span("Sort by backend | "),
            sort_buttons[4];
            class = "sort-info-row"
        ),
        DOM.div(
            sort_button_html;
            class = "sort-button-row"
        ),
        class = "sort-controls"
    )

    # Create sections
    page_header = DOM.div(
        DOM.h1("Reference Images Updater", class = "page-title"),
        DOM.p("Compare and update Makie reference images from CI runs", class = "page-subtitle"),
        class = "page-header"
    )

    update_section = DOM.div(
        DOM.h2("Images to update", class = "section-header"),
        DOM.div(
            "Pressing the button below will download the latest reference images for the selected version; add, update and/or remove the selected images listed below and then upload the changed reference image folder. See Julia terminal for progress updates.",
            class = "section-description"
        ),
        DOM.div(
            tag_textfield,
            upload_button,
            upload_handler,
            update_counts_js,
            class = "upload-controls"
        ),
        DOM.h3(
            "0 images selected for updating:",
            class = "upload-list-header success",
            id = "upload-count-header"
        ),
        DOM.ul(
            class = "upload-list",
            id = "upload-file-list"
        ),
        DOM.h3(
            "0 images selected for removal:",
            class = "upload-list-header danger",
            id = "delete-count-header"
        ),
        DOM.ul(
            class = "upload-list",
            id = "delete-file-list"
        ),
        class = "section"
    )

    glmakie_compare_section = DOM.div(
        DOM.h2("Compare Backend to GLMakie", class = "section-header"),
        DOM.div(
            "Compare a backend to GLMakie by showing only that backend's images with GLMakie references. The main grid below will be filtered to show one column comparing the selected backend to GLMakie.",
            class = "section-description"
        ),
        DOM.div(compare_buttons; class = "upload-controls"),
        class = "section"
    )

    new_image_section = DOM.div(
        DOM.h2("New images without references", class = "section-header"),
        DOM.div(
            "The selected CI run produced an image for which no reference image exists. Selected images will be added as new reference images.",
            class = "section-description"
        ),
        Grid(new_cards, columns = "1fr 1fr 1fr"),
        class = "section"
    )

    missing_recordings_section = DOM.div(
        DOM.h2("Old reference images without recordings", class = "section-header"),
        DOM.div(
            "The selected CI run did not produce an image, but a reference image exists. This implies that a reference test was deleted or renamed. Selected images will be deleted from the reference images.",
            class = "section-description"
        ),
        Grid(missing_cards, columns = "1fr 1fr 1fr"),
        class = "section"
    )

    main_section = DOM.div(
        DOM.h2("Images with references", class = "section-header"),
        DOM.div(
            "This is the normal case where the selected CI run produced an image and the reference image exists. Each row shows one image per backend from the same reference image test, which can be compared with its reference image. Rows are sorted based on the maximum row score (bigger = more different). Background colors are based on this score, with red > $(score_thresholds[1]), orange > $(score_thresholds[2]), yellow > $(score_thresholds[3]) and the rest being light gray.",
            class = "section-description"
        ),
        filter_label,
        sort_controls,
        main_grid,
        class = "section"
    )

    return DOM.div(
        REFIMG_STYLES,
        loading_overlay,
        page_header,
        update_section,
        glmakie_compare_section,
        new_image_section,
        missing_recordings_section,
        main_section,
        class = "main-container"
    )
end

function serve_update_page_from_dir(root_path)
    return App((session) -> create_app_content(session, root_path))
end

function serve_update_page(; commit = nothing, pr = nothing)
    tmpdir = download_artifacts(commit = commit, pr = pr)
    @info "Creating Bonito app from folder $tmpdir."
    return serve_update_page_from_dir(tmpdir)
end
