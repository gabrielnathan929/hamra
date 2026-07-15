_: let
  notificationsPart = import ./notifications.nix {};
  clipboardPart = import ./clipboard.nix {};
  playbackPart = import ./playback.nix {};
  wallpaperPart = import ./wallpaper.nix {};
  screenshotsPart = import ./screenshots.nix {};
in ''
  ${notificationsPart}
  ${clipboardPart}
  ${playbackPart}
  ${wallpaperPart}
  ${screenshotsPart}
''
