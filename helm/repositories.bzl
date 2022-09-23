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
        sha256 = "b593d13bb43c94ce94b483c2858e53a9b811f6f10e1e0eedc61073bd90e58d9c",
        strip_prefix = "rules_python-0.12.0",
        url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/0.12.0.tar.gz",
    )

    maybe(
        http_archive,
        name = "io_bazel_rules_go",
        sha256 = "099a9fb96a376ccbbb7d291ed4ecbdfd42f6bc822ab77ae6f1b5cb9e914e94fa",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.35.0/rules_go-v0.35.0.zip",
            "https://github.com/bazelbuild/rules_go/releases/download/v0.35.0/rules_go-v0.35.0.zip",
        ],
    )

    maybe(
        http_archive,
        name = "bazel_gazelle",
        sha256 = "efbbba6ac1a4fd342d5122cbdfdb82aeb2cf2862e35022c752eaddffada7c3f3",
        urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.27.0/bazel-gazelle-v0.27.0.tar.gz"],
    )

    maybe(
        http_archive,
        name = "go_yaml_yaml",
        urls = ["https://github.com/go-yaml/yaml/archive/refs/tags/v3.0.1.tar.gz"],
        strip_prefix = "yaml-3.0.1",
        sha256 = "cf05411540d3e6ef8f1fd88434b34f94cedaceb540329031d80e23b74540c4e5",
        build_file = Label("//3rdparty/yaml:BUILD.yaml.bazel"),
    )

    maybe(
        http_archive,
        name = "io_bazel_rules_docker",
        sha256 = "b1e80761a8a8243d03ebca8845e9cc1ba6c82ce7c5179ce2b295cd36f7e394bf",
        urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.25.0/rules_docker-v0.25.0.tar.gz"],
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
