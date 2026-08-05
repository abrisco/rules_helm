# rules_helm

Bazel rules for [Helm](https://helm.sh/).

## Documentation

https://periareon.github.io/rules_helm/

## Environment variables

### `RULES_HELM_IMAGE_PUSH_CONCURRENCY`

How many of a chart's bundled image pushers run at once. Defaults to `4`, and applies to
[helm_push](https://periareon.github.io/rules_helm/defs.html#helm_push),
[helm_push_images](https://periareon.github.io/rules_helm/defs.html#helm_push_images),
[helm_install](https://periareon.github.io/rules_helm/defs.html#helm_install) and
[helm_upgrade](https://periareon.github.io/rules_helm/defs.html#helm_upgrade).

Each image is pushed by its own process, which authenticates with the registry before it looks at
anything, so a chart with many images spends most of the push waiting rather than transferring.
Running the pushers concurrently keeps that cost from scaling with the image count.

Set it to `1` to push one image at a time. A serial run also streams each pusher's output live on
its own streams, instead of capturing it and replaying it as a block once the pusher exits, which
makes a single failing push easier to follow.

Values that are not a positive integer are ignored with a warning.
