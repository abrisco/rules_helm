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

def _helm_pull_impl(repository_ctx):
    url = repository_ctx.attr.url
    chart_name = repository_ctx.attr.chart_name
    repo = repository_ctx.attr.repo
    version = repository_ctx.attr.version

    if not url and not repo:
        fail("`repo` or `url` must be specified")

    if url and repo:
        fail("`repo` and `url` are exclusive attributes")

    helm_version = repository_ctx.attr.helm_version

    if not helm_version in HELM_VERSIONS:
        fail("{} is not a supported version ({})".format(helm_version, HELM_VERSIONS.keys()))

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
    helm_bin = repository_ctx.path("helm/{}/helm".format(platform))

    username = repository_ctx.getenv("HELM_REGISTRY_USERNAME")

    password_file = repository_ctx.getenv("HELM_REGISTRY_PASSWORD_FILE")
    if password_file:
        password = repository_ctx.read(password_file)
    else:
        password = repository_ctx.getenv("HELM_REGISTRY_PASSWORD")

    # Conveinently, `helm pull` and `helm show` use the same arguments
    args = []
    if url:
        args.append(url)
    else:
        args.extend([chart_name, "--repo", repo])
    if version:
        args.extend(["--version", version])
    if username and password:
        args.extend(["--username", username, "--password", password])

    # https://helm.sh/docs/helm/helm_pull/
    pull_cmd = [helm_bin, "pull"] + args
    pull_result = repository_ctx.execute(pull_cmd)
    if pull_result.return_code:
        fail(pull_result.stderr)

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

    # Use `helm show chart` to determine which version was pulled and if the
    # rule is reproducible:
    # https://helm.sh/docs/helm/helm_show_chart/
    show_cmd = [helm_bin, "show", "chart"] + args
    show_result = repository_ctx.execute(show_cmd)

    # Unforunately, Bazel doesn't support YAML like it does JSON.
    show_version, show_digest = "", ""
    for line in show_result.stdout.splitlines():
        if line.startswith("version: "):
            show_version = line.removeprefix("version: ")

    # OCI Pull prints the digest on stderr:
    for line in show_result.stderr.splitlines():
        if line.startswith("Digest: "):
            show_digest = line.removeprefix("Digest: ")

    if repo and not version:
        return repository_ctx.repo_metadata(
            reproducible = False,
            attrs_for_reproducibility = {
                "chart_name": chart_name,
                "name": repository_ctx.name,
                "repo": repo,
                "version": show_version,
            },
        )

    # Only checking OCI URLs, HTTP URLs always resolve a specific chart
    if url and url.startswith("oci://") and not version:
        # OCI URLs are reproducible if they end with the version tag or digest:
        if not url.endswith(show_version) and not url.endswith(show_digest):
            return repository_ctx.repo_metadata(
                reproducible = False,
                attrs_for_reproducibility = {
                    "chart_name": chart_name,
                    "name": repository_ctx.name,
                    "url": url,
                    "version": show_version,
                },
            )

    return repository_ctx.repo_metadata(reproducible = True)

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
            doc = "URL of a Helm chart repository. Exclusive with `url`.",
        ),
        "url": attr.string(
            doc = "HTTP or OCI URL to directly download a chart. Exclusive with `repo`.",
        ),
        "version": attr.string(
            doc = "Chart version to pull. If not specified, the latest version is pulled.",
        ),
    },
)
