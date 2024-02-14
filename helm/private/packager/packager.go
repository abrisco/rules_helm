package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"

	"gopkg.in/yaml.v3"
)

type ImageInfo struct {
	Label      string
	Repository string
	Digest     string
}

type ImageManifest struct {
	Label          string `json:"label"`
	RepositoryPath string `json:"repository_path"`
	ImageRootPath  string `json:"image_root_path"`
}

type ImageIndexManifest struct {
	MediaType string `json:"mediaType"`
	Size      int    `json:"size"`
	Digest    string `json:"digest"`
}

type ImageIndex struct {
	SchemaVersion int                  `json:"schemaVersion"`
	MediaType     string               `json:"mediaType"`
	Manifests     []ImageIndexManifest `json:"manifests"`
}

type TemplatesManfiest map[string]string
type DepsManfiest []string

type HelmResultMetadata struct {
	Name    string
	Version string
}

type HelmMaintainer struct {
	Name  string `yaml:"name"`
	Email string `yaml:"email,omitempty"`
	Url   string `yaml:"url,omitempty"`
}

type HelmDependency struct {
	Name         string   `yaml:"name"`
	Version      string   `yaml:"version"`
	Repository   string   `yaml:"repository,omitempty"`
	Condition    string   `yaml:"condition,omitempty"`
	Tags         []string `yaml:"tags,omitempty"`
	ImportValues []string `yaml:"import-values,omitempty"`
	Alias        string   `yaml:"alias,omitempty"`
}

type HelmChart struct {
	ApiVersion   string            `yaml:"apiVersion"`
	Name         string            `yaml:"name"`
	Version      string            `yaml:"version"`
	KubeVersion  string            `yaml:"kubeVersion,omitempty"`
	Description  string            `yaml:"description,omitempty"`
	Type         string            `yaml:"type,omitempty"`
	Keywords     []string          `yaml:"keywords,omitempty"`
	Home         string            `yaml:"home,omitempty"`
	Sources      []string          `yaml:"sources,omitempty"`
	Dependencies []HelmDependency  `yaml:"dependencies,omitempty"`
	Maintainers  []HelmMaintainer  `yaml:"maintainers,omitempty"`
	Icon         string            `yaml:"icon,omitempty"`
	AppVersion   string            `yaml:"appVersion,omitempty"`
	Deprecated   bool              `yaml:"deprecated,omitempty"`
	Annotations  map[string]string `yaml:"annotations,omitempty"`
}

type Arguments struct {
	TemplatesManifest  string
	Chart              string
	Values             string
	Substitutions      string
	DepsManifest       string
	Helm               string
	Output             string
	MetadataOutput     string
	ImageManifest      string
	StableStatusFile   string
	VolatileStatusFile string
	WorkspaceName      string
}

func parseArgs() Arguments {
	var args Arguments

	flag.StringVar(&args.TemplatesManifest, "templates_manifest", "", "A helm file containing a list of all helm template files")
	flag.StringVar(&args.Chart, "chart", "", "The helm `chart.yaml` file")
	flag.StringVar(&args.Values, "values", "", "The helm `values.yaml` file.")
	flag.StringVar(&args.Substitutions, "substitutions", "", "A json file containing key value pairs to substitute into the values file")
	flag.StringVar(&args.DepsManifest, "deps_manifest", "", "A file containing a list of all helm dependency (`charts/*.tgz`) files")
	flag.StringVar(&args.Helm, "helm", "", "The path to a helm executable")
	flag.StringVar(&args.Output, "output", "", "The path to the Bazel `HelmPackage` action output")
	flag.StringVar(&args.MetadataOutput, "metadata_output", "", "The path to the Bazel `HelmPackage` action metadata output")
	flag.StringVar(&args.ImageManifest, "image_manifest", "", "Information about Bazel produced container oci images used by the helm chart")
	flag.StringVar(&args.StableStatusFile, "stable_status_file", "", "The stable status file (`ctx.info_file`)")
	flag.StringVar(&args.VolatileStatusFile, "volatile_status_file", "", "The stable status file (`ctx.version_file`)")
	flag.StringVar(&args.WorkspaceName, "workspace_name", "", "The name of the current Bazel workspace")
	flag.Parse()

	return args
}

