const std = @import("std");

const context = @This();

pub const Context = struct {
    arena: std.mem.Allocator,
    gpa: std.mem.Allocator,
    io: std.Io,
    args: []const [:0]const u8,

    pub fn init(proc: std.process.Init) !Context {
        const arena = proc.arena.allocator();
        return .{
            .arena = arena,
            .gpa = proc.gpa,
            .io = proc.io,
            .args = try proc.minimal.args.toSlice(arena),
        };
    }
};
