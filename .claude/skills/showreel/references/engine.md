# 엔진: 장면 작성법과 기법 코드

## 목차

- 구조와 규칙
- API 요약
- 장면 작성 순서
- 기법 코드: 글자 / 숫자 / 사진 / 도형·선 / 캔버스 / 전환 / 나레이션·음악 동기
- WebGL: 셰이더와 3D
- 미리 계산하는 시뮬레이션
- 전역 레이어(fx.js)
- 렌더러 사용법
- 나눠 만들기
- 문제 해결

## 구조와 규칙

```
<프로젝트>/reel/
  index.html    색·서체 토큰(:root), 장면 공통 CSS
  engine.js     엔진(고치지 않는다 — new_project.py 가 최신으로 덮어쓴다)
  fx.js         전역 레이어(그레인·HUD·자막·섬광 등)
  timeline.js   timeline.py 가 만든다(window.TL: 큐·나레이션 단어 시각·음악 히트)
  scenes.js     장면 코드 — 여기만 쓴다(구간이 많으면 scenes_s01.js … 로 나누고 index.html 에 script 추가)
  _example_scenes.js  API 사용 예시(불러오지 않는다). 화면의 출발점으로 쓰지 않는다
  lib/          WebGL 라이브러리 등 외부 스크립트를 파일로 둔다(렌더 중 네트워크에 기대지 않는다)
  fonts/        new_project.py 가 채운다
```

서버 루트는 프로젝트 폴더다. 이미지는 `../assets/img/x.jpg`처럼 상대 경로로 부른다.

**규칙** — 렌더러는 임의 시각으로 바로 이동하고, 여러 워커가 구간을 나눠 그리며, 모션 블러를 위해 프레임 사이 소수 시각도 찍는다. 그래서:

1. `render(lt)`의 결과는 시각에만 달려야 한다. 이전 프레임에 계산한 값을 누적하지 않는다.
2. `Math.random()`, `Date.now()`, `performance.now()`, CSS `transition`·`animation`·`@keyframes`, `requestAnimationFrame` 루프를 쓰지 않는다. 무작위는 `rand(i, salt)`, 흔들림은 `noise(t, seed)`. 누적이 필요한 계산(물리 시뮬레이션)은 setup 에서 미리 계산한다(아래 "미리 계산하는 시뮬레이션").
3. DOM 은 `setup`에서 만들고 `render`에서는 스타일만 바꾼다. `render`에서 요소를 만들거나 지우지 않는다.
4. 시각은 숫자 대신 큐를 쓴다: `cue('name')`, `cue('line.n03')`, `cue('music.hit2')`. 나레이션을 다시 만들어도 화면이 따라온다.
5. 장면이 끝나기 0.1초 전에 퇴장을 끝낸다. 장면 경계에서 빈 화면·잔상이 생기는 가장 흔한 원인이다.

## API 요약

```js
const { ease, prog, win, kf, spring, clamp, lerp, map, rand, noise, split, stagger, count, scramble, shake, pulse, level, inout, charTimes, sayChars, bar, beat, css, h, s, cue } = REEL;
REEL.config({ duration: 60, fps: 30, width: 1920, height: 1080, audio: '../audio/mix.wav' }); // audio 는 미리보기용
REEL.scene({ id: 'intro', start: 0, end: cue('line.n03') - 0.3,
  setup(el) { /* DOM·SVG·canvas 만들기. this 에 저장 */ },
  render(lt, ctx) { /* lt = 장면 안 시간. ctx = { t, dur, p } */ } });
REEL.img(src)        // 이미지 미리 불러오기(준비될 때까지 렌더를 기다린다) → HTMLImageElement
REEL.TL              // timeline.js: { cues, vo:[{id,text,sub,start,end,words:[[단어,시작,끝]]}], music:{bpm,beats,downbeats,hits} }
```

