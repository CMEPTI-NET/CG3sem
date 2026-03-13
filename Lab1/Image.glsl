const float accuracy = 0.015; 
const float limit = 0.15;
const float speed = 0.8;
const bool hard = true;

struct Surface {
  float dist;
  vec3 color;
};

float sdLineX(vec2 uv, float n){
    float d = n * iResolution.x/iResolution.y;
    d = uv.x - d;
    return d;
}

Surface sdLineRoad(vec2 uv, float n, vec3 colorRoad){
    Surface s;
    s.dist = n * iResolution.x/iResolution.y;
    s.dist = abs(uv.x - s.dist);
    
    s.color = vec3(1., 1., 1.);
    float phase = mod(uv.y + iTime * speed, 0.24);
    if (phase < 0.1) {
        s.color = colorRoad;
    }
    
    return s;
}

Surface sdRectangle(vec2 uv, vec2 r, vec2 offset, vec3 color){
    Surface s;
    vec2 d = abs(uv-offset) - r;
    s.dist = length(max(d,0.)) + min(max(d.x,d.y),0.); 
    s.color = color;
    return s;
}

Surface sdCircle( vec2 uv, float r, vec2 offset, vec3 color )
{
    Surface s;
    s.dist = length(uv - offset) - r;
    s.color = color;
    return s;
}

float dot2(in vec2 v ) { return dot(v,v); }

Surface sdTrapezoid( in vec2 p, in float r1, float r2, float he, vec2 offset ,vec3 color)
{
    Surface s;
    vec2 k1 = vec2(r2,he);
    vec2 k2 = vec2(r2-r1,2.0*he);
    p -= offset;
    p.x = abs(p.x);
    vec2 ca = vec2(p.x-min(p.x,(p.y<0.0)?r1:r2), abs(p.y)-he);
    vec2 cb = p - k1 + k2*clamp( dot(k1-p,k2)/dot2(k2), 0.0, 1.0 );
    float i = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
    s.dist = i*sqrt( min(dot2(ca),dot2(cb)) );
    s.color = color;
    
    return s;
}

vec2 rotate(vec2 uv, float th) {
  return mat2(cos(th), sin(th), -sin(th), cos(th)) * uv;
}

Surface sdCar(vec2 uv){
    Surface s;
    Surface dec;
    
    float Xuv = iResolution.x/iResolution.y;
    vec2 offset = vec2(Xuv*(limit+0.07),0.2);
    float keyboardX = texelFetch( iChannel0, ivec2(0,0),0).x;
    offset.x += keyboardX * (Xuv*(1. - 2.*limit - 0.13));
    
    float rotateN = texelFetch( iChannel0, ivec2(0,0),0).y * 60.0;;
    vec2 rotateUv = rotate(uv - offset,radians(rotateN)) + offset;
    
    float LocalAccuracy = accuracy * 0.1;
    
    vec3 windowColor = vec3(0.,0.5,0.7);
    vec3 carColor = vec3(0.8,0.2,0.45);
    vec3 lightUp = vec3(0.8,0.8,0.);
    vec3 lightDown = vec3(0.8,0.1,0.);
    
    s = sdRectangle(rotateUv,vec2(0.085,0.15),offset,carColor); // корпус
    
    //Колёса
    dec = sdRectangle(rotateUv,vec2(0.1,0.02),vec2(offset.x,offset.y+0.1),vec3(0.,0.,0.));
    if(s.dist>accuracy && dec.dist <= accuracy) { s = dec;}
    dec = sdRectangle(rotateUv,vec2(0.1,0.02),vec2(offset.x,offset.y-0.1),vec3(0.,0.,0.));
    if(s.dist>accuracy && dec.dist <= accuracy) { s = dec;}
    
    
    dec = sdRectangle(rotateUv,vec2(0.075,0.077),vec2(offset.x,offset.y-0.03),carColor-0.08);//крыша
    if (dec.dist <= LocalAccuracy) {s.color = dec.color;}    
    
    
    return s;
}

float rand(vec2 co)
{
   return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}

float yPosCycle(float seed, float minDelay, float maxDelay){
    float r = rand(vec2(seed*210.)) * maxDelay;
    float cycleTime = mod(iTime + r, (minDelay/speed) + maxDelay);
    return 1.1 - cycleTime * speed;
}

Surface sdTree(vec2 uv, float xPos) {
    Surface s;
    Surface dec;
    
    float yPos = yPosCycle(xPos, 0.5, 2.2);
    vec2 center = vec2(xPos, yPos);
    
    float angle = radians(45.0);
    vec2 rotatedUv = rotate(uv - center, angle) + center;
    s = sdRectangle(rotatedUv, vec2(0.07, 0.07), center, vec3(0., 0.7, 0.));
    
    angle = radians(22.5);
    rotatedUv = rotate(uv - center, angle) + center;
    dec = sdRectangle(rotatedUv, vec2(0.052, 0.052), center, vec3(0., 0.65, 0.)); 
    if (dec.dist <= accuracy) {s.color = dec.color;}
    
    dec = sdRectangle(uv, vec2(0.03, 0.03), center, vec3(0., 0.6, 0.)); 
    if (dec.dist <= accuracy) {s.color = dec.color;}
    
    return s;
}

float spawnIndex(float seed, float minDelay, float maxDelay) {
    float cycleTime = (minDelay / speed) + maxDelay;
    return floor((iTime + seed) / cycleTime);
}

