//
//  Promotion.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/20.
//

import Foundation


// MARK: -------------------------------------
// MARK: おすすめ
// json形式のデータとして保存されているおすすめ情報のダウンロード

// S3上のファイル名
enum RECOMMEND_TYPE:String {
    case BANNER = "banner.json"
    case WEEKLY_BRAND = "pointReturn.json"
    case RECOMMEND_BRAND = "brand.json"
    case RECOMMEND_ITAKU = "itaku.json"
    case GOOGSLEEP = "googsleep.json"
    case RETAILER_CAMPAIGN = "retailer_campaign_list.json"
    case SUPPLIER_CAMPAIGN = "supplier_campaign_list.json"
}


class Recommend:NSObject {
    var title:String?
    var shortTitle:String?
    var recommendShops:[RecommendShop] = []
    var type:RECOMMEND_TYPE = .RECOMMEND_BRAND
    
    init(_ type:RECOMMEND_TYPE) {
  
        self.type = type
        
    }

    public func getReccomend() -> Result<Any?, OrosyError> {
        
        // 指定されたタイプに該当する jsonファイルをサーバから取得
        let url = URL(string: EXT_S3_SOURCE_BASE_URL + "/" + self.type.rawValue)
        do {
            let jsonData: Data? = try Data(contentsOf: url!)
            let data = try JSONSerialization.jsonObject(with: jsonData!, options: []) as?  [String:Any]
            self.setData(data)
            return .success(nil)
        }catch{
            return .failure(OrosyError.DoesNotExistS3FIle(url?.absoluteString ?? ""))
        }
        
    }
    
    private func setData(_ _input_dic:[String:Any]? ) {
        if let input_dic = _input_dic {
            title = input_dic["title"] as? String   // "おすすめショップ"などの、このグループ全体のタイトル
            shortTitle = input_dic["shortTitle"] as? String
            
            if let shopArray = input_dic["carouselItems"] as? [[String:Any]] {
                var tempArray:[RecommendShop] = []
                
                for shopDic in shopArray {
                    tempArray.append( RecommendShop(shopDic))
                }
                recommendShops = tempArray
            }

        }
    }
}

class RecommendShop:NSObject {
    var shopId:String?
    var title:String?
    var context:String?
    var shop_description:String?
    var imageUrl:URL?
    var linkUrl:String?
    var extendData:AnyObject?  // なんでも入れられる拡張データ


    init (_ _input_dic:[String:Any]? ) {
        if let input_dic = _input_dic {
            title = input_dic["title"] as? String
            linkUrl = input_dic["linkUrl"] as? String
            shopId = String((linkUrl?.split(separator: "/").last)!)
            context = input_dic["context"] as? String
            shop_description = input_dic["description"] as? String
            imageUrl = (input_dic["imageUrl"] as? String == nil) ? nil : URL(string: input_dic["imageUrl"] as! String)
            
        }
    }
}


class SocialUrl:NSObject {
    var category:SocialURLType = .Others
    var url:String?

    init?(_ _input_dic:[String:Any]? ) {
        
        if let input_dic = _input_dic {
            guard let cat = input_dic["category"] as? String else { return nil }

            category = SocialURLType(rawValue: cat) ?? .Others
            url = input_dic["url"] as? String

        }
    }
    
    init(category:SocialURLType, urlString:String) {
        
        self.category = category
        self.url = urlString
    }
}


// MARK: -------------------------------------
// MARK: コンテンツ関連

class Content:NSObject {
    var slug:String?
    var title:String?
    var contentDescription:String?
    var items:[ItemParent] = []   // API上は "items"

    var content_description:String?
    var imageUrl:URL?
    var contentId:String?
    var blogIds:[String] = []        // URLの一部  漢字が使われているのでURL Encodingされている
    var caegory:Category?

    var extendData:AnyObject?  // なんでも入れられる拡張データ

    init(_ input_dic:[String:Any]) {
        title = input_dic["title"] as? String
        contentDescription = input_dic["description"] as? String
        slug = input_dic["slug"] as? String
        content_description = input_dic["description"] as? String
        imageUrl = URL(string: input_dic["imageUrl"] as? String ?? "")
        contentId = input_dic["contentId"] as? String
        blogIds = input_dic["blogIds"] as? [String] ?? []
        
        caegory = Category(input_dic["category"] as? [String:Any])
        
        var tempArray:[ItemParent] = []
        
        if let array = input_dic["items"] as? [[String:Any]] {
            for dic in array {
                if let item = ItemParent(dic) {
                    tempArray.append(item)
                }
            }
            items = tempArray
        }
        tempArray = []
        /*
        if let array = input_dic["itemSegments"] as? [[String:Any]] {
            for dic in array {
                if let item = Item(dic) {
                    tempArray.append(item)
                }
            }
            itemSegments = tempArray
        }
         */
    }
}


enum SHOWCASE_TYPE:String {
    case NEWER = "newer"
    case TOP = "top"
    case MIDDLE = "middle"
}

// トレンド情報
// slug: 表示位置を示す文字列　　　"top", "middle" など・・
class ShowcaseContents:NSObject {
    var slug:SHOWCASE_TYPE!
    var contents:[Content] = []
    
    init?(slug:SHOWCASE_TYPE) {
        super.init()
        
        self.slug = slug
        
        let result = getShowcaseContents(slug.rawValue)
        switch result {
        case .failure(_):
            return nil
        case .success(_):
            break
        }
    }

