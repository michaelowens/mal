const std = @import("std");
const Value = @import("./types.zig").Value;
const HashMapContext = @import("./types.zig").HashMapContext;

const Token = []const u8;

pub const Tokenizer = struct {
    const Self = @This();

    str: []const u8,
    index: usize = 0,

    pub fn init(input: []const u8) Self {
        return .{ .str = input };
    }

    pub fn next(self: *Self) ?Token {
        while (self.index < self.str.len) {
            // std.debug.print("parsing {any}/{any}\n", .{ self.index, self.str.len });
            var c = self.str[self.index];
            switch (c) {
                ' ', '\t', '\n', ',' => {
                    // std.debug.print("whitespace\n", .{});
                },

                '~' => {
                    if (self.index + 1 < self.str.len and self.str[self.index + 1] == '@') {
                        self.index += 2;
                        return self.str[self.index - 2 .. self.index];
                    }
                    self.index += 1;
                    return self.str[self.index - 1 .. self.index];
                },

                '[', ']', '{', '}', '(', ')', '\'', '`', '^', '@' => {
                    self.index += 1;
                    return self.str[self.index - 1 .. self.index];
                },

                '"' => {
                    var start: usize = self.index;
                    self.index += 1;
                    while (self.index < self.str.len) {
                        c = self.str[self.index];
                        switch (c) {
                            '"' => {
                                self.index += 1;
                                return self.str[start..self.index];
                            },
                            '\\' => {
                                self.index += 1;
                            },
                            else => {},
                        }

                        self.index += 1;
                    }
                    return "EOF"; //std.debug.print("EOF", .{});
                    // return self.str[start..self.index];
                },

                ';' => {
                    var start: usize = self.index;
                    self.index += 1;
                    while (self.index < self.str.len) {
                        c = self.str[self.index];
                        if (c == '\n')
                            break;
                        self.index += 1;
                    }
                    return self.str[start..self.index];
                },

                else => {
                    var start: usize = self.index;
                    var done = false;
                    self.index += 1;
                    while (!done and self.index < self.str.len) {
                        c = self.str[self.index];
                        switch (c) {
                            ' ', '\t', '\n', ',', '[', ']', '{', '}', '(', ')', '\'', '`', ';' => {
                                done = true;
                                break;
                            },
                            else => {
                                self.index += 1;
                            },
                        }
                    }
                    return self.str[start..self.index];
                },
            }
            self.index += 1;
        }

        return null;
    }
};

const ReaderErrors = error{
    ReadFormError,
    ReadAtomError,
    ReadQuotedValueError,
    ReadWithMetaError,
    ParseIntError,
    OutOfMemory,
};

