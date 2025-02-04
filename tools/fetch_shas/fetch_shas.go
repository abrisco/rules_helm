package main

import (
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strings"
)

// Format arguments are `{version}`, `{platform}`, `{compression}`.
var CHECKSUM_URL_TEMPLATE = "https://get.helm.sh/helm-v%s-%s.%s.sha256sum"

var PLATFORMS = []string{
	"darwin-amd64",
	"darwin-arm64",
	"linux-amd64",
	"linux-arm",
	"linux-arm64",
	"linux-i386",
	"linux-ppc64le",
	"windows-amd64",
}

// fetchSHA256 fetches and parses the sha256sum file
func fetchSHA256(version string, platform string) (string, error) {
	compression := "tar.gz"
	if strings.Contains(platform, "windows") {
		compression = "zip"
	}

	// Sanitize platform names.
	if platform == "linux-i386" {
		platform = "linux-386"
	}

	url := fmt.Sprintf(CHECKSUM_URL_TEMPLATE, version, platform, compression)
	resp, err := http.Get(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("failed to fetch: %s, status: %d", url, resp.StatusCode)
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	parts := strings.Fields(string(body))
	if len(parts) < 2 {
		return "", fmt.Errorf("unexpected file format: %s", body)
	}

	checksum, err := hex.DecodeString(parts[0])
	if err != nil {
		return "", fmt.Errorf("failed to decode hex checksum: %v", err)
	}

	encodedChecksum := base64.StdEncoding.EncodeToString(checksum)
	return fmt.Sprintf("sha256-%s", encodedChecksum), nil
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Error: version is required")
		fmt.Println("Usage: fetch_shas <version>")
		os.Exit(1)
	}

	version := os.Args[1]

	result := make(map[string]map[string]string)
	result[version] = make(map[string]string)

	for _, platform := range PLATFORMS {
		sha256sum, err := fetchSHA256(version, platform)
		if err != nil {
			log.Fatalf("Error fetching %s-%s: %v\n", version, platform, err)
		}
		result[version][platform] = sha256sum
	}

	jsonOutput, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		log.Fatalf("Error generating JSON:", err)
	}
	fmt.Println(string(jsonOutput))
}
