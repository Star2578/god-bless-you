shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

// The PS1 Classic Palette
uniform vec3 palette[16] : source_color;

// Settings
uniform int dithering_mode : hint_range(0, 3) = 1; 
uniform float spread : hint_range(0.0, 1.0) = 0.2;
uniform float target_height : hint_range(120.0, 1080.0) = 240.0; // PS1 was usually 240p
uniform bool use_downsampling = true;

// Bayer 4x4 Matrix
const float bayer_matrix[16] = float[](
    0.0/16.0, 0.5, 0.125, 0.625,
    0.75, 0.25, 0.875, 0.375,
    0.1875, 0.6875, 0.0625, 0.5625,
    0.9375, 0.4375, 0.8125, 0.3125
);

vec3 find_closest_color(vec3 color) {
    vec3 closest = palette[0];
    float shortest_dist = distance(color, palette[0]);
    for (int i = 1; i < 16; i++) {
        float dist = distance(color, palette[i]);
        if (dist < shortest_dist) {
            shortest_dist = dist;
            closest = palette[i];
        }
    }
    return closest;
}

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // --- Step 1: Downsampling (The 'Crunch') ---
    if (use_downsampling) {
        float ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
        vec2 res = vec2(target_height * ratio, target_height);
        uv = floor(uv * res) / res;
    }

    vec3 screen_col = texture(SCREEN_TEXTURE, uv).rgb;
    
    // --- Step 2: Dithering Calculations ---
    float dither_shift = 0.0;
    // We use actual screen coordinates for dither pattern stability
    ivec2 dither_coord = ivec2(FRAGCOORD.xy); 
    
    if (dithering_mode == 1) { // Bayer
        int x = dither_coord.x % 4;
        int y = dither_coord.y % 4;
        dither_shift = (bayer_matrix[x + y * 4] - 0.5) * spread;
    } 
    else if (dithering_mode >= 2) { // Floyd-Steinberg / Atkinson Approximation
        // Using a high-frequency hash to simulate error diffusion noise
        float noise = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
        dither_shift = (noise - 0.5) * spread;
    }

    // --- Step 3: Palette Mapping ---
    vec3 final_col = find_closest_color(screen_col + dither_shift);
    
    COLOR = vec4(final_col, 1.0);
}