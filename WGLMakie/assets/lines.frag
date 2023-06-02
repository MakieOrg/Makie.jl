
uniform vec3 diffuse;
uniform float opacity;

in vec2 vUv;


void main() {

    float alpha = opacity;

	// artifacts appear on some hardware if a derivative is taken within a conditional
    float a = vUv.x;
    float b = (vUv.y > 0.0) ? vUv.y - 1.0 : vUv.y + 1.0;
    float len2 = a * a + b * b;
    float dlen = fwidth(len2);

    if (abs(vUv.y) > 1.0) {
        alpha = 1.0 - smoothstep(1.0 - dlen, 1.0 + dlen, len2);
    }

    vec4 diffuseColor = vec4(diffuse, alpha);
    gl_FragColor = vec4(diffuseColor.rgb, alpha);

}
