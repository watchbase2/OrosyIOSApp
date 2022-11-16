//
//  Payment.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/20.
//

import Foundation


// MARK: -------------------------------------
// MARK: 支払い方法

enum PAYMENT_TYPE:String {
    case NP = "np"                  // 掛払い（請求書支払）
    case DAY90 = "stripeInvoice"    // 90日支払い
    case POINT = "point"
    case NONE = ""
}


class PaymentList:NSObject {
    var payments:[Payment] = []

    public func getPaymentData() -> Result<Any?,OrosyError> {
        // 支払い方法が有効かどうかは、今は取得する方法がないので固定で指定している
        // availableが trueのものだけを支払い方法として選択できる。　　　　ポイントは、支払い方法の一つではあるが、自動的に引かれるため、手動選択のリストには表示しない。
        if payments.count == 0 {
            payments.append(Payment(type:.NP, available:true))
            payments.append(Payment(type:.DAY90, available:true))
            payments.append(Payment(type:.POINT, available:false))
        }
        return .success(nil)
    }
    
    public func getPayment(paymentType:PAYMENT_TYPE) -> Payment? {
        
        for pay in payments {
            if pay.type == paymentType {
                return pay
            }
        }
        return nil
    }
}


enum KEY_TYPE: String {
    case NP = "npPayment"
    case OROSY90 = "OrosyPayment"
}

class Payment:NSObject {
    var type:PAYMENT_TYPE = .NONE
    var name:String?
    var available:Bool = false
    var description_text:String?
    var imageUrl:URL?

    init(type:PAYMENT_TYPE, available:Bool) {
        
        super.init()
        
        self.type = type

        self.available = available
        
        switch self.type {
        case .NP:
            description_text = getContent(keyType: .NP)
            imageUrl = URL(string: ROOT_URL + "/images/purchase/payment/bnr_payment.png" )
        case .DAY90:
            description_text = getContent(keyType: .OROSY90)
            imageUrl = nil
        default:
            break
        }
        
        self.name = OrosyAPI.getPaymentDisplayName(self)
    }
    
    func getContent(keyType:KEY_TYPE) -> String {
        var content:String!

        if let config = AppConfigData.shared.config {
            content = config[keyType.rawValue] as? String ?? ""
        }
        return content
    }
}
