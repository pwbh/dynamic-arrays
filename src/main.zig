const std = @import("std");
const dynamic_arrays = @import("dynamic_arrays.zig");

const Vector = dynamic_arrays.Vector;

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();
    var vec = Vector(i32).init(allocator);
    defer vec.deinit();

    try vec.pushBack(0);
    try vec.pushBack(1);
    try vec.pushBack(2);
    try vec.pushBack(3);

    for (vec.data()) |n| {
        std.debug.print("{d}\n", .{n});
    }

    std.debug.print("--------insert-------\n", .{});

    try vec.insert(2, 5);

    for (vec.data()) |n| {
        std.debug.print("{d}\n", .{n});
    }
}

test {
    _ = dynamic_arrays;
}
