//
//  Profile.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/20.
//

import Foundation
import Amplify
import AmplifyPlugins

// MARK: -------------------------------------
// MARK: プロフィール

enum ProfileStatus:String {
    case approved = "approved"
    case requested = "requested"
    case unDefined = "unDefined"
    case denied = "denied"
}

enum ProfileTdStatus:String {
  case Preparing = "preparing"
  case Requested = "requested"
  case Approved = "approved"
  case Denied = "denied"
  case unDefined = "unDefined"
}

enum BusinessFormat:String {
    case parsonal = "parsonal"
    case business = "business"
    case none = "none"
}

final class ProfileDetail:NSObject {
    
    public static let shared = ProfileDetail()
    
    var created:Bool = false      // false: retailerDetailは未作成　-> create()する必要がある
    
    var hasInputDone:Bool {
        get {
            if profiled { return true }
            
            getData()
            
            var done = true
            
            if (accountLastName ?? "").count == 0 || (accountFirstName ?? "").count == 0 || (tel ?? "").count == 0 || businessFormat == .none || (companyName ?? "").count == 0 ||
                (telRepresentative ?? "").count == 0 || !(address?.hasDone ?? false) || (telRepresentative ?? "") .count == 0 {
                done = false
            }
            
            profiled = done
            
            return done
        }
    }
    
    var profiled = false
    
    var firstName:String?
    var lastName:String?
    var tel:String?
    var email:String?
    var companyName:String?
    var address:Address?
    var telRepresentative:String?
    /*
    trustdockを廃止したので新しく登録されるユーザはstatusVerifyは見る必要がないのですが、
    既存のpreparingのユーザは中途半端に情報が登録されているため申請が必要になるように個別に制御を入れています。
    */
    var statusVerify:ProfileTdStatus = .unDefined
    
    var npStatus:ProfileStatus = .unDefined
    var npBuyerId:String?
    var brokerStatus:ProfileStatus = .unDefined
    var userId:String?   // userId は profile attributeから取得している
    var hpUrl:URL?
    var hpUrlString:String? // work用
    var bank:Bank?
    var personal:Personal?
    var business:Business?
    var staff:Staff?
    var businessDocTemp:String?
    var accountLastName:String?
    var accountFirstName:String?
    var businessFormat:BusinessFormat = .parsonal
    var stripeAuthorized:Bool = false
    var credit:Int = 0
    
    init? (_ _input_dic:[String:Any]? ) {
        super.init()
        
        if let input_dic = _input_dic {
            setData(input_dic)
        }else{
            return nil
        }
    }
    
    private override init() { }
    
    func reset() {
        self.accountFirstName = nil
        self.accountLastName = nil
        self.firstName = nil
        self.lastName = nil
        self.tel = nil
        self.email = nil
        self.companyName = nil
        self.statusVerify = .unDefined
        self.npStatus = .unDefined
        self.npBuyerId = nil
        self.stripeAuthorized = false
        self.bank = nil
        self.business = nil
        self.staff = nil
        self.businessDocTemp = nil
        self.accountLastName = nil
        self.accountFirstName = nil
        self.businessFormat = .parsonal
        self.brokerStatus = .unDefined
        self.stripeAuthorized = false
      //  self.profileRetailerRegistered = false
        self.address = nil
        self.telRepresentative = nil
        self.credit = 0
        self.profiled = false
        
    }
    
    func setData(_ resultDic:[String:Any]) {
 
        if let profileDetail = resultDic["profileDetail"] as? [String:Any] {
            self.accountLastName = profileDetail["accountLastName"] as? String
            self.accountFirstName = profileDetail["accountFirstName"] as? String
            self.firstName = profileDetail["firstName"] as? String
            self.lastName = profileDetail["lastName"] as? String
            self.tel = profileDetail["tel"] as? String
            self.telRepresentative = profileDetail["telRepresentative"] as? String
            self.email = profileDetail["email"] as? String
            self.companyName = profileDetail["companyName"] as? String
            self.statusVerify = ProfileTdStatus(rawValue: profileDetail["statusVerify"] as? String ?? "unDefined" ) ?? .unDefined
            self.npStatus = ProfileStatus(rawValue: profileDetail["npStatus"] as? String ?? "unDefined") ?? .unDefined
            self.npBuyerId = profileDetail["npBuyerId"] as? String
            self.stripeAuthorized = profileDetail["stripeAuthorized"] as? Bool ?? false
            self.bank = Bank(profileDetail["bank"] as? [String:Any])
            self.business = Business(profileDetail["business"] as? [String:Any])
            self.staff = Staff(profileDetail["staff"] as? [String:Any])
            self.businessDocTemp = profileDetail["businessDocTemp"] as? String
            self.businessFormat = BusinessFormat(rawValue: profileDetail["businessFormat"] as? String ?? "") ?? .parsonal
            self.brokerStatus = ProfileStatus(rawValue: profileDetail["brokerStatus"] as? String ?? "unDefined") ?? .unDefined
            self.address = Address(profileDetail["address"] as? [String:Any] )
            // 閲覧制御判定
            if let cname = companyName {
                if cname.count > 0 {
                    if self.statusVerify != .Preparing {
                       // self.profileRetailerRegistered = true
                    }
                }
            }
            self.credit = profileDetail["credit"] as? Int ?? 0
            self.created = true
        }
    }
    
