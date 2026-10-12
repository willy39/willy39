# 표현 기법 카탈로그

isometric-web 프로젝트(15초 쇼릴 9편: 아이소메트릭 도시, 한글 키네틱, 비트 그리드, 데이터 맥박, UI 흐름, 유리 활자, 복셀 빛, 실사 광고, 종합 쇼릴)에서 쓴 기법을 이 스킬의 엔진(`REEL`) 코드로 옮긴 것이다. 원본 화면(isometric-web 프로젝트의 `content/reels/<slug>/video.mp4`)이 있으면 그 파일로 확인한다.

이 문서는 장면을 기획하는 목록이 아니라, 이미 검증된 코드 조각 모음이다. 장면은 `concept.md`의 아트 디렉션과 기술 과제에서 출발한다. 필요한 표현이 여기 있으면 코드를 가져다 쓰고 그 구간의 팔레트·서체·움직임에 맞게 바꾼다. 없으면 새로 만든다. 이 목록의 기법만 조합한 영상은 이 스킬로 만든 다른 영상과 비슷해진다.

WebGL 셰이더·three.js 3D·미리 계산하는 시뮬레이션은 `engine.md`에 있다. 맨 앞 "공통 규칙"(싱크, 첫 프레임, 섬광, 결정성)은 새로 만드는 장면에도 모두 적용한다.

## 목차

- 공통 규칙: 싱크, 첫 프레임, 섬광, 결정성
- 공통 도우미 코드
- T01 아이소메트릭 복셀 도시 / T02 낮→밤 그레이딩 / T03 틸트시프트·숫자→제목 모핑
- T04 입자 글자 / T05 한글 자모 조립 / T06 가변 굵기 펌핑 / T07 슬램 타이틀 카드
- T08 유리·크롬 입체 활자 / T09 프리즘 빛줄기
- T10 비트 그리드 타일 / T11 데이터 맥박 / T12 기계식 카운터 / T13 픽셀→입자 분해
- T14 3D 기기 UI 흐름 / T15 펀치 인 / T16 원형 매치 컷·2.5D 패럴랙스 / T17 절차적 김
- T18 비트 몽타주 / T19 잔상·방향 블러 / T20 섬광 안전 리듬 / T21 디더·그레인 / T22 서명 엔드카드

## 공통 규칙

**싱크.** 새 상태가 처음 보이는 프레임을 큐 프레임에 맞춘다. 화면이 소리보다 앞서면 안 된다.

- `ease.snap`(expo.out)이나 outBack 을 "큐에 끝나게" 쓰면 결과가 3~5프레임 먼저 보인다. 큐에 *시작*하거나, 크기 1.0에 처음 닿는 프레임을 큐에 맞춘다.
- 하드 컷·상태 전환의 사건 시각은 `큐 − 0.5프레임`에 둔다. `render.mjs --sub`의 셔터는 프레임 시각 앞뒤 0.25프레임에 걸쳐 있으므로, 이렇게 해야 큐 직전 프레임에 새 상태가 섞이지 않는다.
- 카메라 이동은 `ease.inOutCubic`으로 큐에 정확히 도착시킨다.

**첫 프레임.** 시작 방식은 콘셉트가 정한다. 0초 프레임부터 화면을 채워 움직이게 하려면 아래 방법을 쓴다. 의도하지 않은 빈 프레임이나 페이드 인으로 시작하지 않는다.

- 시간을 0초 이전부터 흐르게 둔다. 예: 선이 0초에 이미 화면 중간까지 그려져 있고, 첫 박의 파형이 이미 보인다.
- 낙하(inExpo)로 시작하면 처음 4~5프레임이 거의 움직이지 않는다. 첫 조각을 화면에 일부 걸어 둔 채 시작한다.

**섬광.** 화면 10% 이상이 밝기 0.1 넘게 오르내리는 변화를 1초에 3회 이하로 둔다.

- 박은 색 반전 대신 위치·회전·크기·굵기로 표현한다.
- 화면 전체가 동시에 바뀌는 동작은 부분집합(체커 반쪽, 2×2 칸의 4분의 1)으로 나눈다.
- 흰 플래시는 한 마디에 한 번까지 쓴다.

**결정성.** 같은 시각을 어떤 순서로 렌더해도 같은 화면이 나와야 한다.

- `will-change`를 쓰지 않는다.
- 자식 요소의 `visibility`는 `inherit`만 쓴다.
- 정적 SVG 일러스트는 setup에서 비트맵으로 굽는다(Chrome 래스터 캐시가 렌더 순서에 따라 가장자리를 다르게 그린 사례가 있다).
- 회전하는 작은 요소에는 `border-radius`와 블러 `box-shadow`를 쓰지 않는다.
- 3D 변환은 필요한 구간에만 건다.

## 공통 도우미 코드

```js
const { ease, prog, kf, clamp, lerp, rand, noise, pulse, css, h, s, cue } = REEL;
const F = 1 / REEL.fps, TAU = Math.PI * 2;
const E = (name) => cue(name) - 0.5 * F;                 // 사건 시각: 큐 프레임에 새 상태가 처음 보이게
const BEATS = REEL.TL.music?.beats || [];                 // timeline.py --music-analysis 로 생긴다
const SPB = 60 / (REEL.TL.music?.bpm || 120);             // 박 길이(초)
const beat = (n) => BEATS[n] ?? n * SPB;                  // n번째 박 시각
function cv(el, w = REEL.W, hh = REEL.H) {               // 장면에 캔버스 하나(알파 캔버스로 두고 바탕을 직접 칠한다)
  const c = h('canvas', '', el); c.width = w; c.height = hh;
  css(c, { position: 'absolute', left: 0, top: 0, width: w + 'px', height: hh + 'px' });
  return c.getContext('2d');
}
const hex = (str) => [1, 3, 5].map((i) => parseInt(str.slice(i, i + 2), 16));
const toLin = (v) => ((v /= 255) <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4);
const toSrgb = (v) => 255 * (v <= 0.0031308 ? v * 12.92 : 1.055 * v ** (1 / 2.4) - 0.055);
const poly = (g, pts, rgb, k = 1) => {                    // 다각형 + 같은 색 0.6px 외곽(면 사이 틈 메우기)
  g.beginPath(); pts.forEach(([x, y], i) => (i ? g.lineTo(x, y) : g.moveTo(x, y))); g.closePath();
  g.fillStyle = `rgb(${rgb.map((v) => Math.min(255, v * k) | 0)})`; g.fill();
  g.strokeStyle = g.fillStyle; g.lineWidth = 0.6; g.stroke();
};
```

