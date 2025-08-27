"""Repository rule for importing a chart using `helm_pull`."""

load("//helm/private:versions.bzl", "DEFAULT_HELM_URL_TEMPLATES", "DEFAULT_HELM_VERSION", "HELM_VERSIONS")

_HELM_DEP_BUILD_FILE = """\
load("@rules_helm//helm:defs.bzl", "helm_import")

helm_import(
    name = "{chart_name}",
    chart = "{chart_file}",
    visibility = ["//visibility:public"],
)

alias(
    name = "{repository_name}",
    actual = ":{chart_name}",
    visibility = ["//visibility:public"],
)
"""

def _platform(repository_ctx):
    """Returns a normalized name of the host os and CPU architecture.

    Alias archictures names are normalized:

    x86_64 => amd64
    aarch64 => arm64

    Common os & architecture pairs that are returned are,

    - darwin-amd64
    - darwin-arm64
    - linux-amd64
    - linux-arm64
    - linux-s390x
    - linux-ppc64le
    - windows-amd64

    Args:
        repository_ctx: repository_ctx

    Returns:
        The normalized "<os>-<arch>" string of the host os and CPU architecture.
    """
    if repository_ctx.os.name.lower().startswith("linux"):
        os = "linux"
    elif repository_ctx.os.name.lower().startswith("mac os"):
        os = "darwin"
    elif repository_ctx.os.name.lower().startswith("freebsd"):
        os = "freebsd"
    elif repository_ctx.os.name.lower().find("windows") != -1:
        os = "windows"
    else:
        fail("unrecognized os")

    # Normalize architecture names
    arch = repository_ctx.os.arch
    if arch == "aarch64":
        arch = "arm64"
    elif arch == "x86_64":
        arch = "amd64"

    return "%s-%s" % (os, arch)

def _helm_pull_repo_metadata(repository_ctx):
    url = repository_ctx.attr.url
    chart_name = repository_ctx.attr.chart_name
    repo = repository_ctx.attr.repo
    version = repository_ctx.attr.version

    reproducible = True
    attrs_for_reproducibility = None

    # HTTP URLs are always reproducible since they point directly to a chart package.
    # OCI URLs may omit a tag or version and default to latest:
    if url and url.startswith("oci://"):
        url = url.removeprefix("oci://")
        if "@" not in url and ":" not in url:
            reproducible = False
            attrs_for_reproducibility = {
                "chart_name": chart_name,
                "name": repository_ctx.name,
                "url": "Specify tag or digest",
            }

        # If a repo is specified, a version should be specified:
    elif repo and (not version or version == "latest"):
        reproducible = False
        attrs_for_reproducibility = {
            "chart_name": chart_name,
            "name": repository_ctx.name,
            "repo": repo,
            "version": "Specific version",
        }

    # Cannot set `attrs_for_reproducibility = None`:
    if reproducible:
        return repository_ctx.repo_metadata(
            reproducible = True,
        )
    else:
        return repository_ctx.repo_metadata(
            reproducible = False,
            attrs_for_reproducibility = attrs_for_reproducibility,
        )

def _helm_pull_impl(repository_ctx):
    url = repository_ctx.attr.url
    chart_name = repository_ctx.attr.chart_name
    repo = repository_ctx.attr.repo
    version = repository_ctx.attr.version

    if url and (repo or version):
        fail("`url` is specified, do not specify `repo` and `version`")

    if not url:
        if not repo:
            fail("`repo` must be specified")

    helm_version = repository_ctx.attr.helm_version
    platform = _platform(repository_ctx)
    if platform.startswith("windows"):
        compression = "zip"
    else:
        compression = "tar.gz"

    repository_ctx.download_and_extract(
        url = [
            template.format(
                version = helm_version,
                platform = platform,
                compression = compression,
            )
            for template in repository_ctx.attr.helm_url_templates
        ],
        output = "helm",
        integrity = HELM_VERSIONS[helm_version][platform],
    )

    helm_bin = "helm/{}/helm".format(platform)

    # https://helm.sh/docs/helm/helm_pull/
    pull_cmd = [repository_ctx.path(helm_bin), "pull"]
    if repository_ctx.attr.url:
        pull_cmd.append(repository_ctx.attr.url)
    else:
        pull_cmd.extend([chart_name, "--repo", repo])
        if version:
            pull_cmd.extend(["--version", version])

    repository_ctx.execute(pull_cmd)

    chart_file = "{}.tgz".format(chart_name)

    # Find the chart archive and rename it:
    for path in repository_ctx.path(".").readdir():
        if path.basename.endswith(".tgz"):
            repository_ctx.rename(path.basename, chart_file)

    repository_ctx.file("BUILD.bazel", content = _HELM_DEP_BUILD_FILE.format(
        chart_name = chart_name,
        chart_file = chart_file,
        repository_name = repository_ctx.name,
    ))

    return _helm_pull_repo_metadata(repository_ctx)

helm_pull = repository_rule(
    doc = "Download a chart using `helm pull`",
    implementation = _helm_pull_impl,
    attrs = {
        "chart_name": attr.string(
            doc = "Name of the chart.",
            mandatory = True,
        ),
        "helm_url_templates": attr.string_list(default = DEFAULT_HELM_URL_TEMPLATES),
        "helm_version": attr.string(default = DEFAULT_HELM_VERSION),
        "repo": attr.string(
            doc = "URL of a Helm chart repository. Do not set if `url` is set.",
        ),
        "url": attr.string(
            doc = "HTTP or OCI URL to directly download a chart.",
        ),
        "version": attr.string(
            doc = "Chart version to pull. Use a specific version to make this rule reproducible.",
        ),
    },
)
