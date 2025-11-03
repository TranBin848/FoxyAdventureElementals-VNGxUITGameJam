shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0);
uniform float line_thickness : hint_range(0, 10) = 1.0;
uniform float glow_opacity : hint_range(0, 1) = 0.75;
uniform float glow_thickness : hint_range(0, 10) = 1.0;

const vec2 OFFSETS[5] = {
	vec2(-1, 0), vec2(-1, 1), vec2(0, 1), vec2(1, 0), vec2(1, 1)
};

void vertex() {
	// Called for every vertex the material is visible on.
	
}

void fragment() {
	//if(COLOR == vec4(0, 0, 0, 1)){
		//COLOR = line_color;
	//}
	if(COLOR.a == 0.0){
		vec2 line_pixel_distance = TEXTURE_PIXEL_SIZE * line_thickness;
		vec2 glow_pixel_distance = line_pixel_distance + TEXTURE_PIXEL_SIZE * glow_thickness;
		float outline = 0.0;
		
		for (int i = 0; i < OFFSETS.length(); i++) {
			//outline += texture(TEXTURE, UV + size * OFFSETS[i]).a;
			if (texture(TEXTURE, UV + line_pixel_distance * OFFSETS[i]).a == 1.0f){
				outline = 1.0;
			}
		}
		if (outline != 1.0){
			for (int i = 0; i < OFFSETS.length(); i++) {
				if(texture(TEXTURE, UV + glow_pixel_distance * OFFSETS[i]).a == 1.0f){
					outline = glow_opacity;
				}
			}
		}
		//outline = min(outline, 1.0);
		
		vec4 color = texture(TEXTURE, UV);
		COLOR = mix(color, line_color, outline - color.a);
	}

}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
