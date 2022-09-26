package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func PrintCommand(cmd string, args ...string) {
	fmt.Printf("%s %s\n", cmd, strings.Join(args, " "))
}

func RunWithMultiWriter(command *exec.Cmd) int {
	var stdBuffer bytes.Buffer
	mw := io.MultiWriter(os.Stdout, &stdBuffer)

	command.Stdout = mw
	command.Stderr = mw
	err := command.Run()
	if err == nil {
		return 0
	} else {
		return 1
	}
}

func RunCommand(cmd string, args ...string) int {
	// PrintCommand(cmd, args...)
	command := exec.Command(cmd, args...)
	return RunWithMultiWriter(command)
}

func match(path string, focus string) bool {
	file := filepath.Base(path)
	if file == focus {
		return true
	}
	return false
}

func convert(name string) string {
	return strings.Replace(name, "clang_proxy", "clang", 1)
}

func mainReturnWithCode() int {
	l := len(os.Args)
	focus := os.Getenv("CLANG_PROXY_FOCUS")
	args := os.Getenv("CLANG_PROXY_ARGS")
	if focus == "" {
		return RunCommand(convert(os.Args[0]), os.Args[1:]...)

	}

	for i := 0; i < l; i++ {
		if os.Args[i] == "-o" {
			if i+1 < l && match(os.Args[i+1], focus) {
				list := os.Args[1:]
				if args != "" {
					list = append(strings.Split(args, " "), list...)
				}
				return RunCommand(convert(os.Args[0]), list...)

			}
		}
	}
	return RunCommand(convert(os.Args[0]), os.Args[1:]...)
}

func main() { os.Exit(mainReturnWithCode()) }
