package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
)

// ManifestEntry represents the structure of each entry in the manifest
type ManifestEntry struct {
	YAML string   `json:"yaml"`
	Data []string `json:"data"`
}

// Manifest represents the entire manifest map
type Manifest map[string]ManifestEntry

func main() {
	// Parse command-line flags
	outputDir := flag.String("output", "", "Path to the output directory")
	manifestPath := flag.String("manifest", "", "Path to the manifest JSON file")
	flag.Parse()

	// Validate the flags
	if *outputDir == "" || *manifestPath == "" {
		fmt.Println("Both -output and -manifest are required")
		flag.Usage()
		os.Exit(1)
	}

	// Create an empty .rules_helm file in the output directory
	rulesHelmPath := filepath.Join(*outputDir, ".rules_helm")
	if _, err := os.Create(rulesHelmPath); err != nil {
		log.Fatalf("Failed to create .rules_helm file in %s: %v\n", *outputDir, err)
	}

	// Read and parse the manifest JSON
	manifestFile, err := os.Open(*manifestPath)
	if err != nil {
		log.Fatalf("Failed to open manifest file: %v\n", err)
	}
	defer manifestFile.Close()

	var manifest Manifest
	decoder := json.NewDecoder(manifestFile)
	if err := decoder.Decode(&manifest); err != nil {
		log.Fatalf("Failed to parse manifest JSON: %v\n", err)
	}

	// Process each entry in the manifest
	for key, entry := range manifest {
		// Validate that all data files have the same parent directory as the YAML file
		yamlDir := filepath.Dir(entry.YAML)

		for _, dataFile := range entry.Data {
			if !strings.HasPrefix(filepath.Dir(dataFile), yamlDir) {
				log.Fatalf("Error: Data file %s does not have the same parent directory as YAML file %s\n", dataFile, entry.YAML)
			}
		}

		// Create the directory for this key in the output path
		targetDir := filepath.Join(*outputDir, key)
		if err := os.MkdirAll(targetDir, os.ModePerm); err != nil {
			log.Fatalf("Failed to create directory %s: %v\n", targetDir, err)
		}

		// Copy the YAML file
		if err := copyFile(entry.YAML, filepath.Join(targetDir, filepath.Base(entry.YAML))); err != nil {
			log.Fatalf("Failed to copy YAML file for %s: %v\n", key, err)
		}

		// Copy each data file and preserve the relative directory structure
		for _, dataFile := range entry.Data {
			relativePath, err := filepath.Rel(yamlDir, dataFile)
			if err != nil {
				log.Fatalf("Failed to determine relative path for %s: %v\n", dataFile, err)
			}

			dataTargetPath := filepath.Join(targetDir, relativePath)
			if err := os.MkdirAll(filepath.Dir(dataTargetPath), os.ModePerm); err != nil {
				log.Fatalf("Failed to create directory %s: %v\n", filepath.Dir(dataTargetPath), err)
			}

			if err := copyFile(dataFile, dataTargetPath); err != nil {
				log.Fatalf("Failed to copy data file %s for %s: %v\n", dataFile, key, err)
			}
		}
	}
}

// copyFile copies a file from src to dst
func copyFile(src, dst string) error {
	sourceFile, err := os.Open(src)
	if err != nil {
		return fmt.Errorf("unable to open source file: %w", err)
	}
	defer sourceFile.Close()

	destinationFile, err := os.Create(dst)
	if err != nil {
		return fmt.Errorf("unable to create destination file: %w", err)
	}
	defer destinationFile.Close()

	_, err = io.Copy(destinationFile, sourceFile)
	if err != nil {
		return fmt.Errorf("failed to copy data: %w", err)
	}

	return nil
}
