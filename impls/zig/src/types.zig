const std = @import("std");
const pr_str = @import("./printer.zig").pr_str;

pub const ValueTag = enum {
    Number,
    Symbol,
    List,
    Vector,
    HashMap,
};

pub const Value = union(ValueTag) {
    Number: isize,
    Symbol: []const u8,
    List: std.ArrayList(Value),
    Vector: std.ArrayList(Value),
    HashMap: std.HashMap(Value, Value, HashMapContext, std.hash_map.default_max_load_percentage),
};

pub const HashMapContext = struct {
    pub fn hash(self: @This(), v: Value) u64 {
        _ = self;

        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        const s = pr_str(v, allocator) catch "";
        return std.hash.Wyhash.hash(0, s);
    }

    pub fn eql(self: @This(), a: Value, b: Value) bool {
        _ = self;
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        const a_str = pr_str(a, allocator) catch return false;
        const b_str = pr_str(b, allocator) catch return false;
        return std.mem.eql(u8, a_str, b_str);
    }
};
