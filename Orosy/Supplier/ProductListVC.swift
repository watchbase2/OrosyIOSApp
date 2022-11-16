//
//  ProductListVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/15.
//　SupplieVC FavoriteVCで共通に使用するVC

import UIKit
import SafariServices


enum ProductListViewMode {
    case ProductList        // サプライヤが持っている商品を一覧表示させる場合
    case Favorite           // お気に入りリストに入っている商品を一覧表示させる場合
    case KeywordSearch      // キーワード検索結果の一覧表示

}

protocol ShowSupplierDelegate: AnyObject {
    func showProduct(itemParent:ItemParent)
}


class ProductListVC: OrosyUIViewController,  UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching  {

    var delegate_home:HomeVC? = nil
    
    var firstItemPreload = true     // 最初の項目はスクロールせずにタッチされるので、最初にプリロードしておく。
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var brandName: UILabel!
    @IBOutlet weak var concept: UITextView!
    var favorites:[Favorite] = []           //　お気に入り一覧
    @IBOutlet weak var blackCoverVIew: UIView!
    
    @IBOutlet weak var MainTableView: UITableView!
    @IBOutlet weak var mainTabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var emptyMessage: UILabel!
    @IBOutlet weak var waitIndicator: UIActivityIndicatorView!
    @IBOutlet weak var modePanel: UIView!
    @IBOutlet weak var modePanelTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var ConnectedTableView: UITableView!
    
    var productListMode:ProductListViewMode!
    var supplier:Supplier? {
        didSet {
            if let sup = supplier {
                self.itemParents = sup.itemParents
                self.tradeConnection = sup.tradeConnection
                if sup.tradeConnection == nil {
                    _ = sup.getTradeConnection()
                }
                self.connectionStatus =  sup.tradeConnection?.status ?? .UNREQUESTED

                print("Connection status: \(self.connectionStatus)")
                if MainTableView != nil { MainTableView.reloadData() }
            }
        }
    }
    var itemParents:[ItemParent] = []       // 商品一覧, 商品検索結果
    var searchIems:SearchItems!             // キーワード検索用オブジェクト（すべて読み込んだかどうか

    
    var tradeConnection:TradeConnection?
    var connectionStatus:ConnectionStatus?  // 取引許可ステータス    お気に入りの場合は、異なるサプライヤーの商品を表示するため、この情報は使えない
    
    var supplierId:String = ""
    
    var basicInfoOpen = false
    var openCloseButton:UIButton!
    var basicInfoCell:UITableViewCell!
    var basicInfoCellOriginalHeight:CGFloat = 0
    
    var displayItemList:[SupplierDisplayItem]!
    
    var basicItems:[[String:Any]]!
  
    
    func isAllow(_ flag:String? ) -> Bool {
        return (flag != nil && flag == "allow")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 15.0, *) {
            MainTableView.sectionHeaderTopPadding = 0.0
         }

