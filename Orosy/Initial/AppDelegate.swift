//
//  AppDelegate.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/07.
//

import UIKit
import Amplify
import AmplifyPlugins

import UserNotifications
import BackgroundTasks
import Firebase
import Stripe
import FacebookCore
import Kingfisher

var LOG_ENABLED = true
var DEVELOP_MODE = false
var g_amplifyProdctionMode = true
var g_loginMode = false
var g_preViewController:OrosyUIViewController!
var g_currentViewController:OrosyUIViewController!  // 表示中のViewController これがMessageVC以外の場合には、Subscription Managerでメッセージを字受信したときにローカル通知する

var g_userLog:UserLog!
var g_trackingAuthorized: Bool?             // Facebook広告トラッキング用

var g_authChecked = false                       // true:認証チェック済み。　　バックグランドから復帰したら　falseにセットされ、認証チェックが実行される
var g_networkAvailable = false                  // true: ネットワーク接続が有効
var g_gotInitialData = false
var g_profileChecked = false
var g_localNotificationManager:LocalNotificationManager!

var g_tabbarController:UITabBarController!
var g_processManager:OrosyProcessManager!

var g_MyId:String?                              // 内部ID     ログアウトすると　""　にクリアーしている。
var g_session:AuthSession!

var g_paymentList:PaymentList!                  // 支払い方法の選択肢
var g_categoryDisplayName:CategoryDisplayName!

var g_cart:Cart!
var g_orderListObject:OrderList!

// 先読みデータ
var g_connectedSuppliers:ConnectedSuppliers?    // 取引が許可されている取引先のリスト
var g_newerSupplier:ShowcaseSuppliers?
var g_banner:ShowcaseContents!
var g_weeklyBrand:Recommend!                    // 週替わりブランド
var g_itaku_brand:Recommend!
var g_favoriteLists:FavoriteLists?              // お気に入りにリスト
var g_favoriteItems:[Favorite] = []

var g_homeVC:HomeVC?                        
var g_faveriteVC:FavoriteVC?                    // お気に入りVC

//　検索時のソートモード
var g_sortModeCategorySearchForProduct:SortMode = .Newer
var g_sortModeCategorySearchForBrand:SortMode = .Newer
var g_sortModeKeywordSearch:SortMode = .Newer

// メッセージ
var g_notificationGranted:Bool = false          // 通知の許可状態
//var g_messageList:MessageList!                // 指定されたユーザとの間のメッセージ
var g_threadList:[MessageThread] = []                  // スレッドのリスト
var g_defaultImage:UIImage!
var g_uuid_Message_queue:[String] = []

//　カート
var g_cartUpdated = false                       // カートに商品が追加されたら trueになる。カート情報をアップデートするかどうかの判定に使用

//  ディープリンクによるページ遷移のリクエスト
var g_openBrandPage:Supplier?
var g_openItemPage:ItemParent?

enum NotificationMessage:String {
    case EnteredIntoForeground = "EnteredIntoForeground"    // バックグランドから復帰した
    case SecondDataLoad = "SecondDataLoad"                  // EnteredIntoForegroundに継続して実行するデータ取得起動
    case ReveicedThreadMessage = "ReveicedThreadMessage"    // サブスクリプションでメッセージを受信した
    case ShowLoginVC = "ShowLoginVC"                        // ログインビューを表示する
    case AuthCheck = "AuthCheck"                            // 認証チェック
    case FavoriteReset = "FavoriteReset"                    // お気に入り情報が変化した
    case RefreshOrderList = "RefreshOrderList"              // 注文履歴を読み直す
    case RefreshApplyStatus = "RefreshApplyStatus"          // コネクション申請ステータスを更新する
    case Reset = "ResetData"                                // アカウントを切り替えたのでデータをリセットする
    case GotInitialData = "GotInitialData"                           // S3から設定データを取得した
}

// ローカル通知
enum NotificationCategory:String {
    case SubscriptionMessage = "subscriptionMessage"
    
}

