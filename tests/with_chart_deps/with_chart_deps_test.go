package main

import (
	"archive/tar"
	"compress/gzip"
	"io"
	"os"
	"strings"
	"testing"

	"github.com/bazelbuild/rules_go/go/runfiles"
)

func WithChartDepsTest(t *testing.T) {
	// Retrieve the Helm chart location from the environment variable
	helmChartPath := os.Getenv("HELM_CHART")
	if helmChartPath == "" {
		t.Fatal("HELM_CHART environment variable is not set")
	}

	// Locate the runfile
	path, err := runfiles.Rlocation(helmChartPath)
	if err != nil {
		t.Fatalf("Failed to find runfile with: %v", err)
	}

	// Open the .tgz file
	file, err := os.Open(path)
	if err != nil {
		t.Fatalf("Failed to open the Helm chart file: %v", err)
	}
	defer file.Close()

	// Wrap the file in a Gzip reader
	gzr, err := gzip.NewReader(file)
	if err != nil {
		t.Fatalf("Failed to create Gzip reader: %v", err)
	}
	defer gzr.Close()

	// Create a tar reader from the Gzip reader
	tarReader := tar.NewReader(gzr)

	// Initialize flags to check for the two files
	var redisChartFound, postgresChartFound bool
	var redisChartContent, postgresChartContent string

	// Iterate through the tar archive
	for {
		header, err := tarReader.Next()
		if err == io.EOF {
			break // End of archive
		}
		if err != nil {
			t.Fatalf("Error reading tar archive: %v", err)
		}

		// Check for the two specific files
		if header.Name == "charts/redis/Chart.yaml" {
			redisChartFound = true
			content, err := io.ReadAll(tarReader)
			if err != nil {
				t.Fatalf("Failed to read redis Chart.yaml: %v", err)
			}
			redisChartContent = string(content)
		}

		if header.Name == "charts/postgresql/Chart.yaml" {
			postgresChartFound = true
			content, err := io.ReadAll(tarReader)
			if err != nil {
				t.Fatalf("Failed to read postgresql Chart.yaml: %v", err)
			}
			postgresChartContent = string(content)
		}
	}

	// Assert that both files were found
	if !redisChartFound {
		t.Error("charts/redis/Chart.yaml was not found in the Helm chart")
	}
	if !postgresChartFound {
		t.Error("charts/postgresql/Chart.yaml was not found in the Helm chart")
	}

	// Assert that the content of both files contains the expected strings
	if !strings.Contains(redisChartContent, "redis") {
		t.Error("charts/redis/Chart.yaml does not contain the expected string 'redis'")
	}
	if !strings.Contains(postgresChartContent, "postgres") {
		t.Error("charts/postgresql/Chart.yaml does not contain the expected string 'postgres'")
	}
}
