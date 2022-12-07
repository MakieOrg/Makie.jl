import * as THREE from "https://cdn.esm.sh/v66/three@0.136/es2021/three.js";

const pixelRatio = window.devicePixelRatio || 1.0;
export function event2scene_pixel(scene, event) {
    const canvas = scene.screen.renderer.domElement;
    const rect = canvas.getBoundingClientRect();
    const x = (event.clientX - rect.left) * pixelRatio;
    const y = (rect.height - (event.clientY - rect.top)) * pixelRatio;
    return [x, y];
}

export function to_world(scene, x, y) {
    const proj_inv = scene.wgl_camera.projectionview_inverse.value;
    const [_x, _y, w, h] = JSServe.get_observable(scene.pixelarea);
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
    const [x, y] = event2scene_pixel(scene, mouse_event);
    const [sx, sy, sw, sh] = scene.pixelarea.value;
    return x >= sx && x < sx + sw && y >= sy && y < sy + sh;
}

// Taken from https://andreasrohner.at/posts/Web%20Development/JavaScript/Simple-orbital-camera-controls-for-THREE-js/
export function attach_3d_camera(canvas, makie_camera, cam3d, scene) {
    if (cam3d === undefined) {
        // we just support 3d cameras atm
        return;
    }
    const [w, h] = makie_camera.resolution.value;
    const camera = new THREE.PerspectiveCamera(
        cam3d.fov,
        w / h,
        cam3d.near,
        cam3d.far
    );

    const center = new THREE.Vector3(...cam3d.lookat);
    camera.up = new THREE.Vector3(...cam3d.upvector);
    camera.position.set(...cam3d.eyeposition);
    camera.lookAt(center);

    function update() {
        camera.updateProjectionMatrix();
        camera.updateWorldMatrix();
        const view = camera.matrixWorldInverse;
        const projection = camera.projectionMatrix;
        const [width, height] = makie_camera.resolution.value;
        const [x, y, z] = camera.position;
        makie_camera.update_matrices(
            view.elements,
            projection.elements,
            [width, height],
            [x, y, z]
        );
    }

    function addMouseHandler(domObject, drag, zoomIn, zoomOut) {
        let startDragX = null;
        let startDragY = null;
        function mouseWheelHandler(e) {
            e = window.event || e;
            if (!in_scene(scene, e)) {
                return;
            }
            const delta = Math.sign(e.deltaY);
            if (delta == -1) {
                zoomOut();
            } else if (delta == 1) {
                zoomIn();
            }

            e.preventDefault();
        }
        function mouseDownHandler(e) {
            if (!in_scene(scene, e)) {
                return;
            }
            startDragX = e.clientX;
            startDragY = e.clientY;

            e.preventDefault();
        }
        function mouseMoveHandler(e) {
            if (!in_scene(scene, e)) {
                return;
            }
            if (startDragX === null || startDragY === null) return;

            if (drag) drag(e.clientX - startDragX, e.clientY - startDragY);

            startDragX = e.clientX;
            startDragY = e.clientY;
            e.preventDefault();
        }
        function mouseUpHandler(e) {
            if (!in_scene(scene, e)) {
                return;
            }
            mouseMoveHandler.call(this, e);
            startDragX = null;
            startDragY = null;
            e.preventDefault();
        }
        domObject.addEventListener("wheel", mouseWheelHandler);
        domObject.addEventListener("mousedown", mouseDownHandler);
        domObject.addEventListener("mousemove", mouseMoveHandler);
        domObject.addEventListener("mouseup", mouseUpHandler);
    }

    function drag(deltaX, deltaY) {
        const radPerPixel = Math.PI / 450;
        const deltaPhi = radPerPixel * deltaX;
        const deltaTheta = radPerPixel * deltaY;
        const pos = camera.position.sub(center);
        const radius = pos.length();
        let theta = Math.acos(pos.z / radius);
        let phi = Math.atan2(pos.y, pos.x);

        // Subtract deltaTheta and deltaPhi
        theta = Math.min(Math.max(theta - deltaTheta, 0), Math.PI);
        phi -= deltaPhi;

        // Turn back into Cartesian coordinates
        pos.x = radius * Math.sin(theta) * Math.cos(phi);
        pos.y = radius * Math.sin(theta) * Math.sin(phi);
        pos.z = radius * Math.cos(theta);

        camera.position.add(center);
        camera.lookAt(center);
        update();
    }

    function zoomIn() {
        camera.position.sub(center).multiplyScalar(0.9).add(center);
        update();
    }

    function zoomOut() {
        camera.position.sub(center).multiplyScalar(1.1).add(center);
        update();
    }

    addMouseHandler(canvas, drag, zoomIn, zoomOut);
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
            const [space, markerspace] = key.split(",");
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
        return;
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
