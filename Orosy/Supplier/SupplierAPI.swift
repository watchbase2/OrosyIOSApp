//
//  Supplier.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/20.
//

import Foundation

// MARK: -------------------------------------
// MARK: サプライヤー

enum SearchKeyForSupplier:String {
    case All = "all"
    case Large = "itemParentsSearch.largeCategoryIds"
    case Middle = "itemParentsSearch.middleCategoryIds"
}

enum ConnectionStatus:String {
    case ACCEPTED = "ACCEPTED"
    case REQUESTED = "REQUESTED"
    case REQUEST_PENDING = "REQUEST_PENDING"
    case UNREQUESTED = "UNREQUESTED"
}

class Supplier:NSObject {
    var id:String = ""
    var brandName:String?
    var category:String?        // カテゴリの記号
    var concept:String?
    var customerBase:String?
    var commitment:String?
    var coverImageUrl:URL?
    var iconImageUrl:URL?
    var imageUrls:[URL] = []
    var products:[Product]?
    var restrictions:Restrictions?
    var otherConditions:String?
    var shippingFeeToArea:[ShippingFeeToArea] = []
    var shippingFeeRules:[ShippingFeeRules] = []    // 配列になっているが1つ目しか使っていない
   // var isAccepted:String?
    var connectionStatus:ConnectionStatus?
    var termFileUrl:URL?
    var tradeConnection:TradeConnection?
    var itemParents:[ItemParent] = []
    var hasAllItemParents:Bool = false  //　すべての商品情報を取得済み
    var urls: [SocialUrl] = []
    var extendData:AnyObject?   // なんでも入れられる拡張データ
    // 以下の二つは getProfilePublic APIで取得する
    var companyName:String?
    var businessFormat:String?
    var imageCacheObject:ImageCacheObject?
    
    private var size:Int = 15   // 10を指定しても、7しか帰らないケースがあったので、多く取得するようにした
    private var nextToken:String? = ""
        
    override init() {
        super.init()
        
    }
    
    init?(_ _input_dic:[String:Any]? ) {
        super.init()
        
        if setData(_input_dic) == nil {
            return nil
        }
    }

    // 基本情報をすべて取得、　itemやconnection情報は含まない
    init?(supplierId:String?, size:Int = 10 )  {
        super.init()
        
        guard let sid = supplierId else{
            return
        }
        
        self.id = sid
        self.size = size
        
        if !getAllInfo(wholeData:false) { return nil }
        
    }
    
    public func getAllInfo(wholeData:Bool) -> Bool {
 
        let graphql = """
        query getSupplier($id: String!) {
          getSupplier(supplierId: $id) {
            id
            brandName
            brandNameAlphabet
            category
            concept
            customerBase
            commitment
            urls {
              category
              url
            }
            annualSales
            numberOfStores
            shippingFeeToArea {
              name
              amount
            }
            shippingFeeRules {
              type
              trigger
              triggerCount
              amount
            }
            imageUrls
            coverImageUrl
            iconImageUrl
            restrictions {
              ecSales
              reprintImages
              dropShipping
            }
            itemParentsSearch {
              itemParentIds {
                id
                imageUrl
              }
            }
            otherConditions
            term
            termFileUrl
          }
        }
        """;
        
        let paramDic = ["id" : self.id]
        
        let result = OrosyAPI.callSyncAPI(graphql, variables:paramDic)
        switch result {
        case .success(let resultDic):
            if let sdic = resultDic["getSupplier"] as? [String:Any] {
                if setData(sdic) == nil {
                    return false
                }
            }
        case .failure(let error):
            return false
        }

        if wholeData {
            if tradeConnection == nil {
                _ = getTradeConnection()
            }
            
            // すべてのアイテム情報と接続情報を取得
            /*
            if !hasAllItemParents {
                _ = getSupplierItemParents(all:true)
            }
            
 
            if companyName == nil {
                _ = getPublic()
            }
             */
        }
        
        return true
    }

