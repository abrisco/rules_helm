"""Helm dependencies"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//helm/private:versions.bzl", "DEFAULT_HELM_URL_TEMPLATES", "DEFAULT_HELM_VERSION", "HELM_VERSIONS")

_HELM_TAR_BUILD_CONTENT = """\
package(default_visibility = ["//visibility:public"])
exports_files(glob(["**"]))
"""

def _helm_bin_repo_name(platform):
    return "helm_{}".format(platform.replace("-", "_"))

# buildifier: disable=unnamed-macro
def rules_helm_dependencies():
    """Defines helm dependencies"""

    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "66ffd9315665bfaafc96b52278f57c7e2dd09f5ede279ea6d39b2be471e7e3aa",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-1.4.2.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-1.4.2.tar.gz",
        ],
    )

    maybe(
        http_archive,
        name = "rules_python",
        sha256 = "863ba0fa944319f7e3d695711427d9ad80ba92c6edd0b7c7443b84e904689539",
        strip_prefix = "rules_python-0.22.0",
        url = "https://github.com/bazelbuild/rules_python/releases/download/0.22.0/rules_python-0.22.0.tar.gz",
    )

    maybe(
        http_archive,
        name = "io_bazel_rules_go",
        sha256 = "6dc2da7ab4cf5d7bfc7c949776b1b7c733f05e56edc4bcd9022bb249d2e2a996",
        urls = [
            "https://github.com/bazelbuild/rules_go/releases/download/v0.39.1/rules_go-v0.39.1.zip",
        ],
    )

    maybe(
        http_archive,
        name = "bazel_gazelle",
        sha256 = "29d5dafc2a5582995488c6735115d1d366fcd6a0fc2e2a153f02988706349825",
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.31.0/bazel-gazelle-v0.31.0.tar.gz"],
    )

    maybe(
        http_archive,
        name = "go_yaml_yaml",
        urls = ["https://github.com/go-yaml/yaml/archive/refs/tags/v3.0.1.tar.gz"],
        strip_prefix = "yaml-3.0.1",
        sha256 = "cf05411540d3e6ef8f1fd88434b34f94cedaceb540329031d80e23b74540c4e5",
        build_file = Label("//3rdparty/yaml:BUILD.yaml.bazel"),
    )

_HELM_TOOLCHAIN_BUILD_CONTENT = """\
load("@rules_helm//helm:toolchain.bzl", "helm_toolchain")

package(default_visibility = ["//visibility:public"])

helm_toolchain(
    name = "toolchain_impl",
    helm = "@helm_{platform}//:{bin}",
)

toolchain(
    name = "toolchain",
    toolchain = ":toolchain_impl",
    toolchain_type = "@rules_helm//helm:toolchain_type",
    exec_compatible_with = {exec_compatible_with},
    target_compatible_with = {target_compatible_with},
)
"""

_HELM_WORKSPACE_CONTENT = """\
workspace(name = "{}")
"""

def _helm_toolchain_repository_impl(repository_ctx):
    platform = repository_ctx.attr.platform

    if platform.startswith("windows"):
        bin = "helm.exe"
    else:
        bin = "helm"

    repository_ctx.file("BUILD.bazel", _HELM_TOOLCHAIN_BUILD_CONTENT.format(
        platform = platform.replace("-", "_"),
        bin = bin,
        exec_compatible_with = json.encode(repository_ctx.attr.exec_compatible_with),
        target_compatible_with = json.encode(repository_ctx.attr.target_compatible_with),
    ))

    repository_ctx.file("WORKSPACE.bazel", _HELM_WORKSPACE_CONTENT.format(
        repository_ctx.name,
    ))

helm_toolchain_repository = repository_rule(
    implementation = _helm_toolchain_repository_impl,
    doc = "A repository rule for generating a Helm toolchain definition.",
    attrs = {
        "exec_compatible_with": attr.string_list(
            doc = "A list of constraints for the execution platform for this toolchain.",
            default = [],
        ),
        "platform": attr.string(
            doc = "Platform the Helm executable was built for.",
            mandatory = True,
        ),
        "target_compatible_with": attr.string_list(
            doc = "A list of constraints for the target platform for this toolchain.",
            default = [],
        ),
    },
)

# buildifier: disable=unnamed-macro
def helm_register_toolchains(version = DEFAULT_HELM_VERSION, helm_url_templates = DEFAULT_HELM_URL_TEMPLATES):
    """Register helm toolchains.

    Args:
        version (str, optional): The version of Helm to use
        helm_url_templates (list, optional): A list of url templates where helm can be downloaded.
    """
    if not version in HELM_VERSIONS:
        fail("{} is not a supported version ({})".format(version, HELM_VERSIONS.keys()))

    helm_version_info = HELM_VERSIONS[version]

    for platform, info in helm_version_info.items():
        if platform.startswith("windows"):
            compression = "zip"
        else:
            compression = "tar.gz"

        name = _helm_bin_repo_name(platform)
        maybe(
            http_archive,
            name = name,
            urls = [
                template.format(
                    version = version,
                    platform = platform,
                    compression = compression,
                )
                for template in helm_url_templates
            ],
            build_file_content = _HELM_TAR_BUILD_CONTENT,
            sha256 = info.sha256,
            strip_prefix = platform,
        )
        maybe(
            helm_toolchain_repository,
            name = name + "_toolchain",
            platform = platform,
            exec_compatible_with = helm_version_info[platform].constraints,
        )

        # The toolchain name is determined by `helm_toolchains`
        toolchain_name = "@{}_toolchain//:toolchain".format(name)
        native.register_toolchains(toolchain_name)
