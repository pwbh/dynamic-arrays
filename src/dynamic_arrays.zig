const std = @import("std");
const math = std.math;

const Allocator = std.mem.Allocator;

const assert = std.debug.assert;

const expect = std.testing.expect;
const expectError = std.testing.expectError;

pub fn Vector(comptime T: type) type {
    return struct {
        allocator: Allocator,
        cap: usize,
        len: usize,
        arr: []T,

        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
                .cap = 0,
                .len = 0,
                .arr = &.{},
            };
        }

        pub fn at(self: *Self, i: usize) !T {
            if (self.cap == 0) {
                return error.Empty;
            }

            if (i >= self.len) {
                return error.IndexOutOfBounds;
            }

            return self.arr[i];
        }

        pub fn front(self: *Self) !T {
            if (self.cap == 0) {
                return error.Empty;
            }

            return self.arr[0];
        }

        pub fn back(self: *Self) !T {
            if (self.cap == 0) {
                return error.Empty;
            }

            return self.arr[self.len - 1];
        }

        pub fn pushBack(self: *Self, item: T) !void {
            if (self.len >= self.cap) {
                try self.resize(null);
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

        pub fn empty(self: *Self) usize {
            return self.cap == 0;
        }

        pub fn size(self: *Self) usize {
            return self.len;
        }

        pub fn reserve(self: *Self, new_cap: usize) !void {
            self.resize(new_cap);
        }

        pub fn capacity(self: *Self) usize {
            return self.cap;
        }

        pub fn shrinkToFit(self: *Self) !void {
            self.resize(self.len);
        }

        pub fn maxSize(self: *Self) usize {
            _ = self;
            return math.maxInt(usize);
        }

        fn resize(self: *Self, new_cap: ?usize) !void {
            const new_capacity = new_cap orelse if (self.cap == 0) 2 else self.cap * 2;
            const new_items = try self.allocator.alloc(T, new_capacity);

            if (self.len > 0) {
                @memcpy(new_items[0..self.len], self.arr[0..self.len]);
                self.allocator.free(self.arr);
                self.arr = &.{};
            }

            self.arr = new_items;
            self.cap = new_capacity;
        }

        /// Dynamic array become undefined after calling `deinit`.
        pub fn deinit(self: *Self) void {
            self.clear();
            self.* = undefined;
        }

        pub fn data(self: *Self) []T {
            return self.arr[0..self.len];
        }

        pub fn clear(self: *Self) void {
            if (self.cap > 0) {
                self.allocator.free(self.arr);
            }

            self.arr = &.{};
            self.cap = 0;
            self.len = 0;
        }

        pub fn insert(self: *Self, pos: usize, element: T) !void {
            if (pos >= self.len) {
                return error.IndexOutOfBounds;
            }

            if (self.len + 1 > self.cap) {
                try self.resize(null);
            }

            const dest = self.arr[(pos + 1)..(self.len + 1)];
            const src = self.arr[pos..self.len];

            @memmove(dest, src);

            self.arr[pos] = element;
            self.len += 1;
        }

        pub fn insertRange(self: *Self, pos: usize, elements: []T) !void {
            _ = self;
            _ = pos;
            _ = elements;
        }

        pub fn appendRange(self: *Self, elements: []T) !void {
            if (self.len + elements.len > self.cap) {
                self.resize();
            }

            @memcpy(self.arr[self.len .. self.len + elements.len], elements);

            self.len += elements.len;
        }

        pub fn popBack(self: *Self) !void {
            if (0 > self.len - 1) {
                return error.Empty;
            }

            self.arr[self.len - 1] = undefined;
            self.len -= 1;
        }

        pub fn swap(self: *Self, other: Vector(T)) !void {
            const current = self.*;
            other.* = self.*;
            self.* = current;
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

test "Vector.insert() inserts the new item in specific pos" {
    const allocator = std.testing.allocator;
    var vec = Vector(i32).init(allocator);
    defer vec.deinit();
    try vec.pushBack(0);
    try vec.pushBack(1);
    try vec.pushBack(2);
    try vec.pushBack(3); // follow the chain of inserts, this element is the last one in the array.
    try expect(try vec.at(1) == 1);
    try vec.insert(1, 10);
    try expect(try vec.at(1) == 10);
    try expectError(error.IndexOutOfBounds, vec.insert(100, 100));
    try expectError(error.IndexOutOfBounds, vec.insert(vec.len, 5555));
    try vec.insert(vec.len - 1, 100);
    try expect(try vec.at(vec.len - 2) == 100);
    try expect(try vec.at(vec.len - 1) == 3);
}
