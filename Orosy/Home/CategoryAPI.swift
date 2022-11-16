//
//  Category.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/20.
//

import Foundation


// MARK: -------------------------------------
// MARK: カテゴリー
//　大カテゴリ、中カテゴリのリストを取得する

final class Categories:NSObject {
    public static let shared = Categories()
    
    var list:[Category] = []

    override private init() {}
    
    // forceGetFromServerがtrueならサーバから、そうでなければローカルから取得
    
    public func getCategories() -> Result<Any?, OrosyError> {
        
        return getCategories(forceGetFromServer:false)
        
    }
    
    public func getCategories(forceGetFromServer:Bool) -> Result<Any?, OrosyError> {
 
        var needGetFromServe = true
        
        if !forceGetFromServer {

            if let jsonString = UserDefaultsManager.shared.category {
                // ローカルの情報を適用する
                if self.convertFromJson(jsonString:jsonString) {
                    needGetFromServe = false
                    return .success(nil)
                }
            }
        }
        
        if needGetFromServe {
            // サーバから取得する必要がある
            let result = self.getCategoriesData()

            switch result {
            case .success(_):
                let jsonString = self.getJson()
                UserDefaultsManager.shared.category = jsonString
                UserDefaultsManager.shared.updateUserData()
                return .success(nil)

            case .failure(let error):
                return .failure(error)
            }
        }
    }
    
    func convertFromJson(jsonString:String) -> Bool {

        var tempArray:[Category] = []
        
        do {
            let data = jsonString.data(using: .utf8)
            if  let jsondata = data {
                let dicList =  try JSONSerialization.jsonObject(with: jsondata , options: []) as! [[String:Any]]

                for dic in dicList {
                    let dataDic = dic["data"] as! [String:Any]
                    if let cat = Category(dataDic) {
                        var children:[Category] = []
                        
                        for childDic in dic["children"] as! [[String:Any]] {
                            if let child = Category(childDic) {
                                children.append(child)
                            }
                        }
                        cat.children = children
                        tempArray.append(cat)
                    }
                }
                
            }else{
                self.list = []
                return false
            }
    
        }catch let error {
            print(error)
            return false
        }
        
        self.list = tempArray
        return true
    }
    
    public func getCategoryName(categoryId:String) -> String {
        
        for category in list {
            if category.id == categoryId {
                return category.name
            }
            for childCategory in category.children {
                if childCategory.id == categoryId {
                    return category.name + "/" + childCategory.name
                }
            }
        }
        return ""
    }
    
    func getJson() -> String? {
        var tempArray:[[String:Any]] = []
        
        
        for cat in list {
            var catgoryDic:[String:Any] = [:]
            catgoryDic["data"] = cat.dictionary
            
            var children:[[String:Any]] = []
            for child in cat.children {
                if let dic = child.dictionary {
                    children.append(dic)
                }
            }
            catgoryDic["children"] = children
            
            tempArray.append(catgoryDic)
        }
        
        var jsonStr = ""
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: tempArray, options: [])
            jsonStr = String(bytes: jsonData, encoding: .utf8)!
            print(jsonStr)
        } catch let error {
            print(error)
        }

        return jsonStr
    }
    

    private func getCategoriesData() -> (Result<[Category], OrosyError>) {
        let graphql = """
        query getCategories {
          getCategories {
            categories{
              id
              name
              indexNo
            }
          }
        }
        """
        
        let result = OrosyAPI.callSyncAPI(graphql)
        var tempArray:[Category] = []
        
        switch result {
        
        case .success(let resultDic):
            if let array = (resultDic["getCategories"] as? [String:Any])?["categories"] as? [[String:Any]] {

                for dic in array {
                    if let cat = Category(dic) {
                        tempArray.append(cat)
                    }
                }
             }
            
            // indexNo 順にソート
            let sortedArray = tempArray.sorted { $0.indexNo > $1.indexNo }
            self.list = sortedArray
            
            //　下位階層のカテゴリを取得
            //  DispatchQueue.global().async {
                self.getLargeCategories(sortedArray)
            //  }
            
            return .success(sortedArray)
            
        case .failure(let error):
            self.list = []
            return .failure(OrosyError.UnknownErrorWithMessage(error.localizedDescription))
        }

    }

    func getLargeCategories(_ categories:[Category]?) {
        
        guard let catList = categories else{
            return
        }
        
        for cat in catList {
            let graphql = """
            query($largeCategoryId: String!, $limit: Int, $nextToken: String) {
              getLargeCategoryChildren(largeCategoryId: $largeCategoryId, limit: $limit, nextToken: $nextToken) {
                categories {
                  id
                  name
                  indexNo
                  rowNo
                }
              }
            }
            """
            
            let paramDic = ["largeCategoryId" : cat.id ]
            let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
            
            switch result {
            case .success(let resultDic):
                var tempArray:[Category] = []

                if let array = (resultDic["getLargeCategoryChildren"] as? [String:Any])?["categories"] as? [[String:Any]] {

                    for dic in array {
                        if let cat = Category(dic) {
                            tempArray.append(cat)
                        }
                    }
                 }

                let sortedArray = tempArray.sorted { $0.indexNo > $1.indexNo }
                cat.children = sortedArray
                
            case .failure(_):
                break
            }

        }
    }
}

// 大カテゴリ
class Category:NSObject , Comparable {

    var id:String = ""
    var home = false    // true：このカテゴリ他選択されたら、カテゴリ検索モードから抜けてホームへ戻る
    var name:String!
    var display_name:String!
    var indexNo:Int!
    var parentCateoryId:String?
    var children:[Category] = []
    var dictionary:[String:Any]?
    var isLargeKey:Bool = true  // 大カテゴリかどうか
    

    init?(_ _input_dic:[String:Any]?) {
        dictionary = _input_dic
        
        if let input_dic = _input_dic {
        
            if g_categoryDisplayName == nil { return nil }
            
            guard let _id = input_dic["id"] as? String else{ return nil }
            id = _id
            name = input_dic["name"] as? String
            display_name = g_categoryDisplayName.getDisplayName( name)
            indexNo = input_dic["indexNo"] as? Int ?? -1
            parentCateoryId = input_dic["parentCateoryId"] as? String
            
        }else{
            return nil
        }
    }
    
    
    init?(title:String) {
   
        home = true
        name = title
    }

    public func isHome() -> Bool {
        return home
    }
    
    static func < (lhs: Category, rhs: Category) -> Bool {
        return lhs.indexNo < rhs.indexNo
    }
    
}

// 指定したカテゴリーのアイテム一覧を取得
//
class CategoryItems:NSObject {
    var itemParents:[ItemParent] = []
    var category_id:String = ""
    var searchKey:SearchKey!
    var size:Int = 10
    var from:Int = 0
    var count:Int = 1
    var sort:SortMode = .Newer

    init?(category_id:String, searchKey:SearchKey, size:Int ,sort:SortMode) {
        super.init()
        
        if category_id == "" { return nil }
        self.category_id = category_id
        self.searchKey = searchKey
        self.size = size
        self.sort = sort
        
    }

    
    // コールするたびに、次のレコードを返す
    func getNext() -> [ItemParent] {
        
        let graphql = """
        query getCategoryItems($categoryId: String!, $searchKey: String, $from: Int, $size: Int, $sort: ListSortEnum) {
          getCategoryItems(categoryId: $categoryId, searchKey: $searchKey, from: $from, size: $size, sort: $sort) {
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
              productNumber
              jancode
              description
              tax
              wholesalePrice
              catalogPrice
              isWholesale
              isConsignment
              setQty
              minLotQty
              inventoryQty
              isPl
              tags
              supplier {
                id
                brandName
                imageUrls
                coverImageUrl
                iconImageUrl
                category
              }
            }
          }
        }
        """

        var count = size
        var tempArray:[ItemParent] = []
        let searchKey = searchKey.rawValue

        var paramDic:[String:Any] = ["categoryId" : category_id, "searchKey" : searchKey, "size" : size, "from" : from]
        if sort != .Recommend {     // 「おすすめ順」にする場合はブランクにする
            paramDic["sort"] = sort.rawValue
        }
        let result = OrosyAPI.callSyncAPI(graphql, variables:paramDic)
        
        switch result {
        case .success(let resultDic):
            if let result = resultDic["getCategoryItems"] as? [String:Any] {
                let pageInfoDic = result["pageInfo"] as? [String:Any]
                count = pageInfoDic?["count"] as? Int ?? 0    // 読み出した件数
                self.from = (pageInfoDic?["from"] as? Int ?? 0) + count
                
                if let items = result["items"] as? [[String:Any]] {
                    for dic in items {
                        if let itemParent = ItemParent(dic) {       // ItemParent と Item　が合わさったデータになっているので、同じ辞書からItemParent と Itemを生成しているが、Itemの中のidは ItemrParentのID である。
                            itemParent.item = Item(dic)
                            tempArray.append(itemParent )
                        }
                    }
                }

            }
        case .failure(_):
            count = 0
        }
             
        self.itemParents.append(contentsOf: tempArray)
        
        return tempArray
    }

}

class LargeCategoryChildren:Category {

var categories:[Category]!

}

class MiddleCategoryChildren:LargeCategoryChildren {

    var largeCategory:Category!
    var middleCategory:Category!

}