    // サプライヤのiconだけを取得(Thread用）
    func getSupplierForThread(_ partnuerId:String ) -> Supplier? {
        let graphql =
        """
        query getSupplier($supplierId: String!) {
          getSupplier(supplierId: $supplierId) {
            id
            iconImageUrl
            brandName
          }
        }
        """
        let paramDic = ["supplierId" :partnuerId]

        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        switch result {
        case .success(let resultDic):
            if let supplierDic = resultDic["getSupplier"] as? [String:Any] {
                _ = setData(supplierDic)
                return self
            }
        case .failure(_):
            return nil
        }
        return nil
    }
    
    // サプライヤーの会社情報を取得
    public func getPublic() -> Bool {
        
        let graphql =
        """
        query getProfilePublic($id: String!) {
            getProfilePublic(userId: $id) {
                companyName
                businessFormat
            }
          }
        """
        
        //graphql = graphql.replacingOccurrences(of: "$userId", with: "\"\(self.id)\"")

        let paramDic = ["id" : self.id]
        let result = OrosyAPI.callSyncAPI(graphql, variables:paramDic)
        switch result {
        case .success(let resultDic):
            if let sdic = resultDic["getProfilePublic"] as? [String:Any] {
                self.companyName = sdic["companyName"] as? String
                self.businessFormat = sdic["businessFormat"] as? String
                return true
            }
            
        case .failure(_):
            break
        }
        return false
    }

    private func setData(_ _input_dic:[String:Any]?) -> NSObject? {
        
        if let input_dic = _input_dic {
            guard let _id = input_dic["id"] as? String else{ return nil}
            id = _id
            
            brandName = input_dic["brandName"] as? String
            category = input_dic["category"] as? String
            concept = input_dic["concept"] as? String
            commitment = input_dic["commitment"] as? String
            customerBase = input_dic["customerBase"] as? String
            coverImageUrl = (input_dic["coverImageUrl"] as? String == nil) ? nil : URL(string: input_dic["coverImageUrl"] as! String)
            iconImageUrl = (input_dic["iconImageUrl"] as? String == nil) ? nil : URL(string: input_dic["iconImageUrl"] as! String)
            
            if let urlArray = input_dic["imageUrls"] as? [String] {
                var urlTempArray:[URL] = []
                for imgUrl in urlArray {
                    if let url = URL(string: imgUrl) {
                        urlTempArray.append(url)
                    }
                }
                imageUrls = urlTempArray
            }
            
            restrictions = Restrictions(input_dic["restrictions"] as? [String:Any])
            otherConditions = input_dic["otherConditions"] as? String
            
            if let array = input_dic["shippingFeeToArea"] as? [[String:Any]] {
                var tempArray:[ShippingFeeToArea] = []
                
                for shipDic in array {
                    tempArray.append( ShippingFeeToArea(shipDic))
                }
                shippingFeeToArea = tempArray
                
            }
            
            if let array = input_dic["shippingFeeRules"] as? [[String:Any]] {
                var tempArray:[ShippingFeeRules] = []
                
                for shipDic in array {
                    tempArray.append( ShippingFeeRules(shipDic))
                }
                shippingFeeRules = tempArray
            }
            
            
            connectionStatus = ConnectionStatus(rawValue: input_dic["connectionStatus"] as? String ?? "UNREQUESTED")
            termFileUrl =  URL(string: input_dic["termFileUrl"] as? String ?? "")
            
            if let array = input_dic["urls"] as? [[String:Any]] {
                var tempArray:[SocialUrl] = []
                for socialDic in array {
                    if let social = SocialUrl(socialDic) {
                        tempArray.append(social)
                    }
                }
                
                // test
                /*
                tempArray.append(SocialUrl(["category":"others", "url":"http://www.yahoo.co.jp"])!)
                tempArray.append(SocialUrl(["category":"others", "url":"http://www.google.co.jp"])!)
                tempArray.append(SocialUrl(["category":"others", "url":"http://www.amazon.co.jp"])!)
                */
                urls = tempArray
            }
            
        }else{
            return nil
        }
        
        return self
    }
    
  
    // 指定されたサプライヤーの取引許可ステータスを取得
    public func getTradeConnection() -> TradeConnection? {
        let graphql = """
        query getTradeConnection($targetId: String!) {
          getTradeConnection(targetId: $targetId, isRetailer: true) {
            supplierId
            retailerId
            connectionStatus
            createdAt
            supplier {
              id
              brandName
            }
          }
        }
        """
        
       // graphql = graphql.replacingOccurrences(of: "$targetId", with: "\"\(self.id)\"")
        
        let paramDic = ["targetId" : self.id]
        let result = OrosyAPI.callSyncAPI(graphql, variables:paramDic)
        switch result {
        case .success(let resultDic):
            self.tradeConnection = TradeConnection(resultDic)
            self.connectionStatus = self.tradeConnection?.status
            return self.tradeConnection
            
        case .failure(_):
            return nil
        }

    }

