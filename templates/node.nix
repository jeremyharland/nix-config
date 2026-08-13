# Drop this in a project as `flake.nix`, then `echo "use flake" > .envrc && direnv allow`
{
  description = "Node / TypeScript dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nodejs_22 # pin the major here — this is your .nvmrc replacement
            pnpm
            typescript
            nodePackages.typescript-language-server
          ];

          shellHook = ''
            # Keep global npm installs inside the project, not in ~/.npm
            export NPM_CONFIG_PREFIX="$PWD/.npm-global"
            export PATH="$PWD/node_modules/.bin:$NPM_CONFIG_PREFIX/bin:$PATH"
            echo "node $(node --version) / pnpm $(pnpm --version)"
          '';
        };
      });
}

# NOTE ON PACKAGES:
# Nix pins the *Node runtime*. Your npm/pnpm dependencies stay in
# package-lock.json / pnpm-lock.yaml as normal. Do not try to Nixify
# node_modules (node2nix, dream2nix) unless you have a specific reason —
# it's a large amount of work for little gain on an app codebase.
#
# Native modules (sharp, better-sqlite3, node-canvas) sometimes need
# extra system libs. Add them to `packages` above, e.g. vips, python3,
# pkg-config.
