# PSXRender - quick setup

Tested in Godot 4.7.2, Compatibility renderer. No plugin or autoload required.

## Add it to another 3D game
1. Copy the entire **PSXRender** folder to the new project root. Keep that folder name.
2. Drag **PSXRender/PSXRender.tscn** into your main scene.
3. Move or instance the level, Player/Camera3D, lights and WorldEnvironment under **PSXRender > Viewport > GameWorld**. Keep exactly one active camera in this viewport.
4. Keep menus, subtitles and crosshair in a **CanvasLayer outside PSXRender**, under the main scene. They stay sharp.
5. Select PSXRender. Set Resolution Divisor to 2, enable Dithering, and try Dither Strength 0.7 / Color Levels 32.
6. For wobble, select a prop or its parent, open **Node > Groups**, add **psx_wobble**, then enable Wobble on PSXRender. Start at strength 0.35. Leave walls and floors out of this group to prevent seams.
7. Run the main scene with F5. Set your UI Controls to Mouse > Filter = Stop when they should block game input.

Scene structure:

Main
  PSXRender
    Viewport
      GameWorld
        Level
        Player + Camera3D
        WorldEnvironment + Lights
  HUD (CanvasLayer)

The viewport uses its own World3D. Move physics objects together with the level; don't leave the player in a different viewport. Mouse look should use InputEventMouseMotion.screen_relative so sensitivity stays the same at every resolution. Existing controllers using the root camera, absolute node paths, root World3D, or root physics queries may need their paths updated. Do not forward input manually: SubViewportContainer already forwards it.

## Settings in code

    $PSXRender.resolution_divisor = 2 # 1 = full; 2/3/4 = smaller internal 3D resolution
    $PSXRender.dithering_enabled = true
    $PSXRender.wobble_enabled = true
    $PSXRender.wobble_strength = 0.35
    $PSXRender.set_comparison(true)  # temporarily view original
    $PSXRender.set_comparison(false) # restore current settings

After spawning new grouped props, call refresh_wobble_targets() once. It scans that viewport only, not the entire game every frame.

## What each effect does
- Pixelation renders 3D at a lower resolution and enlarges it with nearest filtering.
- Dithering uses an ordered 4x4 pattern and color quantization in the existing viewport display pass. No screen-copy buffer or second 3D render.
- Wobble snaps projected vertices to a coarse grid as the camera moves. It is not random shaking. Shadow passes and physics collisions stay stable.
- Comparison restores original materials and full 3D resolution. It does not change lights or shadows, so the comparison uses the same scene conditions.

## Materials and limits
The automatic wobble conversion supports plain opaque, per-pixel StandardMaterial3D with base color/texture, UV scale/offset, roughness, metallic value, specular value and culling. It uses nearest mipmap texture filtering for the PSX look. Original materials are restored when disabled.

Custom shaders, transparency, normal maps, emission, special material features, blend shapes, overlays and whole-mesh material overrides are skipped. They still render normally. Integrate the vertex snapping into an advanced material's own shader if needed. Do not treat this as a universal material converter.

## Performance
Start with divisor 2. Turn wobble off and disable expensive real-time shadows for a lighter mode. A divisor of 4 has fewer pixels but can make fine detail harder to read. Keep HUD separate. The component does not change your game's FPS cap or lighting; those are choices in the demo controller.

This pack renders one world once. Converted materials and shaders are cached; textures are shared, not copied; mesh scanning happens at setup/explicit refresh only. Dithering costs a small display pass operation and wobble costs vertex math. Lower resolution mostly helps pixel/GPU work; it does not fix expensive gameplay scripts or too many draw calls.

Validated on Windows/OpenGL Compatibility. Web, mobile devices, Forward+ and Mobile renderer have not been tested here.
