package main 

import "core:fmt"
import "core:mem"

SpatialHash :: struct {
	width, height: int,
}

hash_coords:: proc (hash: ^SpatialHash, x, y: f32) -> (i32, i32) {
	return i32(x / f32(hash.width)), i32(y / f32(hash.height))	
}

HashTable :: struct {
	hash_fn : SpatialHash,
	table:    [256] List
}

Node :: struct {
	value:  u16,
	next : ^Node
}

List :: struct {
	head : ^Node,
	count: u8
}

prepend :: proc(list: ^List, x: u16) {
	node := new(Node)
	node.value = x 

	node.next = list.head 
	list.head = node 
	list.count += 1 

}

walk :: proc(list: List) {
	ptr := list.head
	for i in 0..<list.count {
		fmt.println(ptr^.value)
		ptr = ptr.next
	}
}
main :: proc() {
	list := List{}
	prepend(&list, 4)
	prepend(&list, 6)
	prepend(&list, 32)
	walk(list)	
	//hash := SpatialHash{10, 10}

	//fmt.println(hash_coords(&hash, 10.3, 43.0))
}