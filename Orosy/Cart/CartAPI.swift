//
//  Cart.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/20.
//

import Foundation
import Amplify

// MARK: -------------------------------------
// MARK: カート
// カート全体の合計額とブランド毎にまとめられたオブジェクトが保存されいている
class Cart:NSObject {
    
    var totalAmount:NSDecimalNumber = .zero
    var totalItemPrice:NSDecimalNumber = .zero
    var totalShippingFeeAmount:NSDecimalNumber = .zero
    var discount:NSDecimalNumber = .zero
    var deposit:NSDecimalNumber = .zero
    var taxes:[Tax] = []
    var cartSections:[CartSection] = []     // ブランド毎に集計された情報
    var payment:Payment!                    // 支払い方法　注文フローの中で選択したものをセット
    var deliveryPlace:DeliveryPlace?        // 出荷先
    
    
    func insertCartNode(graphql:String) -> String {
        let nodeString = """
                        totalAmount
                        totalItemPrice
                        discount
                         totalShippingFeeAmount
                         deposit
                         taxes {
                           amount
                           tax
                         }
                        shippingInfo {
                            name
                            access
                            shippingAddress {
                                apartment
                                city
                                postalCode
                                prefecture {
                                id
                                kana
                                name
                            }
                            town
                            }
                            shippingAddressEqual
                            shippingAddressEtc
                            shippingAddressName
                        }
                         cartSections {
                           shippingFeeAmount
                           totalAmount
                           taxes{
                             amount
                             tax
                           }
                           totalItemPrice
                           deposit
                           supplier {
                             id
                             brandName
                             iconImageUrl
                             shippingFeeRules {
                               amount
                               trigger
                               triggerCount
                               type
                             }
                           }
                           cartItems {
                             id
                             amount
                             saleType
                             quantity
                             price
                             taxAmount
                             item {
                               id
                               title
                               productNumber
                               jancode
                               setQty
                               isPl
                               tax
                               isConsignment
                               isWholesale
                               inventoryQty
                               catalogPrice
                               consignmentPrice
                               wholesalePrice
                               variation1Label
                               variation1Value
                               variation2Label
                               variation2Value
                             }
                             itemParent {
                               id
                               imageUrls
                             }
                           }

                         }
        """
        
        return  graphql.replacingOccurrences(of: "$cartNode", with: nodeString)
        
    }
    
    func updateCart() -> ( Result<Cart, OrosyError>) {
  
        let cartbody = """
             query {
               getCart {
                 $cartNode
               }
             }

             """;
        
        let graphql = insertCartNode(graphql: cartbody)
        
        let result = OrosyAPI.callSyncAPI(graphql)
        
        switch result {
        case .success(let resultDic):
            
            if resultDic["getCart"] != nil {
                if let dic = resultDic["getCart"] as? [String:Any] {
                    calculateCart(cartDic: dic)
                
                    self.deliveryPlace = DeliveryPlace(dic["shippingInfo"] as? [String:Any])
                    return .success(self)
                }else{
                    // まだ、一度もカートに商品を入れていない場合は、getCartのキーはあるが中身がない
                    return .success(self)
                }
                
            }else{
                return .failure(OrosyError.KeyNotFound)
            }
            
        case .failure(let error):
            return .failure(OrosyError.UnknownErrorWithMessage(error.localizedDescription))
        }

    }
    
