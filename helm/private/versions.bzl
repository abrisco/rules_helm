"""Constants for accessing helm binaries"""

DEFAULT_HELM_VERSION = "3.8.1"

DEFAULT_HELM_URL_TEMPLATES = [
    "https://get.helm.sh/helm-v{version}-{platform}.{compression}",
]

HELM_VERSIONS = {
    "2.17.0": {
        "darwin-amd64": struct(
            sha256 = "104dcda352985306d04d5d23aaf5252d00a85c083f3667fd013991d82f57ae83",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "linux-amd64": struct(
            sha256 = "f3bec3c7c55f6a9eb9e6586b8c503f370af92fe987fcbf741f37707606d70296",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "c3ebe8fa04b4e235eb7a9ab030a98d3002f93ecb842f0a8741f98383a9493d7f",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "048147ef523f88753ba34170f2f6acd01ac6ec688c6f5973b0e5ffb0b113a232",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.4.2": {
        "darwin-amd64": struct(
            sha256 = "c33b7ee72b0006f23b33f5032b531dd609fff7b08a4324f9ba07722a4f3fec9a",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "linux-amd64": struct(
            sha256 = "cacde7768420dd41111a4630e047c231afa01f67e49cc0c6429563e024da4b98",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "486cad35b9ac1da88781847f2fcaaaed729e44705eb42593322e4b52d0f2c1a1",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "76ff3f8c21c9af5b80abdd87ec07629ad88dbfe6206decc4d3024f26398554b9",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.5.3": {
        "darwin-amd64": struct(
            sha256 = "451ad70dfe286e3979c78ecf7074f4749d93644da8aa2cc778e2f969771f1794",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "linux-amd64": struct(
            sha256 = "2170a1a644a9e0b863f00c17b761ce33d4323da64fc74562a3a6df2abbf6cd70",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "e1348d94ce4caace43689ee2dfa5f8bcd8687c12053d9c13d79875b65d6b72aa",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "33fef4740b255b58a52e5504622068fd8a7d9aea19f1a84438f5cc1c5aade0d6",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.6.3": {
        "darwin-amd64": struct(
            sha256 = "84a1ff17dd03340652d96e8be5172a921c97825fd278a2113c8233a4e8db5236",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "darwin-arm64": struct(
            sha256 = "a50b499dbd0bbec90761d50974bf1e67cc6d503ea20d03b4a1275884065b7e9e",
            constraints = ["@platforms//os:macos", "@platforms//cpu:aarch64"],
        ),
        "linux-amd64": struct(
            sha256 = "07c100849925623dc1913209cd1a30f0a9b80a5b4d6ff2153c609d11b043e262",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "6fe647628bc27e7ae77d015da4d5e1c63024f673062ac7bc11453ccc55657713",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "797d2abd603a2646f2fb9c3fabba46f2fabae5cbd1eb87c20956ec5b4a2fc634",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.7.2": {
        "darwin-amd64": struct(
            sha256 = "5a0738afb1e194853aab00258453be8624e0a1d34fcc3c779989ac8dbcd59436",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "darwin-arm64": struct(
            sha256 = "260d4b8bffcebc6562ea344dfe88efe252cf9511dd6da3cccebf783773d42aec",
            constraints = ["@platforms//os:macos", "@platforms//cpu:aarch64"],
        ),
        "linux-amd64": struct(
            sha256 = "4ae30e48966aba5f807a4e140dad6736ee1a392940101e4d79ffb4ee86200a9e",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "b0214eabbb64791f563bd222d17150ce39bf4e2f5de49f49fdb456ce9ae8162f",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "299165f0af46bece9a61b41305cca8e8d5ec5319a4b694589cd71e6b75aca77e",
            constraints = ["@platforms//os:windows"],
        ),
    },
    "3.8.1": {
        "darwin-amd64": struct(
            sha256 = "3b6d87d360a51bf0f2344edd54e3580a8e8de2c4a4fd92eccef3e811f7e81bb3",
            constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        ),
        "darwin-arm64": struct(
            sha256 = "5f0fea586781fb867b92c10133786949ab6a447f297d5c12e1e8f5dd3a9ed712",
            constraints = ["@platforms//os:macos", "@platforms//cpu:aarch64"],
        ),
        "linux-amd64": struct(
            sha256 = "d643f48fe28eeb47ff68a1a7a26fc5142f348d02c8bc38d699674016716f61cd",
            constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        ),
        "linux-arm64": struct(
            sha256 = "dbf5118259717d86c57d379317402ed66016c642cc0d684f3505da6f194b760d",
            constraints = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        ),
        "windows-amd64": struct(
            sha256 = "a75003fc692131652d3bd218dd4007692390a1dd156f11fd7668e389bdd8f765",
            constraints = ["@platforms//os:windows"],
        ),
    },
}
