//
//  CartViewController.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/09.
//

import UIKit

enum ItemType_CartGrandTotal {
    case ITEM_TOTAL
    case TAX
    case SHIPPING_FEE
    case TOTAL_AMOUNT
    case DEPOSIT

}


class DisplayItem_CartGrandTotal: NSObject {
    var itemType:ItemType_CartGrandTotal?
    var title:String?
    var cellType:String?
    var itemObject: NSObject?
    var itemHeight:CGFloat
    var fontSize:Int
    var index:Int
    

    init( type:ItemType_CartGrandTotal, title:String?, cell:String?, fontSize:Int, height:CGFloat, index:Int ) {
        
        itemType = type
        self.title = title
        cellType = cell
        itemHeight = height
        self.fontSize = fontSize
        self.index = index
    }
}

class DisplayItem_CartSectionTotal: NSObject {
    var itemType:ItemType_CartGrandTotal?
    var title:String?
    var cellType:String?
    var itemObject: NSObject?
    var itemHeight:CGFloat
    var fontSize:CGFloat
    var index:Int
    

    init( type:ItemType_CartGrandTotal, title:String?, cell:String?, fontSize:CGFloat, height:CGFloat, index:Int ) {
        
        itemType = type
        self.title = title
        cellType = cell
        itemHeight = height
        self.fontSize = fontSize
        self.index = index
    }
}



class CartVC: OrosyUIViewController, UITableViewDataSource, UITableViewDelegate, OrosyProcessManagerDelegate, ConfirmControllerDelegate {
    
    @IBOutlet weak var MainTableView: UITableView!
    @IBOutlet weak var groundTotalView: UIView!             // 総計表示用
    @IBOutlet weak var cartMessage: UILabel!
    
    @IBOutlet weak var orderButtonBotomConstraint: NSLayoutConstraint!
    @IBOutlet weak var OrderButton: OrosyButton!
    @IBOutlet weak var waitIndicator: UIActivityIndicatorView!
    @IBOutlet weak var confirmView: CustomUIView!
    
    var readOnly:Bool = false   // 確認画面の場合には trueにして　数量ボタンを非表示にする
    var cartList:Cart?  // カートの全情報を保持しているオブジェクト。後続の処理で出荷先、支払い方法を選択するが、それもこのオブジェクトに保存している
    var uuid_cartList:String?
    var uuid_payment:String?

    
    var itemList:[DisplayItem_CartGrandTotal] = []
    var itemList_Section:[DisplayItem_CartSectionTotal] = []
    
