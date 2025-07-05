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
              car
              desc
              downlit
              ggbeeswarm
              gapminder
              janitor
              gt
              gtsummary
              rstan
              lobstr
              memoise
              MASS
              ISLR2
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
  postgresConf =
    pkgs.writeText "postgresql.conf"
      ''
        # Add Custom Settings
        log_min_messages = warning
        log_min_error_statement = error
        log_min_duration_statement = 100  # ms
        log_connections = on
        log_disconnections = on
        log_duration = on
        #log_line_prefix = '[] '
        log_timezone = 'UTC'
        log_statement = 'all'
        log_directory = 'pg_log'
        log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
        logging_collector = on
        log_min_error_statement = error
      '';


  # ENV Variables
    #LD_LIBRARY_PATH = "${geos}/lib:${gdal}/lib";
  PGDATA = "./pg";

          shellHook = ''
            #export PG_ROOT=$(git rev-parse --show-toplevel)
    export PGHOST="$PGDATA"
    # Setup: DB
    [ ! -d $PGDATA ] && pg_ctl initdb -o "-U postgres" && cat "$postgresConf" >> $PGDATA/postgresql.conf
    pg_ctl -o "-p 5555 -k $PGDATA" start
    alias fin="pg_ctl stop && exit"
    alias pg="psql -p 5555 -U postgres"
          '';
        };
      }
    );
}
