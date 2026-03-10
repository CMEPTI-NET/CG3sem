const int MAX_MARCHING_STEPS = 100;
const float MIN_DIST = 0.01;
const float MAX_DIST = 100.0;
const float PRECISION = 0.001;

struct Surface {
    float dist;
    vec3 color;
};

Surface opU(Surface d1, Surface d2) {
    if (d1.dist <= d2.dist) {
        return d1;
    } else {
        return d2;
    }
}

mat3 rotateY(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(vec3(c,0,s), vec3(0,1,0), vec3(-s,0,c));
}

mat3 rotateX(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(vec3(1,0,0), vec3(0,c,-s), vec3(0,s,c));
}

mat3 rotateZ(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(vec3(c,-s,0), vec3(s,c,0), vec3(0,0,1));
}

//СДФ-ки
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdCylinder(vec3 p, vec3 a, vec3 b, float r) {
    vec3 ba = b - a;
    vec3 pa = p - a;
    float baba = dot(ba,ba);
    float paba = dot(pa,ba);
    float x = length(pa*baba-ba*paba) - r*baba;
    float y = abs(paba-baba*0.5)-baba*0.5;
    float x2 = x*x;
    float y2 = y*y*baba;
    float d = (max(x,y)<0.0)?-min(x2,y2):(((x>0.0)?x2:0.0)+((y>0.0)?y2:0.0));
    return sign(d)*sqrt(abs(d))/baba;
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
    return length(pa - ba*h) - r;
}

// СДФ для основания корабля
float sdHalfCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float capsuleDist = length(pa - ba * h) - r;
    float cutPlane = p.y;
    return max(capsuleDist, cutPlane);
}

//основание
float sdHull(vec3 p, float length, float width, float height) {
    vec3 a = vec3(-length * 0.5, 0, 0);
    vec3 b = vec3(length * 0.5, 0, 0);
    return sdHalfCapsule(p, a, b, width * 0.3);
}

float sdBridge(vec3 p, float size) {
    return sdSphere(p, size * 0.5);
}
//мачта
float sdMast(vec3 p, float height) {
    return sdCapsule(p, vec3(0, 0, 0), vec3(0, height, 0), 0.05);
}

float sdSail(vec3 p, float width, float height) {
    float sailBend = sin(p.y * 2.0) * 0.1;
    p.z += sailBend;
    p.y -= height * 0.5;
    return sdBox(p, vec3(0.02, height * 0.5, width * 0.5));
}

// Пушка 
float sdCannon(vec3 p, float length, vec2 rotation) {
    p = rotateY(-rotation.x * 1.5) * p; 
    p = rotateX(rotation.y * 0.8) * p; 
    
    vec3 a = vec3(0, 0, -length * 0.1);
    vec3 b = vec3(0, 0, length * 0.9);
    return sdCapsule(p, a, b, 0.03);
}

//волны качаются 
float getWaveHeight(vec2 pos, float time) {
    float baseWave = sin(pos.x * 0.5 + time * 1.5) * 0.2 +
                    sin(pos.x * 0.8 + time * 1.2) * 0.15 +
                    sin(pos.y * 0.6 + time * 1.0) * 0.15;
    return baseWave * 0.4;
}

//полностью корабль
Surface sdPlayerShip(vec3 p) {
    vec4 state = texelFetch(iChannel0, ivec2(0,0), 0);
    vec2 shipPos = state.xy;
    float shipAngle = state.z;
    
    vec3 shipCenter = vec3(shipPos.x, 0.0, shipPos.y - 6.0);
    float time = iTime;
    
    vec3 q = p - shipCenter;
    q = rotateY(shipAngle) * q;
    
    //качка от волн 
    float waveHeight = getWaveHeight(shipCenter.xz, time);
    float roll = sin(time * 0.8 + shipCenter.x * 0.5) * 0.1;
    float pitch = sin(time * 0.6 + shipCenter.z * 0.3) * 0.05;
    
    q.xz = mat2(cos(roll), -sin(roll), sin(roll), cos(roll)) * q.xz;
    q.xy = mat2(cos(pitch), -sin(pitch), sin(pitch), cos(pitch)) * q.xy;
    
    q.y -= 0.2;
    
    vec3 hullColor = vec3(0.6, 0.8, 0.2);
    vec3 sailColor = vec3(0.9, 0.9, 0.8);
    vec3 cannonColor = vec3(0.3, 0.3, 0.3);
    vec3 bridgeColor = vec3(0.7, 0.5, 0.3);
    
    Surface scene = Surface(1e10, vec3(0.0));
    
    vec3 hullPos = q - vec3(0, 0., 0);
    Surface hull = Surface(sdHull(hullPos, 1., 1.7, 0.4), hullColor);
    scene = opU(scene, hull);
    
    vec3 bridgePos = q - vec3(0.4, 0.0, 0);
    Surface bridge = Surface(sdBridge(bridgePos, 0.4), bridgeColor);
    scene = opU(scene, bridge);
    

    vec3 mastPos = q - vec3(0, 0.0, 0);
    Surface mast = Surface(sdMast(mastPos, 1.0), bridgeColor);
    scene = opU(scene, mast);
    
    vec3 sailPos1 = q + vec3(-0.03, -0.3, 0);
    Surface sail1 = Surface(sdSail(sailPos1, 0.7, 1.2), sailColor);
    scene = opU(scene, sail1);
    
    // пушка читает буффер 2 
    vec4 cannonData = texelFetch(iChannel1, ivec2(0,1), 0);
    vec3 cannonPos = q - vec3(0.4, 0.1, 0.0);
    Surface cannon = Surface(sdCannon(cannonPos, 0.6, cannonData.xy), cannonColor);
    scene = opU(scene, cannon);
    

    
    return scene;
}



