# 현재 검증 기록

검증 시각: 2026-08-01 KST

- `swift test`: 17 tests, 0 failures
- release 앱 build, ad-hoc 서명과 strict codesign: 통과
- 앱 번들: 13MB
- Elsa 런타임 WebP: 15개, 각 `8778×1254`
- 추가 고양이 번들 포함: 0개
- K05 제작 증거: raw·intermediate·chroma·reflection·GIF·WebP 각 15세트
- K05 WebP: 15개, 각 `8778×1254`, 7프레임 contact sheet 시각 QA 통과
- K05 ZIP: `K05/strips/*.webp` 15개, 9,889,297 bytes
- K05 SHA-256: `c44b06e7edaf42186a292e4cba085d6104d648e85da48bc561cfabf2b869d9b4`
- 원격 catalog: K01~K05 5개, 중복 없음, K01~K04 값 불변
- 원격 K05 재다운로드: size·SHA-256·파일 집합·strip 규격 재검증 통과
- Git history: Codex 자산 checkpoint 삭제 후 `.git` 2.3GB → 88KB, 도달 가능 객체 0
- `Resources/` 전체 Git ignore, bundled-assets ZIP 12MB와 local HTTP bootstrap 왕복 통과
- 설정 UI: macOS 실제 창에서 상태·버튼·설명 잘림 없음
- K05 앱 왕복: 다운로드 후 자동 선택·실제 미리보기·재실행 유지·삭제 후 Elsa 복귀 통과
- 미완성 고양이: 다운로드와 미리보기 비활성화

K01~K05 팩 게시와 실제 원격 다운로드·삭제 검증은 끝났습니다. 나머지 15종 실사 애니메이션과 별도 범위인 Developer ID/notarization이 남아 있습니다.
