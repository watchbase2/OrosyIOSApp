//
//  OrosyAPI.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/09.
//
//  urlデータは URL型、　金額はDecimal型、日付型は Date に統一

import Foundation
import UIKit
import Amplify
import AmplifyPlugins
import AWSPluginsCore
import Kingfisher

let API_TIMEOUT:Double = 10.0   // time out for semaphore sec.

/*
public enum Result<T, Error> {
    case success(T)
    case failure(Error)
}
*/
var OrosyAppStoreUrl = "itms-apps://itunes.apple.com/app/apple-store/id1616380382?mt=8"     //  id1616380382　　がアプリのId
var ROOT_URL = ""
var RETAILER_SITE_URL = ""
var SUPPLIER_SITE_URL = ""
var EXT_S3_SOURCE_BASE_URL = ""
var BLOG_RETAILER_BASE_URL = ""
var STRIPE_PUBLIC_KEY = ""

let privacyPlicyURL = "https://privacy.spaceengine.io/"
let termsForSupplierURL = "https://tos.spaceengine.io/supplier"
let termsForBuyerURL = "https://tos.spaceengine.io/retailer"

//
enum SaleType:String {
    case WholeSale = "wholesale"
    case Consignment = "consignment"
    case Undefinened = "none"
}

enum SortMode:String {
    case Newer = "newer"
    case Recommend = ""
    case PriceAscend = "price_asc"
    case PriceDesend = "price_desc"
    case Personalized = "personalizedRecommend"
}

enum SearchKey:String {
    case Large = "largeCategoryId"
    case Middle = "middleCategoryId"
}

enum SocialURLType:String {
    case Home = "home"
    case Twitter = "twitter"
    case Facebook = "facebook"
    case Instagram = "instagram"
    case LINE = "line"
    case Others = "other"
}


enum AccountStatus:String {
    case AppInstalled = "AppInstalled"              // アプリインストール済み（インストールしたことをUserLogで通知済みかどうかの判定）
    case AccountNotVerified = "AccountNotVerified"  // アカウントのコード認証待ち
    case AccountVerified = "AccountVerified"        // EmailによるVerifled
    case ApproveRequested = "ApproveRequested"      // アカウント認証中（認証情報入力済み、未認証）
    case AccountApproved = "AccountApproved"        // アカウント認証済     この状態でも商品の閲覧は可能だが、卸価格の閲覧申請はできない
    case AccountProfiled = "AccountProfiled"        // プロフィール設定済み
    case PasswordResetRequested = "PasswordResetRequested"        // パスワードリセットがリクエストされた
}

// MARK: エラーの定義
public enum OrosyError:Error {
    case NotInitialized
    case UserNotConfirmed
    case NeedPasswordReset
    case KeyNotFound
    case PaymentUndifined
    case DeliveryPlaceUndefined
    case UnknownAddress
    case UnknownPrefecture
    case UnknownOwnerId
    case UnknownOrderError
    case NotEnoughInventory(String)
    case UnknownErrorWithMessage(String)
    case CartItemNotRemoved(String)
    case LessThanMinLot(String)
    case DoesNotExistS3FIle(String)
    case AuthError
    case DataReadError
    case API_TIMEOUT
    case CanNotGetOrderHistory
    case PauseProcess
    case NotSignedIn
    case SubscriptionError
    case UserLogError(String)
    case UnKnownAPIError
    case PostCodeAddressUnMatch
    case Exceed90DaysPaymentLimit

}

// エラーメッセージ
extension OrosyError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .NotInitialized: return "初期化されていません"
        case .UserNotConfirmed:return "メール認証を完了していません"
        case .NeedPasswordReset:return "パスワードのリセットが必要です"
        case .KeyNotFound: return "キーが見つかりません"
        case .PaymentUndifined: return "支払い方法が指定されていません"
        case .DeliveryPlaceUndefined: return "配送先が指定されていません"
        case .UnknownAddress: return "配送先の住所が不正です"
        case .UnknownPrefecture: return "配送先の都道府県が不正です"
        case .UnknownOwnerId: return "オーナIDが不正です"
        case .UnknownOrderError: return "不明な理由で注文できませんでした"
        case .NotEnoughInventory(let msg): return "商品が在庫切れです: \(msg)"
        case .UnknownErrorWithMessage(let msg) : return "不明なエラーです: \(msg)"
        case .CartItemNotRemoved(let msg) : return "カートから削除できません: \(msg)"
        case .LessThanMinLot(let msg): return "最小ロット数を満たしていません: \(msg)"
        case .DoesNotExistS3FIle(let msg): return "ファイルが見つかりません: \(msg)"
        case .AuthError: return "認証に失敗しました。ログインしなおしてください"
        case .DataReadError: return "もう読み込めるデータはありません"
        case .API_TIMEOUT:return "APIの呼び出しがタイムアウトしました"
        case .CanNotGetOrderHistory:return "注文履歴データを取得できません"
        case .PauseProcess:return "ポーズ中"
        case .NotSignedIn:return "サインインしていません"
        case .SubscriptionError:return "サブスクリプションリクエストエラー"
        case .UserLogError(let msg): return "UserLogエラー: \(msg)"
        case .UnKnownAPIError:return "APIエラー:"
        case .PostCodeAddressUnMatch:return "入力された郵便番号と住所が一致していません"
        case .Exceed90DaysPaymentLimit: return "90日支払いの購入可能額を上回っています。"
            
        }
    }
}



// MARK: -------------------------------------
// MARK: Util


class OrosyAPI {

    class func initAPI() {
        
