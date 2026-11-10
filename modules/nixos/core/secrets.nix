{
  lib,
  repoPath,
  ...
}: {
  options.hamra.secrets = {
    path = lib.mkOption {
      type = lib.types.path;
      description = "Path to the secrets directory (containing sops-encrypted files).";
    };
  };

  config.hamra.secrets.path = repoPath + "/secrets";
}
