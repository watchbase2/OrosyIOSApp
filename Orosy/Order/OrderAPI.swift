//
//  Orer.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/20.
//

import Foundation


// MARK: -------------------------------------
// MARK: 注文履歴
enum OrderStatus : String {
    case PAYMENT_PENDING = "PAYMENT_PENDING"
    case PENDING = "PENDING"
    case CANCEL = "CANCEL"
    case SENT = "SENT" // 委託のみ
    case ENDPERIOD = "ENDPERIOD" // 委託のみ
    case SENTBACK_PENDING = "SENTBACK_PENDING" // 委託のみ
    case SENTBACK = "SENTBACK" // 委託のみ
    case FAILED = "FAILED"
    case DONE = "DONE"
}

    // 注文履歴一覧
class OrderList:NSObject {
    var list:[Order] = []
    var size:Int    // 一度に読み込む件数
    var nextToken:String? = ""

    init(size:Int) {
        self.size = size
    }
    
    public func getNextOrders() -> Result<Any?, OrosyError> {

        if g_paymentList == nil {
            return .failure(OrosyError.UnknownErrorWithMessage("支払い方法のデータを取得できていない"))
        }
        
        let graphql = """
           query getOrders($nextToken: String, $limit: Int) {
             getOrders(isRetailer: true, nextToken: $nextToken, limit: $limit) {
               nextToken
               orders {
                 totalAmount
                 orderDay
                 orderNo
                 paymentType
                 supplier {
                   id
                   brandName
                   category
                 }
                 itemsConsignment {
                   items {
                     item {
                        title
                     }
                   }
                 }
                 itemsWholesale {
                   items {
                   imageUrls
                    item {
                        title
                    }
                   }
                 }
                 createdAt
                 cancelAt
                 paidAt
                 sentAt
                 registeredSoldQtyAt
                 sentBackAt
                 confirmedSentBackAt
                 failedAt
                 totalAmount
                 totalBill
                 totalDeposit
                 totalItemPrice
                 totalShippingFeeAmount
                 useCredit
               }
             }
           }
           """;
        
        var paramDic:[String:Any]!
        
        if let next = nextToken {
            if next == "" {
                paramDic = ["limit":size]
            }else{
                paramDic = ["limit":size, "nextToken":next]
            }

        }else{
            //　おしまい
            return .success(nil)
        }

        
        let result = OrosyAPI.callSyncAPI(graphql, variables:paramDic)

        switch result {
        case .success(let resultDic):
            if let dic = resultDic["getOrders"] as? [String:Any] {
                nextToken = dic["nextToken"] as? String
                var tempArray:[Order] = []
                for order in dic["orders"] as! [[String:Any]] {
                    let newOrder = Order(order)
                    
                    var find = false
                    for exorder in self.list {
                        if exorder.orderNo == newOrder.orderNo {
                            find = true
                            break
                        }
                    }
                    if !find {
                        tempArray.append(newOrder)
                    }
                }
                self.list.append(contentsOf: tempArray)
                return .success( tempArray)
            }else{
                return .failure(OrosyError.KeyNotFound)
            }
            
        case .failure(let error):
            return .failure(OrosyError.CanNotGetOrderHistory)
        }

    }

}

// オーダー1件毎の情報
class Order:NSObject {
    var orderNo:String?
    var orderDay:Date?
    var totalAmount:NSDecimalNumber = .zero
    var supplier:Supplier?
    var deliverTo:DeliverTo?
    var deliveryDetail:DeliveryDetail?
    var payment:Payment?
    var paymentDisplayString:String?
    var itemsWholesale:[ItemOrder] = []
    var itemsConsignment:[ItemOrder] = []

    var createdAt:Date?
    var cancelAt:Date?
    var paidAt:Date?
    var sentAt:Date?
    var failedAt:Date?
    var sentBackAt:Date?
    var consignmentPeriod:Date?
    var registeredSoldQtyAt:Date?
    var confirmedSentBackAt:Date?
    var orderStatus:OrderStatus?
    var orderStatusString:String?
    var taxes:[Tax] = []
    var totalBill:NSDecimalNumber = .zero
    var totalDeposit:NSDecimalNumber = .zero
    var totalItemPrice:NSDecimalNumber = .zero
    var totalShippingFeeAmount:NSDecimalNumber = .zero
    var useCredit:NSDecimalNumber = .zero


    init(_ _input_dic:[String:Any]? ) {
        super.init()

        setData(_input_dic)
        
    }

