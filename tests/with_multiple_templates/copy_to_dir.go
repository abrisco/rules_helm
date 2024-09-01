package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	// Parse command line flags
	output := flag.String("output", "", "The output directory where files will be copied.")
	var srcFiles stringSliceFlag
	var rootPaths stringSliceFlag

	flag.Var(&srcFiles, "src", "Source file to be copied (can be passed multiple times).")
	flag.Var(&rootPaths, "root_path", "Root path to strip from source files (can be passed multiple times).")

	flag.Parse()

	// Validate the output directory
	if *output == "" {
		fmt.Println("Error: -output is required")
		os.Exit(1)
	}

	// Ensure output directory exists
	if err := os.MkdirAll(*output, os.ModePerm); err != nil {
		fmt.Printf("Error creating output directory: %v\n", err)
		os.Exit(1)
	}

	// Copy each source file to the output directory
	for _, src := range srcFiles {
		relativePath := stripRootPath(src, rootPaths)
		destPath := filepath.Join(*output, relativePath)

		// Ensure parent directory for destination exists
		if err := os.MkdirAll(filepath.Dir(destPath), os.ModePerm); err != nil {
			fmt.Printf("Error creating destination directory: %v\n", err)
			continue
		}

		// Copy the file
		if err := copyFile(src, destPath); err != nil {
			fmt.Printf("Error copying file from %s to %s: %v\n", src, destPath, err)
		}
	}
}

// stringSliceFlag is a custom flag type for collecting multiple values
type stringSliceFlag []string

func (i *stringSliceFlag) String() string {
	return strings.Join(*i, ",")
}

func (i *stringSliceFlag) Set(value string) error {
	*i = append(*i, value)
	return nil
}

// stripRootPath removes any matching root path prefix from the source file path
func stripRootPath(src string, rootPaths []string) string {
	for _, root := range rootPaths {
		if strings.HasPrefix(src, root) {
			return strings.TrimPrefix(src, root)
		}
	}
	return src
}

// copyFile copies a file from src to dst
func copyFile(src, dst string) error {
	sourceFile, err := os.Open(src)
	if err != nil {
		return err
	}
	defer sourceFile.Close()

	destFile, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer destFile.Close()

	_, err = io.Copy(destFile, sourceFile)
	return err
}
