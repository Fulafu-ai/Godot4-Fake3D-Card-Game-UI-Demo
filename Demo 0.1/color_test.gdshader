shader_type canvas_item;

//uniform关键字相当于@export，source_color代表有颜色编辑器形式的变量
uniform vec4 in_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 out_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D gradient_texture;

vec3 hsv2rgb(vec3 hsv) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(hsv.xxx + K.xyz) * 6.0 - K.www);
	return hsv.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), hsv.y);
	}


void fragment() {
	//vec4 color = (1.0 - UV.x) * in_color + UV.x * out_color;
	vec4 color = texture(gradient_texture, vec2(UV.x, 0.0));
	COLOR = color;
}

