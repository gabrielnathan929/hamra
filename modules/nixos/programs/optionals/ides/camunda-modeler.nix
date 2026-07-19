{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.ides."camunda-modeler";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.ides."camunda-modeler" = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Camunda Modeler (BPMN, DMN and CMMN modeling).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.camunda-modeler];
}
