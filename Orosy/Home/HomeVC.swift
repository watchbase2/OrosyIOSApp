//
//  ViewController.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/07.
//
/*
    以下の3箇所はUITableViewにUICollectinViewを載せて表示させている
 　   ・先頭のバナー
 　　　・新着商品
 　　　・ショップ一覧の中の商品一覧
 　  このため、CollectionView側の処理で、どのCollectionViewに関するものなのかを判定できる必要がある。
     これを実現するため、OrosyCollectionView　というEtensionを作成し、そこでに、親であるUITableViewのどのIndexPathの値を保持できるようにした。
 
    キーワード検索とカテゴリ検索の商品一覧は　ProductCollectionVC　で表示している
 
 
 */

import UIKit
import SafariServices
import AppTrackingTransparency
import FacebookCore

let RECOMMEND_BRAND_PRODUCTS = false     // リコメンドエンジンによるリコメンド商品を表示

enum HomeItemType:Int {
    case VIEW_HISTORY
    case RECOMMEND
    case SPECIAL
    case SHOP_LIST
    case PROUCT_LIST
    case NEWER          // 新着商品
    case WEEKLY_BRAND   // 週替わりブランド
    case PROMOTION
    case TREND          // トレンド特集
    case ITAKU          // 委託可能なブランド
    case ORDER
    case SHIPPING
    case ITEM
    case TOTAL

}

enum HomeDisplayMode {
    case Home
    case CategorySearchBrand    // カテゴリ検索結果のブランド一覧
    case CategorySearchProduct  // カテゴリ検索結果のプロダクト一覧
    case KeywardSearchBrand     // キーワード検索結果のブランド一覧
    case KeywordSearchProduct   // キーワード検索結果のプロダクト一覧
    case AmazonReccomend        //
}

class HomeDisplayItem: NSObject {
    var itemType:HomeItemType?
    var title:String?
    var cellType:String?
    var itemObject: NSObject?
    var itemHeight:CGFloat
    

    init( type:HomeItemType, title:String?, cell:String?, height:CGFloat ) {
        
        itemType = type
        self.title = title
        cellType = cell
        itemHeight = height
    }
}


// MARK: メイン
class HomeVC: OrosyUIViewController, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching, UISearchResultsUpdating, UISearchBarDelegate, CategorySelectedDelegate, OrosyProcessManagerDelegate, ProductSelectedDelegate,AppNotificationControllerDelegate, SearchBaDelegate {

    @IBOutlet weak var MainTableView: UITableView!                              // ホームコンテンツ表示用
    @IBOutlet weak var mainTableViewTopConstraint: NSLayoutConstraint!

    var recommendSection:IndexPath?

    
    @IBOutlet weak var BrandSearchTableView: UITableView!                       // カテゴリ検索結果、キーワード検索：ブランド表示用
    @IBOutlet weak var ProductResultView: UICollectionView!                     // 検索結果の商品一覧用

    @IBOutlet weak var CategoryTableView: UITableView!                          // カテゴリ一メニュー覧表示用
   // @IBOutlet weak var categoryTableBottomConstraint: NSLayoutConstraint!       // カテゴリーメニューを下にスライドさせて表示するための制約
    @IBOutlet weak var searchControllerTopConstraint: NSLayoutConstraint!       // キーワード検索バーを上にスライドさせて非表示にするための制約
   // @IBOutlet weak var categoryTableCloseConstraint: NSLayoutConstraint!
    @IBOutlet weak var SearchMenuTableHeight: NSLayoutConstraint!
    @IBOutlet weak var waitIndicator: UIActivityIndicatorView!

    @IBOutlet weak var SearchModePanelView: UIView!                             // 商品/ブランド　切り替えボタン　と　新着順/おすすめ純　切り替えボタンを含むビュー
    @IBOutlet weak var orosySwitch:OrosySwitchButton!                           // 商品/ブランド　切り替えボタン
    @IBOutlet weak var searchModeButton: CustomButton!
    @IBOutlet weak var searchModeButtonTitle: OrosyLabel12!
    @IBOutlet var SearchModePanelViewTopConstraint: NSLayoutConstraint!    // 商品/ ブランドの検索モードの切り替えビューの位置制御
    @IBOutlet weak var searchControllerContainer: UIView!
    @IBOutlet weak var searchController: SearchBarVC!                           // キーワード検索バー
    @IBOutlet weak var SearchBarHeightConstraint: NSLayoutConstraint!           // キーワード検索バーの高さ
    

    // productCollectionViewのトップ位置指定
    @IBOutlet var productCollectionTopConstraint: NSLayoutConstraint!               // カテゴリ商品検索結果のトップ位置
    @IBOutlet var productCollectionTopConstraintForKeySearch: NSLayoutConstraint!   // キーワード商品検索結果のトップ位置        isActiveをfalseにするとリリースされてしまうのでweakにはしない
    @IBOutlet var brandTableTopConstraint: NSLayoutConstraint!
    @IBOutlet var brandTableTopConstraintForKeySearch: NSLayoutConstraint!
    
    var searchBarOnNavi:UISearchBar!                                                // ナビバー上へ移動した後の検索バー
    
    var productCollectionVC:ProductCollectionVC!                                    // カテゴリ検索、キーワード検索の商品一覧画面
    var dataReady = false
    var selectedCateogry:Category!
  
    var supplierList:SupplierList!
    var recommendedItemParents:[ItemParent] = []
    
    var banarScrollView:OrosyUICollectionView! {
        didSet {
            autoScrollEnabled() // バナーの自動スクロールを開始
        }
    }
    var scrollPosition:Int = 0

    let CELL_HEIGHT_BANNER:CGFloat = 90
    let CELL_HEIGHT_NEWER:CGFloat = 184
    let CELL_HEIGHT_SHOP:CGFloat = 180                                          // ショップの中の商品一覧の高さ
    
    let openHeight:CGFloat = 200
    let closeHeight:CGFloat = 20
    let MaxProductListCount = 10                                                //　「もっと見る」でオープした時に表示する商品の最大件数
    let BannerScrollTimer:TimeInterval = 4                                      // バナー広告の自動スクロールタイマー　　sec.

    var categoryTableBottomConstraintOriginal: CGFloat!
    var categorySearchVC:CategorySearchVC!
    var currentDisplayMode:HomeDisplayMode = .Home

    
    // アプリ起動時 & フォアグランドへ復帰時に実行
    var uuid_showCase:String?
    var uuid_banner:String?
    var uuid_mainSupplier:String?
    var uuid_subscription:String?
    var uuid_authentication:String?
    var uuid_categoryDisplayName:String?
    var uuid_category:String?
    var uuid_categories:String?
    var initialized_data = false
    var uuid_favoriteList:String?
    var uuid_weeklyBrand:String?
    var uuid_recommended:String?
    
    // 参照ポイント
    var rowForBrandList:IndexPath?
    var rowForRecommentList:IndexPath?
    
    // キーワード検索
    var keywordSearchView:ProductListVC!
    var searcObj:SearchKey!
    var searchedItems:[Item] = []
    
    // カテゴリ検索
    var categorizedItems:[Item] = []
    var selectedBrandMode:Bool = false     // true: ブランド, false:商品
  
    // データ読み込みサイズ
    let ITEMPARENT_BATCH_SIZE = 2
    let SEARCH_BACH_SIZE = 10
    let CATEGORY_SESRCH_INITIAL_BATCH_SIZE = 2
    let CATEGORY_SESRCH_BATCH_SIZE = 10
    /*
        UITableViewのセクションごとに表示する項目の定義
        タイプによって使用するCELLのデザインなどが異なる
        ここで指定するheightは、テーブルビューの行の高さであり、これを変更しても、その中のCollectionViewのセルの高さは変わらない
    */


    override func viewDidLoad() {

        super.viewDidLoad()
        
        if g_userLog == nil {
            g_userLog = UserLog(userId: g_MyId ?? "")
        }
        
        LogUtil.shared.log("Home loaded")
        
        if let navi = self.orosyNavigationController {
            navi.setFirstPageUrl()
        }
        
        g_homeVC = self
        g_homeTabVC = self
        
        waitIndicator.startAnimating()
        
        if #available(iOS 15.0, *) {
            MainTableView.sectionHeaderTopPadding = 0.0
            CategoryTableView.sectionHeaderTopPadding = 0.0
         }

        // キーワード検索のセットアップ   MainTableViewのサイズを元にして、Viewのサイズを設定しているので、サイズが確定してから呼び出す必要がある
        // 検索バーのデザインカスタマイズ
        //searchController.uiSetup()
  
        // 検索メニュのセットアップ
        setupCatgorySearch()
            
        // 検索結果の商品一覧表示のセットアップ
        // setupProductListView()
        //setupDisplay(.Home)     // 商品一覧、カテゴリ検索結果、キーワード検索結果　のどれを表示するのかを設定
        
