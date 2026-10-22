shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_nearest_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec3 uv_scale = vec3(1.0);
uniform vec3 uv_offset = vec3(0.0);
uniform float roughness_value = 0.8;
uniform float metallic_value = 0.0;
uniform float specular_value = 0.5;
uniform float wobble_strength : hint_range(0.0, 1.0) = 0.35;
uniform float grid_height = 240.0;
void vertex() {
 UV = UV * uv_scale.xy + uv_offset.xy;
 vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
 if (!IN_SHADOW_PASS && clip.w > 0.05) {
  vec2 grid = vec2(grid_height * VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, grid_height);
  vec2 ndc = clip.xy / clip.w;
  vec2 snapped = floor(ndc * grid * 0.5 + 0.5) / (grid * 0.5);
  clip.xy = mix(ndc, snapped, wobble_strength) * clip.w;
 }
 POSITION = clip;
}
void fragment() {
 ALBEDO = texture(albedo_texture, UV).rgb * tint.rgb;
 ROUGHNESS = roughness_value;
 METALLIC = metallic_value;
 SPECULAR = specular_value;
}
