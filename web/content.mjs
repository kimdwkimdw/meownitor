export const releaseTag = 'v0.3.0-alpha.1';
export const repository = 'https://github.com/kimdwkimdw/meownitor';
export const downloadBase = `${repository}/releases/download/${releaseTag}`;

export const translations = {
  ko: {
    skip: '본문으로 건너뛰기', navigation: '주 메뉴', navHow: '어떻게 동작하나요', navCats: '고양이 만나기',
    eyebrow: '당신의 맥에 찾아온 작은 친구', heroLine1: '작은 고양이와', heroLine2: '조금 더 편안한 하루.',
    heroDescription: '일에 푹 빠진 당신을 살짝 챙겨주는 친구. 고개를 들고, 몸을 펴고, 잠깐 쉬어가도록 귀여운 고양이가 알려드려요.',
    downloadMac: 'Mac 알파 받기', meetCats: '내 고양이 만나기', requirements: 'macOS 13+ · Apple silicon 및 Intel · 실험용 알파',
    previewLabel: '곧 책상 위에서 만날 친구를 미리 보세요', speech: '우리, 잠깐 기지개 켤까?', heroCatDetail: '당신의 쉬는 시간 친구', pause: '애니메이션 멈추기',
    factMinutes: '분 후, 자세를 한 번 환기해요', factCats: '종의 개성 있는 고양이', factLocal: '계정도, 카메라도 없이. 고양이만.',
    howEyebrow: '좋은 친구와, 더 편안한 휴식.', howTitle: '필요한 순간에, 작은 알림.', howIntro: '메뉴바에서 조용히 지내다가, 작업 환경에 맞춰 쉬어갈 때를 알려줘요.',
    feature1Title: '노트북에 너무 푹 빠졌나요?', feature1Body: 'MacBook 내장 화면과 키보드로 25분 동안 작업하면, 고양이가 찾아와 자세를 환기해줘요.',
    feature2Title: '물러날 때도 알아요.', feature2Body: '외장 모니터를 연결하거나 외장 키보드를 사용하면 타이머가 초기화돼요. iMac에서는 30~60분마다 작은 휴식 알림을 보여줘요.',
    feature3Title: '당신의 리듬을 먼저.', feature3Body: '30분, 1시간, 2시간 미루기. Escape 두 번으로 닫기. 카메라와 계정은 필요 없고, 키 입력 내용도 저장하지 않아요.',
    catsEyebrow: '함께 일하면 더 좋은 친구들', catsTitle: '마음에 드는 고양이를 만나세요.', catsIntro: '엘사, 호두, 치즈, 모찌와 먼저 시작해요. 다른 고양이는 마음에 드는 친구만 하나씩 내려받을 수 있어요.',
    includedTitle: '처음부터 함께하는 네 친구', includedDetail: '앱에 기본 포함된 고양이 4종', optionalTitle: '한 친구 더 와도 괜찮아요.', optionalDetail: '추가 고양이 17종 · 개별 ZIP 다운로드',
    catalogHelp: '고양이를 누르면 위에서 애니메이션을 볼 수 있어요. Mac 앱의 설정 → 고양이에서 다운로드와 설치를 한 번에 할 수 있어요. ZIP은 별도 앱이 아닌 애니메이션 자산이에요.',
    downloadEyebrow: '책상 한편에, 작은 자리를 내어주세요.', downloadTitle: '쉬는 시간이 기다려질 거예요.', downloadIntro: '목펴라냥의 첫 공개 알파예요. Mac 네이티브 앱과 기본 고양이 네 친구, 그리고 더 만나볼 작은 세계를 담았어요.',
    downloadButton: 'Mac 알파 다운로드', downloadPlatform: 'Universal 앱 · macOS 13+ · 앱 언어: 한국어 / English',
    alphaTitle: '작은 시작을 먼저 나눠요.', alphaBody: 'Apple 공증을 받지 않은 ad-hoc 서명 실험용 빌드예요. macOS에서 실행이 차단될 수 있어요. 초기 버전 테스트에 익숙한 분께 권해요.',
    releaseNotes: '릴리스 노트와 전체 다운로드', bundleDownload: '기본 자산 · 고양이 4종 + 앱 아이콘', checksums: '다운로드 체크섬',
    faqTitle: '몇 가지만 더 알려드릴게요.', faq1Title: '무엇을 모니터링하나요?',
    faq1Body: 'Mac의 작업 환경과 최근 활동 시간만 확인해요. 카메라를 사용하거나 실제 자세를 측정하지 않아요. 입력 모니터링 권한은 외장 키보드를 구분하기 위한 선택 사항이며, 키 입력 내용은 저장하거나 전송하지 않아요. 권한이 없어도 모니터 연결 감지는 동작해요. 자산 다운로드 시에는 GitHub에 연결해요.',
    faq2Title: '어떤 Mac과 언어를 지원하나요?', faq2Body: 'macOS 13 이상의 Apple silicon과 Intel용 Universal 앱이에요. MacBook에서는 자세 알림, iMac에서는 작은 휴식 알림을 보여줘요. 그 외 데스크톱 Mac에는 알림을 표시하지 않아요. 웹은 영어·한국어·일본어, 현재 Mac 앱은 한국어·영어를 지원해요.',
    faq3Title: '다른 고양이는 어떻게 추가하나요?', faq3Body: 'Mac 메뉴바 앱에서 설정을 열고, 고양이를 선택해 내려받으세요. 앱이 설치 전 체크섬을 검증해요. 추가 팩은 설정에서 삭제할 수 있어요. 웹의 ZIP은 수동 사용이나 개발을 위한 동일한 자산이에요.',
    faq4Title: '문제가 생기면 어디에 알려주나요?', faq4Body: '어떤 상황이었는지, macOS 버전과 Mac 종류를 함께 알려주세요. 스크린샷이 있으면 더 좋아요.', issuesLink: 'GitHub 이슈 남기기 ↗',
    footer: '조금 더 편안한 하루를 위해. 기지개 한 번씩.', sourceLink: 'GitHub에서 만나기 ↗',
  },
  ja: {
    skip: '本文へスキップ', navigation: 'メインナビゲーション', navHow: 'しくみ', navCats: '猫たちに会う',
    eyebrow: 'あなたのMACに、小さな相棒を', heroLine1: '小さな猫と、', heroLine2: 'ちょっとやさしい一日。',
    heroDescription: '仕事に夢中なあなたを、そっと気にかける相棒。顔を上げて、背筋を伸ばして、ひと休み。かわいい猫が、そのきっかけを届けます。',
    downloadMac: 'Macアルファ版を入手', meetCats: '相棒を見つける', requirements: 'macOS 13+ · Apple silicon / Intel · 実験的なアルファ版',
    previewLabel: 'デスクで待つ相棒を、ひと足先に', speech: 'ねえ、ちょっと伸びをしよう。', heroCatDetail: 'ひと休みのおとも', pause: 'アニメーションを停止',
    factMinutes: '分たったら、そっとお知らせ', factCats: '匹の個性豊かな猫たち', factLocal: 'アカウントもカメラも不要。猫だけ。',
    howEyebrow: 'いい相棒と、いいひと休み。', howTitle: 'ちょうどいいときに、小さな合図。', howIntro: 'メニューバーで静かに待機。作業環境に合わせて、ひと休みのきっかけを届けます。',
    feature1Title: 'ノートPCに夢中ですか？', feature1Body: 'MacBookの内蔵画面とキーボードで25分間作業すると、猫が現れて姿勢を意識するきっかけをくれます。',
    feature2Title: 'そっと見守ることも得意。', feature2Body: '外部ディスプレイの接続や外付けキーボードの使用で、タイマーをリセット。iMacでは30〜60分ごとに、小さな休憩のお知らせが届きます。',
    feature3Title: 'あなたのペースを大切に。', feature3Body: '30分、1時間、2時間のスヌーズ。Escapeを2回押して閉じることもできます。カメラもアカウントも不要で、キー入力の内容は保存しません。',
    catsEyebrow: '一緒に働きたい、小さな仲間たち', catsTitle: 'お気に入りの猫を見つけよう。', catsIntro: 'まずはエルサ、ホドゥ、チーズ、モチの4匹と。ほかの猫は、お気に入りだけを1匹ずつダウンロードできます。',
    includedTitle: '最初に迎えてくれる4匹', includedDetail: 'アプリに4匹を同梱', optionalTitle: 'もう1匹、迎えてみませんか。', optionalDetail: '追加の17匹 · 個別ZIPダウンロード',
    catalogHelp: '猫をクリックすると、上でアニメーションをプレビューできます。Macアプリの「設定 → 猫」でダウンロードとインストールをまとめて行えます。ZIPは個別のアプリではなく、アニメーション素材です。',
    downloadEyebrow: 'デスクの片隅に、小さな居場所を。', downloadTitle: 'ひと休みが、楽しみになる。', downloadIntro: 'Meownitor、初の公開アルファ版。Macネイティブアプリと4匹の相棒、そしてこれから出会える小さな世界をお届けします。',
    downloadButton: 'Macアルファ版をダウンロード', downloadPlatform: 'Universalアプリ · macOS 13+ · アプリ言語：英語 / 韓国語',
    alphaTitle: '小さなはじまりを、ひと足先に。', alphaBody: 'Appleの公証を受けていない、アドホック署名の実験的なビルドです。macOSに起動をブロックされる場合があります。初期バージョンのテストに慣れている方に向けた公開です。',
    releaseNotes: 'リリースノートと全ダウンロード', bundleDownload: '同梱素材 · 猫4匹＋アプリアイコン', checksums: 'ダウンロードのチェックサム',
    faqTitle: 'もう少し、知っておきたいこと。', faq1Title: '何をモニタリングしますか？',
    faq1Body: 'Macの作業環境と最近の操作タイミングだけを確認します。カメラを使ったり、実際の姿勢を測定したりはしません。入力監視の権限は外付けキーボードを区別するための任意設定で、キー入力の内容を保存・送信することはありません。権限がなくても画面接続の検出は動作します。素材のダウンロード時はGitHubに接続します。',
    faq2Title: '対応するMacと言語は？', faq2Body: 'macOS 13以降のApple siliconとIntelに対応するUniversalアプリです。MacBookには姿勢のお知らせ、iMacには小さな休憩のお知らせが表示されます。ほかのデスクトップMacには表示されません。このサイトは英語・韓国語・日本語、現在のMacアプリは英語・韓国語に対応しています。',
    faq3Title: 'ほかの猫を追加するには？', faq3Body: 'Macのメニューバーアプリから設定を開き、猫を選んでダウンロードします。インストール前にチェックサムを検証します。追加の猫は設定から削除できます。サイトのZIPは同じ素材で、手動での利用や開発向けです。',
    faq4Title: '不具合はどこに報告できますか？', faq4Body: '起きたこと、macOSのバージョン、お使いのMacを教えてください。スクリーンショットもあると助かります。', issuesLink: 'GitHubで報告する ↗',
    footer: 'ちょっとやさしい一日を。ひと伸びずつ。', sourceLink: 'GitHubで会いましょう ↗',
  },
};