        displayItemList =
        [
            SupplierDisplayItem(type: SupplierItemType.PRODUCTS, title: "商品一覧", cell:"ProductCell", height:0 )   // 商品数に応じて行数が変わる
        ]

    }
    
  
    func numberOfSections(in tableView: UITableView) -> Int {
        DispatchQueue.main.async {
            self.waitIndicator.stopAnimating()
        }
        
        return displayItemList.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // 基本情報のみ折りたたむので高さを変える。それ以外は自動設定

        return UITableView.automaticDimension //自動設定
 
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        switch productListMode {
        case .ProductList:
            count = itemParents.count
        case .Favorite:
            break           // この場合はFavoriteVCでセットしている
        case .KeywordSearch:
            count = itemParents.count
        default:
            break
        }
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell!
        
        let row = indexPath.row
        let section = indexPath.section

        let item = displayItemList[section]
        let itemType = item.itemType
        cell = tableView.dequeueReusableCell(withIdentifier: item.cellType!, for: indexPath)
        
        cell.selectionStyle = .none
        
        switch itemType {
 
        case .PRODUCTS:
             
            let imageView = cell.contentView.viewWithTag(1) as! OrosyUIImageView
            let title = cell.contentView.viewWithTag(2) as! UILabel
            let catarogPriceLabel = cell.contentView.viewWithTag(3) as! UILabel
            let catarogPrice = cell.contentView.viewWithTag(13) as! UILabel
            let wholesalePriceLabel = cell.contentView.viewWithTag(4) as! UILabel
            let wholesalePrice = cell.contentView.viewWithTag(14) as! UILabel
            let wholesale_lockIcon = cell.contentView.viewWithTag(6) as! UIImageView
            let disconProductLabel = cell.contentView.viewWithTag(7) as! UILabel
            disconProductLabel.isHidden = true
            let favoriteButton = cell.contentView.viewWithTag(10) as! IndexedButton
            
            var itemParent:ItemParent!
            var isHidden = false
            var favorite:Favorite!
            var removed = false

            switch productListMode {
            case .ProductList:
                itemParent = itemParents[row]
            case .Favorite:
                favorite = favorites[row]
                isHidden = favorite.isHidden
                itemParent = favorite.itemParent
                
                if itemParent == nil {
                    removed = true
                    itemParent = ItemParent(id:favorite.itemParentId)
                }
                itemParent.isFavorite = favorite.isFavorite
                let _ = g_connectedSuppliers?.getSupplier(supplier_id: itemParent.supplier?.id ?? "")
                connectionStatus =  (g_connectedSuppliers?.getSupplier(supplier_id: itemParent.supplier?.id ?? "") != nil) ? ConnectionStatus.ACCEPTED : ConnectionStatus.UNREQUESTED

            case .KeywordSearch:
                itemParent = itemParents[row]
            default:
                break
            }
            
            favoriteButton.isSelected = itemParent.isFavorite
            
            
            if isHidden{
                
                imageView.image = UIImage(named:"hiddenFavorite")
                title.text = itemParent?.item?.title
                catarogPrice.text = ""
                catarogPriceLabel.isHidden = true
                wholesalePriceLabel.isHidden = true
                wholesalePrice.text = ""
                wholesale_lockIcon.isHidden = true
                
                if removed {
                    // 削除されたデータ
                    disconProductLabel.isHidden = false
                }
            }else{
   
                if let item = itemParent.item {
                    
                    imageView.targetRow = row
                  //  imageView.image = nil
                    imageView.getImageFromUrl(row: row, url: itemParent.imageUrls.first, defaultUIImage: g_defaultImage)      //
                    imageView.drawBorder(cornerRadius:0, color:UIColor.orosyColor(color: .Gray300), width:1)
                    catarogPriceLabel.isHidden = false
                    wholesalePriceLabel.isHidden = false
                    title.text = item.title
                    catarogPrice.text = Util.number2Str(item.catalogPrice)
                    
                    if connectionStatus == .ACCEPTED {
                        wholesalePrice.isHidden = false
                        wholesale_lockIcon.isHidden = true
                        
                        if item.isWholesale && item.wholesalePrice.compare(NSDecimalNumber.zero) == ComparisonResult.orderedDescending {
                            wholesalePrice.text = Util.number2Str(item.wholesalePrice)
                        }else{
                            wholesalePrice.text = "-"
                        }
                        
                    }else{
                        wholesalePrice.isHidden = true
                        wholesale_lockIcon.isHidden = false
                    }
                }
            }

            favoriteButton.indexPath = indexPath
            if row == 0 && firstItemPreload {
                firstItemPreload = false
                for url in itemParent.imageUrls {
                    OrosyAPI.cacheImage(url, imagesize: .Size500)   // 商品ページのトップの商品サンプル画像
                }
            }
            
        default:
            break
        }


        return cell
    }

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {

        if productListMode == .ProductList || productListMode == .KeywordSearch {
            for indexPath in indexPaths {
                let row = indexPath.row
                let itemParent = itemParents[row]
                if let _ = itemParent.item {
                    OrosyAPI.cacheImage(itemParent.imageUrls.first, imagesize: .Size200)
                }
            }
        }else{
            
        }
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let row = indexPath.row
        let section = indexPath.section

        let item = displayItemList[section]
        let itemType = item.itemType
        
        if itemType == .PRODUCTS {
            var itemParent:ItemParent?
            
            switch productListMode {
            case .ProductList:
                itemParent = itemParents[row]
            case .Favorite:
                let favorite = favorites[row]
                let isHidden = favorite.isHidden
                if isHidden {
                    itemParent = nil
                    return   //製品ページへは遷移させない
                    
                }else{
                    itemParent = favorite.itemParent
                    self.supplier = itemParent?.supplier
                }
            case .KeywordSearch:
                let itemParent = itemParents[row]
                if let delegate = delegate_home {
                    delegate.showProduct(itemParent:itemParent, waitIndicator: nil)
                }
                return
            default:
                break
            }

            let cell = tableView.cellForRow(at: indexPath)
            let waitIndicator = cell?.viewWithTag(20) as? UIActivityIndicatorView
            waitIndicator?.startAnimating()
            
            DispatchQueue.global().async {
            
                if let itemp = itemParent{
                    DispatchQueue.main.async {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "ProductDetailVC") as! ProductDetailVC
                        vc.navigationItem.leftItemsSupplementBackButton = true
         
                        if self.supplier == nil {
                            vc.supplier =  itemp.supplier     // お気に入りの場合には、商品毎にサプライヤーが異なるのでこちらで指定する
                            _ = vc.supplier.getNextSupplierItemParents()  // 一覧表示する分だけを取得
                        }else{
                            vc.supplier = self.supplier          // これを先に指定しておく必要がある
                        }
                        vc.connectionStatus = self.connectionStatus ?? .UNREQUESTED
                        vc.itemParent = itemp
                        _ = itemp.getItemParent()
                        vc.selectedItem = itemp.item

                       // vc.selectedItem = itemParent?.item
                       // vc.itemParent_id = itemp.id

                        self.orosyNavigationController?.pushViewController(vc, animated: true)
                        waitIndicator?.stopAnimating()
                    }
            
                }else{
                    DispatchQueue.main.async {
                        waitIndicator?.stopAnimating()
                        self.confirmAlert(title: "", message: NSLocalizedString("ProductRemoved", comment: ""), ok: "確認")
                    }
                }
            }
        }
    }
    

    
    // MARK: スクロール
    var scrollBeginingPoint: CGPoint!
    var searchBarIsHidden = false
    
    
    //　スクロールが停止しそうになったら、すくその時点で表示しているサプライヤーに関して「もっと見る」を開いた時に必要となる画像をキャッシュへ入れる
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        LogUtil.shared.log ("in scrollViewWillBeginDecelerating")

        if let _tableView = scrollView as? UITableView {

            if let indixes = MainTableView.indexPathsForVisibleRows  {  // 見えている範囲の行
                for index in indixes {
                    let section = index.section
                    let row = index.row
                    
                    let item = displayItemList[section]
                    let itemType = item.itemType
                    
                    
                    if itemType == .PRODUCTS{
                        var itemParent:ItemParent!
                        
                        switch productListMode {
                        case .ProductList:
                            itemParent = itemParents[row]
                        case .Favorite:
                            let favorite = favorites[row]
                            itemParent = favorite.itemParent
                            
                        case .KeywordSearch:
                            itemParent = itemParents[row]
                        default:
                            break
                        }
                        
                        for url in itemParent.imageUrls {
                            OrosyAPI.cacheImage(url, imagesize: .Size500)   // 商品ページのトップの商品サンプル画像
                            
                        }
                        
                    }
                }
                    
            }
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollBeginingPoint = scrollView.contentOffset;
        
    }

    //　行の最後の近づいたら、次のデータを取得 & スクロール方向に応じて検索バーを隠す
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
 
        if scrollView != MainTableView { return }
        
        let scrollPosY = scrollView.contentOffset.y //スクロール位置
        let maxOffsetY = scrollView.contentSize.height - scrollView.frame.size.height //スクロール領域の高さからスクロール画面の高さを引いた値
        let distanceToBottom = maxOffsetY - scrollPosY //スクロール領域下部までの距離
        let ScrollLimit:CGFloat = 800
        
        if distanceToBottom < 4000 && !fetchingNextDataForMaintable {
            self.fetchingNextDataForMaintable = true
            
            DispatchQueue.global().async {
                //スクロール領域下部に近づいたら追加で取得する
                switch self.productListMode {
                case .ProductList:
                    if let sup = self.supplier {
                        if distanceToBottom < ScrollLimit && !sup.hasAllItemParents {
                            let newItems = sup.getNextSupplierItemParents()
                            if newItems.count > 0 {
                                self.insertItems(addItemParents: newItems)
                            }
                        }
                    }
                case .Favorite:
                    break   // FavoriteVC側で処理
                    
                case .KeywordSearch:
                    
                    if distanceToBottom < ScrollLimit && !self.searchIems.hasAllItemParents {
                        
                        let result = self.searchIems.getNext()
                        
                        switch result {
                        case .success(let newItems):
                            if newItems.count > 0 {
                                self.insertItems(addItemParents: newItems)
                                DispatchQueue.main.async{
                                    self.itemParents = self.searchIems.itemParents
                                    self.MainTableView.reloadData()
                                }
                            }

                        case .failure(_):
                            break
                        }
                    }
                    break
                default:
                    break
                }
            }
        }
    }
    
    var fetchingNextDataForMaintable = false
    
    
    func insertItems(addItemParents:[ItemParent]) {
    
        var row = itemParents.count
        var addedIndexPaths:[IndexPath] = []
        
        for _ in addItemParents {
            
            let indexPath = IndexPath(row:row , section:5)
            addedIndexPaths.append(indexPath)
            row += 1
            
        }
        
        DispatchQueue.main.async {
            self.itemParents.append(contentsOf: addItemParents)     // 表示用配列へ追加
            
            self.MainTableView.beginUpdates()
            self.MainTableView.insertRows(at: addedIndexPaths, with: .none)
            self.MainTableView.endUpdates()
            self.fetchingNextDataForMaintable = false
        }
            
    }
    
    var restrictionMode:Bool = false
    @IBAction func showRestrictionsView(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PopupRestrictionVC") as! PopupRestrictionVC
        vc.navigationItem.leftItemsSupplementBackButton = true
        vc.supplier = supplier
        vc.restrictionMode = true
        self.present(vc,animated: true,completion: nil)
        
        let targetUrl = (self.orosyNavigationController?.getNewTargetUrl(vc) ?? "") + "/tradeConditions"
        self.orosyNavigationController?.sendAccessLog(modal:true, targetUrl:targetUrl)

    }
    
    @IBAction func showShippingFeeViewPushed(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PopupRestrictionVC") as! PopupRestrictionVC
        vc.navigationItem.leftItemsSupplementBackButton = true
        vc.supplier = supplier
        vc.restrictionMode = false
        self.present(vc,animated: true,completion: nil)

        let targetUrl = (self.orosyNavigationController?.getNewTargetUrl(vc) ?? "") + "/shippingFee"
        self.orosyNavigationController?.sendAccessLog(modal:true, targetUrl:targetUrl)

    }

    //　取引申し込み、メッセージ送信画面を表示
    @IBAction func showMessageView(_ sender: Any) {
        
        if !g_loginMode {
            let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "VerifyEmailVC") as! VerifyEmailVC
            vc.displayMode = .requestLogin
            present(vc, animated: true, completion: nil)

            return
        }
        
        if let tc = tradeConnection {
            
            if UserDefaultsManager.shared.accountStatus == .AccountProfiled  {
                if tc.status == .ACCEPTED {
                    // メッセージ送信画面をモーダルビューとして表示
                    let storyboard = UIStoryboard(name: "MessageSB", bundle: nil)
                    if let vc = storyboard.instantiateViewController(withIdentifier: "MessageVC") as? MessageVC {
                        if let sup = supplier {
                            vc.supplier = sup  // 現在選択しているサプライヤーとのメッセージのみを表示
                            vc.modalMode = true
                            vc.brandName = sup.brandName
      
                            /*
                            self.navigationController?.modalPresentationStyle = .overCurrentContext
                            self.present(vc, animated: true)
                            */
                            
                            let nav = UINavigationController(rootViewController: vc)
                            nav.modalPresentationStyle = .fullScreen
                            nav.navigationBar.isHidden = true
                            
                            present(nav, animated: true, completion: nil)
                            
                            g_preViewController = self
                            
                            let targetUrl = self.orosyNavigationController?.getNewTargetUrl(vc) ?? ""
                            self.orosyNavigationController?.sendAccessLog(modal:true, targetUrl:targetUrl)
                        }
                    }
                    
                }else if tc.status == .REQUEST_PENDING {
                    // 申請中なので何もしない
                }else{
                    // 申請画面へ遷移
                    let storyboard = UIStoryboard(name: "AlertSB", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "ApplyConnection") as! ApplyCoonectionVC
                    vc.navigationItem.leftItemsSupplementBackButton = true
                    vc.supplier = supplier
                    vc.orosyNavigationController = self.orosyNavigationController

                    self.present(vc, animated: true, completion: nil)
                    
                    let targetUrl = self.orosyNavigationController?.getNewTargetUrl(vc) ?? ""
                    self.orosyNavigationController?.sendAccessLog(modal:true, targetUrl:targetUrl)

                }
                
            }else{
                // プロフィールの入力を促す
                showCheckProfileVC()

            }
        }
    }
    
    func conectionUpdated() {
        
    }
    
    @IBAction func openBasicInfoView(_ button: UIButton) {
   
        basicInfoOpen = !basicInfoOpen
        openCloseButton.isSelected = basicInfoOpen
        
        if self.basicInfoOpen {
            UIView.animate(withDuration: 0.5, // アニメーションの秒数
                           delay: 0.0, // アニメーションが開始するまでの秒数
                           options: [.curveEaseOut], // アニメーションのオプション 等速 | 繰り返し
                           animations: {
                self.MainTableView?.beginUpdates()
                var frame = self.basicInfoCell.frame
                frame.size.height = (self.basicInfoOpen) ? self.displayItemList[1].itemHeight : 1
                self.basicInfoCell.frame = frame
                self.MainTableView?.endUpdates()
            }, completion: { (finished: Bool) in
               
            })
        
        }else{
            self.MainTableView?.beginUpdates()
            var frame = self.basicInfoCell.frame
            frame.size.height = (self.basicInfoOpen) ? self.displayItemList[1].itemHeight : 1
            self.basicInfoCell.frame = frame
            self.MainTableView?.endUpdates()
        }
    }
    
    @IBAction func shareAction() {

        if productListMode == .Favorite { return }
        
        if let sup = supplier {
            let textData = "ブランド名:" + (sup.brandName ?? "") +  "\n\n" + RETAILER_SITE_URL +  "/brand/" + sup.id
            let shareItem = ShareItem(text:textData, title:NSLocalizedString("ShareThisBrand", comment: ""))
       
            // 共有する項目
            let activityItems = [shareItem ] as [Any]
            
            // 初期化処理
            let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)

            // 使用しないアクティビティタイプ
            //let excludedActivityTypes = [ UIActivity.ActivityType.message ]
            //  activityVC.excludedActivityTypes = excludedActivityTypes


            DispatchQueue.main.async {
                self.present(activityVC, animated: true, completion: nil)
            }
            
            g_userLog.shareSupplier(supplierId:sup.id, pageUrl: self.orosyNavigationController?.currentUrl ?? "")

        }
    }
    
    // MARK: 　＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
    // MARK: お気にり
    
    // ハートボタンが押された
    @IBAction func favoriteButtonPushed(_ button: IndexedButton) {

        if !g_loginMode {
            let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "VerifyEmailVC") as! VerifyEmailVC
            vc.displayMode = .requestLogin
            present(vc, animated: true, completion: nil)

            return
        }
        
        if let indexPath = button.indexPath {
            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            
            let row = indexPath.row
            
            if let fvc = g_faveriteVC {
                var itemParent:ItemParent!
                
                itemParent = itemParents[row]
                emptyMessage.isHidden = (itemParents.count > 0)
      

                let favoriteFlag = fvc.changeFavorite(itemParent: itemParent, callFromSelf: false, referer:self.orosyNavigationController?.currentUrl ?? "")
                itemParent.isFavorite = favoriteFlag
                MainTableView.reloadRows(at: [indexPath], with: .none)
                
                if let log = g_userLog {
                  //  log.addFavorite(itemParentId: itemParent.id, urlString: "test")
                }
            }
        }
    }
    
     
    @IBAction func snsPushed(button: UIButton) {
        var url:String? = nil
        
        let tag = button.tag
        switch tag {
        
        case ..<100:
            // 定義されているSNS
            if let sup = supplier {
                url = sup.urls[tag].url
            }
        case 100:
            // Home
            if let sup = supplier {
                
                for sns in sup.urls {
                    if sns.category == .Home {
                        url = sns.url
                    }
                }
            }
        default:
            // Others
            if let sup = supplier {
                url = sup.urls[tag - 200].url
            }
        }
        
        if let _url = URL(string: url ?? "") {
            let safariViewController = SFSafariViewController(url: _url)
            present(safariViewController, animated: false, completion: nil)
        }
        
    }
    

    @IBOutlet weak var connectedTableTopConstraint: NSLayoutConstraint!
    // お気に入り商品　／　取引ブランドの切替
    @IBAction func productBrandSelected(_ sender: OrosySwitchButton) {
        
    }
    
}
