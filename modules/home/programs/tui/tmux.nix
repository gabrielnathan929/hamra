{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.home.programs.tui.tmux;
  inherit (lib) mkOption mkIf types;

  keybinds = [
    {
      key = "PREFIX";
      action = "Ctrl + Space / Ctrl + B";
    }
    {
      key = "Prefix + q";
      action = "Reload configuration";
    }
    {
      key = "Prefix + ?";
      action = "Show Tmux keybindings";
    }
    {
      key = "Prefix + [";
      action = "Copy mode (vi)";
    }
    {
      key = "Copy + v";
      action = "Begin selection";
    }
    {
      key = "Copy + y";
      action = "Copy selection";
    }
    {
      key = "Alt + Enter";
      action = "Split pane vertically";
    }
    {
      key = "Alt + Shift + Enter";
      action = "Split pane horizontally";
    }
    {
      key = "Alt + Escape";
      action = "Kill pane";
    }
    {
      key = "Prefix + h";
      action = "Split pane vertically";
    }
    {
      key = "Prefix + v";
      action = "Split pane horizontally";
    }
    {
      key = "Prefix + x";
      action = "Kill pane";
    }
    {
      key = "Ctrl + Alt + Left";
      action = "Focus pane left";
    }
    {
      key = "Ctrl + Alt + Right";
      action = "Focus pane right";
    }
    {
      key = "Ctrl + Alt + Up";
      action = "Focus pane up";
    }
    {
      key = "Ctrl + Alt + Down";
      action = "Focus pane down";
    }
    {
      key = "Ctrl + Alt + Shift + Left";
      action = "Resize pane left";
    }
    {
      key = "Ctrl + Alt + Shift + Down";
      action = "Resize pane down";
    }
    {
      key = "Ctrl + Alt + Shift + Up";
      action = "Resize pane up";
    }
    {
      key = "Ctrl + Alt + Shift + Right";
      action = "Resize pane right";
    }
    {
      key = "Prefix + r";
      action = "Rename window";
    }
    {
      key = "Prefix + c";
      action = "Create window";
    }
    {
      key = "Prefix + k";
      action = "Kill window";
    }
    {
      key = "Alt + 1..9";
      action = "Switch to window 1-9";
    }
    {
      key = "Alt + Left";
      action = "Previous window";
    }
    {
      key = "Alt + Right";
      action = "Next window";
    }
    {
      key = "Alt + Shift + Left";
      action = "Move window left";
    }
    {
      key = "Alt + Shift + Right";
      action = "Move window right";
    }
    {
      key = "Prefix + Shift + r";
      action = "Rename session";
    }
    {
      key = "Prefix + Shift + c";
      action = "Create session";
    }
    {
      key = "Prefix + Shift + k";
      action = "Kill session";
    }
    {
      key = "Prefix + P";
      action = "Previous session";
    }
    {
      key = "Prefix + N";
      action = "Next session";
    }
    {
      key = "Alt + Up";
      action = "Previous session";
    }
    {
      key = "Alt + Down";
      action = "Next session";
    }
    {
      key = "Prefix + z";
      action = "Zoom pane (fullscreen)";
    }
  ];

  tmuxConf = ''
    set -g prefix C-Space
    set -g prefix2 C-b
    bind -N "Send prefix" C-Space send-prefix
    bind -N "Reload configuration" q source-file ~/.config/tmux/tmux.conf \; display "Configuration reloaded"
    bind -N "Show Tmux keybindings" ? display-popup -E -w 80% -h 70% -T "Tmux keybindings" "hamra-keybinds tmux | less -R"

    setw -g mode-keys vi
    bind -N "Begin selection" -T copy-mode-vi v send -X begin-selection
    bind -N "Copy selection" -T copy-mode-vi y send -X copy-selection-and-cancel

    bind -N "Split pane vertically" -n M-Enter split-window -v -c "#{pane_current_path}"
    bind -N "Split pane horizontally" -n M-S-Enter split-window -h -c "#{pane_current_path}"
    bind -N "Kill pane" -n M-Escape kill-pane

    bind -N "Split pane vertically" h split-window -v -c "#{pane_current_path}"
    bind -N "Split pane horizontally" v split-window -h -c "#{pane_current_path}"
    bind -N "Kill pane" x kill-pane

    bind -N "Focus pane left" -n C-M-Left select-pane -L
    bind -N "Focus pane right" -n C-M-Right select-pane -R
    bind -N "Focus pane up" -n C-M-Up select-pane -U
    bind -N "Focus pane down" -n C-M-Down select-pane -D

    bind -N "Resize pane left" -n C-M-S-Left resize-pane -L 5
    bind -N "Resize pane down" -n C-M-S-Down resize-pane -D 5
    bind -N "Resize pane up" -n C-M-S-Up resize-pane -U 5
    bind -N "Resize pane right" -n C-M-S-Right resize-pane -R 5

    bind -N "Rename window" r command-prompt -I "#W" "rename-window -- '%%'"
    bind -N "Create window" c new-window -c "#{pane_current_path}"
    bind -N "Kill window" k kill-window

    bind -N "Switch to window 1" -n M-1 select-window -t 1
    bind -N "Switch to window 2" -n M-2 select-window -t 2
    bind -N "Switch to window 3" -n M-3 select-window -t 3
    bind -N "Switch to window 4" -n M-4 select-window -t 4
    bind -N "Switch to window 5" -n M-5 select-window -t 5
    bind -N "Switch to window 6" -n M-6 select-window -t 6
    bind -N "Switch to window 7" -n M-7 select-window -t 7
    bind -N "Switch to window 8" -n M-8 select-window -t 8
    bind -N "Switch to window 9" -n M-9 select-window -t 9

    bind -N "Previous window" -n M-Left select-window -t -1
    bind -N "Next window" -n M-Right select-window -t +1
    bind -N "Move window left" -n M-S-Left swap-window -t -1 \; select-window -t -1
    bind -N "Move window right" -n M-S-Right swap-window -t +1 \; select-window -t +1

    bind -N "Rename session" R command-prompt -I "#S" "rename-session -- '%%'"
    bind -N "Create session" C new-session -c "#{pane_current_path}"
    bind -N "Kill session" K kill-session
    bind -N "Previous session" P switch-client -p
    bind -N "Next session" N switch-client -n

    bind -N "Previous session" -n M-Up switch-client -p
    bind -N "Next session" -n M-Down switch-client -n

    set -g default-terminal "tmux-256color"
    set -ag terminal-overrides ",*:RGB"
    set -g mouse on
    set -g base-index 1
    setw -g pane-base-index 1
    set -g renumber-windows on
    set -g history-limit 50000
    set -g escape-time 0
    set -g focus-events on
    set -g set-clipboard on
    set -g allow-passthrough on
    setw -g aggressive-resize on
    set -g detach-on-destroy off
    set -g extended-keys on
    set -g extended-keys-format csi-u
    set -ag terminal-features "xterm-kitty:extkeys"
    set -as terminal-features ",*:clipboard"

    set -g status-position top
    set -g status-interval 5
    set -g status-left-length 30
    set -g status-right-length 50
    set -g window-status-separator ""
    set -gw automatic-rename on
    set -gw automatic-rename-format '#{b:pane_current_path}'
    set -g set-titles on
    set -g set-titles-string '#h:#W'

    set -g status-style "bg=default,fg=default"
    set -g status-left "#[fg=black,bg=blue,bold] #S #[bg=default] "
    set -g status-right "#[fg=blue]#{?pane_in_mode,COPY ,}#{?client_prefix,PREFIX ,}#{?window_zoomed_flag,ZOOM ,}#[fg=brightblack]#h "
    set -g window-status-format "#[fg=brightblack] #I:#W "
    set -g window-status-current-format "#[fg=blue,bold] #I:#W "
    set -g pane-border-style "fg=brightblack"
    set -g pane-active-border-style "fg=blue"
    set -g message-style "bg=default,fg=blue"
    set -g message-command-style "bg=default,fg=blue"
    set -g mode-style "bg=blue,fg=black"
    setw -g clock-mode-colour blue
  '';
in {
  options.hamra.home.programs.tui.tmux = mkOption {
    type = types.bool;
    default = true;
    description = "Enable Tmux configuration (prefix Ctrl+Space, vi copy mode).";
  };

  config = mkIf cfg {
    xdg.configFile."tmux/tmux.conf" = {
      force = true;
      text = tmuxConf;
    };

    hamra.keybinds.tmux = keybinds;
  };
}
