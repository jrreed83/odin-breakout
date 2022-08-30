package main 

import "core:fmt"
import "core:os"
import "core:strings"

parse_level_file:: proc() {


	fid, _ := os.open("./level_1.txt")
	defer os.close(fid)

	buffer : [8] byte

	n, _ := os.read(fid, buffer[:])

	tmp := strings.clone_from_bytes(buffer[:])
	fmt.println(tmp)

	for char, i in buffer {
		if char == '\n' {
			fmt.println("At end")
		}
	}
}
