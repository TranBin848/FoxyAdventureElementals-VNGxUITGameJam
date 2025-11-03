shader_type canvas_item;

uniform int elemental_type : hint_range(0, 3) = 0;
uniform vec2 border_threshold = vec2(0.01, 0.01);
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.9;
uniform float color_tolerance : hint_range(0.0, 1.0) = 0.2;

// Fire element color mappings
uniform vec4 fire_target_1 : source_color = vec4(0.5, 0.5, 0.5, 1.0);  // Gray
uniform vec4 fire_replace_1 : source_color = vec4(1.0, 0.3, 0.0, 1.0);  // Orange

uniform vec4 fire_target_2 : source_color = vec4(0.3, 0.3, 0.3, 1.0);  // Dark gray
uniform vec4 fire_replace_2 : source_color = vec4(0.8, 0.1, 0.0, 1.0);  // Dark red

// Earth element color mappings
uniform vec4 earth_target_1 : source_color = vec4(0.5, 0.5, 0.5, 1.0);  // Gray
uniform vec4 earth_replace_1 : source_color = vec4(0.6, 0.5, 0.2, 1.0);  // Brown

uniform vec4 earth_target_2 : source_color = vec4(0.3, 0.3, 0.3, 1.0);  // Dark gray
uniform vec4 earth_replace_2 : source_color = vec4(0.72, 0.48, 0.29, 1.0);  // Dark brown

// Water element color mappings
uniform vec4 water_target_1 : source_color = vec4(0.5, 0.5, 0.5, 1.0);  // Gray
uniform vec4 water_replace_1 : source_color = vec4(0.0, 0.5, 1.0, 1.0);  // Cyan

uniform vec4 water_target_2 : source_color = vec4(0.3, 0.3, 0.3, 1.0);  // Dark gray
uniform vec4 water_replace_2 : source_color = vec4(0.0, 0.2, 0.8, 1.0);  // Dark blue

// Glow colors
uniform vec4 fire_glow : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform vec4 earth_glow : source_color = vec4(0.8, 0.6, 0.2, 1.0);
uniform vec4 water_glow : source_color = vec4(0.0, 0.5, 1.0, 1.0);

bool is_on_border(sampler2D tex, vec2 uv, vec4 center_color)
{
	vec4 color_up = texture(tex, uv + vec2(0.0, border_threshold.y));
	vec4 color_down = texture(tex, uv + vec2(0.0, -border_threshold.y));
	vec4 color_left = texture(tex, uv + vec2(-border_threshold.x, 0.0));
	vec4 color_right = texture(tex, uv + vec2(border_threshold.x, 0.0));
	
	if (center_color.a < alpha_threshold) {
		return false;
	}
	
	bool has_transparent_neighbor = 
		color_up.a < alpha_threshold || 
		color_down.a < alpha_threshold || 
		color_left.a < alpha_threshold || 
		color_right.a < alpha_threshold;
	
	return has_transparent_neighbor;
}

vec4 apply_palette_swap(vec4 color, vec4 target_1, vec4 replace_1, vec4 target_2, vec4 replace_2)
{
	vec4 result = color;
	
	// Check first color mapping
	float dist1 = distance(color.rgb, target_1.rgb);
	if (dist1 < color_tolerance) {
		result.rgb = replace_1.rgb;
		return result;
	}
	
	// Check second color mapping
	float dist2 = distance(color.rgb, target_2.rgb);
	if (dist2 < color_tolerance) {
		result.rgb = replace_2.rgb;
		return result;
	}
	
	return result;
}

vec4 get_glow_color()
{
	if (elemental_type == 1) {
		return fire_glow;
	} else if (elemental_type == 2) {
		return earth_glow;
	} else if (elemental_type == 3) {
		return water_glow;
	}
	return vec4(1.0, 1.0, 1.0, 1.0);
}

void fragment() {
	vec4 sprite_tex = texture(TEXTURE, UV);
	vec4 swapped = sprite_tex;
	
	// Apply palette swap based on element type
	if (elemental_type == 1) {
		swapped = apply_palette_swap(sprite_tex, fire_target_1, fire_replace_1, fire_target_2, fire_replace_2);
	} else if (elemental_type == 2) {
		swapped = apply_palette_swap(sprite_tex, earth_target_1, earth_replace_1, earth_target_2, earth_replace_2);
	} else if (elemental_type == 3) {
		swapped = apply_palette_swap(sprite_tex, water_target_1, water_replace_1, water_target_2, water_replace_2);
	}
	
	// Apply glow to borders
	if (is_on_border(TEXTURE, UV, sprite_tex)) {
		vec4 glow = get_glow_color();
		COLOR = mix(swapped, glow, glow_intensity);
	} else {
		COLOR = swapped;
	}
}
