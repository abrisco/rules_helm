package main

import (
	"archive/tar"
	"compress/gzip"
	"encoding/json"
	"io"
	"log"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"strings"
)

type Arguments struct {
	helm_package    string
	chart_patterns  string
	values_patterns string
}

func parse_args() Arguments {
	helm_package, _ := os.LookupEnv("HELM_PACKAGE")
	chart_patterns, _ := os.LookupEnv("CHART_PATTERNS")
	values_patterns, _ := os.LookupEnv("VALUES_PATTERNS")

	var args Arguments
	args.helm_package = helm_package
	args.chart_patterns = chart_patterns
	args.values_patterns = values_patterns

	return args
}

func test_patterns(helm_file string, patterns_file string) {
	helm_raw, err := os.ReadFile(helm_file)
	if err != nil {
		log.Fatal("Error reading file ", helm_file, ":", err)
	}
	helm_content := string(helm_raw)

	patterns_raw, err := os.ReadFile(patterns_file)
	if err != nil {
		log.Fatal("Error reading file ", patterns_file, ":", err)
	}

	// Deserialize the JSON into the slice
	var regexPatterns []string
	json_err := json.Unmarshal(patterns_raw, &regexPatterns)
	if json_err != nil {
		log.Fatal("Error deserializing json:", json_err)
	}

	// Access the parsed regex patterns
	for _, pattern := range regexPatterns {
		// Compile the regex pattern
		regex, err := regexp.Compile(pattern)
		if err != nil {
			log.Fatal("Error compiling regex:", err)
		}

		if !regex.MatchString(helm_content) {
			log.Fatal("The file ", path.Base(helm_file), " does not contain the pattern:\n", pattern)
		}
	}
}

func find_chart_and_value_files(dir string) (string, string) {
	var chart_file string
	var values_file string

	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			if info.Name() == "Chart.yaml" {
				chart_file = path
			}
			if info.Name() == "values.yaml" {
				values_file = path
			}
			if chart_file != "" && values_file != "" {
				return filepath.SkipDir
			}
		}
		return nil
	})

	if err != nil {
		log.Fatal("Failed to find chart and value files: ", err)
	}

	if chart_file == "" {
		log.Fatal("Failed to find Chart.yaml")
	}

	if values_file == "" {
		log.Fatal("Failed to find values.yaml")
	}

	return chart_file, values_file
}

func extract_tar_gz(file string, location string) {
	gzipStream, err := os.Open(file)
	if err != nil {
		log.Fatal("error reading ", file, err)
	}

	uncompressedStream, err := gzip.NewReader(gzipStream)
	if err != nil {
		log.Fatal("ExtractTarGz: NewReader failed")
	}

	tarReader := tar.NewReader(uncompressedStream)

	if err := os.MkdirAll(location, 0755); err != nil {
		log.Fatal("Failed to create directory ", location, " ", err)
	}

	for true {
		header, err := tarReader.Next()

		if err == io.EOF {
			break
		}

		if err != nil {
			log.Fatalf("ExtractTarGz: Next() failed: %s", err.Error())
		}

		switch header.Typeflag {
		case tar.TypeDir:
			if err := os.Mkdir(path.Join(location, header.Name), 0755); err != nil {
				log.Fatalf("ExtractTarGz: Mkdir() failed: %s", err.Error())
			}
		case tar.TypeReg:
			outFileName := path.Join(location, header.Name)

			if err := os.MkdirAll(path.Dir(outFileName), 0755); err != nil {
				log.Fatal("Failed to create directory ", outFileName, " ", err)
			}

			outFile, err := os.Create(outFileName)
			if err != nil {
				log.Fatalf("ExtractTarGz: Create() failed: %s", err.Error())
			}
			if _, err := io.Copy(outFile, tarReader); err != nil {
				log.Fatalf("ExtractTarGz: Copy() failed: %s", err.Error())
			}
			outFile.Close()

		default:
			log.Fatal("ExtractTarGz: unknown type: ", header.Typeflag, " in ", header.Name)
		}
	}
}

func main() {
	// Parse arguments
	var args = parse_args()

	log.SetFlags(log.LstdFlags | log.Lshortfile)

	test_tmpdir, found_test_tmpdir := os.LookupEnv("TEST_TMPDIR")
	if !found_test_tmpdir {
		log.Fatalf("Failed to find TEST_TMPDIR environment variable.")
	}

	test_name, found_test_name := os.LookupEnv("TEST_TARGET")
	if !found_test_name {
		log.Fatalf("Failed to find TEST_TARGET environment variable.")
	}

	extract_dir := path.Join(test_tmpdir, strings.ReplaceAll(strings.ReplaceAll(test_name, "@", ""), ":", "/"))

	// Extract helm package
	extract_tar_gz(args.helm_package, extract_dir)

	// Locate chart and value files
	chart_file, value_file := find_chart_and_value_files(extract_dir)

	// Perform regex tests
	test_patterns(chart_file, args.chart_patterns)
	test_patterns(value_file, args.values_patterns)
}
