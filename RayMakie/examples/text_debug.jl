# Text Rendering Debug Script
# ===========================
# This file helps debug the UV mapping issue between Makie's atlas and RayMakie's sampling.
#
# Key finding: GLMakie renders T correctly, but direct atlas sampling shows garbage.
# The atlas data and UV coordinates appear correct, but something is wrong with the mapping.
#
# Run with: include("text_debug.jl"); debug_text()

using GLMakie, Colors, FileIO
using GeometryBasics: Vec2f, Vec4f, Point3f

#=============================================================================
# CONFIGURATION - Tweak these to experiment
=============================================================================#

const OUTPUT_DIR = "/tmp"
const GLYPH_CHAR = 'T'
const FONT_SIZE = 80

#=============================================================================
# Helper functions
=============================================================================#

function get_text_plot(fig)
    for block in fig.content
        if block isa Axis
            for plot in block.scene.plots
                if plot isa Makie.Text
                    return plot
                end
            end
        end
    end
    error("No text plot found")
end

function get_glyph_info(plot)
    attr = plot.attributes
    return (
        sdf_uv = attr[:sdf_uv][][1],           # UV rect in atlas
        quad_scale = attr[:quad_scale][][1],   # Screen size
        quad_offset = attr[:quad_offset][][1], # Offset within quad
        marker_offset = attr[:marker_offset][][1], # Offset from anchor
    )
end

#=============================================================================
# Core sampling function - THIS IS WHERE THE BUG LIKELY IS
# Modify this to test different UV mapping strategies
=============================================================================#

function sample_glyph(atlas, uv_rect, output_size=100)
    u_min, v_min, u_max, v_max = uv_rect[1], uv_rect[2], uv_rect[3], uv_rect[4]
    atlas_h, atlas_w = size(atlas.data)  # Julia: (rows, cols) = (height, width)

    img = fill(RGBA{Float32}(1,1,1,1), output_size, output_size)

    for py in 1:output_size
        for px in 1:output_size
            # Local UV [0, 1] within output image
            # py=1 is top of output, py=output_size is bottom
            local_u = (px - 0.5f0) / output_size
            local_v = (py - 0.5f0) / output_size

            #------------------------------------------------------------------
            # UV MAPPING - Try different approaches here:
            #------------------------------------------------------------------

            # Current approach (doesn't work):
            atlas_u = u_min + local_u * (u_max - u_min)
            atlas_v = v_min + local_v * (v_max - v_min)

            # Alternative 1: Flip local_v
            # atlas_v = v_max - local_v * (v_max - v_min)

            # Alternative 2: Different interpretation of uv_rect
            # ...

            #------------------------------------------------------------------
            # Atlas sampling
            #------------------------------------------------------------------
            ax = clamp(round(Int, atlas_u * atlas_w), 1, atlas_w)
            ay = clamp(round(Int, atlas_v * atlas_h), 1, atlas_h)

            sdf = Float32(atlas.data[ay, ax])

            # SDF to coverage (edge at 12, AA width 1.5)
            coverage = clamp((12f0 - sdf + 1.5f0) / 3f0, 0f0, 1f0)

            if coverage > 0.01f0
                img[py, px] = RGBA{Float32}(1f0, 0f0, 0f0, coverage)
            end
        end
    end

    return img
end

#=============================================================================
# Extract raw glyph data from atlas for inspection
=============================================================================#

function extract_glyph_region(atlas, uv_rect)
    u_min, v_min, u_max, v_max = uv_rect[1], uv_rect[2], uv_rect[3], uv_rect[4]
    atlas_h, atlas_w = size(atlas.data)

    # Makie's sdf_uv_to_pixel does this:
    # tex_size = Vec2f(size(atlas.data))  # Note: this is (height, width) in Julia!
    # px_left_bottom = ceil.(Int, uv_left_bottom .* tex_size)
    # x_range = px_left_bottom[1]:px_right_top[1]  # columns
    # y_range = px_left_bottom[2]:px_right_top[2]  # rows

    # So for Makie: u maps to first dimension, v maps to second
    # But Julia matrices are [row, col] = [y, x]

    # Let's try both interpretations:
    println("\n=== Pixel coordinate interpretations ===")

    # Interpretation 1: u->col, v->row (standard)
    col_min = ceil(Int, u_min * atlas_w)
    col_max = ceil(Int, u_max * atlas_w)
    row_min = ceil(Int, v_min * atlas_h)
    row_max = ceil(Int, v_max * atlas_h)
    println("Standard (u->col, v->row): rows $row_min:$row_max, cols $col_min:$col_max")

    # Interpretation 2: What Makie's sdf_uv_to_pixel returns
    makie_ranges = Makie.sdf_uv_to_pixel(atlas, uv_rect)
    println("Makie's sdf_uv_to_pixel: ", makie_ranges)

    # Extract using standard interpretation
    return atlas.data[row_min:row_max, col_min:col_max]
end

#=============================================================================
# Main debug function
=============================================================================#

