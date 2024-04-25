"""Bzlmod extensions"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//helm:repositories.bzl", "helm_host_alias_repository", "helm_toolchain_repository")
load("//helm/private:versions.bzl", "DEFAULT_HELM_URL_TEMPLATES", "DEFAULT_HELM_VERSION", "HELM_VERSIONS")
load("//tests:test_deps.bzl", "helm_test_deps")

_HELM_TAR_BUILD_CONTENT = """\
package(default_visibility = ["//visibility:public"])
exports_files(glob(["**"]))
"""

def _impl(ctx):
    module = ctx.modules[0]
    options = module.tags.options
    version = options[0].version
    helm_url_templates = options[0].helm_url_templates

    _register_toolchains(version, helm_url_templates)
    _register_go_yaml()
    helm_test_deps()

def _register_toolchains(version, helm_url_templates):
    if not version in HELM_VERSIONS:
        fail("{} is not a supported version ({})".format(version, HELM_VERSIONS.keys()))

    helm_version_info = HELM_VERSIONS[version]

    for platform, info in helm_version_info.items():
        if platform.startswith("windows"):
            compression = "zip"
        else:
            compression = "tar.gz"

        name = "helm_{}".format(platform.replace("-", "_"))
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

    maybe(
        helm_host_alias_repository,
        name = "helm",
    )

def _register_go_yaml():
    maybe(
        http_archive,
        name = "go_yaml_yaml",
        urls = ["https://github.com/go-yaml/yaml/archive/refs/tags/v3.0.1.tar.gz"],
        strip_prefix = "yaml-3.0.1",
        sha256 = "cf05411540d3e6ef8f1fd88434b34f94cedaceb540329031d80e23b74540c4e5",
        build_file = Label("//3rdparty/yaml:BUILD.yaml.bazel"),
    )

options = tag_class(attrs = {
    "helm_url_templates": attr.string_list(default = DEFAULT_HELM_URL_TEMPLATES),
    "version": attr.string(default = DEFAULT_HELM_VERSION),
})

helm = module_extension(
    implementation = _impl,
    tag_classes = {"options": options},
)
