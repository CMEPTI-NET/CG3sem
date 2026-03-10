const int KEY_RIGHT = 65;
const int KEY_UP = 87;
const int KEY_LEFT = 68;
const int KEY_DOWN = 83;
const int KEY_Q = 81;
const int KEY_E = 69;

struct ShipState {
    vec2 pos;   
    float rot;  
};

ShipState handleKeyboard(ShipState state) {
    float moveSpeed = 8.0;
    float turnSpeed = 2.0;

    float left  = texelFetch(iChannel1, ivec2(KEY_LEFT, 0), 0).x;
    float right = texelFetch(iChannel1, ivec2(KEY_RIGHT,0), 0).x;
    float up    = texelFetch(iChannel1, ivec2(KEY_UP,   0), 0).x;
    float down  = texelFetch(iChannel1, ivec2(KEY_DOWN, 0), 0).x;
    float q     = texelFetch(iChannel1, ivec2(KEY_Q,    0), 0).x;
    float e     = texelFetch(iChannel1, ivec2(KEY_E,    0), 0).x;

    // Поворот на Q/E
    state.rot += (e - q) * turnSpeed * iTimeDelta;

    // Движение в разные стороны немного кривое
    vec2 movement = vec2(0.0);
    movement.x += right - left;
    movement.y += up - down;
    
    // Поворачиваем движение относительно направления корабля
    vec2 forward = vec2(sin(state.rot), cos(state.rot));
    vec2 rightDir = vec2(cos(state.rot), -sin(state.rot));
    
    vec2 worldMovement = forward * movement.y + rightDir * movement.x;
    
    state.pos += worldMovement * moveSpeed * iTimeDelta;

    return state;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 prev = texelFetch(iChannel0, ivec2(0, 0), 0);
    ShipState state;
    
    if (iFrame < 5) {
        state = ShipState(vec2(0.0, -10.0), 0.0); // начальная позиция дальше от камеры
    } else {
        state = ShipState(prev.xy, prev.z);
    }
    
    state = handleKeyboard(state);
    fragColor = vec4(state.pos, state.rot, 1.0);
}