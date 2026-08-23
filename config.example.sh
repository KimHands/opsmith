# opsmith 설정. 이 파일을 config.sh 로 복사해 값을 채운 뒤 install.sh 를 실행하세요.
#   cp config.example.sh config.sh

# 전역 규칙(AGENTS.md)에 들어갈 소개. 비워두면 플레이스홀더가 남습니다.
WORKFLOW_NAME=""          # 예: 홍길동
WORKFLOW_FIELD=""         # 예: OO대학교 컴퓨터공학과 (선택)
WORKFLOW_LANG="한국어"     # 설명 언어

# 네이티브 memory를 미러할 대상 절대경로. 비우면 미러 기능을 설치하지 않습니다.
#   예: "$HOME/Library/Mobile Documents/com~apple~CloudDocs/MyVault/50_PROJECTS"
WORKFLOW_MIRROR_DEST=""

# 세션 종료/알림 시 소리(macOS afplay). on|off. 비-macOS에서는 무시됩니다.
WORKFLOW_SOUND="off"
