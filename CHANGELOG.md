# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Web version of Ichigo (`web/`).** A standalone, build-free static site
  (HTML + CSS + vanilla ES modules) that ports the app to the browser, kept fully
  separate from the Swift sources so it never disturbs the iOS build. It includes
  a content browser for Kanji/Vocab/Grammar N5–N3 (list + detail + live search)
  and the Hiragana/Katakana chart, plus a **flashcard mode whose FSRS-6 scheduler
  is a faithful port of `FlashcardModel.swift`** (same 21 official weights, same
  Anki-style learning steps — new+Easy graduates to 4 days, new+Good enters the
  learning steps), with progress, daily new-card quota, and streak persisted in
  `localStorage`. Theme-aware (light/dark) and responsive. Datasets in
  `web/data/` are copies of `Sources/AppFeature/Resources/`; see `web/README.md`
  for how to serve it (any static host / `python3 -m http.server`). Verified
  end-to-end in headless Chromium with no console errors.
  - **Settings page (⚙️) + backup sync.** Username (used in the Home greeting),
    daily new-card target, theme (Sistem/Terang/Gelap), study stats and reset.
    Cross-device sync without a backend via **Ekspor/Impor** of a backup JSON that
    **merges** on import — per card the newer review wins, streak takes the max —
    mirroring the iOS `BackupMerge` rule so no progress is lost.
  - **Motion polish.** Page-enter fade on navigation, flashcard reveal/next-card
    animations, active-press feedback, all disabled under
    `prefers-reduced-motion`.
  - **Automatic Google Drive sync.** Optional cloud sync to the Drive
    `appDataFolder` via Google Identity Services (browser token flow) + Drive v3
    REST — no backend, no SDK (`web/js/drive.js`, `web/js/gsync.js`). `syncNow`
    pulls the remote snapshot, merges it into local storage (reusing
    `store.importState`, the same newest-review-wins rule), and pushes the merged
    result; auto-sync runs on app load and after each study session. Requires a
    user-supplied OAuth **Web** client ID (entered in Settings or via a git-ignored
    `web/config.js`; template in `web/config.example.js`) — no credentials in the
    repo. Syncs **web ↔ web** (its backup format differs from the iOS payload).
    Non-OAuth paths verified in headless Chromium with no console errors; the
    interactive OAuth flow is documented in `web/README.md` for manual testing.
- **Two-way flashcard sync (Anki-style) over Google Drive.** The previously
  parked backup module is now wired into the app as automatic, bidirectional
  sync. A new `BackupMerge` engine merges the cloud snapshot with the local one
  without losing progress: per-card the copy with the more recent `lastReview`
  wins (ties break toward more repetitions), review logs are unioned by UUID,
  streaks take the larger value, and preferences take the newer snapshot (falling
  back to the other side when a field is absent). `DriveBackupManager.syncNow()`
  performs pull → merge → local restore → push; `ContentView` triggers it on
  foreground (pull-merge) and background (push) when auto-sync is on and an
  account is linked, and reloads `FlashcardStore` via a
  `.ichigoDidApplyRemoteSync` notification so the merged schedule shows at once.
  Settings gains an **Akun & Sinkronisasi** section (Google sign-in, auto-sync
  toggle, "Sinkronkan sekarang" with last-sync time, sign-out) replacing the old
  "coming soon" placeholder. Still gated on a user-supplied `GoogleOAuth.plist`
  (no credentials in the repo); unconfigured, the UI shows setup guidance. Covered
  by `BackupMergeTests` (per-card newest-wins, log union, streak max, preference
  last-writer-wins, new-today union). See `docs/GoogleDriveBackup.md`.
- **Reference sources for the JLPT datasets** documented in
  `Sources/AppFeature/Resources/README.md`: Tanos.co.uk (vocabulary lists),
  JLPTsensei.com (grammar/vocab/kanji per level), Jisho.org (per-entry
  meaning/reading/level verification) and the official JLPT past papers — with a
  note that these are community references (no official list since 2010) to be
  used for verifying individual entries, not copied wholesale.
- **153 verified N3 kanji** (`KanjiN3.json`, `N3_215`–`N3_367`), added in themed
  clusters — economy/money (富, 貧, 貸, 貨, 貯, 販, 換, 略 …), nature/water (波, 岸,
  河, 岩, 砂, 灰, 煙, 湖, 沿, 傾, 沈, 浮, 潮), body/health (胸, 腹, 肩, 腰, 髪, 涙, 汗,
  呼, 眠, 疲, 痛, 症, 骨, 傷), emotion/mind (怒, 悲, 喜, 恐, 怖, 恥, 恋, 慣, 憶, 惑, 悩,
  忙, 忘, 慎) and society/government/finance (党, 律, 憲, 挙, 署, 域, 券, 州, 貿, 購,
  融, 株, 債, 僚) and action/hand-motion (押, 抜, 捨, 拾, 抱, 抵, 拒, 揺, 振, 握, 掘,
  撮, 描, 抑) and speech/thought (討, 詳, 譲, 訴, 誇, 詐, 誠, 誘, 誉, 訂, 謙, 詰, 該,
  諾) and industry/materials/food (織, 維, 綿, 網, 継, 縁, 緩, 咲, 枯, 耕, 菌, 粉, 粒,
  焼) and degree/measure/abstract (及, 否, 賛, 貴, 賢, 距, 隔, 端, 偏, 傍, 幅, 巨, 微,
  劣) and time/motion/misc (昇, 暮, 曇, 陰, 陽, 至, 到, 逃, 逆, 遭, 巡, 迫, 透, 貫, 即,
  駆, 跳, 踏) — all common kanji not already in any level. Each carries accurate
  on'yomi / kun'yomi / meaning and five real compound-word examples (word, reading,
  rōmaji, meaning) rendered into the dataset's fixed sentence templates (sentence +
  furigana + Indonesian). The level count in `KanjiModel.swift` moves 214 → 367 —
  level with the widely-cited JLPT Sensei N3 kanji count — enforced by
  `check_dataset_counts.py`.
- **Grammar N5–N3 completed to the common reference counts.** 22 verified N3
  patterns (`GrammarN3.json`, `N3_G161`–`N3_G182`) and one core N4 pattern
  (`GrammarN4.json`, `N4_G132`: 〜てもいい / 〜てはいけない) that were missing from
  the sets. The N3 additions — 〜として, 〜ば〜ほど, 〜さえ〜ば, 〜きり, 〜わりに(は),
  〜において/〜における, 〜向け/〜向き, 〜だけに, 〜ことだ, 〜っこない, 〜うちに,
  〜からには, 〜わけにはいかない, 〜ざるを得ない, 〜たとたん(に), 〜だけあって,
  〜かと思うと/〜かと思ったら, 〜最中に, 〜てはじめて, 〜からこそ, 〜にすぎない and
  〜ものか — each carry the full schema (structure, nuance, explanation, usage,
  common mistakes and four example sentences with rōmaji + Indonesian) and are
  deduplicated against both the N3 and N4 sets. The level counts in
  `GrammarModel.swift` move to 182 (N3) and 132 (N4), enforced by
  `check_dataset_counts.py`, bringing N5/N4/N3 to 84/132/182 — level with the
  widely-cited JLPT Sensei list counts.