BPM을 120(1박 15프레임)이나 90(1박 20프레임)으로 정하면 박이 정수 프레임에 떨어져 반올림 문제가 줄어든다. 음악 스펙(`audio/music/spec.json`)의 bpm 을 그렇게 정한다.

## T01. 아이소메트릭 복셀 도시

쓰임: 장면 하나를 건물 하나로 놓고 전체 구조를 보여 줄 때, 시스템·파이프라인 구조도, 오프닝, 데이터 묶음.

바닥 좌표 (x, y, z)를 방위각 az로 돌린 뒤 앙각 el(정아이소 35.264°, 2:1 픽셀 아이소 26.565°)로 직교 투영한다. 상자는 카메라를 향한 측면 두 개와 윗면만 그리고, 건물은 깊이 순서로 그린다. 솟는 지연은 거리 *순위*로 고르게 나눈다(거리 비례로 하면 바깥 고리에 몰린다).

```js
const ISO = { s: 30, cx: 960, cy: 600, el: 35.264 * Math.PI / 180 };
function iso(x, y, z, az) {                       // → [화면 x, 화면 y, 깊이]
  const c = Math.cos(az), sn = Math.sin(az), u = x * c - y * sn, v = x * sn + y * c;
  return [ISO.cx + u * ISO.s, ISO.cy + v * ISO.s * Math.sin(ISO.el) - z * ISO.s * Math.cos(ISO.el), v];
}
function box(g, b, hgt, az, light, rgb) {          // b = {x, y, w, d}
  const P = (a, q, z) => iso(b.x + a, b.y + q, z, az), c = Math.cos(az), sn = Math.sin(az);
  const sides = [[[0, -1], [0, 0], [b.w, 0]], [[1, 0], [b.w, 0], [b.w, b.d]], [[0, 1], [b.w, b.d], [0, b.d]], [[-1, 0], [0, b.d], [0, 0]]];
  for (const [[nx, ny], [a0, q0], [a1, q1]] of sides) {
    if (nx * sn + ny * c <= 0) continue;           // 뒷면
    poly(g, [P(a0, q0, 0), P(a1, q1, 0), P(a1, q1, hgt), P(a0, q0, hgt)], rgb, light([nx, ny, 0]));
  }
  poly(g, [P(0, 0, hgt), P(b.w, 0, hgt), P(b.w, b.d, hgt), P(0, b.d, hgt)], rgb, light([0, 0, 1]));
}
REEL.scene({ id: 'city', start: cue('scene.city'), end: cue('scene.city.end'),
  setup(el) {
    this.g = cv(el); this.B = [];
    for (let gx = -6; gx <= 6; gx++) for (let gy = -6; gy <= 6; gy++) {
      const i = (gx + 6) * 13 + gy + 6; if (rand(i, 1) < 0.25) continue;      // 빈 칸 = 길·광장
      this.B.push({ i, x: gx * 1.25, y: gy * 1.25, w: 0.95, d: 0.95, H: 0.5 + 4.5 * rand(i, 2) ** 2, r: Math.hypot(gx, gy) });
    }
    this.B.sort((a, b) => a.r - b.r).forEach((b, k, A) => (b.delay = k / A.length));
  },
  render(lt, ctx) {
    const g = this.g;
    const az = Math.PI / 4 + 0.5 * Math.sin(Math.PI / 2 * Math.min(lt / 9, 1));   // 감속하며 멈추는 궤도
    g.fillStyle = '#0b0e1a'; g.fillRect(0, 0, REEL.W, REEL.H);                  // 또는 T02 paintSky
    const order = this.B.map((b) => [iso(b.x + b.w / 2, b.y + b.d / 2, 0, az)[2], b]).sort((p, q) => p[0] - q[0]);
    for (const [, b] of order) {
      const hgt = b.H * prog(lt, 0.2 + 1.4 * b.delay, 0.5, ease.outBack);
      if (hgt > 0.01) box(g, b, hgt, az, (n) => 0.45 + 0.5 * Math.max(0, n[0] * 0.6 + n[1] * -0.3 + n[2] * 0.8), [46, 56, 96]);
    }
  } });
```

창 불빛은 창마다 다른 주기로 켜지고 꺼지게 하고, 점등 비율을 시간 함수로 둔다(밤으로 갈수록 높게). 네온 윤곽은 윗면 모서리를 `shadowBlur`로 그린다.

주의: 깊이 순서 정렬은 바닥이 같은 크기 칸이고 겹치지 않을 때만 맞는다(긴 건물은 칸으로 쪼갠다). `--sub 4`면 렌더가 4배 느려진다. 카메라 궤도는 엔드 정지 전에 속도 0으로 멈춘다.

## T02. 낮→밤 타임랩스 그레이딩

쓰임: 하루·제작 과정·연대기처럼 시간 흐름을 보여 줄 때, 밝은 시작에서 어두운 클라이맥스로 갈 때.

하늘 위·지평선 색과 해의 고도·방위·세기를 키 표로 두고 **선형 광에서** 보간한다(sRGB에서 바로 섞으면 중간이 탁하고 밝기 변화가 고르지 않다). 면 밝기는 `ambient + diffuse·max(0, n·sun)`이다.

