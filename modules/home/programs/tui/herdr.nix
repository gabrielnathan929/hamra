{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.home.programs.tui.herdr;
  inherit (lib) mkOption mkIf types;

  keybinds = [
    {
      key = "PREFIX";
      action = "Ctrl + Space";
    }
    {
      key = "Prefix + q";
      action = "Reload config";
    }
    {
      key = "Prefix + ?";
      action = "Help";
    }
    {
      key = "Prefix + d";
      action = "Detach";
    }
    {
      key = "Prefix + [";
      action = "Copy mode";
    }
    {
      key = "Prefix + h / Alt + Enter";
      action = "Split horizontal";
    }
    {
      key = "Prefix + v / Alt + Shift + Enter";
      action = "Split vertical";
    }
    {
      key = "Prefix + x / Alt + Escape";
      action = "Close pane";
    }
    {
      key = "Prefix + z";
      action = "Zoom pane";
    }
    {
      key = "Prefix + ;";
      action = "Last pane";
    }
    {
      key = "Ctrl + Alt + Left/Down/Up/Right";
      action = "Focus pane";
    }
    {
      key = "Prefix + Ctrl + Arrows";
      action = "Resize mode";
    }
    {
      key = "Ctrl + Alt + Shift + Left/Down/Up/Right";
      action = "Resize pane";
    }
    {
      key = "Prefix + Shift + o";
      action = "Rename pane";
    }
    {
      key = "Prefix + c";
      action = "New tab";
    }
    {
      key = "Prefix + r";
      action = "Rename tab";
    }
    {
      key = "Prefix + k";
      action = "Close tab";
    }
    {
      key = "Prefix + 1..9 / Alt + 1..9";
      action = "Switch tab";
    }
    {
      key = "Prefix + p / Alt + Left";
      action = "Previous tab";
    }
    {
      key = "Prefix + n / Alt + Right";
      action = "Next tab";
    }
    {
      key = "Alt + Shift + Left";
      action = "Move tab previous";
    }
    {
      key = "Alt + Shift + Right";
      action = "Move tab next";
    }
    {
      key = "Prefix + Shift + c";
      action = "New workspace";
    }
    {
      key = "Prefix + Shift + r";
      action = "Rename workspace";
    }
    {
      key = "Prefix + Shift + k";
      action = "Close workspace";
    }
    {
      key = "Prefix + Shift + p / Alt + Up";
      action = "Previous workspace";
    }
    {
      key = "Prefix + Shift + n / Alt + Down";
      action = "Next workspace";
    }
  ];

  herdrConfig = ''
    [theme]
    name = "terminal"

    [theme.custom]
    panel_bg = "black"

    [terminal]
    new_cwd = "follow"

    [keys]
    prefix = "ctrl+space"
    reload_config = "prefix+q"
    help = "prefix+?"
    detach = "prefix+d"
    copy_mode = "prefix+["
    split_horizontal = ["prefix+h", "alt+enter"]
    split_vertical = ["prefix+v", "alt+shift+enter"]
    close_pane = ["prefix+x", "alt+esc"]
    zoom = "prefix+z"
    last_pane = "prefix+;"
    focus_pane_left = "ctrl+alt+left"
    focus_pane_down = "ctrl+alt+down"
    focus_pane_up = "ctrl+alt+up"
    focus_pane_right = "ctrl+alt+right"
    resize_mode = ["prefix+ctrl+left", "prefix+ctrl+down", "prefix+ctrl+up", "prefix+ctrl+right"]
    resize_pane_left = "ctrl+alt+shift+left"
    resize_pane_down = "ctrl+alt+shift+down"
    resize_pane_up = "ctrl+alt+shift+up"
    resize_pane_right = "ctrl+alt+shift+right"
    rename_pane = "prefix+shift+o"
    new_tab = "prefix+c"
    rename_tab = "prefix+r"
    close_tab = "prefix+k"
    switch_tab = ["prefix+1..9", "alt+1..9"]
    previous_tab = ["prefix+p", "alt+left"]
    next_tab = ["prefix+n", "alt+right"]
    move_tab_previous = "alt+shift+left"
    move_tab_next = "alt+shift+right"
    new_workspace = "prefix+shift+c"
    rename_workspace = "prefix+shift+r"
    close_workspace = "prefix+shift+k"
    previous_workspace = ["prefix+shift+p", "alt+up"]
    next_workspace = ["prefix+shift+n", "alt+down"]

    [ui]
    accent = "blue"
    pane_gaps = false
    pane_outer_borders = false
    pane_scrollbars = false
    confirm_close = false
    prompt_new_tab_name = false
    mouse_capture = true
    tab_bar_right = [{ type = "zoom" }, { type = "hostname" }]
    window_title = "{hostname}: {workspace}"
  '';
in {
  options.hamra.home.programs.tui.herdr = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Herdr terminal workspace manager configuration (mirrors the Tmux keybinds).";
  };

  config = mkIf cfg {
    xdg.configFile."herdr/config.toml" = {
      force = true;
      text = herdrConfig;
    };

    hamra.keybinds.herdr = keybinds;
  };
}
