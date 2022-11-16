//
//  UserLogAPI.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/04/05.
//

import Foundation


final class UserLog:NSObject {
    
    enum LogLevel:String {
        case trace = "TRACE"
        case debug = "DEBUG"
        case info = "INFO"
        case warn = "WARN"
        case error = "ERROR"
        case fatal = "FATAL"
    }

    enum UserAction: String {
        case add    = "add"
        case submit = "submit"
        case search = "search"
        case share = "share"
        case complete = "complete"
    }
    
    enum EventCategory: String {
        case favorite        = "favorite"
        case cart            = "cart"
        case trade_request   = "trade_request"
        case search_supplier = "search_supplier"
        case search_item     = "search_item"
        case search_product  = "search_product"
        case first_trade_request = "first_trade_request"
        case supplier  = "supplier"
        case item      = "item"
        case content   = "content"
        case cart_order = "cart_order"
        case profile_create = "profile_create"
    }

    enum ContentCategory:String {
        case search_items  = "search_items"
        case search_suppliers  = "search_suppliers"
        case recommended_items  = "recommended_items"
        case recommended_supplier  = "recommended_supplier"
    }
    
    enum EventLevel:String {
        case debug = "DEBUG"
        case info = "INFO"
        case worn = "WARN"
        case error = "ERROR"
        case fatal = "FATAL"
    }


    
    // 共通パラメータ
    var service = "retailer-ios"
    var sessionId:String = ""
    var userId:String = ""
    
    init(userId:String) {
        sessionId = Util.getDeviceId()
        self.userId = userId
    }
    
    
    func installed() {
        let eventDic:[String:Any] = [ "event":"install", "device":"ios",  "os":Util.getOSversion(), "app":Util.getAppVersion() ]
        sendLog(level:.info, eventDic: eventDic )
    }
    
    func updateed() {
        let eventDic:[String:Any] = [ "event":"update", "device":"ios",  "os":Util.getOSversion(), "app":Util.getAppVersion() ]
        sendLog(level:.info, eventDic: eventDic )
    }
    
    func login() {
        let eventDic:[String:Any] = [ "event":"login", "device":"ios",  "os":Util.getOSversion(), "app":Util.getAppVersion() ]
        sendLog(level:.info, eventDic: eventDic)
    }
    
    func logout() {
        let eventDic:[String:Any] = [ "event":"logout", "device":"ios",  "os":Util.getOSversion(), "app":Util.getAppVersion() ]
        sendLog(level:.info, eventDic: eventDic )
    }
    
    func error(graphql:String, message:String) {
        
        let api = getApiName(graphql: graphql)
        let eventDic:[String:Any] = [ "api":api, "message":graphql]
        sendLog(level:.error, eventDic: eventDic)
    }
    
    func currentTimeStamp() -> String {
        // return Now as format of '2021-10-01T01:01:00.000Z'

        return Util.dateToAwsTimeStamp(Date())!
    }
    
    //　graphql分からapi名だけを抜き出す　　　　行の先頭から”(”の前を関数名として扱う. "("が複数ある場合は、最後を採用
    func getApiName(graphql:String) -> String {
        var api = ""
        for line in graphql.split(separator: "\n") {
            let subs = line.split(separator: "(")
            if subs.count >= 2 {    // 二つに分割できるはずなので、分割できたら先頭の方に探している文字列が入っているはず
                api = String(subs[0])
            }
        }
        return api
    }
    func sendLog(level:LogLevel, eventDic:[String:Any], pageUrl:String = RETAILER_SITE_URL) {
        
        if userId == "" || sessionId == "" { return }
        
        let graphql = """
         mutation($input: SendLogInput!) {
           sendLog(input: $input ) {
             rejectedLogEventsInfo {
               tooNewLogEventStartIndex
               tooOldLogEventEndIndex
               expiredLogEventEndIndex
             }
           }
         }
        """
        /*
         let graphql = """

         """
         
         input SendLogInput {
           service: String!
           level: LogLevel!
           event: AWSJSON!
           timestamp: AWSDateTime!
           userId: ID
           sessionId: ID
           location: AWSURL
         }
         */
        
        do {
            // DictionaryをJSONデータに変換
            let jsonData = try JSONSerialization.data(withJSONObject: eventDic)
            // JSONデータを文字列に変換
            if let jsonStr = String(bytes: jsonData, encoding: .utf8) {
                
                let paramDic = ["input": [ "level":level.rawValue, "service":service, "userId":userId, "sessionId":sessionId,  "event" : jsonStr, "timestamp":currentTimeStamp(), "location": pageUrl]]
                
                LogUtil.shared.log("sendLog: \(paramDic)")

                OrosyAPI.callAPI(graphql, api:"UserLogCollector", variables: paramDic,  completion: { result in
                
                    switch result {
                    case .success(let resultDic):
                        if let getMessages = resultDic["getMessages"] as? [String:Any] {
                            let rejectedLogEventsInfo = getMessages["rejectedLogEventsInfo"] as? [String:Any] ?? [:]
                            LogUtil.shared.log("sendLog: \(rejectedLogEventsInfo)")
                        }
                        
                    case .failure(let error):
                        LogUtil.shared.log("sendAccessLog error:\(error.localizedDescription)")
                    }

                })
            }
            
        } catch {
            LogUtil.shared.log("sendLog json error: \(eventDic)")
        }

    }

    
    // MARK: SendUserEvent
    