- **690 verified N3 vocabulary entries** (`VocabN3.json`, `N3_V1111`–`N3_V1800`),
  hand-checked batches of common words not already in the set — society/work/health/
  abstract nouns, suru-, plain and compound verbs, na-adjectives, adverbs and
  onomatopoeia (e.g. 発揮する, 把握する, 稼ぐ, 諦める, 取り組む, 味わう, 引っ張る,
  話し合う, 手段, 特徴, 段階, 設備, 在庫, 需要, 業績, 明確, 慎重, 豊富, 滑らか, 最適,
  面倒, 突然, せっかく, 要するに, ぐっすり, ぴったり, わくわく, 述べる, 応じる, 異なる,
  申請, 頻度, 単調, 過度, 相次いで, 次々, とっくに, 筋肉, 血液, 神経, 姿勢, 感謝, 緊張,
  覚悟, 頑固, 真剣, 天候, 稲妻, 虹, 学問, 講義, 論文, 職業, 履歴書, 交渉, 名刺, 郊外,
  首都, 渋滞, 勤める, 任せる, 預ける, 献立, 冷凍, 外食, 家電, 暖房, 換気, 衣服, 制服,
  割引, 消費税, 通帳, 炊く, 労働, 雇用, 概念, 定義, グループ, システム, 従って,
  いわゆる). Each carries an accurate reading, Indonesian meaning and word type; the
  level count advertised in `VocabModel.swift` moves 1.110 → **1.800** — level with
  the widely-cited Tanos/JLPT-Sensei N3 vocabulary figure — and stays enforced by
  `check_dataset_counts.py`. Every candidate was deduplicated against N5/N4/N3
  before insertion — a large share of candidates were already present, confirming
  the set is already broad. Deliberately kept to genuinely-known words rather than
  bulk-generating the long tail, to avoid shipping unverified data.
- **118 core N5 vocabulary entries** (`VocabN5.json`, `N5_V801`–`N5_V918`) filling
  gaps in categories a beginner set must cover: the seven days of the week
  (月曜日〜日曜日), the twelve months (一月〜十二月), the native counting series
  (一つ〜九つ, 十/とお, 二十歳), colour adjectives (赤い, 青い, 白い, 黒い, 黄色い),
  the standalone 男/女 and extended family (お兄さん, お姉さん, 両親, おじさん,
  おばさん, おじいさん, おばあさん, 夫, 妻), relative-time words (今朝, 今晩, 毎朝,
  毎週, 先週/来週, 先月/来月, 去年/来年, 午前/午後, 一昨日, 明後日), question words
  (なぜ, どちら, どんな, どの, いくつ, どうやって), core adverbs (もう, まだ, また,
  すぐ, もっと, ちょっと, たいてい, 一緒に, 初めて, たぶん), common verbs (歌う,
  走る, 選ぶ, 急ぐ, 貸す/借りる/返す, 探す, 並ぶ …), i-/na-adjectives (嬉しい,
  悲しい, 怖い, 正しい, 若い; 簡単, 必要, 大切, 心配, 十分) and everyday concrete
  nouns (薬, 風邪, 傘, 鍵, 財布, 眼鏡, 空港, 神社, 橋, 星 …). Each carries a reading,
  an **original** Indonesian meaning (written from standard basic-Japanese
  knowledge, not copied from any third-party deck) and a word type, and was
  deduplicated by exact kanji+reading pair against the existing set — 108 of 226
  candidates were already present and skipped. The same pass also **removed 13
  exact-duplicate cards** (same word and reading that had slipped in twice, e.g.
  行く, 座る ×3, 練習する), so the file moves 800 → **905**; the count advertised in
  `VocabModel.swift` (and mirrored in Android `ContentLevel.kt` / web `levels.js`)
  moves 800 → 905, enforced by `check_dataset_counts.py`.
