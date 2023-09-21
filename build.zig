const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add your executable and configure with
    // target and optimize, specify your root file (ex. main.zig)
    const exe = b.addExecutable(.{
        .name = "mach-glfw-opengl-example",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    // Use mach-glfw
    const glfw_dep = b.dependency("mach_glfw", .{
        .target = exe.target,
        .optimize = exe.optimize,
    });
    exe.addModule("mach-glfw", glfw_dep.module("mach-glfw"));
    try @import("mach_glfw").link(glfw_dep.builder, exe);

    // Same as above for our gl module,
    // because we copied the gl code into the project
    // we instead just create the module inline
    exe.addModule("gl", b.createModule(.{
        .source_file = .{ .path = "libs/gl41.zig" },
    }));

    const cimgui_dep = b.dependency("cimgui", .{
        .target = target,
        .optimize = optimize,
    });

    exe.defineCMacro("CIMGUI_USE_GLFW", "");
    exe.defineCMacro("CIMGUI_USE_OPENGL3", "");
    exe.addIncludePath(.{ .path = "include" });

    exe.linkLibrary(cimgui_dep.artifact("cimgui"));

    // Once all is done, we install our artifact which
    // in this case is our executable
    b.installArtifact(exe);

    // This is basic boilerplate from zig's stock build.zig,
    // We add a run step so we can run `zig build run` to
    // execute our program after building
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Similar to the above but this adds tests
    // and a test step 'zig build test'
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
