{
  lib,
  pkgs,
  env,
  ...
}: let
  customPart = import ./custom {inherit lib pkgs env;};
  surfacesPart = import ./surfaces {};
  systemPart = import ./system {};
  shellPart = import ./shell {inherit pkgs;};
  mediaPart = import ./media {};
in ''
  -- Noctalia v5

  ${customPart}

  ${surfacesPart}

  ${systemPart}

  ${shellPart}

  ${mediaPart}
''
