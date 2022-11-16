//
//  ThreadListVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/12/18.
//

import UIKit

class ThreadListVC: OrosyUIViewController, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching,  UINavigationControllerDelegate, OrosyProcessManagerDelegate, ThreadListDelegate  {

    @IBOutlet weak var SupplierTableVIew: UITableView!      // メッセージ可能なサプライヤーを一覧表示するテーブル
    @IBOutlet weak var searchController: UISearchBar!
    @IBOutlet weak var searchControllerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var waitIndicator: UIActivityIndicatorView!
    
    var supplierThread:MessageThreads!         // メッセージ相手の一覧
    var unreadFlag:Bool = false                 // 未読メッセージ有り

    var uuid_thread:String?
    var uuid_message:String?

        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNaviTitle(title: "メッセージ")
        
        self.navigationItem.leftBarButtonItems = []     // 戻るボタンを非表示
        self.navigationItem.hidesBackButton = true 

        noDataAlert.selectType(type: .thread)
        // 検索バーのデザインカスタマイズ
        searchController.uiSetup()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(refreshTable), name: Notification.Name(rawValue:NotificationMessage.ReveicedThreadMessage.rawValue), object: nil)
        nc.addObserver(self, selector: #selector(startGetNewThreads), name: Notification.Name(rawValue:NotificationMessage.SecondDataLoad.rawValue), object: nil)
        nc.addObserver(self, selector: #selector(reset), name: Notification.Name(rawValue:NotificationMessage.Reset.rawValue), object: nil)

        SupplierTableVIew.refreshControl = UIRefreshControl()
        SupplierTableVIew.refreshControl?.addTarget(self, action: #selector(startGetNewThreads), for: .valueChanged)
    }
  
    @objc func reset() {
        
        if noDataAlert != nil { noDataAlert.isHidden = false }
        g_threadList = []
        supplierThread = nil
        uuid_thread = nil
        uuid_message = nil
        DispatchQueue.main.async {
            self.SupplierTableVIew.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if  g_processManager.getStatus(uuid: uuid_thread) == .Running { // uuid_thread == nil ||
            DispatchQueue.main.async {
                self.waitIndicator.startAnimating()
            }
        }
    }
    
    
    // 通知または、MessageVCからDelegateとして呼び出される
    @objc func startGetNewThreads() {
        
        g_threadList.removeAll()
        DispatchQueue.main.async {
            self.SupplierTableVIew.reloadData()
        }
        
        uuid_thread = nil
        uuid_thread =  g_processManager.addProcess(name:"スレッド一覧取得", action:self.getNewThreads , errorHandlingLevel: .ALERT_QUIT, errorCountLimit: 10, execInterval: 5, immediateExec: true, processType:.Once, delegate:self )
        
        // メッセージのサブスクリプションを開始
        if SubscriptionManager.shared.subscription == nil {
            _ = g_processManager.addProcess(name:"サブスクリプション開始", action:SubscriptionManager.shared.startSubscription , errorHandlingLevel: .IGNORE, errorCountLimit: -1, execInterval: 5, immediateExec: true, processType:.Once, delegate:self)
        }
    }
    
    func getNewThreads() -> Result< Any?, OrosyError> {
        LogUtil.shared.log ("スレッドの読み込み")
        supplierThread = MessageThreads(size: 20)  // 20は 一度に読み込む件数。　以降はスクロールする度に取得
        g_threadList = supplierThread?.threads ?? []    // これには、取引先の画像や名前は含まれていない
        DispatchQueue.main.async {
            self.noDataAlert.isHidden = (g_threadList.count > 0)
        }
        // 未読がないかチェックして画像をキャッシュへ入れる
        
        DispatchQueue.global().async {
            self.unreadFlag = false
            for thread in g_threadList {
                if thread.unread {
                    self.unreadFlag = true
                    break
                }
                if let url = thread.supplier?.iconImageUrl {
                    OrosyAPI.cacheImage(url, imagesize: .Size100)
                }
            }
        }
        
        // 最新のスレッドの日時を保存
        UserDefaultsManager.shared.latestThreadDate = g_threadList.first?.timestamp
        UserDefaultsManager.shared.updateUserData()

        return .success(true)
    }

    func processCompleted(_ _uuid: String?) {
        
        switch _uuid {
        case uuid_thread:
            DispatchQueue.main.async {
                self.waitIndicator.stopAnimating()
                self.SupplierTableVIew.reloadData()
                self.SupplierTableVIew.refreshControl?.endRefreshing()
            }
            /*
            // メッセージのサブスクリプションを開始
            if SubscriptionManager.shared.subscription == nil {
                _ = g_processManager.addProcess(name:"サブスクリプション開始", action:SubscriptionManager.shared.startSubscription , errorHandlingLevel: .IGNORE, errorCountLimit: -1, execInterval: 5, immediateExec: true, processType:.Once, delegate:self)
            }
            */
        default:
            
           break
        }
    }
    
    // MARK: リフレッシュコントロールによる読み直し
    @objc func refreshTable() {
        self.startGetNewThreads()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return g_threadList.count
    }
    
    let ImageContentSize:CGFloat = 150
    let ImageMargin:CGFloat = 10   // 吹き出し画像とラベルとのマージン
    let buttomMagin:CGFloat = 50   // 日付表示エリアとそのマージンの合計
    let MinWidth:CGFloat = 50
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return 90
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell!

        let row = indexPath.row

        // メッセージ可能なサプライヤーのリスト
        let thread = g_threadList[row]
        cell = tableView.dequeueReusableCell(withIdentifier: "ThreadCell", for: indexPath)
        cell.selectionStyle = .none
        
        // 選択された時のバックグランドカラー
        cell.selectionStyle = .default
        let view = UIView(frame:cell.frame)
        view.backgroundColor = UIColor.orosyColor(color: .Gray300)
        cell.selectedBackgroundView = view
        
        let button = cell.viewWithTag(100) as! IndexedButton
        button.indexPath = indexPath
        
        let imageView = cell.viewWithTag(1) as! OrosyUIImageView
        
        let label = cell.viewWithTag(2) as! UILabel
        label.text = ""
        let messageLabel = cell.viewWithTag(3) as! UILabel
        let dateLabel = cell.viewWithTag(4) as! UILabel
        
        // 別途取得している取引承認されている取引先情報と付き合わせることで、その情報を取得している
    
        imageView.image = nil
        
        if let supplier = g_connectedSuppliers?.getSupplier(supplier_id: thread.partnerUserId) {
            thread.supplier = supplier
            label.text = thread.supplier?.brandName
            imageView.targetRow = row
            imageView.getImageFromUrl(row: row, url: supplier.iconImageUrl, defaultUIImage: nil, radius: 25, fitImage: false)
        }

        if thread.no_message {
            thread.text = NSLocalizedString("NoMessage",comment: "")
            messageLabel.textColor = UIColor.orosyColor(color: .Gray400)
        }else{
            let fontSize = messageLabel.font.pointSize
            messageLabel.font = (thread.unread) ? UIFont(name: OrosyFont.Bold.rawValue, size: fontSize) : UIFont(name:OrosyFont.Regular.rawValue, size: fontSize)
            messageLabel.textColor = UIColor.orosyColor(color: .Black600)
        }
        messageLabel.text = thread.text

        let fontSize = dateLabel.font.pointSize
        dateLabel.text = Util.formattedDate(thread.timestamp) //  Util.formattedDateTime(thread.timestamp)
        dateLabel.font = (thread.unread) ? UIFont(name: OrosyFont.Bold.rawValue, size: fontSize) : UIFont(name:OrosyFont.Regular.rawValue, size: fontSize)
    
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // バックグランドカラーを消す
        if let view = tableView.cellForRow(at: indexPath)?.selectedBackgroundView {
            view.alpha = 0
        }
        
        //if !ProfileDetail.shared.profileRetailerRegistered { return }
        if UserDefaultsManager.shared.accountStatus != .AccountProfiled { return }
        
        let row = indexPath.row
        LogUtil.shared.log("a thread selected")
        
        let thread = g_threadList[row]
        
        self.showSupplierMessage(thread:thread)     // 選択されたサプライヤーのメッセージ表示に切り替える

        if thread.unread {
            thread.unread = false
            self.SupplierTableVIew.reloadRows(at: [indexPath], with: .none)
            DispatchQueue.global().async {
                _ = thread.markAsRead()     // 既読にする
                
            }
        }

    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        gettingNextData = true
        if let s_thread = self.supplierThread {
            DispatchQueue.global().async {
                let lastIndex =  s_thread.threads.count
                let count = s_thread.getNext().count
                if count > 0 {
                    g_threadList = s_thread.threads
                    DispatchQueue.main.async {
                        self.SupplierTableVIew.beginUpdates()
                        var addedIndexPaths:[IndexPath] = []
                        for ip in 0..<count  {
                            addedIndexPaths.append(IndexPath(row:lastIndex + ip, section: 0))
                        }
                        self.SupplierTableVIew.insertRows(at: addedIndexPaths, with: .none)
                        self.SupplierTableVIew.endUpdates()
                    }
                    for row in lastIndex..<lastIndex + count {
                        if row < g_threadList.count - 1 {
                            let thread = g_threadList[row]
                            if let url = thread.supplier?.iconImageUrl {
                                OrosyAPI.cacheImage(url, imagesize: .Size100)
                            }
                        }
                    }
                }
                self.gettingNextData = false
            }
        }
    }
    

    // MARK: スクロール
    var scrollBeginingPoint: CGPoint!
    var searchBarIsHidden = false
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollBeginingPoint = scrollView.contentOffset;
        
    }

    
    // スクロールしてテーブルの端に近づいたら、次のデータを取得
    var gettingNextData = false
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
            
        let scrollPosY = scrollView.contentOffset.y //スクロール位置
        let maxOffsetY = scrollView.contentSize.height - scrollView.frame.size.height //スクロール領域の高さからスクロール画面の高さを引いた値
        let distanceToBottom = maxOffsetY - scrollPosY //スクロール領域下部までの距離
        let currentPoint = scrollView.contentOffset;    //スクロール位置
        
        /*
        //スクロール領域下部に近づいたら追加で取得する
        if distanceToBottom < 400 && !gettingNextData {
            gettingNextData = true
            if let s_thread = self.supplierThread {
                DispatchQueue.global().async {
                    let lastIndex =  s_thread.threads.count
                    let count = s_thread.getNext().count
                    if count > 0 {
                        g_threadList = s_thread.threads
                        DispatchQueue.main.async {
                            var addedIndexPaths:[IndexPath] = []
                            for ip in 0..<count  {
                                addedIndexPaths.append(IndexPath(row:lastIndex + ip, section: 0))
                            }
                            self.SupplierTableVIew.insertRows(at: addedIndexPaths, with: .none)
                        }
                        for row in lastIndex..<lastIndex + count {
                            if row < g_threadList.count - 1 {
                                let thread = g_threadList[row]
                                if let url = thread.supplier?.iconImageUrl {
                                    OrosyAPI.cacheImage(url, imagesize: .Size100)
                                }
                            }
                        }
                    }
                    self.gettingNextData = false
                }
            }
        }
        */
        
        // ==============================
        // スクロール方向によってモードバーを非表示にする。

        if !self.SearchControllerIsHidden && self.scrollBeginingPoint.y < currentPoint.y - 20 && currentPoint.y > 60 {    // 少しスクロールしてから反応させる
            // 下へスクロール
            self.SearchControllerIsHidden = true
            
            
        }else if self.SearchControllerIsHidden && (self.scrollBeginingPoint.y > currentPoint.y + 40 || currentPoint.y < 40) {
            // 上へスクロール
            self.SearchControllerIsHidden = false      // これだけだと、少しだけ下へすくろーつしてスクロールする量が
            
        }else{
            return
        }
        
        openCloseSearchController(close:self.SearchControllerIsHidden)
        
     }
    
    // 商品・モデル選択ビュー
    var SearchControllerIsHidden = false
    func openCloseSearchController(close:Bool) {
        UIView.animate(withDuration: 0.3, // アニメーションの秒数
                       delay: 0.0, // アニメーションが開始するまでの秒数
                       options: [.curveEaseOut], // アニメーションのオプション 等速 | 繰り返し
                       animations: {
            
            self.searchControllerTopConstraint.constant = (close) ? 0 - self.searchController.bounds.height - 10 : 10
            
        }, completion: { (finished: Bool) in
            
        })
    }
    
    // メッセージ一覧を表示していないときにサブスクリプションでメッセージを受信し、それをローカル通知で表示した場合
    @objc func receivedNewMessage(notification: Notification) {
            
        // スレッド一覧を更新
        DispatchQueue.main.async {
            _ = self.getNewThreads()
        }

        guard let userInfo = notification.userInfo else { return }
        if let supplier_id = userInfo["SupplierId"] as? String {
            // メッセージ一覧を開く
            for  thread in g_threadList {
                if thread.partnerUserId == supplier_id {
                    //selectedSupplier = Supplier(supplierId: supplier_id, size:10)
                    showSupplierMessage(thread:thread)
                }
            }
        }
    }

    
    // MARK: サプライヤーとのメッセージ一覧
    // 選択されたているプライヤーのメッセージ一覧の表示画面へ遷移する
    func showSupplierMessage(thread:MessageThread) {
        LogUtil.shared.log("showSupplierMessage: start")
        //guard let supplier = selectedSupplier else { return }

        let storyboard = UIStoryboard(name: "MessageSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MessageVC") as! MessageVC
        
        vc.navigationItem.leftItemsSupplementBackButton = true
        vc.supplier = thread.supplier
        vc.delegate = self

        self.orosyNavigationController?.pushViewController(vc, animated: true)
 
    }

    @IBAction func showSupplierPage(_ button: IndexedButton) {
        
       if let row = button.indexPath?.row {
       
           let thread = g_threadList[row]
           showSupplierPage(supplier: thread.supplier!, activityIndicator: nil)
       }
    }
    
    var lockGotoSupplierPageButton = false
    // ブランド一覧でサプライヤを選択した場合にはsupplierが特定されているのでsupplierオブジェクトが渡されるようにしていたが、この方法だとWeb側でお気に入り情報が変化した場合、それを反映できないので、結局、毎回サプライヤー情報を読み直すこととした。
    // 新着情報やバナーの場合には、supplier idと画像ぐらいしか情報を持っていないので、supplier idが渡される
    public func showSupplierPage(supplier:Supplier, activityIndicator:UIActivityIndicatorView? = nil) {

        if lockGotoSupplierPageButton { return }         //　2度押し防止
        lockGotoSupplierPageButton = true
        
        if let act = activityIndicator  {
            DispatchQueue.main.async{
                act.startAnimating()
            }
        }
        
        DispatchQueue.global().async{

            if supplier.getAllInfo(wholeData: true) {
 
                // サプライヤーページへ遷移
                DispatchQueue.main.async{
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "ProductListVC") as! ProductListVC
                    object_setClass(vc.self, SupplierVC.self)
                    
                    vc.navigationItem.leftItemsSupplementBackButton = true
                    vc.productListMode = .ProductList
                    vc.supplier = supplier
                    
                    self.orosyNavigationController?.pushViewController(vc, animated: true)
                    
                    if let act = activityIndicator  {
                        act.stopAnimating()
                    }

                }
            }
            self.lockGotoSupplierPageButton = false
        }
    }
        
}