```js
const SKY = [[0, '#F4A6C0', '#FFD3B0'], [2.5, '#BFDDF2', '#EAF4FA'], [5, '#9FD3F2', '#DDF0FA'], [7.5, '#FF9A4D', '#FFC98A'],
  [8.75, '#C0607A', '#FF9A6A'], [9.7, '#4A3C78', '#C2567A'], [10, '#141A2E', '#1F2742'], [12.5, '#0B0E1A', '#07090F']];
function mixKeys(keys, x, col) {
  if (x <= keys[0][0]) return hex(keys[0][col]);
  for (let i = 1; i < keys.length; i++) if (x <= keys[i][0]) {
    const p = (x - keys[i - 1][0]) / (keys[i][0] - keys[i - 1][0]), A = hex(keys[i - 1][col]), B = hex(keys[i][col]);
    return A.map((v, j) => toSrgb(lerp(toLin(v), toLin(B[j]), p)));
  }
  return hex(keys[keys.length - 1][col]);
}
function paintSky(g, x) {                          // x: 키 표의 시각(장면 길이에 맞춰 늘린다)
  const gr = g.createLinearGradient(0, 0, 0, REEL.H);
  gr.addColorStop(0, `rgb(${mixKeys(SKY, x, 1).map(Math.round)})`); gr.addColorStop(1, `rgb(${mixKeys(SKY, x, 2).map(Math.round)})`);
  g.fillStyle = gr; g.fillRect(0, 0, REEL.W, REEL.H);
}
```

시계 HUD 는 같은 시간 함수로 숫자를 만든다(`HH:MM`, 고정폭 서체, 쌍점은 박마다 `pulse`). 해질녘에는 HUD 글자색을 ink 에서 흰색으로 바꾸고, 글자 뒤에 10% 어두운 원형 받침을 깐다. 밤 화면을 70% 넘게 어둡게 덮으면 주제인 불빛이 꺼진다.

## T03. 틸트시프트와 숫자→제목 모핑

틸트시프트: 위 22%와 아래 18% 띠만 2·4·6px 블러를 겹쳐 디오라마처럼 보이게 한다. 화면 전체에 `filter: blur`를 걸면 프레임당 수백 ms가 든다.

모핑: HUD 숫자(`24:00`)의 `:00`이 기준선 축으로 접히고(rotateX 0→90°, inExpo 4프레임), 같은 자리의 `시`가 펼쳐진다(−90→0°, outExpo 4프레임). 같은 숫자는 고정폭 서체에서 본문 서체로 교차한다. 3D 변환은 접는 동안에만 건다.

```js
const T = cue('midnight'), fold = prog(ctx.t, T, 4 * F, ease.inExpo), unf = prog(ctx.t, T + 4 * F, 4 * F, ease.outExpo);
css(this.c00, { transformOrigin: '50% 82%', transform: fold > 0 && fold < 1 ? `perspective(600px) rotateX(${90 * fold}deg)` : 'none', opacity: fold >= 1 ? 0 : 1 });
css(this.si, { transformOrigin: '50% 82%', transform: unf > 0 && unf < 1 ? `perspective(600px) rotateX(${-90 + 90 * unf}deg)` : 'none', opacity: unf > 0 ? 1 : 0 });
```

## T04. 입자 글자: 형성·폭발·은하·재형성

쓰임: 키워드 등장의 가장 큰 임팩트, 분해되고 다시 만들어지는 이야기(변환, 생성), 드롭 구간.

setup에서 글자를 오프스크린에 그려 픽셀에서 점을 뽑는다. 위치는 상태마다 닫힌 식으로 계산한다: 유입 outQuart, 떨림 `noise`, 감속 폭발 `a + v·τ(1−e^(−Δt/τ))`, 은하 `θ = arm + r·k + (1.2/√r)·Δt`(안쪽이 빠르다), 내파 inQuart, 재형성 outExpo(왼쪽 글자부터). **상태 사이는 극좌표로 섞는다**(직선 보간은 네모 덩어리가 된다).

```js
function glyphPoints(text, font, step = 6) {       // setup 에서(폰트는 이미 로드돼 있다)
  const g = document.createElement('canvas'); g.width = REEL.W; g.height = REEL.H;
  const c = g.getContext('2d', { willReadFrequently: true });
  c.font = font; c.textAlign = 'center'; c.textBaseline = 'middle'; c.fillStyle = '#fff'; c.fillText(text, REEL.W / 2, REEL.H / 2);
  const d = c.getImageData(0, 0, REEL.W, REEL.H).data, on = (x, y) => d[(y * REEL.W + x) * 4 + 3] > 127, pts = [];
  for (let y = 4; y < REEL.H - 4; y += step) for (let x = 4; x < REEL.W - 4; x += step) if (on(x, y)) pts.push([x, y]);
  return pts;
}
// render: 이전 시각(t − 1/60)의 위치로 속도를 구해 늘임 길이를 정하고, 'lighter'로 그린 뒤 1/4 해상도 블룸을 얹는다
const [x, y] = pos(i, t), [px, py] = pos(i, t - 1 / 60), vx = (x - px) * 60, vy = (y - py) * 60, sp = Math.hypot(vx, vy);
const L = 1 + 6 * Math.min(1, sp / 1500);
g.lineWidth = 3.2 / Math.sqrt(L); g.beginPath(); g.moveTo(x, y); g.lineTo(x - (sp > 1 ? vx / sp * 3 * L : 1), y - (sp > 1 ? vy / sp * 3 * L : 0)); g.stroke();
```

가장 단순한 형태(유입 → 글자 교체)의 계산 방법은 `reel/_example_scenes.js` 엔드카드의 setup·render 코드에 있다. 색·서체·구도는 따라 하지 않는다. 주의: 짝짓기를 무작위로 하면 경로가 엉킨다(반지름 순위끼리 짝짓는다). 화면 가까이 날아오는 큰 입자는 색종이처럼 보이니 늘어날수록 가늘게 그린다. 1만 개가 넘으면 프레임당 수십 ms 걸린다.

