package main

import "core:crypto/legacy/sha1"
import "core:testing"
import "core:crypto/hash"
import "core:encoding/base64"

get_hash :: proc(url: ^string) -> string {
    assert(len(url^) > 0, "Url should not be empty")
    hash_byte := hash.hash_string(.Insecure_SHA1, url^, context.temp_allocator)

    return base64.encode(hash_byte, allocator = context.temp_allocator)
}

@(test)
get_hash__happypath_test :: proc(t: ^testing.T) {
    defer free_all(context.temp_allocator)

    buffer: [sha1.DIGEST_SIZE]u8

    value := "test"
    encoded_value := get_hash(&value)


    testing.expect_value(t, encoded_value, "qUqP5cyxm6YcTAhz05Hph5gvu9M=")
}

@(test)
get_hash__empty_url_test :: proc(t: ^testing.T) {
    defer free_all(context.temp_allocator)

    testing.expect_assert(t, "Url should not be empty")

    buffer: [sha1.DIGEST_SIZE]u8

    value := ""
    encoded_value := get_hash(&value)
}