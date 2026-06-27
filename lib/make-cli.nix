{ pkgs }:
let
  lib = pkgs.lib;
in
{
  /*
    cli - Create a nice multi-command CLI from a declarative spec

    Example:
    jist.cli pkgs {
      name = "mytool";
      desc = "My awesome tool";
      scripts = [ ... ];
    }
  */
  cli = { name, scripts, desc ? "${name} - CLI tool", ... }:
    let
      visibleScripts = builtins.filter (s: s.visible or true) scripts;

      formatCmds = cmds:
        let list = if builtins.isList cmds then cmds else [ cmds ];
        in builtins.concatStringsSep " && " list;

      genScriptCase = s: ''
        "${s.cmd}")
          ${lib.optionalString (s ? deps) ''
            # Run dependencies
            ${builtins.concatStringsSep "\n" (map (dep: ''"$0" "${dep}"'') s.deps)}
          ''}

          ${lib.optionalString (s ? dir) ''
            pushd "${s.dir}" >/dev/null || exit 1
          ''}

          # Main execution
          set -x
          ${formatCmds s.exec} "''${@:2}"
          EXIT_CODE=$?
          { set +x; } 2>/dev/null

          ${lib.optionalString (s ? dir) "popd >/dev/null"}
          [ $EXIT_CODE -eq 0 ] || exit $EXIT_CODE
          ;;
      '';

      dispatcher = ''
        #!/usr/bin/env bash
        set -euo pipefail

        PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

        # Nice gray trace output
        export PS4='$(tput setaf 8 2>/dev/null)+ $(tput sgr0 2>/dev/null)'

        run_cmd() {
          cd "$PROJECT_ROOT" || exit 1

          case "$1" in
            ${builtins.concatStringsSep "\n" (map genScriptCase scripts)}
            *)
              echo "Error: Unknown command '$1'" >&2
              echo "Run '${name}' with no arguments to see available commands." >&2
              exit 1
              ;;
          esac
        }

        case "''${1:-}" in
          "")
            # Help / menu
            bold=$(tput bold 2>/dev/null || echo "")
            reset=$(tput sgr0 2>/dev/null || echo "")
            cyan=$(tput setaf 6 2>/dev/null || echo "")
            green=$(tput setaf 2 2>/dev/null || echo "")

            printf "%s%s🚀 %s%s\n" "$bold" "$cyan" "${desc}" "$reset"
            ${builtins.concatStringsSep "\n" (map (s: ''
              printf "  %s${name} %-12s%s  ${s.desc}\n" "$green" "${s.cmd}" "$reset"
            '') visibleScripts)}
            ;;
          *)
            run_cmd "$@"
            ;;
        esac
      '';
    in
    pkgs.symlinkJoin {
      inherit name;
      paths = [ (pkgs.writeShellScriptBin name dispatcher) ];
      meta = {
        description = desc;
        mainProgram = name;
        homepage = "https://github.com/YOURUSERNAME/jist";
        platforms = lib.platforms.all;
      };
    };
}