        if DEVELOP_MODE {
            ROOT_URL = "https://retailer.beta-env.spaceengine.io/"
            RETAILER_SITE_URL = "https://retailer.beta-env.spaceengine.io"
            SUPPLIER_SITE_URL = "https://supplier.beta-env.spaceengine.io"
            EXT_S3_SOURCE_BASE_URL = "https://orosy-datasource-develop.s3-ap-northeast-1.amazonaws.com"
            BLOG_RETAILER_BASE_URL = "https://blog.orosy.com/retailer/blog/"
            STRIPE_PUBLIC_KEY = "pk_test_MbBzWOwHGN6M0EfTu3TjHovY"

        }else{
            ROOT_URL = "https://retailer.orosy.com/"
            RETAILER_SITE_URL = "https://retailer.orosy.com"
            SUPPLIER_SITE_URL = "https://supplier.orosy.com"
            //EXT_S3_SOURCE_BASE_URL = "https://orosy-datasource-develop.s3-ap-northeast-1.amazonaws.com"
            EXT_S3_SOURCE_BASE_URL = "https://orosy-datasource-production.s3-ap-northeast-1.amazonaws.com"
            BLOG_RETAILER_BASE_URL = "https://blog.orosy.com/retailer/blog/"
            STRIPE_PUBLIC_KEY = "pk_live_jbaUcDxEE4j8xI7X7deBhjgu"
        }
    }
    

    class func callSyncAPI(_ graphql:String, variables: [String:Any]? = nil) -> ( Result<[String:Any], Error> ) {
        
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<[String:Any], Error>!
        
        let api = (g_loginMode) ? "OrosyAuthAPI" : "OrosyUnAuthAPI"
        
        callAPI(graphql, api:api, variables:variables,  completion: { apiresult in
            
            result = apiresult
            semaphore.signal()
        })
        
        let timeoutResult = semaphore.wait(timeout: .now() + API_TIMEOUT)
        switch timeoutResult {
        case .success:
            break
        default:
            return .failure(OrosyError.API_TIMEOUT)
        }
        
        switch result {
        case .success(_):
            break
            
        case .failure(_):
            break

        default:
            break
        }
        
        return result
    }
    
    class func callAPI(_ graphql:String,api:String, variables:[String: Any]? = nil, completion: @escaping ( Result<[String:Any], Error> )-> Void) {
        
        let  req = GraphQLRequest(apiName: api, document: graphql, variables: variables, responseType: String.self)

        
        Amplify.API.query(request: req) { event in
            switch event {
            case .success(let result):
                switch result {
                case .success(let data):
                    let jsondata = data.data(using: .utf8)!
                    do {
                        let resultDic = try JSONSerialization.jsonObject(with: jsondata, options: []) as! [String:Any]
                        completion(.success(resultDic) )    // resultDic に"error"キーが存在しても successで返す
                    } catch {
                        LogUtil.shared.log(graphql)
                        LogUtil.shared.errorLog(error: error)
                        print(error.localizedDescription)
                        g_userLog.error(graphql:graphql, message:error.localizedDescription)
                        completion(.failure(error))
                    }
                case .failure(let error):
                    LogUtil.shared.log(graphql)
                    LogUtil.shared.errorLog(error: error)
                    if let userLog = g_userLog {
                        userLog.error(graphql:graphql, message:error.localizedDescription)
                    }
                    completion(.failure(error))
                }
                
            case .failure(let error):
                LogUtil.shared.log(graphql)
                LogUtil.shared.errorLog(error: error)
                if ((error.underlyingError?.localizedDescription.contains("AuthError")) != nil) {
                    if let userLog = g_userLog {
                        userLog.error(graphql:graphql, message:OrosyError.AuthError.localizedDescription)
                    }
                    completion(.failure(OrosyError.AuthError))
                    
                }else{
                    if let userLog = g_userLog {
                        userLog.error(graphql:graphql, message:error.localizedDescription)
                    }
                    completion(.failure(error))
                }
            }
        }
    }
    
    
    // 取引タイプから取引名へ変換
    class func getPaymentDisplayName(_ payment:Payment?) -> String {
        
        let type = payment?.type ?? .NONE
        
        switch type {
        case .NP: return "翌月末支払い"
        case .DAY90: return "90日支払い"
        case .POINT: return "ポイント"
        case .NONE: return ""
        }
    }

    
    // 画像をネットから取得してキャッシュへ入れる
    class func cacheImage(_ _url:URL? , imagesize:OrosyImageSize) -> DownloadTask? {

        guard let url = _url else { return nil }
        
     //   DispatchQueue.global().async {
            let compressedUrlString = url.absoluteString + imagesize.rawValue
            
            let cache = ImageCache.default
            if !cache.isCached(forKey: compressedUrlString) {
                // キャッシュになかったので、ダウンロードしてキャッシュへ入れる

                if let urlComplressed = URL(string: compressedUrlString) {

                    let downloadTask = KingfisherManager.shared.retrieveImage(with: urlComplressed) { result in
                       print(cache.isCached(forKey: compressedUrlString))
                        switch result {
                        case .success(let value):
                           print(value.cacheType)
                            
                        case .failure(let error):
                            print(error)

                        }
                    }
                    return downloadTask
                    /*
                    let imageData: Data? = try Data(contentsOf:urlComplressed )
                    if let data = imageData {
                        if let image = UIImage(data: data) {
                            cache.store(image, forKey: compressedUrlString)
                        }
                    }
                     */
                }
            }
    //    }
        return nil
    }
    
    class func getImageFromCache(_ _url:URL? , imagesize:OrosyImageSize, completion: @escaping ( UIImage? ) -> Void )  {
        if let url = _url {
            
            let urlString = url.absoluteString
            let compressedUrlString = urlString + ((urlString.contains("gif") || urlString.contains("png") )  ? "" : imagesize.rawValue)
            
            if let urlComplressed = URL(string: compressedUrlString) {
                KingfisherManager.shared.retrieveImage(with: urlComplressed) { result in
                    switch result {
                    case .success(let value):
                       print(value.cacheType)
                        
                        completion(value.image)
                        
                    case .failure(let error):
                        print(error)
                        completion(nil)
                    }
                }
            }
        }else{
            completion(nil)
        }
    }

    
    // Refresh token
    class func fetchCurrentAuthSession()  -> Result<Any?, Error> {

        var success = false