    private func calculateCart(cartDic:[String:Any]) {
        
        self.totalAmount = NSDecimalNumber(value:cartDic["totalAmount"] as? Int ?? 0)
        self.totalItemPrice = NSDecimalNumber(value:cartDic["totalItemPrice"] as? Int ?? 0)
        self.totalShippingFeeAmount = NSDecimalNumber(value:cartDic["totalShippingFeeAmount"] as? Int ?? 0)
        self.discount = NSDecimalNumber(value:cartDic["discount"] as? Int ?? 0)
        
        /* デポジット金額は「買取価格＋消費税額」だが、APIから取得できるデポジット額には消費税が含まれていないため、消費税を加算する必要がある。
            そこで、委託分の消費税額を加算するように変更した　cartSection　の値を使って合計を算出し直す
            また、消費税率毎の消費税額についても同様
        */
        var depositTotal:NSDecimalNumber = .zero
        
        for cartsectionDic in cartDic["cartSections"] as? [[String:Any]] ?? [] {
            let cartSectionObj = CartSection(cartsectionDic)
            self.cartSections.append(cartSectionObj)
            depositTotal = depositTotal.adding(cartSectionObj.deposit)
            
            //
            for taxInCartSection in cartSectionObj.taxes {
                var exist = false

                for tax in self.taxes {
                    if tax.tax == taxInCartSection.tax {
                        tax.amount = tax.amount.adding(taxInCartSection.amount)
                        exist = true
                        break
                    }
                }
                if !exist {
                    let tax = Tax([:])
                    tax.tax = taxInCartSection.tax
                    tax.amount = taxInCartSection.amount
                    self.taxes.append(tax)
                }
            }

        }
        /*  APIで取得した値をそのまま使う場合
        self.deposit = NSDecimalNumber(value:dic["deposit"] as? Int ?? 0)
        for taxDic in (dic["taxes"] as? [[String:Any]] ?? []) {
            self.taxes.append(Tax(taxDic))
        }
        */
        self.deposit = depositTotal //  APIで取得した値ではなく、消費税を加算した値を使う。
        
    }

    func getTax(itax:Int) -> NSDecimalNumber {
        
        for tax in self.taxes {

            if tax.tax == itax {
                return tax.amount
            }
        }
        return .zero
    }
    
    // カート内の全て商品を発注する
    func orderAllItems() -> (Result<String, Error> ) {    // success, error message, orderNo
        
        if payment.type == .NONE {
            return .failure(OrosyError.PaymentUndifined)
            
        }else if deliveryPlace == nil {

            return .failure(OrosyError.DeliveryPlaceUndefined)
            
        }

        // 指定した支払い方式で発注
        let graphql = """
        mutation orderAll($paymentType: String!) {
            orderAll(paymentType: $paymentType) {
                    orderNo
                }
            }
        """
        
        let paramDic = ["paymentType" : payment.type.rawValue]
        
        let paymentResult = OrosyAPI.callSyncAPI(graphql, variables:paramDic)

        switch paymentResult {
        case .success(let resultDic):

            if let msg = resultDic["error"] as? String {        /// E1999521 は、npアカウントが期限切れで無効になっているため。これは開発環境でしか発生しないので無視する
                let errorMsg = msg
                
                // 在庫切れのエラーメッセージを検出し、商品を特定する
                if errorMsg.contains("out of stock") {
                    
                    if let from = errorMsg.range(of: "itemId[")?.upperBound {
                        if let to = errorMsg.firstIndex(of: "]") {
                            let itemId = String(errorMsg[from..<to])
                            for section in cartSections {
                                for cartItem in section.cartItems {
                                    if cartItem.item?.id == itemId {
                                        let itemName = cartItem.item?.title ?? "不明"
                                        return .failure(OrosyError.NotEnoughInventory(itemName))
                                    }
                                }
                            }
                        }
                    }
                }
                return .failure(OrosyError.UnknownErrorWithMessage(errorMsg))
            }
            
            if let orderAll = resultDic["orderAll"] as? [[String:Any]]  {
                if let number = orderAll.first?["orderNo"] as? String {
                    return .success(number)

                }else{
                    return .failure(OrosyError.UnknownOrderError)
                }
            }else{
                return .failure(OrosyError.UnknownOrderError)
            }
            
        case .failure(let error):

            let errorMsg = (error as! AmplifyError).errorDescription
            var errorType = ""
            if errorMsg.contains("min lot quantity") { errorType = "LessThanMinLot" }
            if errorMsg.contains("out of stock") { errorType = "NotEnoughInventory" }
            
            if errorType != "" {
                if let from = errorMsg.range(of: "itemId[")?.upperBound {
                    if let to = errorMsg.firstIndex(of: "]") {
                        let itemId = String(errorMsg[from..<to])
                        for section in cartSections {
                            for cartItem in section.cartItems {
                                if cartItem.item?.id == itemId {
                                    let itemName = cartItem.item?.title ?? "不明"
                                    
                                    if errorType == "LessThanMinLot" {
                                        return .failure(OrosyError.LessThanMinLot(itemName))
                                    }else if errorType == "NotEnoughInventory" {
                                        return .failure(OrosyError.NotEnoughInventory(itemName))
                                    }
                                }
                            }
                        }
                    }
                }
               
                return .failure(OrosyError.LessThanMinLot("不明"))
                    

            }
            if errorMsg.contains("E1999538") { return .failure(OrosyError.PostCodeAddressUnMatch) }
            if errorMsg.contains("exceeded the available amount") { return .failure(OrosyError.Exceed90DaysPaymentLimit) }

            return .failure(error)
        }
    }
    
