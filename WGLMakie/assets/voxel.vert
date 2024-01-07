// debug FLAGS
// #define DEBUG_RENDER_ORDER

// in vec2 vertices;

flat out vec3 o_normal;
out vec3 o_uvw;
flat out int o_side;
out vec2 o_tex_uv;

#ifdef DEBUG_RENDER_ORDER
flat out float plane_render_idx;
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
    // How do we do this for non-cubic chunks?
    ivec3 size = textureSize(voxel_id, 0);
    int dim = 2, id = gl_InstanceID;
    if (gl_InstanceID > size.z + size.y + 1) {
        dim = 0;
        id = gl_InstanceID - (size.z + size.y + 2);
    } else if (gl_InstanceID > size.z) {
        dim = 1;
        id = gl_InstanceID - (size.z + 1);
    }

#ifdef DEBUG_RENDER_ORDER
    plane_render_idx = float(id) / float(size[dim]-1);
#endif

    // plane placement
    // Figure out which plane to start with
    vec3 normal = get_normalmatrix() * unit_vecs[dim];
    float dir = sign(dot(get_view_direction(), normal));
    vec3 displacement;
    if (depthsorting) {
        // depthsorted should start far away from viewer so every plane draws
        displacement = ((0.5 + 0.5 * dir) * float(size[dim]) - dir * float(id)) * unit_vecs[dim];
    } else {
        // no sorting should start at viewer and expand in view direction so
        // that depth test can quickly eliminate unnecessary fragments
        vec4 origin = get_model() * vec4(0, 0, 0, 1);
        float dist = dot(get_eyeposition() - origin.xyz / origin.w, normal) / dot(normal, normal);
        float start = clamp(dist, 0.0, float(size[dim]));
        // this should work better with integer modulo...
        displacement = mod(start + dir * float(id), float(size[dim]) + 0.001) * unit_vecs[dim];
    }

    // place plane vertices
    vec3 voxel_pos = vec3(size) * (orientations[dim] * get_position()) + displacement;
    vec4 world_pos = get_model() * vec4(voxel_pos, 1.0f);
    gl_Position = projection * view * world_pos;
    gl_Position.z += gl_Position.w * get_depth_shift();

    // For each plane the normal is constant and its direction is given by the
    // `displacement` direction, i.e. `n = unit_vecs[dim]`. We just need to derive
    // whether it's +n or -n.
    // If we assume the viewer to be outside of a voxel, the normal direction
    // should always be facing them. Thus:
    o_camdir = get_eyeposition() - world_pos.xyz / world_pos.w;
    float normal_dir = sign(dot(o_camdir, normal));
    o_normal = normalize(normal_dir * normal);

    // The texture coordinate can also be derived. `voxel_pos` effectively gives
    // an integer index into the chunk, shifted to be centered. We can convert
    // this to a float index into the voxel_id texture by normalizing.
    // The minor ceveat here is that because planes are drawn between voxels we
    // would be sampling between voxels like this. To fix this we want to shift
    // the uvw coordinate to the relevant voxel center, which we can do using the
    // normal direction.
    // Here we want to shift in -normal direction to get a front face. Consider
    // this example with 1, 2 solid, 0 air and v the viewer:
    // | 1 | 2 | 0 |   v
    // If we shift in +normal direction (towards viewer) the planes would sample
    // from the id closer to the viewer, drawing a backface.
    o_uvw = (voxel_pos - 0.5 * o_normal) / vec3(size);

    // normal in: -x -y -z +x +y +z direction
    o_side = dim + 3 * int(0.5 + 0.5 * normal_dir);

    // map voxel_pos (-w/2 .. w/2 scale) back to 2d (scaled 0 .. w)
    // if the normal is negative invert range (w .. 0)
    o_tex_uv = transpose(orientations[dim]) * (vec3(-normal_dir, normal_dir, 1.0) * voxel_pos);
}