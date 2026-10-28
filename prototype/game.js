/* Khotwa — browser prototype mirroring khotwa/ Godot 4.7 project logic.
   Same constants: lanes, speeds, spawn, damage, heal, question bank. */
(() => {
  const canvas = document.getElementById('canvas');
  const ctx = canvas.getContext('2d');

  // ---------- constants (mirror GameManager / Player / ItemSpawner in GDScript) ----------
  const LANE_Y = [290, 538, 816];
  const PLAYER_X = 960;
  const BASE_SPEED = 430;
  const MAX_SPEED = 1600;
  const SPEED_INCREMENT = 15;
  const SPEED_TICK = 1.6;
  const SPEED_RAMP = 70;
  const MAX_HEALTH = 100;
  const HAZARD_DAMAGE = 25;
  const SCORE_PER_SEC = 1;
  const SPAWN_INTERVAL = 1.05;
  const MIN_SPAWN = 0.6;
  const HAZARD_CHANCE = 0.5;
  const INVULN_TIME = 0.6;
  const QUESTION_TIME = 15;

  // ---------- assets ----------
  const ASSET = 'khotwa/assets/';
  const img = {};
  function loadImg(name) {
    const i = new Image();
    i.src = ASSET + name;
    i.onerror = () => { img[name] = null; };
    i.onload = () => { img[name] = i; };
    return i;
  }
  loadImg('runner1.png');
  loadImg('runner2.png');
  loadImg('drug.png');
  loadImg('unhealthy.png');
  loadImg('coin.png');
  loadImg('fruit.png');
  loadImg('healthy.png');
  loadImg('railway.png');

  // ---------- audio (Web Audio, no MP3 dependency) ----------
  const AC = new (window.AudioContext || window.webkitAudioContext)();
  let audioOn = true;
  function ensureAudio() { if (AC.state === 'suspended') AC.resume(); }
  function tone(freq, type, duration, vol = 0.12) {
    if (!audioOn) return;
    ensureAudio();
    const t = AC.currentTime;
    const o = AC.createOscillator(); const g = AC.createGain();
    o.type = type; o.frequency.value = freq;
    g.gain.setValueAtTime(vol, t); g.gain.exponentialRampToValueAtTime(0.001, t + duration);
    o.connect(g); g.connect(AC.destination);
    o.start(t); o.stop(t + duration);
  }
  function sfx(kind) {
    if (!audioOn) return;
    if (kind === 'coin')   { tone(880, 'square', 0.12); }
    else if (kind === 'heal') { tone(1200, 'square', 0.16); }
    else if (kind === 'pain') { tone(160, 'sawtooth', 0.35, 0.25); }
    else if (kind === 'death') { tone(110, 'sawtooth', 0.6, 0.3); setTimeout(() => tone(80, 'sawtooth', 0.6, 0.25), 300); }
    else if (kind === 'click') { tone(900, 'square', 0.06); }
  }
  let bgmOn = true;
  let bgmOsc = null, bgmGain = null;
  function bgmStart() {
    if (!bgmOn || bgmOsc) return;
    ensureAudio();
    const t = AC.currentTime;
    bgmGain = AC.createGain(); bgmGain.gain.value = 0.05; bgmGain.connect(AC.destination);
    bgmOsc = AC.createOscillator(); bgmOsc.type = 'sine';
    const seq = [220, 246.94, 293.66, 329.63, 293.66, 246.94, 220, 196];
    let i = 0;
    function next() {
      if (!bgmOsc) return;
      bgmOsc.frequency.exponentialRampToValueAtTime(seq[i], t + (i % 4) * 1.5 + 0.1);
      i = (i + 1) % seq.length;
      setTimeout(next, 1500);
    }
    bgmOsc.connect(bgmGain); bgmOsc.start(t); next();
  }
  function bgmStop() {
    if (bgmOsc) { try { bgmOsc.stop(); } catch (e) {} bgmOsc = null; }
    if (bgmGain) { bgmGain.gain.exponentialRampToValueAtTime(0.001, AC.currentTime + 0.4); bgmGain = null; }
  }

  // ---------- question bank (mirror question_manager.gd) ----------
  const QUESTIONS = [
    { q: "ما هي الخطوة الأكثر فعالية لمساعدة صديق يظهر عليه علامات الإدمان؟", options: ["تجاهله حتى يستيقظ بنفسه", "تشجيعه على طلب المساعدة المهنية", "مشاركته في التجربة ليخفف وحدته", "فضحه أمام الجميع ليخجل"], correct: 1 },
    { q: "أي من هذه العلامات تدل على تعاطي المخدرات لدى مراهق؟", options: ["تحسن الدرجات الدراسية", "زيادة الشهية والنوم العميق", "تغير مفاجئ في الأصدقاء والعزلة", "استقرار الحالة المزاجية"], correct: 2 },
    { q: "ما هو التأثير الفعلي للتعاطي المتكرر على الدماغ؟", options: ["يغيّر كيمياء الدماغ ويسبب الاعتماد", "يزيد الذكاء والتركيز", "يحسّن الذاكرة على المدى الطويل", "ليس له أي تأثير حقيقي"], correct: 0 },
    { q: "ما هي أفضل طريقة للتعامل مع ضغط الامتحانات دون مخدرات؟", options: ["التنظيم وممارسة الرياضة والتنفس العميق", "تناول المنشطات لتقوية التركيز", "السهر لساعات طويلة بدون نوم", "تجاهل الامتحانات كلياً"], correct: 0 },
    { q: "أي عبارة عن الإدمان هي الصحيحة؟", options: ["الإرادة القوية وحدها تكفي دائماً", "الإدمان مرض قابل للعلاج بالدعم والعلاج", "لا يمكن لأي شخص أن يتعافى منه", "الإدمان يصيب الضعفاء فقط"], correct: 1 },
    { q: "ما هو السبب الرئيسي لاستمرار المدمن في التعاطي رغم الضرر؟", options: ["حب المغامرة فقط", "رخص ثمن المادة المخدرة", "الاعتماد الجسدي والنفسي على المادة", "الملل المؤقت"], correct: 2 },
    { q: "ما هو أفضل رد فعل عندما يُعرض عليك مخدر لأول مرة؟", options: ["تجربته مرة واحدة لمعرفة تأثيره", "قبوله حتى لا يرفضك أصدقاؤك", "أخذه وبيعه لاحقاً", "الرفض الحازم والابتعاد عن الموقف"], correct: 3 },
    { q: "كيف تؤثر ممارسة الرياضة على الصحة النفسية؟", options: ["تزيد القلق والتوتر", "لا علاقة لها بالصحة النفسية", "تخفف أعراض الاكتئاب والقلق", "تسبب الأرق المزمن"], correct: 2 },
    { q: "ما هي النتيجة طويلة المدى لاستخدام المؤثرات العقلية (المهلوسات)؟", options: ["اضطرابات نفسية وذكريات مزعجة دائمة", "تحسن الإبداع بشكل آمن", "زيادة التركيز والذاكرة", "نوم عميق وصحي"], correct: 0 },
    { q: "عندما تشعر برغبة قوية في التعاطي، ما هو التصرف الصحيح؟", options: ["الاستسلام للرغبة", "إخفاء المشكلة عن الجميع", "الانعزال عن الناس", "الاتصال بخط المساعدة أو شخص موثوق"], correct: 3 },
  ];

  // ---------- state ----------
  let state = 'MENU'; // MENU, RUNNING, PAUSED, GAMEOVER, QUESTION
  let score = 0, coins = 0, health = MAX_HEALTH, gameSpeed = BASE_SPEED, targetSpeed = BASE_SPEED;
  let scoreAcc = 0, speedAcc = 0;
  let lane = 1, playerY = LANE_Y[1], targetY = LANE_Y[1];
  let invuln = 0, dead = false, bobTime = 0, animDist = 0;
  let spawnTimer = 0, lastLane = -1;
  let items = [];
  let question = null;
  let questionTimer = 0;

  // persistent high score
  let bestScore = 0;
  function loadBest() { try { bestScore = parseInt(localStorage.getItem('khotwa_best') || '0', 10) || 0; } catch (e) { bestScore = 0; } }
  function saveBest() { try { localStorage.setItem('khotwa_best', String(bestScore)); } catch (e) {} }

  const els = {
    score: document.getElementById('score'), coins: document.getElementById('coins'),
    speed: document.getElementById('speed'), fill: document.getElementById('hud-fill'),
    final: document.getElementById('finalScore'), best: document.getElementById('bestScore'),
    qText: document.getElementById('qText'), qTime: document.getElementById('qTime'),
    qOpts: document.getElementById('qOpts'), qResult: document.getElementById('qResult'),
  };
  const screens = { start: document.getElementById('start'), pause: document.getElementById('pause'),
    gameover: document.getElementById('gameover'), question: document.getElementById('question') };
  const panels = { settings: document.getElementById('panelSettings'), howto: document.getElementById('panelHowTo') };
  function show(name) {
    Object.values(screens).forEach(s => s.classList.remove('visible'));
    if (name) screens[name].classList.add('visible');
  }
  function showPanel(name) {
    Object.values(panels).forEach(p => p.classList.remove('visible'));
    if (name) panels[name].classList.add('visible');
  }
  function hideAll() { show(null); Object.values(panels).forEach(p => p.classList.remove('visible')); }
  function fmt(n) { return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ','); }
  function rnd() { return Math.random(); }

  function resetRun() {
    score = 0; coins = 0; health = MAX_HEALTH; gameSpeed = BASE_SPEED; targetSpeed = BASE_SPEED;
    scoreAcc = 0; speedAcc = 0; items = []; lane = 1; playerY = LANE_Y[1]; targetY = LANE_Y[1];
    invuln = 0; dead = false; animDist = 0; spawnTimer = 0; lastLane = -1;
    question = null; questionTimer = 0;
    updateHud();
  }
  function updateHud() {
    els.score.textContent = fmt(score); els.coins.textContent = 'x ' + coins;
    els.speed.textContent = Math.round(gameSpeed);
    const p = health / MAX_HEALTH;
    els.fill.style.width = (p * 100) + '%';
    els.fill.style.background = p > 0.5 ? '#22c55e' : (p > 0.25 ? '#fbbf24' : '#ef4444');
  }
  function addScore(v) { score += v; updateHud(); }
  function takeDamage(amount) {
    if (dead) return;
    health = Math.max(health - amount, 0); sfx('pain'); updateHud();
    if (health <= 0) gameOver();
  }
  function gameOver() {
    dead = true; state = 'GAMEOVER'; bgmStop(); sfx('death');
    if (score > bestScore) { bestScore = score; saveBest(); if (els.best) els.best.textContent = fmt(bestScore); }
    els.final.textContent = fmt(score);
    show('gameover');
  }
  function startRun() { resetRun(); state = 'RUNNING'; dead = false; bgmStart(); hideAll(); }
  function pauseGame() { if (state === 'RUNNING') { state = 'PAUSED'; bgmStop(); show('pause'); } }
  function resumeGame() { if (state === 'PAUSED') { state = 'RUNNING'; bgmStart(); show(null); } }
  function backToMenu() { state = 'MENU'; bgmStop(); showPanel(null); show('start'); }
  function revive() {
    health = MAX_HEALTH; dead = false; state = 'RUNNING'; addScore(100); updateHud();
    bgmStart(); show(null); question = null; questionTimer = 0;
  }

  function startQuestion() {
    state = 'QUESTION'; bgmStop(); questionTimer = QUESTION_TIME;
    const qi = Math.floor(rnd() * QUESTIONS.length);
    question = Object.assign({}, QUESTIONS[qi], { timeLeft: QUESTION_TIME });
    renderQuestion();
    show('question');
  }
  function renderQuestion() {
    if (!question) return;
    els.qText.textContent = question.q;
    els.qTime.textContent = 'الوقت المتبقي: ' + Math.ceil(question.timeLeft);
    els.qOpts.innerHTML = '';
    question.options.forEach((opt, i) => {
      const b = document.createElement('button');
      b.textContent = 'أبجد'[i] + ') ' + opt;
      b.onclick = () => answer(i);
      els.qOpts.appendChild(b);
    });
    els.qResult.textContent = '';
  }
  function answer(i) {
    if (!question) return;
    const correct = i === question.correct;
    els.qResult.textContent = correct ? 'إجابة صحيحة — عدت للعب ✅' : 'إجابة خاطئة — اللعبة انتهت';
    if (correct) { sfx('coin'); setTimeout(revive, 900); }
    else { sfx('pain'); setTimeout(() => { gameOver(); show('gameover'); }, 900); }
    question = null;
  }
  function tickQuestion(dt) {
    if (!question) return;
    questionTimer -= dt;
    if (questionTimer <= 0) { question = null; questionTimer = 0; gameOver(); show('gameover'); return; }
    els.qTime.textContent = 'الوقت المتبقي: ' + Math.ceil(questionTimer);
  }

  // ---------- spawning ----------
  function spawnItem() {
    const isHazard = rnd() < HAZARD_CHANCE;
    let l = Math.floor(rnd() * 3);
    if (l === lastLane) l = (l + 1) % 3;
    lastLane = l;
    let kind;
    if (isHazard) kind = rnd() < 0.5 ? 'drug' : 'unhealthy';
    else { const r = rnd(); kind = r < 0.4 ? 'coin' : (r < 0.75 ? 'fruit' : 'healthy'); }
    const data = {
      drug:   { value: 0, heal: 0, glow: '#ff4444', tex: img['drug.png'],   region: [196, 55, 296, 262], cx: 0 },
      unhealthy: { value: 0, heal: 0, glow: '#ff4444', tex: img['unhealthy.png'], region: [196, 55, 296, 262], cx: 0 },
      coin:   { value: 5, heal: 0, glow: '#ffd140', tex: img['coin.png'],   region: [94, 27, 489, 315], cx: 0 },
      fruit:  { value: 10, heal: 25, glow: '#8eeaa8', tex: img['fruit.png'], region: [133, 54, 437, 265], cx: 0 },
      healthy: { value: 15, heal: 40, glow: '#8eeaa8', tex: img['healthy.png'], region: [133, 54, 437, 265], cx: 0 },
    }[kind];
    const s = 150 / data.region[3];
    items.push({
      x: 2020 + rnd() * 400, y: LANE_Y[l], lane: l, kind, value: data.value, heal: data.heal,
      glow: data.glow, tex: data.tex, region: data.region, cx: data.cx, s,
      hitW: data.region[2] * s * 1.02, hitH: Math.min(data.region[3] * s * 1.02, 120),
      phase: rnd() * Math.PI * 2,
    });
  }

  // ---------- input ----------
  function onKey(e, pressed) {
    if (state === 'MENU' && pressed && (e.key === 'Enter' || e.key === ' ')) { sfx('click'); startRun(); return; }
    if (state !== 'RUNNING') return;
    const k = e.key;
    if (pressed && (k === 'ArrowLeft' || k === 'a' || k === 'A' || k === 'ArrowUp' || k === 'w' || k === 'W')) {
      lane = Math.max(lane - 1, 0); targetY = LANE_Y[lane];
    } else if (pressed && (k === 'ArrowRight' || k === 'd' || k === 'D' || k === 'ArrowDown' || k === 's' || k === 'S')) {
      lane = Math.min(lane + 1, 2); targetY = LANE_Y[lane];
    }
  }
  function tapLane(sy) {
    let best = 0, bestD = 1e9;
    for (let i = 0; i < 3; i++) { const d = Math.abs(sy - LANE_Y[i]); if (d < bestD) { bestD = d; best = i; } }
    lane = best; targetY = LANE_Y[lane];
  }
  canvas.addEventListener('pointerdown', e => {
    const rect = canvas.getBoundingClientRect();
    const sx = (e.clientX - rect.left) * (1920 / rect.width);
    const sy = (e.clientY - rect.top) * (1080 / rect.height);
    if (state === 'MENU' || state === 'GAMEOVER') { sfx('click'); startRun(); return; }
    tapLane(sy);
  });
  window.addEventListener('keydown', e => onKey(e, true));
  window.addEventListener('keyup', e => onKey(e, false));

  // ---------- UI wiring ----------
  // Start screen buttons
  document.getElementById('btnStart').onclick = () => { sfx('click'); ensureAudio(); startRun(); };
  document.getElementById('btnSettings').onclick = () => { sfx('click'); showPanel('settings'); };
  document.getElementById('btnHowTo').onclick = () => { sfx('click'); showPanel('howto'); };
  document.getElementById('btnScore').onclick = () => { sfx('click'); showPanel('settings'); if (els.best) els.best.textContent = fmt(bestScore); };

  // Panel closes
  document.getElementById('panelSettingsClose').onclick = () => { sfx('click'); showPanel(null); };
  document.getElementById('panelHowToClose').onclick = () => { sfx('click'); showPanel(null); };

  // Settings toggles
  document.getElementById('togMusic').onchange = (e) => { sfx('click'); bgmOn = e.target.checked; if (!bgmOn) bgmStop(); else if (state === 'RUNNING') bgmStart(); };
  document.getElementById('togSfx').onchange = (e) => { sfx('click'); audioOn = e.target.checked; };

  // In-game buttons
  document.getElementById('btnResume').onclick = () => { sfx('click'); resumeGame(); };
  document.getElementById('btnMenuPause').onclick = () => { sfx('click'); backToMenu(); };
  document.getElementById('btnRevive').onclick = () => { sfx('click'); if (state === 'GAMEOVER' && !question) startQuestion(); };
  document.getElementById('btnRestart').onclick = () => { sfx('click'); startRun(); };
  document.getElementById('btnPause').onclick = pauseGame;

  // ---------- loop ----------
  let last = performance.now();
  function frame(now) {
    const dt = Math.min((now - last) / 1000, 0.05);
    last = now;

    if (state === 'RUNNING') {
      scoreAcc += dt;
      while (scoreAcc >= 1.0) { scoreAcc -= 1.0; addScore(SCORE_PER_SEC); }

      speedAcc += dt;
      if (speedAcc >= SPEED_TICK) { speedAcc = 0; targetSpeed = Math.min(targetSpeed + SPEED_INCREMENT, MAX_SPEED); }
      const diff = targetSpeed - gameSpeed;
      gameSpeed += diff * Math.min(1, SPEED_RAMP * dt / Math.max(Math.abs(diff), 1));
      if (diff > 0 && gameSpeed > targetSpeed) gameSpeed = targetSpeed;
      if (diff < 0 && gameSpeed < targetSpeed) gameSpeed = targetSpeed;

      bobTime += dt;
      animDist += gameSpeed * dt;

      const remain = targetY - playerY;
      let eased = remain * (1 - Math.exp(-11 * dt));
      const maxSlide = 560 * dt;
      if (eased > maxSlide) eased = maxSlide;
      if (eased < -maxSlide) eased = -maxSlide;
      playerY += eased;

      spawnTimer -= dt;
      if (spawnTimer <= 0) {
        const ratio = gameSpeed / BASE_SPEED;
        spawnTimer = Math.max(MIN_SPAWN, SPAWN_INTERVAL / ratio);
        spawnItem();
      }

      const hitbox = { x: PLAYER_X - 60, y: playerY - 45 - 54, w: 120, h: 108 };
      for (let i = items.length - 1; i >= 0; i--) {
        const it = items[i];
        it.x -= gameSpeed * dt;
        const oy = it.y + Math.sin(bobTime * 2.5 + it.phase) * 6;
        const ir = { x: it.x - it.hitW / 2, y: oy - it.hitH / 2, w: it.hitW, h: it.hitH };
        if (rectsIntersect(hitbox, ir) && invuln <= 0) {
          if (it.kind === 'drug' || it.kind === 'unhealthy') {
            invuln = INVULN_TIME; takeDamage(HAZARD_DAMAGE);
          } else {
            addScore(it.value);
            if (it.heal > 0) { health = Math.min(health + it.heal, MAX_HEALTH); sfx('heal'); updateHud(); }
            else { coins += 1; sfx('coin'); updateHud(); }
          }
          items.splice(i, 1); continue;
        }
        if (it.x < -140) items.splice(i, 1);
      }
      if (invuln > 0) invuln = Math.max(invuln - dt, 0);
      if (health <= 0 && state !== 'GAMEOVER') gameOver();
    }
    draw(now);
    requestAnimationFrame(frame);
  }

  function rectsIntersect(a, b) {
    return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
  }

  // ---------- draw ----------
  function draw(t) {
    const g = ctx.createLinearGradient(0, 0, 0, 1080);
    g.addColorStop(0, '#0b1020'); g.addColorStop(1, '#050810');
    ctx.fillStyle = g; ctx.fillRect(0, 0, 1920, 1080);

    // track band
    ctx.fillStyle = '#121a2b'; ctx.fillRect(0, 260, 1920, 560);

    // speed lines
    ctx.strokeStyle = 'rgba(255,255,255,0.10)';
    ctx.lineWidth = 2;
    const lineLen = Math.min(24 + gameSpeed * 0.04, 96);
    const move = (t * gameSpeed * 1.6) % (1920 + 800);
    for (let i = 0; i < 14; i++) {
      const x = ((i * 317 + move) % (1920 + 800)) - 400;
      const y = 60 + ((i * 97) % 760);
      ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x + lineLen, y); ctx.stroke();
    }

    // lane guides
    for (let i = 0; i < 3; i++) {
      const on = i === lane;
      ctx.fillStyle = on ? 'rgba(255,209,40,0.95)' : 'rgba(255,209,40,0.35)';
      ctx.fillRect(780, LANE_Y[i] + 6, 360, on ? 18 : 10);
    }

    // items
    for (const it of items) {
      const oy = it.y + Math.sin(bobTime * 2.5 + it.phase) * 6;
      const x = it.x, y = oy;
      const grad = ctx.createRadialGradient(x, y, 0, x, y, 150);
      grad.addColorStop(0, it.glow + '55'); grad.addColorStop(1, it.glow + '00');
      ctx.fillStyle = grad; ctx.beginPath(); ctx.arc(x, y, 150, 0, Math.PI * 2); ctx.fill();
      if (it.tex) {
        const [rx, ry, rw, rh] = it.region;
        ctx.drawImage(it.tex, rx, ry, rw, rh, x - rw * it.s / 2 + it.cx * it.s, y - rh * it.s / 2, rw * it.s, rh * it.s);
      } else {
        ctx.fillStyle = it.kind === 'drug' || it.kind === 'unhealthy' ? '#ef4444' : '#22c55e';
        ctx.fillRect(x - 45, y - 60, 90, 120);
      }
    }

    // player
    const scale = 180 / 768;
    const animFrame = dead ? 0 : (invuln > 0 ? Math.floor((Date.now() % 4000) / 500) % 4 : Math.floor(animDist / 32) % 4);
    const tex = img['runner1.png'];
    if (tex) {
      ctx.save();
      ctx.translate(PLAYER_X, playerY);
      if (invuln > 0) ctx.globalAlpha = 0.5 + 0.5 * Math.sin(Date.now() / 60);
      ctx.drawImage(tex, animFrame * 352, 0, 352, 768, -125 * scale, -705 * scale, 352 * scale, 768 * scale);
      ctx.restore();
    } else {
      ctx.fillStyle = invuln > 0 ? '#ffd140' : '#3b82f6';
      ctx.fillRect(PLAYER_X - 30, playerY - 120, 60, 120);
    }
  }

  requestAnimationFrame(function step(now) {
    frame(now);
    requestAnimationFrame(step);
  });

  // init
  loadBest();
  if (els.best) els.best.textContent = fmt(bestScore);

  // question timer (runs independently of state)
  setInterval(() => tickQuestion(0.1), 100);
})();
