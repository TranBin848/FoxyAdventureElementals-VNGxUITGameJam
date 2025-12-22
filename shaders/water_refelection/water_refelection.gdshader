shader_type canvas_item;

// --- Existing Reflection Uniforms ---
uniform vec4 CAST_COLOR: source_color;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform sampler2D fast_noise: repeat_enable;
uniform vec2 speed = vec2(0.03, 0.07);
uniform float wave_strength = 2;
uniform float scale_y;
uniform float y_zoom;

// --- New "Cutout" Uniforms ---
uniform float surface_speed = 3.0;
uniform float surface_frequency = 10.0;
uniform float surface_amplitude = 0.02; // 0.02 means 2% of the sprite height

void fragment() {
	// 1. Calculate the Sine Wave
	// We oscillate around 0.0.
	float wave_offset = sin(UV.x * surface_frequency + TIME * surface_speed) * surface_amplitude;
	
	// 2. Define the Water Level
	// We want the average water level to be slightly down (by the amplitude amount)
	// so the peaks of the waves don't get cut off by the top of the sprite.
	float current_water_level = surface_amplitude + wave_offset;
	
	// 3. The Cutout Check
	// If the current pixel is higher (lower UV.y value) than the water level, make it invisible.
	if (UV.y < current_water_level) {
		COLOR.a = 0.0;
	} else {
		// --- Your Original Reflection Logic (Runs only for water pixels) ---
		vec2 uv = UV + speed * TIME;
		vec2 noise = texture(fast_noise, uv).rg;
		float uv_height = (SCREEN_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.y);
		
		vec2 refelected_uv = vec2(SCREEN_UV.x, SCREEN_UV.y - (uv_height * UV.y * scale_y * y_zoom));
		vec4 refelection = texture(SCREEN_TEXTURE, refelected_uv);
		vec4 waves = texture(SCREEN_TEXTURE, refelected_uv + noise * y_zoom * (wave_strength / 100.0));
		
		COLOR = waves + CAST_COLOR;
	}
} 