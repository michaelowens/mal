const std = @import("std");
const pr_str = @import("./printer.zig").pr_str;

pub const MalError = error{
    InvalidArgumentCount,
    InvalidArgumentType,
    InvalidSymbol,
    Overflow,
    DivisionError,

    // Reader
    ReadFormError,
    ReadAtomError,
    ReadQuotedValueError,
    ReadWithMetaError,
    ParseIntError,
    OutOfMemory,
};

pub const ValueTag = enum {
    Integer,
    Symbol,
    List,
    Vector,
    HashMap,
    Fn,
};

pub const Value = union(ValueTag) {
    Integer: isize,
    Symbol: []const u8,
    List: std.ArrayList(Value),
    Vector: std.ArrayList(Value),
    HashMap: std.HashMap(Value, Value, HashMapContext, std.hash_map.default_max_load_percentage),
    Fn: *const fn (args: std.ArrayList(Value)) MalError!Value, // TODO: find way to get rid of ArrayList
};

pub const HashMapContext = struct {
    pub fn hash(self: @This(), v: Value) u64 {
        _ = self;

        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        const s = pr_str(allocator, v) catch "";
        return std.hash.Wyhash.hash(0, s);
    }

    pub fn eql(self: @This(), a: Value, b: Value) bool {
        _ = self;
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        const a_str = pr_str(allocator, a) catch return false;
        const b_str = pr_str(allocator, b) catch return false;
        return std.mem.eql(u8, a_str, b_str);
    }
};
