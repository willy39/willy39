# 오디오: 나레이션·음악·효과음·믹스

## 목차

- ElevenLabs 키와 플랜
- 보이스와 모델
- 나레이션 생성과 발음 검증
- 음악
- 효과음
- 믹스 기준
- 자주 생기는 문제

## ElevenLabs 키와 플랜

`python3 scripts/eleven.py check`로 키·보이스·모델을 점검한다. 키가 없으면 아래 절차를 사용자에게 그대로 안내한다(같은 내용이 `eleven.py`의 `KEY_HELP`에 있다).

1. https://elevenlabs.io 가입·로그인 → 왼쪽 아래 Developers(또는 프로필) → API Keys → Create API Key
2. 권한: Text to Speech, Speech to Text, Sound Effects, Music, Voices(Read), User(Read)를 켠다. User Read가 있어야 남은 크레딧을 조회할 수 있다. 키는 한 번만 보이므로 바로 복사한다.
3. 셸 설정에 저장: `echo 'export ELEVENLABS_API_KEY="sk_..."' >> ~/.zshrc && source ~/.zshrc`, 또는 프로젝트 폴더의 `.env`에 `ELEVENLABS_API_KEY=sk_...`

플랜별로 막히는 기능(실측):

| 기능 | Free | 유료(Starter $6 이상) |
| --- | --- | --- |
| 라이브러리 보이스(Marcus 등) | 402로 막힘 | 가능 |
| Music API | 402로 막힘 | 가능 |
| 192kbps 출력 | 403(Creator 이상) | Creator 이상 |
| 효과음, STT | 가능 | 가능 |
| 상업적 이용 | 불가(출처 표기 필요) | 가능 |

- 동시 요청 한도는 플랜에 따라 2~5개다. 넘으면 429가 나는데, `eleven.py`가 기다렸다가 다시 시도한다. 스크립트 기본 동시성은 TTS 2개, 효과음 3개다.
- `/v1/user/subscription`이 401(missing user_read)이면 키 권한 문제일 뿐 키는 정상이다. 크레딧은 대시보드에서 확인하라고 안내한다.
- 막히면 우회하지 말고 바로 알린다. 사용자가 그 자리에서 결제한 사례가 있다.

## 보이스와 모델

| 보이스 | voice_id | 특징 | 권장 모델 |
| --- | --- | --- | --- |
| Marcus | `ibCGc01503OQd2R6i1n1` | 깊고 차분한 바리톤, 서울 억양, 낭독용. 아래 설정을 검증한 보이스(F0 약 78~83Hz) | `eleven_multilingual_v2` (파인튜닝됨) |
| Do Hyeon | `FQ3MuLxZh0jHcZmA5vW1` | 깊은 중년 남성 | `eleven_v3` |
| Yohan Koo | `4JJwo477JUAx3HV0T7n7` | 자신감 있는 권위형 | v2·v4 |
| 안재동 Jaedong Ahn | `ZcZcEsYxXAIc3nNSev1H` | 차분한 중년 남성 | v2 |
| Kwan | `eMzlsWTml7eAEDvSiETn` | 에너지·열정 | v2 |
| Anna Kim | `uyVNoMrnUku1dZyVEXwD` | 젊은 여성, 단정함(속삭임 연기 `[whispers]`) | v3·v4 |
| Sujin | `8zHuDw1bbkbkL93Inv5N` | 밝고 경쾌한 여성 | v2 |

다른 보이스는 `eleven.py voices --lang ko`(내 보이스), `--library`(공개 라이브러리 검색)로 찾는다.

모델 선택:

- `eleven_multilingual_v2`(기본): `previous_text`·`next_text`로 문장 사이 억양이 이어지고, style·speed를 쓸 수 있다. Marcus가 이 모델로 파인튜닝돼 있다.
- `eleven_v3`: 오디오 태그(`[serious]`, `[whispers]`)를 쓴다. 이름·숫자를 v2보다 정확히 읽은 사례가 있다(이훈희, 2026). stability는 0.5. 0.0은 없는 말을 붙였고 1.0은 오독했다. `previous_text`를 받지 않는다. 문제 줄만 v3로 바꿀 때는 음높이가 앞뒤 줄과 이어지는지 확인한다.
- `eleven_v4`: stability·similarity만 받는다. Marcus는 v4로 파인튜닝돼 있지 않아 음색이 달라질 수 있다.