- **N1 vocabulary — finishing pass round 1 on Android (+157).** Working through the
  large JLPT Tango N1 checklist, 157 clean advanced words were added
  (`N1_V305`–`N1_V461`), 304 → **461**, with **original** meanings and verified
  readings (exact kanji+reading dedup). Coverage: relations/mind (身内, 名付ける,
  横取り, 家出, 健在, 他界, 身の上, 見栄っ張り, 一目惚れ, 片思い, 有頂天, 馴れ初め,
  対人関係, 告げ口, 素っ気ない), money/household (家計, 手取り, 共働き, やりくり, ゆとり,
  懐, 人並み, 甘口/辛口, 食わず嫌い, 嗜む), time (終日, 四六時中, 日夜, 夕闇, 日没,
  夜更け, 更ける, 隔月/隔週/隔日, 来たる), home/objects (図案, 軋む, 補強, 改装, 構える,
  細工, 豪邸, 山積み, 圧縮, 蕩ける, 憩う, 引き籠る, 日向, 見積もる, 嵩張る), study/work
  (周年, 共学, 多数決, 漫然, 堪能, 主旨, 結び付く, 難易度, 度忘れ, 偏差値, 無闇, 以ての外,
  身嗜み, 正規, 売買, 好調, 切り抜ける, 出社) and misc verbs/adverbs (目覚める, 捲る,
  萎びる, 膨れる, 潤む, 張り合う, 残らず, 取り分け, 代わる代わる). `ContentLevel.kt` N1
  304 → **461** (finishing pass continues). Round 2 (+147, `N1_V462`–`N1_V608`,
  → **608**) then covered work/business (立腹, 弱音, 教訓, 弁える, 気兼ね, 一目置く,
  拝借, 仰ぐ, 準じる, 前置き, 理屈, 遜る, 事業, 起業, 実業家, 承知, 提示, 家業,
  やり遂げる, 後押し, 引き継ぐ, 解雇), city/transport (街並み, 住人, 地下街, 埋め立てる,
  着工, 趣, 追放, 条例, 現行, 事例, 立候補, 視察, 設置, 路線, 沿線, 最寄り, 先頭,
  駆け込む, 乗り込む, 改定, 引き締める, 遠ざかる, 辿り着く, 時速, 立ち往生, 修復, 改良,
  乗り切る, 電力, 出生, 青春, 母校, 過疎, 井戸, 澄む) and body/health (体付き, 逞しい,
  腹筋, 体脂肪, 脇, 擽る, 脳, 長寿, 老化, 老いる, 五感, 過労, 弱る, 物忘れ, 昏睡, 正気,
  発作, 全身, 痣, 貧血, 噎せる, 浮腫む, 捻挫, 抓る, 肺炎, 喘息, 鬱病, 認知症, 慢性,
  応急, 矯正, 面会, 安静, 手遅れ, 全快, 処方箋, 薬剤師, 容姿, 透き通る, 瞬き).
  `ContentLevel.kt` N1 → **608**. Round 3 (+120, `N1_V609`–`N1_V728`, → **728**)
  covered sport/competition (油断, 作戦, 戦力, 負かす, 獲得, 意気込む, 負けず嫌い,
  健闘, 手加減, 補充, 反則, 抗議, お手上げ, 行進, 観戦, 声援, 育成, 実る, 転落, 栄光,
  伝説), fashion (着飾る, 引き立てる, 粋, 気品, 目敏い, 見せびらかす, 今時, 淡い, 解ける,
  束ねる, 見違える, 手芸, 編む, 織る, 縫う), hobbies/arts (盆栽, 和紙, 着付け, 手本,
  高尚, 音色, 極める, 一期一会, 武道, 囲碁, 将棋, 書籍, 特集, 読者, 老若男女, 待望,
  共感, 連載, 圧巻, 原稿, 著作権, 描写, 主題, 正体, 罠, 上演, 前売り, 視聴率, 知名度,
  絶大, 巨匠, 押しかける, 惜しむ, 出演, 物真似, 滑稽, 芸, 見所, 穴場, 特典) and misc
  (秘訣, 生まれ付き, 生まれ変わる, 引っ込む, 禿げる, 弛む, 瞑る, コンプレックス, エッセイ,
  シナリオ). Round 4 (+183, `N1_V729`–`N1_V911`, → **911**) covered weather/disaster
  (豪雨, 暴風雨, 雨雲, 震源地, 猛烈, 浸水, 雪崩, 被災, 異変, 襲う, 荒らす, 一帯, 配給,
  紫外線, 致命的, 増殖, 脱する, 頂上, 尖る, 連なる, 群れる, 星座, 満月, 謎, 希少, 巣,
  翼, 操縦, 搬送), crime/law/news (轢き逃げ, 通報, 出動, 誤魔化す, 身元, 見抜く, 究明,
  自首, 再現, 脅す, 不審, 手口, 偽造, 目論む, 同一, 真実, 報じる, 引き起こす, 突き止める,
  杜撰, 手掛かり, 取り調べ, 追い詰める, 刑務所, 治安, 速報, 声明, 結成, 可決, 当選, 遺憾,
  背く, 過ち, 公表, 上昇, 運用, 外貨, 乗っ取る) and personality/emotion (大らか, 気さく,
  気立て, 情け深い, 強情, お節介, 横柄, 無神経, 爽快, 喜ばしい, 時めく, 待ち遠しい, 乗り気,
  喜怒哀楽, やるせない, 心苦しい, 虚しい, 嫉む, 淑やか, 優雅, 健全, 恥じらう, 容易い,
  嫌らしい, 月並み, 不細工, 萎む, 無礼, 気取る). `ContentLevel.kt` N1 → **911** (nearly
  done).
- **N1 vocabulary second batch on Android (+137).** Using the JLPT Tango N1 word
  list as a **coverage checklist** only, 137 more advanced words were added to
  `android/app/src/main/assets/data/VocabN1.json` (`N1_V168`–`N1_V304`) with
  **original** Indonesian meanings and hand-verified readings — bringing the
  Android N1 vocab set from 167 to **304**. Coverage: people/relationships/mind
  (肉親, 亭主, 仕草, 指図, 反発, 再婚, 連中, 恐縮, 告白, 浮気, 発覚, 縁談, 敬遠, 陰口,
  軽蔑, 人目, 眼差し), nuanced verbs (惑わす, 育む, 寄り添う, 踏み込む, 絡む, 開き直る,
  割り切る, 立ち直る, 使いこなす, 使い分ける, 手掛ける, 出向く, 取り次ぐ, 突き詰める,
  満たす, 見落とす, 潜る, 叶う, 心掛ける, 寛ぐ, 安らぐ, 面する, 嵩む, 掬う, 啜る,
  据え付ける), home/property (外観, 設計, 所有, 表札, 扉, 物陰, 近隣, 物件, 荷造り,
  手順), money/consumer (老後, 滞納, 値打ち, 正味, 名義, 換算, 代用, 吟味), study
  (助言, 名称, 暗唱, 諺, 文房具, 口頭, 万全, 不正, 内心, 落胆, 取得, 不備, 首席,
  最先端, 手引き, 変遷), work/business (情熱, 気合, 考慮, 雑談, 特許, 適性, 議題,
  分担, 根回し, 代理, 弊社, 先方, 単身, 創立, 在籍, 手分け), na-adjectives (厳か,
  丹念, 簡潔, 有望, 手近, 精神的, 自主的, 良心的), i-adjectives (愛しい,
  決まり悪い, 焦げ臭い, 申し分ない) and adverbs (散々, 時折, 渋々, 極力, 自ら, 俄然,
  所々, 程々, 強ち, 取り急ぎ, 先頃, 心底). Deduplicated by exact kanji+reading and by
  reading against every shipped level. `ContentLevel.kt` moves the N1 count 167 →
  **304**.
- **N2 vocabulary — finishing pass rounds 1-2 on Android (+276).** Working through
  the JLPT Tango N2 checklist, 276 more clean words were added (`N2_V1589`–`N2_V1864`),
  1.588 → **1.864**, with **original** meanings and verified readings (exact
  kanji+reading dedup). Coverage: household/relations (一家, 躾, 意思, 幹事, 花嫁,
  避ける, 貶す, 口論, 台無し, 持て成す), home/kitchen (一戸建て, 点検, 容器, 食卓,
  風呂場, 清掃, 分類, 収集, 炊事, 濯ぐ, 煮える, 冷ます, 舐める), money/time (大金,
  納める, 引き落とし, 好物, 年月, 日時, 予め, 起床, 年度, 夜明け), civic/city (街,
  人通り, 境, 落書き, 身分証明書, 帰省, 近郊, 公共, 普及, 急増), study/IT (願書,
  修了, 学力, 記号, 混同, 採点, 受講, 講師, 学会, 起動, 本体, 転送, 余白, 手書き),
  work/business (求人, 内定, 入社, 大企業, 大手, 派遣社員, 有給休暇, 人事, 資本,
  売り上げ, 打ち合わせ, 依頼, 転職, 立ち上げる, 専念, 敬意, 反論, 頷く), sport (競技,
  戦う, 敗れる, 攻める, 逆転, 延長, 指導, 技, 足元), arts/media (劇場, 役者, 主役,
  台詞, 芸術家, 粗筋, 人物, 場面, 著者, 伝記, 発想, 空想, 連想, 生み出す), hobbies
  (習い事, 拘る, 名人, 編み物, 手品, 占い, 手話, 撮影, 宝くじ) and weather/season
  (四季, 初夏, 温帯, 確率, 夕立, 生憎, 吹雪, 冷え込む, 日差し, 降水量, 観測, 大気).
  Rounds 3-5 (+258, `N2_V1865`–`N2_V2122`) finished the set with nature/leisure
  (去る, 大地, 滝, 岸, 海辺, 透明, 生き物, 天然, 夕焼け, 休息, 芝生, 漕ぐ, 訪れる,
  体験, 豪華, 手配, 免税店, 海水浴, 出来事), body/health (心身, 手首, 爪先, 血管,
  傷跡, 休養, 体調, 通院, 補給, 医師, 便秘, 寒気, 湿疹, 伝染, 熱中症, 躓く, 手当て,
  遺伝, リハビリ, 肌, 脂肪, 肥満, 減量), society/crime/news (対立, 拒否, 関わる,
  侵入, 捜査, 少年, 目撃, 行方, 過失, 爆発, 火災, 救助, 政党, 思想, 改正, 成立, 非難,
  復興, 世間, 報道, 中継, 国旗, 支援, 開発, 調査), personality/emotion (人柄,
  社交的, 素朴, 無口, 人見知り, 厚かましい, 大雑把, 短気, 前向き, 憂鬱,
  惨め, 弱気, 傷付く, 躊躇う, 恐れる, 恥, 謙遜, 憎らしい, 鬱陶しい, 中途半端) and the
  last loanwords/expressions (オフィス, ビジネス, プロジェクト, サポート, ベテラン,
  リストラ, キーボード, プリンター, 所謂, 仕方ない, バイキング, キャンパス, デモ,
  省エネ). `ContentLevel.kt` N2 1.588 → **2.122**. **N2 vocab is complete** — the
  Tango N2 list's genuine content words are exhausted (remainder is particles,
  ～な grammar forms of listed adjectives, onomatopoeia and archaic ateji).