    private func setData(_ _input_dic:[String:Any]?) {
        
        if let input_dic = _input_dic {
            self.orderNo = input_dic["orderNo"] as? String
            self.orderDay = Util.dateFromDateString(input_dic["orderDay"] as? String)    // 2021-10-25
            self.payment = g_paymentList.getPayment(paymentType: PAYMENT_TYPE(rawValue: input_dic["paymentType"] as? String ?? "") ?? .NONE)
            
            self.paymentDisplayString = OrosyAPI.getPaymentDisplayName(payment)
            
            self.totalAmount = NSDecimalNumber(value: input_dic["totalAmount"] as? Int ?? 0)
            self.supplier = Supplier(input_dic["supplier"] as? [String:Any])
            self.deliverTo = DeliverTo(input_dic["deliverTo"] as? [String:Any])
            self.deliveryDetail = DeliveryDetail(input_dic["deliveryDetail"] as? [String:Any])
            self.itemsWholesale = getItems(input_dic["itemsWholesale"] as! [String:Any] )
            self.itemsConsignment = getItems(input_dic["itemsConsignment"] as! [String:Any] )
            
            self.createdAt = Util.dateFromUTCString(input_dic["createdAt"] as? String)
            self.cancelAt = Util.dateFromUTCString(input_dic["cancelAt"] as? String)
            self.paidAt = Util.dateFromUTCString(input_dic["paidAt"] as? String)
            self.sentAt = Util.dateFromUTCString(input_dic["sentAt"] as? String)
            self.failedAt = Util.dateFromUTCString(input_dic["failedAt"] as? String)
            self.consignmentPeriod =  Util.dateFromUTCString(input_dic["consignmentPeriod"] as? String)  // 2021-11-30T14:59:59.999Z

            self.orderStatus = getOrderStatusFromOrder(order:self, today:Date())
            self.orderStatusString = orderStatusToString(orderStatus)
            
            var taxes:[Tax] = []
            if let taxDicArray = input_dic["taxes"] as? [[String:Any]] {
                for taxDic in taxDicArray {
                    taxes.append(Tax(taxDic))
                }
            }
            
            self.taxes = taxes
            self.totalBill = NSDecimalNumber(value: input_dic["totalBill"] as? Int ?? 0)
            self.totalDeposit = NSDecimalNumber(value: input_dic["totalDeposit"] as? Int ?? 0)
            self.totalItemPrice = NSDecimalNumber(value: input_dic["totalItemPrice"] as? Int ?? 0)
            self.totalShippingFeeAmount = NSDecimalNumber(value: input_dic["totalShippingFeeAmount"] as? Int ?? 0)
            self.useCredit = NSDecimalNumber(value: input_dic["useCredit"] as? Int ?? 0)
        }
    }

    public func getOrderDetail() -> Bool {
        let graphql = """
       query getOrder($orderNo: String!) {
         getOrder(orderNo: $orderNo) {
             totalAmount
             orderDay
             orderNo
             paymentType
             consignmentPeriod
             supplier {
               id
               brandName
               category
             }
             buyer {
               brokerStatus
               businessType
               businessFormat
               npStatus
               npBuyerId
             }
             deliverTo {
               name
               shopId
               statusShopVerify
               createdAt
               shippingAddressEtc
               shippingAddressName
               shippingAddress {
                 apartment
                 apartmentKana
                 city
                 postalCode
                 prefecture {
                   name
                 }
                 town
               }
             }
             deliveryDetail {
               voucherNumber
               company
               url
             }
             itemsConsignment {
               items {
                item {
                    title
                    id
                    productNumber
                    catalogPrice
                    wholesalePrice
                    consignmentPrice
                    isConsignment
                    isWholesale
                    jancode
                    isPl
                    categoryNo
                    tax
                    setQty
                    variation1Label
                    variation1Value
                    variation2Label
                    variation2Value
                }
                 imageUrls
                 amount
                 quantity
                 saleType
                 taxAmount
                 totalPrice
                 soldQuantity
               }
               taxes {
                 amount
                 tax
               }
               totalAmount
               totalItemPrice
               totalShippingFeeAmount
             }
             itemsWholesale {
               items {
                item {
                    title
                    id
                    productNumber
                    catalogPrice
                    wholesalePrice
                    consignmentPrice
                    isConsignment
                    isWholesale
                    jancode
                    isPl
                    categoryNo
                    setQty
                    variation1Label
                    variation1Value
                    variation2Label
                    variation2Value
                }
                 imageUrls
                 amount
                 quantity
                 saleType
                 taxAmount
                 totalPrice
                 soldQuantity
               }
               taxes {
                 amount
                 tax
               }
               totalAmount
               totalItemPrice
               totalShippingFeeAmount
             }
             cancelAt
             createdAt
             paidAt
             sentAt
             registeredSoldQtyAt
             sentBackAt
             confirmedSentBackAt
             failedAt
             totalAmount
          　　totalBill
          　　totalItemPrice
            totalShippingFeeAmount
            useCredit
            totalDeposit
            taxes {
              amount
              tax
            }
         }
       }
       """;

        if let _orderNo = self.orderNo {
            let paramDic:[String:Any] = ["orderNo" : _orderNo]
            
            let result = OrosyAPI.callSyncAPI(graphql, variables:paramDic)
            switch result {
            case .success(let resultDic):
                if let dic = resultDic["getOrder"] as? [String:Any] {
                    self.setData( dic)
                }
            case .failure(_):
                return false
            }
            
        }else{
            return false
        }

        return true
        
    }


