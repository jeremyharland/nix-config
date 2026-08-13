# Drop this in a project as `flake.nix`, then `echo "use flake" > .envrc && direnv allow`
{
  description = "Kotlin / JVM dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        jdk = pkgs.jdk21; # pin your JDK major here
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            jdk
            kotlin
            (gradle.override { java = jdk; }) # make sure gradle uses the same JDK
            kotlin-language-server
            ktlint
          ];

          shellHook = ''
            export JAVA_HOME="${jdk}"
            export GRADLE_USER_HOME="$PWD/.gradle"
            echo "JDK: $(java -version 2>&1 | head -n1)"
          '';
        };
      });
}

# NOTE ON THE JVM:
# This is the language ecosystem Nix handles best. The JDK is a single
# self-contained tree, and Gradle/Maven resolve their own dependencies
# from lockfiles — so Nix pins the toolchain and Gradle does the rest.
#
# IntelliJ: point Project SDK at the JDK the shell provides. Run
# `echo $JAVA_HOME` inside the shell and add that path manually, since
# IntelliJ won't see the direnv environment on its own. The
# "Direnv integration" plugin handles this if you'd rather it be automatic.
#
# Gradle toolchains: if your build.gradle.kts declares a
# `jvmToolchain(21)`, Gradle may try to auto-download a JDK. Set
# `org.gradle.java.installations.auto-download=false` in gradle.properties
# so it uses the Nix-provided one.