| 함수 | 설명 |
| --- | --- |
| `prog(t, start, dur, e=ease.snap)` | start부터 dur 동안 0→1 |
| `win(t, a, b, inDur, outDur)` | a에서 들어와 b에서 나가는 0→1→0 |
| `kf(t, [[t0,v0],[t1,v1,ease],…])` | 키프레임 보간 |
| `spring(t, t0, f=2.2, z=0.42)` | 감쇠 스프링 0→1(살짝 넘침) |
| `split(el, 'char'|'word', {mask})` | 글자·어절 span 배열. 한글 음절 단위 |
| `stagger(t, start, each, dur, i, e)` | i번째 요소의 지연 진행률 |
| `count(p, to, {decimals, from})` | 천 단위 쉼표 숫자 문자열 |
| `scramble(final, p, t, seed)` | 무작위 글자에서 최종 문자열로 풀림(한글은 한글로) |
| `shake(t, [[t0, amp, decay]])` | {x, y, r} 흔들림 |
| `pulse(t, [t0, …], decay)` | 히트마다 1에서 감쇠 |
| `inout(el, t, a, b, o)` | a 에서 아래·흐림·확대 상태로 들어오고 b 에서 위로 밀리며 줄고 흐려지며 나간다. 퇴장을 페이드 대신 이것으로 |
| `charTimes(id, sub)` · `sayChars(spans, t, times)` | 나레이션 글자별 시각, 그 시각에 맞춰 글자를 하나씩 올림 |
| `bar(n, frac)` · `beat(n)` | n번째 마디·박의 시각(1부터, 큐 `bar1`과 같음) |
| `level(t, src)` | 소리 크기 0~1. src 없으면 그 시각의 나레이션, 줄 id 면 그 줄, `'music'`이면 음악 에너지(`timeline.py`가 만든 곡선) |
| `ease.*` | linear, in/out/inOut Quad·Cubic·Quart·Expo, outQuint, outBack, outElastic, inOutSine, **snap**(등장), **swift**(in-out), **exit**(퇴장), **pop**(칩) |

## 장면 작성 순서

1. 스토리보드의 장면마다 `REEL.scene` 하나. 시작·끝은 큐로 정한다.
2. 구간마다 대표 프레임을 먼저 만들고 스틸 시트를 본다(스타일 프레임, SKILL.md 7단계). 구간끼리 다른 작업으로 보이고 각 프레임이 포스터로 쓸 수준이면 나머지를 만든다.
3. 장면 하나를 쓸 때마다 그 장면의 시작+0.5초, 큐+0.4초, 끝-0.6초 스틸을 뽑아 본다.
4. 전역 레이어(카메라·섬광·자막 등)가 필요하면 마지막에 붙인다.

## 기법 코드

아래 코드는 `setup`/`render` 안에 그대로 넣어 쓰는 조각이다. 수치는 1920×1080 기준.

### 글자: 마스크 안에서 솟는 등장

```js
setup(el) {
  this.t1 = h('div', 'center display', el, '무대가 된다.'); css(this.t1, { top: '440px', fontSize: '200px' });
  this.c1 = split(this.t1, 'char', { mask: true });
},
render(lt) {
  const out = prog(lt, 3.2, 0.35, ease.exit);
  this.c1.forEach((c, i) => {
    const p = stagger(lt, 0.2, 0.04, 0.6, i);
    css(c, { transform: `translateY(${(1 - p) * 135 - out * 135}%)`, opacity: p > 0 ? 1 : 0, filter: `blur(${(1 - p) * 8}px)` });
  });
}
```

마스크 아래 여백(.18em) 때문에 110%로는 글자 윗부분이 대시처럼 비친다. 135%로 내리고 등장 전에는 opacity 0으로 둔다.

### 글자: 슬램(히트에 착지)

```js
const T = cue('name');                                   // 나레이션에서 이름이 발음되는 시각
const sp = prog(lt, T - start - 0.28, 0.3, ease.snap);   // 히트 0.28초 전에 출발해 히트에 착지
css(this.name, { opacity: sp, transform: `scale(${lerp(1.9, 1, sp)})`, filter: `blur(${(1 - sp) * 24}px)` });
```