        let semaphore = DispatchSemaphore(value: 0)
        _ = Amplify.Auth.fetchAuthSession { result in
            
    
            switch result {
            case .success(let session):
                print("Is user signed in - \(session.isSignedIn)")
                
                /*
                if let sess = session as? AWSAuthCognitoSession {
                  let result = sess.getCognitoTokens()
                  switch result {
                    case .success(let tokens):
                      let accessToken = tokens.accessToken
                      let idToken = tokens.idToken
                      let refreshToken = tokens.refreshToken
 
                      let parts = accessToken.components(separatedBy: ".")

                      if parts.count != 3 { fatalError("jwt is not valid!") }

                      let header = parts[0]
                      let payload = parts[1]
                      let signature = parts[2]
                      print(decodeJWTPart(part: payload) ?? "could not converted to json!")
                      
                    case .failure(let error):
                      print("Fetch user tokens failed with error \(error)")
                  }
                }
                */
                
                if session.isSignedIn {
                    g_session = session

                    let user = Amplify.Auth.getCurrentUser()
                    g_MyId = user?.userId.graphQLDocumentValue
                    

                    if g_userLog == nil {
                        if let userId = g_MyId {
                            LogUtil.shared.log("init UserLog")
                            g_userLog = UserLog(userId: userId)
                        }
                    }

                    
                    success = true
                    LogUtil.shared.log("Session is available")
                    semaphore.signal()
                    
                }else{
                    success = false
                    semaphore.signal()
                    LogUtil.shared.log("Session is disabled")
                }
                
            case .failure(let error):
                LogUtil.shared.errorLog(error: error)
                success = false
                semaphore.signal()
            }
        }
        
        semaphore.wait()
        
        return (success) ? .success(nil) : .failure(OrosyError.AuthError)

    }

    class func base64StringWithPadding(encodedString: String) -> String {
        var stringTobeEncoded = encodedString.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let paddingCount = encodedString.count % 4
        for _ in 0..<paddingCount {
            stringTobeEncoded += "="
        }
        return stringTobeEncoded
    }

   class func decodeJWTPart(part: String) -> [String: Any]? {
        let payloadPaddingString = base64StringWithPadding(encodedString: part)
        guard let payloadData = Data(base64Encoded: payloadPaddingString) else {
            fatalError("payload could not converted to data")
        }
            return try? JSONSerialization.jsonObject(
            with: payloadData,
            options: []) as? [String: Any]
    }
     
    class func signIn(userId: String, password: String, completion: @escaping ( Result<String, OrosyError>) -> Void )  {
       
        Amplify.Auth.signIn(username: userId, password: password) { result in
            switch result {
            case .success(let signinResult):    // id/passのチェックは成功
                
                switch signinResult.nextStep {
                case .confirmSignInWithSMSMFACode(let deliveryDetails, let info):
                    LogUtil.shared.log("SMS code send to \(deliveryDetails.destination)")
                    LogUtil.shared.log("Additional info \(info?.description ?? "")")
 
                    // Prompt the user to enter the SMSMFA code they received
                    // Then invoke `confirmSignIn` api with the code
                
                case .confirmSignInWithCustomChallenge(let info):
                    LogUtil.shared.log("Custom challenge, additional info \(info?.description ?? "")")
                    
                    // Prompt the user to enter custom challenge answer
                    // Then invoke `confirmSignIn` api with the answer
                
                case .confirmSignInWithNewPassword(let info):
                    LogUtil.shared.log("New password additional info \(info?.description ?? "")")
                    
                    // Prompt the user to enter a new password
                    // Then invoke `confirmSignIn` api with new password
                
                case .resetPassword(let info):
                    LogUtil.shared.log("Reset password additional info \(info?.description ?? "")")
                    
                    // User needs to reset their password.
                    // Invoke `resetPassword` api to start the reset password
                    // flow, and once reset password flow completes, invoke
                    // `signIn` api to trigger signin flow again.
                
                case .confirmSignUp(let info):
                    // 認証コードの入力待ち
                    LogUtil.shared.log("Confirm signup additional info \(info?.description ?? "")")
                    UserDefaultsManager.shared.accountStatus = .AccountNotVerified
                    UserDefaultsManager.shared.updateUserData()
                    
                    completion( .failure(OrosyError.UserNotConfirmed))
                    // User was not confirmed during the signup process.
                    // Invoke `confirmSignUp` api to confirm the user if
                    // they have the confirmation code. If they do not have the
                    // confirmation code, invoke `resendSignUpCode` to send the
                    // code again.
                    // After the user is confirmed, invoke the `signIn` api again.
                    
                case .done:
                    
                    // Use has successfully signed in to the app
                    UserDefaultsManager.shared.accountStatus = .AccountVerified
                    UserDefaultsManager.shared.updateUserData()
                    print("Signin complete")
                    
                    LogUtil.shared.log("Sign in succeed")
                    let user = Amplify.Auth.getCurrentUser()
                    let userId = user?.userId.graphQLDocumentValue ?? ""
                    
                    //ProfileDetail.shared.getData()   //　ログインしているユーザのプロファイル
                    
                    completion( .success(userId) )
                }
                
            // 未認証だと userIDが nilになる
            case .failure(let error):
                // id/passのチェックに失敗

                LogUtil.shared.errorLog(error: error)
                _ = Amplify.Auth.signOut()

                completion( .failure(OrosyError.AuthError) )
            }
        }
    }

    // 認証メールを再送
    class func resend(userId: String,  completion: @escaping ( Result<String, OrosyError>) -> Void )  {
        
        Amplify.Auth.resendSignUpCode(for: userId) { result in
        
            switch result {
            case .success(_):    // 認証コードを再送した
                completion(.success(userId))
                
            case .failure(_):
                completion(.failure(OrosyError.AuthError))
                break
            }
        }
    }
    
    class func signOut( completion: @escaping ( Result<Bool , AuthError>) -> Void )   {
        
        Amplify.Auth.signOut() { result in
            switch result {
            case .success:
                g_MyId = nil
                
                UserDefaultsManager.shared.accountStatus = .AppInstalled
                UserDefaultsManager.shared.updateUserData()
                
                LogUtil.shared.log("Successfully signed out")
                completion(.success(true))
            case .failure(let error):
                LogUtil.shared.errorLog(error: error)
                completion (.failure(error))
            }
        }
    }

    enum SignupError {
        case success
        case codeExpired
        case notConfirmed
        case aleradyConfirmed
        case otherError             // 認証コードが間違っているとか・・
    }