float xPosCycle(float seed, float minDelay, float maxDelay) {
    float index = spawnIndex(seed, minDelay, maxDelay);
    float r = rand(vec2(seed, index));
    return ceil(rand(vec2(seed, r))*4.) * (iResolution.x/iResolution.y*(1.-2.0*limit))/4.+limit;
}

Surface sdHole( vec2 uv, float seed)
{
    Surface s;
    Surface dec;
    
    float xPos = xPosCycle(seed, 1.0, 4.2);
    float yPos = yPosCycle(seed, 1.0, 4.2);
    
    s = sdCircle(uv, 0.12, vec2(xPos,yPos),vec3(0.4,0.4,0.4));
    dec = sdCircle(uv, 0.1, vec2(xPos,yPos),vec3(0.2,0.2,0.2));
    if (dec.dist <= accuracy) {s.color = dec.color;}
    dec = sdCircle(uv, 0.09, vec2(xPos,yPos),vec3(0.11,0.11,0.11));
    if (dec.dist <= accuracy) {s.color = dec.color;}
    return s;
}

Surface sdBox( vec2 uv, float seed)
{
    Surface s;
    Surface dec;
    
    float xPos = xPosCycle(seed, 1.8, 3.9);
    float yPos = yPosCycle(seed, 1.8, 3.9);
    vec2 center = vec2(xPos,yPos);
    s = sdRectangle(uv, vec2(0.075, 0.075), center, vec3(0.7, 0.4, 0.)); 
    dec = sdRectangle(uv, vec2(0.07, 0.003), (center- vec2(0.,0.06)), vec3(0.6, 0.3, 0.)); 
    if (dec.dist <= accuracy) {s.color = dec.color;}
    
    dec = sdRectangle(uv, vec2(0.07, 0.003), (center- vec2(0.,-0.06)), vec3(0.6, 0.3, 0.)); 
    if (dec.dist <= accuracy) {s.color = dec.color;}
    
    float angle = radians(-45.0);
    vec2 rotatedUv = rotate(uv - center, angle) + center;
    dec = sdRectangle(rotatedUv, vec2(0.09,0.003), center, vec3(0.55, 0.25, 0.)); 
    if (dec.dist <= accuracy) {s.color = dec.color;}
    return s;
}

vec4 DrawScene(vec2 uv){

    float Xuv = iResolution.x/iResolution.y;

    // задник
    vec3 OutColor = vec3(0.45,0.45,0.45);
    if (sdLineX(uv, limit) < accuracy) { OutColor = vec3(0., 0., 0.); }
    if (sdLineX(uv, 1. - limit) > accuracy) { OutColor = vec3(0., 0., 0.); }
    if (sdLineX(uv, limit - accuracy) < accuracy) { OutColor = vec3(0., 0.5, 0.); }
    if (sdLineX(uv, 1. - limit + accuracy) > accuracy) { OutColor = vec3(0., 0.5, 0.); }
    Surface LineRoad = sdLineRoad(uv, 0.5, vec3(0.45,0.45,0.45));
    if (LineRoad.dist < accuracy) { OutColor = LineRoad.color; }
    
    //задник движ
    Surface tree = sdTree(uv, 0.12);
    if (tree.dist < accuracy) {OutColor = tree.color;}
    tree = sdTree(uv, 0.15);
    if (tree.dist < accuracy) {OutColor = tree.color;}
    tree = sdTree(uv, 0.19);
    if (tree.dist < accuracy) {OutColor = tree.color;}
    tree = sdTree(uv, 0.17);
    if (tree.dist < accuracy) {OutColor = tree.color;}
    tree = sdTree(uv, 0.14);
    if (tree.dist < accuracy) {OutColor = tree.color;}
    
    tree = sdTree(uv, Xuv - 0.12);
    if (tree.dist < accuracy) {OutColor = tree.color;}
    tree = sdTree(uv, Xuv - 0.15);
    if (tree.dist < accuracy) {OutColor = tree.color;}
    tree = sdTree(uv, Xuv - 0.19);
    if (tree.dist < accuracy) {OutColor = tree.color;}
    tree = sdTree(uv, Xuv - 0.17);
    if (tree.dist < accuracy) {OutColor = tree.color;}
    tree = sdTree(uv, Xuv - 0.14);
    if (tree.dist < accuracy) {OutColor = tree.color;}
    
    //дорога движ
    Surface enemy1 = sdBox(uv,2.42);
    if (enemy1.dist < accuracy) {OutColor = enemy1.color;}
    Surface enemy2= sdBox(uv,2.92);
    if (enemy2.dist < accuracy) {OutColor = enemy2.color;}
    Surface enemy3 = sdBox(uv,3.82);
    if (enemy3.dist < accuracy) {OutColor = enemy3.color;}
    
    //машина
    Surface car = sdCar(uv);
    if (car.dist < accuracy) {OutColor = car.color;}
    
    if(hard == true){
        if(car.dist <= accuracy && min(min(enemy1.dist,enemy2.dist),enemy3.dist) <= accuracy){
            OutColor = vec3(0.3,0.,0.);
        }
    }
    
    return vec4(OutColor,1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    vec2 uv = fragCoord.xy / iResolution.y; 
    
    fragColor = DrawScene(uv);
}