Marcus 낭독 설정(검증한 값): stability 0.42~0.5, similarity 0.8~0.82, style 0.38~0.45, speed 0.97~1.05, speaker boost 켬. style을 올리면 덜 단조롭다.

## 보이스 교차

한 영상에서 보이스를 여러 개 번갈아 쓰면 장면이 바뀌는 느낌이 소리로도 전달된다. `script.json`의 줄마다 `"voice"`(필요하면 `"model"`, `"settings"`)를 따로 적으면 된다. `narrate.py`는 같은 보이스 줄끼리만 앞뒤 문맥을 넘기고, `mix.py`는 줄마다 음량을 맞추므로 보이스가 바뀌어도 크기가 튀지 않는다.

쓰는 방식:

| 방식 | 예 | 맞는 곳 |
| --- | --- | --- |
| 주 나레이터 + 인용 보이스 | Marcus가 이끌고, 인물의 말·고객의 목소리만 다른 보이스 | 프로필, 브랜드 필름 |
| 장(챕터)마다 보이스 | 1장 Marcus, 2장 Yohan Koo, 3장 Anna Kim | 여러 관점을 보여 주는 소개 |
| 한 단어씩 이어 말하기 | 네 보이스가 "기획." "원고." "목소리." "영상."을 하나씩 | 오프닝 도입, 몽타주 |
| 같은 문장을 여러 보이스로 | 같은 문장을 보이스만 바꿔 연달아 들려 주기 | 보이스·기능 시연 |
| 속삭임·연기 | Anna Kim `eleven_v3` + `[whispers]` | 티저의 반전 |

- 보이스는 서너 개까지만 쓴다. 넘으면 누가 말하는지 헷갈린다.
- 보이스가 바뀌는 줄에는 화면에도 변화(장면 전환, 화자 이름 라벨, 색)를 같이 준다.
- 진지한 인물 프로필은 주 나레이터 하나를 기본으로 하고, 교차는 오프닝·인용에만 쓴다.
- 보이스마다 발음 버릇이 다르므로 `--stt` 검증을 줄마다 한다.

## 나레이션 생성과 발음 검증

```bash
python3 scripts/narrate.py <프로젝트>/script.json --stt
```

- 줄마다 `/with-timestamps`로 생성해 글자 단위 정렬(`<id>.align.json`)을 저장한다. 한국어는 `alignment`를 쓴다. `normalized_alignment`는 한글을 로마자로 돌려준다.
- `--stt`: Scribe로 받아써서 화면 표기·발음 표기 중 가까운 쪽과 비교한다. 유사도가 0.85 미만이거나 숫자가 다르면 ✗다.
- 바뀐 줄만 다시 만든다. 특정 줄만 다시 만들려면 `--only n03,n07 --force`.
- `takes`: 시드를 바꿔 N번 만들고 STT가 가장 정확한 테이크를 본 파일로 쓴다. 나머지는 `<id>.t2.mp3` 등으로 남는다.

✗가 나오면 이 순서로 고친다.

1. 발음 표기 수정(숫자·약어 한글화)
2. 쉼표·말줄임표로 끊어 읽기("이공, 이육!", "언리얼… 아이돌.")
3. 문장 변경: 브랜드명 뒤 조사 빼기, 동음이의어 피하기
4. `takes` 3~5
5. 그 줄만 `"model": "eleven_v3"`, 텍스트 앞에 `[serious]`

stability를 바꾸거나 모델을 통째로 바꾸는 것은 효과가 없었다.

**클립 단독 STT를 통과해도 완성 믹스에서 틀릴 수 있다.** 음악·효과음이 덮기 때문이다. 그래서 `qa_check.py --stt`로 완성본도 받아쓴다. STT는 실행마다 결과가 달라질 수 있으니 같은 줄이 두 번 연속 틀릴 때 고친다.

## 음악

### 1) 스펙 하나로 두 경로

`audio/music/spec.json`을 한 번 쓰면 ElevenLabs 플랜과 합성 음악을 모두 만들 수 있다.

```json
{"duration": 60, "mood": "cinematic", "bpm": 90, "key": "D", "minor": true,
 "global_styles": ["<콘셉트가 정한 장르·악기·질감, 영어>", "instrumental"],
 "sections": [{"name": "Cold Open", "start": 0, "energy": 0.2},
              {"name": "Reveal", "start": 8.5, "energy": 0.6, "style": "massive braam on the first beat"},
              {"name": "Rise", "start": 18, "energy": 0.8}, {"name": "Climax", "start": 40, "energy": 0.95},
              {"name": "Finale", "start": 52, "energy": 0.3}],
 "events": [{"t": 8.5, "type": "hit"}, {"t": 39.6, "type": "riser", "dur": 2}, {"t": 30, "type": "stop", "dur": 0.8},
            {"t": 56, "type": "boom"}, {"t": 57.5, "type": "chime"}]}
```

