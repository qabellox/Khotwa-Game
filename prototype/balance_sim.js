// Headless balance simulation of the ported game logic (no canvas).
const LANE_Y = [290, 538, 816], PLAYER_X = 960;
const BASE_SPEED = 430, MAX_SPEED = 1600, SPEED_INC = 15, SPEED_TICK = 1.6, SPEED_RAMP = 70;
const MAX_HEALTH = 100, HAZARD_DMG = 25, SPAWN_INT = 1.05, MIN_SPAWN = 0.6, HAZARD_CH = 0.5, INVULN = 0.6;
const HITBOX = { x: PLAYER_X - 60, w: 120, h: 108 };

let state = 'RUNNING', health = MAX_HEALTH, gameSpeed = BASE_SPEED, targetSpeed = BASE_SPEED;
let lane = 1, playerY = LANE_Y[1], targetY = LANE_Y[1];
let score = 0, coins = 0, scoreAcc = 0, speedAcc = 0;
let invuln = 0, bobTime = 0, animDist = 0, spawnTimer = 0, lastLane = -1;
let items = [], hits = 0, heals = 0, coinsCollected = 0;
let frames = 0, dt = 1 / 60;
let laneChanges = 0;

// deterministic pseudo-random
let seed = 42;
function rnd() { seed = (seed * 1664525 + 1013904223) >>> 0; return (seed >>> 8) / 16777216; }
function spawnItem() {
  const hazard = rnd() < HAZARD_CH;
  let l = Math.floor(rnd() * 3);
  if (l === lastLane) l = (l + 1) % 3;
  lastLane = l;
  let kind = hazard ? (rnd() < 0.5 ? 'drug' : 'unhealthy') : ((r) => r < 0.4 ? 'coin' : r < 0.75 ? 'fruit' : 'healthy')(rnd());
  const d = { drug: { v: 0, h: 0 }, unhealthy: { v: 0, h: 0 }, coin: { v: 5, h: 0 }, fruit: { v: 10, h: 25 }, healthy: { v: 15, h: 40 } }[kind];
  const s = 150 / 262;
  items.push({ x: 2020 + rnd() * 400, y: LANE_Y[l], kind, value: d.v, heal: d.h, hitW: 296 * s * 1.02, hitH: Math.min(262 * s * 1.02, 120), phase: rnd() * 6.28 });
}
function rectInt(a, b) { return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y; }

let t = 0;
while (state === 'RUNNING' && t < 300) {
  scoreAcc += dt; while (scoreAcc >= 1) { scoreAcc -= 1; score++; }
  speedAcc += dt; if (speedAcc >= SPEED_TICK) { speedAcc = 0; targetSpeed = Math.min(targetSpeed + SPEED_INC, MAX_SPEED); }
  const diff = targetSpeed - gameSpeed; gameSpeed += diff * Math.min(1, SPEED_RAMP * dt / Math.max(Math.abs(diff), 1));
  bobTime += dt; animDist += gameSpeed * dt;

  // player lane follows target smoothly; simulate arriving at target each frame for simplicity
  playerY = targetY;
  if (frames % 90 === 0) { lane = Math.min(lane + (rnd() < 0.5 ? -1 : 1), 2); lane = Math.max(lane, 0); targetY = LANE_Y[lane]; laneChanges++; }

  spawnTimer -= dt;
  if (spawnTimer <= 0) { spawnTimer = Math.max(MIN_SPAWN, SPAWN_INT / (gameSpeed / BASE_SPEED)); spawnItem(); }

  const hitbox = { x: PLAYER_X - 60, y: playerY - 99, w: 120, h: 108 };
  for (let i = items.length - 1; i >= 0; i--) {
    const it = items[i];
    it.x -= gameSpeed * dt;
    const oy = it.y + Math.sin(bobTime * 2.5 + it.phase) * 6;
    const ir = { x: it.x - it.hitW / 2, y: oy - it.hitH / 2, w: it.hitW, h: it.hitH };
    if (rectInt(hitbox, ir) && invuln <= 0) {
      if (it.kind === 'drug' || it.kind === 'unhealthy') { invuln = INVULN; health -= HAZARD_DMG; hits++; if (health <= 0) { state = 'GAMEOVER'; } }
      else { score += it.value; if (it.heal > 0) { health = Math.min(health + it.heal, MAX_HEALTH); heals++; } else { coins++; coinsCollected++; } sfxDummy(); }
      items.splice(i, 1); continue;
    }
    if (it.x < -140) items.splice(i, 1);
  }
  if (invuln > 0) invuln = Math.max(invuln - dt, 0);
  frames++; t += dt;
}
console.log('survival_s:', t.toFixed(2), 'frames', frames, 'hits', hits, 'heals', heals, 'coins', coinsCollected, 'score', score, 'laneChanges', laneChanges, 'finalSpeed', Math.round(gameSpeed), 'itemsLeft', items.length);
function sfxDummy() {}
