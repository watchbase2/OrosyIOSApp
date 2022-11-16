//
//  ActionNotification.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/04/14.
//
// s3から設定ファイルを取得

import Foundation
import UIKit
import SafariServices

enum ActionCode:String {
    case versionUp = "version_up"
    case popupMessage = "popup_message"
}

enum ActionCondition:String {
    case appVersionLT = "app_version_LT"
    case appVersionGT = "app_version_GT"
    case appVersionEQ = "app_version_EQ"
    case one_time     = "one_time"
    case userID       = "user_id"
    case lastDateLT   = "last_date_LT"
    case lastDateGT   = "last_date_GT"
    case none = ""
}

enum ActionRestriction:String {
    case lockout = "lockout"
    
}

// MARK: アプリ通知

protocol AppNotificationControllerDelegate: AnyObject {
    func showAppStore()
}


// S3からアップデートなどのアクション情報を取得
final public class AppNotification:NSObject, ConfirmControllerDelegate {

    public static let shared = AppNotification()
    
    var requestedActions:[ActionData] = []
    var selectedNotificationAction:ActionData!
    var delegate:AppNotificationControllerDelegate!
    var pendingAction:ActionData?
    
    override private init() {}
    
    public func checkActionData()  {
        
        DispatchQueue.global().async {
            let file = "ActionRequest.json"
            //  jsonファイルをサーバから取得
            let url = URL(string: EXT_S3_SOURCE_BASE_URL + "/" + file)
            do {
                let jsonData: Data? = try Data(contentsOf: url!)
                let dicArray = try JSONSerialization.jsonObject(with: jsonData!, options: []) as?  [[String:Any]] ?? []
                
                var tempArray:[ActionData] = []
                
                for dic in dicArray {
                    if let act = ActionData(dic) {
                        tempArray.append(act)
                    }
                }
                self.requestedActions = tempArray
                
                self.appExecute()
                
                return
                
            }catch{
                return
            }
        }

    }
    
 
    // 指定されたアクションを実行する
    public func appExecute()
    {
        var tempArray:[ActionData] = []
        
        for action in requestedActions {
            
            selectedNotificationAction = action
            
            switch action.actionCode {
            case .versionUp:
                if let _ = getTopViewController() {
                    if checkCondition(action) {         // 実行が必要な条件がある
                        showNoticication(action)
                    }
                }else{
                    tempArray.append(action)    // 実行できなかったので戻す
                }
                
            case .popupMessage:
                if let _ = getTopViewController() {
                    if checkCondition(action) {         // 実行が必要な条件がある
                        showNoticication(action)
                    }
                }else{
                    tempArray.append(action)    // 実行できなかったので戻す
                }
   
            default:
                break
            }
        }
        requestedActions = tempArray

    }

    // 実行判定条件の評価
    // 複数条件はANDとして判定する。条件が指定されていない場合は　trueを返す（つまり実行を許可する）
    //　不正な条件が指定されている場合は、falseを返す
    func checkCondition(_ action:ActionData) -> Bool {
        
        var exec = true

     //   if let _ = getTopViewController() {
            let appVersion = Util.getAppVersion()
            
            for cond in action.conditions {
                    
                switch cond.condition {
                    
                case .appVersionLT:
                    if !(appVersion < cond.value ?? "0") { exec = false }
                case .appVersionGT:
                    if !(appVersion > cond.value ?? "0") { exec = false }
                case .appVersionEQ:
                    if !(appVersion == cond.value ?? "0") { exec = false }
                case .userID:
                    if ((g_MyId ?? "") != cond.value ?? "") { exec = false }
                case .one_time:
                    if  let flag = cond.value {
                        let sel = UserDefaultsManager.shared.actionFlags[flag]
                        if sel == nil {
                            UserDefaultsManager.shared.actionFlags[flag] = "done"   // 実行済みフラグをセット　nilかどうかで判定しているので セットする文字列はなんでも良い
                            UserDefaultsManager.shared.updateUserData()
                        }else{
                            exec = false
                        }
                    }

                default:
                    exec = false
                    break
                }
            }
    //    }
        
        return exec
    }
    
