# 릴리스

## 기본 번들 자산

```bash
./Scripts/build-bundled-assets.sh
```

공개 저장소 생성 후 Elsa·아이콘·현지화를 코드와 분리해 게시합니다.

```bash
gh release create bundled-assets-v1 \
  dist/bundled-assets/Meownitor-Bundled-Assets-v1.zip \
  dist/bundled-assets/Meownitor-Bundled-Assets-v1.zip.sha256 \
  --title "Meownitor Bundled Assets v1"
```

새 clone은 `Scripts/bootstrap-bundled-assets.sh`로 이를 복원합니다. `Resources/` 파일을 `git add -f`로 우회해 넣지 않습니다.

## 고양이 팩

QA가 완료된 ID만 명시합니다.

```bash
CAT_PACK_REPOSITORY=kimdwkimdw/meownitor \
CAT_PACK_TAG=cat-packs-v1 \
./Scripts/build-cat-packs.sh K02
```

검수 후 Release를 만듭니다.

```bash
gh release create cat-packs-v1 \
  dist/cat-packs/Meownitor-Cat-*-v1.zip \
  dist/cat-packs/cat-packs.json \
  --title "Meownitor Cat Packs v1"
```

게시된 `cat-packs.json`을 `Resources/CatPacks/cat-packs.json`에 복사하고 앱 테스트를 다시 실행합니다. 존재하지 않는 URL이나 QA 미완료 ID를 수동으로 카탈로그에 추가하지 않습니다.

## 앱

```bash
swift test
./Scripts/build-app.sh
git tag v0.3.0
git push origin v0.3.0
```

`v*` 태그는 GitHub Actions에서 앱 ZIP을 만듭니다. 현재 로컬 빌드는 ad-hoc 서명이므로, 일반 사용자에게 배포하기 전 Developer ID 인증서·notarytool 자격 증명·stapling을 추가해야 합니다.

공개 전 최종 확인:

- 저장소에 `Resources/Cats`, Elsa 제작 원본, `.codex-logs`, 비밀값이 추적되지 않음
- 저장소에 `Resources/` 파일이 하나도 추적되지 않음
- README의 진행 상태가 실제 QA와 일치
- 앱 ZIP에 Elsa 15개와 승인된 catalog만 존재
- Release URL에서 다운로드·설치·삭제 왕복 성공