    class func signUp(userId: String, password: String, email: String, completion: @escaping ( Result<Bool, Error> ) -> Void )   {
        
        let userAttributes = [AuthUserAttribute(.email, value: email)]
            let options = AuthSignUpRequest.Options(userAttributes: userAttributes)
        
        Amplify.Auth.signUp(username: userId, password: password, options: options ) { result in
            switch result {
            case .success(let signUpResult):
                
                // ユーザ登録をリクエスト（認証メールが送信される)
                if case let .confirmUser(deliveryDetails, _) = signUpResult.nextStep {
                    LogUtil.shared.log("Delivery details \(String(describing: deliveryDetails))")
                    
                } else {
                    LogUtil.shared.log("SignUp Complete")
                }
                completion(.success(true))
                
            case .failure(let error):
                LogUtil.shared.log("An error occurred while registering a user \(error)")
                completion(.failure(error))

            }
        }
    }

    
    class func confirmSignUp(for username: String, with confirmationCode: String) -> SignupError {
        let semaphore = DispatchSemaphore(value: 0)
        var errorCode:SignupError = .otherError
        
        Amplify.Auth.confirmSignUp(for: username, confirmationCode: confirmationCode) { result in
            switch result {

            case .success:
                LogUtil.shared.log("Confirm signUp succeeded")
                errorCode = .success
                
            case .failure(let error):
                LogUtil.shared.log("ConfirmSignup error:\(error.localizedDescription)")
                switch error {
                case .service(let errorDescription, _, let err):
                    /*  コードがExpireしている場合
                     (Amplify.AuthError) error = service {
                       service = (0 = "Invalid code provided, please request a code again.", 1 = "Rerun the flow to send the code again", 2 = codeExpired)
                     }
                     */
                    LogUtil.shared.log(errorDescription)
                    if let nsError = err as? NSError {
                        print(nsError.code )
                        
                        if  nsError.code == 6 { errorCode = .codeExpired }else{  errorCode = .otherError }
                    }
                    
                case .validation(let field, let errorDescription , let sugestion, let err):
                    /*　コードが不正？
                     validation = {
                       0 = "code"
                       1 = "code is required to confirmSignUp"
                       2 = "Make sure that a valid code is passed for confirmSignUp"
                       3 = nil
                     }
                     */
                    errorCode = .otherError
                    break
                default:
                    break
                }

            }
            semaphore.signal()
        }
        semaphore.wait()
        return errorCode
    }
    
}

class OrosyAPIAuthProviderFactory: APIAuthProviderFactory {
    let myAuthProvider = MyOIDCAuthProvider()

    override func oidcAuthProvider() -> AmplifyOIDCAuthProvider? {
        return myAuthProvider
    }
}

class MyOIDCAuthProvider : AmplifyOIDCAuthProvider {
    
    func getLatestAuthToken() -> Result<AuthToken, Error> {

        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<String, Error> = .failure(AuthError.unknown("Could not retrieve Cognito token"))
        
        Amplify.Auth.fetchAuthSession { (event) in
            defer {
                semaphore.signal()
            }
            switch event {
            case .success(let session):
                if let cognitoTokenResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens() {
                    switch cognitoTokenResult {
                    case .success(let tokens):
                        result = .success(tokens.idToken)
                    case .failure(let error):
                        result = .failure(error)
                    }
                }
            case .failure(let error):
                result = .failure(error)
            }
        }
        semaphore.wait()
        return result
    }
}


// MARK: ローカル保存
final public class UserDefaultsManager:NSObject {
    
    public static let shared = UserDefaultsManager()
    
    var accountStatus:AccountStatus = .AppInstalled     // アプリのインストール直後から認証、プロフィール入力などの状況
    var appInitiated:Bool = false                       // false: アプリのインストール直後
    var appVersion:String?                              // アプリのバージョン（バージョンアップしたことを判定するために使用。ログ送信用）
    var loginId:String?                                 // ログインアカウントのid
    var selectedDelivelyPlaceId:String?                 // デフォルトの配送先
    var selectedPayment:PAYMENT_TYPE?                   // デフォルトの支払い方法
    var readPointer:Int = 0                             // ホームのサプライヤ一覧用データ読み出し位置
    var category:String?                                // json形式の文字列
    var latestThreadDate:Date?                          // 最新のスレッドの日時
    var actionFlags:[String:String] = [:]               // アクション通知の実行済みフラグ（アクションのvalueの値を保持する
    
    

    private override init() { }

    // ローカルデータの読み出し。　この中では、サーバからデータが取得できていることを前提とした変換処理は行わないこと！
    public func getUserData() {
        
        if let userDic = UserDefaults.standard.object(forKey: "UserData") as? [String:Any] {
            accountStatus = AccountStatus(rawValue: userDic["accountStatus"] as? String ?? "None") ?? .AppInstalled
            appInitiated = userDic["appInitiated"] as? Bool ?? false
            g_MyId = userDic["userId"] as? String ?? ""
            selectedPayment = PAYMENT_TYPE(rawValue: userDic["selectedPayment"] as? String ?? "") ?? .NONE
            readPointer = userDic["readPointer"] as? Int ?? 0
            category = userDic["category"] as? String
            latestThreadDate = userDic["latestThreadDate"] as? Date
            appVersion = userDic["appVersion"] as? String
            g_sortModeKeywordSearch = SortMode(rawValue:userDic["keywordSearchMode"] as? String ?? "") ?? .Newer
            actionFlags = userDic["actionFlags"] as? [String:String] ?? [:]

        }else{
            accountStatus = .AppInstalled
            
        }
    }

    public func updateUserData() {
        let userDic:[String : Any] = [
                "accountStatus":accountStatus.rawValue,
                "appInitiated":appInitiated,             //　false: インストール直後
                "appVersion":Util.getAppVersion(),      // 最新のバージョン情報を保存
                "userId":g_MyId ?? "",
                "selectedPayment": selectedPayment?.rawValue ?? "",
                "readPointer": readPointer,
                "category": category ?? "",
                "latestThreadDate": latestThreadDate ?? Date(),
                "keywordSearchMode": g_sortModeKeywordSearch.rawValue,
                "actionFlags" : actionFlags
        ]

        
        UserDefaults.standard.set(userDic, forKey: "UserData")
    }
    
