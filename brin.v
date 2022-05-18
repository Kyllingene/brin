module main

import os

fn output(destination string, data string) {
	if destination == '||STDOUT||' {
		print("$data")
		
	} else {
		prev_data := os.read_file(destination) or { '' }
		
		os.write_file(destination, prev_data + '\n' + data) or {
			eprintln("\n\nERROR: Couldn't write to output file $destination;\n\n$err")
			exit(2)
		}
	}
}

fn dump_info(pointer int, stack [30000]u8, destination string) {
	mut p := 29999
	for p != 0 && stack[p] == 0 { p -= 1 }
	mut relevant_stack := []u8{}
	relevant_stack = stack[0..p]

	output(destination, '\n[<]\n')
	output(destination, "Pointer: $pointer\n")
	output(destination, "Stack:\n$relevant_stack\n")
}

// from https://github.com/alexprengere/ python implementation
fn make_jump_table(data string) map[int]int {
	mut index := 0
	mut left_positions := []int{}
	mut table := map[int]int{}
	
	for index < data.len {
		if data[index].ascii_str() == '[' { left_positions << index }
		else if data[index].ascii_str() == ']' {
			left := left_positions.pop()
			right := index
			
			table[left] = right
			table[right] = left
		}
		
		index += 1
	}
	
	return table
}

fn main() {
	args := os.args_after('')
	
	if args.len > 3 {
		println("Usage:\nbrin [input] [output]")
		return
		
	} else if args.len > 1 {
		debug_out := match true {
			args.len > 2 { args[2] }
			else { '||STDOUT||' }
		}
		
		data := os.read_file(args[1]) or {
			output(debug_out, "ERROR: Couldn't load input file ${args[1]};\n\n$err")
			exit(2)
		}
		
		if data.count('[') != data.count(']') {
			output(debug_out, "ERROR: Mismatched braces")
			exit(1)
		}

		jump_table := make_jump_table(data)
		
		mut stack := [30000]u8{}
		mut pointer := 0
		
		mut ipointer := 0
		for ipointer < data.len {
			match data[ipointer].ascii_str() {
				'+' { stack[pointer] += 1 }
				'-' { stack[pointer] -= 1 }
				'>' { pointer += 1 }
				'<' { pointer -= 1 }
				'.' { output(debug_out, stack[pointer].ascii_str()) }
				',' { stack[pointer] = os.get_raw_stdin()[0] }
				'[' { if stack[pointer] == 0 { ipointer = jump_table[ipointer] }}
				']' { if stack[pointer] != 0 { ipointer = jump_table[ipointer] }}
				'#' { dump_info(pointer, stack, debug_out) }
				else { }
			}
			
			pointer %= 30000
			if pointer < 0 { pointer = 29999 }
			stack[pointer] %= 256
			
			ipointer += 1
		}
		
		
	} else {	
		mut stack := [30000]u8{}
		mut pointer := 0
		
		mut data := ''
		
		for data != 'exit' {
			debug_out := '||STDOUT||'
			data = os.input('[>] ')

			if data.count('[') != data.count(']') {
				output('||STDOUT||', "ERROR: Mismatched braces\n")
				continue
			}
			
			jump_table := make_jump_table(data)
			
			mut ipointer := 0
			for ipointer < data.len {
				match data[ipointer].ascii_str() {
					'+' { stack[pointer] += 1 }
					'-' { stack[pointer] -= 1 }
					'>' { pointer += 1 }
					'<' { pointer -= 1 }
					'.' { output(debug_out, stack[pointer].ascii_str()) }
					',' { stack[pointer] = os.get_raw_stdin()[0] }
					'[' { if stack[pointer] == 0 { ipointer = jump_table[ipointer] }}
					']' { if stack[pointer] != 0 { ipointer = jump_table[ipointer] }}
					'#' { dump_info(pointer, stack, debug_out) }
					else { }
				}
				
				pointer %= 30000
				if pointer < 0 { pointer = 29999 }
				stack[pointer] %= 256
				
				ipointer += 1
			}
		}
	}
}
