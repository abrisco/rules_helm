<!-- Generated with Stardoc: http://skydoc.bazel.build -->

# rules_helm

Bazel rules for producing [helm charts][helm]

[helm]: https://helm.sh/

## Setup WORKSPACE

```starlark
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

```starlark
bazel_dep(name = "rules_helm", version = "{version}")
```

## Rules

- [helm_chart](#helm_chart)
- [helm_import_repository](#helm_import_repository)
- [helm_import](#helm_import)
- [helm_install](#helm_install)
- [helm_lint_aspect](#helm_lint_aspect)
- [helm_lint_test](#helm_lint_test)
- [helm_package](#helm_package)
- [helm_push](#helm_push)
- [helm_push_registry](#helm_push_registry)
- [helm_register_toolchains](#helm_register_toolchains)
- [helm_reinstall](#helm_reinstall)
- [helm_toolchain](#helm_toolchain)
- [helm_uninstall](#helm_uninstall)
- [rules_helm_dependencies](#rules_helm_dependencies)
- [chart_content](#chart_content)

<a id="chart_file"></a>

## chart_file

<pre>
chart_file(<a href="#chart_file-name">name</a>, <a href="#chart_file-api_version">api_version</a>, <a href="#chart_file-app_version">app_version</a>, <a href="#chart_file-chart_name">chart_name</a>, <a href="#chart_file-description">description</a>, <a href="#chart_file-type">type</a>, <a href="#chart_file-version">version</a>)
</pre>

Create a Helm chart file.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="chart_file-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="chart_file-api_version"></a>api_version |  The Helm API version   | String | optional |  `"v2"`  |
| <a id="chart_file-app_version"></a>app_version |  The version number of the application being deployed.   | String | optional |  `"1.16.0"`  |
| <a id="chart_file-chart_name"></a>chart_name |  The name of the chart   | String | optional |  `""`  |
| <a id="chart_file-description"></a>description |  A descritpion of the chart.   | String | optional |  `"A Helm chart for Kubernetes by Bazel."`  |
| <a id="chart_file-type"></a>type |  The chart type.   | String | optional |  `"application"`  |
| <a id="chart_file-version"></a>version |  The chart version.   | String | optional |  `"0.1.0"`  |


<a id="helm_import"></a>

## helm_import

<pre>
helm_import(<a href="#helm_import-name">name</a>, <a href="#helm_import-chart">chart</a>, <a href="#helm_import-version">version</a>)
</pre>

A rule that allows pre-packaged Helm charts to be used within Bazel.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="helm_import-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="helm_import-chart"></a>chart |  A Helm chart's `.tgz` file.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="helm_import-version"></a>version |  The version fo the helm chart   | String | optional |  `""`  |


<a id="helm_import_repository"></a>

## helm_import_repository

<pre>
helm_import_repository(<a href="#helm_import_repository-name">name</a>, <a href="#helm_import_repository-chart_name">chart_name</a>, <a href="#helm_import_repository-repo_mapping">repo_mapping</a>, <a href="#helm_import_repository-repository">repository</a>, <a href="#helm_import_repository-sha256">sha256</a>, <a href="#helm_import_repository-url">url</a>, <a href="#helm_import_repository-version">version</a>)
</pre>

A rule for fetching external Helm charts from an arbitrary repository.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="helm_import_repository-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="helm_import_repository-chart_name"></a>chart_name |  Chart name to import.   | String | optional |  `""`  |
| <a id="helm_import_repository-repo_mapping"></a>repo_mapping |  A dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.<p>For example, an entry `"@foo": "@bar"` declares that, for any time this repository depends on `@foo` (such as a dependency on `@foo//some:target`, it should actually resolve that dependency within globally-declared `@bar` (`@bar//some:target`).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | required |  |
| <a id="helm_import_repository-repository"></a>repository |  Chart repository url where to locate the requested chart.   | String | required |  |
| <a id="helm_import_repository-sha256"></a>sha256 |  The expected SHA-256 hash of the chart imported.   | String | optional |  `""`  |
| <a id="helm_import_repository-url"></a>url |  The url where the chart can be directly downloaded.   | String | optional |  `""`  |
| <a id="helm_import_repository-version"></a>version |  Specify a version constraint for the chart version to use.   | String | optional |  `""`  |


