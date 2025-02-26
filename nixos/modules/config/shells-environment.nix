# This module defines a global environment configuration and
# a common configuration for all shells.

{ config, lib, utils, pkgs, ... }:

with lib;

let

  cfg = config.environment;

  exportedEnvVars =
    let
      absoluteVariables =
        mapAttrs (n: toList) cfg.variables;

      suffixedVariables =
        flip mapAttrs cfg.profileRelativeEnvVars (envVar: listSuffixes:
          concatMap (profile: map (suffix: "${profile}${suffix}") listSuffixes) cfg.profiles
        );

      allVariables =
        zipAttrsWith (n: concatLists) [ absoluteVariables suffixedVariables ];

      exportVariables =
        mapAttrsToList (n: v: ''export ${n}="${concatStringsSep ":" v}"'') allVariables;
    in
      concatStringsSep "\n" exportVariables;
in

{

  options = {

    environment.variables = mkOption {
      default = {};
      example = { EDITOR = "nvim"; VISUAL = "nvim"; };
      description = lib.mdDoc ''
        A set of environment variables used in the global environment.
        These variables will be set on shell initialisation (e.g. in /etc/profile).
        The value of each variable can be either a string or a list of
        strings.  The latter is concatenated, interspersed with colon
        characters.
      '';
      type = with types; attrsOf (oneOf [ str path (listOf str) ]);
      apply = mapAttrs (n: v: if isList v then concatStringsSep ":" v else "${v}");
    };

    environment.profiles = mkOption {
      default = [];
      description = lib.mdDoc ''
        A list of profiles used to setup the global environment.
      '';
      type = types.listOf types.str;
    };

    environment.profileRelativeEnvVars = mkOption {
      type = types.attrsOf (types.listOf types.str);
      example = { PATH = [ "/bin" ]; MANPATH = [ "/man" "/share/man" ]; };
      description = lib.mdDoc ''
        Attribute set of environment variable.  Each attribute maps to a list
        of relative paths.  Each relative path is appended to the each profile
        of {option}`environment.profiles` to form the content of the
        corresponding environment variable.
      '';
    };

    # !!! isn't there a better way?
    environment.extraInit = mkOption {
      default = "";
      description = lib.mdDoc ''
        Shell script code called during global environment initialisation
        after all variables and profileVariables have been set.
        This code is assumed to be shell-independent, which means you should
        stick to pure sh without sh word split.
      '';
      type = types.lines;
    };

    environment.shellInit = mkOption {
      default = "";
      description = lib.mdDoc ''
        Shell script code called during shell initialisation.
        This code is assumed to be shell-independent, which means you should
        stick to pure sh without sh word split.
      '';
      type = types.lines;
    };

    environment.loginShellInit = mkOption {
      default = "";
      description = lib.mdDoc ''
        Shell script code called during login shell initialisation.
        This code is assumed to be shell-independent, which means you should
        stick to pure sh without sh word split.
      '';
      type = types.lines;
    };

    environment.interactiveShellInit = mkOption {
      default = "";
      description = lib.mdDoc ''
        Shell script code called during interactive shell initialisation.
        This code is assumed to be shell-independent, which means you should
        stick to pure sh without sh word split.
      '';
      type = types.lines;
    };

    environment.shellAliases = mkOption {
      example = { l = null; ll = "ls -l"; };
      description = lib.mdDoc ''
        An attribute set that maps aliases (the top level attribute names in
        this option) to command strings or directly to build outputs. The
        aliases are added to all users' shells.
        Aliases mapped to `null` are ignored.
      '';
      type = with types; attrsOf (nullOr (either str path));
    };

    environment.homeBinInPath = mkOption {
      description = lib.mdDoc ''
        Include ~/bin/ in $PATH.
      '';
      default = false;
      type = types.bool;
    };

    environment.localBinInPath = mkOption {
      description = lib.mdDoc ''
        Add ~/.local/bin/ to $PATH
      '';
      default = false;
      type = types.bool;
    };

    environment.binsh = mkOption {
      default = "${config.system.build.binsh}/bin/sh";
      defaultText = literalExpression ''"''${config.system.build.binsh}/bin/sh"'';
      example = literalExpression ''"''${pkgs.dash}/bin/dash"'';
      type = types.path;
      visible = false;
      description = lib.mdDoc ''
        The shell executable that is linked system-wide to
        `/bin/sh`. Please note that NixOS assumes all
        over the place that shell to be Bash, so override the default
        setting only if you know exactly what you're doing.
      '';
    };

    environment.shells = mkOption {
      default = [];
      example = literalExpression "[ pkgs.bashInteractive pkgs.zsh ]";
      description = lib.mdDoc ''
        A list of permissible login shells for user accounts.
        No need to mention `/bin/sh`
        here, it is placed into this list implicitly.
      '';
      type = types.listOf (types.either types.shellPackage types.path);
    };

  };

  config = {

    system.build.binsh = pkgs.bashInteractive;

    # Set session variables in the shell as well. This is usually
    # unnecessary, but it allows changes to session variables to take
    # effect without restarting the session (e.g. by opening a new
    # terminal instead of logging out of X11).
    environment.variables = config.environment.sessionVariables;

    environment.profileRelativeEnvVars = config.environment.profileRelativeSessionVariables;

    environment.shellAliases = mapAttrs (name: mkDefault) {
      ls = "ls --color=tty";
      ll = "ls -l";
      l  = "ls -alh";
    };

    environment.etc.shells.text =
      ''
        ${concatStringsSep "\n" (map utils.toShellPath cfg.shells)}
        /bin/sh
      '';

    # For resetting environment with `. /etc/set-environment` when needed
    # and discoverability (see motivation of #30418).
    environment.etc.set-environment.source = config.system.build.setEnvironment;

    system.build.setEnvironment = pkgs.writeText "set-environment"
      ''
        # DO NOT EDIT -- this file has been generated automatically.

        # Prevent this file from being sourced by child shells.
        export __NIXOS_SET_ENVIRONMENT_DONE=1

        ${exportedEnvVars}

        ${cfg.extraInit}

        ${optionalString cfg.homeBinInPath ''
          # ~/bin if it exists overrides other bin directories.
          export PATH="$HOME/bin:$PATH"
        ''}

        ${optionalString cfg.localBinInPath ''
          export PATH="$HOME/.local/bin:$PATH"
        ''}
      '';

    system.activationScripts.binsh = stringAfter [ "stdio" ]
      ''
        # Create the required /bin/sh symlink; otherwise lots of things
        # (notably the system() function) won't work.
        mkdir -m 0755 -p /bin
        ln -sfn "${cfg.binsh}" /bin/.sh.tmp
        mv /bin/.sh.tmp /bin/sh # atomically replace /bin/sh
      '';

  };

}