    var dialogVC:UIViewController!
    
    //true: 完了　top Viewが TbaControllerの場合には、まだビューの準備ができていないので、falseを返す
    func showNoticication(_ action:ActionData){
        
        if dialogVC != nil {
            return                  // ダイアログ表示中は何もしない
        }

        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "AlertSB", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ConfirmVC") as! ConfirmVC
            
            vc.image = action.image
            vc.message_title = action.title ?? ""
            vc.message_body = action.message ?? ""
            vc.mainButtonTitle = action.mainButtonTitle
            vc.cancelButtonTitle = action.cancelButtonTitle     //  nilの場合にはキャンセルボタンは表示されない
            vc.delegate = self
            // rock outを指定した場合には、キャンセルボタンを非表示にし、また画面のプルダウンでもキャンセルできないようにする
            if action.restriction == .lockout {
                vc.isModalInPresentation = true
                vc.cancelButtonTitle = nil
            }
            
            self.dialogVC = vc
            
            if let topController = self.getTopViewController() {
                topController.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func getTopViewController() -> UIViewController? {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var topController: UIViewController = appDelegate.window!.rootViewController!
        while (topController.presentedViewController != nil) {
            topController = topController.presentedViewController!
        }

        if topController is LoginVC {
            return nil
        }
        return topController
    }
    
    func selectedAction(sel: Bool) {

        dialogVC = nil     // ダイアログがクローズされた
        
        switch selectedNotificationAction.actionCode {
        case .versionUp:
                
            if sel {
                // App Storeでアプリのページを開く
                UIApplication.shared.open(URL(string: OrosyAppStoreUrl)!, options: [:], completionHandler: nil)
            }else{
                // キャンセルした
                if selectedNotificationAction.restriction == .lockout {
                    // ロックアウトする
                }else{
                    dialogVC.dismiss(animated: true, completion: nil)   // ダイアログを閉じる
                    dialogVC = nil
                }
            }
        case .popupMessage:
            // メッセージを表示するだけなのでこれで終わり
            break
        default:
            break
        }
    }
}


public class ActionData:NSObject {
    var index:Int = -1
    var actionCode:ActionCode?
    var target:String?
    var conditions:[ConditionData] = []
    var value:Any?
    var image:UIImage?
    var title:String?
    var message:String?
    var restriction:ActionRestriction?
    var mainButtonTitle:String?
    var cancelButtonTitle:String?
    
    init?(_ dic:[String:Any]) {

        self.actionCode = ActionCode(rawValue: dic["action"] as? String ?? "" )
        self.target = dic["target"] as? String
        
        var tempArray:[ConditionData] = []
        let dicArray = dic["conditions"] as? [[String:String]] ?? []
        for dic in dicArray {
            if let cnd = ConditionData(dic) {
                tempArray.append(cnd)
            }
        }
        self.conditions = tempArray
        
        if var imageUrl = dic["imageUrl"] as? String {
            do {
                if !imageUrl.contains("http") {     // ファイル名だけの場合は、s3のパスを追加する
                    imageUrl = EXT_S3_SOURCE_BASE_URL + "/" + imageUrl
                }
                if let url = URL(string: imageUrl) {
                    let imageData: Data? = try Data(contentsOf:url )
                    if let data = imageData {
                        self.image = UIImage(data: data)
                    }
                }
            }
            catch {

            }
        }
        self.title = dic["title"] as? String
        self.value = dic["value"] as? String
        self.message = dic["message"] as? String
        self.restriction = ActionRestriction(rawValue: dic["restriction"] as? String ?? "" )
        
        self.mainButtonTitle =  dic["mainButtonTitle"] as? String
        self.cancelButtonTitle =  dic["cancelButtonTitle"] as? String
    }
}

class ConditionData:NSObject {
    var condition:ActionCondition?
    var value:String?
    
    init?(_ dic:[String:Any]) {
        condition = ActionCondition(rawValue: dic["condition"] as? String ?? "") ?? ActionCondition.none
        value = dic["value"] as? String ?? ""
    }
}
