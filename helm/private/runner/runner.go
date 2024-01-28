package main

import (
	"log"
	"os"
	"os/exec"

	"github.com/abrisco/rules_helm/helm/private/stamp"
)

func main() {
	helm_bin := os.Getenv("HELM_BIN")
	stable_status_file, ok := os.LookupEnv("STABLE_STATUS_FILE")
	volatile_status_file, ok := os.LookupEnv("VOLATILE_STATUS_FILE")

	var args = []string{}
	if ok {
		stamps, err := stamp.LoadStamps(volatile_status_file, stable_status_file)
		if err != nil {
			log.Fatalf("Error loading stamps: %v", err)
		}

		for _, arg := range os.Args[1:] {
			stampedArg, err := stamp.ReplaceKeyValues(arg, stamps)
			if err != nil {
				log.Fatalf("Error replacing key values for %s: %v", arg, err)
			}

			args = append(args, stampedArg)
		}
	} else {
		args = os.Args[1:]
	}

	cmd := exec.Command(helm_bin, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Fatalf("Error running helm: %v", err)
	}
}
