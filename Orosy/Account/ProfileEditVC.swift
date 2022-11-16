//
//  ProfileVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/05/23.
//

import UIKit

protocol ProfileEditDelegate:AnyObject {
    func refreshData()
}



class ProfileEditVC: CommonEditVC, UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIImagePickerControllerDelegate,ConfirmControllerDelegate, UIPopoverPresentationControllerDelegate, CroppingDelegate   {

    var profileDetail:ProfileDetail!
    var retailerDetail:RetailerDetail!
    var delegate:ProfileEditDelegate!
    

    @IBOutlet var brandTitleImageView: OrosyUIImageView!
    @IBOutlet var brandIconImageView: OrosyUIImageView100!
    @IBOutlet var brandIconBackgroundImageView: OrosyUIImageView!
    @IBOutlet var brandTitleLabel: UILabel!
    //@IBOutlet var titleView: UIView!
    @IBOutlet weak var editButton: OrosyButtonWhite!
    @IBOutlet weak var photoSelectErrorMsg: OrosyLabel14!
    @IBOutlet weak var ogpSampleView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    


    var photoCollectionView: OrosyUICollectionView!

    var otherUrls:[String] = []
    var otherUrlPoint:Int = 0
    var shopPhotos:[PhotoData] = []
    var titleImage:PhotoData?
    var logoImage:PhotoData?
    

    class PhotoData:NSObject {
        var type:PhotoMode!
        var url:URL?
        var image:UIImage?
        
        init(type:PhotoMode, url:URL? = nil, image:UIImage?) {
            self.type = type
            self.url = url
            self.image = image
        }
    }
    

    /*
        UITableViewのセクションごとに表示する項目の定義
        タイプによって使用するCELLのデザインなどが異なる
    */
    
    // NORMAL_CELL:  タイトルあり
    // WITHOUT_TITLE_CELL: タイトルなし
    // LIST_BOX_CELL: 選択ボックス
    // ADD_URL_CELL: 追加ボタン
    

    let imageViewBackgroundNormalColor = UIColor.orosyColor(color: .S50)
    let imageViewBackgroundErrorColor = UIColor.orosyColor(color: .R50)
    
