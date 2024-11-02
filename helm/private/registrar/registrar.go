package main

import (
	"bufio"
	"flag"
	"fmt"
	"log"
	"net/url"
	"os"
	"os/exec"
	"strings"

	"github.com/bazelbuild/rules_go/go/runfiles"
)

// Chart represents the structure of Chart.yaml
type Chart struct {
	Version string `yaml:"version"`
}

func readArgsFromFile(filepath string) ([]string, error) {
	file, err := os.Open(filepath)
	if err != nil {
		return nil, fmt.Errorf("failed to open arguments file: %w", err)
	}
	defer file.Close()

	var args []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		args = append(args, scanner.Text())
	}

	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("failed to read arguments file: %w", err)
	}
	return args, nil
}

func getRunfile(runfile_path string) string {

	runfiles, err := runfiles.New()
	if err != nil {
		log.Fatalf("Failed to load runfiles: ", err)
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

func getHostFromURL(inputURL string) (string, error) {
	// Replace "oci://" with "https://" so that net/url can parse it
	parsedURL, err := url.Parse(strings.Replace(inputURL, "oci://", "https://", 1))
	if err != nil {
		return "", fmt.Errorf("failed to parse URL: %w", err)
	}
	return parsedURL.Host, nil
}

func main() {
	// Get the file path for args
	argsRlocation := os.Getenv("HELM_PUSH_ARGS_FILE")
	if argsRlocation == "" {
		log.Fatalf("HELM_PUSH_ARGS_FILE environment variable is not set")
	}

	argsFilePath := getRunfile(argsRlocation)

	// Read args from the file
	fileArgs, err := readArgsFromFile(argsFilePath)
	if err != nil {
		log.Fatalf("Error reading arguments file: %v", err)
	}

	// Setup flags for helm, chart, registry_url, and image_pushers
	rawHelmPath := flag.String("helm", "", "Path to helm binary")
	rawChartPath := flag.String("chart", "", "Path to Helm .tgz file")
	registryURL := flag.String("registry_url", "", "URL of registry to upload helm chart")
	rawLoginURL := flag.String("login_url", "", "URL of registry to login to.")
	rawImagePushers := flag.String("image_pushers", "", "Comma-separated list of image pusher executables")

	// Parse command line arguments
	flag.CommandLine.Parse(fileArgs)

	// Check required arguments
	if *rawHelmPath == "" || *rawChartPath == "" || *registryURL == "" {
		log.Fatalf("Missing required arguments: helm, chart, registry_url")
	}

	helmPath := getRunfile(*rawHelmPath)
	chartPath := getRunfile(*rawChartPath)

	var imagePushers []string
	if *rawImagePushers != "" {
		for _, pusher := range strings.Split(*rawImagePushers, ",") {
			imagePushers = append(imagePushers, getRunfile(pusher))
		}
	}

	// Check for registry login credentials
	helmUser := os.Getenv("HELM_REGISTRY_USERNAME")
	var helmPassword string

	// Try to get the password from HELM_REGISTRY_PASSWORD or HELM_REGISTRY_PASSWORD_FILE
	if pwFile := os.Getenv("HELM_REGISTRY_PASSWORD_FILE"); pwFile != "" {
		// Read the first line from the specified password file
		file, err := os.Open(pwFile)
		if err != nil {
			log.Fatalf("Failed to open password file: %v", err)
		}
		defer file.Close()

		scanner := bufio.NewScanner(file)
		if scanner.Scan() {
			helmPassword = scanner.Text()
		}
		if err := scanner.Err(); err != nil {
			log.Fatalf("Failed to read password file: %v", err)
		}
	} else {
		// Use HELM_REGISTRY_PASSWORD if HELM_REGISTRY_PASSWORD_FILE is not set
		helmPassword = os.Getenv("HELM_REGISTRY_PASSWORD")
	}

	// Proceed with login if both username and password are available
	if helmUser != "" && helmPassword != "" {
		loginUrl := *rawLoginURL

		// If an explicit login url was not set, attempt to parse it from registryURL.
		if loginUrl == "" {
			host, err := getHostFromURL(*registryURL)
			if err == nil {
				loginUrl = host
			}
		}

		loginCmd := exec.Command(helmPath, "registry", "login", "--username", helmUser, "--password-stdin", loginUrl)
		loginCmd.Stdout = os.Stdout
		loginCmd.Stderr = os.Stderr

		// Provide the password to stdin of the login command
		loginCmd.Stdin = strings.NewReader(helmPassword)

		log.Printf("Logging into Helm registry `%s`...\n", loginUrl)
		if err := loginCmd.Run(); err != nil {
			log.Fatalf("Failed to login to Helm registry: %v", err)
		}
	} else if helmUser != "" {
		log.Printf("WARNING: A Helm registry username was set but no associated `HELM_REGISTRY_PASSWORD`/`HELM_REGISTRY_PASSWORD_FILE` var was found. Skipping `helm registry login`.")
	} else if helmPassword != "" {
		log.Printf("WARNING: A Helm registry password was set but no associated `HELM_REGISTRY_USERNAME` var was found. Skipping `helm registry login`.")
	}

	// Subprocess image pushers
	for _, pusher := range imagePushers {
		cmd := exec.Command(pusher)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr

		log.Printf("Running image pusher: %s", pusher)
		if err := cmd.Run(); err != nil {
			log.Fatalf("Failed to run image pusher %s: %v", pusher, err)
		}
	}

	// Subprocess helm push
	pushCmd := exec.Command(helmPath, "push", chartPath, *registryURL)
	pushCmd.Stdout = os.Stdout
	pushCmd.Stderr = os.Stderr

	log.Printf("Running helm push: %s", pushCmd.String())
	if err := pushCmd.Run(); err != nil {
		log.Fatalf("Failed to push helm chart: %v", err)
	}
}
