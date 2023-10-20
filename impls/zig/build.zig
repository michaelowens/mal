const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exes = [_]*std.Build.Step.Compile{
        b.addExecutable(.{
            .name = "step0_repl",
            .root_source_file = .{ .path = "src/step0_repl.zig" },
            .target = target,
            .optimize = optimize,
        }),
        b.addExecutable(.{
            .name = "step1_read_print",
            .root_source_file = .{ .path = "src/step1_read_print.zig" },
            .target = target,
            .optimize = optimize,
        }),
        b.addExecutable(.{
            .name = "step2_eval",
            .root_source_file = .{ .path = "src/step2_eval.zig" },
            .target = target,
            .optimize = optimize,
        }),
        // b.addExecutable(.{
        //     .name = "step3_env",
        //     .root_source_file = .{ .path = "src/step3_env.zig" },
        //     .target = target,
        //     .optimize = optimize,
        // }),
        // b.addExecutable(.{
        //     .name = "step4_if_fn_do",
        //     .root_source_file = .{ .path = "src/step4_if_fn_do.zig" },
        //     .target = target,
        //     .optimize = optimize,
        // }),
        // b.addExecutable(.{
        //     .name = "step5_tco",
        //     .root_source_file = .{ .path = "src/step5_tco.zig" },
        //     .target = target,
        //     .optimize = optimize,
        // }),
        // b.addExecutable(.{
        //     .name = "step6_file",
        //     .root_source_file = .{ .path = "src/step6_file.zig" },
        //     .target = target,
        //     .optimize = optimize,
        // }),
        // b.addExecutable(.{
        //     .name = "step7_quote",
        //     .root_source_file = .{ .path = "src/step7_quote.zig" },
        //     .target = target,
        //     .optimize = optimize,
        // }),
        // b.addExecutable(.{
        //     .name = "step8_macros",
        //     .root_source_file = .{ .path = "src/step8_macros.zig" },
        //     .target = target,
        //     .optimize = optimize,
        // }),
        // b.addExecutable(.{
        //     .name = "step9_try",
        //     .root_source_file = .{ .path = "src/step9_try.zig" },
        //     .target = target,
        //     .optimize = optimize,
        // }),
        // b.addExecutable(.{
        //     .name = "step9_try stepA_mal",
        //     .root_source_file = .{ .path = "src/stepA_mal.zig" },
        //     .target = target,
        //     .optimize = optimize,
        // }),
    };

    // const exe = b.addExecutable(.{
    //     .name = "step0_repl",
    //     // In this case the main source file is merely a path, however, in more
    //     // complicated build scripts, this could be a generated file.
    //     .root_source_file = .{ .path = "src/step0_repl.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    const linenoise = b.dependency("linenoise", .{
        .target = target,
        .optimize = optimize,
    });

    for (exes) |exe| {
        exe.addModule("linenoise", linenoise.module("linenoise"));
        exe.linkLibrary(linenoise.artifact("linenoise"));

        // This declares intent for the executable to be installed into the
        // standard location when the user invokes the "install" step (the default
        // step when running `zig build`).
        b.installArtifact(exe);

        // This *creates* a Run step in the build graph, to be executed when another
        // step is evaluated that depends on it. The next line below will establish
        // such a dependency.
        // const run_cmd = b.addRunArtifact(exe);

        // // By making the run step depend on the install step, it will be run from the
        // // installation directory rather than directly from within the cache directory.
        // // This is not necessary, however, if the application depends on other installed
        // // files, this ensures they will be present and in the expected location.
        // run_cmd.step.dependOn(b.getInstallStep());

        // // This allows the user to pass arguments to the application in the build
        // // command itself, like this: `zig build run -- arg1 arg2 etc`
        // if (b.args) |args| {
        //     run_cmd.addArgs(args);
        // }

        // // This creates a build step. It will be visible in the `zig build --help` menu,
        // // and can be selected like this: `zig build run`
        // // This will evaluate the `run` step rather than the default, which is "install".
        // const run_step = b.step("run", "Run the app");
        // run_step.dependOn(&run_cmd.step);
    }

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    // const unit_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/main.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_unit_tests.step);
}
