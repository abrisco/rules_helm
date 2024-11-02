"""Dependencies for helm test/example targets"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@rules_oci//oci:pull.bzl", "oci_pull")
load("//helm:defs.bzl", "helm_import_repository")

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
    maybe(
        helm_import_repository,
        name = "helm_test_deps__with_chart_deps_redis",
        repository = "https://charts.bitnami.com/bitnami",
        url = "https://charts.bitnami.com/bitnami/redis-14.4.0.tgz",
        version = "14.4.0",
        sha256 = "43374837646a67539eb2999cd8973dc54e8fcdc14896761e594b9d616734edf2",
        chart_name = "redis",
    )

    maybe(
        helm_import_repository,
        name = "helm_test_deps__with_chart_deps_postgresql",
        repository = "https://charts.bitnami.com/bitnami",
        url = "https://charts.bitnami.com/bitnami/postgresql-14.0.5.tgz",
        version = "14.0.5",
        sha256 = "38d9b6657aa3b0cc16d190570dbaf96796e997d03a1665264dac9966343e4d1b",
        chart_name = "postgresql",
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
