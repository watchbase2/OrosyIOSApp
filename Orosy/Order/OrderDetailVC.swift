//
//  OrderDetailVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/20.
//

import UIKit
import WebKit
import SafariServices

class OrderDetailVC: OrosyUIViewController, UITableViewDataSource, UITableViewDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    
     var selectedOrder:Order? = nil {
        didSet {
            _ = selectedOrder?.getOrderDetail()
            print("paymentDisplayString:\(selectedOrder?.paymentDisplayString ?? "?")")
        }
    }
        
    
    var orderNo:String = "" {
        didSet {
         //   selectedOrder = OrosyAPI.shared.getOrder(orderNo)
            
        }
    }
    
    
    @IBOutlet weak var MainTableView: UITableView!
    @IBOutlet weak var waitIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cartInMessageView: UIView!
    
    var tax8:NSDecimalNumber = 0
    var tax10:NSDecimalNumber = 0
    var subTotals:[[String:String]] = []
    
    var webView:WKWebView!
    
    /*
        UITableViewのセクションごとに表示する項目の定義
        タイプによって使用するCELLのデザインなどが異なる
    */

    func getItemidForPageUrl() -> String {
        return selectedOrder?.orderNo ?? ""
    }

    override func viewDidLoad() {
        
        self.setNaviTitle(title: "注文NO. " + (selectedOrder?.orderNo ?? ""))
        
        if #available(iOS 15.0, *) {
            MainTableView.sectionHeaderTopPadding = 0.0 // iOS15から追加された、セクションヘッダーの上のスペースを消す
        }

        
        if let order = selectedOrder {
            for tax in order.taxes {
                if tax.tax == 10 {
                    tax10 = tax.amount
                }else if tax.tax == 8 {
                    tax8 = tax.amount
                }
            }
            
            // サブトータル
            subTotals.append(["label":"商品小計", "value":Util.number2Str(order.totalItemPrice)])
            if !tax10.isEqual(to: 0) {
                subTotals.append(["label":"消費税（10%）", "value":Util.number2Str(tax10)])
            }
            if !tax8.isEqual(to: 0) {
                subTotals.append(["label":"消費税（8%）", "value":Util.number2Str(tax8)])
            }
            subTotals.append(["label":"送料（税込）", "value":Util.number2Str(order.totalShippingFeeAmount)])
          //  if order.orderStatus == .DONE {   // なぜこの判定を入れた？？
                subTotals.append(["label":"ポイント", "value":Util.number2Str( (NSDecimalNumber.zero).subtracting(order.useCredit) )])
          //  }
        }
  
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(reset), name: Notification.Name(rawValue:NotificationMessage.Reset.rawValue), object: nil)

        
    }

    @objc func reset() {
        DispatchQueue.main.async{
            self.navigationController?.popToRootViewController(animated: false)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return UITableView.automaticDimension //自動設定
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 3 {

            let cell = tableView.dequeueReusableCell(withIdentifier: "headFooterCell", for: IndexPath(row:0, section:section))
            let baseView = cell.viewWithTag(1000) as! OrosyUIView
            baseView.roundCorner(cornerRadius: 4, lower: false)   // 上の両端だけ丸める
            let label1 = cell.viewWithTag(101) as! OrosyLabel16B; label1.isHidden = false
            let label2 = cell.viewWithTag(102) as! OrosyLabel14; label2.isHidden = true
            let label3 = cell.viewWithTag(103) as! OrosyLabel20B; label3.isHidden = true
            
            label1.text = selectedOrder?.supplier?.brandName ?? ""
            
            return cell.contentView
            
        }else{
            return UIView()
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 3 {
            return 59   // ヘッダー（ブランド名）  // 閉経用ビューの高さが57にしているので、1ptのラインが残る
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        switch section {
        case 0: count = 1 + ((selectedOrder?.orderStatus == .DONE) ? 1 : 0)                     // ステータスまでと配送情報
        case 1: count = 1
        case 2: count = 1 + ((selectedOrder?.deliverTo?.shippingAddressEtc == nil) ? 0 : 1)
        case 3: count = (selectedOrder?.itemsWholesale.count ?? 0)
        case 4: count = subTotals.count + 2                                                     // 商品小計、送料、ポイント + tax8 + tax10 　 + 2は、上下のセパレータ行
        case 5: count = 1
        default:
            break
        }
        
        return count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell:UITableViewCell!

        let row = indexPath.row
        let section = indexPath.section
        let order = selectedOrder!
        
        switch section {
            
        case 0: // 注文概要
            
            if row == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "OrderCell", for: indexPath)
                let baselView = cell.viewWithTag(100) as! OrosyUIView
                baselView.roundCorner(cornerRadius: 4, lower: false)   // 上の両端だけ丸める
                
                let dateLabel = cell.viewWithTag(1) as! UILabel
                let brand = cell.viewWithTag(2) as! UILabel
                let price = cell.viewWithTag(3) as! UILabel
                let orderNo = cell.viewWithTag(4) as! UILabel
                let status_view = cell.viewWithTag(5) as! OrosyUIImageView
                let status = cell.viewWithTag(6) as! UILabel
                
                status_view.drawBorder(cornerRadius: 7)
                dateLabel.text = Util.formattedDate(order.orderDay)
                brand.text = order.supplier?.brandName ?? ""
                price.text = Util.number2Str( order.totalAmount)
                orderNo.text = "注文NO. " + (order.orderNo ?? "")
                
                switch order.orderStatus ?? .FAILED {
                case .PAYMENT_PENDING:
                    status_view.backgroundColor = UIColor.orosyColor(color: .S200)
                    status.text = NSLocalizedString("NPPending", comment: "")
                case .PENDING:
                    status_view.backgroundColor = UIColor.orosyColor(color: .S200)
                    status.text = NSLocalizedString("WaitShipping", comment: "")
                case .DONE:
                    status_view.backgroundColor = UIColor.orosyColor(color: .S400)
                    status.text = NSLocalizedString("Shipped", comment: "")
                case .CANCEL:
                    status_view.backgroundColor = UIColor.orosyColor(color: .Gray400)
                    status.text = NSLocalizedString("Canceled", comment: "")
                default:
                    status_view.backgroundColor = UIColor.orosyColor(color: .Red)
                    status.text = NSLocalizedString("OrderError", comment: "")
                }

            }else{
                
                cell = tableView.dequeueReusableCell(withIdentifier: "DeliveryInfoCell", for: indexPath)
                let baselView = cell.viewWithTag(100) as! OrosyUIView
                baselView.roundCorner(cornerRadius: 4, lower: true)   // 下の両端だけ丸める
                
                let trnsporter = cell.viewWithTag(1) as! UILabel
                let voucherNumber = cell.viewWithTag(2) as! UILabel
                
                trnsporter.text = "宅配業者：" + (order.deliveryDetail?.company ?? "")
                voucherNumber.text = "伝票番号：" + (order.deliveryDetail?.voucherNumber ?? "")
            }
            
        case 1: // 支払い方法
            cell = tableView.dequeueReusableCell(withIdentifier: "PaymentCell", for: indexPath)
            let paymentLabel = cell.viewWithTag(1) as! UILabel
            paymentLabel.text = order.paymentDisplayString
            
        case 2: // 納品場所
            
            if row == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "ShippingCell", for: indexPath)

                
                let placeLabel = cell.viewWithTag(1) as! UILabel
                let addressLabel = cell.viewWithTag(2) as! UILabel

                placeLabel.text = order.deliverTo?.name
                var addressName = (order.deliverTo?.shippingAddress?.postalCode ?? "") + "\n" + ( order.deliverTo?.shippingAddress?.concatinated ?? "")
                if let name = order.deliverTo?.shippingAddressName {
                    addressName = addressName + "\n" + name + "宛"
                }
                addressLabel.text = addressName

                let baselView = cell.viewWithTag(100) as! OrosyUIView
                let separator = cell.viewWithTag(3) as! UILabel
                if selectedOrder?.deliverTo?.shippingAddressEtc == nil {
                    separator.text = "  "
                    baselView.roundCorner(cornerRadius: 4)                  // 上下を丸める
                    
                }else{
                    // shippingAddressEtc　がブランクでない場合には、下にセルがつくので、下側は丸めない
                    separator.text = ""
                    baselView.roundCorner(cornerRadius: 0, lower: false)   // 上の両端だけ丸める
                }
                
            }else{
    
                cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath)
                let baselView = cell.viewWithTag(100) as! OrosyUIView
                baselView.roundCorner(cornerRadius: 4, lower: true)   // 下の両端だけ丸める
                
                let noteTitle = cell.viewWithTag(1) as! UILabel
                let noteLabel = cell.viewWithTag(2) as! OrosyLabel14

                if let note = order.deliverTo?.shippingAddressEtc {
                    noteLabel.text = note
                    noteTitle.text = "備考"
                }else{

                    noteLabel.text = ""
                    noteTitle.text = ""
                }
            }
  

        case 3: // 商品一覧
  
           let itemOrder = order.itemsWholesale[row]
            
            cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
            let product = cell.viewWithTag(1) as! UILabel
            let productButton = cell.viewWithTag(20) as! IndexedButton
            productButton.indexPath = indexPath
            let variation = cell.viewWithTag(2) as! UILabel
            let sets = cell.viewWithTag(3) as! UILabel
            let unitPrice = cell.viewWithTag(4) as! UILabel
            let total = cell.viewWithTag(5) as! UILabel
            let quantity = cell.viewWithTag(6) as! UILabel
            let tax = cell.viewWithTag(7) as! UILabel
            
            product.text = itemOrder.item?.title
            var variant = ""
            if let variant1 = itemOrder.item?.variation1Label {
                variant = variant1 + "：" + (itemOrder.item?.variation1Value ?? "")
            }
            if let variant2 = itemOrder.item?.variation2Label {
               variant = variant + "   " + variant2 + "：" + (itemOrder.item?.variation2Value ?? "")
            }
            variation.text = variant
            sets.text = "セット数量：" + String(itemOrder.quantity)
            unitPrice.text = "：" + Util.number2Str(itemOrder.item?.wholesalePrice ?? 0)
            total.text = "：" + Util.number2Str((itemOrder.item?.wholesalePrice ?? 0).multiplying(by: NSDecimalNumber(value: itemOrder.quantity)))
            quantity.text = "：" + String(itemOrder.quantity)
            tax.text = "：" + Util.number2Str(itemOrder.taxAmount)
            
            if itemOrder.imageUrls.count > 0 {
                let imageView = cell.viewWithTag(10) as! OrosyUIImageView100
                imageView.targetRow = row
                imageView.getImageFromUrl(row: row, url:itemOrder.imageUrls.first )
            }
            
           case 4:

            if row == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "SeparatorCell", for: indexPath)
                
            }else if row > 0 && row <= subTotals.count {
               cell = tableView.dequeueReusableCell(withIdentifier: "SubTotalCell", for: indexPath)
               let label = cell.viewWithTag(1) as! UILabel
               let value = cell.viewWithTag(2) as! UILabel
            
               label.text = subTotals[row - 1]["label"]
               value.text = subTotals[row - 1]["value"]
            }else{
                cell = tableView.dequeueReusableCell(withIdentifier: "SeparatorCell", for: indexPath)
            }
        
           case 5:
             cell = tableView.dequeueReusableCell(withIdentifier: "TotalCell", for: indexPath)
             let subTotalView = cell.viewWithTag(100) as! OrosyUIView
             subTotalView.roundCorner(cornerRadius: 4, lower: true)   // 下の両端だけ丸める
             
             let subTotalLabel = cell.viewWithTag(2) as! OrosyLabel20B
             
           //  label2.text = "総合計"
             subTotalLabel.text = Util.number2Str(selectedOrder?.totalAmount.subtracting(order.useCredit) )
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
    
    
    @IBAction func pushedAddToCart(_ sender: Any) {
        // 選択中の商品をカートへ追加
        var message:String = ""
        var cartInSuccess = false
        
        waitIndicator.startAnimating()
        //self.showBlackCoverView(show: true)
        
        DispatchQueue.global().async {
            
            let result = self.selectedOrder?.addCart()
            
            switch result {
            case .success(_):
                message = "商品がカートに追加されました"
                cartInSuccess = true
                DispatchQueue.global().async {
                    for itemOrder in self.selectedOrder?.itemsWholesale ?? [] {
                        if let item = itemOrder.item {
                            g_userLog.addCart(itemId: item.id, pageUrl: self.orosyNavigationController?.currentUrl ?? "", count:itemOrder.quantity)
                        }
                    }
                }
                
            case .failure(let error):
                message = error.localizedDescription
                DispatchQueue.main.async {
                    self.waitIndicator.stopAnimating()
                   // self.showBlackCoverView(show: false)
                    
                    let dialog =  SmoothDialog()
                    self.view.addSubview(dialog)
                    dialog.show(message: message, pointY: self.view.bounds.height / 2.0 )
                }
                break
            default:
                break
            }
      
            if cartInSuccess {
                g_cartUpdated = true
                LogUtil.shared.log ("カートへ追加")

                // 成功した場合
                DispatchQueue.main.async {
                    self.waitIndicator.stopAnimating()
                    //self.showBlackCoverView(show: false)
                    
                    let frame = self.cartInMessageView.frame
                    self.cartInMessageView.bringSubviewToFront(self.view)
                    self.cartInMessageView.alpha = 0
                    UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseOut],  animations: {
                        self.cartInMessageView.alpha = 1
                    }, completion: { (finished: Bool) in
                        UIView.animate(withDuration: 0.3, delay: 1.5, options: [.curveEaseOut], animations: {
                            self.cartInMessageView.alpha = 0
                        }, completion: { (finished: Bool) in

                        })
                    })
                }
            }
        }
    }
        

    func orderStatusToLongString(_ orderStatus: OrderStatus?, isConsignmentItems:Bool) -> String {
        
        guard let status = orderStatus else { return "ERROR" }
        
        switch status {
            case OrderStatus.PAYMENT_PENDING: return "掛払いの審査中です"
            case OrderStatus.PENDING: return "商品の発送を待っています"
            case OrderStatus.SENT: return "商品が発送されました"
            case OrderStatus.ENDPERIOD: return "委託商品の販売結果を報告しましょう"
            case OrderStatus.SENTBACK_PENDING: return " 商品を返送しましょう"
            case OrderStatus.SENTBACK: return "商品を返送しました"
            case OrderStatus.DONE:
                if isConsignmentItems {return "返送商品が確認されました" }else{return "商品が発送されました"  }
            case OrderStatus.CANCEL: return "キャンセルされました"
            case OrderStatus.FAILED:
                return "エラーが発生しました、再度注文を行って下さい"

        }
    }
    
    @IBAction func showDeliveryInfo(_ sender: Any) {
        // 配送状況の問いわせ
        if let url = selectedOrder?.deliveryDetail?.url {
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: false, completion: nil)
        }
    }
    
    // サプライヤページへ遷移
    var lockGotoSupplierPageButton = false
    @IBAction func showSupplierPage(_ sender:  UIButton) {

        if lockGotoSupplierPageButton { return }         //　2度押し防止
        lockGotoSupplierPageButton = true


        if let supplier = selectedOrder?.supplier {
           /*
            if let act = sender.activityIndicator {
                DispatchQueue.main.async{
                    act.startAnimating()
                }
            }
            */
            DispatchQueue.global().async{
                
                var supplierHasData:Supplier!
    
                    supplierHasData = supplier
                //}

                _ = supplierHasData.getNextSupplierItemParents()

                if supplierHasData.getAllInfo(wholeData: true) {
     
                    // サプライヤーページへ遷移
                    DispatchQueue.main.async{
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "ProductListVC") as! ProductListVC
                        object_setClass(vc.self, SupplierVC.self)
                        
                        vc.navigationItem.leftItemsSupplementBackButton = true
                        vc.productListMode = .ProductList
                        vc.supplier = supplierHasData
  
                        self.orosyNavigationController?.pushViewController(vc, animated: true)
                        /*
                        if let act = sender.activityIndicator  {
                            act.stopAnimating()
                        }
                         */
                    }
                }
                self.lockGotoSupplierPageButton = false
            }
        }
        
    }
    
    var lockGotoProductPageButton = false
    
    @IBAction func showProductPage(_ sender: IndexedButton) {
        
        return
        
        //今は機能がない
        /*
        if lockGotoProductPageButton { return }         //　2度押し防止
        lockGotoProductPageButton = true
        
        let row = sender.indexPath?.row ?? 0
        if let itemOrder = selectedOrder?.itemsWholesale[row] {

            if let act = sender.activityIndicator {
                DispatchQueue.main.async{
                    act.startAnimating()
                }
            }
            
            DispatchQueue.global().async{
                    // プロダクトページへ遷移
                    DispatchQueue.main.async{
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "ProductDetailVC") as! ProductDetailVC
                        vc.navigationItem.leftItemsSupplementBackButton = true

                        let supplier = Supplier(supplierId: self.selectedOrder?.supplier?.id ?? "")          // これを先に指定しておく必要がある
                        _ = supplier?.getNextSupplierItemParents()
                        vc.supplier = supplier
                        vc.itemParent_id = itemOrder.item?.id ?? ""
                        
                        self.orosyNavigationController?.pushViewController(vc, animated: true)
                        
                        if let act = sender.activityIndicator  {
                            act.stopAnimating()
                        }
                    }
           
                self.lockGotoProductPageButton = false
            }
        }
         */
    }
    
    // =============
    // MARK: 請求書表示処理
    
    @IBAction func receiptVIewPushed(_ sender: Any) {
        
        let message = NSLocalizedString("ReceiptNotReady", comment: "")
        
        
        let dialog =  SmoothDialog()
        self.view.addSubview(dialog)
        dialog.show(message: message)
        
        
       // setupWebKit()
        /*
        if let number = selectedOrder?.orderNo {
            let urlString = "https://retailer.orosy.com/order/\(number)/receipt"
            if let url = URL(string: urlString) {
               // let safariViewController = SFSafariViewController(url: url)
               // present(safariViewController, animated: false, completion: nil)
            }
        }
         */
    }
    
    func setupWebKit() {
        let webConfiguration = WKWebViewConfiguration()
        let userController: WKUserContentController = WKUserContentController()
        userController.add(self, name: "LOGIN_COMPLETE")
        webConfiguration.userContentController = userController
        webView = WKWebView( frame: self.view.frame   , configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        self.view.addSubview(webView)

        if let url = NSURL(string: "https://retailer.orosy.com/#") {
           let request = NSURLRequest(url: url as URL)
            self.webView.load(request as URLRequest)
            self.webView.navigationDelegate = self
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let select = message.body as? String ?? ""
        print(select)
        
        
        if select == "LOGIN_COMPLETE" {
            
        }
    }
    
    /*
     <a href="#" @click="showLoginForm">ログイン</a>
     ID入力       <label for="input-437" class="v-label theme--light" style="left: 0px; right: auto; position: absolute;">メールアドレス</label>
     pwd        <label for="input-441" class="v-label theme--light error--text" style="left: 0px; right: auto; position: absolute;">パスワード</label>
     <button data-v-4e7a6a32="" type="button" class="v-btn v-btn--block v-btn--has-bg v-btn--rounded theme--light v-size--x-large primary"><span class="v-btn__content">ログイン</span></button>
     
     */
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        
        webView.evaluateJavaScript(
                  """
                    showLoginForm();
                  """ )
                  {  (response, error) in
                      
                  }

    }
    
}