        selectedBrandMode = true
        orosySwitch.isSelected = selectedBrandMode   // 商品/ブランドの切り替え
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(favoriteReset), name: Notification.Name(rawValue:NotificationMessage.FavoriteReset.rawValue), object: nil)
    
        // APIを使った処理は、TabVCでのログイン処理（認証チェック）が完了すると送られる通知を受けてから行う
        let enc = NotificationCenter.default
        enc.addObserver(self, selector: #selector(enteredIntoForeground), name: Notification.Name(rawValue:NotificationMessage.EnteredIntoForeground.rawValue), object: nil)
        enc.addObserver(self, selector: #selector(checkAuth), name: Notification.Name(rawValue:NotificationMessage.AuthCheck.rawValue), object: nil)    // フォアグランドに復帰したら、このイベントを受けて、データの再取得を開始する
        enc.addObserver(self, selector: #selector(reset), name: Notification.Name(rawValue:NotificationMessage.Reset.rawValue), object: nil)
        
        MainTableView.refreshControl = UIRefreshControl()
        MainTableView.refreshControl?.addTarget(self, action: #selector(refreshMainProducts), for: .valueChanged)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ProductCollectionVC") as! ProductCollectionVC
        vc.currentPageUrl = self.orosyNavigationController?.currentUrl
        
        self.productCollectionVC = vc
        ProductResultView.delegate = vc
        ProductResultView.dataSource = vc
        
        checkTrackingAuthorizationStatus()
        
        test()
    }
    
    func test() {
        

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            
        if let vc = segue.destination as? SearchBarVC {
            searchController = vc
            searchController.delegate = self
        }
    }
 
    // ログアウトしたときに必要な処理
    @objc func reset() {
        uuid_showCase = nil
        uuid_banner = nil
        uuid_mainSupplier = nil
        uuid_subscription = nil
        uuid_authentication = nil
        uuid_categoryDisplayName = nil
        uuid_category = nil
        uuid_categories = nil
        uuid_favoriteList = nil
        uuid_weeklyBrand = nil
        
        initialized_data = false

        supplierList = nil
        
        if g_processManager != nil {
            g_processManager.allStop()
        }
        
        let userDefaults = UserDefaultsManager.shared
        userDefaults.loginId = nil
        userDefaults.selectedDelivelyPlaceId = nil
        userDefaults.selectedPayment = nil
        userDefaults.readPointer = 0
        userDefaults.latestThreadDate = nil
        
        userDefaults.updateUserData()

        g_processManager = nil
        g_banner = nil
        g_weeklyBrand = nil
        g_newerSupplier = nil
        g_categoryDisplayName = nil
        
        //profileCheck()
        
    }
    
    var showHomeFirstTIme = true
    
   override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
       
       if let supplier = g_openBrandPage {
           
           self.showSupplierPage(supplierId: supplier.id)
           g_openBrandPage = nil
           return
       }
       if let itemParent = g_openItemPage {
           self.showProduct(itemParent: itemParent, waitIndicator: nil)
           g_openItemPage = nil
           return
       }
       
        LogUtil.shared.log("viewWillAppear start")
        // viewを切り替えるたびにチェックする
        checkAuth()      // 認証に失敗したらログイン画面が表示される

        if showHomeFirstTIme {      // 最初だけはHomeを開いたことを記録。それ以降はNavigationControllerが勝手に記録する
            showHomeFirstTIme = false
            if let userLog = g_userLog {
                userLog.sendAccessLog(pageUrl: self.orosyNavigationController?.getNewTargetUrl(self) ?? "")
           }
        }

        profileCheck()
       setupDisplay(currentDisplayMode)     // 商品一覧、カテゴリ検索結果、キーワード検索結果　のどれを表示するのかを設定
       
       LogUtil.shared.log("viewWillAppear end")
    }
    
    func profileCheck() {
        if UserDefaultsManager.shared.loginId == nil { return }    // ログインしていない
        if g_profileChecked { return }  // 起動直後のみチェック
        
        if ProfileDetail.shared.hasInputDone && RetailerDetail.shared.hasInputDone {
            UserDefaultsManager.shared.accountStatus = .AccountProfiled
            UserDefaultsManager.shared.updateUserData()

            return
        }
                    
        let accountStatus = UserDefaultsManager.shared.accountStatus
        if accountStatus != .AccountProfiled {
            
            g_profileChecked = true
            // プロファイル入力を完了していない
            showCheckProfileVC()
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        if scrollTimer != nil {
            scrollTimer.invalidate()
            scrollTimer = nil
        }
        
    }

    // 以下の処理はログインに成功しないと呼ばれない
    @objc func enteredIntoForeground() {
        // お気に入りのv1では、Itemparentにお気に入り情報は入ってこないので、お気に入り情報を取得してからメインのリストは取得する必要がある
        // Web側で変更したお気に入り情報を反映させるためには、データを読み直す必要がある。
        
            
        if g_loginMode && g_MyId == nil {
            LogUtil.shared.log("MyId is null. Can not start EnteredIntoForeground")

            return
        }

        
        AppNotification.shared.checkActionData()
        
        DispatchQueue.main.async {
            self.waitIndicator.startAnimating()
        }
        
        LogUtil.shared.log("Start EnteredIntoForeground")
        
        initialized_data = false
     
        // 週替わりブランド
        if g_weeklyBrand == nil {
            g_weeklyBrand = Recommend(.WEEKLY_BRAND)
            uuid_weeklyBrand = nil
        }
        uuid_weeklyBrand = g_processManager.addProcess(name:"週替わり情報を取得", action: self.getWeeklyBrands, errorHandlingLevel: .IGNORE, errorCountLimit: 5, execInterval: 2, immediateExec: true, processType:.Once, delegate:self)

        // 新着情報を取得
        if g_newerSupplier == nil {
            g_newerSupplier = ShowcaseSuppliers(.NEWER)
            uuid_showCase = nil
        }
        uuid_showCase =  g_processManager.addProcess(name:"新着データ取得", action: self.getShowcaseSuppliers, errorHandlingLevel: .IGNORE, errorCountLimit: 5, execInterval: 5, immediateExec: true, processType:.Once, delegate:self)     //  取得できなかった場合は、suppliers.count がゼロになる
    
        //　お気に入りを取得
        uuid_favoriteList = getFavoriteListsAndData()

        //
        /*
        if g_categoryDisplayName == nil {
            g_categoryDisplayName = CategoryDisplayName()
            uuid_categoryDisplayName = nil
        }
         */
        uuid_categoryDisplayName = g_processManager.addProcess(name:"カテゴリ表示名取得", action: g_categoryDisplayName.get, errorHandlingLevel: .IGNORE, errorCountLimit: 5, execInterval: 5, immediateExec: true, processType:.Once, delegate:self)
 
        AppNotification.shared.appExecute()    // やり残したアクションがあれば実行する（ログイン直後でViewがまだ準備できていない時などにアクションが未実行で残る場合がある）

    }

    
    func showAppStore() {
        if let url =  URL(string: OrosyAppStoreUrl) {
                
            let safariViewController = SFSafariViewController(url:url)
                                              
            present(safariViewController, animated: false, completion: nil)
        }
    }
        
    func processCompleted(_ _uuid:String? ) {
        
        if g_processManager == nil { return }
        
        if let uuid = _uuid {
            
            switch uuid {
                
            case uuid_mainSupplier:
                DispatchQueue.main.async {
                    self.MainTableView.refreshControl?.endRefreshing()
                    self.waitIndicator.stopAnimating()
                    self.MainTableView.reloadData()
                }
                break
            case uuid_recommended:
              //  self.MainTableView.reloadSections(IndexSet(integer: 4), with: .none)    //  切り替えボタンを更新
                break
            case uuid_weeklyBrand:
                break
            case uuid_banner:
                break
    
            case uuid_showCase:
                break

            case uuid_categoryDisplayName:
                
                _ = Categories.shared.getCategories()
    
            case uuid_categories:
                DispatchQueue.main.async {
                    self.categorySearchVC.setCategoryList = Categories.shared.list
                    self.searchController.setCategoryList = Categories.shared.list
                   // self.CategoryTableView.reloadData()   // ここでリロードしてはいけない
                }
            case  uuid_favoriteList:
                // バナー情報を取得     お気に入りと付き合わせるため、お気に入りの取得の後でないといけない
               if g_banner == nil {
                   autoScrollDisabled()
                   uuid_banner = nil
                   uuid_banner = g_processManager.addProcess(name:"バナー情報を取得", action: self.getBanners, errorHandlingLevel: .IGNORE, errorCountLimit: 3, execInterval: 2, immediateExec: true, processType:.Once, delegate:self)
               }
                
            default:
                break
            }
        }
 
        // メインのリストを取得
        if g_processManager.getStatus(uuid: uuid_mainSupplier) == .UnDefined && g_processManager.getStatus(uuid: uuid_categoryDisplayName) == .Completed && g_processManager.getStatus(uuid: g_faveriteVC?.uuid_favoriteList) == .Completed {
         
            if supplierList == nil {
                supplierList = SupplierList()
                _ = supplierList.initMain(tableView: MainTableView )   // メインとカテゴリ用のデータセットを初期化
                _ = supplierList.initCategory(tableView: BrandSearchTableView)
                
                uuid_mainSupplier = g_processManager.addProcess(name:"サプライヤの初期情報を取得", action: setSuppierQueryFirstForMain, errorHandlingLevel: .ALERT, errorCountLimit: -1, execInterval: 5, immediateExec: true, processType:.Once, delegate:self)

            }
            if recommendedItemParents == [] {
                uuid_recommended = g_processManager.addProcess(name:"Amazonリコメンドを取得", action: getReccomendedItemParents, errorHandlingLevel: .IGNORE, errorCountLimit: 5, execInterval: 5, immediateExec: true, processType:.Once, delegate:self)

            }
        }
        
        // 全てのデータを読み終わったら、まとめてテーブルを更新する
        //  新着データ、週替わり情報、サプライヤの初期情報の取得を完了したら先へ進む
       if !initialized_data && g_processManager.getStatus(uuid: uuid_showCase) == .Completed  && g_processManager.getStatus(uuid: uuid_weeklyBrand) == .Completed  && g_processManager.getStatus(uuid: uuid_banner) == .Completed && g_processManager.getStatus(uuid: uuid_mainSupplier) == .Completed  {
            
            //dataReady = true
            uuid_categories = g_processManager.addProcess(name:"カテゴリデータ取得", action:self.getCategories , errorHandlingLevel: .IGNORE, errorCountLimit: -1, execInterval: 5, immediateExec: true, processType:.Once, delegate:self)
            
            DispatchQueue.main.async {
                self.MainTableView.reloadData()
                self.waitIndicator.stopAnimating()
            }
            
            initialized_data = true
            
            let nextLoad = Notification.Name(NotificationMessage.SecondDataLoad.rawValue)   // 各タブのデータ更新を依頼
            NotificationCenter.default.post(name: nextLoad, object: nil, userInfo: nil)
            
        }
    }

    // MARK: リコメンド商品
    var recommendedItemParentIds:[[String:String]] = []     // リコメンド商品の全リスト。この中から実際に表示可能なものを抽出し、済んだものは順次消していくので最終的にはゼロのなる。
    var recommend:RecommendedItems?                         // 実際に表示するリコメンド商品のリスト（スクロールに応じて増えていく）

    
    func getReccomendedItemParents() -> Result<Any?,OrosyError> {   // Amazon Reccomendation
        
        if fetchingNextDataForMaintable { return .success(true)}
        fetchingNextDataForMaintable = true
        
        let reccomendStep = 5       //　一度にgetItemsByItemIdsで取得する件数
        var addedIndexPaths:[IndexPath] = []

        
        if recommend == nil {
            let MaxNumber = 500 // リコメンドのリストを取得する件数
            recommend = RecommendedItems()
            recommendedItemParentIds = recommend!.getReccomendedItems(size:MaxNumber)
        }
        
        var maxNumber = recommendedItemParentIds.count
        let startRow = self.recommendedItemParents.count    // 行を追加する戦闘位置
        var tempArray:[[String:String]] = []
        var newItemParents:[ItemParent] = []
        var tempItem:[ItemParent] = []
               
        while maxNumber > 0 {
            let STEP = reccomendStep   //　一度にgetItemsByItemIdsで取得する件数
            
        //    for _ in stride(from: 0, to: maxNumber, by: STEP) {

                var removeArray:[Int] = []

                for  _ in 0 ..< STEP * 3 {
                    let randomNum = Int.random(in: 0...maxNumber - 1)
                    let recommendDic = recommendedItemParentIds[randomNum]
                    
                    var find = false
                    
                    for dic in tempArray {
                        if dic["itemParentId"] == recommendDic["itemParentId"] { find = true; break }   // 同じものがなければ追加
                    }
                    
                    if !find {
                        tempArray.append(recommendDic)
                        removeArray.append(randomNum)
                    }
                    
                 }
                
                removeArray.sort { $0 > $1 }

                for removePoint in removeArray {
                    recommendedItemParentIds.remove(at: removePoint)
                }
                
                newItemParents.append(contentsOf:  recommend!.getItemsByItemIds(itemIds:tempArray))
                tempArray.removeAll()
                
                maxNumber = recommendedItemParentIds.count
                if newItemParents.count > reccomendStep { break }    // とりあえず、reccomendStep 件まで取得する      全てのリコメンドに関する情報を取得できるわけではない（古いものやなくなったものなどがある）

        }

        if newItemParents.count > 0 {
            var row = startRow
            
            for item in newItemParents {
                /*
                for sup in g_connectedSuppliers?.list ?? [] {
                    if item.supplier?.id ?? "" == sup.id {
                        item.supplier?.connectionStatus = .ACCEPTED     // 連携しているサプライヤー
                        break
                    }
                }
                 */
                let indexPath = IndexPath(row:row , section:4)
                addedIndexPaths.append(indexPath)
                row += 1
                tempItem.append(item)     // 表示用配列へ追加
                
            }
            
            DispatchQueue.main.async {
                self.recommendedItemParents.append(contentsOf: tempItem)     // 表示用配列へ追加
                print(self.recommendedItemParents.count)
                
                self.MainTableView.beginUpdates()
                self.MainTableView.insertRows(at: addedIndexPaths, with: .none)
                self.MainTableView.endUpdates()
                self.fetchingNextDataForMaintable = false
            }
            
            DispatchQueue.global().async {
                for item in self.recommendedItemParents {
                    if item.imageUrls.count > 0 {
                        OrosyAPI.cacheImage(item.imageUrls.first, imagesize: .Size200)
                    }
                }
            }
            
        }else{
            self.fetchingNextDataForMaintable = false
        }
         
        return .success(true)
            

    }
   
    
    func getCategories() -> Result<Any?,OrosyError> {
        Categories.shared.getCategories()
        
    }
    
    func getFavoriteListsAndData()  -> String? {
        // FavoriteVCの関数を呼び出す
        var uuid:String? = nil
        
        if let vc = g_faveriteVC {
            uuid = vc.getFavoriteData()
        }
        return uuid
    }
    

    func getShowcaseSuppliers()  -> Result<Any?, OrosyError> {
        
        if let ns = g_newerSupplier {
            let result = ns.getShowcaseSuppliers()
            
            switch result {
            case .success(_):
                // 拡張データをセット
                for sup in g_newerSupplier?.suppliers ?? [] {
                    let extendData = ExtendSupplier()
                    extendData.showMore = false
                    sup.extendData = extendData
                    
                    let imgUrl = (sup.imageUrls.count > 0) ? sup.imageUrls.first : nil
                    OrosyAPI.cacheImage(imgUrl, imagesize: .Size200)
                }
                return .success(nil)
            case .failure(let error):
                return .failure(error)
            }
        }
        return .failure(OrosyError.NotInitialized)
    }

    func getWeeklyBrands()  -> Result<Any?, OrosyError> {
        
        return getRecommendedData(bannerObj:g_weeklyBrand)
    }
    
    
    func getRecommendedData(bannerObj:Recommend)  -> Result<Any?, OrosyError> {
        let result = bannerObj.getReccomend()
        
        switch result {
        case .success(_):
            // 拡張データをセット
            for sup in bannerObj.recommendShops {
                let extendData = ExtendSupplier()
                extendData.showMore = false
                sup.extendData = extendData     // このデータには、広告用の最低限の情報しか含まれていないので、ブランドページの画像を先読みするためには、shop_idからSupplierを読み出す必要がある。
                
                DispatchQueue.global().async {
                    OrosyAPI.cacheImage(sup.imageUrl, imagesize: .Size200)
                }
            }
            
            return .success(nil)
        case .failure(let error):
            return .failure(error)
        }
    }

    
    func getBanners()  -> Result<Any?, OrosyError> {
        g_banner = ShowcaseContents(slug: .MIDDLE)
        if g_banner != nil {
            // 拡張データをセット
            for sup in g_banner.contents {
                let extendData = ExtendSupplier()
                extendData.showMore = false
                sup.extendData = extendData
                
                DispatchQueue.global().async {
                    OrosyAPI.cacheImage(sup.imageUrl, imagesize: .None)
                }
            }
            return .success(nil)
        }else{
            return .failure(OrosyError.NotInitialized)
        }
    }
    

    var lastDisplayMode:HomeDisplayMode = .Home
    
    // 表示モードに応じた設定
    func setupDisplay(_ _currentMode:HomeDisplayMode) {
        
        lastDisplayMode = currentDisplayMode
        currentDisplayMode = _currentMode
        
        DispatchQueue.main.async {
            
            switch self.currentDisplayMode {
            case .Home:
                self.setNaviTitle(title: "orosy_logo", logo:true)
                self.MainTableView.isHidden = false
                self.searchControllerContainer.isHidden = false

                self.BrandSearchTableView.isHidden = true
                self.SearchModePanelView.isHidden = true
                self.ProductResultView.isHidden = true
                if let vc = self.keywordSearchView {
                    vc.view.isHidden = true
                }
 
                let categoryMenu = UIImage(named: "humbergerMenu")?.withRenderingMode(.alwaysOriginal)
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: categoryMenu, style:.plain, target: self, action: #selector(self.showCategorySearchView))
                let accountMenu = UIImage(named: "config")?.withRenderingMode(.alwaysOriginal)
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: accountMenu, style:.plain, target: self, action: #selector(self.showAccount))
                self.searchControllerTopConstraint.constant = 0
              //  self.mainTableViewTopConstraint.constant = 54
                
            case .CategorySearchBrand:
                self.setNaviTitle(title: self.selectedCateogry.name)
                self.SearchModePanelView.isHidden = false
                self.SearchModePanelViewTopConstraint.constant = 0
                self.orosySwitch.isHidden = false
                self.BrandSearchTableView.isHidden = false
                
                self.MainTableView.isHidden = true
                self.searchControllerContainer.isHidden = true
                self.ProductResultView.isHidden = true
                if let vc = self.keywordSearchView {
                    vc.view.isHidden = true
                }
                self.brandTableTopConstraint.isActive = true
                self.brandTableTopConstraintForKeySearch.isActive = false
                self.orosySwitch.isSelected = true
                
            case .CategorySearchProduct:
                self.setNaviTitle(title: self.selectedCateogry.name)
                self.ProductResultView.isHidden = false
                self.SearchModePanelView.isHidden = false
                self.SearchModePanelViewTopConstraint.constant = 0
                self.orosySwitch.isHidden = false
                
                self.searchControllerContainer.isHidden = true
                self.MainTableView.isHidden = true
                self.BrandSearchTableView.isHidden = true
  
                if let vc = self.keywordSearchView {
                    vc.view.isHidden = true
                }
                self.productCollectionTopConstraint.constant = 118
                self.productCollectionTopConstraint.isActive = true
                self.productCollectionTopConstraintForKeySearch.isActive = false
                self.orosySwitch.isSelected = false
                
                
            case .KeywardSearchBrand:
                self.BrandSearchTableView.isHidden = false
                self.ProductResultView.isHidden = true
                self.searchControllerContainer.isHidden = false
                self.SearchModePanelView.isHidden = true
                if let vc = self.keywordSearchView {
                    vc.view.isHidden = false
                }
                self.brandTableTopConstraint.isActive = false
                self.brandTableTopConstraintForKeySearch.isActive = true

            case .KeywordSearchProduct:
                self.SearchModePanelView.isHidden = false
                self.ProductResultView.isHidden = false
                self.searchControllerContainer.isHidden = false
                self.SearchModePanelView.isHidden = true
                self.MainTableView.isHidden = true
                self.BrandSearchTableView.isHidden = true
                if let vc = self.keywordSearchView {
                    vc.view.isHidden = false
                }

                self.productCollectionTopConstraint.constant = self.searchController.miniHeight + 10
                self.productCollectionTopConstraintForKeySearch.isActive = true
                self.productCollectionTopConstraint.isActive = false
                
            case .AmazonReccomend:
                self.MainTableView.isHidden = false
                //  self.mainTableViewTopConstraint.constant = 54
                self.SearchModePanelView.isHidden = true
                self.searchControllerContainer.isHidden = false
               // self.searchControllerTopConstraint.constant = 0
                self.selectedBrandMode = false
                break;
            }
        }
    }
    
    @objc func changeDisplayModeToHome() {

        searchController.closeSearchBar()  // キーワード検索バーをクローズする
        setupDisplay(.Home)
        noDataAlert.isHidden = true

    }
    

    func setSuppierQueryFirstForMain() -> Result<Any?, OrosyError> {
        
        if supplierList.nextData(tableView:MainTableView) >= 0{
            return .success(nil)
        }else{
            return .failure(OrosyError.DataReadError)
        }
    }
   

    func setSupplierQuery(targetTableView:UITableView) {
    
        LogUtil.shared.log( "setSupplierQuery")
        if targetTableView == MainTableView && fetchingNextDataForMaintable { return }
        
        fetchingNextDataForMaintable = true
        
        DispatchQueue.global().async {
            // let semaphore = DispatchSemaphore(value: 0)
            var count:Int = 0
            var lastIndex:Int = 0
            let targetSection = (targetTableView == self.MainTableView) ? self.BrandSection : 0     // 3はサプライヤー一覧のセクション
            
            
            if let supplierDataSet = self.supplierList.getDataSetFor(tableView: targetTableView) {
                let item = supplierDataSet.displayItem[targetSection]
                if  item.itemType == .SHOP_LIST {
                    
                    lastIndex = supplierDataSet.suppliers?.list.count ?? 0
                    LogUtil.shared.log("現在の最後の行 : \(lastIndex) ")
                    
                }
            }
            
            // ここで次のデータを取得している
            count = self.supplierList.nextData(tableView:targetTableView)
            
            if count == -1 {
                LogUtil.shared.log( "データを取得できませんでした")
                self.fetchingNextDataForMaintable = false
                return
            }
            
            DispatchQueue.main.async {
                LogUtil.shared.log( "データを取得:supplierList.nextData 完了")
                
                targetTableView.beginUpdates()
                LogUtil.shared.log("current count:\(lastIndex),  add count:\(count) ")
                var addedIndexPaths:[IndexPath] = []
                for ip in 0..<count  {
                    addedIndexPaths.append(IndexPath(row:lastIndex + ip, section: targetSection))
                }
                targetTableView.insertRows(at: addedIndexPaths, with: .none)
                targetTableView.endUpdates()
                self.fetchingNextDataForMaintable = false
                
                LogUtil.shared.log( "targetTableView.insertRows 終了")
                
            }
            
            LogUtil.shared.log( "setSupplierQuery: End ")
        }
    }

    // MARK: UITableView
    func numberOfSections(in tableView: UITableView) -> Int {
        var count = 0
        
        if supplierList == nil { return 0 }
        let supplierDataSet = supplierList.getDataSetFor(tableView: tableView)
        count = supplierDataSet?.displayItem.count ?? 0

        return count           // バナー、新着情報、ショップリストはセクションで分けている
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        var height:CGFloat = 0
        
        if (currentDisplayMode == .Home || currentDisplayMode == .AmazonReccomend) && recommendedItemParents.count > 0 {    // データを取得できていたらリコメンドを選択するモード切替ボタンを表示する
            if let supplierDataSet = supplierList.getDataSetFor(tableView: tableView) {
                let item = supplierDataSet.displayItem[section]

                let itemType = item.itemType

                if itemType == .SHOP_LIST {
                    height = (currentDisplayMode == .AmazonReccomend) ? 0 : 80
                }else if itemType == .RECOMMEND {
                    recommendSection = IndexPath(row: 0, section: section)
                    height = (currentDisplayMode == .AmazonReccomend) ? 80 : 0
                }
            }
        }
        
        return height
    }
        
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == RecommendSection { return 20 }else{ return 0 }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        var view:UIView? = nil
        
        if let supplierDataSet = supplierList.getDataSetFor(tableView: tableView) {
            let item = supplierDataSet.displayItem[section]

            let itemType = item.itemType

            if itemType == .SHOP_LIST && section == BrandSection {

                if let cell = tableView.dequeueReusableCell(withIdentifier: "ModeSelectCell") {
                    view = cell.contentView
                    if let button = view?.viewWithTag(10) as? OrosySwitchButton {
                        button.isSelected = true
                        button.indexPath = IndexPath(row:0, section:section)
                    }
                }
            }else if itemType == .RECOMMEND {
                if let cell = tableView.dequeueReusableCell(withIdentifier: "ModeSelectCell") {
                    view = cell.contentView
                    if let button = view?.viewWithTag(10) as? OrosySwitchButton {
                        button.isSelected = false
                        button.indexPath = IndexPath(row:0, section:section)
                    }
                }
            }
        }

        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        var height:CGFloat = 0
        
        let section = indexPath.section
        let row = indexPath.row

        if let supplierDataSet = supplierList.getDataSetFor(tableView: tableView) {
            let item = supplierDataSet.displayItem[section]
            let suppliers = supplierDataSet.suppliers!
            
            let itemType = item.itemType
            
            switch itemType {
            case .SHOP_LIST:
                //　画面幅に応じて画像の高さが変わるため、画面幅から高さを算出
                
                if currentDisplayMode == .AmazonReccomend {
                    return 0
                }else{
                    if suppliers.list.count > row {
                        if let extendData = suppliers.list[row].extendData as? ExtendSupplier {
                            let open = extendData.showMore
                            height = self.view.bounds.width - 30 + 115 + ((open) ? openHeight : closeHeight)
                        }
                    }
                }
   
            case .PROMOTION:
                height = item.itemHeight
            case .WEEKLY_BRAND:
                height = item.itemHeight
            case .NEWER:
                height = item.itemHeight
            case .RECOMMEND:
                if currentDisplayMode == .AmazonReccomend {
                    return UITableView.automaticDimension //自動設定
                }else{
                    height = 0
                }
            default:
                height = 0
            }
        }
  
        return height
        
    }
     
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 1


        if let supplierDataSet = supplierList.getDataSetFor(tableView: tableView) {
            let item = supplierDataSet.displayItem[section]
            let itemType = item.itemType
            
            switch itemType {
            case .SHOP_LIST:
                /*
                if currentDisplayMode == .AmazonReccomend {
                    count = 0
                }else{
                 */
                    count = supplierDataSet.suppliers?.list.count ?? 0
                    print("\(section): \(supplierDataSet.displayMode) : \(count) ")
              //  }
    
            case .WEEKLY_BRAND:
                if (g_weeklyBrand?.recommendShops.count ?? 0) > 0 {
                    count = 1
                }else{
                    count = 0       //　まだデータを取得できていない時
                }
            case .PROMOTION:
                if (g_banner?.contents.count ?? 0) > 0 {
                    count = 1
                }else{
                    count = 0       //　まだデータを取得できていない時
                }
            case .NEWER:
                count = 0
                if let sc = g_newerSupplier?.suppliers {
                    if sc.count > 0 {
                        count = 1
                    }
                }
            case .RECOMMEND:
               // if currentDisplayMode == .AmazonReccomend {
                count = recommendedItemParents.count
                /*
                }else{
                    count = 0
                }
                 */
            default:
                if supplierDataSet.displayMode == .Home {
                    count = 1
                }else{
                    count = 0
                }
            }
   
        }else{
            count = 0
        }
  

        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell!

        let row = indexPath.row
        let section = indexPath.section
        

            let supplierDataSet = supplierList.getDataSetFor(tableView: tableView)
            
            let item = supplierDataSet!.displayItem[section]
            let itemType = item.itemType
            
            switch itemType {
            case .PROMOTION:

                cell = tableView.dequeueReusableCell(withIdentifier: item.cellType!, for: indexPath)
                if let collectionView = cell.viewWithTag(200) as? OrosyUICollectionView {
                    collectionView.indexPath = indexPath
                    collectionView.displayMode = .Home
                    collectionView.decelerationRate = .fast
                    banarScrollView = collectionView
                }
            case .WEEKLY_BRAND:

                cell = tableView.dequeueReusableCell(withIdentifier: item.cellType!, for: indexPath)
                let title = cell.viewWithTag(1) as! UILabel
                title.text = g_weeklyBrand.shortTitle ?? ""
                
                if let collectionView = cell.viewWithTag(200) as? OrosyUICollectionView {
                    collectionView.indexPath = indexPath
                    collectionView.displayMode = .Home
                    collectionView.decelerationRate = .fast
                   
                }
            case .NEWER:
                cell = tableView.dequeueReusableCell(withIdentifier: item.cellType!, for: indexPath)
                let title = cell.viewWithTag(1) as! UILabel
                title.text = item.title
                
                if let collectionView = cell.viewWithTag(200) as? OrosyUICollectionView {
                    collectionView.tag = itemType!.rawValue     // どのタイプのデータを表示するのかを保存
                    collectionView.indexPath = indexPath
                    collectionView.displayMode = .Home
                }
                
            case .SHOP_LIST:
            
                tableView.register(UINib(nibName: "CommonShopSB", bundle: nil), forCellReuseIdentifier: item.cellType!)
                cell = tableView.dequeueReusableCell(withIdentifier: item.cellType!, for: indexPath)
                
                // 商品表示用のコレクションビュー
                let collectionView = cell.contentView.viewWithTag(200) as! OrosyUICollectionView
                collectionView.indexPath = indexPath
                collectionView.displayMode = (tableView == MainTableView) ? .Home : .CategorySearchBrand
                collectionView.delegate = self
                collectionView.dataSource = self
                collectionView.prefetchDataSource = self
                
                let supplierDataSet = supplierList.getDataSetFor(tableView: tableView)
                let displayMode = supplierDataSet!.displayMode
                
                if let sup = supplierDataSet?.suppliers {
                    if row < sup.list.count  {
                        let supplier = supplierDataSet!.suppliers!.list[row] 
                        
                        let baseView = cell.contentView.viewWithTag(100)! as? OrosyUIView
                        baseView?.drawBorder(cornerRadius: 4)
                        
                        let shopConceptImageView = cell.contentView.viewWithTag(1) as! OrosyUIImageView500
                        
                        let shopIconView = cell.contentView.viewWithTag(2) as! OrosyUIImageView100

                        let titleLabel = cell.contentView.viewWithTag(3) as! UILabel
                        let categoryLabel = cell.contentView.viewWithTag(4) as! UILabel
                        let moreButton = cell.contentView.viewWithTag(6) as! UIButton       // ボタンとしては使っていない。ボタンアイコ表示用として使用している
                        
                        if supplier.extendData != nil {
                            moreButton.isSelected = (supplier.extendData as! ExtendSupplier).showMore
                        }
                        
                        var imageViews:[OrosyUIImageView] = []
                        imageViews.append(cell.contentView.viewWithTag(10) as! OrosyUIImageView100)
                        imageViews.append(cell.contentView.viewWithTag(11) as! OrosyUIImageView100)
                        imageViews.append(cell.contentView.viewWithTag(12) as! OrosyUIImageView100)
                        imageViews.append(cell.contentView.viewWithTag(13) as! OrosyUIImageView100)
                        
                        // サプライヤー選択用のトランスペアレントなボタン
                        let supplierButton = cell.contentView.viewWithTag(101) as! IndexedButton
                        supplierButton.indexPath = indexPath
                        supplierButton.baseView = baseView
                        supplierButton.displayMode = displayMode
                        supplierButton.addTarget(self, action: #selector(gotoSupplierPage), for: .touchUpInside)
                        
                        // 「もっと見る」用のトランスペアレントなボタン
                        let showMoreButton = cell.contentView.viewWithTag(102) as! IndexedButton
                        showMoreButton.indexPath = indexPath
                        showMoreButton.displayMode = displayMode
                        showMoreButton.baseView = baseView
                        showMoreButton.collectionView = collectionView
                        showMoreButton.cell = cell
                        showMoreButton.addTarget(self, action: #selector(showMore), for: .touchUpInside)
                        
                        shopConceptImageView.image = nil
                        shopConceptImageView.targetRow = row
                        shopConceptImageView.getImageFromUrl(row: row, url: supplier.imageUrls.first, defaultUIImage: g_defaultImage)
                        shopConceptImageView.drawBorder(cornerRadius: 0)
                        
                        //shopIconView.image = nil
                        shopIconView.getImageFromUrl(row: row, url: supplier.iconImageUrl, defaultUIImage: g_defaultImage)
                        shopIconView.drawBorder(cornerRadius: shopIconView.bounds.height / 2)
                        
                        titleLabel.text = supplier.brandName

                        categoryLabel.text = g_categoryDisplayName.getDisplayName(supplier.category)
                        
                        // 代表画像を4つまでセット
                        for ip in 0..<4 {

                            let imageView = imageViews[ip]
                            imageView.image = nil
                            
                            let itemParents = supplier.itemParents
                            if ip < itemParents.count {
                                
                                imageView.targetRow = row
                                imageView.drawBorder(cornerRadius: 0)
                                if itemParents[ip].imageUrls.count > 0 {
                                    let url = itemParents[ip].imageUrls.first
                                    imageView.getImageFromUrl(row: row, url: url, defaultUIImage: g_defaultImage)
                                    imageView.drawBorder(cornerRadius: 0, color: UIColor.orosyColor(color: .Gray300), width: 1)
                                }
                            }else{
                                imageView.hideBorder()
                            }
                        }
                        if supplier.extendData != nil {
                            (supplier.extendData as! ExtendSupplier).activityIndicator = cell.viewWithTag(110) as? UIActivityIndicatorView
                        }
                      collectionView.reloadData()
                    }else{
                        print("empty data")
                    }
                }
                
            case .RECOMMEND:
                // Amazon Reccomendation
                
                cell = tableView.dequeueReusableCell(withIdentifier: item.cellType!, for: indexPath)
                let imageView = cell.contentView.viewWithTag(1) as! OrosyUIImageView200
                let title = cell.contentView.viewWithTag(2) as! UILabel
                let catarogPriceLabel = cell.contentView.viewWithTag(3) as! UILabel
                let catarogPrice = cell.contentView.viewWithTag(13) as! UILabel
                let wholesalePriceLabel = cell.contentView.viewWithTag(4) as! UILabel
                let wholesalePrice = cell.contentView.viewWithTag(14) as! UILabel
                let wholesale_lockIcon = cell.contentView.viewWithTag(6) as! UIImageView
                let disconProductLabel = cell.contentView.viewWithTag(7) as! UILabel
                disconProductLabel.isHidden = true
                let favoriteButton = cell.contentView.viewWithTag(10) as! IndexedButton
                let selectedButton = cell.contentView.viewWithTag(11) as! IndexedButton
                
                var itemParent:ItemParent!


                itemParent = recommendedItemParents[row]

                favoriteButton.isSelected = itemParent.isFavorite
                
                if let item = itemParent.item {
                    
                    imageView.targetRow = row
                    imageView.image = nil
                    imageView.getImageFromUrl(row: row, url: itemParent.imageUrls.first, defaultUIImage: g_defaultImage)      //
                    imageView.drawBorder(cornerRadius:0, color:UIColor.orosyColor(color: .Gray300), width:1)
                    catarogPriceLabel.isHidden = false
                    wholesalePriceLabel.isHidden = false
                    title.text = item.title
                    catarogPrice.text = Util.number2Str(item.catalogPrice)
                    
                    
                    if itemParent.supplier?.connectionStatus == .ACCEPTED {
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

                favoriteButton.indexPath = indexPath
                selectedButton.indexPath = indexPath
                
            default:
                break;
            }
            
    
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
     
   
            let cell = self.tableView(tableView, cellForRowAt: indexPath)
            if let indicator = cell.viewWithTag(20) as? UIActivityIndicatorView {
                
                let itemParent = recommendedItemParents[row]
                self.showProduct(itemParent: itemParent, waitIndicator:indicator)    // 商品ページへ遷移
                    
            }
 
    }
    
    // セルが表示される前に必要な画像をキャッシュしておく
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        return
        
        if tableView == MainTableView && currentDisplayMode != .AmazonReccomend{
            LogUtil.shared.log("Main: prefetchRowsAt")
            for indexPath in indexPaths {
                let section = indexPath.section
                let row = indexPath.row
                
                var supplierDataSet = supplierList.getDataSetFor(tableView: tableView)
        
                let item = supplierDataSet!.displayItem[section]
                let itemType = item.itemType

                if itemType == .SHOP_LIST {
                    if let list = supplierDataSet?.suppliers?.list {
                        if row < list.count {
                            let supplier = list[row]
                            let imageCacheObject = ImageCacheObject()
                            imageCacheObject.cacheImageForSuppilerPrefetch(supplier: supplier)
                            supplier.imageCacheObject = imageCacheObject
                            
                            /*
                            OrosyAPI.cacheImage(supplier.imageUrls.first, imagesize: .Size200)
                            OrosyAPI.cacheImage(supplier.iconImageUrl, imagesize: .Size100)

                            for ip in 0..<4 {
                                if ip < supplier.imageUrls.count - 1 {
                                    let url  = supplier.imageUrls[ip + 1]
                                    OrosyAPI.cacheImage(url, imagesize: .Size200)
                                }
                            }
                            */
                        }
                    }
                }
            }
            LogUtil.shared.log("Main: prefetchRowsAt: Done")
            
        }else if tableView == BrandSearchTableView {
            
        }
        
        /*
        if tableView == MainTableView {
            
            if currentDisplayMode == .AmazonReccomend {
                
             //   getReccomendedItemParents()
                
            }else{
                LogUtil.shared.log("次のデータをフェッチ")
     
                self.setSupplierQuery(targetTableView: self.MainTableView)
                
                LogUtil.shared.log("次のデータをフェッチ完了")
                
                LogUtil.shared.log("Main: prefetchRowsAt")
                
                DispatchQueue.global().async {
                    for indexPath in indexPaths {
                        let section = indexPath.section
                        let row = indexPath.row
                        
                        let supplierDataSet = self.supplierList.getDataSetFor(tableView: tableView)
                        
                        let item = supplierDataSet!.displayItem[section]
                        let itemType = item.itemType
                        
                        if itemType == .SHOP_LIST {
                            if let list = supplierDataSet?.suppliers?.list {
                                if row < list.count {
                                    let supplier = list[row]
                                    
                                    OrosyAPI.cacheImage(supplier.imageUrls.first, imagesize: .Size200)
                                    OrosyAPI.cacheImage(supplier.iconImageUrl, imagesize: .Size100)
                                    
                                    for ip in 0..<4 {
                                        if ip < supplier.imageUrls.count - 1 {
                                            let url  = supplier.imageUrls[ip + 1]
                                            OrosyAPI.cacheImage(url, imagesize: .Size200)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
            }
         }
        */

    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 未実行のプリフェッチをキャンセルする --.> TableViewによるプリフェッチをやめたので未滋養
        return
        
        if tableView == MainTableView && currentDisplayMode != .AmazonReccomend{
            LogUtil.shared.log("Main: prefetchRowsAt")
  
            let section = indexPath.section
            let row = indexPath.row
            
            var supplierDataSet = supplierList.getDataSetFor(tableView: tableView)
            
            let item = supplierDataSet!.displayItem[section]
            let itemType = item.itemType
            
            if itemType == .SHOP_LIST {
                if let list = supplierDataSet?.suppliers?.list {
                    if row < list.count {
                        let supplier = list[row]
                        if let cacheObject = supplier.imageCacheObject {
                            cacheObject.cancelTask()
                            supplier.imageCacheObject = nil
                        }
                    }
                }
            }

        }

    }
    
    @IBAction func touchedRecommendedProduct(_ sender: Any) {
        
  
        let button = sender as! IndexedButton
        if let indexPath = button.indexPath {
            let row = indexPath.row
            
            let cell = self.tableView(MainTableView, cellForRowAt: indexPath)
            if let indicator = cell.viewWithTag(20) as? UIActivityIndicatorView {
                
                DispatchQueue.main.async {
                    indicator.startAnimating()
                }
                
                DispatchQueue.global().async {
                    let itemParent = self.recommendedItemParents[row]
                    self.showProduct(itemParent: itemParent, waitIndicator:indicator)    // 商品ページへ遷移
                }
            }
        }
    }
    
    // 商品一覧・ブランド一覧の切り替え
    //　同じセクションに表示させているため、切り替える前に表示していた位置を覚えておき、切り替えたときに以前の位置へ戻している
    var BrandSection = 3
    var RecommendSection = 4
    var firstTimeShowReccomendSecion = true
    
    @IBAction func ShopListBrand(_ sender: Any) {

        let button = sender as! OrosySwitchButton
        let branddMode = button.isSelected  // 切り替える前の状態
        var topIndexForSection:IndexPath!
        
        // リコメンド商品もしくはブランドの見えている範囲の行の先頭を探す
        if let topIndexs = MainTableView.indexPathsForVisibleRows {
            for index in topIndexs {
                if branddMode && index.section == BrandSection || !branddMode && index.section == RecommendSection {
                    topIndexForSection = index
                    break
                }
            }
                
        }
        
        if branddMode {
            // リコメンド
            self.rowForBrandList = topIndexForSection     // 切り替える時に表示していた行を保存
            self.currentDisplayMode = .AmazonReccomend
            self.selectedBrandMode = false
            //self.searchControllerContainer.isHidden = true
            self.ProductBrandSelectViewisHidden = true
            self.mainTableViewTopConstraint.constant = 0
            self.MainTableView.beginUpdates()
            self.MainTableView.reloadSections(IndexSet(integer: RecommendSection), with: .none)    //  切り替えボタン以下を更新
            self.MainTableView.endUpdates()
            if let indexPath = self.rowForRecommentList {
                self.MainTableView.scrollToRow(at: indexPath, at: .top, animated: false)
            }else{
                self.MainTableView.scrollToRow(at: IndexPath(row: 0, section: RecommendSection), at: .top, animated: false)
            }
            if firstTimeShowReccomendSecion {
                firstTimeShowReccomendSecion = false
                self.checkPreFetchData(MainTableView)
                
            }
            
        }else{
            //  通常のブランド一覧
            self.rowForRecommentList = topIndexForSection
            self.selectedBrandMode = true
            self.currentDisplayMode = .Home
            self.mainTableViewTopConstraint.constant = 0
           // self.searchControllerContainer.isHidden = true
            self.MainTableView.beginUpdates()
            self.MainTableView.reloadSections(IndexSet(integer: BrandSection), with: .none)

            self.MainTableView.endUpdates()
            if let indexPath = self.rowForBrandList {
                self.MainTableView.scrollToRow(at: indexPath, at: .top, animated: false)
            }
            

        }

    }
    
    @IBAction func SHopListDIsplayMode(_ sender: Any) {
        
        
    }

    
    // MARK: コレクションビュー
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        var count = 0
        
        if let cview = collectionView as? OrosyUICollectionView {
            if let indexPathOnMainTable = cview.indexPath {
                let rowInMainTable = indexPathOnMainTable.row
                let sectionInMainTable = indexPathOnMainTable.section

                if let supplierDataSet = supplierList.getDataSetFor(displayMode: cview.displayMode ) {
                    if supplierDataSet.displayItem.count > sectionInMainTable {
                        let item = supplierDataSet.displayItem[sectionInMainTable]
                       // let displayMode = cview.displayMode
                        
                        let itemType = item.itemType
                        switch itemType {
                        
                        case .PROMOTION:
                            // バナーコレクション
                            count = g_banner?.contents.count ?? 0
                        case .WEEKLY_BRAND:
                            count = g_weeklyBrand?.recommendShops.count ?? 0
                        case .NEWER:
                            // 新着商品のコレクション
                            if let sc = g_newerSupplier?.suppliers {
                                count = sc.count
                            }
                        case .SHOP_LIST:
                            if supplierDataSet.suppliers!.list.count > rowInMainTable {
                                let supplier = supplierDataSet.suppliers!.list[rowInMainTable]
                                // ショップコレクション
                                // ここにくるまでにデータの読み込みは済ませておく！！
                                let supplierItems = supplier.itemParents
                                count = supplierItems.count + 1  //最後に　「全ての商品を見る」を追加
                                if count > MaxProductListCount {    // 表示する商品点数を制限
                                    count = MaxProductListCount + 1
                                }
                                cview.total = count   // 商品点数を保存
                            }
                        default:
                            break
                        }
                    }
                }
            }
        }

        return count
    }

    // セルのサイズをセット
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        var size:CGSize!
        
        if let cview = collectionView as? OrosyUICollectionView {
            
            if let indexPathOnMainTable = cview.indexPath {
                let sectionInMainTable = indexPathOnMainTable.section

                if let supplierDataSet = supplierList.getDataSetFor(displayMode: cview.displayMode) {
                    let item = supplierDataSet.displayItem[sectionInMainTable]
                    let itemType = item.itemType
                    switch itemType {
                    
                    case .PROMOTION:
                        size = CGSize(width: view.frame.size.width + 20, height: 90)    //　バナー +20は、画像の左側にスペースを開けるためのもの。画像の幅は画面サイズと一致させ、画像を右に＋20ズラすことで、画像は画面幅にピッタリ収まるようにしながら、画像間に20のスペースを設けている。
                    case .NEWER:
                        size = CGSize(width: 130, height: CELL_HEIGHT_NEWER)                  // 新商品
                    case .WEEKLY_BRAND:
                        size = CGSize(width: 130, height: CELL_HEIGHT_NEWER)
                    case .SHOP_LIST:// ショップの下の商品一覧
                        size = CGSize(width: 110, height: CELL_HEIGHT_SHOP)
                    default:
                        size = CGSize.zero
                    }
                }
            }
        }
            
        return size
    }
    
    //　セル間スペース調整
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        var space:CGFloat = 0.0
        
        if let cview = collectionView as? OrosyUICollectionView {
            
            if let indexPathOnMainTable = cview.indexPath {
                let sectionInMainTable = indexPathOnMainTable.section

                if let supplierDataSet = supplierList.getDataSetFor(displayMode: cview.displayMode) {
                    let item = supplierDataSet.displayItem[sectionInMainTable]
                    let itemType = item.itemType
                    switch itemType {
                    
                    case .PROMOTION:
                        space = 0.0
                    default:
                        space = 20.0
                    }
                }
            }
        }
        return space
    }
    
 
    var currentBanner:Int = 0
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let row = indexPath.row
        var cell:UICollectionViewCell!
        
        
        if let cview = collectionView as? OrosyUICollectionView {
            if let indexPathOnMainTable = cview.indexPath {
                let rowInMainTable = indexPathOnMainTable.row
                let sectionInMainTable = indexPathOnMainTable.section

                let supplierDataSet = supplierList.getDataSetFor(displayMode: cview.displayMode)
                let item = supplierDataSet!.displayItem[sectionInMainTable]
                
                let itemType = item.itemType
                switch itemType {
                
                case .PROMOTION:
                    cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BannerCell", for: indexPath)
                    
                    // バナーを追加する
                    let content =  g_banner?.contents[row]
                    if let imageView = cell.viewWithTag(1) as? OrosyUIImageView {
                        imageView.targetRow = row
                        imageView.getImageFromUrl( url: content?.imageUrl, defaultUIImage: g_defaultImage)
                        imageView.drawBorder(cornerRadius: 0)
                    }
                    
                    (content?.extendData as! ExtendSupplier).activityIndicator = cell.viewWithTag(120) as? UIActivityIndicatorView
                    
                    currentBanner = row
                
                case .WEEKLY_BRAND:
                    cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewCell", for: indexPath)
                    
                    let imageView = cell.contentView.viewWithTag(1) as! OrosyUIImageView200
                    let title = cell.contentView.viewWithTag(2) as! UILabel
                    let category = cell.contentView.viewWithTag(3) as! UILabel
                    
                    let recommendShop = g_weeklyBrand.recommendShops[row]
                    
                    title.text = recommendShop.title
                    category.text = recommendShop.context
                
                    let imgUrl = recommendShop.imageUrl
                    imageView.image = nil
                    imageView.targetRow = row
                    imageView.getImageFromUrl(row: row, url: imgUrl, defaultUIImage: g_defaultImage)
                    imageView.drawBorder(cornerRadius: 0)
                    (recommendShop.extendData as! ExtendSupplier).activityIndicator  = cell.viewWithTag(120) as? UIActivityIndicatorView
 
                case .NEWER:
                    // 新着商品のコレクション
                    print(collectionView.tag)

                    cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewCell", for: indexPath)
                    
                    let imageView = cell.contentView.viewWithTag(1) as! OrosyUIImageView200
                    let title = cell.contentView.viewWithTag(2) as! UILabel
                    let category = cell.contentView.viewWithTag(3) as! UILabel
                    
                    if let supplier = g_newerSupplier?.suppliers[row] {
                        title.text = supplier.brandName
                        category.text = g_categoryDisplayName.getDisplayName(supplier.category) //  supplier.category_name
                    
                        let imgUrl = (supplier.imageUrls.count > 0) ? supplier.imageUrls.first : nil
                        imageView.image = nil
                        imageView.targetRow = row
                        imageView.getImageFromUrl(row: row, url: imgUrl, defaultUIImage: g_defaultImage)
                        imageView.drawBorder(cornerRadius: 0)
                        
                        (supplier.extendData as! ExtendSupplier).activityIndicator = cell.viewWithTag(120) as? UIActivityIndicatorView
                    }

                case .SHOP_LIST:

                    // ショップリスト中のプロダクトコレクション
                    let newIndexPath = IndexPath(row:row, section:rowInMainTable)
                    print(newIndexPath)
                    collectionView.register(UINib(nibName: "CommonCollectionSB", bundle: nil), forCellWithReuseIdentifier: "ProductCell")
                    cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCell", for: newIndexPath)
                    
                    let imageView = cell.contentView.viewWithTag(1) as! OrosyUIImageView
                    let title = cell.contentView.viewWithTag(2) as! UILabel
                    let catarogPrice = cell.contentView.viewWithTag(3) as! UILabel
                    let priceLabel = cell.contentView.viewWithTag(4) as! UILabel
                    let showShopPage = cell.contentView.viewWithTag(5) as! UILabel
                    //let moreButton = cell.contentView.viewWithTag(6) as! UIButton       // ボタンとしては使っていない。
                    let favoriteButton = cell.contentView.viewWithTag(10) as! IndexedButton
                    favoriteButton.indexPath = IndexPath(row:row, section:rowInMainTable)
                    favoriteButton.displayMode = cview.displayMode
                    favoriteButton.addTarget(self, action: #selector(favoriteButtonPushed), for: .touchUpInside)
                    
                    let supplierDataSet = supplierList.getDataSetFor(displayMode: cview.displayMode)
                    let supplier = supplierDataSet!.suppliers!.list[rowInMainTable]
                    let itemParent = supplier.itemParents.first
                    
                    imageView.targetRow = row
                    
                    //if row < MaxProductListCount || cview.total < MaxProductListCount {    // 表示件数を制限
                    if row < cview.total - 1 {
                        var supplierItems:[ItemParent]?
                        
                        if supplier.itemParents.count == 0 {
                            supplierItems = supplier.getNextSupplierItemParents()
                        }else{
                            supplierItems = supplier.itemParents
                        }
                        
                        if let itemParent = supplierItems?[row] {
                            if let item = itemParent.item {
                                imageView.image = nil
                                
                                imageView.getImageFromUrl(row: row, url: itemParent.imageUrls.first, defaultUIImage: g_defaultImage)
                                imageView.drawBorder(cornerRadius: 4, color: UIColor.orosyColor(color: .Gray300), width: 1)
                                
                                title.text = item.title
                                catarogPrice.text = Util.number2Str(item.catalogPrice)
                                priceLabel.isHidden = false
                            }
                            showShopPage.text = ""
                            priceLabel.isHidden = false
                            favoriteButton.isSelected = itemParent.isFavorite
                            favoriteButton.isHidden = false
                        }

                    }else{
                        imageView.image = nil
                        imageView.layer.borderColor = UIColor.orosyColor(color: .Gray300).cgColor
                        imageView.layer.borderWidth = 1
                        
                        if let exd = itemParent?.extendData as? ExtendSupplier {
                            exd.activityIndicatorForProducList = cell.contentView.viewWithTag(110) as? UIActivityIndicatorView
                        }
                        
                        showShopPage.text = "全ての\n商品を見る"
                        title.text = ""
                        catarogPrice.text = ""
                        priceLabel.isHidden = true
                        favoriteButton.isHidden = true
                    }

                default:
                    break
                }
            }
        }

        return cell
    }
    
    var scrollTimer:Timer!
    @objc func autoScrollEnabled() {
        if scrollTimer != nil { scrollTimer.invalidate() ; scrollTimer = nil }
        
        scrollTimer = Timer.scheduledTimer(timeInterval: BannerScrollTimer, target: self, selector: #selector(gotoNextBanner), userInfo:nil, repeats: true) //　自動スクロール
    }
    
    func autoScrollDisabled() {
        if scrollTimer != nil {
            scrollTimer.invalidate()
            scrollTimer = nil
        }
        scrollTimer = Timer.scheduledTimer(timeInterval: 6, target: self, selector: #selector(autoScrollEnabled), userInfo:nil, repeats: false)
        // 6秒間ドラッグしないと再度スクロールする
        
    }
    
    @objc func gotoNextBanner() {
        
        var animation = true
        var nextRow = currentBanner + 1
        if  nextRow >= g_banner?.contents.count ?? 0 {
            nextRow = 0         // 最後までスクロールしたら先頭へ戻す
            animation = false   // 先頭へ戻す時はアニメーションさせない
        }
        
        if g_banner?.contents.count ?? 0 > 0 {
            if let _ = banarScrollView {
                self.banarScrollView.scrollToItem(at: IndexPath(row:nextRow,section:0), at: .left, animated: animation)
                currentBanner = nextRow
            }
        }
    }
    
    // prefetch開始
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
       
        if let cview = collectionView as? OrosyUICollectionView {
            
            if let indexPathOnMainTable = cview.indexPath {
                let rowInMainTable = indexPathOnMainTable.row
                let sectionInMainTable = indexPathOnMainTable.section

                let supplierDataSet = supplierList.getDataSetFor(displayMode: cview.displayMode)
                let item = supplierDataSet!.displayItem[sectionInMainTable]

                let itemType = item.itemType
                switch itemType {
                
                case .PROMOTION:
                    // バナーを追加する
                    for indexPath in indexPaths {
                        let row = indexPath.row
                        let recommendShop =  g_banner?.contents[row]
                        OrosyAPI.cacheImage(recommendShop?.imageUrl, imagesize: .None)
                    }
                    
                case .NEWER:
                    // 新着商品のコレクション
                    for indexPath in indexPaths {
                        let row = indexPath.row
                        if let supplier = g_newerSupplier?.suppliers[row] {
                            if supplier.imageUrls.count > 0 {
                                OrosyAPI.cacheImage(supplier.imageUrls.first, imagesize: .Size300)
                            }
                        }
                    }
                    
                case .SHOP_LIST:
                    // ショップコレクション
                    let supplier = supplierDataSet!.suppliers!.list[rowInMainTable]
   
                    for indexPath in indexPaths {
                        let row = indexPath.row
                        //if row < MaxProductListCount || cview.total < MaxProductListCount {    // 表示件数を制限
                        if row < cview.total - 1 {
                            var supplierItems:[ItemParent]?
                            
                            if supplier.itemParents.count == 0 {
                                supplierItems = supplier.getNextSupplierItemParents()
                            }else{
                                supplierItems = supplier.itemParents
                            }
                            
                            let row = indexPath.row
                            let itemParent = supplierItems?[row]
                            if let _ = itemParent?.item {
                                OrosyAPI.cacheImage(itemParent?.imageUrls.first, imagesize: .Size200)   // 最初の商品画像をキャッシュ
                            }

                        }
                    }
                    
                default:
                    break
                }
            }
        }
    }
 
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let row = indexPath.row
      
        if let cview = collectionView as? OrosyUICollectionView {

            if let indexPathOnMainTable = cview.indexPath {
                let rowInMainTable = indexPathOnMainTable.row
                let sectionInMainTable = indexPathOnMainTable.section

                let supplierDataSet = supplierList.getDataSetFor(displayMode: cview.displayMode)
                let item = supplierDataSet!.displayItem[sectionInMainTable]
                
                let itemType = item.itemType
                switch itemType {
                
                case .PROMOTION:
                    if let content = g_banner?.contents{
                        showSpecialFeaturePage(content:content[row])
                    }
                    
                case .WEEKLY_BRAND:
                    if let recommendShops = g_weeklyBrand?.recommendShops {
                        let recommendShop = recommendShops[row]
                        let act = (recommendShop.extendData as! ExtendSupplier).activityIndicator
                        showSupplierPage(supplierId: recommendShop.shopId, activityIndicator:act)
                    }
                    
                case .NEWER:
                    
                    if let supplier = g_newerSupplier?.suppliers[row]{
                        let act = (supplier.extendData as! ExtendSupplier).activityIndicator
                        showSupplierPage(supplierId: supplier.id, activityIndicator:act)
                    }
                    
                case .SHOP_LIST:
     
                    let supplier = supplierDataSet!.suppliers!.list[rowInMainTable]
                    if supplier.itemParents.count > 0 {
                        var itemParent = supplier.itemParents.first
                        
                        itemParent?.supplier = supplier
                        
                        if row < cview.total - 1 {    // 表示件数を制限
                            let supplierItems = (supplier.itemParents.count == 0) ? supplier.getNextSupplierItemParents() : supplier.itemParents
                             
                            let itemParent = supplierItems[row]
                            
                            self.showProduct(itemParent: itemParent, waitIndicator: nil)    // 商品ページへ遷移
                            
                        }else{
                            // 最大件数以上の場合
                            let act = (itemParent?.extendData as! ExtendSupplier).activityIndicatorForProducList
                            showSupplierPage(supplierId:supplier.id, activityIndicator: act)
                        }
                    }else{
                        showSupplierPage(supplierId:supplier.id, activityIndicator: nil)
                    }
                default:
                    break
                }
            }
        }
    }
    

    func showSpecialFeaturePage(content:Content) {

        let storyboard = UIStoryboard(name: "SpecialFeature", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SpecialFeatureVC") as! SpecialFeatureVC
        vc.navigationItem.leftItemsSupplementBackButton = true
        vc.selectedContent = content
        
        self.orosyNavigationController?.pushViewController(vc, animated: true)
        
    }
    
    // キーワード検索結果やリコメンド商品を表示しているProductListVCから呼び出される
    func showProduct(itemParent:ItemParent, waitIndicator:UIActivityIndicatorView? ) {
        
     //   DispatchQueue.global().async {
        
        let supplier = itemParent.supplier  // +Supplier(supplierId: itemParent.supplier?.id ?? "")          // これを先に指定しておく必要がある
        /*
            _ = supplier?.getNextSupplierItemParents()
        */
            let storyboard = UIStoryboard(name: "Main", bundle: nil)

            DispatchQueue.main.async {
                let vc = storyboard.instantiateViewController(withIdentifier: "ProductDetailVC") as! ProductDetailVC
                vc.navigationItem.leftItemsSupplementBackButton = true
                vc.supplier = supplier
                _ = itemParent.getItemParent()
                vc.selectedItem = itemParent.item
                vc.itemParent = itemParent
                vc.connectionStatus = supplier?.connectionStatus // セットされていない場合は、ProductDetailVCで　読み出している
                
                self.orosyNavigationController?.pushViewController(vc, animated: true)
                
                if let indicator = waitIndicator {
                    indicator.stopAnimating()
                }
            }
     //   }
    }
    
    // MARK: もっと見る
    // cellの高さを広げて、10個の商品を一覧表示させる
    
    @IBAction func showMore(_ button: IndexedButton) {
               
        if let indexPathOnMainTable = button.indexPath {

            let row = indexPathOnMainTable.row
           
            let displayMode = button.displayMode
            
            let supplierDataSet = supplierList.getDataSetFor(displayMode: displayMode)
            let supplier = supplierDataSet!.suppliers!.list[row]

            let tableView = supplierDataSet!.tableView
            let extendData = supplier.extendData as! ExtendSupplier

            let open = !extendData.showMore

            let cell = button.cell
            let moreButton = cell!.contentView.viewWithTag(6) as! UIButton
            moreButton.isSelected = open
            extendData.showMore = open
            
            let height = self.view.bounds.width - 30 + 115 + ((open) ? openHeight : closeHeight)

            if open {
                if supplier.itemParents.count == 0 {
                    let _ = supplier.getNextSupplierItemParents()  // 一覧表示する分だけを取得
                }
                
                DispatchQueue.main.async {
                    let collectionView = cell!.contentView.viewWithTag(200) as! OrosyUICollectionView
                    collectionView.reloadData()
                    
                    UIView.animate(withDuration: 0.3, // アニメーションの秒数
                                        delay: 0.0, // アニメーションが開始するまでの秒数
                                       options: [.curveEaseOut], // アニメーションのオプション 等速 | 繰り返し
                                       animations: {
                        
                            tableView.beginUpdates()
                            //　画面幅に応じて画像の高さが変わるため、画面幅から高さを算出
                            var frame = cell!.frame
                            frame.size.height = height
                            cell!.frame = frame
                            tableView.endUpdates()
                        
                        }, completion: { (finished: Bool) in
                            
                            DispatchQueue.global().async {

                                if supplier.tradeConnection == nil {
                                    _ = supplier.getTradeConnection()
                                }
                            }
                           
                        })
                }
   
            }else{
            // 閉じる方は、アニメーションを入れると余計なバウンス動作が入るため、やめた
                tableView.beginUpdates()
                //　画面幅に応じて画像の高さが変わるため、画面幅から高さを算出
                var frame = cell!.frame
                frame.size.height = height
                cell!.frame = frame
                tableView.endUpdates()
            }
        }
    }
    

    // メッセージ送信画面表示へ遷移
    @objc func showMessage() {
        let storyboard = UIStoryboard(name: "MessageSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MessageVC") as! MessageVC
        
        //present(vc, animated: true, completion: nil)
        self.orosyNavigationController?.pushViewController(vc, animated: true)
        
    }
    
    // サプライヤーページへ遷移
    // ショップ一覧から遷移する場合
    @IBAction func gotoSupplierPage(_ button: IndexedButton) {
                
        let row = button.indexPath?.row ?? 0
        let displayMode = button.displayMode
        let supplierDataSet = supplierList.getDataSetFor(displayMode: displayMode)
        
        let supplier = supplierDataSet!.suppliers!.list[row]

        let act = (supplier.extendData as! ExtendSupplier).activityIndicator
        self.showSupplierPage(supplierId: supplier.id, activityIndicator:  act)

    }

    var lockGotoSupplierPageButton = false
    // ブランド一覧でサプライヤを選択した場合にはsupplierが特定されているのでsupplierオブジェクトが渡されるようにしていたが、この方法だとWeb側でお気に入り情報が変化した場合、それを反映できないので、結局、毎回サプライヤー情報を読み直すこととした。
    // 新着情報やバナーの場合には、supplier idと画像ぐらいしか情報を持っていないので、supplier idが渡される
    public func showSupplierPage(supplierId:String?, supplier:Supplier? = nil, activityIndicator:UIActivityIndicatorView? = nil) {

        if lockGotoSupplierPageButton { return }         //　2度押し防止
        lockGotoSupplierPageButton = true
        
        if let act = activityIndicator  {
            DispatchQueue.main.async{
                act.startAnimating()
            }
        }
        
        DispatchQueue.global().async{
            var supplierHasData:Supplier!
   
            if supplier == nil {
                supplierHasData = Supplier(supplierId: supplierId, size:self.ITEMPARENT_BATCH_SIZE)    // 商品一覧を取得。  新着情報の場合はSupplierオブジェクトではないので・・。　ここではitemparentは取得していない。
                if supplierHasData == nil {
                    LogUtil.shared.log("get supplier failed")
                    self.lockGotoSupplierPageButton = false
                    return      // データを取得できない
                }else{
                    OrosyAPI.cacheImage(supplierHasData.coverImageUrl, imagesize: .Size400)
                    OrosyAPI.cacheImage(supplierHasData.iconImageUrl, imagesize: .Size100)
                }

            }else{
                supplierHasData = supplier
            }

           _ = supplierHasData.getNextSupplierItemParents()
            if supplierHasData.getAllInfo(wholeData: true) {
 
                // サプライヤーページへ遷移
                DispatchQueue.main.async{
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "ProductListVC") as! ProductListVC
                    object_setClass(vc.self, SupplierVC.self)
                    
                    vc.navigationItem.leftItemsSupplementBackButton = true
                    vc.productListMode = .ProductList
                    vc.supplier = supplierHasData
                    
                    //vc.supplierId = supplierId
                    self.orosyNavigationController?.pushViewController(vc, animated: true)
                    
                    if let act = activityIndicator  {
                        act.stopAnimating()
                    }

                }
            }
            self.lockGotoSupplierPageButton = false
        }
    }
    
    // MARK: スクロールに応じたプリフェッチ
    
 
 
    //　スクロールが停止しそうになったら、すくその時点で表示しているサプライヤーに関して「もっと見る」を開いた時に必要となる画像をキャッシュへ入れる
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {  // scrollViewDidEndDecelerating を使っていたが、これだと呼び出される回数が多すぎる
        LogUtil.shared.log ("in scrollViewWillBeginDecelerating")

        checkPreFetchData(scrollView)
    }
    

    // カテゴリ検索とキーワード検索の商品一覧の場合は　ProductCollectionVCで処理している
    func checkPreFetchData(_ scrollView: UIScrollView) {
        
        if let _tableView = scrollView as? UITableView {
            // サプライヤ一覧の場合
            
            if currentDisplayMode == .AmazonReccomend {
                let indixes = MainTableView.indexPathsForVisibleRows    // 見えている範囲の行
                for index in indixes ?? [] {
                    let section = index.section
                    if section == recommendSection?.section ?? -1 {
                        let row = index.row
                        let itemParent = recommendedItemParents[row]
                        
                        DispatchQueue.global().async {
                            
                            for url in itemParent.imageUrls {
                                OrosyAPI.cacheImage(url, imagesize: .Size500)   // 商品ページのトップの商品サンプル画像
                                
                            }
                        }
                    }
                }
                
            }else{
                
                if supplierList == nil { return }
                
                let supplierDataSet = supplierList.getDataSetFor(tableView:_tableView  )
                let displayMode = supplierDataSet!.displayMode
                
                var indixes:[IndexPath]?
                
                if displayMode == .Home {
                    indixes = MainTableView.indexPathsForVisibleRows    // 見えている範囲の行
                    
                }else{
                    indixes = BrandSearchTableView.indexPathsForVisibleRows
                }
                
                LogUtil.shared.log ("in checkPreFetchData")
                
                for index in indixes ?? []{
                    let section = index.section
                    let row = index.row
                    
                    let item = supplierDataSet!.displayItem[section]
                    
                    let itemType = item.itemType
                    if itemType == .SHOP_LIST {
                        
                        if row >= supplierDataSet!.suppliers!.list.count {return}
                        
                        let supplier = supplierDataSet!.suppliers!.list[row] //  Index out of rangeで落ちた
                        
                        let itemParent = supplier.itemParents.first
                        
                        DispatchQueue.global().async {
                            
                            OrosyAPI.cacheImage(supplier.imageUrls.first, imagesize: .Size400)
                            OrosyAPI.cacheImage(supplier.coverImageUrl, imagesize: .Size640)    // ブランドページを開いたときのタイトル用
                            OrosyAPI.cacheImage(supplier.iconImageUrl, imagesize: .Size100)
                            
                            // まだ読み込み済みでない場合だけデータを取得し、画像をキャッシュする
                            if let itemp = itemParent {
                                var ip = 0
                                for url in itemp.imageUrls {
                                    OrosyAPI.cacheImage(url, imagesize: .Size200)
                                    ip += 1
                                    if ip >= 4 { break }
                                }
                                
                                // まだ画像を読み込んでいないのなら読み込む
                                if supplier.itemParents.count == 0 {
                                    let suppliers = supplier.getNextSupplierItemParents()
                                    if suppliers.count == 0 {
                                        print("最後です")
                                        
                                    }else{
                                        for supplier in suppliers {
                                            OrosyAPI.cacheImage(supplier.imageUrls.first, imagesize: .Size200)
                                        }
                                    }
                                }
                                
                                if supplier.tradeConnection == nil {
                                    _ = supplier.getTradeConnection()
                                }
                                
                            }
                        }
                    }
                }
            }
            
        }
    }
    

    var scrollBeginingPoint: CGPoint = CGPoint(x:0, y:0)
    var searchBarIsHidden = false
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        scrollBeginingPoint = scrollView.contentOffset;
        
        if let cview = scrollView as? OrosyUICollectionView {
            if let indexPathOnMainTable = cview.indexPath {
                let sectionInMainTable = indexPathOnMainTable.section
                let supplierDataSet = supplierList.getDataSetFor(displayMode: cview.displayMode )
                let item = supplierDataSet!.displayItem[sectionInMainTable]
                
                let itemType = item.itemType
                switch itemType {
                    
                case .PROMOTION:
                    autoScrollDisabled()      // 手でドラッグしたら自動スクロールを止める
    
                default:
                    break
                }
            }
        }
        
    }

    
    //　MARK: 行の最後の近づいたら、次のデータを取得 & スクロール方向に応じて検索バーを隠す
    var fetchingNextDataForMaintable = false        // 重ねてフェッチしないようにするためのフラグ
    var fetchingNextDataForSearchresultTable = false    // 重ねてフェッチしないようにするためのフラグ
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
       // if !dataReady { return }    // データの準備ができていない時は無視する
        
        let scrollPosY = scrollView.contentOffset.y //スクロール位置
        let maxOffsetY = scrollView.contentSize.height //- scrollView.frame.size.height //スクロール領域の高さからスクロール画面の高さを引いた値
        let distanceToBottom = maxOffsetY - scrollPosY //スクロール領域下部までの距離
        if distanceToBottom < 0 || scrollPosY < 400 {
            return
        }
        let currentPoint = scrollView.contentOffset;    //スクロール位置
        
        // 通常表示モード
        if scrollView == MainTableView  {
            
          //  print(distanceToBottom)
            if currentDisplayMode == .AmazonReccomend && distanceToBottom < 3000 && !fetchingNextDataForMaintable {
                DispatchQueue.global().async {
                    _ = self.getReccomendedItemParents()
                }
            }else
            if currentDisplayMode == .Home && distanceToBottom < 4000 && !fetchingNextDataForMaintable { // 先頭は10000くらいになるので、400から2000へ増やした
                LogUtil.shared.log("次のデータをフェッチ")
             //   DispatchQueue.global().async {        // ここでやると落ちる
                    self.setSupplierQuery(targetTableView: self.MainTableView)
             //   }
                LogUtil.shared.log("次のデータをフェッチ完了")
            }
             
            // ==============================
            // スクロール方向によって検索バーを非表示にする。
            if !self.searchBarIsHidden && self.scrollBeginingPoint.y < currentPoint.y - 20 && currentPoint.y > 60 {    // 少しスクロールしてから反応させる
                // 下へスクロール　　->　検索バーを隠す
                self.searchBarIsHidden = true
                self.mainTableViewTopConstraint.constant = 0
                openCloseSearchBar(close:true)

                
             //   print("close")
            }else if self.searchBarIsHidden && (self.scrollBeginingPoint.y > currentPoint.y + 20 || currentPoint.y < 40) {
                // 上へスクロール　　->　検索バーを表示する
                self.searchBarIsHidden = false
                self.mainTableViewTopConstraint.constant = 54
                openCloseSearchBar(close:false)
                

                print("open")
            }else{
                return
            }
            

            openCloseProductBrandSelectView(close:self.ProductBrandSelectViewisHidden)
            // カテゴリ検索・キーワード検索の商品一覧場合は、ProductCollectionVCで処理している
                

        }else if scrollView == BrandSearchTableView {
            // カテゴリ検索のブランド一覧の場合
            
            print(distanceToBottom)
            print(scrollView.contentSize.height)
            print( scrollView.frame.size.height )
            //スクロール領域下部に近づいたら追加で取得する

            if self.currentDisplayMode == .CategorySearchBrand {
                
                if distanceToBottom < 4000 && !fetchingNextDataForSearchresultTable {
                    print("次のデータをフェッチ")
                    self.fetchingNextDataForSearchresultTable = true
                    self.setSupplierQuery(targetTableView: self.BrandSearchTableView)
                    
                    print("次のデータをフェッチ完了")
   
                }
                /*else if distanceToBottom > 4000 {   // スキャンしてデータがロードされると、テーブルの下端から離れるので、それをきっかけとして次のデータ取得を許可する
                    // setSupplierQueryの後に追加するとうまくいかなかった。
                    self.fetchingNextDataForSearchresultTable = false
                }
                 */
                // ==============================
                // スクロール方向によって検索バーを非表示にする。

                if !self.ProductBrandSelectViewisHidden && self.scrollBeginingPoint.y < currentPoint.y - 20 && currentPoint.y > 60 {    // 少しスクロールしてから反応させる
                    // 下へスクロール　　->　商品/ブランド切替バーを隠す
                    self.ProductBrandSelectViewisHidden = true
                    self.mainTableViewTopConstraint.constant = 0
                    
                }else if self.ProductBrandSelectViewisHidden && (self.scrollBeginingPoint.y > currentPoint.y + 40 || currentPoint.y < 40) {
                    // 上へスクロール　　->　商品/ブランド切替バーを表示する
                    self.ProductBrandSelectViewisHidden = false
                    self.mainTableViewTopConstraint.constant = 54
                    
                }
                openCloseProductBrandSelectView(close:self.ProductBrandSelectViewisHidden)
            }

        }

    }
    
    


    // スクロールに応じて検索バーの表示・非表示を変える
    func openCloseSearchBar(close:Bool) {
        UIView.animate(withDuration: 0.3, // アニメーションの秒数
                       delay: 0.0, // アニメーションが開始するまでの秒数
                       options: [.curveEaseOut], // アニメーションのオプション 等速 | 繰り返し
                       animations: {
            
            self.searchControllerTopConstraint.constant = (close) ? 0 - self.searchController.miniHeight : 0
            
        }, completion: { (finished: Bool) in
           
        })
    }
    

    
    // MARK: リフレッシュコントロールによる読み直し

    func refreshSearchResult( waitIndicator:UIActivityIndicatorView? = nil) {
        
        if currentDisplayMode == .KeywordSearchProduct {
            // キーワード検索の場合
           // keywordSearch()
            
        }else{
            // カテゴリ検索の場合
            refreshCategorySearchResult( waitIndicator:waitIndicator)
        }
    }
    

    @objc func refreshMainProducts() {
        if let slist = supplierList {
            let supplierDataSet = slist.getDataSetFor(tableView: MainTableView)
            
            if supplierList.main.lockNextData { return }  // データ更新中なので画面更新はしない
            
            supplierDataSet?.suppliers?.list = []     // ここで空にすると落ちる??

            _ = supplierList.initMain(tableView: MainTableView )   // メインのデータセットを初期化
            uuid_mainSupplier = nil
            uuid_mainSupplier = g_processManager.addProcess(name:"サプライヤの初期情報を取得", action: setSuppierQueryFirstForMain, errorHandlingLevel: .ALERT, errorCountLimit: -1, execInterval: 5, immediateExec: true, processType:.Once, delegate:self)
        }
    }

    
    // MARK: ==========================================
    // MARK: カテゴリ検索関連
    
    //　カテゴリ検索メニューのセットアップ
    func setupCatgorySearch() {
        DispatchQueue.global().async {

            DispatchQueue.main.async {
              //  self.categoryTableBottomConstraintOriginal = self.CategoryTableView.bounds.height  // カテゴリテーブルの初期高さをキープ
              //  self.categoryTableBottomConstraint.constant = self.categoryTableBottomConstraintOriginal // 最初は非表示
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CategorySearchVC") as! CategorySearchVC

                vc.delegate = self
                self.categorySearchVC = vc
                
                self.CategoryTableView.delegate = self.categorySearchVC
                self.CategoryTableView.dataSource = self.categorySearchVC
                
                //      self.categorySearchVC.categoryList = g_categories?.list ?? []
                self.categorySearchVC.categoryMenuTableView = self.CategoryTableView
                
            }
        }
    }
    
    // カテゴリ検索メニューの On/Off
    var isCategoryTableOpened = false
    @IBAction func showCategorySearchView() {
        
        DispatchQueue.main.async {
            self.noDataAlert.isHidden = true
            self.searchController.closeSearchBar()       // 検索バーだけの表示にする
        }
        
        searchController.isHidden = !self.isCategoryTableOpened     // カテゴリメニューが閉じている ー＞ 開くので検索バーは隠す
        
        UIView.animate(withDuration: 0.3, // アニメーションの秒数
                       delay: 0.0, // アニメーションが開始するまでの秒数
                       options: [.curveEaseOut], // アニメーションのオプション 等速 | 繰り返し
                       animations: {
            
            if self.isCategoryTableOpened {
                //　Open -> Close
                //  self.categoryTableBottomConstraint.constant = self.categoryTableBottomConstraintOriginal    // close状態
                self.SearchMenuTableHeight.constant = 0
                self.isCategoryTableOpened = false
                let menu = UIImage(named: "humbergerMenu")?.withRenderingMode(.alwaysOriginal)
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: menu, style:.plain, target: self, action: #selector(self.showCategorySearchView))
             }else{
                 // close -> open状態
                 //  self.categoryTableBottomConstraintOriginal = self.categoryTableBottomConstraint.constant
                 //  self.categoryTableBottomConstraint.constant = 0     // open状態
                 self.SearchMenuTableHeight.constant = self.MainTableView.frame.size.height
                 self.isCategoryTableOpened = true
                 let close = UIImage(named: "close")?.withRenderingMode(.alwaysOriginal)
                 self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: close, style:.plain, target: self, action: #selector(self.closeSearchView))

            }
            self.view.layoutIfNeeded()
            
        }, completion: { (finished: Bool) in
            
        })
    }
    
    //　新着、おすすめの切り替えボタン
    func setupProductListView() {
        
        //　メニュ項目の追加
        var actions = [UIMenuElement]()
        
        var sortMode:SortMode!
        if selectedBrandMode {
            sortMode = g_sortModeCategorySearchForBrand
        }else{
            sortMode = g_sortModeCategorySearchForProduct
        }
        
        actions.append(UIAction(title: "新着順", image: nil, state: (sortMode == .Newer) ? .on : .off, handler: { (_) in
            if self.selectedBrandMode {
                g_sortModeCategorySearchForBrand = .Newer
            }else{
                g_sortModeCategorySearchForProduct = .Newer
            }
            self.setupProductListView()              // ボタンの選択状態を更新
            self.refreshSearchResult()       // 検索をやり直して結果を表示
            }))
        actions.append(UIAction(title: "おすすめ順", image: nil, state: (sortMode == .Recommend) ? .on : .off, handler: { (_) in
            if self.selectedBrandMode {
                g_sortModeCategorySearchForBrand = .Recommend
            }else{
                g_sortModeCategorySearchForProduct = .Recommend
            }

            self.setupProductListView()
            self.refreshSearchResult()
        }))

        
        if !selectedBrandMode {
            // 商品一覧の場合
            actions.append(UIAction(title: "小売価格が安い順", image: nil, state: (sortMode == .PriceAscend) ? .on : .off, handler: { (_) in
                g_sortModeCategorySearchForProduct = .PriceAscend
                self.setupProductListView()
                self.refreshSearchResult()
            }))
            actions.append(UIAction(title: "小売価格が高い順", image: nil, state: (sortMode == .PriceDesend) ? .on : .off, handler: { (_) in
                g_sortModeCategorySearchForProduct = .PriceDesend
                self.setupProductListView()
                self.refreshSearchResult()
            }))
            
        }
        
        
        // UIButtonにUIMenuを設定
        searchModeButton.menu = UIMenu(title:"" , options: .destructive, children: actions)  // 初期設定
        // こちらを書かないと表示できない場合があるので注意
        searchModeButton.showsMenuAsPrimaryAction = true
        
        // ボタンの表示をセット
        var msg = ""
        
        var searchMode:SortMode = .Newer
        if selectedBrandMode {
            searchMode = g_sortModeCategorySearchForBrand
        }else{
            searchMode = g_sortModeCategorySearchForProduct
        }
        
        switch searchMode {
        case .Newer: msg = "新着順"
        case .Recommend: msg = "おすすめ順"
        case .PriceDesend: msg = "小売価格が高い順"
        case .PriceAscend: msg = "小売価格が安い順"
        case .Personalized: msg = "あなたへのおすすめ商品"
        }
        self.searchModeButtonTitle.text = msg
    }
    
    
    @objc func closeSearchView() {
        LogUtil.shared.log("closeSearchView:start")
     
        DispatchQueue.main.async {
            self.noDataAlert.isHidden = true
            self.searchController.closeSearchBar()

        }
        
        if isCategoryTableOpened {   //　開いていれば閉じる
            DispatchQueue.main.async {
                self.showCategorySearchView()
            }
        }
  
    }
    
    let GapForKeywordSearch:CGFloat = -100  // 表示順を表示させる場合は　-60 にする
    
    // 商品・モデル選択ビュー
    var ProductBrandSelectViewisHidden = false
    func openCloseProductBrandSelectView(close:Bool) {
        UIView.animate(withDuration: 0.3, // アニメーションの秒数
                       delay: 0.0, // アニメーションが開始するまでの秒数
                       options: [.curveEaseOut], // アニメーションのオプション 等速 | 繰り返し
                       animations: {
            
            
            if self.currentDisplayMode == .KeywordSearchProduct {
                // カテゴリの商品検索結果
                self.SearchModePanelViewTopConstraint.constant = (close) ? -200 :  self.GapForKeywordSearch
            }else if self.currentDisplayMode == .CategorySearchBrand || self.currentDisplayMode == .CategorySearchProduct {
                // キーワード商品検索結果
                self.searchControllerTopConstraint.constant = (close) ? -100 : 0
                self.brandTableTopConstraintForKeySearch.constant = (close) ? 0 : self.searchController.miniHeight + 10
                self.productCollectionTopConstraintForKeySearch.constant = (close) ? 0 : self.searchController.miniHeight + 10
            }else{
                self.SearchModePanelViewTopConstraint.constant = (close) ? -200 :  0
            }
            /*
            if self.productCollectionTopConstraint.isActive {
                // カテゴリの商品検索結果
                self.SearchModePanelViewTopConstraint.constant = (close) ? -200 : (self.currentDisplayMode == .KeywordSearchProduct) ? self.GapForKeywordSearch : 0
            }else{
                // キーワード商品検索結果
                self.searchControllerTopConstraint.constant = (close) ? -100 : 0
                self.brandTableTopConstraintForKeySearch.constant = (close) ? 0 : self.searchController.miniHeight + 10
                self.productCollectionTopConstraintForKeySearch.constant = (close) ? 0 : self.searchController.miniHeight + 10
            }
            */
            
        }, completion: { (finished: Bool) in
            
        })
    }
     
    // CategorySeachVCで選択されたカテゴリを取得
    public func categorySelected(category:Category, waitIndicator:UIActivityIndicatorView?) {
  
        if category.isHome() {
            changeDisplayModeToHome() // Homeへ戻す
            self.closeSearchView()   // メニューを隠す
            
            DispatchQueue.main.async {
                self.MainTableView.reloadSections(IndexSet(integer: self.BrandSection), with: .none)
            }
            return
        }
        
        selectedCateogry = category
        
        DispatchQueue.main.async {
            self.waitIndicator.startAnimating()
        }
        DispatchQueue.global().async {
            self.refreshCategorySearchResult(waitIndicator:waitIndicator )
       }
        
        self.closeSearchView()   // メニューを隠す
 
    }

    // 選択されたカテゴリのブランド/商品情報を取得
    func refreshCategorySearchResult( waitIndicator:UIActivityIndicatorView? = nil) {
        
        // 先に表示する方のデータを取得しておき、次に残りを取る
        if selectedBrandMode {
            requestAnother = true
            self.setupDisplay(.CategorySearchBrand)
            self.getCategorySearchResult(brandMode:true, showAlert:true )
            
        }else{
            // 商品リスト表示の場合
            requestAnother = true
            self.setupDisplay(.CategorySearchProduct)
            self.getCategorySearchResult(brandMode:false, showAlert:true )
        }
    }

    var requestAnother = false  // true: 検索結果を最初に表示するモードとは異なるモードのデータも続けて取得しておく
    
    func getCategorySearchResult(brandMode:Bool, showAlert:Bool  ) {
                
        let isLargeKey = self.selectedCateogry.isLargeKey

        DispatchQueue.main.async {
            self.waitIndicator.startAnimating()
        }
        
        
        if brandMode {

            DispatchQueue.global().async {
                
                // サプライヤ　のリストを取得
                if let suppliers = Suppliers(categoryId: self.selectedCateogry.id, from: 0, size: self.CATEGORY_SESRCH_INITIAL_BATCH_SIZE,  sort: g_sortModeCategorySearchForBrand, searchKey:((isLargeKey) ? .Large : .Middle)) {
                    let newSuppliers = suppliers.fetch(readPointer: 0)
                    
                    DispatchQueue.main.async {
                        if newSuppliers?.count ?? 0 == 0{
                            if showAlert {
                                self.noDataAlert.selectType(type: .searchBrand)
                                self.noDataAlert.isHidden  = false
                            }
                        }else{
                            self.noDataAlert.isHidden  = true
                        }
                    }
                    self.supplierList.setCategory(suppliers: suppliers)
                       
                    for supplier in newSuppliers ?? [] {
                        let extendData = ExtendSupplier()
                        extendData.showMore = false
                        supplier.extendData = extendData
                        let itemParents = supplier.getNextSupplierItemParents()  // 一覧表示する分だけを取得
                        
                        for item in itemParents {
                            item.extendData = extendData
                        }
                        
                        OrosyAPI.cacheImage(supplier.coverImageUrl, imagesize: .Size400)
                    }
                    
                    DispatchQueue.main.async {

                        self.waitIndicator.stopAnimating()
                        
                        if brandMode {
                            self.BrandSearchTableView.reloadData()    // 検索結果表示用
                            if suppliers.list.count > 0 {self.BrandSearchTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)}  //TableViewをトップへ戻す
                        }else{
                            self.ProductResultView.reloadData()
                            if suppliers.list.count > 0 {self.ProductResultView.scrollToItem(at: IndexPath(row:0, section:0), at: .top, animated: false)} // CollectionViewをトップへ戻す
                        }
                    }
                
                    self.fetchingNextDataForSearchresultTable = false
                    
                    if let supplierDataSet = self.supplierList.getDataSetFor(tableView: self.BrandSearchTableView) {
                        
                        if let suppliers = supplierDataSet.suppliers {
                            if suppliers.from > 0 {
                                suppliers.size = self.CATEGORY_SESRCH_BATCH_SIZE    // 最初は小さく、2回目以降は大きなサイズで取得
                            }
                            
                            self.setSupplierQuery(targetTableView: self.BrandSearchTableView)
                        }
                    }
                    if self.requestAnother {
                        self.requestAnother = false
                        self.getCategorySearchResult(brandMode:false, showAlert:false  )    // 商品一覧の情報も取得しておく
                    }
                }
            }

        }else{

            // 商品のリストを取得
            
            if let searchItems = SearchItems(searchWord:nil , size: self.SEARCH_BACH_SIZE, sort:g_sortModeCategorySearchForProduct, categoryKey:((isLargeKey) ? .Large : .Middle), categoryId: self.selectedCateogry.id, pageUrl:self.orosyNavigationController?.currentUrl ?? "/" ) {
                
           // if let categoryItems = CategoryItems(category_id: self.selectedCateogry.id, searchKey: ((isLargeKey) ? .Large : .Middle), size: 6, sort: g_sortModeCategorySearch) {
                let result = searchItems.getNext()
                
                switch result {
                case .success(let newItems):
                    DispatchQueue.main.async {
                        self.waitIndicator.stopAnimating()
                        
                        if newItems.count == 0 {
                            if showAlert {
                                self.noDataAlert.selectType(type: .searchProduct )
                                self.noDataAlert.isHidden  = false
                            }
                        }else{
                            self.noDataAlert.isHidden  = true
                        }
                        
                        self.productCollectionVC.collectionView = self.ProductResultView    // 先にこちらをセットしておく必要がある
                        self.productCollectionVC.currentDisplayMode = .CategorySearchProduct
                        self.productCollectionVC.searchItems = searchItems
                        self.productCollectionVC.delegate = self
                        self.productCollectionVC.currentPageUrl = self.orosyNavigationController?.currentUrl
                        self.ProductResultView.reloadData()
                        
                        if self.requestAnother {
                            self.requestAnother = false
                            self.getCategorySearchResult(brandMode:false, showAlert:false  )    // ブランドのリストも取得しておく
                        }
                    }
                    
                    for item in newItems {
                        OrosyAPI.cacheImage(item.imageUrls.first, imagesize: .Size200)
                    }
                case .failure(_):
                    break
                }
            }
        }

    }
    

    // 商品　／　ブランドの切替
    // カテゴリを選択した時点で両方のデータを取得しているので、ここではデータは取得しない
    @IBAction func productBrandSelected(_ sender: OrosySwitchButton) {
        print (sender.isSelected)
        
        if currentDisplayMode == .AmazonReccomend {
            
            UIView.animate(withDuration: 0.3, // アニメーションの秒数
                                delay: 0.0, // アニメーションが開始するまでの秒数
                               options: [.curveEaseOut], // アニメーションのオプション 等速 | 繰り返し
                               animations: {
                
                sender.isSelected = false
                
                }, completion: { (finished: Bool) in
                    self.setupDisplay(.Home)
                })
            
        }else{
            
            UIView.animate(withDuration: 0.3, // アニメーションの秒数
                                delay: 0.0, // アニメーションが開始するまでの秒数
                               options: [.curveEaseOut], // アニメーションのオプション 等速 | 繰り返し
                               animations: {
                
                sender.isSelected = !sender.isSelected
                
                }, completion: { (finished: Bool) in
                    self.selectedBrandMode = sender.isSelected
                    
                    if self.selectedBrandMode {
                        //　ブランド一覧
                        self.setupDisplay(.CategorySearchBrand)
                        self.MainTableView.reloadData()
                        
                    }else{
                        // 商品一覧
                        self.setupDisplay(.CategorySearchProduct)
                    }
                    
                    self.setupProductListView()  //表示順選択メニューを作り直す
                })
            
        }
        
    }
    
    // MARK: キーワード検索
    // 検索条件設定中
    func keywordSearching(_ show:Bool) {
        
        self.noDataAlert.isHidden = true

        SearchBarHeightConstraint.constant = (show) ? self.view.bounds.height : searchController.miniHeight
        
    }
    
    func returnToLastDisplayMode() {
        setupDisplay(lastDisplayMode)
        SearchBarHeightConstraint.constant = searchController.miniHeight     //　検索条件入力エリアの高さを最小にする
    }
    

    // キーワード検索
    func searchExec(searchWord:String, targetMode: HomeDisplayMode , categoryKey:SearchKey? = nil, categoryId:String? = nil) {
        
        self.setupDisplay(.KeywordSearchProduct)
        
        DispatchQueue.main.async {
            self.waitIndicator.startAnimating()
        }
        
        searchWordExec(searchWord:searchWord, targetMode:targetMode, categoryKey:categoryKey, categoryId:categoryId)
    }
    
    func searchWordExec(searchWord:String, targetMode: HomeDisplayMode , categoryKey:SearchKey? = nil , categoryId:String? = nil) {
        
        SearchBarHeightConstraint.constant = searchController.miniHeight
        
        self.noDataAlert.isHidden = true
        
        self.searchController.resignFirstResponder() // hides the keyboard.
        
        DispatchQueue.global().async {
            
            if targetMode == .KeywordSearchProduct {
                // 商品検索
                var categoryName:String = ""
                if let cid =  categoryId {
                    categoryName = Categories.shared.getCategoryName(categoryId:cid)
                }else{
                    categoryName = "全ての商品"
                }
                
                DispatchQueue.main.async {
                    self.setNaviTitle(title: "商品/\(categoryName)")
                }
                
                if let searchItems = SearchItems(searchWord:searchWord , size: self.SEARCH_BACH_SIZE, sort:g_sortModeCategorySearchForProduct, categoryKey:categoryKey, categoryId: categoryId , pageUrl:self.orosyNavigationController?.currentUrl ?? "/" ) {
        
                    let result = searchItems.getNext()
                    
                    switch result {
                    case .success(_):   // true なら読み終わったことを意味する
                        if searchItems.itemParents.count == 0 {
                            DispatchQueue.main.async {
                                self.noDataAlert.selectType(type: .searchProduct)
                                self.noDataAlert.isHidden = false
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.productCollectionVC.collectionView = self.ProductResultView    // 先にこちらをセットしておく必要がある
                            self.productCollectionVC.currentDisplayMode = .KeywordSearchProduct
                            self.productCollectionVC.searchIems = searchItems
                            self.productCollectionVC.delegate = self
                            self.productCollectionVC.currentPageUrl = self.orosyNavigationController?.currentUrl
                            
                            self.ProductResultView.reloadData()
                            self.ProductResultView.setContentOffset(.zero, animated: false)
                            
                            self.waitIndicator.stopAnimating()
                        }
                        
                    case .failure(_):
                        break
                    }
                }
            }
            if targetMode == .KeywardSearchBrand {
                // ブランド検索
                
                if let searchSuppliers = SearchSuppliers(searchWord:searchWord , size: self.SEARCH_BACH_SIZE , pageUrl:self.orosyNavigationController?.currentUrl ?? "/") {
        
                    let result = searchSuppliers.getNextSuppliers( )
                    
                    switch result {
                    case .success(_):   // true なら読み終わったことを意味する
                        if searchSuppliers.list.count == 0 {
                            DispatchQueue.main.async {
                                self.noDataAlert.selectType(type: .searchBrand)
                                self.noDataAlert.isHidden = false
                            }
                        }
          
                        
                        for supplier in searchSuppliers.list {
                            let extendData = ExtendSupplier()
                            extendData.showMore = false
                            supplier.extendData = extendData
                            let itemParents = supplier.getNextSupplierItemParents()  // 一覧表示する分だけを取得
                            
                            for item in itemParents {
                                item.extendData = extendData
                            }
                            
                            OrosyAPI.cacheImage(supplier.coverImageUrl, imagesize: .Size400)
                        }
                        
                        DispatchQueue.main.async {
                            self.setupDisplay(.KeywardSearchBrand)
                            self.supplierList.setCategory(suppliers: searchSuppliers)
                            self.BrandSearchTableView.reloadData()
                            self.waitIndicator.stopAnimating()
                        }
 
                    case .failure(_):
                        break
                    }
                }
            }
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        return
    }
    


// MARK: ==========================================
// MARK: お気に入り
// ハートボタンが押された
// 「もっと見る」で表示される商品一覧を変更した場合
    @IBAction func favoriteButtonPushed(_ button: IndexedButton) {

        if let indexPath = button.indexPath {
            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }

            let row = indexPath.row
            let rowInMaintable = indexPath.section

            let displayMode = button.displayMode
            let supplierDataSet = supplierList.getDataSetFor(displayMode: displayMode)

            let supplier = supplierDataSet!.suppliers!.list[rowInMaintable]
            let itemParent = supplier.itemParents[row]

            //let fvc = FavoriteVC()
            
            if let fvc = g_faveriteVC {
                let favoriteFlag = fvc.changeFavorite(itemParent: itemParent, callFromSelf: false, referer:self.orosyNavigationController?.currentUrl ?? "")   // お気に入りVCを呼び出す
                itemParent.isFavorite = favoriteFlag
            }

            // どのセクションにショップリストが入っているのかを探して、データを更新する
            var mainSection = 0
            for ditem in supplierDataSet!.displayItem {
                if ditem.itemType == .SHOP_LIST {
                    let cellMain = supplierDataSet!.tableView.cellForRow(at: IndexPath(row:rowInMaintable, section:mainSection))
                    let collectionView = cellMain?.viewWithTag(200) as! OrosyUICollectionView
                    collectionView.reloadItems(at:[IndexPath(row:row, section:0)])
                }
                mainSection += 1
            }
        }
    }

    @IBAction func favoriteButtonPushedOnRecommend(_ button: IndexedButton) {

        if let indexPath = button.indexPath {
            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }

            let row = indexPath.row
            let itemParent = recommendedItemParents[row]

            //let fvc = FavoriteVC()
            
            if let fvc = g_faveriteVC {
                let favoriteFlag = fvc.changeFavorite(itemParent: itemParent, callFromSelf: false, referer:self.orosyNavigationController?.currentUrl ?? "")   // お気に入りVCを呼び出す
                itemParent.isFavorite = favoriteFlag
            }

            // データを更新する

            MainTableView.reloadRows(at: [IndexPath(row:row, section:4)], with: .none)

        }
    }
    
    // お気に入りが更新されたという通知を受けた(ホームとカテゴリ検索結果一覧と共有）
    @objc func favoriteReset(notification: Notification) {


        guard let userInfo = notification.userInfo else { return }

        if let updatedItemParent = userInfo["itemParent"] as? ItemParent {
            let onOff = userInfo["onOff"] as? Bool ?? false  // true: お気に入りに入れた

   
                
            if currentDisplayMode == .AmazonReccomend {
                
                
                var row = 0
                for item in recommendedItemParents {
                    if item.id == updatedItemParent.id {
                        item.isFavorite = onOff
                    
                        MainTableView.reloadRows(at: [IndexPath(row:row, section:4)], with: .none)
                    }
                    row += 1
                }
                
            }else{
                // 今表示しているのと同じならアップデートする

                let supplierDataSet = supplierList.getDataSetFor(displayMode: currentDisplayMode)

                var mainSection = 0
                var mainRow = 0
                for supplier in supplierDataSet!.suppliers!.list {
                    
                    var row = 0
                    for item in supplier.itemParents {
                        if item.id == updatedItemParent.id {
                            item.isFavorite = onOff
                            // どのセクションにショップリストが入っているのかを探して、データを更新する
                            for ditem in supplierDataSet!.displayItem {
                                if ditem.itemType == .SHOP_LIST {

                                    let cellMain = supplierDataSet?.tableView.cellForRow(at: IndexPath(row:mainRow, section:mainSection))
                                    if let collectionView = cellMain?.viewWithTag(200) as? OrosyUICollectionView {
                                    
                                        collectionView.reloadItems(at:[IndexPath(row:row, section:0)])
                                       // break　同じものが複数存在する場合がある
                                    }
                               }
                                mainSection += 1
                            }
                        }
                        row += 1
                    }
                    mainRow += 1

                }
            }
        }

    }

    @IBAction func sendNotification(_ sender: Any) {
    let content = UNMutableNotificationContent()
    content.title = "Orosyからのお知らせ"
    content.body = "メッセージを受信しました"
    content.sound = UNNotificationSound.default

    // 直ぐに通知を表示
    let request = UNNotificationRequest(identifier: "immediately", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)

    }

    func checkTrackingAuthorizationStatus() {
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .notDetermined:
            requestTrackingAuthorization()
        case .restricted:
            updateTrackingAuthorizationStatus(false)
        case .denied:
            updateTrackingAuthorizationStatus(false)
        case .authorized:
            updateTrackingAuthorizationStatus(true)
        @unknown default:
            fatalError()
        }
    }

  
    func requestTrackingAuthorization() {
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .notDetermined: break
            case .restricted:
                self.updateTrackingAuthorizationStatus(false)
            case .denied:
                self.updateTrackingAuthorizationStatus(false)
            case .authorized:
                self.updateTrackingAuthorizationStatus(true)
            @unknown default:
                fatalError()
            }
        }
    }

    func updateTrackingAuthorizationStatus(_ flag: Bool) {
        g_trackingAuthorized = flag
        //Settings.shared.isAdvertiserTrackingEnabled = flag
        //Settings.shared.isAdvertiserIDCollectionEnabled = flag
    }

    
}

