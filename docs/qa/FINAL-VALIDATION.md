# 현재 검증 기록

검증 시각: 2026-07-30 KST

- `swift test`: 16 tests, 0 failures
- release 앱 build와 ad-hoc 서명: 통과
- 앱 번들: 12MB
- Elsa 런타임 WebP: 15개, 각 `8778×1254`
- 추가 고양이 번들 포함: 0개
- K02 팩: 15동작 제작 증거와 ZIP 규격 게이트 통과
- K02 ZIP: 15 WebP 외 AppleDouble/resource fork 없음
- Git history: Codex 자산 checkpoint 삭제 후 `.git` 2.3GB → 88KB, 도달 가능 객체 0
- `Resources/` 전체 Git ignore, bundled-assets ZIP 12MB와 local HTTP bootstrap 왕복 통과
- 설정 UI: macOS 실제 창에서 상태·버튼·설명 잘림 없음
- 미완성 고양이: 다운로드와 미리보기 비활성화

아직 최종 완료가 아닙니다. K01·K02·K03·K04 팩 게시와 실제 원격 다운로드·삭제 검증은 끝났으며, 나머지 16종 실사 애니메이션, Developer ID/notarization과 최종 설치 QA가 남아 있습니다.
