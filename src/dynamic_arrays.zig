const std = @import("std");

const Allocator = std.mem.Allocator;

pub fn Vector(comptime T: type) type {
    return struct {
        allocator: Allocator,
        capacity: usize,
        len: usize,
        arr: []T,

        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
                .capacity = 0,
                .len = 0,
                .arr = undefined,
            };
        }

        pub fn get(self: *Self, i: usize) !T {
            if (i >= self.arr.len) {
                return error.IndexOutOfBounds;
            }

            return self.arr[i];
        }

        pub fn push_back(self: *Self, item: T) !void {
            if (self.len >= self.capacity) {
                try self.resize();
            }

            self.arr[self.len] = item;
            self.len += 1;
        }

        fn resize(self: *Self) !void {
            const new_capacity = if (self.capacity == 0) 2 else self.capacity * 2;
            const new_items = try self.allocator.alloc(T, new_capacity);

            if (self.capacity > 0) {
                @memcpy(new_items[0..self.arr.len], self.arr);
            }

            self.arr = new_items;
            self.capacity = new_capacity;
        }

        pub fn deinit(self: *Self) void {
            if (self.capacity > 0) {
                self.allocator.free(self.arr);
            }

            self.* = undefined;
        }

        pub fn items(self: *Self) []T {
            return self.arr[0..self.len];
        }
    };
}
