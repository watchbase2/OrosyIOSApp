//
//  ProfileVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/05/23.
//

import UIKit


class ProfileVC: CommonEditVC, UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ProfileEditDelegate  {

    var delegate:ProfileRequestDelegate?
    
    var photoCollectionView: UICollectionView!
    var profileDetail:ProfileDetail?
    var retailerDetail:RetailerDetail?
    

    /*
        UITableViewのセクションごとに表示する項目の定義
        タイプによって使用するCELLのデザインなどが異なる
    */
    
    
    var itemListForRealShop:[String:Any] =
        [
            "TITLE" : "",
            "DATA" : [
                DisplayItem(type: ItemType.TITLE, title: "区分", cell:"TITLE_CELL", height:44),
                DisplayItem(type: ItemType.BUSINESS_FORMAT, title: "区分", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.BUSINESS_TYPE, title: "販売形式", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.CATEGORY_MAIN, title: "店舗業種", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.CATEGORY_SUB, title: "カテゴリ", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.START_YEAR, title: "開設年", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.NUMBER_OF_SHOPS, title: "開設店舗数", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.ANNUAL_REVENUE, title: "年間売上", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.HOME_URL, title:  "URL", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.INSTAGRAM, title:  "Instagram ID", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.TWITTER, title:  "Twitter ID", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.FACEBOOK, title:  "Facebook ID", cell:"COMMON_CELL", height:44),

            ]
        ]
    let subListForRealShop:[DisplayItem] =
    [
        DisplayItem(type: ItemType.SHOP_PHOTO, title: "店舗写真", cell:"PHOTO_CELL", height:44),
        DisplayItem(type: ItemType.CONCEPT, title: "店舗コンセプト", cell:"CONCEPT_CELL", height:44),
        DisplayItem(type: ItemType.TARGET_USER, title: "客層", cell:"COMMON_CELL", height:44),
        DisplayItem(type: ItemType.REVENUE_PER_CUSTOMER, title: "客単価", cell:"COMMON_CELL", height:44),
    ]
    