    var brandImageError = false
    var logoImageError = false
    var shopImageError = false
    var numberOfShopPhoto:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNaviTitle(title: "プロフィール情報")
        LogUtil.shared.log("Start viewDidLoad")
 
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"blank"), style:.plain, target: self, action: nil)    // タイトルがセンターになるようにダミーのボタンを配置
      
        var hpUrl:String = ""
        var instagramUrl:String = ""
        var twitterUrl:String = ""
        var facebookUrl:String = ""
        
        for social in retailerDetail?.shopUrls ?? [] {
            if social.category == .Home {
                hpUrl = social.url ?? ""
            }
            if social.category == .Instagram {
                instagramUrl = social.url ?? ""
            }
            if social.category == .Twitter {
                twitterUrl = social.url ?? ""
            }
            if social.category == .Facebook {
                facebookUrl = social.url ?? ""
            }
        }
    
        
        let itemBlock1 = [
            DisplayItem(type: ItemType.HEADER, title: "", cell:"TITLE_CELL", height:44),
            DisplayItem(type: ItemType.BRAND_NAME, title: "ブランド名・ディスプレイネーム（最大30文字）", cell:"NORMAL_CELL", placeholder:"Ex.オロシー", height:44,inputStr: retailerDetail?.shopName ?? "", focus: false), //最初にフォーカスを置く行)
            DisplayItem(type: ItemType.BUSINESS_FORMAT, title: "区分", cell:"WITHOUT_TITLE_CELL", height:44, fixed:true),
            DisplayItem(type: ItemType.BUSINESS_TYPE, title: "販売形式", cell:"WITHOUT_TITLE_CELL", height:44, fixed:true),
        ]
        let itemBloxk2_real = [
            DisplayItem(type: ItemType.CATEGORY_MAIN, title: "店舗業種", cell:"LIST_BOX_CELL", placeholder:"業種を選択", height:44, errorMsg:"選択してください"),
            DisplayItem(type: ItemType.CATEGORY_SUB, title: "カテゴリ", cell:"LIST_BOX_CELL", placeholder:"カテゴリを選択", height:44, errorMsg:"選択してください"),
        ]
        let itemBloxk2_ec = [
            DisplayItem(type: ItemType.CATEGORY_SUB, title: "カテゴリ", cell:"LIST_BOX_CELL", placeholder:"カテゴリを選択", height:44, errorMsg:"選択してください"),
        ]
        let itemBlock3 = [
            DisplayItem(type: ItemType.START_YEAR, title: "開設年", cell:"NORMAL_CELL", placeholder:"Ex.2018", height:44, validationType:.IntNumber, inputStr: ((retailerDetail.openingYear == 0) ? "" : String(retailerDetail.openingYear)), errorMsg:"半角数字で入力してください"),
        ]
        let itemBloxk4_real = [
            DisplayItem(type: ItemType.NUMBER_OF_SHOPS, title: "開設店舗数", cell:"LIST_BOX_CELL", placeholder:"展開店舗数を選択", height:44, validationType:.None,inputStr:retailerDetail?.numberOfStores?.rawValue),
        ]
        let itemBlock5 = [
            DisplayItem(type: ItemType.ANUAL_REVENUE, title: "年間売上（任意）", cell:"NORMAL_CELL", placeholder:"Ex.400000", height:44, validationType:.IntNumberAllowBlank, inputStr:String(retailerDetail?.annualSales ?? 0), errorMsg:"半角数字で入力してください"),
        ]
        let itemBloxk6_real = [
            DisplayItem(type: ItemType.WEBSITE, title:  "店舗のwebsite", cell:"NORMAL_CELL", placeholder:"Ex.https://orosy.com", height:44, validationType:.URL,inputStr:hpUrl,  errorMsg:"入力してください"),
        ]
        let itemBloxk6_ec = [
            DisplayItem(type: ItemType.ECSITE_URL, title:  "ECサイトのURL", cell:"NORMAL_CELL", height:44, validationType:.URL,inputStr:hpUrl,  errorMsg:"入力してください"),
        ]
        
        let itemBlock7 = [
            DisplayItem(type: ItemType.INSTAGRAM, title:  "Instagram ID（任意）", cell:"NORMAL_CELL", height:44, validationType:.None,inputStr:instagramUrl,helpButtonEnable:true),
            DisplayItem(type: ItemType.TWITTER, title:  "Twitter ID（任意）", cell:"NORMAL_CELL", height:44, validationType:.None, inputStr:twitterUrl,helpButtonEnable:true),
            DisplayItem(type: ItemType.FACEBOOK, title:  "Facebook ID（任意）", cell:"NORMAL_CELL", height:44, validationType:.None, inputStr:facebookUrl,helpButtonEnable:true),
            DisplayItem(type: ItemType.ADD_URL, title:  "URLを追加", cell:"ADD_URL_CELL", height:44, fixed:true),
        ]
        let itemBlock8_real = [
            DisplayItem(type: ItemType.SHOP_PHOTO, title: "店舗写真", cell:"PHOTO_CELL", height:44, validationType:.NormalString, fixed:true, errorMsg:"写真を選択してください"),
            DisplayItem(type: ItemType.CONCEPT, title: "店舗コンセプト", cell:"TEXTVIEW_CELL", placeholder:"Ex.世界に広がるクリエイターのグローバルネットワークのためのサービスをお届けします。", height:44, validationType:.NormalString, inputStr: String(retailerDetail?.concept ?? ""), errorMsg:"入力してください"),

        ]
        let itemBlock8_ec = [
            DisplayItem(type: ItemType.CONCEPT, title: "サイトコンセプト", cell:"TEXTVIEW_CELL", placeholder:"Ex.世界に広がるクリエイターのグローバルネットワークのためのサービスをお届けします。", height:44, validationType:.NormalString, inputStr: String(retailerDetail?.concept ?? ""), errorMsg:"入力してください"),
        ]
        let itemBlock9 = [
            DisplayItem(type: ItemType.TARGET_USER, title: "客層", cell:"NORMAL_CELL", placeholder:"Ex.20〜40代女性", height:44, validationType:.NormalString, inputStr: String(retailerDetail?.customerType ?? ""), errorMsg:"入力してください"),
            DisplayItem(type: ItemType.REVENUE_PER_CUSTOMER, title: "客単価（任意）", cell:"NORMAL_CELL", placeholder:"Ex.1400", height:44, validationType:.IntNumberAllowBlank, inputStr: String(retailerDetail?.amountPerCustomer ?? 0 ), errorMsg:"半角数字で入力してください"),
            DisplayItem(type: .FOOTER, title: "ボタン", cell:"FOOTER_CELL", placeholder:"" ),
        ]
        
        var tempList :[DisplayItem] = []
        tempList.append(contentsOf: itemBlock1)
        // 実店舗かECに応じて選択
        if retailerDetail?.haveRealShop ?? false {
            // 実店舗
            tempList.append(contentsOf: itemBloxk2_real)
            tempList.append(contentsOf: itemBlock3)
            tempList.append(contentsOf: itemBloxk4_real)
            tempList.append(contentsOf: itemBlock5)
            tempList.append(contentsOf: itemBloxk6_real)
            tempList.append(contentsOf: itemBlock7)
            tempList.append(contentsOf: itemBlock8_real)
            tempList.append(contentsOf: itemBlock9)
        }else{
            // ECサイト
            tempList.append(contentsOf: itemBloxk2_ec)
            tempList.append(contentsOf: itemBlock3)
            tempList.append(contentsOf: itemBlock5)
            tempList.append(contentsOf: itemBloxk6_ec)
            tempList.append(contentsOf: itemBlock7)
            tempList.append(contentsOf: itemBlock8_ec)
            tempList.append(contentsOf: itemBlock9)
        }
        
        var dic:[String:Any] = [:]
        
        dic["DATA"] = tempList

        // その他のURLの定義を追加
        var tempArray:[DisplayItem] = []
        for social in retailerDetail?.shopUrls ?? [] {
            if social.category == .Others {
                if let url = social.url {
                    otherUrls.append(url)
                    tempArray.append(DisplayItem(type: ItemType.OTHER_URL, title:  "その他（任意）", cell:"NORMAL_CELL", height:44,validationType: .URL,inputStr: url))
                }
            }
        }
        // 追加ボタン用のデータを追加
        if tempArray.count > 0 {
            var dataArray = dic["DATA"] as! [DisplayItem]
            for item in dataArray {
                if item.itemType == .ADD_URL {
                    dataArray.insert(contentsOf: tempArray, at:otherUrlPoint)
                    break
                }
                otherUrlPoint += 1
            }
            dic["DATA"] = dataArray
        }
        
        itemList.append(dic)
        
        if let url = retailerDetail.headerImage {
            // キャッシュから取得できなければダウンロードする
           OrosyAPI.getImageFromCache(url,imagesize:.None) { completion in
               
               if let cashedImage = completion {
                   self.titleImage = PhotoData(type: PhotoMode.brand_title, url: url, image: cashedImage)
               }
            }
            /*
             if let cashedImage = OrosyAPI.getImageFromCache(url,imagesize:.None) {
                 titleImage = PhotoData(type: PhotoMode.brand_title, url: url, image: cashedImage)
                 
             }else{
                 do {
                     let imageData: Data? = try Data(contentsOf:url )
                     if let data = imageData {
                         if let image = UIImage(data: data) {
                             titleImage = PhotoData(type: PhotoMode.brand_title, url: url, image: image)
                         }
                     }
                 }catch{
                     
                 }
             }
             */
        }
        
        if let url = retailerDetail.logoImage {
            // キャッシュから取得できなければダウンロードする
            
            OrosyAPI.getImageFromCache(url,imagesize:.None) { completion in
                
                if let cashedImage = completion {
                    self.logoImage = PhotoData(type: PhotoMode.brand_title, url: url, image: cashedImage)
                    DispatchQueue.main.async {
                        self.MainTableView.reloadData()
                    }
                }
             }
            /*
            if let cashedImage = OrosyAPI.getImageFromCache(url,imagesize:.Size100) {

                logoImage = PhotoData(type: PhotoMode.brand_title, url: url, image: cashedImage)
            }else{

                do {
                    let imageData: Data? = try Data(contentsOf:url )
                    if let data = imageData {
                        if let image = UIImage(data: data) {
                            logoImage =  PhotoData(type: PhotoMode.brand_icon, url: url, image: image)
                        }
                    }
                }catch{
                    
                }
            }
             */
        }
        
       // self.MainTableView.reloadData()
        
        DispatchQueue.global().sync {
            LogUtil.shared.log("Start load shopImages")
            for photoUrl in retailerDetail.shopImages {
                
                OrosyAPI.getImageFromCache(photoUrl,imagesize:.Size100) { completion in
                    if let cashedImage = completion {
                        self.shopPhotos.append( PhotoData(type: PhotoMode.shop, url: photoUrl, image: cashedImage))
                    }
                    DispatchQueue.main.async {
                        LogUtil.shared.log("Done load shopImages")
                        self.MainTableView.reloadData()
                    }
                }
                /*
                if let cashedImage = OrosyAPI.getImageFromCache(photoUrl,imagesize:.Size100) {
                    shopPhotos.append( PhotoData(type: PhotoMode.shop, url: photoUrl, image: cashedImage))
                }else{
                    do {
                        let imageData: Data? = try Data(contentsOf:photoUrl )
                        if let data = imageData {
                            if let image = UIImage(data: data) {
                                shopPhotos.append( PhotoData(type: PhotoMode.shop, url: photoUrl, image: image))
                            }

                    }catch{
                    }
                }
                 */
            }
        }
        
        numberOfShopPhoto = shopPhotos.count

        MainTableView.reloadData()

        test()
    }
    
    func test() {

        /*
        if let image = UIImage(named:"test.jpg") {
            retailerDetail.saveImage(type: .retailerLogo, image: image) { complete in
                if let url = complete {
                    self.retailerDetail.logoImage = URL(string:url)
                    self.retailerDetail.update()
                }

            }
        }
         */
    }
    
    func numberOfSections(in: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        let row_data = getItemData(indexPath)
        if row_data.itemType == .CATEGORY_SUB {
            return (row_data.error) ? 100 : 80
            
        }else{
            return UITableView.automaticDimension //自動設定
        }
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        let display_data = itemList[section]["DATA"] as! [DisplayItem]
        
        count = display_data.count
        
        return count
    }
    

    var serviceRetail:RealShopMainCategory = .RETAIL
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        
        let row_data = getItemData(indexPath)
        row_data.indexPath = indexPath
        
        let cell = tableView.dequeueReusableCell(withIdentifier: row_data.cellType!, for: indexPath)
        if let titleLabel = cell.viewWithTag(1) as? UILabel {
            titleLabel.text = row_data.title
        }
        
        let valueLabel = cell.viewWithTag(1) as? OrosyTextFieldLabel
        valueLabel?.text = ""
        
        let textField = cell.viewWithTag(2) as? OrosyTextField
        textField?.text = ""
        
        let unitLabel = cell.viewWithTag(3) as? OrosyLabel14
        unitLabel?.text = ""
        

        let itemType = row_data.itemType
        
        if row_data.cellType == "NORMAL_CELL" {
            valueLabel?.indexPath = indexPath
            valueLabel?.title = row_data.title ?? ""
            valueLabel?.textField?.placeholder = row_data.placeholder
            valueLabel?.error = row_data.error
            valueLabel?.errorText = row_data.errorMsg ?? ""
            valueLabel!.helpButtonEnable = row_data.helpButtonEnable

            valueLabel?.focus = row_data.focus
            if row_data.focus {
                selectedItem = row_data
                valueLabel?.textField?.becomeFirstResponder()
            }
            
            let validationType = row_data.validationType!
            
            if validationType == .PhoneNumber || validationType == .IntNumber || validationType == .IntNumberAllowBlank {
                valueLabel?.textField?.keyboardType = .numbersAndPunctuation
            }else{
                valueLabel?.textField?.keyboardType = .default
            }
        }
        
        switch itemType {
        case .HEADER:
            // ブランドタイトル画像
            
            let brandTitleImageView = cell.viewWithTag(1) as! OrosyUIImageView
            brandTitleImageView.backgroundColor = (brandImageError) ? imageViewBackgroundErrorColor : imageViewBackgroundNormalColor
            brandTitleImageView.image = titleImage?.image
            
            let cameraiconOnTitle = cell.viewWithTag(2) as! UIImageView
            cameraiconOnTitle.isHidden = (titleImage?.image == nil) ? false : true
            
            let tapMessageLabel = cell.viewWithTag(3) as! OrosyLabel12
            tapMessageLabel.isHidden = (titleImage == nil) ? false : true
            let errorLabel = cell.viewWithTag(7) as! OrosyLabel14
            errorLabel.isHidden = !brandImageError && !logoImageError
  
            // ロゴ画像
            let logoBackView = cell.viewWithTag(4) as! OrosyUIImageView
            logoBackView.drawBorder(cornerRadius: logoBackView.bounds.width / 2.0)
            let logoView = cell.viewWithTag(5) as! OrosyUIImageView100
            logoView.drawBorder(cornerRadius: logoView.bounds.width / 2.0)
            logoView.backgroundColor = (logoImageError) ? imageViewBackgroundErrorColor : imageViewBackgroundNormalColor
            
            logoView.image = logoImage?.image
            let cameraiconOnLogo = cell.viewWithTag(6) as! UIImageView
            cameraiconOnLogo.isHidden = (logoImage == nil) ? false : true
 
            
        case .BRAND_NAME:
            valueLabel!.title = row_data.title ?? ""
            valueLabel!.text = row_data.inputStr ?? ""
            
        case .BUSINESS_FORMAT:
            textField?.textColor = UIColor.orosyColor(color: .Gray400)
            textField?.underlineColor = UIColor.orosyColor(color: .S100)
            textField?.text = "区分：" + (( profileDetail?.businessFormat ?? .none == .business) ? "法人" : "個人事業主")
            textField?.isUserInteractionEnabled = false
            
        case .BUSINESS_TYPE:
            textField?.textColor = UIColor.orosyColor(color: .Gray400)
            textField?.underline = true
            textField?.underlineColor = UIColor.orosyColor(color: .S100)
            textField?.text = "販売形式：" + (( retailerDetail?.haveRealShop ?? false) ? "実店舗を持っている" : "ECサイトのみ")
            textField?.isUserInteractionEnabled = false
            
        case .CATEGORY_MAIN:
            
            let buttonWithLabel = cell.viewWithTag(10) as? OrosyMenuButtonWithLabel
            let button = buttonWithLabel?.button
            buttonWithLabel?.title = row_data.title ?? ""
            buttonWithLabel?.error = row_data.error
            buttonWithLabel?.errorText = row_data.errorMsg ?? ""
            buttonWithLabel?.underline = true

            let key =  ( retailerDetail?.categoryMain ?? .none)
            
            let categoryTitle = [RealShopMainCategory.RETAIL:"小売店" ,RealShopMainCategory.SERVICE :"サービス"]
  
            if let buttonMenu = button {
                if row_data.inputStr == nil {
                    row_data.inputStr = key?.rawValue
                }

                var actions = [UIMenuElement]()

                self.serviceRetail = RealShopMainCategory(rawValue:  row_data.inputStr ?? "retail") ?? .RETAIL

                actions.append(UIAction(title: categoryTitle[RealShopMainCategory.RETAIL]!, image: nil, state: (serviceRetail == .RETAIL) ? .on : .off, handler: { (_) in
                    row_data.inputStr = RealShopMainCategory.RETAIL.rawValue
                    row_data.edited = true
                    self.serviceRetail = .RETAIL
                    buttonWithLabel!.setButtonTitle(title:categoryTitle[RealShopMainCategory.RETAIL]!, fontSize:16)
                    buttonWithLabel?.focus = false
                    self.MainTableView.reloadRows(at: [IndexPath(row:row, section:0),IndexPath(row:row+1, section:0)], with: .automatic)
                    row_data.indexPath = indexPath
                    self.selectedItem = row_data
                    self.moveToNextField()
                }))
                    
                actions.append(UIAction(title: categoryTitle[RealShopMainCategory.SERVICE]!, image: nil, state: (serviceRetail == .SERVICE) ? .on : .off, handler: { (_) in
                    row_data.inputStr = RealShopMainCategory.SERVICE.rawValue
                    row_data.edited = true
                    self.serviceRetail = .SERVICE
                    buttonWithLabel!.setButtonTitle(title:categoryTitle[RealShopMainCategory.SERVICE]!, fontSize:16)
                    buttonWithLabel?.focus = false
                    self.MainTableView.reloadRows(at: [IndexPath(row:row, section:0), IndexPath(row:row+1, section:0)], with: .automatic)
                    row_data.indexPath = indexPath
                    self.selectedItem = row_data
                    self.moveToNextField()
                }))
                    
                // UIButtonにUIMenuを設定
                buttonMenu.menu = UIMenu(title:"" , options: .displayInline, children: actions)
                // こちらを書かないと表示できない場合があるので注意
                buttonMenu.showsMenuAsPrimaryAction = true

                // ボタンの表示を変更
                // 初期状態表示するタイトル
                let title = (row_data.inputStr == nil) ? row_data.placeholder : categoryTitle[RealShopMainCategory(rawValue: row_data.inputStr ?? "retail")!]
                buttonWithLabel!.setButtonTitle(title: title ?? "", fontSize:16)

            }
        case .CATEGORY_SUB:

            let buttonWithLabel = cell.viewWithTag(10) as? OrosyMenuButtonWithLabel
            let button = buttonWithLabel?.button
            buttonWithLabel?.title = row_data.title ?? ""
            buttonWithLabel?.error = row_data.error
            buttonWithLabel?.errorText = row_data.errorMsg ?? ""
            
            if let buttonMenu = button {
                if row_data.inputStr == nil {
                    row_data.inputStr = retailerDetail!.categorySub
                }

                if ( retailerDetail?.haveRealShop ?? false) {
                    var actions = [UIMenuElement]()
                    let isRetail = (serviceRetail == .RETAIL) ? true : false
                    let categories = (isRetail) ? AppConfigData.shared.retailShopCategoryList : AppConfigData.shared.serviceShopCategoryList
                    
                    for category in categories {
                        actions.append(UIAction(title: category.name, image: nil, state: category.key == row_data.inputStr ? .on : .off, handler: { (_) in
                            row_data.inputStr = category.key
                            row_data.edited = true
                            row_data.error = false
                            buttonWithLabel!.setButtonTitle(title:category.name, fontSize:16)
                            self.MainTableView.reloadRows(at: [indexPath], with: .automatic)
                            row_data.indexPath = indexPath
                            self.selectedItem = row_data
                            self.moveToNextField()
                        }))
                    }

                    // UIButtonにUIMenuを設定
                    buttonMenu.menu = UIMenu(title:"" , options: .displayInline, children: actions)
                    // こちらを書かないと表示できない場合があるので注意
                    buttonMenu.showsMenuAsPrimaryAction = true

                    // ボタンの表示を変更
                    // 初期状態表示するタイトル
                    
                    let title = (row_data.inputStr == nil) ? "カテゴリを選択" : AppConfigData.shared.getNameFromShopKey(retail: isRetail, key: row_data.inputStr ?? "")
                    buttonWithLabel!.setButtonTitle(title: title, fontSize:16)
                    
                }else{
                    //  EC
                    var actions = [UIMenuElement]()

                    for category in AppConfigData.shared.ecShopCategoryList {
                        actions.append(UIAction(title: category.name, image: nil, state: category.key == row_data.inputStr ? .on : .off, handler: { (_) in
                            row_data.inputStr = category.key
                            row_data.edited = true
                            row_data.error = false
                            buttonWithLabel!.setButtonTitle(title:category.name, fontSize:16)
                            self.MainTableView.reloadRows(at: [indexPath], with: .automatic)
                            row_data.indexPath = indexPath
                            self.selectedItem = row_data
                            self.moveToNextField()
                            }))
                    }

                    // UIButtonにUIMenuを設定
                    buttonMenu.menu = UIMenu(title:"" , options: .displayInline, children: actions)
                    // こちらを書かないと表示できない場合があるので注意
                    buttonMenu.showsMenuAsPrimaryAction = true

                    // ボタンの表示を変更
                    // 初期状態表示するタイトル
                    
                    let title = (row_data.inputStr == nil) ? "カテゴリー" : AppConfigData.shared.getNameFromECKey(key: row_data.inputStr ?? "")
                    buttonWithLabel!.setButtonTitle(title: title, fontSize:16)
                    
                }
            }

        case .START_YEAR:
            valueLabel!.title = row_data.title ?? ""
            valueLabel!.text = row_data.inputStr ?? ""
            unitLabel?.text = "年"
            
        case .NUMBER_OF_SHOPS:
            let buttonWithLabel = cell.viewWithTag(10) as? OrosyMenuButtonWithLabel
            let button = buttonWithLabel?.button
            buttonWithLabel?.title = row_data.title ?? ""
            buttonWithLabel?.error = row_data.error
            
            if let buttonMenu = button {
                var actions = [UIMenuElement]()

                for store in NumberOfStores.allCases {
                    
                    actions.append(UIAction(title: NSLocalizedString(store.rawValue, comment: ""), image: nil, state: store.rawValue == row_data.inputStr ? .on : .off, handler: { (_) in
                        row_data.inputStr = store.rawValue
                        row_data.edited = true
                        buttonWithLabel!.setButtonTitle(title:NSLocalizedString(store.rawValue, comment: ""), fontSize:16)
                        self.MainTableView.reloadRows(at: [IndexPath(row:row, section:0)], with: .automatic)
                        row_data.indexPath = indexPath
                        self.selectedItem = row_data
                        self.moveToNextField()
                        }))
                }
                // UIButtonにUIMenuを設定
                buttonMenu.menu = UIMenu(title:"" , options: .displayInline, children: actions)
                // こちらを書かないと表示できない場合があるので注意
                buttonMenu.showsMenuAsPrimaryAction = true

                // ボタンの表示を変更
                // 初期状態表示するタイトル
                if row_data.inputStr == nil { row_data.inputStr =  NumberOfStores.SMALL.rawValue }
                buttonWithLabel!.setButtonTitle(title: NSLocalizedString(row_data.inputStr!, comment: ""), fontSize:16)
           
            }
            
        case .ANUAL_REVENUE:
            valueLabel!.title = row_data.title ?? ""
            valueLabel?.text =  row_data.inputStr ?? ""
            unitLabel?.text = "円"
        case .WEBSITE, .ECSITE_URL :
            valueLabel!.title = row_data.title ?? ""
            valueLabel!.text = row_data.inputStr ?? ""
            let urlStr = (row_data.inputStr ?? "").lowercased()
            if urlStr.count == 0 {
                valueLabel?.errorText = row_data.errorMsg ?? ""
            }else{
                if !urlStr.contains("http://") && !urlStr.contains("https://") {
                    valueLabel?.errorText = "hhttps://を先頭に記載してください。"
                }
            }

        case .INSTAGRAM:
            valueLabel!.title = row_data.title ?? ""
            valueLabel!.text = row_data.inputStr ?? ""
            valueLabel!.helpButton?.indexPath = indexPath
            
        case .TWITTER:
            if row_data.inputStr == nil {
                for social in retailerDetail?.shopUrls ?? [] {
                    if social.category == .Twitter {
                        row_data.inputStr = social.url ?? ""
                    }
                }
            }
            valueLabel!.title = row_data.title ?? ""
            valueLabel!.text = row_data.inputStr ?? ""
            valueLabel!.helpButton?.indexPath = indexPath
        case .FACEBOOK:
            if row_data.inputStr == nil {
                for social in retailerDetail?.shopUrls ?? [] {
                    if social.category == .Facebook {
                        row_data.inputStr = social.url ?? ""
                    }
                }
            }
            valueLabel!.title = row_data.title ?? ""
            valueLabel!.text = row_data.inputStr ?? ""
            valueLabel!.helpButton?.indexPath = indexPath
        case .ADD_URL:
            let button = cell.viewWithTag(12) as? IndexedButton
            button?.indexPath = indexPath
            
        case .OTHER_URL:
            valueLabel!.title = row_data.title ?? ""
            valueLabel!.text = row_data.inputStr ?? ""
            
        case .SHOP_PHOTO:
            photoCollectionView = cell.contentView.viewWithTag(200) as? OrosyUICollectionView
            //photoCollectionView.error = shopImageError
            photoCollectionView.reloadData()
            photoCollectionView.indexPath = indexPath
            
        case .CONCEPT:
            let textView = cell.viewWithTag(1) as! OrosyTextViewLabel
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
        case .TARGET_USER:
            valueLabel!.title = row_data.title ?? ""
            valueLabel?.text =  row_data.inputStr ?? ""
        case .REVENUE_PER_CUSTOMER:
            valueLabel!.title = row_data.title ?? ""
            valueLabel?.text =  ( row_data.inputStr == "0") ? "" : row_data.inputStr ?? ""
            unitLabel?.text = "円"
        case .FOOTER:
            activityIndicator = cell.viewWithTag(1) as? UIActivityIndicatorView
            if saving { activityIndicator.startAnimating() }
            
        default:
            print("nothing to do")
        }
        
        return cell
    }
    
    @IBAction func clearPhotoButtonTouched(_ sender: UIButton) {
    
        let button = sender as! IndexedButton
        
        switch button.tag {
        case 11:
            // title
            titleImage = nil     // 未使用
        case 21:
            // icon
            logoImage = nil     // 未使用
            
        case 31:
            // shop
            let row = button.indexPath!.row
            shopPhotos.remove(at: row)
            shopPhotoCollectionView.reloadData()
        default:
            break
        }
        MainTableView.reloadData()
        
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let row_data = getItemData(indexPath)
    
        let itemType = row_data.itemType
        
        switch itemType {

        default:
            print("nothing to do")
        }
    
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    // 店舗写真
    // セルのサイズをセット
    let CELL_HEIGHT_PHOTO = 100
    var shopPhotoCollectionView:UICollectionView!
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        shopPhotoCollectionView = collectionView
        
        return CGSize(width: CELL_HEIGHT_PHOTO, height: CELL_HEIGHT_PHOTO)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let count = shopPhotos.count
        return (count == 0) ? 2 : (count + ((count < 10) ? 1 : 0))        // 10未満なら写真追加ボタンを表示
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let row = indexPath.row
        var cell:UICollectionViewCell!
        
        var cellID = "ShopPhotosCell"
        let count = shopPhotos.count
        if count == 0 {
            cellID = (row == 0) ? "CameraIconCell" : "AddPhotoButtonCell"
        }else if count < 10 {
            if row == count {
                cellID = "AddPhotoButtonCell"
            }
        }
        
        cell = collectionView.dequeueReusableCell(withReuseIdentifier:cellID  , for: indexPath)
        
        if cellID == "ShopPhotosCell"  {
            let clearButton = cell.viewWithTag(31) as! IndexedButton
            clearButton.indexPath = indexPath

        }
        if cellID == "AddPhotoButtonCell"  || cellID == "CameraIconCell" {
            let photoButton = cell.viewWithTag(10) as! IndexedButton
            photoButton.indexPath = indexPath
            photoButton.setTitle("", for: .normal)
        }
        if count > 0 && row < count {
            let imageView = cell.contentView.viewWithTag(100) as! OrosyUIImageView100

            imageView.image = nil
            
            imageView.image = shopPhotos[row].image
            imageView.drawBorder(cornerRadius: 0)

        }else{
            
            if shopImageError {     //  }(   collectionView as! OrosyUICollectionView).error {
                cell.contentView.backgroundColor = UIColor.orosyColor(color: .R50)
            }else{
                cell.contentView.backgroundColor = UIColor.orosyColor(color: .S50)
            }
        }


        return cell
    }
    
    var shopPhotoAppendMode = false
    var shopPhotoPosition:Int = 0
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        return
        let row = indexPath.row
        shopPhotoPosition = row
        
        let count = retailerDetail?.shopImages.count ?? 0
        shopPhotoAppendMode = (row >= count) ? true : false
        // 写真を追加
        selectedPhotoMode = .shop

    }
    
    
    @IBAction func addShopPhoto(_ sender: IndexedButton) {
        if let indexPath = sender.indexPath {
            let row = indexPath.row
            shopPhotoPosition = row
            
            let count = retailerDetail?.shopImages.count ?? 0
            shopPhotoAppendMode = (row >= count) ? true : false
            // 写真を追加
            selectedPhotoMode = .shop
            
            selectPhoto(sender)
        }
        
    }
    
    // MARK: 追加
    @IBAction func addOtherUrlButtonTapped(_ sender: Any) {
        let button = sender as! IndexedButton
        if let indexPath = button.indexPath {
            
            let item = DisplayItem(type: ItemType.OTHER_URL, title:  "その他（任意）", cell:"NORMAL_CELL", height:44)
            var itemArray = itemList[0]["DATA"] as! [DisplayItem]
            itemArray.insert(item, at: indexPath.row)
            itemList[0]["DATA"] = itemArray
            //MainTableView.reloadData()
            otherUrls.append("")
            MainTableView.insertRows(at: [indexPath], with: .top)  // ＋ボタンの行も更新する必要がある
            button.indexPath = IndexPath(row:indexPath.row + 1, section:indexPath.section)

            // 以降の行を更新することで、 indexPath情報を更新する
            var paths:[IndexPath] = []
            let startRow = indexPath.row
            for row in startRow..<itemArray.count {
                paths.append(IndexPath(row:row , section:0))
            }
            
            MainTableView.reloadRows(at: paths, with: .none)
            
            /*
            for row in 0..<itemArray.count {
                let indexPath = IndexPath(row:row, section:0)
                let row_data = getItemData(indexPath)
                row_data.indexPath = indexPath
            }
             */
        }
    }


    // MARK: 保存
    var initial:Bool = false
    var conceptView:OrosyTextViewLabel?
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
        
        otherUrls = []
        var error = false
        let display_data = itemList[0]["DATA"] as! [DisplayItem]

        for row in 0..<(itemList[0]["DATA"] as! [DisplayItem]).count {
   
            let row_data = display_data[row]

            let itemType = row_data.itemType
            
            if itemType == .BUSINESS_FORMAT || itemType == .BUSINESS_TYPE || itemType == .ADD_URL{ continue }

            var success = true
            var _normalizedStr = row_data.inputStr
            
            (success, _normalizedStr) = Validation.normalize(type: row_data.validationType, inStr:row_data.inputStr )
            
            row_data.error = !success
            
            let normalizedStr = _normalizedStr ?? ""

            switch  itemType {
            case .HEADER:
                success = true
            case .BRAND_NAME:        // 実店舗の場合は　ブランド名、 ECサイトの場合はECサイト名
                retailerDetail!.shopName = normalizedStr

            case .CATEGORY_MAIN:
                if let str = row_data.inputStr {
                    retailerDetail!.categoryMain = RealShopMainCategory(rawValue: str )
                }else{
                    retailerDetail!.categoryMain = RealShopMainCategory.RETAIL
                }
                toBeSaved = true
            case .CATEGORY_SUB:
                retailerDetail!.categorySub = row_data.inputStr
                toBeSaved = true
            case .WEBSITE, .ECSITE_URL:
                var find = false
                if normalizedStr == "" {
                    row_data.error = true
                }else{
                    for socialUrl in retailerDetail!.shopUrls {
                        if socialUrl.category == .Home {
                            socialUrl.url = normalizedStr
                            find = true
                            break
                        }
                    }
                    if !find {
                        //存在しなかったので追加する
                        retailerDetail!.shopUrls.append(SocialUrl.init(category:.Home, urlString: normalizedStr))
                        row_data.error = false
                    }
                }

            case .INSTAGRAM:
                var find = false
                for socialUrl in retailerDetail!.shopUrls {
                    if socialUrl.category == .Instagram {
                        socialUrl.url = normalizedStr
                        find = true
                        break
                    }
                }
                if !find {
                    //存在しなかったので追加する
                    retailerDetail!.shopUrls.append(SocialUrl.init(category:.Instagram, urlString: normalizedStr))
                }
                row_data.error = false
            case .TWITTER:
                var find = false
                for socialUrl in retailerDetail!.shopUrls {
                    if socialUrl.category == .Twitter {
                        socialUrl.url = normalizedStr
                        find = true
                        break
                    }
                }
                if !find {
                    //存在しなかったので追加する
                    retailerDetail!.shopUrls.append(SocialUrl.init(category:.Twitter, urlString: normalizedStr))
                }
                row_data.error = false
            case .FACEBOOK:
                var find = false
                for socialUrl in retailerDetail!.shopUrls {
                    if socialUrl.category == .Facebook {
                        socialUrl.url = normalizedStr
                        find = true
                        break
                    }
                }
                if !find {
                    //存在しなかったので追加する
                    retailerDetail!.shopUrls.append(SocialUrl.init(category:.Facebook, urlString: normalizedStr))
                }
                row_data.error = false
            case .OTHER_URL:
                if otherUrls.count > row - otherUrlPoint {
                    otherUrls[row - otherUrlPoint] = normalizedStr
                }else{
                    otherUrls.append(normalizedStr)
                }
                row_data.error = false
                success = true
            case .START_YEAR:
                retailerDetail!.openingYear =  Int(normalizedStr) ?? 0
                
            case .NUMBER_OF_SHOPS:
                retailerDetail!.numberOfStores = NumberOfStores(rawValue: normalizedStr)
                toBeSaved = true
            case .ANUAL_REVENUE:
                retailerDetail!.annualSales = Int(normalizedStr) ?? 0
            case .CONCEPT:
                retailerDetail.concept = normalizedStr
            case .TARGET_USER:
                retailerDetail.customerType = normalizedStr
            case .REVENUE_PER_CUSTOMER:
                retailerDetail.amountPerCustomer = Int(normalizedStr) ?? 0
            case .SHOP_PHOTO:

                if shopPhotos.count == 0 {
                    row_data.error = true
                    success = false
                }else{
                    row_data.error = false
                    success = true
                }
                
            default:
                success = true
                break
            }

            if !success {
                error = true
            }    // どれか一つでもエラーになったらエラーダイアログを表示する

        }
        
        if otherUrls.count > 0 {
            var newArray:[SocialUrl] = []
            for socialUrl in retailerDetail!.shopUrls {
                if socialUrl.category != .Others {
                    newArray.append(socialUrl)
                }
            }
            for url in otherUrls {
                if url != "" {
                    let otherSocial = SocialUrl.init(category:.Others, urlString: url)
                    newArray.append(otherSocial)
                }
            }
            retailerDetail!.shopUrls = newArray
        }

        // 画像をアップロードしてurlを取得
        
        if titleImage?.image == nil {
            error = true
            brandImageError = true
        }else{
            brandImageError = false
            if titleImage?.url == nil {
                if let image = titleImage?.image {
                    let semaphore = DispatchSemaphore(value: 0)
                    retailerDetail.saveImage(type: .retailerHeader, image: image) { complete in
                        if let url = complete {
                            self.retailerDetail.headerImage = URL(string:url)
                        }
                        semaphore.signal()
                    }
                    semaphore.wait()
                }
            }
        }
        //
        if logoImage?.image == nil {
            error = true
            logoImageError = true
        }else{
            logoImageError = false
            if logoImage?.url == nil {
                if let image = logoImage?.image {
                    let semaphore = DispatchSemaphore(value: 0)
                    retailerDetail.saveImage(type: .retailerLogo, image: image) { complete in
                        if let url = complete {
                            self.retailerDetail.logoImage = URL(string:url)
                        }
                        semaphore.signal()
                    }
                    semaphore.wait()
                }
            }
        }
        
        if retailerDetail?.haveRealShop ??  false {
            // 店舗ありの時は写真が必要
            self.retailerDetail.shopImages = []
            var tempArray:[URL] = []
            
            if shopPhotos.count == 0 {
                error = true
                shopImageError = true
            }else{
                shopImageError = false
                for photoData in shopPhotos {
                    if photoData.url == nil {
                        let semaphore = DispatchSemaphore(value: 0)
                        retailerDetail.saveImage(type: .retailerShops, image: photoData.image!) { complete in
                            if let urlStr = complete {
                                if let url = URL(string: urlStr) {
                                    tempArray.append(url)
                                }
                            }
                            semaphore.signal()
                        }
                        semaphore.wait()
                    }else{
                        if let url = photoData.url {
                            tempArray.append(url)
                        }
                    }
                }
                self.retailerDetail.shopImages = tempArray
            }
        }
        
        if error {
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()

                // エラーが解消されていない
                let dialog =  SmoothDialog()
                self.view.addSubview(dialog)
                dialog.show(message: NSLocalizedString("CheckInputData", comment: ""))
                self.MainTableView.reloadData()
            }
            saving = false
            return
        }
        

        //　保存
        let result = retailerDetail!.update()     // リテイラー情報を更新　　notCreated: レコード未作成
         
        switch result {
        case .success(_):

            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.saving = false
                self.delegate.refreshData()
                _ = self.orosyNavigationController?.popViewController(animated: true)
            }
        case .failure(_):
            DispatchQueue.main.async {
                self.saving = false
                self.activityIndicator.stopAnimating()
                self.confirmAlert(title: "登録できませんでした。", message: "やり直してください")
            }
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
            
    // MARK: カメラ関連
    var imagePicker: UIImagePickerController!
    var cameraPicker:UIImagePickerController!
    var photoMode = false

    enum PhotoMode {
        case brand_title
        case brand_icon
        case shop
    }
    var selectedPhotoMode:PhotoMode!
    
    @IBAction func photoButtonTapped(_ sender: Any) {
        selectedPhotoMode = ((sender as! UIButton).tag == 10) ? .brand_title : .brand_icon
       /*
        if let image = UIImage(named:"test.jpg") {
            self.showCroppView(image, circle:true)
        }
        */
         selectPhoto(sender as? UIView)
    }
    
    func selectPhoto(_ sender:UIView? = nil) {

        CameraAuthorization.request(vc: self) { allow in
            
            if !allow { return  }
            
            DispatchQueue.main.async {

                // styleをActionSheetに設定
                let alertSheet = UIAlertController(title: "", message: "写真を選択してください", preferredStyle: .actionSheet)
                  // 選択肢を生成
                let action1 = UIAlertAction(title: "ライブラリから選択", style: .default, handler: {
                    (action: UIAlertAction!) in
                     
                    self.imagePicker = UIImagePickerController()
                    self.imagePicker.delegate = self
                    self.imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
                    self.imagePicker.allowsEditing = false
                    self.imagePicker.view.backgroundColor = .white
                    self.imagePicker.navigationBar.isTranslucent = false
                    self.imagePicker.navigationBar.barTintColor = .blue
                    self.imagePicker.navigationBar.tintColor = .white
                    self.imagePicker.navigationBar.titleTextAttributes = [
                         NSAttributedString.Key.foregroundColor: UIColor.white
                     ] // Title color
                    self.photoMode = true
                    self.present(self.imagePicker, animated: true, completion: nil)
                })
                alertSheet.addAction(action1)
                // カメラデバイスがあれば、写真を撮るメニューを表示する
                if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
                    let action2 = UIAlertAction(title: "写真を撮る", style: .default, handler: {
                        (action: UIAlertAction!) in
                        
                        self.cameraPicker = UIImagePickerController()
                        self.cameraPicker.sourceType = .camera
                        self.cameraPicker.delegate = self
                        // UIImagePickerController カメラを起動する
                        self.photoMode = true
                        self.present(self.cameraPicker, animated: true, completion: nil)
                        
                    })
                    alertSheet.addAction(action2)
                }
                
                if self.selectedPhotoMode == .brand_title {
                    let action3 = UIAlertAction(title: "Webサイトから取得", style: .default, handler: {
                    (action: UIAlertAction!) in
                        self.getImageFromWebsite()
                    
                    })
                    alertSheet.addAction(action3)
                }
                
                let cancel = UIAlertAction(title: "キャンセル", style: .cancel, handler: {
                    (action: UIAlertAction!) in
                    
                })
                alertSheet.addAction(cancel)

                
                // iPad support
                if let senderView = sender {
                    alertSheet.popoverPresentationController?.sourceView = senderView
                    alertSheet.popoverPresentationController?.sourceRect = senderView.bounds
                }else{
                    // xは画面中央、yは画面下部になる様に指定
                    alertSheet.popoverPresentationController?.sourceView = self.view
                    let screenSize = UIScreen.main.bounds
                    alertSheet.popoverPresentationController?.sourceRect = CGRect(x: 0, y: screenSize.size.height, width: 0, height: 0)
                }
  
                self.present(alertSheet, animated: true, completion: nil)
            }

        }

    }

    func closePreviewView() {
      //  imagePreviewView.isHidden = true
      //  self.imagePreView.isHidden = true
    }
    // 画像選択画面でキャンセルした
    @IBAction func sendCancel() {
        closePreviewView()
    }
    // 画像が選択された時に呼ばれる
     func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

         toBeSaved = true
         
         if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
             
             self.dismiss(animated: true, completion: nil)
             switch selectedPhotoMode {
             case .brand_title:
                 
                 self.showCroppView(image, circle:false)
             case .brand_icon:
                 self.showCroppView(image, circle:true)
             case .shop:
                 let photo = PhotoData(type: .shop, url:nil, image: image)
                 shopImageError = false
                 if shopPhotoAppendMode {
                     shopPhotos.append(photo)
                 }else{
                     shopPhotos[shopPhotoPosition] = photo
                 }
                 
                 shopPhotoCollectionView.reloadData()
             default:
                 break
             }
         }
     }

     // 画像選択がキャンセルされた時に呼ばれる.
     func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {

         // モーダルビューを閉じる
         self.dismiss(animated: true, completion: nil)
     }

    func showCroppView(_ image:UIImage, circle:Bool ) {
        
        let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CroppingVC") as! CroppingVC
        vc.circeMode = circle
        vc.originalImage = image    // UIImage(named: "test")
        vc.delegate = self
        self.present(vc, animated: true)
    }
    
    func getCoppedImage(_ croppedImage:UIImage) {
        
        switch selectedPhotoMode {
        case .brand_title:
            titleImage = PhotoData(type: PhotoMode.brand_title, url: nil, image: croppedImage)
            brandImageError = false
        case .brand_icon:
            logoImage = PhotoData(type: PhotoMode.brand_icon, url: nil, image: croppedImage)
            logoImageError = false
        default:
            break
        }
        MainTableView.reloadRows(at: [IndexPath(row:0, section:0)], with: .none)
        
    }

    @IBAction override func closeView() {
        
        if toBeSaved {
            openConfirmVC(title:NSLocalizedString("NotSaved", comment: ""), message: NSLocalizedString("ConfirmNotSaveReturn", comment: ""), mainButtonTitle:"キャンセル", cancelButtonTitle:"閉じる")
        }else{
            _ = self.orosyNavigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: Popup View
    @IBAction override func orosyTextFieldButton(_ button: IndexedButton) {
        
        guard let indexPath = button.indexPath else { return }
        
        let row_data = getItemData(indexPath)
        
        let itemType = row_data.itemType
        var snsMode:PopoverVC.POPUP_HELP!
        
        switch itemType {
        case .FACEBOOK:
            snsMode = .FACEBOOK
        case .INSTAGRAM:
            snsMode = .INSTAGRAM
        case .TWITTER:
            snsMode = .TWITTER
        default:
            print("nothing to do")
        }
    
        
        let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PopoverVC") as! PopoverVC
        vc.mode = snsMode
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
    
    @IBOutlet weak var acceptThisImageButton: OrosyButton!
    //
    @IBAction func getImageFromWebsite() {
        let ogpFetcher = OGPFetcher()
        let display_data = itemList[0]["DATA"] as! [DisplayItem]
        acceptThisImageButton.isEnabled = false
        
        for row in 0..<display_data.count {
            
            let row_data = getItemData(IndexPath(row:row, section:0))
            
            if row_data.itemType == .WEBSITE || row_data.itemType == .ECSITE_URL {
                var url = row_data.inputStr
                /*
                if url == nil || url == "" {
                    for social in retailerDetail?.shopUrls ?? [] {
                        if social.category == .Home {
                            url = social.url
                        }
                    }
                }
                 */
                let urlStr = url ?? ""
                if urlStr != "" {
                    
                    ogpSampleView.isHidden = false
                    let label = self.ogpSampleView.viewWithTag(1) as? UILabel
                    let titleImage = self.ogpSampleView.viewWithTag(2) as? OrosyUIImageView
                    let faviImage = self.ogpSampleView.viewWithTag(3) as? OrosyUIImageView100
                    
                    label?.text = ""
                    titleImage?.image = nil
                    faviImage?.image = nil
                    
                    DispatchQueue.main.async {
                        self.ogpWaitIndicator.startAnimating()
                    }
                    
                    DispatchQueue.global().async {

                        if ogpFetcher.get(targetURL: urlStr) {

                            DispatchQueue.main.async {
                                self.acceptThisImageButton.isEnabled = true
                                self.ogpWaitIndicator.stopAnimating()
                                self.ogpSampleView.isHidden = false

                                label?.text = ogpFetcher.site_name
                                
                                titleImage?.getImageFromUrl(url: ogpFetcher.image)
                                faviImage?.getImageFromUrl(url: ogpFetcher.favicon)
                            }
                        }else{
                            // 画像は見つかりません
                            DispatchQueue.main.async {
                                let dialog =  SmoothDialog()
                                self.view.addSubview(dialog)
                                dialog.show(message: "画像は見つかりません。\n他のURLで試すか、他の方法で取得してください")
                                self.ogpSampleView.isHidden = true
                            }
                        }
                    }

                }else{
                    // urlがセットされていない
                    let dialog =  SmoothDialog()
                    self.view.addSubview(dialog)
                    dialog.show(message: "先にサイトのURLをセットしてください")
                    ogpSampleView.isHidden = true
                }
            }
            ogpWaitIndicator.stopAnimating()
        }
    }
    @IBOutlet weak var ogpWaitIndicator: UIActivityIndicatorView!
    @IBAction func selectOgpImage(_ sender: Any) {
        let image = (self.ogpSampleView.viewWithTag(2) as? OrosyUIImageView)?.image
        self.titleImage = PhotoData(type: PhotoMode.brand_title, url: nil, image: image)
        ogpSampleView.isHidden = true
        
        MainTableView.reloadRows(at: [IndexPath(row:0, section:0)], with: .none)
    }
    @IBAction func closeOgpSampleView(_ sender: Any) {
        ogpSampleView.isHidden = true
    }
}
