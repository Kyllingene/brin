# brin
## A user-friendly Brain*** interpreter

## brin's source code is poorly formatted; any help would be appreciated! 

### Introduction
`brin` is a Brain*** interpreter written in [V](https://vlang.io). It also has a built-in REPL.
It supports several debug operators, and supports the Dynamic Brain*** opset using an optional flag.

### Operators
In addition to the standard 8, there are two additional operators, useful for debugging: `#` and `*`.
 - `#` dumps the current tape pointer, along with the tape.
 - `~` prints the current cell as a hex digit.
 - `(` and `)` delimit a string to print to output (USE FOR DEBUG ONLY!)
 - `^` writes the pointer to the cell indicated by the current cell + the neighboring one.
 - `@` reads the pointer from the current cell + the neighboring one.
 
*Unimplemented:*
##### Taken from [adam-mcdaniel/harbor](https://github.com/adam-mcdaniel/harbor)
Additionally, with the flag `-d / --dyn`, you gain access to the 6 additional operators that come with Dynamic Brain***:
 - `?` Read the value of the current cell, and allocate that many cells at the end of the tape. Then, set the current cell's value equal to the index of first cell in that allocated block.
 - `!` Read the value of the current cell, and free + zero the allocated cells starting at that index.
 - `*` Push the pointer to a stack, and set the pointer equal to the value of the current cell.
 - `&` Pop the old pointer off the dereference stack, and set the pointer equal to it.
 - `#` Make the current cell equal to the next integer in the input buffer.
 - `$` Output the current cell as a decimal integer.