## T05. 한글 자모 조립

쓰임: 한국어 영상의 오프닝, 브랜드 이름 등장, 부품이 모여 하나가 되는 메시지.

전처리 없이 하는 방법: 같은 음절 DOM을 조각 수만큼 겹치고 자모 영역별 `clip-path: inset()`으로 잘라 따로 움직인다. 조각을 다 합치면 원래 글자와 같으므로 정지 상태는 완벽하다. 영역은 중성 종류로 고른다.

```js
const VERT = new Set([0, 1, 2, 3, 4, 5, 6, 7, 20]);        // ㅏㅐㅑㅒㅓㅔㅕㅖㅣ: 초성 왼쪽 | 중성 오른쪽
const MIX = new Set([9, 10, 11, 14, 15, 16, 19]);          // ㅘㅙㅚㅝㅞㅟㅢ
function jamoRegions(ch) {                                  // [x0, y0, x1, y1] (글자 상자 비율). 서체마다 스틸로 확인해 조정
  const c = ch.charCodeAt(0) - 0xac00; if (c < 0 || c > 11171) return [[0, 0, 1, 1]];
  const jung = Math.floor((c % 588) / 28), jong = c % 28, yb = jong ? 0.6 : 1;
  const top = VERT.has(jung) ? [[0, 0, 0.56, yb], [0.56, 0, 1, yb]]
    : MIX.has(jung) ? [[0, 0, 0.62, yb * 0.52], [0, yb * 0.52, 0.62, yb], [0.62, 0, 1, yb]]
    : [[0, 0, 1, yb * 0.52], [0, yb * 0.52, 1, yb]];        // ㅗㅛㅜㅠㅡ
  return jong ? [...top, [0, yb, 1, 1]] : top;
}
REEL.scene({ id: 'jamo', start: 0, end: cue('scene.jamo.end', 6),
  setup(el) {
    this.pieces = []; let k = 0;
    [...'쇼릴'].forEach((ch, ci) => jamoRegions(ch).forEach(([x0, y0, x1, y1]) => {
      const p = h('div', 'display', el, ch);
      css(p, { position: 'absolute', left: `${700 + ci * 280}px`, top: '400px', fontSize: '260px', lineHeight: 1,
        clipPath: `inset(${y0 * 100}% ${(1 - x1) * 100}% ${(1 - y1) * 100}% ${x0 * 100}%)` });
      const side = rand(k, 1) < 0.5;
      this.pieces.push({ el: p, k, dx: side ? (rand(k, 2) < 0.5 ? -1 : 1) * 700 : 0, dy: side ? 0 : -620 - 200 * rand(k, 3), slide: side });
      k++;
    }));
  },
  render(lt, ctx) {
    const t = ctx.t;
    this.pieces.forEach((p) => {
      const L = 0.4 + p.k * SPB / 2 - 0.5 * F;                                     // 8분음표마다 한 조각씩 착지
      const k = t >= L ? 0 : p.slide ? 1 - ease.outExpo(clamp((t - (L - 3 * F)) / (10 * F)))   // 미끄러짐: 10프레임 곡선의 앞 3프레임
                                     : 1 - ease.inExpo(clamp((t - (L - 8 * F)) / (8 * F)));    // 낙하: inExpo 8프레임
      const q = t < L ? 1 : t < L + 3 * F ? 0.86 : lerp(0.86, 1, ease.outBack(clamp((t - L - 3 * F) / (4 * F))));   // 착지 눌림
      css(p.el, { transform: `translate(${p.dx * k}px, ${p.dy * k}px) scale(${1 + (1 - q) * 0.5}, ${q})`, transformOrigin: '50% 100%',
        color: t < L ? 'var(--accent)' : 'var(--ink)' });
    });
  } });
```

정밀한 방법: fontTools로 음절 윤곽을 굵기 세 벌(100·400·900)로 뽑고 윤곽 번호를 자모 조각으로 묶는다(isometric-web 프로젝트의 `production/reels/hangul-kinetic/`). 타자 방식: '한'을 ㅎ → 하 → 한으로 바꿔 끼운다(`String.fromCharCode(0xAC00 + cho*588 + jung*28 + jong)`).

주의: 바뀌는 색은 착지 후 4프레임에 걸쳐 정착시킨다. 수백 조각을 모두 한 곳으로 날리면 엉킨다. 주인공 조각만 날리고 나머지는 작아지며 사라지게 한다.

## T06. 가변 굵기 펌핑과 굵기 물결

Pretendard Variable(45–920)의 `'wght'`를 글자마다 바꾼다. 킥에는 모든 글자가 동시에 900으로 치고, 풀림만 x 위치만큼 늦춰 물결이 흐르게 한다.

```js
const b = BEATS.filter((x) => x - F <= ctx.t).pop() ?? -99;           // 가장 최근 박
this.chars.forEach((c, i) => {
  const atk = clamp((ctx.t - (b - F)) / (3 * F)), rel = clamp((ctx.t - (b + 2 * F) - i * 0.025) / (SPB - 3 * F));
  const w = atk < 1 ? lerp(200, 900, ease.outExpo(atk)) : lerp(900, 200, ease.inOutSine(rel));
  css(c, { fontVariationSettings: `'wght' ${w.toFixed(1)}` });
});
// 음절 격자(u, v): w = 100 + 800·(0.5 + 0.5·cos(2π(박위상 − off))), off 를 대각선 (u+v)/8 에서 방사 hypot(u−cx, v−cy)/8 로 바꾼다
```

주의: 굵기가 바뀌면 라틴 글자 폭이 바뀐다. 고정 폭 칸에 넣는다(Pretendard 한글 음절은 굵기와 관계없이 폭이 같다). 큰 면이 박마다 900↔100으로 깜빡이면 섬광이 된다.

## T07. 슬램 타이틀 카드

