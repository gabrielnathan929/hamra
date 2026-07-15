{lib, ...}: {
  options.hamra.theme = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "studio-ghibli";
      description = "Tema do Hamra.";
    };

    wallpaper = lib.mkOption {
      type = lib.types.path;
      internal = true;
      default = ./studio-ghibli/wallpapers/wallpaper.jpg;
      description = "Caminho do wallpaper ativo, definido pelo tema.";
    };

    profileIcon = lib.mkOption {
      type = lib.types.path;
      internal = true;
      default = ./studio-ghibli/icons/profile.jpg;
      description = "Caminho do avatar de perfil ativo, definido pelo tema.";
    };
  };
}
