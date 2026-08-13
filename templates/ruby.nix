# Drop this in a project as `flake.nix`, then `echo "use flake" > .envrc && direnv allow`
#
# READ THE NOTE AT THE BOTTOM BEFORE COMMITTING TO THIS.
{
  description = "Ruby dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        ruby = pkgs.ruby_3_3; # pin your Ruby here
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            ruby
            bundler

            # Build deps for the native gems that always break:
            pkg-config
            openssl
            libyaml      # psych
            libffi       # ffi
            libxml2      # nokogiri
            libxslt      # nokogiri
            zlib
            readline
            postgresql   # pg gem — supplies pg_config
            # sqlite      # uncomment if you use the sqlite3 gem
            # vips        # uncomment for image_processing
          ];

          shellHook = ''
            # Keep gems inside the project so they can't collide across repos
            export BUNDLE_PATH="$PWD/.bundle"
            export GEM_HOME="$PWD/.bundle"
            export PATH="$GEM_HOME/bin:$PATH"

            # Point native gem builds at the Nix-provided libraries
            export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.libyaml.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
            export BUNDLE_BUILD__NOKOGIRI="--use-system-libraries"

            echo "ruby $(ruby --version)"
          '';
        };
      });
}

# ---------------------------------------------------------------------
# HONEST NOTE ON RUBY UNDER NIX
# ---------------------------------------------------------------------
# Ruby is the weakest of your three stacks on Nix, and it's the one most
# likely to cost you a frustrating afternoon.
#
# Why: many popular gems compile C extensions at `bundle install` time and
# expect a conventional FHS layout (/usr/lib, /usr/include). Nix has no such
# layout, so each of these gems needs its libraries wired up explicitly —
# the BUNDLE_BUILD__* and PKG_CONFIG_PATH lines above are examples. Every
# new native gem is a potential new line.
#
# Common offenders: nokogiri, pg, mysql2, ffi, sassc, grpc, libv8/mini_racer,
# ruby-vips, sqlite3, curb, therubyracer.
#
# Two reasonable positions:
#
#   1. Push through. Use this flake and add libs as gems break. Once it
#      works it's fully reproducible, which is the whole point.
#
#   2. Keep Ruby outside Nix. Leave mise (or rbenv) managing Ruby only,
#      and use Nix for everything else. This is not a defeat — plenty of
#      people run exactly this hybrid deliberately. If you take this route,
#      add `mise` to home.nix's home.packages and let it own ~/.mise.toml.
#
# My suggestion: migrate Node and JVM to Nix first, since those are
# low-friction and will prove out the whole setup. Leave Ruby on mise for
# a few weeks. Then attempt the Ruby migration as a separate, contained
# piece of work when your machine is otherwise fully working — not during
# the laptop switch.
