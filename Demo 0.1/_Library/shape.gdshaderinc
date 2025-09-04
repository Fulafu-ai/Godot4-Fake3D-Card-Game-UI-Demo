//#include "res://_Library/shape.gdshaderinc"

#include "space.gdshaderinc"


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
	vec2 polar = rec2polar(uv2rec(uv));
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


bool display_tri(vec2 a, vec2 b, vec2 c, vec2 uv) {
    //坐标变换
	vec2 p = (uv - 0.5) * 2.0;
	
	// 计算向量
    vec2 v0 = b - a;
    vec2 v1 = c - a;
    vec2 v2 = p - a;
    
    // 计算叉积
    float d00 = dot(v0, v0);
    float d01 = dot(v0, v1);
    float d02 = dot(v0, v2);
    float d11 = dot(v1, v1);
    float d12 = dot(v1, v2);
    
    // 计算重心坐标 (u, v)
    float inv_denom = 1.0 / (d00 * d11 - d01 * d01);
    float u = (d11 * d02 - d01 * d12) * inv_denom;
    float v = (d00 * d12 - d01 * d02) * inv_denom;
    
    // 检查点是否在三角形内
    return (u >= 0.0) && (v >= 0.0) && (u + v <= 1.0);
}