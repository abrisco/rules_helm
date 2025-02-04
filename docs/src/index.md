# rules_helm

Bazel rules for producing [helm charts][helm]

[helm]: https://helm.sh/

## Setup WORKSPACE

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# See releases for urls and checksums
http_archive(
    name = "rules_helm",
    sha256 = "{sha256}",
    urls = ["https://github.com/abrisco/rules_helm/releases/download/{version}/rules_helm-v{version}.tar.gz"],
)

load("@rules_helm//helm:repositories.bzl", "helm_register_toolchains", "rules_helm_dependencies")

rules_helm_dependencies()

helm_register_toolchains()

load("@rules_helm//helm:repositories_transitive.bzl", "rules_helm_transitive_dependencies")

rules_helm_transitive_dependencies()
```

## Setup MODULE

```python
bazel_dep(name = "rules_helm", version = "{version}")
```

## Run as a tool

```bash
bazel run @helm//:helm -- ...
```

## Use in a genrule

```starlark
genrule(
    name = "genrule",
    srcs = [":chart"],
    outs = ["template.yaml"],
    cmd = "$(HELM_BIN) template my-chart $(execpath :chart) > $@",
    toolchains = ["@rules_helm//helm:current_toolchain"],
)
```
