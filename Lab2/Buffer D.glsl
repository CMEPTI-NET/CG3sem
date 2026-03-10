mat3 rotateX(float theta) {
    float c = cos(theta), s = sin(theta);
    return mat3(vec3(1,0,0), vec3(0,c,-s), vec3(0,s,c));
}

mat3 rotateY(float theta) {
    float c = cos(theta), s = sin(theta);
    return mat3(vec3(c,0,s), vec3(0,1,0), vec3(-s,0,c));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    ivec2 uv = ivec2(fragCoord);

    vec4 prevBullet    = texelFetch(iChannel3, ivec2(0,0), 0);
    vec4 prevBulletDir = texelFetch(iChannel3, ivec2(1,0), 0);
    vec4 prevExplosion = texelFetch(iChannel3, ivec2(3,0), 0);
    vec4 prevSpaceFlag = texelFetch(iChannel3, ivec2(4,0), 0);
    vec4 prevEnemy1    = texelFetch(iChannel3, ivec2(2,0), 0);
    vec4 prevEnemy2    = texelFetch(iChannel3, ivec2(5,0), 0);

    vec4 player = texelFetch(iChannel0, ivec2(0,0), 0);
    vec4 ch1 = texelFetch(iChannel1, ivec2(0,0), 0);
    vec4 ch2 = texelFetch(iChannel2, ivec2(0,0), 0);

    vec2 aim = vec2(0.0);
    if (length(ch1.xy)  1e-5) {
        aim = ch1.xy;
    } else if (length(ch2.xy)  1e-5) {
        aim = ch2.xy;
    }

    bool nowSpace = (ch1.z  0.5)  (ch2.z  0.5);

    vec4 bullet = prevBullet;
    vec4 bulletDir = prevBulletDir;
    vec4 enemy1 = prevEnemy1;
    vec4 enemy2 = prevEnemy2;
    vec4 explosion = prevExplosion;

     Инициализация врагов в начале
    if (iFrame  3 && enemy1.w  0.5) {
        enemy1 = vec4(15.0, 0.0, -20.0, 1.0);
        enemy2 = vec4(-10.0, 0.0, -30.0, 1.0);
    }

     Позиция и поворот корабля игрока
    vec3 shipCenter = vec3(player.x, 0.0, player.y - 6.0);
    float shipRot = player.z;
    mat3 rotShip = rotateY(-shipRot);

     синхронизация с имаджом

    vec3 cannonBaseLocal = vec3(0.4, 0.1, 0.0);
    
     Направление дула (синхронизируем с sdCannon)
    vec3 cannonDirLocal = vec3(0.0, 0.0, 1.0);  базовое направление вперед
    cannonDirLocal = rotateY(aim.x  1.5)  cannonDirLocal;  те же коэффициенты
    cannonDirLocal = rotateX(aim.y  0.8)  cannonDirLocal;  что в sdCannon

    vec3 cannonTipWorld = shipCenter + rotShip  (cannonBaseLocal + cannonDirLocal  0.3);
    vec3 cannonDirWorld = normalize(rotShip  cannonDirLocal);

    
     Респавн уничтоженных врагов через 3 секунды
    float respawnTime = 3.0;
    
    if (enemy1.w  0.5) {
         Используем компонент .w как таймер респавна
         Временно используем enemy1.y для хранения времени смерти
        if (iTime - enemy1.y  respawnTime) {
             Респавним врага в случайной позиции вокруг игрока
            float angle = fract(sin(iTime  10.0)  100.0)  6.283;
            float distance = 20.0 + sin(iTime  2.0)  5.0;
            vec3 spawnPos = shipCenter + vec3(
                sin(angle)  distance,
                0.0,
                cos(angle)  distance
            );
            enemy1 = vec4(spawnPos, 1.0);
        }
    }
    
    if (enemy2.w  0.5) {
        if (iTime - enemy2.y  respawnTime) {
            float angle = fract(sin(iTime  7.0)  100.0)  6.283;
            float distance = 25.0 + sin(iTime  1.7)  8.0;
            vec3 spawnPos = shipCenter + vec3(
                sin(angle)  distance,
                0.0,
                cos(angle)  distance
            );
            enemy2 = vec4(spawnPos, 1.0);
        }
    }

     Логика выстрела
    if (bullet.w  0.5 && nowSpace && prevSpaceFlag.x  0.5) {
        bullet = vec4(cannonTipWorld, 1.0);
        bulletDir = vec4(cannonDirWorld, 40.0);  скорость пули
    }

     Движение пули
    if (bullet.w  0.5) {
        bullet.xyz += bulletDir.xyz  (bulletDir.w  iTimeDelta);
        
         Уничтожаем пулю если улетела далеко
        if (length(bullet.xyz - shipCenter)  100.0) bullet.w = 0.0;
        
         Пуля падает в воду (учитываем волны)
        float waveHeight = sin(bullet.x  0.5 + iTime  1.5)  0.2 +
                          sin(bullet.x  0.8 + iTime  1.2)  0.15 +
                          sin(bullet.z  0.6 + iTime  1.0)  0.15;
        waveHeight = 0.4;
        
        if (bullet.y = waveHeight) {
            bullet.w = 0.0;
            explosion = vec4(bullet.xyz, 1.0);
        }
    }

     Столкновение пули с врагом 1
    if (bullet.w  0.5 && enemy1.w  0.5) {
        float dist = length(bullet.xyz - enemy1.xyz);
        if (dist  2.5) {
            bullet.w = 0.0;
             Сохраняем время смерти в .y компоненте
            enemy1.y = iTime;
            enemy1.w = 0.0;
            explosion = vec4(enemy1.xyz, 1.0);
        }
    }

     Столкновение пули с врагом 2
    if (bullet.w  0.5 && enemy2.w  0.5) {
        float dist = length(bullet.xyz - enemy2.xyz);
        if (dist  2.5) {
            bullet.w = 0.0;
            enemy2.y = iTime;
            enemy2.w = 0.0;
            explosion = vec4(enemy2.xyz, 1.0);
        }
    }

     Анимация взрыва
    if (explosion.w  0.0) {
        explosion.w = pow(0.92, iTimeDelta  60.0);
        if (explosion.w  0.0005) explosion.w = 0.0;
    }

    prevSpaceFlag.x = nowSpace  1.0  0.0;

     Записываем данные в соответствующие пиксели буфера
    vec4 outc = texelFetch(iChannel3, uv, 0); 
    if (uv == ivec2(0,0)) outc = bullet;
    else if (uv == ivec2(1,0)) outc = bulletDir;
    else if (uv == ivec2(2,0)) outc = enemy1;
    else if (uv == ivec2(3,0)) outc = explosion;
    else if (uv == ivec2(4,0)) outc = prevSpaceFlag;
    else if (uv == ivec2(5,0)) outc = enemy2;

    fragColor = outc;
}