    // 取引を申請
    public func askTradeConnection() -> Result<Bool, Error> {
        let graphql = """
        mutation createTradeAcceptRequest($targetId: String!) {
          createTradeConnection(targetId: $targetId, isRetailer: true) {
                supplierId
                retailerId
                connectionStatus
                createdAt
            }
        }

        """
    
        let paramDic = ["targetId" : self.id]
        let result = OrosyAPI.callSyncAPI(graphql, variables:paramDic)
    
        switch result {
        case .success(let resultDic):
            let dic = resultDic["createTradeConnection"] as? [String:Any]
            
            let isAccepted = (ConnectionStatus(rawValue: dic?["connectionStatus"] as? String ?? "UNREQUESTED") == .ACCEPTED) ? true : false
            return .success(isAccepted)
        case .failure(let error):
            return .failure(error)
        }
    }

    public func setFetchSize(size:Int) {
        self.size = size
    }
    
    // 商品一覧を取得
    public func getNextSupplierItemParents() -> [ItemParent] {
        
     //   if nextToken == nil { return [] }
            
        let graphql = """
        query getSupplierItemParents($supplierId: String!, $nextToken: String, $limit: Int) {
          getSupplierItemParents(supplierId: $supplierId, nextToken: $nextToken, limit: $limit) {
            nextToken
            itemParents {
              id
              imageUrls
              isConsignment
              isWholesale
              item {
                id
                title
                productNumber
                jancode
                isPl
                catalogPrice
                categoryNo
                consignmentPrice
                isConsignment
                isWholesale
                wholesalePrice
              }
              variationItems {
                 id
                 isWholesale
                 isConsignment
                 wholesalePrice
                 title
              }
              supplier {
                id
                brandName
                category
                concept
                iconImageUrl
                coverImageUrl
              }
            }
          }
        }
        """;
 
        let limit = self.size
        var tempArray:[ItemParent] = []

        var paramDic:[String:Any]!
        
        if let next = nextToken {
            if next == "" {
                paramDic = ["supplierId":self.id, "limit":limit]
            }else{
                paramDic = ["supplierId":self.id, "limit":limit, "nextToken":next]
            }

        }else{
           // paramDic = ["supplierId":self.id, "limit":limit]
            return []
        }

        let result = OrosyAPI.callSyncAPI(graphql, variables:paramDic)
        switch result {
        case .success(let resultDic):
            if let result = resultDic["getSupplierItemParents"] as? [String:Any] {
                nextToken = result["nextToken"] as? String
                if let items = result["itemParents"] as? [[String:Any]] {
                    for dic in items {
                        if let itemParent =  ItemParent(dic) {
                            if itemParent.variationItems.count > 0 {        // ItemParentの中で、委託商品を取り除いているため、すべてが委託商品の場合はカウントがゼロになるので、その場合は商品そのものを取り除いている
                                tempArray.append(itemParent)
                            }
                        }
                    }
                    self.itemParents.append(contentsOf: tempArray)
                }
                if nextToken == nil || nextToken == "" {
                    hasAllItemParents = true    // 正常終了でnextTokenがnilの場合は、もう残っているデータはないことを意味する
                }
            }
        case .failure(let error):
            nextToken = nil
        }
 
       // itemParents.append(contentsOf: tempArray)
        return tempArray
    }
    
