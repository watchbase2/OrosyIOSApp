//
//  Favorit.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/20.
//

import Foundation

// MARK: -------------------------------------
// MARK: お気に入り関連


// お気に入りリスト（お気に入りの分類名のリスト）を取得（ページネーション対応はしていない）
class FavoriteLists:NSObject {
    var list:[FavoriteList] = []    // v1では1つだけ
    var size:Int = 10
    var nextToken:String? = ""
    var hasAllData = false
    
    init(size:Int = 1) {
              
        self.size = size

    }
    
    public func createFavoriteList(name:String) -> Result<Bool, OrosyError> {
        
        let graphql = """
        mutation createFavoriteItemList($listName: String!) {
            createFavoriteItemList(listName: $listName) {
                listId
                listName
            }
        }
        """
        
        let paramDic = ["listName" : name]

        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        
        switch result {
        case .success(_):
            return .success(true)
        case .failure(let error):
            return .failure(OrosyError.UnknownErrorWithMessage(error.localizedDescription))
        }
    }
    
    public func getNext() -> Result<[FavoriteList], OrosyError> {
        let graphql = """
        query getFavoriteItemLists($limit: Int, $nextToken: String) {
        getFavoriteItemLists (limit: $limit, nextToken: $nextToken) {
                favoriteItemLists {
                    listId
                    listName
                    userId
                }
                nextToken
            }
        }
        """
        
        var tempArray:[FavoriteList] = []
        var paramDic:[String:Any] = ["limit": self.size]
        if nextToken != "" {
            paramDic["nextToken"] = nextToken
        }
        
        
        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        switch result {
        case .success(let resultDic):
            if let listDic = resultDic["getFavoriteItemLists"] as? [String:Any] {
                if let favorArray = listDic["favoriteItemLists"] as? [[String:Any]] {
                    for fdic in favorArray {
                        tempArray.append(FavoriteList(fdic))
                    }
                    self.list = tempArray
                }
                nextToken = listDic["nextToken"] as? String
                hasAllData = (nextToken == nil) ? true : false
                
                return .success(tempArray)
            }
            
        case .failure(let error):
            return .failure(OrosyError.UnknownErrorWithMessage(error.localizedDescription))
        }
        
        return .failure(OrosyError.KeyNotFound)
    }
    
}

class ItemParentFallback:NSObject {
    var supplier:Supplier?
    var item:Item?
    
    init(_ _input_dic:[String:Any]?) {
        
        if let input_dic = _input_dic {
            supplier = Supplier(input_dic["supplier"] as? [String:Any])
            if let itemDic = input_dic["item"] as? [String:Any] {
                item = Item(title: itemDic["title"] as? String ?? "")
            }
        }
    }
}

class Favorite:NSObject {
    var isHidden:Bool = false                   // true: この商品は削除済みもしくは非表示の商品。お気に入り一覧で使っている
    var itemParent:ItemParent?                  // 商品情報         削除されている場合は　nilになる
    var itemParentId:String = ""                // お気に入りへの追加・削除ではこのidを使う
    var isFavorite:Bool = true                  // お気に入りとして選択されているというフラグを立てておく。一案表示するときには、Itemparent.isFavriteへコピーして使っている。これはお気に入り一覧以外ではItemParentにisFaviriteがセットされているから
    
    init?(_ _input_dic:[String:Any]?) {
        
        guard let input_dic = _input_dic else{ return nil }
        
        if let isHidden = input_dic["isHidden"] as? Bool {
            self.isHidden = isHidden
            if isHidden {
                // Fallback data 内部ではItemParentにマップしている
                // self.itemParentFallback = ItemParentFallback(input_dic["itemParentFallback"] as? [String:Any])

                if let idc = input_dic["itemParentFallback"] as? [String:Any] {       // 削除隅の総品の情報はここに入っている
                    var itemParnetDic = idc
                    itemParnetDic["id"] = "*"
                    if let dic = itemParnetDic["item"] as? [String:String] {
                        var itemDic = dic
                        itemDic["id"] = "*"
                        itemParnetDic["item"] = itemDic
                        self.itemParent = ItemParent(itemParnetDic)
                    }
                   
                }else{
                    //　削除・非公開された商品
                    print("削除・非公開された商品")
                }
                
            }else{
                if let itemDic = input_dic["itemParent"] as? [String:Any] {
                    self.itemParent = ItemParent(itemDic)
                }
            }
            self.itemParentId = input_dic["itemParentId"] as? String ?? ""
            self.itemParent?.isFavorite = true  // お気に入りとして選択されているというフラグを立てておく
        }
        
        if self.itemParent == nil {
            return nil      // 委託商品の場合には強制的にnilを返す
        }
    }
}

// お気に入りデータ（特定のお気に入り分類に登録されているお気に入りデータ）
class FavoriteList:NSObject {
    var listId:String = ""
    var listName:String = ""
    var userId:String = ""
    var itemParents:[Favorite] = []
    var createdAt:Date?
    var limit:Int = 20
    var nextToken:String? = ""
    
    init(_ _input_dic:[String:Any]?) {
        
        if let input_dic = _input_dic {
            listId = input_dic["listId"] as! String
            listName = input_dic["listName"] as! String
            userId = input_dic["userId"] as! String
            createdAt = Util.dateFromUTCString(input_dic["createdAt"] as? String)
        }
    }
    
    func reset() {
        nextToken = ""
        itemParents = []
    }
    
    // full = false: 商品一覧でお気に入りに入っているかどうかをチェックするための最低限のデータを取得する場合
    //        true: お気に入り一覧で商品を一覧表示するために必要なデータを取得する場合
    func getFavoriteItem(full:Bool, limit:Int) -> Result<[Favorite], OrosyError> {
        
        if nextToken == nil {
            return .success([])
        }
        
        self.limit = limit
        var graphql:String!
        
        if full {
            graphql =
            """
             query getFavoriteItemList($listId: String!, $limit: Int, $nextToken: String) {
                 getFavoriteItemList(listId: $listId, limit: $limit, nextToken: $nextToken) {
                     favoriteItems {
                         createdAt
                         isHidden
                         itemParentId
                         itemParent {
                             id
                             imageUrls
                             isWholesale
                             item {
                                 id
                                 title
                                 productNumber
                                 jancode
                                 isPl
                                 catalogPrice
                                 isWholesale
                                 wholesalePrice
                             }
                             variationItems {
                                 catalogPrice
                                 consignmentPrice
                                 id
                                 inventoryQty
                                 isConsignment
                                 isPl
                                 isWholesale
                                 jancode
                                 minLotQty
                                 setQty
                                 size
                                 title
                                 productNumber
                                 variation1Label
                                 variation1Value
                                 variation2Label
                                 variation2Value
                                 wholesalePrice
                             }
                             supplier {
                                 brandName
                                 id
                                 iconImageUrl
                                 coverImageUrl
                                 imageUrls
                                 itemParentsSearch {
                                     itemParentIds {
                                         id
                                         imageUrl
                                     }
                                 }
                             }
                         }
                         itemParentFallback {
                             item {
                                 title
                             }
                             supplier {
                                 brandName
                                 id
                             }
                         }
                     }
                     nextToken
                 }
             }
             """
        }else{
            graphql =
            """
             query getFavoriteItemList($listId: String!, $limit:Int, $nextToken:String) {
               getFavoriteItemList(listId: $listId, limit: $limit, nextToken: $nextToken) {
                 favoriteItems {
                   itemParentId
                   itemParent {
                     id
                     item {
                       id
                       title
                     }
                     supplier {
                       brandName
                       id
                     }
                   }
                   itemParentFallback {
                     item {
                       title
                     }
                     supplier {
                       brandName
                       id
                     }
                   }
                 }
                 nextToken
               }
             }
             """
        }
        
        var tempArray:[Favorite] = []
        var paramDic:[String:Any]
        
        if nextToken == "" {
            paramDic = ["listId": listId, "limit": limit]
        }else{
            paramDic = ["listId": listId, "limit": limit, "nextToken": nextToken ?? ""]
        }
        
        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        switch result {
        case .success(let resultDic):
            if let listDic = resultDic["getFavoriteItemList"] as? [String:Any] {
                if let itemArray = listDic["favoriteItems"] as? [[String:Any]] {
                    
                    for itemDic in itemArray {
                        if let favorite = Favorite(itemDic) {
                            tempArray.append(favorite)
                        }
                    }
                    self.itemParents = tempArray
                }
                nextToken = listDic["nextToken"] as? String
                return .success(tempArray)
            }
            
        case .failure(let error):
            return .failure(OrosyError.UnknownErrorWithMessage(error.localizedDescription))
        }
        return .failure(OrosyError.KeyNotFound)
    }
    
    // on = true: お気に入りリストへ追加、 false:削除
    public func changeFavorite(itemParentId:String, on:Bool) -> Bool {
        
        var graphql =
        """
            mutation $func($itemParentId: String!, $listId: String!)  {
                $func(itemParentId: $itemParentId, listId: $listId) {
                    listId
                }
            }
        """
        
        graphql = graphql.replacingOccurrences(of: "$func", with: ((on) ? "addFavoriteItem" : "deleteFavoriteItem"))
        
        let paramDic = ["itemParentId" : itemParentId, "listId": self.listId]

        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        
        switch result {
        case .success(_):
            // リストを更新しておく
            let result2 = getFavoriteItem(full:false, limit:self.limit)
            switch result2 {
            case .success(_):
                g_favoriteItems = self.itemParents
                return true
            case .failure(_):
                return false
            }
        case .failure(_):
            break
        }
        return false
    }
}