<a id="helm_install"></a>

## helm_install

<pre>
helm_install(<a href="#helm_install-name">name</a>, <a href="#helm_install-helm_opts">helm_opts</a>, <a href="#helm_install-install_name">install_name</a>, <a href="#helm_install-opts">opts</a>, <a href="#helm_install-package">package</a>)
</pre>

Produce a script for performing a helm install action

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="helm_install-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="helm_install-helm_opts"></a>helm_opts |  Additional arguments to pass to `helm` during install.   | List of strings | optional |  `[]`  |
| <a id="helm_install-install_name"></a>install_name |  The name to use for the `helm install` command. The target name will be used if unset.   | String | optional |  `""`  |
| <a id="helm_install-opts"></a>opts |  Additional arguments to pass to `helm install`.   | List of strings | optional |  `[]`  |
| <a id="helm_install-package"></a>package |  The helm package to install.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="helm_lint_test"></a>

## helm_lint_test

<pre>
helm_lint_test(<a href="#helm_lint_test-name">name</a>, <a href="#helm_lint_test-chart">chart</a>)
</pre>

A rule for performing `helm lint` on a helm package

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="helm_lint_test-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="helm_lint_test-chart"></a>chart |  The helm package to run linting on.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="helm_package"></a>

## helm_package

<pre>
helm_package(<a href="#helm_package-name">name</a>, <a href="#helm_package-deps">deps</a>, <a href="#helm_package-chart">chart</a>, <a href="#helm_package-chart_json">chart_json</a>, <a href="#helm_package-images">images</a>, <a href="#helm_package-stamp">stamp</a>, <a href="#helm_package-substitutions">substitutions</a>, <a href="#helm_package-templates">templates</a>, <a href="#helm_package-values">values</a>,
             <a href="#helm_package-values_json">values_json</a>)
</pre>

