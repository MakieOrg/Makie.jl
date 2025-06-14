import * as THREE from "https://cdn.esm.sh/v66/three@0.173/es2021/three.js";
import * as Camera from "./Camera.js";
import * as Plots from "./Plots.js";
import { create_texture, to_three_vector } from "./ThreeHelper.js";
import { get_texture_atlas } from "./TextureAtlas.js";

function create_plot(scene, data) {
    const PlotClass = Plots[data.plot_type]; // Dynamically lookup the class
    if (typeof PlotClass !== "function") {
        throw new Error(`Unknown plot type: ${data.plot_type}`);
    }
    return new PlotClass(scene, data);
}

// global scene cache to look them up for dynamic operations in Makie
// e.g. insert!(scene, plot) / delete!(scene, plot)
const scene_cache = {};
const plot_cache = {};

export function add_plot(scene, plot_data) {
    // fill in the camera uniforms, that we don't sent in serialization per plot
    const p = create_plot(scene, plot_data);
    plot_cache[p.uuid] = p.mesh;
    scene.add(p.mesh);
    // execute all next insert callbacks
    const next_insert = new Set(ON_NEXT_INSERT); // copy
    next_insert.forEach((f) => f());
}

export function add_scene(scene_id, three_scene) {
    scene_cache[scene_id] = three_scene;
}

export function find_scene(scene_id) {
    return scene_cache[scene_id];
}

export function delete_scene(scene_id) {
    const scene = scene_cache[scene_id];
    if (!scene) {
        return;
    }
    delete_three_scene(scene);
    while (scene.children.length > 0) {
        scene.remove(scene.children[0]);
    }
    delete scene_cache[scene_id];
}

export function find_plots(plot_uuids) {
    const plots = [];
    plot_uuids.forEach((id) => {
        const plot = plot_cache[id];
        if (plot) {
            plots.push(plot);
        }
    });
    return plots;
}

export function delete_scenes(scene_uuids, plot_uuids) {
    plot_uuids.forEach((plot_id) => {
        const plot = plot_cache[plot_id];
        if (plot) {
            delete_plot(plot);
        }
    });
    scene_uuids.forEach((scene_id) => {
        delete_scene(scene_id);
    });
}

export function insert_plot(scene_id, plot_data) {
    const scene = find_scene(scene_id);
    plot_data.forEach((plot) => {
        add_plot(scene, plot);
    });
}

export function delete_plots(plot_uuids) {
    const plots = find_plots(plot_uuids);
    plots.forEach(delete_plot);
}

function convert_texture(scene, data) {
    const tex = create_texture(scene, data);
    tex.needsUpdate = true;
    tex.generateMipmaps = data.mipmap;
    tex.minFilter = THREE[data.minFilter];
    tex.magFilter = THREE[data.magFilter];
    tex.anisotropy = data.anisotropy;
    tex.wrapS = THREE[data.wrapS];
    if (data.size.length > 1) {
        tex.wrapT = THREE[data.wrapT];
    }
    if (data.size.length > 2) {
        tex.wrapR = THREE[data.wrapR];
    }
    return tex;
}


export function is_typed_array(data) {
    return data instanceof Float32Array || data instanceof Int32Array || data instanceof Uint32Array;
}

function to_uniform(scene, data) {
    if (data.type !== undefined) {
        if (data.type == "Sampler") {
            return convert_texture(scene, data);
        }
        throw new Error(`Type ${data.type} not known`);
    }
    if (Array.isArray(data) || ArrayBuffer.isView(data)) {
        if (!data.every((x) => typeof x === "number")) {
            // if not all numbers, we just leave it
            return data;
        }
        // else, we convert it to THREE vector/matrix types
        return to_three_vector(data);
    }
    // else, leave unchanged
    return data;
}


export function deserialize_uniforms(scene, data) {
    const result = {};
    for (const name in data) {
        const value = data[name];
        // this is already a uniform - happens when we attach additional
        // uniforms like the camera matrices in a later stage!
        if (value instanceof THREE.Uniform) {
            // nothing needs to be converted
            result[name] = value;
        } else {
            const ser = to_uniform(scene, value);
            result[name] = new THREE.Uniform(ser);
        }
    }
    return result;
}