같은 글자를 강조색으로 복제해 `mix-blend-mode: screen`으로 겹치고, 히트 뒤 0.5초 동안 커지며 사라지게 하면 잔상이 생긴다(코드는 `reel/_example_scenes.js`의 오프닝 장면).

### 글자: 스크램블·타자

```js
this.tag.textContent = scramble('<구간 카피>', prog(lt, 0.2, 0.6, ease.linear), lt, 3);
const full = '<구간 카피>';                              // 타자 + 깜빡이는 커서
this.kick.textContent = full.slice(0, Math.floor(prog(lt, 0.4, 0.6, ease.linear) * full.length)) + (Math.floor(lt * 4) % 2 ? '▍' : ' ');
```

### 글자: 사진을 품은 글자

```js
css(this.word, { backgroundImage: 'url(../assets/img/stage.jpg)', backgroundSize: 'cover',
  backgroundPosition: `${50 + lt * 6}% 50%`, WebkitBackgroundClip: 'text', backgroundClip: 'text', color: 'transparent',
  WebkitTextStroke: '1.5px rgba(255,236,200,.6)' });
```

### 글자: 빛 스윕

```js
css(this.name, { backgroundImage: 'linear-gradient(105deg, var(--ink) 40%, var(--accent) 50%, var(--ink) 60%)', backgroundSize: '300% 100%',
  WebkitBackgroundClip: 'text', color: 'transparent', backgroundPosition: `${lerp(100, -100, prog(lt, 1.2, 1.1, ease.inOutSine))}% 0` });
```

### 숫자: 카운트업

```js
this.num.textContent = count(prog(lt, 0.3, 1.6, ease.outQuart), 12840000);   // 12,840,000
css(this.num, { fontFamily: 'var(--num)', fontSize: '320px', fontVariantNumeric: 'tabular-nums' });
```

자릿수가 바뀌며 폭이 흔들리지 않도록 `tabular-nums`를 쓴다. 단위("명", "%")는 본문 서체로 작게 붙인다.

### 사진: 켄 번스 + 글자 쪽 스크림

```js
setup(el) {
  this.im = REEL.img('../assets/img/city.jpg');
  this.wrap = h('div', 'full', el); this.wrap.appendChild(this.im);
  css(this.im, { width: '100%', height: '100%', objectFit: 'cover', filter: 'saturate(.8) brightness(.85)' });
  h('div', 'full', el).style.background = 'linear-gradient(90deg, rgba(0,0,0,.82) 0%, rgba(0,0,0,0) 60%)';
},
render(lt, ctx) {
  css(this.im, { transform: `scale(${lerp(1.08, 1.18, ctx.p)}) translateX(${lerp(0, -2, ctx.p)}%)` });
}
```

### 사진: 3D 카드 + 클립 와이프

```js
const open = prog(lt, 0.15, 0.7, ease.swift);
css(this.card, { clipPath: `inset(0 ${(1 - open) * 100}% 0 0)`,
  transform: `perspective(1600px) rotateY(${lerp(-18, -6, open)}deg)`, boxShadow: '0 40px 90px rgba(0,0,0,.6)' });
```

### 사진: 누끼 + 림라이트

```js
// prep_images.py --cutout 으로 만든 투명 PNG. 누끼를 마스크로 써서 구간 팔레트의 빛을 인물 안쪽 가장자리에만
css(this.rim, { WebkitMaskImage: 'url(../assets/img/person_cut.png)', WebkitMaskSize: 'contain', WebkitMaskRepeat: 'no-repeat',
  background: 'linear-gradient(100deg, var(--accent), transparent 45%)', mixBlendMode: 'screen' });
css(this.person, { filter: 'drop-shadow(0 0 30px var(--accent))' });
```

### 도형·선: SVG 선 그리기(노드 그래프·지도·도식)

