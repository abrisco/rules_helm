package main

import (
	"fmt"
	"io"
	"log"
	"os"
)

func main() {
	// Check for correct number of arguments
	if len(os.Args) != 3 {
		log.Fatalf("Usage: copier <source> <destination>")
	}

	sourcePath := os.Args[1]
	destPath := os.Args[2]

	// Perform the file copy
	if err := copyFile(sourcePath, destPath); err != nil {
		log.Fatalf("Error copying file: %v\n", err)
	}
}

// copyFile copies the contents of the source file to the destination file
func copyFile(source string, destination string) error {
	// Open the source file for reading
	sourceFile, err := os.Open(source)
	if err != nil {
		return fmt.Errorf("failed to open source file: %w", err)
	}
	defer sourceFile.Close()

	// Create the destination file
	destFile, err := os.Create(destination)
	if err != nil {
		return fmt.Errorf("failed to create destination file: %w", err)
	}
	defer destFile.Close()

	// Copy the contents from the source to the destination
	_, err = io.Copy(destFile, sourceFile)
	if err != nil {
		return fmt.Errorf("error during copy: %w", err)
	}

	// Ensure all data is written to the destination file
	err = destFile.Sync()
	if err != nil {
		return fmt.Errorf("failed to sync destination file: %w", err)
	}

	return nil
}
