shader_type canvas_item;

// RADIAL PROGRESSBAR WITH INNER CIRCLE BACKGROUND

#define TWO_PI 6.28318530718

uniform vec3 first_color: source_color = vec3(1.0);
uniform vec3 second_color: source_color = vec3(1.0);
uniform vec3 third_color: source_color = vec3(1.0);
uniform vec3 outline_color: source_color = vec3(0.0);
uniform vec3 unfilled_color: source_color = vec3(0.443);

// --- CENTER CIRCLE SETTINGS ---
uniform vec4 center_color: source_color = vec4(0.5, 0.5, 0.5, 0.5);
uniform float center_blur_softness: hint_range(0.0, 1.0) = 0.1;

uniform float value: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float smooth_ = 0.005;
uniform float width_in = 0.85;
uniform float width_out = 0.95;
uniform float border_width = 0.03;

vec4 radial_progress(vec2 UV_, float VAL, float SMOOTH, float IR, float OR)
{
	vec2 uv = (UV_ * 2.0) - 1.0;

	// Get distance
	float d = length(uv);

	// Define the ring shape
	float ring = smoothstep(OR + SMOOTH, OR - SMOOTH, d) - smoothstep(IR + SMOOTH, IR - SMOOTH, d);

	// Calculate Angle
	float a = atan(uv.y, uv.x);
	float theta = (a < 0.0) ? (a + TWO_PI) / TWO_PI : a / TWO_PI;

	// Cut the ring based on value
	float bar = step(theta, VAL);

	// Final alpha for the ring
	float alpha = ring * bar;

	return vec4(alpha);
}

void fragment()
{
	// 1. Determine Ring Color based on value
	vec3 innerColor;
	if (value > 0.6)
		innerColor = first_color;
	else if (value > 0.3)
		innerColor = second_color;
	else
		innerColor = third_color;

	// 2. Generate the Ring Layers
	// We only need the Alpha (mask) from the function, then apply color
	float primary_alpha = radial_progress(UV, value, smooth_, width_in, width_out).a;
	vec4 primary = vec4(innerColor, primary_alpha);

	float outline_alpha = radial_progress(UV, 100.0, smooth_, width_in - border_width, width_out + border_width).a;
	vec4 outline = vec4(outline_color, outline_alpha);

	float unfilled_alpha = radial_progress(UV, 100.0, smooth_, width_in, width_out).a;
	vec4 unfilled = vec4(unfilled_color, unfilled_alpha);

	// 3. Combine Ring Layers (Logic to prevent overlap)
	vec4 ring_layer = vec4(0.0);

	// Draw outline
	ring_layer = mix(ring_layer, outline, outline.a);
	// Draw unfilled background on top of outline
	ring_layer = mix(ring_layer, unfilled, unfilled.a);
	// Draw value bar on top of background
	ring_layer = mix(ring_layer, primary, primary.a);

	// --- 4. INNER CIRCLE LOGIC ---

	// Calculate distance from center (0.0 to 1.0)
	float d = length((UV * 2.0) - 1.0);

	// The limit is exactly where the outline starts
	float inner_radius_limit = width_in - border_width;

	// Create a soft circle that fades out before it hits the ring
	float inner_alpha = smoothstep(inner_radius_limit, inner_radius_limit - center_blur_softness, d);

	vec4 background_layer = center_color;
	background_layer.a *= inner_alpha;

	// --- 5. FINAL COMPOSITE ---
	// Start with the background layer (Gray Circle)
	// Then mix the Ring Layer on top.
	// This ensures the ring is never blurred by the gray color.
	COLOR = mix(background_layer, ring_layer, ring_layer.a);
}