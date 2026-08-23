#!/usr/bin/env python3
"""SessionStart 훅.
 - 프로젝트 루트에 CLAUDE.md가 없으면 **자동으로 만들어 준다**(1줄 포인터. 되돌리기 쉬움)
 - 서브폴더 진입 / 규칙 밖 폴더는 경고만 한다. 절대 세션을 막지 않는다.
자동 생성이 싫으면 ~/Ops/.no-autoheal 파일을 만들면 꺼진다.
"""
import json, os

HOME = os.path.expanduser("~")
ROOTS = [os.path.join(HOME, "Desktop", "Projects"), os.path.join(HOME, "Desktop", "Career")]
AUTOHEAL_OFF = os.path.join(HOME, "Ops", ".no-autoheal")

SKELETON = """# {name}

(한 줄로 이 프로젝트가 무엇인지 적으세요)

## 이 프로젝트에서 항상 지킬 것
- 형식 규칙: `~/Ops/domains/` 에서 해당하는 것을 참조 (deck / hwp / web / paper)
- (작업하다 "또 이걸 어겼네" 싶은 게 생기면 여기에 한 줄씩 추가하세요)
"""

def heal(proj_root):
    """CLAUDE.md(+AGENTS.md)를 만들어 준다. 실패해도 조용히 넘어간다."""
    made = []
    try:
        c = os.path.join(proj_root, "CLAUDE.md")
        a = os.path.join(proj_root, "AGENTS.md")
        if not os.path.exists(a):
            with open(a, "w", encoding="utf-8") as f:
                f.write(SKELETON.format(name=os.path.basename(proj_root)))
            made.append("AGENTS.md")
        if not os.path.exists(c):
            with open(c, "w", encoding="utf-8") as f:
                f.write("@AGENTS.md\n")
            made.append("CLAUDE.md")
    except Exception:
        return []
    return made

def build(cwd):
    msgs = []
    for root in ROOTS:
        if not cwd.startswith(root + os.sep):
            continue
        parts = os.path.relpath(cwd, root).split(os.sep)
        proj_root = os.path.join(root, parts[0])

        if len(parts) > 1:
            msgs.append(
                f"⚠ 서브폴더에서 세션을 열었습니다. memory는 경로별로 갈라지므로 "
                f"프로젝트 루트({proj_root})에서 여는 것이 원칙입니다.")

        if not os.path.isfile(os.path.join(proj_root, "CLAUDE.md")):
            if os.path.exists(AUTOHEAL_OFF):
                msgs.append(
                    f"⚠ {os.path.basename(proj_root)}에 CLAUDE.md가 없어 프로젝트 규칙이 주입되지 않습니다. "
                    f"루트에 CLAUDE.md를 만들고 첫 줄에 @AGENTS.md 를 넣으세요.")
            else:
                made = heal(proj_root)
                if made:
                    msgs.append(
                        f"✅ {os.path.basename(proj_root)}에 {' · '.join(made)}를 자동 생성했습니다. "
                        f"AGENTS.md에 이 프로젝트에서 지킬 규칙을 3~6개 적어두세요.")
                else:
                    msgs.append(
                        f"⚠ {os.path.basename(proj_root)}에 CLAUDE.md가 없는데 자동 생성에 실패했습니다. "
                        f"직접 만들어 주세요(첫 줄 @AGENTS.md).")
        break
    else:
        d = os.path.join(HOME, "Desktop")
        if cwd.startswith(d + os.sep):
            top = os.path.relpath(cwd, d).split(os.sep)[0]
            if top not in ("Projects", "Career", "Inbox"):
                msgs.append(
                    f"⚠ '{top}'은 폴더 규칙 밖입니다. 마감이 있으면 Projects/, "
                    f"끝이 없으면 Career/, 미분류면 Inbox/ 로 옮기세요.")
    return "\n".join(msgs)

def main():
    try:
        ctx = build(os.getcwd())
    except Exception:
        ctx = ""      # fail-safe: 세션 시작을 절대 깨뜨리지 않는다
    if ctx:
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "SessionStart", "additionalContext": ctx}}, ensure_ascii=False))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
