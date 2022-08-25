package main 

import "core:fmt"
import "core:mem"
import "core:math"

//Node :: struct {
//	value:  u16,
//	next : ^Node
//}

//List :: struct {
//	head : ^Node,
//	count: u8
//}

//prepend :: proc(list: ^List, x: u16) {
//	node := new(Node)
//	node.value = x 
//
//	node.next = list.head 
//	list.head = node 
//	list.count += 1 
//
//}

//walk :: proc(list: List) {
//	ptr := list.head
//	for i in 0..<list.count {
//		fmt.println(ptr^.value)
//		ptr = ptr.next
//	}
//}

//SpatialHash :: struct {
//	pixel_dims : [2] f32,
//	tile_dims  : [2] u32,      
//}

//hash_coords:: proc (hash: SpatialHash, x, y: f32) -> (int, int) {
//	return int(math.ceil(x / f32(hash.width))), int(math.ceil(y / f32(hash.height)))	
//}

//NUM_TILES_X :: 20 
//NUM_TILES_Y :: 20 
//NUM_TILES   :: NUM_TILES_Y * NUM_TILES_X

//HashTable :: distinct [NUM_TILES] [dynamic] int
//hash := SpatialHash {16, 16}

//hash_entity :: proc (tbl: ^HashTable, id: int, min, max : [2]f32) {
//
//	i0, j0 := hash_coords(hash, min.x, min.y)
//	i1, j1 := hash_coords(hash, max.x, max.y)
//
//	fmt.println(i0, j0)
//	fmt.println(i1, j1)
//	for i in i0..=i1 {
//		for j in j0..=j1 {
//			k := j + i*NUM_TILES_Y
//			append(&tbl[k], id)
//
//		}
//	}
//
//}

main :: proc() {
	//hash := SpatialHash{10, 10}

	//tbl : HashTable

	//hash_entity(&tbl, 3, {32.0, 35.0}, {56.0, 60.0}) 

	//for i in 0..<len(tbl) {
	//	if tbl[i] != nil { 
	//		fmt.println(i, tbl[i])
	//	}
	//}

	foo :: proc() -> [dynamic] u16 {
		x := [dynamic] u16{1,2}
		return x
	}

	aa := foo()

	fmt.println(uintptr(&aa[0]), uintptr(&aa[1]))
	fmt.println(cap(aa))
	append(&aa, 6,8,9)

	fmt.println(uintptr(&aa[0]), uintptr(&aa[1]), uintptr(&aa[2]), uintptr(&aa[3]), uintptr(&aa[4]))
	fmt.println(cap(aa))

}