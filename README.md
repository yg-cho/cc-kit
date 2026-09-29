# cc-kit

개인·팀 공용 Claude Code 플러그인 모음.

## 설치

```
/plugin marketplace add yg-cho/cc-kit
/plugin install bulk-reader@cc-kit
```

설치 후 Claude Code 재시작.

## 플러그인

### bulk-reader

큰 파일을 메인 컨텍스트에 통째로 올리지 않게 한다.

- **훅**: `Read` 또는 `cat/less/more/bat`로 350줄 넘는 텍스트 파일 전체를 읽으면 차단하고 대안 안내.
  - 통과: `Read(offset, limit)` 구간 읽기, 파이프·리다이렉트 섞인 명령, 바이너리, bulk-reader 에이전트 자신.
- **에이전트** `bulk-reader` (Sonnet, effort low): 파일을 나눠 읽고 줄번호 근거 붙은 불릿 요약만 반환.

설정:

- `BULK_READ_THRESHOLD` 차단 기준 줄 수 (기본 350)
- 의존성: `jq` (없으면 훅 비활성)
