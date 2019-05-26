{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.holochain;

  inherit (config.users.users.holochain) home;

  defaults = {
    agents = [];
    dnas = [];
    instances = [];
    interfaces = [];
    bridges = [];

    logger.type = "debug";

    persistence_dir = home;
  };

  config = defaults // cfg.config;

  json = pkgs.writeText "dnscrypt-proxy.json" (builtins.toJSON config);

  toml = pkgs.runCommand "dnscrypt-proxy.toml" {} ''
    ${pkgs.remarshal}/bin/json2toml < ${json} > $out
  '';
in

{
  options.services.holochain = {
    enable = mkEnableOption "Holochain conductor";

    config = mkOption {
      type = types.attrs;
    };

    package = mkOption {
      default = pkgs.holochain;
      type = types.package;
    };
  };

  config = {
    environment.systemPackages = with pkgs; [
      holochain-cli
    ];

    systemd.services.holochain = {
      after = [ "local-fs.target" "network.target" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [ n3h ];

      # TODO: This is extremely dangerous and should never be run by end user!
      # This should be fixed upstream by separating state from config. If this
      # warning is ignored, we will never, ever be able to change this config
      # without resetting user's HoloPort to factory settings, which frankly
      # would make running NixOS pointless.
      preStart = ''
        if [ ! -e ${home}/config.toml ]; then
          cat ${toml} > ${home}/config.toml
	fi
      '';
    
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/holochain -c ${home}/config.toml";
        KillMode = "process";
        Restart = "always";
        User = "holochain";
      };
    };
    
    users.users.holochain = {
      createHome = true;
      home = "/var/lib/holochain";
    };
  };
}