func loadStamps(volatileStatusFile string, stableStatusFile string) ([]ReplacementGroup, error) {
	replacementGroups := []ReplacementGroup{}

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
			split := strings.SplitN(strings.TrimRight(line, "\r"), " ", 2)
			if len(split) < 2 {
				continue
			}
			key, val := split[0], split[1]
			replacementGroups = append(replacementGroups, ReplacementGroup{
				Name: key,
				Replacements: map[string]string{
					key: val,
				},
			})
		}
	}

	return replacementGroups, nil
}

func loadImageInfos(imageManifestPath string) ([]ImageInfo, error) {
	if len(imageManifestPath) == 0 {
		return nil, fmt.Errorf("No image manifest path provided")
	}

	imageInfos := []ImageInfo{}

	content, err := os.ReadFile(imageManifestPath)
	if err != nil {
		return nil, fmt.Errorf("Error reading file %s: %w", imageManifestPath, err)
	}

	var paths []string
	err = json.Unmarshal(content, &paths)
	if err != nil {
		return nil, fmt.Errorf("Error unmarshalling file %s: %w", imageManifestPath, err)
	}

	for _, path := range paths {
		imageManifest, err := loadImageManifest(path)
		if err != nil {
			return nil, fmt.Errorf("Error loading image manifest %s: %w", path, err)
		}

		imageInfo, err := imageManifestToImageInfo(imageManifest)
		if err != nil {
			return nil, fmt.Errorf("Error converting image manifest %s: %w", path, err)
		}

		imageInfos = append(imageInfos, imageInfo)
	}

	return imageInfos, nil
}

func loadImageManifest(imageManifestPath string) (ImageManifest, error) {
	var manifest ImageManifest
	content, err := os.ReadFile(imageManifestPath)
	if err != nil {
		return manifest, fmt.Errorf("Error reading file %s: %w", imageManifestPath, err)
	}
	err = json.Unmarshal(content, &manifest)
	if err != nil {
		return manifest, fmt.Errorf("Error unmarshalling file %s: %w", imageManifestPath, err)
	}

	return manifest, nil
}

func imageManifestToImageInfo(imageManifest ImageManifest) (ImageInfo, error) {
	var imageInfo ImageInfo
	imageInfo.Label = imageManifest.Label

	repository, err := os.ReadFile(imageManifest.RepositoryPath)
	if err != nil {
		return imageInfo, fmt.Errorf("Error reading file %s: %w", imageManifest.RepositoryPath, err)
	}
	imageInfo.Repository = string(repository)

	imageIndexPath := filepath.Join(imageManifest.ImageRootPath, "index.json")
	imageIndexContent, err := os.ReadFile(imageIndexPath)
	if err != nil {
		return imageInfo, fmt.Errorf("Error reading file %s: %w", imageIndexPath, err)
	}

	var imageIndex ImageIndex
	err = json.Unmarshal(imageIndexContent, &imageIndex)
	if err != nil {
		return imageInfo, fmt.Errorf("Error unmarshalling file %s: %w", imageIndexPath, err)
	}

	imageInfo.Digest = imageIndex.Manifests[0].Digest
	return imageInfo, nil
}

type ReplacementGroup struct {
	Name         string
	Replacements map[string]string
}

func loadImageStamps(imageManifestPath string) ([]ReplacementGroup, error) {
	imageInfos, err := loadImageInfos(imageManifestPath)
	if err != nil {
		return nil, fmt.Errorf("Error loading image infos: %w", err)
	}

	replacementGroups := []ReplacementGroup{}

	for _, imageInfo := range imageInfos {
		workspaceLabel := strings.Replace(imageInfo.Label, "@@", "@", 1)
		bzmodLabel := fmt.Sprintf("@%s", imageInfo.Label)
		imageUrl := fmt.Sprintf("%s@%s", imageInfo.Repository, imageInfo.Digest)

		replacementGroups = append(replacementGroups, ReplacementGroup{
			Name: imageInfo.Label,
			Replacements: map[string]string{
				workspaceLabel: imageUrl,
				bzmodLabel:     imageUrl,
			},
		})
	}

	return replacementGroups, nil
}

