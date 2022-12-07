import * as THREE from "https://cdn.esm.sh/v66/three@0.136/es2021/three.js";
import { getWebGLErrorMessage } from "./WEBGL.js";
import { delete_scenes, insert_plot, delete_plots, deserialize_scene, delete_scene, TEXTURE_ATLAS} from "./Serialization.js";
import { event2scene_pixel } from "./Camera.js";

window.THREE = THREE;

const pixelRatio = window.devicePixelRatio || 1.0;

export function render_scene(scene) {
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
        renderer.setClearColor(scene.backgroundcolor.value);
        renderer.render(scene, camera);
    }

    return scene.scene_children.every(render_scene);
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

function set_picking_uniforms(scene, last_id, picking, picked_plots, plots) {
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
            }
        }
    });
    return last_id + scene.children.length;
}

export function pick_native(scenes, x, y, w, h) {
    const { renderer, camera, picking_target } = scenes[0].screen;
    // render the scene
    renderer.setRenderTarget(picking_target);

    const pixelRatio = window.devicePixelRatio || 1.0;

    let last_id = 1;
    scenes.forEach((scene) => {
        last_id = set_picking_uniforms(scene, last_id, true);

        const area = scene.pixelarea.value;
        const [_x, _y, _w, _h] = area.map((t) => t / pixelRatio);
        renderer.autoClear = true;
        renderer.setViewport(_x, _y, _w, _h);
        renderer.setScissor(_x, _y, _w, _h);
        renderer.setScissorTest(true);
        renderer.setClearAlpha(0);
        renderer.setClearColor(new THREE.Color(0), 0.0);
        renderer.render(scene, camera);
    });

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
    const reinterpret_view = new DataView(pixel_bytes.buffer);

    for (let i = 0; i < pixel_bytes.length / 4; i++) {
        const id = reinterpret_view.getUint16(i * 4);
        const index = reinterpret_view.getUint16(i * 4 + 2);
        picked_plots[id] = index;
    }
    // dict of plot_uuid => primitive_index (e.g. instance id or triangle index)
    const plots = [];
    scenes.forEach((scene) =>
        set_picking_uniforms(scene, 0, false, picked_plots, plots)
    );
    return plots;
}

export function pick_native_uuid(scenes, x, y, w, h) {
    const picked_plots = pick_native(scenes, x, y, w, h);
    return picked_plots.map((x) => [x[0].plot_uuid, x[1]]);
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
};
