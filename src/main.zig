const std = @import("std");
const dynamic_arrays = @import("dynamic_arrays.zig");

const Vector = dynamic_arrays.Vector;

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    var debug_allocator = std.heap.DebugAllocator(.{}){};
    const allocator = debug_allocator.allocator();
    var vec = Vector(i32).init(allocator);
    defer vec.deinit();
    try vec.pushBack(3);

    for (vec.data()) |item| {
        std.debug.print("{d}\n", .{item});
    }

    var iterator = vec.begin();

    while (iterator.next()) |item| {
        std.debug.print("item {d}\n", .{item});
    }
}

test {
    _ = dynamic_arrays;
}