export const ui = {
  en: { title: 'Meownitor — A small cat. A gentler workday.', included: 'Included with the app', download: 'Get ZIP', preview: 'Preview', play: 'Play animation', pause: 'Pause animation', description: 'A little cat that reminds you to sit up and take a break. Meet Meownitor for macOS and choose from 21 animated companions.' },
  ko: { title: '목펴라냥 — 작은 고양이와 조금 더 편안한 하루.', included: '앱에 기본 포함', download: 'ZIP 받기', preview: '미리보기', play: '애니메이션 재생', pause: '애니메이션 멈추기', description: '고개를 들고 잠깐 쉬어가도록 알려주는 작은 고양이. Mac용 목펴라냥과 21종의 움직이는 친구들을 만나보세요.' },
  ja: { title: 'Meownitor — 小さな猫と、ちょっとやさしい一日。', included: 'アプリに同梱', download: 'ZIPを入手', preview: 'プレビュー', play: 'アニメーションを再生', pause: 'アニメーションを停止', description: '顔を上げて、ひと休み。Mac用Meownitorと、21匹の動く相棒たちに会いましょう。' },
};

export function resolveLanguage(query, stored, preferred = []) {
  return [query, stored, ...preferred.map(value => value.toLowerCase().split('-')[0]), 'en']
    .find(value => Object.hasOwn(ui, value));
}
