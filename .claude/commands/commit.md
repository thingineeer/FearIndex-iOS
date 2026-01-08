# /commit - 커밋 정책에 따라 커밋하기

이 skill은 `.claude/commit-policy.md`를 읽고 정책에 맞게 커밋합니다.

## 실행 시 수행할 작업

1. `.claude/commit-policy.md` 파일 읽기
2. `git status`로 변경사항 확인
3. `git diff --stat`로 변경된 파일 목록 확인
4. 변경사항을 논리적 단위로 분류
5. 각 단위별로 커밋 (정책 준수)

## 커밋 정책 요약

### 절대 포함하지 않을 것
- `Generated with [Claude Code]`
- `Co-Authored-By: Claude`
- AI 생성 관련 모든 문구

### 커밋 메시지 형식
```
<type>: <subject>

- 변경사항 1
- 변경사항 2
```

### Type 종류
- `feat`: 새로운 기능
- `fix`: 버그 수정
- `refactor`: 리팩토링
- `style`: 코드 스타일 변경
- `docs`: 문서 수정
- `chore`: 빌드, 설정 등

## 커밋 명령어 예시

```bash
git add <files>
git commit -m "$(cat <<'EOF'
feat: 로그인 기능 구현

- AuthRepository 프로토콜 정의
- Firebase Auth 연동
EOF
)"
```

## 주의사항
- HEREDOC 사용 시 EOF 앞에 공백 없이
- 커밋 단위는 revert 가능한 크기로
- 한글 커밋 메시지 사용

## 사용법

```
/commit
```

실행하면 정책을 읽고 현재 변경사항을 커밋합니다.
