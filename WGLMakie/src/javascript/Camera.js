import * as THREE from "https://cdn.esm.sh/v66/three@0.173/es2021/three.js";
import { OrbitControls } from "./OrbitControls.js";

// Unitless is the scene pixel unit space
// so scene.viewport, or size(scene)
// Which isn't the same as the framebuffer pixel size due to scalefactor/px_per_unit/devicePixelRatio
export function events2unitless(screen, event) {
    const { canvas, winscale, renderer } = screen;
    const rect = canvas.getBoundingClientRect();
    const x = (event.clientX - rect.left) / winscale;
    const y = (event.clientY - rect.top) / winscale;
    return [x, renderer._height - y];
}

export function to_world(scene, x, y) {
    const proj_inv = scene.wgl_camera.projectionview_inverse.value;
    const [_x, _y, w, h] = scene.viewport.value;
    const pix_space = new THREE.Vector4(
        ((x - _x) / w) * 2 - 1,
        ((y - _y) / h) * 2 - 1,
        0,
        1.0
    );
    pix_space.applyMatrix4(proj_inv);
    return new THREE.Vector2(
        pix_space.x / pix_space.w,
        pix_space.y / pix_space.w
    );
}

// make it a bit clearer what the THREE API produces!
function Identity4x4() {
    return new THREE.Matrix4();
}

function in_scene(scene, mouse_event) {
    const [x, y] = events2unitless(scene.screen, mouse_event);
    const [sx, sy, sw, sh] = scene.viewport.value;
    return x >= sx && x < sx + sw && y >= sy && y < sy + sh;
}

// Taken from https://andreasrohner.at/posts/Web%20Development/JavaScript/Simple-orbital-camera-controls-for-THREE-js/
export function attach_3d_camera(
    canvas,
    makie_camera,
    cam3d,
    light_dir,
    scene
) {
    if (cam3d === undefined) {
        // we just support 3d cameras atm
        return;
    }
    const [w, h] = makie_camera.resolution.value;
    const camera = new THREE.PerspectiveCamera(
        cam3d.fov.value,
        w / h,
        0.01,
        100.0
    );

    const center = new THREE.Vector3(...cam3d.lookat.value);
    camera.up = new THREE.Vector3(0, 0, 1);
    camera.position.set(...cam3d.eyeposition.value);
    camera.lookAt(center);

    const use_orbit_cam = () =>
        !(Bonito.can_send_to_julia && Bonito.can_send_to_julia());
    const controls = new OrbitControls(camera, canvas, use_orbit_cam, (e) =>
        in_scene(scene, e)
    );
    controls.target = center.clone()
    controls.target0 = center.clone()

    scene.orbitcontrols = controls;

    controls.addEventListener("change", (e) => {
        const [width, height] = cam3d.resolution.value;
        const position = camera.position;
        const lookat = controls.target;
        const [x, y, z] = position;
        const dist = position.distanceTo(lookat);
        camera.aspect = width / height;
        camera.near = dist * 0.1;
        camera.far = dist * 5;
        camera.updateProjectionMatrix();
        camera.updateWorldMatrix();
        const view = camera.matrixWorldInverse;
        const projection = camera.projectionMatrix;
        makie_camera.update_matrices(
            view.elements,
            projection.elements,
            [width, height],
            [x, y, z]
        );
        makie_camera.update_light_dir(light_dir.value);
    });
}

function mul(a, b) {
    return b.clone().multiply(a);
}

function orthographicprojection(left, right, bottom, top, znear, zfar) {
    return [
        2 / (right - left),
        0,
        0,
        0,
        0,
        2 / (top - bottom),
        0,
        0,
        0,
        0,
        -2 / (zfar - znear),
        0,
        -(right + left) / (right - left),
        -(top + bottom) / (top - bottom),
        -(zfar + znear) / (zfar - znear),
        1,
    ];
}

function pixel_space_inverse(w, h, near) {
    return [
        0.5 * w,
        0,
        0,
        0,
        0,
        0.5 * h,
        0,
        0,
        0,
        0,
        near,
        0,
        0.5 * w,
        0.5 * h,
        0,
        1,
    ];
}

function relative_space() {
    const relative = Identity4x4();
    relative.fromArray([2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, -1, -1, 0, 1]);
    return relative;
}

