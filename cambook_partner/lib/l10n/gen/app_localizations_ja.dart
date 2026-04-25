// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'CamBook パートナー';

  @override
  String get navHome => 'ホーム';

  @override
  String get navOrders => '注文';

  @override
  String get navMessages => 'メッセージ';

  @override
  String get navIncome => '収入';

  @override
  String get navProfile => 'マイページ';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get save => '保存';

  @override
  String get edit => '編集';

  @override
  String get delete => '削除';

  @override
  String get back => '戻る';

  @override
  String get loading => '読み込み中…';

  @override
  String get noData => 'データなし';

  @override
  String get noMore => '注文はこれ以上ありません';

  @override
  String get error => '読み込み失敗';

  @override
  String get retry => '再試行';

  @override
  String get close => '閉じる';

  @override
  String get send => '送信';

  @override
  String get call => '電話';

  @override
  String get navigate => 'ナビ';

  @override
  String get copy => 'コピー';

  @override
  String get justNow => 'たった今';

  @override
  String minutesAgo(int n) {
    return '$n分前';
  }

  @override
  String hoursAgo(int n) {
    return '$n時間前';
  }

  @override
  String daysAgo(int n) {
    return '$n日前';
  }

  @override
  String get success => '成功';

  @override
  String get failed => '失敗';

  @override
  String get submitting => '送信中…';

  @override
  String get statusOnline => 'オンライン';

  @override
  String get statusBusy => '対応中';

  @override
  String get statusRest => '休憩';

  @override
  String get statusOnlineDesc => '受注可能';

  @override
  String get statusBusyDesc => '対応中';

  @override
  String get statusRestDesc => '休憩中';

  @override
  String get statusSwitchTitle => 'ステータス変更';

  @override
  String get statusSwitchDesc => '受注状況に影響します';

  @override
  String get greetingMorning => 'おはようございます';

  @override
  String get greetingAfternoon => 'こんにちは';

  @override
  String get greetingEvening => 'こんばんは';

  @override
  String get techNo => '技術者番号';

  @override
  String get todayStats => '本日の実績';

  @override
  String get todayOrders => '本日の注文';

  @override
  String get todayIncome => '本日の収入';

  @override
  String get todayRating => '本日の評価';

  @override
  String get quickActions => 'クイックアクション';

  @override
  String get startAccepting => '受注開始';

  @override
  String get appointments => '予約管理';

  @override
  String get viewSchedule => 'スケジュール確認';

  @override
  String get recentOrders => '最近の注文';

  @override
  String get viewAll => 'すべて見る';

  @override
  String get noOrdersToday => '本日の注文はありません';

  @override
  String get newOrderTitle => '新しい注文';

  @override
  String get newOrderDesc => '新しいサービスリクエスト';

  @override
  String get acceptOrder => '受注する';

  @override
  String get rejectOrder => '断る';

  @override
  String autoReject(int s) {
    return '$s秒後に自動拒否';
  }

  @override
  String get refreshed => '更新しました';

  @override
  String get ordersTitle => '注文管理';

  @override
  String get tabPending => '受注待ち';

  @override
  String get tabAccepted => '受注済み';

  @override
  String get statusReception => '受付中';

  @override
  String get tabInService => '対応中';

  @override
  String get tabCompleted => '完了';

  @override
  String get tabCancelled => 'キャンセル';

  @override
  String get orderNo => '注文番号';

  @override
  String get serviceType => 'サービス種別';

  @override
  String get homeService => '出張サービス';

  @override
  String get storeService => '店舗サービス';

  @override
  String get amount => '金額';

  @override
  String get appointTime => '予約時間';

  @override
  String get distance => '距離';

  @override
  String get remark => '備考';

  @override
  String get btnAccept => '受注';

  @override
  String get btnReject => '断る';

  @override
  String get btnArrive => '到着';

  @override
  String get btnStartService => '開始';

  @override
  String get btnComplete => '完了';

  @override
  String get btnContact => '連絡';

  @override
  String get btnDetail => '詳細';

  @override
  String get rejectReason => '断り理由';

  @override
  String get rejectReasonHint => '理由を入力（任意）';

  @override
  String get acceptConfirm => 'この注文を受注しますか？';

  @override
  String get completeConfirm => 'サービスを完了しますか？';

  @override
  String get rejectConfirm => 'この注文を断りますか？';

  @override
  String get noOrders => '注文なし';

  @override
  String get duration => '所要時間';

  @override
  String get unitMin => '分';

  @override
  String get orderDetailTitle => '注文詳細';

  @override
  String get customerInfo => '顧客情報';

  @override
  String get orderInfo => '注文情報';

  @override
  String get serviceItems => 'サービス内容';

  @override
  String get totalAmount => '合計';

  @override
  String get orderTime => '注文時間';

  @override
  String get serviceAddress => '住所';

  @override
  String get customerNotes => '顧客メモ';

  @override
  String get serviceProgress => '進捗';

  @override
  String get stepPending => '受注待ち';

  @override
  String get stepAccepted => '受注済み';

  @override
  String get stepArrived => '到着';

  @override
  String get stepInService => '対応中';

  @override
  String get stepCompleted => '完了';

  @override
  String get confirmArrival => '到着確認';

  @override
  String get serviceActiveTitle => '対応中';

  @override
  String get elapsed => '経過時間';

  @override
  String get remaining => '残り時間';

  @override
  String get pause => '一時停止';

  @override
  String get resume => '再開';

  @override
  String get endService => 'サービス終了';

  @override
  String get endServiceConfirm => 'サービスを終了しますか？';

  @override
  String get pauseConfirm => '一時停止しますか？';

  @override
  String get focusMode => '集中モード';

  @override
  String get messagesTitle => 'メッセージ';

  @override
  String get systemNotice => 'システム';

  @override
  String get noMessages => 'メッセージなし';

  @override
  String get markAllRead => 'すべて既読';

  @override
  String get unread => '未読';

  @override
  String get chatPlaceholder => 'メッセージを入力…';

  @override
  String get quickReplies => 'クイック返信';

  @override
  String get sendLocation => '位置情報';

  @override
  String get noChatMessages => 'チャットを始めましょう';

  @override
  String get qr1 => '今向かっています';

  @override
  String get qr2 => 'どこにいますか？';

  @override
  String get qr3 => '到着しました';

  @override
  String get qr4 => 'サービスを開始しました';

  @override
  String get qr5 => '少々お待ちください';

  @override
  String get qr6 => 'ご利用いただきありがとうございます';

  @override
  String get incomeTitle => '収入';

  @override
  String get incomeOverview => '概要';

  @override
  String get periodToday => '本日';

  @override
  String get periodWeek => '今週';

  @override
  String get periodMonth => '今月';

  @override
  String get periodTotal => '累計';

  @override
  String get todayIncomeLabel => '本日の収入';

  @override
  String get weekIncomeLabel => '今週の収入';

  @override
  String get monthIncomeLabel => '今月の収入';

  @override
  String get totalIncomeLabel => '累計収入';

  @override
  String get incomeTrend => '収入推移';

  @override
  String get incomeRecords => '取引履歴';

  @override
  String get noRecords => '履歴なし';

  @override
  String get incomeOrder => '注文収入';

  @override
  String get incomeBonus => 'ボーナス';

  @override
  String get incomeDeduction => '差引';

  @override
  String get withdraw => '出金';

  @override
  String get availableBalance => '出金可能残高';

  @override
  String get withdrawAmount => '出金額';

  @override
  String get withdrawMethod => '出金方法';

  @override
  String get bankCard => '銀行カード';

  @override
  String get usdtLabel => 'USDT';

  @override
  String get withdrawMin => '最低出金\$10';

  @override
  String get withdrawConfirm => '出金確認';

  @override
  String get withdrawSuccess => '出金申請を受け付けました';

  @override
  String get inputAmount => '金額を入力';

  @override
  String get profileTitle => 'マイページ';

  @override
  String get levelNormal => '一般';

  @override
  String get levelSenior => '上級';

  @override
  String get levelGold => 'ゴールド';

  @override
  String get levelTop => 'トップ';

  @override
  String get completedOrders => '完了注文';

  @override
  String get skillsMenu => 'スキル管理';

  @override
  String get reviewsMenu => '口コミ';

  @override
  String get scheduleMenu => 'スケジュール';

  @override
  String get settingsMenu => '設定';

  @override
  String get helpMenu => 'ヘルプ';

  @override
  String get aboutMenu => 'アプリについて';

  @override
  String get logout => 'ログアウト';

  @override
  String get logoutConfirm => 'ログアウトしますか？';

  @override
  String get editProfile => 'プロフィール編集';

  @override
  String get memberSince => '加入日';

  @override
  String get settingsTitle => '設定';

  @override
  String get accountSection => 'アカウント';

  @override
  String get changePassword => 'パスワード変更';

  @override
  String get notifySection => '通知';

  @override
  String get orderNotify => '注文通知';

  @override
  String get messageNotify => 'メッセージ通知';

  @override
  String get systemNotify => 'システム通知';

  @override
  String get langSection => '言語';

  @override
  String get currentLanguage => '現在の言語';

  @override
  String get aboutSection => '情報';

  @override
  String get version => 'バージョン';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get terms => '利用規約';

  @override
  String get savedSuccess => '保存しました';

  @override
  String get scheduleTitle => 'スケジュール管理';

  @override
  String get calendarTab => 'カレンダー';

  @override
  String get appointmentsTab => '予約';

  @override
  String get setAvailable => '対応可能にする';

  @override
  String get setUnavailable => '休憩にする';

  @override
  String get workHours => '勤務時間';

  @override
  String get addTimeSlot => '時間帯を追加';

  @override
  String get noAppointments => '予約なし';

  @override
  String get upcoming => '今後の予定';

  @override
  String get confirmScheduleChange => 'スケジュールを変更しますか？';

  @override
  String get weekdayMon => '月';

  @override
  String get weekdayTue => '火';

  @override
  String get weekdayWed => '水';

  @override
  String get weekdayThu => '木';

  @override
  String get weekdayFri => '金';

  @override
  String get weekdaySat => '土';

  @override
  String get weekdaySun => '日';

  @override
  String get langZh => '中文';

  @override
  String get langEn => 'English';

  @override
  String get langVi => 'Tiếng Việt';

  @override
  String get langKm => 'ភាសាខ្មែរ';

  @override
  String get langKo => '한국어';

  @override
  String get langJa => '日本語';

  @override
  String get langTitle => '言語設定';

  @override
  String get loginTitle => 'パートナーログイン';

  @override
  String get loginSubtitle => 'おかえりなさい';

  @override
  String get phone => '電話番号';

  @override
  String get phoneHint => '電話番号を入力';

  @override
  String get password => 'パスワード';

  @override
  String get passwordHint => 'パスワードを入力';

  @override
  String get loginBtn => 'ログイン';

  @override
  String get forgotPassword => 'パスワードを忘れた方';

  @override
  String get loginSuccess => 'ログイン成功';

  @override
  String get loginFailed => '認証情報が正しくありません';

  @override
  String get phoneRequired => '電話番号を入力してください';

  @override
  String get passwordRequired => 'パスワードを入力してください';

  @override
  String get skillsTitle => 'スキル管理';

  @override
  String get reviewsTitle => '口コミ';

  @override
  String get noReviews => 'まだ口コミはありません';

  @override
  String get avgRating => '平均評価';

  @override
  String totalReviews(int n) {
    return '$n件のレビュー';
  }

  @override
  String get loginTabPhone => '電話番号でログイン';

  @override
  String get loginTabTechId => '技師IDでログイン';

  @override
  String get fieldTechId => '技師番号';

  @override
  String get techIdHint => '技師番号を入力してください';

  @override
  String get techIdRequired => '技師番号を入力してください';

  @override
  String get noAccount => 'アカウントをお持ちでないですか?';

  @override
  String get goRegister => '今すぐ登録';

  @override
  String get haveAccount => 'すでにアカウントをお持ちですか?';

  @override
  String get goLogin => 'ログイン';

  @override
  String get registerTitle => '技師アカウント作成';

  @override
  String registerSubtitle(String merchant) {
    return '$merchantに参加してサービスを開始しましょう';
  }

  @override
  String get fieldFullName => '氏名';

  @override
  String get fullNameHint => '氏名を入力してください';

  @override
  String get fullNameRequired => '氏名を入力してください';

  @override
  String get fieldEmail => 'メール';

  @override
  String get emailHint => 'メールアドレスを入力してください';

  @override
  String get fieldConfirmPassword => 'パスワード確認';

  @override
  String get confirmPasswordHint => 'パスワードを再入力してください';

  @override
  String get passwordMismatch => 'パスワードが一致しません';

  @override
  String get passwordTooShort => 'パスワードは6文字以上';

  @override
  String get fieldTelegram => 'Telegram';

  @override
  String get telegramHint => '@username（任意）';

  @override
  String get fieldFacebook => 'Facebook';

  @override
  String get facebookHint => 'ユーザー名またはURL（任意）';

  @override
  String get fieldMerchantCode => '加盟店コード';

  @override
  String get merchantCodeHint => '加盟店招待コードを入力してください';

  @override
  String get merchantCodeRequired => '加盟店コードを入力してください';

  @override
  String get selectCountry => '国を選択';

  @override
  String get registerBtn => '今すぐ登録';

  @override
  String get registerSuccess => '登録完了！加盟店の承認をお待ちください';

  @override
  String get registerFailed => '登録に失敗しました。再試行してください';

  @override
  String get invalidPhone => '無効な電話番号';

  @override
  String get invalidEmail => '無効なメールアドレス';

  @override
  String get optionalField => '任意';

  @override
  String get myMerchant => '所属加盟店';

  @override
  String get merchantVerified => '認証済み';

  @override
  String get merchantPending => '承認待ち';

  @override
  String get forgotPasswordTitle => 'パスワードを忘れた場合';

  @override
  String get forgotPasswordDesc => '登録済みの電話番号を入力してOTPを受信してください';

  @override
  String get sendOtp => 'OTPを送信';

  @override
  String otpSent(String phone) {
    return '$phoneにOTPを送信しました';
  }

  @override
  String get comingSoon => '近日公開';

  @override
  String get arrivalNotice => '技術者が到着しました。サービス開始を確認してください';

  @override
  String get launchingApp => 'アプリを起動中...';

  @override
  String get statusSwitchedTo => 'ステータスが変更されました';

  @override
  String get customerMessage => 'お客様からのメッセージ';

  @override
  String get systemMessage => 'システムメッセージ';

  @override
  String get serviceCompleted => 'サービス完了';

  @override
  String get grabExpired => '注文受付時間切れ';

  @override
  String get newOrder => '新規注文';

  @override
  String get newOrderGrab => '新規注文 — 今すぐ受付';

  @override
  String get distanceFrom => '距離:';

  @override
  String get ignore => '無視';

  @override
  String get grabOrder => '今すぐ受注';

  @override
  String get announcements => 'お知らせ';

  @override
  String get helpAndSupport => 'ヘルプ & サポート';

  @override
  String get rateApp => 'アプリを評価する';

  @override
  String get exitApp => 'アプリを終了';

  @override
  String get exitAppConfirm => 'アプリを終了しますか？';

  @override
  String get todaySchedule => '本日のスケジュール';

  @override
  String get allOrders => 'すべての注文';

  @override
  String get orderStatusPending => '確認待ち';

  @override
  String get orderStatusAccepted => '受注済み';

  @override
  String get orderStatusInProgress => 'サービス中';

  @override
  String get orderStatusCompleted => '完了';

  @override
  String get orderStatusCancelled => 'キャンセル';

  @override
  String get noScheduleToday => '本日の予約はありません';

  @override
  String get keepOnlineHint => 'オンラインを維持して新規注文を待ちましょう ✨';

  @override
  String get myStats => '私のデータ';

  @override
  String get totalOrders => '累計受注';

  @override
  String get overallRating => '総合評価';

  @override
  String get currentBalance => '現在の残高';

  @override
  String get statTodayAppointments => '本日の予約';

  @override
  String get statTodayCompleted => '本日の完了';

  @override
  String get statTodayCancelled => '本日のキャンセル';

  @override
  String schedOrderCount(int n) {
    return '$n件';
  }

  @override
  String get schedInService => 'サービス中';

  @override
  String get schedPending => 'サービス待ち';

  @override
  String get totalDuration => '合計時間';

  @override
  String scheduleProgress(int completed, int total) {
    return '$completed / $total 完了';
  }

  @override
  String get statusOnWay => '移動中';

  @override
  String get statusCancelling => 'キャンセル中';

  @override
  String get statusRefunding => '返金中';

  @override
  String get statusRefunded => '返金済み';

  @override
  String schedEndTime(String time, String duration) {
    return '終了 $time · $duration分';
  }

  @override
  String get serviceInProgress => 'サービス中';

  @override
  String estimatedIncome(String amount) {
    return '予定 $amount';
  }

  @override
  String get sessionExpiredTitle => 'セッション期限切れ';

  @override
  String get sessionExpiredMessage => 'ログアウトされました。続けるには再度ログインしてください。';

  @override
  String get goToLogin => 'ログインへ';

  @override
  String get networkTimeout => 'リクエストがタイムアウトしました。接続を確認してください。';

  @override
  String get networkUnavailable => 'ネットワークが利用できません。接続を確認してください。';

  @override
  String get networkError => 'リクエストが失敗しました。後でもう一度お試しください。';

  @override
  String get orderTypeOnline => 'オンライン予約';

  @override
  String get orderTypeWalkin => '店頭来店';

  @override
  String get walkinGuest => '一般来客';

  @override
  String get sessionNo => 'セッション';

  @override
  String get walkinOrderTip => '店頭注文はフロントデスクが管理します。';

  @override
  String get notificationSound => '通知音';

  @override
  String get vibration => 'バイブレーション';

  @override
  String get rating => '評価';

  @override
  String get myOrders => '注文一覧';

  @override
  String get reviews => 'レビュー';

  @override
  String get langHint => '表示言語を選択してください';
}
