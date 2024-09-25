workspace(name = "rules_helm")

load("@rules_helm//helm:repositories.bzl", "helm_register_toolchains", "rules_helm_dependencies")

rules_helm_dependencies()

helm_register_toolchains()

load("@rules_helm//helm:repositories_transitive.bzl", "rules_helm_transitive_dependencies")

rules_helm_transitive_dependencies()

# =============================================================================
#  Internal dependencies only
# =============================================================================

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_oci",
    sha256 = "d007e6c96eb62c88397b68f329e4ca56e0cfe31204a2c54b0cb17819f89f83c8",
    strip_prefix = "rules_oci-2.0.0",
    url = "https://github.com/bazel-contrib/rules_oci/releases/download/v2.0.0/rules_oci-v2.0.0.tar.gz",
)

load("@rules_oci//oci:dependencies.bzl", "rules_oci_dependencies")

rules_oci_dependencies()

load("@rules_oci//oci:repositories.bzl", "oci_register_toolchains")

oci_register_toolchains(name = "oci")

load("//tests:test_deps.bzl", "helm_test_deps")

helm_test_deps()

http_archive(
    name = "io_bazel_stardoc",
    sha256 = "62bd2e60216b7a6fec3ac79341aa201e0956477e7c8f6ccc286f279ad1d96432",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/stardoc/releases/download/0.6.2/stardoc-0.6.2.tar.gz",
        "https://github.com/bazelbuild/stardoc/releases/download/0.6.2/stardoc-0.6.2.tar.gz",
    ],
)

load("@io_bazel_stardoc//:setup.bzl", "stardoc_repositories")

stardoc_repositories()

load("@rules_jvm_external//:repositories.bzl", "rules_jvm_external_deps")

rules_jvm_external_deps()

load("@rules_jvm_external//:setup.bzl", "rules_jvm_external_setup")

rules_jvm_external_setup()

load("@io_bazel_stardoc//:deps.bzl", "stardoc_external_deps")

stardoc_external_deps()

load("@stardoc_maven//:defs.bzl", stardoc_pinned_maven_install = "pinned_maven_install")

stardoc_pinned_maven_install()