Rules for creating Helm chart packages.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="helm_package-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="helm_package-deps"></a>deps |  Other helm packages this package depends on.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="helm_package-chart"></a>chart |  The `Chart.yaml` file of the helm chart   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="helm_package-chart_json"></a>chart_json |  The `Chart.yaml` file of the helm chart as a json object   | String | optional |  `""`  |
| <a id="helm_package-images"></a>images |  A list of                 [oci_push](https://github.com/bazel-contrib/rules_oci/blob/main/docs/push.md#oci_push_rule-remote_tags)                 targets.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="helm_package-stamp"></a>stamp |  Whether to encode build information into the helm actions. Possible values:<br><br>- `stamp = 1`: Always stamp the build information into the helm actions, even in                 [--nostamp](https://docs.bazel.build/versions/main/user-manual.html#flag--stamp) builds.                 This setting should be avoided, since it potentially kills remote caching for the target and                 any downstream actions that depend on it.<br><br>- `stamp = 0`: Always replace build information by constant values. This gives good build result caching.<br><br>- `stamp = -1`: Embedding of build information is controlled by the                 [--[no]stamp](https://docs.bazel.build/versions/main/user-manual.html#flag--stamp) flag.<br><br>Stamped targets are not rebuilt unless their dependencies change.   | Integer | optional |  `-1`  |
| <a id="helm_package-substitutions"></a>substitutions |  A dictionary of substitutions to apply to the `values.yaml` file.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  `{}`  |
| <a id="helm_package-templates"></a>templates |  All templates associated with the current helm chart. E.g., the `./templates` directory   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="helm_package-values"></a>values |  The `values.yaml` file for the current package.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="helm_package-values_json"></a>values_json |  The `values.yaml` file for the current package as a json object.   | String | optional |  `""`  |


<a id="helm_push"></a>

## helm_push

<pre>
helm_push(<a href="#helm_push-name">name</a>, <a href="#helm_push-package">package</a>)
</pre>

Produce a script for pushing all oci images used by a helm chart

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="helm_push-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="helm_push-package"></a>package |  The helm package to upload images from.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="helm_push_registry"></a>

## helm_push_registry

<pre>
helm_push_registry(<a href="#helm_push_registry-name">name</a>, <a href="#helm_push_registry-package">package</a>, <a href="#helm_push_registry-registry_url">registry_url</a>)
</pre>

Produce a script for performing a helm push to a registry

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="helm_push_registry-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="helm_push_registry-package"></a>package |  The helm package to push to the registry.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="helm_push_registry-registry_url"></a>registry_url |  The URL of the registry.   | String | required |  |


<a id="helm_reinstall"></a>

## helm_reinstall

<pre>
helm_reinstall(<a href="#helm_reinstall-name">name</a>, <a href="#helm_reinstall-helm_opts">helm_opts</a>, <a href="#helm_reinstall-install_name">install_name</a>, <a href="#helm_reinstall-opts">opts</a>, <a href="#helm_reinstall-package">package</a>)
</pre>

Produce a script for performing a helm uninstall and install actions

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="helm_reinstall-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="helm_reinstall-helm_opts"></a>helm_opts |  Additional arguments to pass to `helm` during install.   | List of strings | optional |  `[]`  |
| <a id="helm_reinstall-install_name"></a>install_name |  The name to use for the `helm install` command. The target name will be used if unset.   | String | optional |  `""`  |
| <a id="helm_reinstall-opts"></a>opts |  Additional arguments to pass to helm uninstall / install commands.   | List of strings | optional |  `[]`  |
| <a id="helm_reinstall-package"></a>package |  The helm package to reinstall.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="helm_toolchain"></a>

## helm_toolchain

<pre>
helm_toolchain(<a href="#helm_toolchain-name">name</a>, <a href="#helm_toolchain-helm">helm</a>)
</pre>

A helm toolchain

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="helm_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="helm_toolchain-helm"></a>helm |  A helm binary   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="helm_uninstall"></a>

## helm_uninstall

<pre>
helm_uninstall(<a href="#helm_uninstall-name">name</a>, <a href="#helm_uninstall-helm_opts">helm_opts</a>, <a href="#helm_uninstall-install_name">install_name</a>, <a href="#helm_uninstall-opts">opts</a>)
</pre>

Produce a script for performing a helm uninstall action

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="helm_uninstall-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="helm_uninstall-helm_opts"></a>helm_opts |  Additional arguments to pass to `helm` during install.   | List of strings | optional |  `[]`  |
| <a id="helm_uninstall-install_name"></a>install_name |  The name to use for the `helm install` command. The target name will be used if unset.   | String | optional |  `""`  |
| <a id="helm_uninstall-opts"></a>opts |  Additional arguments to pass to `helm uninstall`.   | List of strings | optional |  `[]`  |


<a id="helm_upgrade"></a>

## helm_upgrade

<pre>
helm_upgrade(<a href="#helm_upgrade-name">name</a>, <a href="#helm_upgrade-helm_opts">helm_opts</a>, <a href="#helm_upgrade-install_name">install_name</a>, <a href="#helm_upgrade-opts">opts</a>, <a href="#helm_upgrade-package">package</a>)
</pre>

Produce a script for performing a helm upgrade action

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="helm_upgrade-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="helm_upgrade-helm_opts"></a>helm_opts |  Additional arguments to pass to `helm` during upgrade.   | List of strings | optional |  `[]`  |
| <a id="helm_upgrade-install_name"></a>install_name |  The name to use for the `helm upgrade` command. The target name will be used if unset.   | String | optional |  `""`  |
| <a id="helm_upgrade-opts"></a>opts |  Additional arguments to pass to `helm upgrade`.   | List of strings | optional |  `[]`  |
| <a id="helm_upgrade-package"></a>package |  The helm package to upgrade.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="HelmPackageInfo"></a>

## HelmPackageInfo

<pre>
HelmPackageInfo(<a href="#HelmPackageInfo-chart">chart</a>, <a href="#HelmPackageInfo-images">images</a>, <a href="#HelmPackageInfo-metadata">metadata</a>)
</pre>

A provider for helm packages

**FIELDS**


| Name  | Description |
| :------------- | :------------- |
| <a id="HelmPackageInfo-chart"></a>chart |  File: The result of `helm package`    |
| <a id="HelmPackageInfo-images"></a>images |  list[Target]: A list of [@rules_oci//oci:defs.bzl%oci_push](https://github.com/bazel-contrib/rules_oci/blob/main/docs/push.md#oci_push_rule-remote_tags)]) targets    |
| <a id="HelmPackageInfo-metadata"></a>metadata |  File: A json encoded file containing metadata about the helm chart    |


<a id="chart_content"></a>

## chart_content

<pre>
chart_content(<a href="#chart_content-name">name</a>, <a href="#chart_content-api_version">api_version</a>, <a href="#chart_content-description">description</a>, <a href="#chart_content-type">type</a>, <a href="#chart_content-version">version</a>, <a href="#chart_content-app_version">app_version</a>)
</pre>

A convenience wrapper for defining Chart.yaml files with [helm_package.chart_json](#helm_package-chart_json).

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="chart_content-name"></a>name |  The name of the chart   |  none |
| <a id="chart_content-api_version"></a>api_version |  The Helm API version   |  `"v2"` |
| <a id="chart_content-description"></a>description |  A descritpion of the chart.   |  `"A Helm chart for Kubernetes by Bazel."` |
| <a id="chart_content-type"></a>type |  The chart type.   |  `"application"` |
| <a id="chart_content-version"></a>version |  The chart version.   |  `"0.1.0"` |
| <a id="chart_content-app_version"></a>app_version |  The version number of the application being deployed.   |  `"1.16.0"` |

**RETURNS**

str: A json encoded string which represents `Chart.yaml` contents.


<a id="helm_chart"></a>

## helm_chart

<pre>
helm_chart(<a href="#helm_chart-name">name</a>, <a href="#helm_chart-chart">chart</a>, <a href="#helm_chart-chart_json">chart_json</a>, <a href="#helm_chart-values">values</a>, <a href="#helm_chart-values_json">values_json</a>, <a href="#helm_chart-substitutions">substitutions</a>, <a href="#helm_chart-templates">templates</a>, <a href="#helm_chart-images">images</a>, <a href="#helm_chart-deps">deps</a>,
           <a href="#helm_chart-tags">tags</a>, <a href="#helm_chart-install_name">install_name</a>, <a href="#helm_chart-registry_url">registry_url</a>, <a href="#helm_chart-helm_opts">helm_opts</a>, <a href="#helm_chart-opts">opts</a>, <a href="#helm_chart-install_opts">install_opts</a>, <a href="#helm_chart-upgrade_opts">upgrade_opts</a>,
           <a href="#helm_chart-reinstall_opts">reinstall_opts</a>, <a href="#helm_chart-uninstall_opts">uninstall_opts</a>, <a href="#helm_chart-stamp">stamp</a>, <a href="#helm_chart-kwargs">kwargs</a>)
</pre>

Rules for producing a helm package and some convenience targets.

| target | rule |
| --- | --- |
| `{name}` | [helm_package](#helm_package) |
| `{name}.push` | [helm_push](#helm_push) |
| `{name}.push_registry` | [helm_push_registry](#helm_push_registry) |
| `{name}.install` | [helm_install](#helm_install) |
| `{name}.uninstall` | [helm_uninstall](#helm_uninstall) |
| `{name}.reinstall` | [helm_reinstall](#helm_reinstall) |


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="helm_chart-name"></a>name |  The name of the [helm_package](#helm_package) target.   |  none |
| <a id="helm_chart-chart"></a>chart |  The path to the chart directory. Defaults to `Chart.yaml`.   |  `None` |
| <a id="helm_chart-chart_json"></a>chart_json |  The json encoded contents of `Chart.yaml`.   |  `None` |
| <a id="helm_chart-values"></a>values |  The path to the values file. Defaults to `values.yaml`.   |  `None` |
| <a id="helm_chart-values_json"></a>values_json |  The json encoded contents of `values.yaml`.   |  `None` |
| <a id="helm_chart-substitutions"></a>substitutions |  A dictionary of substitutions to apply to `values.yaml`.   |  `{}` |
| <a id="helm_chart-templates"></a>templates |  A list of template files to include in the package.   |  `None` |
| <a id="helm_chart-images"></a>images |  A list of [oci_push](https://github.com/bazel-contrib/rules_oci/blob/main/docs/push.md#oci_push_rule-remote_tags) targets   |  `[]` |
| <a id="helm_chart-deps"></a>deps |  A list of helm package dependencies.   |  `None` |
| <a id="helm_chart-tags"></a>tags |  Tags to apply to all targets.   |  `[]` |
| <a id="helm_chart-install_name"></a>install_name |  The `helm install` name to use. `name` will be used if unset.   |  `None` |
| <a id="helm_chart-registry_url"></a>registry_url |  The registry url for the helm chart. `{name}.push_registry` is only defined when a value is passed here.   |  `None` |
| <a id="helm_chart-helm_opts"></a>helm_opts |  Additional options to pass to helm.   |  `[]` |
| <a id="helm_chart-opts"></a>opts |  Additional options to pass to `helm install`, `helm uninstall`, and `helm reinstall`.   |  `[]` |
| <a id="helm_chart-install_opts"></a>install_opts |  Additional options to pass to `helm install`.   |  `[]` |
| <a id="helm_chart-upgrade_opts"></a>upgrade_opts |  Additional options to pass to `helm upgrade`.   |  `[]` |
| <a id="helm_chart-reinstall_opts"></a>reinstall_opts |  Additional options to pass to helm reinstall.   |  `[]` |
| <a id="helm_chart-uninstall_opts"></a>uninstall_opts |  Additional options to pass to `helm uninstall`.   |  `[]` |
| <a id="helm_chart-stamp"></a>stamp |  Whether to encode build information into the helm chart.   |  `None` |
| <a id="helm_chart-kwargs"></a>kwargs |  Additional keyword arguments for `helm_package`.   |  none |


<a id="helm_register_toolchains"></a>

## helm_register_toolchains

<pre>
helm_register_toolchains(<a href="#helm_register_toolchains-version">version</a>, <a href="#helm_register_toolchains-helm_url_templates">helm_url_templates</a>)
</pre>

Register helm toolchains.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="helm_register_toolchains-version"></a>version |  The version of Helm to use   |  `"3.13.3"` |
| <a id="helm_register_toolchains-helm_url_templates"></a>helm_url_templates |  A list of url templates where helm can be downloaded.   |  `["https://get.helm.sh/helm-v{version}-{platform}.{compression}"]` |


<a id="rules_helm_dependencies"></a>

## rules_helm_dependencies

<pre>
rules_helm_dependencies()
</pre>

Defines helm dependencies



<a id="helm_lint_aspect"></a>

## helm_lint_aspect

<pre>
helm_lint_aspect(<a href="#helm_lint_aspect-name">name</a>)
</pre>

An aspect for running `helm lint` on helm package targets

**ASPECT ATTRIBUTES**



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="helm_lint_aspect-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |


