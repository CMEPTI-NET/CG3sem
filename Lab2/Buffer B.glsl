const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;

const float velocity = 1.;


vec2 handleKeyboard(vec2 offset) {
    vec2 left = texelFetch(iChannel1, ivec2(KEY_LEFT, 0), 0).x * vec2(-1, 0);
    vec2 up = texelFetch(iChannel1, ivec2(KEY_UP,0), 0).x * vec2(0, -1);
    vec2 right = texelFetch(iChannel1, ivec2(KEY_RIGHT, 0), 0).x * vec2(1, 0);
    vec2 down = texelFetch(iChannel1, ivec2(KEY_DOWN, 0), 0).x * vec2(0, 1);

    offset += (left + up + right + down) * velocity * iTimeDelta;

    return offset;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 offset = texelFetch( iChannel0, ivec2(0, 0), 0).xy; //Возвращает значение смещения от последнего кадра
    offset = handleKeyboard(offset);
    
    if (offset.y < -0.25){ offset.y = -0.25;}
    if (offset.y > 0.12){ offset.y = 0.12;}
    if (offset.x < -1.55){ offset.x = -1.55;}
    if (offset.x > 1.55){ offset.x = 1.55;}
    

    fragColor = vec4(offset, 0, 0);
}
