shader_type canvas_item;

uniform vec4 target_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float white_threshold : hint_range(0.0, 1.0) = 0.95;
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.65;

// Controls how far out the shader looks to define the "edge" thickness
uniform float edge_thickness : hint_range(0.5, 5.0) = 1.6;

// Helper function to check if a pixel is white
float check_white(vec4 color) {
    float brightness = (color.r + color.g + color.b) / 3.0;
    return step(white_threshold, brightness) * step(alpha_threshold, color.a);
}

void fragment() {
    // Get texture pixel size for accurate neighbor offsets
    vec2 texel_size = TEXTURE_PIXEL_SIZE * edge_thickness;
    
    // Sample the center pixel and its 4 direct neighbors
    vec4 center = texture(TEXTURE, UV);
    vec4 top    = texture(TEXTURE, UV + vec2(0.0, -texel_size.y));
    vec4 bottom = texture(TEXTURE, UV + vec2(0.0, texel_size.y));
    vec4 left   = texture(TEXTURE, UV + vec2(-texel_size.x, 0.0));
    vec4 right  = texture(TEXTURE, UV + vec2(texel_size.x, 0.0));
    
    // Evaluate whiteness for all 5 samples (1.0 = white, 0.0 = not white)
    float c_w = check_white(center);
    float t_w = check_white(top);
    float b_w = check_white(bottom);
    float l_w = check_white(left);
    float r_w = check_white(right);
    
    // A pixel is "interior" ONLY if it and all 4 neighbors are white
    float is_interior = c_w * t_w * b_w * l_w * r_w;
    
    // Color the interior, keep original border and transparency
    vec3 final_rgb = mix(center.rgb, target_color.rgb, is_interior);
    COLOR = vec4(final_rgb, center.a);
}
