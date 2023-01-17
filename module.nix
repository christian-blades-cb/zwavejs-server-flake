{ self } : { config, lib, pkgs, ... }:

let
  cfg = config.services.zwave-js;
in {
  options.services.zwave-js = {
    enable = lib.mkEnableOption "Enables zwave-js server";

    device = lib.mkOption rec {
      type = lib.types.path;
      default = "/dev/ttyACM0";
      example = default;
      description = "zwave device";
    };

    host = lib.mkOption rec {
      type = lib.types.str;
      default = "0.0.0.0";
      example = "127.0.0.1";
      description = "ip to bind the websocket";
    };

    port = lib.mkOption rec {
      type = lib.types.port;
      default = 3000;
      example = default;
      description = "port to bind the websocket";
    };

    mock = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "don't connect to a real zwave device";
    };

    dns-sd = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "enable the DNS-SD feature";
    };

    # settings = lib.mkOption rec {
    #   type = lib.types.attrs;
    #   default = {
    #     storage.cacheDir = "/var/lib/zwave-js";
    #   };
    #   example = default;
    #   description = "zwave-js settings, following the structure at https://zwave-js.github.io/node-zwave-js/#/api/driver?id=zwaveoptions";
    # };

  };

  config = lib.mkIf cfg.enable {
    users.users."zwave-js" = {
      isSystemUser = true;
      group = "dialout";
      extraGroups = [ "tty" ];
    };

    systemd.services."zwave-js-server" = {
      wantedBy = [ "multi-user.target" ];
      environment = { "ZWAVEJS_EXTERNAL_CONFIG" = "/var/lib/zwave-js/"; };

      serviceConfig = let
        pkg = self.packages.${pkgs.system}.default;
        # configFile = pkgs.writeText "config.json" (lib.strings.toJSON cfg.settings);
      in
        {
          Restart = "on-failure";
          ExecStart = "${pkg}/bin/zwave-server ${cfg.device} --host ${cfg.host} --port ${toString cfg.port}" +
                      (lib.optionalString cfg.mock " --mock-driver") +
                      (lib.optionalString (!cfg.dns-sd) " --disable-dns-sd");
          User = "zwave-js";
          Group = "dialout";
          RuntimeDirectory = "zwave-js";
          RuntimeDirectoryMode = "0755";
          StateDirectory = "zwave-js";
          StateDirectoryMode = "0700";
          CacheDirectory = "zwave-js";
          CacheDirectoryMode = "0750";
        };
    };
  };
}