    var sectionTotalTableList:[UITableView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        noDataAlert.selectType(type: .cart)
       
        g_cartVC = self
        self.setNaviTitle(title: "カート")

        self.navigationItem.leftBarButtonItems = []     // 戻るボタンを非表示
        self.navigationItem.hidesBackButton = true 

        OrderButton.setButtonTitle(title: NSLocalizedString("ShippingAndPayment", comment: ""), fontSize: 12)
        OrderButton.isEnabled = false
        
        //　テーブルの一番下にマージンを空ける
        let footerView = UIView(frame:CGRect(x:0, y:0, width:100, height:20))
        MainTableView.tableFooterView = footerView
        
        MainTableView.refreshControl = UIRefreshControl()
        MainTableView.refreshControl?.addTarget(self, action: #selector(refreshTable), for: .valueChanged)
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(getData), name: Notification.Name(rawValue:NotificationMessage.SecondDataLoad.rawValue), object: nil)
        nc.addObserver(self, selector: #selector(reset), name: Notification.Name(rawValue:NotificationMessage.Reset.rawValue), object: nil)
        
    }
    

    @objc func reset() {
        if noDataAlert != nil { noDataAlert.isHidden = false }
        cartList = nil
        uuid_cartList = nil
        uuid_payment = nil
        
        DispatchQueue.main.async {
            self.OrderButton.isEnabled = false
            self.MainTableView.reloadData()
            self.setGroundTotalView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !g_loginMode {
            self.OrderButton.isEnabled = false
            self.noDataAlert.isHidden = false

        }else{
            if g_cartUpdated {
                uuid_cartList = nil
                OrderButton.isEnabled = false
                getData()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if  g_processManager.getStatus(uuid: uuid_cartList) == .Running {   // uuid_cartList == nil ||
            DispatchQueue.main.async {
                self.waitIndicator.startAnimating()
            }
        }
    }
    

    @objc func getData() {
 
        if uuid_cartList == nil {
            uuid_cartList = g_processManager.addProcess(name:"カート情報", action:self.refreshData , errorHandlingLevel: .IGNORE, errorCountLimit: -1, execInterval: 5, immediateExec: true, processType:.Once, delegate:self)
        }
        
        if g_paymentList == nil {
            g_paymentList = PaymentList()
        }
        if uuid_payment == nil {
            uuid_payment = g_processManager.addProcess(name:"支払い方法データ取得", action: g_paymentList.getPaymentData, errorHandlingLevel: .IGNORE, errorCountLimit: 5, execInterval: 5, immediateExec: false, processType:.Once, delegate:self)
        }
    }

    // 合計や消費税はサーバ側で計算しているので、カートの商品を削除したり追加した場合は、サーバから読み直す必要がある
    func refreshData() -> Result<Any?, OrosyError>{
        LogUtil.shared.log ("カート情報の読み込み")

        let result = Cart().updateCart()
        
        switch result {
        case .success(let cart):
            
            // 「詳細を見る」の状態を保持する
            for newCartSection in cart.cartSections {
                for cartSection in cartList?.cartSections ?? [] {
                    if (newCartSection.supplier?.id ?? "") == (cartSection.supplier?.id ?? "") {
                        newCartSection.opened = cartSection.opened
                    }
                }
            }
            cartList = cart

        case .failure(let error):
            //confirmAlert(title: "エラー", message: error.localizedDescription, ok:"確認")
            return .failure(error)
        }
        
        g_cart = cartList
        if g_cart.payment == nil {
            g_cart.payment = g_paymentList?.getPayment( paymentType:UserDefaultsManager.shared.selectedPayment ?? .NONE)
        }
        
        return .success(true)
    }


    func processCompleted(_: String?) {
        
        if uuid_cartList == nil || uuid_payment == nil { return }
        if  g_processManager.getStatus(uuid: uuid_cartList) == ProcessStatus.Completed  &&  g_processManager.getStatus(uuid: uuid_payment) == ProcessStatus.Completed  {
            g_cartUpdated = false
       
            DispatchQueue.main.async {
                self.waitIndicator.stopAnimating()
                self.MainTableView.reloadData()
                
                self.setGroundTotalView()

                if self.cartList?.cartSections.count == 0 {
                    self.OrderButton.isEnabled = false
                    self.noDataAlert.isHidden = false
                }else{
                    self.OrderButton.isEnabled = true
                    self.noDataAlert.isHidden = true
                }
            }
        }
    }
    
    // ブランド毎にセクションを分ける
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return cartList?.cartSections.count ?? 0
    }

    // ブランド上部のマージン
    let topMargin:CGFloat = 0
     func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

         return topMargin
     }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let marginView = UIView(frame: CGRect(x:0, y:0, width:tableView.bounds.width, height: topMargin))
        marginView.backgroundColor = UIColor.orosyColor(color: .Background)
        return marginView
    }


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        let cartSection = cartList?.cartSections[indexPath.section]
        let row = indexPath.row
        
        if row == 1 {   // ブランド小計の内訳行
            
            if cartSection!.opened {    // 詳細表示
                return UITableView.automaticDimension
            }else{
                return 0
            }
        }
        return UITableView.automaticDimension //自動設定
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let cartSection = cartList?.cartSections[section]
        let count = (cartSection == nil) ? 0 : ((cartSection?.cartItems.count ?? 0 ) + rowForCartSection)    // ＋1は小計用
   
        return count
    }
    

    var max_stack_row:Int = 0  // スタックの最大行数。　余計な行を削除するために使用
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = indexPath.section
        let row = indexPath.row
        
        var cell:UITableViewCell!
        