    func addCart(itemId:String, pageUrl:String,count:Int) {
        let urlString = pageUrl
        sendUserEvent(action: .add, category: .cart, pageUrl: urlString,  label: itemId, value:count)
    }
    
    func addFavorite(itemParentId:String, pageUrl:String ) {
        let urlString = pageUrl
        sendUserEvent(action: .add, category: .favorite, pageUrl: urlString, label: itemParentId)
    }
    
    func askTradeRequest(supplierId:String, pageUrl:String ) {
        let urlString = pageUrl
        sendUserEvent(action: .submit, category: .trade_request, pageUrl: urlString, label: supplierId)
    }
    
    func searchItem(keyWord:String, pageUrl:String, count:Int) {
        let urlString = pageUrl
        sendUserEvent(action: .search, category: .search_item, pageUrl: urlString, label: keyWord, value:count)
    }
    
    func searchSupplier(keyWord:String, pageUrl:String, count:Int) {
        let urlString = pageUrl
        sendUserEvent(action: .search, category: .search_supplier, pageUrl: urlString, label: keyWord, value:count)
    }
    
    func shareSupplier(supplierId:String, pageUrl:String) {
        let urlString = pageUrl
        sendUserEvent(action: .share, category: .supplier, pageUrl: urlString,label:supplierId)
    }
    
    func shareItem(itemId:String, pageUrl:String ) {
        let urlString = pageUrl
        sendUserEvent(action: .share, category: .item, pageUrl: urlString,label:itemId)
    }
    
    func shareContent(contentId:String, pageUrl:String) {
        let urlString =  pageUrl
        sendUserEvent(action: .share, category: .content, pageUrl: urlString,label:contentId)
    }
    
    func cartOrder(contentId:String, pageUrl:String) {
        let urlString =  pageUrl
        sendUserEvent(action: .complete, category: .cart_order, pageUrl: urlString,label:contentId)
    }
    
    func profileCreate(userId:String, pageUrl:String) {
        let urlString =  pageUrl
        sendUserEvent(action: .complete, category: .profile_create, pageUrl: urlString, label:userId)
    }
    
    func sendUserEvent(action:UserAction, category:EventCategory, pageUrl:String, label:String, value:Int = 1) {
                
        if userId == "" || sessionId == "" { return }
        
        let graphql = """
        mutation($input: SendUserEventInput!) {
          sendUserEvent(input: $input) {
            recordId
          }
        }

        """
        /*
         input SendUserEventInput {
           service: String!
           sessionId: ID!
           url: AWSURL!
           userId: ID
           action: String
           category: String
           label: String
           value: Int
         }
         */
        
        let paramDic:[String : Any] = ["input": [ "service":service, "userId":userId, "sessionId":sessionId, "url":pageUrl, "action" : action.rawValue, "category" : category.rawValue, "label": label, "value":value ]]

        LogUtil.shared.log("sendUserEvent: \(paramDic)")
      //  return .success(nil)

        OrosyAPI.callAPI(graphql, api:"UserLogCollector", variables: paramDic,  completion: { result in
        
            switch result {
            case .success(_):
                LogUtil.shared.log("sendAccessLog succcess")
                
            case .failure(let error):
                LogUtil.shared.log("sendAccessLog error:\(error.localizedDescription)")

            }
        })
    }
    
   
    
