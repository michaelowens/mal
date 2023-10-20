const std = @import("std");
const Linenoise = @import("linenoise").Linenoise;
const Reader = @import("./reader.zig").Reader;
const Tokenizer = @import("./reader.zig").Tokenizer;
const MalError = @import("./types.zig").MalError;
const Value = @import("./types.zig").Value;
const ValueTag = @import("./types.zig").ValueTag;
const HashMapContext = @import("./types.zig").HashMapContext;
const pr_str = @import("./printer.zig").pr_str;

fn READ(allocator: std.mem.Allocator, input: []const u8) MalError!Value {
    return try Reader.initFromString(allocator, input);
}

fn eval_ast(allocator: std.mem.Allocator, input: Value, env: std.StringHashMap(Value)) MalError!Value {
    return switch (input) {
        .Symbol => |symbol| env.get(symbol) orelse MalError.InvalidSymbol,
        .List => |list| blk: {
            var value = Value{
                .List = std.ArrayList(Value).init(allocator),
            };

            for (list.items) |item| {
                try value.List.append(try EVAL(allocator, item, env));
            }

            break :blk value;
        },
        .Vector => |list| blk: {
            var value = Value{
                .Vector = std.ArrayList(Value).init(allocator),
            };

            for (list.items) |item| {
                try value.Vector.append(try EVAL(allocator, item, env));
            }

            break :blk value;
        },
        .HashMap => |map| blk: {
            var result = Value{ .HashMap = std.HashMap(Value, Value, HashMapContext, std.hash_map.default_max_load_percentage).init(allocator) };
            var it = map.iterator();
            while (it.next()) |kv| {
                try result.HashMap.put(kv.key_ptr.*, try EVAL(allocator, kv.value_ptr.*, env));
            }

            break :blk result;
        },
        else => input,
    };
}

fn EVAL(allocator: std.mem.Allocator, input: Value, env: std.StringHashMap(Value)) MalError!Value {
    return switch (input) {
        .List => |list| blk: {
            if (list.items.len == 0) {
                break :blk input;
            }

            const result = eval_ast(allocator, input, env) catch break :blk input;
            var args = std.ArrayList(Value).init(allocator);
            try args.insertSlice(args.items.len, result.List.items[1..]);
            break :blk result.List.items[0].Fn(args);
        },
        else => try eval_ast(allocator, input, env),
    };
}

fn PRINT(allocator: std.mem.Allocator, input: Value) MalError![]const u8 {
    return pr_str(allocator, input);
}

fn rep(allocator: std.mem.Allocator, input: []const u8, env: std.StringHashMap(Value)) MalError![]const u8 {
    var ast = try READ(allocator, input);
    var result = try EVAL(allocator, ast, env);
    return try PRINT(allocator, result);
}

fn add(args: std.ArrayList(Value)) MalError!Value {
    if (args.items.len != 2) {
        return MalError.InvalidArgumentCount;
    }

    if (@as(ValueTag, args.items[0]) != ValueTag.Integer) {
        return MalError.InvalidArgumentType;
    }

    if (@as(ValueTag, args.items[1]) != ValueTag.Integer) {
        return MalError.InvalidArgumentType;
    }

    return .{ .Integer = std.math.add(isize, args.items[0].Integer, args.items[1].Integer) catch return MalError.Overflow };
}

fn sub(args: std.ArrayList(Value)) MalError!Value {
    if (args.items.len != 2) {
        return MalError.InvalidArgumentCount;
    }

    if (@as(ValueTag, args.items[0]) != ValueTag.Integer) {
        return MalError.InvalidArgumentType;
    }

    if (@as(ValueTag, args.items[1]) != ValueTag.Integer) {
        return MalError.InvalidArgumentType;
    }

    return .{ .Integer = std.math.sub(isize, args.items[0].Integer, args.items[1].Integer) catch return MalError.Overflow };
}

fn mul(args: std.ArrayList(Value)) MalError!Value {
    if (args.items.len != 2) {
        return MalError.InvalidArgumentCount;
    }

    if (@as(ValueTag, args.items[0]) != ValueTag.Integer) {
        return MalError.InvalidArgumentType;
    }

    if (@as(ValueTag, args.items[1]) != ValueTag.Integer) {
        return MalError.InvalidArgumentType;
    }

    return .{ .Integer = std.math.mul(isize, args.items[0].Integer, args.items[1].Integer) catch return MalError.Overflow };
}

fn div(args: std.ArrayList(Value)) MalError!Value {
    if (args.items.len != 2) {
        return MalError.InvalidArgumentCount;
    }

    if (@as(ValueTag, args.items[0]) != ValueTag.Integer) {
        return MalError.InvalidArgumentType;
    }

    if (@as(ValueTag, args.items[1]) != ValueTag.Integer) {
        return MalError.InvalidArgumentType;
    }

    return .{ .Integer = std.math.divExact(isize, args.items[0].Integer, args.items[1].Integer) catch return MalError.DivisionError };
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

    var env = std.StringHashMap(Value).init(allocator);
    try env.put("+", .{ .Fn = &add });
    try env.put("-", .{ .Fn = &sub });
    try env.put("*", .{ .Fn = &mul });
    try env.put("/", .{ .Fn = &div });

    while (try ln.linenoise("user> ")) |input| {
        // defer allocator.free(input);
        try stdout.print("{s}\n", .{try rep(allocator, input, env)});
        try bw.flush();
        try ln.history.add(input);
    }
}
