//
//  Delivery.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/20.
//

import Foundation

// MARK: -------------------------------------
// MARK: 配送先

// 配送先
class DeliveryDetail:NSObject {
    var deliveryDetail:String?
    var voucherNumber:String?
    var company:String?
    var url:URL?

    init(_ _input_dic:[String:Any]? ) {

        if let input_dic = _input_dic {
            deliveryDetail = input_dic["deliveryDetail"] as? String
            voucherNumber = input_dic["voucherNumber"] as? String
            company = input_dic["company"] as? String
            url = URL(string: input_dic["url"] as? String ?? "")
        }
    }
}

// 登録されている出荷先リスト
class DeliveryPlaces:NSObject {
    var places:[DeliveryPlace] = []

    public func getDeliveryPlaces() -> Result<[DeliveryPlace] , Error> {
        let graphql = """
        query MyQuery {
          getDeliveryPlaces {
            deliveryPlaces {
              deliveryPlaceId
              name
              ownerId
              shippingAddress {
                town
                townKana
                city
                cityKana
                apartment
                apartmentKana
                postalCode
                prefecture {
                  name
                  id
                  kana
                }
              }
              shippingAddressName
              shippingAddressEtc
              tel
            }
          }
        }
        """
        
        let result = OrosyAPI.callSyncAPI(graphql)
        var tempArray:[DeliveryPlace]  = []
        
        switch result {
        case .success(let resultDic):
            if let sdic = resultDic["getDeliveryPlaces"] as? [String:Any] {
                if let placeList = sdic["deliveryPlaces"] as? [[String:Any]] {
                    for placeDic in placeList {
                        tempArray.append(DeliveryPlace(placeDic))
                    }
                }
            }
            places = tempArray
            return .success(places)
            
        case .failure(let error):
            return .failure(error)
        }
    }

    public func getDeliveryPlaceFrom(id:String?) -> DeliveryPlace? {
        if let _id = id {

            for place in places {
                if place.deliveryPlaceId == _id {
                    return place
                }
            }
        }
        return nil
    }
}

// 商品を販売している店舗の情報（出荷先）
class DeliveryPlace:NSObject {
    var deliveryPlaceId:String?
    var name:String = ""
    var shippingAddress:Address?
    var shippingAddressName:String = ""
    var shippingAddressEtc:String = ""
    var tel:String = ""
    var ownerId:String?


    init(_ _input_dic:[String:Any]? ) {
        if let input_dic = _input_dic {
            deliveryPlaceId = input_dic["deliveryPlaceId"] as? String
            name = input_dic["name"] as? String ?? ""
            shippingAddressName = input_dic["shippingAddressName"] as? String ?? ""
            shippingAddressEtc = input_dic["shippingAddressEtc"] as? String ?? ""
            tel = input_dic["tel"] as? String ?? ""
            ownerId = input_dic["ownerId"] as? String
            shippingAddress = Address(input_dic["shippingAddress"] as? [String:Any])
        }
    }

    
    func copy() -> DeliveryPlace {
    
        let newPlace = DeliveryPlace([:])
        
        newPlace.deliveryPlaceId = self.deliveryPlaceId
        newPlace.name = self.name
        
        if let address = self.shippingAddress {
            newPlace.shippingAddress = address.copy()
        }
        newPlace.shippingAddressName = self.shippingAddressName
        newPlace.shippingAddressEtc = self.shippingAddressEtc
        newPlace.tel = self.tel
        newPlace.ownerId = self.ownerId
            
        return newPlace
    }
    
