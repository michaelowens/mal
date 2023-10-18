const std = @import("std");
const Linenoise = @import("linenoise").Linenoise;
const Reader = @import("./reader.zig").Reader;
const Tokenizer = @import("./reader.zig").Tokenizer;
const Value = @import("./types.zig").Value;
const pr_str = @import("./printer.zig").pr_str;

fn READ(allocator: std.mem.Allocator, input: []const u8) !Value {
    return try Reader.initFromString(allocator, input);
}

fn EVAL(input: Value) Value {
    return input;
}

fn PRINT(allocator: std.mem.Allocator, input: Value) ![]const u8 {
    return pr_str(allocator, input);
}

fn rep(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var ast = try READ(allocator, input);
    var result = EVAL(ast);
    return try PRINT(allocator, result);
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
        try stdout.print("{s}\n", .{try rep(allocator, input)});
        try bw.flush();
        try ln.history.add(input);
    }
}
