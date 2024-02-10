"""Helm transitive dependencies"""

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

# buildifier: disable=unnamed-macro
def rules_helm_transitive_dependencies():
    """Defines helm transitive dependencies"""
    go_rules_dependencies()

    if "go_sdk" not in native.existing_rules():
        go_register_toolchains(go_version = "1.18.10")
