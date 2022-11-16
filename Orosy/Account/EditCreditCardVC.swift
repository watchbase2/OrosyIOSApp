//
//  EditCreditCard.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/07/02.
//

import UIKit
import Stripe

class EditCreditCardVC: CommonEditVC, UITableViewDataSource, UITableViewDelegate, ConfirmControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
 
    var stripeCard:StripeCard!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNaviTitle(title: "90日支払いの申込み")      // カードを変更して再審査
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"blank"), style:.plain, target: self, action: nil)    // タイトルがセンターになるようにダミーのボタンを配置

        /*
        var expire:String = ""
        
        if stripeCard.getData(){
            
            expire = (stripeCard == nil || stripeCard.expMonth == nil || stripeCard.expYear == nil) ? "" : String(stripeCard.expMonth) + "/" + String(stripeCard.expYear)
        }
        */
        
        let itemDic:[String:Any] =
        [
        "TITLE" : "",
        "DATA" :
            [
            DisplayItem(type: .HEADER, title: "", cell:"HEADER_CELL", placeholder:"" ),
            DisplayItem(type: .CARD_NUMBER, title: "カード番号", cell:"NORMAL_CELL", placeholder:"Ex.123412341234", validationType:.IntNumber, inputStr:"", errorMsg:"入力してください",focus: true),   //stripeCard?.last4 ?? ""
            DisplayItem(type: .EXPIRE_DATE, title: "MM/YY", cell:"NORMAL_CELL", placeholder:"Ex.1234", validationType:.ExpirationDate, inputStr: "", errorMsg:"入力してください"),            // expire
            DisplayItem(type: .SECURITY_CODE, title: "セキュリティコード", cell:"NORMAL_CELL", placeholder:"Ex.123", validationType:.IntNumber3, inputStr:"", errorMsg:"入力してください"),    //stripeCard?.cvc ??
            DisplayItem(type: .CARD_OWNER, title: "カード名義人", cell:"NORMAL_CELL", placeholder:"Ex. OTOSY TARO", validationType:.NormalString, inputStr:"", errorMsg:"入力してください"),                              // stripeCard?.owner ??
            DisplayItem(type: .LIMIT_AMOUNT, title: "", cell:"BUDGET_CELL", placeholder:" Ex.250000", validationType:.IntNumber, inputStr: "", errorMsg:""),   // Util.decimal2Str(stripeCard?.expectedMaxAmount,withUnit:false)
            DisplayItem(type: .FOOTER, title: "ボタン", cell:"FOOTER_CELL", placeholder:"" )
            ]
        ]
        
        itemList.append(itemDic)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    let HeaderHight:CGFloat = 80
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView(frame: CGRect(x:0, y:0, width:tableView.bounds.width, height:HeaderHight))
        view.backgroundColor = .clear
        let label = OrosyLabel16(frame: CGRect(x:20, y:10, width:tableView.bounds.width, height:HeaderHight))
        label.textColor = UIColor.orosyColor(color: .S400)
        view.addSubview(label)
      //  label.text = itemList[row]["TITLE"] as? String ?? ""
        let sublabel = OrosyLabel14(frame: CGRect(x:20, y:30, width:tableView.bounds.width, height:HeaderHight))
        sublabel.textColor = UIColor.orosyColor(color: .Black600)
        view.addSubview(sublabel)
        sublabel.text = "orosyからご連絡させて頂く際に利用します。"
        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 0) ? 0 : HeaderHight
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        let display_data = itemList[section]["DATA"] as! [DisplayItem]
        
        count = display_data.count
        
        return count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension //自動設定
    }
    
    var selectedPref:Prefecture?
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let row_data = getItemData(indexPath)
        row_data.indexPath = indexPath
        
        let cell = tableView.dequeueReusableCell(withIdentifier: row_data.cellType!, for: indexPath)
        if let titleLabel = cell.viewWithTag(1) as? UILabel {
            titleLabel.text = row_data.title
        }
        
        if row_data.itemType == .HEADER {
            if let contentLabel = cell.viewWithTag(2) as? UILabel {
                contentLabel.text = "ご利用頂ける利用可能枠を、\nクレジットカードなどを元に審査致します。"
                contentLabel.textAlignment = .center
            }
            // "ご不明点があれば050-1751-6172にお電話ください。\n担当者が折り返しサポートいたします。";
            if let telLabel = cell.viewWithTag(3) as? UILabel {
                telLabel.textAlignment = .center

                let combination = NSMutableAttributedString()
                
                let textAttributes1: [NSAttributedString.Key : Any] = [
                      .font : UIFont(name: OrosyFont.Regular.rawValue, size: 14)!,
                      .foregroundColor : UIColor.orosyColor(color: .Black600)
                      ]
                let part1 = NSAttributedString(string: "ご不明点があれば", attributes: textAttributes1 )
                combination.append(part1)
                //
                let textAttributes2: [NSAttributedString.Key : Any] = [
                      .font : UIFont(name: OrosyFont.Regular.rawValue, size: 14)!,
                      .foregroundColor : UIColor.orosyColor(color: .Blue)
                      ]
                let part2 = NSAttributedString(string:"050-1751-6172", attributes: textAttributes2 )
                combination.append(part2)
                //
                let textAttributes3: [NSAttributedString.Key : Any] = [
                      .font : UIFont(name: OrosyFont.Regular.rawValue, size: 14)!,
                      .foregroundColor : UIColor.orosyColor(color: .Black600)
                      ]
                let part3 = NSAttributedString(string: "にお電話ください。\n担当者が折り返しサポートいたします。", attributes: textAttributes3 )
                combination.append(part3)
                
                telLabel.attributedText = combination
                
            }
            
            return cell
        }
        
        let valueLabel = cell.viewWithTag(1) as? OrosyTextFieldLabel
        valueLabel?.text = ""
        valueLabel?.indexPath = indexPath
        valueLabel?.title = row_data.title ?? ""
        valueLabel?.text = row_data.inputStr ?? ""
        valueLabel?.textField?.placeholder = row_data.placeholder
        valueLabel?.error = row_data.error
        valueLabel?.errorText = row_data.errorMsg ?? ""
        valueLabel?.helpButtonEnable = row_data.helpButtonEnable
        
        if row_data.cellType == "NORMAL_CELL" {
            
            let textField = cell.viewWithTag(2) as? OrosyTextField
            textField?.text = ""
            
            let unitLabel = cell.viewWithTag(3) as? OrosyLabel14
            unitLabel?.text = ""
            
            let validationType = row_data.validationType!
            
            if validationType == .PhoneNumber || validationType == .IntNumber || validationType == .IntNumberAllowBlank {
                valueLabel?.textField?.keyboardType = .numbersAndPunctuation
            }else{
                valueLabel?.textField?.keyboardType = .default
            }
            if row_data.focus {
                selectedItem = row_data
                valueLabel?.textField?.becomeFirstResponder()
            }
        }
        
        if row_data.cellType == "BUDGET_CELL" {
            let titleLabel = cell.viewWithTag(3) as? OrosyLabel14
            titleLabel?.text = "現在のご利用可能残高をご入力ください"
            
            let noteLabel = cell.viewWithTag(2) as? OrosyLabel14
            noteLabel?.text = "例：上限30万円のカードで、今月すでに5万円利用している場合、ご利用可能残高は25万円です。"

            valueLabel?.textField?.keyboardType = .default
            
            if row_data.focus {
                selectedItem = row_data
                valueLabel?.textField?.becomeFirstResponder()
            }
        }
        

        
        let itemType = row_data.itemType
        switch itemType {

        case .FOOTER:
            activityIndicator = cell.viewWithTag(1) as? UIActivityIndicatorView
        default:
            break
        }

        
        return cell
    }

    /*
    override func orosyTextFieldDidChangeSelection(_ _orosyTextFieldLabel: OrosyTextFieldLabel) {
               
        if let indexPath = _orosyTextFieldLabel.indexPath {
           let row_data = getItemData(indexPath)
            
            if row_data.itemType == .EXPIRE_DATE {
                let text = _orosyTextFieldLabel.text
                if text.count == 2 { _orosyTextFieldLabel.text = text + "/" }
                if text.count > 2 && !text.contains("/") {
                    _orosyTextFieldLabel.text = text.prefix(2) + "/" + text.suffix( text.count - 2)
                }
            }
        }
        
        super.orosyTextFieldDidChangeSelection(_orosyTextFieldLabel)
            
    }
    */
    // MARK: 保存
    var initial:Bool = false
    var saving = false
    
    @IBAction func saveData() {
        if saving { return }
        saving = true
        
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
        }
        
        DispatchQueue.global().async {
            self.saveSub()
        }
    }
    
    func saveSub() {
        // 最後にカーソルがセットされているフィールドからカーソルを外すことで、そのフィールドを編集モードから抜けさせる
        if let indexPath = indexPathBeingEdited {
            DispatchQueue.main.async {
                if let cell = self.MainTableView.cellForRow(at: indexPath) {
                
                    if let lastTextField = cell.viewWithTag(2) as? OrosyTextField {
                        lastTextField.resignFirstResponder()
                    }
                    if let textView = cell.viewWithTag(5) as? OrosyTextViewLabel {
                        textView.resignFirstResponder()
                    }
                }
            }
        }
        
        initial = false
        
        var error = false
        
        var success = true

        for section in 0..<itemList.count {
            let display_data = itemList[section]["DATA"] as! [DisplayItem]

            for row in 0..<display_data.count {
       
                let row_data = display_data[row]
                let itemType = row_data.itemType

                var _normalizedStr = row_data.inputStr
                
                (success, _normalizedStr) = Validation.normalize(type: row_data.validationType, inStr:row_data.inputStr )

                let normalizedStr = _normalizedStr ?? ""

                switch itemType {
                case .CARD_NUMBER:
                    stripeCard?.cardNumber = normalizedStr
                case .EXPIRE_DATE:
                    //let text = normalizedStr.replacingOccurrences(of: " / ", with: "")
                    stripeCard?.expMonth = Int(String(normalizedStr.prefix(2))) ?? 0
                    stripeCard?.expYear = Int(String(normalizedStr.suffix(2))) ?? 0

                case .CARD_OWNER:
                    stripeCard?.owner = normalizedStr
                    break
                case .SECURITY_CODE:
                    stripeCard?.cvc = normalizedStr
                case .LIMIT_AMOUNT:
                    stripeCard?.expectedMaxAmount = Decimal( string:normalizedStr)
                    break

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
                self.MainTableView.reloadData()
                self.saving = false
                self.activityIndicator.stopAnimating()
            }
            return
        }
        
        //　保存
        //stripeCard.expectedMaxAmount = 100000
            
        if stripeCard.validateCard()  {
            print ("validate success")
            
            stripeCard.setupIntent( completion: { result in
                if result {
                    print ("setup intent success")
                    
                    self.saving = false
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        _ = self.orosyNavigationController?.popViewController(animated: true)
                    }

                    return
                    
                }else{
                    var messageKey = ""
                    
                    switch self.stripeCard.autholizedError {
                    case .debit_is_rejected:
                        messageKey = "CardDebitError"
                    case .other:
                        messageKey = "CardOtherError"
                    case .unexpected:
                        messageKey = "CardUnexpectedError"
                    default:
                        messageKey = "CardUnexpectedError"
                    }
                    
                    DispatchQueue.main.async {
                        /*
                        let dialog =  SmoothDialog()
                        self.view.addSubview(dialog)
                        dialog.show(message: NSLocalizedString(messageKey, comment: ""))
                         */
                        self.confirmAlert(title: "", message: NSLocalizedString(messageKey, comment: ""), ok: "確認") { completion in
                        }
                    }
                    
                    return
                }
            })
            
        }else{
            DispatchQueue.main.async {
                let dialog =  SmoothDialog()
                self.view.addSubview(dialog)
                dialog.show(message: NSLocalizedString("CardValidationError", comment: ""))
            }
            
        }
        
        saving = false
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }
    
  
    @objc override func closeView() {
        
        if toBeSaved {
            openConfirmVC(title:NSLocalizedString("NotSaved", comment: ""), message: NSLocalizedString("ConfirmNotSaveReturn", comment: ""), mainButtonTitle:"キャンセル", cancelButtonTitle:"閉じる")
        }else{
            _ = self.orosyNavigationController?.popViewController(animated: true)
        }
    }
    
    func openConfirmVC(title:String, message:String, mainButtonTitle:String, cancelButtonTitle:String) {

        let storyboard = UIStoryboard(name: "AlertSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ConfirmVC") as! ConfirmVC
        vc.message_title = title
        vc.message_body = message
        vc.mainButtonTitle = mainButtonTitle
        vc.cancelButtonTitle = cancelButtonTitle
        vc.delegate = self

        self.present(vc, animated: true, completion: nil)
    }
    
    func selectedAction(sel: Bool) {
        self.dismiss(animated: true)
        
        if !sel {
            _ = self.orosyNavigationController?.popViewController(animated: true)
        }
    }
    @IBAction func phoneCall(_ sender: Any) {
        let url: NSURL = URL(string: "TEL://05017516172")! as NSURL
        UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
    }
}
