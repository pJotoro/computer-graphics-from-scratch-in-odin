package main

/*

app.gl_init(4, 5)




Vertex :: struct {
    position: Vector2f32,
    uv: Vector2f32,
    color: Vector3f32,
}

vbo: u32
{
    data := [?]Vertex{
        { { -0.00, +0.75 }, { 25.0, 50.0}, { 1, 0, 0 } },
        { { +0.75, -0.50 }, {  0.0,  0.0}, { 0, 1, 0 } },
        { { -0.75, -0.50 }, { 50.0,  0.0}, { 0, 0, 1 } },
    }
    gl.CreateBuffers(1, &vbo)
    gl.NamedBufferStorage(vbo, size_of(data), &data[0], 0)
}

vao: u32
{
    gl.CreateVertexArrays(1, &vao)

    vbuf_index := u32(0)
    gl.VertexArrayVertexBuffer(vao, vbuf_index, vbo, 0, size_of(Vertex))

    a_pos := u32(0)
    gl.VertexArrayAttribFormat(vao, a_pos, 2, gl.FLOAT, gl.FALSE, u32(offset_of(Vertex, position)))
    gl.VertexArrayAttribBinding(vao, a_pos, vbuf_index)
    gl.EnableVertexArrayAttrib(vao, a_pos)

    a_uv := u32(1)
    gl.VertexArrayAttribFormat(vao, a_uv, 2, gl.FLOAT, gl.FALSE, u32(offset_of(Vertex, uv)))
    gl.VertexArrayAttribBinding(vao, a_uv, vbuf_index)
    gl.EnableVertexArrayAttrib(vao, a_uv)

    a_color := u32(2)
    gl.VertexArrayAttribFormat(vao, a_color, 3, gl.FLOAT, gl.FALSE, u32(offset_of(Vertex, color)));
    gl.VertexArrayAttribBinding(vao, a_color, vbuf_index);
    gl.EnableVertexArrayAttrib(vao, a_color);
}

texture: u32
{
    pixels := [?]u32{
        0x80000000, 0xffffffff,
        0xffffffff, 0x80000000,
    }

    gl.CreateTextures(gl.TEXTURE_2D, 1, &texture);
    gl.TextureParameteri(texture, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.TextureParameteri(texture, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.TextureParameteri(texture, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.TextureParameteri(texture, gl.TEXTURE_WRAP_T, gl.REPEAT);

    width := i32(2)
    height := i32(2)
    gl.TextureStorage2D(texture, 1, gl.RGBA8, width, height);
    gl.TextureSubImage2D(texture, 0, 0, 0, width, height, gl.RGBA, gl.UNSIGNED_BYTE, &pixels[0]);
}

pipeline, vshader, fshader: u32
{
    glsl_vshader := cstring(`
    #version 450 core                             
                                                  
    layout (location=0) in vec2 a_pos;             // position attribute index 0
    layout (location=1) in vec2 a_uv;              // uv attribute index 1
    layout (location=2) in vec3 a_color;           // color attribute index 2
                                                  
    layout (location=0)                            // (from ARB_explicit_uniform_location)
    uniform mat2 u_matrix;                         // matrix uniform location 0
                                                  
    out gl_PerVertex { vec4 gl_Position; };        // required because of ARB_separate_shader_objects
    out vec2 uv;                                  
    out vec4 color;                               
                                                  
    void main()                                   
    {                                             
        vec2 pos = u_matrix * a_pos;              
        gl_Position = vec4(pos, 0, 1);            
        uv = a_uv;                                
        color = vec4(a_color, 1);                 
    }                                             
    `)

    glsl_fshader := cstring(`
    #version 450 core                             
                                                    
    in vec2 uv;                                   
    in vec4 color;                                
                                                    
    layout (binding=0)                             // (from ARB_shading_language_420pack)
    uniform sampler2D s_texture;                   // texture unit binding 0
                                                    
    layout (location=0)                           
    out vec4 o_color;                              // output fragment data location 0
                                                    
    void main()                                   
    {                                             
        o_color = color * texture(s_texture, uv); 
    }                                             
    `)

    vshader = gl.CreateShaderProgramv(gl.VERTEX_SHADER, 1, &glsl_vshader)
    fshader = gl.CreateShaderProgramv(gl.FRAGMENT_SHADER, 1, &glsl_fshader)

    linked: i32
    gl.GetProgramiv(vshader, gl.LINK_STATUS, &linked)
    assert(linked != 0)
    gl.GetProgramiv(fshader, gl.LINK_STATUS, &linked)
    assert(linked != 0)

    gl.GenProgramPipelines(1, &pipeline)
    gl.UseProgramStages(pipeline, gl.VERTEX_SHADER_BIT, vshader)
    gl.UseProgramStages(pipeline, gl.FRAGMENT_SHADER_BIT, fshader)
}

{
    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

    gl.Disable(gl.DEPTH_TEST)

    gl.Disable(gl.CULL_FACE)
}

angle: f32









gl.Viewport(0, 0, i32(app.width()), i32(app.height()))

        gl.ClearColor(0.392, 0.584, 0.929, 1)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT | gl.STENCIL_BUFFER_BIT)

        {
            delta := f32(1.0 / 144.0)
            angle += delta * 2 * math.PI / 20
            angle = math.mod(angle, 2 * math.PI)

            aspect := f32(app.height()) / f32(app.width())
            m := [?]f32{
                math.cos(angle) * aspect, -math.sin(angle),
                math.sin(angle) * aspect, math.cos(angle),
            }

            u_matrix: i32
            gl.ProgramUniformMatrix2fv(vshader, u_matrix, 1, gl.FALSE, &m[0])
        }

        gl.BindProgramPipeline(pipeline)

        gl.BindVertexArray(vao)

        s_texture: u32
        gl.BindTextureUnit(s_texture, texture)

        gl.DrawArrays(gl.TRIANGLES, 0, 3)

        app.gl_swap_buffers()
*/