"""Dependencies for helm test/example targets"""

load("@io_bazel_rules_docker//container:container.bzl", "container_pull")
load("//helm:defs.bzl", "helm_dep_repository")

def helm_test_deps():
    helm_dep_repository(
        name = "helm_test_deps__with_chart_deps",
        repository = "https://charts.bitnami.com/bitnami",
        url = "https://charts.bitnami.com/bitnami/redis-14.4.0.tgz",
        version = "14.4.0",
        sha256 = "43374837646a67539eb2999cd8973dc54e8fcdc14896761e594b9d616734edf2",
        chart_name = "redis",
    )

    container_pull(
        name = "rules_helm_test_container_base",
        registry = "docker.io",
        repository = "alpine",
        digest = "sha256:2042a492bcdd847a01cd7f119cd48caa180da696ed2aedd085001a78664407d6",
    )
