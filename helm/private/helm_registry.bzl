"""Helm rules"""

load("//helm:providers.bzl", "HelmPackageInfo")

def _get_image_push_commands(ctx, pkg_info):
    image_pushers = []
    image_runfiles = []
    for image in pkg_info.images:
        image_pushers.append(image[DefaultInfo].files_to_run.executable)
        image_runfiles.append(image[DefaultInfo].default_runfiles)

    if image_pushers:
        image_commands = "\n".join([pusher.short_path for pusher in image_pushers])
    else:
        image_commands = "echo 'No OCI images to push for Helm chart.'"

    runfiles = ctx.runfiles(files = image_pushers)
    for ir in image_runfiles:
        runfiles = runfiles.merge(ir)
    return image_commands, runfiles

def _helm_push_impl(ctx):
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    if toolchain.helm.basename.endswith(".exe"):
        registrar = ctx.actions.declare_file(ctx.label.name + ".bat")
    else:
        registrar = ctx.actions.declare_file(ctx.label.name + ".sh")

    registry_url = ctx.attr.registry_url
    pkg_info = ctx.attr.package[HelmPackageInfo]

    image_commands = ""
    image_runfiles = ctx.runfiles()
    if ctx.attr.include_images:
        image_commands, image_runfiles = _get_image_push_commands(
            ctx = ctx,
            pkg_info = pkg_info,
        )

    ctx.actions.expand_template(
        template = ctx.file._registrar,
        output = registrar,
        substitutions = {
            "{chart}": pkg_info.chart.short_path,
            "{helm}": toolchain.helm.short_path,
            "{image_pushers}": image_commands,
            "{registry_url}": registry_url,
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles([registrar, toolchain.helm, pkg_info.chart]).merge(image_runfiles)

    return [
        DefaultInfo(
            files = depset([registrar]),
            runfiles = runfiles,
            executable = registrar,
        ),
    ]

helm_push = rule(
    doc = "Produce an executable for performing a helm push to a registry.",
    implementation = _helm_push_impl,
    executable = True,
    attrs = {
        "include_images": attr.bool(
            doc = "If True, images depended on by `package` will be pushed as well.",
            default = False,
        ),
        "package": attr.label(
            doc = "The helm package to push to the registry.",
            providers = [HelmPackageInfo],
            mandatory = True,
        ),
        "registry_url": attr.string(
            doc = "The URL of the registry.",
            mandatory = True,
        ),
        "_registrar": attr.label(
            doc = "A process wrapper to use for performing `helm registry and helm push`.",
            allow_single_file = True,
            default = Label("//helm/private/registrar:template"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)

def _helm_push_images_impl(ctx):
    toolchain = ctx.toolchains[Label("//helm:toolchain_type")]

    if toolchain.helm.basename.endswith(".exe"):
        pusher = ctx.actions.declare_file(ctx.label.name + ".bat")
    else:
        pusher = ctx.actions.declare_file(ctx.label.name + ".sh")

    pkg_info = ctx.attr.package[HelmPackageInfo]

    image_commands, image_runfiles = _get_image_push_commands(
        ctx = ctx,
        pkg_info = pkg_info,
    )

    ctx.actions.expand_template(
        template = ctx.file._pusher,
        output = pusher,
        substitutions = {
            "{image_pushers}": image_commands,
        },
        is_executable = True,
    )

    runfiles = ctx.runfiles([pusher]).merge(image_runfiles)

    return [
        DefaultInfo(
            files = depset([pusher]),
            runfiles = runfiles,
            executable = pusher,
        ),
    ]

helm_push_images = rule(
    doc = "Produce an executable for pushing all oci images used by a helm chart.",
    implementation = _helm_push_images_impl,
    executable = True,
    attrs = {
        "package": attr.label(
            doc = "The helm package to upload images from.",
            providers = [HelmPackageInfo],
            mandatory = True,
        ),
        "_pusher": attr.label(
            doc = "A template used to produce the pusher executable.",
            allow_single_file = True,
            default = Label("//helm/private/pusher:template"),
        ),
    },
    toolchains = [
        str(Label("//helm:toolchain_type")),
    ],
)
