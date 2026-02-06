const std = @import("std");
const math = std.math;

const Allocator = std.mem.Allocator;

const assert = std.debug.assert;

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
                .arr = &.{},
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

        pub fn pushBack(self: *Self, item: T) !void {
            if (self.len >= self.capacity) {
                try self.resize();
            }

            self.arr[self.len] = item;
            self.len += 1;
        }

        pub fn begin(self: *Self) VectorIterator(T) {
            return .{
                .buffer = self.arr[0..self.len],
                .index = 0,
            };
        }

        pub fn end(self: *Self) VectorIterator(T) {
            return .{
                .buffer = self.arr[0..self.len],
                .index = self.len - 1,
            };
        }

        pub fn rbegin(self: *Self) VectorReverseIterator(T) {
            return .{
                .buffer = self.arr[0..self.len],
                .index = 0,
            };
        }

        pub fn rend(self: *Self) VectorReverseIterator(T) {
            return .{
                .buffer = self.arr[0..self.len],
                .index = self.len - 1,
            };
        }

        fn maxSize(self: *Self) usize {
            _ = self;
            return math.maxInt(usize);
        }

        fn resize(self: *Self) !void {
            const new_capacity = if (self.capacity == 0) 2 else self.capacity * 2;
            const new_items = try self.allocator.alloc(T, new_capacity);

            if (self.len > 0) {
                @memcpy(new_items[0..self.len], self.arr[0..self.len]);
                self.allocator.free(self.arr);
                self.arr = &.{};
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

pub fn VectorIterator(comptime T: type) type {
    return struct {
        buffer: []const T = &.{},
        index: ?usize = 0,

        const Self = @This();

        pub fn first(self: *Self) ?T {
            assert(self.index.? == 0);
            return self.next();
        }

        pub fn next(self: *Self) ?T {
            const idx = self.index orelse return null;
            if (idx >= self.buffer.len) return null;
            const item = self.buffer[idx];
            self.index.? += 1;
            return item;
        }
    };
}

pub fn VectorReverseIterator(comptime T: type) type {
    return struct {
        buffer: []const T = &.{},
        index: ?usize = 0,

        const Self = @This();

        pub fn first(self: *Self) ?T {
            assert(self.index.? == 0);
            return self.next();
        }

        pub fn next(self: *Self) ?T {
            const idx = self.index orelse return null;
            if (0 >= idx) return null;
            const item = self.buffer[idx];
            self.index.? -= 1;
            return item;
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
    try vec.pushBack(10);
    try expect(try vec.at(0) == 10);
    try expectError(error.IndexOutOfBounds, vec.at(1));
}

test "Vector.front() gets the first element in the array or returns an appropriate error" {
    const allocator = std.testing.allocator;
    var vec = Vector(i32).init(allocator);
    defer vec.deinit();
    try expectError(error.Empty, vec.front());
    try vec.pushBack(1);
    try vec.pushBack(2);
    try vec.pushBack(3);
    try expect(try vec.front() == 1);
    try expect(try vec.front() == try vec.at(0));
}

test "Vector.back() gets the first element in the array or returns an appropriate error" {
    const allocator = std.testing.allocator;
    var vec = Vector(i32).init(allocator);
    defer vec.deinit();
    try expectError(error.Empty, vec.back());
    try vec.pushBack(1);
    try expect(try vec.back() == 1);
    try vec.pushBack(2);
    try expect(try vec.back() == 2);
    try vec.pushBack(3);
    try expect(try vec.back() == 3);
}
