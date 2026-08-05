package main

import (
	"bufio"
	"log"
	"os"

	"github.com/periareon/rules_helm/helm/private/helm_utils"
)

func main() {
	argsRlocation := os.Getenv("RULES_HELM_PUSHER_ARGS_FILE")
	if argsRlocation == "" {
		log.Fatalf("RULES_HELM_PUSHER_ARGS_FILE environment variable is not set")
	}

	argsFilePath := helm_utils.GetRunfile(argsRlocation)

	file, err := os.Open(argsFilePath)
	if err != nil {
		log.Fatalf("Failed to open args file %s: %v", argsFilePath, err)
	}
	defer file.Close()

	var imagePushers []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if line != "" {
			imagePushers = append(imagePushers, helm_utils.GetRunfile(line))
		}
	}
	if err := scanner.Err(); err != nil {
		log.Fatalf("Failed to read args file: %v", err)
	}

	if err := helm_utils.RunImagePushers(imagePushers); err != nil {
		log.Fatal(err)
	}
}
