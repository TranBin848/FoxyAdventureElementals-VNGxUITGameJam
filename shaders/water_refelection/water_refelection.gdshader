shader_type canvas_item;

uniform vec4 CAST_COLOR: source_color;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;

uniform sampler2D fast_noise: repeat_enable;

uniform vec2 speed = vec2(0.03, 0.07);

uniform float wave_strength = 2;

uniform float scale_y;
uniform float y_zoom;

void vertex() {
	VERTEX.y += sin(TIME) * 0.01;
}

void fragment() {
	vec2 uv = UV + speed * TIME;
	
	vec2 noise = texture(fast_noise, uv).rg;
	
	float uv_height = (SCREEN_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.y);
	
	vec2 refelected_uv = vec2(SCREEN_UV.x, SCREEN_UV.y - (uv_height * UV.y * scale_y* y_zoom));
	
	vec4 refelection = texture(SCREEN_TEXTURE, refelected_uv);
	
	vec4 waves = texture(SCREEN_TEXTURE, refelected_uv + noise * y_zoom * (wave_strength / 100.0));
	
	COLOR = waves + CAST_COLOR;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
