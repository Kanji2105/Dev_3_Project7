shader_type canvas_item;
render_mode unshaded;
uniform vec2 source_size = vec2(640.0, 360.0);
uniform float strength : hint_range(0.0, 1.0) = 0.7;
uniform float levels : hint_range(4.0, 64.0) = 32.0;
const float BAYER[16] = float[16](0.0,8.0,2.0,10.0,12.0,4.0,14.0,6.0,3.0,11.0,1.0,9.0,15.0,7.0,13.0,5.0);
void fragment() {
 vec4 color = texture(TEXTURE, UV);
 ivec2 pixel = ivec2(floor(UV * source_size));
 float threshold = (BAYER[(pixel.y % 4) * 4 + pixel.x % 4] + 0.5) / 16.0 - 0.5;
 float steps = levels - 1.0;
 color.rgb = clamp(floor(color.rgb * steps + 0.5 + threshold * strength) / steps, vec3(0.0), vec3(1.0));
 COLOR = color;
}
