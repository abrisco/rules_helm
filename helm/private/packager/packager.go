package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"gopkg.in/yaml.v3"
	"io"
	"log"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"regexp"
	"strings"
)

type ImageManifest struct {
	Label      string
	Registry   string
	Repository string
	Digest     string
}
type ImagesManifest []ImageManifest

type TemplatesManfiest map[string]string
type DepsManfiest []string

type HelmResultMetadata struct {
	Name    string
	Version string
}

type HelmChart struct {
	ApiVersion  string
	Name        string
	Description string
	Type        string
	Version     string
	AppVersion  string
}

type Arguments struct {
	templates_manifest   string
	chart                string
	values               string
	deps_manifest        string
	helm                 string
	output               string
	metadata_output      string
	image_manifest       string
	stable_status_file   string
	volatile_status_file string
	workspace_name       string
	oci_image_manifest   string
}

func parse_args() Arguments {
	var args Arguments

	flag.StringVar(&args.templates_manifest, "templates_manifest", "", "A helm file containing a list of all helm template files")
	flag.StringVar(&args.chart, "chart", "", "The helm `chart.yaml` file")
	flag.StringVar(&args.values, "values", "", "The helm `values.yaml` file.")
	flag.StringVar(&args.deps_manifest, "deps_manifest", "", "A file containing a list of all helm dependency (`charts/*.tgz`) files")
	flag.StringVar(&args.helm, "helm", "", "The path to a helm executable")
	flag.StringVar(&args.output, "output", "", "The path to the Bazel `HelmPackage` action output")
	flag.StringVar(&args.metadata_output, "metadata_output", "", "The path to the Bazel `HelmPackage` action metadata output")
	flag.StringVar(&args.oci_image_manifest, "oci_image_manifest", "", "Information about Bazel produced container oci images used by the helm chart")
	flag.StringVar(&args.stable_status_file, "stable_status_file", "", "The stable status file (`ctx.info_file`)")
	flag.StringVar(&args.volatile_status_file, "volatile_status_file", "", "The stable status file (`ctx.version_file`)")
	flag.StringVar(&args.workspace_name, "workspace_name", "", "The name of the current Bazel workspace")
	flag.Parse()

	return args
}