강조색 전면 바탕에 굵은 디스플레이 서체. 음절이 8분음표마다 1.6배에서 박히고(outExpo 5프레임, 사건 = 큐 − 0.4프레임), 박힐 때마다 줄 전체가 가운데로 다시 모인다. 카드는 박마다 4px 흔들리되 방향을 매번 돌린다. 퇴장은 3프레임 가라앉았다가 inExpo 4프레임으로 위로 빠지며 세로로 1.3배 늘어난다.

```js
const LEAD = 0.4 * F;
const slam = (t, c, from = 1.6, dur = 5 * F) => lerp(from, 1, ease.outExpo(clamp((t - (c - LEAD)) / dur)));
// setup 에서 음절마다 접두 폭(prefixW)을 재 두고, render 에서 박힌 음절 수 n 의 폭으로 줄 중심을 다시 잡는다
const cx = REEL.W / 2 - lerp(this.prefixW[Math.max(0, n - 1)], this.prefixW[n], ease.outExpo(clamp((t - (hits[n - 1] - LEAD)) / (5 * F)))) / 2;
```

주의: 28프레임 넘게 카피만 머물면 멈춘 화면이 된다. 자간 −0.02→−0.06em 조임과 1.00→1.03 밀기를 함께 준다. 전면 강조색 카드와 어두운 화면을 1초에 여러 번 오가면 섬광이 된다.

## T08. 유리·크롬 입체 활자

같은 글자 24겹을 `translateZ(−1.6i px)`로 쌓아 두께를 만들고(뒤로 갈수록 어둡게), 앞면은 `background-clip: text`로 조명 띠 그라디언트를 품게 한 뒤 띠 위치를 시간으로 돌린다. 크롬은 어둠-흰띠-어둠의 날카로운 반사, 유리는 반투명 앞면 + `-webkit-text-stroke` 모서리.

```js
setup(el) {
  css(el, { perspective: '1800px' });
  this.wrap = h('div', '', el); css(this.wrap, { position: 'absolute', left: '960px', top: '470px', transformStyle: 'preserve-3d' });
  for (let i = 23; i >= 0; i--) {
    const d = h('div', 'display', this.wrap, '마감');
    css(d, { position: 'absolute', fontSize: '220px', transform: `translate(-50%,-50%) translateZ(${-i * 1.6}px)`, color: `rgb(${12 + i * 0.6},${16 + i * 0.8},${34 + i * 1.6})` });
  }
  this.face = h('div', 'display', this.wrap, '마감');
  css(this.face, { position: 'absolute', fontSize: '220px', transform: 'translate(-50%,-50%)', color: 'transparent', WebkitBackgroundClip: 'text', backgroundClip: 'text',
    backgroundSize: '400% 100%', WebkitTextStroke: '1.5px rgba(214,232,255,.9)',
    backgroundImage: 'linear-gradient(100deg,#07090F 0%,#1F2742 22%,#F2F4FF 25%,#9EC5FF 28%,#141A2E 38%,#7B5CFF 52%,#0B0E1A 62%,#F2F4FF 64%,#0B0E1A 69%,#07090F 100%)' });
},
render(lt, ctx) {
  css(this.face, { backgroundPosition: `${(lt * 13) % 400}% 0` });
  const settle = prog(lt, ctx.dur - 2, 2, ease.inOutCubic);            // 끝에서 정면으로 멈춤
  css(this.wrap, { transform: `rotateY(${lerp(-26, 0, settle) + 3 * noise(lt * 0.4, 2) * (1 - settle)}deg) rotateX(${lerp(14, 6, settle)}deg)` });
}
```

바닥 반사는 같은 구조를 `scaleY(-1)`로 복제하고 `mask-image: linear-gradient(to bottom, rgba(0,0,0,.35), transparent 60%)`를 건다. 주의: 각도가 ±30°를 넘으면 겹 사이 계단이 보인다.

## T09. 프리즘 빛줄기

모서리 직선을 따라 가산 빛줄기가 프레임당 약 245px로 달린다. 머리는 흰색으로 짧게, 꼬리는 하늘색으로 길게 끈다. 무지개는 파장 16개를 직선에 수직으로 0→18px 벌리고 3프레임 동안 1.00 → 0.47 → 0.22로 끈다.

```js
function streak(g, x0, y0, ang, head, amp, spread) {
  g.save(); g.globalCompositeOperation = 'lighter'; g.translate(x0, y0); g.rotate(ang);
  const core = g.createLinearGradient(head - 600, 0, head + 150, 0);
  core.addColorStop(0, 'rgba(158,197,255,0)'); core.addColorStop(0.8, `rgba(242,244,255,${amp})`); core.addColorStop(1, 'rgba(255,255,255,0)');
  g.fillStyle = core; g.fillRect(head - 600, -3, 750, 6);
  for (let i = 0; spread > 0 && i < 16; i++) {
    const w = (i + 0.5) / 16, off = (w - 0.5) * spread;
    g.fillStyle = `hsla(${w * 0.8 * 360},100%,62%,${(amp * 1.9) / 16})`; g.fillRect(head - 420 + (w - 0.5) * spread * 6, off - 1, 840, 2);
  }
  g.restore();
}
const n = Math.floor((ctx.t - cue('glint')) * REEL.fps + 1e-4);
if (n >= 0 && n < 3) streak(g, 0, 591, Math.atan(-0.0844), 900 + 50 * n, [1, 0.47, 0.22][n], [4, 11, 18][n]);
```

## T10. 비트 그리드 타일

32×18칸(60px)에 바우하우스 도형 7종(사각, 원, 사분원, 반원, 삼각, 호 두 개, 점). 칸마다 이벤트 목록(flip, rot, pop)을 setup에서 박 시각으로 만들고, render에서 닫힌 식으로 평가한다.

