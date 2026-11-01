const std = @import("std");
const Sha1 = std.crypto.hash.Sha1;
const base64 = std.base64.url_safe_no_pad;

pub const encoded_size = base64.Encoder.calcSize(Sha1.digest_length);

pub fn hash(url: []const u8) [encoded_size]u8 {
    var digest: [Sha1.digest_length]u8 = undefined;
    Sha1.hash(url, &digest, .{});

    var out: [encoded_size]u8 = undefined;
    _ = base64.Encoder.encode(&out, &digest);
    return out;
}

test "basic hash" {
    try std.testing.expectEqualStrings(
        "00hq6RNueFa8QiEjhep5cJRHWAI",
        &hash("Hello world!"),
    );
}

test "empty string uses url-safe alphabet" {
    try std.testing.expectEqualStrings(
        "2jmj7l5rSw0yVb_vlWAYkK_YBwk",
        &hash(""),
    );
}