const ON_NEXT_INSERT = new Set();

export function on_next_insert(f) {
    ON_NEXT_INSERT.add(f);
}


// the plot order is different in WGLMakie (js) compared to serialization order
// In julia, so we need to first go through all plots and update the glyphs.
// Example: plota brings glyphs [a,b,c] from text "abc", plotb brings [d, e] from text "abcde".
// If plotb gets serialized first, the glyphs from plota will be missing.
function add_glyphs_from_plots(scene_data) {
    const atlas = get_texture_atlas();
    scene_data.plots.forEach((plot_data) => {
        if (plot_data.glyph_data) {
            const glyph_data = plot_data.glyph_data;
            const { atlas_updates } = glyph_data;
            if (atlas_updates) {
                atlas.insert_glyphs(atlas_updates);
            }
        }
    });
    scene_data.children.forEach((child) => {
        add_glyphs_from_plots(child);
    });
}

export function deserialize_scene(data, screen) {
    add_glyphs_from_plots(data);
    return deserialize_scene_recursive(data, screen);
}

export function deserialize_scene_recursive(data, screen) {
    const scene = new THREE.Scene();
    scene.screen = screen;
    const { canvas } = screen;
    add_scene(data.uuid, scene);
    scene.scene_uuid = data.uuid;
    scene.frustumCulled = false;
    scene.viewport = data.viewport;
    scene.backgroundcolor = data.backgroundcolor;
    scene.backgroundcolor_alpha = data.backgroundcolor_alpha;
    scene.clearscene = data.clearscene;
    scene.visible = data.visible;

    const camera = new Camera.MakieCamera();

    scene.wgl_camera = camera;

    function update_cam(camera_matrices, force) {
        if (!force) {
            // we use the threejs orbit controls, if the julia connection is gone
            // at least for 3d ... 2d is still a todo, and will stay static right now
            if (!(Bonito.can_send_to_julia && Bonito.can_send_to_julia())) {
                return;
            }
        }
        const [view, projection, resolution, eyepos] = camera_matrices;
        camera.update_matrices(view, projection, resolution, eyepos);
    }

    if (data.cam3d_state) {
        Camera.attach_3d_camera(
            canvas,
            camera,
            data.cam3d_state,
            data.light_direction,
            scene
        );
    }

    update_cam(data.camera.value, true); // force update on first call

    data.camera.on(update_cam);

    if (data.camera_relative_light.value) {
        camera.update_light_dir(data.light_direction.value);
        scene.light_direction = camera.light_direction;
        data.light_direction.on((value) => {
            camera.update_light_dir(value);
        });
    } else {
        const light_dir = new THREE.Vector3().fromArray(
            data.light_direction.value
        );
        scene.light_direction = new THREE.Uniform(light_dir);
        data.light_direction.on((value) => {
            scene.light_direction.value.fromArray(value);
        });
    }

    const ambient = new THREE.Vector3().fromArray(data.ambient.value);
    scene.ambient = new THREE.Uniform(ambient);
    data.ambient.on((value) => {
        scene.ambient.value.fromArray(value);
    })

    const light_color = new THREE.Vector3().fromArray(data.light_color.value);
    scene.light_color = new THREE.Uniform(light_color);
    data.light_color.on((value) => {
        scene.light_color.value.fromArray(value);
    })

    data.plots.forEach((plot_data) => {
        add_plot(scene, plot_data);
    });
    scene.scene_children = data.children.map((child) => {
        const childscene = deserialize_scene_recursive(child, screen);
        return childscene;
    });
    return scene;
}

export function delete_plot(plot) {
    plot.plot_object.dispose()
}

export function delete_three_scene(scene) {
    delete scene_cache[scene.scene_uuid];
    scene.scene_children.forEach(delete_three_scene);
    while (scene.children.length > 0) {
        delete_plot(scene.children[0]);
    }
}

export { scene_cache, plot_cache };
