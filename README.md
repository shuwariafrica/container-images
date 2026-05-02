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

`alpine-jdk` cannot be used as a `container:` on `ubuntu-24.04-arm` runners. `actions/runner` refuses to launch JavaScript actions inside an Alpine container on arm64 hosts ([StepHost.cs](https://github.com/actions/runner/blob/main/src/Runner.Worker/Handlers/StepHost.cs)) because it ships no musl/arm64 Node externals; bypassing the detection only swaps the failure for a glibc-binary relocation error against musl, which `gcompat` does not fully cover. The limitation is tracked at [actions/runner#801](https://github.com/actions/runner/issues/801).

Workarounds for arm64 jobs that need the musl/static-link toolchain:

- Use `shuwariafrica/el10-jdk:<jdk>` as the `container:` on arm64 - it is glibc-based, so the runner gate does not apply.
- Or drop the `container:` syntax and run on `ubuntu-24.04-arm` directly, invoking the Alpine image inline:
    ```yaml
    - run: |
        docker run --rm -v "$PWD:/work" -w /work shuwariafrica/alpine-jdk:21 \
          sh -c 'sbt test'
    ```

On `linux/amd64` the issue does not apply and `alpine-jdk` works as a `container:` normally.
