# QA

## 자동

```bash
./Scripts/bootstrap-bundled-assets.sh
swift test
./Scripts/build-app.sh
codesign --verify --deep --strict .build/Meownitor.app
```

확인 항목:

- MacBook/iMac/외장 모니터/외장 키보드/idle/미루기 정책
- 내장 화면 전용 overlay와 ESC 두 번 닫기
- Elsa WebP 15개, 각 `8778×1254`, 7프레임과 투명 모서리
- 팩 카탈로그 파싱, 설치 상태, 삭제
- 앱 번들에 Elsa 15개만 있고 `Resources/Cats`가 없음
- 앱 번들 약 12MB
- `git rev-list --objects --all`에 `Resources/` 바이너리가 없음

팩 생성:

```bash
./Scripts/build-cat-packs.sh K02
unzip -l dist/cat-packs/Meownitor-Cat-K02-v1.zip
```

스크립트는 다음 중 하나라도 틀리면 실패해야 합니다.

- raw 동작 디렉터리 15개
- intermediate 동작 디렉터리 15개
- chroma 보고서 15개
- reflection 보고서 15개
- WebP 스트립 15개
- 모든 스트립 `8778×1254`

## 시각

각 고양이의 contact sheet와 15개 GIF에서 다음을 확인합니다.

- 동일 고양이 정체성·털무늬·눈색·노출
- 추가/누락된 팔다리 없음
- 동작 부위의 실제 해부학 변화
- 심한 크기·위치 점프 없음
- 루프 마지막에서 첫 프레임으로 자연스러운 복귀
- 어두운/밝은 배경에서 마젠타 fringe, 검은 코, 회색 반사 패치 없음
- 신체와 수염 클리핑 없음

## 실제 앱

1. 설정에서 Elsa가 기본 선택되고 “앱에 기본 포함됨”을 확인합니다.
2. 미설치 고양이는 “제작 및 검수 중” 또는 다운로드 크기를 표시하고 미리보기를 비활성화합니다.
3. Release 팩 다운로드 후 자동 선택·미리보기·재실행 지속성을 확인합니다.
4. 삭제 후 Elsa로 복귀하고 Application Support의 해당 ID만 사라지는지 확인합니다.
5. 큰/작은/권한 overlay가 외장 화면이 아닌 내장 화면에만 나타나는지 확인합니다.
6. 외장 모니터 또는 외장 키보드 사용 중 자동 overlay가 나타나지 않는지 확인합니다.

실제 Release가 게시되기 전에는 3~4번을 완료로 표시하지 않습니다.
