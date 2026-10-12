# Contributing to showreel

Thank you for your interest in improving `showreel`. This guide explains how to set up a development copy, what to check before opening a pull request, and how the skill's documents are written.

한국어 안내는 이 문서 아래쪽 [한국어](#한국어)에 있습니다.

## Ways to contribute

- **Bug reports**: a script fails, a render looks wrong, QA misses a problem. Use the bug report template.
- **Feature requests**: new techniques, mood presets, video formats, providers. Use the feature request template.
- **Pull requests**: fixes, new techniques with code, documentation improvements.

For larger changes, open an issue first so the approach can be agreed before you spend time on it.

## Development setup

```bash
git clone https://github.com/<your-account>/showreel.git ~/.claude/skills/showreel
cd ~/.claude/skills/showreel/scripts && npm install
python3 -m pip install numpy pillow
python3 ~/.claude/skills/showreel/scripts/preflight.py
```

If you already have the skill installed, move the existing folder aside first. Claude Code loads the skill from `~/.claude/skills/showreel`, so your working copy is what Claude uses.

## Testing your change

There is no unit test suite. Changes are checked by running the affected step on a small project and looking at the output.

1. Create a test project outside the repository:

   ```bash
   python3 ~/.claude/skills/showreel/scripts/new_project.py /tmp/showreel-test --ratio 16:9 --duration 15
   ```

2. Run the scripts your change touches, for example `timeline.py`, `render.mjs --stills`, `mix.py` or `qa_check.py`.
3. For visual changes, render stills or a draft and attach a contact sheet (`contact_sheet.py`) to the pull request.
4. For audio changes, attach the numeric report (`mix.py` table, loudness, STT result) and describe what you listened to.
5. For changes to `SKILL.md` or `references/`, run at least one prompt from `evals/evals.json` end to end with Claude Code and report which assertions pass.

## Rules the engine depends on

- A frame is a pure function of time `t`. Do not use `Math.random`, `Date.now`, CSS transitions or animations, or state carried over from a previous frame. The renderer seeks to arbitrary times and splits frames across workers.
- Scene timing comes from named cues (`REEL.cue('name')`), not hard-coded seconds.
- Keep photosensitive safety: flashes at opacity 0.15 or lower on dark backgrounds, no more than three per second.
- Do not add code that disables TLS verification or prints API keys.

## Writing style for skill documents

`SKILL.md` and `references/` are read by Claude while it works, and they are written in Korean.

- Write plain, direct Korean sentences with a clear subject and verb.
- Do not use metaphors. Name the object or give a concrete number or example.
- When a rule exists because of a past failure, state the failure in one sentence so the reason is visible.
- Keep `SKILL.md` focused on the workflow; put detail in the matching file under `references/`.

## Pull request checklist

- [ ] The change is described, with the reason and how you tested it.
- [ ] Renders and audio still pass `qa_check.py` on a test project.
- [ ] No API keys, `.env` files, personal paths or generated media you do not have rights to share.
- [ ] Documentation (`SKILL.md`, `references/`, `README.md`, `README.ko.md`) is updated where behavior changed.
- [ ] `CHANGELOG.md` has an entry under **Unreleased**.

## Code of Conduct

By participating, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

---

## 한국어

`showreel`에 기여해 주셔서 고맙습니다. 위 영어 안내와 같은 내용을 요약합니다.

- **버그 신고와 기능 제안**은 이슈 템플릿으로 남겨 주세요. 큰 변경은 PR 전에 이슈로 먼저 방향을 맞춰 주시길 권합니다.
- **개발 환경**: 저장소를 `~/.claude/skills/showreel`에 내려받고 `scripts/`에서 `npm install`, `pip install numpy pillow`를 실행한 뒤 `preflight.py`로 점검합니다.
- **확인 방법**: 단위 테스트는 없습니다. 저장소 밖에 짧은 테스트 프로젝트를 만들고, 바꾼 단계의 스크립트를 실행해 결과를 확인합니다. 화면을 바꿨다면 검수 시트를, 소리를 바꿨다면 `mix.py` 표와 음량·받아쓰기 결과를 PR에 붙여 주세요. `SKILL.md`나 `references/`를 바꿨다면 `evals/evals.json`의 프롬프트 하나 이상을 처음부터 끝까지 돌려 판정 결과를 적어 주세요.
- **엔진 규칙**: 화면은 시간 t만으로 정해져야 합니다. `Math.random`, `Date.now`, CSS transition·animation, 이전 프레임 상태를 쓰지 않습니다. 시각은 `REEL.cue('이름')`으로 씁니다.
- **문서 문체**: `SKILL.md`와 `references/`는 Claude가 작업 중에 읽는 한국어 문서입니다. 주어와 동사가 분명한 평이한 문장으로 쓰고, 비유를 쓰지 않습니다. 과거 실패 때문에 생긴 규칙은 그 사례를 한 문장으로 함께 적습니다.
- **PR 전 확인**: API 키, `.env`, 개인 경로, 공유할 권리가 없는 생성물이 들어가지 않았는지 확인하고, 동작이 바뀌었으면 문서와 `CHANGELOG.md`의 **Unreleased**를 고쳐 주세요.
