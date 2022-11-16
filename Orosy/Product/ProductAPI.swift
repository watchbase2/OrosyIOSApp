//
//  Product.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/20.
//

import Foundation
import Amplify

// MARK: -------------------------------------
// MARK: 商品情報
// 商品単体の情報
class Item:NSObject {
    var id:String
    var title:String?
    var productNumber:String?
    var item_description:String?
    var jancode:String?
    var isWholesale:Bool = false
    var isConsignment:Bool = false
    var isPl:Bool = false
    var supplier:Supplier?
    var categoryNo:String?
    var catalogPrice:NSDecimalNumber = .zero
    var consignmentPrice:NSDecimalNumber = .zero
    var wholesalePrice:NSDecimalNumber = .zero
    var tax:Int = 0
    var imageUrls:[URL] = []
    var setQty:Int = 0
    var inventoryQty:Int = 0
    var minLotQty:Int = 0
    var size:String?
    var variation1Label:String? // バリエーション項目名
    var variation1Value:String?
    var variation2Label:String?
    var variation2Value:String?
    var precaution:String?
    var specification:String?
    var explanation:String?
    var ecUrl:URL?
    var requirement:String?
    
    init(title:String) {

        id = "*"    // for favorit fallback data
        self.title = title
    }
    
    init?(_ _input_dic:[String:Any]? ) {
        
        if let input_dic = _input_dic {
            
            guard let _id = input_dic["id"] as? String else{ return nil }
            id = _id

            isWholesale = input_dic["isWholesale"] as? Bool ?? false
            /*
            if !isWholesale {
                return nil
            }      // 委託商品は使わない
            */
            
            title = input_dic["title"] as? String
            item_description = input_dic["description"] as? String
            productNumber = input_dic["productNumber"] as? String
            jancode = input_dic["jancode"] as? String
            wholesalePrice = NSDecimalNumber(value:input_dic["wholesalePrice"] as? Int ?? .zero)
            catalogPrice = NSDecimalNumber(value:input_dic["catalogPrice"] as? Int ?? .zero)
         //   consignmentPrice = NSDecimalNumber(value:input_dic["consignmentPrice"] as? Int ?? .zero)
            tax = input_dic["tax"] as? Int ?? 0

            
         //   isConsignment = input_dic["isConsignment"] as? Bool ?? false
            isPl = input_dic["isPl"] as? Bool ?? false
            categoryNo = input_dic["categoryNo"] as? String
            setQty = input_dic["setQty"] as? Int ?? 0
            inventoryQty = input_dic["inventoryQty"] as? Int ?? 0
            minLotQty = input_dic["minLotQty"] as? Int ?? 0
            /*
            variation1Label = input_dic["variation1Label"] as? String
            variation1Value = input_dic["variation1Value"] as? String
            variation2Label = input_dic["variation2Label"] as? String
            variation2Value = input_dic["variation2Value"] as? String
             */
            variation1Label = input_dic["variation1Label"] as? String
            variation1Value = input_dic["variation1Value"] as? String
            variation2Label = input_dic["variation2Label"] as? String
            variation2Value = input_dic["variation2Value"] as? String
            
            if variation1Label == nil || variation1Value == nil {
                variation1Label = variation2Label
                variation1Value = variation2Value
                variation2Label = nil
                variation2Value = nil
            }
            
            if variation1Value == nil {
                variation1Label = nil
            }
            if variation2Value == nil {
                variation2Label = nil
            }
            
            
            precaution = input_dic["precaution"] as? String
            specification = input_dic["specification"] as? String
            explanation = input_dic["explanation"] as? String
            ecUrl = URL(string: input_dic["ecUrl"] as? String ?? "")
            size = input_dic["size"] as? String
            requirement = input_dic["requirement"] as? String
            
            supplier = Supplier(input_dic["supplier"] as? [String:Any])
            
            if let urlArray = input_dic["imageUrls"] as? [String] {
                for urlString in urlArray {
                    let imageUrl  = URL(string: urlString)
                    if imageUrl != nil {
                        imageUrls.append(imageUrl!)
                    }
                }
            }
        }else{
            return nil
        }
    }