    //　注文実績の有無のチェック（購入実績なしのときに適用可能なキャンペーンのためのチェック）
    // 注文実績がない場合の特典のためなおで、エラーの場合には注文実績有りとして判定している。
    // 過去にオーダがあれば　true　
    func checkOrders() -> Bool {
        
        let graphql =
        """
            query getOrdersOfSupplierFromRetailer($supplierId: String!, $limit: Int) {
            getOrdersOfSupplierFromRetailer(supplierId: $supplierId, limit: $limit) {
              nextToken
              orders {
                orderNo
                orderDay
        
              }
            }
          }
        """
        
        var paramDic:[String:Any] = ["supplierId":self.id, "limit":5,]
        
        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        
        switch result {
        case .success(let resultDic):
            if let result = resultDic["getOrdersOfSupplierFromRetailer"] as? [String:Any] {
                if let orders = result["orders"] as? [[String:Any]] {
                    return (orders.count > 0) ? true : false
                }
            }
        case .failure(_):
            return true
        }
        return true
    }
    

}



class Suppliers:NSObject {
    var list:[Supplier] = []
    
    public  var total:Int = 0
    private var categoryId:String = ""
    var size:Int = 10
    var from:Int = 0
    var count:Int = 1

    private var sort:SortMode = .Newer
    private var searchKey:SearchKeyForSupplier!
    
    init?(categoryId:String? = nil, from:Int, size:Int, sort:SortMode = .Newer, searchKey:SearchKeyForSupplier = .All)  {
        super.init()
        
        //guard let _categoryId = categoryId else { return nil }
        
        list = []
        self.categoryId = categoryId ?? ""
        self.from = from
        self.size = size
        self.searchKey = searchKey
        self.sort = sort

    }
    
    // 指定したカテゴリのサプライヤーを取得
    
    public func getNext() -> [Supplier]? {
        return fetch(readPointer: from)
    }

