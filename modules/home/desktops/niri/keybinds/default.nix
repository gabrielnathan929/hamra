{
  config,
  lib,
  env,
  pkgs,
  ...
}: let
  customPart = import ./custom {inherit config lib env pkgs;};
  surfacesPart = import ./surfaces {};
  systemPart = import ./system {};
  shellPart = import ./shell {};
  mediaPart = import ./media {};
in ''
  // Noctalia v5
  binds {
    ${customPart}

    ${surfacesPart}

    ${systemPart}

    ${shellPart}

    ${mediaPart}
  }
''
