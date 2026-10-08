# Android tooling.
#
# Options:
#   android - Enable adb, fastboot and friends.
{hamraLib, ...}: {
  hamra.mobile.android = hamraLib.mkBase false;
}
