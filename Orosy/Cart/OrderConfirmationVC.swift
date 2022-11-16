//
//  OrderConfirmationVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/11/09.
//

import UIKit


class OrderConfirmationVC: OrosyUIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var MainTableView: UITableView!
    @IBOutlet weak var orderWaitIndicatior: UIActivityIndicatorView!
    @IBOutlet weak var orderExecButton: OrosyButtonGradient!
    var cartList:Cart?
    var cartVC:CartVC!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNaviTitle(title: "注文内容確認")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"blank"), style:.plain, target: self, action: nil)    // タイトルがセンターになるようにダミーのボタンを配置
        orderExecButton.setButtonTitle(title: "注文を確定する", fontSize: 16)
        
        if #available(iOS 15.0, *) {
            MainTableView.sectionHeaderTopPadding = 0.0 // iOS15から追加された、セクションヘッダーの上のスペースを消す
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        cartVC = storyboard.instantiateViewController(withIdentifier: "CartVC") as? CartVC
        cartVC.readOnly = true

        //　テーブルの一番下にマージンを空ける
        let footerView = UIView(frame:CGRect(x:0, y:0, width:100, height:20))
        MainTableView.tableFooterView = footerView
        
        MainTableView.reloadData()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(reset), name: Notification.Name(rawValue:NotificationMessage.Reset.rawValue), object: nil)

    }

    @objc func reset() {
        DispatchQueue.main.async{
            self.orosyNavigationController?.popToRootViewController(animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if g_cartUpdated {
            self.orosyNavigationController?.popToRootViewController(animated: false)
            
        }
        
        cartList = g_cart
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2  + (cartList?.cartSections.count ?? 0)
    }
    
    /*
     func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

         var height:CGFloat = 0
         
         if section == 2 {
             height = 30
         }
         return height
     }
    
   
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView(frame:CGRect(x:0, y:6, width:tableView.bounds.width, height:24))

        
        let label = UILabel(frame:view.frame)
        label.textAlignment = .center
        label.text = "購入ブランドの全商品"
        label.font = UIFont(name: OrosyFont.Bold.rawValue, size: 16)
        view.addSubview(label)

        return view
    }
    */
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let section = indexPath.section
        
        if let cartSections = cartList?.cartSections {
            if section > 1 && cartSections.count > section - 2 {
                let cartSection = cartSections[section - 2]
                let row = indexPath.row
                
                if row == 1 {   // ブランド小計の内訳行
                    if cartSection.opened {    // 詳細表示
                        return UITableView.automaticDimension
                    }else{
                        return 0
                    }
                }
            }
        }
        
        return UITableView.automaticDimension //自動設定
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 1
        
        if section >= 2 {
            if let cartSections =  cartList?.cartSections {
                if cartSections.count > section - 2 {
                    let cartSection = cartSections[section - 2]
                    count = cartSection.cartItems.count + 3 // ヘッダ、ボディ、フッターの後にアイテム学r
                }else{
                    count = 0
                }
            }
        }
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = indexPath.section
        let row = indexPath.row
        
        var cell:UITableViewCell!
        
        switch section {
        case 0: //　お届け先、支払い方法
            
            cell = tableView.dequeueReusableCell(withIdentifier: "PayShipCell", for: indexPath)
            
            let label1 = cell.viewWithTag(1) as! UILabel
            let label2 = cell.viewWithTag(2) as! UILabel
            let label3 = cell.viewWithTag(3) as! UILabel
            
            let selectedDeliveryPlace = g_cart.deliveryPlace
            label1.text = selectedDeliveryPlace?.name ?? ""
            label2.text = (selectedDeliveryPlace?.shippingAddress?.postalCode ?? "") + "\n" + (selectedDeliveryPlace?.shippingAddress?.concatinated ?? "")
            label3.text = g_cart.payment?.name ?? ""
        
        case 1: // ブランド合計
            
            cell = tableView.dequeueReusableCell(withIdentifier: "CartListCell", for: indexPath)
            
            let stackView = cell.contentView.viewWithTag(100) as! UIStackView
            stackView.removeFullyAllArrangedSubviews()
            
            print(stackView.bounds.width, cell.contentView.bounds.width)
            
            var stackCount = 0

            for cartSection in cartList!.cartSections {
            
                let view = setLabelView(label:cartSection.supplier?.brandName ?? "", value:Util.number2Str(cartSection.totalAmount), width:stackView.bounds.width)
                stackCount += 1

                stackView.addArrangedSubview(view)
           }
            
          if stackCount > 0 {
              let viewHeight = CGFloat(stackCount) * 40.0
              stackView.heightAnchor.constraint(equalToConstant:viewHeight).isActive = true
          }

        // 合計金額
            let tax10 = cartList?.getTax(itax: 10) ?? .zero
            let tax8 = cartList?.getTax(itax: 8) ?? .zero
            stackCount = 3
            
            let itemTotal = cartList?.totalAmount.subtracting(cartList?.totalShippingFeeAmount ?? .zero).subtracting(tax10).subtracting(tax8)
            let stackView2 = cell.contentView.viewWithTag(101) as! UIStackView
            stackView2.removeFullyAllArrangedSubviews()
            stackView2.addArrangedSubview(setLabelView(label:"商品小計", value:Util.number2Str(itemTotal), width:stackView.bounds.width))     // 税抜合計
            
            if !tax10.isEqual(to: NSDecimalNumber.zero) {
                stackView2.addArrangedSubview(setLabelView(label:"消費税（10％）", value:Util.number2Str(tax10), width:stackView.bounds.width))
                stackCount += 1
            }
            if !tax8.isEqual(to: NSDecimalNumber.zero) {
                stackView2.addArrangedSubview(setLabelView(label:"消費税（8％）", value:Util.number2Str(tax8), width:stackView.bounds.width))
                stackCount += 1
            }
            stackView2.addArrangedSubview(setLabelView(label:"送料（税込）", value:Util.number2Str(cartList?.totalShippingFeeAmount), width:stackView.bounds.width))
            stackView2.addArrangedSubview(setLabelView(label:"ポイント", value:Util.number2Str(NSDecimalNumber.zero.subtracting( cartList?.discount ?? .zero)), width:stackView.bounds.width))
         
            let viewHeight = CGFloat(stackCount) * 40.0
            stackView2.heightAnchor.constraint(equalToConstant:viewHeight).isActive = true
            
        // 総計
            let stackView3 = cell.contentView.viewWithTag(102) as! UIStackView
            stackView3.removeFullyAllArrangedSubviews()
            stackView3.addArrangedSubview(setLabelView(label:"総合計", value:Util.number2Str(cartList?.totalAmount.subtracting(cartList?.discount ?? .zero)), width:stackView.bounds.width, font:20))
            
        default:    // section 2以降はカートに入っている商品を表示
            
            cartVC.cartList = cartList
            cell = cartVC.tableView(tableView, cellForRowAt: IndexPath(row:row, section:section - 2))
            
            if row == 0 {
                if let cartSection = cartList?.cartSections[section - 2] {
                    let openButton = cell.viewWithTag(1002) as! IndexedButton
                    openButton.indexPath = indexPath    // IndexPath(row:row, section: section - 2)
                    openButton.isSelected = cartSection.opened
                    openButton.removeTarget(nil, action: nil, for: .allEvents)
                    openButton.addTarget(self, action: #selector(openDetail), for: .touchUpInside)
                }
            }
        }

        return cell
    }


    
    @IBAction func openDetail(_ sender: Any) {
        
        let button = sender as! IndexedButton
        if let indexPath = button.indexPath {

            if let cartSection = self.cartList?.cartSections[indexPath.section - 2] {
                cartSection.opened = !cartSection.opened
                button.isSelected = cartSection.opened
                MainTableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
    
    func setLabelView(label:String, value:String, width:CGFloat, font:CGFloat = 16) -> UIView {
        let valueWidth:CGFloat = 150
        
        let view = UIView(frame:CGRect(x:0, y:0, width:width, height:40))

        let labelFrame = CGRect(x:0, y:0, width:width - valueWidth, height:40)
        let labelView = OrosyLabel14(frame:labelFrame)
        labelView.textColor = UIColor.orosyColor(color: .Black600)
        labelView.font = UIFont(name: OrosyFont.Regular.rawValue, size: 14)
        labelView.text = label
        view.addSubview(labelView)
        
        let valueFrame = CGRect(x:width - valueWidth, y:0, width:valueWidth, height:40)
        let valueLabel = OrosyLabel16B(frame:valueFrame)
        valueLabel.textColor = UIColor.orosyColor(color: .Black600)
        valueLabel.text = value
        valueLabel.textAlignment = .right
        valueLabel.font = UIFont(name: OrosyFont.Bold.rawValue, size: font)
        view.addSubview(valueLabel)
        
        view.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return view
    }
    
    /*
    func getBrandTotalLine(_ stackView:UIStackView) {
        
        let frame = stackView.frame
        var idx = 0
        var stackCount = 0
        var view = UIView()
        view.tag = 99
        
        if let cartSections = cartList?.cartSections  {
            for brand in cartSections {
            
                let labelFrame = CGRect(x:0, y:CGFloat(stackCount) * 25, width:frame.size.width, height:25)
                let titleLabel = OrosyLabel14(frame:labelFrame)
                titleLabel.textColor = UIColor.orosyColor(color: .Blue)
                titleLabel.text = sns.url?.absoluteString ?? ""
                titleLabel.adjustsFontSizeToFitWidth = false
                    view.addSubview(titleLabel)
                    
     
                    stackCount += 1
                    
                idx += 1
            }
            
            if stackCount > 0 {
                let viewHeight = CGFloat(stackCount) * 25.0
                view.heightAnchor.constraint(equalToConstant: viewHeight).isActive = true
                stackView.addArrangedSubview(view)
                stackView.heightAnchor.constraint(equalToConstant:viewHeight + 40 ).isActive = true
            }
        }

    }
    */
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  
        MainTableView.reloadData()
    }

    @IBAction func doPayment() {

        if (g_cart.payment.type == .NP && ProfileDetail.shared.npStatus != .approved) {
            self.confirmAlert(title:"", message:"現在掛金枠の審査中です。申し訳ありませんが1,2日経ってから再度お試し下さい。", ok:"確認")
            return
        }

        DispatchQueue.main.async {
         //   self.orderWaitIndicatior.startAnimating()
            self.showBlackCoverView(show: true)
        }
        
        var result:Result<String,Error>!
        DispatchQueue.global().async {
            result = g_cart.orderAllItems()     // 注文

            DispatchQueue.main.async {
                self.showBlackCoverView(show: false)
               // self.orderWaitIndicatior.stopAnimating()
                
                var title = ""
                var message = ""
                var order_error = false
                
                switch result {
                case .success(let orderNo):
                    title = "注文を完了しました"
                    message = "注文No.は \(orderNo) です。"
                    
                    g_userLog.cartOrder(contentId: orderNo, pageUrl: self.orosyNavigationController?.currentUrl ?? "")
                    
                case .failure(let error):
                    title = "注文できませんでした"
                    message = error.localizedDescription
                    order_error = true
                default:
                    break
                }
                
                let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle:  UIAlertController.Style.alert)
                
                let defaultAction: UIAlertAction = UIAlertAction(title: "確認", style: UIAlertAction.Style.default, handler:{
                    // ボタンが押された時の処理を書く（クロージャ実装）
                    (action: UIAlertAction!) -> Void in
                    
                    g_cart = nil // カートオブジェクトをクリアー
                    g_cartUpdated = true
                    let notification = Notification.Name(NotificationMessage.RefreshOrderList.rawValue)   // 注文履歴データの更新を依頼
                    NotificationCenter.default.post(name: notification, object: nil, userInfo: nil)
                    
                    let targetViewController = self.navigationController!.viewControllers[0]    // Root（カートページ）から数えたビューコントローラの位置
                    self.navigationController?.popToViewController(targetViewController, animated: true)
                    if !order_error {

                        if let tabbar = self.tabBarController{
                            self.tabBarController?.selectedIndex = 4
                            //　先頭viewへ戻す
                            if let navi = tabbar.viewControllers?[4] as? OrosyNavigationController {
                                navi.popToRootViewController(animated: false)
                            }
                        }
                    }
                })
                
                alert.addAction(defaultAction)
                
                self.present(alert, animated: true, completion: nil)
            }
        }
        
    }
}
