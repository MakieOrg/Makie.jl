import * as THREE from "https://cdn.esm.sh/v66/three@0.173/es2021/three.js";
import {to_three_vector} from "./ThreeHelper.js";

/**
 * Converts a UV rectangle to pixel bounds.
 * @param {THREE.Vector4} uv
 * @param {number} tex_width
 * @param {number} tex_height
 * @returns {{x_start: number, y_start: number, x_end: number, y_end: number}}
 */
function uv_to_pixel_bounds(uv, tex_width, tex_height) {
    const tex_size = new THREE.Vector2(tex_width, tex_height);

    const uv_left_bottom = new THREE.Vector2(uv.x, uv.y);
    const uv_right_top = new THREE.Vector2(uv.z, uv.w);

    const px_left_bottom = uv_left_bottom
        .clone()
        .multiply(tex_size)
        .floor();

    const px_right_top = uv_right_top
        .clone()
        .multiply(tex_size)
        .ceil();
    const wx = Math.abs(px_right_top.x - px_left_bottom.x);
    const wy = Math.abs(px_right_top.y - px_left_bottom.y);
    return [px_left_bottom, new THREE.Vector2(wx, wy)];
}

export class TextureAtlas {
    /**
     * @param {number} width - Width of the texture atlas.
     * @param {number} height - Height of the texture atlas.
     */
    constructor(width, pix_per_glyph, glyph_padding) {
        this.pix_per_glyph = pix_per_glyph; // Pixels per glyph
        this.glyph_padding = glyph_padding; // Padding around each glyph
        this.width = width;
        this.height = width;
        this.data = new Float32Array(width * width); // Flat 1-channel data
        for (let i = 0; i < this.data.length; i++) {
            this.data[i] = 0.0//0.5 * pix_per_glyph + glyph_padding;
        }
        this.glyph_data = new Map(); // Map<UInt32, THREE.Vector4>
        this.textures = new Map(); // Map<WebGLContext, THREE.DataTexture>
    }

    /**
     * Insert a glyph into the atlas.
     * @param {number} hash - UInt32 hash of the glyph.
     * @param {Float32Array} glyph_data - Flattened glyph pixel data (single channel).
     * @param {THREE.Vector4} uv_pos - UV coordinates of the glyph in the atlas.
     * @param {THREE.Vector2} width - with of the glyph boundingbox
     * @param {THREE.Vector2} minimum - minimum of the glyph boundingbox
     */
    insert_glyph(hash, glyph_data, uv_pos, width, minimum) {
        this.glyph_data.set(hash, [uv_pos, width, minimum]);

        const [px_start, px_width] = uv_to_pixel_bounds(
            uv_pos,
            this.width,
            this.height
        );

        for (let col = 0; col < px_width.y; col++) {
            for (let row = 0; row < px_width.x; row++) {
                // Column-major indexing
                const glyph_index = col * px_width.x + row;
                const atlas_index =
                    (px_start.y + col) * this.height + (px_start.x + row);
                this.data[atlas_index] = glyph_data.array[glyph_index];
            }
        }
    }
    insert_glyphs(glyph_data) {
        let written = false;
        Object.keys(glyph_data).forEach((hash) => {
            if (this.glyph_data.has(hash)) {
                // TODO, be more careful to not update the same glyphs
                // (e.g. in deserialize_scene and in the plots code)
                return;
            }
            const [uv, sdf, width, minimum] = glyph_data[hash];
            this.insert_glyph(
                hash,
                sdf,
                to_three_vector(uv),
                to_three_vector(width),
                to_three_vector(minimum)
            );
            written = true;
            return;
        });
        if (written) {
            this.upload_tex_data();
        }
    }

    /**
     * Get glyph metadata from the atlas.
     * @param {number} hash - UInt32 hash of the glyph.
     * @returns {{ uv: THREE.Vector4, offset: THREE.Vector2 } | null}
     */
    get_glyph_data(hash, scale) {
        const data = this.glyph_data.get(hash.toString());
        if (!data) {
            console.warn(
                `Glyph with hash ${hash} not found in the atlas.`
            );
            return null;
        }
        const [uv_offset_width, width, mini] = data;
        const w_scaled = width.clone().multiply(scale);
        const mini_scaled = mini.clone().multiply(scale);
        const pad = this.glyph_padding / this.pix_per_glyph;
        const scaled_pad = scale.clone().multiplyScalar(2 * pad);
        const scales = w_scaled.clone().add(scaled_pad);

        const quad_offsets = mini_scaled
            .clone()
            .sub(scale.clone().multiplyScalar(pad));

        return [uv_offset_width, scales, quad_offsets];
    }

    /**
     * Get or create a THREE.DataTexture for the given renderer.
     * @param {THREE.WebGLRenderer} renderer
     * @returns {THREE.DataTexture}
     */
    get_texture(renderer) {

        if (this.textures.has(renderer)) {
            return this.textures.get(renderer);
        }

        const texture = new THREE.DataTexture(
            this.data,
            this.width,
            this.height,
            THREE.RedFormat,
            THREE.FloatType
        );
        texture.magFilter = THREE.NearestFilter;
        texture.minFilter = THREE.NearestFilter;
        texture.wrapS = THREE.ClampToEdgeWrapping;
        texture.wrapT = THREE.ClampToEdgeWrapping;
        this.textures.set(renderer, texture);
        return texture;
    }

    /**
     * Upload a sub-region of the atlas to the GPU.
     * @private
     * @param {THREE.WebGLRenderer} renderer
     * @param {THREE.DataTexture} texture
     * @param {number} start_x - X pixel coordinate in the atlas.
     * @param {number} start_y - Y pixel coordinate in the atlas.
     * @param {number} width - Width of the updated region in pixels.
     * @param {number} height - Height of the updated region in pixels.
     * @param {Float32Array} glyph_data - Flattened glyph pixel data to upload.
     */
    upload_tex_data() {
        // Update all GPU textures
        for (const [renderer, texture] of this.textures.entries()) {
            if (!texture.image) {
                this.textures.delete(renderer);
                continue;
            }
            texture.image.data.set(this.data);
            texture.needsUpdate = true;
        }
    }
}

const TEXTURE_ATLAS = [];

export function get_texture_atlas() {
    if (TEXTURE_ATLAS.length === 0) {
        const atlas = new TextureAtlas(2048, 64, 12);
        TEXTURE_ATLAS.push(atlas);
    }
    return TEXTURE_ATLAS[0];
}
