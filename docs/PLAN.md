# Meownitor 재개 계획

## 현재 기준

- 앱 기능, Elsa 번들, K01~K05 팩은 완료됐다.
- K05는 raw·intermediate·chroma·reflection·GIF·WebP 15세트와 시각 QA를 모두 통과했다.
- `cat-packs-v1`에는 K01~K05의 중복 없는 catalog와 검증된 ZIP이 게시됐다.
- K06~K10과 U01~U10의 기존 affine 스트립은 참고용이며 배포 대상으로 보지 않는다.

## K05 완료 조건

1. 네 동작마다 핵심 자세 4장과 의미 기반 중간 자세 3장이 있다.
2. K05 전체가 raw·intermediate·chroma·reflection·GIF·WebP 각 15세트를 가진다.
3. 모든 WebP가 `8778×1254`이며 정체성·해부학·alpha·연속성·동작 의미 QA를 통과한다.
4. `Meownitor-Cat-K05-v1.zip`은 `K05/strips/*.webp` 15개만 포함한다.
5. K01~K04를 변경하지 않고 K05 ZIP을 먼저 게시한 뒤 5개짜리 catalog를 마지막에 교체한다.
6. 실제 원격 다운로드·선택·재실행·삭제 왕복과 전체 앱 검증을 통과한다.

## 체크리스트

- [x] 현재 `main` 기준 테스트·release build·ad-hoc 서명·CI 확인
- [x] K05 `11-yawn` 7프레임 제작과 시각 QA
- [x] K05 `12-paw-wave` 7프레임 제작과 시각 QA
- [x] K05 `13-groom` 7프레임 제작과 시각 QA
- [x] K05 `14-stretch` 7프레임 제작과 시각 QA
- [x] K05 전체 15동작 재빌드와 팩 생성 게이트
- [x] `cat-packs-v1`에 K05 ZIP과 5개짜리 catalog 게시
- [x] 실제 원격 설치·미리보기·재실행·삭제 왕복
- [x] README와 최종 검증 기록 갱신

## 재개 규칙

세션 기록이 아니라 각 `Resources/Cats/<ID>/`의 디렉터리와 QA 파일 개수를 기준으로 진행률을 다시 계산한다. 생성 입력이나 게이트가 하나라도 부족하면 기존 placeholder 스트립을 사용하거나 Release catalog에 수동 등록하지 않는다.

다음 체크포인트는 K06~K10과 U01~U10의 제작 증거를 고양이별로 완성하는 것이다. 앱 태그·앱 ZIP·Developer ID/notarization은 별도 계획으로 다룬다.