    // カートへ入れる
    // 同一商品で複数の販売形式（買取、委託）に対応しているものがあるため、販売形式の指定が必要
    public func addCart( quantity: Int, saleType: SaleType)  -> Result<Bool, OrosyError>  {
        
        let graphql = """
        mutation ($itemId: String!, $quantity: Int!, $saleType: String! ){
            addCartItem(itemId: $itemId, quantity: $quantity, saleType: $saleType){
            cartItems {
              amount
              id
              price
              quantity
              saleType
              taxAmount
            }
            deposit
            discount
            retailerId
            totalAmount
            totalItemPrice
            totalShippingFeeAmount
          }
        }
        """
        
        let paramDic:[String:Any] = ["itemId" : id, "quantity" : quantity, "saleType" : saleType.rawValue]
        let result = OrosyAPI.callSyncAPI(graphql, variables:paramDic)
        
        switch result {
        case .success(_):
            return .success(true)
        case .failure(let error):
            let msg = (error as! AmplifyError).errorDescription
            // 在庫切れのエラーメッセージを検出し、商品を特定する
            if msg.contains("out of stock") {
                return .failure(OrosyError.NotEnoughInventory(self.title ?? ""))
            }

            return .failure(OrosyError.UnknownErrorWithMessage(error.localizedDescription))
        }
    }
}


class ItemParent:NSObject {
    var id:String = ""
    var imageUrls:[URL] = []
    var item:Item?
    var supplier:Supplier?
    var variationItems:[Item] = []  // バリエーション分のアイテム情報
    var category:Category?
    var isFavorite:Bool = false
    var extendData:AnyObject?   // なんでも入れられる拡張データ
 //   var isWholesale:Bool = false
 //   var isConsignment:Bool = false
    
    init(id:String) {
        self.id = id
    }
    
    init?(_ _input_dic:[String:Any]? ) {
        super.init()
        
        if !self.setData(_input_dic) {
            return nil
        }
    }

    func setData(_ _input_dic:[String:Any]? ) -> Bool {
        if let input_dic = _input_dic {
            guard let _id = input_dic["id"] as? String else{ return false }
            self.id = _id
         //   self.isWholesale = input_dic["isWholesale"] as? Bool ?? false
         //   self.isConsignment = input_dic["isConsignment"] as? Bool ?? false
            
            if let itemDic = input_dic["item"] as? [String:Any] {
                self.item = Item(itemDic)
            }
            
            if let urlArray = input_dic["imageUrls"] as? [String] {
                for urlString in urlArray {
                    let imageUrl  = URL(string: urlString)
                    if imageUrl != nil {
                        self.imageUrls.append(imageUrl!)
                    }
                }
            }
  
            if let supDic = input_dic["supplier"] as? [String:Any] {
                self.supplier = Supplier( supDic)
            }
            
            // variationItemsは買取のみを残す
            if let array = input_dic["variationItems"] as? [[String:Any]] {
                var temp:[Item] = []
                for dic in array {
                    if let item = Item(dic) {
                      if item.isWholesale {
                          temp.append(item)    // isWholesale が falseの場合には追加しない
                       }
                    }
                }
                self.variationItems = temp
                if self.variationItems.count == 0 {
                    return false    // 委託を取り除いたらゼロになった
                }
                
                // 代表商品が委託なら、variationItemsから取ってくる（この時点では、variationItemsに入っているのは買取のみになっている）
                if self.item?.isWholesale == false {
                    self.item  = self.variationItems.first   // variationItemsにはcatalogPritaxは入っていないので、元の情報をコピーしておく
                }
            }
            if let categoryDic = input_dic["category"] as? [String:Any] {
                self.category = Category(categoryDic)
            }
            
            self.isFavorite = input_dic["isFavorite"] as? Bool ?? false
            
            // v1 では、APIからはお気に入りのフラグは返らないので、お気に入りリストの内容と付き合わせてセットする
            for favorite in g_favoriteItems {
                if !favorite.isHidden {
                    let itemParent = favorite.itemParent
               
                    if self.id == itemParent?.id ?? "" {
                        self.isFavorite = favorite.isFavorite   // 通常はg_favoriteItemsに入っているItemのisFavoriteは trueだが、お気に入り画面でお気に入りから外した直後は falseになっていることがあるので、フラグをコピーしている
                        break
                    }
                }
            }
            
            return true
        }else{
            return false
        }
    }

    init?(itemParentId: String) {
        
        super.init()
        
        if !self.getItemParent(itemParentId) {
            return nil
        }
        
    }