    public func fetch(readPointer:Int) -> [Supplier]? {
   // newerは　, $sort: ListSortEnum　と定義されていて、　"newer" という文字列をセットするとエラーになるので、queryに埋め込んでいる。
        // デフォルトの recommendにするためには、　sortパラメータごと削除する必要がある
        
           let graphql =
           """
           query getSuppliersWithItemParents($categoryId: String!, $searchKey: String, $from: Int, $size: Int, $sort: ListSortEnum) {
             getSuppliersWithItemParents(categoryId: $categoryId, searchKey: $searchKey, from: $from, size: $size, sort: $sort) {
                       pageInfo {
                           count
                           from
                           size
                           total
                       }
                       suppliers {
                           id
                           brandName
                           category
                           coverImageUrl
                           iconImageUrl
                           imageUrls
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

        var count = size
        var tempArray:[Supplier] = []
         
        var paramDic:[String:Any] = ["categoryId":categoryId, "searchKey":searchKey.rawValue, "size":size, "from":readPointer]
        if sort == .Newer {     // 「おすすめ順」にする場合はブランクにする
            paramDic["sort"] = sort.rawValue
        }
        
        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)

           switch result {
           case .success(let resultDic):
               if let result = resultDic["getSuppliersWithItemParents"] as? [String:Any] {
                   let pageInfoDic = result["pageInfo"] as? [String:Any]
                  total = pageInfoDic?["total"] as? Int ?? 0
                   count = pageInfoDic?["count"] as? Int ?? 0    // 読み出した件数
                   self.from = (pageInfoDic?["from"] as? Int ?? 0) + count
                   
                   if let items = result["suppliers"] as? [[String:Any]] {
                       for dic in items {
                           if let item = Supplier(dic) {
                               tempArray.append(item )
                           }
                       }
                   }
               }
           case .failure(_):
               return nil
           }
                
           self.list.append(contentsOf: tempArray)
        
           return tempArray
       }
    
 
}

class Product:NSObject {
    var productID:String!
    var productName:String!
    var shopID:String!
    var listPrice:String!
    var approved:Bool = false      // 取引許可
}

// 取引条件
class Restrictions:NSObject {
    var allowDirectShipments:String?    // allow or deny
    var allowOnlineSales:String?
    var allowPrePurchases:String?
    var allowReprintImages:String?
    var dropShipping:String?
    var ecSales:String?
    var reprintImages:String?

    init(_ _input_dic:[String:Any]? ) {
        
        if let input_dic = _input_dic {
            allowDirectShipments = input_dic["allowDirectShipments"] as? String
            allowOnlineSales = input_dic["allowOnlineSales"] as? String
            allowPrePurchases = input_dic["allowPrePurchases"] as? String
            allowReprintImages = input_dic["allowReprintImages"] as? String
            dropShipping = input_dic["dropShipping"] as? String ?? ""
            ecSales = input_dic["ecSales"] as? String
            reprintImages = input_dic["ecSales"] as? String
            
        }
    }
}

// 取引許可申請状態
class TradeConnection:NSObject {
    var supplierId:String?
    var retailerId:String?
    var status:ConnectionStatus!      // 取引申請ステータス
    var supplier:Supplier?

    init(_ input_dic:[String:Any]) {
        
        if let dic = input_dic["getTradeConnection"] as? [String:Any] {

            supplierId = dic["supplierId"] as? String
            retailerId = dic["retailerId"] as? String
            status = ConnectionStatus(rawValue: dic["connectionStatus"] as? String ?? "UNREQUESTED")
       
            supplier = Supplier(dic["supplier"] as? [String:Any])
        }
    }
}

// MARK: -------------------------------------
// MARK: 取引許可されているサプライヤー

class ConnectedSuppliers:NSObject {
    var list:[Supplier] = []
    var size:Int = 20
    var next:String? = ""
    var hasAllData = false
    var lastNext:String? = ""
    
    public init(size:Int) {
        self.size = size
        list = []
    }
    
    public func reset() {
        hasAllData = false
        next = nil
        
    }
    // 許可状態の取引先だけを返す
    public func getNext() -> Result<[Supplier]?, OrosyError> {
        
        var fin = false
        while !fin {
            
            switch get() {      // 返ってくる数は不定なので,10件以上溜まるか最後まで読むまで繰り返す
            case .success(let item):
                if item.count > 10 || next == nil {
                    fin = true
                }
            case .failure(let err):
                return .failure(err)
            }
            
        }
        return .success(list)
        
    }
    
    private func get() -> Result<[Supplier], OrosyError> {
        
        let graphql =
        """
        query getTradeConnectionsConnectionStatus($connectionStatus: ConnectionStatus!, $limit: Int, $nextToken: String) {
          getTradeConnectionsWithConnectionStatus(connectionStatus: $connectionStatus, isRetailer: true,  limit: $limit, nextToken: $nextToken) {
            tradeConnections {
              supplier {
                id
                brandName
                coverImageUrl
                iconImageUrl
                imageUrls
              }
              connectionStatus
            }
          }
        }
        """
        /*
        """
        query getBrands($limit: Int, $nextToken: String) {
          getTradeConnections(limit: $limit, nextToken: $nextToken)  {
            nextToken
            tradeConnections {
              supplier {
                id
                brandName
                category
                coverImageUrl
                iconImageUrl
                imageUrls
              }
              connectionStatus
            }
          }
        }
        """
         */
        
        var paramDic:[String:Any]!
        
        if let nextStr = next {
            if nextStr == "" {
                paramDic = ["limit" : size, "connectionStatus":"ACCEPTED"]
            }else{
                paramDic = ["limit" : size, "connectionStatus":"ACCEPTED", "nextToken":nextStr]
            }
            
        }else{
            return (.failure(OrosyError.DataReadError))
        }
        
        
        let result = OrosyAPI.callSyncAPI(graphql,variables: paramDic)
        var tempArray:[Supplier] = []
        
        switch result {
        case .success(let resultDic):
            if let result = resultDic["getTradeConnectionsWithConnectionStatus"] as? [String:Any] {
                if let array = result["tradeConnections"] as? [[String:Any]] {
                    for supplier in array {
                        if let sup = Supplier(supplier["supplier"] as? [String:Any]) {
                            var find = false
                            for obj in list {
                                if obj.id == sup.id {
                                    find = true
                                    break
                                }
                            }
                            if !find {
                                tempArray.append(sup)
                            }
                        }
                    }
                }
                next = result["nextToken"] as? String
                if next == nil {
                    hasAllData = true
                }
                list.append(contentsOf: tempArray)
                
                return .success(tempArray)
            }else{
                return .failure(OrosyError.UnknownErrorWithMessage("Key not found"))
            }
        case .failure(let error):
            return .failure(OrosyError.UnknownErrorWithMessage(error.localizedDescription))
        }
        
    }

    public func getSupplier(supplier_id:String) -> Supplier? {
        
        for supplier in list {
            
            if supplier.id == supplier_id {
                return supplier
            }
        }
        
        return nil
    }
}