// バックグランドフェッチ
 private let apprefreshIdentifier: String = "com.orosy.buyer.Orosy.refresh"


// View Controllers
var g_homeTabVC:HomeVC!
var g_cartVC:CartVC!

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, OrosyProcessManagerDelegate {
    
    var window: UIWindow?
    var uuid_S3data:String?
    var uuid_category:String?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("Application directory: \(NSHomeDirectory())")
        

#if DEVELOP
        DEVELOP_MODE = true
#else
        DEVELOP_MODE = false
#endif

        ApplicationDelegate.shared.application(  application,   didFinishLaunchingWithOptions: launchOptions )  // Added for Facebook SDK
        
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSAPIPlugin(apiAuthProviderFactory: OrosyAPIAuthProviderFactory()))
            try Amplify.configure()
            print("Amplify configured with auth plugin")
       } catch {
            print("An error occurred setting up Amplify: \(error)")
       }
        
        Network.shared.setUp() // ネットワークチェックの初期化
        
        // Use the Firebase library to configure APIs.
        FirebaseApp.configure()

        /*
        // バックグランドタスクを登録
        BGTaskScheduler.shared.register(forTaskWithIdentifier: apprefreshIdentifier, using: nil) { task in
            // バックグラウンド処理
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        */

        UserDefaultsManager.shared.getUserData()      // ローカルに保存している情報を取得
        OrosyAPI.initAPI()

        if g_processManager == nil {
            g_processManager = OrosyProcessManager()
            g_processManager.processManagerStatus = .ready
        }
        

        g_categoryDisplayName = CategoryDisplayName()
        
        uuid_S3data = g_processManager.addProcess(name:"s3データ", action: self.getS3Data, errorHandlingLevel: .IGNORE, errorCountLimit: -1, execInterval: 2, immediateExec: true, processType:.Once, delegate:self)

        
        var accountStatus = UserDefaultsManager.shared.accountStatus