```js
setup(el) {
  this.svg = s('svg', { width: 1920, height: 1080, viewBox: '0 0 1920 1080' }, el); this.svg.style.position = 'absolute';
  this.path = s('path', { d: 'M200,540 C600,200 1000,880 1700,540', fill: 'none', stroke: 'var(--accent)', 'stroke-width': 3 }, this.svg);
  this.len = this.path.getTotalLength();                 // setup 은 화면이 보이는 상태로 실행되므로 길이 측정이 된다
  this.path.style.strokeDasharray = this.len;
},
render(lt) { this.path.style.strokeDashoffset = this.len * (1 - prog(lt, 0.3, 1.2, ease.swift)); }
```

노드는 박마다 하나씩 켠다: `const k = REEL.TL.music?.beats?.filter(b => b <= t).length`.

### 도형: 거대 외곽선 마키

```js
css(this.marq, { fontFamily: 'var(--num)', fontSize: '340px', whiteSpace: 'nowrap', color: 'transparent',
  WebkitTextStroke: '2px rgba(243,239,230,.12)', transform: `translateX(${-200 - lt * 120}px)` });
```

### 캔버스: 입자가 모여 글자가 됨

계산 방법은 `reel/_example_scenes.js` 엔드카드의 setup·render 코드에 있다. 색·서체·구도는 따라 하지 않는다. 핵심은 다음과 같다.

1. setup 에서 오프스크린 캔버스에 글자를 그린다(폰트는 이미 로드돼 있다).
2. 알파가 있는 픽셀을 5px 간격으로 샘플링해 목표점을 만든다.
3. 입자마다 `rand`로 시작점·지연을 정한다.
4. render 에서 `lerp(시작, 목표, ease(진행률))`로 위치를 계산한다. 이전 위치를 쓰지 않는다.
5. `globalCompositeOperation = 'lighter'`로 겹친 곳이 밝아지게 한다.

### 캔버스: 결정적 흐름·데이터 비

입자 위치는 언제나 `f(i, t)`로 계산한다. 예: 화면을 흐르는 점 `x = (rand(i,1)*W + t*speed_i) % W`, `y = rand(i,2)*H + noise(t*0.3, i)*20`. 프레임마다 캔버스를 지우고 다시 그린다. 자국(trail)이 필요하면 같은 공식으로 과거 몇 시각(t-0.03, t-0.06…)을 함께 그린다.

### 전환: 색면 와이프

```js
const wi = prog(lt, 0, 0.22, ease.swift), wo = prog(lt, 0.22, 0.3, ease.swift);
css(this.wipe, { transform: `scaleX(${wo > 0 ? 1 - wo : wi})`, transformOrigin: wo > 0 ? '100% 50%' : '0% 50%' });
```

### 전환: 푸시

다음 장면 전체를 아래에서 밀어 올리는 전환은 **배경을 장면 `section`(el)에 주지 말고, 움직이는 안쪽 root 에 준다.** section 에 배경을 주면 밀려 들어오는 동안 앞 장면을 덮어 2~3프레임이 빈다.

```js
setup(el) { this.root = h('div', 'full', el); css(this.root, { background: 'var(--bg)' }); /* 내용은 this.root 안에 */ },
render(lt) { css(this.root, { transform: `translateY(${(1 - prog(lt, 0, 0.35, ease.swift)) * 100}%)` }); }
```

### 전환: 줌 스루

```js
const z = prog(lt, endAt - 0.3, 0.3, ease.inExpo);        // 장면 끝 0.3초
css(this.root, { transform: `scale(${1 + z * 8})`, transformOrigin: '975px 548px', filter: `blur(${z * 6}px)` });
// 다음 장면 시작에 FX.flash 0.1 짧게
```

`transformOrigin`은 확대해 들어갈 점(눈동자, 글자 'ㅇ'의 구멍, 모니터)이다.

### 나레이션 동기: 단어마다 띄우기

```js
const line = REEL.TL.vo.find(v => v.id === 'n05');        // words: [[단어, 시작, 끝], …] 은 발음 표기(tts) 기준
line.words.forEach(([w, t0], i) => { const p = prog(t, t0 - 0.06, 0.25); css(this.ws[i], { opacity: p, transform: `translateY(${(1 - p) * 40}px)` }); });
```