    // オーダーステータスの判定
    private func getOrderStatusFromOrder(order: Order, today: Date ) -> OrderStatus {
        if order.failedAt != nil { return OrderStatus.FAILED }
        if order.cancelAt != nil { return OrderStatus.CANCEL}
        
        if (order.itemsConsignment.count == 0) {
            if order.sentAt != nil { return OrderStatus.DONE }
            if order.paidAt != nil { return OrderStatus.PENDING }
        } else {
            if order.confirmedSentBackAt != nil { return OrderStatus.DONE }
            if order.sentBackAt != nil { return OrderStatus.SENTBACK }
            if order.registeredSoldQtyAt != nil { return OrderStatus.SENTBACK_PENDING }
            if order.sentAt != nil {
                return (today > order.consignmentPeriod ?? Date(timeIntervalSince1970: 0) ) ? OrderStatus.ENDPERIOD : OrderStatus.SENT
            }
            if order.paidAt != nil { return OrderStatus.PENDING }

        }
        return OrderStatus.PAYMENT_PENDING
        
    }

    func orderStatusToString(_ orderStatus: OrderStatus?) -> String {
        
        guard let status = orderStatus else { return "エラー" }
        
        switch status {
            case OrderStatus.PAYMENT_PENDING: return "審査待ち"
            case OrderStatus.PENDING: return "発送待ち"
            case OrderStatus.CANCEL: return "キャンセル"
            case OrderStatus.SENT: return "発送済"
            case OrderStatus.ENDPERIOD: return "販売報告"
            case OrderStatus.SENTBACK_PENDING: return "要返送"
            case OrderStatus.SENTBACK: return "返送確認"
            case OrderStatus.DONE: return "完了"
            default: return "エラー"
        }
    }

    private func getItems(_ input_dic:[String:Any]) -> [ItemOrder] {
        var tempArray:[ItemOrder] = []
        
        if let array = input_dic["items"] as? [[String:Any]] {
            for dic in array {
                tempArray.append(ItemOrder(dic))
            }
        }
        return tempArray
    }

    // このオーダ中の商品を全てカートに入れる
    public func addCart() -> Result<Bool,OrosyError> {
        
        for itemOrder in self.itemsWholesale {
            
            let result = itemOrder.addCart()
            
            switch result {
            case .success(_):
                continue
            case .failure(let error):
                return .failure(error)
            }
        }
        
        for itemOrder in self.itemsConsignment {
            let result = itemOrder.addCart()
            
            switch result {
            case .success(_):
                continue
            case .failure(let error):
                return .failure(error)
            }
        }
        
        return .success(true)
        
    }
}

// 商品毎のオーダ詳細
class ItemOrder:NSObject {
    var amount:NSDecimalNumber = .zero
    var quantity:Int = 0
    var taxAmount:NSDecimalNumber = .zero
    var saleType:SaleType = .Undefinened
    var item:Item?
    var imageUrls:[URL] = []
    var supplier:Supplier?

    init(_ _input_dic:[String:Any]? ) {
        
        if let input_dic = _input_dic {
            amount = NSDecimalNumber(value:input_dic["amount"] as? Int ?? .zero)
            taxAmount = NSDecimalNumber(value:input_dic["taxAmount"] as? Int ?? .zero)
            quantity = input_dic["quantity"] as? Int ?? 0
            saleType = SaleType(rawValue: input_dic["saleType"] as? String ?? "") ?? .Undefinened
            
            if let itemDic = input_dic["item"] as? [String:Any] {
                item = Item(itemDic)
            }
            
            if let urlArray = input_dic["imageUrls"] as? [String] {
                for urlString in urlArray {
                    let imageUrl  = URL(string: urlString)
                    if imageUrl != nil {
                        imageUrls.append(imageUrl!)
                    }
                }
            }
            
            supplier = Supplier(input_dic["supplier"] as? [String:Any] )
            
        }
    }

    func addCart() -> Result<Bool,OrosyError> {
        
        return (self.item?.addCart(quantity: self.quantity, saleType:self.saleType))!
        
    }
}