// MARK: ==========================================
class ExtendSupplier:NSObject {     // Supplierクラスの中に保存する拡張データ
    var activityIndicator:UIActivityIndicatorView?
    var activityIndicatorForProducList:UIActivityIndicatorView?
    var row:Int = 0
    var showMore:Bool = false           // 「もっと見る」でオープンしているかどうか
}

// メインのサプライヤー一覧とカテゴリ検索で選択した情報を管理
class SupplierList:NSObject {

    struct SupplierDataSet {
        var displayMode:HomeDisplayMode
        var tableView:UITableView
        var suppliers:Suppliers?
        var items:[Item]?
        var displayItem:[HomeDisplayItem]
        var lockNextData = false      // 多重呼び出し防止用

    }
    
    var main:SupplierDataSet!
    var category:SupplierDataSet!
    var readPointer:Int = 0
    
    func initMain(tableView:UITableView ) -> Bool {
        let displayItem =
        [
            HomeDisplayItem(type: HomeItemType.PROMOTION, title: "バナー", cell:"PromotionCell", height:90),
            HomeDisplayItem(type: HomeItemType.WEEKLY_BRAND, title: "", cell:"NewCell", height:247),            // 週替わりブランド
            HomeDisplayItem(type: HomeItemType.NEWER, title: "新しい商品があるブランド", cell:"NewCell", height:247),            // 新着商品
            HomeDisplayItem(type: HomeItemType.SHOP_LIST, title: "", cell:"ShopCell", height:430 ),              // ショップ一覧、商品数に応じて行数が変わる
            HomeDisplayItem(type: HomeItemType.RECOMMEND, title: "", cell:"ProductCell", height:430 )              // リコメンド一覧、商品数に応じて行数が変わる
        ]
      
        readPointer = UserDefaultsManager.shared.readPointer
        
        if RECOMMEND_BRAND_PRODUCTS {

        }else{
            
            if let suppliers = Suppliers(categoryId: "", from: readPointer, size: 10, sort: .Newer, searchKey: .All) {
                
                main = SupplierDataSet(displayMode:.Home, tableView: tableView, suppliers: suppliers, displayItem: displayItem)
                return true
                
            }else{
                return false
            }
        }
        return true
    }
    