화면 글자는 화면 표기로 따로 만들고, 시각만 `words`에서 가져온다. 단어 수가 다르면 `cues`로 필요한 단어에만 이름을 붙여 쓴다.

### 음악 동기: 박·히트에 반응

```js
const hits = REEL.TL.music?.hits || [];
const b = pulse(t, hits, 0.25);                           // 히트마다 1에서 감쇠
css(this.glow, { opacity: 0.3 + 0.5 * b, transform: `scale(${1 + 0.04 * b})` });
```

장면 경계는 `downbeats` 중 가까운 값에 맞춘다. 컷이 박에 맞으면 편집이 살아 보인다.

### 소리 크기에 반응: 파형·말할 때 빛나는 테두리

`timeline.py`가 나레이션 줄마다 20ms 간격, 음악은 50ms 간격의 크기 곡선을 `timeline.js`에 넣는다. 나레이션이나 음악을 바꾸면 `timeline.py`만 다시 돌리면 된다.

```js
// 보이스 소개: 말하는 동안 막대 파형이 실제 목소리를 따라 움직인다
bars.forEach((b, i) => {
  const v = level(t - (bars.length - 1 - i) * 0.03);          // 막대마다 30ms 씩 지난 값 → 흐르는 파형
  b.style.transform = `scaleY(${0.06 + 0.94 * v})`;
});
css(this.frame, { boxShadow: `0 0 ${40 * level(t, 'n12')}px var(--accent)` });  // 특정 줄에만 반응
css(this.bg, { opacity: 0.35 + 0.4 * level(t, 'music') });  // 음악 에너지에 따라 배경 밝기
```

막대 높이처럼 큰 움직임에는 그대로 쓰고, 밝기·크기처럼 눈에 띄는 값에는 0.3~0.5배로 줄여 쓴다. 매 프레임 값이 바뀌므로 깜빡임이 심하면 `(level(t) + level(t - 0.04) + level(t - 0.08)) / 3`처럼 평균을 낸다.

## WebGL: 셰이더와 3D

렌더러(헤드리스 Chrome)에서 WebGL2 셰이더와 three.js(r160 `build/three.min.js`) 장면이 렌더되고, 시각마다 다른 프레임이 나오며 `--sub 4` 모션 블러도 된다(2026-10 확인). 규칙은 다른 장면과 같다. 그리는 일은 `render(lt)` 안에서 시각으로만 한다.

- 컨텍스트는 `preserveDrawingBuffer: true`로 만든다. 캡처 시점에 버퍼가 비어 검게 나오는 것을 막는다.
- 캔버스 크기는 `REEL.W × REEL.H` 픽셀로 고정하고 CSS 크기도 같게 둔다. `--scale 0.5` 초안에서도 장면 좌표는 바뀌지 않는다.
- 라이브러리는 `reel/lib/`에 파일로 받아 `index.html`에서 `engine.js` 앞에 `<script src="lib/three.min.js"></script>`로 불러온다. 렌더 중 CDN에 기대지 않는다.
- three.js 애니메이션 믹서는 `mixer.setTime(lt)`로 시각을 지정한다. `clock.getDelta()`를 쓰지 않는다.
- 한글을 3D로 쓰려면 캔버스 2D에 글자를 그려 `THREE.CanvasTexture`로 붙이거나, 글자 픽셀에서 뽑은 점(T04)을 3D 좌표로 올린다.

셰이더(전체 화면 사각형 하나에 프래그먼트 셰이더):

```js
setup(el) {
  const c = h('canvas', '', el); c.width = REEL.W; c.height = REEL.H;
  css(c, { position: 'absolute', left: 0, top: 0, width: REEL.W + 'px', height: REEL.H + 'px' });
  const gl = this.gl = c.getContext('webgl2', { preserveDrawingBuffer: true, antialias: true });
  const sh = (type, src) => { const o = gl.createShader(type); gl.shaderSource(o, src); gl.compileShader(o);
    if (!gl.getShaderParameter(o, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(o)); return o; };
  const pr = this.pr = gl.createProgram();
  gl.attachShader(pr, sh(gl.VERTEX_SHADER, `#version 300 es
