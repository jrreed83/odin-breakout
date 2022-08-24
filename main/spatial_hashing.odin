package main 

import "core:fmt"
import "core:mem"

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

SpatialHash :: struct {
	width, height: int,
}

hash_coords:: proc (hash: SpatialHash, x, y: f32) -> (int, int) {
	return int(x / f32(hash.width)), int(y / f32(hash.height))	
}

NUM_TILES_X :: 10 
NUM_TILES_Y :: 10 
NUM_TILES   :: NUM_TILES_Y * NUM_TILES_X

HashTable :: distinct [NUM_TILES] [dynamic] int
hash := SpatialHash {16, 16}

hash_entity :: proc (tbl: ^HashTable, id: int, min_x, min_y, max_x, max_y: f32) {

	i0, j0 := hash_coords(hash, min_x, min_y)
	i1, j1 := hash_coords(hash, max_x, min_y)
	i2, j2 := hash_coords(hash, max_x, max_y)
	i3, j3 := hash_coords(hash, min_x, max_y)

	k0 := j0 + i0*NUM_TILES_Y
	k1 := j1 + i1*NUM_TILES_Y
	k2 := j2 + i2*NUM_TILES_Y
	k3 := j3 + i3*NUM_TILES_Y

	append(&tbl[k0], id)
	append(&tbl[k1], id)
	append(&tbl[k2], id)
	append(&tbl[k3], id)

}

main :: proc() {
	//hash := SpatialHash{10, 10}

	tbl : HashTable

	hash_entity(&tbl, 3, 32.0, 35.0, 59.0, 60.0) 

	for i in 0..<len(tbl) {
		if tbl[i] != nil { 
			fmt.println(i, tbl[i])
		}
	}

	for i in 0..<len(tbl) {
		tbl[i] = nil
	}

	for i in 0..<len(tbl) {
		if tbl[i] != nil { 
			fmt.println(i, tbl[i])
		}
	}

	x : [dynamic] int = {1,2,3,4,5}
	for xi, i in x {
		fmt.println(xi)
		fmt.println("----")
		for xj, j in x[i+1:] {
			fmt.println(xj)
		}
	}
	//fmt.println(hash_coords(&hash, 10.3, 43.0))
}