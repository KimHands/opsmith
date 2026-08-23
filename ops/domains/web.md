# 웹·앱 개발 규칙
구현 전 실패하는 테스트를 먼저 쓴다.
DB는 read-only 계정으로 연결한다. 스키마 변경·마이그레이션은 사람이 한다.
배포를 트리거하는 명령(PR 머지 등)은 매번 명시적 확인 후 실행한다.
브라우저 확인이 필요하면 `gstack`을 명시 호출한다.

## 단계별 도구 배치
기획·설계 → superpowers:brainstorming · writing-plans / 구현 → test-driven-development + 언어 LSP + context7
리뷰 → /code-review 먼저, 그 뒤 code-simplifier·static-analysis를 명시 호출 / 마무리 → gh 커밋·PR
