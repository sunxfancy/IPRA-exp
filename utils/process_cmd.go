package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)

	// Scans a line from Stdin(Console)
	for scanner.Scan() {
		
		// Holds the string that scanned
		text := scanner.Text()
		if len(text) != 0 {
			commands := strings.Fields(text)
			last := len(commands)-1
			ii := commands[last-2]
			commands[last] = ii[:len(ii)-2] + ".i"
			fmt.Println(strings.Join(commands, " "))
		}
	}
}