in vec2 p; void main(){ gl_Position = vec4(p, 0., 1.); }`));
  gl.attachShader(pr, sh(gl.FRAGMENT_SHADER, `#version 300 es
precision highp float; uniform float t; uniform vec2 r; out vec4 o;
void main(){ vec2 u = (gl_FragCoord.xy - .5 * r) / r.y;
  float d = length(u) - .3 - .05 * sin(10. * atan(u.y, u.x) + t * 6.);
  o = vec4(mix(vec3(1., .3, .1), vec3(.05, .1, .3), smoothstep(0., .01, d)), 1.); }`));
  gl.linkProgram(pr);
  gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer());
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);
  const loc = gl.getAttribLocation(pr, 'p'); gl.enableVertexAttribArray(loc); gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);
},
render(lt) {
  const gl = this.gl; gl.viewport(0, 0, REEL.W, REEL.H); gl.useProgram(this.pr);
  gl.uniform1f(gl.getUniformLocation(this.pr, 't'), lt);
  gl.uniform2f(gl.getUniformLocation(this.pr, 'r'), REEL.W, REEL.H);
  gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
}
```

three.js:

```js
setup(el) {
  const r = this.r = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true });
  r.setPixelRatio(1); r.setSize(REEL.W, REEL.H, false); el.appendChild(r.domElement);
  css(r.domElement, { position: 'absolute', left: 0, top: 0, width: REEL.W + 'px', height: REEL.H + 'px' });
  this.scene = new THREE.Scene();
  this.cam = new THREE.PerspectiveCamera(35, REEL.W / REEL.H, 0.1, 100); this.cam.position.set(0, 0, 8);
  this.m = new THREE.Mesh(new THREE.TorusKnotGeometry(1.4, 0.45, 256, 32),
    new THREE.MeshStandardMaterial({ color: 0xff5a1f, metalness: 0.6, roughness: 0.25 }));
  const key = new THREE.DirectionalLight(0xffffff, 3); key.position.set(3, 4, 5);
  this.scene.add(this.m, key, new THREE.AmbientLight(0x404060, 1.2));
},
render(lt) { this.m.rotation.set(lt * 0.8, lt * 1.3, 0); this.r.render(this.scene, this.cam); }
```

주의: 장면이 꺼진 동안(`display:none`)에는 그리지 않아도 된다. 셰이더의 무작위는 `fract(sin(dot(...)))` 같은 결정적 해시로 만든다. 큰 셰이더는 프레임당 수십 ms가 들 수 있으니 초안 렌더 시간을 보고 최종 렌더 시간을 추정한다.

## 미리 계산하는 시뮬레이션

천이 펄럭이거나 조각이 부딪혀 쌓이는 장면처럼 이전 상태가 필요한 움직임은 setup 에서 고정 간격(1/fps 또는 그보다 촘촘하게)으로 끝까지 계산해 배열에 저장하고, render 에서는 시각으로 읽어 보간한다. 초기값의 무작위는 `rand(i, salt)`로 정한다. 이렇게 하면 렌더 워커가 어느 시각부터 그려도 같은 화면이 나온다.

```js
setup() {
  const N = 400, steps = Math.ceil((this._e - this._s) * 120);          // 장면 길이(초) × 120 단계. _s·_e 는 엔진이 setup 전에 채운다
  const S = this.states = new Float32Array((steps + 1) * N * 2);
  let x = Array.from({ length: N }, (_, i) => rand(i, 1) * REEL.W), y = Array.from({ length: N }, (_, i) => -rand(i, 2) * 600);
  let vx = x.map((_, i) => (rand(i, 3) - 0.5) * 200), vy = x.map(() => 0);
  for (let k = 0; k <= steps; k++) {
    for (let i = 0; i < N; i++) {
      S[(k * N + i) * 2] = x[i]; S[(k * N + i) * 2 + 1] = y[i];
      vy[i] += 2400 / 120; x[i] += vx[i] / 120; y[i] += vy[i] / 120;
      if (y[i] > 900) { y[i] = 900; vy[i] *= -0.45; vx[i] *= 0.8; }  // 바닥에서 튐
    }
  }
  this.N = N; this.steps = steps;
},
render(lt) {
  const f = Math.min(this.steps, lt * 120), k = Math.floor(f), a = f - k, k2 = Math.min(this.steps, k + 1), S = this.states;
  for (let i = 0; i < this.N; i++) {
    const px = S[(k * this.N + i) * 2] * (1 - a) + S[(k2 * this.N + i) * 2] * a;
    const py = S[(k * this.N + i) * 2 + 1] * (1 - a) + S[(k2 * this.N + i) * 2 + 1] * a;
    // px, py 로 그린다
  }
}
```

