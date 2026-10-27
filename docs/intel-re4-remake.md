# Intel iGPU: Resident Evil 4 Remake (Proton)

Reference hardware: Intel Core i5-1235U (Alder Lake-UP3), Iris Xe Graphics
(80 EUs), PCI ID `8086:46a8`. Verify on your machine with
`lspci -nn | grep -i vga`. The default kernel driver is `i915`; the `xe`
module is also built into the kernel and can be selected per host.

## Kernel driver: `i915` (default) or `xe`

`hamra.hardware.intel.xe` takes the PCI ID to hand over to `xe`
(`null` keeps `i915`):

```nix
hamra.hardware = {
  gpu = "intel";
  intel.xe = "46a8";
};
```

This generates `boot.kernelParams = [ "i915.force_probe=!46a8" "xe.force_probe=46a8" ]`.
Use the ID reported by your own `lspci -nn`: a wrong ID leaves the GPU
without a driver. Rebuild, reboot, and check with `lspci -k -s 00:02.0`
(`Kernel driver in use: xe`). If the display misbehaves, pick the previous
generation in the systemd-boot menu.

## Steam launch options

The string below was proposed for this game, but two of its tokens are not
recognized by the upstream projects and must not be used:

- `VKD3D_CONFIG=no_as_compute` — not a vkd3d-proton flag (the flag list is in
  `include/private/config_flag_decl.h` of the vkd3d-proton repository).
- `INTEL_DEBUG=xe` — not a Mesa `INTEL_DEBUG` flag (see `intel_debug.h` in Mesa).

`vblank_mode=0` is a valid Mesa variable, but it only removes the vsync cap and
is not expected to fix a frame rate this low.

Use this to collect a log when diagnosing the title screen slowdown:

```
PROTON_LOG=1 %command%
```

The log is written to `~/steam-<appid>.log` (appid `2050650`).