func replaceKeyValues(content string, replacementGroups []ReplacementGroup, mustReplace bool) (string, error) {
	for _, replacementGroup := range replacementGroups {
		replaced := false

		for key, val := range replacementGroup.Replacements {
			replaceKey := fmt.Sprintf("{%s}", key)
			if strings.Contains(content, key) {
				replaced = true
			}
			content = strings.ReplaceAll(content, replaceKey, val)
		}

		if !replaced && mustReplace {
			return content, fmt.Errorf("Failed to find key %s in content", replacementGroup.Name)
		}
	}

	return content, nil
}

func applySubstitutions(content string, substitutions_file string) (string, error) {
	if len(substitutions_file) == 0 {
		return content, nil
	}

	contentBytes, err := os.ReadFile(substitutions_file)
	if err != nil {
		return content, fmt.Errorf("Error reading substitutions file %s: %w", substitutions_file, err)
	}

	var substitutions map[string]string
	err = json.Unmarshal(contentBytes, &substitutions)
	if err != nil {
		return content, fmt.Errorf("Error unmarshalling substitutions file %s: %w", substitutions_file, err)
	}

	for key, val := range substitutions {
		replaceKey := fmt.Sprintf("{%s}", key)
		content = strings.ReplaceAll(content, replaceKey, val)
	}

	return content, nil
}

func applyStamping(content string, stamps []ReplacementGroup, imageStamps []ReplacementGroup, requireImageStamps bool) (string, error) {
	content, err := replaceKeyValues(content, stamps, false)
	if err != nil {
		return content, fmt.Errorf("Error replacing stamps: %w", err)
	}

	content, err = replaceKeyValues(content, imageStamps, requireImageStamps)
	if err != nil {
		return content, fmt.Errorf("Error replacing image stamps: %w", err)
	}

	return content, nil
}

func sanitizeChartContent(content string) (string, error) {
	var chart HelmChart
	err := yaml.Unmarshal([]byte(content), &chart)
	if err != nil {
		return "", fmt.Errorf("Error unmarshalling chart content: %w", err)
	}

	re := regexp.MustCompile(`.*{.+}.*`)

	// TODO: This should probably happen for all values
	versionMatch := re.FindAllString(chart.Version, 1)
	if len(versionMatch) != 0 {
		var replacement = versionMatch[0]
		replacement = strings.ReplaceAll(replacement, "{", "")
		replacement = strings.ReplaceAll(replacement, "}", "")
		replacement = strings.ReplaceAll(replacement, "_", "-")

		content = strings.ReplaceAll(content, versionMatch[0], replacement)
	}

	return content, nil
}

func loadChart(content string) (HelmChart, error) {
	var chart HelmChart
	err := yaml.Unmarshal([]byte(content), &chart)
	if err != nil {
		return chart, fmt.Errorf("Error unmarshalling chart content: %w", err)
	}

	return chart, nil
}

func copyFile(source string, dest string) error {
	srcFile, err := os.Open(source)
	if err != nil {
		return fmt.Errorf("Error opening source file %s: %w", source, err)
	}
	defer srcFile.Close()

	parent := filepath.Dir(dest)
	err = os.MkdirAll(parent, 0700)
	if err != nil {
		return fmt.Errorf("Error creating parent directory %s: %w", parent, err)
	}

	destFile, err := os.Create(dest)
	if err != nil {
		return fmt.Errorf("Error creating destination file %s: %w", dest, err)
	}

	defer destFile.Close()

	_, err = io.Copy(destFile, srcFile)
	if err != nil {
		return fmt.Errorf("Error copying file %s to %s: %w", source, dest, err)
	}

	err = destFile.Sync()
	if err != nil {
		return fmt.Errorf("Error syncing file %s: %w", dest, err)
	}

	return nil
}

