{lib, ...}: {
  options.hamra.theme = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "evangelion";
      description = "Tema do Hamra.";
    };

    wallpaper = lib.mkOption {
      type = lib.types.path;
      internal = true;
      default = ./evangelion/wallpapers/evangelion-01.jpg;
      description = "Caminho do wallpaper ativo, definido pelo tema.";
    };

    profileIcon = lib.mkOption {
      type = lib.types.path;
      internal = true;
      default = ./evangelion/icons/evangelion-profile-1.jpg;
      description = "Caminho do avatar de perfil ativo, definido pelo tema.";
    };

    videosDir = lib.mkOption {
      type = lib.types.path;
      internal = true;
      default = ./evangelion/videos;
      description = "Diretório de vídeos do tema ativo, definido pelo tema.";
    };
  };
}
