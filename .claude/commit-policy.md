# Git Commit Policy

## Author 설정
- Name: thingineeer
- Email: dlaudwls1203@gmail.com

## 절대 포함하지 않을 것
- `Generated with [Claude Code]`
- `Co-Authored-By: Claude`
- AI 생성 관련 모든 문구

## 커밋 메시지 형식
```
<type>: <subject>

<description>
```

### Type 종류
- `feat`: 새로운 기능
- `fix`: 버그 수정
- `refactor`: 리팩토링
- `style`: 코드 스타일 변경
- `docs`: 문서 수정
- `chore`: 빌드, 설정 등
- `test`: 테스트 추가/수정

### Subject 규칙
- 한글로 작성
- 50자 이내
- 명사형으로 끝내기 (예: "로그인 기능 구현", "버그 수정")

### Description 규칙
- 어떻게 해결했는지 상세 설명
- bullet point로 작성
- 각 항목은 `-`로 시작

## 커밋 단위 원칙
1. **하나의 논리적 변경 = 하나의 커밋**
2. **revert 가능한 최소 단위**
3. **기능별, 파일 그룹별 분리**

### 좋은 예시
```
feat: 이벤트 구독 기능 추가

- subscribeClick() 호출 추가
- subscribeCrosshairMove() 호출 추가
```

```
fix: 기간 변경 시 데이터 동기화 문제 해결

- updateUIView에서 parent 참조 갱신
- currentData 동기화 로직 추가
```

### 나쁜 예시
```
feat: 여러 기능 구현  # 너무 포괄적
fix: 버그 수정  # 무슨 버그인지 알 수 없음
```

## 커밋 명령어
```bash
git add <files>
git commit --author="thingineeer <dlaudwls1203@gmail.com>" -m "$(cat <<'EOF'
<type>: <subject>

<description>
EOF
)"
```

## 주의사항
- 커밋 전 `git diff --staged`로 변경사항 확인
- 관련 없는 파일은 별도 커밋으로 분리
- 빌드 깨지는 상태로 커밋하지 않기