- **N2 vocabulary expanded on Android (+141).** Using the JLPT Tango N2 word list
  as a **coverage checklist** only, 141 common N2 words missing from the set were
  added to `android/app/src/main/assets/data/VocabN2.json` (`N2_V1448`–`N2_V1588`)
  with **original** Indonesian meanings and hand-verified readings. Coverage:
  relationships/society (役目, 尊重, 説得, 介護, 妊娠, 出産, 友人, 思いやり, 初対面,
  自己紹介, お辞儀, 大家, 再会, 口実, 他人, 双子), interaction & action verbs (向き合う,
  甘える, 打ち明ける, 呆れる, 招く, 探る, 示す, 睨む, 殴る, 誓う, 囁く, 俯く, 振り返る,
  立て替える, 取り寄せる, 叶える, 挟む, 添える, 漏れる, 取り除く, 担ぐ, 掴む, 描く,
  用いる, 訳す, 貼り付ける, 限る, 言い換える), housing/place (賃貸, 敷金, 家屋, 洗面所,
  間取り, 住宅, 付近, 下町, 活気, 坂), money/service (手数料, 援助, 安定, 品質, 返品,
  返金, 購入, 値引き, 配達, 提供, 用途), civic (自治体, 知事, 年金, 署名), transport
  (故郷, 方面, 横断, 通行, 歩行者), study/writing (開始, 担任, 充実, 学習, 参考書,
  徹夜, 上達, 基本, 実現, 複数, 活用, 段落, 箇所, 引用, 編集, 文書, 改行, 拡大),
  na-adjectives (粗末, 余分, 自動的, 疎か, 必死),
  i-adjectives (有り難い, 久しい, 生臭い, 諄い, 気まずい) and adverbs (つくづく, 言わば,
  もしかすると, 一旦, 絶えず, ほぼ, さっさと, てきぱき, 先ほど, 近々, あらゆる, 一切).
  Deduplicated by exact kanji+reading and by reading against every shipped level.
  `ContentLevel.kt` moves the Android N2 count 1.447 → **1.588**. Android-first —
  iOS/web stay at 1.447 until the later sync pass.
- **N3 vocabulary — finishing pass, round 2 on Android (+128).** Continuing to work
  through the JLPT Tango N3 checklist, 128 more clean words were added
  (`N3_V1925`–`N3_V2052`), 1.922 → **2.050**, with **original** meanings and verified
  readings (exact kanji+reading dedup, so homophones like 揚げる vs 上げる are kept).
  Coverage: family (三女, 三男, 一人っ子, 夫妻, 幼児, 乳児, 出身地, 既婚, 専業主婦, 無職,
  彼氏), time (翌月, 翌週, 昨年, 再来週/再来月/再来年, 先々週/先々月, 初旬, 数回/数年/数か月,
  以来), kitchen/food (おやつ, グルメ, フライパン, お玉, しゃもじ, 大匙/小匙, 流し台,
  電子レンジ, 酢, 胡椒, 揚げる, 熱する, 注ぐ), cleaning (箒, 塵取り, バケツ, 洗剤, 黴,
  乾燥機, アイロン, 糸, 針, 空き缶, 空き瓶, 零す/零れる, 臭う), home/furniture (リビング,
  ヒーター, クーラー, カーペット, ソファー, クッション, コンセント, スイッチ, ドライヤー),
  money/bank (札, コイン, 硬貨, 交際費, 公共料金, 銀行口座, 暗証番号, 税込/税別, 貯める/
  貯まる, 引き出す, 割り引く, 無駄遣い), services (出迎え, 見送り, 差出人, 留守番電話,
  再利用) and city/place (高層ビル, 自動ドア, 入館料, 休館日, 歩道橋, 居酒屋, 八百屋,
  正面, 中心, 中央, 移転, 空き地, 人込み, 徒歩, 遠回り). `ContentLevel.kt` N3
  1.922 → 2.050. Round 3 (+154, `N3_V2053`–`N3_V2206`) then covered study/school
  (英会話, 教科, 理科, 国語, 足し算/引き算/掛け算/割り算, 三角形, 定規, 物差し, 文系/理系,
  言語学, 法学, 物理学, 心理学, 専攻, 公立/市立/県立/国立/私立, 教授, 進路, 休学/退学,
  受験生, 正解, 実力, 可能性), work (登録, 記入, 正社員, 研修, 実習, 早退, 社会人, 判子,
  後輩, 同期, 飲み会, 歓迎会, 送別会, 出版社, 長期/短期, 日程, 延期, 省略, 成長, 儲かる/
  儲ける, 受け付ける), tech/email (件名, 受信/送信/返信, やり取り, 変換, 挿入, ブログ, マウス,
  ダウンロード, インストール, アップロード, ノートパソコン, エンジニア, デザイナー), professions
  (作家, 画家, 政治家, 学者, 美容師, 歌手, タレント), travel (日帰り, 滞在, ツアー, 観光客,
  集合, 解散, 満室, 近付く, 持ち物, スーツケース, 来日, 活躍), sport (前半/後半, 引き分け,
  運動会, 思い切る, 拍手, 握手, 惜しい, 体操, 日課, 得る) and connectives (そのため, なぜなら,
  つまり, だけど, 是非とも, 全て). Rounds 4-5 (+277, `N3_V2207`–`N3_V2483`) then added transport/driving
  (往復切符, 終電, 終点, 改札, 指定席, 自由席, 車掌, 線路, 踏切, 乗り遅れる, 高速道路,
  運転免許証, 一方通行, 轢く, タイヤ, 助手席, シートベルト, 交通費, 払い戻す), school
  (入学式, 卒業式, 通学, 学年, 学期, 居眠り, 給食, 体育館, 単語, 記憶力, 聞き取る,
  聞き返す, 言い直す), body/health (汗, 息, 溜息, 虫歯, 裸, 白髪, 抜く, 花粉症, 鼻水,
  掻く, 頭痛, 腹痛, 吐き気, 骨折, 検査, 内科/外科/小児科, 注射, 回復, 悪化, 包帯, 巻く,
  長生き), fashion/appearance (水着, 上着, 化粧, 化粧品, 口紅, 睫毛, 眉毛, 香水, 半袖,
  袖, 柄, 花柄, 水玉, 縞模様, 縦書き/横書き, 無地, 真っ赤/真っ黒/真っ青/真っ白, 美人,
  大型/小型), nature/weather (草, 種, 浮かぶ, 掘る, 埋める, 丘, 吠える, 尻尾, 予想,
  曇る, 強風, 大雨/小雨, 濡らす, 積もる, 輝く, 氷, 猛暑日, 暖冬/冷夏), holidays (祭日,
  元日, 元旦, お年玉, 成人式, 雛祭り, 雛人形, 子供の日, 母の日, 父の日, 海の日,
  敬老の日, 七五三) and emotion/personality (個性的, 働き者, 大人しい, 感動, 感心,
  愛する, 微笑む, 悲しむ, 望む, 魅力的, 平気, 焦り, 自慢, 不機嫌). Rounds 6-7 (+170, `N3_V2484`–`N3_V2653`) finished
  the set with society/media (噂, 記事, 週刊誌, 市民, 国民, 立場, 世の中, 司会, 生放送/
  再放送, 発売, 注目, 現場, 停電, 断水, 増加, 信用, 失う, 円高/円安, 不景気), the
  productive negative prefixes 不/無/非/未 (不可能, 不自然, 不完全, 無意味, 無免許,
  無計画, 非常識, 非公式, 未成年, 未経験, 未解決), superlatives (最大/最小/最高/最低/
  最悪/最多/最良), geography (北極, 南極, 赤道, 中東, 北欧/東欧/西欧/南欧, 欧米,
  中南米, オセアニア), events/misc (天才, 稽古, 読書, 講演会, 好奇心, 変化, 一定, 区別,
  求める, 広げる, 活動, 当然, 当たり前, 金持ち, 貧乏, 進歩, 盛ん, 商売, 立派, 現代的,
  偉大) and the last loanwords/adverbs (デザート, カタログ, ライブ, ゴール,
  ジェスチャー, 生き生き, すっきり, ドキドキ). `ContentLevel.kt` N3 1.922 → **2.651**.
  **N3 vocab is complete** — the Tango N3 list's genuine content words are exhausted
  (the remainder is compound phrases, ～な grammar forms of already-listed adjectives,
  particles and archaic ateji, none of which belong as standalone vocabulary).