```js
function cellAt(c, t) {                                  // c.ev 는 시작 시각 오름차순
  let face = c.f0, ang = 0, sx = 1, k = 1;
  for (const e of c.ev) {
    if (t < e.s) break;
    const x = (t - e.s) / e.dur;
    if (e.type === 'flip') { const p = x >= 1 ? 1 : ease.inOutExpo(x); if (p >= 0.5) face = e.to; if (x < 1) sx *= Math.abs(Math.cos(Math.PI * p)); }
    if (e.type === 'rot') { ang += e.d * Math.PI / 2 * (x >= 1 ? 1 : ease.outBack(x, 1.4)); if (x < 1) k *= 1 - 0.13 * Math.sin(Math.PI * x); }
    if (e.type === 'pop' && x < 1) k *= 1 + 0.1 * (1 - ease.outExpo(x));
  }
  return { face, ang, sx, k };
}
// 파문: 거리 '순위'로 시간을 나눠 프레임마다 뒤집히는 칸 수를 일정하게(섬광 안전)
const rank = cells.map((c, i) => [Math.hypot(c.c - 15.5, c.r - 8.5), i]).sort((a, b) => a[0] - b[0]);
rank.forEach(([, i], n) => cells[i].ev.push({ type: 'flip', s: E('ripple') - 3 * F + (12 * F * n) / (rank.length - 1), dur: 6 * F, to: pickFace(i) }));
```

**가장 중요한 주의점**: 고대비 타일이 화면을 덮은 상태에서 전체가 동시에 회전·반전·밀림하면 거의 모두 섬광 기준을 넘는다(실제로 1초에 섬광 16회가 나왔다). 방향별 변화 면적을 프레임당 8% 안쪽에 두고, 박 표현은 색 반전 대신 회전·눌림·크기 맥동으로 한다. 강조색은 지금 움직이는 칸에만 칠한다.

## T11. 데이터 맥박: 이어지는 도표

장면을 자르지 않고 요소가 다음 도표가 된다: 심전도 선 → x축 → 눈금 → 견본 → 막대 → 점 → 선 그래프 → 도넛 → 카운터. 선은 `Path2D` + `shadowBlur 16`. 실제 값은 setup에서 JSON(예: `timeline.json`, 조사 자료)을 읽어 계산한다.

```js
function ecg(u) {                                       // u = R 정점에서 떨어진 프레임 수. 박 프레임에 R 정점
  let y = 0;
  if (u > -3.6 && u < -2.0) y += 0.075 * Math.sin((Math.PI * (u + 3.6)) / 1.6);
  if (u > -1.3 && u <= -0.8) y += (-0.07 * (u + 1.3)) / 0.5;
  else if (u > -0.8 && u <= 0) y += lerp(-0.07, 1, (u + 0.8) / 0.8);
  else if (u > 0 && u <= 2) y += lerp(1, -0.5, u / 2);
  else if (u > 2 && u <= 4) y += lerp(-0.5, 0, (u - 2) / 2);
  if (u > 5 && u < 8.5) y += 0.14 * Math.sin((Math.PI * (u - 5)) / 3.5);
  return y;
}
// f0 에 선 머리가 이미 화면 중간(x 700)에 있고 앞 박의 R파가 그려진 채 시작한다(첫 프레임부터 움직임)
const head = Math.min(1824, 700 + 24 * ctx.t * REEL.fps);
```

주의: 1px 선은 +0.5 좌표에 둔다. 불투명 캔버스(`alpha: false`)는 글자에 색 번짐을 만든다. 내용이 한쪽에 몰리면 반대쪽을 보조 도표로 채운다.

## T12. 기계식 카운터와 슬롯 롤

자리마다 0–9–0 세로 띠를 두고, 윗자리는 아랫자리가 9→0을 넘을 때만 돌린다. 창 위아래 10%는 그라디언트 마스크로 지운다.

```js
const odoPos = (v, place) => { if (!place) return v; const d = 10 ** place, lo = ((v % d) + d) % d; return Math.floor(v / d) + clamp(lo - (d - 1), 0, 1); };
setup(el) {
  this.box = h('div', 'num', el); this.wheels = [];
  for (let k = 0; k < 3; k++) {
    const win = h('span', '', this.box), strip = h('span', '', win, [...'01234567890'].map((d) => `<span>${d}</span>`).join(''));
    css(win, { display: 'inline-block', overflow: 'hidden', height: '1em', verticalAlign: 'top', maskImage: 'linear-gradient(transparent, #000 10%, #000 90%, transparent)' });
    css(strip, { display: 'flex', flexDirection: 'column', lineHeight: 1 });
    this.wheels.push(strip);
  }
},
render(lt, ctx) {
  const v = lerp(0, 256, prog(ctx.t, cue('count') - 0.9, 0.9, ease.outQuart));     // 큐에 착지
  this.wheels.forEach((w, k) => css(w, { transform: `translateY(${-(odoPos(v, 2 - k) % 10)}em)` }));
}
```

고정폭 서체나 `tabular-nums`를 쓴다. 빠르게 도는 숫자는 `--sub`에서 겹쳐 보일 수 있다.

## T13. 픽셀→입자 분해

전환 직전 화면을 오프스크린에 그려 불투명 화소 후보를 3px 간격으로 모으고, `rand`로 섞어 200개를 뽑는다. **원래 x 순서대로** 목적지를 배정해야 경로가 교차하지 않는다. 2차 베지어(제어점 = 출발과 도착 사이 + 난수)와 inQuart 로 빨려 들고, 도착하면 맡은 선 조각을 켠다. `getImageData`는 setup 에서 한 번만 쓴다.

## T14. 3D 기기 UI 흐름

쓰임: 제품·앱·도구 사용 장면(질문 → 선택 → 생성 → 완료).

무대 `perspective: 2400px`, 기기 `preserve-3d`. 자세(x, y, ry, rx, s)를 `kf`로 보간하고 떠다님(±4px, ±0.8°)을 더한다. 화면 안은 실제 DOM UI다.

