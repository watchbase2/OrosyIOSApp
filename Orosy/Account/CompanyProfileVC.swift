//
//  CompanyProfileVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/06/17.
//


import UIKit
import Amplify

protocol ProfileRequestDelegate:AnyObject {
    func updateStatus()
}

class CompanyProfileVC: CommonEditVC, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, ConfirmControllerDelegate {

    var delegate:ProfileRequestDelegate?
 
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var profileDetail:ProfileDetail!
    var retailerDetail:RetailerDetail!
    var prefectures:[Prefecture]!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"blank"), style:.plain, target: self, action: nil)    // タイトルがセンターになるようにダミーのボタンを配置

        
        profileDetail = ProfileDetail.shared
        profileDetail.getData()

        self.setNaviTitle(title: (profileDetail.businessFormat == .parsonal) ? "事業者情報" : "会社情報")
        
        prefectures = Address.getAllPrefecture()
        selectedPref = profileDetail.address?.prefecture
        
        itemList =
            [
                [
                "TITLE" : "",
                "DATA" :
                    [
                        DisplayItem(type: .COMPANY_NAME, title: "会社名|屋号", cell:"NORMAL_CELL", placeholder:"Ex.オロシー", inputStr:profileDetail?.companyName ?? "", errorMsg:"入力してください", focus:true ),
                        DisplayItem(type: .POLSTAL_CODE, title: "郵便番号（ハイフン無し）",  cell:"NORMAL_CELL",placeholder:"Ex.12345678", validationType:.PostalCode, inputStr:profileDetail?.address?.postalCode ?? "", errorMsg:"入力してください" ),
                        DisplayItem(type: .PREFECTURE, title: "都道府県", cell:"LIST_BOX_CELL", placeholder:"", errorMsg:"選択してください" ),
                        DisplayItem(type: .CITY, title: "市区郡", cell:"NORMAL_CELL", placeholder:"Ex.千代田区",inputStr:profileDetail?.address?.city ?? "", errorMsg:"入力してください" ),
                        DisplayItem(type: .TOWN, title: "町名番地", cell:"NORMAL_CELL", placeholder:"Ex.九段北4丁目1-28", inputStr:profileDetail?.address?.town ?? "", errorMsg:"入力してください" ),
                        DisplayItem(type: .FIRMNAME, title: "ビル・建物名（任意）", cell:"NORMAL_CELL", placeholder:"オロシービル4F",inputStr:profileDetail?.address?.apartment ?? "", errorMsg:"入力してください" ),

                        DisplayItem(type: .COMPANY_TEL, title: "会社代表電話番号（ハイフン無し）", cell:"NORMAL_CELL", placeholder:"Ex. 09012345678", validationType:.PhoneNumber, inputStr:profileDetail?.telRepresentative ?? "",  errorMsg:"数字で入力してください" ),

                    ]
                ],
                [
                "TITLE" : "",
                "DATA" :
                    [
                        DisplayItem(type: .SECTION_HEADER, title: "担当者情報", cell:"SECTION_HEADER_CELL",inputStr:"", errorMsg:"入力してください"),
                        DisplayItem(type: .LAST_NAME, title: "担当者（姓）", cell:"NORMAL_CELL", placeholder:"山田",inputStr:profileDetail?.accountLastName ?? "", errorMsg:"入力してください"),
                        DisplayItem(type: .FIRST_NAME, title: "担当者（名）", cell:"NORMAL_CELL", placeholder:"太郎",inputStr:profileDetail?.accountFirstName ?? "", errorMsg:"入力してください" ),
                        DisplayItem(type: .TEL, title: "担当者電話番号（ハイフン無し）", cell:"NORMAL_CELL", placeholder:"Ex.宅配ボックス", validationType:.PhoneNumber, inputStr:profileDetail?.tel ?? "", errorMsg:"数字で入力してください" )
                    ]
                ],
                [
                "TITLE" : "",
                "DATA" :
                    [
                        DisplayItem(type: .FOOTER, title: "ボタン", cell:"FOOTER_CELL", placeholder:"" )
                    ]
                ]
            ]
        
        MainTableView.reloadData()



    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return itemList.count
    }
    
    /*
    let HeaderHight:CGFloat = 80
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var view:UIView!
        
        if section == 1 {
            view = UIView(frame: CGRect(x:0, y:0, width:tableView.bounds.width, height:HeaderHight))
            view.backgroundColor = .clear
            let label = OrosyLabel16(frame: CGRect(x:20, y:10, width:tableView.bounds.width, height:HeaderHight))
            label.textColor = UIColor.orosyColor(color: .S400)
            view.addSubview(label)
            label.text = itemList[section]["TITLE"] as? String ?? ""
            let sublabel = OrosyLabel14(frame: CGRect(x:20, y:30, width:tableView.bounds.width, height:HeaderHight))
            sublabel.textColor = UIColor.orosyColor(color: .Black600)
            view.addSubview(sublabel)
            sublabel.text = "orosyからご連絡させて頂く際に利用します。"

        }
        
        return view
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 1) ? HeaderHight : 0
    }
*/
    
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
        
        let valueLabel = cell.viewWithTag(1) as? OrosyTextFieldLabel
 
        let textField = cell.viewWithTag(2) as? OrosyTextField
        textField?.text = ""
        
        let unitLabel = cell.viewWithTag(3) as? OrosyLabel14
        unitLabel?.text = ""
        
        if row_data.cellType == "NORMAL_CELL" {
            valueLabel?.indexPath = indexPath
            valueLabel?.title = row_data.title ?? ""
            valueLabel?.textField?.placeholder = row_data.placeholder
            valueLabel?.error = row_data.error
            valueLabel?.errorText = row_data.errorMsg ?? ""
            valueLabel!.helpButtonEnable = row_data.helpButtonEnable
            var frame = valueLabel!.frame
            frame.size.width = self.view.bounds.width - 40
            valueLabel!.frame = frame

            let validationType = row_data.validationType!
            
            if validationType == .PhoneNumber || validationType == .IntNumber || validationType == .IntNumberAllowBlank {
                valueLabel?.textField?.keyboardType = .numbersAndPunctuation
            }else{
                valueLabel?.textField?.keyboardType = .default
            }
            /*
            if row_data.focus {
                selectedItem = row_data
                valueLabel?.textField.becomeFirstResponder()
            }
             */
        }
        
        let itemType = row_data.itemType
        switch itemType {

        case .SECTION_HEADER:
            let label = cell.viewWithTag(2) as? OrosyLabel14
            label?.text = NSLocalizedString("NameSubTitle", comment: "")
            
        case .COMPANY_NAME:
            if let labels = row_data.title?.split(separator: "|") {
                valueLabel?.title = (profileDetail.businessFormat == .business) ? String(labels[0]) : String(labels[1])          //　法人と個人事業主で項目名が異なる
            }

        case .PREFECTURE:

            let buttonWithLabel = cell.viewWithTag(10) as? OrosyMenuButtonWithLabel
            buttonWithLabel?.title = row_data.title ?? ""
            buttonWithLabel?.error = row_data.error
            let menuButton = buttonWithLabel?.button
            
            //メニュー項目をセット
            var actions = [UIMenuElement]()
            
            for pref in prefectures {
                actions.append(UIAction(title: pref.name, image: nil, state: pref.id == (selectedPref?.id ?? "") ? .on : .off, handler: { (_) in
                    //menuButton.setTitle(pref.name, for: .normal)
                    buttonWithLabel!.setButtonTitle(title:pref.name, fontSize:16)
                    self.selectedPref = pref
                    self.MainTableView.reloadRows(at: [indexPath], with: .none)
                    row_data.indexPath = indexPath
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
                buttonWithLabel!.setButtonTitle(title:selectedPref?.name ?? "都道府県を選択", fontSize:16)
            }
        case .FOOTER:
            activityIndicator = cell.viewWithTag(1) as? UIActivityIndicatorView
        
            
        default:
            break
        }

        valueLabel?.text = row_data.inputStr ?? ""
        
        return cell
    }
    
    // 郵便番号処理
    var address_pref:OrosyMenuButton?
    var address_city:OrosyTextFieldLabel?
    var address_town:OrosyTextFieldLabel?
    
    override func orosyTextFieldDidChangeSelection(_ _orosyTextFieldLabel: OrosyTextFieldLabel) {
        
        super.orosyTextFieldDidChangeSelection(_orosyTextFieldLabel)
        
        if let indexPath = _orosyTextFieldLabel.indexPath {
            let row_data = getItemData(indexPath)
            
            let itemType = row_data.itemType
            switch itemType {
                
            case .PREFECTURE:
                break

            case .POLSTAL_CODE:
                let item_pref = searchItem(itemType: .PREFECTURE)
                let item_city = searchItem(itemType: .CITY)
                let item_town = searchItem(itemType: .TOWN)
                
             //   if item_city?.inputStr == "" && item_town?.inputStr == "" {
                    
                    let postCode = _orosyTextFieldLabel.text
                    if String(postCode.replacingOccurrences(of: "-", with: "")).count == 7 {
                        PostCode.getAddress(postCode: postCode) { complete in
                            if let addrDic = complete {
                                DispatchQueue.main.async {
                                    print(addrDic)
                                    item_pref?.inputStr = addrDic["address1"] ?? ""
                                    item_city?.inputStr = addrDic["address2"] ?? ""
                                    item_town?.inputStr = addrDic["address3"] ?? ""
                                    
                                    var indexPaths:[IndexPath] = []
                                    if let indexPath = item_pref?.indexPath {
                                        indexPaths.append(indexPath)
                                        for pref in self.prefectures {
                                            if pref.name == item_pref?.inputStr {
                                                self.selectedPref = pref
                                            }
                                        }
                                    }
                                    if let indexPath = item_city?.indexPath {
                                        indexPaths.append(indexPath)
                                    }
                                    if let indexPath = item_town?.indexPath {
                                        indexPaths.append(indexPath)
                                    }
                                    self.MainTableView.reloadRows(at: indexPaths, with: .none)
                                }
                            }
                        }
                    }
              //  }
            default:
                break
            }
        }
    }

    
    func searchItem(itemType:ItemType) -> DisplayItem? {
        
        for section_data in itemList {
            
            for row_data in section_data["DATA"] as! [DisplayItem] {
                
                if row_data.itemType == itemType {
                    return row_data
                }
            }
        }
        return nil
        
    }
    
    // MARK: 保存
    var initial:Bool = false
    var saving = false
    
    @IBAction func saveDate() {
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

                case .COMPANY_NAME:
                    profileDetail?.companyName = normalizedStr
                case .POLSTAL_CODE:
                    // 郵便番号整形
                    var postalCode = normalizedStr
                    if !postalCode.contains("-") {
                        postalCode = postalCode.prefix(3) + "-" + postalCode.suffix(4)
                    }
                    profileDetail?.address?.postalCode = postalCode
                    
                case .PREFECTURE:
                    profileDetail?.address?.prefecture = selectedPref
                    success = (selectedPref == nil) ? false : true
                case .CITY:
                    profileDetail?.address?.city = normalizedStr
                case .TOWN:
                    profileDetail?.address?.town = normalizedStr
                case .FIRMNAME:
                    profileDetail?.address?.apartment = normalizedStr
                    success = true
                case .LAST_NAME:
                    profileDetail?.accountLastName = normalizedStr
                case .FIRST_NAME:
                    profileDetail?.accountFirstName = normalizedStr
                case .COMPANY_TEL:
                    profileDetail?.telRepresentative = normalizedStr.replacingOccurrences(of: "-", with: "")
                case .TEL:
                     profileDetail?.tel = normalizedStr.replacingOccurrences(of: "-", with: "")
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
        profileDetail.email = KeyChainManager.shared.load(id:.loginId) ?? ""
        
        var result_p:Result<[String:Any], Error>!
    
        result_p = profileDetail.npUpdate()
        
        switch result_p {
        case .success(_):

            if let dg = delegate {
                dg.updateStatus()
            }
            DispatchQueue.main.async {
                _ = self.orosyNavigationController?.popViewController(animated: true)
            }
        case .failure(let error as GraphQLResponseError<String>):
            switch error {
            case .error (let graphqlErrors):
                print(graphqlErrors)
                for errorData in graphqlErrors {
                    print(errorData.message)
                    let errorData: Data =  errorData.message.data(using: String.Encoding.utf8)!
                     
                    do {
                        // パースする
                        var title = "登録できませんでした。"
                        var message = "入力したデータを見直してください"
                        do {
                            let itemDic = try JSONSerialization.jsonObject(with: errorData) as! Dictionary<String, Any>
                            if let errorNote = itemDic["errornote"] as? [[String:Any]] {
                                
                                if let firstError = errorNote.first {
                                    title = firstError["field"] as? String ?? ""
                                    
                                    if (firstError["code"] as? String ?? "") == "E1999507" {
                                        message = "入力された郵便番号と住所が一致していません"
                                    }else{
                                        message = firstError["message"] as? String ?? ""
                                    }
                                }
                            }
                        }catch{
                            
                        }
                        DispatchQueue.main.async {
                            self.confirmAlert(title: title, message: message)
                        }
                    }
                    saving = false
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                    }
                    return

                }
                break

            default:
                break
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
