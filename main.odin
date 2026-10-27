package main

import "core:fmt"
import "core:net"
import "core:strings"

main :: proc() {
    
    socket, err := net.listen_tcp({
        address = net.IP4_Address{127,0,0,1},
        port = 8080,
    })

    if err != nil {
        fmt.println("Error creating server:", err)
        return
    }
    defer net.close(socket)


    for {
        client, client_addr, client_err := net.accept_tcp(socket)
        if client_err != nil {
            fmt.println("Error accepting request:", client_err)
            continue
        }

        handle_client(client)
    }

}

handle_client :: proc(client: net.TCP_Socket) {
    defer net.close(client)

    buffer: [4096]u8
    bytes_read, err := net.recv_tcp(client, buffer[:])
    if err != nil {
        fmt.println("Error reading from client:", err)
        return
    }

    request := string(buffer[:bytes_read])
    fmt.printfln("Recived request:\n%s", request)

    response := strings.concatenate([]string{
        "HTTP/1.1 200 OK\r\n",
        "Content-Type: text/html\r\n",
        "Connection: close\r\n",
        "\r\n",
        "<html><body><h1>Hellope from Odin server!</h1></body></html>"
    })

    net.send(client, transmute([]u8)response)
}