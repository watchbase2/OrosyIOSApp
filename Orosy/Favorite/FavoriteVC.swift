//
//  FavoriteViewController.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/09.
//
// お気に入り商品のリストは　ProductListVCで表示させ、取引ブランドはここで表示させている。
// 取引先かどうかを判定するために、このデータを使っている関係で、先に全て読み出すようにしている。

import UIKit

class FavoriteVC: ProductListVC, OrosyProcessManagerDelegate  {
    
    var favoriteLists:[FavoriteList] = []       // お気に入りを分類管理ためのリスト
    var selectedFavorList:FavoriteList?         // 選択されているお気に入り
    var connectedSuppliers:ConnectedSuppliers?  // 取引先
    
    var uuid_favoriteList:String?   // お気に入り
    var uuid_connectedList:String?  // 取引ブランド
    var favoriteMode = true         // お気に入り・取引ブランド
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        g_faveriteVC = self
        
        self.setNaviTitle(title: "お気に入り")
        
        self.navigationItem.leftBarButtonItems = []     // 戻るボタンを非表示
        self.navigationItem.hidesBackButton = true
        
        let accountBarButtonItem = UIBarButtonItem(image: UIImage(named: "config"), style: .plain, target: self, action: #selector(showAccount))
        //navigationItem.setRightBarButtonItems(nil, animated: false) // ProductListVCを継承しているのでシェアボタンが表示されるのを消す
        super.navigationItem.setRightBarButtonItems([accountBarButtonItem], animated: false)
        
        let image = UIImage(named: "config")?.withRenderingMode(.alwaysOriginal)
        let accountBarButton = UIButton()
        


     //   accountBarButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
      //  accountBarButton.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: 0).isActive = true
       // accountBarButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
      //  accountBarButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        accountBarButton.setBackgroundImage(image ,for: .normal)
        accountBarButton.frame = CGRect(x:0, y:20, width:24, height:24)
        accountBarButton.backgroundColor = .red
  
        
        modePanel.isHidden = false
        mainTabelTopConstraint.constant = 96
        
        productListMode = .Favorite

        MainTableView.refreshControl = UIRefreshControl()
        MainTableView.refreshControl?.addTarget(self, action: #selector(refreshTable), for: .valueChanged)
        
        ConnectedTableView.refreshControl = UIRefreshControl()
        ConnectedTableView.refreshControl?.addTarget(self, action: #selector(refreshConnectedTable), for: .valueChanged)
        
        favoriteMode = true
        

        let enc = NotificationCenter.default
        enc.addObserver(self, selector: #selector(reset), name: Notification.Name(rawValue:NotificationMessage.Reset.rawValue), object: nil)
    }
    

    @objc func reset() {
        if noDataAlert != nil { noDataAlert.isHidden = false }
        favoriteLists = []
        g_favoriteLists = nil
        favorites = []
        g_favoriteItems = []
        connectedSuppliers = nil
        g_connectedSuppliers = nil
        uuid_favoriteList = nil
        uuid_connectedList = nil
        
        DispatchQueue.main.async {
            self.MainTableView.reloadData()
            self.navigationController?.popToRootViewController(animated: false)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        favorites = g_favoriteItems
   
        nodataCheck()
        self.MainTableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {

        if g_processManager != nil {
            if g_processManager.getStatus(uuid: uuid_favoriteList) == .Running {    // uuid_favoriteList == nil ||
                DispatchQueue.main.async {
                    self.waitIndicator.startAnimating()
                }
            }
        }
    }

    func nodataCheck() {
        DispatchQueue.main.async {
            
            if self.favoriteMode {
                if g_favoriteItems.count == 0 {
                    self.noDataAlert.isHidden = false
                    self.noDataAlert.selectType(type: .favoriteProduct)
                }else{
                    self.noDataAlert.isHidden = true
                }
            }else{
                //self.connectedSuppliers?.list = []  // test
                
                if (self.connectedSuppliers?.list.count ?? 0) == 0 {
                    self.noDataAlert.isHidden = false
                    self.noDataAlert.selectType(type: .favoriteBrand)
                }else{
                    self.noDataAlert.isHidden = true
                }
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension //自動設定
 
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        if tableView == MainTableView {
            count = favorites.count
            
        }else if tableView == ConnectedTableView {
            count = connectedSuppliers?.list.count ?? 0
        }
        
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell:UITableViewCell!
        
        if tableView == MainTableView {
            cell = super.tableView(tableView, cellForRowAt: indexPath)
            
        }else if tableView == ConnectedTableView {

            let row = indexPath.row
 
            cell = tableView.dequeueReusableCell(withIdentifier: "ConnectedCell", for: indexPath)
            cell.selectionStyle = .none
            
            let imageView = cell.contentView.viewWithTag(1) as! OrosyUIImageView100
            let brandTitle = cell.contentView.viewWithTag(2) as! UILabel
            let category = cell.contentView.viewWithTag(3) as! UILabel
            let no_product = cell.contentView.viewWithTag(4) as! UILabel
            
            var imageViews:[OrosyUIImageView] = []
            imageViews.append(cell.contentView.viewWithTag(10) as! OrosyUIImageView)
            imageViews.append(cell.contentView.viewWithTag(11) as! OrosyUIImageView)
            imageViews.append(cell.contentView.viewWithTag(12) as! OrosyUIImageView)
            imageViews.append(cell.contentView.viewWithTag(13) as! OrosyUIImageView)
            
            if let supplier = self.connectedSuppliers?.list[row] {
                imageView.getImageFromUrl(url: supplier.iconImageUrl)
                imageView.drawBorder(cornerRadius: imageView.bounds.width / 2.0, color: UIColor.orosyColor(color: .Gray200), width: 1)
                brandTitle.text = supplier.brandName
                category.text = g_categoryDisplayName.getDisplayName(supplier.category)
                
                // 代表画像を4つまでセット
                for ip in 0..<4 {

                    let imageView = imageViews[ip]
                    imageView.image = nil
                    
                    let itemParents = supplier.itemParents
                    if ip < itemParents.count {
                        imageView.isHidden = false
                        imageView.targetRow = row
                        imageView.drawBorder(cornerRadius: 0, color: .orosyColor(color: .Gray200), width: 1)
                        if itemParents[ip].imageUrls.count > 0 {
                            let url = itemParents[ip].imageUrls.first
                            imageView.getImageFromUrl(row: row, url: url, defaultUIImage: g_defaultImage)
                        }

                    }else{
                        imageView.drawBorder(cornerRadius: 0, color: .clear, width: 0)
                    }
                }
                
                if supplier.itemParents.count == 0 {
                    no_product.text = NSLocalizedString("NoProducts", comment: "")
                    no_product.isHidden = false
                }else{
                    no_product.isHidden = true
                }
            }
        }
        
        return cell
    }
        
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let row = indexPath.row

        if tableView == MainTableView {
            super.tableView(tableView, didSelectRowAt: indexPath)
            
        }else{
            if let supplier = self.connectedSuppliers?.list[row] {
                showSupplierPage(supplier: supplier, activityIndicator: nil)
            }
        }
    }
    
    var lockGotoSupplierPageButton = false
    // ブランド一覧でサプライヤを選択した場合にはsupplierが特定されているのでsupplierオブジェクトが渡されるようにしていたが、この方法だとWeb側でお気に入り情報が変化した場合、それを反映できないので、結局、毎回サプライヤー情報を読み直すこととした。
    // 新着情報やバナーの場合には、supplier idと画像ぐらいしか情報を持っていないので、supplier idが渡される
    func showSupplierPage(supplier:Supplier, activityIndicator:UIActivityIndicatorView? = nil) {

        if lockGotoSupplierPageButton { return }         //　2度押し防止
        lockGotoSupplierPageButton = true
        
        if let act = activityIndicator  {
            DispatchQueue.main.async{
                act.startAnimating()
            }
        }
        
        DispatchQueue.global().async{

            OrosyAPI.cacheImage(supplier.coverImageUrl, imagesize: .Size400)
            OrosyAPI.cacheImage(supplier.iconImageUrl, imagesize: .Size100)

            _ = supplier.getNextSupplierItemParents()
            
            if supplier.getAllInfo(wholeData: true) {
 
                // サプライヤーページへ遷移
                DispatchQueue.main.async{
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "ProductListVC") as! ProductListVC
                    object_setClass(vc.self, SupplierVC.self)
                    
                    vc.navigationItem.leftItemsSupplementBackButton = true
                    vc.productListMode = .ProductList
                    vc.supplier = supplier
                //    vc.itemParents = supplier.itemParents
                 //   vc.connectionStatus = supplier.tradeConnection?.status
                    self.orosyNavigationController?.pushViewController(vc, animated: true)
                    
                    if let act = activityIndicator  {
                        act.stopAnimating()
                    }

                }
            }
            
            self.lockGotoSupplierPageButton = false
        }
    }
        
    enum UpdateTableForFavorite {
        case wholeData
        case partialData
        case none
    }
    
    // MARK: お気に入りの変更
    // ProductListVCやHomeVCで変更するときに呼び出される
    func changeFavorite(itemParent:ItemParent, callFromSelf:Bool, referer:String = "") ->  Bool {
        
        let favoriteFlag = !itemParent.isFavorite
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        if let favoriteLists = g_favoriteLists {
            if favoriteLists.list.count == 0 {
                confirmAlert(title: "登録できるお気に入りリストが無いため登録できません", message: "作成してください", ok: "確認")
                return favoriteFlag
            }
            if favoriteLists.list.count == 1 {
                let favoriteObj = favoriteLists.list.first!
                if favoriteObj.changeFavorite(itemParentId: itemParent.id, on: favoriteFlag) {      // APIをコールしてサーバのデータを変更する
   
                    if callFromSelf {
  
                    }else{
                        //　自分以外から呼び出された場合はデータを取得し直す
                        _ = getFavoriteData()
                        if favoriteFlag {   // 追加の場合だけ、userLogに残す
                            g_userLog.addFavorite(itemParentId: itemParent.id, pageUrl: referer)
                        }
                    }
                    
                }else{
                    confirmAlert(title: "お気に入りリストへ登録できませんでした", message: "", ok: "確認")
                    return favoriteFlag
                }
  
            }else{
                //　お気に入りリストが複数あるので選択する　　未対応！！
            }
        }
        return favoriteFlag
    }
    
    // 最初はHomeから呼び出される
    func getFavoriteData(delegate:AnyClass? = nil) -> String? {
        if g_processManager == nil { return nil }
        
        if  g_processManager.getStatus(uuid: uuid_favoriteList) == .Running { return nil }    // 実行中なら無視する。　HOMEからコールされてデータの取得中にタブが切り替えられると二重に実行されてしまう可能性があるので、その対策
        self.uuid_favoriteList = g_processManager.addProcess(name:"お気に入りデータの取得", action: getFavoriteListsAndData , errorHandlingLevel: .IGNORE, errorCountLimit: -1, execInterval: 5, immediateExec: true, processType:.Once, delegate:self)

        return uuid_favoriteList
    }

    
    func processCompleted(_ _uuid: String?) {
 
        if g_processManager == nil { return }
        
        if let uuid = _uuid {
            
            switch uuid {
            case uuid_favoriteList:
                if g_processManager.getStatus(uuid: uuid_favoriteList) == .Completed  {

                    if let vc = g_homeVC {
                        vc.processCompleted(uuid)   // HomeVCヘ、お気に入りデータの読み込みが完了したことを通知
                    }
                            
                    LogUtil.shared.log ("お気に入りの読み込み完了")
                    favorites = g_favoriteItems
                    
                    DispatchQueue.main.async {
                        
                        if self.MainTableView != nil {
                            self.MainTableView.refreshControl?.endRefreshing()
                            self.MainTableView.reloadData()
                            
                            if let _ = self.waitIndicator {
                                self.waitIndicator.stopAnimating()
                            }
                            self.nodataCheck()
                        }
                    }
                    
                    DispatchQueue.global().async {
                        for favorite in self.favorites {
                            if !favorite.isHidden {
                                OrosyAPI.cacheImage(favorite.itemParent?.imageUrls.first, imagesize: .None)
                            }
                        }
                    }
                    
                    //　取引ブランドデータを取得
                    if  g_processManager.getStatus(uuid: uuid_connectedList) == .UnDefined {
                        self.uuid_connectedList = g_processManager.addProcess(name:"取引ブランドデータの取得", action:self.getConnectedData , errorHandlingLevel: .IGNORE, errorCountLimit: -1, execInterval: 600, immediateExec: true, processType:.Forever, delegate:self)
                    }
                }
            
            case uuid_connectedList:
                if  g_processManager.getStatus(uuid: uuid_connectedList) == .Completed {
                    DispatchQueue.main.async {
                        if self.ConnectedTableView != nil {
                            self.ConnectedTableView.reloadData()    // ここで落ちたのでnilチェックを追加した
                        }
                    }
                }
            default:
                break
            }
        }
    }
    
    // MARK: データ取得
    let DEFAULT_FAVORITE_LISTNAME = "お気に入りリスト"

    func getFavoriteListsAndData() -> Result<Any?, OrosyError> {
        LogUtil.shared.log("getFavoriteListsAndData: start")
        
        if g_favoriteLists == nil {
            LogUtil.shared.log("お気に入りリストを取得：開始")
            //　お気に入りリストを取得
            let favoriteList = FavoriteLists()
            let result = favoriteList.getNext()
            switch result {
            case .success(_):
                g_favoriteLists = favoriteList
                LogUtil.shared.log("お気に入りリストを取得：完了")
                if favoriteList.list.count == 0 {
                    _ = favoriteList.createFavoriteList(name: "お気に入りリスト")
                    _ = favoriteList.getNext()
                }
                
            case .failure(let error):
                g_favoriteLists = nil
                return .failure(OrosyError.UnknownErrorWithMessage(error.localizedDescription))
            }
        }
        
        let favorlite = g_favoriteLists!
        
        if favorlite.list.count == 0 {
            LogUtil.shared.log("お気に入りリストを作成")
            let result = favorlite.createFavoriteList(name: DEFAULT_FAVORITE_LISTNAME)
            switch result {
            case .success(_):
                break
            case .failure(let error):
                return .failure(error)
            }
        }

        // お気に入りデータを全て取得　　全て取得しておかないと商品とマッチングできないから
   
        selectedFavorList = g_favoriteLists?.list.first // v1ではお気に入りリストは一つしかサポートしていない
        selectedFavorList?.reset()   // 先頭から全て読み直すため、nextTokenを消しておく必要がある
     
        var completed = false
        LogUtil.shared.log("getFavoriteListsAndData: While start")
        var tempArray:[Favorite] = []
        
        while !completed {
            let resultF = selectedFavorList?.getFavoriteItem(full:true, limit: 20)  // お気に入りの最小限の情報だけを取得
            switch resultF {
            case .success(let items):

                if items.count == 0 {
                    completed = true    // 取得できた件数がゼロなのでおしまい
                }else{
                    tempArray.append(contentsOf: items)
                }
            case .failure(_):
                //return .failure(OrosyError.UnknownErrorWithMessage(error.localizedDescription))
                completed = true    //　アカウントを作成した直後でもエラーとなってしまうので、完了として扱うことにした。
            default:
                break
            }
        }
        
        g_favoriteItems = tempArray
        LogUtil.shared.log("getFavoriteListsAndData: While end")
        return .success(nil)
        
    }
    
    // ハートボタンが押された
    @IBAction override func favoriteButtonPushed(_ button: IndexedButton) {

        if let indexPath = button.indexPath {
            // タッチされたことをフィードバック
            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            
            // 押された商品を特定
            let row = indexPath.row

            var itemParent:ItemParent!
            
            let favorite = favorites[row]
            if favorite.isHidden {
                itemParent = ItemParent(id:favorite.itemParentId)   //  FavoriteのItemParentは nil なので、ダミーのオブジェクトを作成する
                itemParent.isFavorite = favorite.isFavorite
            }else{
                itemParent = favorite.itemParent
            }
            // 表示する商品がゼロなら、メッセージを表示
            emptyMessage.isHidden = (favorites.count > 0)
     
            // お気に入りの状態を変更
            let favoriteFlag = self.changeFavorite(itemParent: itemParent, callFromSelf: true)
            
            favorite.isFavorite = favoriteFlag
            MainTableView.reloadRows(at: [indexPath], with: .none)    // changeFavoriteでデータを読み直しているので、データ件数が和変わると落ちる
            
            //　他のビューへ通知
            let reflethNotification = Notification.Name(NotificationMessage.FavoriteReset.rawValue)
            NotificationCenter.default.post(name: reflethNotification, object: nil, userInfo:[ "itemParent":itemParent!, "onOff": favoriteFlag ])
            
        }
        
    }
    
    // お気に入り商品　／　取引ブランドの切替
 
    @IBAction override func productBrandSelected(_ sender: OrosySwitchButton) {
        print (sender.isSelected)
        
        sender.isSelected = !sender.isSelected
        
        favoriteMode = !sender.isSelected
        
        nodataCheck()
        
        
        if favoriteMode {
            // お気に入り商品一覧
            self.MainTableView.isHidden = false
            self.ConnectedTableView.isHidden = true

            let targetUrl = (self.orosyNavigationController?.getNewTargetUrl(self) ?? "") 
            self.orosyNavigationController?.sendAccessLog(targetUrl:targetUrl)
        }else{
            //　ブランド一覧
            self.MainTableView.isHidden = true
            self.ConnectedTableView.isHidden = false
            self.ConnectedTableView.reloadData()

            let targetUrl = RETAILER_SITE_URL + "/brands"
            self.orosyNavigationController?.sendAccessLog(targetUrl:targetUrl)
        }

    }
    
    // MARK: リフレッシュコントロールによる読み直し
    @objc func refreshTable() {
        if let _ = selectedFavorList {
            g_favoriteLists = nil
            favorites.removeAll()
            self.MainTableView.reloadData()
            
            self.getFavoriteData()
            DispatchQueue.main.async {
                self.MainTableView.refreshControl?.endRefreshing()
            }
        }else{
            DispatchQueue.main.async {
                self.MainTableView.refreshControl?.endRefreshing()
            }
        }
    }
    
    @objc func refreshConnectedTable() {

        DispatchQueue.global().async {
            self.connectedSuppliers?.list.removeAll()
            
            _ = self.getConnectedData()
            
        }
    }
    
    // MARK: =====================
    // MARK: 取引ブランド
    func getConnectedData() -> Result<Any?, OrosyError> {
        
        if connectedSuppliers == nil {
            self.connectedSuppliers = ConnectedSuppliers(size:200)   // このAPIは、コネクションがないサプライヤーも返してきて、その中からコネクションがあるものだけを返すので、サイズを大きくしている
            g_connectedSuppliers =  self.connectedSuppliers
        }
        
        var hasAllData = false
        
        while !hasAllData {
            
            let result = self.connectedSuppliers!.getNext()
            
            switch result {
            case .success(let suppliers):
                hasAllData = self.connectedSuppliers?.hasAllData ??  true
                
                for supplier in suppliers ?? [] {
                    _ = supplier.getNextSupplierItemParents()
                    
                    for item in supplier.itemParents {
                        for url in item.imageUrls {
                            OrosyAPI.cacheImage(url, imagesize: .Size100)
                        }
                    }
                }


                DispatchQueue.main.async {
                    if self.ConnectedTableView.refreshControl?.isRefreshing ?? false {
                        self.ConnectedTableView.refreshControl?.endRefreshing()
                        self.ConnectedTableView.reloadData()    // ここで落ちたのでnilチェックを追加した
                        self.nodataCheck()
                    }
                }
                self.connectedSuppliers?.next = "";     // 継続して取得するため、リセットする
                
                // 他のビューへ通知
                let reflethNotification = Notification.Name(NotificationMessage.RefreshApplyStatus.rawValue)
                NotificationCenter.default.post(name: reflethNotification, object: nil, userInfo:nil)
                
                
            case .failure(let error):
                DispatchQueue.main.async {
                    if self.ConnectedTableView.refreshControl?.isRefreshing ?? false {
                        self.ConnectedTableView.refreshControl?.endRefreshing()
                    }
                }
                return .failure(error)
            }
        }
        return .success(nil)
    }
    
    // MARK: スクロール
    var fetchingNextData = false
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollPosY = scrollView.contentOffset.y //スクロール位置
        let maxOffsetY = scrollView.contentSize.height - scrollView.frame.size.height //スクロール領域の高さからスクロール画面の高さを引いた値
        let distanceToBottom = maxOffsetY - scrollPosY //スクロール領域下部までの距離
        let currentPoint = scrollView.contentOffset;    //スクロール位置

        
        // ==============================
        // スクロール方向によってモードバーを非表示にする。

        if !self.ProductBrandSelectViewisHidden && self.scrollBeginingPoint.y < currentPoint.y - 20 && currentPoint.y > 60 {    // 少しスクロールしてから反応させる
            // 下へスクロール
            self.ProductBrandSelectViewisHidden = true
            
            
        }else if self.ProductBrandSelectViewisHidden && (self.scrollBeginingPoint.y > currentPoint.y + 40 || currentPoint.y < 40) {
            // 上へスクロール
            self.ProductBrandSelectViewisHidden = false      // これだけだと、少しだけ下へすくろーつしてスクロールする量が
            
        }else{
            return
        }
        
        openCloseProductBrandSelectView(close:self.ProductBrandSelectViewisHidden)
        
 
        //スクロール領域下部に近づいたら追加で取得する
        if distanceToBottom < 400 && !fetchingNextData {
            fetchingNextData = true
            if let indixes = self.MainTableView.indexPathsForVisibleRows  {  // 見えている範囲の行
                
                DispatchQueue.global().async{
                    let lastRow = indixes.last?.row ?? 0

                    if self.favoriteMode {
                        for row in lastRow..<lastRow + 10 {  // 見えている範囲から後ろの１０件の画像を取得
                            if row < self.favorites.count - 1 {
                                let favorite = self.favorites[row]
                                for url in favorite.itemParent?.imageUrls ?? [] {
                                    OrosyAPI.cacheImage(url, imagesize: .Size500)   // トップの商品サンプル画像
                                }
                            }
                        }
                    }else{
                        
                    }
                }
                
            }
        }
    }
    
    // 商品・モデル選択ビュー
    var ProductBrandSelectViewisHidden = false
    func openCloseProductBrandSelectView(close:Bool) {
        UIView.animate(withDuration: 0.3, // アニメーションの秒数
                       delay: 0.0, // アニメーションが開始するまでの秒数
                       options: [.curveEaseOut], // アニメーションのオプション 等速 | 繰り返し
                       animations: {
            
            self.modePanelTopConstraint.constant = (close) ? -76 : 0
            //self.SearchModePanelView.alpha = (close) ? 0 : 1
            
        }, completion: { (finished: Bool) in
            
        })
    }
}
