shader_type canvas_item;

#include "res://_Library/color.gdshaderinc"
#include "res://_Library/shape.gdshaderinc"
#include "res://_Library/space.gdshaderinc"

uniform sampler2D gradient_texture;
uniform sampler2D alpha_curve;


float input_curve(float x, float from, float to, sampler2D curve_texture) {
	float _x = (x - from) / (to - from);
	return texture(curve_texture, vec2(_x, 0.0)).x;
}


void fragment() {
	bool display0 = false;
	bool display1 = false;
	vec2 uv_polar = rec2polar(uv2rec(UV));
	vec4 color0 = vec4(hsv2rgb(vec3(uv_polar.x, 1.0, 1.0)), input_curve(uv_polar.y, 0.9, 0.6, alpha_curve));
	vec4 color1 = texture(gradient_texture, vec2((UV.x - 0.375) * 8.0 / 3.0, 0.0));

	display0 = display_ring(0.6, 0.9, UV, vec2(-PI, PI));
	display1 = display_tri(vec2(-0.25, -sqrt(3)*0.25), vec2(-0.25, sqrt(3)*0.25), vec2(0.5, 0.0), UV);

	if(display0){
		COLOR = color0;
	}else if(display1){
		COLOR = color1;
	}else{
		COLOR = vec4(1.0, 1.0, 1.0, 0.0);
	}
}
