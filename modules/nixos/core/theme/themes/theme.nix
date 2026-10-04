{lib, ...}: {
  options.hamra.theme = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "dragon-ball";
      description = "Tema do Hamra.";
    };

    wallpaper = lib.mkOption {
      type = lib.types.path;
      internal = true;
      default = ./dragon-ball/wallpapers/dragon-ball-01.jpg;
      description = "Caminho do wallpaper ativo, definido pelo tema.";
    };

    profileIcon = lib.mkOption {
      type = lib.types.path;
      internal = true;
      default = ./dragon-ball/icons/dragon-ball-profile.jpg;
      description = "Caminho do avatar de perfil ativo, definido pelo tema.";
    };

    videosDir = lib.mkOption {
      type = lib.types.path;
      internal = true;
      default = ./dragon-ball/videos;
      description = "Diretório de vídeos do tema ativo, definido pelo tema.";
    };
  };
}