`this._s`·`this._e`는 엔진이 setup 을 부르기 전에 채우는 장면의 시작·끝 시각(초)이다. 단계 수 × 요소 수가 수천만을 넘으면 setup 이 길어지므로 요소 수나 간격을 줄인다.

## 더 많은 표현

아이소메트릭 도시, 한글 자모 조립, 가변 굵기 물결, 유리·크롬 활자, 프리즘 빛줄기, 비트 그리드, 데이터 맥박, 기계식 카운터, 3D 기기 UI, 펀치 인, 매치 컷, 비트 몽타주, 잔상 등은 `techniques.md`에 코드와 함께 있다. 같은 문서 맨 앞의 싱크·첫 프레임·섬광·결정성 규칙은 모든 장면에 적용한다.

## 전역 레이어(fx.js)

모두 선택 사항이다. 콘셉트에 필요한 것만 `scenes.js` 끝에서 호출한다. 호출 순서가 위아래 순서다. 레터박스·그레인·비네트·HUD를 습관처럼 모두 붙이지 않는다(`design.md`의 "뻔한 화면").

```js
FX.camera({ shakes: [[cue('name'), 14, 0.4]], drift: 0.6 });          // 장면 전체 흔들림·드리프트
FX.flash([[cue('name'), 0.2, 0.12]]);                                  // [시각, 길이, 세기(≤0.15), 색]
FX.leak([[cue('scene.s02'), 1.4, 'rgba(255,170,70,.9)', 0.7]]);
FX.letterbox(t => 1 - prog(t, cue('name') - 0.1, 0.5, ease.swift) + prog(t, 57, 0.5, ease.swift));  // 1=닫힘
FX.vignette({ strength: 0.6 });
FX.grain({ opacity: 0.09 });
FX.hud({ left: '<라벨>', chapters: [[0, '<구간 이름>'], ['scene.s01', '<구간 이름>']], from: 3, to: 57 });
FX.subtitles({ size: 40 });                                            // TL.vo 의 sub 를 번인. "nosub" 줄은 번인에서만 빠진다(SRT 에는 남음, SRT 에서 빼려면 "nosrt")
// 세로(9:16) 영상이면 HUD·자막이 앱 UI 영역(위 250px·아래 420px)을 자동으로 피한다
```

## 렌더러 사용법

```bash
node $S/render.mjs --dir reel --serve                                  # 미리보기 URL(사용자에게 줄 수도 있다)
node $S/render.mjs --dir reel --stills 1.2,4.5,9 --outdir qa/stills    # 지정 시각 스틸
node $S/render.mjs --dir reel --every 0.5 --from 8 --to 16 --outdir qa/stills_s01
node $S/render.mjs --dir reel --out out/draft.mp4 --scale 0.5          # 초안
node $S/render.mjs --dir reel --out out/video.mp4 --sub 4 --format png # 최종(모션 블러)
```

