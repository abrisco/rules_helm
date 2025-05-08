# rules_helm

Bazel rules for producing [helm charts][helm]

[helm]: https://helm.sh/

## Setup MODULE.bazel

`rules_helm` is published to the
[Bazel Central Registry](https://registry.bazel.build/modules/rules_helm):

```starlark
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
