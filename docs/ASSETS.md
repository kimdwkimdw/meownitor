# 고양이 자산 계약

## 공통 규격

- 동작: `idle`, `blink`, `breathe`, 4방향 시선, `ear-twitch`, `tail-swish`, `head-tilt`, `meow`, `yawn`, `paw-wave`, `groom`, `stretch`
- 동작당 7프레임: 핵심 자세 4장 + 의미 기반 중간 자세 3장
- 셀: `1254×1254`
- 스트립: `8778×1254`, 7열 × 1행, 투명 배경
- 고양이당 105개 고유 프레임

전체 스프라이트의 이동·확대·회전만으로 만든 affine 모션은 최종 자산으로 허용하지 않습니다. 해당 동작의 눈꺼풀·눈·귀·머리·입·흉곽·앞발·꼬리 형태가 실제로 변해야 합니다.

## 기본 포함 고양이

제작 원본 PNG와 raw/intermediate/QA는 로컬에 보존합니다. `Resources/` 전체는 Git에서 제외합니다. 설치 앱용 Elsa와 K01–K03 WebP 각 15개, `.icns`·현지화·다운로드 카탈로그는 `v0.3.0-alpha.1` Release의 `Meownitor-Bundled-Assets-v1.zip`에 포함합니다. 예외적으로 웹에 필요한 축소 WebP 미리보기 43개만 `web/assets/`에 추적하며, 원본과 전체 동작은 넣지 않습니다.

- WebP quality 95, alpha quality 100
- 원본 68MB → 런타임 11MB
- 원본/압축본 1:1 확대 시각 비교 통과

## 추가 고양이

제작 자산은 `Resources/Cats/<ID>/` 아래에 둡니다.

```text
raw/<sequence>/                 4 key poses
intermediate/<sequence>/        3 semantic poses
strips/<sequence>.webp          runtime strip
qa/<sequence>.gif
qa/contact-sheet.png
qa/chroma-<sequence>.json
qa/reflection-<sequence>.json
```

`Scripts/build-cat-hd-assets.sh`가 스트립·GIF·contact sheet를 만듭니다. `Scripts/build-cat-packs.sh`는 15동작 전체 제작 증거와 규격을 확인한 뒤 `Meownitor-Cat-<ID>-v1.zip`과 `cat-packs.json`을 만듭니다.

ZIP은 `<ID>/strips/*.webp`만 포함하며 macOS resource fork와 제작 원본은 제외합니다. 앱은 manifest의 SHA-256과 예상 파일 15개를 검증합니다.

`Scripts/build-bundled-assets.sh`는 기본 4종 런타임·앱 아이콘·현지화만 별도 ZIP으로 만들고, `Scripts/bootstrap-bundled-assets.sh`는 ZIP과 sidecar SHA-256을 확인합니다.