- **N3 vocabulary expanded on Android (+124, −2 duplicates).** Using the JLPT
  Tango N3 word list as a **coverage checklist** only, 124 common N3 words missing
  from the set were added to `android/app/src/main/assets/data/VocabN3.json`
  (`N3_V1801`–`N3_V1924`) with **original** Indonesian meanings and hand-verified
  readings. Coverage: family/people (父親, 母親, 長男/長女, 次男/次女, 姉妹, 甥, 姪,
  親類, 先祖, 女性/男性, 主婦, 名字, 我々), relationships (遠慮, 出会う, 交際, 恋愛,
  味方, 悪口, 内緒, 真似), give/receive & action verbs (頂く, 下さる, 差し上げる,
  預ける, 握る, 塗る, 剥く, 割る, 沸く, 焦げる, 揃える/揃う, 撫でる, 捻る, 解く,
  結ぶ, 支払う, 振り込む), time (本日, 前日, 翌日, 先日, 上旬/中旬/下旬, 真夜中, 日常),
  food & kitchen (朝食/昼食/夕食, 包丁, まな板, 炊飯器, 食器, 味見, 冷凍, 塩辛い,
  温い), home & cleaning (住まい, 物置, 座布団, 絨毯, 雑巾, 内部, 清潔/不潔, 臭い,
  子育て), money & shopping (紙幣, 生活費, 光熱費, 贅沢, 割り勘, 預金, 送金,
  合計, 請求書, 売り切れ, 品切れ, 半額, 割引券, 損/得, 定休日, 商店街) plus
  common adverbs (少々, 暫く, しょっちゅう, 取り敢えず, わざと). Deduplicated by exact
  kanji+reading and by reading against every shipped level; the same pass removed
  two **pre-existing** exact duplicates (保存する at `N3_V428`, 見送る at `N3_V960`).
  `ContentLevel.kt` moves the Android N3 count 1.800 → **1.922**. Android-first —
  iOS/web stay at 1.800 until the later sync pass.
- **N4 vocabulary finished on Android (+202).** Two more clean rounds exhaust the
  JLPT Tango N4 checklist (`N4_V827`–`N4_V1028`), bringing N4 from 825 to **1.027**
  with **original** meanings and verified readings. Adds everyday verbs (似る, 飼う,
  建つ, 貼る, 上げる, 暮らす, 計る, 寄る, 晴れる, 向かう, ぶつかる, 贈る, 破る, 汚す,
  踏む, 逃げる, 楽しむ, 伸ばす, 行う, 増やす, 減らす, 見える, 聞こえる, 外れる, 遅れる,
  治す, 見付かる), nouns across home/city/study/travel/body (管理人, 缶, 餌, 城, 教会,
  非常口, 髪型, 美容院, 形, 専門学校, 学部, 医学, 実験, 挨拶, 許可, 入力, 出発, 用意,
  注意, 途中, 発見, 発表, 放送, 連絡, 大会, 選手, 応援, 会場, 水泳, 入院, 退院, 見舞い,
  石油, 世界遺産, 世紀, 国際, 先輩, 婚約, 喧嘩, 髭, 腕, 背中, 胃, 腰, 尻, 爪, 骨,
  火傷, 倍, 以上/以下/以内, 両方), i-/na-adjectives (濃い, 可笑しい, 嫌, 楽), pronouns
  (彼ら, 君), a large set of common loanwords (マンション, カレンダー, ポスター, メニュー,
  ソース, レジ, サイン, レシート, オートバイ, ガソリン, エンジン, サンダル, リュック,
  ドラマ, キャンプ, ビタミン, インフルエンザ, チーム, ダイエット, 体温計 …) and core
  adverbs/conjunctions (必ず, 絶対, 随分, 決して, 殆ど, 到頭, やっと, 例えば, どんどん,
  なるほど, もし, 一生懸命, しっかり, 確か, びっくり, それで, その上, けれども, ところで).
  A homophone-recovery pass restored 23 distinct words the reading-dedup had wrongly
  dropped (e.g. 城/しろ vs 白, 飼う/かう vs 買う, 建つ/たつ vs 立つ), using exact
  kanji+reading dedup. `ContentLevel.kt` moves the Android N4 count 825 → **1.027**;
  **N4 vocab is complete** (the remaining checklist is place names, particles,
  な-adjective grammar forms and ateji — not vocabulary).
