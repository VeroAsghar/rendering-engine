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
        .context_version_major = 4,
        .context_version_minor = 0,
    }) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);

    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    _ = c.igCreateContext(null);
    defer c.igDestroyContext(null);

    _ = c.igGetIO();
    _ = c.ImGui_ImplGlfw_InitForOpenGL(@ptrCast(window.handle), true);
    defer c.ImGui_ImplOpenGL3_Shutdown();

    const glsl_version = "#version 150";
    _ = c.ImGui_ImplOpenGL3_Init(glsl_version);
    defer c.ImGui_ImplGlfw_Shutdown();

    _ = c.igStyleColorsDark(null);

    var showDemo = true;

    // Wait for the user to close the window.
    while (!window.shouldClose()) {
        glfw.pollEvents();

        c.ImGui_ImplOpenGL3_NewFrame();
        c.ImGui_ImplGlfw_NewFrame();
        c.igNewFrame();

        c.igShowDemoWindow(&showDemo);

        gl.clearColor(1, 0, 1, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);
        c.igRender();
        c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());
        window.swapBuffers();
    }
}
