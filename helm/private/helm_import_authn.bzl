"""Repository rule for OCI repo authentication."""

# Unfortunately bazel downloader doesn't let us sniff the WWW-Authenticate header, therefore we need to
# keep a map of known registries that require us to acquire a temporary token for authentication.
_WWW_AUTH = {
    "registry-1.docker.io": {
        "challenge": "Bearer",
        "realm": "auth.docker.io/token",
        "scope": "repository:{chart}:pull",
        "service": "registry.docker.io",
    },
}

def _get_token(repository_ctx, state, hostname, chart_path):
    allow_fail = repository_ctx.os.environ.get("OCI_GET_TOKEN_ALLOW_FAIL") != None
    www_auth = dict(**_WWW_AUTH)
    for registry_pattern in www_auth.keys():
        if (hostname == registry_pattern) or hostname.endswith(registry_pattern):
            www_authenticate = www_auth[registry_pattern]
            scheme = "https://"
            if "://" in www_authenticate["realm"]:
                scheme = ""
            url = "{scheme}{realm}?scope={scope}&service={service}".format(
                scheme = scheme,
                realm = www_authenticate["realm"].format(hostname = hostname),
                service = www_authenticate["service"].format(hostname = hostname),
                scope = www_authenticate["scope"].format(chart = chart_path),
            )

            # if a token for this hostname and chart_path is acquired, use that instead.
            if url in state["token"]:
                return state["token"][url]

            result = repository_ctx.download(
                url = [url],
                output = "www-authenticate.json",
                allow_fail = allow_fail,
            )
            if allow_fail and not result.success:
                repository_ctx.file("www-authenticate.json", content = "")
                repository_ctx.delete("www-authenticate.json")
                return {}
            auth_raw = repository_ctx.read("www-authenticate.json")
            repository_ctx.delete("www-authenticate.json")

            auth = json.decode(auth_raw)

            token = ""
            if "token" in auth:
                token = auth["token"]
            if "access_token" in auth:
                token = auth["access_token"]
            if token == "":
                if allow_fail:
                    return {}
                fail("could not find token in neither field 'token' nor 'access_token' in the response from the hostname")
            pattern = {
                "type": "pattern",
                "pattern": "%s <password>" % www_authenticate["challenge"],
                "password": token,
            }

            # put the token into cache so that we don't do the token exchange again.
            state["token"][url] = pattern
            return pattern
    return {}

def _new_auth(repository_ctx):
    state = {
        "config": {},
        "token": {},
    }
    return struct(
        get_token = lambda hostname, chart_path: _get_token(repository_ctx, state, hostname, chart_path),
    )

authn = struct(
    new = _new_auth,
)
