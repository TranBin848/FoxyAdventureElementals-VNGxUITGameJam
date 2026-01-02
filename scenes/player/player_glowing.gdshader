shader_type canvas_item;
render_mode unshaded;

// Enum Mapping: 0:NONE, 1:METAL, 2:WOOD, 3:WATER, 4:FIRE, 5:EARTH
uniform int elemental_type : hint_range(0, 5) = 0;
uniform float color_tolerance : hint_range(0.0, 1.0) = 0.3;
uniform float glow_intensity : hint_range(0.0, 5.0) = 0.7;
uniform float outline_threshold : hint_range(0.0, 1.0) = 0.1;

// NEW: Toggle for the crop logic
uniform bool is_fireball_state = false;

// --- CROP SETTINGS ---
uniform float crop_radius : hint_range(0.0, 500.0) = 6.8;
uniform float crop_feathering : hint_range(0.0, 20.0) = 1.0;

// --- PALETTE SWAP COLORS ---
// 1. METAL
uniform vec4 metal_target_1 : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 metal_replace_1 : source_color = vec4(0.9, 0.95, 1.0, 1.0);
uniform vec4 metal_target_2 : source_color = vec4(0.3, 0.3, 0.3, 1.0);
uniform vec4 metal_replace_2 : source_color = vec4(0.5, 0.55, 0.65, 1.0);

// 2. WOOD
uniform vec4 wood_target_1 : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 wood_replace_1 : source_color = vec4(0.2, 0.8, 0.3, 1.0);
uniform vec4 wood_target_2 : source_color = vec4(0.3, 0.3, 0.3, 1.0);
uniform vec4 wood_replace_2 : source_color = vec4(0.55, 0.35, 0.15, 1.0);

// 3. WATER
uniform vec4 water_target_1 : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 water_replace_1 : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform vec4 water_target_2 : source_color = vec4(0.3, 0.3, 0.3, 1.0);
uniform vec4 water_replace_2 : source_color = vec4(0.0, 0.2, 0.8, 1.0);

// 4. FIRE
uniform vec4 fire_target_1 : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 fire_replace_1 : source_color = vec4(1.0, 0.3, 0.0, 1.0);
uniform vec4 fire_target_2 : source_color = vec4(0.3, 0.3, 0.3, 1.0);
uniform vec4 fire_replace_2 : source_color = vec4(0.8, 0.1, 0.0, 1.0);

// 5. EARTH
uniform vec4 earth_target_1 : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 earth_replace_1 : source_color = vec4(0.6, 0.5, 0.2, 1.0);
uniform vec4 earth_target_2 : source_color = vec4(0.3, 0.3, 0.3, 1.0);
uniform vec4 earth_replace_2 : source_color = vec4(0.72, 0.48, 0.29, 1.0);

// --- OUTLINE GLOW COLORS ---
uniform vec4 metal_glow : source_color = vec4(0.9, 0.95, 1.0, 1.0);
uniform vec4 wood_glow : source_color = vec4(0.2, 0.9, 0.3, 1.0);
uniform vec4 water_glow : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform vec4 fire_glow : source_color = vec4(1.0, 0.4, 0.0, 1.0);
uniform vec4 earth_glow : source_color = vec4(0.7, 0.5, 0.2, 1.0);


varying vec2 local_pixel_pos;

void vertex() {
	local_pixel_pos = VERTEX;
}

vec4 apply_palette_swap(vec4 color, vec4 target_1, vec4 replace_1, vec4 target_2, vec4 replace_2) {
	vec4 result = color;
	if (distance(color.rgb, target_1.rgb) < color_tolerance) result.rgb = replace_1.rgb;
	else if (distance(color.rgb, target_2.rgb) < color_tolerance) result.rgb = replace_2.rgb;
	return result;
}

vec4 get_glow_color(int type) {
	if (type == 1) return metal_glow;
	if (type == 2) return wood_glow;
	if (type == 3) return water_glow;
	if (type == 4) return fire_glow;
	if (type == 5) return earth_glow;
	return vec4(1.0);
}

void fragment() {
	// Default to NO CROP (1.0 alpha)
	float circle_alpha = 1.0;

	// ONLY calculate crop if we are in fireball state
	if (is_fireball_state) {
		float dist_from_center = length(local_pixel_pos);
		circle_alpha = 1.0 - smoothstep(crop_radius, crop_radius + crop_feathering, dist_from_center);
	}

	// Logic resumes: If fully cropped out, discard.
	if (circle_alpha <= 0.0) {
		COLOR = vec4(0.0);
	} else {
		vec4 current_color = texture(TEXTURE, UV);
		vec2 pixel_size = TEXTURE_PIXEL_SIZE;

		// IS THIS PIXEL PART OF THE SPRITE?
		if (current_color.a > outline_threshold) {
			vec4 swapped_color = current_color;

			if (elemental_type == 1) swapped_color = apply_palette_swap(current_color, metal_target_1, metal_replace_1, metal_target_2, metal_replace_2);
			else if (elemental_type == 2) swapped_color = apply_palette_swap(current_color, wood_target_1, wood_replace_1, wood_target_2, wood_replace_2);
			else if (elemental_type == 3) swapped_color = apply_palette_swap(current_color, water_target_1, water_replace_1, water_target_2, water_replace_2);
			else if (elemental_type == 4) swapped_color = apply_palette_swap(current_color, fire_target_1, fire_replace_1, fire_target_2, fire_replace_2);
			else if (elemental_type == 5) swapped_color = apply_palette_swap(current_color, earth_target_1, earth_replace_1, earth_target_2, earth_replace_2);

			// Apply the circle mask alpha (If not fireball, this is just * 1.0)
			swapped_color.a *= circle_alpha;
			COLOR = swapped_color;
		}
		// IS THIS PIXEL EMPTY SPACE? (Outline logic)
		else {
			if (elemental_type > 0) {
				float max_neighbor = 0.0;
				float alpha_up = texture(TEXTURE, UV + vec2(0.0, -pixel_size.y)).a;
				float alpha_down = texture(TEXTURE, UV + vec2(0.0, pixel_size.y)).a;
				float alpha_left = texture(TEXTURE, UV + vec2(-pixel_size.x, 0.0)).a;
				float alpha_right = texture(TEXTURE, UV + vec2(pixel_size.x, 0.0)).a;

				if (alpha_up > outline_threshold) max_neighbor = max(max_neighbor, alpha_up);
				if (alpha_down > outline_threshold) max_neighbor = max(max_neighbor, alpha_down);
				if (alpha_left > outline_threshold) max_neighbor = max(max_neighbor, alpha_left);
				if (alpha_right > outline_threshold) max_neighbor = max(max_neighbor, alpha_right);

				if (max_neighbor > 0.0) {
					vec4 outline_col = get_glow_color(elemental_type);
					// Important: Mask the outline too!
					outline_col.a = min(1.0, glow_intensity) * circle_alpha;
					COLOR = outline_col;
				} else {
					COLOR = current_color;
				}
			} else {
				COLOR = current_color;
			}
		}
	}
}