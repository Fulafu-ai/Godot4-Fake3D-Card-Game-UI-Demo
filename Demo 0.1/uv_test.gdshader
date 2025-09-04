shader_type canvas_item;

bool display_rec(vec2 length_width, vec2 uv){
	if (uv.x > 0.5 - length_width.x/2.0 && uv.x < 0.5 + length_width.x/2.0 &&
	uv.y > 0.5 - length_width.y/2.0 && uv.y < 0.5 + length_width.y/2.0){
		return true;
		}else{
			return false;
			}
}


bool display_disk(float radius, vec2 uv, vec2 degree){
	//令圆心为正中央并且在sprite中正好放下一个单位圆
	uv = (uv - 0.5) * 2.0;
	vec2 polar = vec2(atan(uv.y, uv.x), length(uv));
	if (polar.y < radius &&
	polar.x > degree.x && polar.x < degree.y){
		return true;
		}else{
			return false;
			}
}


bool display_ring(float inner_radius, float out_radius, vec2 uv, vec2 degree){
	//令圆心为正中央并且在sprite中正好放下一个单位圆
	uv = (uv - 0.5) * 2.0;
	vec2 polar = vec2(atan(uv.y, uv.x), length(uv));
	if (inner_radius < polar.y && polar.y < out_radius &&
	polar.x > degree.x && polar.x < degree.y){
		return true;
		}else{
			return false;
			}
}


void fragment() {
	bool display = false;

	display = display_ring(0.3, 0.8, UV, vec2(-PI, -2.0 * PI / 3.0))||
	display_ring(0.3, 0.8, UV, vec2(-PI / 3.0, 0.0))||
	display_ring(0.3, 0.8, UV, vec2(PI / 3.0, 2.0 * PI / 3.0))||
	display_disk(0.2, UV, vec2(-PI, PI));

	if(display){
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	}else{
		COLOR = vec4(1.0, 1.0, 0.0, 1.0);
	}
}

