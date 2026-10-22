PSX HORROR SKYBOXES - FREE SAMPLER by LESED (lesed.itch.io)

3 dithered PS1-style horror skies. Each sky comes as an equirectangular panorama (1024x512 and 2048x1024)
and as 6 cube faces (512x512). Low colour depth with ordered dithering; hills and treelines on the horizon.

01 full_moon_night: Cold blue night, white moon, stars, pine treeline
02 blood_moon: Huge red moon over a dead forest
03 whiteout_fog: Thick white fog, trees barely visible

FOLDERS
panorama_1024x512/   chunky PS1 look (recommended)
panorama_2048x1024/  finer pixels for wide FOV or high resolutions
cubemap_512/<sky>/   px nx py ny pz nz = +X -X +Y(up) -Y(down) +Z -Z, OpenGL cubemap convention
godot/               an Environment (.tres) per sky: panorama sky, no filtering, matching fog colour
skies.csv, preview_all.png

IMPORT
Godot 4: copy this folder into your project root (keep the folder name). Drag a *_environment.tres into a
  WorldEnvironment node. Or: Environment > Sky > New PanoramaSkyMaterial, set Panorama, turn Filter off.
Unity: import a panorama with Texture Shape 2D, Filter Mode Point, Compression None, Wrap Clamp (U Repeat).
  Create a material with shader Skybox/Panoramic, Mapping Latitude Longitude Layout, assign it in
  Window > Rendering > Lighting > Environment > Skybox Material.
Unreal: import the panorama or the cube faces as a TextureCube (Filter: Nearest) and use it on a sky sphere,
  or in a Sky Light with Source Type 'SLS Specified Cubemap'.
Other engines: any equirectangular (lat-long) panorama sky works; use nearest filtering.

Rotate the sky in your engine to place the moon/sun where you want it.

Made procedurally with code (gradients, noise clouds, silhouettes, 4-bit ordered dithering). The generation
code was written with AI assistance; no generative image models were used.

License: see LICENSE.txt. Commercial use allowed; do not resell or share the files.

THE FULL PACK: 20 skies (blood moon, eclipse, storm, aurora, hellfire, a giant eye, a cracked sky...):
https://lesed.itch.io/psx-horror-skyboxes
