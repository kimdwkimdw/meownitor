# 목펴라냥 (Meownitor)

MacBook을 내장 화면과 내장 키보드만으로 25분 이상 사용할 때 귀여운 실사 고양이로 자세를 환기하는 macOS 메뉴바 앱입니다.

## 주요 동작

- MacBook + 외장 모니터 없음 + 내장 키보드 사용: 25분 후 큰 고양이 경고
- 외장 모니터 또는 외장 키보드 사용: 경고 중지와 누적 시간 초기화
- iMac: 큰 경고 없이 30~60분 간격의 작은 휴식 알림
- Dock 아이콘 없이 메뉴바에서만 실행
- 큰 경고에서 30분·1시간·2시간 미루기
- `ESC` 두 번으로 즉시 닫기
- 모든 고양이 UI는 MacBook 내장 화면에만 표시

입력 모니터링 권한은 선택 사항입니다. 권한이 없으면 외장 키보드는 구분하지 못하지만 외장 모니터 연결 여부만으로 앱을 사용할 수 있습니다. 키 입력 내용은 저장하거나 전송하지 않습니다.

## 고양이

Elsa HD는 앱에 기본 포함됩니다. 한국 10종과 미국 10종은 설정에서 보고, 원하는 고양이만 GitHub Release에서 내려받거나 삭제할 수 있습니다.

- 앱 기본 크기: 약 12MB
- Elsa 런타임 자산: 별도 `bundled-assets-v1` Release의 WebP 15동작 × 7프레임
- 추가 고양이: 고양이별 ZIP과 SHA-256이 기록된 카탈로그
- 설치 전 검증: 체크섬, 정확한 15개 파일, 각 `8778×1254`
- 저장 위치: `~/Library/Application Support/Meownitor/Cats/<ID>/`

추가 고양이는 단일 이미지를 이동·확대하는 방식이 아니라, 내장 `imagegen`으로 만든 네 개의 실제 핵심 자세와 세 개의 의미 기반 중간 자세를 사용합니다. 제작·시각 QA가 끝난 팩만 다운로드 카탈로그에 나타납니다.

## 현재 상태

- Elsa HD: 완료, 기본 포함
- K02 Cheese: 15/15 실사 동작과 QA 완료
- K01 Hodu: 10/15 실사 동작
- K03 Mochi: 15/15 실사 동작과 QA 완료
- 나머지 18종: 실사 애니메이션 교체 진행 중
- GitHub 공개 저장소: 소스만 게시 완료
- `bundled-assets-v1`: Elsa·아이콘·현지화 자산 게시 및 clean-clone 빌드 검증 완료
- `cat-packs-v1`: K02·K03 선택 다운로드 팩 게시 완료

## 개발

요구 환경은 macOS 13 이상과 Swift 5.10 이상입니다.

```bash
./Scripts/bootstrap-bundled-assets.sh
swift test
./Scripts/build-app.sh
codesign --verify --deep --strict .build/Meownitor.app
```

로컬 설치:

```bash
rm -rf /Applications/Meownitor.app
ditto .build/Meownitor.app /Applications/Meownitor.app
open /Applications/Meownitor.app
```

고양이 팩 생성:

```bash
./Scripts/build-cat-packs.sh K02
```

스크립트는 15개 raw·intermediate·chroma·reflection QA 증거와 최종 스트립 규격이 모두 있을 때만 ZIP과 카탈로그를 만듭니다.

`Resources/` 전체와 `dist/`는 Git에서 제외됩니다. Elsa·앱 아이콘·현지화는 `build-bundled-assets.sh`, 추가 고양이는 `build-cat-packs.sh`로 로컬에서 압축해 GitHub Release에만 올립니다.

## 문서

- [완성 계획](docs/PLAN.md)
- [아키텍처](docs/ARCHITECTURE.md)
- [동작 명세](docs/BEHAVIOR.md)
- [자산 계약](docs/ASSETS.md)
- [QA](docs/QA.md)
- [릴리스 절차](docs/RELEASING.md)
- [고양이 후보](docs/CAT-CANDIDATES.md)
