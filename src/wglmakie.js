
function create_texture(data){
    if (data.size.length == 3){
        return new THREE.DataTexture3D(
            data.data, data.size[0], data.size[1], data.size[3],
            data.three_format, data.three_type
        )
    } else {
        return new THREE.DataTexture(
            data.data, data.size[0], data.size[1],
            data.three_format, data.three_type
        )
    }
}

function convert_texture(data){
    const tex = create_texture(data)
    tex.needsUpdate = true
    tex.minFilter = data.minFilter
    tex.magFilter = data.magFilter
    tex.anisotropy = data.anisotropy
    tex.wrapS = data.wrapS
    if (data.size.length > 2){
        tex.wrapT = data.wrapT
    }
    if (data.size.length > 3){
        tex.wrapR = data.wrapR
    }
    return tex
}

function deserialize_three(data){
    if (typeof data === "number"){
        return data
    }
    if (typeof data === "string"){
        // since we don't use strings together with deserialize_three, this must be
        // a three global!
        return THREE[data]
    }
    if (data.type !== undefined) {
        if (data.type == "Sampler"){
            return convert_texture(data)
        }
        const array_types = [
            "Uint8Array",
            "Int32Array",
            "Uint32Array",
            "Float32Array"]

        if (array_types.includes(data.type)) {
            return new window[data.type](data.data)
        }
    }
    if (is_list(data)) {
        if (data.length == 2) {
            return new THREE.Vector2(data)
        }
        if (data.length == 3) {
            return new THREE.Vector3(data)
        }
        if (data.length == 4) {
            return new THREE.Vector4(data)
        }
        if (data.length == 16){
            const mat = THREE.new.Matrix4()
            mat.fromArray(data)
            return mat
        }
    }
    // Ok, WHAT ON EARTH IS THIS?!!? WHAT HAVE WE DONE?
    throw `Data isn't a recognized three data type: ${JSON.stringify(data)}`
}

function BufferAttribute(buffer) {
    const jsbuff = new Float32BufferAttribute(buffer.flat, buffer.element_length);
    jsbuff.setUsage(three.DynamicDrawUsage);
    return jsbuff
}

function InstanceBufferAttribute(buffer) {
    const jsbuff = new InstancedBufferAttribute(buffer.flat, buffer.element_length);
    jsbuff.setUsage(three.DynamicDrawUsage);
    return jsbuff
}

function attach_geometry(buffer_geometry, vertexarrays, faces) {
    for(const name in vertexarrays) {
        const buffer = BufferAttribute(vertexarrays[name]);
        buffer_geometry.setAttribute(name, buffer);
    }
    buffer_geometry.setIndex(faces);
    buffer_geometry.boundingSphere = new Sphere()
    // don't use intersection / culling
    buffer_geometry.boundingSphere.radius = 10000000000000f0
    return buffer_geometry;
}

function attach_instanced_geometry(buffer_geometry, instance_attributes) {
    for(const name in instance_attributes) {
        const buffer = InstanceBufferAttribute(instance_attributes[name]);
        buffer_geometry.setAttribute(name, buffer);
    }
}

function recreate_instanced_geometry(mesh, vertexarrays, faces, instance_attributes) {
    const buffer_geometry = new THREE.InstancedBufferGeometry();
    attach_geometry(buffer_geometry, vertexarrays, faces)
    attach_instanced_geometry(buffer_geometry, instance_attributes);
    mesh.geometry = buffer_geometry;
    mesh.needsUpdate = true;
}

function recreate_geometry(mesh, vertexarrays, faces) {
    const buffer_geometry = new THREE.BufferGeometry();
    attach_geometry(buffer_geometry, vertexarrays, faces);
    mesh.geometry = buffer_geometry;
    mesh.needsUpdate = true;
}

function update_buffer(mesh, buffer){
    const {name, flat, len} = buffer;
    const geometry = mesh.geometry;
    const jsb = geometry.attributes[name];
    jsb.set(flat, 0)
    jsb.needsUpdate = true
    geometry.instanceCount = len
}

function create_material(program){
    return new THREE.RawShaderMaterial({
        uniforms: program.uniforms,
        vertexShader: program.vertex_source,
        fragmentShader: program.fragment_source,
        side: THREE.DoubleSide,
        transparent: true,
        // depthTest: true,
        // depthWrite: true
    })
}

function create_mesh(program){
    const buffer_geometry = new THREE.BufferGeometry()
    attach_geometry(buffer_geometry, program.vertexarrays, program.faces)
    const material = create_material(
        program.vertex_source,
        program.fragment_source,
        program.uniforms
    )
    return new THREE.Mesh(buffer_geometry, material);
}

function create_instanced_mesh(ip){
    const buffer_geometry = new THREE.InstancedBufferGeometry()
    attach_geometry(buffer_geometry, program.vertexarrays, program.faces)
    attach_instanced_geometry(buffer_geometry, program.instance_attributes);
    const material = create_material(program)

    return new THREE.Mesh(buffer_geometry, material);
}
