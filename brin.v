module main

import os

fn max(x int, y int) int {
    return match x > y { true {x} false {y} }
}

fn pop(buffer string) (u8, string) {
    return buffer[0], buffer[1..]
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

fn print_stack(stack [30000]u8, highest int) string {
    mut out := "\t"
    mut line := 0
    
    for v in stack[0..highest + 1] {
        out += "0x"
        out += v.hex()
        out += " "
        line += 1
        
        if line > 7 {
            line = 0
            out += "\n\t"
        }
    }
    return out
}

fn dump_info(pointer int, highest int, stack [30000]u8, destination string) {
	printed_stack := print_stack(stack, highest)

	output(destination, '\n[<]\n')
	output(destination, "Pointer: $pointer\n")
	output(destination, "Stack:\n$printed_stack\n\n")
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

fn eval(ch u8, mut stack [30000]u8, p int, ip int, h int, jump_table map[int]int, b string, debug_out string) (int, int, int, string) {
    
    // TODO: clean all stuff like this
    mut pointer := p
    mut ipointer := ip
    mut highest := h
    mut buffer := b.str()
    
    match ch.ascii_str() {
        '+' {
            stack[pointer] += 1
            if pointer > highest {highest = pointer}
        }
        
        '-' {
            stack[pointer] -= 1
            if pointer > highest {highest = pointer}
        }
        
        '>' { pointer += 1 }
        '<' { pointer -= 1 }
        '.' { output(debug_out, stack[pointer].ascii_str()) }
        '*' { output(debug_out, "0x" + stack[pointer].hex() + " ") }
        ',' { 
            if buffer == "" {
                buffer = os.input("")
                buffer += "\x00"
            }
            
            stack[pointer], buffer = pop(buffer)
            
            if pointer > highest {highest = pointer}
        }
        
        '[' { if stack[pointer] == 0 { ipointer = jump_table[ipointer] }}
        ']' { if stack[pointer] != 0 { ipointer = jump_table[ipointer] }}
        '#' { dump_info(pointer, highest, stack, debug_out) }
        else { }
    }

    pointer %= 30000
    if pointer < 0 { pointer = 29999 }
    stack[pointer] %= 256

    ipointer += 1
    
    return pointer, ipointer, highest, buffer
}

fn loop_eval(data string, mut stack [30000]u8, p int, h int, debug_out string) (int, int) {
    if data.count('[') != data.count(']') {
        output(debug_out, "ERROR: Mismatched braces\n")
        return p, h
    }
    
    jump_table := make_jump_table(data)
    
    mut buffer := "" 
    
    mut pointer := p
    mut highest := h
    mut ipointer := 0
    
    for ipointer < data.len {
        pointer, ipointer, highest, buffer = eval(data[ipointer], mut stack, pointer, ipointer, highest, jump_table, buffer, debug_out)
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
		
		mut stack := [30000]u8{}
        loop_eval(data, mut stack, 0, 0, debug_out)
		
	} else {	
        debug_out := '||STDOUT||'
		mut stack := [30000]u8{}
		mut pointer := 0
		mut highest := 0
        
		mut data := ''
		
        println("Type 'exit' to exit")
        
		for data != 'exit' {
			data = os.input('[>] ')

			pointer, highest = loop_eval(data, mut stack, pointer, highest, debug_out)
		}
	}
}
