//
//  StripeAPI.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/07/23.
//

import Foundation
import Stripe

// カード情報
class StripeCard:NSObject {
    enum autholizeError {
        case authorized
        case debit_is_rejected
        case other
        case unexpected
    }
    
    
    var setupInsetId:String?
    
    var brand:String?
    var last4:String?
    var funding:String?
    var cardNumber:String?
    var expYear:Int = 0
    var expMonth:Int = 0
    var expectedMaxAmount:Decimal?
    var unpaidAmount:Decimal?
    var cvc:String?
    var message:String?
    var owner:String?
    var autholizedError:autholizeError = .unexpected
    
    var stripeCardToken:String?
    
    var stpCardParams:STPCardParams!
    
    override init() {}
        
    init? (_ _input_dic:[String:Any]? ) {
        super.init()
        
        if let input_dic = _input_dic {
            setData(input_dic)
        }else{
            return nil
        }
    }
    
    func setData(_ input_dic:[String:Any]) {
        if let dic = input_dic["getStripeCard"] as? [String:Any] {
            self.brand = dic["brand"] as? String
            self.last4 = dic["last4"] as? String
            self.funding = dic["funding"] as? String
            self.expYear = dic["expYear"] as? Int ?? 0
            self.expMonth = dic["expMonth"] as? Int ?? 0
            self.expectedMaxAmount = Decimal(dic["expectedMaxAmount"] as? Int ?? 0)
            self.unpaidAmount = Decimal(dic["unpaidAmount"] as? Int ?? 0)
            self.message = dic["message"] as? String
        }
        if let dic = input_dic["getStripeCardToken"] as? [String:Any] {
            self.stripeCardToken = dic["stripeCardToken"] as? String
        }
    }
    
    func getData() -> Bool {
        let graphql =
        """
        query getStripeCard {
          getStripeCard {
            expMonth
            expYear
            expectedMaxAmount
            funding
            last4
            unpaidAmount
            message
            brand
          }
        }

        """
        
        let result = OrosyAPI.callSyncAPI(graphql)
    
        switch result {
        case .success(let resultDic):
            self.setData(resultDic)
            return true
            
        case .failure(let error):
            return false

        }
    }
    
    func getCartToken() -> String? {
        let graphql =
        """
        query getStripeCard {
          getStripeCardToken {
            stripeCardToken
          }
        }

        """
        
        let result = OrosyAPI.callSyncAPI(graphql)
    
        switch result {
        case .success(let resultDic):
            if let tokenDic = resultDic["getStripeCardToken"] as? [String:String] {
                return tokenDic["stripeCardToken"]
            }
            return nil
        case .failure(_):
            return nil

        }
    }
    
    func authorizeStripeCard() -> Bool {
        let graphql =
        """
        mutation authorizeStripeCard($expectedMaxAmount:Int!,$setupInsetId:String!) {
          authorizeStripeCard(expectedMaxAmount: $expectedMaxAmount,setupInsetId: $setupInsetId) {
            last4
            expYear
            expMonth
            expectedMaxAmount
            unpaidAmount
            message
          }
        }
        """
        
        guard let exm = self.expectedMaxAmount as? NSNumber else{ return false }
        guard let id = self.setupInsetId else{ return false }
        let paramDic:[String:Any] = ["expectedMaxAmount" : Int(truncating:exm), "setupInsetId": id]

        let result = OrosyAPI.callSyncAPI(graphql, variables:paramDic)
    
        switch result {
        case .success(let resultDic):
            if let authDic = resultDic["authorizeStripeCard"] as? [String:Any] {
               let message = authDic["message"] as? String ?? ""      // 成功だとnilが返る
            
                switch message {
                case "":autholizedError = .authorized
                case "debit_is_rejected": autholizedError = .debit_is_rejected
                case "other" : autholizedError = .other
                case "unexpected" : autholizedError = .unexpected
                default : autholizedError = .unexpected
                }
            }else{
                autholizedError = .unexpected
            }
            return (autholizedError == .authorized) ? true : false
            
        case .failure(_):
            autholizedError = .unexpected
            return false
        }
    }
    
    func validateCard() -> Bool { //cardNumber:String, expMonth:Int, expYear:Int, cvc:String ) -> Bool {
        stpCardParams = STPCardParams()
        stpCardParams.number = self.cardNumber ;                    // VISA　US 用 テストアカウント  日本用は　　4000003920000003
        stpCardParams.expMonth = UInt(self.expMonth)   //self.expMonth ?? 0
        stpCardParams.expYear = UInt(self.expYear )     //self.expYear ?? 0
        stpCardParams.cvc = self.cvc
        stpCardParams.name = self.owner
        stpCardParams.currency = "jpy"

 
        // Validate the card
        if STPCardValidator.validationState(forCard: stpCardParams) == .valid {
            return true
        }else{
            return false
        }
    }
    
    // カード登録
    func setupIntent(completion: @escaping ( Bool )-> Void) {
      
        let stripeClient = STPAPIClient.init(publishableKey: STRIPE_PUBLIC_KEY)         // Initialize API
        
        let cardParms = STPPaymentMethodCardParams(cardSourceParams: stpCardParams)
        
        let paymentMethodParams = STPPaymentMethodParams()
        paymentMethodParams.type = .card
        paymentMethodParams.card = cardParms
        
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = self.owner
        paymentMethodParams.billingDetails = billingDetails
        
        if let stripeCardToken = getCartToken() {
  
            let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: stripeCardToken )
            setupIntentParams.useStripeSDK = true
            setupIntentParams.paymentMethodParams = paymentMethodParams

            
            stripeClient.confirmSetupIntent(with: setupIntentParams) { (createResult, createError) in
                if let result = createResult {
                    self.setupInsetId = result.stripeID
                    
                    if self.authorizeStripeCard() {
                        completion( true )
                        return
                    }
                }
                completion(false )
            }
        }else{
            completion(false )
        }
    }
}
