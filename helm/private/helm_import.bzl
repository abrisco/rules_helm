"""Helm rules for managing external dependencies"""

load("//helm:providers.bzl", "HelmPackageInfo")
load(":helm_import_authn.bzl", "authn")

def _helm_import_impl(ctx):
    metadata_output = ctx.actions.declare_file(ctx.label.name + ".metadata.json")
    ctx.actions.write(
        output = metadata_output,
        content = json.encode_indent(struct(
            name = ctx.label.name,
            version = ctx.attr.version,
        ), indent = " " * 4),
    )

    return [
        DefaultInfo(
            files = depset([ctx.file.chart]),
            runfiles = ctx.runfiles([ctx.file.chart]),
        ),
        HelmPackageInfo(
            chart = ctx.file.chart,
            images = [],
            metadata = metadata_output,
        ),
    ]

helm_import = rule(
    implementation = _helm_import_impl,
    doc = "A rule that allows pre-packaged Helm charts to be used within Bazel.",
    attrs = {
        "chart": attr.label(
            doc = "A Helm chart's `.tgz` file.",
            allow_single_file = [".tgz"],
        ),
        "version": attr.string(
            doc = "The version of the helm chart",
        ),
    },
)

def _find_chart_url(repository_ctx, repo_file, chart_name, chart_version):
    # HTTP source for `repository_ctx.download`:
    chart_file = "{}-{}.tgz".format(chart_name, chart_version)

    # OCI source:
    oci_identifier = "{}:{}".format(chart_name, chart_version)

    repo_def = repository_ctx.read(repo_file)
    lines = repo_def.splitlines()
    for line in lines:
        line = line.lstrip(" ")
        if line.startswith("-") and line.endswith(chart_file) or line.endswith(oci_identifier):
            url = line.lstrip("-").lstrip(" ")
            if url == chart_file:
                return "{}/{}".format(repository_ctx.attr.repository, url)
            if url.startswith("http") and url.endswith("/{}".format(chart_file)):
                return url
            if url.startswith("oci") and url.endswith("/{}".format(oci_identifier)):
                return url
    fail("cannot find {} (version {}) in {}".format(chart_name, chart_version, repository_ctx.attr.repository))

def _find_chart_digest(manifest):
    for layer in manifest["layers"]:
        # https://helm.sh/docs/topics/registries/#helm-chart-manifest
        if layer["mediaType"] == "application/vnd.cncf.helm.chart.content.v1.tar+gzip":
            return layer["digest"]
    fail("could not find chart content layer")

_HELM_DEP_BUILD_FILE = """\
load("@rules_helm//helm:defs.bzl", "helm_import")

helm_import(
    name = "{chart_name}",
    chart = "{chart_file}",
    visibility = ["//visibility:public"],
)
"""

def _helm_import_url_impl(repository_ctx):
    chart_name = repository_ctx.attr.chart_name
    chart_url = repository_ctx.attr.url

    chart_file = "{}.tgz".format(chart_name)

    repository_ctx.file("BUILD.bazel", content = _HELM_DEP_BUILD_FILE.format(
        chart_name = chart_name,
        chart_file = chart_file,
    ))

    if chart_url.startswith("http"):
        repository_ctx.download(
            output = repository_ctx.path(chart_file),
            url = chart_url,
            # canonical_id = get_default_canonical_id(repository_ctx, [chart_url]),
            # sha256 = repository_ctx.attr.sha256,
        )
    elif chart_url.startswith("oci"):
        _oci_url_download(repository_ctx, chart_url, chart_file)
    else:
        fail("{} does not use a supported protocol".format(chart_url))

helm_import_url = repository_rule(
    implementation = _helm_import_url_impl,
    attrs = {
        "chart_name": attr.string(
            doc = "Chart name to import.",
            mandatory = True,
        ),
        "url": attr.string(
            doc = "The URL where the chart can be directly downloaded.",
            mandatory = True,
        ),
    },
)

def _oci_url_download(repository_ctx, url, chart_file):
    url, _, chart_version = url.rpartition(":")
    hostname, _, chart_path = url.removeprefix("oci://").partition("/")

    au = authn.new(repository_ctx)
    token = au.get_token(hostname, chart_path)

    manifest_json = "manifest.json"
    manifest_url = "https://{}/v2/{}/manifests/{}".format(
        hostname,
        chart_path,
        chart_version,
    )
    repository_ctx.download(
        output = manifest_json,
        url = manifest_url,
        auth = {
            manifest_url: token,
        },
        # Copied from `helm pull --debug`
        headers = {
            "Accept": [
                "application/vnd.docker.distribution.manifest.v2+json",
                "application/vnd.docker.distribution.manifest.list.v2+json",
                "application/vnd.oci.image.manifest.v1+json",
                "application/vnd.oci.image.index.v1+json",
                "*/*",
            ],
        },
    )
    manifest = json.decode(repository_ctx.read(manifest_json))

    # https://helm.sh/docs/topics/registries/#helm-chart-manifest
    if manifest["config"]["mediaType"] != "application/vnd.cncf.helm.config.v1+json":
        fail("oci://{}/{} is not a Helm chart package".format(hostname, chart_path))

    chart_digest = _find_chart_digest(manifest)
    chart_blob_url = "https://{}/v2/{}/blobs/{}".format(
        hostname,
        chart_path,
        chart_digest,
    )

    # Download the chart package:
    return repository_ctx.download(
        output = repository_ctx.path(chart_file),
        url = chart_blob_url,
        auth = {
            chart_blob_url: token,
        },
    )

def _helm_import_repository_impl(repository_ctx):
    chart_name = repository_ctx.attr.chart_name
    chart_version = repository_ctx.attr.version

    repo_yaml = "index.yaml"
    repository_ctx.download(
        output = repo_yaml,
        url = "{}/{}".format(
            repository_ctx.attr.repository,
            repo_yaml,
        ),
    )
    chart_url = _find_chart_url(repository_ctx, repo_yaml, chart_name, chart_version)
    chart_file = "{}.tgz".format(chart_name)

    if chart_url.startswith("http"):
        repository_ctx.download(
            output = repository_ctx.path(chart_file),
            url = chart_url,
        )
    elif chart_url.startswith("oci"):
        _oci_url_download(repository_ctx, chart_url, chart_file)
    else:
        fail("cannot download {} from {}, unsupported scheme".format(chart_name, chart_url))

    repository_ctx.file("BUILD.bazel", content = _HELM_DEP_BUILD_FILE.format(
        chart_name = chart_name,
        chart_file = chart_file,
        repository_name = repository_ctx.name,
    ))

helm_import_repository = repository_rule(
    implementation = _helm_import_repository_impl,
    doc = "A rule for fetching external Helm chart from a HTTP repository.",
    attrs = {
        "chart_name": attr.string(
            doc = "Chart name to import.",
            mandatory = True,
        ),
        "repository": attr.string(
            doc = "Repository URL where to locate the specified chart.",
            mandatory = True,
        ),
        "version": attr.string(
            doc = "Chart version to import.",
            mandatory = True,
        ),
    },
)
