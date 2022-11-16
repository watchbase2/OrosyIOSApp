//
//  ProductDetailVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/16.
//

import UIKit
import SafariServices

enum ProductItemType {
    case IMAGE
    case TITLE
    case PRICE
    case UNIT
    case VARIATION
    case CARTBUTTON
    case CODITIONS
    case TAX
    case SIZE
    case PL
    case OTHERS
    case MATERIAL
    case DETAIL
    case PRODUCTS       // 関連商品
    case SECTION_TITLE
    case URL
    case PRECAUTION
    case SPECIFICATION
    case REQUIREMENT
    case RECOMMEND
    case POINT_CAMPAIGN
}


class ProductDisplayItem: NSObject {
    
    var itemType:ProductItemType?
    var title:String?
    var cellType:String?
    var itemObject: NSObject?
    var itemHeight:CGFloat
    var expand:Bool = false
    

    init( type:ProductItemType, title:String?, cell:String?, height:CGFloat, expand:Bool ) {
        
        self.itemType = type
        self.title = title
        self.cellType = cell
        self.itemHeight = height
        self.expand = expand
    }
}

class ProductDetailVC: OrosyUIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    @IBOutlet weak var MainTableView:UITableView!
    @IBOutlet weak var blackCoverView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cartInMessageView: UIView!
    
    @IBOutlet weak var popupModalVIewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var modalView: UIView!
    var defaultTopConstraint:CGFloat = 0
    
    let PRODUCT_IMAGE_SIZE_RATE:CGFloat = 0.88      // 画面幅に対する比率
    let MAX_IMAGE_WIDTH:CGFloat = 400               // 画面幅ｘPRODUCT_IMAGE_SIZE_RATEの最大値
    
    var displayItemList:[[String:Any]] = []
    var displayItemList_base:[[String:Any]] =   // バリエーションに関係なく表示する項目
    [
        ["SECTION_TITLE": "ProductImage",
            "ROW_DATA": [
                ProductDisplayItem(type: .IMAGE, title: "イメージ", cell:"ImageCell", height:-1, expand:false)
                    ]
        ],
        ["SECTION_TITLE": "",
            "ROW_DATA": [
                    ProductDisplayItem(type: .TITLE, title: "タイトル", cell:"TitleCell", height:-1, expand:false)
                    ]
        ],
        ["SECTION_TITLE": "",
            "ROW_DATA": [
                    ProductDisplayItem(type: .PRICE, title: "価格", cell:"CommonCell", height:-1, expand:false),
                    ProductDisplayItem(type: .PRICE, title: "価格", cell:"CommonCell", height:-1, expand:false),
                    ProductDisplayItem(type: .PRICE, title: "消費税率", cell:"CommonCell", height:-1, expand:false),
                    ProductDisplayItem(type: .POINT_CAMPAIGN, title: "獲得ポイント", cell:"CampaignCell", height:-1, expand:false)
                    
            ]
        ] ,
        ["SECTION_TITLE": "",
            "ROW_DATA": [
                    ProductDisplayItem(type: .VARIATION, title: "ロット数", cell:"VariationCell", height:-1, expand:false),
                    ProductDisplayItem(type: .VARIATION, title: "バリエーション1", cell:"VariationCell", height:-1, expand:false),
                    ProductDisplayItem(type: .VARIATION, title: "バリエーション2", cell:"VariationCell", height:-1, expand:false)
            ]
        ] , // 商品によって行数が変わる
        ["SECTION_TITLE": "",
            "ROW_DATA": [
                    ProductDisplayItem(type: .CARTBUTTON, title: "カート", cell:"BuyCell", height:-1, expand:false )
                    ]
        ]
        
    ]

    var  restIitemParents:[ItemParent] = [] //　選択されている商品以外の同じブランドの他の商品
    /*
    //　Homeやサプライヤページから遷移するとき
    var itemParent_id:String! { // 上位で持っている情報だけでは不十分なので、選択された商品のidを受け取って必要な情報を全て読み出す
        didSet {
           DispatchQueue.global().async {
                self.itemParent = ItemParent(itemParentId:self.itemParent_id)
               self.selectedItem = self.itemParent.item
           }
        }
    }
    */
    
    var recommendedItems:[ItemParent] = []
    
    var orderedCheck:Bool = false
    var supplier:Supplier! {
        didSet {
            orderedCheck = supplier.checkOrders()   // 過去に注文実績があるかどうかのチェック　　true: 過去にオーダがある
            //orderedCheck = false   // for test
        }
    }
    
    // 複数バリエーション中で選択しているアイテム
    var itemParent:ItemParent! {
        didSet {
            self.imageUrls = self.itemParent.imageUrls
            
            LogUtil.shared.log("Start get itemParent")
            
            DispatchQueue.global().async {
                _ = self.itemParent.getItemParent()
                self.selectedItem = self.itemParent.item

                self.imageUrls = self.itemParent.imageUrls
                
                if self.selectedItem == nil {
                    self.selectedItem = self.itemParent.variationItems.first
                }

                
              //  if self.connectionStatus == nil {
                    if self.supplier.tradeConnection == nil {
                        self.supplier.tradeConnection = self.supplier.getTradeConnection()
                    }
                    self.connectionStatus = self.supplier.tradeConnection?.status
             //  }
                
                
                //　同じブランドの商品
                self.getRestProduct()
                
                // リコメンド商品の表示
                let recommend = RecommendedItems()
           
                if self.MainTableView == nil || self.displayItemList.count == 0 {   // まだ viewDidloadでの準備ができていない場合は、ここではデータをセットしない。
                    
                    self.requestRestPRoducts = true
                    
                }else{
                    self.setRestProducts()
                    
                }
                
                LogUtil.shared.log("Start recommendedItems")
                self.recommendedItems = recommend.getRecommendedItemListByItemId(size:20, itemId: self.itemParent.id)   //　処理時間がかかっているが分割して取得する方法はない
                LogUtil.shared.log("End recommendedItems")
                
                for  itemParent in self.recommendedItems {
                    if let _ = itemParent.item {
                        OrosyAPI.cacheImage(itemParent.imageUrls.first, imagesize: .Size100)
                    }
                }
     
                if self.MainTableView == nil || self.displayItemList.count == 0 {
                    
                    self.requestRecommendedProducts = true
                    
                }else{
                    self.setRecommendedProducts()
                    
                }
            }

        }
    }
    
    var selectedItem:Item! {
        didSet {
  
        }
    }
    
    var requestRestPRoducts = false
    
    func setRestProducts() {
        DispatchQueue.main.async {
            
            LogUtil.shared.log("Ready Table update in selectedItem")
            self.MainTableView.beginUpdates()
            
            if self.restIitemParents.count > 0 {
                self.MainTableView.reloadSections(IndexSet(integer: self.displayItemList.count - 2), with: .none)
            }else{
                LogUtil.shared.log("restIitemParents is empty")
            }
            
        }
        
    }
    
    var requestRecommendedProducts = false
    
    func setRecommendedProducts() {
        DispatchQueue.main.async {
                                                            
            if self.recommendedItems.count > 0 {
                self.MainTableView.reloadSections(IndexSet(integer: self.displayItemList.count-1), with: .none)
            }else{
                LogUtil.shared.log("restIitemParents is empty")
            }
            self.MainTableView.endUpdates()
        }
            
        for  itemP in self.restIitemParents {
            if let _ = itemP.item {
                OrosyAPI.cacheImage(itemP.imageUrls.first, imagesize: .Size100)
            }
        }
    }
    

    var imageUrls:[URL]?
   
    
    var productTitle:UILabel!
    var quantityButton:UIButton!        // 数量選択ボタン
    var addCartButton:OrosyButton!         // カート追加ボタン
    var variation1Label:UILabel!
    var variation2Label:UILabel!
    
    var variationButton1:UIButton!
    var variationButton2:UIButton!
    
    var connectionStatus:ConnectionStatus? = nil
    
    var mainImageView:OrosyUIImageView!
    var imageSampleCollectionView: UICollectionView!
    var allProductsCollectionView: UICollectionView!
    var recommendedProductsCollectionView: UICollectionView!
    var selectedImageRow = 0

    var selectedSetQty = 0          // 選択したセット数量
    var selectedQuantity = 0        // 選択した数量
    var selectedSaleType:SaleType = .WholeSale    // 選択した仕入れ形式

    var pageConroller:OrosyPageContorl!
    var favoriteButton:IndexedButton!
    
    var initialOrderPointCampaign:Bool = false      // 初回購入ポイントキャンペーン
    
    func getItemidForPageUrl() -> String {
        return itemParent.id
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.setNaviTitle(title: "")   // 選択している商品名をタイトルに表示
        LogUtil.shared.log("Start viewDidLoad")
        
        self.setNaviTitle(title: self.selectedItem?.title ?? "")   // 選択している商品名をタイトルに表示
        self.setDisplayData()

        
        if #available(iOS 15.0, *) {
            MainTableView.sectionHeaderTopPadding = 0.0
         }

        // 商品タイトル画像をキャッシュへ入れておく
        if let urls = imageUrls {
            var row = 0
            DispatchQueue.global().async {
                for url in urls {
                    OrosyAPI.cacheImage(url, imagesize: .Size500)
                    row += 1
                }
            }
        }
                
        
        if let config = AppConfigData.shared.config {
            initialOrderPointCampaign = config["InitialOrderPointCampaign"] as? Bool ?? false
        }

            
        self.MainTableView.reloadData()

        if  self.requestRestPRoducts {
            setRestProducts()
        }
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(favoriteReset), name: Notification.Name(rawValue:NotificationMessage.FavoriteReset.rawValue), object: nil)
        nc.addObserver(self, selector: #selector(refreshStatus), name: Notification.Name(rawValue:NotificationMessage.RefreshApplyStatus.rawValue), object: nil)
        nc.addObserver(self, selector: #selector(reset), name: Notification.Name(rawValue:NotificationMessage.Reset.rawValue), object: nil)
        LogUtil.shared.log("End viewDidLoad")
    }
    
    
    func getRestProduct() {
        
        LogUtil.shared.log("Start getRestProduct")
        
        if !supplier.hasAllItemParents {
            _ = supplier.getNextSupplierItemParents()   // サプライヤ画面では表示したところまでしか読み込んでいないので、残りを取得する必要がある。
        }
        
        var tempArray:[ItemParent] = []
        
        for itemp in self.supplier.itemParents {
            if itemp.id != self.itemParent.id {
                tempArray.append(itemp)
            }
        }
        self.restIitemParents = tempArray
     
    }
    
    
    @objc func reset() {
        DispatchQueue.main.async{
            self.navigationController?.popToRootViewController(animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setDisplayData() {
        
        var sectionDic:[String:Any]!
        var rowData:[ProductDisplayItem] = []
        
        if selectedItem == nil {
            return
        }
        // 基本情報
        if selectedItem.precaution != nil || selectedItem.tax != 0 {
            rowData.append( ProductDisplayItem(type: .SECTION_TITLE, title: "基本情報", cell:"SectionCell", height:-1, expand:false ) )
        }
        if selectedItem.item_description != nil {
            rowData.append( ProductDisplayItem(type: .DETAIL, title: "商品の説明", cell:"InfoCell", height:-1, expand:false ) )
        }
        if selectedItem.size != nil {
            rowData.append( ProductDisplayItem(type: .SIZE, title: "サイズ＆重量", cell:"InfoCell", height:-1 , expand:false) )
        }
        if selectedItem.specification != nil {
            rowData.append( ProductDisplayItem(type: .SPECIFICATION, title: "規格（製造国、原材料など）", cell:"InfoCell", height:-1 , expand:false) )
        }
        if selectedItem.ecUrl != nil {
            rowData.append( ProductDisplayItem(type: .URL, title: "ECサイトURL", cell:"InfoCell", height:-1 , expand:false) )
        }
        
        
        sectionDic = ["SECTION_TITLE": "基本情報",
                                   "EXPAND" : true,
                                   "ROW_DATA": rowData
                                ]
        displayItemList.removeAll()
        displayItemList.append(contentsOf: displayItemList_base)
        displayItemList.append(sectionDic)
    
        // 仕入情報
        rowData = []
      //  if selectedItem.precaution != nil || item.tax != 0 {
            rowData.append( ProductDisplayItem(type: .SECTION_TITLE, title: "仕入情報", cell:"SectionCell", height:-1, expand:false ) )
     //   }
        if  selectedItem.requirement != nil {
            rowData.append( ProductDisplayItem(type: .REQUIREMENT, title: "販売条件・返品条件", cell:"InfoCell", height:-1, expand:false ) )
        }
        if selectedItem.precaution != nil {
            rowData.append( ProductDisplayItem(type: .PRECAUTION, title: "注意事項,出荷条件など", cell:"InfoCell", height:-1 , expand:false) )
        }
        //if selectedItem.isPl != nil {
            rowData.append( ProductDisplayItem(type: .PL, title: "PL保険、販促物の有無", cell:"PL_CELL", height:-1 , expand:false) )
       // }

        sectionDic = ["SECTION_TITLE": "基本情報",
                                   "EXPAND" : true,
                                   "ROW_DATA": rowData
                                ]

        displayItemList.append(sectionDic)

        let brandDic = ["SECTION_TITLE": "同じブランドの商品",
                        "ROW_DATA": [
                            ProductDisplayItem(type: .SECTION_TITLE, title: "同じブランドの商品", cell:"SectionCell", height:80, expand:false ),
                            ProductDisplayItem(type: .PRODUCTS, title: "", cell:"ProductCell", height:-1 , expand:false)
                        ]
        ] as [String : Any]
        
        LogUtil.shared.log("Ready Table update in getRestProduct")
        
        self.displayItemList.append(brandDic)
        let recommendDic = ["SECTION_TITLE": "おすすめの商品",
                            "ROW_DATA": [
                                ProductDisplayItem(type: .SECTION_TITLE, title: "おすすめの商品", cell:"SectionCell", height:80, expand:false ),
                                ProductDisplayItem(type: .RECOMMEND, title: "", cell:"RecommendCell", height:-1 , expand:false)
                            ]
        ] as [String : Any]
        

        self.displayItemList.append(recommendDic)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return displayItemList.count
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var count = 0
        if selectedItem == nil { return 0 }
        
        let itemDic = displayItemList[section]
        let items = itemDic["ROW_DATA"] as! [ProductDisplayItem]
        
        if items.count == 0 { return 0 }
        let itemType = items.first!.itemType
        
        switch itemType {
        case .VARIATION:
            count = 1
            if selectedItem.variation1Label != nil { count += 1 }
            if selectedItem.variation2Label != nil { count += 1 }

        default:
            count = items.count
        }
        
        return count
    }
    
    let defaultHeightForInfoCell:CGFloat = 54
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = indexPath.row
        let section = indexPath.section
        var height:CGFloat = 44
        
        let itemDic = displayItemList[section]
        let items = itemDic["ROW_DATA"] as! [ProductDisplayItem]
        let displayItem = items[row]
        
        if displayItem.itemType == .POINT_CAMPAIGN {
            if !initialOrderPointCampaign { return 0 }      // キャンペーンが無効なら表示しない
            return (connectionStatus == .ACCEPTED &&  !self.orderedCheck) ? UITableView.automaticDimension : 0
            
        }else if displayItem.itemType == .CARTBUTTON {
            
            return UITableView.automaticDimension
            
        }else if displayItem.itemType == .PRODUCTS {
            if self.requestRestPRoducts && restIitemParents.count == 0 {    // 取得済なのにゼロ件の場合には非表示にする
                return 0
            }else{
                return UITableView.automaticDimension
            }
        }
            
        if  itemDic["SECTION_TITLE"] as? String == "ProductImage" {
            height = self.view.bounds.width * PRODUCT_IMAGE_SIZE_RATE
            if height > MAX_IMAGE_WIDTH { height = MAX_IMAGE_WIDTH }
            height = height + 20 + 20 + 28 // 28とは別に、セルの周りのスペースとして20空く
            
        }else
        if let _ = itemDic["EXPAND"] as? Bool {

            if displayItem.itemType == .PL {
                height = (displayItem.expand) ? UITableView.automaticDimension : 40
            }else{
                height = (displayItem.expand) ? UITableView.automaticDimension : defaultHeightForInfoCell
            }

        }else{
            
            if displayItem.itemHeight == -1 {
                height = UITableView.automaticDimension
            }else{
                height = displayItem.itemHeight
            }
        }
        
        return height
    }
    

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        let section = indexPath.section

        let itemDic = displayItemList[section]
        let displayItems = itemDic["ROW_DATA"] as! [ProductDisplayItem]
        let displayItem = displayItems[row]
        
        let cellType = displayItem.cellType!

        let cell = tableView.dequeueReusableCell(withIdentifier: cellType, for: indexPath)

        var titleLabel:UILabel!
        var content:UILabel!
        var openCloseButton:IndexedButton!
        var openCloseIndicateButton:IndexedButton!
        
        
        if let _ = itemDic["EXPAND"] as? Bool {
            titleLabel = cell.contentView.viewWithTag(1) as? UILabel
            content = cell.contentView.viewWithTag(2) as? UILabel
            if content != nil {
                content.textColor = UIColor.orosyColor(color: .Black600)
            }
            openCloseIndicateButton = cell.contentView.viewWithTag(10) as? IndexedButton
            openCloseButton = cell.contentView.viewWithTag(11) as? IndexedButton
            if let _ = openCloseButton {
                openCloseButton.indexPath = indexPath
                openCloseButton.cell = cell
            }
        }
        
        var contentButton:IndexedButton? = nil
        if cellType == "InfoCell" {
            contentButton = cell.viewWithTag(20) as? IndexedButton
            contentButton?.indexPath = nil
        }
        
        switch displayItem.itemType {
        case .IMAGE: // 商品画像
            imageSampleCollectionView = cell.contentView.viewWithTag(1) as? UICollectionView
             updateLayoutForTitle()
            
            imageSampleCollectionView?.reloadData()
            
            favoriteButton = cell.contentView.viewWithTag(2) as? IndexedButton
            favoriteButton.indexPath = indexPath
            favoriteButton.selectedItemParent = itemParent
            favoriteButton.baseView = tableView
            favoriteButton.isSelected = itemParent.isFavorite
            
            pageConroller = cell.contentView.viewWithTag(10) as? OrosyPageContorl
            
            if let urls = imageUrls {
                if urls.count == 0 {
                    pageConroller.isHidden = true
                }else{
                    pageConroller.isHidden = false
                    pageConroller.numberOfPages = urls.count
                }
            }
            imageSampleCollectionView?.decelerationRate = .fast
            
        case .TITLE:

            // ブランド名
            let title1 = cell.contentView.viewWithTag(1) as! UILabel
            title1.text = supplier?.brandName
            // 商品名
            productTitle = cell.contentView.viewWithTag(2) as? UILabel
            productTitle.text = selectedItem.title
            //商品コード
            let title3 = cell.contentView.viewWithTag(3) as! UILabel
            title3.text = "品番:\(selectedItem.productNumber ?? "")"
            // JANコード
            let jancode = cell.contentView.viewWithTag(4) as! UILabel
            jancode.text = "JANコード:\(selectedItem.jancode ?? "")"
            
        case .PRICE:
            let title = cell.contentView.viewWithTag(1) as! UILabel
            let title2 = cell.contentView.viewWithTag(2) as! UILabel
            let title3 = cell.contentView.viewWithTag(3) as! UILabel
            title3.isHidden = true
            title2.textColor = UIColor.orosyColor(color: .Black600)
            let lockIcon = cell.contentView.viewWithTag(4) as! UIImageView

            if row == 0 {
                title.text = "上代単価（税抜）"
                title2.text = Util.number2Str(selectedItem.catalogPrice)
                lockIcon.isHidden = true
            }else if row == 1 {
                title.text = "卸価格（税抜）"
                
                if connectionStatus == .ACCEPTED {
                    title2.isHidden = false
                    title3.isHidden = true
                    lockIcon.isHidden = true

                    let price = selectedItem.wholesalePrice
                    let isWholesale = selectedItem.isWholesale
                    if isWholesale  && (price.compare( NSDecimalNumber.zero) == ComparisonResult.orderedDescending)  {
                        title2.text = Util.number2Str(price)
                    }else{
                        title2.text = "-"
                    }
                }else{
                    title2.isHidden = true
                    title3.isHidden = false
                    title3.text = NSLocalizedString("ConnectionMessage", comment: "")
                    title3.textColor = UIColor.orosyColor(color: .Gray400)
                    lockIcon.isHidden = false
                }

            }else{
                title.text = "消費税率"
                title2.text = "\(selectedItem?.tax ?? 0) %"
                lockIcon.isHidden = true
            }
            
        case .VARIATION:
            let titleLabel = cell.contentView.viewWithTag(1) as! UILabel
            let buttonTitle = cell.contentView.viewWithTag(2) as! UILabel
            let setButton = cell.contentView.viewWithTag(3) as! UIButton
            
            switch row {

            case 0:
                // セット数
                titleLabel.text = "セット"
                if itemParent == nil {
                    buttonTitle.text = String(selectedItem.setQty)
                }else{
                    setSetButtonMenu(menuButton: setButton)
                }
            case 1:
                // バリエーション1
                variation1Label = cell.contentView.viewWithTag(1) as? UILabel
                variation1Label.text = selectedItem.variation1Label
                variationButton1 = cell.contentView.viewWithTag(3) as? UIButton
                setVariationButtonMenu(index: 1)
                
            case 2:
                // バリエーション2
                variation2Label = cell.contentView.viewWithTag(1) as? UILabel
                variation2Label.text = selectedItem.variation2Label
                variationButton2 = cell.contentView.viewWithTag(3) as? UIButton
                setVariationButtonMenu(index: 2)
                
            default:
                break
            }

        case .CARTBUTTON:  // カートへ入れるボタン
           // let msgLabel = cell.contentView.viewWithTag(1) as! UILabel
          //  let numberLabel = cell.contentView.viewWithTag(2) as! UILabel
            let mimLots = cell.contentView.viewWithTag(3) as! UILabel
           // let openIcon = cell.contentView.viewWithTag(4) as! UIButton

            let buttonView = cell.contentView.viewWithTag(102)!
            let activityIndicator = buttonView.viewWithTag(2) as? UIActivityIndicatorView
            addCartButton = buttonView.viewWithTag(1) as? OrosyButton
            addCartButton.titleEdgeInsets = UIEdgeInsets(top: 7.0, left: 0.0, bottom: 0.0, right: 0.0)  //
            addCartButton.indexPath = indexPath
            addCartButton.activityIndicator = activityIndicator
            quantityButton = cell.contentView.viewWithTag(11) as? UIButton       // 数量設定メニュー
            let lot = cell.contentView.viewWithTag(100)!
            let comapign = cell.contentView.viewWithTag(101)!
            refreshQuantityButton(item:selectedItem)
            
            if connectionStatus == .ACCEPTED {
                comapign.isHidden = true
                lot.isHidden = false
                mimLots.text = "最小ロット：\(selectedItem.minLotQty)"
                quantityButton.isEnabled = true
            }else if connectionStatus == .REQUEST_PENDING {
                comapign.isHidden = true
                lot.isHidden = true
                quantityButton.isEnabled = false
            }else{
                comapign.isHidden = !initialOrderPointCampaign     // キャンペーンが有効なら表示
                lot.isHidden = true
                quantityButton.isEnabled = true
            }
 
            setAddCartButtonTitle(cell)
        
        case .SECTION_TITLE:
            titleLabel = cell.contentView.viewWithTag(1) as? UILabel
            titleLabel.text = displayItem.title
            
        case .PRECAUTION:
            titleLabel.text = displayItem.title
            content.text = selectedItem!.precaution
            openCloseIndicateButton.isHidden = (selectedItem!.precaution == nil) ? true : false
            
        case .TAX:
            titleLabel.text = displayItem.title
            content.text = "\(selectedItem.tax) %"
            openCloseButton.height = content.frame.size.height
   
        case .DETAIL:
            titleLabel.text = displayItem.title
            content.text = selectedItem.item_description
            openCloseButton.height = content.frame.size.height
            
        case .OTHERS:
            titleLabel.text = displayItem.title
            content.text = selectedItem.specification
            openCloseButton.height = content.frame.size.height
            
        case .SIZE:
            titleLabel.text = displayItem.title
            content.text = selectedItem.size
            openCloseButton.height = content.frame.size.height

        case .PL:
            titleLabel.text = displayItem.title
            let plButton = cell.viewWithTag(11) as! UIButton
            plButton.isSelected = selectedItem.isPl
            
            let hansokuButton = cell.viewWithTag(12) as! UIButton
            let exp = selectedItem.explanation ?? ""
            hansokuButton.isSelected = exp.count > 0
            content.text = exp
            
        case .MATERIAL:
            titleLabel.text = displayItem.title
            content.text = selectedItem.explanation
            openCloseButton.height = content.frame.size.height

        case .PRODUCTS:
            allProductsCollectionView = cell.viewWithTag(1) as? UICollectionView
            //allProductsCollectionView.reloadData()
            
        case .RECOMMEND:
            recommendedProductsCollectionView = cell.viewWithTag(1) as? UICollectionView
            //recommendedProductsCollectionView.reloadData()
            
        case .URL:
            titleLabel.text = displayItem.title
            content.text = selectedItem.ecUrl?.absoluteString ?? ""
            content.textColor = UIColor.orosyColor(color: .Blue)
            if let button = contentButton {
                button.indexPath = indexPath // 反応させる場合だけセットする
            }
            
        case .SPECIFICATION:
            titleLabel.text = displayItem.title
            content.text = selectedItem.specification ?? ""
        case .CODITIONS:
            titleLabel.text = displayItem.title
          //  content.text = selectedItem.conditions ?? ""
        case .REQUIREMENT:
            titleLabel.text = displayItem.title
            content.text = selectedItem.requirement ?? ""
        case .POINT_CAMPAIGN:
            let titleLabel = cell.contentView.viewWithTag(1) as! UILabel
            titleLabel.text = displayItem.title
            let pointLabel = cell.contentView.viewWithTag(3) as! UILabel
            //let campaignLabel = cell.contentView.viewWithTag(4) as! UILabel
            var point = round(selectedItem.wholesalePrice.doubleValue * 0.2)        // ここでは購入数量と関係なく算出
            if point > 10000 { point = 10000 }
            
            pointLabel.text = "+" + Util.number2Str(NSNumber(value:point), withUnit: false) + "pt"
            //campaignLabel.text = "初回20%ポイント還元＋返品可能"
         default:
           break
        }
        
        return cell
    }
    
 
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        
    }
    
    func checkInventoryNumber() -> Bool {
        var restQuantity:Int = selectedItem.inventoryQty    // 選択している商品の在庫数
        
        restQuantity = restQuantity - getCartQuantity(item_id: selectedItem.id)  // カートに入っている数量を引く
        
        return (restQuantity >= selectedItem.minLotQty )
    }
    
    //  MARK: カート
    func setAddCartButtonTitle(_ cell:UITableViewCell) {

        var buttonTitle = ""
        var fontSize:CGFloat
       // quantityButton.isHidden = true
        
        if itemParent == nil {
        addCartButton.isHidden = true
            
        }else{
            addCartButton.isHidden = false
           // quantityButton.isHidden = false
        
            fontSize = 15
            
            if connectionStatus == .ACCEPTED {
                fontSize = 15
                if checkInventoryNumber() {   // 購入できるだけの在庫があるかチェック
                    addCartButton.isEnabled = true
                    buttonTitle = NSLocalizedString("AddToCart", comment: "")
                }else{
                    addCartButton.isEnabled = false
                    buttonTitle = NSLocalizedString("OutOfStock", comment: "")
                }
             //   addCartButton.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 80).isActive = true
                
            }else if connectionStatus == .REQUEST_PENDING || connectionStatus == .REQUESTED {
              //  quantityButton.isHidden = true
                buttonTitle = "申請中"
                fontSize = 15
                addCartButton.isEnabled = false
             //   addCartButton.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 30).isActive = true
            }else{
                buttonTitle = NSLocalizedString("ShowHolesalePrice", comment: "")
                addCartButton.isEnabled = true
            //    addCartButton.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 30).isActive = true
            }

            addCartButton.setButtonTitle(title: buttonTitle, fontSize: fontSize)
            
        }
    }
    
    @IBAction func showCampaignHelp(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ModalVC") as! ModalVC
        self.present(vc, animated: true)
    }
    

    
    //　カートへ入れる、取引許可申込画面表示
    // addCart
    var cartAdding = false
    @IBAction func applyAccept(_ sender: IndexedButton) {
        
        if !g_loginMode {
            let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "VerifyEmailVC") as! VerifyEmailVC
            vc.displayMode = .requestLogin
            present(vc, animated: true, completion: nil)

            return
        }
        
        if selectedQuantity == 0 {
            return
        }
        
        if connectionStatus == .ACCEPTED {
            if !cartAdding {
                
                DispatchQueue.main.async {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
                
                cartAdding = true
                
                var restQuantity:Int = selectedItem.inventoryQty    // 選択している商品の在庫数
                
                // すでにカートに入っている数量を調べる
                restQuantity = restQuantity - (selectedQuantity + getCartQuantity(item_id: selectedItem.id))    // 現在個数から　カートに入っている数量と今回カートへ追加しようとしている数量を引く
                //　カートに同じ商品がある場合は、合算して在庫数チェックする
                if  restQuantity < 0 {
                        
                    let dialog =  SmoothDialog()
                    self.view.addSubview(dialog)
                    dialog.show(message: NSLocalizedString("NotEnoughInventory", comment: ""))
                    //activityIndicator.stopAnimating()
                    cartAdding = false
                    
                    return
                }
  
                // 在庫数を超えていなければカートへ追加
                self.activityIndicator = sender.activityIndicator
                self.activityIndicator.startAnimating()
                
                let rectInTableView = MainTableView.rectForRow(at: sender.indexPath!)
                let rectInSuperview = MainTableView.convert(rectInTableView, to: self.view)
                                            
                // 選択中の商品をカートへ追加
                DispatchQueue.global().async {
                    let result = self.selectedItem?.addCart(quantity: self.selectedQuantity, saleType: self.selectedSaleType)
                    g_cartUpdated = true
                    LogUtil.shared.log ("カートへ追加")
                    
                    var message:String!
                    var failure = false
                    
                    switch result {
                    case .success(_):
                        // message = "商品がカートに追加されました"
                        
                        let result = Cart().updateCart()    // カート情報を更新
                        
                        switch result {
                        case .success(let cart):

                            g_cart = cart
                            DispatchQueue.main.async {
                                // カートへ追加した分、在庫数が減るので、数量ボタンも更新する
                                self.refreshQuantityButton(item:self.selectedItem)

                                self.activityIndicator.stopAnimating()
                                self.cartAdding = false
                            }
                            
                            g_userLog.addCart(itemId: self.selectedItem.id, pageUrl: self.orosyNavigationController?.currentUrl ?? "", count:self.selectedQuantity)
                            
                        case .failure(let error):
                            message = error.localizedDescription
                            failure = true
                        }
                        
                    case .failure(_):
                        message = "エラーになりました"
                        failure = true
                    case .none:
                        break;
                    }
     
                    if failure {
                        
                        DispatchQueue.main.sync {
                            // エラーになった場合
                            var lowerPointY = rectInSuperview.origin.y + rectInTableView.size.height
                            print( self.view.bounds.height )
                            
                            if lowerPointY < self.view.bounds.height  - 100 {
                               // lowerPointY = lowerPointY
                            }else{
                                lowerPointY = rectInSuperview.origin.y
                            }

                            let dialog =  SmoothDialog()
                            self.view.addSubview(dialog)
                            dialog.show(message: message, pointY: lowerPointY)
                            self.activityIndicator.stopAnimating()
                        }
                        
                    }else{
                        // 成功した場合
                        
                        DispatchQueue.main.async {
                            let frame = self.cartInMessageView.frame
                            self.cartInMessageView.bringSubviewToFront(self.view)
                            self.cartInMessageView.alpha = 0
                            UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseOut],  animations: {
                                self.cartInMessageView.alpha = 1
                            }, completion: { (finished: Bool) in
                                UIView.animate(withDuration: 0.3, delay: 1.5, options: [.curveEaseOut], animations: {
                                    self.cartInMessageView.alpha = 0
                                }, completion: { (finished: Bool) in

                                })
                            })
                        }
                    }
                }
            }
            
        }else{
            
            //if ProfileDetail.shared.profileRetailerRegistered  {
            if UserDefaultsManager.shared.accountStatus == .AccountProfiled {
                // 申請画面へ遷移
                let storyboard = UIStoryboard(name: "AlertSB", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "ApplyConnection") as! ApplyCoonectionVC
                vc.navigationItem.leftItemsSupplementBackButton = true
                vc.supplier = supplier
                vc.orosyNavigationController = self.orosyNavigationController
                
                self.present(vc, animated: true, completion: nil)
                
                let targetUrl = self.orosyNavigationController?.getNewTargetUrl(vc) ?? ""
                self.orosyNavigationController?.sendAccessLog(modal:true, targetUrl:targetUrl)

            }else{
                      
                // プロフィールの入力を促す
                showCheckProfileVC()
                
            }
        }
    }

    func getCartQuantity(item_id: String) -> Int{
        var cartQuantity = 0
        if g_cart != nil {
            if let cartItem = g_cart.getCartItem(item_id: item_id) {
                cartQuantity = cartItem.quantity
            }
        }
        return cartQuantity
    }
    
    func refreshQuantityButton(item:Item) {
        var restQuantity:Int = item.inventoryQty                // 選択している商品の在庫数
        
        // すでにカートに入っている数量を調べる
        restQuantity = restQuantity - getCartQuantity(item_id: item.id)    // 現在個数から　カートに入っている数量と今回カートへ追加しようとしている数量を引く
        
        if self.quantityButton != nil {
            self.setUnitButtonMenu(menuButton: self.quantityButton,current: selectedItem.minLotQty, min:selectedItem.minLotQty, max:restQuantity)
        }
    }
    
    //　折り畳み表示
    @IBAction func openInfoButton(_ button: IndexedButton) {

        if let indexPath = button.indexPath {
         
            let section = indexPath.section
            let row = indexPath.row
            
            let itemDic = displayItemList[section]
            
            let displayItems = itemDic["ROW_DATA"] as! [ProductDisplayItem]
            let displayItem = displayItems[row]
            displayItem.expand = !displayItem.expand
  
            let cell = button.cell
            let openCloseButton = cell?.viewWithTag(10) as! UIButton
            openCloseButton.isSelected = displayItem.expand
            var contentLength = (cell?.viewWithTag(2) as! UILabel).text?.count ?? 0
            if contentLength < 150 { contentLength = 150 }
            if contentLength > 600 { contentLength = 600 }
 
            DispatchQueue.main.async {
                
                UIView.animate(withDuration: TimeInterval(Double(contentLength) / 1200.0) , // アニメーションの秒数
                                    delay: 0.0, // アニメーションが開始するまでの秒数
                                   options: [.curveEaseOut], // アニメーションのオプション 等速 | 繰り返し
                                   animations: {
                    
                    self.MainTableView.beginUpdates()
                    /*
                        //　画面幅に応じて画像の高さが変わるため、画面幅から高さを算出　　->　この時点ではまだ、オブジェクトのサイズは変化していないので、アニメーションは意味がない
                        var frame = cell!.frame
                        frame.size.height = height
                        cell!.frame = frame
                     */
                    self.MainTableView.endUpdates()
                    
                    }, completion: { (finished: Bool) in

                    })
            }
        }
    }
    
    // MARK: 商品画像サンプル一覧
    let CELL_HEIGHT_NEWER:CGFloat = 164
    // セルのサイズをセット
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        var size:CGSize!
        
        if collectionView == imageSampleCollectionView {
            
            var width = self.view.bounds.width * PRODUCT_IMAGE_SIZE_RATE
            if width > MAX_IMAGE_WIDTH { width = MAX_IMAGE_WIDTH }
            size = CGSize(width: width, height: width)
            
        }else{
            size = CGSize(width: 110, height: CELL_HEIGHT_NEWER)
        }
        
        return size
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {

        guard
            let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout,
            case let numItems = collectionView.numberOfItems(inSection: section), numItems > 0
        else {
            return .zero
        }

        //1セクション分の表示幅の計算(セルを可変サイズにする場合などは要修正)
        let minSpacing = flowLayout.minimumInteritemSpacing
        let itemWidth = flowLayout.itemSize.width
        let minSectionWidth = itemWidth * CGFloat(numItems) + minSpacing * CGFloat(numItems-1)

        //CollectionViewのコンテンツ領域の幅の計算
        let contentWidth = collectionView.frame.size.width - collectionView.contentInset.left - collectionView.contentInset.right

        //デフォルトのInsetsの取得
        var insets = flowLayout.sectionInset
        //セクションの表示幅がコンテンツ領域より小さい時には余白を計算
        if minSectionWidth < contentWidth {
            let paddingWidth = (contentWidth - minSectionWidth)/2
            insets.left = paddingWidth
            insets.right = paddingWidth
        }
        return insets
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        
        if collectionView == imageSampleCollectionView {
            count = imageUrls?.count ?? 0
        }else if collectionView == allProductsCollectionView {
            count = restIitemParents.count
        }else if collectionView == recommendedProductsCollectionView {
            count = recommendedItems.count
        }
        
        return count
    }
    

    // トップの商品画像を表示しているCollectionViewのスタイル設定
    private func updateLayoutForTitle() {
        let layout = CarouselCollectionViewFlowLayout()
       // let collectionViewSize = imageSampleCollectionView.frame.size
        let cellInsets = UIEdgeInsets(top: 0.0, left: OrosyCollectionViewCell.widthInset, bottom: 0.0, right: OrosyCollectionViewCell.widthInset)
        
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 10
        layout.sectionInset = cellInsets
        var layoutWidth = self.view.bounds.width * PRODUCT_IMAGE_SIZE_RATE
        if layoutWidth > MAX_IMAGE_WIDTH { layoutWidth = MAX_IMAGE_WIDTH }
        
        let layoutHeight = layoutWidth
        layout.itemSize = CGSize(width: layoutWidth, height: layoutHeight)
        imageSampleCollectionView.collectionViewLayout = layout
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let row = indexPath.row
        var cell:UICollectionViewCell!
        
        if collectionView == imageSampleCollectionView {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath)
                
            let imageView = cell.contentView.viewWithTag(1) as! OrosyUIImageView500
            imageView.image = nil
            imageView.targetRow = row
            if let urls = imageUrls {
                imageView.getImageFromUrl(row: row, url: urls[row])
            }else{
                print("check")
            }
            imageView.drawBorder(cornerRadius: 0)
            /*
            if row == 0 {
                for url in imageUrls {
                    if url != imageUrls.first {
                        OrosyAPI.cacheImage(url, imagesize: .Size500)
                    }
                }
            }
             */
            
        }else if collectionView == allProductsCollectionView || collectionView == recommendedProductsCollectionView {
           
            // 同じブランドの商品一覧
            collectionView.register(UINib(nibName: "CommonCollectionSB", bundle: nil), forCellWithReuseIdentifier: "ProductCell")
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCell", for: indexPath)

            let imageView = cell.contentView.viewWithTag(1) as! OrosyUIImageView200
            let title = cell.contentView.viewWithTag(2) as! UILabel
            let catarogPrice = cell.contentView.viewWithTag(3) as! UILabel
            let priceLabel = cell.contentView.viewWithTag(4) as! UILabel
            let showShopPage = cell.contentView.viewWithTag(5) as! UILabel
 
            imageView.targetRow = row
 
            var itemParent:ItemParent!
            
            if collectionView == allProductsCollectionView { itemParent = restIitemParents[row] }
            if collectionView == recommendedProductsCollectionView { itemParent = recommendedItems[row] }

            let favoriteButton = cell.contentView.viewWithTag(10) as! IndexedButton
            favoriteButton.baseView = collectionView
            favoriteButton.indexPath = indexPath
            favoriteButton.selectedItemParent = itemParent
          
            imageView.image = nil
            
            imageView.getImageFromUrl(row: row, url: itemParent.imageUrls.first, defaultUIImage: g_defaultImage)
            imageView.drawBorder(cornerRadius: 4)
            
            title.text = itemParent.item?.title ?? ""
            catarogPrice.text = Util.number2Str(selectedItem.catalogPrice)
            priceLabel.isHidden = false
     
            showShopPage.text = ""
            
            priceLabel.isHidden = false
            favoriteButton.isSelected = itemParent.isFavorite
            favoriteButton.isHidden = false
            favoriteButton.addTarget(self, action:  #selector(favoriteButtonPushed(_:)), for: .touchUpInside)
            favoriteButton.indexPath = indexPath
        }

        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = indexPath.row

        let cell = collectionView.cellForItem(at: indexPath)
        let waitIndicator = cell?.viewWithTag(110) as? UIActivityIndicatorView
        DispatchQueue.main.async {
            waitIndicator?.startAnimating()
        }
        
        if collectionView == allProductsCollectionView  || collectionView == recommendedProductsCollectionView {
            
            DispatchQueue.global().async {
                if collectionView == self.allProductsCollectionView { self.itemParent = self.restIitemParents[row] }
                if collectionView == self.recommendedProductsCollectionView { self.itemParent = self.recommendedItems[row] }
                
                var vc_supplier:Supplier!
                
                if self.supplier == nil || collectionView == self.recommendedProductsCollectionView {
                    vc_supplier =  self.itemParent.supplier         // お気に入りの場合には、商品毎にサプライヤーが異なるのでこちらで指定する
                    _ = vc_supplier.getNextSupplierItemParents()
                     
                }else{
                    vc_supplier = self.supplier          // これを先に指定しておく必要がある
                }
                
                DispatchQueue.main.async {

                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "ProductDetailVC") as! ProductDetailVC
                    vc.navigationItem.leftItemsSupplementBackButton = true
                    vc.supplier = vc_supplier
                    vc.connectionStatus = self.supplier?.connectionStatus
                    vc.itemParent = self.itemParent
                    vc.selectedItem = self.itemParent?.item
                    //vc.itemParent_id = self.selectedItem.id

                    self.orosyNavigationController?.pushViewController(vc, animated: true)
                    waitIndicator?.stopAnimating()
                }
            }
        }
    }
    

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
 
        let scrollPosY = scrollView.contentOffset.y //スクロール位置
        let maxOffsetY = scrollView.contentSize.height - scrollView.frame.size.height //スクロール領域の高さからスクロール画面の高さを引いた値
        let distanceToBottom = maxOffsetY - scrollPosY //スクロール領域下部までの距離

        if scrollView == allProductsCollectionView {
            
            if distanceToBottom < 300  {
                
                if !supplier.hasAllItemParents {
                    _ = supplier.getNextSupplierItemParents()   // サプライヤ画面では表示したところまでしか読み込んでいないので、残りを取得する必要がある。
                }
            }
            
            /*
           //スクロール領域下部に近づいたら追加で取得する
           if distanceToBottom < 300  {
             
               if !supplier.hasAllItemParents {
                   _ = supplier.getNextSupplierItemParents()
                   getRestItemParents()
                   
                   if self.restIitemParents.count > 0 {
                       let brandDic = ["SECTION_TITLE": "同じブランドの商品",
                           "ROW_DATA": [
                               ProductDisplayItem(type: .SECTION_TITLE, title: "同じブランドの商品", cell:"SectionCell", height:80, expand:false ),
                               ProductDisplayItem(type: .PRODUCTS, title: "", cell:"ProductCell", height:-1 , expand:false)
                           ]
                       ] as [String : Any]
                       
                       
                       DispatchQueue.main.async {
                           self.displayItemList.append(brandDic)
                           self.MainTableView.beginUpdates()
                           self.MainTableView.insertSections(IndexSet(integer: 7), with: .none)    // セクションを追加
                           self.MainTableView.endUpdates()
                           
                       }
                       
                       for  itemParent in self.restIitemParents {
                           if let _ = itemParent.item {
                               OrosyAPI.cacheImage(itemParent.imageUrls.first, imagesize: .Size100)
                           }
                       }
                   }
                   allProductsCollectionView.reloadData()
              
               }
               
           }
               */
        }else if scrollView == imageSampleCollectionView {
            decidePage(scrollView)
        }
    }

    // トップの画像一覧のページ番号を求める
    func decidePage(_ scrollView: UIScrollView) {
        
        var visibleRect = CGRect()

        if let collectionView = scrollView as? UICollectionView {
            visibleRect.origin = collectionView.contentOffset
            visibleRect.size = collectionView.bounds.size

            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            print("visiblePoint:\(visiblePoint)")
                  
            guard let indexPath = collectionView.indexPathForItem(at: visiblePoint) else { return }

            pageConroller.currentPage = indexPath.row
        }
    }
    
    @IBAction func pageChanged(_ sender: OrosyPageContorl) {
        
        let row = sender.currentPage
        sender.setDots(index: row)
        imageSampleCollectionView.scrollToItem(at: IndexPath(row:row,section:0), at: .left, animated: true)
    }
    
    // セットの選択ボタン
    func setSetButtonMenu(menuButton: UIButton) {

        //メニュー項目をセット
        var actions = [UIMenuElement]()
        
        // 重複を取り除く
        var uniqueItems:[Item] = []
        //var preValue:Int = -1
        
        for item in itemParent.variationItems {
  
           // if item.isWholesale || item.isConsignment {
            var find = false
            for pre_item in uniqueItems {

                if pre_item.setQty == item.setQty {
                    find = true
                    break
                }
            }
            if !find {
                uniqueItems.append(item)
            }
        }

        // ソート
        let sortedItems = uniqueItems.sorted(by: { (a, b) -> Bool in

            return a.setQty < b.setQty

        })
        
        if selectedItem == nil {
            selectedItem = uniqueItems.first
        }
        
        for item in sortedItems {

            actions.append(UIAction(title: String(item.setQty) + "個", image: nil, state: item == selectedItem ? .on : .off, handler: { (_) in

                self.selectedSetQty = item.setQty
                menuButton.setTitle(String(self.selectedSetQty) + "個", for: .normal)

                //セットを変更するとバリエーションも変わる
                //  self.MainTableView.reloadRows(at: [IndexPath(row:6, section:0), IndexPath(row:8, section:0)], with: .none)
                self.selectedItem = item
                
                self.setDisplayData()
                self.MainTableView.reloadData()
            }))
        }

        if actions.count > 0 {
            // UIButtonにUIMenuを設定
            menuButton.menu = UIMenu(title:"" , options: .displayInline, children: actions)
            // こちらを書かないと表示できない場合があるので注意
            menuButton.showsMenuAsPrimaryAction = true

            // ボタンの表示を変更
            
            // 初期状態では、先頭の項目を選択状態にする
            selectedSetQty = selectedItem.setQty
            menuButton.setTitle(String(selectedSetQty) + "個", for: .normal)
        }

    }

    
    // バリエーションボタン設定
    //  index: variation1　か　2　の選択
    //  indexが2の場合は、　選択中のバリエーション1に該当するデータだけを返す
    
    func setVariationButtonMenu(index:Int) {
        
        let menuButton = (index == 1) ? variationButton1!: variationButton2!
        
        var variationItems:[Item] = []
        
        if itemParent == nil {
            
            variationItems.append(selectedItem)
            
        }else{
            for variatinon in itemParent.variationItems {
                if variatinon.isWholesale || variatinon.isConsignment {
                    
                    if index == 1 || index == 2 && variatinon.variation1Value == selectedItem?.variation1Value {
                        variationItems.append(variatinon)
                    }
                }
            }
        }
        

        // 選択されている数量セットに該当するものだけを取り出し、さらに重複を取り除く
        var uniqueItems:[Item] = []
        
        for item in variationItems {
            if index == 1 {

                if item.setQty == selectedSetQty {
                    var exist = false
                    for preValue in uniqueItems {
                        if preValue.variation1Value == item.variation1Value {
                            exist = true
                            break
                        }
                    }
                    if !exist {
                        uniqueItems.append(item)
                    }
                }
            }else{
                if item.variation2Value != nil {
                    var exist = false
                    for preValue in uniqueItems {
                        if preValue.variation2Value == item.variation2Value {
                            exist = true
                            break
                        }
                    }
                    if !exist {
                        uniqueItems.append(item)
                    }
                }
            }
        }

        // ソート
        let sortedItems = uniqueItems.sorted(by: { (a, b) -> Bool in
            if index == 1 {
                if a.variation1Value == nil { return true }
                if b.variation1Value == nil { return false }
                return a.variation1Value! > b.variation1Value!
            }else{
                
                return a.variation2Value! > b.variation2Value!
            }
        })
        
        //　メニュ項目の追加
        var actions = [UIMenuElement]()

        for item in sortedItems {
            let title = ((index == 1 ) ? item.variation1Value : item.variation2Value) ?? "-"
    
            actions.append(UIAction(title: title, image: nil, state: item == selectedItem ? .on : .off, handler: { (_) in

                menuButton.setTitle(title, for: .normal)
                
                self.selectedItem = item
                
                if index == 1 && self.selectedItem.variation2Label != nil {
                    self.setVariationButtonMenu(index: 2)
                }
                
                // バリエーションを切り替えると最小ロットするが変化する可能性があるので、数量ボタンも更新する
                if self.quantityButton != nil {
                    self.refreshQuantityButton(item:item)
                }
                self.setDisplayData()
                self.MainTableView.reloadData()
            }))

        }

        if sortedItems.count > 0 {
            menuButton.isHidden = false
            
            if actions.count > 0 {
                // UIButtonにUIMenuを設定
                menuButton.menu = UIMenu(title:"" , options: .destructive, children: actions)
                // こちらを書かないと表示できない場合があるので注意
                menuButton.showsMenuAsPrimaryAction = true
                // ボタンの表示を変更
                if selectedItem == nil {
                    selectedItem = sortedItems.first
                }
                
                if index == 1 {
                  //  variation1Label.isHidden = false
                    //variation1Label.text = selectedItem.variation1Value
                    menuButton.setTitle(selectedItem?.variation1Value ?? "-", for: .normal)
                }else{
                  //  variation2Label.isHidden = false
                  //  variation2Label.text = selectedItem.variation2Value
                    menuButton.setTitle(selectedItem?.variation2Value ?? "-", for: .normal)
                }
            }

        }else{
            menuButton.isHidden = true
            if index == 1 {
                variation1Label.isHidden = true
            }else{
                variation2Label.isHidden = true
            }
        }

        return 

    }
    
    /*
    // 仕入れ方式選択ボタンの設定
    func setBuyWayButtonMenu(menuButton:UIButton, isWholesale:Bool, isConsignment:Bool ) {
        
        //メニュー項目をセット
        var actions = [UIMenuElement]()
        
        if isConsignment {
            let title = "委託仕入"
            actions.append(UIAction(title: title, image: nil, state: .off, handler: { (_) in

                menuButton.setTitle(title, for: .normal)
                self.selectedSaleType = .Consignment
            }))
        }
        
        if isWholesale {
            let title = "買取仕入"
            actions.append(UIAction(title: title, image: nil, state: .on, handler: { (_) in

                menuButton.setTitle(title, for: .normal)
                self.selectedSaleType = .WholeSale
            }))
        }

        if isConsignment || isWholesale {
            // UIButtonにUIMenuを設定
            menuButton.menu = UIMenu(title:"" , options: .displayInline, children: actions)
            // こちらを書かないと表示できない場合があるので注意
            menuButton.showsMenuAsPrimaryAction = true
            // ボタンの表示を変更
            menuButton.setTitle(isWholesale ? "買取仕入" : "委託仕入", for: .normal)
            selectedSaleType = (isWholesale) ? .WholeSale : .Consignment
        }
    }
    */
    

    // 数量選択ボタンに数量をセット
    func setUnitButtonMenu(menuButton: UIButton, current:Int, min:Int, max:Int) {
        
        //メニュー項目をセット
        var actions = [UIMenuElement]()
        selectedQuantity = current

        actions.removeAll()
        
        if checkInventoryNumber() {
            var limit = max
            if max > 50 { limit = 50 }
            let minValue = min
            if limit < minValue { limit = minValue }
            
            for number in (minValue..<limit+1) {

                actions.append(UIAction(title: String(number), image: nil, state: (current == number) ? .on : .off, handler: { (_) in
                    menuButton.setTitleAttribute(title: String(number) + "個", fontSize: 14)
                    self.setUnitButtonMenu(menuButton:menuButton, current:number, min:min, max:max)
                    self.selectedQuantity = number
                    self.MainTableView.reloadSections(IndexSet(integer: 2), with: .none)
                }))
            }
            if actions.count > 0 {
                menuButton.menu = UIMenu(title:"" , options: .displayInline, children: actions)     // UIButtonにUIMenuを設定
                menuButton.showsMenuAsPrimaryAction = ( max > 0)                                    // こちらを書かないと長押しで表示となる
                // ボタンの表示を変更
                menuButton.setTitleAttribute(title: String(current) + "個", fontSize: 14)
                addCartButton.isEnabled = true    // 追加できる在庫がない場合はカートへ追加ボタンを無効にする
                self.MainTableView.reloadSections(IndexSet(integer: 2), with: .none)
            }
            
        }else{
            // 在庫がなくなったので、カート追加ボタンの表示を変更し、数量ボタンを空にする
            actions.append(UIAction(title: "", image: nil, state: .off, handler: { (_) in
                
            }))
            menuButton.menu = UIMenu(title:"" , options: .displayInline, children: actions)     // UIButtonにUIMenuを設定
            menuButton.setTitleAttribute(title: "0個" , fontSize: 14)
            addCartButton.isEnabled = false
            addCartButton.setButtonTitle(title: NSLocalizedString("OutOfStock", comment: ""), fontSize: 15)

        }

    }
    
    @IBAction func shareAction() {
        LogUtil.shared.log ("商品画面：シェア")
        let textData = "商品名:" + (selectedItem.title ?? "") +  "\n\n" + RETAILER_SITE_URL +  "/item/" + itemParent.id
        let shareItem = ShareItem(text:textData, title:NSLocalizedString("ShareThisProduct", comment: "") )
  
        // 共有する項目
        let activityItems = [shareItem ] as [Any]
        //let activityItems = [shareText, shareUrl ] as [Any]
        
        // 初期化処理
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)

        // 使用しないアクティビティタイプ
        //let excludedActivityTypes = [ UIActivity.ActivityType.message ]
        //  activityVC.excludedActivityTypes = excludedActivityTypes

        // UIActivityViewControllerを表示
        DispatchQueue.main.async {
            self.present(activityVC, animated: true, completion: nil)
        }

        g_userLog.shareItem(itemId:selectedItem.id, pageUrl: self.orosyNavigationController?.currentUrl ?? "")
        
    }
    
    // サプライヤーページへ遷移
    @IBAction func gotoSupplierPage(_ sender: Any) {
        
        // ブランドページの直下なら、元のページへ戻る
        let parentVc = self.navigationController?.viewControllers[(self.navigationController?.viewControllers.count ?? 0) - 2]
        if parentVc is SupplierVC {
            self.navigationController?.popViewController(animated: true)
        
        }else{

            var supplierHasData:Supplier!
            if supplier.category == nil {
                //　検索で商品を選択した場合にはサプライヤーの情報が不足しているため、取り直す
                supplierHasData = Supplier(supplierId: supplier.id)
                //supplierHasData.itemParents = supplier.itemParents
                supplierHasData.itemParents = supplierHasData.getNextSupplierItemParents()  // 最初は一部だけを読み出す
                supplierHasData.getAllInfo(wholeData: true)
                supplierHasData.connectionStatus = supplier.connectionStatus
            }else{
                supplierHasData = supplier
            }
            
            OrosyAPI.cacheImage(supplierHasData.coverImageUrl, imagesize: .Size400)
            OrosyAPI.cacheImage(supplierHasData.iconImageUrl, imagesize: .Size100)
            if supplierHasData.imageUrls.count > 0 {
                OrosyAPI.cacheImage(supplierHasData.imageUrls.first, imagesize: .Size200)
            }
    
            // サプライヤーページへ遷移
            DispatchQueue.main.async{
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "ProductListVC") as! ProductListVC
                object_setClass(vc.self, SupplierVC.self)
                
                vc.navigationItem.leftItemsSupplementBackButton = true
                vc.productListMode = .ProductList
                vc.supplier = supplierHasData

             //   vc.itemParents = supplierHasData.itemParents
             //   vc.tradeConnection = supplierHasData.tradeConnection
             //   vc.connectionStatus =  supplierHasData.tradeConnection?.status
                self.orosyNavigationController?.pushViewController(vc, animated: true)
                
            }

        }

    }
    

    //　取引申請状態が変化した（取引を申し込んだ）
    @objc func refreshStatus(notification: Notification) {
        
        self.supplier.getTradeConnection()
        connectionStatus = self.supplier.tradeConnection?.status
        DispatchQueue.main.async {
            self.MainTableView.reloadData()
        }
    }
    
    
    // MARK: お気に利関連
    // ハートボタンがタッチされた
    @IBAction func favoriteButtonPushed(_ sender: IndexedButton) {
        

        if !g_loginMode {
            let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "VerifyEmailVC") as! VerifyEmailVC
            vc.displayMode = .requestLogin
            present(vc, animated: true, completion: nil)

            return
        }
        
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        if let favoriteLists = g_favoriteLists {
            if favoriteLists.list.count == 0 {
                confirmAlert(title: "登録できるお気に入りリストが無いため登録できません", message: "作成してください", ok: "確認")
                return
            }
            
            // トップ画像のところにあるハートボタンを押した場合
            
            if let fvc = g_faveriteVC {
                if let selectedItemParent = sender.selectedItemParent {
                    let favoriteFlag = fvc.changeFavorite(itemParent: selectedItemParent, callFromSelf: false, referer:self.orosyNavigationController?.currentUrl ?? "")
 
                    if let baseView = sender.baseView as? UITableView {
                        if let indexPath = sender.indexPath {
                            itemParent.isFavorite = favoriteFlag
                            MainTableView.reloadRows(at: [indexPath], with: .none)
                        }
                    }else if let baseView = sender.baseView as? UICollectionView {
                        if let indexPath = sender.indexPath {
                            sender.selectedItemParent?.isFavorite = favoriteFlag
                            baseView.reloadItems(at: [indexPath])
                        }
                    }
                }
            }
        }
    }
    
    // お気に入りが更新されたという通知を受けた
    @objc func favoriteReset(notification: Notification) {
        
        guard let userInfo = notification.userInfo else { return }
        
        if let updatedItemParent = userInfo["itemParent"] as? ItemParent {
            let onOff = userInfo["onOff"] as? Bool ?? false  // true: お気に入りに入れた
            // 今表示しているのと同じならアップデートする
            if updatedItemParent.id == itemParent.id {
                itemParent.isFavorite = onOff
                favoriteButton.isSelected = onOff
            }
            
            // 同じブランドの商品の中の場合
            if let collection = allProductsCollectionView {
                var row = 0
                for item in restIitemParents {
                    if updatedItemParent.id == item.id {
                        item.isFavorite = onOff
                        favoriteButton.isSelected = onOff
                        collection.reloadItems(at: [IndexPath(row:row, section:0)])
                    }
                    row += 1
                }
                row = 0
            }
            //　おすすめ商品の中の場合
            if let collection = recommendedProductsCollectionView {
                var row = 0
                for item in recommendedItems {
                    if updatedItemParent.id == item.id {
                        item.isFavorite = onOff
                        favoriteButton.isSelected = onOff
                        collection.reloadItems(at: [IndexPath(row:row, section:0)])
                    }
                    row += 1
                }
                row = 0
            }
        }
    }
    
    
    @IBAction func infoSelected(_ sender: IndexedButton) {
        
        guard let _ = sender.indexPath else { return }
        
        if let url = selectedItem.ecUrl {
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: false, completion: nil)
        }
    }

}


class OrosyCollectionViewCell: UICollectionViewCell {
    
    static let identifier: String = "OrosyCollectionViewCell"
    
    static let widthInset: CGFloat = 20.0
    static let cellWidth: CGFloat = 330
    static let cellHeight: CGFloat = 330

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}

final class CarouselCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return .zero }
        let pageWidth = itemSize.width + minimumLineSpacing
        let currentPage = collectionView.contentOffset.x / pageWidth

        print(currentPage, collectionView.contentOffset.x, pageWidth)
        if abs(velocity.x) > 0.3 {
            let nextPage = (velocity.x > 0) ? ceil(currentPage) : floor(currentPage)
            return CGPoint(x: nextPage * pageWidth, y: proposedContentOffset.y)
        } else {
            return CGPoint(x: round(currentPage) * pageWidth, y: proposedContentOffset.y)
        }
    }
}
