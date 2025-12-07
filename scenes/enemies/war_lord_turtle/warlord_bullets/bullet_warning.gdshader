shader_type canvas_item;

uniform float thickness = 20.0;
uniform vec4 warning_color = vec4(1.0, 0.2, 0.2, 1.0);
uniform float speed = 6.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);

    float pulse = (sin(TIME * speed) * 0.5) + 0.5;

    // Nếu pixel trong suốt → kiểm tra viền
    if (col.a == 0.0) {
        float outline = 0.0;
        vec2 px = TEXTURE_PIXEL_SIZE;

        outline += texture(TEXTURE, UV + vec2(px.x * thickness, 0.0)).a;
        outline += texture(TEXTURE, UV - vec2(px.x * thickness, 0.0)).a;
        outline += texture(TEXTURE, UV + vec2(0.0, px.y * thickness)).a;
        outline += texture(TEXTURE, UV - vec2(0.0, px.y * thickness)).a;

        if (outline > 0.0) {
            COLOR = warning_color * pulse;
        }
		else
		{
    		// pixel gốc
    		COLOR = col;
			
		}
    }

}