    public func reset() {
        
        UserDefaults.standard.set([:], forKey: "UserData")
        UserDefaultsManager.shared.accountStatus = .AppInstalled
        UserDefaultsManager.shared.updateUserData()
    }
}



// カテゴリ記号から表示名へ変換
// 変換テーブルはS3から取得しローカルに保存する。以降はローカルのデータを使う
// forceGetFromServerをtrueにすると、強制的にサーバから取得する

class CategoryDisplayName:NSObject {

    var categoryNameDic:[String:String]?
    
    public func get() -> Result<Any?, OrosyError>{
        
        return get(forceGetFromServer:false )
        
    }
    
   public func  get(forceGetFromServer:Bool )  -> Result<Any?, OrosyError>{
        
       var toGetFromServer = forceGetFromServer
       
       // ローカルから読み出す。ローカルになければサーバから取得する
       if let userDic = UserDefaults.standard.object(forKey: "CategoryNameData") as? [String:String] {
            categoryNameDic = userDic
            return .success(nil)
           
       }else{
            toGetFromServer = true
       }
       
       if toGetFromServer {
           if let config = AppConfigData.shared.config {
               categoryNameDic = config["CategoryName"] as? [String:String]
               UserDefaults.standard.set(categoryNameDic, forKey: "CategoryNameData")
               return .success(nil)
           }
       }
       return .failure(OrosyError.DoesNotExistS3FIle("Category"))
    }
    

    public func getDisplayName(_ category:String?) -> String {
    
    guard let cat = category else { return "" }
    
        if let dic = categoryNameDic {
            var name = dic[cat] ?? ""       // crash
            if name == "" { name = ""}
            return name
        }else{
            return "???"
        }
    }
}

// S3から設定情報を読み出す　　　このデータは、ログインしていなくても取得可能
final class AppConfigData:NSObject {
    
    public static let shared = AppConfigData()
    var config:[String:Any]?
    
    public var ecShopCategoryList:[ShopCategory] = []
    public var retailShopCategoryList:[ShopCategory] = []
    public var serviceShopCategoryList:[ShopCategory] = []
    
    public class ShopCategory:NSObject {
        var key:String!
        var name:String!
        
        init(key:String, name:String) {
            self.key = key
            self.name = name
        }
    }

    
    private override init() {

    }
    
    public func update() -> Result<Any?, Error> {
        let file = "OrosyAppConfig.json"
        //  jsonファイルをサーバから取得
        let url = URL(string: EXT_S3_SOURCE_BASE_URL + "/" + file)
        do {
            let jsonData: Data? = try Data(contentsOf: url!)
            config = try JSONSerialization.jsonObject(with: jsonData!, options: []) as?  [String:Any]
            
            makeecShopCategoryList()
            
            return .success(nil)
            
        }catch{
            print(error.localizedDescription)
            config = [:]
            LogUtil.shared.errorLog(error: OrosyError.DoesNotExistS3FIle(file))
            return .failure(OrosyError.DoesNotExistS3FIle(file))
        }
    }
    
    //  実店舗 （retailかserviceかに応じてカテゴリ名を返す）
    public func getNameFromShopKey(retail:Bool,key:String) -> String {
        
        let shopList = (retail) ? retailShopCategoryList : serviceShopCategoryList
        for cat in shopList {
            if cat.key == key {
                return cat.name
            }
        }
        return ""
    }
    
    // EC
    public func getNameFromECKey(key:String) -> String {
        
        for cat in ecShopCategoryList {
            if cat.key == key {
                return cat.name
            }
        }
        return ""
    }
    
    private func makeecShopCategoryList() {
        if let catList = config?["EcCategory"] as? [[String:String]] {
            var tempArray:[ShopCategory] = []
            
            for cat in catList {
                if cat.keys.contains("key") && cat.keys.contains("name") {
                    tempArray.append(ShopCategory(key:cat["key"] ?? "",name:cat["name"] ?? ""))
                }
            }
            ecShopCategoryList = tempArray
        }
        //
        if let shopCategory = config?["ShopCategory"] as? [[String:Any]] {
        
            for shop in shopCategory {
                
                if (shop["key"] as? String ?? "") == "retail" {
                    if let catList = shop["subItems"] as? [[String:String]] {
                        var tempArray:[ShopCategory] = []
                        
                        for cat in catList {
                            if cat.keys.contains("key") && cat.keys.contains("name") {
                                tempArray.append(ShopCategory(key:cat["key"] ?? "",name:cat["name"] ?? ""))
                            }
                        }
                        retailShopCategoryList = tempArray
                    }
                }
                if (shop["key"] as? String ?? "") == "service" {
                    //
                    if let catList = shop["subItems"] as? [[String:String]] {
                        var tempArray:[ShopCategory] = []
                        
                        for cat in catList {
                            if cat.keys.contains("key") && cat.keys.contains("name") {
                                tempArray.append(ShopCategory(key:cat["key"] ?? "",name:cat["name"] ?? ""))
                            }
                        }
                        serviceShopCategoryList = tempArray
                    }
                }
            }
        }
    }
}
 

// MARK: キーチェイン
final class KeyChainManager:NSObject {
    
    enum KeyChainId:String{
        case loginId = "loginId"
        case password = "password"
    }
    
    private let key = "orosy-retailer"
    
    public static let shared = KeyChainManager()
    
    private override init() { }
    
    public func save(id:KeyChainId, value: String) {

        guard let data = value.data(using: .utf8) else {
            return
        }
        
        let query: [String: Any] = [
            kSecClass              as String: kSecClassGenericPassword,
            kSecAttrService        as String: key,
            kSecAttrAccount        as String: id.rawValue,
            kSecValueData          as String: data,
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        var itemUpdateStatus: OSStatus?
        
        print(status)

        switch status {
        case errSecItemNotFound:
            itemUpdateStatus = SecItemAdd(query as CFDictionary, nil)

        case errSecSuccess:
            itemUpdateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)

        default:
            print("該当なし")
        }
        
        if itemUpdateStatus == errSecSuccess {
            LogUtil.shared.log("Keychainへ保存")
        } else {
            LogUtil.shared.log("Keychainへ保存失敗")
        }

    }

