package main

import (
	"errors"
	"os"
	"reflect"
	"strings"
	"testing"

	"github.com/bazelbuild/rules_go/go/runfiles"
)

func parseModuleBazel() (string, error) {
	path, err := runfiles.Rlocation("rules_helm/MODULE.bazel")
	if err != nil {
		return "", err
	}

	content, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}

	var moduleFound bool = false
	for _, line := range strings.Split(string(content), "\n") {
		text := strings.TrimRight(line, "\r")
		if moduleFound {
			if strings.HasSuffix(text, ")") {
				return "", errors.New("Failed to parse version from module section")
			}
			split := strings.SplitN(text, " = ", 2)
			if len(split) < 2 {
				continue
			}
			param, val := split[0], split[1]
			if strings.Trim(param, " ") == "version" {
				return strings.Trim(val, "\" ,"), nil
			}

		} else if strings.HasPrefix(text, "module(") {
			moduleFound = true
			continue
		}
	}
	return "", errors.New("Failed to parse version from MODULE.bazel")
}

func TestVersionFiles(t *testing.T) {
	version, found := os.LookupEnv("VERSION")
	if !found {
		t.Fatal("Couldn't parse VERSION from environment.")
	}

	module_bazel, err := parseModuleBazel()
	if err != nil {
		t.Fatalf("Error reading file MODULE.bazel: %v", err)
	}

	if !reflect.DeepEqual(version, module_bazel) {
		t.Fatalf("version.bzl (%s) != MODULE.bazel (%s)", version, module_bazel)
	}
}
