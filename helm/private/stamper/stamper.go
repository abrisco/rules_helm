package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
)

type Arguments struct {
	StableStatusFile   string
	VolatileStatusFile string
	InputFile          string
	OutputFile         string
}

func parseArgs() Arguments {
	var args Arguments

	flag.StringVar(&args.StableStatusFile, "stable_status_file", "", "The stable status file (`ctx.info_file`)")
	flag.StringVar(&args.VolatileStatusFile, "volatile_status_file", "", "The stable status file (`ctx.version_file`)")
	flag.StringVar(&args.InputFile, "input_file", "", "The input file to stamp")
	flag.StringVar(&args.OutputFile, "output_file", "", "The output file to write")

	flag.Parse()

	return args
}

func loadStamps(volatileStatusFile string, stableStatusFile string) (map[string]string, error) {
	stamps := map[string]string{}

	stampFiles := []string{volatileStatusFile, stableStatusFile}
	for _, stampFile := range stampFiles {
		// The files may not be defined
		if len(stampFile) == 0 {
			continue
		}

		content, err := os.ReadFile(stampFile)
		if err != nil {
			return nil, fmt.Errorf("Error reading file %s: %w", stampFile, err)
		}

		for _, line := range strings.Split(string(content), "\n") {
			split := strings.SplitN(line, " ", 2)
			if len(split) < 2 {
				continue
			}
			key, val := split[0], split[1]
			stamps[key] = val
		}
	}

	return stamps, nil
}

func replaceKeyValues(content string, stamps map[string]string) (string, error) {
	for key, value := range stamps {
		replaceKey := fmt.Sprintf("{%s}", key)
		content = strings.ReplaceAll(content, replaceKey, value)
	}

	return content, nil
}

func main() {
	var args = parseArgs()

	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// Collect all stamp values
	stamps, err := loadStamps(args.VolatileStatusFile, args.StableStatusFile)
	if err != nil {
		log.Fatal(err)
	}

	// Read input file
	content, err := os.ReadFile(args.InputFile)
	if err != nil {
		log.Fatal(err)
	}

	// Apply stamping
	stampedContent, err := replaceKeyValues(string(content), stamps)
	if err != nil {
		log.Fatal(err)
	}

	// Write output file
	err = os.WriteFile(args.OutputFile, []byte(stampedContent), 0644)
	if err != nil {
		log.Fatal(err)
	}
}
