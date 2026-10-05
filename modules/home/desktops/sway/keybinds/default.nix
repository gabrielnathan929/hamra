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
  shellPart = import ./shell {inherit pkgs;};
  mediaPart = import ./media {};
in ''
  set $ipc noctalia msg

  ${customPart}

  ${surfacesPart}

  ${systemPart}

  ${shellPart}

  ${mediaPart}
''