- 곡의 성격은 콘셉트에서 정한다. `"global_styles": ["glitchy breakbeat with janggu percussion", "crisp clicks", "instrumental"]`처럼 장르·악기·질감을 영어로 적으면 ElevenLabs 플랜이 그 문구를 쓴다. 제외할 것은 `"negative_styles"`, 마지막 섹션의 끝맺음은 `"ending"`(기본 "final big hit then long reverb ring out")으로 정한다.
- `global_styles`가 없으면 mood의 기본 문구를 쓴다: `cinematic`(오케스트라·타이코 트레일러풍) / `pulse`(일렉트로닉 펄스) / `soft`(피아노·현악) / `playful`(경쾌한 팝). `synth_music.py` 대체 경로는 이 네 가지만 만들 수 있으므로 mood는 대체 경로용으로 함께 적어 둔다.
- 쇼릴은 섹션을 `concept.md`의 구간과 맞춘다. 구간마다 소리의 질감이 바뀌어야 하면 섹션 `style`에 악기 변화를 적는다.
- sections의 energy(0~1)는 층의 개수를 정한다. 플랜에서는 무드에 맞는 문장으로 바뀐다(테크 무드에 "orchestra"가 들어가지 않는다).
- 섹션은 4마디 단위로 잡는다(bpm 120이면 8초, 90이면 10.67초). 경계가 마디에 있지 않으면 `plan`이 경고한다. 3초보다 짧은 섹션은 API가 받지 않으므로, `plan`이 경계를 3초 지점으로 밀거나 앞 섹션에 합친다.
- events: hit, boom, braam, riser(끝이 t), whoosh, chime, stop(음악만 잠깐 끊기 — 정적 연출)

### 2) ElevenLabs Music

```bash
python3 scripts/music_tools.py plan audio/music/spec.json            # → audio/music/plan.json
python3 scripts/eleven.py music audio/music/music.mp3 --plan audio/music/plan.json
```

- 섹션은 3초 이상이어야 한다. `plan`이 짧은 섹션을 앞 섹션에 합친다.
- **아티스트·작곡가·곡 이름을 넣지 않는다.** "Hans Zimmer style"이 두 번 400으로 거부됐다. 거부되면 `eleven.py`가 응답의 대체 프롬프트를 보여 준다.
- 생성 시간은 60초 곡에 1~2분이다. 같은 플랜으로 `--seed`를 바꿔 두 곡을 만들어 고를 수 있다. `--prompt`와 `--seed`를 함께 주면 422가 나므로 `eleven.py`가 seed를 빼고 보낸다.
- 402가 나면 합성 음악으로 간다.
- 생성된 곡 길이가 요청과 다를 수 있다(10초 요청에 7초가 나온 사례). `music_tools.py fit`으로 영상 길이에 맞춘 뒤 분석한다.
- 생성된 곡은 대개 평평하다(평가에서 두 곡 모두 82~85%가 최대 세기에서 3dB 안이었다). `analyze`가 경고하면 큰 히트 앞을 믹스에서 내린다. `script.json`의 `music`에 `"automation": [[0, 0], ["line.n07-2.5", 0], ["line.n07-0.3", -10], ["line.n07", 0]]`처럼 [시각, dB]를 적으면 `mix.py`가 그 곡선대로 음악 음량을 바꾼다. 시각은 초·큐 이름·"큐±초"를 쓸 수 있다. 히트 2~3초 앞에서 -8~-12dB로 내렸다가 히트 프레임에 0dB로 돌아오게 하면, 같은 곡에서도 예고 → 타격 구조가 들린다.
- 스펙을 쓸 때 섹션 에너지에 대비를 둔다. 절정(0.9 이상)은 전체의 25% 안, 가운데쯤에 0.3~0.45의 브레이크다운 하나, 이웃 섹션은 `style`에 악기 변화를 적는다(예: "strings drop out, only ticking pulse", "add brass stabs and choir"). `plan`이 평평한 스펙을 경고한다.
- 플랜의 stop(정적 연출)은 무시되는 경우가 많았다(2분 곡에서 확인). 생성 뒤 `analyze`로 다음 프레이즈의 첫 박을 찾고 그 자리까지 끊는다: `python3 scripts/music_tools.py gap audio/music/music.mp3 audio/music/music_edit.wav 103.2-103.97`. `script.json`의 `music.file`을 `audio/music/music_edit.wav`로 바꾸고 `timeline.py`부터 다시 돌린다.