pub const Reader = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    tokens: std.ArrayList(Token),
    index: usize = 0,

    pub fn init(allocator: std.mem.Allocator, tokens: std.ArrayList(Token)) Self {
        return .{
            .tokens = tokens,
            .allocator = allocator,
        };
    }

    pub fn initFromString(allocator: std.mem.Allocator, input: []const u8) !Value {
        var tokens = try Reader.tokenize(allocator, input);
        var reader = Reader.init(allocator, tokens);
        return try reader.read_form();
    }

    pub fn tokenize(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Token) {
        var tokenizer = Tokenizer.init(input);
        var tokens = std.ArrayList(Token).init(allocator);
        while (tokenizer.next()) |token| {
            try tokens.append(token);
        }
        return tokens;
    }

    pub fn read_form(self: *Self) ReaderErrors!Value {
        var c = self.peek() orelse return error.ReadFormError;
        return switch (c[0]) {
            '(' => self.read_list(),
            '[' => self.read_vector(),
            '{' => self.read_hash_map(),
            '\'', '`', '~', '@' => self.read_quoted_value(),
            '^' => self.read_with_meta(),
            else => self.read_atom(),
        };
    }

    pub fn read_list(self: *Self) ReaderErrors!Value {
        _ = self.next(); // consume '('

        var value = Value{
            .List = std.ArrayList(Value).init(self.allocator),
        };

        while (self.peek()) |t| {
            if (t[0] == ')') {
                _ = self.next();
                return value;
            }
            var result = try self.read_form();
            try value.List.append(result);
        }

        std.debug.print("EOF", .{});
        return value;
    }

    pub fn read_vector(self: *Self) ReaderErrors!Value {
        _ = self.next(); // consume '['

        var value = Value{
            .Vector = std.ArrayList(Value).init(self.allocator),
        };

        while (self.peek()) |t| {
            if (t[0] == ']') {
                _ = self.next();
                return value;
            }
            var result = try self.read_form();
            try value.Vector.append(result);
        }

        std.debug.print("EOF", .{});
        return value;
    }

    pub fn read_hash_map(self: *Self) ReaderErrors!Value {
        _ = self.next(); // consume '{'

        var value = Value{
            .HashMap = std.HashMap(Value, Value, HashMapContext, std.hash_map.default_max_load_percentage).init(self.allocator),
        };

        while (self.peek()) |t| {
            if (t[0] == '}') {
                _ = self.next();
                return value;
            }
            var key = try self.read_form();

            const t2 = self.peek() orelse {
                std.debug.print("EOF", .{});
                return value;
            };
            if (t2[0] == '}') {
                std.debug.print("hash-map key without value!\n", .{});
                _ = self.next();
                return value;
            }

            var val = try self.read_form();
            try value.HashMap.put(key, val);
        }

        std.debug.print("EOF", .{});
        return value;
    }

    pub fn read_quoted_value(self: *Self) ReaderErrors!Value {
        var t = self.peek() orelse return ReaderErrors.ReadQuotedValueError;
        switch (t[0]) {
            '\'' => {
                _ = self.next(); // consume "'"
                var result = Value{ .List = std.ArrayList(Value).init(self.allocator) };
                try result.List.append(Value{ .Symbol = "quote" });
                try result.List.append(try self.read_form());
                return result;
            },
            '`' => {
                _ = self.next(); // consume "`"
                var result = Value{ .List = std.ArrayList(Value).init(self.allocator) };
                try result.List.append(Value{ .Symbol = "quasiquote" });
                try result.List.append(try self.read_form());
                return result;
            },
            '~' => {
                if (t.len > 1 and t[1] == '@') {
                    _ = self.next(); // consume "~@"
                    var result = Value{ .List = std.ArrayList(Value).init(self.allocator) };
                    try result.List.append(Value{ .Symbol = "splice-unquote" });
                    try result.List.append(try self.read_form());
                    return result;
                } else {
                    _ = self.next(); // consume "~"
                    var result = Value{ .List = std.ArrayList(Value).init(self.allocator) };
                    try result.List.append(Value{ .Symbol = "unquote" });
                    try result.List.append(try self.read_form());
                    return result;
                }
            },
            '@' => { // FIXME: this probably shouldn't be here
                _ = self.next(); // consume "'"
                var result = Value{ .List = std.ArrayList(Value).init(self.allocator) };
                try result.List.append(Value{ .Symbol = "deref" });
                try result.List.append(try self.read_form());
                return result;
            },
            else => {
                std.debug.print("unknown quote!\n", .{});
                return error.ReadQuotedValueError;
            },
        }
    }

    pub fn read_with_meta(self: *Self) ReaderErrors!Value {
        _ = self.next(); // consume '^'

        var value = self.read_form() catch return ReaderErrors.ReadWithMetaError;
        var meta = self.read_form() catch return ReaderErrors.ReadWithMetaError;
        var result = Value{ .List = std.ArrayList(Value).init(self.allocator) };
        try result.List.append(Value{ .Symbol = "with-meta" });
        try result.List.append(meta);
        try result.List.append(value);
        return result;
    }

    pub fn read_atom(self: *Self) ReaderErrors!Value {
        var t = self.next() orelse return ReaderErrors.ReadAtomError;
        return switch (t[0]) {
            '0'...'1' => blk: {
                var i = std.fmt.parseInt(isize, t, 10) catch return ReaderErrors.ParseIntError;
                break :blk Value{ .Number = i };
            },
            else => return Value{ .Symbol = t },
        };
    }

    pub fn next(self: *Self) ?Token {
        if (self.index < self.tokens.items.len) {
            self.index += 1;
            return self.tokens.items[self.index - 1];
        }
        return null;
    }

    pub fn peek(self: Self) ?Token {
        if (self.index < self.tokens.items.len)
            return self.tokens.items[self.index];
        return null;
    }
};