- **N4 vocabulary expanded on Android (+126, −1 duplicate).** Using the JLPT
  Tango N4 word list as a **coverage checklist** only, 126 common N4 words missing
  from the set were added to `android/app/src/main/assets/data/VocabN4.json`
  (`N4_V701`–`N4_V826`) with **original** Indonesian meanings and hand-verified
  readings (the deck's meanings/examples were not used — its readings are riddled
  with collocation bleed such as `卒業→をそつぎょうする`). Coverage: family (息子,
  娘, 祖父, 祖母, 孫, 叔父, 叔母), home & furniture (自宅, 廊下, 和室, 畳, 布団, 家具,
  押し入れ, 留守, カーテン), everyday verbs (移す/移る, 動かす, 起こす, 慣れる, 過ごす,
  尋ねる, 混む, 進む, 折れる/折る, 残す/残る), school (出席, 欠席, 予習, 復習, 塾,
  発音, 生徒, 大学生, 作文, 辞典), travel (海外, 景色, 連休, 旅館, 温泉, 両替), weather/nature
  (天気予報, 曇り, 津波, 空気, 枝), food & shopping (和食, 洋食, 材料, 鍋, 缶詰, 計算,
  お釣り, 食料品) plus 熱心 / 偉い. Deduplicated by exact kanji+reading and by reading
  against every shipped level; the same pass removed one **pre-existing** exact
  duplicate (積極的 at `N4_V355`). `ContentLevel.kt` moves the Android N4 count
  700 → **825** (`700+` → exact). Android-first — iOS/web stay at 700 until the
  later sync pass.
- **N5 vocabulary round 2 on Android (+78) — finishing the N5 set.** Continuing to
  exhaust the JLPT Tango N5 checklist (words only; deck meanings/readings not used),
  78 more clean N5 words were added (`N5_V1001`–`N5_V1078`) with **original**
  Indonesian meanings and verified readings, after filtering out the checklist's
  non-vocabulary noise (particles, set-phrase greetings, place names, archaic ateji,
  predictable counters). Coverage: professions (看護師, 駅員, 運転手, 歯医者, 研究者),
  places/buildings (本屋, 大使館, 大学院, 建物, 庭, お手洗い, 乗り場, 所, 県), study/media
  (勉強, 練習, 見学, 研究, 確認, 平仮名, 片仮名, 電子辞書, 番組, 漫画, 絵, 歌), food
  (お菓子, 煙草, ナイフ), sport/hobby (試合, 相撲, 柔道, 釣り, 生け花), nature (桜, 紅葉,
  象), post/transport (切手, 年賀状, 航空便, 船便, 特急, 各駅, 運転), body (喉, 指, 肩,
  首, 歯, 痛み), verbs (居る, 要る, 勝つ, 負ける, 思う, 掛かる, 回す, 吸う, 出掛ける,
  下ろす, 置く), adjectives (駄目, 欲しい) and question words (何歳, 何月, 何曜日).
  A final round-3 then mopped up the remaining legitimate loanwords/misc (ピアノ,
  ギター, アニメ, ゲーム, ジャズ, スピーチ, ロビー, コンピューター, サイズ, デザイン,
  ジーンズ, パンツ, ダンス, プール, スキー, ゴルフ, テニス, ホームステイ, 自動販売機,
  一杯, 連れて行く, 持って行く). Deduplicated by exact kanji+reading and by reading
  against every shipped level. `ContentLevel.kt` moves the Android N5 count 987 →
  **1.087** — the Tango N5 list's genuine content words are now exhausted (only
  place names, particles, set-phrase greetings and archaic ateji remain, which do
  not belong in a vocabulary deck). **N5 vocab is complete.**
- **N5 vocabulary top-up on Android (+82, using the reference word lists).** Using
  the level-tagged JLPT Tango N5 word list purely as a **coverage checklist** (which
  words exist at N5 — a fact), 82 essential N5 words missing from the set were added
  to `android/app/src/main/assets/data/VocabN5.json` (`N5_V919`–`N5_V1000`) with
  **original** Indonesian meanings and hand-verified readings (the deck's own
  meanings/example sentences were *not* used — its readings even carry systematic
  errors like `お茶→おおちゃ`). The batch fills real beginner gaps: the people
  counters 一人〜十人 (irregular readings ひとり/ふたり/…), the day-of-month counters
  一日〜十日 + 二十日 (ついたち/ふつか/…/はつか), the "how many" question words
  (何人/何日/何個/何台/何枚/何回/何番/何時間), everyday nouns (兄弟, 世界, 小学校,
  中学校, 高校, 事務所, 工場, 電池, 手帳, 風呂, 食べ物, 飲み物, 紅茶, 弁当, 寿司,
  醤油, 味噌…), wear/attach verbs (履く, 被る, 脱ぐ, 浴びる, 迎える) and common
  loanwords (ノート, ボールペン, クラス, ホテル, スーツ, サングラス, ビール, ラーメン…).
  Deduplicated by exact kanji+reading and by reading against every shipped level.
  `ContentLevel.kt` moves the Android N5 count 905 → **987**; this is **Android-first**
  — iOS `VocabN5.json`/`VocabModel.swift` and the web copy stay at 905 until a later
  sync pass, so the Swift `check_dataset_counts.py` (which reads only the Swift side)
  is unaffected.
- **N1 vocabulary unlocked on Android (first verified batch).** The N1 tier —
  previously a locked "10.000+ Kosakata Master" placeholder — now ships **167
  genuinely-advanced vocabulary entries** (`android/app/src/main/assets/data/VocabN1.json`,
  `N1_V001`–`N1_V167`) so N1 vocab is browsable, searchable and available as
  flashcards. The batch spans formal/abstract nouns not already taught lower
  (理念, 体系, 範疇, 官僚, 主権, 責務, 心境, 手腕, 兆候, 流儀, 貫禄, 醍醐味…),
  four-character idioms / yojijukugo (一石二鳥, 以心伝心, 優柔不断, 半信半疑,
  千差万別, 弱肉強食, 温故知新, 言語道断, 一挙両得, 正々堂々…), literary/formal verbs
  and suru-verbs (承る, 繕う, 擁する, 是正する, 掌握する, 躊躇する, 邁進する, 撤回する,
  翻弄する, 罷免する…), na-/i-adjectives (精巧, 綿密, 周到, 悲惨, 煩雑, 華麗, 目覚ましい,
  脆い, 名高い…) and advanced adverbs (軒並み, 依然, 敢えて, 一概に, てっきり, おおむね,
  何気なく…). Each carries a
  reading and an **original** Indonesian meaning written from standard advanced-
  Japanese knowledge (not copied from any third-party deck), and every candidate
  was deduplicated by exact kanji+reading pair against the shipped N2–N5 sets so
  N1 only holds words not already taught at a lower tier — of ~450 candidates,
  ~280 were already present at N2/N3 and were dropped. `ContentLevel.kt` unlocks
  the N1 vocab level and advertises the real count ("167 Kosakata Master");
  **N1 Kanji and Grammar stay locked** (no dataset yet), and the guard test
  `ContentLevelTest` was updated to expect exactly this. This is **Android-first**:
  the iOS `VocabModel.swift`/`Resources` and the web copy are intentionally left
  for a later pass, so the Swift `check_dataset_counts.py` still sees N1 as a
  not-yet-shipped level and its approximate "10.000+" figure remains valid.
