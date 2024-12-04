# https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/misc/ollama.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;

  cfg = config.services.ollama;
in
{
  options = {
    services.ollama = {
      enable = lib.mkEnableOption "ollama server for local large language models";
      package = lib.mkPackageOption pkgs "ollama" { };

      home = lib.mkOption {
        type = types.str;
        default = "/var/lib/ollama";
        example = "/home/foo";
        description = ''
          The home directory that the ollama service is started in.
        '';
      };
      models = lib.mkOption {
        type = types.str;
        default = "${cfg.home}/models";
        defaultText = "\${config.services.ollama.home}/models";
        example = "/path/to/ollama/models";
        description = ''
          The directory that the ollama service will read models from and download new models to.
        '';
      };

      host = lib.mkOption {
        type = types.str;
        default = "127.0.0.1";
        example = "[::]";
        description = ''
          The host address which the ollama server HTTP interface listens to.
        '';
      };
      port = lib.mkOption {
        type = types.port;
        default = 11434;
        example = 11111;
        description = ''
          Which port the ollama server listens to.
        '';
      };

      environmentVariables = lib.mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          OLLAMA_LLM_LIBRARY = "cpu";
          HIP_VISIBLE_DEVICES = "0,1";
        };
        description = ''
          Set arbitrary environment variables for the ollama service.

          Be aware that these are only seen by the ollama server (systemd service),
          not normal invocations like `ollama run`.
          Since `ollama run` is mostly a shell around the ollama server, this is usually sufficient.
        '';
      };
      loadModels = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Download these models using `ollama pull` as soon as `ollama.service` has started.

          This creates a systemd unit `ollama-model-loader.service`.

          Search for models of your choice from: https://ollama.com/library
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.ollama = {
      description = "Server for local large language models";
      wantedBy = [ "system-manager.target" ];
      after = [ "network.target" ];
      environment = cfg.environmentVariables // {
        HOME = cfg.home;
        OLLAMA_MODELS = cfg.models;
        OLLAMA_HOST = "${cfg.host}:${toString cfg.port}";
      };
      serviceConfig = {
        Type = "exec";
        DynamicUser = true;
        ExecStart = "${lib.getExe cfg.package} serve";
        WorkingDirectory = cfg.home;
        StateDirectory = [ "ollama" ];
        ReadWritePaths = [
          cfg.home
          cfg.models
        ];

        CapabilityBoundingSet = [ "" ];
        DeviceAllow = [
          # CUDA
          # https://docs.nvidia.com/dgx/pdf/dgx-os-5-user-guide.pdf
          "char-nvidiactl"
          "char-nvidia-caps"
          "char-nvidia-frontend"
          "char-nvidia-uvm"
          # ROCm
          "char-drm"
          "char-kfd"
        ];
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = false; # hides acceleration devices
        PrivateTmp = true;
        PrivateUsers = true;
        ProcSubset = "all"; # /proc/meminfo
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        SupplementaryGroups = [ "render" ]; # for rocm to access /dev/dri/renderD* devices
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service @resources"
          "~@privileged"
        ];
        UMask = "0077";
      };
    };

    systemd.services.ollama-model-loader = lib.mkIf (cfg.loadModels != [ ]) {
      description = "Download ollama models in the background";
      wantedBy = [
        "system-manager.target"
        "ollama.service"
      ];
      after = [ "ollama.service" ];
      bindsTo = [ "ollama.service" ];
      environment = config.systemd.services.ollama.environment;
      serviceConfig = {
        Type = "exec";
        DynamicUser = true;
        Restart = "on-failure";
        # bounded exponential backoff
        RestartSec = "1s";
        RestartMaxDelaySec = "2h";
        RestartSteps = "10";
      };

      script = ''
        total=${toString (builtins.length cfg.loadModels)}
        failed=0

        for model in ${lib.escapeShellArgs cfg.loadModels}; do
          '${lib.getExe cfg.package}' pull "$model" &
        done

        for job in $(jobs -p); do
          set +e
          wait $job
          exit_code=$?
          set -e

          if [ $exit_code != 0 ]; then
            failed=$((failed + 1))
          fi
        done

        if [ $failed != 0 ]; then
          echo "error: $failed out of $total attempted model downloads failed" >&2
          exit 1
        fi
      '';
    };
  };
}
