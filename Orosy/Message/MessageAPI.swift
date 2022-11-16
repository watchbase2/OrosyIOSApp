//
//  Message.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/20.
//

import Foundation
import Amplify

// MARK: -------------------------------------
// MARK: メッセージ

enum MediaType:String {
    case text = "text/plain"
    case imagePng = "image/png"
    case imageJpeg = "image/jpeg"
    case none = ""
}

enum SendStatus {
    case Requested
    case Finished
    case Error
    case None
}

class Message:NSObject {
    var mediaType:MediaType = .text
    var sendBy:String?
    var text:String?
    var url:URL?
    var timestamp:Date?
    var threadId:String?
    var status:SendStatus = .None

    override init() {
        super.init()
    }
    
    init?(_ _input_dic:[String:Any]? ) {
        if let input_dic = _input_dic {

            mediaType = MediaType.init( rawValue: input_dic["mediaType"] as? String ?? "") ?? .none
            sendBy = input_dic["sendBy"] as? String ?? ""
            text = input_dic["text"] as? String ?? ""
            url = URL(string: input_dic["url"] as? String ?? "")
            timestamp = Util.dateFromUTCString(input_dic["timestamp"] as? String)
            threadId = input_dic["threadId"] as? String ?? ""

        }else{
            return nil
        }
    }

}


class MessageList:NSObject {
    
    var messages:[Message] = []
    var nextToken:String?
    var size:Int = 10
    var userId:String = ""


    init?(size:Int, userId:String ) {
        super.init()
        
        self.size = size
        self.userId = userId
        
        _ = getNext(firstTime:true)
    }

    public func getNext() -> (Result<[Message], Error>) {
        
        return  getNext(firstTime: false)
        
    }

    // コールするたびに、次のレコードを返す
    private func getNext(firstTime:Bool) -> ( Result<[Message], Error> ) {

        let graphql = """
        query getMessages($userId: String!, $limit: Int, $nextToken: String) {
          getMessages(userId: $userId, limit: $limit, nextToken: $nextToken) {
                    messages {
                        mediaType
                        sendBy
                        text
                        url
                        timestamp
                        threadId
                    }
                    nextToken
                }
            }
        """

        let limit = self.size

        var tempArray:[Message] = []

        var paramDic:[String:Any]!
        
        
        if firstTime {
            paramDic = ["userId":userId, "limit":limit]
        }else{
            if nextToken == nil {
                return .success([])
            }
            paramDic = ["userId":userId, "limit":limit, "nextToken":nextToken!]
            
        }

        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        
        switch result {
        case .success(let resultDic) :
            if let result = resultDic["getMessages"] as? [String:Any] {
                nextToken = result["nextToken"] as? String
                if let items = result["messages"] as? [[String:Any]] {

                     for dic in items {
                        if let item =  Message(dic) {
                           // tempArray.insert(item, at: 0) //　逆順にソート
                            tempArray.append(item)
                        }
                    }
                }
            }
        case .failure(let error):
            nextToken = nil
            return .failure(error)
        }
        
        messages.append(contentsOf:tempArray)

        return .success(tempArray)    // 新規に取得できた分だけを返す
    }


    public func sendMessage(message:String, type:MediaType, receiver:String) -> Result<Message?, OrosyError> {
        
        var graphql =
        """
        mutation createMessage {
          createMessage(input: {mediaType: $mediaType, text: $message, userId: $receiver})
          {
            sendBy
            text
            threadId
            timestamp
            url
            userId
            mediaType
          }
        }
        """
        
        graphql = graphql.replacingOccurrences(of: "$mediaType", with: "\"\(type.rawValue)\"" )
        graphql = graphql.replacingOccurrences(of: "$message", with: "\"\(message)\"" )
        graphql = graphql.replacingOccurrences(of: "$receiver", with: "\"\(receiver)\"" )
  
    
        let result = OrosyAPI.callSyncAPI(graphql)
        switch result {
        case .success(let resultDic):
            let message = Message(resultDic["createMessage"] as? [String:Any])
            return .success(message)

        case .failure(let error):
            return .failure(OrosyError.UnknownErrorWithMessage(error.localizedDescription))
        }
        
    }
    