    public func getItemParent(_ _itemParentId:String? = nil) -> Bool {
        var itemParentId = _itemParentId
        
        if itemParentId == nil { itemParentId = self.id }
        
        let graphql = """
        query ($itemParentId: String!) {
          getItemParent(itemParentId: $itemParentId) {
                id
                category {
                    name
                    categoryNo
                    id
                }
                supplier {
                  brandName
                  id
                  imageUrls
                }
                item {
                    title
                    catalogPrice
                    categoryNo
                    consignmentPrice
                    description
                    ecUrl
                    explanation
                    id
                    isConsignment
                    inventoryQty
                    jancode
                    isWholesale
                    isPl
                    minLotQty
                    precaution
                    productNumber
                    requirement
                    searchWord1
                    searchWord2
                    searchWord3
                    searchWord4
                    setQty
                    size
                    specification
                    tags
                    tax
                    variation1Label
        　　　　　　　 variation1Value
                    variation2Label
                    variation2Value
                    wholesalePrice
                    
                }
                imageUrls
                isPublic
                isWholesale
                isConsignment
                variationItems {
                    title
                    catalogPrice
                    categoryNo
                    consignmentPrice
                    description
                    ecUrl
                    explanation
                    id
                    isConsignment
                    inventoryQty
                    jancode
                    isWholesale
                    isPl
                    minLotQty
                    precaution
                    productNumber
                    requirement
                    searchWord1
                    searchWord2
                    searchWord3
                    searchWord4
                    setQty
                    size
                    specification
                    tags
                    tax
                    variation1Label
        　　　　　　　 variation1Value
                    variation2Label
                　　 variation2Value
                    wholesalePrice
                }
            }
        }
        """;
        
        let paramDic = ["itemParentId" :itemParentId]
        
        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        
        switch result {
        case .success(let resultDic):
            if !self.setData(resultDic["getItemParent"] as? [String:Any] ?? [:]) {
                return false
            }
            return true
            
        case .failure(_):
            return false
        }

    }
        
}

class AllItems:NSObject {
    var list:[ItemParent] = []

    public func fetch(from:Int, size:Int) -> (Int, Int) {

        let graphql =
        """
        query getItems( $from: Int, $size: Int) {
          getItems(from: $from, size: $size) {
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
              description
              productNumber
              tax
              wholesalePrice
              consignmentPrice
              catalogPrice
              isWholesale
              isConsignment
              setQty
              minLotQty
              inventoryQty
              isPl
              jancode
              supplier {
                id
                brandName
                coverImageUrl
                iconImageUrl
                category
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
        }
        """

        var total:Int = 0
        var tempArray:[ItemParent] = []

        let paramDic = ["from" : from, "size": size]

        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        
        switch result {
        case .success(let resultDic):
            if let result = resultDic["getItems"] as? [String:Any] {
                let pageInfoDic = result["pageInfo"] as? [String:Any]
              //  count = pageInfoDic?["count"] as? Int ?? 0    // 読み出した件数
                total = pageInfoDic?["total"] as? Int ?? 0

                
                if let items = result["items"] as? [[String:Any]] {
                    for itemDic in items {
                        
                        if let itemParents = ItemParent(itemDic) {
                            tempArray.append(itemParents)
                        }
                    }
                }
            }
        case .failure(_):
            return (0, 0)
        }
        
        self.list.append(contentsOf: tempArray)
        
        return (tempArray.count, total)
                                                    
    }
    
    public func fetchSuppliers(from:Int, size:Int) -> (Int, Int) {

        let graphql =
        """
        query getItems( $from: Int, $size: Int) {
          getItems(from: $from, size: $size) {
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
              description
              tax
              wholesalePrice
              consignmentPrice
              catalogPrice
              isWholesale
              isConsignment
              setQty
              minLotQty
              inventoryQty
              isPl
              jancode
              supplier {
                id
                brandName
                coverImageUrl
                iconImageUrl
                category
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
        }
        """

        var total:Int = 0
        var tempArray:[ItemParent] = []

        let paramDic = ["from" : from, "size": size]

        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        
        switch result {
        case .success(let resultDic):
            if let result = resultDic["getItems"] as? [String:Any] {
                let pageInfoDic = result["pageInfo"] as? [String:Any]
              //  count = pageInfoDic?["count"] as? Int ?? 0    // 読み出した件数
                total = pageInfoDic?["total"] as? Int ?? 0

                
                if let items = result["items"] as? [[String:Any]] {
                    for itemDic in items {
                        
                        if let itemParents = ItemParent(itemDic) {
                            tempArray.append(itemParents)
                        }
                    }
                }
            }
        case .failure(_):
            return (0, 0)
        }
        
        self.list.append(contentsOf: tempArray)
        
        return (tempArray.count, total)
                                                    
    }
    
}