    private func setData(_ input_dic:[String:Any]) {
        var tempArray:[Content] = []

        let array = input_dic["contents"] as! [[String:Any]]
        for dic in array {
            tempArray.append(Content(dic))
        }
        contents = tempArray
    }

    private func getShowcaseContents(_ slug:String) -> Result<Bool, Error> {
         let graphql = """
        query getShowcaseContents($slug: String!) {
          getShowcaseContents(slug: $slug) {
              contents {
                title
                description
                blogIds
                contentId
                imageUrl
                items {
                   imageUrls
                   id
                   isWholesale
                   supplier {
                      id
                      brandName
                   }
                   item {
                     title
                     id
                     catalogPrice
                     wholesalePrice
                     isWholesale
                   }
                }
              }
            }
          }
        """
        
       // graphql = graphql.replacingOccurrences(of: "$slug", with: "\"\(slug)\"")
        let paramDic = ["slug": slug]
        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        switch result {
        case .success(let resultDic):
            if let sdic = resultDic["getShowcaseContents"] as? [String:Any] {
                self.setData(sdic)
            }
        case .failure(let error):
            return .failure(error)
        }

        // 画像を先読みしてキャッシュへ登録
        DispatchQueue.global().async {
            
            for content in self.contents {
                OrosyAPI.cacheImage(content.imageUrl, imagesize: .Size200)
           }

        }
        
        return .success(true)
    }
}

// 新着のサプライヤー情報
// slug: 表示位置を示す文字列　　　"newer", " など・・
class ShowcaseSuppliers:NSObject {
    var suppliers:[Supplier] = []
    var slug:SHOWCASE_TYPE = .NEWER

    init?(_ slug:SHOWCASE_TYPE) {
        
        self.slug = slug
    }
     
    public func getShowcaseSuppliers() -> Result<[Supplier], OrosyError> {
        /*
            coverImageUrl: ショップページの一番上に表示されるイメージ画像
            category: スポーツなどの文字列でセットされている
        */
        
        let graphql = """
        query getShowcaseSuppliers($slug: String!) {
          getShowcaseSuppliers(slug: $slug) {
            suppliers {
              id
              brandName
              category
              iconImageUrl
              imageUrls

            }
          }
        }
        """
        
        let paramDic = ["slug": self.slug.rawValue]
        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic as [String : Any])
        
        switch result {
        case .success(let resultDic):
            if let sdic = resultDic["getShowcaseSuppliers"] as? [String:Any] {
                if let array = sdic["suppliers"] as? [[String : Any]] {
                    for dic in array {
                        if let sup = Supplier(dic) {
                            self.suppliers.append(sup)
                        }
                    }
                }
            }
        case .failure(let error):
            print(error.localizedDescription)
            return .failure(OrosyError.UnknownErrorWithMessage(error.localizedDescription))
        }
        
        // 画像を先読みしてキャッシュへ登録
        DispatchQueue.global().async {
            for supplier in self.suppliers {
                
                for url in supplier.imageUrls {
                    OrosyAPI.cacheImage(url, imagesize: .Size200)
                }
                OrosyAPI.cacheImage(supplier.coverImageUrl, imagesize: .Size400)
            }
        }
        
        return .success(suppliers)
    }
}

class PersonalReccomend:NSObject {
    var itemParentId:String?
    var itemParent:ItemParent?
    
    init?(_ _input_dic:[String:Any]?) {

        if let input_dic = _input_dic {
            
            itemParentId = input_dic["itemParentId"] as? String
            itemParent = ItemParent(input_dic["itemParent"] as? [String:Any])
        }
    }
}

class PersonalRecommedList:NSObject {
    var list:[PersonalReccomend] = []
    var size:Int = 10
    
    init?( size:Int) {
        
        self.size = size
   
    }
     
    public func getNext() -> Result<[PersonalReccomend], OrosyError> {
        /*
            coverImageUrl: ショップページの一番上に表示されるイメージ画像
            category: スポーツなどの文字列でセットされている
        */
        
        let graphql = """
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
        
        let paramDic = ["size": self.size]
        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic as [String : Any])
        
        switch result {
        case .success(let resultDic):
            if let array = resultDic["getRecommendedItemList"] as? [[String:Any]] {
                var tempArray:[PersonalReccomend] = []
                for sdic in array {
                    if let pr = PersonalReccomend(sdic)  {
                        tempArray.append(pr)
                    }
                }
                list = tempArray
            }
        case .failure(let error):
            print(error.localizedDescription)
            return .failure(OrosyError.UnknownErrorWithMessage(error.localizedDescription))
        }
        /*
        // 画像を先読みしてキャッシュへ登録
        DispatchQueue.global().async {
            for supplier in self.suppliers {
                
                for url in supplier.imageUrls {
                    OrosyAPI.cacheImage(url, imagesize: .Size200)
                }
                OrosyAPI.cacheImage(supplier.coverImageUrl, imagesize: .Size400)
            }
        }
        */
        return .success(list)
    }
}


class TopArticles:NSObject {
    var contentId:String?
    var title:String?
    var item_description:String?
    var imageUrl:URL?

    init(_ input_dic:[String:Any]) {
        
        if let contentsDic = input_dic["getContents"] as? [String:Any] {
            if let array = contentsDic["contents"] as? [[String:Any]] {
                for dic in array {
                    contentId = dic["contentId"] as? String
                    title = dic["title"] as? String
                    item_description = dic["description"] as? String
                    imageUrl = (dic["imageUrl"] as? String == nil) ? nil : URL(string: input_dic["imageUrl"] as! String)
                    
                }
            }
        }
    }
}
