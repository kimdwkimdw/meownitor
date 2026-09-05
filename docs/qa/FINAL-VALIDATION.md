# 2026-08-05 검증 기록

이 문서는 당시의 기록입니다. 최신 웹 알파 검증은 [WEB-ALPHA.md](WEB-ALPHA.md)를 확인하세요.

검증 시각: 2026-08-05 KST

- 기준 commit: `908cf76e599e`
- `swift test`: 17 tests, 0 failures
- release 앱 build, ad-hoc 서명과 strict codesign: 통과
- 앱 번들: 73,211,904 bytes
- 측정용 앱 ZIP: 72,081,897 bytes, 약 68.7MiB
- 기본 포함 WebP: Elsa·K01·K02·K03 각 15개, 총 60개
- 다른 고양이의 앱 번들 WebP: 0개
- 각 WebP: `8778×1254`, 7프레임, visible pixel과 투명 모서리 검사 통과
- 번들 교체 ZIP: 71,918,522 bytes, 파일 63개 중 WebP 60개
- 번들 교체 ZIP SHA-256: `7a0627e0179a4cdff6c53e261d7a420b9e22bcdfbf30a74dcd0b416a2c6a4834`
- 번들 교체 ZIP의 local HTTP 다운로드·checksum·bootstrap 왕복 통과
- catalog 검증: 기본 포함 K01~K03 항목 무시, 중복 ID 거부, K04 설치·삭제 상태 검사 통과
- 기본 포함 K01~K03의 팩 생성 차단
- 전체 고양이 제작 자산: Elsa와 K01~K10·U01~U10의 15동작 및 시각 QA 완료
- `/Applications/Meownitor.app`: 새 빌드 설치·strict codesign·실행 확인, 기본 WebP 60개
- 기존 Application Support 다운로드 팩 20개: 설치 교체 후 그대로 보존

로컬 구현과 자산 검증은 완료됐습니다. 원격 `bundled-assets-v1` 교체, K04~K10·U01~U10의 17개 다운로드 catalog 게시, 원격 왕복·clean-clone·CI 검증은 아직 수행하지 않았습니다. Developer ID/notarization과 앱 버전 태그는 별도 범위입니다.
