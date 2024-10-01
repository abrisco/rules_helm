"""Dependencies for helm test/example targets"""

load("@rules_oci//oci:pull.bzl", "oci_pull")
load("//helm:defs.bzl", "helm_import_repository")

def helm_test_deps():
    helm_import_repository(
        name = "helm_test_deps__with_chart_deps_redis",
        repository = "https://charts.bitnami.com/bitnami",
        url = "https://charts.bitnami.com/bitnami/redis-14.4.0.tgz",
        version = "14.4.0",
        sha256 = "43374837646a67539eb2999cd8973dc54e8fcdc14896761e594b9d616734edf2",
        chart_name = "redis",
    )

    helm_import_repository(
        name = "helm_test_deps__with_chart_deps_postgresql",
        repository = "https://charts.bitnami.com/bitnami",
        url = "https://charts.bitnami.com/bitnami/postgresql-14.0.5.tgz",
        version = "14.0.5",
        sha256 = "38d9b6657aa3b0cc16d190570dbaf96796e997d03a1665264dac9966343e4d1b",
        chart_name = "postgresql",
    )

    oci_pull(
        name = "rules_helm_test_container_base",
        digest = "sha256:2042a492bcdd847a01cd7f119cd48caa180da696ed2aedd085001a78664407d6",
        image = "alpine",
    )
