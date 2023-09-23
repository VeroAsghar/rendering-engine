const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const c = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "");
    @cInclude("cimgui.h");
    @cInclude("cimgui_impl.h");
});
const log = std.log.scoped(.Engine);

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = glfw.Window.create(640, 480, "mach-glfw + zig-opengl", null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 3,
        .context_version_minor = 3,
    }) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);

    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    const vertex_shader_source =
        \\#version 330 core
        \\layout (location = 0) in vec3 aPos;
        \\void main() {
        \\       gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
        \\}
    ;

    var vertex_shader: gl.GLuint = undefined;
    vertex_shader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertex_shader, 1, &&vertex_shader_source[0], null);
    gl.compileShader(vertex_shader);

    var success: gl.GLint = undefined;
    gl.getShaderiv(vertex_shader, gl.COMPILE_STATUS, &success);

    if (success == 0) {
        return error.ShaderCompilationFailed;
    }

    const frag_shader_source =
        \\#version 330 core
        \\out vec4 FragColor;
        \\void main() {
        \\    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
        \\}
    ;

    var frag_shader: gl.GLuint = undefined;
    frag_shader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(frag_shader, 1, &&frag_shader_source[0], null);
    gl.compileShader(frag_shader);

    gl.getShaderiv(frag_shader, gl.COMPILE_STATUS, &success);

    if (success == 0) {
        return error.ShaderCompilationFailed;
    }

    var shader_program: gl.GLuint = undefined;
    shader_program = gl.createProgram();
    defer gl.deleteProgram(shader_program);

    gl.attachShader(shader_program, vertex_shader);
    gl.attachShader(shader_program, frag_shader);
    gl.linkProgram(shader_program);
    gl.getProgramiv(shader_program, gl.LINK_STATUS, &success);
    var info_log: [512]u8 = undefined;
    if (success == 0) {
        gl.getProgramInfoLog(shader_program, 512, null, &info_log);
        std.debug.print("{s}\n", .{info_log});
        return error.ShaderProgramCompilationFailed;
    }
    gl.deleteShader(vertex_shader);
    gl.deleteShader(frag_shader);

    _ = c.igCreateContext(null);
    defer c.igDestroyContext(null);

    _ = c.igGetIO();
    _ = c.ImGui_ImplGlfw_InitForOpenGL(@ptrCast(window.handle), true);
    defer c.ImGui_ImplOpenGL3_Shutdown();

    const glsl_version = "#version 330 core";
    _ = c.ImGui_ImplOpenGL3_Init(glsl_version);
    defer c.ImGui_ImplGlfw_Shutdown();

    _ = c.igStyleColorsDark(null);

    var showDemo = true;

    var VAO: gl.GLuint = undefined;
    gl.genVertexArrays(1, &VAO);
    defer gl.deleteVertexArrays(1, &VAO);

    var VBO: gl.GLuint = undefined;
    gl.genBuffers(1, &VBO);
    defer gl.deleteBuffers(1, &VBO);

    gl.bindVertexArray(VAO);
    gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(f32) * vertices.len, &vertices, gl.STATIC_DRAW);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), @ptrFromInt(0));
    gl.enableVertexAttribArray(0);

    // Wait for the user to close the window.
    while (!window.shouldClose()) {
        c.ImGui_ImplOpenGL3_NewFrame();
        c.ImGui_ImplGlfw_NewFrame();
        c.igNewFrame();
        c.igShowDemoWindow(&showDemo);

        gl.clearColor(0.2, 0.3, 0.3, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.useProgram(shader_program);
        gl.bindVertexArray(VAO);
        gl.drawArrays(gl.TRIANGLES, 0, 3);

        c.igRender();
        c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());

        window.swapBuffers();
        glfw.pollEvents();
    }
}

const vertices = [_]f32{
    -0.5, -0.5, 0.0,
    0.5,  -0.5, 0.0,
    0.0,  0.5,  0.0,
};