    func getData()  {
        
        let graphql = """
        query getProfileStatus{
            profileDetail {
              accountLastName
              accountFirstName
              firstName
              lastName
              tel
              email
              companyName
              statusVerify
              npStatus
              bank {
                accountHolder
                accountNumber
                accountType
                bankCode
                bankName
                branchName
                branchNumber
              }
              businessFormat
              existBusinessDocTemp
              brokerStatus
              credit
              stripeAuthorized
              telRepresentative
              address {
                  apartment
                  city
                  postalCode
                  prefecture {
                    id
                    name
                    kana
                  }
                  cityKana
                  apartmentKana
                  town
                  townKana
              }
            }

          }
        """

        let result = OrosyAPI.callSyncAPI(graphql)
        
        switch result {
        case .success(let resultDic):
            LogUtil.shared.log("success getProfile")
            
            self.setData(resultDic)
 
        case .failure(let error):
            LogUtil.shared.errorLog(error: error)
            // メール認証していないとここにくる
            self.statusVerify = .unDefined
           break
        }
    }
    
    // アカウント作成時はこちらを使う
    func update() -> Result<[String:Any], Error> {
        
        let cmdStr = (self.created) ? "updateProfileBasic" : "createProfile"
      
        var graphql = """
        mutation profile( $profile: ProfileInput! ) {
                  $cmd( profile: $profile ) {
            firstName
          }
        }
        """

        graphql = graphql.replacingOccurrences(of: "$cmd", with: cmdStr)
 
        /*
         input ProfileInput {
           companyName: String
           lastName: String
           firstName: String
           tel: String
           personal: PersonalInput
           statusVerify: String
           business: BusinessInput
           staff: StaffInput
           businessFormat: String
           accountLastName: String
           accountFirstName: String
           lastNameKana: String
           firstNameKana: String
           companyNameKana: String
           openingDate: String
           hpUrl: String
           annualSales: Long
           businessType: String
           businessDesc: String
           isRetailer: Boolean
           brokerStatus: String
           telRepresentative: String
           messageTemplate: MessageTemplateInput
           address: AddressInput
         }
         
         input AddressInput {
           postalCode: String
           prefecture: PrefectureInput
           city: String
           town: String
           apartment: String
           cityKana: String
           townKana: String
           apartmentKana: String
         }

         input PrefectureInput {
           id: String
           name: String
           kana: String
         }
         */
        

        var profileParamDic:[String:Any] =
        ["accountLastName" : self.accountLastName ?? "", "accountFirstName":self.accountFirstName ?? "", "telRepresentative": self.telRepresentative ?? "", "tel": self.tel ?? "" , "companyName": self.companyName ?? "" , "businessFormat":self.businessFormat.rawValue, "isRetailer":true ]

        if !self.created {
            profileParamDic["brokerStatus"] = ProfileStatus.requested.rawValue
        }
        
        if let ad = self.address {
            if let prefec = self.address?.prefecture {
            
                profileParamDic["address"] = [
                        "postalCode" : ad.postalCode, "city" : ad.city, "apartment" : ad.apartment, "town" : ad.town,
                        "prefecture" : [
                            "name": prefec.name, "id" : prefec.id, "kana" : prefec.kana
                        ]
                    ]
            }
        }

        let result = OrosyAPI.callSyncAPI(graphql, variables:["profile": profileParamDic])
    
        switch result {
        case .success(let resultDic):
            let dic = resultDic[cmdStr] as? [String:Any] ?? [:]
            created = true
            return .success(dic)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // NP申請とpofileの登録用   申請に成功すると　"npStatus"が "requested"になる
    func npUpdate() -> Result<[String:Any], Error> {
        
        let graphql = """
        mutation updateProfileForRetailer(
          $profile: ProfileInput,
          $npBuyer: NpBuyerInput
        ) {
          updateProfileForRetailer(
            profile: $profile
            npBuyer: $npBuyer
          ) {
            companyName
          }
        }
        """
        
        /*
         input NpBuyerInput {
           companyName: String
           zipCode: String
           address: String
           telNo: String
           mailAddress: String
         }
         */

        var address = self.address?.concatinated ?? ""
        address = address.replacingOccurrences(of: "\n", with: " ")
        let npParamDic:[String:Any] =
        ["companyName" : self.companyName ?? "", "zipCode":self.address?.postalCode ?? "", "telNo": self.telRepresentative ?? "", "address": address, "mailAddress": self.email ?? "" ]
              
        var profileParamDic:[String:Any] =
        ["accountLastName" : self.accountLastName ?? "", "accountFirstName":self.accountFirstName ?? "", "telRepresentative": self.telRepresentative ?? "", "tel": self.tel ?? "" , "companyName": self.companyName ?? ""       ]

        if let ad = self.address {
            if let prefec = self.address?.prefecture {
            
                profileParamDic["address"] = [
                        "postalCode" : ad.postalCode, "city" : ad.city, "apartment" : ad.apartment, "town" : ad.town,
                        "prefecture" : [
                            "name": prefec.name, "id" : prefec.id, "kana" : prefec.kana
                        ]
                    ]
            }
        }
        

        let result = OrosyAPI.callSyncAPI(graphql, variables:["profile": profileParamDic, "npBuyer":npParamDic])
    
        switch result {
        case .success(let resultDic):
            let dic = resultDic["updateProfileForRetailer"] as? [String:Any] ?? [:]
            created = true
            return .success(dic)
            
        case .failure(let error ):
            return .failure(error)
        default:
            return .failure(OrosyError.UnknownErrorWithMessage(""))
        }
        
    }
    
    func checkProfiled() -> Bool {
        getData()
        
        var done = true
        
        if (accountLastName ?? "").count == 0 || (accountFirstName ?? "").count == 0 || (tel ?? "").count == 0 || businessFormat == .none || (companyName ?? "").count == 0 ||
            (telRepresentative ?? "").count == 0 || !(address?.hasDone ?? false) || (telRepresentative ?? "") .count == 0 {
            done = false
        }
        
        profiled = done
        
        return done
    }
}


class Personal:NSObject {
    var gender:String?
    var birth:Date?
    var address:Address?

    init? (_ _input_dic:[String:Any]? ) {

        if let input_dic = _input_dic {
            gender = input_dic["gender"] as? String
            birth = Util.dateFromUTCString(input_dic["birth"] as? String)
            address = Address(input_dic["address"] as? [String:Any])
        }
    }
}

class Staff:Personal {
var isRep:Bool = false
    
    override init? (_ _input_dic:[String:Any]? ) {

        super.init(_input_dic)
        
        if let input_dic = _input_dic {
            isRep = input_dic["isRep"] as? Bool ?? false
        }
    }
}

class Business:NSObject {
    var repFirstName:String?
    var repLastName:String?
    var hqAddress:Address?
    var issued_at:Date?

    init? (_ _input_dic:[String:Any]? ) {

        if let input_dic = _input_dic {
            repFirstName = input_dic["repFirstName"] as? String
            repLastName = input_dic["repLastName"] as? String
            hqAddress = Address(input_dic["hqAddress"] as? [String:Any])
            issued_at = Util.dateFromUTCString(input_dic["issued_at"] as? String)

        }
    }
}

//　銀行口座情報
class Bank:NSObject {

    var bankName:String?
    var bankCode:String?
    var branchName:String?
    var branchNumber:String?
    var accountType:String?     // saving = "預金口座", ordinary = "普通口座"
    var accountNumber:String?
    var accountHolder:String?

    override init() {}
    
    init? (_ _input_dic:[String:Any]? ) {

        if let input_dic = _input_dic {
            bankName = input_dic["bankName"] as? String
            bankCode = input_dic["bankCode"] as? String
            branchName = input_dic["branchName"] as? String
            branchNumber = input_dic["branchNumber"] as? String
            accountType = input_dic["accountType"] as? String
            accountNumber = input_dic["accountNumber"] as? String
            accountHolder = input_dic["accountHolder"] as? String

        }else{
            return nil
        }
    }

    func update() -> Result<[String:Any], Error>  {
        
        let graphql = """
        mutation updateProfileBank (
          $bankName: String,
          $bankCode:String,
          $branchName:String,
          $branchNumber:String,
          $accountType:String,
          $accountNumber:String,
          $accountHolder:String
        ) {
          updateProfileBank (
            bank: {
              bankName: $bankName,
              bankCode: $bankCode,
              branchName: $branchName,
              branchNumber: $branchNumber,
              accountType: $accountType ,
              accountNumber: $accountNumber,
              accountHolder: $accountHolder
            }
          ) {
            bank {
              bankName
              bankCode
              branchName
              branchNumber
              accountType
              accountNumber
              accountHolder
            }
          }
        }

        """

        let paramDic:[String:Any] =
        ["bankName":self.bankName,"bankCode":self.bankCode,"branchName":self.branchName,"branchNumber":self.branchNumber,"accountType":self.accountType,"accountNumber":self.accountNumber,"accountHolder":self.accountHolder]

        let result = OrosyAPI.callSyncAPI(graphql, variables:paramDic)
    
        switch result {
        case .success(let resultDic):
            return .success(resultDic)
        case .failure(let error):
            return .failure(error)
        }

    }
    
}

//
class CreditData:NSObject {
    var createdAt:Date?
    var additionalCredits:Int = 0
    var creditDescription:String?
    
    init? (_ _input_dic:[String:Any]? ) {
        
        if let input_dic = _input_dic {
            self.createdAt = Util.dateFromUTCString(input_dic["createdAt"] as? String)
            self.additionalCredits = input_dic["additionalCredits"] as? Int ?? 0
            self.creditDescription = input_dic["description"] as? String
        }else{
            return nil
        }
    }
}
class CreditHistory:NSObject {
    
    var list:[CreditData] = []
    var hasAllCredits:Bool = false
    private var size:Int = 20
    private var nextToken:String? = ""
    
    
    func getData() -> [CreditData] {
        
    let graphql =
    """
        query ($limit: Int, $nextToken: String) {
          getCreditHistories(limit: $limit, nextToken: $nextToken) {
            creditHistories {
              createdAt
              additionalCredits
              description
            }
            nextToken
          }
        }
    """
        
        let limit = self.size

        var paramDic:[String:Any]!
        
        if let next = nextToken {
            if next == "" {
                paramDic = ["limit":limit]
            }else{
                paramDic = ["limit":limit, "nextToken":next]
            }

        }else{
           // paramDic = ["supplierId":self.id, "limit":limit]
            return []
        }

        let result = OrosyAPI.callSyncAPI(graphql, variables:paramDic)

        var tempArray:[CreditData] = []
        
        switch result {
        case .success(let resultDic):
            if let creditDic = resultDic["getCreditHistories"] as? [String:Any] {
                let credits = creditDic["creditHistories"] as? [[String:Any]] ?? []
                for dic in credits {
                    if let credit = CreditData(dic) {
                        tempArray.append(credit)
                    }
                }
                list = tempArray
                
                nextToken = creditDic["nextToken"] as? String
                if nextToken == nil || nextToken == "" {
                    hasAllCredits = true    // 正常終了でnextTokenがnilの場合は、もう残っているデータはないことを意味する
                }
            }
            return list
            
        case .failure(_):
            return []

        }

        
    }
}

class NpBuyer:NSObject {
    var amountLimit:Decimal = .zero
    var usedAmount:Decimal = .zero

    init? (_ _input_dic:[String:Any]? ) {
        if let input_dic = _input_dic {
            if let dic = input_dic["getNpBuyer"] as? [String:Any] {
                amountLimit = Decimal(dic["amountLimit"] as? Int ?? 0)
                usedAmount = Decimal(dic["usedAmount"] as? Int ?? 0)
            }
        }else{
            return nil
        }
    }
}

//

class ProfileDetailBank:NSObject {
    
    var profileDetail:ProfileDetail?
    var stripeCard:StripeCard?
    var npBuyer:NpBuyer?
    
    func getData() -> Bool {
        let graphql =
        """
        query profileDetailBank {
          profileDetail {
            bank{
              bankName
              bankCode
              branchName
              branchNumber
              accountType
              accountNumber
              accountHolder
            }
            npStatus
            credit
          }
          getStripeCard {
            last4
            expYear
            expMonth
            expectedMaxAmount
            unpaidAmount
          }
          getNpBuyer {
            amountLimit
            usedAmount
          }
        }
        """
        
        let result = OrosyAPI.callSyncAPI(graphql)

        switch result {
        case .success(let resultDic):
            self.profileDetail = ProfileDetail(resultDic)
            self.stripeCard = StripeCard(resultDic)
            self.npBuyer = NpBuyer(resultDic)
            return true
            
        case .failure(let error):
            return false

        }
    }
    
}