func load_stamps(volatile_status_file string, stable_status_file string) map[string]string {
	stamps := make(map[string]string)

	stamp_files := []string{volatile_status_file, stable_status_file}
	for _, stamp_file := range stamp_files {

		// The files may not be defined
		if len(stamp_file) == 0 {
			continue
		}

		content, err := os.ReadFile(stamp_file)
		if err != nil {
			log.Fatal("error reading ", stamp_file, err)
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

	return stamps
}

type readManifest func([]byte) ImageManifest

func load_image_stamps(image_manifest string, workspace_name string, applyReadManifest readManifest) map[string]string {
	images := make(map[string]string)

	if len(image_manifest) == 0 {
		return images
	}

	content, err := os.ReadFile(image_manifest)
	if err != nil {
		log.Fatal("error reading ", image_manifest, err)
	}
	var paths []string
	_ = json.Unmarshal(content, &paths)
	for _, path := range paths {
		content, err := os.ReadFile(path)
		if err != nil {
			log.Fatalf("Error during ReadFile %s: %s", path, err)
		}
		manifest := applyReadManifest(content)
		var registryUrl = fmt.Sprintf("%s/%s@%s", manifest.Registry, manifest.Repository, manifest.Digest)
		images[manifest.Label] = registryUrl
		// Allow local labels to be resolved using workspace absolute labels.
		if strings.HasPrefix(manifest.Label, "@") {
			var absLabel = fmt.Sprintf("@%s%s", workspace_name, manifest.Label)
			images[absLabel] = registryUrl
		}
	}

	return images
}

func readOciImageManifest(content []byte) ImageManifest {
	imageManifest := ImageManifest{}
	type LocalManifest = struct {
		Label string
		Paths []string
	}
	localManifest := LocalManifest{}
	manifestDir := ""
	yqPath := ""
	_ = json.Unmarshal(content, &localManifest)
	imageManifest.Label = strings.Clone(localManifest.Label)
	for _, path := range localManifest.Paths {
		file, _ := os.Open(strings.Clone(path))
		stat, _ := file.Stat()
		if strings.HasSuffix(stat.Name(), ".sh") {
			scanner := bufio.NewScanner(file)
			for scanner.Scan() {
				text := scanner.Text()
				if strings.HasPrefix(text, "readonly FIXED_ARGS") {
					image := strings.SplitN(strings.Replace(strings.Replace(strings.Split(strings.Clone(text), " ")[2], "\"", "", -1), ")", "", -1), "/", 2)
					imageManifest.Registry = image[0]
					imageManifest.Repository = image[1]
				}
			}
		}
		if stat.IsDir() {
			manifestDir = strings.Clone(path)
		}
		if strings.HasSuffix(stat.Name(), "yq") {
			yqPath = strings.Clone(path)
		}
		digest, _ := exec.Command(yqPath, ".manifests[0].digest", manifestDir+"/index.json").Output()
		imageManifest.Digest = strings.Replace(string(digest), "\n", "", -1)
		file.Close()
	}
	return imageManifest
}

func apply_stamping(content string, stamps map[string]string, oci_image_stamps map[string]string) string {
	for key, val := range stamps {
		content = strings.Replace(content, "{"+key+"}", val, -1)
	}

	for key, val := range oci_image_stamps {
		content = strings.Replace(content, "{"+key+"}", val, -1)
	}

	return content
}

func sanitize_chart_content(content string) string {
	var chart HelmChart
	err := yaml.Unmarshal([]byte(content), &chart)
	if err != nil {
		log.Fatal(err)
	}

	re := regexp.MustCompile(`.*{.+}.*`)

	// TODO: This should probably happen for all values
	version_match := re.FindAllString(chart.Version, 1)
	if len(version_match) != 0 {
		var replacement = version_match[0]
		replacement = strings.ReplaceAll(replacement, "{", "")
		replacement = strings.ReplaceAll(replacement, "}", "")
		replacement = strings.ReplaceAll(replacement, "_", "-")

		content = strings.ReplaceAll(content, version_match[0], replacement)
	}

	return content
}

func get_chart_name(content string) string {
	for _, line := range strings.Split(content, "\n") {
		if !strings.HasPrefix(line, "name:") {
			continue
		}

		_, name, found := strings.Cut(line, "name:")
		if !found {
			log.Fatal("The line should start with 'name:' at this point")
		}
		return strings.Trim(name, " '\"\n")
	}

	log.Fatal("Failed to find chart name from content:", content)
	return ""
}

func copy_file(source string, dest string) {
	src_file, err := os.Open(source)
	if err != nil {
		log.Fatal(err)
	}

	parent := path.Dir(dest)
	dir_err := os.MkdirAll(parent, 0755)
	if dir_err != nil {
		log.Fatal(dir_err)
	}

	dest_file, err := os.Create(dest)
	if err != nil {
		log.Fatal(err)
	}

	_, err = io.Copy(dest_file, src_file)
	if err != nil {
		log.Fatal(err)
	}

	err = dest_file.Sync()
	if err != nil {
		log.Fatal(err)
	}

	src_file.Close()
	dest_file.Close()
}

func install_helm_content(working_dir string, stamped_chart_content string, stamped_values_content string, templates_manifest string, deps_manifest string) {
	err := os.MkdirAll(working_dir, 0755)
	if err != nil {
		log.Fatal(err)
	}

	var chart_yaml = path.Join(working_dir, "Chart.yaml")
	chart_err := os.WriteFile(chart_yaml, []byte(stamped_chart_content), 0644)
	if chart_err != nil {
		log.Fatal(chart_err)
	}

	var values_yaml = path.Join(working_dir, "values.yaml")
	value_err := os.WriteFile(values_yaml, []byte(stamped_values_content), 0644)
	if value_err != nil {
		log.Fatal(value_err)
	}

	manifest_content, err := os.ReadFile(templates_manifest)
	if err != nil {
		log.Fatal(err)
	}

	var templates TemplatesManfiest
	err = json.Unmarshal(manifest_content, &templates)
	if err != nil {
		log.Fatal(err)
	}

	var templates_dir = path.Join(working_dir, "templates")
	var templates_root = ""

	// Copy all templates
	for template_path, template_shortpath := range templates {

		// Locate the templates directory so we can start copying files
		// into the new templates directory at the right location
		if len(templates_root) == 0 {
			var current = template_shortpath
			for {
				if len(current) == 0 {
					log.Fatal("Failed to find templates directory for ", template_shortpath)
				}
				parent := path.Dir(current)
				if path.Base(parent) == "templates" {
					templates_root = parent
					break
				}
				current = parent
			}
		}

		if !strings.HasPrefix(template_shortpath, templates_root) {
			log.Fatal("A template file has an unexpected prefix", template_shortpath, "does not start with", templates_root)
		}

		target_file, err := filepath.Rel(templates_root, template_shortpath)
		if err != nil {
			log.Fatal(err)
		}

		copy_file(template_path, path.Join(templates_dir, target_file))
	}

	// Copy over any dependency chart files
	if len(deps_manifest) > 0 {
		manifest_content, err := os.ReadFile(deps_manifest)
		if err != nil {
			log.Fatal(err)
		}

		var deps DepsManfiest
		err = json.Unmarshal(manifest_content, &deps)
		if err != nil {
			log.Fatal(err)
		}

		for _, dep := range deps {
			copy_file(dep, path.Join(working_dir, "charts", path.Base(dep)))
		}
	}
}

func find_generated_package(logging string) (string, error) {
	if strings.Contains(logging, ":") {
		// This line assumes the logging from helm will be a single line of
		// text which starts with `Successfully packaged chart and saved it to:`
		split := strings.SplitN(logging, ":", 2)
		var pkg = strings.TrimSpace(split[1])
		if _, err := os.Stat(pkg); err == nil {
			return pkg, nil
		}
	}

	return "", errors.New("failed to find package")
}

func write_results_metadata(package_base string, metadata_output string) {
	re := regexp.MustCompile(`(.*)-([\d][\d\w\-\.]+)\.tgz`)
	match := re.FindAllStringSubmatch(package_base, 2)

	if len(match) == 0 {
		log.Fatal("Unable to parse file name: ", package_base)
	}

	var result_metadata = HelmResultMetadata{
		Name:    match[0][1],
		Version: match[0][2],
	}
	// TODO: This is only used to get lowercase keys in the seralized json.
	// There's surely a better way to do this.
	var serializable = make(map[string]string)
	serializable["name"] = result_metadata.Name
	serializable["version"] = result_metadata.Version

	text, err := json.MarshalIndent(serializable, "", "    ")
	if err != nil {
		log.Fatal(err)
	}

	write_err := os.WriteFile(metadata_output, text, 0644)
	if write_err != nil {
		log.Fatal(write_err)
	}
}

func main() {
	var args = parse_args()

	log.SetFlags(log.LstdFlags | log.Lshortfile)

	cwd, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}

	dir := path.Join(cwd, ".rules_helm_pkg_dir")

	chart_content, err := os.ReadFile(args.chart)
	if err != nil {
		log.Fatal(err)
	}

	values_content, err := os.ReadFile(args.values)
	if err != nil {
		log.Fatal(err)
	}

	// Collect all stamp values
	var stamps = load_stamps(args.volatile_status_file, args.stable_status_file)
	var oci_image_stamps = load_image_stamps(args.oci_image_manifest, args.workspace_name, readOciImageManifest)

	// Stamp any templates out of top level helm sources
	var stamped_values_content = apply_stamping(string(values_content), stamps, oci_image_stamps)
	var stamped_chart_content = sanitize_chart_content(apply_stamping(string(chart_content), stamps, oci_image_stamps))

	// Create a directory in which to run helm package
	var chart_name = get_chart_name(stamped_chart_content)
	var tmp_path = path.Join(dir, chart_name)
	install_helm_content(tmp_path, stamped_chart_content, stamped_values_content, args.templates_manifest, args.deps_manifest)

	// Build the helm package
	command := exec.Command(path.Join(cwd, args.helm), "package", ".")
	command.Dir = tmp_path
	out, err := command.Output()
	if err != nil {
		os.Stderr.WriteString(string(out))
		log.Fatal(err)
	}

	// Locate the package file
	pkg, err := find_generated_package(string(out))
	if err != nil {
		os.Stderr.WriteString(string(out))
		log.Fatal(err)
	}

	// Write output metadata file to satisfy the Bazel output
	copy_file(pkg, args.output)

	// Write output metadata to retain information about the helm package
	write_results_metadata(path.Base(pkg), args.metadata_output)
}