```js
const pose = (t) => ({
  x: kf(t, [[0, 1380], [cue('land'), 960, ease.outExpo], [cue('exit'), 960], [cue('exit') + 16 * F, 1340, ease.inOutExpo]]),
  ry: kf(t, [[0, -62], [cue('land'), -18, ease.outExpo], [cue('detail'), 14, ease.inOutCubic]]), rx: 8 + 0.5 * noise(t * 0.8, 3), s: 1,
});
const p = pose(ctx.t);
css(this.phone, { transform: `translate(${p.x - 220}px, ${88 + 4 * Math.sin(TAU * ctx.t / 4.6)}px) rotateY(${p.ry + 0.8 * Math.sin(TAU * ctx.t / 7.7)}deg) rotateX(${p.rx}deg) scale(${p.s})` });
// 터치 표시: 누르기 직전 1.2→1.0, 누름 0.85, 떼면 1.15로 커지며 사라짐
const tp = ctx.t - cue('tap');
const sc = tp < -4 * F ? 0 : tp < 0 ? lerp(1.2, 1, ease.outQuart(clamp((tp + 4 * F) / (4 * F)))) : tp < 6 * F ? 0.85 : 0.85 + 0.3 * ease.outQuart(clamp((tp - 6 * F) / (7 * F)));
```

공유 요소 확장은 카드 사각형(x, y, w, h, r)을 머리 사각형으로 inOutExpo 16프레임 보간하고, 안의 이미지는 `object-fit: cover`로 둔다. 컨페티는 공기 저항 + 중력 닫힌 식 `x = x0 + vx(1−e^(−ku))/k`, `y = y0 + (g/k)u + (vy − g/k)(1−e^(−ku))/k`.

주의: 밝은 UI 위의 반투명 흰 터치 원은 안 보인다(어두운 1px 외곽선을 더한다). 정적 SVG 아이콘은 setup 에서 비트맵으로 굽는다. 기기가 화면의 25%보다 작으면 핵심 순간에 T15.

## T15. 펀치 인 카메라

쓰임: 핵심 순간의 피사체가 화면의 25%보다 작아 잘 보이지 않을 때.

기준점(버튼, 데이터의 한 점, 건물)의 화면 좌표를 `transform-origin`으로 2D 배율을 건다. 들어갈 때와 나올 때 모두 `ease.inOutCubic`으로 큐 프레임에 도착한다. 라이저 동안 배율을 1.30에서 1.38로 천천히 더 올린다. 배경은 반대로 3% 물러나게 하면 깊이가 생긴다.

```js
const z = 1 + 0.45 * (prog(t, cue('like') - 8 * F, 8 * F, ease.inOutCubic) - prog(t, cue('toast') + 2 * F, 10 * F, ease.inOutCubic));
css(this.camera, z === 1 ? { transform: 'none' } : { transformOrigin: `${ax}px ${ay}px`, transform: `scale(${z.toFixed(4)})` });
css(this.bg, { transformOrigin: `${ax}px ${ay}px`, transform: `scale(${1 - 0.03 * (z - 1) / 0.45})` });
```

outExpo로 들어가면 큐 4프레임 전에 이미 도착해 앞서 보인다. inOutExpo로 복귀하면 가장자리가 프레임당 100px 넘게 움직여 블러로도 가릴 수 없다.

## T16. 원형 매치 컷·아이리스와 2.5D 패럴랙스

- 2.5D: 사진마다 누끼(`prep_images.py --cutout`)와 배경을 겹치고, 누끼는 scale 1.00→1.06·x +12px, 배경은 1.02·x −6px(inOutSine)로 움직인다. 피사체가 바닥에 닿는 점을 축으로 둔다.
- 아이리스: `clip-path: circle(r at x y)`의 r 을 원래 원 반지름에서 화면 모서리까지 거리로 inOutExpo, 2px 강조색 고리를 함께 키운다.
- 매치 컷: 다음 장면의 원(잔 테두리, 동공, 시계)이 앞 장면 원과 같은 자리·크기가 되도록 시작 배율을 정하고(`z0 = r_prev / r_new`) 1박 동안 outExpo로 푼다.

```js
const cover = (x, y) => Math.max(Math.hypot(x, y), Math.hypot(REEL.W - x, y), Math.hypot(x, REEL.H - y), Math.hypot(REEL.W - x, REEL.H - y)) + 6;
const p = prog(ctx.t, E('wipe'), 0.75, ease.inOutExpo), [cx, cy, r0] = this.circle, r = lerp(r0, cover(cx, cy), p);
css(this.next, { clipPath: p <= 0 ? 'circle(0px at 0 0)' : `circle(${r}px at ${cx}px ${cy}px)` });
```

원 좌표는 사진마다 재서 표로 둔다. 생성 프롬프트에서 맞출 원의 위치를 지정해 두면 확대가 덜 필요하다. 크로스 디졸브는 컷 뒤 2프레임에만 넣는다.

## T17. 절차적 김·연기

1/4 해상도(480×270) 캔버스에 도메인 왜곡 fbm 리본 밀도를 계산해 흰색 15~30%로 `screen` 합성하고 CSS로 확대한다. 상승은 `ny = q.y − t·rise`, 흔들림은 높이에 비례한다. 픽셀 루프가 무거우니 이미터 주변 사각형만 계산한다. 원본 코드: isometric-web 프로젝트의 `production/reels/morning-brew/`.

## T18. 비트 몽타주

- 소스는 ffmpeg로 필요한 구간만 JPG 시퀀스로 뽑는다(`<video>` 요소는 프레임 정확도가 없어 쓰지 않는다): `ffmpeg -ss 7.0 -i in.mp4 -frames:v 45 -vf fps=30 -q:v 2 assets/seq/a/%04d.jpg`. setup 에서 `REEL.img`로 미리 불러온다.
- 박마다 컷을 넘긴다. 전환은 흰 플래시 1~2프레임(한 마디에 한 번), 줌 펀치(1.08→1.00, 4프레임), 휩 팬(들어오는 쪽 4프레임: 8% 이동 + 가로 블러 40px outExpo).
- 드롭은 3×3 격자: 칸이 1박에 하나씩 scale 0.6→1과 가로선에서 열리는 클립으로 박히고, 가운데 칸은 강조색 + 숫자.
- 컷에 라벨을 붙인다면 모양·서체·위치는 그 구간의 아트 디렉션으로 정한다.