// врагиии
Surface sdEnemyShip(vec3 p, vec3 enemyPos, vec3 playerPos) {
    vec3 q = p - enemyPos;
    float time = iTime;
    
    //
    vec3 toPlayer = playerPos - enemyPos;
    toPlayer.y = 0.0; 
    float targetAngle = atan(toPlayer.x, toPlayer.z);
    
    // Применяем вращение к вражескому кораблю
    q = rotateY(targetAngle) * q;
    
    float waveHeight = getWaveHeight(enemyPos.xz, time);
    float roll = sin(time * 0.8 + enemyPos.x * 0.5) * 0.1;
    float pitch = sin(time * 0.6 + enemyPos.z * 0.3) * 0.05;
    
    q.xz = mat2(cos(roll), -sin(roll), sin(roll), cos(roll)) * q.xz;
    q.xy = mat2(cos(pitch), -sin(pitch), sin(pitch), cos(pitch)) * q.xy;
    q.y -= 0.2;
    
    vec3 enemyHullColor = vec3(0.5, 0.1, 0.8);
    vec3 enemySailColor = vec3(0.95, 0.8, 0.8);
    
    Surface scene = Surface(1e10, vec3(0.0));
    
    vec3 hullPos = q - vec3(0, 0., 0);
    Surface hull = Surface(sdHull(hullPos, 1., 1.7, 0.4), enemyHullColor);
    scene = opU(scene, hull);
    
    vec3 bridgePos = q - vec3(0.4, 0.0, 0);
    Surface bridge = Surface(sdBridge(bridgePos, 0.4), vec3(0.9, 0.6, 0.6));
    scene = opU(scene, bridge);
    
    vec3 mastPos = q - vec3(0, 0.0, 0);
    Surface mast = Surface(sdMast(mastPos, 1.0), vec3(0.9, 0.6, 0.6));
    scene = opU(scene, mast);
    
    vec3 sailPos1 = q + vec3(-0.03, -0.3, 0);
    Surface sail1 = Surface(sdSail(sailPos1, 0.7, 1.2), enemySailColor);
    scene = opU(scene, sail1);
    
    return scene;
}
Surface sdWater(vec3 p) {
    float wave = getWaveHeight(p.xz, iTime);
    float waterDist = p.y - wave;
    vec3 waterColor = vec3(0.1, 0.3, 0.8);
    return Surface(waterDist, waterColor);
}

Surface sdBullet(vec3 p) {
    vec4 bullet = texelFetch(iChannel3, ivec2(0,0), 0);
    if (bullet.w > 0.5) {
        float bulletDist = sdSphere(p - bullet.xyz, 0.15);
        return Surface(bulletDist, vec3(1.0, 0.9, 0.1));
    }
    return Surface(MAX_DIST, vec3(0.0));
}

Surface sdExplosion(vec3 p) {
    vec4 explosion = texelFetch(iChannel3, ivec2(3,0), 0);
    if (explosion.w > 0.0) {
        float explosionDist = sdSphere(p - explosion.xyz, explosion.w * 2.5);
        vec3 explosionColor = mix(vec3(1.0,0.5,0.0), vec3(1.0,0.9,0.3), explosion.w);
        return Surface(explosionDist, explosionColor);
    }
    return Surface(MAX_DIST, vec3(0.0));
}


