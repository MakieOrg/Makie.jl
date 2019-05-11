precision mediump float;

varying vec3 frag_normal;
varying vec3 frag_position;
varying vec3 frag_lightdir;

vec3 blinnphong(vec3 N, vec3 V, vec3 L, vec3 color){
    float diff_coeff = max(dot(L, N), 0.0);

    // specular coefficient
    vec3 H = normalize(L+V);

    float spec_coeff = pow(max(dot(H, N), 0.0), 8.0);
    if (diff_coeff <= 0.0)
        spec_coeff = 0.0;

    // final lighting model
    return vec3(
        vec3(0.1) * vec3(0.3)  +
        vec3(0.9) * color * diff_coeff +
        vec3(0.3) * spec_coeff
    );
}

void main() {
    vec3 color = blinnphong(frag_normal, frag_position, frag_lightdir, vec3(1, 0, 0));
    gl_FragColor = vec4(color, 1);
}
