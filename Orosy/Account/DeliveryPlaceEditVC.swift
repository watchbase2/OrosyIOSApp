//
//  DeliveryPlaceEditVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/20.
//

import UIKit


protocol DeliveryPlaceListVCDelegate: AnyObject {
    func refresh()
}

class DeliveryTextField:OrosyTextField {
    var titleLabel:UILabel!
    
}

class DeliveryPlaceEditVC: CommonEditVC, UITableViewDataSource, UITableViewDelegate,ConfirmControllerDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var createMode = false
    var selectedPlace:DeliveryPlace!    // 納品先一覧で選択した納品先
    var newPlace:DeliveryPlace!         // 更新した納品先
    var initial = true                  // 都道府県が未選択でも、最初はエラー表示にしないためのフラグ。一度、保存ボタンを押すと false　になる
    var delegate:DeliveryPlaceListVCDelegate!
    var selectedPref:Prefecture? = nil


    var prefectures:[Prefecture]!
    
    func getItemidForPageUrl() -> String {
        return selectedPlace?.deliveryPlaceId ?? ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"blank"), style:.plain, target: self, action: nil)    // タイトルがセンターになるようにダミーのボタンを配置
 
        
        prefectures = Address.getAllPrefecture()
        
        if let place = selectedPlace {
            selectedPref = place.shippingAddress?.prefecture
            newPlace = place.copy()
            self.setNaviTitle(title: "納品先情報を登録")
        }else{
            //新規追加
            createMode = true
            newPlace = DeliveryPlace([:])
            selectedPlace = newPlace
            self.setNaviTitle(title:"納品先を新規作成")
            
        }
        
        let itemDic:[String:Any] =
        [
        "TITLE" : "",
        "DATA" :
            [
                DisplayItem(type: ItemType.DeliveryPlaeName, title: "納品先名称", cell:"NORMAL_CELL", placeholder:"Ex.オロシー", validationType:.NormalString, inputStr: newPlace.name ,errorMsg:"入力してください"),
                DisplayItem(type: ItemType.POLSTAL_CODE, title: "郵便番号",  cell:"NORMAL_CELL",placeholder:"Ex.12345678", validationType:.PostalCode, inputStr:newPlace.shippingAddress?.postalCode  ,errorMsg:"入力してください" ),
                DisplayItem(type: ItemType.PREFECTURE, title: "都道府県", cell:"LIST_BOX_CELL", placeholder:"", validationType:.NormalString, inputStr: newPlace.shippingAddress?.prefecture?.name ,errorMsg:"入力してください"),
                DisplayItem(type: ItemType.CITY, title: "市区郡", cell:"NORMAL_CELL", placeholder:"Ex.千代田区", validationType:.NormalString, inputStr:newPlace.shippingAddress?.city  ,errorMsg:"入力してください" ),
                DisplayItem(type: ItemType.TOWN, title: "町名番地", cell:"NORMAL_CELL", placeholder:"Ex.九段北4丁目1-28",  validationType:.NormalString, inputStr:newPlace.shippingAddress?.town  ,errorMsg:"入力してください" ),
                DisplayItem(type: ItemType.FIRMNAME, title: "ビル・建物名（任意）", cell:"NORMAL_CELL", placeholder:"オロシービル4F", validationType:.None, inputStr:newPlace.shippingAddress?.apartment  , errorMsg:"入力してください"),
                DisplayItem(type: ItemType.PersonName, title: "納品先の宛名", cell:"NORMAL_CELL", placeholder:"山田太郎", validationType:.NormalString, inputStr:newPlace.shippingAddressName  , errorMsg:"入力してください"),
                DisplayItem(type: ItemType.TEL, title: "納品先電話番号", cell:"NORMAL_CELL", placeholder:"09012345678", validationType:.PhoneNumber, inputStr:newPlace.tel  , errorMsg:"入力してください" ),
                DisplayItem(type: ItemType.Memo, title: "備考（任意）", cell:"TEXTVIEW_CELL", placeholder:"Ex.宅配ボックス", validationType:.None, inputStr:newPlace.shippingAddressEtc  , errorMsg:"入力してください"),
                DisplayItem(type: ItemType.FOOTER, title: "ボタン", cell:"FOOTER_CELL", placeholder:"", validationType:.None, inputStr: "" , errorMsg:"入力してください")
            ]
        ]
        
        itemList.append(itemDic)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MainTableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return itemList.count
    }
    
    let HeaderHight:CGFloat = 20
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x:0, y:0, width:tableView.bounds.width, height:HeaderHight))
        view.backgroundColor = .clear
        
        return view
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return HeaderHight
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x:0, y:0, width:tableView.bounds.width, height:HeaderHight))
        view.backgroundColor = .clear
        
        return view
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return HeaderHight
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        var count = 0
        if selectedPlace == nil { return 0 }
        
        let display_data = itemList[section]["DATA"] as! [DisplayItem]
        
        count = display_data.count
        
        return count

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        let row_data = getItemData(indexPath)
        let itemType = row_data.itemType
        
        if itemType == .Memo {
            return 108
        }else{
            return UITableView.automaticDimension //自動設定
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let row_data = getItemData(indexPath)
        row_data.indexPath = indexPath
        
        let itemType = row_data.itemType
        
        var cell:UITableViewCell!
        
        let cellType = row_data.cellType ?? ""
        cell = tableView.dequeueReusableCell(withIdentifier: cellType, for: indexPath)
        
        var content:OrosyTextFieldLabel!
        
        if row_data.cellType == "NORMAL_CELL" {
            content = cell.viewWithTag(1) as? OrosyTextFieldLabel
            content.text = ""
            selectedItem = row_data
     
                content.title = row_data.title ?? ""
                content.text = row_data.inputStr ?? ""
                content.textField?.placeholder = row_data.placeholder
                content.error = row_data.error
                content.indexPath = indexPath
                
                content.focus = row_data.focus
                if row_data.focus {
                    selectedItem = row_data
                    content?.textField?.becomeFirstResponder()
                }
        }

        switch itemType  {
        case .DeliveryPlaeName:
            break
        case .POLSTAL_CODE:
            break
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
                buttonWithLabel!.setButtonTitle(title:selectedPref?.name ?? "都道府県を選択", fontSize:16)
            }
        case .CITY:
            break
        case .TOWN:
            break
        case .FIRMNAME:
            break
        case .PersonName:
            break
        case .TEL:
            break
        case .Memo:
            let textView = cell.viewWithTag(1) as! OrosyTextViewLabel
            textView.text = row_data.inputStr ?? ""
            textView.indexPath = indexPath
            textView.title = row_data.title ?? ""
            textView.text =  row_data.inputStr ?? ""
            textView.errorText = row_data.errorMsg ?? ""
            textView.underlineColor = UIColor.orosyColor(color: .S400)
            
            if textView.text.count == 0 {
                textView.placeholder = row_data.placeholder ?? ""
            }else{
                textView.placeholder = ""
            }
            textView.error = row_data.error
        case .FOOTER:
            activityIndicator = cell.viewWithTag(1) as? UIActivityIndicatorView
        default:
            break
        }

        return cell
    }
    
    // 郵便番号処理
    var address_pref:OrosyMenuButton?
    var address_city:OrosyTextFieldLabel?
    var address_town:OrosyTextFieldLabel?
    
    override func orosyTextFieldDidChangeSelection(_ _orosyTextFieldLabel: OrosyTextFieldLabel) {
        
        super.orosyTextFieldDidChangeSelection( _orosyTextFieldLabel)
        
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

        let display_data = itemList[0]["DATA"] as! [DisplayItem]

        for row in 0..<(itemList[0]["DATA"] as! [DisplayItem]).count {
   
            let row_data = display_data[row]
            let itemType = row_data.itemType

            var success = true
            var _normalizedStr = row_data.inputStr
            
            (success, _normalizedStr) = Validation.normalize(type: row_data.validationType, inStr:row_data.inputStr )
            
            row_data.error = !success
            
            let normalizedStr = _normalizedStr ?? ""

            switch  itemType {

            case .DeliveryPlaeName:        // 実店舗の場合は　ブランド名、 ECサイトの場合はECサイト名
                newPlace.name = normalizedStr
            case .POLSTAL_CODE:    // ハイフンあり
  
                var err = false
                let text = normalizedStr.replacingOccurrences(of: "-", with: "")
                if text.count == 7 && text.isOnlyNumeric() {  // ハイフン無しで、7桁,数字のみ
                    newPlace.shippingAddress!.postalCode = normalizedStr
                }else{
                    err = true
                    error = true
                }

                row_data.error = err
                error = err
            case .PREFECTURE:
                newPlace.shippingAddress?.prefecture = selectedPref
                success = (selectedPref == nil) ? false : true
            case .CITY:
                newPlace.shippingAddress?.city = normalizedStr
            case .TOWN:
                newPlace.shippingAddress?.town = normalizedStr
            case .FIRMNAME:
                newPlace.shippingAddress?.apartment = normalizedStr
            case .PersonName:
                newPlace.shippingAddressName = normalizedStr
            case .TEL:  // ハイフンなし
                newPlace.tel = normalizedStr.replacingOccurrences(of: "-", with: "")
            case .Memo:
                newPlace.shippingAddressEtc = normalizedStr
                
            default:
                success = true
                break
            }

            if !success {
                error = true
            }    // どれか一つでもエラーになったらエラーダイアログを表示する

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
        var result:Result< Bool, Error>!
        if createMode {
            result = newPlace.createDeliveryPlace()
        }else{
            result = newPlace.updateDeliveryPlace()
        }
        
        switch result {
        case .success(_):
            DispatchQueue.main.async {
                if let dlg = self.delegate {
                    dlg.refresh()
                }
                _ = self.orosyNavigationController?.popViewController(animated: true)
            }
        case .failure(let error):
            DispatchQueue.main.async {
                print(error.localizedDescription)
                let dialog =  SmoothDialog()
                self.view.addSubview(dialog)
                dialog.show(message: NSLocalizedString("SaveFilure", comment: ""))
                
                let title = "登録できませんでした。"
                let message = "入力したデータを見直してください"
                

                self.confirmAlert(title: title, message: message)

                self.activityIndicator.stopAnimating()
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
