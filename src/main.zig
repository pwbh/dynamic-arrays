const std = @import("std");
const dynamic_arrays = @import("dynamic_arrays.zig");

const Vector = dynamic_arrays.Vector;

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();
    var vec = Vector(i32).init(allocator);
    defer vec.destroy();
    try vec.push_back(3);

    for (vec.items()) |item| {
        std.debug.print("{d}\n", .{item});
    }
}

test "Vector initializes and deinitializes" {
    const allocator = std.testing.allocator;
    var vec = Vector(i32).init(allocator);
    defer vec.deinit();
}

test "Vector.get() returns the element at given index" {
    const allocator = std.testing.allocator;
    var vec = Vector(i32).init(allocator);
    defer vec.deinit();
    try vec.push_back(10);
    std.debug.assert(try vec.get(0) == 10);
}
