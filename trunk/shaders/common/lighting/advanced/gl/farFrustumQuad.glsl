

vec2 getUVFromSSPos( vec3 ssPos, vec4 rtParams )
{
	vec2 outPos = ( ssPos.xy + 1.0 ) / 2.0;
	outPos.y = 1.0 - outPos.y;
	outPos = ( outPos * rtParams.zw ) + rtParams.xy;
	return outPos;
}