func installHelmContent(workingDir string, stampedChartContent string, stampedValuesContent string, templatesManifest string, depsManifest string) error {
	err := os.MkdirAll(workingDir, 0700)
	if err != nil {
		return fmt.Errorf("Error creating working directory %s: %w", workingDir, err)
	}

	chartYaml := filepath.Join(workingDir, "Chart.yaml")
	err = os.WriteFile(chartYaml, []byte(stampedChartContent), 0644)
	if err != nil {
		return fmt.Errorf("Error writing chart file %s: %w", chartYaml, err)
	}

	valuesYaml := filepath.Join(workingDir, "values.yaml")
	err = os.WriteFile(valuesYaml, []byte(stampedValuesContent), 0644)
	if err != nil {
		return fmt.Errorf("Error writing values file %s: %w", valuesYaml, err)
	}

	manifestContent, err := os.ReadFile(templatesManifest)
	if err != nil {
		return fmt.Errorf("Error reading templates manifest %s: %w", templatesManifest, err)
	}

	var templates TemplatesManfiest
	err = json.Unmarshal(manifestContent, &templates)
	if err != nil {
		return fmt.Errorf("Error unmarshalling templates manifest %s: %w", templatesManifest, err)
	}

	templatesDir := filepath.Join(workingDir, "templates")
	templatesRoot := ""

	// Copy all templates
	for templatePath, templateShortpath := range templates {

		// Locate the templates directory so we can start copying files
		// into the new templates directory at the right location
		if len(templatesRoot) == 0 {
			var current = filepath.Clean(templateShortpath)
			for {
				if len(current) == 0 {
					return errors.New("Failed to find templates directory")
				}
				parent := filepath.Dir(current)
				if filepath.Base(parent) == "templates" {
					templatesRoot = filepath.Clean(parent)
					break
				}
				current = parent
			}
		}

		if !strings.HasPrefix(filepath.Clean(templateShortpath), templatesRoot) {
			return fmt.Errorf(
				"Template path (%s) does not start with templates root (%s)",
				filepath.Clean(templateShortpath), templatesRoot)
		}

		targetFile, err := filepath.Rel(templatesRoot, templateShortpath)
		if err != nil {
			return err
		}

		templateDest := filepath.Join(templatesDir, targetFile)
		templateDestDir := filepath.Dir(templateDest)
		err = os.MkdirAll(templateDestDir, 0700)
		if err != nil {
			return fmt.Errorf("Error creating template parent directory %s: %w", templateDestDir, err)
		}

		err = copyFile(templatePath, templateDest)
		if err != nil {
			return fmt.Errorf("Error copying template %s: %w", templatePath, err)
		}
	}

	// Copy over any dependency chart files
	if len(depsManifest) > 0 {
		manifestContent, err := os.ReadFile(depsManifest)
		if err != nil {
			return fmt.Errorf("Error reading deps manifest %s: %w", depsManifest, err)
		}

		var deps DepsManfiest
		err = json.Unmarshal(manifestContent, &deps)
		if err != nil {
			return fmt.Errorf("Error unmarshalling deps manifest %s: %w", depsManifest, err)
		}

		for _, dep := range deps {
			err = copyFile(dep, filepath.Join(workingDir, "charts", filepath.Base(dep)))
			if err != nil {
				return fmt.Errorf("Error copying dep %s: %w", dep, err)
			}
		}
	}

	return nil
}

func findGeneratedPackage(logging string) (string, error) {
	if strings.Contains(logging, ":") {
		// This line assumes the logging from helm will be a single line of
		// text which starts with `Successfully packaged chart and saved it to:`
		split := strings.SplitN(logging, ":", 2)
		var pkg = strings.TrimSpace(split[1])
		if _, err := os.Stat(pkg); err != nil {
			return "", fmt.Errorf("Failed to parse package installed at '%s' with %w", pkg, err)
		}
		return pkg, nil
	}

	return "", errors.New("failed to find package")
}