export class MakieCamera {
    constructor() {
        // Matrices that get updated from Julia or from a JS camera reacting to events
        this.view = new THREE.Uniform(Identity4x4());
        this.projection = new THREE.Uniform(Identity4x4());
        this.projectionview = new THREE.Uniform(Identity4x4());
        this.pixel_space = new THREE.Uniform(Identity4x4());

        // inverses
        this.pixel_space_inverse = new THREE.Uniform(Identity4x4());
        this.projectionview_inverse = new THREE.Uniform(Identity4x4());

        // Constant matrices
        this.relative_space = new THREE.Uniform(relative_space());
        this.relative_inverse = new THREE.Uniform(relative_space().invert());
        this.clip_space = new THREE.Uniform(Identity4x4());

        // needed for some shaders (e.g. resolution -> line shader, or eyeposition -> volume shader)
        this.resolution = new THREE.Uniform(new THREE.Vector2());
        this.eyeposition = new THREE.Uniform(new THREE.Vector3());

        // preprojection matrix needed for markers + sprites
        // Lazy calculation, only if a plot type requests them
        // will be of the form: {[space, markerspace]: THREE.Uniform(...)}
        this.preprojections = {};

        // For camera-relative light directions
        // TODO: intial position wrong...
        this.original_light_direction = [-1, -1, -1];
        this.light_direction = new THREE.Uniform(
            new THREE.Vector3(-1, -1, -1).normalize()
        );

        this.on_update = new Map();
    }

    calculate_matrices() {
        const [w, h] = this.resolution.value;
        const nearclip = -10_000;
        const farclip = 10_000;
        this.pixel_space.value.fromArray(
            orthographicprojection(0, w, 0, h, nearclip, farclip)
        );
        this.pixel_space_inverse.value.fromArray(
            pixel_space_inverse(w, h, nearclip)
        );
        // TODO reuse existing matrices instead of `new` in `mul`
        const proj_view = mul(this.view.value, this.projection.value);
        this.projectionview.value = proj_view;

        this.projectionview_inverse.value = proj_view.clone().invert();

        // update all existing preprojection matrices
        Object.keys(this.preprojections).forEach((key) => {
            const [space, markerspace] = key.split(","); // jeez js, really just converting array keys to "elem,elem"?
            this.preprojections[key].value =
                this.calculate_preprojection_matrix(space, markerspace);
        });
    }

    update_matrices(view, projection, resolution, eyepos) {
        this.view.value.fromArray(view);
        this.projection.value.fromArray(projection);
        this.resolution.value.fromArray(resolution);
        this.eyeposition.value.fromArray(eyepos);
        this.calculate_matrices();
        this.recalculate_light_dir();
        for (const func of this.on_update.values()) {
            try {
                func(this);
            } catch (e) {
                console.error("Error during camera update callback:", e);
            }
        }
    }

    recalculate_light_dir() {
        const light_dir = this.original_light_direction;
        this.update_light_dir(light_dir);
    }

    update_light_dir(light_dir) {
        this.original_light_direction = light_dir;
        const T = new THREE.Matrix3().setFromMatrix4(this.view.value).invert();
        const new_dir = new THREE.Vector3().fromArray(light_dir);
        new_dir.applyMatrix3(T).normalize();
        this.light_direction.value = new_dir;
    }

    clip_to_space(space) {
        if (space === "data") {
            return this.projectionview_inverse.value;
        } else if (space === "pixel") {
            return this.pixel_space_inverse.value;
        } else if (space === "relative") {
            return this.relative_inverse.value;
        } else if (space === "clip") {
            return this.clip_space.value; // identity doesn't need inversion
        } else {
            throw new Error(`Space ${space} not recognized`);
        }
    }

    space_to_clip(space) {
        if (space === "data") {
            return this.projectionview.value;
        } else if (space === "pixel") {
            return this.pixel_space.value;
        } else if (space === "relative") {
            return this.relative_space.value;
        } else if (space === "clip") {
            return this.clip_space.value;
        } else {
            throw new Error(`Space ${space} not recognized`);
        }
    }

    calculate_preprojection_matrix(space, markerspace) {
        const cp = this.clip_to_space(markerspace);
        const sc = this.space_to_clip(space);
        return mul(sc, cp);
    }

    preprojection_matrix(space, markerspace) {
        const key = [space, markerspace];
        const matrix_uniform = this.preprojections[key];
        // lazily calculate it!
        if (matrix_uniform) {
            return matrix_uniform;
        } else {
            const matrix = this.calculate_preprojection_matrix(
                space,
                markerspace
            );
            const uniform = new THREE.Uniform(matrix);
            this.preprojections[key] = uniform;
            return uniform;
        }
    }
}