    //    if tableView == MainTableView {
            if let cartSection = cartList?.cartSections[section] {
                // 商品毎の価格表示
                switch row {
                case 0:
                    tableView.register(UINib(nibName: "CartSectionTotalSB", bundle: nil), forCellReuseIdentifier: "CartSectionTotalCell")
                    cell = tableView.dequeueReusableCell(withIdentifier: "CartSectionTotalCell", for: indexPath)
                    
                    // 上だけ角丸にする
                    let baseView = cell.viewWithTag(1000) as! OrosyUIView
                    baseView.roundCorner(cornerRadius: 4, lower: false)   // 上の両端だけ丸める
    
                    //
                    let activityIndicator = cell.viewWithTag(101) as! UIActivityIndicatorView
                    let showSupplierButton = cell.viewWithTag(100) as! IndexedButton
                    showSupplierButton.indexPath = indexPath
                    showSupplierButton.activityIndicator = activityIndicator
                    showSupplierButton.addTarget(self, action: #selector(showSupplierPage), for: .touchUpInside)   // このビューに紐づいているNIBのセルとは異なるセルを使っていうので、ここで定義する必要がある
                    
                    let iconView = cell.viewWithTag(10) as! OrosyUIImageView100
                    iconView.getImageFromUrl(row:row,  url: cartSection.supplier?.iconImageUrl, radius:iconView.bounds.height / 2.0)
                    iconView.targetRow = row
                    
                    let openButton = cell.viewWithTag(1002) as! IndexedButton
                    openButton.indexPath = indexPath
                    openButton.isSelected = cartSection.opened
                    openButton.addTarget(self, action: #selector(openDetail), for: .touchUpInside)   // このビューに紐づいているNIBのセルとは異なるセルを使っていうので、ここで定義する必要がある
                    
                    let brandNameLabel = cell.viewWithTag(1) as! UILabel
                    brandNameLabel.text = cartSection.supplier?.brandName ?? ""
                    
                    let totalAmountLabel = cell.viewWithTag(3) as! OrosyLabel16B
                    totalAmountLabel.text = Util.number2Str(cartSection.totalAmount)
                    
                case 1:     // ボタンによって表示・非表示を切り替えられる
                    tableView.register(UINib(nibName: "CartSectionBodySB", bundle: nil), forCellReuseIdentifier: "CartSectionBodyCell")
                    cell = tableView.dequeueReusableCell(withIdentifier: "CartSectionBodyCell", for: indexPath)
                    if let stack = cell.viewWithTag(100) as? UIStackView {
                        (stack.viewWithTag(101) as! UILabel).text = "商品小計"
                        (stack.viewWithTag(102) as! UILabel).text = "：" + Util.number2Str(cartSection.totalItemPrice)
    
                        
                        var largeTax:Tax? = nil
                        var smallTax:Tax? = nil
                        
                        for tax in cartSection.taxes {
                            if largeTax == nil {
                                largeTax = tax
                            }else{
                                if largeTax!.tax < tax.tax {
                                    smallTax = largeTax
                                    largeTax = tax
                                }else{
                                    smallTax = tax
                                }
                            }
                        }
                        
                        // 二つある場合は、大きい方を先に表示する
                        if let taxItem = largeTax {
                            (stack.viewWithTag(103) as! UILabel).text = "消費税（\(taxItem.tax)％）"
                            (stack.viewWithTag(104) as! UILabel).text = "：" + Util.number2Str(taxItem.amount)
                        }
                        if let taxItem = smallTax {
                            (stack.viewWithTag(105) as! UILabel).text = "消費税（\(taxItem.tax)%）"
                            (stack.viewWithTag(106) as! UILabel).text = "：" + Util.number2Str(taxItem.amount)
                        }else{
                            (stack.viewWithTag(105) as! UILabel).text = ""
                            (stack.viewWithTag(106) as! UILabel).text = ""
                        }
                    }
                case 2:     //セクションの一番下に表示する「送料見込み」
                    tableView.register(UINib(nibName: "CartSectionFooterSB", bundle: nil), forCellReuseIdentifier: "CartSectionFooterCell")
                    cell = tableView.dequeueReusableCell(withIdentifier: "CartSectionFooterCell", for: indexPath)

                    let shippingFeeLabel = cell.viewWithTag(3) as! UILabel
                    let freeShippingConditionLabel = cell.viewWithTag(4) as! UILabel
                    var diffForFreeShipping:NSNumber = 0
                    
                    if let shippingFeeRules = cartSection.supplier?.shippingFeeRules {
                        if shippingFeeRules.first?.type == "free" {
                            if let triggerCount = shippingFeeRules.first?.triggerCount {             // NSDecimalNumber
                                diffForFreeShipping = triggerCount.subtracting(cartSection.totalItemPrice)
                            }
                        }
                    }
                    shippingFeeLabel.text = "送料見込み：" + Util.number2Str(cartSection.shippingFeeAmount)    //　送料は配送先（都道府県）によって異なるが、ここでは配送先が決まっていないので、見込み送料となっている
                    freeShippingConditionLabel.text = ((diffForFreeShipping.intValue > 0) ? "あと" + Util.number2Str(diffForFreeShipping) + "円で送料無料" : "")

                default:
                    tableView.register(UINib(nibName: "CartSectionItemSB", bundle: nil), forCellReuseIdentifier: "CartSectionItemCell")
                    cell = tableView.dequeueReusableCell(withIdentifier: "CartSectionItemCell", for: indexPath)
                    
                    //　一番下だけ角丸にする
                    let baseView = cell.viewWithTag(1000) as! OrosyUIView
                    if row - 2 == cartSection.cartItems.count {
                        baseView.roundCorner(cornerRadius: 4, lower: true)   // 下の両端だけ丸める
                    }else{
                        baseView.roundCorner(cornerRadius: 0)
                    }
   
                    
                    let cartItem = cartSection.cartItems[row - 3]

                    let imageView = cell.viewWithTag(10) as! OrosyUIImageView100
                    imageView.drawBorder(cornerRadius: 0, color: UIColor.orosyColor(color: .Gray300), width: 1)
                    let titleLabel = cell.viewWithTag(1) as! UILabel
                    
                    var labels:[UILabel] = []
                    labels.append(cell.viewWithTag(2) as! UILabel)
                    labels.append(cell.viewWithTag(3) as! UILabel)
                    labels.append(cell.viewWithTag(4) as! UILabel)
                    labels.append(cell.viewWithTag(5) as! UILabel)
                    let priceLabel = cell.viewWithTag(6) as! UILabel
                   // let indicator = cell.viewWithTag(10) as! UIActivityIndicatorView
                    
                    if let item = cartItem.item {
                        
                        imageView.getImageFromUrl(row:row, url: cartItem.itemParent?.imageUrls.first)
                        imageView.targetRow = row
                        
                        titleLabel.text = item.title ?? ""
                        priceLabel.text = Util.number2Str(item.wholesalePrice)

                        var ip = 0
                        if item.variation1Label != nil && item.variation1Value != nil {
                            labels[ip].text = "\(item.variation1Label!)：\(item.variation1Value!)"
                            ip += 1
                        }
                        
                        if item.variation2Label != nil && item.variation2Value != nil {
                            labels[ip].text = "\(item.variation2Label!)：\(item.variation2Value!)"
                            ip += 1
                        }
                        labels[ip].text = "セット数量：" + String(cartItem.item?.setQty ?? 0) + "個"
                        ip += 1
                        labels[ip].text = "消費税：\(item.tax)%"      // (Util.number2Str(cartItem.taxAmount)) "
                        ip += 1
                        
                        for rest in ip..<4 {
                            labels[rest].text = ""
                        }
                    }

                    //
                    let indicator = cell?.viewWithTag(200) as! UIActivityIndicatorView
                    
                    let opneProductButton = cell.viewWithTag(101) as! IndexedButton
                    opneProductButton.indexPath = indexPath
                    opneProductButton.addTarget(self, action: #selector(showProductPage), for: .touchUpInside)
                    
                    let closeButton = cell.viewWithTag(100) as! IndexedButton
                    closeButton.indexPath = indexPath
                    closeButton.isHidden = readOnly
                    closeButton.addTarget(self, action: #selector(removeItemButtonPushed), for: .touchUpInside)
                    
                    let incDecButtonView = cell.viewWithTag(20)!
                    incDecButtonView.isHidden = readOnly
                    
                    let minusButton = incDecButtonView.viewWithTag(-1) as! IndexedButton
                    minusButton.layer.borderColor = UIColor.orosyColor(color: .Gray300).cgColor
                    minusButton.layer.borderWidth = 1
                    minusButton.indexPath = indexPath
                    minusButton.addTarget(self, action: #selector(updateQuantity), for: .touchUpInside)
                    minusButton.activityIndicator = indicator
                    
                    let plusButton = incDecButtonView.viewWithTag(1) as! IndexedButton
                    plusButton.indexPath = indexPath
                    plusButton.layer.borderColor = UIColor.orosyColor(color: .Gray300).cgColor
                    plusButton.layer.borderWidth = 1
                    plusButton.addTarget(self, action: #selector(updateQuantity), for: .touchUpInside)
                    plusButton.activityIndicator = indicator
                    
                    let quantityLabel = cell.viewWithTag(103) as! UILabel

                    let quantity = cartItem.quantity    // カートにセットされていた数量をデフォルトとしてセット
                    quantityLabel.text = String(quantity)

                    let quantityLabel2 = cell.viewWithTag(7) as! OrosyLabel16
                    if readOnly {
                        quantityLabel2.text = "X \(String(cartItem.quantity))個"
                    }else{
                        quantityLabel2.text = ""
                    }
                    //
                    let quantityButton = incDecButtonView.viewWithTag(10) as! IndexedButton       // 数量設定メニュー
                    quantityButton.activityIndicator = indicator
                    quantityButton.indexPath = indexPath
                    setUnitButtonMenu(menuButton: quantityButton, cartItem:cartItem, label:quantityLabel)

                    
                }
            }
   
     //   }
 

        return cell
    }
    


    // 詳細を見る
    @IBAction func openDetail(_ sender: Any) {
        
        let button = sender as! IndexedButton
        if let indexPath = button.indexPath {

            if let cartSection = self.cartList?.cartSections[indexPath.section] {
                cartSection.opened = !cartSection.opened
                button.isSelected = cartSection.opened
                MainTableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
    
    // 数量変更
    @IBAction func updateQuantity(_ sender: Any) {

        let button = sender as! IndexedButton
        let indicator = button.activityIndicator
        
        if let indexPath = button.indexPath {
            let diff = button.tag

           // let cell = MainTableView.cellForRow(at: indexPath)
            //let indicator = cell?.viewWithTag(200) as! UIActivityIndicatorView
            
            let section = indexPath.section
            let cartRow = indexPath.row - self.rowForCartSection
            let cartSection = self.cartList?.cartSections[section]
            
            if let cartItem = cartSection?.cartItems[cartRow] {
                
                let quantity = cartItem.quantity + diff
                
                if quantity > cartItem.item?.inventoryQty ?? 0 {
                    // 在庫不足エラー
                    let dialog =  SmoothDialog()
                    self.view.addSubview(dialog)
                    dialog.show(message: NSLocalizedString("NotEnoughInventory", comment: ""))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dialog.show(message: NSLocalizedString("CallSupplier", comment: ""))
                    }

                }else if quantity < cartItem.item?.minLotQty ?? 0 {
                    // 最小数量エラー
                    let dialog =  SmoothDialog()
                    self.view.addSubview(dialog)
                    dialog.show(message: NSLocalizedString("NotEnoughQuantity", comment: ""))

                }else{
                    
                    if quantity >= 0 {
                        if let ind = indicator {
                            ind.startAnimating()
                        }
                        
                        DispatchQueue.global().async {
                            cartItem.quantity = quantity
                            let (success, result) = cartItem.updateQuantity()
                            
                            if success {
                                self.uuid_cartList = nil
                                self.getData()
                             }else{
                                 self.confirmAlert(title: "エラーになりました", message:result.description,ok:"確認")
                             }
                        }
                    }
                }
            }
        }
    }
    
    // 数量選択ボタンに数量をセット
    func setUnitButtonMenu(menuButton: IndexedButton, cartItem:CartItem, label:UILabel){
        
        let min = cartItem.item?.minLotQty ?? 0
        let max = cartItem.item?.inventoryQty ?? 0
        
        //メニュー項目をセット
        var actions = [UIMenuElement]()
        
        var limit = max
        if max > 50 { limit = 50 }
        let minValue = (min == 0) ? 1 : min
        if limit < minValue { limit = minValue }
            
        for number in (minValue..<limit+1) {

            actions.append(UIAction(title: String(number), image: nil, state: (cartItem.quantity == number) ? .on : .off, handler: { (_) in

                self.setUnitButtonMenu(menuButton:menuButton, cartItem:cartItem,label:label)
                cartItem.quantity = number
 
                label.text = String(number)

                if let ind = menuButton.activityIndicator {
                    ind.startAnimating()
                }
                DispatchQueue.global().async {
                    let (success, result) = cartItem.updateQuantity()
                    
                    if success {
                        self.uuid_cartList = nil
                        self.getData()
                     }else{
                         self.confirmAlert(title: "エラーになりました", message:result.description,ok:"確認")
                     }
                }

            }))
        }

        if actions.count > 0 {
            // UIButtonにUIMenuを設定
            menuButton.menu = UIMenu(title:"" , options: .displayInline, children: actions)
            // こちらを書かないと長押しで表示となる
            menuButton.showsMenuAsPrimaryAction = true
 
        }
    }
    
    
    // MARK: リフレッシュコントロールによる読み直し
    @objc func refreshTable() {
     
        uuid_cartList = nil
        getData()
        MainTableView.refreshControl?.endRefreshing()
        //MainTableView.reloadData()
    }
    
    
    func setSectionTotalItem(_ _cartSection:CartSection?) {
        
        guard let cartSection = _cartSection else{ return }
        
        itemList_Section = []
        
        //　ブランド毎の合計欄表示用項目設定
        itemList_Section.append(
            DisplayItem_CartSectionTotal(type: ItemType_CartGrandTotal.ITEM_TOTAL, title: "商品小計", cell:"", fontSize:14, height:30, index:0) )
        
        // 消費税率毎に消費税を表示しているため、有無によって表示・非表示が変化する。それを組み立てている。

        for taxObj in cartSection.taxes {
            itemList_Section.append(
                DisplayItem_CartSectionTotal(type: ItemType_CartGrandTotal.TAX, title: "消費税(\(taxObj.tax)%)", cell:"", fontSize:14, height:30, index:taxObj.tax)  )
        }

        itemList_Section.append(
            DisplayItem_CartSectionTotal(type: ItemType_CartGrandTotal.SHIPPING_FEE, title: "送料見込み（税込）", cell:"", fontSize:14, height:30, index:0)  )
        itemList_Section.append(
            DisplayItem_CartSectionTotal(type: ItemType_CartGrandTotal.DEPOSIT, title: "デポジット合計", cell:"", fontSize:14, height:30, index:0)  )
        itemList_Section.append(
            DisplayItem_CartSectionTotal(type: ItemType_CartGrandTotal.TOTAL_AMOUNT, title: "合計", cell:"", fontSize:16, height:40, index:0 )  )
    }
    

    //スワイプしたセルを削除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == UITableViewCell.EditingStyle.delete {
            
            //removeItem(indexPath)

        }
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt: IndexPath) -> String? {
        return "削除"
    }
    
    @IBAction func showBrandPage(_ sender: UIButton) {
        
        let tag = sender.tag - 100
        guard let cartSection = cartList?.cartSections[tag] else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SupplierVC") as! SupplierVC
        vc.navigationItem.leftItemsSupplementBackButton = true
        
        let supplierId = cartSection.supplier?.id
        
        if let sid = supplierId {
            vc.supplierId = sid
            self.orosyNavigationController?.pushViewController(vc, animated: true)
        }
    }
    
    let rowForCartSection = 3   // 最初の3行はカートセクションの情報を表示するために使用
    func removeItem(cartItem:CartItem) {
        
        self.showBlackCoverView(show:true)
        let result = cartItem.delete()
        
        self.showBlackCoverView(show:false)
        
        switch result {
        case .success(_):
            //cartSection?.cartItems.remove(at: cartRow)
            uuid_cartList = nil
            self.getData()
            
        case .failure(let error):
            self.confirmAlert(title: "エラーになりました", message:error.localizedDescription, ok:"確認")
         }
    }
    
    var selectedCartItem:CartItem!
    
    @IBAction func removeItemButtonPushed(_ sender: Any) {
        let button = sender as! IndexedButton
        if let indexPath = button.indexPath {
            let section = indexPath.section
            let row = indexPath.row
            
            let cartRow = row - rowForCartSection
            let cartSection = cartList?.cartSections[section]
            if let cartItem = cartSection?.cartItems[cartRow] {
                // 削除確認
                let msg = cartItem.item?.title ?? ""
                selectedCartItem = cartItem
                openConfirmVC(title:"商品をカートから削除", message:msg + "\nをカートから削除します。よろしいですか？", mainButtonTitle:"削除", cancelButtonTitle:"キャンセル")

            }
        }
    }
    

    func selectedAction(sel: Bool) {
        if sel {
            removeItem(cartItem: selectedCartItem)
        }
    }
    


    // MARK: 総計
    // 総計をセットアップ
    func setGroundTotalView() {

        let total = groundTotalView.viewWithTag(1) as! UILabel
        let numberOfBrand = groundTotalView.viewWithTag(2) as! UILabel

        total.text = Util.number2Str(cartList?.totalAmount)
        numberOfBrand.text = "ブランド数：" + String(cartList?.cartSections.count ?? 0)

    }

    // MARK: 画面遷移
    @IBAction func gotoDeliverySelectVC() {
        
        if g_cart == nil { return }
        
        var minimumChargeAmountError = false
        for cartSection in cartList?.cartSections ?? [] {
            if cartSection.totalAmount.intValue < 50 {
                minimumChargeAmountError = true
            }
        }
        
        
        let storyboard = UIStoryboard(name: "CartSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DeliverySelectVC") as! DeliverySelectVC
        vc.navigationItem.leftItemsSupplementBackButton = true
        vc.minimumChargeAmountError = minimumChargeAmountError

        self.orosyNavigationController?.pushViewController(vc, animated: true)
    }

    func openConfirmVC(title:String, message:String, mainButtonTitle:String, cancelButtonTitle:String) {

        let storyboard = UIStoryboard(name: "AlertSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ConfirmVC") as! ConfirmVC
        vc.message_title = title
        vc.message_body = message
        vc.mainButtonTitle = mainButtonTitle
        vc.cancelButtonTitle = cancelButtonTitle
        vc.delegate = self
      //  vc.referer = self.pageUrl
      //  vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)

    }

    
    // プロダクトページへ遷移
    var lockGotoProductPageButton = false
    
    @IBAction func showProductPage(_ sender: IndexedButton) {
        
       // return
        
        if lockGotoProductPageButton { return }         //　2度押し防止
        lockGotoProductPageButton = true
        
        let section = sender.indexPath?.section ?? 0
        let row = sender.indexPath?.row ?? 0
        if let cartSection = cartList?.cartSections[section] {
            let cartItem = cartSection.cartItems[row - 3]

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

                        if let itemp = cartItem.itemParent {
                            let supplier = Supplier(supplierId: cartSection.supplier?.id ?? "")          // これを先に指定しておく必要がある
                            _ = supplier?.getNextSupplierItemParents()
                            vc.supplier = supplier
                            vc.itemParent = itemp
                            _ = itemp.getItemParent()
                            vc.selectedItem = itemp.item
                            vc.connectionStatus = supplier!.connectionStatus
                            
                            self.orosyNavigationController?.pushViewController(vc, animated: true)
                            
                            if let act = sender.activityIndicator  {
                                act.stopAnimating()
                            }
                        }
                    }
           
                self.lockGotoProductPageButton = false
            }
        }

    }
    
    // サプライヤページへ遷移
    var lockGotoSupplierPageButton = false
    @IBAction func showSupplierPage(_ sender: IndexedButton) {

        if lockGotoSupplierPageButton { return }         //　2度押し防止
        lockGotoSupplierPageButton = true

        let section = sender.indexPath?.section ?? 0
        let cartSection = cartList?.cartSections[section]
        if let supplier = cartSection?.supplier {
           
            if let act = sender.activityIndicator {
                DispatchQueue.main.async{
                    act.startAnimating()
                }
            }
            
            DispatchQueue.global().async{
                
                var supplierHasData:Supplier!
                /*
                if supplier == nil {
                    supplierHasData = Supplier(supplierId: supplierId, size:self.ITEMPARENT_BATCH_SIZE)    // 商品一覧を取得。  新着情報の場合はSupplierオブジェクトではないので・・
                    if supplierHasData == nil {
                        LogUtil.shared.log("get supplier failed")
                        self.lockGotoSupplierPageButton = false
                        return      // データを取得できない
                    }else{
                        OrosyAPI.cacheImage(supplierHasData.coverImageUrl, imagesize: .Size400)
                        OrosyAPI.cacheImage(supplierHasData.iconImageUrl, imagesize: .Size100)
                    }

                }else{
                 */
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
                        
                        if let act = sender.activityIndicator  {
                            act.stopAnimating()
                        }
                    }
                }
                self.lockGotoSupplierPageButton = false
            }
        }
        
    }
}