    func getCartItem(item_id:String) -> CartItem? {
        for brand in self.cartSections {
            
            for cartItem in brand.cartItems {
                if (cartItem.item?.id ?? "") == item_id {
                    return cartItem
                }
            }
        }
        return nil
    }
}

// ブランド内の商品毎のデータ
class CartItem:NSObject {
    var id:String      // カートから削除する場合はこのIDを指定する
    var saleType:SaleType = .Undefinened
    var amount:NSDecimalNumber = .zero
    var quantity:Int = 0
    var price:NSDecimalNumber = .zero
    var taxAmount:NSDecimalNumber = .zero
    var item:Item?
    var itemParent:ItemParent?
        
    init?(_ _input_dic:[String:Any]?) {
        
        if let input_dic = _input_dic {
            guard let _id = input_dic["id"] as? String else{ return nil }
            id = _id
            
            saleType = SaleType(rawValue: input_dic["saleType"] as? String ?? "") ?? .Undefinened
            let tax = input_dic["taxAmount"] as? Int ?? 0
            
            // amountに消費税が含まれているが、消費税抜きにする
            amount = NSDecimalNumber(value:(input_dic["amount"] as? Int ?? 0) - tax)
            taxAmount = NSDecimalNumber(value:tax)

            quantity = input_dic["quantity"] as? Int ?? 0
            price = NSDecimalNumber(value:input_dic["price"] as? Int ?? 0)

            item = Item(input_dic["item"] as? [String:Any])
            itemParent = ItemParent(input_dic["itemParent"] as? [String:Any])
            
        }else{
            return nil
        }
    }

    // カートから削除する
    public func delete() -> (Result< Bool , Error>) {
        var graphql = """
        mutation MyMutation {
          deleteCartItem(cartItemId: $itemId) {
                totalAmount
            }
        }
        """

        graphql = graphql.replacingOccurrences(of: "$itemId", with: "\"\(self.id)\"")
        
        let result = OrosyAPI.callSyncAPI(graphql)
        
        switch result {
        case .success(let resultDic):
            if let msg = resultDic["error"] as? String {
                return .failure(OrosyError.UnknownErrorWithMessage(msg))
            }else{
                return .success(true)   // このtrueはダミー
            }
        case .failure(let error):
            return .failure(OrosyError.CartItemNotRemoved(error.localizedDescription))
        }

    }

    // カート内の数量を変更
    //public func updateQuantity(newQuantity:Int) -> (Bool , String) {
    public func updateQuantity() -> (Bool , String) {
            let graphql = """
        mutation ($cartItemId: String!, $quantity: Int! ){
            updateCartItemQuantity (cartItemId: $cartItemId, quantity: $quantity) {
                totalAmount
            }
        }
        """
        var succeed = false
        var errorMsg = ""
        
        let paramDic:[String:Any] = ["cartItemId": self.id, "quantity": self.quantity]
        
        let result = OrosyAPI.callSyncAPI(graphql, variables: paramDic)
        switch result {
        case .success(let resultDic):
            if let msg = resultDic["error"] as? String {
                succeed = false
                errorMsg = msg
            }
            succeed = true
        case .failure(let error):
            succeed = false
            errorMsg = error.localizedDescription
        }
        
        return (succeed, errorMsg )
    }
}