//　指定した商品に関連するリコメンド商品を取得
// getRecommendedItemIdList+getItemsByItemIds に変える？

class RecommendedItems:NSObject {
    var list:[ItemParent] = []
    var itemIds:[[String:String]] = []
    var curenntPointer:Int = 0

    func getRecommendedItemListByItemId(size:Int, itemId:String = "") ->  [ItemParent] {
        var graphql:String!
        var paramDic:[String: Any]!
        var key:String!
        
        if itemId == "" {
            key = "getRecommendedItemIdList"
            graphql =
            """
             getRecommendedItemIdList(limit: $size) {
                itemParentId
             }
            """
            paramDic = ["size": size]
            
            /*
            key = "getRecommendedItemList"
            graphql =
             """
             query getRecommendedItemList($size: Int) {
              getRecommendedItemList(limit: $size) {
                itemParentId
                itemParent {
                  id
                  imageUrls
                  supplier {
                    id
                    brandName
                  }
                  item {
                    id
                    title
                    catalogPrice
                    wholesalePrice
                    supplier {
                      id
                      brandName

                    }
                    isConsignment
                    isWholesale
                  }
                }
              }
            }
            """
            paramDic = ["limit": size]
             */
            
        }else{
            //　商品一覧用
            key = "getRecommendedItemListByItemId"
           graphql =
                """
            query getRecommendedItemListByItemId($itemId: String, $size: Int) {
              getRecommendedItemListByItemId(itemId: $itemId, limit: $size) {
                itemParentId
                itemParent {
                  id
                  imageUrls
                  supplier {
                    id
                    brandName
                  }
                  item {
                    id
                    title
                    catalogPrice
                    wholesalePrice
                    supplier {
                      id
                      brandName
                    }
                    isConsignment
                    isWholesale
                    tags
                  }
                }
              }
            }
            """
            paramDic = ["itemId" : itemId, "size": size]
            
        }

        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        var tempArray:[ItemParent] = []

        switch result {
        case .success(let resultDic):
            if let results = resultDic[key] as? [[String:Any]] {
                
                for dic in results {
                    
                    if let itemDic = dic["itemParent"] as? [String:Any] {
                        if let itemParents = ItemParent(itemDic) {
                            tempArray.append(itemParents)
                        }
                    }
                }
                self.list = tempArray
                return tempArray
                
            }
        case .failure(let error):
            return []
        }
        
        return []
    }
    
    func getReccomendedItems(size:Int) -> [[String:String]] {
        
        let graphql =
        """
        query getRecommendedItemIdList($size: Int) {
          getRecommendedItemIdList(limit: $size) {
            itemParentId
          }
        }
        """
        let paramDic = ["size": size]
        
        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
   
        switch result {
        case .success(let resultDic):
            if let results = resultDic["getRecommendedItemIdList"] as? [[String:String]] {
                
                var tempArray:[[String:String]] = []
                
                for dic in results {
                    /*
                    if let itemParentId = dic["itemParentId"] as? String {
                        tempArray.append(itemParentId)
                    }
                     */
                    tempArray.append(dic);
                    
                }
                
                self.itemIds = tempArray
                
                return tempArray
            }
        case .failure(let error):
            return []
        }
        return []
    }
    
    func getItemsByItemIds(itemIds:[[String:String]]) -> [ItemParent] {
        let graphql =
        """
         query getItemsByItemIds($itemParentIds: [ItemParentIdInput]!) {
           getItemsByItemIds(itemParentIds: $itemParentIds) {
             itemParentId
              itemParent {
               id
               imageUrls
               supplier {
                 id
                 brandName
               }
               item {
                 id
                 title
                 catalogPrice
                 wholesalePrice
                 supplier {
                   id
                   brandName
                 }
                 isConsignment
                 isWholesale
               }
             }
           }
         }

         """
         let paramDic = ["itemParentIds" : itemIds]
         
    
         let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
         var tempArray:[ItemParent] = []

         switch result {
         case .success(let resultDic):
             if let results = resultDic["getItemsByItemIds"] as? [[String:Any]] {
                 
                 for dic in results {
                     if let itemDic = dic["itemParent"] as? [String:Any] {
                         if let itemParents = ItemParent(itemDic) {
                             tempArray.append(itemParents)
                         }
                     }
                 }
                 list.append(contentsOf: tempArray)
                 return tempArray
             }
         case .failure(let error):
             return []
         }
        return []
    }
}