### 3) 합성 음악(대체 경로)

```bash
python3 scripts/synth_music.py music audio/music/spec.json audio/music/music.wav
```

음원 없이 numpy로 만든다. 같은 입력이면 같은 소리가 나고 몇 초면 끝난다. ElevenLabs Music보다 단순하므로 납품 보고에 합성 음악이라고 적는다.

### 4) 분석해서 장면을 맞춘다

**ElevenLabs Music은 플랜의 섹션 길이를 지키지 않는다.** 대개 4마디 단위 프레이즈로 수렴한다(120 BPM이면 8초). 생성한 뒤 반드시 분석한다.

```bash
python3 scripts/music_tools.py analyze audio/music/music.mp3     # → analysis.json: bpm, beats, downbeats, hits, energy
```

- 분석 결과를 보고 장면 경계를 실제 히트·다운비트로 옮긴다. `timeline.py --music-analysis`를 주면 `music.hit1…` 큐가 생기고, 화면에서 `REEL.TL.music.hits`·`downbeats`를 쓸 수 있다.
- 드롭·클라이맥스가 약하면 그 구간만 따로 생성해("starts immediately with a massive hit on the first beat", negative "slow intro") 이어 붙이고, 히트를 다시 분석해 맞춘다.
- 길이가 조금 다르면 `music_tools.py fit in.mp3 out.wav --dur 60`으로 맞춘다(6% 이내면 템포 미세 조정, 아니면 자르기·채우기 + 페이드).
- **드롭이 늦게 오면 박 단위로 잘라 붙인다.** 15초 릴스에서 드롭을 3초에 요청했는데 두 시드 모두 7.8초에 나온 사례가 있다. 분석 결과의 박 시각을 보고, 같은 박 위상(마디 시작끼리)에서 자른다.

```bash
python3 scripts/music_tools.py splice audio/music/music.mp3 audio/music/music_edit.wav \
  --segments 0-3.90,7.78-19.5 --snap audio/music/analysis.json      # 빌드업 앞부분 + 드롭부터 → 드롭이 약 3.9초로 당겨짐
python3 scripts/music_tools.py analyze audio/music/music_edit.wav   # 다시 분석해 장면 경계를 맞춘다
```

## 효과음

```bash
python3 scripts/eleven.py sfx-kit audio/sfx --names impact,whoosh,riser,logo_hit,glitch,ui_blip   # ElevenLabs
python3 scripts/synth_music.py sfx audio/sfx --names impact,whoosh,riser,logo_hit                 # 합성(무료, 즉시)
```

프리셋 이름과 프롬프트는 `assets/sfx_presets.json`에 있다: sub_boom, impact, braam, logo_hit, final_hit, riser, reverse_swell, whoosh, whoosh_deep, glitch, shimmer, ui_blip, ui_ticks, typing, stamp, shutter, counter, heartbeat, clock_tick, crowd, pop, ding, chime, drone. 새 효과음은 `eleven.py sfx "prompt" out.mp3 --dur 2`로 만든다. 길이는 0.5~30초다.

배치 원칙:

- **같은 whoosh를 모든 전환에 반복하지 않는다.** 장면마다 같은 소리를 넣으면 반복돼 단조롭게 들린다. 화면의 재질(종이, 유리, 액체, 금속, 전자음)에 맞는 소리를 `eleven.py sfx "prompt"`로 따로 만들고, 범용 whoosh는 큰 전환 몇 곳에만 쓴다.
- 타격음(impact, logo_hit)은 `align: peak`로 화면 히트 프레임에 맞추되, **나레이션의 핵심 단어와 0.2~0.3초 비켜 놓는다.** 로고 히트가 "커넥트"를 덮어 STT가 "Summit"으로 받아쓴 사례가 있다.
- 라이저는 `align: end`로 끝이 히트 시각에 오게 한다. 1~2초 전에 시작한다.
- 화면에 소리 나는 사물(카운터, 자판)이 있으면 그 소리를 같은 프레임에 넣는다.
- 같은 이벤트가 화면과 소리에 함께 있어야 한다. 효과음 시각은 `script.json`의 큐로 걸어, 화면(`REEL.cue`)과 같은 숫자를 쓴다.

