{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dream2nix.url = "github:nix-community/dream2nix";
    zwavejs-src = {
      url = "github:zwave-js/zwave-js-server";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, gitignore, dream2nix, zwavejs-src }:
    {
      nixosModule = import ./module.nix { inherit self; };
      nixosConfigurations.container = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModule
          {
            services.zwave-js.enable = true;
            services.zwave-js.mock = true;

            boot.isContainer = true;

            users.users.admin = {
              isNormalUser = true;
              initialPassword = "admin";
              extraGroups = [ "wheel" ];
            };

            services.openssh.passwordAuthentication = true;
            services.openssh.enable = true;
            networking.firewall.allowedTCPPorts = [ 3000 ];
          }
        ];
      };
    } // dream2nix.lib.makeFlakeOutputs {
      systems = flake-utils.lib.defaultSystems;
      config.projectRoot = ./.;
      source = gitignore.lib.gitignoreSource zwavejs-src;
      # autoProjects = true;
      projects = ./projects.toml;
    };
}
