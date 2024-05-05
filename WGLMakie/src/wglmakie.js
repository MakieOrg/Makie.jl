import * as THREE from "./THREE.js";
import { getWebGLErrorMessage } from "./WEBGL.js";
import {
    delete_scenes,
    insert_plot,
    delete_plots,
    delete_scene,
    delete_three_scene,
    find_plots,
    deserialize_scene,
    TEXTURE_ATLAS,
    on_next_insert,
    scene_cache,
    plot_cache,
    find_scene,
} from "./Serialization.js";

import { events2unitless } from "./Camera.js";

window.THREE = THREE;

export function render_scene(scene, picking = false) {
    const { camera, renderer, px_per_unit } = scene.screen;
    const canvas = renderer.domElement;
    if (!document.body.contains(canvas)) {
        console.log("removing WGL context, canvas is not in the DOM anymore!");
        if (scene.screen.texture_atlas) {
            // we need a better observable API to deregister callbacks,
            // Right now one can only deregister a callback from within the callback by returning false.
            // So we notify the whole texture atlas with the texture that needs to go & deregister.
            const data = TEXTURE_ATLAS[0].value;
            TEXTURE_ATLAS[0].notify(scene.screen.texture_atlas, true);
            TEXTURE_ATLAS[0].value = data;
            scene.screen.texture_atlas = undefined;
        }
        delete_three_scene(scene);
        renderer.state.reset();
        renderer.dispose();
        return false;
    }
    // dont render invisible scenes
    if (!scene.visible.value) {
        return true;
    }
    renderer.autoClear = scene.clearscene.value;
    const area = scene.viewport.value;
    if (area) {
        const [x, y, w, h] = area.map((x) => x * px_per_unit);
        renderer.setViewport(x, y, w, h);
        renderer.setScissor(x, y, w, h);
        renderer.setScissorTest(true);
        if (picking) {
            renderer.setClearAlpha(0);
            renderer.setClearColor(new THREE.Color(0), 0.0);
        } else {
            const alpha = scene.backgroundcolor_alpha.value;
            renderer.setClearColor(scene.backgroundcolor.value, alpha);
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
    // ID of queued future update
    let future_id = undefined;
    function inner_throttle(...args) {
        // Current called time of the function
        const now = new Date().getTime();

        // If we had a queued run, clear it now, we're
        // either going to execute now, or queue a new run.
        if (future_id !== undefined) {
            clearTimeout(future_id);
            future_id = undefined;
        }

        // If difference is greater than delay call
        // the function again.
        if (now - prev > delay) {
            prev = now;
            // "..." is the spread operator here
            // returning the function with the
            // array of arguments
            return func(...args);
        } else {
            // Otherwise, we want to queue this function call
            // to occur at some later later time, so that it
            // does not get lost; we'll schedule it so that it
            // fires just a bit after our choke ends.
            future_id = setTimeout(
                () => inner_throttle(...args),
                now - prev + 1
            );
        }
    }
    return inner_throttle;
}

function get_body_size() {
    const bodyStyle = window.getComputedStyle(document.body);
    // Subtract padding that is added by VSCode
    const width_padding =
        parseInt(bodyStyle.paddingLeft, 10) +
        parseInt(bodyStyle.paddingRight, 10) +
        parseInt(bodyStyle.marginLeft, 10) +
        parseInt(bodyStyle.marginRight, 10);
    const height_padding =
        parseInt(bodyStyle.paddingTop, 10) +
        parseInt(bodyStyle.paddingBottom, 10) +
        parseInt(bodyStyle.marginTop, 10) +
        parseInt(bodyStyle.marginBottom, 10);
    const width = (window.innerWidth - width_padding);
    const height = (window.innerHeight - height_padding);
    return [width, height];
}
function get_parent_size(canvas) {
    const rect = canvas.parentElement.getBoundingClientRect();
    return [rect.width, rect.height];
}

export function wglerror(gl, error) {
    switch (error) {
        case gl.NO_ERROR:
            return "No error";
        case gl.INVALID_ENUM:
            return "Invalid enum";
        case gl.INVALID_VALUE:
            return "Invalid value";
        case gl.INVALID_OPERATION:
            return "Invalid operation";
        case gl.OUT_OF_MEMORY:
            return "Out of memory";
        case gl.CONTEXT_LOST_WEBGL:
            return "Context lost";
        default:
            return "Unknown error";
    }
}
// taken from THREEJS:
//https://github.com/mrdoob/three.js/blob/5303ef2d46b02e7c503ca63cedca0b93cd9c853e/src/renderers/webgl/WebGLProgram.js#L67C1-L89C2
function handleSource(string, errorLine) {
    const lines = string.split("\n");
    const lines2 = [];

    const from = Math.max(errorLine - 6, 0);
    const to = Math.min(errorLine + 6, lines.length);

    for (let i = from; i < to; i++) {
        const line = i + 1;
        lines2.push(`${line === errorLine ? ">" : " "} ${line}: ${lines[i]}`);
    }

    return lines2.join("\n");
}

function getShaderErrors(gl, shader, type) {
    const status = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
    const errors = gl.getShaderInfoLog(shader).trim();

    if (status && errors === "") return "";

    const errorMatches = /ERROR: 0:(\d+)/.exec(errors);
    if (errorMatches) {
        // --enable-privileged-webgl-extension
        // console.log( '**' + type + '**', gl.getExtension( 'WEBGL_debug_shaders' ).getTranslatedShaderSource( shader ) );

        const errorLine = parseInt(errorMatches[1]);
        return (
            type.toUpperCase() +
            "\n\n" +
            errors +
            "\n\n" +
            handleSource(gl.getShaderSource(shader), errorLine)
        );
    } else {
        return errors;
    }
}
function on_shader_error(gl, program, glVertexShader, glFragmentShader) {
    const programLog = gl.getProgramInfoLog(program).trim();
    const vertexErrors = getShaderErrors(gl, glVertexShader, "vertex");
    const fragmentErrors = getShaderErrors(gl, glFragmentShader, "fragment");
    const vertexLog = gl.getShaderInfoLog(glVertexShader).trim();
    const fragmentLog = gl.getShaderInfoLog(glFragmentShader).trim();

    const err =
        "THREE.WebGLProgram: Shader Error " +
        wglerror(gl, gl.getError()) +
        " - " +
        "VALIDATE_STATUS " +
        gl.getProgramParameter(program, gl.VALIDATE_STATUS) +
        "\n\n" +
        "Program Info Log:\n" +
        programLog +
        "\n" +
        vertexErrors +
        "\n" +
        fragmentErrors +
        "\n" +
        "Fragment log:\n" +
        fragmentLog +
        "Vertex log:\n" +
        vertexLog;

    Bonito.Connection.send_warning(err);
}

function add_canvas_events(screen, comm, resize_to) {
    const { canvas,  winscale } = screen;
    function mouse_callback(event) {
        const [x, y] = events2unitless(screen, event);
        comm.notify({ mouseposition: [x, y] });
    }

    const notify_mouse_throttled = throttle_function(mouse_callback, 40);

    function mousemove(event) {
        notify_mouse_throttled(event);
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

    function resize_callback() {
        let width, height;
        if (resize_to == "body") {
            [width, height] = get_body_size();
        } else if (resize_to == "parent") {
            [width, height] = get_parent_size(canvas);
        }
        // Send the resize event to Julia
        comm.notify({ resize: [width / winscale, height / winscale] });
    }
    if (resize_to) {
        const resize_callback_throttled = throttle_function(
            resize_callback,
            100
        );
        window.addEventListener("resize", (event) =>
            resize_callback_throttled()
        );
        // Fire the resize event once at the start to auto-size our window
        resize_callback_throttled();
    }
}

function threejs_module(canvas) {

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

    renderer.debug.onShaderError = on_shader_error;
    renderer.setClearColor("#ffffff");

    return renderer;
}

function set_render_size(screen, width, height) {
    const { renderer, canvas, scalefactor, winscale, px_per_unit } = screen;
    // The displayed size of the canvas, in CSS pixels - which get scaled by the device pixel ratio
    const [swidth, sheight] = [winscale * width, winscale * height];

    const real_pixel_width = Math.ceil(width * px_per_unit);
    const real_pixel_height = Math.ceil(height * px_per_unit);

    renderer._width = width;
    renderer._height = height;

    canvas.width = real_pixel_width;
    canvas.height = real_pixel_height;

    canvas.style.width = swidth + "px";
    canvas.style.height = sheight + "px";

    renderer.setViewport(0, 0, real_pixel_width, real_pixel_height);
    add_picking_target(screen);
    return;
}

function add_picking_target(screen) {
    const { picking_target, canvas } = screen;
    const [w, h] = [canvas.width, canvas.height];
    if (picking_target) {
        if (picking_target.width == w && picking_target.height == h) {
            return
        } else {
            picking_target.dispose();
        }
    }
    // BIG TODO here...
    // We should only make the picking target as big as the area we're picking
    // e.g. for just the mouse position it should be 1x1
    // Or we should just always bind the target and render to it in one pass
    // 1) One Pass:
    //      Only works on WebGL 2.0, which is still not as widely supported
    //      Also it's a bit more complicated to setup
    // 2) Only Area we pick
    //      It's currently not as easy to change the offset + area of the camera
    //      So, we'll need to make that easier first
    screen.picking_target = new THREE.WebGLRenderTarget(w, h);
    return;
}

function create_scene(
    wrapper,
    canvas,
    canvas_width,
    scenes,
    comm,
    width,
    height,
    texture_atlas_obs,
    fps,
    resize_to,
    px_per_unit,
    scalefactor
) {
    if (!scalefactor) {
        scalefactor = window.devicePixelRatio || 1.0;
    }
    if (!px_per_unit) {
        px_per_unit = scalefactor;
    }

    const renderer = threejs_module(canvas);

    TEXTURE_ATLAS[0] = texture_atlas_obs;

    if (!renderer) {
        const warning = getWebGLErrorMessage();
        // wrapper.removeChild(canvas)
        wrapper.appendChild(warning);
    }

    const camera = new THREE.PerspectiveCamera(45, 1, 0, 100);
    camera.updateProjectionMatrix();
    const pixel_ratio = window.devicePixelRatio || 1.0;
    const winscale = scalefactor / pixel_ratio;
    const screen = {
        renderer,
        camera,
        fps,
        canvas,
        px_per_unit,
        scalefactor,
        winscale,
        texture_atlas: undefined
    };
    add_canvas_events(screen, comm, resize_to);
    set_render_size(screen, width, height);

    const three_scene = deserialize_scene(scenes, screen);

    start_renderloop(three_scene);

    canvas_width.on((w_h) => {
        // `renderer.setSize` correctly updates `canvas` dimensions
        set_render_size(screen, ...w_h);
    });
    return renderer;
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

/**
 *
 * @param {*} scene
 * @param {*} x in scene unitless pixel space
 * @param {*} y in scene unitless pixel space
 * @param {*} w in scene unitless pixel space
 * @param {*} h in scene unitless pixel space
 * @returns
 */
export function pick_native(scene, _x, _y, _w, _h) {
    const { renderer, picking_target, px_per_unit } = scene.screen;
    [_x, _y, _w, _h] = [_x, _y, _w, _h].map((x) => Math.ceil(x * px_per_unit));
    const [x, y, w, h] = [_x, _y, _w, _h];
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
    const { renderer } = scene.screen;
    const [ width, height ] = [renderer._width, renderer._height];

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
    const { renderer } = scene.screen;
    const [width, height] = [renderer._width, renderer._height];

    if (!(1.0 <= xy[0] <= width && 1.0 <= xy[1] <= height)) {
        return null;
    }

    const x0 = Math.max(1, xy[0] - range);
    const y0 = Math.max(1, xy[1] - range);
    const x1 = Math.min(width, Math.floor(xy[0] + range));
    const y1 = Math.min(height, Math.floor(xy[1] + range));

    const dx = x1 - x0;
    const dy = y1 - y0;

    const [plot_data, selected] = pick_native(scene, x0, y0, dx, dy);
    if (selected.length == 0) {
        return null;
    }
    const plot_matrix = plot_data.data;
    const distances = selected.map((x) => range ^ 2);
    const x = xy[0] + 1 - x0;
    const y = xy[1] + 1 - y0;
    let pindex = 0;
    for (let i = 1; i <= dx; i++) {
        for (let j = 1; j <= dx; j++) {
            const d = (x - i) ^ (2 + (y - j)) ^ 2;
            if (plot_matrix.length <= pindex) {
                continue;
            }
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

export function register_popup(popup, scene, plots_to_pick, callback) {
    if (!scene || !scene.screen) {
        // scene not innitialized or removed already
        return;
    }
    const { canvas } = scene.screen;
    canvas.addEventListener("mousedown", (event) => {
        const [x, y] = events2unitless(scene.screen, event);
        const [_, picks] = pick_native(scene, x, y, 1, 1);
        if (picks.length == 1) {
            const [plot, index] = picks[0];
            if (plots_to_pick.has(plot.plot_uuid)) {
                const result = callback(plot, index);
                if (!popup.classList.contains("show")) {
                    popup.classList.add("show");
                }
                popup.style.left = event.pageX + "px";
                popup.style.top = event.pageY + "px";
                if (typeof result === "string" || result instanceof String) {
                    popup.innerText = result;
                } else {
                    popup.innerHTML = result;
                }
            }
        } else {
            popup.classList.remove("show");
        }
    });
    canvas.addEventListener("keyup", (event) => {
        if (event.key === "Escape") {
            popup.classList.remove("show");
        }
    });
}

window.WGL = {
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
    events2unitless,
    on_next_insert,
    register_popup,
    render_scene,
    TEXTURE_ATLAS,
};

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
    events2unitless,
    on_next_insert,
};