    public func addMessage(_ newMessage:Message) {
        messages.insert(newMessage, at: 0)

    }
 }

 // 指定した相手との送受信メッセージを取得
 protocol MessageUpdateDelegate: AnyObject {
     func messageUpdate(message:Message)
 }

// メッセージのリアルタイム受信
class Subscription:NSObject {

    private var onCreateMessageByMyself:GraphQLSubscriptionOperation<String>?
    private var onCreateMessageByPartner:GraphQLSubscriptionOperation<String>?
    private var onSendDataUploadNotificationByMyself:GraphQLSubscriptionOperation<String>?
    private var onSendDataUploadNotificationByPartner:GraphQLSubscriptionOperation<String>?

    var delegate:MessageUpdateDelegate? = nil

    // サブスクリプションを停止
    public func stopSubscription() {
        onCreateMessageByMyself?.cancel()
        onSendDataUploadNotificationByPartner?.cancel()
    }

    // サブスクリプション設定
    public func startSubscription(userId:String) -> Result<Any?, OrosyError> {
    
        stopSubscription()
        
    // 4種類登録する
        
        let semaphore = DispatchSemaphore(value: 0)
        // onCreateMessageByMyself  自身が送信したテキストメッセージを受信する
        var graphql = """
            subscription onCreateMessageByMyself {
                onCreateMessage(sendBy: $sendBy, mediaType: "text/plain") {
                    threadId
                    timestamp
                    mediaType
                    userId
                    sendBy
                    text
                    url
                }
            }
        """
        
       graphql = graphql.replacingOccurrences(of: "$sendBy", with: "\"\(userId)\"" )
        
        var req = GraphQLRequest(apiName: "OrosyAuthAPI", document: graphql, responseType: String.self)
        
        onCreateMessageByMyself = Amplify.API.subscribe(request: req, valueListener: { (subscriptionEvent) in
            
            switch subscriptionEvent {
            case .connection(let subscriptionConnectionState):
                print("Subscription connect state is \(subscriptionConnectionState)")
                semaphore.signal()
                
            case .data(let result):
                switch result {
                case .success(let message):
                    print("Successfully got message from subscription: \(message)")
                    if let jsondata = message.data(using: .utf8) {
                        do {
                            let messageDic =  try JSONSerialization.jsonObject(with: jsondata, options: []) as! [String:Any]
                            if let messageObj = Message(messageDic["onCreateMessage"] as? [String:Any]) {
                                // 自分が送信したものだけを追加する
                              //  if messageObj.sendBy == g_MyId {
                                    self.addMessage(messageObj)
                              //  }
                            }
                        }catch{
                            
                        }
                    }
                case .failure(let error):
                    print("Got failed result with \(error.errorDescription)")
                }
            }
        }) { result in
            switch result {
            case .success:
                print("Subscription has been closed successfully")
            case .failure(let apiError):
                print("Subscription has terminated with \(apiError)")
                
            }
            self.onCreateMessageByMyself = nil
            semaphore.signal()
        }
        
        graphql = """
            subscription onSendDataUploadNotificationByMyself {
                onSendDataUploadNotification(sendBy: $sendBy) {
                    threadId
                    timestamp
                    mediaType
                    userId
                    sendBy
                    url
                }
            }
        """
        
        graphql = graphql.replacingOccurrences(of: "$sendBy", with: "\"\(userId)\"" )
        
        req = GraphQLRequest(apiName: "OrosyAuthAPI", document: graphql, responseType: String.self)
        
        onSendDataUploadNotificationByMyself = Amplify.API.subscribe(request: req, valueListener: { (subscriptionEvent) in
            
            switch subscriptionEvent {
            case .connection(let subscriptionConnectionState):
                print("Subscription connect state is \(subscriptionConnectionState)")
                semaphore.signal()
                
            case .data(let result):
                switch result {
                case .success(let message):
                    print("Successfully got message from subscription: \(message)")
                    if let jsondata = message.data(using: .utf8) {
                        do {
                            let messageDic =  try JSONSerialization.jsonObject(with: jsondata, options: []) as! [String:Any]
                            if let messageObj = Message(messageDic["onSendDataUploadNotification"] as? [String:Any]) {
                                // 自分が送信したものだけを追加する
                               // if messageObj.sendBy == g_MyId {
                                    self.addMessage(messageObj)
                               // }
                            }
                        }catch{
                            
                        }
                    }
                case .failure(let error):
                    print("Got failed result with \(error.errorDescription)")
                }
            }
        }) { result in

            switch result {
            case .success:
                print("Subscription has been closed successfully")
            case .failure(let apiError):
                print("Subscription has terminated with \(apiError)")
                
            }
            self.onSendDataUploadNotificationByMyself = nil
            semaphore.signal()
        }

        graphql = """
        subscription onCreateMessageByPartner {
            onCreateMessage(userId: $userId, mediaType: "text/plain") {
                threadId
                timestamp
                mediaType
                userId
                sendBy
                text
                url
            }
        }
        """

        graphql = graphql.replacingOccurrences(of: "$userId", with: "\"\(userId)\"" )
         
        req = GraphQLRequest(apiName: "OrosyAuthAPI", document: graphql, responseType: String.self)
         
        onCreateMessageByPartner = Amplify.API.subscribe(request: req, valueListener: { (subscriptionEvent) in
             
             switch subscriptionEvent {
             case .connection(let subscriptionConnectionState):
                 print("Subscription connect state is \(subscriptionConnectionState)")
                 semaphore.signal()
                 
             case .data(let result):
                 switch result {
                 case .success(let message):
                     print("Successfully got message from subscription: \(message)")
                     if let jsondata = message.data(using: .utf8) {
                         do {
                             let messageDic =  try JSONSerialization.jsonObject(with: jsondata, options: []) as! [String:Any]
                             if let messageObj = Message(messageDic["onCreateMessage"] as? [String:Any]) {
                                 // 現在開いているユーザに関するものだけを追加する --> 全て通知するように変更
                                 //if messageObj.sendBy == self.userId {
                                     self.addMessage(messageObj)
                                // }
                             }
                         }catch{
                             
                         }
                     }
                 case .failure(let error):
                     print("Got failed result with \(error.errorDescription)")
                 }
             }
         }) { result in
             switch result {
             case .success:
                 print("Subscription has been closed successfully")
             case .failure(let apiError):
                 print("Subscription has terminated with \(apiError)")
             }
             self.onCreateMessageByPartner = nil
             semaphore.signal()
         }

        // onSendDataUploadNotificationByPartner
        graphql = """
        subscription onSendDataUploadNotificationByPartner {
            onSendDataUploadNotification(userId: $userId)  {
                threadId
                timestamp
                mediaType
                userId
                sendBy
                url
            }
        }
        """

        graphql = graphql.replacingOccurrences(of: "$userId", with: "\"\(userId)\"" )
         
        req = GraphQLRequest(apiName: "OrosyAuthAPI", document: graphql, responseType: String.self)
         
        onSendDataUploadNotificationByPartner = Amplify.API.subscribe(request: req, valueListener: { (subscriptionEvent) in
             
             switch subscriptionEvent {
             case .connection(let subscriptionConnectionState):
                 print("Subscription connect state is \(subscriptionConnectionState)")
                 semaphore.signal()
                 
             case .data(let result):
                 switch result {
                 case .success(let message):
                     print("Successfully got message from subscription: \(message)")
                     if let jsondata = message.data(using: .utf8) {
                         do {
                             let messageDic =  try JSONSerialization.jsonObject(with: jsondata, options: []) as! [String:Any]
                             if let messageObj = Message(messageDic["onSendDataUploadNotification"] as? [String:Any]) {
                                 // 現在開いているユーザに関するものだけを追加する
                                // if messageObj.sendBy == self.userId {
                                     self.addMessage(messageObj)
                                // }
                             }
                         }catch{
                             
                         }
                     }
                 case .failure(let error):
                     print("Got failed result with \(error.errorDescription)")
                 }
             }
         }) { result in
             switch result {
             case .success:
                 print("Subscription has been closed successfully")
             case .failure(let apiError):
                 print("Subscription has terminated with \(apiError)")
             }
             self.onSendDataUploadNotificationByPartner = nil
             semaphore.signal()
         }
        
        _ = semaphore.wait(timeout: .now() + API_TIMEOUT)
        _ = semaphore.wait(timeout: .now() + API_TIMEOUT)
        _ = semaphore.wait(timeout: .now() + API_TIMEOUT)
        _ = semaphore.wait(timeout: .now() + API_TIMEOUT)
        
        if onCreateMessageByMyself == nil || onCreateMessageByPartner == nil || onSendDataUploadNotificationByMyself == nil || onSendDataUploadNotificationByPartner == nil {
            
            return .failure(OrosyError.API_TIMEOUT)
        }
        return .success(nil)
        
    }

