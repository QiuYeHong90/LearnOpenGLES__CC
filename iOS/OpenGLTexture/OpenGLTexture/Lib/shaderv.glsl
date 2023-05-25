attribute vec3 vPosition;
attribute vec4 a_Color;

varying lowp vec4 frag_Color;
void main(void)
{
    frag_Color = a_Color;
//    gl_Position = vec4(vPosition.xyz,1);
    gl_Position = vec4(vPosition.x,vPosition.y,vPosition.z,1.0);
}