Surface sdScene(vec3 p) {
    Surface scene = Surface(MAX_DIST, vec3(0.0));
    
    Surface water = sdWater(p);
    scene = opU(scene, water);
    
    Surface player = sdPlayerShip(p);
    scene = opU(scene, player);
    
    vec4 enemy1 = texelFetch(iChannel3, ivec2(2,0), 0);
    vec4 enemy2 = texelFetch(iChannel3, ivec2(5,0), 0);
    vec4 playerData = texelFetch(iChannel0, ivec2(0,0), 0);
    vec3 playerPos = vec3(playerData.x, 0.0, playerData.y - 6.0);
    
    if (enemy1.w > 0.5) {
        // Передаем позицию игрока для вращения врага
        Surface enemyShip1 = sdEnemyShip(p, enemy1.xyz, playerPos);
        scene = opU(scene, enemyShip1);
    }
    
    if (enemy2.w > 0.5) {
        Surface enemyShip2 = sdEnemyShip(p, enemy2.xyz, playerPos);
        scene = opU(scene, enemyShip2);
    }
    
    Surface bullet = sdBullet(p);
    scene = opU(scene, bullet);
    
    Surface explosion = sdExplosion(p);
    scene = opU(scene, explosion);
    
    return scene;
}
float rayMarch(vec3 ro, vec3 rd) {
    float depth = 0.0;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        vec3 p = ro + depth * rd;
        float dist = sdScene(p).dist;
        if (dist < PRECISION) return depth;
        depth += dist;
        if (depth > MAX_DIST) return MAX_DIST;
    }
    return MAX_DIST;
}

vec3 calcNormal(vec3 p) {
    vec2 eps = vec2(0.001, 0.0);
    return normalize(vec3(
        sdScene(p + eps.xyy).dist - sdScene(p - eps.xyy).dist,
        sdScene(p + eps.yxy).dist - sdScene(p - eps.yxy).dist,
        sdScene(p + eps.yyx).dist - sdScene(p - eps.yyx).dist
    ));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    vec4 state = texelFetch(iChannel0, ivec2(0,0), 0);
    vec2 shipPos = state.xy;
    float shipAngle = state.z;
    
    
    
    vec3 shipCenter = vec3(shipPos.x, 0.0, shipPos.y);
    
    // управление камерой
    vec2 mouseUV = iMouse.xy / iResolution.xy;
    bool mouseClicked = iMouse.z > 0.5;
    
    if (length(iMouse.xy) < 1.0) {
        mouseUV = vec2(0.5, 0.3);
    }
    
    float cameraDistance = 8.0;
    float cameraHeight = 3.0;
    
    float cameraYaw = (mouseUV.x - 0.5) * 4.0; 
    float cameraPitch = (mouseUV.y - 0.5) * 1.5 + 0.3;
    
    vec3 cameraOffset = vec3(
        sin(cameraYaw) * cos(cameraPitch) * cameraDistance,
        sin(cameraPitch) * cameraDistance + cameraHeight,
        cos(cameraYaw) * cos(cameraPitch) * cameraDistance
    );
    
    vec3 ro = shipCenter + cameraOffset;
    vec3 target = shipCenter;
    
    vec3 forward = normalize(target - ro);
    vec3 right = normalize(cross(forward, vec3(0.0,1.0,0.0)));
    vec3 up = cross(right, forward);
    
    float fov = 0.8;
    vec3 rd = normalize(forward + uv.x * right * fov + uv.y * up * fov);
    
    float dist = rayMarch(ro, rd);
    
    vec3 color;
    
    if (dist < MAX_DIST) {
        vec3 p = ro + rd * dist;
        vec3 normal = calcNormal(p);
        Surface surface = sdScene(p);
        
        vec3 lightPos = vec3(5, 8, -3);
        vec3 lightDir = normalize(lightPos - p);
        float diff = max(dot(normal, lightDir), 0.0);
        
        color = surface.color * (diff + 0.2);
        
        if (surface.dist < 0.1 && p.y < 1.0) {
            float spec = pow(max(dot(reflect(-lightDir, normal), -rd), 0.0), 32.0);
            color += vec3(0.8,0.9,1.0) * spec * 0.3;
        }
        
        // Эффект от взрыва
        vec4 explosion = texelFetch(iChannel3, ivec2(3,0), 0);
        if (explosion.w > 0.0) {
            float distToExplosion = distance(p, explosion.xyz);
            float glow = explosion.w * (1.0 - smoothstep(0.0, 4.0, distToExplosion));
            color += vec3(1.0,0.6,0.2) * glow;
        }
        
    } else {
        color = mix(vec3(0.3,0.5,0.9), vec3(0.6,0.8,1.0), uv.y + 0.5);
    }
    
    fragColor = vec4(color, 1.0);
}