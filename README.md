Container Images
-------------

OCI base container images used for Scala 3 / Scala Native development at Shuwari Africa.

## Images

| Image                            | Base              | libc  | Static linking | Intended use                                      |
| -------------------------------- | ----------------- | ----- | -------------- | ------------------------------------------------- |
| `shuwariafrica/el10-jdk:<jdk>`   | Oracle Linux 10   | glibc | No (dynamic)   | Scala 3 / Scala Native dev on the RHEL family.    |
| `shuwariafrica/alpine-jdk:<jdk>` | Alpine Linux      | musl  | Yes            | Scala 3 / Scala Native fully-static builds.       |

The `<jdk>` tag is the JDK major version. Supported: `17`, `21`, `25`. All published tags are multi-arch (`linux/amd64` and `linux/arm64`).

Each successful publish also produces an immutable tag `<jdk>-<short-hash>`, where `<short-hash>` is derived from the full installed package manifest. The CI build only publishes when this hash differs from what is already on the registry, so the monthly cron is a no-op when nothing upstream has changed.

## Scope

These are intentionally minimal Scala Native build images - JDK, sbt, and the C/LLVM toolchain plus the libraries Scala Native links against.

## Licensing notes

The `el10-jdk` image is built on glibc and deliberately omits any `*-static` libraries to avoid the LGPL static-linking obligations that apply to glibc. Use `alpine-jdk` when static linking is required - musl, zlib, libunwind, and the Boehm GC are permissively licensed under terms compatible with static linking.

## Notes on Scala Native garbage collectors on Alpine

Alpine's `gc-dev` package only ships shared libraries; there is no `libgc.a`. This means **Boehm GC cannot be statically linked** on `alpine-jdk` without building libgc from source. The default Scala Native GC (Immix) is built into the Scala Native runtime and does not require an external static library, so the standard fully-static build path works out of the box. Commix likewise needs no external GC library.

## Using `alpine-jdk` as a GitHub Actions container on arm64

GitHub Actions's runner (`actions/runner`) carries a hardcoded check that refuses to launch JavaScript actions inside an Alpine container on arm64 hosts (it ships musl Node externals only for x64). The check is purely a substring search for `"alpine"` in lines starting with `ID` from `/etc/*release` inside the container - see [`StepHost.cs`](https://github.com/actions/runner/blob/main/src/Runner.Worker/Handlers/StepHost.cs).

`alpine-jdk` works around this by:

- Renaming `ID=alpine` to `ID=linux` in `/etc/os-release` (other identification paths - `NAME`, `PRETTY_NAME`, `/etc/alpine-release`, the `apk` toolchain - are untouched).
- Bundling `gcompat`, the glibc-shim package, so the runner's default glibc-built Node binary can execute on musl.

The combination lets `shuwariafrica/alpine-jdk:<jdk>` be used as a `container:` on `ubuntu-24.04-arm` runners without hitting the upstream gate. If a future runner release ships native musl/arm64 Node externals, this workaround will be removed.
