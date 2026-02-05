const std = @import("std");

const Allocator = std.mem.Allocator;

pub fn Vector(comptime T: type) type {
    return struct {
        allocator: Allocator,
        capacity: usize,
        items: ?[]T,

        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
                .capacity = 4,
                .items = null,
            };
        }

        pub fn get(self: *Self, i: usize) !T {
            if (self.items) {
                if (i >= self.items.len) {
                    return error.IndexOutOfBounds;
                }

                return self.items[i];
            }

            return error.Empty;
        }

        pub fn push_back(self: *Self, item: T) !void {
            if (self.items) |items| {
                const next_length = items.len + 1;

                if (next_length > self.capacity) {
                    self.capacity *= 2;
                    self.items = try cpy_resize(self.allocator, self.capacity, items);
                }

                self.items.?[next_length] = item;
            } else {
                self.items = try cpy_resize(self.allocator, self.capacity, null);
            }
        }

        fn cpy_resize(allocator: Allocator, capacity: usize, current_items: ?[]T) ![]T {
            const new_items = try allocator.alloc(T, capacity);
            if (current_items) |items| {
                @memcpy(new_items, items);
                allocator.free(items);
            }
            return new_items;
        }

        pub fn destroy(self: *Self) void {
            if (self.items) |items| {
                self.allocator.free(items);
                self.items = null;
            }
        }
    };
}
