shader_type canvas_item;
render_mode unshaded;

uniform vec4 core_color : source_color = vec4(0.92, 0.98, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.38, 0.68, 0.94, 0.85);
uniform float cut_offset : hint_range(-0.35, 0.35) = 0.16;
uniform float softness : hint_range(0.005, 0.08) = 0.025;
uniform float sheen : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float outer_distance = length(p);
	float inner_distance = length(p - vec2(cut_offset, 0.0));
	float outer = 1.0 - smoothstep(0.78 - softness, 0.78 + softness, outer_distance);
	float cut = 1.0 - smoothstep(0.61 - softness, 0.61 + softness, inner_distance);
	float crescent = outer * (1.0 - cut);
	float outer_rim = smoothstep(0.66, 0.77, outer_distance) * crescent;
	float inner_rim = smoothstep(0.50, 0.61, inner_distance) * crescent;
	float highlight = clamp((1.0 - UV.y) * 0.78 + (1.0 - UV.x) * 0.22, 0.0, 1.0);
	vec3 body = mix(edge_color.rgb, core_color.rgb, 0.48 + highlight * sheen * 0.52);
	body += core_color.rgb * (outer_rim * 0.42 + inner_rim * 0.22);
	float alpha = crescent * mix(edge_color.a, core_color.a, highlight);
	COLOR = vec4(body, alpha);
}
