package main

import (
	"flag"
	"log"
	"os"
	"os/exec"
	"strings"
	"syscall"

	"github.com/abrisco/rules_helm/helm/private/helm_utils"
)

func parseArgsUpToDashDash(argv []string) ([]string, []string) {
	var before, after []string
	foundSeparator := false

	for _, arg := range argv {
		if foundSeparator == false && arg == "--" {
			foundSeparator = true
			continue // Skip adding "--" itself to either list
		}
		if foundSeparator {
			after = append(after, arg)
		} else {
			before = append(before, arg)
		}
	}
	return before, after
}

func main() {
	// Get the file path for args
	argsRlocation := os.Getenv("RULES_HELM_HELM_RUNNER_ARGS_FILE")
	if argsRlocation == "" {
		log.Fatalf("RULES_HELM_HELM_RUNNER_ARGS_FILE environment variable is not set")
	}

	argsFilePath := helm_utils.GetRunfile(argsRlocation)

	// Read args from the file
	argv, err := helm_utils.ArgvWithFile(argsFilePath)
	if err != nil {
		log.Fatalf("Error loading command line args: %s", err)
	}

	internalArgs, helmArgs := parseArgsUpToDashDash(argv)

	// Setup flags for helm, chart, registry_url, and image_pushers
	rawHelmPath := flag.String("helm", "", "Path to helm binary")
	rawHelmPluginsPath := flag.String("helm_plugins", "", "The path to helm plugins.")
	rawChartPath := flag.String("chart", "", "Path to Helm .tgz file")
	rawImagePushers := flag.String("image_pushers", "", "Comma-separated list of image pusher executables")

	// Parse command line arguments
	flag.CommandLine.Parse(internalArgs)

	// Check required arguments
	if *rawHelmPath == "" || *rawHelmPluginsPath == "" || *rawChartPath == "" {
		log.Fatalf("Missing required arguments: helm, helm_plugins, chart")
	}

	helmPath := helm_utils.GetRunfile(*rawHelmPath)
	helmPluginsPath := helm_utils.GetRunfile(*rawHelmPluginsPath)
	chartPath := helm_utils.GetRunfile(*rawChartPath)

	// Update the chart path whenever it's found.
	for i, item := range helmArgs {
		helmArgs[i] = strings.ReplaceAll(item, *rawChartPath, chartPath)
	}

	var imagePushers []string
	if *rawImagePushers != "" {
		for _, pusher := range strings.Split(*rawImagePushers, ",") {
			imagePushers = append(imagePushers, helm_utils.GetRunfile(pusher))
		}
	}

	_, is_debug := os.LookupEnv("RULES_HELM_DEBUG")

	// Subprocess image pushers
	for _, pusher := range imagePushers {
		cmd := exec.Command(pusher)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr

		if is_debug {
			log.Println(strings.Join(cmd.Args, " "))
		}

		if err := cmd.Run(); err != nil {
			log.Fatalf("Failed to run image pusher %s: %v", pusher, err)
		}
	}

	cmd, err := helm_utils.BuildHelmCommand(helmPath, helmArgs, helmPluginsPath)
	if err != nil {
		log.Fatal(err)
	}

	cmd.Env = helm_utils.SandboxFreeEnv(cmd.Env)

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if is_debug {
		log.Println(strings.Join(cmd.Args, " "))
	}
	if err := cmd.Run(); err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			if status, ok := exitError.Sys().(syscall.WaitStatus); ok {
				exitCode := status.ExitStatus()
				os.Exit(exitCode)
			}
		}
		os.Exit(1)
	}
}
