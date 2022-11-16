//
//  RetailerAPI.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/05/15.
//

import Foundation
import UIKit

enum NumberOfStores:String, CaseIterable {
    case SMALL = "SMALL"
    case MEDIUM  = "MEDIUM"
    case LARGE = "LARGE"
    case EXTRALARGE = "EXTRALARGE"
}

enum RealShopMainCategory:String {
    case RETAIL = "retail"
    case SERVICE = "service"
}


enum RetailerImageDocumentType:String {
    case retailerShop = "retailerShop"
    case retailerShops = "retailerShops"
    case tdShop = "tdShop"
    case retailerHeader = "retailerHeader"
    case retailerImages = "retailerImages"
    case retailerLogo = "retailerLogo"
    case tdProfilePersonal = "tdProfilePersonal"
    case tdProfileBusiness = "tdProfileBusiness"
}

final class RetailerDetail:NSObject {
    
    public static let shared = RetailerDetail()
    
    var hasInputDone:Bool {
        get {

            getData()
            
            var done = true
            
            if (shopName ?? "").count == 0 || headerImage == nil || logoImage == nil {
                done = false
            }
            if haveRealShop && (numberOfStores == nil || shopImages == nil) {
                done = false
            }
            
            return done
        }
    }
    
    var created:Bool = false      // false: retailerDetailは未作成　-> create()する必要がある
    var shopName:String?
    var logoImage:URL?
    var salesFormOffline:Bool = false
    var salesFormOnline:Bool = false
    var openingYear:Int = 0
    var annualSales:Int = 0
    var categoryMain:RealShopMainCategory?
    var categorySub:String?
    var shopImages:[URL] = []
    var headerImage:URL?
    var concept:String?
    var customerType:String?
    var amountPerCustomer:Int = 0
    var haveRealShop:Bool = false
    var shopUrl:URL?
    var shopUrls:[SocialUrl] = []
    var numberOfStores:NumberOfStores?


    private override init() {}
    
    
    public func getData() {
        
        let graphql = """
        query retailerDetail{
          retailerDetail {
            shopName
            logoImage
            salesFormOffline
            salesFormOnline
            openingYear
            annualSales
            categoryMain
            categorySub
            shopImages
            headerImage
            concept
            customerType
            annualSales
            amountPerCustomer
            haveRealShop
            shopUrl
            shopUrls {
              category
              url
            }
            numberOfStores
          }
        }
        """

        let result = OrosyAPI.callSyncAPI(graphql)
        
        switch result {
        case .success(let resultDic):
            if let input_dic = resultDic["retailerDetail"] as? [String:Any] {
                
                shopName = input_dic["shopName"] as? String
                logoImage = (input_dic["logoImage"] as? String == nil) ? nil : URL(string: input_dic["logoImage"] as! String)
                salesFormOffline = input_dic["salesFormOffline"] as? Bool ?? false
                salesFormOnline = input_dic["salesFormOnline"] as? Bool ?? false
                openingYear = input_dic["openingYear"] as? Int ?? 0
                annualSales = input_dic["annualSales"] as? Int ?? 0
                categoryMain =  RealShopMainCategory(rawValue:  input_dic["categoryMain"] as? String ?? "retail")
                categorySub = input_dic["categorySub"] as? String
                if let array = input_dic["shopImages"] as? [String] {
                    for urlString in array {
                        if let url = URL(string: urlString) {
                            shopImages.append(url)
                        }
                    }
                }
                
                headerImage =  (input_dic["headerImage"] as? String == nil) ? nil : URL(string: input_dic["headerImage"] as! String)
                
                if let array = input_dic["shopImages"] as? [String] {
                    var tempArray:[URL] = []
                    for urlStr in array {
                        if let url = URL(string:urlStr) {
                            tempArray.append(url)
                        }
                    }
                    shopImages = tempArray
                }
                
                concept = input_dic["concept"] as? String
                customerType = input_dic["customerType"] as? String
                amountPerCustomer = input_dic["amountPerCustomer"] as? Int ?? 0
                haveRealShop = input_dic["haveRealShop"] as? Bool ?? false
                shopUrl = URL(string: input_dic["shopUrl"] as? String ?? "")
                
                if let array = input_dic["shopUrls"] as? [[String:Any]] {
                    var tempArray:[SocialUrl] = []
                    
                    for socialDic in array {
                        if let social = SocialUrl(socialDic) {
                            tempArray.append(social)
                            
                        }
                    }
                    shopUrls = tempArray
                }
                numberOfStores = NumberOfStores(rawValue: input_dic["numberOfStores"] as? String ?? NumberOfStores.SMALL.rawValue)     // "SMALL"のような文字がセットされている？
                self.created = true
            }
            
        case .failure(_):
            break
        }
    }
    
