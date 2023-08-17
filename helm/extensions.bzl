load("//helm:repositories.bzl", "helm_toolchain_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//helm/private:versions.bzl", "DEFAULT_HELM_URL_TEMPLATES", "DEFAULT_HELM_VERSION", "HELM_VERSIONS")

_HELM_TAR_BUILD_CONTENT = """\
package(default_visibility = ["//visibility:public"])
exports_files(glob(["**"]))
"""

def _helm_register_toolchains(ctx):
    """Register helm toolchains.

       Args:
           version (str, optional): The version of Helm to use
           helm_url_templates (list, optional): A list of url templates where helm can be downloaded.
       """
    module = ctx.modules[0]
    options = module.tags.options
    version = options[0].version
    helm_url_templates = options[0].helm_url_templates

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

options = tag_class(attrs={
    "version": attr.string(default = DEFAULT_HELM_VERSION),
    "helm_url_templates": attr.string_list(default = DEFAULT_HELM_URL_TEMPLATES),
})

helm = module_extension(
    implementation = _helm_register_toolchains,
    tag_classes = {"options": options},
)