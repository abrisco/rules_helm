package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"

	"github.com/abrisco/rules_helm/helm/private/stamp"
)

func main() {
	helm_bin := os.Getenv("HELM_BIN")
	stable_status_file := os.Getenv("STABLE_STATUS_FILE")
	volatile_status_file := os.Getenv("VOLATILE_STATUS_FILE")

	stamps, err := stamp.LoadStamps(volatile_status_file, stable_status_file)
	if err != nil {
		log.Fatalf("Error loading stamps: %v", err)
	}

	var stampedArgs = []string{}
	for _, arg := range os.Args[1:] {
		stampedArg, err := stamp.ReplaceKeyValues(arg, stamps)
		if err != nil {
			log.Fatalf("Error replacing key values for %s: %v", arg, err)
		}

		stampedArgs = append(stampedArgs, stampedArg)
	}

	cmd := exec.Command(helm_bin, stampedArgs...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("Error running helm: %v\n\n%s", err, output)
	}

	fmt.Print(string(output))
}
