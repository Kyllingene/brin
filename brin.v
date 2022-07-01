module main

import os

fn max(x int, y int) int {
    return match x > y { true {x} false {y} }
}

fn pop(buffer string) (u8, string) {
    return buffer[0], buffer[1..]
}

fn to_u8s(pointer int) (u8, u8) {
    return u8((pointer & 0b11110000) >> 4), u8(pointer & 0b00001111)
}

fn from_u8s(v1 u8, v2 u8) int {
    //println(int((v1 << 4) | v2))
    return int((v1 << 4) | v2)
}

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

fn print_tape(tape [30000]u8, highest int) string {
    mut out := "\t| "
    mut line := 0
    
    for i, v in tape[0..highest + 1] {
        mut i_out := i.str()
        if i_out.len < 2 {
            i_out = " " + i_out
        }
        
        out += i_out
        out += ": 0x"
        out += v.hex()
        out += " | "
        line += 1
        
        if line > 7 {
            line = 0
            out += "\n\t| "
        }
    }
    return out
}

fn dump_info(pointer int, highest int, tape [30000]u8, destination string) {
	printed_tape := print_tape(tape, highest)

	output(destination, '\n[<]\n')
	output(destination, "Pointer: $pointer\n")
	output(destination, "tape:\n$printed_tape\n\n")
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

fn eval(ch u8, mut tape [30000]u8, p int, ip int, h int, db bool, jump_table map[int]int, b string, debug_out string) (int, int, int, string, bool) {
    
    // TODO: clean all stuff like this
    mut pointer := p
    mut ipointer := ip
    mut highest := h
    mut buffer := b.str()
    mut is_debug_print := db
        
    match ch.ascii_str() {
        '+' {
            tape[pointer] += 1
            if pointer > highest {highest = pointer}
        }
        
        '-' {
            tape[pointer] -= 1
            if pointer > highest {highest = pointer}
        }
        
        '>' { pointer += 1 }
        '<' { pointer -= 1 }
        '.' { output(debug_out, tape[pointer].ascii_str()) }
        '~' { output(debug_out, pointer.str() + ": 0x" + tape[pointer].hex() + " ") }
        ',' { 
            if buffer == "" {
                //TODO: buffer = os.get_raw_stdin().bytestr()
                buffer = os.input("")
                buffer += "\x00"
            }
            
            tape[pointer], buffer = pop(buffer)
            
            if pointer > highest {highest = pointer}
        }
        
        '[' { if tape[pointer] == 0 { ipointer = jump_table[ipointer] }}
        ']' { if tape[pointer] != 0 { ipointer = jump_table[ipointer] }}
        '``' { dump_info(pointer, highest, tape, debug_out) }
        '^' {
            tp := from_u8s(tape[pointer], tape[(pointer+1) % 30000])
            tape[tp], tape[tp+1] = to_u8s(pointer)
            if pointer+1 > highest { highest = pointer+1 }
        }
        
        '@' { pointer = from_u8s(tape[pointer], tape[(pointer+1) % 30000]) }
        '(' { is_debug_print = true }
        ')' {
            is_debug_print = false
            print("\n")
        }
        
        else {
            if is_debug_print {
                print(ch.ascii_str())
            }
        }
    }

    pointer %= 30000
    if pointer < 0 { pointer = 29999 }
    tape[pointer] %= 256

    ipointer += 1
    
    return pointer, ipointer, highest, buffer, is_debug_print
}

fn loop_eval(data string, mut tape [30000]u8, p int, h int, debug_out string) (int, int) {
    if data.count('[') != data.count(']') {
        output(debug_out, "ERROR: Mismatched braces\n")
        return p, h
    }
    
    jump_table := make_jump_table(data)
    
    mut buffer := "" 
    
    mut pointer := p
    mut highest := h
    mut ipointer := 0
    mut is_debug_print := false
    
    for ipointer < data.len {
        pointer, ipointer, highest, buffer, is_debug_print = eval(data[ipointer], mut tape, pointer, ipointer, highest, is_debug_print, jump_table, buffer, debug_out)
    }
    
    return p, highest
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
		
		mut tape := [30000]u8{}
        loop_eval(data, mut tape, 0, 0, debug_out)
		
	} else {	
        debug_out := '||STDOUT||'
		mut tape := [30000]u8{}
		mut pointer := 0
		mut highest := 0
        
		mut data := ''
		
        println("Type 'exit' to exit")
        
		for data != 'exit' {
			data = os.input('[>] ')

			pointer, highest = loop_eval(data, mut tape, pointer, highest, debug_out)
		}
	}
}
