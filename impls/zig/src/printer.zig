const std = @import("std");
const Value = @import("./types.zig").Value;
const ValueTag = @import("./types.zig").ValueTag;

pub fn pr_str(value: Value, allocator: std.mem.Allocator) ![]const u8 {
    return switch (value) {
        ValueTag.List => |list| blk: {
            var result = std.ArrayList(u8).init(allocator);
            // FIXME: can't deinit due to memory being freed when returning. Is this necessary though when using an arena?
            // defer result.deinit();

            try result.append('(');
            for (list.items) |item| {
                _ = try result.writer().write(try pr_str(item, allocator));
                try result.append(' ');
            }
            if (result.items.len > 1) {
                result.items[result.items.len - 1] = ')';
            } else {
                _ = try result.append(')');
            }
            break :blk result.items;
        },
        ValueTag.Vector => |list| blk: {
            var result = std.ArrayList(u8).init(allocator);
            // FIXME: can't deinit due to memory being freed when returning. Is this necessary though when using an arena?
            // defer result.deinit();

            try result.append('[');
            for (list.items) |item| {
                _ = try result.writer().write(try pr_str(item, allocator));
                try result.append(' ');
            }
            if (result.items.len > 1) {
                result.items[result.items.len - 1] = ']';
            } else {
                _ = try result.append(']');
            }
            break :blk result.items;
        },
        ValueTag.HashMap => |map| blk: {
            var result = std.ArrayList(u8).init(allocator);
            // FIXME: can't deinit due to memory being freed when returning. Is this necessary though when using an arena?
            // defer result.deinit();

            try result.append('{');
            var it = map.iterator();
            while (it.next()) |kv| {
                _ = try result.writer().write(try pr_str(kv.key_ptr.*, allocator));
                try result.append(' ');
                _ = try result.writer().write(try pr_str(kv.value_ptr.*, allocator));
                try result.append(' ');
            }
            if (result.items.len > 1) {
                result.items[result.items.len - 1] = '}';
            } else {
                _ = try result.append('}');
            }
            break :blk result.items;
        },
        ValueTag.Number => |i| try std.fmt.allocPrint(allocator, "{d}", .{i}),
        ValueTag.Symbol => |str| str,
    };
}
