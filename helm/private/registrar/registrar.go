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

	"github.com/abrisco/rules_helm/helm/private/helm_cmd"
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

// Because the registrar runs outside of Bazel, there are environment variables
// we want to explicitly allow from the host machine.
func updateEnv(current []string) []string {

	keysToRemove := []string{
		"HELM_CACHE_HOME",
		"HELM_CONFIG_HOME",
		"HELM_DATA_HOME",
		"HELM_REPOSITORY_CACHE",
		"HELM_REPOSITORY_CONFIG",
		"HELM_REGISTRY_CONFIG",
		"KUBECONFIG",
	}

	// Convert envVars to a map for easier lookup
	currentEnv := make(map[string]string)
	for _, envVar := range current {
		parts := strings.SplitN(envVar, "=", 2)
		if len(parts) == 2 {
			key := parts[0]
			value := parts[1]
			currentEnv[key] = value
		}
	}

	// Convert replacements to a map for easier lookup
	globalEnv := make(map[string]string)
	for _, replacement := range os.Environ() {
		parts := strings.SplitN(replacement, "=", 2)
		if len(parts) == 2 {
			key := parts[0]
			value := parts[1]
			globalEnv[key] = value
		}
	}

	// Process the removal and replacement
	for _, key := range keysToRemove {
		if value, exists := globalEnv[key]; exists {
			// If the key exists in the replacements map, update the original map
			currentEnv[key] = value
		} else {
			// If the key does not exist in the replacements map, delete it
			delete(currentEnv, key)
		}
	}

	newEnv := make([]string, 0, len(currentEnv))
	for key, value := range currentEnv {
		newEnv = append(newEnv, fmt.Sprintf("%s=%s", key, value))
	}

	return newEnv
}

func runHelm(helmPath string, args []string, pluginsDir string, stdin *string) {
	cmd, err := helm_cmd.BuildHelmCommand(helmPath, args, pluginsDir)
	if err != nil {
		log.Fatal(err)
	}

	cmd.Env = updateEnv(cmd.Env)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if stdin != nil {
		cmd.Stdin = strings.NewReader(*stdin)
	}

	if err := cmd.Run(); err != nil {
		log.Fatalf("Failed to run helm command: %w", err)
	}
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
	rawHelmPluginsPath := flag.String("helm_plugins", "", "The path to helm plugins.")
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
	helmPluginsPath := getRunfile(*rawHelmPluginsPath)
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

		log.Printf("Logging into Helm registry `%s`...\n", loginUrl)
		runHelm(helmPath, []string{"registry", "login", "--username", helmUser, "--password-stdin", loginUrl}, helmPluginsPath, &helmPassword)
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
	log.Println("Running helm push...")
	runHelm(helmPath, []string{"push", chartPath, *registryURL}, helmPluginsPath, nil)
}
