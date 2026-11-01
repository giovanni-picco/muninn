const std = @import("std");
const log = std.log;
const net = std.Io.net;
const Io = std.Io;
const Request = std.http.Server.Request;
const hash = @import("hash.zig");
const pg = @import("pg");

pub fn main(init: std.process.Init) !void {
    _ = hash;
    const io = init.io;

    // 1. Init Database connection
    var db_pool = try pg.Pool.init(io, init.gpa, .{
        .size = 5,
        .connect = .{ .host = "127.0.0.1", .port = 5432 },
        .auth = .{
            .database = "muninn",
            .username = "postgres",
            .password = "muninn!",
            .timeout = 10_000,
        },
    });
    defer db_pool.deinit();

    // 2. start a TCP server
    const addr = try net.IpAddress.parse("127.0.0.1", 8080);
    var server = try addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);

    log.info("Start HTTP server at {f}", .{addr});

    while (true) {
        const stream = server.accept(io) catch |err| {
            log.err("failed to accept connection: {s}", .{@errorName(err)});
            continue;
        };

        const thread = std.Thread.spawn(.{}, accept, .{ io, stream, db_pool }) catch |err| {
            log.err("unable to spawn connection thread: {s}", .{@errorName(err)});
            stream.close(io);
            continue;
        };

        thread.detach();
    }
}

fn accept(io: Io, stream: net.Stream, pool: *pg.Pool) !void {
    defer stream.close(io);

    log.info("Got new client!", .{});

    var recv_buffer: [4096]u8 = undefined;
    var send_buffer: [4096]u8 = undefined;

    var stream_reader = stream.reader(io, &recv_buffer);
    var stream_writer = stream.writer(io, &send_buffer);

    var server = std.http.Server.init(&stream_reader.interface, &stream_writer.interface);
    while (server.reader.state == .ready) {
        var request = server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => return,
            else => return err,
        };

        try serveHTTP(&request, pool);
    }
}

fn serveHTTP(request: *Request, pool: *pg.Pool) !void {
    log.info("Received request!", .{});

    const result = try pool.query("SELECT hash, url FROM link;", .{});
    defer result.deinit();

    // TODO: testing some queries
    while (try result.next()) |row| {
        log.info("Found a new row. ", .{});
        const key = try row.get([]u8, 0);
        const url = try row.get([]u8, 1);

        log.info("{s}: '{s}'", .{ key, url });
    }

    try request.respond("Hello World from Zig HTTP server", .{
        .extra_headers = &.{
            .{ .name = "custom-header", .value = "custom value" },
        },
    });
}