- **Editable username in Settings.** A new **PROFIL** section carries a **Nama
  Pengguna** field bound to `AccountStore.displayName`; it persists automatically
  and syncs live to the Home greeting and the Profile header (both observe the
  shared `AccountStore`). Default is `user123`.
- **Time-of-day greeting on Home.** The static "Halo" line now reads *Selamat
  pagi / siang / sore / malam* by the device hour (`TimeGreeting`, unit-tested).
- **First-install date is recorded** (`AppInstallInfo`) as the origin for the
  per-day counts, stamped once during the splash preload.
- **Ichigo v2 visual design** across the app: a central `AppTheme` carrying the
  design's exact tokens (warm beige `#E7E0DC` page, white cards, plum `#2B2029`
  ink, muted `#B0A199`, blue `#2E7BFF` accent with its gradient pairs) and a
  rounded type ramp.
  - **Home**: "Okaeri 🍓" greeting, tappable gradient avatar, blue hero card
    (daily progress + Due / Streak / Mastered) and a tile grid with per-tile
    gradients.
  - **Profile**: rounded gradient header with ringed avatar and "JLPT Learner"
    badge, daily-target card, 2×2 stat grid and the answer-summary pills.
  - **Settings**: sectioned white cards with gradient icon chips and inset
    dividers; native controls retained.
  - **Browsing screens** (Vocabulary / Kanji / Grammar): pinned `ScreenHeader`,
    pill `SearchField` and `FilterChipRow` that stay fixed while content scrolls.
  - **Level lists** (Vocabulary / Kanji / Grammar) now use one card layout —
    52pt level chip, bold name with chevron, and a single grey subtitle
    carrying the count ("120 Essential Kanji", "800 Kosakata Dasar", "84 Pola
    Tata Bahasa Dasar") — plus the same locked-card treatment. The unlocked and
    locked cards are byte-identical across the three screens apart from their
    level type.
  - **App-wide type ramp**: every screen now draws its fonts from
    `AppTheme.rounded(...)` and its text colours, surfaces and shadows from the
    theme tokens, so the flashcard, kana, kanji, vocabulary and grammar screens
    match Home/Profile/Settings.
- **Light / dark mode setting.** Settings → PREFERENSI carries a **Mode
  Tampilan** row with a slide toggle — drag or tap left for light, right for
  dark (`ThemeSlideToggle`). The choice is applied once at the root via
  `preferredColorScheme`, so every screen and sheet follows it, and it is
  persisted and included in the backup payload alongside the other preferences.
  Before the first drag the app follows the device (`system`); older backups
  without the field restore the same way. Every screen already draws its
  colours from the colour-scheme-aware `AppTheme` tokens, so nothing is left
  stranded in light styling when dark is selected.
- **Google Drive backup & restore implementation** (`Sources/AppFeature/Backup/`):
  dependency-free OAuth 2.0 + PKCE via `ASWebAuthenticationSession`, tokens in the
  Keychain, and `URLSession` REST scoped to the Drive `appDataFolder`, plus the
  local progress snapshot (`BackupService`/`BackupPayload`). **Parked for a later
  release** — Settings advertises Akun, Cadangkan & Pulihkan and Sinkronisasi
  otomatis under "SEGERA HADIR" rather than exposing the controls. Setup notes for
  when it ships: `docs/GoogleDriveBackup.md`.

- **Swift package manifest** (`Package.swift`) defining the single-target iOS
  application — the project now has a canonical, buildable structure.
- **Unit test suite** (`Tests/AppFeatureTests`) covering the FSRS-6 math, the
  review-engine state machine, the session queue builder, day-boundary/streak
  accounting, the retention validator, analytics, deck-card mapping, the backup
  round-trip, PKCE and the account store.
- **Datasets folder** (`Sources/AppFeature/Resources/`) documented as the drop-in
  location for the maintainer's JSON datasets (kana, kanji, vocabulary, grammar),
  with the expected schemas in its `README.md`. The datasets themselves are
  supplied separately by the maintainer.
- **Unified logging** via `os.Logger` (`Log` with `resources`, `flashcards` and
  `notifications` categories).
- **Shared `ResourceLoader`** that centralises JSON array decoding and error
  handling for all loaders.
- **Documentation:** `README.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`, this
  changelog, and a `.swiftlint.yml` configuration.

### Changed
- **Flashcard new-card quota follows the daily target.** The session builder's
  per-deck new-card limit is now the **Target Harian** value from Settings instead
  of a fixed 35, so setting e.g. 45/day gives 45 new cards per deck each day; due
  repetitions still stack on top as they come due. The `FlashcardSettings` default
  is unchanged so the pure builder tests keep asserting against a known value.
- **Home "Due" / Profile "hari ini" now show the day's real workload.** They read
  `FlashcardStore.dailyDueTotal(target:)` — remaining new cards for today plus the
  reviews that have come due — instead of counting every un-mastered card. The
  figure resets each day from the install date.
- **Light and dark palette tuned for comfort.** Light mode moves to a slightly
  brighter warm cream (`#F1EAE3`, with matching track/hairline) and dark mode moves
  off pure black to a soft navy (`#12161F` page, `#1C2231` cards). All values live
  in the single `AppTheme` colour panel, so every screen follows in both modes.
- **Project restructured** from a flat pile of files at the repository root into
  a single `Sources/AppFeature/` app target (all logic, UI, `@main` entry and the
  `Resources/` datasets). A single target is required by Swift Playgrounds, which
  cannot link `@main` when the app is split into a separate library and executable.
- **CI** now builds the app with `xcodebuild` against an iOS Simulator
  destination (`-sdk iphonesimulator`) instead of the previous `swift build`,
  which could not compile a UIKit/SwiftUI iOS app.
- **Consistent branding:** the app entry point was renamed `MyApp` → `IchigoApp`
  and stray "NihongoMaster" / "Nihongo Master" strings are now "Ichigo".
- **Consistent filenames:** `ProfilView.swift` → `ProfileView.swift`,
  `SetingsView.swift` → `SettingsView.swift`.
- **Single source of truth for flashcards:** the flashcard flow now receives the
  shared `FlashcardStore` from the app root via dependency injection instead of
  creating a second, divergent store instance.
- **`GrammarListView`** loads its data with structured concurrency
  (`Task.detached`) to match the other list screens, replacing nested
  `DispatchQueue` calls.
- **Kana quiz** now builds answer choices from distinct distractors only.
- Loaders (`KanjiLoader`, `VocabularyLoader`, `GrammarLoader`, `KanaLoader`) are
  now stateless enums routed through `ResourceLoader`.

### Fixed
- **Placeholder kanji examples in `KanjiN5.json`.** 51 kanji carried a bogus
  fifth example whose word was the kanji with `語` appended (`水語`, `木語`, `山語`
  …) and whose `reading`/`romaji` were blank — auto-generated filler that never
  read as real Japanese. Each is now the standalone kanji with its primary
  on'yomi (`水` → スイ/sui, `木` → モク/moku), derived from the entry's existing
  `onyomi` field and a deterministic katakana→rōmaji conversion validated against
  the 69 already-correct entries. Item count is unchanged and every reading/rōmaji
  is now filled.
- **Empty example translation in `GrammarN4.json`.** Item `N4_G125` (〜どうしても)
  had one example with a blank Indonesian translation; it is now filled.
- **Graduating-interval settings were dead code.** `FlashcardSettings`
  carried `graduatingIntervalDays` (1) and `easyIntervalDays` (4) but the review
  engine ignored them and graduated every learning card straight off its FSRS
  stability (≈2 days for Good), so a new card first reappeared on day 3 rather
  than day 2. The learning/relearning graduation now uses the fixed graduating
  interval ("cara A": Anki-style learning steps + graduating interval), so a
  Good graduation is due the next day and an Easy graduation in four; FSRS-6
  then schedules every subsequent review from the card's stability, unchanged.
  Regression tests assert the graduating intervals.
- **FSRS-6 difficulty update was missing linear damping.** `nextDifficulty`
  applied the FSRS-4.5 form (`D − w6·(G−3)`), omitting the `(10 − D)/9` damping
  introduced in FSRS-5/6 that shrinks difficulty changes as a card approaches
  the maximum. The mean-reversion step was already present; the damping is now
  applied before it, matching the reference algorithm. New tests assert the
  direction (Again harder, Easy easier) and that the change shrinks near the
  ceiling.
- **Flashcard session summary was bare.** After a deck session ended the screen
  showed only "Benar: X - Ulang: Y". It now presents a full summary — session
  accuracy, the number correct / needing another round / total cards, and the
  current day streak — all read from the same `FlashcardStore` that feeds the
  Home hero card and Profile, so the figures agree across every screen.
- **Dataset failures were swallowed.** `ResourceLoader` caught every error and
  returned an empty array, so a missing or corrupt JSON file was reported to the
  user as "Coming soon — konten level ini belum tersedia" and the `.failed`
  state was never assigned, leaving `ErrorStateView` unreachable. The kanji,
  vocabulary and grammar loaders now throw and their screens surface the real
  reason; callers with a genuine fallback use the explicit `loadArrayOrEmpty`.
- **Grammar list built every card eagerly**, constructing all 160 N3 rows on
  open where the kanji and vocabulary lists build only what is on screen; it is
  now a `LazyVStack` and shares the same load-state branches and 20pt inset.
- **Level counts contradicted the bundled datasets.** Kanji N3 advertised "580
  Essential Kanji" against a 214-entry dataset, Vocabulary N4 claimed ~1500
  words against 700, and Vocabulary N3 claimed ~3750 against 1110. Every count
  is now the real number of entries in the shipped JSON (Kanji 120/181/214,
  Vocabulary 800/700/1110, Grammar 84/131/160); levels whose data has not
  shipped are the only ones allowed an approximate "1.000+" figure.
  `scripts/check_dataset_counts.py` enforces both rules in CI.
- **`trailing_whitespace` was in SwiftLint's `disabled_rules`**, silencing 361
  violations across 20 files instead of fixing them. The whitespace is gone and
  the rule is on, leaving no rule switched off. The config's `excluded` path
  also still pointed at the pre-restructure `Sources/AppModule/Resources` and
  so matched nothing; it now points at `Sources/AppFeature/Resources`.
- **Level cards** for Kanji, Vocabulary and Grammar had duplicated SwiftUI
  modifiers that silently overrode the description styling; the intended
  two-line layout (name + count-bearing subtitle) is restored.
- **Kana flashcard** could render multiple "correct" answer buttons and emit
  duplicate `ForEach` identifiers when the distractor pool was small; choices are
  now guaranteed distinct.
- **Notification scheduling** now logs failures from `UNUserNotificationCenter`.

### Removed
- **Level search field on the Vocabulary screen.** It filtered a fixed list of
  five levels, which the Kanji and Grammar screens never had; the three level
  lists are now identical. Search remains where it does work — inside a level,
  over that level's actual entries.
- Dead code: the unused `AppState` observable object, the legacy `FlashcardItem`
  type and its initializer, the unused `itemsPerLevel` storage, and the no-op
  `NotificationManager.skipTodayIfTargetMet` method.
- Dead code: `FlashcardStore.dueTodayGrandTotal`, which summed every un-mastered
  card across all decks and is superseded by `dailyDueTotal(target:)`.
- Debug `print` statements across the loaders (replaced by unified logging).
- Artificial fixed-delay spinners on the static Kanji/Grammar/Vocabulary level
  lists, improving perceived navigation speed.
- Leftover review-note comments in the source.

### Changed (continued)
- **Deprecated SwiftUI APIs migrated.** `NavigationView` → `NavigationStack`
  (dropping the now-unnecessary `.navigationViewStyle(.stack)`) and every
  `foregroundColor(_:)` → `foregroundStyle(_:)` across the app. The minimum
  target is iOS 17, so both replacements are available; behaviour is unchanged.

### Design decisions
- **Typography stays on SF Pro Rounded**, the system's rounded face, as the
  native stand-in for the design's Baloo 2 / Nunito. This keeps the app binary
  small and avoids bundling and registering font files; the shapes are a close
  match.
- **Indonesian-only, strings inline.** The app ships in Indonesian and there is
  no second language planned, so user-facing text stays in the views. SwiftUI's
  `Text` already treats those literals as localised keys with the Indonesian
  text as the fallback, so the app remains translation-ready without a
  `Localizable.strings` file — which in the Swift Playgrounds package would add
  bundle-resolution risk for no benefit while the app has one language.

### Known limitations / next steps
- Content covers JLPT **N5–N3** plus kana; N2/N1 datasets are the recommended
  next expansion (those levels stay gated until their data is added).
- Account, backup and sync are implemented under `Backup/` but parked behind
  "Segera hadir"; wiring them to the UI is the largest remaining piece.
