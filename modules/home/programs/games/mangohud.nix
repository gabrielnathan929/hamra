{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.home.programs.games.mangohud;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.games.mangohud = mkOption {
    type = types.bool;
    default = false;
    description = "Enable MangoHud configuration (overlay stats, layout and keybindings, requires the games.mangohud package).";
  };

  config = mkIf cfg {
    xdg.configFile."MangoHud/MangoHud.conf" = {
      force = true;
      text = ''
        legacy_layout=0
        position=top-left
        text_color=FFFFFF
        background_alpha=0.5

        fps
        frametime
        frame_timing
        cpu_stats
        cpu_temp
        gpu_stats
        gpu_temp
        vram
        ram

        toggle_hud=Shift_R+F2
        toggle_hud_position=Shift_R+F3
        toggle_logging=Shift_R+F1
      '';
    };
  };
}