## 믹스 기준

```bash
python3 scripts/mix.py <프로젝트>/timeline.json
```

| 항목 | 기준 |
| --- | --- |
| 소스 정규화 | 나레이션 말소리 RMS -20dBFS, 음악 -16 LUFS, 효과음 피크 -3dBFS(그 뒤 `gain_db`) |
| 나레이션 체인 | 하이패스 70Hz, 220Hz -2dB, 3.2kHz +3dB, 9kHz 셸빙 +1.5dB, 컴프레서 3:1 |
| 나레이션 리버브 | 기본은 넣지 않는다(`--hall 0`). 웅장한 톤에서도 마찬가지이며, 웅장한 느낌은 음악·효과음으로 낸다. 공간감이 꼭 필요할 때만 `--hall 0.04~0.08`(1.4초 홀, 프리딜레이 30ms, 300~5000Hz). `--hall` 값은 말소리 구간의 wet/dry 비율이다(0.06 = wet -24dB) |
| 말 끝 잔향 | 리버브를 쓰면 `mix.py`가 쉼 앞 말 끝 0.05~0.35초의 잔향 크기를 말소리와 비교해 보여 준다. -32dB 이하 ✓, -28dB 초과 ✗. 이전 기본값(2.4초 홀, `--hall 0.12`)은 -22.8dB로, 에코가 너무 많다는 지적을 받았다 |
| 음악 | `gain_db` -6~-10, 덕킹 0.7~0.8(말소리 대역은 더 깊게) |
| 효과음 | 말 위에서 45% 낮춤(`--sfx-duck`) |
| 줄별 나레이션 대 배경 | 9dB 이상 ✓, 6~9dB △, 6dB 미만 ✗ |
| 마스터 | 리미터 → 2패스 loudnorm -14 LUFS, true peak -2.0 dBTP. AAC 인코딩 뒤 피크가 0.5~0.9dB 오르고 공유용 파일은 한 번 더 인코딩하므로 여유를 둔다(`finish.py`가 공유용 피크를 다시 재서 넘으면 낮춘다) |
| 나레이션 없는 영상 | `mix.py`가 효과음마다 "효과음 대 음악" dB를 보여 준다. 타격음은 +3dB 이상이어야 들린다 |

✗ 줄 고치는 순서: 그 줄 근처 효과음 `gain_db`를 낮추거나 시각을 비킨다 → 그 줄 `gain_db` +2~3 → `--duck 0.8`. 원인이 헷갈리면 `--mute music` / `--mute sfx`로 하나씩 끄고 다시 본다.

## 자주 생기는 문제

| 증상 | 원인과 조치 |
| --- | --- |
| Python에서 `CERTIFICATE_VERIFY_FAILED` | python.org 배포판의 인증서 문제다. 검증을 끄지 않는다. `eleven.py`는 curl을 쓴다 |
| mp3가 재생되지 않음("Failed to find two consecutive MPEG audio frames") | 오류 JSON이 mp3 이름으로 저장된 것이다. `eleven.py`가 HTTP 상태와 내용을 검사해 막는다 |
| 빈 텍스트로 TTS 호출 | 200과 무음 mp3가 온다. `eleven.py`가 미리 막는다 |
| 효과음이 거의 무음 | `sfx-kit`이 피크 -24dB 미만이면 프롬프트를 바꿔 다시 만든다 |
| 음악 섹션 422 | 섹션이 3초 미만이다. `music_tools.py plan`이 합친다 |
| 나레이션에 에코·울림이 많음 | `--hall`을 빼고 `mix.py` → `finish.py`만 다시 돌린다. ElevenLabs 원본 클립은 말이 끝나면 0.1초 안에 -60dBFS까지 떨어지므로, 에코는 믹스에서 넣은 리버브 때문이다 |
| 나레이션 길이가 정렬 정보와 다름 | 후처리(리버브·apad)로 길이가 바뀐 클립은 정렬을 다시 계산해야 한다. 원본 클립은 수정하지 말고 믹서에서 처리한다 |
| 소리가 맞는지 모르겠음 | Claude는 소리를 들을 수 없다. 수치(VO 대 배경, LUFS, STT, 스펙트로그램)로 확인하고 사용자에게 청취를 부탁한다 |
