const std = @import("std");
const context = @import("context.zig").Context;

pub fn main(init: std.process.Init) !void {
    _ = try context.init(init);

    std.debug.print("Environment Variables:\n", .{});
    for (init.environ_map.keys()) |key| {
        std.debug.print("{s}:{?s}\n", .{ key, init.environ_map.get(key) });
    }
}
