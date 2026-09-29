#!/usr/bin/env bash
# bulk-read gate - PreToolUse(Read|Bash) 훅.
# THRESHOLD줄 초과 텍스트 파일의 전체 읽기를 차단하고 bulk-reader 서브에이전트 위임을 안내한다.
# 통과: offset/limit 지정 Read, 바이너리, bulk-reader 에이전트 자신, 파이프 섞인 Bash, jq 없음.
THRESHOLD="${BULK_READ_THRESHOLD:-350}"
[ -n "${BULK_READER:-}" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat)
AT=$(printf "%s" "$INPUT" | jq -r ".agent_type // empty")
[ -n "$AT" ] && [ "$AT" != "${AT%bulk-reader}" ] && exit 0
TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')
FILES=()
if [ "$TOOL" = "Bash" ]; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
  # 단순 전체 출력 명령만 검사: cat/less/more/bat FILE... (파이프·리다이렉트 있으면 통과)
  case "$CMD" in *'|'*|*'>'*|*';'*|*'&&'*) exit 0 ;; esac
  set -- $CMD
  case "${1##*/}" in cat|less|more|bat) shift ;; *) exit 0 ;; esac
  for a in "$@"; do [ "${a#-}" = "$a" ] && FILES+=("${a/#\~/$HOME}"); done
else
  RANGE=$(printf '%s' "$INPUT" | jq -r '[.tool_input.offset, .tool_input.limit] | map(select(. != null)) | length')
  [ "$RANGE" -gt 0 ] && exit 0
  FILES+=("$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')")
fi
for FILE in "${FILES[@]}"; do
  [ -n "$FILE" ] && [ -f "$FILE" ] || continue
  grep -Iq . "$FILE" 2>/dev/null || continue
  LINES=$(wc -l < "$FILE" | tr -d ' ')
  [ "$LINES" -le "$THRESHOLD" ] && continue
  cat >&2 <<MSG
[bulk-read gate] $FILE ${LINES}줄. ${THRESHOLD}줄 초과 전체 읽기 차단(컨텍스트 보호).
대안 1: 편집·정밀 검토용이면 필요한 구간만 Read(offset, limit).
대안 2: 내용 파악·요약·표 추출·검색이면 bulk-reader 서브에이전트에 질문+파일 경로 넘겨 위임. 파일 여러 개면 병렬.
MSG
  exit 2
done
exit 0