/*
        OrosyAPI.signOut() { completion in
        
        }
        exit(0)
*/

        if !UserDefaultsManager.shared.appInitiated {
            OrosyAPI.signOut() { completion in

            }
            // 初期画面へ
            LogUtil.shared.log("call vc from appDeegate: 初期画面へ")
            let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
            let vc = storyboard.instantiateInitialViewController()
            self.setRootViewController(viewControllerName: vc!)
            
            return true
        }
        
        // すでにログイン状態なら、AccountVerified にしておく <-- すでにステータスは変わっているはずだからここで変更する必要はない？
        let result = OrosyAPI.fetchCurrentAuthSession()
        
        switch result {
        case .success(_):
            g_loginMode = true
                           
            if UserDefaultsManager.shared.accountStatus == .ApproveRequested {
                ProfileDetail.shared.getData()
                let brokerStatus = ProfileDetail.shared.brokerStatus
                if  brokerStatus == .approved {
                    accountStatus = .AccountApproved
                    UserDefaultsManager.shared.accountStatus = .AccountApproved
                }
            }
            
            
            switch accountStatus {
            case .AppInstalled:
                
                OrosyAPI.signOut() { completion in

                }
                // 初期画面へ
                LogUtil.shared.log("call vc from appDelegate: 初期画面へ")
                let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
                let vc = storyboard.instantiateInitialViewController()
                self.setRootViewController(viewControllerName: vc!)
        
            case .AccountNotVerified:
                // メール認証待ち画面へ
                LogUtil.shared.log("call vc from appDelegate: メール認証待ち画面へ")
                let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "VerifyEmailVC") as! VerifyEmailVC
                vc.displayMode = .notConfirmed
                setRootViewController(viewControllerName: vc)
            
            case .AccountVerified:
                // 審査入力画面へ
                LogUtil.shared.log("call vc from appDelegate: 審査入力画面へ")
                let storyboard = UIStoryboard(name: "RetailerSB", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "RetailerInfoVC") as! RetailerInfoVC
                setRootViewController(viewControllerName: vc)
            /*
            case .ApproveRequested:
                // 審査待ち画面へ
                LogUtil.shared.log("call vc from appDelegate: 審査待ち画面へ")
                let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "VerifyEmailVC") as! VerifyEmailVC
                vc.displayMode = .waitApprove
                setRootViewController(viewControllerName: vc)
            */
            //case .AccountApproved, .AccountProfiled:
            case .PasswordResetRequested:
                break
            default:
               // 利用開始！
                LogUtil.shared.log("call vc from appDelegate: 利用開始")
               let storyboard = UIStoryboard(name: "Main", bundle: nil)
               let vc = storyboard.instantiateInitialViewController()
               setRootViewController(viewControllerName: vc!)
            
            }
            
        case .failure(_):
        
            if g_loginMode {
            
                  let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
                  if let vc = storyboard.instantiateInitialViewController() {
                   
                      g_authChecked = false
                      setRootViewController(viewControllerName: vc)
                  }else{
                      LogUtil.shared.log("RootviewControllerが見つからない!")
                      return false
                  }
            }else{
                // ログイン無しで利用開始！
                 LogUtil.shared.log("call vc from appDelegate: 利用開始")
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateInitialViewController()
                setRootViewController(viewControllerName: vc!)
            }
        }
        
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 300 * 1024 * 1024   // メモリキャッシュのサイズ
        cache.diskStorage.config.sizeLimit = 1000 * 1024 * 1024     // DISKへ保存する画像キャッシュのサイズ
        KingfisherManager.shared.downloader.downloadTimeout = 60        // sec.
        
        // Remove all.
       // cache.clearMemoryCache()
       // cache.clearDiskCache { print("Done") }


        return true
    }

    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }

    // 初期画面を表示
    func setRootViewController(viewControllerName:UIViewController) {
        
        if g_processManager == nil {
            g_processManager = OrosyProcessManager()
            g_processManager.processManagerStatus = .ready
        }
        
        g_categoryDisplayName = CategoryDisplayName()
        
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        window!.rootViewController = viewControllerName
        window!.makeKeyAndVisible()
    
    }
    
    func getS3Data() -> Result<Any?, OrosyError> {
        let result = AppConfigData.shared.update()
        
        switch result {
        case .success(_):       
            return .success(true)
        case .failure(let error):
            return .failure(OrosyError.DoesNotExistS3FIle(error.localizedDescription))
        }
    }
    
    func getCategory() -> Result<Any?, OrosyError> {
        let result = Categories.shared.getCategories()
        
        switch result {
        case .success(_):
            return .success(true)
        case .failure(let error):
            return .failure(OrosyError.DoesNotExistS3FIle(error.localizedDescription))
        }
    }
    
    func processCompleted(_ _uuid:String? ) {
        
        if  _uuid == uuid_S3data {
            uuid_category = g_processManager.addProcess(name:"カテゴリデータ", action: self.getCategory , errorHandlingLevel: .IGNORE, errorCountLimit: -1, execInterval: 2, immediateExec: true, processType:.Once, delegate:self)   // アカウント作成後のプロフィール設定で必要なのでここで取得
        }
        
        if _uuid == uuid_category  {
            g_gotInitialData = true
            let refresh = Notification.Name(NotificationMessage.GotInitialData.rawValue)
            NotificationCenter.default.post(name: refresh, object: nil)
        }
        
        return
    }
    

    
    func applicationWillEnterForeground(_ application: UIApplication) {
        LogUtil.shared.log ("フォアグランドへ遷移した")
        g_authChecked = false
        g_cartUpdated = true
        let refresh = Notification.Name(NotificationMessage.AuthCheck.rawValue)  // 認証チェックを依頼
        NotificationCenter.default.post(name: refresh, object: nil)

    }
    
    func applicationWillTerminate(_ application: UIApplication) {

        SubscriptionManager.shared.stopSubscription()
        
        // Remove only expired.
        let cache = ImageCache.default
        cache.cleanExpiredMemoryCache()
        cache.cleanExpiredDiskCache { print("Done") }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {

        SubscriptionManager.shared.stopSubscription()
    }
    
    // MARK: ユニバーサルリンク
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    {
        if let incomingURL = userActivity.webpageURL {
            
            let urlStr = incomingURL.absoluteString
            if urlStr.contains("signup") &&  urlStr.contains("code=") {
                //アカウント認証なので、認証コードを取り出す
                if let range = urlStr.range(of: "code=") {
                  let code = urlStr[range.upperBound...]
                    print (code)
                    LogUtil.shared.log("ユニバーサルリンク:認証コードを受信")
                    
                    // 審査待ち画面へ
                    LogUtil.shared.log("call vc from appDeegate: 審査待ち画面へ")
                    let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "VerifyEmailVC") as! VerifyEmailVC
                    vc.displayMode = .notConfirmed
                    vc.verifyCode = String(code)
                    setRootViewController(viewControllerName: vc)
                    
                    return true     // アプリを起動する
                }
            }else
            if urlStr.contains("brand/")  {
                if let range = urlStr.range(of:"/brand/") {
                    let brand_id = String(urlStr[range.upperBound...])
                    
                    // Homeタブでブランドページを開く
                     g_openBrandPage = Supplier(supplierId: brand_id)
                    // Homeタブへ切り替える
                    openHomeTab()
                }
                
            }else
            if urlStr.contains("item/"){
                if let range = urlStr.range(of:"/item/") {
                    let item_id = String(urlStr[range.upperBound...])
                    
                    // Homeタブでプロダクトページを開く
                    g_openItemPage = ItemParent(itemParentId: item_id)
                    // Homeタブへ切り替える
                    openHomeTab()
                }
            }
        }
        
        return false    // 無視する
    }
    
    func openHomeTab() {
        if let tabBarController = self.window!.rootViewController as? UITabBarController {
            tabBarController.selectedIndex = 0  // タブをHOMEに切り替える
            //　HOMEタブをrootへ戻す
            
            if let navViewController = tabBarController.viewControllers?.first as? UINavigationController {
                navViewController.popToRootViewController(animated: false)
                if let viewController = navViewController.viewControllers.first {
                    viewController.viewWillAppear(true)
                }
            }
        }
    }
    // MARK: 通知処理
    // これらは AppDelegate内に記述する必要がある
    // 通知の受信を受け取るかどうか
     func userNotificationCenter(
         _ center: UNUserNotificationCenter,
         willPresent notification: UNNotification,
         withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
     {
         // アプリ起動時も通知を行う
         if #available(iOS 14.0, *) {
             completionHandler([[.banner, .list, .sound]])
         } else {
             completionHandler([[.alert, .sound]])
         }
     }
     
     func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
         
         // 通知の情報を取得
         let notification = response.notification

         // リモート通知かローカル通知かを判別
         if notification.request.trigger is UNPushNotificationTrigger {
             // Push Notification
             
         } else {
             // Local Notification
             // 通知の ID を取得

             switch NotificationCategory(rawValue: notification.request.content.categoryIdentifier) {
             case .SubscriptionMessage:
                 let userInfo = notification.request.content.userInfo
                 if let action = userInfo["Action"] as? String {
                     if action == "MessageVC" {
                         
                        // if let _ = userInfo["SupplierId"] as? String {
                             
                             g_tabbarController.changeTab(index: TabPosition.Message)
                             let refresh = Notification.Name(NotificationMessage.ReveicedThreadMessage.rawValue)  // データ更新を依頼
                             NotificationCenter.default.post(name: refresh, object: nil, userInfo: nil)
                      //   }
                    }
                 }
             default:
                 break
             }
         }

         completionHandler()
         
     }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // ケジューリング登録
        // scheduleAppRefresh()
        LogUtil.shared.log ("バックグランドへ遷移した")
    }
}


    /*
    // MARK: バックグランド処理関連
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        //バックグラウンドで実行する処理

        //適切なものを渡します → 新規データ: .newData 失敗: .failed データなし: .noData
        completionHandler(.newData)
    }



    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: apprefreshIdentifier)          // Info.plistで定義したIdentifierを指定
       
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)  // 最低で、どの程度の期間を置いてから実行するか指定 15分

        do {
            try BGTaskScheduler.shared.submit(request)      // スケジューラーに実行リクエストを登録
        } catch {
            print("Could not schedule app Refresh: \(error)")
        }
    }
    

    private func handleAppRefresh(task: BGAppRefreshTask) {
        
        print("handleAppRefresh called")
        
        scheduleAppRefresh()    // 新たにスケジューリングに登録

        // 1. オペレーションキューの作成
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        
        let operation = FetchThreadsOperation()

        // 時間内に実行完了しなかった場合は、処理を解放します
        // バックグラウンドで実行する処理は、次回に回しても問題ない処理のはずなので、これでOK
        task.expirationHandler = {
            operation.cancel()
        }

        operation.completionBlock = {
            // 最後の処理が完了したら、必ず完了したことを伝える必要がある
            task.setTaskCompleted(success: operation.isFinished)

        }

        // Start the operation.
        operationQueue.addOperation(operation)
        
    }

}

class FetchThreadsOperation:Operation {
    
    enum OperationError: Error {
         case cancelled
     }
    
    private let identifier: String = "fetch_threads_operation"
    
    
    // 非同期処理を行う場合、isAsynchronousをオーバーライドしてtrueを返すようにする
    override var isAsynchronous: Bool {
        return true
    }

    // 非同期処理を行う場合、isExecutingのオーバーライドが必要
    // 値を変更するときはKVOの変更通知を行う
    private var _isExecuting: Bool = false
    override var isExecuting: Bool {
        get {
            _isExecuting
        }
        set {
            willChangeValue(forKey: #keyPath(isExecuting))
            _isExecuting = newValue
            didChangeValue(forKey: #keyPath(isExecuting))
        }
    }

    // 非同期処理を行う場合、isFinishedのオーバーライドが必要
    // 値を変更するときはKVOの変更通知を行う
    private var _isFinished: Bool = false
    override var isFinished: Bool {
        get {
            _isFinished
        }
        set {
            willChangeValue(forKey: #keyPath(isFinished))
            _isFinished = newValue
            didChangeValue(forKey: #keyPath(isFinished))
        }
    }

    // キャンセル処理
    override func cancel() {
        super.cancel()

    }

    // 非同期オペレーションのエントリーポイント
    override func start() {
        print("Background Refresh: Start")
        // 実行中フラグON
        isExecuting = true

        if isCancelled {
            completionHandler(result: .failure(OperationError.cancelled))
            return
        }
        
        OrosyAPI.initAPI(production: false)
        g_userDefaults = UserDefaultsManager()
        let latestThreadDate = g_userDefaults.latestThreadDate ?? Date(timeIntervalSince1970: 0)
        print("Background Refresh: Got thread")
        if let threads = Threads(size: 1)?.threads { // 最新の一つだけを取得
            if threads.count > 0 {
                if let lastThread = threads.first {
                    if lastThread.timestamp ?? Date(timeIntervalSince1970: 0) > latestThreadDate {
                        g_userDefaults.latestThreadDate = lastThread.timestamp
                        g_userDefaults.updateUserData()
                        print("Background Refresh: Local Notification")
                        // ローカル通知ポップアップ
                        if let supplier = lastThread.supplier {
                            g_localNotificationManager = LocalNotificationManager()
                            g_localNotificationManager.setAppNotification(title:"Orosyからのお知らせ", body:"\(supplier.brandName ?? "不明")様からのメッセージを受信しました", userInfo:["Action":"MessageV5C", "SupplierId":supplier.id])
                        }
 
                    }
                }
            }
        }
    }
    
    // 処理完了ハンドラ
     private func completionHandler(result: Result<[String], Error>) {

         guard isExecuting else {
             return
         }

         // 実行中フラグOFF
         isExecuting = false

         // 終了フラグON
         isFinished = true
     }
}
*/
    
