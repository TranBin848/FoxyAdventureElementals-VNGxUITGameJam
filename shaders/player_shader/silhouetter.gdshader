shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

uniform vec4 silhouette_color : source_color = vec4(0.0, 0.0, 0.0, 0.5); // Default: Semi-transparent black

uniform float color_tolerance : hint_range(0.0, 0.2) = 0.05;

void fragment() {

	vec4 sprite_color = texture(TEXTURE, UV);


	if (sprite_color.a <= 0.01) {
		discard;
	}


	vec4 screen_color = texture(screen_texture, SCREEN_UV);


	bool colors_match = all(lessThan(abs(sprite_color - screen_color), vec4(color_tolerance)));


	if (colors_match) {

		COLOR = sprite_color;
	} else {

		COLOR = vec4(silhouette_color.rgb, silhouette_color.a * sprite_color.a);
	}
}