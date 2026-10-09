{
  pkgs,
  system,
}: {
  ${system} = {
    cookiecutter = pkgs.callPackage ../apps/cookiecutter {};
  };
}