    public func load(id:KeyChainId) -> String? {

         let query: [String: Any] = [
             kSecClass              as String: kSecClassGenericPassword,
             kSecAttrService        as String: key,
             kSecAttrAccount        as String: id.rawValue,
             kSecMatchLimit         as String: kSecMatchLimitOne,
             kSecReturnAttributes   as String: true,
             kSecReturnData         as String: true,
         ]
             
         var item: CFTypeRef?
         let status = SecItemCopyMatching(query as CFDictionary, &item)
         switch status {
         case errSecItemNotFound:
             return nil
         case errSecSuccess:
             guard let item = item,
                   let value = item[kSecValueData as String] as? Data else {
                       print("データなし")
                       return nil
                   }
             guard let loadString = String(data: value, encoding: .utf8) else {
                 return nil
             }
             return loadString
         default:
             print("該当なし")
         }
         return nil
     }
}




// MARK: -------------------------------------
//  MARK: 住所

class Address:NSObject {
    var postalCode:String = ""
    var prefecture:Prefecture?
    var city:String = ""
    var cityKana:String = ""
    var town:String = ""
    var townKana:String = ""
    var apartment:String = ""
    var apartmentKana:String = ""
    var concatinated:String {    // 建物名を含む住所　建物名の前で改行
        get {
            var conc = (prefecture?.name ?? "") + city + town

            if apartment.count > 0 {
                conc = conc + "\n" + apartment   // 建物名の前に改行コードに置き換えて出力する
            }
            return conc
        }
        
    }
    var hasDone:Bool {
        get {
            if postalCode.count != 0 && city.count != 0 && town.count != 0 && (prefecture?.name ?? "").count != 0 {
                return true
            }else{
                return false
            }
        }
        
    }
    init(_ _input_dic:[String:Any]? ) {
        super.init()
        
        if let input_dic = _input_dic {
            postalCode = input_dic["postalCode"] as? String ?? ""
            prefecture = Prefecture(input_dic["prefecture"] as? [String:String])
            city = input_dic["city"] as? String ?? ""
            cityKana = input_dic["cityKana"] as? String ?? ""
            town = input_dic["town"] as? String ?? ""
            townKana = input_dic["townKana"] as? String ?? ""
            apartment = input_dic["apartment"] as? String ?? ""
            apartmentKana = input_dic["apartmentKana"] as? String ?? ""
            /*
            concatinated = (prefecture?.name ?? "") + city + town
            if apartment.count > 0 {
                concatinated = concatinated + "\n" + apartment   // 建物名の前に改行コードに置き換えて出力する
            }
             */
        }
    }
    
    func copy() -> Address {
        
        let newAddress = Address([:])
        newAddress.postalCode = self.postalCode
        newAddress.prefecture = self.prefecture
        newAddress.city = self.city
        newAddress.cityKana = self.cityKana
        newAddress.town = self.town
        newAddress.townKana = self.townKana
        newAddress.apartment = self.apartment
        newAddress.apartmentKana = self.apartmentKana
        //newAddress.concatinated = self.concatinated
        
        return newAddress
    }
    
