## Container Images

OCI base container images used for Scala 3 / Scala Native development and compilation.

## Images

| Image                                 | Base                | libc  | Static linking |
| ------------------------------------- | ------------------- | ----- | -------------- |
| `shuwariafrica/el10-jdk:<jdk>`        | Oracle Linux 10     | glibc | No (dynamic)   |
| `shuwariafrica/alpine-jdk:<jdk>`      | Alpine Linux        | musl  | Yes            |
| `shuwariafrica/alpine-edge-jdk:<jdk>` | Alpine edge         | musl  | Yes            |
| `shuwariafrica/ubuntu26-jdk:<jdk>`    | Ubuntu 26.04        | glibc | No (dynamic)   |
| `shuwariafrica/fedora-jdk:<jdk>`      | Fedora (latest)     | glibc | No (dynamic)   |
| `shuwariafrica/rawhide-jdk:<jdk>`     | Fedora rawhide      | glibc | No (dynamic)   |
| `shuwariafrica/opensuse-jdk:<jdk>`    | openSUSE Tumbleweed | glibc | No (dynamic)   |

`JAVA_HOME` is `/opt/jdk` on every image.

## Supported JDK streams

Supported streams are `21` and `25` - the release and current LTS, matching the Scala CI's `JDK_RELEASE` and `JDK_CURRENT`. Every image ships its distribution's own OpenJDK; a stream a distribution does not ship has no tag.

| Base                        | 21     | 25  |
| --------------------------- | ------ | --- |
| Alpine (stable and edge)    | yes    | yes |
| Ubuntu 26.04                | yes    | yes |
| openSUSE Tumbleweed         | yes    | yes |
| Oracle Linux 10             | yes    | yes |
| Fedora (latest and rawhide) | **no** | yes |

#### Notes:

- The `jdks_*` lists in `docker-bake.hcl` are the authority for this table; CI builds what `docker buildx bake --print` renders, so an unsupported cell is never published. Establish a cell by installing the JDK package in the base image, and treat a cell as unsupported only when the package manager reports the name as unknown - openSUSE's mirrors fail downloads often enough to fake an absence.
- `sbt` is installed on every image from the pinned, checksum-verified release tarball (`SBT_VERSION`/`SBT_SHA256` in `docker-bake.hcl`).
- `sudo` is installed but grants nothing: no image defines any sudoers policy. Consumers that run as a non-root user supply their own.
- `docker-bake.hcl` is the single source for the build matrix, every version pin and every digest-pinned base image. A version stated anywhere else is a bug.
- The `<jdk>` tag is the JDK major version. All published tags are multi-arch (`linux/amd64` and `linux/arm64`) and carry BuildKit provenance and SBOM attestations.

## Keeping pins current

| Pin                                     | Maintained by                                               |
| --------------------------------------- | ----------------------------------------------------------- |
| `BASE_*` digests in `docker-bake.hcl`   | Renovate (`renovate.json` regex manager, docker datasource) |
| Action versions in `.github/workflows/` | Renovate (`helpers:pinGitHubActionDigests`)                 |
| `SBT_VERSION` **and** `SBT_SHA256`      | `.github/workflows/update-sbt-pin.yml`                      |
| Distribution packages inside the images | not pinned; the scheduled build re-resolves them            |

sbt is excluded from Renovate in `renovate.json`. The pin is a version and a tarball checksum, and deriving the second needs `postUpgradeTasks`, which the hosted Renovate app does not run - so a version-only bump would land a pin that cannot build. `update-sbt-pin.yml` moves both in one commit; `verify-pins.yml` independently re-derives the checksum on every pull request and fails if the two disagree.

Because the base digests are pinned, a scheduled rebuild is the only thing that picks up distribution package updates within a pinned base. The immutable-tag hash gates publishing, so a rebuild that resolves identical packages publishes nothing.

Each publish also produces an immutable tag `<jdk>-<short-hash>`, hashed over **both** architectures' installed-package manifests. Downstream consumers must reference immutable tags or digests, never the mutable `<jdk>` tag. Per-arch layers are pushed by digest unconditionally; the tagging step is what skips when the combined hash is already published for both platforms.

## Scope

These are intentionally minimal Scala Native build images - JDK, sbt, and the C/LLVM toolchain plus the libraries Scala Native links against.

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