    func getItemPosition(itemType:HomeItemType) -> Int {
        switch itemType {
        case .PROMOTION: return 0
        case .NEWER: return 1
        case .SHOP_LIST: return 2
        default: return -1
        }
        
    }
    
    // 次のデータを取得　　Mainの場合は開始位置を指定するが、カテゴリの場合には指定しない

    func nextData(tableView:UITableView) -> Int {   // 取得したデータ件数を返す     -1 : error
        
        var count = 0
        var error = false
        var gotSupplier:[Supplier]!
        
        if tableView == main.tableView {
            if main.lockNextData { return 0 }
            
            main.lockNextData = true
            
            LogUtil.shared.log("Main: nexData:start")
            guard let suppliers = main.suppliers else { return -1 }
            
            gotSupplier = suppliers.fetch(readPointer: readPointer)  // サプライヤーの一覧を取得size:一度に取得する件数
            
            if gotSupplier == nil {
                error = true
                
            }else{
                LogUtil.shared.log("readPointer:\(readPointer), gotSupplier.count: \(gotSupplier.count)")
                
                if gotSupplier.count == 0 {
                    // ポインタを先頭へ戻して読み直す
                    readPointer = 0
                    gotSupplier = suppliers.fetch(readPointer: readPointer)  // size:一度に取得する件数
                    if gotSupplier == nil {
                        error = true
                        LogUtil.shared.log("gotSupplier is nil")
                    }else{
                        if gotSupplier.count == 0 {
                            error = true
                            LogUtil.shared.log("got zero data")
                        }else{
                            count = gotSupplier.count
                        }
                    }
                }else{
                    count = gotSupplier.count
                }
            }

            if error {
                LogUtil.shared.log("suppliers.fetch error")
                return -1
            }
            
            LogUtil.shared.log("suppliers.fetch count: \(count)")
            
            if count == 0 {
                UserDefaultsManager.shared.readPointer = 0
            }else{
                readPointer += count
                UserDefaultsManager.shared.readPointer = readPointer
            }
            
            UserDefaultsManager.shared.updateUserData()
            
            main.lockNextData = false
        }else{
            guard let suppliers = category.suppliers else { return -1 }
            category.lockNextData = true
            
            gotSupplier = suppliers.getNext()
            
            if gotSupplier == nil {
                error = true
            }else{
                if gotSupplier.count == 0 {
                    return 0  //　最後まで行ったら終わり
                }else{
                    count = gotSupplier.count
                }
            }
            if error {
                return -1     // 通信エラーの場合、リトライできるように、再読み込みを許可しておくためにtrueを返す
            }
            
            category.lockNextData = false
        }
        
        LogUtil.shared.log("Get ItemParents")
        //  取得したサプライヤ毎の商品一覧を取得
     //   let dispatchGroup = DispatchGroup()
  //      let dispatchQueue = DispatchQueue(label: "getSupplierQueue", attributes: .concurrent)
        
        DispatchQueue.global().async {
            for supplier in gotSupplier {
                //dispatchQueue.async(group: dispatchGroup) {
                    self.getItems(supplier:supplier)
                    
                   _ = OrosyAPI.cacheImage(supplier.imageUrls.first, imagesize:.Size500)   //  ブランドの代表画像をキャッシュへ入れる
                    
            }
        }
        // 全ての非同期処理完了を待つ
    //    dispatchGroup.wait()
        
        LogUtil.shared.log("Main: nextData:End got count:\(count)")
            
        return count
    }
    
    func getItems(supplier:Supplier) {
        let extendData = ExtendSupplier()
        extendData.showMore = false
        supplier.extendData = extendData

        // Itemparentを取得
        _ = supplier.getNextSupplierItemParents()
        for item in supplier.itemParents {
                item.extendData = ExtendSupplier()
        }
    }
    

    
    func initCategory(tableView:UITableView) {
        let displayItem =
            [
                HomeDisplayItem(type: HomeItemType.SHOP_LIST, title: "", cell:"ShopCell", height:430 )    // サプライヤ数に応じて行数が変わる
            ]
        category = SupplierDataSet(displayMode:.CategorySearchProduct, tableView: tableView, suppliers: nil, displayItem: displayItem)  // この段階ではサプライヤは未定

    }
    
    func setCategory(suppliers:Suppliers) {
        category.suppliers = suppliers
    }
    
    func getDataSetFor(tableView:UITableView) -> SupplierDataSet? {
        
        if tableView == main.tableView { return main }else{ return category }
        
    }
    func getDataSetFor(displayMode:HomeDisplayMode) -> SupplierDataSet? {
        
        if displayMode == .Home { return main }else{ return category }
        
    }
    

}


