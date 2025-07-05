{
  description = "A basic flake with a shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    devDB = {
      url = "github:hermann-p/nix-postgres-dev-db";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, flake-utils, devDB, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        db = devDB.outputs.packages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [ pkgs.bashInteractive ];
          buildInputs = with pkgs; [
            R
            postgresql_15
            db.start-database
            db.stop-database
            db.psql-wrapped
            pgadmin4-desktopmode
            dbeaver-bin
            quarto
            chromium
            pandoc
            texlive.combined.scheme-full
            rstudio
            (with rPackages; [
              quarto
              pagedown
              tidyverse
              bench
              desc
              downlit
              ggbeeswarm
              gapminder
              janitor
              gt
              gtsummary
              lobstr
              memoise
              png
              palmerpenguins
              profvis
              R6
              dbplyr
              RPostgres
              Rcpp
              sessioninfo
              sloop
              testthat
              zeallot
              RSQLite
              bookdown
            ])
          ];
          shellHook = ''
            export PG_ROOT=$(git rev-parse --show-toplevel)
          '';
        };
      }
    );
}
