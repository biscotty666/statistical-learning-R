{
  description = "A basic flake with a shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/25.05";
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
        #pkgs = nixpkgs.legacyPackages.${system};
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
        db = devDB.outputs.packages.${system};
        myvscode = pkgs.vscode-with-extensions.override {
          vscodeExtensions = (with pkgs.vscode-extensions; [
          enkia.tokyo-night
          sainnhe.gruvbox-material
          vscodevim.vim
          reditorsupport.r
        ]);
      };
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [ pkgs.bashInteractive ];
          venvDir = "./.venv";
          buildInputs = with pkgs; [
            R
            myvscode
            postgresql_15
            db.start-database
            db.stop-database
            db.psql-wrapped
            pgadmin4-desktopmode
            dbeaver-bin
            quarto
            pyenv
            chromium
            pandoc
            texlive.combined.scheme-full
            rstudio
            radianWrapper
            jupyter-all
            (with rPackages; [
              BART
              GGally
              IRdisplay
              ISLR2
              MASS
              R6
              ROCR
              RPostgres
              RSQLite
              Rcpp
              TTR
              akima
              bench
              bookdown
              car
              coxed
              crayon
              dbplyr
              desc
              devtools
              digest
              downlit
              e1071
              evaluate
              forecast
              keras
              gam
              gapminder
              gbm
              ggbeeswarm
              ggfortify
              ggpubr
              glmnet
              gt
              gtsummary
              httpgd
              interp
              janitor
              languageserver
              leaps
              lintr
              lobstr
              memoise
              nortest
              pagedown
              palmerpenguins
              Rpdb
              pls
              png
              profvis
              quarto
              randomForest
              repr
              reticulate
              rstan
              scatterPlotMatrix
              sessioninfo
              sloop
              testthat
              tidyverse
              timetk
              tree
              uuid
              zeallot
            ])
          (python3.withPackages(ps: with ps; [
            ipython
            pip
            jupyter
            widgetsnbextension
            ipympl
            jupyter-nbextensions-configurator
            jedi-language-server
            keras
            tensorflow
            pandas
            numpy
            matplotlib
            quarto
          ]))
          ];
        postVenvCreation = ''
          unset SOURCE_DATE_EPOCH
          pip install -r requirements.txt
        '';

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
    export PIP_PREFIX=$(pwd)/venvDir
    export PYTHONPATH="$PIP_PREFIX/${pkgs.python3.sitePackages}:$PYTHONPATH"
    export PATH="$PIP_PREFIX/bin:$PATH"
    export QUARTO_PYTHON=$(pyenv which python)
     unset SOURCE_DATE_EPOCH
          '';
        postShellHook = ''
          # allow pip to install wheels
          unset SOURCE_DATE_EPOCH
        '';
        };
      }
    );
}
