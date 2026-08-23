# my-workflow

**Claude Code를 위한 개인 운용체계(operating layer) 템플릿.**
규칙은 항상 주입되는 문서로, 반복 작업은 스크립트로, 검증은 다른 벤더로 —
이 세 가지를 `~/Ops/` 한 곳에 모아 누구나 설치해 쓸 수 있게 만든 것.

설계 배경은 [`docs/philosophy.md`](docs/philosophy.md)와
[`docs/decisions.md`](docs/decisions.md)를 먼저 읽으면 이해가 빠릅니다.

## 무엇이 설치되나

- `~/Ops/AGENTS.md` → `~/.claude/CLAUDE.md` 심링크로 **모든 세션에 자동 주입**되는 전역 규칙
- `~/Ops/domains/*.md` — 발표자료·한글문서·웹개발·논문·검증의 형식별 규칙
- `~/Ops/bin/*` — 새 프로젝트 생성, SessionStart 가드, 메모리 미러, 회귀 측정 루프,
  교차검증 루프, 백업 스크립트
- `~/.claude/settings.json`에 훅 2개(SessionStart 가드 · Stop 미러)와 `~/Ops` 읽기 권한 **병합**
- `~/.zshrc`에 `newproj` · `proj` · `ops` 단축키

## 설치

**요구사항:** [Claude Code](https://code.claude.com) · Python 3 · bash · git. (외부 의존성 없음, 표준 라이브러리만.)

```bash
git clone https://github.com/<your>/my-workflow.git
cd my-workflow
cp config.example.sh config.sh    # 이름·언어·미러대상·사운드를 채운다
bash install.sh
source ~/.zshrc                    # 단축키 즉시 반영
# Claude Code 재시작 → 훅 로드
```

**멱등 설치** — 여러 번 돌려도 안전하며 기존 설정을 덮어쓰지 않고 병합합니다(항상 `.bak` 백업).

제거: `bash uninstall.sh` (병합분만 되돌리고 `~/Ops` 데이터는 보존).

## 하루 사용법

```bash
newproj my-talk deck     # 규칙에 맞는 새 프로젝트 생성 + 이동
proj my-talk             # 기존 프로젝트로 이동
ops                      # ~/Ops 로 이동
```

새 프로젝트는 폴더명 규칙(ASCII 소문자·숫자·하이픈, 개명 금지)을 강제하고,
루트에 `CLAUDE.md`(→`@AGENTS.md`) 골격을 만듭니다. 세션을 열면 SessionStart 가드가
누락된 `CLAUDE.md`를 자동 생성하고 규칙 위반을 경고합니다(막지는 않음).

## 저장소 구조

```
ops/          ~/Ops 로 설치될 템플릿 (규칙·domains·bin·adr·golden)
claude/       ~/.claude 에 병합될 훅/권한 스니펫
              (settings.snippet.json 은 예시용 — $HOME 경로는 install.sh 가 실행 시점에 치환하므로
               직접 복사하지 말고 반드시 install.sh 를 통해 설치하세요)
config.example.sh  사용자가 채우는 값
install.sh · uninstall.sh
docs/         설계 철학·버린 대안·운용 설명서
tests/        격리 스모크 테스트
```

## 검증

```bash
bash tests/install-smoke.sh   # 임시 HOME에서 설치·멱등성 검증 (실제 홈 무해)
```

## 라이선스

MIT
