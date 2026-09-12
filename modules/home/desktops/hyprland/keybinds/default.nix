{
  config,
  lib,
  env,
  ...
}: let
  customPart = import ./custom {inherit config lib env;};
  surfacesPart = import ./surfaces {};
  systemPart = import ./system {};
  shellPart = import ./shell {};
  mediaPart = import ./media {};
in ''
  -- Noctalia v5

  ${customPart}

  ${surfacesPart}

  ${systemPart}

  ${shellPart}

  ${mediaPart}
''
