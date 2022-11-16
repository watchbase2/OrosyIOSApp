//
//  RetailerInfoVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/05/07.
//
// 登録する情報は　ProfileDetailと RetailerDetail の2種類の情報が混在している。


import UIKit


class RetailerInfoVC:CommonEditVC, UITableViewDelegate, UITableViewDataSource,  UITextViewDelegate {


    var initial = true                  // 最初はエラー表示にしないためのフラグ。一度、保存ボタンを押すと false　になる
    var retailerDetail:RetailerDetail!
    var profileDetail:ProfileDetail!

    let SaleTypes = ["実店舗を持っている","ECサイトのみ","販売形式を選択"]
    let businessFormat = ["法人","個人事業主","区分を選択"]
    

    let itemBasicDic:[String:Any] =
        [
            "TITLE" : "",
            "DATA" : [
                DisplayItem(type: ItemType.BUSINESS_FORMAT, title: "区分", cell:"LIST_BOX_CELL", placeholder:"", validationType:.NormalString, errorMsg:"選択してください", focus: true), //最初にフォーカスを置く行
                DisplayItem(type: ItemType.SALE_TYPE, title: "販売形式", cell:"LIST_BOX_CELL", placeholder:"", validationType:.NormalString, errorMsg:"選択してください"),
                DisplayItem(type: ItemType.LAST_NAME, title: "担当者（姓）",cell:"NORMAL_CELL", placeholder:"Ex.卸田", validationType:.NormalString, errorMsg:"入力してください"),
                DisplayItem(type: ItemType.FIRST_NAME, title: "担当者（名）",cell:"NORMAL_CELL", placeholder:"Ex.太郎", validationType:.NormalString, errorMsg:"入力してください"),
                DisplayItem(type: ItemType.TEL, title: "担当者電話番号（ハイフン無し）",cell:"NORMAL_CELL", placeholder:"Ex.09012345678", validationType:.PhoneNumber, errorMsg:"入力してください")
            ]
        ]
    
    
    let itemListForRealShop:[String:Any] =
 
        [
            "TITLE" : "店舗情報を入力してください",
            "DATA" : [
                DisplayItem(type: ItemType.BRAND_NAME, title: "店舗ブランド名",cell:"NORMAL_CELL", placeholder:"Ex.orosy", validationType:.NormalString, errorMsg:"入力してください"),
                DisplayItem(type: ItemType.WEBSITE, title: "店舗のwebsite",cell:"NORMAL_CELL", placeholder:"Ex.https://orosy.com", validationType:.URL, errorMsg:"入力してください"),
                DisplayItem(type: ItemType.NUMBER_OF_SHOPS, title: "展開店舗数",cell:"LIST_BOX_CELL", placeholder:"展開店舗数を選択", validationType:.None, errorMsg:"選択してください"),
                DisplayItem(type: ItemType.ANUAL_REVENUE, title: "年間売上（任意）",cell:"NORMAL_CELL", placeholder:"3000000", validationType:.None)

            ]
        ]
   
    let itemListForEC:[String:Any] =

        [
            "TITLE" : "ECサイト情報を入力してください",
            "DATA" : [
                DisplayItem(type: ItemType.ECSITE_NAME, title: "ECサイト名",cell:"NORMAL_CELL", placeholder:"Ex.orosy", validationType:.NormalString, errorMsg:"入力してください"),
                DisplayItem(type: ItemType.ECSITE_URL, title: "ECサイトのURL",cell:"NORMAL_CELL", placeholder:"Ex.https://orosy.com", validationType:.URL, errorMsg:"入力してください"),
                DisplayItem(type: ItemType.CATEGORY, title: "カテゴリ",cell:"LIST_BOX_CELL", placeholder:"カテゴリを選択", validationType:.NormalString, errorMsg:"選択してください"),
                DisplayItem(type: ItemType.ANUAL_REVENUE, title: "年間売上（任意）",cell:"NORMAL_CELL", placeholder:"3000000", validationType:.None)

            ]
        ]
            
     
    var retailerProfile:RetailerDetail!
    var businessCategories:[[String:[String:String]]]!

    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        if let navi = self.orosyNavigationController {
            navi.setFirstPageUrl()
        }
        