// カート内のブランド単位の集計データ
class CartSection:NSObject {

    var totalAmount:NSDecimalNumber = .zero         // 合計金額、税込、送料込み
    var totalItemPrice:NSDecimalNumber = .zero      // 送料抜きの合計金額
    var deposit:NSDecimalNumber = .zero             // 消費税を加算した値に置き換えている
    var shippingFeeAmount:NSDecimalNumber = .zero   //　送料
    var supplier:Supplier?
    var cartItems:[CartItem] = []
    var taxes:[Tax] = []                            // 消費税率毎の内訳。　税率と値のセットになっている
    var taxAmount:NSDecimalNumber = .zero           // 消費税の合計
    var opened = false                              // カート画面で詳細表示を開いているかどうか

    init(_ _input_dic:[String:Any]?) {
        
        if let input_dic = _input_dic {
            totalAmount = NSDecimalNumber(value:input_dic["totalAmount"] as? Int ?? 0)
            totalItemPrice = NSDecimalNumber(value:input_dic["totalItemPrice"] as? Int ?? 0)
            shippingFeeAmount = NSDecimalNumber(value:input_dic["shippingFeeAmount"] as? Int ?? 0)
            supplier = Supplier(input_dic["supplier"] as? [String:Any])
            
            //デポジット金額は「買取価格＋消費税額」だが、APIから取得できるデポジット額には消費税が含まれていないため、消費税を加算する必要がある。
            // そこで、委託分の消費税額だけを抜き出して合計を算出する
            // 消費税の税率毎の内訳データもそのままでは使えないため、デポジットを考慮した数値でtaxesを組み立て直している

            
            var depositTotal:NSDecimalNumber = .zero

            for carItemDic in (input_dic["cartItems"] as? [[String:Any]] ?? []) {
                if let cartItem = CartItem(carItemDic) {
                    cartItems.append(cartItem)
                    
                    if cartItem.saleType == SaleType.Consignment {
                        depositTotal = depositTotal.adding(cartItem.amount)
                        cartItem.taxAmount = 0
                        
                    }else{
                        taxAmount = taxAmount.adding(cartItem.taxAmount)
                        
                        var exist = false
                        for tax in taxes {
                            if tax.tax == cartItem.item?.tax {
                                tax.amount = tax.amount.adding(cartItem.taxAmount)
                                exist = true
                                break
                            }
                        }
                        if !exist {
                            let tax = Tax([:])
                            tax.tax = cartItem.item?.tax ?? 0
                            tax.amount = cartItem.taxAmount
                            taxes.append(tax)
                        }
                        
                    }
                }

            }
            
            deposit = depositTotal  // APIで取得した値ではなく、消費税を加算した値を使う。NSDecimalNumber(value:input_dic["deposit"] as? Int ?? 0)
            
            // APIで取得した値には委託販売分も含まれているため使用しない。委託販売分を含まない値に置き換える
            /*
            for taxDic in (input_dic["taxes"] as? [[String:Any]] ?? []) {
                taxes.append(Tax(taxDic))
            }
            */
        }
    }
    
    func getTax(itax:Int) -> NSDecimalNumber {
        
        for tax in self.taxes {

            if tax.tax == itax {
                return tax.amount
            }
        }
        return .zero
    }
}

// 消費税
class Tax:NSObject {
    var tax:Int = 0                     // 税率
    var amount:NSDecimalNumber = .zero  // 税額

    init(_ _input_dic:[String:Any]?) {
        
        if let input_dic = _input_dic {
            tax = input_dic["tax"] as? Int ?? 0
            amount = NSDecimalNumber(value:input_dic["amount"] as? Int ?? 0)
        }
    }
}
