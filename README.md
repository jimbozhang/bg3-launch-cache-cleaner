# bg3-launch-cache-cleaner

A Windows batch script that clears the BG3 / GPU shader caches responsible
for the "instant crash on launch" problem.

## The problem

The game launches once, then crashes right after the splash screen on every
subsequent launch. It is unrelated to mods or saves. As described on the
[Larian forums](https://forums.larian.com/ubbthreads.php?ubb=showflat\&Number=945089):

> I can launch it once after which each time I try to launch it again the
> game will crash...

## Does this apply to you?

Launch crashes have many causes. This tool only helps if your crash matches:

- The crash happens within a few seconds of pressing Play — right after the
  splash screen, before the main menu or any loading screen appears.
- It is flaky: retrying a few times sometimes lets the game start.
- It is not tied to a specific save, mod, or settings change — the same
  thing happens on a fresh character / empty mod list.
- You are using the DirectX 11 renderer (`bg3_dx11.exe`, the Windows default).
  The Vulkan backend has its own separate launch crashes this tool does not
  target.
- The crash dump (the `CrashDump - *.dmp` / `.state` files the game writes
  to its `bin\` folder) faults in an NVIDIA driver module
  (`nvwgf2umx.dll`, `nvldumdx.dll`, ...) or `d3d11.dll`, not in a mod or in
  the game itself.

If your crash happens while loading a save, in a specific location, or
reliably (never works, even after retries), the cause is probably elsewhere
(corrupt save, incompatible mod, VRAM shortage, ...) and this tool will not
help.

## How it works

During launch, the DX11 renderer loads pre-compiled shaders from on-disk
caches: the NVIDIA `DXCache`, BG3's `LevelCache` / `Temp`, and the Windows
`D3DSCache`. These caches outlive game and driver updates, so an entry that
is stale or corrupted makes D3D11 device initialization fail — which is why
the crash happens in the first seconds, before the main menu. Deleting the
caches forces a clean re-compile on the next launch. `disable_HAGS.reg`
addresses the remaining driver-side trigger: Hardware-accelerated GPU
scheduling has been an early-launch crash factor on newer NVIDIA drivers.

## Usage

Run `bg3_clean_launch_cache.bat` as administrator, and apply `disable_HAGS.reg` 
then reboot. This tool is safe to try even if you are not sure it applies —
worst case it simply does not help.