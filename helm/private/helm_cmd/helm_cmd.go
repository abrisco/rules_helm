package helm_cmd

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
)

func BuildHelmCommand(helmPath string, args []string, pluginsDir string) (exec.Cmd, error) {
	// Create a temporary directory with a specified prefix.
	tempDir, err := os.MkdirTemp(os.Getenv("TEST_TMPDIR"), "helm_cmd-")
	if err != nil {
		log.Fatal(err)
	}

	// Generate a fake kubeconfig for more consistent results when building packages
	kubeconfig := filepath.Join(tempDir, ".kubeconfig")
	file, err := os.Create(kubeconfig)
	if err != nil {
		log.Fatal(err)
	}
	if err := file.Chmod(0700); err != nil {
		log.Fatal(err)
	}
	file.Close()

	// Set the HELM_PLUGINS environment variable for plugins directory
	cmd := exec.Command(helmPath, args...)

	env := os.Environ()
	env = append(env, fmt.Sprintf("HELM_PLUGINS=%s", pluginsDir))
	env = append(env, fmt.Sprintf("HELM_CACHE_HOME=%s", filepath.Join(tempDir, "cache")))
	env = append(env, fmt.Sprintf("HELM_CONFIG_HOME=%s", filepath.Join(tempDir, "config")))
	env = append(env, fmt.Sprintf("HELM_DATA_HOME=%s", filepath.Join(tempDir, "data")))
	env = append(env, fmt.Sprintf("HELM_REPOSITORY_CACHE=%s", filepath.Join(tempDir, "repository_cache")))
	env = append(env, fmt.Sprintf("HELM_REPOSITORY_CONFIG=%s", filepath.Join(tempDir, "repositories.yaml")))
	env = append(env, fmt.Sprintf("HELM_REGISTRY_CONFIG=%s", filepath.Join(tempDir, "config.json")))
	env = append(env, fmt.Sprintf("KUBECONFIG=%s", kubeconfig))

	return *cmd, nil
}
