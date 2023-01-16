# brin
## A user-friendly Brain*** interpreter

### Introduction
`brin` is a Brain*** interpreter written in [V](https://vlang.io). It also has a built-in REPL.
It supports several debug operators, including two that handle pointer manipulation.

### Operators
In addition to the standard 8, there are six additional operators; four for debugging, two that add functionality. 
 - `;` dumps the current tape pointer, along with the tape.
 - `~` prints the pointer and the current cell as a hex digit.
 - `(` and `)` delimit a string to print to output (still executes instructions found inside)
 - `^` writes the pointer to the cell indicated by the current cell + the neighboring one.
 - `@` reads the pointer from the current cell + the neighboring one.
