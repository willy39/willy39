# Security Policy

## Supported versions

| Version | Supported |
| --- | --- |
| 1.0.x | ✓ |
| < 1.0 | ✗ |

## Reporting a vulnerability

Please do **not** open a public issue for security problems.

Use GitHub's private vulnerability reporting: open the [Security tab](https://github.com/revfactory/showreel/security) of this repository and choose **Report a vulnerability**. Include the affected file, steps to reproduce and the impact you expect. The maintainer aims to acknowledge reports within 7 days and will tell you whether the report is accepted and when a fix is expected.

## Scope

Examples of issues in scope:

- API keys exposed in logs, generated files or error messages
- Scripts that execute or load untrusted input in an unsafe way (file paths, project files, downloaded fonts or media)
- Disabled or bypassed TLS verification

Out of scope: vulnerabilities in third-party services (ElevenLabs, OpenAI Codex), in Claude Code itself, or in dependencies that are already reported upstream.

## Handling secrets

- `ELEVENLABS_API_KEY` is read from the environment or a project `.env` file. `.env` is listed in `.gitignore`; keep it out of commits.
- `eleven.py` calls the API with `curl` and checks HTTP status and content type, so error responses are not saved as audio files.
- Generated narration, music and images may be subject to your provider's terms. Check them before publishing.

## 한국어 요약

보안 문제는 공개 이슈로 올리지 말고, 저장소의 [Security 탭](https://github.com/revfactory/showreel/security)에서 **Report a vulnerability**로 비공개 신고해 주세요. 관련 파일, 재현 방법, 예상 영향을 적어 주시면 관리자가 7일 안에 확인하는 것을 목표로 합니다. API 키는 환경 변수나 `.env`에 두고 커밋하지 마세요.
