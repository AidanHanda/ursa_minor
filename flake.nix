{
  description = "Ursa Minor dynamic DNS updater";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    oxcaml.url = "github:oxcaml/oxcaml";
    oxcaml.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, oxcaml }:
    let
      systems = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      perSystem = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          compiler = (oxcaml.packages.${system}.oxcaml.override {
            withMerlin = false;
            withJsoo = false;
          }).overrideAttrs (old: {
            # The bootstrap builds ocamltest even for downstream consumers.
            # Keep its configure support enabled, but skip the compiler's own
            # full regression suite. Ursa Minor still runs its tests below.
            doCheck = false;
            passthru = (old.passthru or { }) // {
              nativeCompilers = true;
            };
            meta = (old.meta or { }) // {
              platforms = systems;
              license = pkgs.lib.licenses.lgpl21Only;
            };
          });
          # OxCaml's AST differs from upstream OCaml. Use the matching PPX
          # libraries shipped with its source rather than nixpkgs' vanilla ones.
          oxPpx = pkgs.runCommand "oxcaml-ppx-libraries" {
            version = "0.33.0";
          } ''
            mkdir -p "$out/lib/ocaml/${compiler.version}/site-lib"
            for library in ${compiler.mkPpxlibLibs compiler}/lib/*; do
              ln -s "$library" "$out/lib/ocaml/${compiler.version}/site-lib/"
            done
          '';
          oxPackages = (pkgs.ocaml-ng.mkOcamlPackages compiler).overrideScope (_: _: {
            ppxlib = oxPpx;
            ppxlib_jane = oxPpx;
            ocaml-compiler-libs = oxPpx;
            ppx_derivers = oxPpx;
            stdlib-shims = oxPpx;
          });
          mkPackage = ocamlPackages: ocamlPackages.buildDunePackage {
            pname = "ursa_minor";
            version = "0.1.0";
            duneVersion = "3";
            src = pkgs.lib.fileset.toSource {
              root = ./.;
              fileset = pkgs.lib.fileset.unions [
                ./dune-project ./ursa_minor.opam ./bin ./lib ./test
              ];
            };
            buildInputs = with ocamlPackages; [
              core async core_unix async_ssl cohttp-async jsonaf ppx_jane ppx_jsonaf_conv
            ];
            doCheck = true;
            meta = {
              description = "Update Cloudflare DNS records with the current public IP";
              homepage = "https://github.com/AidanHanda/ursa_minor";
              mainProgram = "ursa_minor";
              platforms = systems;
            };
          };
          package = mkPackage pkgs.ocaml-ng.ocamlPackages_5_4;
          oxPackage = mkPackage oxPackages;
          mkShell = package: pkgs.mkShell {
            inputsFrom = [ package ];
            packages = [ pkgs.ocamlformat ];
          };
        in {
          packages = {
            default = package;
            ursa_minor = package;
            oxcaml = oxPackage;
          };
          checks = { ursa_minor = package; };
          devShells = {
            default = mkShell package;
            oxcaml = mkShell oxPackage;
          };
          formatter = pkgs.nixfmt;
        };
    in {
      packages = forAllSystems (system: (perSystem system).packages);
      checks = forAllSystems (system: (perSystem system).checks);
      devShells = forAllSystems (system: (perSystem system).devShells);
      formatter = forAllSystems (system: (perSystem system).formatter);
    };
}
