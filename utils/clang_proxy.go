package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
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
	debug := os.Getenv("CLANG_PROXY_DEBUG")
	if debug != "" {
		PrintCommand(cmd, args...)
	}
	command := exec.Command(cmd, args...)
	return RunWithMultiWriter(command)
}

func RunCommandAsync(c chan int, cmd string, args ...string) {
	c <- RunCommand(cmd, args...)
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
	variant := os.Getenv("CLANG_PROXY_VAR")

	if focus == "" {
		return RunCommand(convert(os.Args[0]), os.Args[1:]...)
	}

	for i := 0; i < l; i++ {
		if os.Args[i] == "-o" {
			if i+1 < l && match(os.Args[i+1], focus) {
				original := os.Args[1:]
				list := original
				if args != "" {
					argsList := strings.Split(args, " ")
					list = append(argsList, original...)
				}
				if variant != "" {
					conf := strings.Split(variant, ";")
					retVal := make([]chan int, len(conf))
					for j, c := range conf {
						if c == "" {
							continue
						}
						retVal[j] = make(chan int)
						s := strings.Split(c, " ")
						curI := i + len(s)
						s = append(s, original...)
						s[curI] = s[curI] + "." + strconv.Itoa(j)
						go RunCommandAsync(retVal[j], convert(os.Args[0]), s...)
					}
					ret := RunCommand(convert(os.Args[0]), list...)
					for j, c := range conf {
						if c == "" {
							continue
						}
						retNum := <-retVal[j]
						if retNum != 0 {
							ret = retNum
						}
						close(retVal[j])
					}
					return ret
				}
				return RunCommand(convert(os.Args[0]), list...)
			}
		}
	}
	return RunCommand(convert(os.Args[0]), os.Args[1:]...)
}

func main() { os.Exit(mainReturnWithCode()) }
