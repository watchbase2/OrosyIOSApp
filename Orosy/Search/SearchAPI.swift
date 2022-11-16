//
//  Search.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/22.
//

import Foundation

// MARK: -------------------------------------
// MARK: 検索

class SearchItems:NSObject {
    var itemParents:[ItemParent] = []
    var size:Int = 10
    var from:Int = 0
    var count:Int = 0
    var total:Int = 0
    var sort:SortMode = .Newer
    
    var searchWord:String?          // 検索ワード　　指定しない場合はカテゴリの指定が必要
    var categoryId:String?
    var categoryKey:SearchKey?         // カテゴリが　大か中カテゴリかの指定
    var hasAllItemParents:Bool = false  //　すべての商品情報を取得済み
    var pageUrl:String = ""
    var userLogDone = false
    
    init?(searchWord:String? = nil, size:Int = 10, sort:SortMode, categoryKey:SearchKey? = nil, categoryId:String? = nil, pageUrl:String ) {
        self.searchWord = searchWord
        self.size = size
        self.sort = sort
        self.categoryKey = categoryKey
        self.categoryId = categoryId
        self.pageUrl = pageUrl
        userLogDone = false
    }
    
    
    //　残りのデータを取得　　　　pageUrl:検索ページのURL, Contentsログ用
    func getNext() -> Result< [ItemParent], OrosyError> {
        let graphql =
        """
         query searchItems(
           $searchWord: String
           $supplierId: String
           $searchCategoryKey: String
           $categoryId: String
           $from: Int!
           $size: Int!
           $sort: ListSortEnum
         ) {
           searchItems(
             searchWord: $searchWord
             supplierId: $supplierId
             searchCategoryKey: $searchCategoryKey
             categoryId: $categoryId
             from: $from
             size: $size
             sort: $sort
           ) {
             pageInfo {
               total
               from
               size
               count
             }
             items {
               id
               imageUrls
               title
               catalogPrice
               wholesalePrice
               isWholesale
               supplier {
                 id
                 brandName
               }
             }
         
           }
         }
         """
        
        var paramDic = [ "from":from, "size": size] as [String : Any]
        
        if let key = searchWord {
            paramDic["searchWord"] = key
        }
        if let cid = categoryId {
            paramDic["categoryId"] = cid
            
            if let ckey = categoryKey {
                paramDic["searchCategoryKey"] = ckey.rawValue
            }
        }
        
        if sort != .Recommend {
            paramDic["sort"] = sort.rawValue
        }
        
        var tempArray:[ItemParent] = []
        
        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        
        switch result {
        case .success(let resultDic):
            if let sdic = resultDic["searchItems"] as? [String:Any] {
                if let pageInfoDic = sdic["pageInfo"] as? [String:Any] {
                    count = pageInfoDic["count"] as! Int
                    total = pageInfoDic["total"] as! Int    // 値が怪しい
                    from = pageInfoDic["from"] as! Int
                    from = from + count
                    if count < self.size {
                        hasAllItemParents = true    // 最後まで読み込んだ
                    }
                }
                if let itemsDic = sdic["items"] as? [[String:Any]] {
                    
                    for itemDic in itemsDic {
                        if let item = Item(itemDic) {
                            if let itemParent = ItemParent(itemDic) {
                                itemParent.item = item
                                tempArray.append(itemParent)
                            }
                        }
                    }
                    
                    let startIndex = self.itemParents.count
                    self.itemParents.append(contentsOf: tempArray)
                    
                    if userLogDone {
                        if let key = searchWord {
                            g_userLog.searchItem(keyWord: key, pageUrl: pageUrl, count: total)
                            userLogDone = true
                        }
                    }
                    // 表示コンテンツのログ送信
                    g_userLog.makeItemsContents(category: .search_items, pageUrl: pageUrl, itemParents: tempArray, startIndex:startIndex)    // 追加で読み込んで分だけをログ送信
                    
                    
                    return .success(tempArray)
                }
            }
            return .failure(OrosyError.KeyNotFound)
            
        case .failure(let error):
            return .failure(OrosyError.UnknownErrorWithMessage(error.localizedDescription))
        }
        
    }
}


// ブランド検索
class SearchSuppliers:Suppliers {

   // var list:[Supplier] = []
  //  var size:Int = 10
  //  var from:Int = 0
  //  var count:Int = 0
   // var total:Int = 0
    
    var searchWord:String = ""
    var hasAllISuppliers:Bool = false  //　すべての報を取得済み
    var pageUrl:String = ""

    
    init?(searchWord:String, size:Int = 10,pageUrl:String) {
        super.init( from:0, size:size)
        self.searchWord = searchWord
        self.pageUrl = pageUrl
    }
    
    //　残りのデータを取得　　　　pageUrl:検索ページのURL, Contentsログ用
    func getNextSuppliers() -> Result< [Supplier], OrosyError> {
        let graphql =
        """
         query searchSuppliers(
           $searchWord: String!
           $from: Int
           $size: Int
         ) {
           searchSuppliers(
             searchWord: $searchWord
             from: $from
             size: $size
           ) {
             pageInfo {
               total
               from
               size
               count
             }
             suppliers {
               id
               brandName
               iconImageUrl
               imageUrls
               category
               itemParentsSearch {
                 itemParentIds {
                   id
                   imageUrl
                 }
               }
             }
           }
         }
         """
        
        let paramDic = ["searchWord": searchWord, "from":from, "size": size] as [String : Any]
        
        var tempArray:[Supplier] = []
        
        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        
        switch result {
        case .success(let resultDic):
            if let sdic = resultDic["searchSuppliers"] as? [String:Any] {
                if let pageInfoDic = sdic["pageInfo"] as? [String:Any] {
                    count = pageInfoDic["count"] as! Int
                    total = pageInfoDic["total"] as! Int    // 値が怪しい
                    from = pageInfoDic["from"] as! Int
                    from = from + count
                    if count < self.size {
                        hasAllISuppliers = true    // 最後まで読み込んだ
                    }
                }
                if let suppliersDic = sdic["suppliers"] as? [[String:Any]] {
                    
                    for supplierDic in suppliersDic {
                        if let supplier = Supplier(supplierDic) {
                            tempArray.append(supplier)
                        }
                    }
                    
                    let startIndex = self.list.count
                    self.list.append(contentsOf: tempArray)
                    
                    // 表示コンテンツのログ送信
                    g_userLog.makeSupplierContents(category: .search_suppliers, pageUrl: pageUrl, suppliers: tempArray, startIndex:startIndex)    // 追加で読み込んで分だけをログ送信
                    
                    return .success(tempArray)
                }
            }
            return .failure(OrosyError.KeyNotFound)
            
        case .failure(let error):
            return .failure(OrosyError.UnknownErrorWithMessage(error.localizedDescription))
        }
        
    }
}
