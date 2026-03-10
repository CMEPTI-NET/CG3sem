const int KEY_LEFT  = 102;
const int KEY_RIGHT = 100;
const int KEY_SPACE = 32;


vec2 handleKeyboard(vec2 offset) {
    float velocity = 4.4; // смещение на одну сотую при нажатии

    
    vec2 left = texelFetch(iChannel1, ivec2(KEY_LEFT, 0), 0).x * vec2(-1, 0);
    vec2 right = texelFetch(iChannel1, ivec2(KEY_RIGHT, 0), 0).x * vec2(1, 0);

    offset += (left + right) * velocity * iTimeDelta;

    return offset;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 offset = texelFetch( iChannel0, ivec2(0, 0), 0).xy; //Возвращает значение смещения от последнего кадра
    offset = handleKeyboard(offset);
    
    float space = texelFetch(iChannel1, ivec2(KEY_SPACE, 0), 0).x;

    // смещенение для каждого пикселz

    fragColor = vec4(offset, space, 0);
}