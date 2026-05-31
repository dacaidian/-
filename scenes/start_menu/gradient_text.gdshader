shader_type canvas_item;

uniform vec4 color_start : source_color = vec4(1.0, 0.0, 0.0, 1.0); // 起始颜色 (红色)
uniform vec4 color_end : source_color = vec4(0.0, 0.0, 1.0, 1.0);   // 结束颜色 (蓝色)

void fragment() {
    // UV.x 是横向坐标 (0到1, 从左到右)
    // UV.y 是纵向坐标 (0到1, 从上到下)
    float mix_factor = UV.x;
    // 将两个颜色根据混合因子进行混合
    vec4 final_color = mix(color_start, color_end, mix_factor);
    
    // 应用混合后的颜色到文字，同时保留文字原有的形状（alpha值）
    COLOR = final_color * texture(TEXTURE, UV);
}