function debug_text()
    println("="^60)
    println("TEXT RENDERING DEBUG")
    println("="^60)

    # 1. Create test scene and render with GLMakie
    println("\n[1] Creating test scene...")
    GLMakie.activate!()

    fig = Figure(size=(400, 300))
    ax = Axis(fig[1,1], aspect=DataAspect())
    hidedecorations!(ax); hidespines!(ax)
    limits!(ax, -1, 1, -1, 1)
    text!(ax, 0, 0, text=string(GLYPH_CHAR), fontsize=FONT_SIZE, color=:red, align=(:center, :center))

    save("$OUTPUT_DIR/reference_glmakie.png", fig)
    println("   Saved: $OUTPUT_DIR/reference_glmakie.png (GLMakie reference)")

    # 2. Get glyph data from plot
    println("\n[2] Extracting glyph data from plot...")
    plot = get_text_plot(fig)
    glyph = get_glyph_info(plot)

    println("   sdf_uv: ", glyph.sdf_uv)
    println("   quad_scale: ", glyph.quad_scale)
    println("   quad_offset: ", glyph.quad_offset)
    println("   marker_offset: ", glyph.marker_offset)

    # 3. Get atlas info
    println("\n[3] Atlas info...")
    atlas = Makie.get_texture_atlas()
    println("   size: ", size(atlas.data), " (rows x cols)")
    println("   glyph_padding: ", atlas.glyph_padding)
    println("   pix_per_glyph: ", atlas.pix_per_glyph)

    # 4. Extract raw glyph region
    println("\n[4] Extracting raw glyph region...")
    glyph_region = extract_glyph_region(atlas, glyph.sdf_uv)
    println("   Region size: ", size(glyph_region))
    println("   SDF range: ", minimum(glyph_region), " to ", maximum(glyph_region))
    println("   Pixels inside (SDF < 12): ", count(x -> x < 12, glyph_region))

    # 5. Save raw glyph region as image
    println("\n[5] Saving raw glyph visualizations...")
    gh, gw = size(glyph_region)
    raw_img = fill(RGBA{Float32}(1,1,1,1), gh, gw)
    for y in 1:gh, x in 1:gw
        sdf = Float32(glyph_region[y, x])
        coverage = clamp((12f0 - sdf + 1.5f0) / 3f0, 0f0, 1f0)
        if coverage > 0.01f0
            raw_img[y, x] = RGBA{Float32}(1f0, 0f0, 0f0, coverage)
        end
    end
    save("$OUTPUT_DIR/glyph_raw.png", raw_img)
    save("$OUTPUT_DIR/glyph_yflipped.png", raw_img[end:-1:1, :])
    save("$OUTPUT_DIR/glyph_xflipped.png", raw_img[:, end:-1:1])
    save("$OUTPUT_DIR/glyph_xyflipped.png", raw_img[end:-1:1, end:-1:1])
    println("   Saved: glyph_raw.png, glyph_yflipped.png, glyph_xflipped.png, glyph_xyflipped.png")

    # 6. Sample using current algorithm
    println("\n[6] Sampling with current algorithm...")
    sampled = sample_glyph(atlas, glyph.sdf_uv)
    save("$OUTPUT_DIR/sampled_current.png", sampled)
    println("   Saved: $OUTPUT_DIR/sampled_current.png")

    # 7. Summary
    println("\n" * "="^60)
    println("OUTPUT FILES in $OUTPUT_DIR/:")
    println("  reference_glmakie.png  - Correct rendering (GLMakie)")
    println("  glyph_raw.png          - Raw atlas data at UV coords")
    println("  glyph_yflipped.png     - Raw atlas data, Y flipped")
    println("  glyph_xflipped.png     - Raw atlas data, X flipped")
    println("  glyph_xyflipped.png    - Raw atlas data, XY flipped")
    println("  sampled_current.png    - Result of sample_glyph()")
    println("="^60)
    println("\nEdit sample_glyph() in this file to fix the UV mapping!")

    return (fig=fig, atlas=atlas, glyph=glyph, glyph_region=glyph_region)
end

# Quick test function to try a specific UV mapping
function test_mapping(atlas, uv_rect; flip_local_v=false, flip_atlas_v=false, swap_uv=false)
    u_min, v_min, u_max, v_max = uv_rect[1], uv_rect[2], uv_rect[3], uv_rect[4]
    atlas_h, atlas_w = size(atlas.data)

    img = fill(RGBA{Float32}(1,1,1,1), 100, 100)

    for py in 1:100, px in 1:100
        local_u = (px - 0.5f0) / 100
        local_v = (py - 0.5f0) / 100

        if flip_local_v
            local_v = 1f0 - local_v
        end

        atlas_u = u_min + local_u * (u_max - u_min)
        atlas_v = v_min + local_v * (v_max - v_min)

        if flip_atlas_v
            atlas_v = 1f0 - atlas_v
        end

        if swap_uv
            atlas_u, atlas_v = atlas_v, atlas_u
        end

        ax = clamp(round(Int, atlas_u * atlas_w), 1, atlas_w)
        ay = clamp(round(Int, atlas_v * atlas_h), 1, atlas_h)

        sdf = Float32(atlas.data[ay, ax])
        coverage = clamp((12f0 - sdf + 1.5f0) / 3f0, 0f0, 1f0)
        if coverage > 0.01f0
            img[py, px] = RGBA{Float32}(1f0, 0f0, 0f0, coverage)
        end
    end

    return img
end

# Run if executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    debug_text()
end
