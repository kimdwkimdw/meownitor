# 아키텍처

```text
AppDelegate
├── MonitoringEngine
│   ├── SystemSnapshotProvider
│   ├── ExternalKeyboardMonitor
│   └── MonitorPolicy
├── SettingsController
│   ├── CatProfile
│   └── CatPackStore
└── OverlayController
    └── SpriteView
```

## 런타임

- `AppDelegate`: 메뉴바, 언어, 로그인 항목, 미루기와 overlay 수명
- `MonitorPolicy`: 입력 시간과 하드웨어 상태를 판단하는 순수 상태 머신
- `OverlayController`: `CGDisplayIsBuiltin`으로 찾은 온라인 내장 화면에만 패널 표시
- `SpriteView`: `8778×1254` 스트립을 일곱 개의 `1254×1254` 프레임으로 재생
- `CatProfile`: 21개 고양이의 ID·한/영 이름·품종
- `CatPackStore`: Release 카탈로그, 다운로드, SHA-256, ZIP 해제, 규격 검증, 설치·삭제

Elsa는 앱 번들의 `Contents/Resources/ElsaHD/*.webp`에서 읽습니다. 소스 clone은 `bundled-assets-v1` Release를 bootstrap해 Elsa와 아이콘을 로컬 `Resources/`에 복원합니다. 추가 고양이는 `~/Library/Application Support/Meownitor/Cats/<ID>/strips`를 우선 사용하며, 개발 중에는 로컬 `Resources/Cats/<ID>/strips`가 마지막 fallback입니다.

미설치 고양이가 이전 설정에 남아 있으면 `CatProfile.selected`가 Elsa로 복귀합니다. 설치는 임시 디렉터리에서 전부 검증한 뒤 ID별 디렉터리를 교체하므로 부분 다운로드를 런타임이 읽지 않습니다.

## 네트워크와 개인정보

일반 모니터링에는 네트워크를 사용하지 않습니다. 설정을 열 때 고정된 GitHub Release URL의 1MB 이하 카탈로그를 새로고침하고, 사용자가 다운로드를 누르면 해당 HTTPS 자산을 받습니다. 계정·분석 SDK·키 입력 문자열은 없습니다.

## 배포

`Resources/`는 전부 Git ignore 대상입니다. `Scripts/bootstrap-bundled-assets.sh`가 별도 Release ZIP과 SHA-256을 검증한 뒤 로컬 자산을 복원하고, `Scripts/build-app.sh`가 Elsa WebP를 포함해 ad-hoc 서명합니다. 일반 사용자 배포 전에 Developer ID 서명과 notarization이 별도로 필요합니다.