func writeResultsMetadata(packageBase string, metadataOutput string) error {
	// Official recommended regex from https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
	re := regexp.MustCompile(`(.*)-^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$\.tgz`)
	match := re.FindAllStringSubmatch(packageBase, 2)

	if len(match) == 0 {
		return errors.New("Failed to parse package name")
	}

	var resultMetadata = HelmResultMetadata{
		Name:    match[0][1],
		Version: match[0][2],
	}
	// TODO: This is only used to get lowercase keys in the seralized json.
	// There's surely a better way to do this.
	var serializable = make(map[string]string)
	serializable["name"] = resultMetadata.Name
	serializable["version"] = resultMetadata.Version

	text, err := json.MarshalIndent(serializable, "", "    ")
	if err != nil {
		return fmt.Errorf("Error marshalling metadata: %w", err)
	}

	err = os.WriteFile(metadataOutput, text, 0644)
	if err != nil {
		return fmt.Errorf("Error writing metadata file: %w", err)
	}

	return nil
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
	var args = parseArgs()

	log.SetFlags(log.LstdFlags | log.Lshortfile)

	cwd, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}

	// Generate a directory name but keep it short for windows
	dir_name := fmt.Sprintf(".rules_helm_pkg_%s", hashString(args.Output)[:12])
	dir := filepath.Join(cwd, dir_name)

	// Ensure the directory is clean
	if err := os.RemoveAll(dir); err != nil {
		log.Fatal(err)
	}
	if err := os.MkdirAll(dir, 0700); err != nil {
		log.Fatal(err)
	}

	// Generate a fake kubeconfig for more consistent results when building packages
	kubeconfig := filepath.Join(dir, ".kubeconfig")
	file, err := os.Create(kubeconfig)
	if err != nil {
		log.Fatal(err)
	}
	if err := file.Chmod(0700); err != nil {
		log.Fatal(err)
	}
	file.Close()

	chartContent, err := os.ReadFile(args.Chart)
	if err != nil {
		log.Fatal(err)
	}

	valuesBytes, err := os.ReadFile(args.Values)
	if err != nil {
		log.Fatal(err)
	}
	valuesContent := string(valuesBytes)

	// Collect all stamp values
	stamps, err := loadStamps(args.VolatileStatusFile, args.StableStatusFile)
	if err != nil {
		log.Fatal(err)
	}

	imageStamps, err := loadImageStamps(args.ImageManifest)
	if err != nil {
		log.Fatal(err)
	}

	// Apply substitutions.
	valuesContent, err = applySubstitutions(valuesContent, args.Substitutions)
	if err != nil {
		log.Fatal(err)
	}

	// Stamp any templates out of top level helm sources
	stampedValuesContent, err := applyStamping(string(valuesContent), stamps, imageStamps, true)
	if err != nil {
		log.Fatal(err)
	}
	stampedChartContent, err := applyStamping(string(chartContent), stamps, imageStamps, false)
	if err != nil {
		log.Fatal(err)
	}
	stampedChartContent, err = sanitizeChartContent(stampedChartContent)
	if err != nil {
		log.Fatal(err)
	}

	chart, err := loadChart(stampedChartContent)
	if err != nil {
		log.Fatal(err)
	}

	// Create a directory in which to run helm package
	tmpPath := filepath.Join(dir, chart.Name)
	err = installHelmContent(tmpPath, stampedChartContent, stampedValuesContent, args.TemplatesManifest, args.DepsManifest)
	if err != nil {
		log.Fatal(err)
	}

	// Build the helm package
	command := exec.Command(filepath.Join(cwd, args.Helm), "package", ".")
	command.Dir = tmpPath
	command.Env = append(os.Environ(), fmt.Sprintf("KUBECONFIG=%s", kubeconfig))
	out, err := command.CombinedOutput()
	if err != nil {
		os.Stderr.WriteString(string(out))
		log.Fatal(err)
	}

	// Locate the package file
	pkg, err := findGeneratedPackage(string(out))
	if err != nil {
		os.Stderr.WriteString(string(out))
		log.Fatal(err)
	}

	// Write output metadata file to satisfy the Bazel output
	err = copyFile(pkg, args.Output)
	if err != nil {
		log.Fatal(err)
	}

	// Write output metadata to retain information about the helm package
	err = writeResultsMetadata(filepath.Base(pkg), args.MetadataOutput)
	if err != nil {
		log.Fatal(err)
	}
}
