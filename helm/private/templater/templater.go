package main

import (
	"flag"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"syscall"

	"github.com/abrisco/rules_helm/helm/private/helm_utils"
)

type Arguments struct {
	helm        string
	helmPlugins string
	chart       string
	output      string
}

func makeAbsolutePath(path string) string {
	if filepath.IsAbs(path) {
		return path
	}
	cwd, err := os.Getwd()
	if err != nil {
		log.Fatal("Couldn't determine current working directory")
	}
	return filepath.Join(cwd, path)
}

func parse_args() Arguments {
	var args Arguments

	flag.StringVar(&args.helm, "helm", "", "The path to a helm executable")
	flag.StringVar(&args.helmPlugins, "helm_plugins", "", "The path to a helm plugins directory")
	flag.StringVar(&args.chart, "chart", "", "The path to the helm chart to template.")
	flag.StringVar(&args.output, "output", "", "The output file to write.")
	flag.Parse()

	return args
}

func main() {
	args := parse_args()

	log.SetFlags(log.LstdFlags | log.Lshortfile)

	chart := makeAbsolutePath(args.chart)
	helm := makeAbsolutePath(args.helm)
	helmPlugins := makeAbsolutePath(args.helmPlugins)
	output := makeAbsolutePath(args.output)

	helmArgs := []string{"template", chart}
	cmd, err := helm_utils.BuildHelmCommand(helm, helmArgs, helmPlugins)
	if err != nil {
		log.Fatal(err)
	}

	outputFile, err := os.Create(output)
	if err != nil {
		log.Fatal(err)
	}

	cmd.Stdout = outputFile
	cmd.Stderr = os.Stderr

	exitCode := 0
	var cmdError error

	cmdErr := cmd.Run()
	if cmdErr != nil {
		if exitError, ok := cmdErr.(*exec.ExitError); ok {
			if status, ok := exitError.Sys().(syscall.WaitStatus); ok {
				exitCode = status.ExitStatus()
			}
		} else {
			cmdError = cmdErr
			exitCode = 1
		}
	}

	if cmdError != nil {
		log.Fatal(cmdError)
	}

	os.Exit(exitCode)
}
