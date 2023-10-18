const std = @import("std");
const Linenoise = @import("linenoise").Linenoise;
const Reader = @import("./reader.zig").Reader;
const Tokenizer = @import("./reader.zig").Tokenizer;
const Value = @import("./types.zig").Value;
const pr_str = @import("./printer.zig").pr_str;

fn READ(input: []const u8, allocator: std.mem.Allocator) !Value {
    return try Reader.initFromString(input, allocator);
}

fn EVAL(input: Value) Value {
    return input;
}

fn PRINT(input: Value, allocator: std.mem.Allocator) ![]const u8 {
    return pr_str(input, allocator);
}

fn rep(input: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    var ast = try READ(input, allocator);
    var result = EVAL(ast);
    return try PRINT(result, allocator);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var ln = Linenoise.init(allocator);
    defer ln.deinit();

    const stdout_writer = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_writer);
    const stdout = bw.writer();

    while (try ln.linenoise("user> ")) |input| {
        // defer allocator.free(input);
        try stdout.print("{s}\n", .{try rep(input, allocator)});
        try bw.flush();
        try ln.history.add(input);
    }
}