    func update( ) -> Result<[String:Any], Error> {
        
        var graphql = """
        mutation retailer( $retailer: RetailerInput! ) {
                  $cmd( retailer: $retailer ) {
            shopName
          }
        }
        """
        
        let cmdStr = (created) ? "updateRetailer" : "createRetailer"
 
        graphql = graphql.replacingOccurrences(of: "$cmd", with: cmdStr)
 
    
        /*
         input RetailerInput {
           shopName: String
           logoImage: String
           salesFormOffline: Boolean
           salesFormOnline: Boolean
           openingYear: Int
           annualSales: Long
           categoryMain: String
           categorySub: String
           haveRealShop: Boolean
           shopUrl: String
           numberOfStores: NumberOfStores
           headerImage: String
           shopImages: [String]
           concept: String
           customerType: String
           amountPerCustomer: Int
           shopUrls: [UrlsInput]
         }
         */
        
        
        var shopUrlDic:[[String:String]] = []
        
        for social in self.shopUrls {
            let dic = ["category":social.category.rawValue , "url":social.url ?? ""]
            shopUrlDic.append(dic)
        }
        
        var paramDic:[String:Any] = ["shopName" : self.shopName ?? "", "annualSales":self.annualSales , "haveRealShop": self.haveRealShop,  ]
        
        if self.logoImage != nil {
            let url = self.logoImage?.absoluteString
            paramDic["logoImage"] = url
        }
        if self.headerImage != nil {
            let url = self.headerImage?.absoluteString
            paramDic["headerImage"] = url
        }
        if self.shopImages.count > 0 {
            var tempArray:[String] = []
            for url in shopImages {
                tempArray.append( url.absoluteString)
            }
            paramDic["shopImages"] = tempArray
            
            /*
             if let array = input_dic["shopImages"] as? [String] {
                 var tempArray:[URL] = []
                 for urlStr in array {
                     if let url = URL(string:urlStr) {
                         tempArray.append(url)
                     }
                 }
                 shopImages = tempArray
             }
             */
        }
        if self.shopUrls.count > 0 { paramDic["shopUrls"] = shopUrlDic }
        if self.categoryMain != nil {paramDic["categoryMain"] = (self.categoryMain ?? .RETAIL).rawValue }
        if self.categorySub != nil { paramDic["categorySub"] = self.categorySub ?? "" }
        if self.numberOfStores != nil { paramDic["numberOfStores"] = self.numberOfStores?.rawValue ?? ""}
        if self.concept != nil { paramDic["concept"] = self.concept ?? ""}
        if self.customerType != nil { paramDic["customerType"] = self.customerType ?? ""}
        paramDic["openingYear"] = self.openingYear
        paramDic["amountPerCustomer"] = self.amountPerCustomer
        
       // paramDic = ["categoryMain": "fasion","shopName": "oro"]
        let result = OrosyAPI.callSyncAPI(graphql, variables:["retailer": paramDic])
    
        switch result {
        case .success(let resultDic):
            let dic = resultDic[cmdStr] as? [String:Any] ?? [:]
            self.created = true
            return .success(dic)
        case .failure(let error):
            return .failure(error)
        }
    }

    
    
    func saveImage(type:RetailerImageDocumentType, image:UIImage, position:Int = 0, complete: @escaping (String?) -> Void) {
        
        let result:Result = getNewImagePath(imageType:type, position:position)
        
        switch result {
        case .success(let dic):
            let getUrl = dic["getUrl"]
            let putUrl = dic["putUrl"]
            
            if let url = URL(string: putUrl ?? "") {
                var jpegData:Data!
                
                var size = 6*1024*1024 + 1
                var quality:CGFloat = 1
                while size > 6*1024*1024 {
                    jpegData = image.jpegData(compressionQuality: quality)
                    quality = quality * 0.9
                    size = jpegData.count
                }
                
                self.fileUpload(url, data: jpegData ) { (error) in
                    if error == nil {
                        complete (getUrl)
                    } else {
                        complete (nil)
                    }
                }
            }else{
                complete (nil)
            }

        case .failure(_):
            complete (nil)
        }
      
    }
    
        
    func fileUpload(_ url: URL, data: Data,completion: @escaping ( Error?) -> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"      //  これ注意！　POSTではなく、PUTにする必要がある

        let headers = ["Content-Type": "image/jpeg", "Accept": "application/json"]
        let urlConfig = URLSessionConfiguration.default
        urlConfig.httpAdditionalHeaders = headers
         
        let session = Foundation.URLSession(configuration: urlConfig)

        let task = session.uploadTask(with: request,from: data) { data, response, error in
                         
            if (error != nil) {
                  print(error!.localizedDescription)      // タイムアウトになると、ここでエラーになる
                  completion(nil)
                  return
            }else{
         
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func getNewImagePath(imageType:RetailerImageDocumentType, position:Int ) -> Result<[String:String], Error > {
        
        let graphql =
        """
        query getUrlsToPutGetS3(
          $type: String!
          $mediaType: String!
          $params: [String]
        ) {
          getUrlsToPutGetS3(
            input: {
              type: $type
              mediaType: $mediaType
              params: $params
            }
          ) {
            getUrl
            putUrl
            documentPath
          }
        }

        """
        
        var paramDic:[String:Any] = ["type":imageType.rawValue, "mediaType":"image/jpeg"]
        if imageType == .retailerShops {
            paramDic["params"] = [String(position)]
        }
        
        let result = OrosyAPI.callSyncAPI(graphql, variables:paramDic )
    
        switch result {
        case .success(let resultDic):
            if let dic = resultDic["getUrlsToPutGetS3"] as? [String:String] {
                return .success(dic)
            }else{
                return .failure(OrosyError.UnknownOwnerId)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func reset() {
        created = false      // false: retailerDetailは未作成　-> create()する必要がある
        shopName = ""
        logoImage = nil
        salesFormOffline = false
        salesFormOnline = false
        openingYear = 0
        annualSales = 0
        categoryMain = nil
        categorySub = nil
        shopImages = []
        headerImage = nil
        concept = nil
        customerType = nil
        amountPerCustomer = 0
        haveRealShop = false
        shopUrl = nil
        shopUrls = []
        numberOfStores = nil
        
    }
}
