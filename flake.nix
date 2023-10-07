{
  nixConfig = {
    extra-substituters = [ "https://ai.cachix.org" ];
    extra-trusted-public-keys = [ "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc=" ];
  };

  description = "A Nix Flake that makes AI reproducible and easy to run";

  inputs = {
    nixpkgs = {
      url = github:nixos/nixpkgs/e35dcc04a3853da485a396bdd332217d0ac9054f;
    };
    invokeai-src = {
      url = "github:invoke-ai/InvokeAI/v2.3.1.post2";
      flake = false;
    };
    koboldai-src = {
      url = "github:koboldai/koboldai-client/1.19.2";
      flake = false;
    };
    textgen-src = {
      url = "github:oobabooga/text-generation-webui/main";
      flake = false;
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    hercules-ci-agent = {
      url = "github:hercules-ci/hercules-ci-agent";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    hercules-ci-effects = {
      url = "github:hercules-ci/hercules-ci-effects";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hercules-ci-agent.follows = "hercules-ci-agent";
      inputs.flake-parts.follows = "flake-parts";
    };
  };
  outputs = { flake-parts, invokeai-src, hercules-ci-effects, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      perSystem = { system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs { config.allowUnfree = true; inherit system; };
      };
      systems = [
        "x86_64-linux"
      ];
      debug = true;
      imports = [
        hercules-ci-effects.flakeModule
#        ./modules/nixpkgs-config
        ./overlays
        ./projects/invokeai
        ./projects/koboldai
        ./projects/textgen
        ./website
      ];
    };
}
