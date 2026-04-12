shader_type sky;

uniform vec3 color_top : source_color = vec3(0.05, 0.2, 0.9);      // Deep Blue
uniform vec3 color_middle : source_color = vec3(0.9, 0.2, 0.4);   // Pink/Magenta
uniform vec3 color_bottom : source_color = vec3(1.0, 0.8, 0.2);   // Yellow/Orange

uniform float middle_position : hint_range(-1.0, 1.0) = 0.0;
uniform float blending : hint_range(0.0, 2.0) = 0.5;

void sky() {
    float v_grad = EYEDIR.y;
    
    // Smoothly blend between bottom-to-middle and middle-to-top
    vec3 lower_gradient = mix(color_bottom, color_middle, smoothstep(middle_position - blending, middle_position, v_grad));
    vec3 final_color = mix(lower_gradient, color_top, smoothstep(middle_position, middle_position + blending, v_grad));
    
    COLOR = final_color;
}