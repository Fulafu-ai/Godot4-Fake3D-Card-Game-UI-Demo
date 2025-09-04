//#include "res://_Library/space.gdshaderinc"

float cross2d(vec2 a, vec2 b) {
    return a.x * b.y - a.y * b.x;
}


vec2 rec2polar(vec2 rec){
	vec2 polar = vec2(atan(rec.y, rec.x) / TAU, length(rec));
	return polar;
}


vec2 uv2rec(vec2 uv){
	vec2 rec = (uv - 0.5) * 2.0;
	return rec;
}