- 로그 첫 줄에 로드된 폰트 목록이 나온다. 쓰려는 서체가 없으면 `fonts/fonts.css`를 확인한다.
- 종료 코드 2는 페이지 오류다. 로그의 `[pageerror]`를 고친다.
- 렌더 로그에는 `console.error`와 `[REEL]`로 시작하는 `console.warn`만 나온다. 장면 코드의 디버그 값은 `console.warn('[REEL] …')`로 남긴다.
- 최종 렌더는 청크(2초) 단위로 저장되므로 중단돼도 같은 명령을 다시 실행하면 이어서 렌더한다. 설정을 바꾸면 처음부터 다시 렌더한다.
- 다른 렌더가 같은 컴퓨터에서 돌고 있으면 10배 넘게 느려진다. `--workers 2`로 줄인다.

## 나눠 만들기

구간이 많은 쇼릴이나 3분 넘는 영상은 구간(또는 챕터)마다 `scenes_s01.js`, `scenes_s02.js`로 나누고 `index.html`에 script 태그를 추가한다. 공용 헬퍼는 `scenes_common.js`에 둔다. 구간마다 아트 디렉션이 다른 쇼릴은 구간을 서브에이전트에 하나씩 맡겨 동시에 만들 수 있다. 메인은 콘셉트를 지키는지 보고, 구간 사이 전환과 전체 비평을 맡는다.

서브에이전트에 구간을 맡길 때는 다음 계약을 프롬프트에 넣는다.

- 먼저 읽을 것: 이 문서(engine.md), design.md, `concept.md`의 자기 구간 행(매체·팔레트·서체·움직임·기술 과제·연결 방법), `reel/scenes_common.js`, `timeline.json`의 자기 구간 부분
- 기준: SKILL.md 맨 앞 "이 스킬이 맞추는 기준" 표. 자기 구간이 독립된 작업 한 편으로 보여야 한다
- 수정 범위: `reel/scenes_sNN.js`와 그 구간의 `reel/lib/`·`assets/` 파일만. 공용 파일의 문제는 고치지 말고 보고한다
- 작업 파일은 프로젝트 폴더 안에 둔다. `/tmp`를 쓰지 않는다
- 안전 영역, 자막 영역, 의도하지 않은 1초 넘는 정지 금지, 큐 ±3프레임, 마지막 10프레임 새 정보 금지, `Math.random` 금지
- 검증: 장면마다 시작+0.5·큐+0.4·끝-0.6초 스틸과 핵심 순간의 프레임 띠(0.033~0.1초 간격)를 `qa/stills_sNN/`에 뽑아 시트를 Read로 확인하고 고친 뒤 보고
- 보고는 짧게(코드를 붙이지 않는다): 만든 장면, 확인한 시트 경로, 공용 코드 문제, 스스로 본 이 구간의 가장 약한 점. 보고는 응답 텍스트로 돌려준다. 서브에이전트에게 보고 파일을 쓰게 하면 실행 환경이 막을 수 있으므로, 기록이 필요하면 메인이 받은 보고를 파일로 남긴다

## 문제 해결

| 증상 | 원인과 조치 |
| --- | --- |
| 다른 장면 요소가 비쳐 보임 | 엔진은 장면을 `display:none`으로 끈다. 장면 밖(`REEL.top` 등)에 만든 요소라면 직접 숨긴다 |
| 첫 프레임에 글자가 보였다가 사라짐 | 등장 전 상태(opacity 0, translate)를 `render`에서 lt=0일 때도 적용하는지 확인 |
| 글자 폭·위치가 어긋남 | `setup`에서 측정하면 된다(폰트 로드 뒤 실행). 렌더 중 측정은 하지 않는다 |
| 워커 경계에서 화면이 튐 | 누적 상태가 있다. render를 시각의 함수로 고친다 |
| 렌더가 느림 | 전체 화면 `filter: blur()`·큰 `box-shadow`를 줄인다. 캔버스 입자는 2,000~10,000개 안에서, 그라디언트 객체는 setup 에서 만든다 |
| 장면 경계에 빈 프레임 | 다음 장면이 시작 직후 6~20프레임 안에 무엇이든 움직이게 한다. 퇴장은 컷 0.1초 전에 끝낸다 |
| 9:16 에서 잘림 | `REEL.config`의 width/height를 바꾸고 좌표를 `REEL.W`/`REEL.H` 기준 비율로 쓴다 |