    var itemListForEC:[String:Any] =
        [
                "TITLE" : "",
                "DATA" : [
                DisplayItem(type: ItemType.TITLE, title: "区分", cell:"TITLE_CELL", height:44),
                DisplayItem(type: ItemType.BUSINESS_FORMAT, title: "区分", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.BUSINESS_TYPE, title: "販売形式", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.CATEGORY_SUB, title: "カテゴリ", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.START_YEAR, title: "開設年", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.ANNUAL_REVENUE, title: "年間売上", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.HOME_URL, title:  "ECサイトのURL", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.INSTAGRAM, title:  "Instagram ID", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.TWITTER, title:  "Twitter ID", cell:"COMMON_CELL", height:44),
                DisplayItem(type: ItemType.FACEBOOK, title:  "Facebook ID", cell:"COMMON_CELL", height:44),

                ]
            ]
    let subListForEC:[DisplayItem] =
    [
        DisplayItem(type: ItemType.CONCEPT, title: "サイトコンセプト", cell:"CONCEPT_CELL", height:44),
        DisplayItem(type: ItemType.TARGET_USER, title: "客層", cell:"COMMON_CELL", height:44),
        DisplayItem(type: ItemType.REVENUE_PER_CUSTOMER, title: "客単価", cell:"COMMON_CELL", height:44),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNaviTitle(title: "プロフィール情報")
   
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"blank"), style:.plain, target: self, action: nil)    // タイトルがセンターになるようにダミーのボタンを配置

        if #available(iOS 15.0, *) {
            MainTableView.sectionHeaderTopPadding = 0.0 // iOS15から追加された、セクションヘッダーの上のスペースを消す
        }

        profileDetail = ProfileDetail.shared
        retailerDetail = RetailerDetail.shared

        if RetailerDetail.shared.hasInputDone && ProfileDetail.shared.hasInputDone {
            UserDefaultsManager.shared.accountStatus = .AccountProfiled
            UserDefaultsManager.shared.updateUserData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {

        refreshData()
        MainTableView.reloadData()
    }
    
    func refreshData() {
        profileDetail?.getData()
        retailerDetail?.getData()

        itemList = []
        // 実店舗かECに応じて選択
        itemList.append( ( retailerDetail?.haveRealShop ?? false ) ? itemListForRealShop : itemListForEC )
        
        var data = itemList[0]["DATA"] as? [DisplayItem] ?? []
        var count = 1
        for shop in retailerDetail?.shopUrls ?? [] {
            
            if shop.category == .Others {
                data.append(DisplayItem(type: ItemType.OTHER_URL, title: "URL" + String(count), cell: "COMMON_CELL", inputStr:shop.url ?? ""))
                count += 1
            }
        }
        
        data.append(contentsOf: ( retailerDetail?.haveRealShop ?? false ) ? subListForRealShop : subListForEC)
        itemList[0]["DATA"] = data
        
        // ショップ画像をキャッシュへ入れる
        DispatchQueue.global().sync {
            LogUtil.shared.log("Start load shopImages")
            for photoUrl in retailerDetail!.shopImages {
                OrosyAPI.cacheImage(photoUrl,imagesize:.Size100)
            }
        }
        
        MainTableView.reloadData()
    
    }

    func numberOfSections(in: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension //自動設定
        
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        let display_data = itemList[0]["DATA"] as! [DisplayItem]
        
        count = display_data.count
        
        return count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let row = indexPath.row
        
        let display_data = itemList[0]["DATA"] as! [DisplayItem]
        let row_data = display_data[row]
 
        let cell = tableView.dequeueReusableCell(withIdentifier: row_data.cellType!, for: indexPath)
        let titleLabel = cell.viewWithTag(1) as! UILabel
        let valueLabel = cell.viewWithTag(2) as? UILabel
        
        titleLabel.text = row_data.title
        valueLabel?.text = ""
        
        let itemType = row_data.itemType
        
        switch itemType {
        case .TITLE:
            let brandTitleLabel = cell.viewWithTag(1) as! UILabel
            let brandTitleImageView = cell.viewWithTag(2) as! OrosyUIImageView
            let brandIconBackgroundImageView = cell.viewWithTag(3) as! OrosyUIImageView
            let brandIconImageView = cell.viewWithTag(4) as! OrosyUIImageView100
            let brandName = cell.viewWithTag(5) as! UILabel
            let editButton = cell.viewWithTag(10) as! OrosyButtonWhite
            
            brandTitleImageView.getImageFromUrl(url: retailerDetail?.headerImage)
            brandIconImageView.getImageFromUrl(url: retailerDetail?.logoImage)
            brandName.text = retailerDetail?.shopName
            
            brandTitleLabel.text = "こちらの情報はサプライヤーに公開される情報です。"
            editButton.setButtonTitle(title: "プロフィールを編集する", fontSize: 14)
            editButton.layer.borderColor = UIColor.orosyColor(color: .Blue).cgColor
                                                      
            brandIconImageView.drawBorder(cornerRadius:  brandIconImageView.bounds.height  / 2, color: UIColor.orosyColor(color: .Gray200), width: 1)
            brandIconBackgroundImageView.drawBorder(cornerRadius: brandIconBackgroundImageView.bounds.height / 2, color: .clear, width: 0)

        case .BUSINESS_FORMAT: valueLabel?.text = ( profileDetail?.businessFormat ?? .none == .business) ? "法人" : "個人事業主"
        case .BUSINESS_TYPE: valueLabel?.text = ( retailerDetail?.haveRealShop ?? false) ? "実店舗を持っている" : "ECサイトのみ"
        case .CATEGORY_MAIN:
             var value:String!
             if ( retailerDetail?.haveRealShop ?? false) {
                 let key =  ( retailerDetail?.categoryMain ?? .none)
                 value = (key == .RETAIL) ? "小売店" : "サービス"
             }else{
                 // ECサイト
                 value = ""
             }
             valueLabel?.text = value
                                  
        case .CATEGORY_SUB:
            let key =  ( retailerDetail?.categorySub ?? .none) ?? ""
            
            if ( retailerDetail?.haveRealShop ?? false)  {
                let retail = (retailerDetail?.categoryMain == .RETAIL) ? true : false
                //valueLabel?.text = AppConfigData.shared.getNameFromShopKey(retail:retail, key:key)
                valueLabel?.text = AppConfigData.shared.getNameFromShopKey(retail: retail, key:key)
            }else{
                // ECサイト
                valueLabel?.text = AppConfigData.shared.getNameFromECKey( key:key)
            }
             
        case .START_YEAR:
            if let year = retailerDetail?.openingYear {
                if year == 0 {
                    valueLabel?.text = ""
                }else{
                    valueLabel?.text = String(year) + "年"
                }
            }else{
                valueLabel?.text = ""
            }
        case .NUMBER_OF_SHOPS: valueLabel?.text = NSLocalizedString ((retailerDetail?.numberOfStores ?? .SMALL).rawValue, comment: "")
        case .ANNUAL_REVENUE:

            valueLabel?.text = Util.number2Str(NSNumber(value: retailerDetail?.annualSales ?? 0))
        case .HOME_URL:
            for social in retailerDetail?.shopUrls ?? [] {
                if social.category == .Home {
                    valueLabel?.text = social.url
                }
            }
        case .INSTAGRAM:
            for social in retailerDetail?.shopUrls ?? [] {
                if social.category == .Instagram {
                    valueLabel?.text = social.url
                }
            }
        case .TWITTER:
            for social in retailerDetail?.shopUrls ?? [] {
                if social.category == .Twitter {
                    valueLabel?.text = social.url
                }
            }
        case .FACEBOOK:
            for social in retailerDetail?.shopUrls ?? [] {
                if social.category == .Facebook {
                    valueLabel?.text = social.url
                }
            }
        case .OTHER_URL:
            valueLabel?.text = row_data.inputStr
        
        case .SHOP_PHOTO:
            photoCollectionView = cell.contentView.viewWithTag(200) as? UICollectionView
            photoCollectionView.reloadData()
            
        case .CONCEPT:
            let textView = cell.viewWithTag(2) as! UILabel
            textView.text = retailerDetail?.concept ?? ""
        case .TARGET_USER: valueLabel?.text = retailerDetail?.customerType ?? ""
            
        case .REVENUE_PER_CUSTOMER: valueLabel?.text = Util.number2Str(NSNumber(value:retailerDetail?.amountPerCustomer ?? 0))
            
        default:
            print("nothing to do")
        }
        
        return cell
    }
    
    var logoutExec = false
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row

        let display_data = itemList[0]["DATA"] as! [DisplayItem]
        let row_data = display_data[row]
    
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: CELL_HEIGHT_PHOTO, height: CELL_HEIGHT_PHOTO)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let count = retailerDetail?.shopImages.count ?? 0

        return (count == 0) ? 1 : count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let row = indexPath.row
        var cell:UICollectionViewCell!
        
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShopPhotosCell", for: indexPath)

        let imageView = cell.contentView.viewWithTag(100) as! OrosyUIImageView100
        
        imageView.targetRow = row

        imageView.image = nil
        
        if retailerDetail?.shopImages.count ?? 0 > row {
            let shopImageUrl = retailerDetail?.shopImages[row]
        
            imageView.getImageFromUrl(row: row, url: shopImageUrl, defaultUIImage: g_defaultImage)
            imageView.drawBorder(cornerRadius: 0)
        }
        return cell
    }

    
    @IBAction func goToEditMode(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ProfileEditVC") as! ProfileEditVC
        vc.delegate = self
        vc.profileDetail = profileDetail
        vc.retailerDetail = retailerDetail
       // var delegate:ProfileEditDelegate!
        self.orosyNavigationController?.pushViewController(vc, animated: true)

    }

}
