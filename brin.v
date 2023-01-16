module main

import os

struct Eval {
    mut: pointer int
         ipointer int
         highest int
         is_debug_print bool
         buffer string
}

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
    return int((v1 << 4) | v2)
}

// TODO: buffer this
fn output(destination string, data string) {
	if destination == '1' {
		print("$data")
        os.flush()
		
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

fn eval(ch u8, mut tape [30000]u8, mut data Eval, jump_table map[int]int, debug_out string) {
    match ch.ascii_str() {
        '+' {
            tape[data.pointer] += 1
            if data.pointer > data.highest {data.highest = data.pointer}
        }
        
        '-' {
            tape[data.pointer] -= 1
            if data.pointer > data.highest {data.highest = data.pointer}
        }
        
        '>' { data.pointer += 1 }
        '<' { data.pointer -= 1 }
        '.' { output(debug_out, tape[data.pointer].ascii_str()) }
        '~' { output(debug_out, data.pointer.str() + ": 0x" + tape[data.pointer].hex() + " ") }
        ',' { 
            if data.buffer == "" {
                //TODO: buffer = os.get_raw_stdin().bytestr()
                data.buffer = os.input("")
                data.buffer += "\x00"
            }
            
            tape[data.pointer], data.buffer = pop(data.buffer)
            
            if data.pointer > data.highest {data.highest = data.pointer}
        }
        
        '[' { if tape[data.pointer] == 0 { data.ipointer = jump_table[data.ipointer] }}
        ']' { if tape[data.pointer] != 0 { data.ipointer = jump_table[data.ipointer] }}
        ';' { dump_info(data.pointer, data.highest, tape, debug_out) }
        '^' {
            tp := from_u8s(tape[data.pointer], tape[(data.pointer+1) % 30000])
            tape[tp], tape[tp+1] = to_u8s(data.pointer)
            if data.pointer+1 > data.highest { data.highest = data.pointer+1 }
        }
        
        '@' { data.pointer = from_u8s(tape[data.pointer], tape[(data.pointer+1) % 30000]) }
        '(' { data.is_debug_print = true }
        ')' {
            data.is_debug_print = false
            print("\n")
        }
        
        else {
            if data.is_debug_print {
                print(ch.ascii_str())
            }
        }
    }

    data.pointer %= 30000
    if data.pointer < 0 { data.pointer = 29999 }
    tape[data.pointer] %= 256

    data.ipointer += 1
    
    // return pointer, ipointer, highest, buffer, is_debug_print
}

fn loop_eval(data string, mut tape [30000]u8, mut edata Eval, debug_out string) {
    if data.count('[') != data.count(']') {
        output(debug_out, "ERROR: Mismatched braces\n")
    }
    
    jump_table := make_jump_table(data)
            
    for edata.ipointer < data.len {
        eval(data[edata.ipointer], mut tape, mut edata, jump_table, debug_out)
    }    
}

fn main() {
	args := os.args_after('')
	
	if args.len > 3 {
		println("Usage:\nbrin [input] [output]")
		return
		
	} else if args.len > 1 {
		debug_out := match true {
			args.len > 2 { args[2] }
			else { '1' }
		}
		
		data := os.read_file(args[1]) or {
        output(debug_out, "ERROR: Couldn't load input file ${args[1]};\n\n$err")
			exit(2)
		}
		
		mut tape := [30000]u8{}
        mut edata := Eval {
            0,
            0,
            0,
            false,
            "",
        }

        loop_eval(data, mut tape, mut edata, debug_out)
		
	} else {
        debug_out := '1'
		mut tape := [30000]u8{}        
		mut data := ''
		
        mut edata := Eval {
            0,
            0,
            0,
            false,
            "",
        }

        println("Type 'exit' to exit")
        
		for data != 'exit' {
			data = os.input('[>] ')

			loop_eval(data, mut tape, mut edata, debug_out)
		}
	}
}
