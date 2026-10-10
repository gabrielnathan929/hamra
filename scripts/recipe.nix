{
  answersFile,
  repoPath,
}: let
  answers = builtins.fromJSON (builtins.readFile (/. + answersFile));
  repo = /. + repoPath;

  flake = builtins.getFlake (toString repo);
  lib = flake.inputs.nixpkgs.lib;
  hamraLib = import (toString flake.outPath + "/modules/lib") {inherit lib;};

  loadNixosModule = f:
    import f {
      config = {};
      inherit lib;
      pkgs = {};
      hostName = "cookiecutter";
      inherit (flake) inputs self;
      inherit hamraLib;
    };
  loadHomeModule = f:
    import f {
      config = {};
      inherit lib;
      pkgs = {};
    };

  walk = prefix: node:
    if builtins.isAttrs node && (node._type or "") == "option"
    then [
      {
        inherit prefix;
        default = node.default or null;
      }
    ]
    else if builtins.isAttrs node
    then lib.concatLists (lib.mapAttrsToList (n: v: walk (prefix ++ [n]) v) node)
    else [];

  categoryDirs = base: let
    entries = builtins.readDir base;
  in
    lib.filter (n: entries.${n} == "directory") (lib.naturalSort (builtins.attrNames entries));

  moduleFiles = base:
    lib.concatMap (cat: let
      dir = base + "/${cat}";
    in
      map (f: dir + "/${f}")
      (lib.filter (n: lib.hasSuffix ".nix" n && n != "default.nix")
        (builtins.attrNames (builtins.readDir dir))))
    (categoryDirs base);

  collectToggles = tree: entries: let
    step = acc: e: let
      p = e.prefix;
      d = e.default;
    in
      if lib.length p < 4 || lib.take 2 p != ["programs" tree]
      then acc // {skipped = acc.skipped ++ [("hamra." + lib.concatStringsSep "." p)];}
      else let
        cat = lib.elemAt p 2;
        app = lib.concatStringsSep "." (lib.drop 3 p);
      in
        if !builtins.isBool d
        then throw "toggle ${tree}.${cat}.${app} has non-bool default ${toString d} — cookiecutter only generates bool toggles"
        else acc // {toggles = acc.toggles // {${cat} = (acc.toggles.${cat} or {}) // {${app} = d;};};};
  in
    lib.foldl step {
      toggles = {};
      skipped = [];
    }
    entries;

  coreUniverse =
    collectToggles "core"
    (lib.concatMap (f: walk [] (loadNixosModule f).options.hamra)
      (moduleFiles (repo + "/modules/nixos/programs/core")));
  optionalsUniverse =
    collectToggles "optionals"
    (lib.concatMap (f: walk [] (loadNixosModule f).options.hamra)
      (moduleFiles (repo + "/modules/nixos/programs/optionals")));
  homeUniverse = let
    entries =
      lib.concatMap (f: walk [] ((loadHomeModule f).options.hamra.home.programs or {}))
      (moduleFiles (repo + "/modules/home/programs"));
    step = acc: e: let
      p = e.prefix;
      d = e.default;
    in
      if lib.length p < 2
      then acc
      else let
        cat = lib.elemAt p 0;
        app = lib.concatStringsSep "." (lib.drop 1 p);
      in
        if !builtins.isBool d
        then throw "home toggle ${cat}.${app} has non-bool default"
        else acc // {${cat} = (acc.${cat} or {}) // {${app} = d;};};
  in
    lib.foldl step {} entries;

  setToggle = val: acc: path: let
    parts = lib.splitString "." path;
    cat = lib.head parts;
    app = lib.concatStringsSep "." (lib.tail parts);
  in
    if cat == "" || app == "" || !(acc ? ${cat}) || !(acc.${cat} ? ${app})
    then throw "unknown app '${path}' — not a declared toggle"
    else acc // {${cat} = acc.${cat} // {${app} = val;};};

  applyToggles = universe: enable: disable:
    lib.foldl (setToggle false) (lib.foldl (setToggle true) universe enable) disable;

  get = key: default: answers.${key} or default;

  enableBase = get "enable" [];
  enable = let
    withSamba =
      if answers.nas && !(lib.elem "services.samba" enableBase)
      then enableBase ++ ["services.samba"]
      else enableBase;
  in
    if answers.vnc && !(lib.elem "services.wayvnc" withSamba)
    then withSamba ++ ["services.wayvnc"]
    else withSamba;

  optionals0 = applyToggles optionalsUniverse.toggles enable (get "disable" []);
  core = applyToggles coreUniverse.toggles (get "core_enable" []) (get "core_disable" []);
  home = applyToggles homeUniverse (get "hm_enable" []) (get "hm_disable" []);

  davinciAuto = answers.gpu == "virtio" && optionals0.media ? "davinci-resolve" && optionals0.media."davinci-resolve";
  optionals1 =
    optionals0
    // lib.optionalAttrs davinciAuto {media = optionals0.media // {"davinci-resolve" = false;};};
  gearleverAuto = !(optionals1.services.appimage or true) && (optionals1.packaging.gearlever or true);
  optionals =
    optionals1
    // lib.optionalAttrs gearleverAuto {packaging = optionals1.packaging // {gearlever = false;};};

  autoNotes =
    (
      if davinciAuto
      then [''media."davinci-resolve" = false (virtio GPU cannot run it)'']
      else []
    )
    ++ (
      if gearleverAuto
      then ["packaging.gearlever = false (gearlever requires appimage)"]
      else []
    );

  webapps = get "webapps" {};
  webappCheck = lib.mapAttrsToList (n: w:
    if !(w ? url) || !(w ? desktopName)
    then throw "webapps.${n} needs url and desktopName"
    else null)
  webapps;

  env = get "env" {
    editor = "neovim";
    browser = "chromium";
    terminal = "foot";
    filemanager = "thunar";
  };

  keyboard =
    if answers ? keyboard && answers.keyboard != null
    then answers.keyboard
    else {
      keymap = "br";
      xkbVariant = "abnt2";
    };

  displaysByGpu =
    if answers.gpu == "intel"
    then {
      physical = {
        "eDP-1" = {
          mode = "1920x1080";
          position = "0x0";
          scale = 1.0;
        };
      };
      virtual = {};
    }
    else if answers.gpu == "virtio"
    then {
      physical = {};
      virtual = {
        "Virtual-1" = {
          mode = "1920x1080@60";
          position = "0x0";
          scale = 1.0;
        };
      };
    }
    else {
      physical = {};
      virtual = {};
    };
  displays =
    displaysByGpu
    // {
      headless =
        if answers.vnc
        then {
          "HEADLESS-1" = {
            mode = "1920x1080@60";
            position = "1920x0";
            scale = 1.0;
          };
        }
        else {};
    };

  tree =
    {
      networking.hostname = answers.hostname;
      users = {
        userName = answers.username;
        fullName = get "fullName" "Gabriel Nathan dos Santos Pires";
        email = get "email" "devgabrielnathan@gmail.com";
      };
      locale = get "locale" "pt_BR.UTF-8";
      timezone = get "timezone" "America/Sao_Paulo";
      theme = {name = get "theme" "dragon-ball";};
      hardware = {
        inherit (answers) gpu firmware;
        bluetooth = true;
        brightness = true;
        touchpad = true;
      };
      inherit keyboard;
      audio = {default = "pipewire";};
      boot = {
        grub = {
          device = "/dev/sda";
          useOSProber = false;
        };
        loader = "systemd-boot";
        systemd = {editor = false;};
      };
      desktop = {default = answers.desktop;};
      displayManager = {
        default = get "displayManager" "sddm";
        sddm = {
          theme = "silent";
          preset = "catppuccin-mocha";
        };
      };
      inherit displays;
      gc = {
        enable = true;
        keepDays = 30;
        maxGenerations = 20;
        schedule = "weekly";
      };
      printing = true;
      services = {
        gnupg = true;
        keyring = true;
        polkit = true;
        sshd = true;
      };
      firewall = get "firewall" {
        enable = true;
        ports = {
          ssh = true;
          mosh = false;
          http = false;
          https = false;
          dev = false;
          vnc = false;
          rdp = false;
          samba = false;
          syncthing = false;
          kdeconnect = false;
          jellyfin = false;
          printer = false;
          mpd = false;
        };
      };
      inherit env;
      mise = get "mise" {
        env = {};
        settings = {};
        tools = {};
      };
      flatpak = {apps = [];};
      packages = {extra = [];};
      programs = {inherit core optionals;};
    }
    // (
      if webapps != {}
      then {inherit webapps;}
      else {}
    );

  nixKey = k:
    if lib.strings.match "[a-zA-Z0-9_]+" k != null
    then k
    else ''"${k}"'';

  pad = i: lib.concatStringsSep "" (lib.genList (_: "  ") i);

  renderFloat = v: let
    raw = lib.strings.floatToString v;
    m = builtins.match "([0-9]+)\\.([0-9]*[1-9]|)0*" raw;
  in
    if m == null
    then raw
    else let
      intPart = lib.head m;
      fracPart = lib.elemAt m 1;
    in
      if fracPart == ""
      then intPart + ".0"
      else intPart + "." + fracPart;

  render = v: i:
    if builtins.isBool v
    then
      (
        if v
        then "true"
        else "false"
      )
    else if lib.isInt v
    then toString v
    else if lib.isFloat v
    then renderFloat v
    else if lib.isString v
    then lib.strings.escapeNixString v
    else if v == null
    then "null"
    else if lib.isList v
    then
      (
        if v == []
        then "[]"
        else "[\n" + lib.concatMapStringsSep "\n" (x: pad (i + 1) + render x (i + 1)) v + "\n" + pad i + "]"
      )
    else if builtins.isAttrs v
    then
      (
        if v == {}
        then "{}"
        else
          "{\n"
          + lib.concatMapStringsSep "\n"
          (k: pad (i + 1) + nixKey k + " = " + render v.${k} (i + 1) + ";")
          (lib.sort (a: b: a < b) (builtins.attrNames v))
          + "\n"
          + pad i
          + "}"
      )
    else throw "cannot render ${builtins.typeOf v}";

  envLines = [
    "    env = {"
    "      editor = pkgs.${env.editor};"
    "      browser = pkgs.${env.browser};"
    "      terminal = pkgs.${env.terminal};"
    "      filemanager = pkgs.${env.filemanager};"
    "    };"
    ""
  ];

  renderSection = section: let
    parts = lib.splitString "." section;
    node = lib.getAttrFromPath parts tree;
    line =
      if lib.length parts > 1
      then "    ${lib.head parts}.${lib.concatStringsSep "." (lib.tail parts)} = ${render node 2};"
      else "    ${nixKey (lib.head parts)} = ${render node 2};";
  in [line ""];

  HOST_FILES = [
    {
      file = "config/system.nix";
      sections = ["networking.hostname" "users" "locale" "timezone" "theme.name" "gc" "printing" "services" "firewall"];
    }
    {
      file = "config/hardware.nix";
      sections = ["hardware" "keyboard" "audio" "boot"];
    }
    {
      file = "config/desktop.nix";
      sections = ["desktop" "displayManager" "displays" "env" "mise" "flatpak.apps" "packages.extra" "webapps"];
    }
    {
      file = "config/programs-core.nix";
      sections = ["programs.core"];
    }
    {
      file = "config/programs-optionals.nix";
      sections = ["programs.optionals"];
    }
  ];

  fileHeaders = {
    "config/desktop.nix" = "{pkgs, ...}";
    "config/home.nix" = "{config, ...}";
  };

  renderFile = spec: let
    raw =
      lib.concatLists
      (map (s:
        if s == "env"
        then envLines
        else if s == "users"
        then ["    users = ${render tree.users 2};" ""]
        else if s == "webapps" && webapps == {}
        then []
        else renderSection s)
      spec.sections);
    body =
      if lib.length raw > 0 && lib.last raw == ""
      then lib.init raw
      else raw;
  in
    (fileHeaders.${spec.file} or "_")
    + ": {\n  hamra = {\n"
    + lib.concatStringsSep "\n" body
    + "\n  };\n}\n";

  files =
    {
      "configuration.nix" = ''
        _: {
          imports = [
            ../../modules/nixos/core
            ../../modules/nixos/desktops
            ../../modules/nixos/programs
            ./hardware-configuration.nix
            ./config/system.nix
            ./config/hardware.nix
            ./config/desktop.nix
            ./config/programs-core.nix
            ./config/programs-optionals.nix
            ./config/home.nix
          ];
        }
      '';
    }
    // builtins.listToAttrs (map (spec: {
        name = spec.file;
        value = renderFile spec;
      })
      HOST_FILES)
    // {
      "config/home.nix" = ''
        {config, ...}: {
          home-manager.users.''${config.hamra.users.userName}.hamra.home.programs = ${render home 1};
        }
      '';
    };

  countToggles = u: lib.foldl (acc: cat: acc + lib.length (builtins.attrNames u.${cat})) 0 (builtins.attrNames u);
in
  assert lib.all (x: x == null) webappCheck; {
    inherit files autoNotes;
    skipped = coreUniverse.skipped ++ optionalsUniverse.skipped;
    counts = {
      core = countToggles coreUniverse.toggles;
      optionals = countToggles optionalsUniverse.toggles;
      home = countToggles homeUniverse;
    };
  }
