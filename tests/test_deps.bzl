"""Dependencies for helm test/example targets"""

load("@rules_oci//oci:pull.bzl", "oci_pull")
load("//helm:defs.bzl", "helm_import_repository")

def helm_test_deps():
    helm_import_repository(
        name = "helm_test_deps__with_chart_deps",
        repository = "https://charts.bitnami.com/bitnami",
        url = "https://charts.bitnami.com/bitnami/redis-14.4.0.tgz",
        version = "14.4.0",
        sha256 = "43374837646a67539eb2999cd8973dc54e8fcdc14896761e594b9d616734edf2",
        chart_name = "redis",
    )

    oci_pull(
        name = "rules_helm_test_oci_container_base",
        digest = "sha256:2042a492bcdd847a01cd7f119cd48caa180da696ed2aedd085001a78664407d6",
        image = "alpine",
    )
