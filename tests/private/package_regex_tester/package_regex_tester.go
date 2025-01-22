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

	"github.com/bazelbuild/rules_go/go/runfiles"
)

func GetRunfile(runfile_path string) string {

	runfiles, err := runfiles.New()
	if err != nil {
		log.Fatalf("Failed to load runfiles: %s", err)
	}

	// Use the runfiles library to locate files
	runfile, err := runfiles.Rlocation(runfile_path)
	if err != nil {
		log.Fatal("When reading file ", runfile_path, " got error ", err)
	}

	// Check that the file actually exist
	if _, err := os.Stat(runfile); err != nil {
		log.Fatal("File found by runfile doesn't exist")
	}

	return runfile
}

type Arguments struct {
	helm_package       string
	chart_patterns     string
	values_patterns    string
	templates_patterns string
}

func parse_args() Arguments {
	helm_package, _ := os.LookupEnv("HELM_PACKAGE")
	chart_patterns, _ := os.LookupEnv("CHART_PATTERNS")
	values_patterns, _ := os.LookupEnv("VALUES_PATTERNS")
	templates_patterns, _ := os.LookupEnv("TEMPLATES_PATTERNS")

	var args Arguments
	args.helm_package = GetRunfile(helm_package)
	args.chart_patterns = GetRunfile(chart_patterns)
	args.values_patterns = GetRunfile(values_patterns)
	args.templates_patterns = GetRunfile(templates_patterns)

	return args
}

func test_patterns(file string, patterns []string) {
	file_content_raw, err := os.ReadFile(file)
	if err != nil {
		log.Fatal("Error reading file ", file, ":", err)
	}
	file_content := string(file_content_raw)

	// Access the parsed regex patterns
	for _, pattern := range patterns {
		// Compile the regex pattern
		regex, err := regexp.Compile(pattern)
		if err != nil {
			log.Fatal("Error compiling regex:", err)
		}

		if !regex.MatchString(file_content) {
			log.Fatal("The file ", path.Base(file), " does not contain the pattern:\n", pattern)
		}
	}
}

func find_file(dir string, file_name string) string {
	var found_file string

	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && info.Name() == file_name {
			found_file = path
			return filepath.SkipDir
		}
		return nil
	})

	if err != nil {
		log.Fatal("Failed to find file: ", file_name, " in directory: ", dir, " with error: ", err)
	}

	if found_file == "" {
		log.Fatal("Failed to find file: ", file_name)
	}

	return found_file
}

func read_patterns_file(filePath string) []string {
	// Read the file content
	fileContent, err := os.ReadFile(filePath)
	if err != nil {
		log.Fatalf("Error reading file %s: %v", filePath, err)
	}

	// Decode the JSON into a list of strings
	var patterns []string
	if err := json.Unmarshal(fileContent, &patterns); err != nil {
		log.Fatalf("Error decoding JSON from file %s: %v", filePath, err)
	}

	return patterns
}

func extract_tar_gz(file string, location string) {
	gzipStream, err := os.Open(file)
	if err != nil {
		log.Fatal("Error reading ", file, err)
	}

	uncompressedStream, err := gzip.NewReader(gzipStream)
	if err != nil {
		log.Fatal("ExtractTarGz: NewReader failed")
	}

	tarReader := tar.NewReader(uncompressedStream)

	if err := os.MkdirAll(location, 0755); err != nil {
		log.Fatal("Failed to create directory ", location, " ", err)
	}

	for {
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
	chart_file := find_file(extract_dir, "Chart.yaml")
	value_file := find_file(extract_dir, "values.yaml")

	chart_patterns := read_patterns_file(args.chart_patterns)
	value_patterns := read_patterns_file(args.values_patterns)

	// Perform regex tests for Chart.yaml and values.yaml
	test_patterns(chart_file, chart_patterns)
	test_patterns(value_file, value_patterns)

	// Handle templates patterns
	if args.templates_patterns != "" {
		templates_patterns_raw, err := os.ReadFile(args.templates_patterns)
		if err != nil {
			log.Fatal("Error reading templates patterns file:", err)
		}

		var templates_patterns map[string][]string
		if err := json.Unmarshal(templates_patterns_raw, &templates_patterns); err != nil {
			log.Fatal("Error parsing templates patterns JSON:", err)
		}

		for template, patterns := range templates_patterns {
			template_file := find_file(extract_dir, template)
			test_patterns(template_file, patterns)
		}
	}
}
