"""rules_helm provider definitions"""

HelmPackageInfo = provider(
    doc = "A provider for helm packages",
    fields = {
        "chart": "File: The result of `helm package`",
        "images": "list[Target]: A list of [@rules_docker//container:push.bzl%container_push](https://github.com/bazelbuild/rules_docker/blob/v0.22.0/docs/container.md#container_push) targets",
        "metadata": "File: A json encoded file containing metadata about the helm chart",
    },
)
