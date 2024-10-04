function typedarray_to_vectype(typedArray, ndim) {
    if (typedArray instanceof Float32Array) {
        if (ndim === 1) {
            return "float";
        } else {
            return "vec" + ndim;
        }
    } else if (typedArray instanceof Int32Array) {
        if (ndim === 1) {
            return "int";
        } else {
            return "ivec" + ndim;
        }
    } else if (typedArray instanceof Uint32Array) {
        if (ndim === 1) {
            return "uint";
        } else {
            return "uvec" + ndim;
        }
    } else {
        return;
    }
}

export function attribute_type(attribute) {
    if (attribute) {
        return typedarray_to_vectype(attribute.array, attribute.itemSize);
    } else {
        return;
    }
}

export function uniform_type(obj) {
    if (obj instanceof THREE.Uniform) {
        return uniform_type(obj.value);
    } else if (typeof obj === "number") {
        return "float";
    } else if (typeof obj === "boolean") {
        return "bool";
    } else if (obj instanceof THREE.Vector2) {
        return "vec2";
    } else if (obj instanceof THREE.Vector3) {
        return "vec3";
    } else if (obj instanceof THREE.Vector4) {
        return "vec4";
    } else if (obj instanceof THREE.Color) {
        return "vec4";
    } else if (obj instanceof THREE.Matrix3) {
        return "mat3";
    } else if (obj instanceof THREE.Matrix4) {
        return "mat4";
    } else if (obj instanceof THREE.Texture) {
        return "sampler2D";
    } else {
        return "invalid";
    }
}

export function uniforms_to_type_declaration(uniform_dict) {
    let result = "";
    for (const name in uniform_dict) {
        const uniform = uniform_dict[name];
        const type = uniform_type(uniform);
        if (type != "invalid")
            result += `uniform ${type} ${name};\n`;
    }
    return result;
}

export function attributes_to_type_declaration(attributes_dict) {
    let result = "";
    for (const name in attributes_dict) {
        const attribute = attributes_dict[name];
        const type = attribute_type(attribute);
        result += `in ${type} ${name};\n`;
    }
    return result;
}