    // MARK: sendAccessLog
    func sendAccessLog( pageUrl:String, pageId:String? = nil, referer:String? = nil) {
        
        if userId == "" || sessionId == "" { return }
        

        let graphql = """
        mutation ($input: SendAccessLogInput!) {
          sendAccessLog(input: $input) {
            recordId
          }
        }
        """
        /*
         input SendAccessLogInput {
           service: String!
           sessionId: ID!
           url: AWSURL!
           userId: ID
           method: String
           statusCode: Int
           referer: AWSURL
         }
         */
        
        
        var paramDic:[String : Any] = ["input": [ "service":service, "userId":userId, "sessionId":sessionId, "url": pageUrl + (pageId ?? "") ]]
        if let ref = referer {
            var inputDic = paramDic["input"] as! [String:String]
            inputDic["referer"] = ref
            paramDic["input"] = inputDic
        }

        LogUtil.shared.log("sendAccessLog: \(pageUrl), referer:\(referer ?? "")")
   
        OrosyAPI.callAPI(graphql, api:"UserLogCollector", variables: paramDic,  completion: { result in
        
            switch result {
            case .success(_):
                LogUtil.shared.log("sendAccessLog succcess")
                
            case .failure(let error):
                LogUtil.shared.log("sendAccessLog error:\(error.localizedDescription)")

            }
        })
     
    }

    
    // MARK:  DisplayedContent

    struct DisplayContent  {
        var pageUrl:String!
        var category:ContentCategory!
        var label:String!
        var index:Int = 0
        
        init?(pageUrl:String, category:ContentCategory, label:String, index:Int = 0) {
            
            self.pageUrl = pageUrl
            self.category = category
            self.label = label
            self.index = index
            
            if pageUrl == "" || category.rawValue == "" || label == "" {
                return nil
            }
        }
    }

    
    func makeItemsContents(category:ContentCategory, pageUrl:String, itemParents:[ItemParent], startIndex:Int = 0) {
        
        var contents:[[String:Any]] = []
        var index = startIndex
        
        for item in itemParents {
            let content:[String:Any] = [ "service":service, "userId":userId, "sessionId":sessionId, "url": pageUrl, "category":category.rawValue, "label":item.id, "index":index ]
            contents.append(content)
            index += 1
        }
        
        _ = bulkSendDisplayedContent(displayContents:contents)
        
    }

    func makeSupplierContents(category:ContentCategory, pageUrl:String, suppliers:[Supplier], startIndex:Int = 0) {
        
        var contents:[[String:Any]] = []
        var index = startIndex
        
        for supplier in suppliers {
            let content:[String:Any] = [ "service":service, "userId":userId, "sessionId":sessionId, "url": pageUrl, "category":category.rawValue, "label":supplier.id, "index":index ]
            contents.append(content)
            index += 1
        }
        
        _ = bulkSendDisplayedContent(displayContents:contents)
        
    }
    
    func bulkSendDisplayedContent( displayContents: [[String:Any]] ) {
        
        if userId == "" || sessionId == "" || displayContents.count == 0 { return }
        
            let graphql = """
            mutation($input: BulkSendDisplayedContentInput!) {
              bulkSendDisplayedContent(input: $input) {
                recordIds
              }
            }

            """
            /*
             input SendDisplayedContentInputs {
               service: String!
               sessionId: ID!
               url: AWSURL!
               userId: ID
               category: String!
               label: String!
               index: Int!
             }
             */
            
        let paramDic:[String : Any] = ["input": ["sendDisplayedContentInputs": displayContents]]

        LogUtil.shared.log("bulkSendDisplayedContent: \(paramDic)")
        //print ("bulkSendDisplayedContent: \(paramDic)")
        
         OrosyAPI.callAPI(graphql, api:"UserLogCollector", variables: paramDic,  completion: { result in
         
             switch result {
             case .success(_):
                 LogUtil.shared.log("bulkSendDisplayedContent succcess")
                 
             case .failure(let error):
                 LogUtil.shared.log("bulkSendDisplayedContent error:\(error.localizedDescription)")

             }
         })
    }
    
}
