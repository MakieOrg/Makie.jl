// debug FLAGS
// #define DEBUG_RENDER_ORDER

flat out vec3 o_normal;
out vec3 o_uvw;
flat out int o_side;
out vec2 o_tex_uv;

#ifdef DEBUG_RENDER_ORDER
flat out float plane_render_idx;
flat out int plane_dim;
flat out int plane_front;
#endif

out vec3 o_camdir;

uniform mat4 projection, view;

const vec3 unit_vecs[3] = vec3[]( vec3(1, 0, 0), vec3(0, 1, 0), vec3(0, 0, 1) );
const mat2x3 orientations[3] = mat2x3[](
    mat2x3(0, 1, 0, 0, 0, 1), // xy -> _yz (x normal)
    mat2x3(1, 0, 0, 0, 0, 1), // xy -> x_z (y normal)
    mat2x3(1, 0, 0, 0, 1, 0)  // xy -> xy_ (z normal)
);

void main() {
    get_dummy(); // otherwise this doesn't render :)

    /* How this works:
    To simplify lets consider a 2d grid of pixel where the voxel surface would
    be the square outline of around a data point x.
        +---+---+---+
        | x | x | x |
        +---+---+---+
        | x | x | x |
        +---+---+---+
        | x | x | x |
        +---+---+---+
    Naively we would draw 4 lines for each point x, coloring them based on the
    data attached to x. This would result in 4 * N^2 lines with N^2 = number of
    pixels. We can do much better though by drawing a line for each column and
    row of pixels:
      1 +---+---+---+
        | x | x | x |
      2 +---+---+---+
        | x | x | x |
      3 +---+---+---+
        | x | x | x |
      4 +---+---+---+
        5   6   7   8
    This results in 2 * (N+1) lines. We can adjust the color of the line by
    sampling a Texture containing the information previously attached to vertices.

    Generalized to 3D voxels, lines become planes and the texture becomes 3D.
    We draw the planes through instancing. So first we will need to map the
    instance id to a dimension (xy, xz or yz plane) and an offset (in z, y or
    x direction respectively).
    */

    // TODO: might be better for transparent rendering to alternate xyz?
    // But how would we do this for non-cubic chunks?

    // Map instance id to dimension and index along dimension (0..N+1 or 0..2N)
    ivec3 size = textureSize(voxel_id, 0);
    int dim, id = gl_InstanceID, front = 1;
    float gap = get_gap();
    if (gap > 0.01) {
        front = 1 - 2 * int(gl_InstanceID & 1);
        if (id < 2 * size.z) {
            dim = 2;
            id = id;
        } else if (id < 2 * (size.z + size.y)) {
            dim = 1;
            id = id - 2 * size.z;
        } else { // if (id > 2 * (size.z + size.y)) {
            dim = 0;
            id = id - 2 * (size.z + size.y);
        }
    } else {
        if (id < size.z + 1) {
            dim = 2;
            id = id;
        } else if (id < size.z + size.y + 2) {
            dim = 1;
            id = id - (size.z + 1);
        } else {
            dim = 0;
            id = id - (size.z + size.y + 2);
        }
    }

#ifdef DEBUG_RENDER_ORDER
    plane_render_idx = float(id) / float(size[dim]-1);
    plane_dim = dim;
    plane_front = front;
#endif

    // plane placement
    // Figure out which plane to start with
    vec3 normal = get_normalmatrix() * unit_vecs[dim];
    int dir = dot(get_view_direction(), normal) < 0.0 ? -1 : 1, start;
    if (depthsorting) {
        // TODO: depthsorted should start far away from viewer so every plane draws
        start = int((0.5 + 0.5 * float(dir)) * float(size[dim]));
        dir *= -1;
    } else {
        // otherwise we should start at viewer and expand in view direction so
        // that the depth test can quickly eliminate unnecessary fragments
        // Note that model can have rotations and (uneven) scaling
        vec4 origin = model * vec4(0, 0, 0, 1);
        vec4 back   = model * vec4(size, 1);
        float front_dist = dot(origin.xyz / origin.w, normal);
        float back_dist  = dot(back.xyz / back.w, normal);
        float cam_dist   = dot(eyeposition, normal);
        float dist01 = (cam_dist - front_dist) / (back_dist - front_dist);

        // index of voxel closest to (and in front of) the camera
        start = clamp(int(float(size[dim]) * dist01), 0, size[dim]);
    }

    vec3 displacement;
    if (gap > 0.01) {
        // planes are doubled
        // 2 * start + min(dir, 0)                  closest (camera facing) plane
        // dir * id                                 iterate away from first plane
        // (idx + 2 * size[dim]) % 2 * size[dim]    normalize to [0, 2size[dim])
        int plane_idx = (2 * start + min(dir, 0) + dir * id + 2 * size[dim]) % (2 * size[dim]);
        // (plane_idx + 1) / 2          map to idx 0, 1, 2, 3, 4 -> displacements 0, 1, 1, 2, 2, ...
        // 0.5 * dir * gap * front      gap based offset from space filling placements
        displacement = (float((plane_idx + 1) / 2) + 0.5 * float(dir * front) * gap) * unit_vecs[dim];
    } else {
        // similar to above but with N+1 indices around N voxels
        displacement = float((start + dir * id + size[dim] + 1) % (size[dim] + 1)) * unit_vecs[dim];
    }

    // place plane vertices
    vec3 plane_vertex = vec3(size) * (orientations[dim] * get_position()) + displacement;
    vec4 world_pos = get_model() * vec4(plane_vertex, 1.0f);
    gl_Position = projection * view * world_pos;
    gl_Position.z += gl_Position.w * get_depth_shift();

    // For each plane the normal is constant in
    // +- normal = +- world_normalmatrix * unit_vecs[dim] direction. We just need
    // the correct prefactor
    o_camdir = eyeposition - world_pos.xyz / world_pos.w;
    float normal_dir;
    if (gap > 0.01) {
        // With a gap we render front and back faces. Since the gap always takes
        // away from a voxel the normal should go in the opposite direction.
        normal_dir = -float(dir * front);
    } else {
        // Without a gap we skip back facing faces so every normal faces the camera
        normal_dir = sign(dot(o_camdir, normal));
    }
    o_normal = normal_dir * normalize(normal);

    // The quad we render here is directly between two slices of voxels in our
    // chunk. Each `plane_vertex` of the quad is in a 0 .. size scale, so they
    // can be mapped directly to texture indices. We just need to figure out if
    // the quad is associated with the "previous" or "next" slice of voxels. We
    // can derive that from the normal direction, as the normal always points
    // away from the voxel center.
    o_uvw = (plane_vertex - 0.5 * (1.0 - gap) * o_normal) / vec3(size);

    // normal in: -x -y -z +x +y +z direction
    o_side = dim + 3 * int(0.5 + 0.5 * normal_dir);

    // map plane_vertex (-w/2 .. w/2 scale) back to 2d (scaled 0 .. w)
    // if the normal is negative invert range (w .. 0)
    o_tex_uv = transpose(orientations[dim]) * (vec3(-normal_dir, normal_dir, 1.0) * plane_vertex);
}