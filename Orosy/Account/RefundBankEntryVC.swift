//
//  RefundBankEntryVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/07/30.
//

import UIKit


class RefundBankEntryVC: CommonEditVC, UITableViewDataSource, UITableViewDelegate, ConfirmControllerDelegate {

    var profileDetailBank:ProfileDetailBank!
    var bankInfo:Bank?
    var npbuyer:NpBuyer!
    var selectedAcc:[String:String] = [:]
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let BankAccountTypes:[[String:String]] = [ ["type":"ordinary", "type-j":"普通"], ["type":"saving", "type-j":"当座"]]

    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setNaviTitle(title: "払戻情報登録")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"blank"), style:.plain, target: self, action: nil)    // タイトルがセンターになるようにダミーのボタンを配置
        

        
        
        let itemDic:[String:Any] =
        [
        "TITLE" : "",
        "DATA" :
            [
            DisplayItem(type: ItemType.BANK_NAME, title: "銀行名", cell:"NORMAL_CELL", placeholder:"Ex.オロシー銀行", validationType:.NormalString, inputStr:bankInfo?.bankName  , errorMsg:"入力してください"),
            DisplayItem(type: ItemType.BANK_CODE, title: "銀行コード", cell:"NORMAL_CELL", placeholder:"Ex.1234", validationType:.IntNumber, inputStr:bankInfo?.bankCode  , errorMsg:"入力してください"),
            DisplayItem(type: ItemType.BRANCH_NAME, title: "支店名", cell:"NORMAL_CELL", placeholder:"Ex.東京支店", validationType:.NormalString, inputStr:bankInfo?.branchName  , errorMsg:"入力してください"),
            DisplayItem(type: ItemType.BRANCH_CODE, title: "支店コード", cell:"NORMAL_CELL", placeholder:"Ex.1234", validationType:.IntNumber, inputStr:bankInfo?.branchNumber  , errorMsg:"入力してください"),
            DisplayItem(type: ItemType.ACCOUNT_TYPE, title: "口座種別", cell:"LIST_BOX_CELL", placeholder:"", validationType:.NormalString, inputStr:bankInfo?.accountType  , errorMsg:"入力してください"),
            DisplayItem(type: ItemType.ACCOUNT_NUMBER, title: "口座番号", cell:"NORMAL_CELL", placeholder:"Ex.1234567", validationType:.IntNumber, inputStr:bankInfo?.accountNumber  , errorMsg:"入力してください"),
            DisplayItem(type: ItemType.ACCOUNT_NAME, title: "口座名義", cell:"NORMAL_CELL", placeholder:"Ex.オロシー太郎", validationType:.NormalString, inputStr:bankInfo?.accountHolder  , errorMsg:"入力してください"),
            DisplayItem(type: .FOOTER, title: "ボタン", cell:"FOOTER_CELL", placeholder:"" )
            ]
        ]
        
        itemList.append(itemDic)
        profileDetailBank = ProfileDetailBank()
        _ = profileDetailBank.getData()

        npbuyer = profileDetailBank.npBuyer
        bankInfo = profileDetailBank.profileDetail?.bank
        
        MainTableView.reloadData()
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return UITableView.automaticDimension //自動設定

    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        let display_data = itemList[section]["DATA"] as! [DisplayItem]
        count = display_data.count
        
        return count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let section = indexPath.section
        var cell:UITableViewCell!
        
        let row_data = getItemData(indexPath)
        row_data.indexPath = indexPath
        
        cell = tableView.dequeueReusableCell(withIdentifier: row_data.cellType ?? "", for: indexPath)
        
        if let titleLabel = cell.viewWithTag(1) as? UILabel {
            titleLabel.text = row_data.title
        }
        
        let valueLabel = cell.viewWithTag(1) as? OrosyTextFieldLabel
        valueLabel?.text = ""
        
        if row_data.focus {
            selectedItem = row_data
            valueLabel?.textField?.becomeFirstResponder()
        }
        
        switch row_data.itemType {
            
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
            valueLabel!.helpButtonEnable = row_data.helpButtonEnable

            let validationType = row_data.validationType!
            
            if validationType == .PhoneNumber || validationType == .IntNumber || validationType == .IntNumberAllowBlank {
                valueLabel?.textField?.keyboardType = .numbersAndPunctuation
            }else{
                valueLabel?.textField?.keyboardType = .default
            }

        }

        return cell
        
    }

    // MARK: 保存
    var initial:Bool = false
    var saving = false
    
    @IBAction func saveData() {
        if saving { return }
        saving = true
        
        if let indexPath = indexPathBeingEdited {
            if let cell = self.MainTableView.cellForRow(at: indexPath) {
            
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
                self.MainTableView.reloadData()
                self.saving = false
                self.activityIndicator.stopAnimating()
            }
            return
        }
        
        //　保存


        let result =  bankInfo?.update()
        
        switch result {
        case .success(_):

            DispatchQueue.main.async {
                _ = self.orosyNavigationController?.popViewController(animated: true)
            }
        case .failure(_):
            let title = "登録できませんでした。"
            let message = "入力したデータを見直してください"
            saving = false
            DispatchQueue.main.async {
                self.confirmAlert(title: title, message: message)
            }
        default:
            break
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
       
}
