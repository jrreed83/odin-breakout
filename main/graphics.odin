package main 

import "core:os"
import "core:fmt"

test_read :: proc() {
    fid, err := os.open("main/main.odin")
    defer os.close(fid)
    if err != os.ERROR_NONE {
        fmt.println("Error", err)
    }

    buffer: [1024] byte
    n, err1 := os.read(fid, buffer[:])
    if err1 != os.ERROR_NONE {
        fmt.println("Error", err1)
    }
    
    fmt.printf("Hello %s\n", buffer)

}

test_write :: proc() {
	fid, _ := os.open("test.png", os.O_WRONLY)
	//os.write(fid, 7)
	defer os.close(fid)
}