//
//  PaymentVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/06/30.
//

import UIKit
import SafariServices

class PaymentInfoVC: CommonEditVC, UITableViewDataSource, UITableViewDelegate, UIPopoverPresentationControllerDelegate {

    var creditHistory:[CreditData] = []
    var profileDetailBank:ProfileDetailBank!
    var bankInfo:Bank?
    var stripeCard:StripeCard?
    var npbuyer:NpBuyer!
    var showPointHistoryMode = false
    var pointHistoryIndex:IndexPath?

    var refundIndex:IndexPath?
    
    var cardRegisterd = false
    var cardError = false
    var kakeError = false
    var pay90daysLink:NSMutableAttributedString?

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
  
    enum SECTION_BLOCK:Int {
        case AVAILABLE = 0
      //  case POINT = 1
        case REFUND = 1
    }
    
    let BankAccountTypes:[[String:String]] = [ ["type":"ordinary", "type-j":"普通"], ["type":"saving", "type-j":"当座"]]
    

    


    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNaviTitle(title: "支払・払戻情報")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"blank"), style:.plain, target: self, action: nil)    // タイトルがセンターになるようにダミーのボタンを配置
        
        creditHistory = CreditHistory().getData()       
        getPaymentInfo()
        
        let itemDic1:[String:Any] =
            ["SECTION":SECTION_BLOCK.AVAILABLE,
             "DATA":
                [
                    DisplayItem(type: ItemType.HEADER, title: "ご利用可能枠", cell:"HEADER_CELL", height:44),
                    DisplayItem(type: ItemType.METHOD_TITLE, title: "90日支払い", cell:"NORMAL_CELL", placeholder:"", height:44),
                    DisplayItem(type: ItemType.METHOD_TITLE, title: "翌月末支払い", cell:"NORMAL_CELL", placeholder:"", height:44),

                ]
            ]

        itemList.append(itemDic1)
        
        let itemDic2:[String:Any] =
            ["SECTION":SECTION_BLOCK.REFUND,
             "DATA":
                [
                    DisplayItem(type: ItemType.HEADER, title: "払い戻し先情報", cell:"HEADER_CELL", height:44),
                   // DisplayItem(type: ItemType.METHOD_TITLE, title: "", cell:"REFUND_BANK_CELL", placeholder:"", height:44),
                    DisplayItem(type: ItemType.BANK_NAME, title: "銀行名", cell:"REFUND_NORMAL_CELL", placeholder:"Ex.オロシー銀行", validationType:.NormalString, inputStr:bankInfo?.bankName  , errorMsg:"入力してください"),
                    DisplayItem(type: ItemType.BANK_CODE, title: "銀行コード", cell:"REFUND_NORMAL_CELL", placeholder:"Ex.1234", validationType:.IntNumber, inputStr:bankInfo?.bankCode  , errorMsg:"入力してください"),
                    DisplayItem(type: ItemType.BRANCH_NAME, title: "支店名", cell:"REFUND_NORMAL_CELL", placeholder:"Ex.東京支店", validationType:.NormalString, inputStr:bankInfo?.branchName  , errorMsg:"入力してください"),
                    DisplayItem(type: ItemType.BRANCH_CODE, title: "支店コード", cell:"REFUND_NORMAL_CELL", placeholder:"Ex.1234", validationType:.IntNumber, inputStr:bankInfo?.branchNumber  , errorMsg:"入力してください"),
                    DisplayItem(type: ItemType.ACCOUNT_TYPE, title: "口座種別", cell:"REFUND_LIST_BOX_CELL", placeholder:"", validationType:.NormalString, inputStr:bankInfo?.accountType  , errorMsg:"入力してください"),
                    DisplayItem(type: ItemType.ACCOUNT_NUMBER, title: "口座番号", cell:"REFUND_NORMAL_CELL", placeholder:"Ex.1234567", validationType:.IntNumber, inputStr:bankInfo?.accountNumber  , errorMsg:"入力してください"),
                    DisplayItem(type: ItemType.ACCOUNT_NAME, title: "口座名義", cell:"REFUND_NORMAL_CELL", placeholder:"Ex.オロシー太郎", validationType:.NormalString, inputStr:bankInfo?.accountHolder  , errorMsg:"入力してください"),
                    DisplayItem(type: .FOOTER, title: "ボタン", cell:"REFUND_FOOTER_CELL", placeholder:"" )
                ]
             ]
           
        itemList.append(itemDic2)
        
        
        let boldAttribute: [NSAttributedString.Key : Any] = [
            .font : UIFont(name: OrosyFont.Bold.rawValue, size: 14)!,
            .foregroundColor : UIColor.orosyColor(color: .Blue)
            ]
        let normalAttribute: [NSAttributedString.Key : Any] = [
            .font : UIFont(name: OrosyFont.Regular.rawValue, size: 14)!,
            .foregroundColor : UIColor.orosyColor(color: .Black600)
            ]

        let text1 = NSAttributedString(string: "ご購入から90日以内に、クレジットカードまたは銀行振込でお支払い頂けます。\n 詳しくは", attributes: normalAttribute)
        let link = NSAttributedString(string: "こちら", attributes: boldAttribute)
        let text2 = NSAttributedString(string: " を御覧ください。", attributes: normalAttribute)


        pay90daysLink = NSMutableAttributedString()
        pay90daysLink?.append(text1)
        pay90daysLink?.append(link)
        pay90daysLink?.append(text2)
        

    }

    func getPaymentInfo() {
        profileDetailBank = ProfileDetailBank()
        _ = profileDetailBank.getData()

        npbuyer = profileDetailBank.npBuyer
        bankInfo = profileDetailBank.profileDetail?.bank
        kakeError = (profileDetailBank.profileDetail?.npStatus == .approved) ? false : true
        stripeCard = profileDetailBank.stripeCard
        if let stripe = stripeCard {
            if stripe.last4 != nil {
                cardRegisterd = true
            }else{
                cardRegisterd = false
            }
        }
        
       
    }
    
    override func viewWillAppear(_ animated: Bool) {

        MainTableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {

        let count = itemList.count
 
        return count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return UITableView.automaticDimension //自動設定

    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        let display_data = itemList[section]["DATA"] as! [DisplayItem]
        let count = display_data.count
        
        return count
    }
    

    
    var serviceRetail:RealShopMainCategory = .RETAIL
    var barWidth:CGFloat = 0
    var selectedAcc:[String:String] = [:]
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let section = indexPath.section
        var cell:UITableViewCell!

        let row_data = getItemData(indexPath)
        row_data.indexPath = indexPath
    
        cell = tableView.dequeueReusableCell(withIdentifier: row_data.cellType!, for: indexPath)
        
        if row_data.itemType == .HEADER {
            if let titleLabel = cell.viewWithTag(1) as? UILabel {
                titleLabel.text = row_data.title
            }
            if let contentLabel = cell.viewWithTag(2) as? UILabel {
                if section == 0 {
                    contentLabel.text = NSLocalizedString("PaymentExplanation", comment: "")
                }else if section == 1 {
                    contentLabel.text = NSLocalizedString("RefundExplanation", comment: "")
                }
            }
        }

        let baseView = cell.viewWithTag(1000)
        baseView?.backgroundColor = .white
        
        
        switch SECTION_BLOCK(rawValue:section) {
        case .AVAILABLE:
            
            switch row_data.itemType {

            case .METHOD_TITLE:

                let titleView = cell.viewWithTag(100)
                
                let kakeErrorView = cell.viewWithTag(101)
                let subTitleView = cell.viewWithTag(102)
                let progressBarView = cell.viewWithTag(103)
                let addButtonView = cell.viewWithTag(104)
                let statusView = cell.viewWithTag(105)
                let cardErrorView = cell.viewWithTag(106)
                let separator = cell.viewWithTag(107) as? UIImageView
                let cardInfoView = cell.viewWithTag(108)
                let resetDateView = cell.viewWithTag(109)
                
                if let titleLabel = titleView?.viewWithTag(1) as? UILabel {
                    titleLabel.text = row_data.title
                }
                if let contentLabel = subTitleView?.viewWithTag(1) as? UILabel {
                    if row == 1 {
                        contentLabel.attributedText = pay90daysLink
                    }else{
                        contentLabel.text = NSLocalizedString("PayNexMonthEndExplanation", comment: "")
                    }
                }
                if let linkButton = subTitleView?.viewWithTag(2) as? UIButton {
                    linkButton.isUserInteractionEnabled = (row == 1) ? true : false
                }
                progressBarView?.isHidden = !cardRegisterd


                statusView?.isHidden = true
                cardInfoView?.isHidden = true
                cardErrorView?.isHidden = true
                addButtonView?.isHidden = true
                kakeErrorView?.isHidden = true
                cardInfoView?.isHidden = true
                separator?.isHidden = true
                resetDateView?.isHidden = true
                
                let viewWidth = UIScreen.main.bounds.width - 80 //　Constraintが反映されていないのか widthが実際と異なるので、画面幅から計算するようにした
                
                if row == 1 {
                    //　90日払い
                    if let last4 = stripeCard?.last4 {
                        cardRegisterd = true
                        if let label = cardInfoView?.viewWithTag(2) as? OrosyLabel14 {
                            label.text = "**** **** **** \(last4)"
                        }
                    }else{
                        cardRegisterd = false
                        if let addButton = addButtonView?.viewWithTag(1) as? OrosyButtonWhite {
                            addButton.setButtonTitle(title: "クレジットカードを登録", fontSize: 12)
                            addButton.isSelected = true
                        }
                    }

                    baseView?.backgroundColor = (!cardRegisterd) ? UIColor.orosyColor(color: .S100) : .white

                    cardErrorView?.isHidden = !cardError
                    addButtonView?.isHidden = cardRegisterd
                    separator?.isHidden = !cardRegisterd
                    cardInfoView?.isHidden = !cardRegisterd

                    let error = cardErrorView?.viewWithTag(1) as! OrosyLabel10
                    error.text = NSLocalizedString("CardError", comment: "")

                    if let label = cardInfoView?.viewWithTag(3) as? OrosyLabel12 {
                        label.text = NSLocalizedString("CardApply", comment: "")
                    }
                   
                    var cardRestValue:Decimal = .zero
                    var cardLimitValue:Decimal = .zero
                    
                    if let stc = stripeCard {
                        cardLimitValue = stc.expectedMaxAmount ?? .zero
                        cardRestValue = cardLimitValue - (stc.unpaidAmount ?? .zero)
                        
                        if cardRestValue < 0 || cardLimitValue == 0 {
                            cardRestValue = 0
                            cardLimitValue = 0
                        }
                    }
                   // cardRestValue = 100
                   // cardLimitValue = 100
                    //cardRegisterd = true
                    // バー

                    if let barView = baseView?.viewWithTag(103) {

                        barView.isHidden = !cardRegisterd
                        let barBaseView = barView.viewWithTag(1) as! UIImageView
                        var frame = barBaseView.frame   //　Constraintが反映されていないのか widthが実際と異なるので、画面幅から計算するようにした

                        if cardLimitValue > 0 {
                            let barImageView = barView.viewWithTag(3) as! UIImageView
                            frame.size.width = viewWidth * Double(truncating:cardRestValue as NSNumber) / Double(truncating:cardLimitValue as NSNumber)
                            barImageView.frame = frame
                        }
                    }
                    
                    if let statusView = baseView?.viewWithTag(105) {
                        statusView.isHidden = !cardRegisterd
 
                            if let restValue = statusView.viewWithTag(1) as? UILabel {
                                restValue.text = Util.decimal2Str(cardRestValue)
                            }
                            if let limitValue = statusView.viewWithTag(2) as? UILabel {
                                limitValue.text = Util.decimal2Str(cardLimitValue)
                            }
                    }
                    
                }else if row == 2 {
                    // 翌月末はらい
                    kakeErrorView?.isHidden = !kakeError
                    statusView?.isHidden = false
                    resetDateView?.isHidden = false
                    
                    var npRestValue:Decimal = .zero
                    var npLimitValue:Decimal = .zero
                    
                    if let np = npbuyer {
                        npRestValue = np.amountLimit - np.usedAmount
                        npLimitValue = np.amountLimit
                        
                        if npRestValue < 0 || npLimitValue == 0 {
                            npRestValue = 0
                            npLimitValue = 100
                        }
                    }
                   // npRestValue = 50
                   // npLimitValue = 100
                    if let kakeErrorLabel = kakeErrorView?.viewWithTag(1) as? OrosyLabel14 {
                        kakeErrorLabel.text = NSLocalizedString("KakeError", comment: "")
                    }
                    if let kakeErrorExplaneationLabel = kakeErrorView?.viewWithTag(2) as? OrosyLabel10 {
                        kakeErrorExplaneationLabel.text = NSLocalizedString("KakeErrorExplaination", comment: "")
                    }

                    // バー
                    if let barView = baseView?.viewWithTag(103) {

                        barView.isHidden = false
                        let barBaseView = barView.viewWithTag(1) as! UIImageView

                        var frame = barBaseView.frame   //　Constraintが反映されていないのか widthが実際と異なるので、画面幅から計算するようにした
                        let barImageView = barView.viewWithTag(3) as! UIImageView
                        if npLimitValue > 0 {
                            frame.size.width = viewWidth * Double(truncating:npRestValue as NSNumber) / Double(truncating:npLimitValue as NSNumber)
                        }else{
                            frame.size.width = 0
                        }
                        barImageView.frame = frame
 
                    }
                    
                    if let statusView = baseView?.viewWithTag(105) {
                        if npbuyer != nil {
                            if let restValue = statusView.viewWithTag(1) as? UILabel {
                                restValue.text = Util.decimal2Str(npRestValue)
                            }
                            if let limitValue = statusView.viewWithTag(2) as? UILabel {
                                limitValue.text = Util.decimal2Str(npLimitValue)
                            }
                        }
                    }
                    
                    //リセット日
                    if let resetView = baseView?.viewWithTag(109) {
                        if let resetDate = resetView.viewWithTag(3) as? UILabel {
                            //　次の1日を求める
                            let calendar = Calendar(identifier: .gregorian)
                            let today = Date()
                            var year = calendar.component(.year, from: today)
                            var month = calendar.component(.month, from: today)
                            var day = calendar.component(.day, from: today)
                            if day > 1 {
                                month += 1; if month > 12 { month = 1; year += 1;}
                            }
                            day = 1
                            resetDate.text = "リセット日　\(year)/\(month)/\(day)"
                        }
                    }
                }
  
            default:break
                
            }

        case .REFUND:
            
            // 払戻先登録
            refundIndex = indexPath

            let valueLabel = cell.viewWithTag(1) as? OrosyTextFieldLabel
            valueLabel?.text = ""
            
            if row_data.focus {
                selectedItem = row_data
                valueLabel?.textField?.becomeFirstResponder()
            }
            
            switch row_data.itemType {
            
            case .METHOD_TITLE:
                if let titleLabel = cell.viewWithTag(1) as? UILabel {
                    titleLabel.text = row_data.title
                }
          
            case .ACCOUNT_TYPE:

                let buttonWithLabel = cell.viewWithTag(10) as? OrosyMenuButtonWithLabel
                buttonWithLabel?.title = row_data.title ?? ""
                buttonWithLabel?.error = row_data.error
                let menuButton = buttonWithLabel?.button
                
                //メニュー項目をセット
                var actions = [UIMenuElement]()
                
                let accountType = row_data.inputStr

                
                for acc in BankAccountTypes {
                    if acc["type"] == accountType { selectedAcc = acc}
                    actions.append(UIAction(title: acc["type-j"] ?? "", image: nil, state: (acc["type"] == selectedAcc["type"] ?? "") ? .on : .off, handler: { (_) in
                        self.selectedAcc = acc
                        buttonWithLabel!.setButtonTitle(title:acc["type-j"] ?? "", fontSize:14)
                        row_data.inputStr = acc["type"] ?? ""
                        self.MainTableView!.reloadRows(at: [indexPath], with: .none)
                        
                        row_data.indexPath = indexPath
                        self.unfocusedOnCurrentCell()
                        self.selectedItem = row_data
                        self.moveToNextField()

                    }))
                }

                if actions.count > 0 {
                    // UIButtonにUIMenuを設定
                    menuButton!.menu = UIMenu(title:"" , options: .displayInline, children: actions)
                    // こちらを書かないと表示できない場合があるので注意
                    menuButton!.showsMenuAsPrimaryAction = true

                    // 初期状態のボタン表示
                    
                    buttonWithLabel!.setButtonTitle(title:selectedAcc["type-j"] ?? "口座種別を選択", fontSize:14)
                }
            case .FOOTER:
                activityIndicator = cell.viewWithTag(1) as? UIActivityIndicatorView
                
            default:
                valueLabel?.indexPath = indexPath
                valueLabel?.title = row_data.title ?? ""
                valueLabel?.text = row_data.inputStr ?? ""
                valueLabel?.textField?.placeholder = row_data.placeholder
                valueLabel?.error = row_data.error
                valueLabel?.errorText = row_data.errorMsg ?? ""
                valueLabel?.helpButtonEnable = row_data.helpButtonEnable

                let validationType = row_data.validationType!
                
                if validationType == .PhoneNumber || validationType == .IntNumber || validationType == .IntNumberAllowBlank {
                    valueLabel?.textField?.keyboardType = .numbersAndPunctuation
                }else{
                    valueLabel?.textField?.keyboardType = .default
                }

            }
        default:break
            
        }



        return cell
    }
    
    @IBAction func AddCreditCard(_ sender: Any) {
        
        // 先にプロフィールを入力済みでないとカード登録を受け付けない
        if cardRegisterd || UserDefaultsManager.shared.accountStatus == .AccountProfiled {
            // クレジットカード登録画面へ遷移
            let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "EditCreditCardVC") as! EditCreditCardVC
            vc.stripeCard = stripeCard
            self.orosyNavigationController?.pushViewController(vc, animated: true)

        }else{
            // プロフィールの入力を促す
            self.showCheckProfileVC()
            
        }
    }

    
    @IBAction func show90DaysPaymentHelp() {
        
        if let url = URL(string:"https://help.orosy.com/hc/ja/articles/4408486253977") {
            let safariViewController = SFSafariViewController(url: url)
            safariViewController.delegate = self
            present(safariViewController, animated: false, completion: nil)
        }
    }

    /*
    @IBAction func showPointHistory(_ sender: Any) {
        showPointHistoryMode = true
        creditHistory = CreditHistory().getData()
        if let indexPath = pointHistoryIndex {
            MainTableView.reloadRows(at: [indexPath], with: .automatic)
            MainTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    */
    @IBAction func closePointHistory(_ sender: Any) {
        showPointHistoryMode = false
        if let indexPath = pointHistoryIndex {
            MainTableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    
    @IBAction func debugModeChanged(_ sender: Any) {
        let control = sender as! UISegmentedControl
        
        cardRegisterd = true
        cardError = false
        kakeError = false
        
        switch control.selectedSegmentIndex {
        case 0:cardRegisterd = false
        case 1:cardError = true;kakeError = true;
        default:
            break
        }
        
        MainTableView.reloadData()
        
    }
    // MARK: Popup View
   
    @IBAction func helpButton(_ button: IndexedButton) {
        
        let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PopoverVC") as! PopoverVC
        vc.mode = .STRING
        vc.text = NSLocalizedString("90DayPaymentHelp", comment: "")
        vc.modalPresentationStyle = .popover
        vc.preferredContentSize = vc.view.frame.size

        let presentationController = vc.popoverPresentationController
        presentationController?.delegate = self
        presentationController?.permittedArrowDirections = .any
        presentationController?.sourceView = button
        presentationController?.sourceRect = button.bounds

        present(vc, animated: true, completion: nil)
    }
    
    //　これがないとPopupにならない
   func adaptivePresentationStyle(for controller: UIPresentationController,
                                  traitCollection: UITraitCollection) -> UIModalPresentationStyle {
       return .none
   }
    
    
    // MARK: 払い戻し先の保存
    var initial:Bool = false
    var saving = false
    
    @IBAction func saveData() {
        if saving { return }
        saving = true
        
        if let indexPath = indexPathBeingEdited {
            if let cell = self.MainTableView!.cellForRow(at: indexPath) {
            
                if let lastTextField = cell.viewWithTag(2) as? OrosyTextField {
                    lastTextField.resignFirstResponder()
                }
                if let textView = cell.viewWithTag(5) as? OrosyTextViewLabel {
                    textView.resignFirstResponder()
                }
            }
        }
        
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
        }
        
        DispatchQueue.global().async {
            self.saveSub()
        }
    }
    
    func saveSub() {
        // 最後にカーソルがセットされているフィールドからカーソルを外すことで、そのフィールドを編集モードから抜けさせる

        initial = false
        
        var error = false
        
        var success = true
        if bankInfo == nil {
            bankInfo = Bank()
        }
        
        for section in 0..<itemList.count {
            let display_data = itemList[section]["DATA"] as! [DisplayItem]

            for row in 0..<display_data.count {
       
                let row_data = display_data[row]
                let itemType = row_data.itemType

                let _normalizedStr = row_data.inputStr
                let normalizedStr = _normalizedStr ?? ""
                
                switch itemType {

                case .BANK_NAME: bankInfo?.bankName = normalizedStr
                case .BANK_CODE: bankInfo?.bankCode = normalizedStr
                case .BRANCH_NAME: bankInfo?.branchName = normalizedStr
                case .BRANCH_CODE: bankInfo?.branchNumber = normalizedStr
                case .ACCOUNT_TYPE: bankInfo?.accountType = normalizedStr
                case .ACCOUNT_NUMBER: bankInfo?.accountNumber = normalizedStr
                case .ACCOUNT_NAME: bankInfo?.accountHolder = normalizedStr
                default:
                    success = true
                    break
                }
                
                row_data.error = !success
                
                if !success {
                    error = true    // どれか一つでもエラーになったらエラーダイアログを表示する
                }
            }
        }

        if error {
            // エラーが解消されていない

            DispatchQueue.main.async {
                let dialog =  SmoothDialog()
                self.view.addSubview(dialog)
                dialog.show(message: NSLocalizedString("CheckInputData", comment: ""))
                self.MainTableView!.reloadData()
                self.saving = false
                self.activityIndicator.stopAnimating()
            }
            return
        }
        
        //　保存


        let result =  bankInfo?.update()
        
        switch result {
        case .success(_):
            let title = "登録を完了しました。"
            let message = ""
            saving = false
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.confirmAlert(title: title, message: message)
            }
        case .failure(_):
            let title = "登録できませんでした。"
            let message = "入力したデータを見直してください"
            saving = false
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.confirmAlert(title: title, message: message)
            }
        default:
            break
        }
    }
    

}
