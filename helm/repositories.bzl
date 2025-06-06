"""Helm dependencies"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//helm/private:versions.bzl", "CONSTRAINTS", "DEFAULT_HELM_URL_TEMPLATES", "DEFAULT_HELM_VERSION", "HELM_VERSIONS")

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
        sha256 = "bc283cdfcd526a52c3201279cda4bc298652efa898b10b4db0837dc51652756f",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz",
        ],
    )

    maybe(
        http_archive,
        name = "io_bazel_rules_go",
        sha256 = "f4a9314518ca6acfa16cc4ab43b0b8ce1e4ea64b81c38d8a3772883f153346b8",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.50.1/rules_go-v0.50.1.zip",
            "https://github.com/bazelbuild/rules_go/releases/download/v0.50.1/rules_go-v0.50.1.zip",
        ],
    )

    maybe(
        http_archive,
        name = "bazel_gazelle",
        integrity = "sha256-t2D3/nUXOIYAf3wuYWohJBII89kOhlfcZdNqdx6Ra2o=",
        urls = ["https://github.com/bazel-contrib/bazel-gazelle/releases/download/v0.39.1/bazel-gazelle-v0.39.1.tar.gz"],
    )

_HELM_TOOLCHAIN_BUILD_CONTENT = """\
load("@rules_helm//helm:toolchain.bzl", "helm_toolchain")

package(default_visibility = ["//visibility:public"])

helm_toolchain(
    name = "toolchain_impl",
    helm = "@helm_{platform}//:{bin}",
    plugins = {plugins},
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
        plugins = json.encode(repository_ctx.attr.plugins),
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
        "plugins": attr.string_list(
            doc = "A list of plugins to add to the generated toolchain.",
            default = [],
        ),
        "target_compatible_with": attr.string_list(
            doc = "A list of constraints for the target platform for this toolchain.",
            default = [],
        ),
    },
)

def _platform(rctx):
    """Returns a normalized name of the host os and CPU architecture.

    Alias archictures names are normalized:

    x86_64 => amd64
    aarch64 => arm64

    The result can be used to generate repository names for host toolchain
    repositories for toolchains that use these normalized names.

    Common os & architecture pairs that are returned are,

    - darwin_amd64
    - darwin_arm64
    - linux_amd64
    - linux_arm64
    - linux_s390x
    - linux_ppc64le
    - windows_amd64

    Args:
        rctx: rctx

    Returns:
        The normalized "<os>_<arch>" string of the host os and CPU architecture.
    """
    if rctx.os.name.lower().startswith("linux"):
        os = "linux"
    elif rctx.os.name.lower().startswith("mac os"):
        os = "darwin"
    elif rctx.os.name.lower().startswith("freebsd"):
        os = "freebsd"
    elif rctx.os.name.lower().find("windows") != -1:
        os = "windows"
    else:
        fail("unrecognized os")

    # Normalize architecture names
    arch = rctx.os.arch
    if arch == "aarch64":
        arch = "arm64"
    elif arch == "x86_64":
        arch = "amd64"

    return "%s_%s" % (os, arch)

def _helm_host_alias_repository_impl(repository_ctx):
    is_windows = repository_ctx.os.name.lower().find("windows") != -1
    ext = ".exe" if is_windows else ""

    repository_ctx.file("BUILD.bazel", """# @generated by @rules_helm//helm/repositories.bzl
package(default_visibility = ["//visibility:public"])
exports_files(["helm{ext}"])
""".format(
        ext = ext,
    ))

    repository_ctx.symlink("../{name}_{platform}/helm{ext}".format(
        name = repository_ctx.attr.name,
        platform = _platform(repository_ctx),
        ext = ext,
    ), "helm{ext}".format(ext = ext))

helm_host_alias_repository = repository_rule(
    implementation = _helm_host_alias_repository_impl,
    doc = """Creates a repository with a shorter name meant for the host platform, which contains
    a BUILD.bazel file that exports symlinks to the host platform's binaries
    """,
)

# buildifier: disable=unnamed-macro
def helm_register_toolchains(version = DEFAULT_HELM_VERSION, helm_url_templates = DEFAULT_HELM_URL_TEMPLATES, plugins = []):
    """Register helm toolchains.

    Args:
        version (str, optional): The version of Helm to use
        helm_url_templates (list, optional): A list of url templates where helm can be downloaded.
        plugins (list, optional): Labels to `helm_plugin` targets to add to generated toolchains.
    """
    if not version in HELM_VERSIONS:
        fail("{} is not a supported version ({})".format(version, HELM_VERSIONS.keys()))

    helm_version_info = HELM_VERSIONS[version]

    for platform, integrity in helm_version_info.items():
        if platform.startswith("windows"):
            compression = "zip"
        else:
            compression = "tar.gz"

        # The URLs for linux-i386 artifacts are actually published under
        # a different name. The check below accounts for this.
        # https://github.com/abrisco/rules_helm/issues/76
        url_platform = platform
        if url_platform == "linux-i386":
            url_platform = "linux-386"

        name = _helm_bin_repo_name(platform)
        maybe(
            http_archive,
            name = name,
            urls = [
                template.format(
                    version = version,
                    platform = url_platform,
                    compression = compression,
                )
                for template in helm_url_templates
            ],
            build_file_content = _HELM_TAR_BUILD_CONTENT,
            integrity = integrity,
            strip_prefix = url_platform,
        )
        maybe(
            helm_toolchain_repository,
            name = name + "_toolchain",
            platform = platform,
            plugins = plugins,
            exec_compatible_with = CONSTRAINTS[platform],
        )

        # The toolchain name is determined by `helm_toolchains`
        toolchain_name = "@{}_toolchain//:toolchain".format(name)
        native.register_toolchains(toolchain_name)

    maybe(
        helm_host_alias_repository,
        name = "helm",
    )
