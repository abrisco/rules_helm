"""Dependencies for helm test/example targets"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@rules_oci//oci:pull.bzl", "oci_pull")
load("//helm:defs.bzl", "helm_pull")

_CM_HELM_PUSH_BUILD_CONTENT = """\
package(default_visibility = ["//visibility:public"])

exports_files(["plugin.yaml"])

filegroup(
    name = "data",
    srcs = glob(["bin/**"]),
)
"""

def helm_test_deps():
    """Helm test dependencies"""

    # Pull this chart from a repository:
    maybe(
        helm_pull,
        name = "helm_test_deps__with_chart_deps_redis",
        repo = "https://charts.bitnami.com/bitnami",
        chart_name = "redis",
        version = "21.2.5",
    )

    # Directly pull this chart from a HTTP URL:
    maybe(
        helm_pull,
        name = "helm_test_deps__with_chart_deps_postgresql",
        chart_name = "postgresql",
        url = "https://charts.bitnami.com/bitnami/postgresql-14.0.5.tgz",
    )

    # Directly pull this chart from an OCI URL:
    maybe(
        helm_pull,
        name = "helm_test_deps__with_chart_deps_grafana",
        chart_name = "grafana",
        url = "oci://registry-1.docker.io/bitnamicharts/grafana:12.1.4",
    )

    maybe(
        oci_pull,
        name = "rules_helm_test_container_base",
        digest = "sha256:2042a492bcdd847a01cd7f119cd48caa180da696ed2aedd085001a78664407d6",
        image = "alpine",
    )

    maybe(
        http_archive,
        name = "helm_cm_push_linux",
        urls = ["https://github.com/chartmuseum/helm-push/releases/download/v0.10.4/helm-push_0.10.4_linux_amd64.tar.gz"],
        integrity = "sha256-KfH3E2mbR+PJwY1gtQVffA6LzBIh1mOcBX54fgi2Vqg=",
        build_file_content = _CM_HELM_PUSH_BUILD_CONTENT,
    )

    maybe(
        http_archive,
        name = "helm_cm_push_macos",
        urls = ["https://github.com/chartmuseum/helm-push/releases/download/v0.10.4/helm-push_0.10.4_darwin_arm64.tar.gz"],
        integrity = "sha256-oKyCvUYCHt/LPcIj99ZaVP6PlpGPy7dgwTl/yo43SqI=",
        build_file_content = _CM_HELM_PUSH_BUILD_CONTENT,
    )

    maybe(
        http_archive,
        name = "helm_cm_push_windows",
        urls = ["https://github.com/chartmuseum/helm-push/releases/download/v0.10.4/helm-push_0.10.4_windows_amd64.tar.gz"],
        integrity = "sha256-aFkN3IJXd8TVlJ/NY3v2sZ4Rerp644e02u0HNqboELw=",
        build_file_content = _CM_HELM_PUSH_BUILD_CONTENT,
    )
