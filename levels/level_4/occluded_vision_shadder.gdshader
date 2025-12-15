shader_type canvas_item;

uniform vec2 player_uv;   // Player position from 0.0 to 1.0
uniform float ratio;      // Screen aspect ratio (width / height)
uniform float radius = 0.2; // Radius size (relative to screen height)

void fragment() {
    // 1. Get current pixel UV
    vec2 current_uv = UV;
    vec2 center_uv = player_uv;

    // 2. Correct aspect ratio (so the circle doesn't look like an oval)
    // We multiply the X coordinate by the aspect ratio
    current_uv.x *= ratio;
    center_uv.x *= ratio;

    // 3. Calculate distance
    float dist = distance(current_uv, center_uv);

    // 4. Draw the hole (0.0 = transparent, 1.0 = black)
    // smoothstep creates a soft edge
    float alpha = smoothstep(radius, radius + 0.3, dist);

    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