    class func getAllPrefecture() -> [Prefecture] {
       [
        Prefecture(id: "hokkaido", name: "北海道", kana: "ﾎｯｶｲﾄﾞｳ" ),
        Prefecture(id: "aomori", name: "青森県", kana: "ｱｵﾓﾘｹﾝ" ),
        Prefecture(id: "iwate", name: "岩手県", kana: "ｲﾜﾃｹﾝ" ),
        Prefecture(id: "miyagi", name: "宮城県", kana: "ﾐﾔｷﾞｹﾝ" ),
        Prefecture(id: "akita", name: "秋田県", kana: "ｱｷﾀｹﾝ" ),
        Prefecture(id: "yamagata", name: "山形県", kana: "ﾔﾏｶﾞﾀｹﾝ" ),
        Prefecture(id: "fukushima", name: "福島県", kana: "ﾌｸｼﾏｹﾝ" ),
        Prefecture(id: "ibaraki", name: "茨城県", kana: "ｲﾊﾞﾗｷｹﾝ" ),
        Prefecture(id: "tochigi", name: "栃木県", kana: "ﾄﾁｷﾞｹﾝ" ),
        Prefecture(id: "gunma", name: "群馬県", kana: "ｸﾞﾝﾏｹﾝ" ),
        Prefecture(id: "saitama", name: "埼玉県", kana: "ｻｲﾀﾏｹﾝ" ),
        Prefecture(id: "chiba", name: "千葉県", kana: "ﾁﾊﾞｹﾝ" ),
        Prefecture(id: "tokyo", name: "東京都", kana: "ﾄｳｷｮｳﾄ" ),
        Prefecture(id: "kanagawa", name: "神奈川県", kana: "ｶﾅｶﾞﾜｹﾝ" ),
        Prefecture(id: "niigata", name: "新潟県", kana: "ﾆｲｶﾞﾀｹﾝ" ),
        Prefecture(id: "toyama", name: "富山県", kana: "ﾄﾔﾏｹﾝ" ),
        Prefecture(id: "ishikawa", name: "石川県", kana: "ｲｼｶﾜｹﾝ" ),
        Prefecture(id: "fukui", name: "福井県", kana: "ﾌｸｲｹﾝ" ),
        Prefecture(id: "yamanashi", name: "山梨県", kana: "ﾔﾏﾅｼｹﾝ" ),
        Prefecture(id: "nagano", name: "長野県", kana: "ﾅｶﾞﾉｹﾝ" ),
        Prefecture(id: "gifu", name: "岐阜県", kana: "ｷﾞﾌｹﾝ" ),
        Prefecture(id: "shizuoka", name: "静岡県", kana: "ｼｽﾞｵｶｹﾝ" ),
        Prefecture(id: "aichi", name: "愛知県", kana: "ｱｲﾁｹﾝ" ),
        Prefecture(id: "mie", name: "三重県", kana: "ﾐｴｹﾝ" ),
        Prefecture(id: "shiga", name: "滋賀県", kana: "ｼｶﾞｹﾝ" ),
        Prefecture(id: "kyoto", name: "京都府", kana: "ｷｮｳﾄﾌ" ),
        Prefecture(id: "osaka", name: "大阪府", kana: "ｵｵｻｶﾌ" ),
        Prefecture(id: "hyogo", name: "兵庫県", kana: "ﾋｮｳｺﾞｹﾝ" ),
        Prefecture(id: "nara", name: "奈良県", kana: "ﾅﾗｹﾝ" ),
        Prefecture(id: "wakayama", name: "和歌山県", kana: "ﾜｶﾔﾏｹﾝ" ),
        Prefecture(id: "tottori", name: "鳥取県", kana: "ﾄｯﾄﾘｹﾝ" ),
        Prefecture(id: "shimane", name: "島根県", kana: "ｼﾏﾈｹﾝ" ),
        Prefecture(id: "oakayama", name: "岡山県", kana: "ｵｶﾔﾏｹﾝ" ),
        Prefecture(id: "hiroshima", name: "広島県", kana: "ﾋﾛｼﾏｹﾝ" ),
        Prefecture(id: "yamaguchi", name: "山口県", kana: "ﾔﾏｸﾞﾁｹﾝ" ),
        Prefecture(id: "tokushima", name: "徳島県", kana: "ﾄｸｼﾏｹﾝ" ),
        Prefecture(id: "kagawa", name: "香川県", kana: "ｶｶﾞﾜｹﾝ" ),
        Prefecture(id: "ehime", name: "愛媛県", kana: "ｴﾋﾒｹﾝ" ),
        Prefecture(id: "kochi", name: "高知県", kana: "ｺｳﾁｹﾝ" ),
        Prefecture(id: "fukuoka", name: "福岡県", kana: "ﾌｸｵｶｹﾝ" ),
        Prefecture(id: "saga", name: "佐賀県", kana: "ｻｶﾞｹﾝ" ),
        Prefecture(id: "nagasaki", name: "長崎県", kana: "ﾅｶﾞｻｷｹﾝ" ),
        Prefecture(id: "kumamoto", name: "熊本県", kana: "ｸﾏﾓﾄｹﾝ" ),
        Prefecture(id: "oita", name: "大分県", kana: "ｵｵｲﾀｹﾝ" ),
        Prefecture(id: "miyazaki", name: "宮崎県", kana: "ﾐﾔｻﾞｷｹﾝ" ),
        Prefecture(id: "kagoshima", name: "鹿児島県", kana: "ｶｺﾞｼﾏｹﾝ" ),
        Prefecture(id: "okinawa", name: "沖縄県", kana: "ｵｷﾅﾜｹﾝ" )
      ]
    }
}

// 都道府県
class Prefecture:NSObject {
    var id:String = ""
    var kana:String = ""
    var name:String = ""

    init?(_ _input_dic:[String:Any]? ) {
        
        super.init()
        
        if let input_dic = _input_dic {
            id = input_dic["id"] as? String ?? ""
            kana = input_dic["kana"] as? String ?? ""
            name = input_dic["name"] as? String ?? ""

        }else{
            return nil
        }
    }
    
    init(id:String, name:String, kana:String ) {
        self.id = id
        self.name = name
        self.kana = kana
    }
}


// MARK: ============================

class PostCode:NSObject {
    
   class func getAddress(postCode:String, completion: @escaping (_ value :  [String:String]? )-> Void) {
        
        var urlString = "https://zipcloud.ibsnet.co.jp/api/search?zipcode=" + postCode
        
        if let url = URLComponents(string: urlString) {
            
            // HTTPメソッドを実行
            var request = URLRequest(url: url.url!)
            request.httpMethod = "POST"
            request.timeoutInterval = 600
            
            let configuration = URLSessionConfiguration.default
            configuration.httpCookieStorage = nil
            configuration.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
            if #available(iOS 11.0, *) {
               configuration.waitsForConnectivity = false
            }

            let session = URLSession(configuration: configuration)

            let task = session.dataTask(with: request) { data, response, error in
                
                if (error != nil) {
                    print(error!.localizedDescription)      // タイムアウトになると、ここでエラーになる
                    completion(nil)
                    return
                }
                guard let _data = data else { completion(nil); return }
                // JSONデコード
                do {
                    let metaDic = try JSONSerialization.jsonObject(with: _data, options: []) as!  [String:Any]
                    print(metaDic)
                    if let status = metaDic["status"] as? Int {
                        if status == 200 {
                            if let addrDics = metaDic["results"] as? [[String:String]] {
                                if addrDics.count > 0 {
                                    let addrDic = addrDics.first
                                    
                                    completion(addrDic)
                                }
                            }
                        }
                    }
                    completion(nil)

                } catch {
                    print(error.localizedDescription)
                    completion(nil)
                }
            }
            task.resume()
        }
    }
}

class OGPFetcher:NSObject {

    var image:URL?
    var site_name:String?
    var favicon:URL?

    let targetTags = ["site_name", "image"]
    
    func get(targetURL:String) -> Bool {
        
        if let url = URL(string:targetURL) {
            var baseUrl = url.baseURL
            if baseUrl == nil { baseUrl = url }
            var baseUrlStr = (baseUrl?.absoluteString ?? "")
            if baseUrlStr.hasSuffix("/") {
                baseUrlStr = String(baseUrlStr.dropLast())
            }
            
            do {
                let sourceHTML: String = try String(contentsOf: url, encoding: String.Encoding.utf8);
                let result = parseOGP(htmlString: sourceHTML)
                if var urlStr = result["image"] {
                    if !urlStr.contains("http") {
                        urlStr = (baseUrlStr) + urlStr
                    }
                    self.image = URL(string: urlStr)
                }
                if let name = result["site_name"] {
                    self.site_name = name
                }
                
                if var urlStr = parseFavicon(htmlString: sourceHTML) {
                    if !urlStr.contains("http") {
                        urlStr = (baseUrlStr) + urlStr
                    }
                    self.favicon = URL(string:urlStr )
                }
                
                if self.image != nil { return true }else{ return false }

            }catch{
                return false
            }
        }
        return false
    }
    
