# The Last Class - PSX Shader Demo

Open project.godot in Godot 4.7.2 and press **F5**. The demo starts with mild pixelation, ordered dithering and subtle wobble on furniture.

## Try it
- **Esc:** release mouse and open settings. Click **Back to demo** to resume.
- **Original / Mild PSX / Strong PSX / Eco:** clickable presets in settings.
- **Hold Tab:** see the original rendering at the same camera position. Release to restore your settings.
- **1 / 2 / 3 / 4:** full / half / third / quarter 3D resolution. These keys change resolution only.
- **T:** toggle dithering. **V:** toggle vertex wobble.
- **WASD / arrows:** move. **Shift:** sprint. **F:** flashlight.
- **L:** normal/dim lighting. **R:** reset camera position. **H:** hide/show HUD.

Settings include independent effect controls, strength sliders, color levels and a real-time shadow toggle. HUD and settings remain sharp. The demo is capped at 60 FPS to avoid unnecessary rendering above that rate.

**Eco:** half resolution, dithering on, wobble off, real-time shadows off. It is a lighter starting point, not a guarantee of mobile performance.

## Use in another game
Copy the PSXRender folder and follow **PSXRender/README.md**. No addon installation is needed. The demo room, controller and UI are examples; the reusable component is just that folder.

## Optimized room
scenes/Storage.tscn is the editable source. scenes/Storage_Optimized.scn is the static baked copy used by the demo. The bake combines identical materials into 33 batches from 613 surfaces while keeping collision shapes and lighting. It freezes the room's visual geometry; original asset animations remain in the source assets, not in the baked demo room.

To rebuild after editing the room, run Godot with:

    godot --headless --path "path/to/demo-for-sahders" --script res://checks/bake_static_room.gd

This is a compact single-room optimization, not a generic world/animated-character batching tool. Keep larger rooms split for culling and movable objects separate.

## Verification
- checks/verify_pixelation.gd: input, resolution, physics, HUD and resizing.
- checks/verify_psx.gd: render differences, source/baked room parity, collisions, material restoration, comparison/focus, instance isolation and settings clicks.
- checks/benchmark.gd: fresh-process frame time and memory measurements.
- checks/PERFORMANCE.md: measured results and limits.

Run a check using `godot --path "path/to/demo-for-sahders" --script res://checks/verify_psx.gd`. Rendering checks require a graphics display, not --headless. The checks take control of input and quit their own game window when done. No game export is required.
