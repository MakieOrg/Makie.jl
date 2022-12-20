import * as THREE from "https://cdn.esm.sh/v66/three@0.136/es2021/three.js";
import { getWebGLErrorMessage } from "./WEBGL.js";
import {
    delete_scenes,
    insert_plot,
    delete_plots,
    deserialize_scene,
    delete_scene,
    TEXTURE_ATLAS,
    on_next_insert,
} from "./Serialization.js";

import { event2scene_pixel } from "./Camera.js";

window.THREE = THREE;

const pixelRatio = window.devicePixelRatio || 1.0;

export function render_scene(scene, picking = false) {
    const { camera, renderer } = scene.screen;
    const canvas = renderer.domElement;
    if (!document.body.contains(canvas)) {
        console.log("EXITING WGL");
        renderer.state.reset();
        renderer.dispose();
        return false;
    }
    // dont render invisible scenes
    if (!scene.visible.value) {
        return true;
    }
    renderer.autoClear = scene.clearscene;
    const area = scene.pixelarea.value;
    if (area) {
        const [x, y, w, h] = area.map((t) => t / pixelRatio);
        renderer.setViewport(x, y, w, h);
        renderer.setScissor(x, y, w, h);
        renderer.setScissorTest(true);
        if (picking) {
            renderer.setClearAlpha(0);
            renderer.setClearColor(new THREE.Color(0), 0.0);
        } else {
            renderer.setClearColor(scene.backgroundcolor.value);
        }
        renderer.render(scene, camera);
    }
    return scene.scene_children.every((x) => render_scene(x, picking));
}

function start_renderloop(three_scene) {
    // extract the first scene for screen, which should be shared by all scenes!
    const { fps } = three_scene.screen;
    const time_per_frame = (1 / fps) * 1000; // default is 30 fps
    // make sure we immediately render the first frame and dont wait 30ms
    let last_time_stamp = performance.now();
    function renderloop(timestamp) {
        if (timestamp - last_time_stamp > time_per_frame) {
            const all_rendered = render_scene(three_scene);
            if (!all_rendered) {
                // if scenes don't render it means they're not displayed anymore
                // - time to quit the renderin' business
                return;
            }
            last_time_stamp = performance.now();
        }
        window.requestAnimationFrame(renderloop);
    }
    // render one time before starting loop, so that we don't wait 30ms before first render
    render_scene(three_scene);
    renderloop();
}

// from: https://www.geeksforgeeks.org/javascript-throttling/
function throttle_function(func, delay) {
    // Previously called time of the function
    let prev = 0;
    return (...args) => {
        // Current called time of the function
        const now = new Date().getTime();
        // If difference is greater than delay call
        // the function again.
        if (now - prev > delay) {
            prev = now;
            // "..." is the spread operator here
            // returning the function with the
            // array of arguments
            return func(...args);
        }
    };
}

function threejs_module(canvas, comm, width, height) {
    let context = canvas.getContext("webgl2", {
        preserveDrawingBuffer: true,
    });
    if (!context) {
        console.warn(
            "WebGL 2.0 not supported by browser, falling back to WebGL 1.0 (Volume plots will not work)"
        );
        context = canvas.getContext("webgl", {
            preserveDrawingBuffer: true,
        });
    }
    if (!context) {
        // Sigh, safari or something
        // we return nothing which will be handled by caller
        return;
    }
    const renderer = new THREE.WebGLRenderer({
        antialias: true,
        canvas: canvas,
        context: context,
        powerPreference: "high-performance",
    });

    renderer.setClearColor("#ffffff");

    // The following handles high-DPI devices
    // `renderer.setSize` also updates `canvas` size
    renderer.setPixelRatio(pixelRatio);
    renderer.setSize(width / pixelRatio, height / pixelRatio);

    const mouse_callback = (x, y) => comm.notify({ mouseposition: [x, y] });
    const notify_mouse_throttled = throttle_function(mouse_callback, 40);

    function mousemove(event) {
        var rect = canvas.getBoundingClientRect();
        var x = (event.clientX - rect.left) * pixelRatio;
        var y = (event.clientY - rect.top) * pixelRatio;

        notify_mouse_throttled(x, y);
        return false;
    }

    canvas.addEventListener("mousemove", mousemove);

    function mousedown(event) {
        comm.notify({
            mousedown: event.buttons,
        });
        return false;
    }
    canvas.addEventListener("mousedown", mousedown);

    function mouseup(event) {
        comm.notify({
            mouseup: event.buttons,
        });
        return false;
    }

    canvas.addEventListener("mouseup", mouseup);

    function wheel(event) {
        comm.notify({
            scroll: [event.deltaX, -event.deltaY],
        });
        event.preventDefault();
        return false;
    }
    canvas.addEventListener("wheel", wheel);

    function keydown(event) {
        comm.notify({
            keydown: event.code,
        });
        return false;
    }

    canvas.addEventListener("keydown", keydown);

    function keyup(event) {
        comm.notify({
            keyup: event.code,
        });
        return false;
    }

    canvas.addEventListener("keyup", keyup);
    // This is a pretty ugly work around......
    // so on keydown, we add the key to the currently pressed keys set
    // if we open the contextmenu before releasing the key, we'll never
    // receive an up event, so the key will stay inside the currently_pressed
    // set... Only option I found is to actually listen to the contextmenu
    // and remove all keys if its opened.
    function contextmenu(event) {
        comm.notify({
            keyup: "delete_keys",
        });
        return false;
    }

    canvas.addEventListener("contextmenu", (e) => e.preventDefault());
    canvas.addEventListener("focusout", contextmenu);

    return renderer;
}

