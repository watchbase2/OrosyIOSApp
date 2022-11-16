//
//  SubscriptionManager.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/12/19.
//
// サブスクリプションでメッセージを受信する機能
//　メッセージを受信したら以下の処理を行っている
//      MesaageVC　で表示するよう、delegateで通知
//      ローカル通知機能で通知

import UIKit
import UserNotifications

protocol SubscriptionReceivedDelegate: AnyObject {
    func messageReceived(message:Message)
    
}


final class SubscriptionManager:NSObject , MessageUpdateDelegate {
    
    public static let shared = SubscriptionManager()
    
    var delegate:SubscriptionReceivedDelegate? = nil
    var subscription:Subscription? = nil
        
    private override init() {
        
    }
    
    
    func startSubscription() -> Result< Any?, OrosyError> {

        LogUtil.shared.log("サブスクリプション開始")
        
        let enc = NotificationCenter.default
        enc.addObserver(self, selector: #selector(reset), name: Notification.Name(rawValue:NotificationMessage.Reset.rawValue), object: nil)
        
        if let myId = g_MyId {
            // サブスクリプションを開始
            subscription = Subscription()
            
            if let sub = subscription {
                sub.delegate = self
                print("Subscription setup done")
                let result = sub.startSubscription(userId:myId)
                return result
            }else{
                return .failure(OrosyError.SubscriptionError)
            }
        }else{
            return .failure(OrosyError.NotSignedIn)
        }
    }

    @objc func reset() {
        LogUtil.shared.log("サブスクリプション　リセット")
        stopSubscription()
        subscription = nil
    }
    
    // Subscriptionで受信したメッセージを受け取るdelegate
    func messageUpdate(message:Message) {

        DispatchQueue.main.async {
            if  g_currentViewController is MessageVC {
                // メッセージタブを開いている
                // メッセージ一覧のVCヘ通知
                if let sub = self.delegate{
                    sub.messageReceived(message:message)
                }
                
            }else{
                // 他のタブを開いている
                if let supplier = Supplier(supplierId: message.sendBy, size:10) {
                    if supplier.brandName == nil {
                        print("null")
                    }else{
                        // ローカル通知ポップアップ
                        g_localNotificationManager.setAppNotification(title:"Orosyからのお知らせ", body:"\(supplier.brandName ?? "サプライヤ")様からのメッセージを受信しました", userInfo:["Action":"MessageVC", "SupplierId":supplier.id])
                    }
                    let refresh = Notification.Name(NotificationMessage.ReveicedThreadMessage.rawValue)  // データ更新を依頼
                    NotificationCenter.default.post(name: refresh, object: nil)
                }
            }
        }
    }
    
    
    func stopSubscription() {
        // サブスクリプションをキャンセルする
        LogUtil.shared.log("サブスクリプション　ストップ")
        if let sub = subscription {
            sub.stopSubscription()
            subscription = nil
        }
    }
}