    // カートへの保存用
    public func setDeliveryPlace() -> Result< Bool, Error> {
        // 配送先を指定
    
        let graphql = """
        mutation cartSetShippingAddress($shippingAddress: DeliveryPlaceInput!) {
          cartSetShippingAddress(shippingAddress: $shippingAddress) {
            retailerId
            shippingInfo {
              shippingAddress {
                postalCode
                prefecture {
                  id
                  name
                  kana
                }
                city
                town
                apartment
                cityKana
                townKana
                apartmentKana
              }
            }
          }
        }
        """
         
        
        guard let ad = self.shippingAddress else { return .failure(OrosyError.UnknownAddress) }
        guard let prefec = ad.prefecture else { return .failure(OrosyError.UnknownPrefecture) }
        guard let ownerId = self.ownerId else { return .failure(OrosyError.UnknownOwnerId) }
     
    
        let paramDic:[String:Any] =
        ["shippingAddress":
                ["shippingAddress":
                    [
                        "postalCode" : ad.postalCode, "city" : ad.city, "cityKana" : ad.cityKana, "apartment" : ad.apartment, "apartmentKana" : ad.apartmentKana, "town" : ad.town, "townKana" : ad.townKana,
                        "prefecture" : ["name": prefec.name, "id" : prefec.id, "kana" : prefec.kana]
                    ],
                    "name":name, "shippingAddressName":shippingAddressName, "shippingAddressEtc":shippingAddressEtc,"ownerId":ownerId,"tel":tel
                ],
         ]
           
        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)     // 配送先を指定するだけ
       
        
        switch result {
        case .success(_):
            return .success(true)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // プロフィールの更新用
    public func updateDeliveryPlace() -> Result< Bool, Error> {
        // 配送先を指定
    
        let graphql = """
            mutation updateDeliveryPlace( $deliveryPlaceDic : DeliveryPlaceInput! ) {
              updateDeliveryPlace(deliveryPlace: $deliveryPlaceDic) {
                    deliveryPlaceId
                    name
            }
        }
        """
        
        /*
         input DeliveryPlaceInput {
           deliveryPlaceId: String
           ownerId: String
           name: String
           tel: String
           shippingAddress: AddressInput
           shippingAddressName: String
           shippingAddressEtc: String
           createdAt: AWSDateTime
           modifiedAt: AWSDateTime
         }
         */
        
        guard let deliveryId = self.deliveryPlaceId else { return .failure(OrosyError.UnknownAddress) }
        guard let ad = self.shippingAddress else { return .failure(OrosyError.UnknownAddress) }
        guard let prefec = ad.prefecture else { return .failure(OrosyError.UnknownPrefecture) }
    

        
        let paramDic:[String:Any] =
        ["deliveryPlaceDic":
            [
                "deliveryPlaceId" : deliveryId ,
                "name":name,
                "shippingAddressName": self.shippingAddressName,
                "shippingAddressEtc": self.shippingAddressEtc,
                "tel":self.tel,
                "shippingAddress": [
                    "postalCode" : ad.postalCode, "city" : ad.city, "cityKana" : ad.cityKana, "apartment" : ad.apartment, "apartmentKana" : ad.apartmentKana, "town" : ad.town, "townKana" : ad.townKana,
                    "prefecture" : [
                        "name": prefec.name, "id" : prefec.id, "kana" : prefec.kana
                    ]
                ]
     
            ]
        ]
           
        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
       
        switch result {
        case .success(_):
            return .success(true)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func createDeliveryPlace() -> Result< Bool, Error> {
        // 配送先を指定
    
        let graphql = """
            mutation createDeliveryPlace( $deliveryPlaceDic : DeliveryPlaceInput! ) {
              createDeliveryPlace(deliveryPlace: $deliveryPlaceDic) {
                    deliveryPlaceId
            }
        }
        """
         
        guard let ad = self.shippingAddress else { return .failure(OrosyError.UnknownAddress) }
        guard let prefec = ad.prefecture else { return .failure(OrosyError.UnknownPrefecture) }

        
        let paramDic:[String:Any] =
        ["deliveryPlaceDic":
            [
                "name":name,
                "shippingAddressName": self.shippingAddressName,
                "shippingAddressEtc": self.shippingAddressEtc,
                "tel":self.tel,
                "shippingAddress": [
                    "postalCode" : ad.postalCode, "city" : ad.city, "cityKana" : ad.cityKana, "apartment" : ad.apartment, "apartmentKana" : ad.apartmentKana, "town" : ad.town, "townKana" : ad.townKana,
                    "prefecture" : [
                        "name": prefec.name, "id" : prefec.id, "kana" : prefec.kana
                    ]
                ]
            ]
        ]
           
        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
       
        switch result {
        case .success(_):
            return .success(true)
        case .failure(let error):
            return .failure(error)
        }
    }
}

class DeliverTo:NSObject {
    var name:String?        // 発送先名称
    var shopId:String?
    var statusShopVerify:String?
    var createdAt:Date?
    var shippingAddress:Address?
    var shippingAddressName:String?     // 発送先の担当者名
    var shippingAddressEtc:String?

    init(_ _input_dic:[String:Any]? ) {

        if let input_dic = _input_dic {
            name = input_dic["name"] as? String
            shopId = input_dic["shopId"] as? String
            statusShopVerify = input_dic["statusShopVerify"] as? String
            createdAt = Util.dateFromUTCString(input_dic["createdAt"] as? String)
            shippingAddressName = input_dic["shippingAddressName"] as? String
            shippingAddressEtc = input_dic["shippingAddressEtc"] as? String
            shippingAddress = Address(input_dic["shippingAddress"] as? [String:Any])
        }
    }
}




// MARK: 配送条件
class ShippingFeeRules:NSObject {
    var amount:NSDecimalNumber = .zero
    var triggerCount:NSDecimalNumber = .zero
    var trigger:String?
    var type:String?

    init(_ _input_dic:[String:Any]? ) {
        if let input_dic = _input_dic {
            amount = NSDecimalNumber(value: input_dic["amount"] as? Int ?? 0)
            triggerCount = NSDecimalNumber(value: input_dic["triggerCount"] as? Int ?? 0)
            trigger = input_dic["trigger"] as? String
            type = input_dic["type"] as? String             //  送料無料の場合は　'free'がセットされている。
        }
    }

}

// エリア毎の配送料金
class ShippingFeeToArea:NSObject {
    var amount:NSDecimalNumber = .zero
    var name:String?
    var prefectures:[Prefecture] = []

    init(_ _input_dic:[String:Any]? ) {
        if let input_dic = _input_dic {
            amount = NSDecimalNumber(value: input_dic["amount"] as? Int ?? 0)
            name = input_dic["name"] as? String
            
            var tempArray:[Prefecture] = []
            
            if let array = _input_dic!["prefectures"] as? [[String:Any]] {
                for dic in array {
                    if let pref = Prefecture(dic) {
                        tempArray.append(pref)
                    }
                }
            }
        }
    }
}