        let enc = NotificationCenter.default
        enc.addObserver(self, selector: #selector(gotInitialData), name: Notification.Name(rawValue:NotificationMessage.GotInitialData.rawValue), object: nil)

        itemList.append(itemBasicDic)
        itemList.append(itemListForRealShop)

        let headerView = UIView(frame: CGRect(x:0, y:0, width:self.view.bounds.width, height:90))
        let titleLabel = OrosyLabel16(frame:CGRect(x:20, y:20, width:self.view.bounds.width - 40, height:80))
        titleLabel.numberOfLines = 2
        titleLabel.text = NSLocalizedString("ApproveTitle", comment: "")
        headerView.addSubview(titleLabel)
        MainTableView.tableHeaderView = headerView
        //
        let footerView = UIView(frame: CGRect(x:0, y:0, width:self.view.bounds.width, height:80))
        let button = OrosyButton(frame:CGRect(x:20, y:20, width:self.view.bounds.width - 40, height:40))
        button.addTarget(self, action: #selector(applyButtonTuched), for: .touchUpInside)
        button.setButtonTitle(title: "完了", fontSize: 12)
        footerView.addSubview(button)
        MainTableView.tableFooterView = footerView
        
        retailerDetail = RetailerDetail.shared
        profileDetail = ProfileDetail.shared
        

        test()
    }
    
    func test() {

    }
    
    @objc func gotInitialData() {
        if let config = AppConfigData.shared.config {
            businessCategories = config["BusinessCategory"] as? [[String:[String:String]]] ?? []
            DispatchQueue.main.async {
                self.viewWillAppear(false)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
      //  profileDetail.getData()  //　ログインしているユーザのプロファイル
        profileDetail.created = false
        profileDetail.hpUrlString = profileDetail.hpUrl?.absoluteString     // urlを一旦文字列として保存しておく
        
        let brokerStatus = profileDetail.brokerStatus
        
        //　審査待ちチェック
        if brokerStatus == .unDefined {
            // 未入力なのでこのまま入力を続ける
            retailerDetail.getData()
            
        }else{
            if brokerStatus == .approved {
                // 審査済み
                
                UserDefaultsManager.shared.accountStatus = .AccountApproved
                
                // 利用開始！
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let vc = storyboard.instantiateInitialViewController() {
                    (UIApplication.shared.delegate as! AppDelegate).setRootViewController(viewControllerName: vc)       // ホームを開く
                }
                
            }else{
                // 審査待ち
                let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "VerifyEmailVC") as! VerifyEmailVC
                vc.displayMode = .waitApprove
                (UIApplication.shared.delegate as! AppDelegate).setRootViewController(viewControllerName: vc)
            }
        }
    }
    
    func numberOfSections(in: UITableView) -> Int {
        return itemList.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        let display_item = itemList[section] as [String:Any]
        
        return display_item["TITLE"] as? String
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension //自動設定
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        let display_item = itemList[section] as [String:Any]
        let display_data = display_item["DATA"] as! [DisplayItem]
        
        count = display_data.count
        
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let row_data = getItemData(indexPath)
        row_data.indexPath = indexPath
        let itemType = row_data.itemType
 
        let cell = tableView.dequeueReusableCell(withIdentifier: row_data.cellType!, for: indexPath)
        var textField:OrosyTextFieldLabel!
        var buttonWithLabel:OrosyMenuButtonWithLabel!
        var button:UIButton!
        
        if row_data.cellType == "NORMAL_CELL" {
            textField = cell.viewWithTag(1) as? OrosyTextFieldLabel
            textField.indexPath = indexPath
            textField.title = row_data.title ?? ""
            textField.textField?.placeholder = row_data.placeholder
            textField.error = row_data.error
            textField?.errorText = row_data.errorMsg ?? ""
            
            if row_data.validationType == .PhoneNumber || row_data.validationType == .IntNumber {
                textField.textField?.keyboardType = .numbersAndPunctuation
            }else{
                textField.textField?.keyboardType = .default
            }

        }else{
            
            buttonWithLabel = cell.viewWithTag(10) as? OrosyMenuButtonWithLabel
            buttonWithLabel?.button
            buttonWithLabel?.title = row_data.title ?? ""
            buttonWithLabel?.error = row_data.error
            buttonWithLabel?.errorText = row_data.errorMsg ?? ""
            button = buttonWithLabel?.button
        }
        
        switch itemType {
            
        case .BUSINESS_FORMAT:  // 法人/ 個人事業主の区分
            if row_data.inputStr == nil {
                if retailerDetail.created {
                    row_data.inputStr = ((profileDetail.businessFormat == .business) ? "0" : "1")
                }else{
                    row_data.inputStr = "2"
                }
            }
            var sel = Int(row_data.inputStr ?? "2") ?? 2        // 非選択状態にする
            var actions = [UIMenuElement]()
            
            actions.append(UIAction(title: businessFormat[0], image: nil, state: BusinessFormat.business.rawValue == row_data.inputStr ? .on : .off, handler: { (_) in
                row_data.inputStr = "0"
                row_data.error = false
                self.MainTableView.reloadRows(at: [indexPath], with: .none)
                buttonWithLabel?.focus = false
                self.unfocusedOnCurrentCell()
                self.selectedItem = row_data
                self.moveToNextField()
    
                }))

            actions.append(UIAction(title: businessFormat[1], image: nil, state: BusinessFormat.parsonal.rawValue == row_data.inputStr ? .on : .off, handler: { (_) in
                row_data.inputStr = "1"
                row_data.error = false
                self.MainTableView.reloadRows(at: [indexPath], with: .none)
                buttonWithLabel?.focus = false
                self.unfocusedOnCurrentCell()
                self.selectedItem = row_data
                self.moveToNextField()
                }))

            // UIButtonにUIMenuを設定
            button!.menu = UIMenu(title:"" , options: .displayInline, children: actions)
            // こちらを書かないと表示できない場合があるので注意
            button!.showsMenuAsPrimaryAction = true

            // ボタンの表示を変更
            // 初期状態表示するタイトル

            if row_data.inputStr == nil {
                row_data.inputStr = "2"
                sel = 2
                buttonWithLabel!.button.backgroundColor = UIColor.orosyColor(color: .S50)
            }else{
                sel = Int(row_data.inputStr ?? "2") ?? 2
            }
            
            buttonWithLabel!.setButtonTitle(title:businessFormat[sel], fontSize:16)
            if sel == 0 {
            }else if sel == 1 {
            }
            buttonWithLabel!.setButtonTitle(title: businessFormat[sel], fontSize:16)
        
            if initial {
                initial = false
                selectedItem = row_data
                buttonWithLabel.focus = true
            }
            
        case .SALE_TYPE:    // 実店舗の有無
            var actions = [UIMenuElement]()
            if row_data.inputStr == nil {
                if retailerDetail.created {
                    row_data.inputStr = (retailerDetail.haveRealShop) ? "0" : "1"
                }else{
                    row_data.inputStr = "2"
                }
            }
            
            var sel = Int(row_data.inputStr ?? "2") ?? 2        // 非選択状態にする
            actions.append(UIAction(title: SaleTypes[0], image: nil, state: sel == 0 ? .on : .off, handler: { (_) in    //　実店舗
                row_data.inputStr = "0"
                self.itemList.removeLast()
                self.itemList.append(self.itemListForRealShop)
                row_data.error = false
                self.MainTableView.reloadData()     // 店舗ありとECのみの切り替えが発生するのですべて更新する必要がある

                buttonWithLabel?.focus = false
                row_data.indexPath = indexPath
                self.unfocusedOnCurrentCell()
                self.selectedItem = row_data
                self.moveToNextField()

                }))

            actions.append(UIAction(title: SaleTypes[1], image: nil, state: sel == 1 ? .on : .off, handler: { (_) in    //　ECサイトのみ
                row_data.inputStr = "1"
                self.itemList.removeLast()
                self.itemList.append(self.itemListForEC)
                row_data.error = false
                self.MainTableView.reloadData()     // 店舗ありとECのみの切り替えが発生するのですべて更新する必要がある

                buttonWithLabel?.focus = false
                row_data.indexPath = indexPath
                self.unfocusedOnCurrentCell()
                self.selectedItem = row_data
                self.moveToNextField()

                }))

            // UIButtonにUIMenuを設定
            button!.menu = UIMenu(title:"" , options: .displayInline, children: actions)
            // こちらを書かないと表示できない場合があるので注意
            button!.showsMenuAsPrimaryAction = true

            // ボタンの表示を変更
            // 初期状態表示するタイトル

            sel = Int(row_data.inputStr ?? "2") ?? 2
            buttonWithLabel!.setButtonTitle(title:SaleTypes[sel], fontSize:16)
            if sel == 0 {
                self.itemList.removeLast()
                self.itemList.append(self.itemListForRealShop)
            }else if sel == 1 {
                self.itemList.removeLast()
                self.itemList.append(self.itemListForEC)
            }

        case .FIRST_NAME:
            if row_data.inputStr == nil {
                row_data.inputStr  = profileDetail.accountFirstName ?? ""
            }
            textField.text = row_data.inputStr ?? ""

        case .LAST_NAME:
            if row_data.inputStr == nil {
                row_data.inputStr  = profileDetail.accountLastName ?? ""
            }
            textField.text = row_data.inputStr ?? ""
        case .TEL:
            if row_data.inputStr == nil {
                row_data.inputStr  = profileDetail.tel ?? ""
            }
            textField.text = row_data.inputStr ?? ""
        case .BRAND_NAME, .ECSITE_NAME:
            if row_data.inputStr == nil {
                row_data.inputStr  = retailerDetail.shopName ?? ""
            }
            textField.text = row_data.inputStr ?? ""
        case .WEBSITE, .ECSITE_URL:
            if row_data.inputStr == nil {
                for socialUrl in retailerDetail.shopUrls {
                    if socialUrl.category == .Home {
                        row_data.inputStr = socialUrl.url ?? ""
                    }
                }
            }
            textField.text = row_data.inputStr ?? ""
            let urlStr = (row_data.inputStr ?? "").lowercased()
            if urlStr.count == 0 {
                textField.errorText = row_data.errorMsg ?? ""
            }else{
                if !urlStr.contains("http://") && !urlStr.contains("https://") {
                    textField.errorText = "hhttps://を先頭に記載してください。"
                }
            }
                
        case .ANUAL_REVENUE:
            if row_data.inputStr == nil {
                row_data.inputStr  = (retailerDetail.annualSales == 0) ? "" : String(retailerDetail.annualSales)
            }
            textField.text = row_data.inputStr ?? ""
            
        case .CATEGORY: // ECの時は商品カテゴリを選択する
            if row_data.inputStr == nil {
                row_data.inputStr = retailerDetail.categorySub
            }

            var actions = [UIMenuElement]()

            for category in AppConfigData.shared.ecShopCategoryList {
                actions.append(UIAction(title: category.name, image: nil, state: category.key == row_data.inputStr ? .on : .off, handler: { (_) in
                    row_data.inputStr = category.key
                    row_data.error = false
                    buttonWithLabel!.setButtonTitle(title:category.name, fontSize:16)
                    self.MainTableView.reloadRows(at: [indexPath], with: .none)

                    buttonWithLabel?.focus = false
                    row_data.indexPath = indexPath
                    self.unfocusedOnCurrentCell()
                    self.selectedItem = row_data
                    self.moveToNextField()

                    }))
            }

            // UIButtonにUIMenuを設定
            button!.menu = UIMenu(title:"" , options: .displayInline, children: actions)
            // こちらを書かないと表示できない場合があるので注意
            button!.showsMenuAsPrimaryAction = true

            // ボタンの表示を変更
            // 初期状態表示するタイトル
            let title = (row_data.inputStr == nil) ? row_data.placeholder ?? "" : AppConfigData.shared.getNameFromECKey(key: row_data.inputStr ?? "")
            buttonWithLabel!.setButtonTitle(title: title, fontSize:16)

        case .NUMBER_OF_SHOPS:
            var actions = [UIMenuElement]()
            if row_data.inputStr == nil {
                row_data.inputStr = retailerDetail.numberOfStores?.rawValue
            }
            
            for store in NumberOfStores.allCases {
                
                actions.append(UIAction(title: NSLocalizedString(store.rawValue, comment: ""), image: nil, state: store.rawValue == row_data.inputStr ? .on : .off, handler: { (_) in
                    row_data.inputStr = store.rawValue
                    row_data.error = false
                //    buttonWithLabel!.button.setButtonTitle(title:NSLocalizedString(store.rawValue, comment: ""), fontSize:16)
                    self.MainTableView.reloadRows(at: [indexPath], with: .none)
 
                    buttonWithLabel?.focus = false
                    row_data.indexPath = indexPath
                    self.unfocusedOnCurrentCell()
                    self.selectedItem = row_data
                    self.moveToNextField()

                    }))

            }
            // UIButtonにUIMenuを設定
            button!.menu = UIMenu(title:"" , options: .displayInline, children: actions)
            // こちらを書かないと表示できない場合があるので注意
            button!.showsMenuAsPrimaryAction = true

            // ボタンの表示を変更
            // 初期状態表示するタイトル
            let title = (row_data.inputStr == nil) ? "店舗数を選択" : NSLocalizedString(row_data.inputStr!, comment: "")

            buttonWithLabel!.setButtonTitle(title:title , fontSize:16)
            break
            
            
        default:
            textField.titleLabel?.text = row_data.title

        }
        
        return cell
    }
    
    
    @objc func applyButtonTuched() {
        
        // 最後にカーソルがセットされているフィールドからカーソルを外すことで、そのフィールドを編集モードから抜けさせる
        if let indexPath = indexPathBeingEdited {
            if let cell = self.MainTableView.cellForRow(at: indexPath) {
            
                if let lastTextField = cell.viewWithTag(2) as? OrosyTextField {
                    lastTextField.resignFirstResponder()        // 最後のフィールド
                }
            }
        }
        
        initial = false
        
        var error = false
        
        for section in 0..<itemList[0].count {
            let datas = itemList[section]["DATA"] as? [DisplayItem] ?? []
            for row in 0..<datas.count {
                let row_data = getItemData(IndexPath(row: row, section: section))
                
                var (success, _normalizedStr) = Validation.normalize(type: row_data.validationType, inStr:row_data.inputStr )

                row_data.error = !success
                
                if let normalizedStr = _normalizedStr {

                    switch  row_data.itemType {
                    
                    case .BUSINESS_FORMAT:
                        let sel = Int(normalizedStr) ?? 0
                        if sel == 2 {
                            success = false
                        }else{
                            success = true
                            profileDetail.businessFormat = (sel == 0) ? .business : .parsonal
                        }
                        row_data.error = !success
                    case .SALE_TYPE:
                        let sel = Int(normalizedStr) ?? 0
                        if sel == 2 {
                            success = false
                        }else{
                            success = true
                            retailerDetail.haveRealShop = (sel == 0) ? true : false
                        }
                        row_data.error = !success
                        
                    case .LAST_NAME:
                        profileDetail.accountLastName = normalizedStr
                    case .FIRST_NAME:
                        profileDetail.accountFirstName = normalizedStr
                    case .TEL:
                        profileDetail.tel = normalizedStr
                    case .BRAND_NAME,  .ECSITE_NAME:        // 実店舗の場合は　ブランド名、 ECサイトの場合はECサイト名
                        retailerDetail.shopName = normalizedStr
                        
                    case .WEBSITE, .ECSITE_URL:
                        
                        var find = false
                        for socialUrl in retailerDetail.shopUrls {
                            if socialUrl.category == .Home {
                                socialUrl.url = normalizedStr
                                find = true
                                break
                            }
                        }
                        if !find {
                            //存在しなかったので追加する
                            retailerDetail.shopUrls.append(SocialUrl.init(category:.Home, urlString: normalizedStr))
                        }
                    
                    case .NUMBER_OF_SHOPS:
                        if normalizedStr == "" {
                            success = false
                        }else{
                            success = true
                            retailerDetail.numberOfStores = NumberOfStores(rawValue: normalizedStr)
                        }
                        row_data.error = !success

                    case .ANUAL_REVENUE:
                        retailerDetail.annualSales = Int(normalizedStr) ?? 0
                        success = true
                        row_data.error = false
                    case .CATEGORY:
                        retailerDetail.categorySub = normalizedStr       // EC用の業種カテゴリーは　　Subに登録する
                    default:
                        break
                    }
                }
                if !success { error = true }    // どれか一つでもエラーになったらエラーダイアログを表示する
            }
        }
        
        if error {
            // エラーが解消されていない
            let dialog =  SmoothDialog()
            dialog.label.textColor = UIColor.orosyColor(color: .Red)
            self.view.addSubview(dialog)
            dialog.show(message: NSLocalizedString("CheckInputData", comment: ""))
            MainTableView.reloadData()
            
            return
        }
        
        //　保存
        let result = profileDetail.update()    //　プロファイルも更新
         
        switch result {
        case .success(_):
          //  profileDetail.email = KeyChainManager.shared.load(id:.loginId) ?? ""
            let result_p = retailerDetail.update()     // リテイラー情報を更新　　notCreated: レコード未作成

            
            switch result_p {
            case .success(_):
                
                UserDefaultsManager.shared.accountStatus = .ApproveRequested
                UserDefaultsManager.shared.updateUserData()
                
                /*
                let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "VerifyEmailVC") as! VerifyEmailVC
                vc.displayMode = .waitApprove
                (UIApplication.shared.delegate as! AppDelegate).setRootViewController(viewControllerName: vc)
                */
                g_userLog.profileCreate(userId:g_MyId ?? "", pageUrl: RETAILER_SITE_URL + "/account/basicInitialRegister")
                
                gotoHome()
                
            case .failure(_):
                self.confirmAlert(title: "登録できませんでした。", message: "やり直してください")
            }
            
        case .failure(_):
            self.confirmAlert(title: "登録できませんでした。", message: "やり直してください")

        }
    }
    
    
    func gotoHome() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateInitialViewController() {
            
            let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
            appDelegate.setRootViewController(viewControllerName: vc)   // ホームを開く
            if let window = appDelegate.window {
                UIView.transition(with: window,
                                  duration: 0.5,
                                  options: .transitionCrossDissolve,
                                  animations: nil,
                                  completion: nil)
            }
        }
        
    }
    
}