    func addMessage(_ newMessage:Message) {

        //　メッセージが更新されたことをDelegateへ知らせる
        if let _delegate = self.delegate {
            _delegate.messageUpdate(message: newMessage)
        }

    }
}

//

class MessageThread:NSObject {
var threadId:String
var partnerUserId:String
var mediaType:MediaType = .text        //  text/plain
var sendBy:String
var text:String
var timestamp:Date?
var unread:Bool = false
var userId:String
var supplier:Supplier?
var messageList:MessageList?    // 外部からセットしている
var no_message:Bool = false     // true: まだ一度もメッセージを受信していない = textがnull
    
    init?(_ _input_dic:[String:Any]? ) {
        if let input_dic = _input_dic {
            if let _threadId =  input_dic["threadId"] as? String {
                threadId = _threadId
                partnerUserId = input_dic["partnerUserId"] as? String ?? ""
                mediaType = MediaType.init( rawValue: input_dic["mediaType"] as? String ?? "") ?? .none
                sendBy = input_dic["sendBy"] as? String ?? ""
                
                if mediaType == .text || mediaType == .none {
                    if let msg = input_dic["text"] as? String {
                        text = msg
                    }else{
                        text = ""
                        no_message = true
                    }
                }else{
                    text = NSLocalizedString("ImageMessage", comment: "")
                }
      
                unread = input_dic["unread"] as? Bool ?? false
                userId = input_dic["userId"] as? String ?? ""
                timestamp = Util.dateFromUTCString(input_dic["timestamp"] as? String)
                
            }else{
                return nil
            }
        }else{
            return nil
        }
    }

