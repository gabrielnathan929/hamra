# Intel iGPU: Resident Evil 4 Remake (Proton)

Reference machine: `samsung` (Samsung Galaxy Book2 550XED) with an Intel Core
i5-1235U (Alder Lake-UP3, Iris Xe Graphics, 80 EUs, PCI ID `8086:46a8`), 16 GB
DDR4 dual channel. The game is `2050650`, DirectX 12 only, so Proton translates
it through vkd3d-proton onto Vulkan (Mesa ANV).

## What the `intel` GPU toggle configures

`modules/nixos/core/hardware/gpu/intel.nix` runs whenever
`hamra.hardware.gpu = "intel"`:

| Setting | Effect |
|---|---|
| `hardware.graphics.enable` | installs Mesa + the Vulkan ICDs into `/run/opengl-driver` |
| `hardware.graphics.enable32Bit` | same libraries for 32-bit binaries (Steam's client and some games) |
| `extraPackages = [ intel-media-driver intel-compute-runtime ]` | VA-API encode/decode (`iHD`) and the OpenCL runtime |
| `extraPackages32 = [ intel-media-driver ]` | 32-bit VA-API driver |
| `environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD"` | pins the modern VA-API backend |
| `environment.systemPackages = [ intel-gpu-tools ]` | `intel_gpu_top`, useful to see whether the GPU is the bottleneck |
| `services.thermald` | thermal daemon, keeps the 15 W package from clamping early |
| `hamra-intel-dptf-powerlimit` | writes `28000000` (28 W) to the DPTF MMIO RAPL limit at boot, reasserted every 30 s by a timer |

Neither package above accelerates vkd3d-proton: DX12 shaders and compute are
compiled by Mesa's ANV Vulkan driver, which ships with `enable`/`enable32Bit`.
`intel-media-driver` is VA-API (video), and the `intel-compute-runtime` build in
nixpkgs 26.05 only contains the OpenCL ICD (`intel-opencl` and `libocloc.so`, no
Level Zero `libze_intel_gpu.so`). They are still correct to have for browsers,
video and OpenCL workloads, but they are not the fix for a low frame rate.

The 32-bit block matters for the Steam client itself: the client is a 32-bit
program, and without `extraPackages32` it cannot load the VA-API/Vulkan stack.

## Kernel driver: `i915` (default) or `xe`

`samsung` runs `i915`. `lspci -k -s 00:02.0` reports:

```
Kernel driver in use: i915
Kernel modules: i915, xe
```

Both modules are available in the 6.18 kernel, so the handover is a kernel
parameter, not a rebuild of the kernel. `hamra.hardware.intel.xe` takes the PCI
device ID to hand over to `xe` (`null` keeps `i915`):

```nix
hamra.hardware = {
  gpu = "intel";
  intel.xe = "46a8";
};
```

That generates `boot.kernelParams = [ "i915.force_probe=!46a8" "xe.force_probe=46a8" ]`.
Use the ID from your own `lspci -nn`: a wrong ID leaves the GPU without a
driver. Rebuild, reboot and check with `lspci -k -s 00:02.0`
(`Kernel driver in use: xe`). If the display, brightness or suspend misbehaves,
pick the previous generation in the systemd-boot menu; the setting is one line
in `hosts/<machine>/config/hardware.nix`.

`xe` is still the newer path on Alder Lake-P: it is the way forward, but it can
regress power management and output handling from one kernel to the next. Test
it with the frame rate you already recorded, and keep `i915` if it does not
measurably help.

## Steam launch options

The string proposed for this title is:

```
VKD3D_CONFIG=no_as_compute INTEL_DEBUG=xe vblank_mode=0 %command%
```

Two of its three tokens are not recognized by the projects that read them:

| Token | Verdict | Why |
|---|---|---|
| `VKD3D_CONFIG=no_as_compute` | invalid | vkd3d-proton validates its flags against `include/private/config_flag_decl.h`; there is no `no_as_compute`. An unknown name is ignored, it does not disable anything. |
| `INTEL_DEBUG=xe` | invalid | `INTEL_DEBUG` flags are declared in Mesa's `intel_debug.h`; `xe` is a kernel driver name, not a debug flag, and is ignored. |
| `vblank_mode=0` | valid | Mesa variable that uncaps presentation (no vsync). It can only raise a frame rate that is already above the refresh rate; at 11 FPS it changes nothing. |

So the effective string is just `vblank_mode=0`, and it will not fix the title
screen. Use these instead.

The real vkd3d-proton flags closest to the intent of `no_as_compute` are
`VKD3D_CONFIG=no_upload_hvv` and `VKD3D_CONFIG=no_gpu_upload_heap`. They change
how memory is uploaded, not how compute is scheduled; test one at a time, since
on a driver that is already behaving they can cost performance instead of
gaining it.

Normal play, with the repo's own toggles (`games.gamemode`, `games.mangohud`):

```
gamemoderun %command%
```

Diagnostics, when the frame rate is wrong and you want evidence:

```
PROTON_LOG=1 MANGOHUD=1 gamemoderun %command%
```

`PROTON_LOG=1` writes `~/steam-2050650.log`; the `vkd3d` lines show the feature
level, the adapter and the queue families actually used. `MANGOHUD=1` overlays
GPU load, clocks and the frame time, which separates "GPU idle, CPU bound" from
"GPU pinned at the power limit".

## Diagnosing a low frame rate on this laptop

1. Confirm the driver and the Vulkan device: `lspci -k -s 00:02.0` and
   `vulkaninfo --summary` (device `Intel(R) Iris Xe Graphics (ADL GT2)`).
2. Check that the window is not being forced through software: in `MangoHud`,
   the GPU name must be the Iris Xe, not `llvmpipe`.
3. Check the power limit: `cat /sys/class/powercap/intel-rapl-mmio:0/constraint_0_power_limit_uw`
   should read `28000000`. If it reads `15000000`, the refresh timer did not run
   (`systemctl status hamra-intel-dptf-powerlimit-refresh`).
4. Check GPU utilisation with `intel_gpu_top`: near 100% render busy means the
   iGPU is the limit, and the only levers left are resolution and upscaling
   (1280x720 + FSR, lowest textures); low utilisation with high CPU time means
   the bottleneck is elsewhere.
5. Compare against the title screen with `gamemoderun` enabled and disabled, so
   the governor and the CPU boost behaviour are not mistaken for a driver fix.

## Host audit

| | `samsung` | `acer` |
|---|---|---|
| Role | laptop, `wayvnc` server | NAS (`services.samba`), desktop |
| CPU | Intel Core i5-1235U, verified with `lscpu` | Intel (`kvm-intel`, `vmd` in `initrd.availableKernelModules`); exact model not recorded in the repo |
| iGPU | Iris Xe `8086:46a8`, verified with `lspci -nn` | declared only as `hamra.hardware.gpu = "intel"`; PCI ID not recorded in the repo |
| Kernel driver | `i915` (`hamra.hardware.intel.xe = null`) | `i915` (option not set, default `null`) |
| Games toggles | `steam`, `gamemode`, `mangohud` | `steam`, `gamemode`, `mangohud` |

To fill the `acer` row, run on that machine:

```
lscpu | grep 'Model name'
lspci -nn | grep -Ei 'vga|3d|display'
```

If it also has an Iris Xe and the same title screen behaviour, the same toggle
applies; `hamra.hardware.intel.xe` stays per host on purpose, because the PCI ID
and the willingness to run `xe` differ per machine.