function create_scene(
    wrapper,
    canvas,
    canvas_width,
    scenes,
    comm,
    width,
    height,
    fps,
    texture_atlas_obs
) {
    const renderer = threejs_module(canvas, comm, width, height);
    TEXTURE_ATLAS[0] = texture_atlas_obs;

    if (renderer) {
        const camera = new THREE.PerspectiveCamera(45, 1, 0, 100);
        camera.updateProjectionMatrix();
        const size = new THREE.Vector2();
        renderer.getDrawingBufferSize(size);
        const picking_target = new THREE.WebGLRenderTarget(size.x, size.y);
        const screen = { renderer, picking_target, camera, fps, canvas };

        const three_scene = deserialize_scene(scenes, screen);
        console.log(three_scene);
        start_renderloop(three_scene);

        canvas_width.on((w_h) => {
            // `renderer.setSize` correctly updates `canvas` dimensions
            const pixelRatio = renderer.getPixelRatio();
            renderer.setSize(w_h[0] / pixelRatio, w_h[1] / pixelRatio);
        });
    } else {
        const warning = getWebGLErrorMessage();
        // wrapper.removeChild(canvas)
        wrapper.appendChild(warning);
    }
}

function set_picking_uniforms(
    scene,
    last_id,
    picking,
    picked_plots,
    plots,
    id_to_plot
) {
    scene.children.forEach((plot, index) => {
        const { material } = plot;
        const { uniforms } = material;
        if (picking) {
            uniforms.object_id.value = last_id + index;
            uniforms.picking.value = true;
            material.blending = THREE.NoBlending;
        } else {
            // clean up after picking
            uniforms.picking.value = false;
            material.blending = THREE.NormalBlending;
            // we also collect the picked/matched plots as part of the clean up
            const id = uniforms.object_id.value;
            if (id in picked_plots) {
                plots.push([plot, picked_plots[id]]);
                id_to_plot[id] = plot; // create mapping from id to plot at the same time
            }
        }
    });
    let next_id = last_id + scene.children.length;
    scene.scene_children.forEach((scene) => {
        next_id = set_picking_uniforms(
            scene,
            next_id,
            picking,
            picked_plots,
            plots,
            id_to_plot
        );
    });
    return next_id;
}

export function pick_native(scene, x, y, w, h) {
    const { renderer, picking_target } = scene.screen;
    // render the scene
    renderer.setRenderTarget(picking_target);
    set_picking_uniforms(scene, 1, true);
    render_scene(scene, true);
    renderer.setRenderTarget(null); // reset render target

    const nbytes = w * h * 4;
    const pixel_bytes = new Uint8Array(nbytes);
    //read the pixel
    renderer.readRenderTargetPixels(
        picking_target,
        x, // x
        y, // y
        w, // width
        h, // height
        pixel_bytes
    );
    const picked_plots = {};
    const picked_plots_array = [];

    const reinterpret_view = new DataView(pixel_bytes.buffer);

    for (let i = 0; i < pixel_bytes.length / 4; i++) {
        const id = reinterpret_view.getUint16(i * 4);
        const index = reinterpret_view.getUint16(i * 4 + 2);
        picked_plots_array.push([id, index]);
        picked_plots[id] = index;
    }
    // dict of plot_uuid => primitive_index (e.g. instance id or triangle index)
    const plots = [];
    const id_to_plot = {};
    set_picking_uniforms(scene, 0, false, picked_plots, plots, id_to_plot);
    const picked_plots_matrix = picked_plots_array.map(([id, index]) => {
        const p = id_to_plot[id];
        return [p ? p.plot_uuid : null, index];
    });
    const plot_matrix = { data: picked_plots_matrix, size: [w, h] };

    return [plot_matrix, plots];
}