    public func markAsRead() -> Bool {
        let graphql =
        """
        mutation($userId: String!) {
          markThreadAsRead(userId: $userId) {
            threadId
            userId
            mediaType
            text
            unread
          }
        }
        """
        
        let paramDic = ["userId":partnerUserId]

        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        
        switch result {
        case .success(_) :
            self.unread = false
            return true
        case .failure(_):
            return false
        }
    }

}

// メッセージ交換している相手（パートナ）の一覧取得
class MessageThreads:NSObject {

    var threads:[MessageThread] = []
    var size:Int = 10
    var nextToken:String?

    init?(size:Int ) {
        super.init()
    
        self.size = size
    
    _ = getNext(firstTime:true)
        
    }

    public func getNext() -> [MessageThread] {
    
        return  getNext(firstTime: false)
    
    }
    // コールするたびに、次のレコードを返す
    private func getNext(firstTime:Bool) -> [MessageThread] {
    
        let graphql = """
        query getThreads($limit: Int, $nextToken: String) {
          getThreads(limit: $limit, nextToken: $nextToken) {
                    threads {
                        partnerUserId
                        mediaType
                        sendBy
                        text
                        threadId
                        timestamp
                        unread
                        userId
                    }
                    nextToken
                }
            }
        """

        let limit = self.size

        var tempArray:[MessageThread] = []

        var paramDic:[String:Any]!
        
        if firstTime {
            paramDic = ["limit" :limit ]
        }else{
            if nextToken == nil { return [] }  //　もうない
            paramDic = ["limit" :limit, "nextToken":nextToken! ]
        }

        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        
        switch result {
        case .success(let resultDic):
            if let result = resultDic["getThreads"] as? [String:Any] {
                nextToken = result["nextToken"] as? String
                if let items = result["threads"] as? [[String:Any]] {
                    for dic in items {
                        if let item = MessageThread(dic) {
                            item.supplier = Supplier()
                           // _ = item.supplier?.getSupplierForThread(item.partnerUserId)
                            tempArray.append(item)
                        }
                    }
                }
            }
        case .failure(_):
            nextToken = nil
        }

        threads.append(contentsOf: tempArray)
        return tempArray
    }
}

