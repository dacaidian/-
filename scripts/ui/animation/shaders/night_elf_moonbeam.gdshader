shader_type canvas_item;
render_mode unshaded;

uniform vec4 core_color : source_color = vec4(0.82, 0.94, 1.0, 0.40);
uniform vec4 edge_color : source_color = vec4(0.34, 0.56, 0.82, 0.0);
uniform float time_offset = 0.0;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float taper : hint_range(0.0, 0.8) = 0.28;

void fragment() {
	vec2 uv = UV;
	float half_width = mix(0.50 - taper, 0.50, uv.y);
	float horizontal = 1.0 - smoothstep(half_width * 0.42, half_width, abs(uv.x - 0.5));
	float bottom_fade = 1.0 - smoothstep(0.68, 1.0, uv.y);
	float top_fade = smoothstep(0.0, 0.10, uv.y);
	float vertical = bottom_fade * top_fade;
	float silk = 0.88 + 0.12 * sin(uv.y * 18.0 + uv.x * 7.0 + time_offset);
	float leaf_shadow = 1.0 - 0.10 * (
		sin(uv.x * 23.0 + uv.y * 11.0)
		* sin(uv.x * 9.0 - uv.y * 17.0)
	);
	float alpha = horizontal * vertical * silk * leaf_shadow * core_color.a * intensity;
	vec3 color = mix(edge_color.rgb, core_color.rgb, horizontal * 0.76);
	COLOR = vec4(color, alpha);
}
