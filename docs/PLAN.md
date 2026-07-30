# Meownitor 완성 계획

## 완료 조건

1. Elsa와 K01~K10, U01~U10이 각각 15동작 × 7개의 해부학적으로 다른 실사 프레임을 가진다.
2. 모든 고양이가 정체성·해부학·alpha·chroma·연속성·동작 의미 QA를 통과한다.
3. 앱은 Elsa만 기본 포함하고, 나머지는 GitHub Release 팩으로 개별 설치·삭제한다.
4. 다운로드는 SHA-256, 파일 집합, `8778×1254` 규격을 통과한 뒤 원자적으로 설치한다.
5. 테스트·release build·실제 UI 검증 후 `/Applications/Meownitor.app`을 백업 없이 교체한다.
6. 공개 저장소에는 소스만 포함하고 `Resources/`·제작 원본·QA 작업물·고양이 팩을 Git 이력에 넣지 않는다.

## 단계

- [x] macOS 메뉴바 앱, 모니터/키보드 정책, 미루기, 권한 안내
- [x] 내장 화면 전용 overlay와 native 닫기 버튼
- [x] Elsa HD 15×7 실사 애니메이션
- [x] Elsa 런타임 PNG를 68MB에서 11MB WebP로 축소
- [x] `.git`의 내부 자산 checkpoint를 제거해 2.3GB에서 88KB로 정리
- [x] `Resources/` 전체 Git 제외와 bundled-assets bootstrap
- [x] GitHub Actions build/release 초안
- [x] 고양이 팩 ZIP·manifest·SHA-256 생성 스크립트
- [x] 설정의 다운로드·삭제·설치 상태 UI
- [x] Application Support 자산 로더와 무결성 검사
- [x] K01 15동작
- [x] K02 15동작
- [x] K03 15동작
- [x] K04 15동작
- [ ] K05~K10 15동작
- [ ] U01~U10 15동작
- [ ] 20개 팩 전체 contact sheet·GIF 최종 QA
- [ ] 공개 GitHub Release에 팩과 manifest 게시
- [x] 실제 Release 다운로드·삭제 왕복 검증
- [ ] Developer ID 서명·notarization 결정 및 적용
- [ ] 최종 앱 설치·실기 QA

미완성 고양이의 기존 affine 스트립은 제작 참고용일 뿐 배포 완료로 간주하지 않는다. `Scripts/build-cat-packs.sh`가 제작 증거 15세트를 확인하지 못하면 해당 팩을 거부한다.
