# Nix store garbage collection.
#
# Options:
#   enable - Run the GC automatically.
#   maxGenerations - Maximum generations kept.
#   schedule - Supported: "daily" | "weekly".
#   keepDays - Days to retain generations.
{hamraLib, ...}: {
  hamra.gc = hamraLib.mkBase {
    enable = true;
    maxGenerations = 20;
    schedule = "weekly";
    keepDays = 30;
  };
}
