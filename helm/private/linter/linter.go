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
	"path/filepath"
	"strings"

	"github.com/abrisco/rules_helm/helm/private/helm_utils"
)

type Arguments struct {
	helm        string
	helmPlugins string
	pkg         string
	output      string
}

func makeAbsolutePath(path string) string {
	if filepath.IsAbs(path) {
		return path
	}
	cwd, err := os.Getwd()
	if err != nil {
		log.Fatal("Couldn't determine current working directory")
	}
	return filepath.Join(cwd, path)
}

func parse_args() Arguments {
	var args Arguments

	flag.StringVar(&args.helm, "helm", "", "The path to a helm executable")
	flag.StringVar(&args.helmPlugins, "helm_plugins", "", "The path to a helm plugins directory")
	flag.StringVar(&args.output, "output", "", "The path to the Bazel `HelmPackage` action output")
	flag.StringVar(&args.pkg, "package", "", "The path to the helm package to lint.")

	args_file, found := os.LookupEnv("RULES_HELM_HELM_LINT_TEST_ARGS_PATH")
	if found {
		content, err := os.ReadFile(helm_utils.GetRunfile(args_file))
		if err != nil {
			log.Fatal(err)
		}

		args := strings.Split(string(content), "\n")
		os.Args = append(os.Args, args...)
	}

	flag.Parse()

	return args
}

func extractPackage(sourcePath string, targetDir string) error {
	// Open the tar.gz file for reading
	file, err := os.Open(sourcePath)
	if err != nil {
		return err
	}
	defer file.Close()

	// Create a gzip reader
	gzipReader, err := gzip.NewReader(file)
	if err != nil {
		return err
	}
	defer gzipReader.Close()

	// Create a tar reader
	tarReader := tar.NewReader(gzipReader)

	// Iterate through the tar entries and extract them
	for {
		header, err := tarReader.Next()

		if err == io.EOF {
			break
		}

		if err != nil {
			return err
		}

		// Construct the target file path
		targetFilePath := filepath.Join(targetDir, header.Name)

		switch header.Typeflag {
		case tar.TypeDir:
			// Create directories if they don't exist
			err = os.MkdirAll(targetFilePath, 0755)
			if err != nil {
				return err
			}

		case tar.TypeReg:
			// Ensure the file's parents exist
			if err := os.MkdirAll(filepath.Dir(targetFilePath), 0755); err != nil {
				return err
			}
			// Create the file
			file, err := os.Create(targetFilePath)
			if err != nil {
				return err
			}
			defer file.Close()

			// Copy the file contents
			_, err = io.Copy(file, tarReader)
			if err != nil {
				return err
			}

		default:
			return fmt.Errorf("Unsupported tar entry type: %c", header.Typeflag)
		}
	}

	return nil
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

func lint(directory string, package_name string, helm string, helmPluginsDir string, output string) {
	cmd, err := helm_utils.BuildHelmCommand(helm, []string{"lint", package_name}, helmPluginsDir)
	if err != nil {
		log.Fatal(err)
	}

	cmd.Dir = directory

	out, err := cmd.Output()
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
	test_tmpdir, is_test := os.LookupEnv("TEST_TMPDIR")
	if is_test {
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

	var pkg = args.pkg
	var helm = args.helm
	var helmPlugins = args.helmPlugins
	if is_test {
		pkg = helm_utils.GetRunfile(pkg)
		helm = helm_utils.GetRunfile(helm)
		helmPlugins = helm_utils.GetRunfile(helmPlugins)
	} else {
		pkg = makeAbsolutePath(pkg)
		helm = makeAbsolutePath(helm)
		helmPlugins = makeAbsolutePath(helmPlugins)
	}

	if err := extractPackage(pkg, dir); err != nil {
		log.Fatal(err)
	}

	lint_dir := find_package_root(dir)

	lint(dir, lint_dir, helm, helmPlugins, args.output)
}
