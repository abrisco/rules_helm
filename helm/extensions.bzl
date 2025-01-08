"""Bzlmod extensions"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load(
    "//helm:repositories.bzl",
    "helm_host_alias_repository",
    "helm_toolchain_repository",
)
load(
    "//helm/private:versions.bzl",
    "CONSTRAINTS",
    "DEFAULT_HELM_URL_TEMPLATES",
    "DEFAULT_HELM_VERSION",
    "HELM_VERSIONS",
)

_HELM_TAR_BUILD_CONTENT = """\
package(default_visibility = ["//visibility:public"])
exports_files(glob(["**"]))
"""

def _helm_impl(ctx):
    toolchain_config = {
        "helm_url_templates": DEFAULT_HELM_URL_TEMPLATES,
        "plugins": [],
        "version": DEFAULT_HELM_VERSION,
    }
    for module in ctx.modules:
        if not module.is_root:
            # TODO support toolchain generation from non-root modules. This requires encoding all options into the repo name and adding deduplication.
            print("Ignoring call to helm module extension in non-root module.")  # buildifier: disable=print
            continue
        if len(module.tags.options) > 0:
            # TODO Use deprecation tag when available: https://github.com/bazelbuild/bazel/issues/24843
            # TODO remove deprecated tag in next major release
            print("helm.options() is deprecated. Use helm.toolchain() instead.")  # buildifier: disable=print
        toolchain_options = module.tags.toolchain + module.tags.options
        if len(toolchain_options) > 1:
            # TODO support generating multiple toolchains. This requires encoding all options into the repo name and adding deduplication.
            fail("Only a single call to helm.toolchain() is taken into account. Please remove the other ones.")
        for toolchain_option in toolchain_options:
            toolchain_config["version"] = toolchain_option.version
            toolchain_config["helm_url_templates"] = toolchain_option.helm_url_templates
            toolchain_config["plugins"] = toolchain_option.plugins

    _register_toolchains(**toolchain_config)
    _register_go_yaml()

def _register_toolchains(version, helm_url_templates, plugins):
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

        name = "helm_{}".format(platform.replace("-", "_"))
        maybe(
            http_archive,
            name = name,
            urls = [
                template.replace(
                    "{version}",
                    version,
                ).replace(
                    "{platform}",
                    url_platform,
                ).replace(
                    "{compression}",
                    compression,
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

_toolchain = tag_class(
    doc = "Configure a helm toolchain.",
    attrs = {
        "helm_url_templates": attr.string_list(
            doc = (
                "A url template used to download helm. The template can contain the following " +
                "format strings `{platform}` for the helm platform, `{version}` for the helm " +
                "version, and `{compression}` for the archive type containing the helm binary."
            ),
            default = DEFAULT_HELM_URL_TEMPLATES,
        ),
        "plugins": attr.string_list(
            doc = "A list of plugins to add to the generated toolchain.",
            default = [],
        ),
        "version": attr.string(
            doc = "The version of helm to download for the toolchain.",
            default = DEFAULT_HELM_VERSION,
        ),
    },
)

helm = module_extension(
    implementation = _helm_impl,
    tag_classes = {
        "options": _toolchain,  # deprecated: use toolchain instead and remove in next major version
        "toolchain": _toolchain,
    },
)
