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
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.1.1/bazel-skylib-1.1.1.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.1.1/bazel-skylib-1.1.1.tar.gz",
        ],
        sha256 = "c6966ec828da198c5d9adbaa94c05e3a1c7f21bd012a0b29ba8ddbccb2c93b0d",
    )

    maybe(
        http_archive,
        name = "rules_python",
        sha256 = "15f84594af9da06750ceb878abbf129241421e3abbd6e36893041188db67f2fb",
        strip_prefix = "rules_python-0.7.0",
        url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/0.7.0.tar.gz",
    )

    maybe(
        http_archive,
        name = "io_bazel_rules_docker",
        sha256 = "85ffff62a4c22a74dbd98d05da6cf40f497344b3dbf1e1ab0a37ab2a1a6ca014",
        strip_prefix = "rules_docker-0.23.0",
        urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.23.0/rules_docker-v0.23.0.tar.gz"],
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
    doc = "",
    attrs = {
        "exec_compatible_with": attr.string_list(
            doc = "",
            default = [],
        ),
        "platform": attr.string(
            doc = "",
            mandatory = True,
        ),
        "target_compatible_with": attr.string_list(
            doc = "",
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