export function pick_closest(scene, xy, range) {
    const { picking_target } = scene.screen;
    const { width, height } = picking_target;

    if (!(1.0 <= xy[0] <= width && 1.0 <= xy[1] <= height)) {
        return [null, 0];
    }

    const x0 = Math.max(1, xy[0] - range);
    const y0 = Math.max(1, xy[1] - range);
    const x1 = Math.min(width, Math.floor(xy[0] + range));
    const y1 = Math.min(height, Math.floor(xy[1] + range));
    const dx = x1 - x0;
    const dy = y1 - y0;
    const [plot_data, _] = pick_native(scene, x0, y0, dx, dy);
    const plot_matrix = plot_data.data;
    let min_dist = range ^ 2;
    let selection = [null, 0];
    const x = xy[0] + 1 - x0;
    const y = xy[1] + 1 - y0;
    let pindex = 0;
    for (let i = 1; i <= dx; i++) {
        for (let j = 1; j <= dx; j++) {
            const d = (x - i) ^ (2 + (y - j)) ^ 2;
            const [plot_uuid, index] = plot_matrix[pindex];
            pindex = pindex + 1;
            if (d < min_dist && plot_uuid) {
                min_dist = d;
                selection = [plot_uuid, index];
            }
        }
    }
    return selection;
}

export function pick_sorted(scene, xy, range) {
    const { picking_target } = scene.screen;
    const { width, height } = picking_target;

    if (!(1.0 <= xy[0] <= width && 1.0 <= xy[1] <= height)) {
        return [null, 0];
    }

    const x0 = Math.max(1, xy[0] - range);
    const y0 = Math.max(1, xy[1] - range);
    const x1 = Math.min(width, Math.floor(xy[0] + range));
    const y1 = Math.min(height, Math.floor(xy[1] + range));

    const dx = x1 - x0;
    const dy = y1 - y0;
    const [plot_data, selected] = pick_native(scene, x0, y0, dx, dy);
    if (selected.length == 0) {
        return [];
    }

    const plot_matrix = plot_data.data;
    const distances = selected.map((x) => range ^ 2);
    const x = xy[0] + 1 - x0;
    const y = xy[1] + 1 - y0;
    let pindex = 0;
    for (let i = 1; i <= dx; i++) {
        for (let j = 1; j <= dx; j++) {
            const d = (x - i) ^ (2 + (y - j)) ^ 2;
            const [plot_uuid, index] = plot_matrix[pindex];
            pindex = pindex + 1;
            const plot_index = selected.findIndex(
                (x) => x[0].plot_uuid == plot_uuid
            );
            if (plot_index >= 0 && d < distances[plot_index]) {
                distances[plot_index] = d;
            }
        }
    }

    const sorted_indices = Array.from(Array(distances.length).keys()).sort(
        (a, b) =>
            distances[a] < distances[b] ? -1 : (distances[b] < distances[a]) | 0
    );

    return sorted_indices.map((idx) => {
        const [plot, index] = selected[idx];
        return [plot.plot_uuid, index];
    });
}

export function pick_native_uuid(scene, x, y, w, h) {
    const [_, picked_plots] = pick_native(scene, x, y, w, h);
    return picked_plots.map(([p, index]) => [p.plot_uuid, index]);
}

export function pick_native_matrix(scene, x, y, w, h) {
    const [matrix, _] = pick_native(scene, x, y, w, h);
    return matrix;
}

export {
    deserialize_scene,
    threejs_module,
    start_renderloop,
    delete_plots,
    insert_plot,
    find_plots,
    delete_scene,
    find_scene,
    scene_cache,
    plot_cache,
    delete_scenes,
    create_scene,
    event2scene_pixel,
    on_next_insert
};
