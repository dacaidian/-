shader_type canvas_item;
render_mode unshaded;

uniform vec4 core_color : source_color = vec4(0.91, 0.97, 1.0, 0.95);
uniform vec4 edge_color : source_color = vec4(0.42, 0.67, 0.90, 0.75);
uniform float phase : hint_range(-1.0, 1.0) = 0.0;
uniform float softness : hint_range(0.005, 0.08) = 0.025;
uniform float detail_strength : hint_range(0.0, 0.5) = 0.12;

float soft_circle(vec2 p, float radius, float feather) {
	return 1.0 - smoothstep(radius - feather, radius + feather, length(p));
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float disc = soft_circle(p, 0.76, softness);
	float phase_sign = phase < 0.0 ? -1.0 : 1.0;
	float phase_amount = abs(phase);
	vec2 cut_center = vec2(phase_sign * mix(1.12, 0.04, phase_amount), 0.0);
	float phase_cut = soft_circle(p - cut_center, 0.76, softness);
	float illuminated = mix(disc, disc * (1.0 - phase_cut), 1.0 - phase_amount);
	float rim = smoothstep(0.62, 0.76, length(p)) * illuminated;
	float quiet_detail = (
		sin(p.x * 17.0 + p.y * 7.0)
		* sin(p.y * 13.0 - p.x * 5.0)
		* 0.5 + 0.5
	);
	vec3 color = mix(edge_color.rgb, core_color.rgb, 0.62 + quiet_detail * detail_strength);
	color += core_color.rgb * rim * 0.34;
	float alpha = illuminated * mix(edge_color.a, core_color.a, 0.68);
	COLOR = vec4(color, alpha);
}
