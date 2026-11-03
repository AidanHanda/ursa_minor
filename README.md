# Ursa Minor

Built because I wanted a quick tool that would let me update DNS entries with Dynamic IP addresses. This tool is somewhat hacky - I wrote it in an hour.

## Install

Install with `opam install ursa_minor.opam`

## Nix

The flake pins the compiler and dependencies in `flake.lock`:

```sh
nix build
nix run . -- -config config.sexp
nix develop
# Inside the development shell:
dune build
dune runtest
```

The default package uses OCaml 5.4. An experimental OxCaml variant rebuilds
the dependencies with OxCaml and its matching PPX libraries:

```sh
nix build .#oxcaml
nix develop .#oxcaml
```

`nix flake check` builds and tests the default package. OxCaml compatibility
is checked separately in CI and is not yet guaranteed.

## GitHub builds

Every push and pull request runs the [build workflow](https://github.com/AidanHanda/ursa_minor/actions/workflows/build.yml)
on macOS ARM64 and Linux x86_64. Each builds the flake, runs the Dune tests,
and checks the executable's help command. OxCaml runs on both platforms as
an experimental job; its failure does not block the standard OCaml builds.

Download artifacts from the workflow run's **Artifacts** section. Each contains
the executable archive, SHA-256 checksums, and a compressed Nix export of its
complete runtime closure. The executable requires its Nix runtime paths;
the archive alone is not a standalone installation. With Nix installed on
the matching platform, import the runtime and run the packaged executable:

```sh
gunzip -c ursa_minor-*.nix-export.gz | nix-store --import
"$(cat store-path.txt)/bin/ursa_minor" -help
```

Alternatively, build and run directly from GitHub with
`nix run github:AidanHanda/ursa_minor -- -config config.sexp`.

## Example Config

You can run with: `ursa_minor -config config.sexp`

Where `config.sexp` looks like
```
((Cloudflare (
  (apikey somekeyhere)
  (zone   example.com)
  (url    some.example.com)))
 (Cloudflare (
  (apikey somekeyhere)
  (zone   example.com)
  (url    another.example.com))))
```
