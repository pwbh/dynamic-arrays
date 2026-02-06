const std = @import("std");

const Allocator = std.mem.Allocator;

const expect = std.testing.expect;
const expectError = std.testing.expectError;

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

        pub fn at(self: *Self, i: usize) !T {
            if (self.capacity == 0) {
                return error.Empty;
            }

            if (i >= self.len) {
                return error.IndexOutOfBounds;
            }

            return self.arr[i];
        }

        pub fn front(self: *Self) !T {
            if (self.capacity == 0) {
                return error.Empty;
            }

            return self.arr[0];
        }

        pub fn back(self: *Self) !T {
            if (self.capacity == 0) {
                return error.Empty;
            }

            return self.arr[self.len - 1];
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

            if (self.len > 0) {
                @memcpy(new_items[0..self.len], self.arr[0..self.len]);
                self.allocator.free(self.arr);
                self.arr = undefined;
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

        pub fn data(self: *Self) []T {
            return self.arr[0..self.len];
        }
    };
}

test "Vector initializes and deinitializes" {
    const allocator = std.testing.allocator;
    var vec = Vector(i32).init(allocator);
    defer vec.deinit();
}

test "Vector.at() returns the element at given index or appropriate error" {
    const allocator = std.testing.allocator;
    var vec = Vector(i32).init(allocator);
    defer vec.deinit();
    try expectError(error.Empty, vec.at(0));
    try expectError(error.Empty, vec.at(1));
    try vec.push_back(10);
    try expect(try vec.at(0) == 10);
    try expectError(error.IndexOutOfBounds, vec.at(1));
}

test "Vector.front() gets the first element in the array or returns an appropriate error" {
    const allocator = std.testing.allocator;
    var vec = Vector(i32).init(allocator);
    defer vec.deinit();
    try expectError(error.Empty, vec.front());
    try vec.push_back(1);
    try vec.push_back(2);
    try vec.push_back(3);
}
