package main

import (
	"archive/tar"
	"compress/gzip"
	"crypto/sha256"
	"encoding/hex"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/bazelbuild/rules_go/go/tools/bazel"
)

type Arguments struct {
	helm   string
	pkg    string
	output string
}

func parse_args() Arguments {
	var args Arguments

	flag.StringVar(&args.helm, "helm", "", "The path to a helm executable")
	flag.StringVar(&args.output, "output", "", "The path to the Bazel `HelmPackage` action output")
	flag.StringVar(&args.pkg, "package", "", "The path to the helm package to lint.")

	args_file, found := os.LookupEnv("RULES_HELM_HELM_LINT_TEST_ARGS_PATH")
	if found {
		content, err := os.ReadFile(args_file)
		if err != nil {
			log.Fatal(err)
		}

		args := strings.Split(string(content), "\n")
		os.Args = append(os.Args, args...)
	}

	flag.Parse()

	return args
}

func extract_package(source string, target string) {

	reader, err := os.Open(source)
	if err != nil {
		log.Fatal(err)
	}
	defer reader.Close()

	gzr, err := gzip.NewReader(reader)
	if err != nil {
		log.Fatal(err)
	}
	defer gzr.Close()

	tr := tar.NewReader(gzr)

	for {
		header, err := tr.Next()

		switch {

		// if no more files are found return
		case err == io.EOF:
			return

		// return any other error
		case err != nil:
			log.Fatal(err)

		// if the header is nil, just skip it (not sure how this happens)
		case header == nil:
			log.Fatal("NULL")
			continue
		}

		// the target location where the dir/file should be created
		target := filepath.Join(target, header.Name)

		// check the file type
		switch header.Typeflag {

		// if its a dir and it doesn't exist create it
		case tar.TypeDir:
			if _, err := os.Stat(target); err != nil {
				if err := os.MkdirAll(target, 0755); err != nil {
					log.Fatal(err)
				}
			}

		// if it's a file create it
		case tar.TypeReg:
			parent := filepath.Dir(target)
			if err := os.MkdirAll(parent, 0755); err != nil {
				log.Fatal(err)
			}
			f, err := os.OpenFile(target, os.O_CREATE|os.O_RDWR, os.FileMode(header.Mode))
			if err != nil {
				log.Fatal(err)
			}

			// copy over contents
			if _, err := io.Copy(f, tr); err != nil {
				log.Fatal(err)
			}

			// manually close here after each file operation; deferring would cause each file close
			// to wait until all operations have completed.
			f.Close()
		}
	}
}

func find_package_root(extract_dir string) string {
	// After the package is extracted, there should be one directory within it.
	// locate this and return it for linting
	dir, err := os.Open(extract_dir)
	if err != nil {
		log.Fatal(err)
	}
	file_info, err := dir.Readdir(-1)
	if err != nil {
		log.Fatal(err)
	}
	defer dir.Close()

	if len(file_info) == 0 {
		log.Fatal("Unexpected number of files for", file_info)
	}

	return file_info[0].Name()
}

func lint(directory string, package_name string, helm string, output string) {
	command := exec.Command(helm, "lint", package_name)
	command.Dir = directory
	out, err := command.Output()
	if err != nil {
		os.Stderr.WriteString(string(out))
		log.Fatal(err)
	}

	if len(output) > 0 {
		parent := filepath.Dir(output)
		dir_err := os.MkdirAll(parent, 0755)
		if dir_err != nil {
			log.Fatal(dir_err)
		}
		f, err := os.Create(output)
		if err != nil {
			log.Fatal(err)
		}
		defer f.Close()

		_, write_err := f.Write(out)
		if write_err != nil {
			log.Fatal(write_err)
		}
	}
}

func get_runfile(runfile_path string) string {

	// Use the runfiles library to locate files
	runfile, err := bazel.Runfile(runfile_path)
	if err != nil {
		log.Fatal("When reading file ", runfile_path, " got error ", err)
	}

	// Check that the file actually exist
	if _, err := os.Stat(runfile); err != nil {
		log.Fatal("File found by runfile doesn't exist")
	}

	return runfile
}

func hashString(text string) string {
	// Create a new SHA-256 hash
	hasher := sha256.New()

	// Write the string to the hash
	hasher.Write([]byte(text))

	// Get the final hash sum as a byte slice
	hashSum := hasher.Sum(nil)

	// Convert the byte slice to a hexadecimal string
	return hex.EncodeToString(hashSum)
}

func main() {
	args := parse_args()

	log.SetFlags(log.LstdFlags | log.Lshortfile)

	cwd, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}

	var prefix = ""
	test_tmpdir, found := os.LookupEnv("TEST_TMPDIR")
	if found {
		prefix = test_tmpdir
	} else {
		prefix = cwd
	}

	// Generate a directory name but keep it short for windows
	dir_name := fmt.Sprintf("rules_helm_lint_%s", hashString(args.output)[:12])
	dir := filepath.Join(prefix, dir_name)

	// Ensure the directory is clean
	if err := os.RemoveAll(dir); err != nil {
		log.Fatal(err)
	}
	if err := os.MkdirAll(dir, 0700); err != nil {
		log.Fatal(err)
	}

	extract_package(get_runfile(args.pkg), dir)
	lint_dir := find_package_root(dir)

	lint(dir, lint_dir, get_runfile(args.helm), args.output)
}