```js
const frame = (seq, t0, t, rate = 1) => seq[clamp(Math.floor((t - t0) * REEL.fps * rate), 0, seq.length - 1)];
function whip(g, img, k) {                                  // k: 1(시작) → 0(정지). 같은 이미지를 9번 밀어 그려 평균 = 가로 블러
  const shift = 0.08 * REEL.W * k, blur = 40 * k, sc = 1 + (2 * (shift + blur / 2)) / REEL.W, n = blur > 1 ? 9 : 1;
  for (let i = 0; i < n; i++) {
    g.globalAlpha = 1 / (i + 1);
    g.setTransform(sc, 0, 0, sc, REEL.W / 2 * (1 - sc) + shift + (n > 1 ? blur * (i / (n - 1) - 0.5) : 0), REEL.H / 2 * (1 - sc));
    g.drawImage(img, 0, 0, REEL.W, REEL.H);
  }
  g.globalAlpha = 1; g.setTransform(1, 0, 0, 1, 0, 0);
}
```

섬광 고르는 법: 후보의 첫·끝 프레임에서 밝은 화소(선형 휘도 ≥ 0.1) 비율을 미리 잰다. 연속 컷은 어두운 장면 위주로 고르고, 밝은 장면은 격자 칸(화면 9%)으로 보낸다.

## T19. 잔상과 방향 블러

1. 최종 렌더는 `render.mjs --sub 4`(셔터 180°)를 쓴다. 이때 하드 컷·상태 변화의 사건 시각은 `E('큐')`(큐 − 0.5프레임)에 둔다.
2. 양식화된 잔상: 같은 상태 함수를 t − 2/3프레임, t − 1/3프레임으로 다시 불러 15%·30%로 겹친다. 프레임당 40px 넘게 움직인 요소에만 쓴다.
3. 요소 하나만 번지게: SVG `feGaussianBlur`의 축별 표준편차 = min(26, 0.145·속도px/프레임).

`--sub`와 잔상을 함께 쓰면 과하게 번진다. 150px 넘는 큰 글자에는 잔상보다 블러가 깨끗하다.

## T20. 섬광 안전 리듬

"공통 규칙"의 섬광 항목을 지킨다. `motion_check.py`(초안)와 `qa_check.py`(완성본)의 섬광 판정은 화면 면적 기준(인접 프레임에서 밝기가 0.1 넘게 변한 화소가 10% 이상이면 전이, 반대 방향 전이 두 번이 섬광 1회, 1초에 3회 초과면 실패)이다. 실패 구간이 나오면 그 구간의 동시 변화 면적을 나눈다. 모션 블러(`--sub 4`)는 컷을 두 프레임에 섞어 전이를 늘린다. 비교 실험에서 `--sub 1`로 통과한 구간이 `--sub 4` 마스터에서 실패했다. 컷을 사선 와이프(6~7프레임)로 바꾸고 미끄러지는 거리를 줄이자 통과했다.

## T21. 디더·그레인

어두운 바탕의 넓은 그라디언트·글로우·블룸에는 밴딩(계단)이 생긴다. setup 에서 화면 고정 디더(2×2 블록, ±2 코드값)를 한 번 만들어 `overlay`로 얹는다. 프레임마다 바꾸지 않는다. 디더와 그레인은 파일 용량을 크게 키우므로 공유용 파일은 CRF를 1~2 올린다.

```js
REEL.overlay(() => {}, { setup(el) {
  const c = h('canvas', '', el); c.width = REEL.W; c.height = REEL.H; const g = c.getContext('2d'), im = g.createImageData(REEL.W, REEL.H);
  for (let y = 0; y < REEL.H; y++) for (let x = 0; x < REEL.W; x++) {
    const v = 128 + (rand((y >> 1) * 4096 + (x >> 1), 17) < 0.5 ? -2 : 2), i = (y * REEL.W + x) * 4;
    im.data[i] = im.data[i + 1] = im.data[i + 2] = v; im.data[i + 3] = 255;
  }
  g.putImageData(im, 0, 0); css(c, { position: 'absolute', inset: 0, mixBlendMode: 'overlay', opacity: 0.6, pointerEvents: 'none' });
} });
```

## T22. 서명 엔드카드와 정지

엔드카드를 판 열림과 글자 세 덩어리로 만들 때 쓰는 코드다. 끝 화면의 모양은 콘셉트가 정한다. 판이 왼쪽부터 `clip-path: inset(0 X% 0 0)`으로 드러나고(X 100→0, outExpo 10프레임), 강조 사각형이 outBack 6프레임으로 팝한다. 글자 세 덩어리가 2프레임씩 어긋나 opacity 0→1, `top` +12px→0(outQuart 6프레임)으로 들어온다. 이후 끝까지 거의 정지한다(드리프트 2px 이하). 마지막 타격은 소리만 낸다.

```js
const T0 = REEL.duration - 2.0;
render(lt, ctx) {
  const t = ctx.t;
  css(this.plate, { clipPath: `inset(0 ${100 * (1 - prog(t, T0, 10 * F, ease.outExpo))}% 0 0)` });
  css(this.sq, { transform: `scale(${prog(t, T0 + 2 * F, 6 * F, ease.outBack)})` });
  this.parts.forEach((el, i) => { const p = prog(t, T0 + (4 + 2 * i) * F, 6 * F, ease.outQuart); css(el, { opacity: p, top: `${12 * (1 - p)}px` }); });
}
```

글자 등장을 `transform: translateY`로 하면 직전 프레임의 합성 레이어를 재사용해 렌더 순서에 따라 가장자리가 달라질 수 있다. 정지 구간의 글자는 `top`으로 움직인다.
