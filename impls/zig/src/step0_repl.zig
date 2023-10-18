const std = @import("std");
const Linenoise = @import("linenoise").Linenoise;

fn READ(input: []const u8) []const u8 {
    return input;
}

fn EVAL(input: []const u8) []const u8 {
    return input;
}

fn PRINT(input: []const u8) []const u8 {
    return input;
}

fn rep(input: []const u8) []const u8 {
    var ast = READ(input);
    var result = EVAL(ast);
    return PRINT(result);
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var ln = Linenoise.init(allocator);
    defer ln.deinit();

    const stdout_writer = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_writer);
    const stdout = bw.writer();

    while (try ln.linenoise("user> ")) |input| {
        defer allocator.free(input);
        try stdout.print("{s}\n", .{rep(input)});
        try bw.flush();
        try ln.history.add(input);
    }
}
