"""Helm transitive dependencies"""

load("@gazelle//:deps.bzl", "gazelle_dependencies")
load("@rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("//helm:go_repositories.bzl", "go_dependencies")

# buildifier: disable=unnamed-macro
def rules_helm_transitive_dependencies():
    """Defines helm transitive dependencies"""
    go_rules_dependencies()

    if "go_sdk" not in native.existing_rules():
        go_register_toolchains(go_version = "1.23.0")

    gazelle_dependencies()

    go_dependencies()
