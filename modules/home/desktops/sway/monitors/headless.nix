{
  displays,
  lib,
}: let
  headlessDisplays = displays.headless or {};
  firstHeadless = lib.head (builtins.attrValues headlessDisplays);
  cfg = firstHeadless;
in
  if headlessDisplays == {}
  then ""
  else ''
    # Output headless do SwayFX
    #
    # O backend headless do wlroots nomeia automaticamente os outputs como
    # HEADLESS-1, HEADLESS-2, etc. O primeiro é criado na inicialização
    # quando WLR_BACKENDS inclui "headless".
    #
    # A resolução, posição e escala vêm de hamra.displays.headless.
    #
    output "HEADLESS-1" {
      mode ${cfg.mode}${lib.optionalString (lib.hasInfix "@" cfg.mode) "Hz"}
      position ${lib.replaceStrings ["x"] [" "] cfg.position}
      scale ${toString cfg.scale}
    }
  ''