    func parseOGP(htmlString: String) -> [String: String] {
        
        var resoruces:[String:String] = [:]
        
        // extract meta tag
        let metatagRegex  = try! NSRegularExpression(
            pattern: "<meta(?:\".*?\"|\'.*?\'|[^\'\"])*?>",
            options: [.dotMatchesLineSeparators]
        )

        let propertyRegexp = try! NSRegularExpression(
            pattern: "\\sproperty=(?:\"|\')*og:([a-zA_Z:]+)(?:\"|\')*",
            options: []
        )
        
        let contentRegexp = try! NSRegularExpression(
            pattern: "\\scontent=\\\\*?\"(.*?)\\\\*?\"",
            options: []
        )

        // fetch meta tags
        let metaTagMatches = metatagRegex.matches(in: htmlString,
                                       options: [],
                                       range: NSMakeRange(0, htmlString.count))
        if metaTagMatches.isEmpty {
            return [:]
        }
        
        for result in metaTagMatches {
            
            let start = htmlString.index(htmlString.startIndex, offsetBy: result.range(at: 0).location)
            let end = htmlString.index(start, offsetBy: result.range(at: 0).length)
            let metaText = String(htmlString[start..<end])
            
            // extract ogp tag
            let propertyMatches = propertyRegexp.matches(in: metaText, options: [], range: NSMakeRange(0, metaText.count))
            if propertyMatches.isEmpty {
                continue
            }
            // find ogp tags
            for result in propertyMatches {

                let startOGP = metaText.index(htmlString.startIndex, offsetBy: result.range(at: 1).location)
                let endOGP = metaText.index(startOGP, offsetBy: result.range(at: 1).length)
                let ogpText = String(metaText[startOGP..<endOGP])

                if let _ = targetTags.firstIndex(of:ogpText) {
                    // find target ogp tag
                    print("ogp Tag:\(ogpText)")
                    
                    let contentMatches = contentRegexp.matches(in: metaText, options: [], range: NSMakeRange(0, metaText.count))
                    if contentMatches.isEmpty {
                        continue
                    }
                    for result in contentMatches {

                        let startContent = metaText.index(metaText.startIndex, offsetBy: result.range(at: 1).location)
                        let endContent = metaText.index(startContent, offsetBy: result.range(at: 1).length)
                        let contentText = String(metaText[startContent..<endContent])
                        print("ogp content:\(contentText)")
                        
                        resoruces[ogpText] = contentText
                    }
                }
            }
        }
        return resoruces
    }
    
    func parseFavicon(htmlString: String) -> String? {
        
        var favicon:String?
        
        // extract meta tag
        let metatagRegex  = try! NSRegularExpression(
            pattern: "<link(?:\".*?\"|\'.*?\'|[^\'\"])*?>",
            options: [.dotMatchesLineSeparators]
        )

        let propertyRegexp = try! NSRegularExpression(
            pattern: "\\srel=(?:\"|\')*([a-zA_Z:]+)(?:\"|\')*",
            options: []
        )
        
        let contentRegexp = try! NSRegularExpression(
            pattern: "\\shref=\\\\*?\"(.*?)\\\\*?\"",
            options: []
        )

        // fetch meta tags
        let metaTagMatches = metatagRegex.matches(in: htmlString,
                                       options: [],
                                       range: NSMakeRange(0, htmlString.count))
        if metaTagMatches.isEmpty {
            return ""
        }
        
        for result in metaTagMatches {
            
            let start = htmlString.index(htmlString.startIndex, offsetBy: result.range(at: 0).location)
            let end = htmlString.index(start, offsetBy: result.range(at: 0).length)
            let metaText = String(htmlString[start..<end])
            
            // extract tag
            let propertyMatches = propertyRegexp.matches(in: metaText, options: [], range: NSMakeRange(0, metaText.count))
            if propertyMatches.isEmpty {
                continue
            }
            // find tags
            for result in propertyMatches {

                let startOGP = metaText.index(htmlString.startIndex, offsetBy: result.range(at: 1).location)
                let endOGP = metaText.index(startOGP, offsetBy: result.range(at: 1).length)
                let ogpText = String(metaText[startOGP..<endOGP])

                if ogpText == "icon" {
                    // find target ogp tag
                    print("favicon Tag:\(ogpText)")
                    
                    let contentMatches = contentRegexp.matches(in: metaText, options: [], range: NSMakeRange(0, metaText.count))
                    if contentMatches.isEmpty {
                        continue
                    }
                    for result in contentMatches {

                        let startContent = metaText.index(metaText.startIndex, offsetBy: result.range(at: 1).location)
                        let endContent = metaText.index(startContent, offsetBy: result.range(at: 1).length)
                        let contentText = String(metaText[startContent..<endContent])
                        print("ogp content:\(contentText)")
                        
                        favicon = contentText
                        break
                    }
                }
            }
        }
        return favicon
    }
}

//==============
// MARK: ImageCacheObject
class ImageCacheObject: NSObject {
    var taskS200:DownloadTask?
    var taskS100:DownloadTask?
    var productsTask:[DownloadTask] = []
    
    func cacheImageForSuppilerPrefetch(supplier:Supplier) {
        
        taskS200 = OrosyAPI.cacheImage(supplier.imageUrls.first, imagesize: .Size200)
        taskS100 = OrosyAPI.cacheImage(supplier.iconImageUrl, imagesize: .Size100)
        
        for ip in 0..<4 {
            if ip < supplier.imageUrls.count - 1 {
                let url  = supplier.imageUrls[ip + 1]
                if let downloadTask = OrosyAPI.cacheImage(url, imagesize: .Size200) {
                    productsTask.append(downloadTask)
                }
            }
        }
    }
    
    func cancelTask() {
        if let task = taskS200 {
            task.cancel()
        }
        if let  task = taskS100 {
            task.cancel()
        }
        for task in productsTask {
            task.cancel()
        }
    }
}
