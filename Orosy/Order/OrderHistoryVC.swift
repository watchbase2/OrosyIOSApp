//
//  OrderHistoryVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/18.
//
/*
 仕入れ形式：itemsWholesale　にデータがあるか、itemConsignemntにあるかで判定する
 
 
 */
 
import UIKit

class OrderHistoryVC: OrosyUIViewController, UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching, OrosyProcessManagerDelegate {

    
    
    @IBOutlet weak var MainTableView: UITableView!
    @IBOutlet weak var waitIndicator: UIActivityIndicatorView!
    
    var orderList:[Order] = []
    var uuid_orderHistory:String!
    
    var fetchingNextData = false
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNaviTitle(title: "注文履歴")
        
        self.navigationItem.leftBarButtonItems = []     // 戻るボタンを非表示
        self.navigationItem.hidesBackButton = true
        
        self.noDataAlert.selectType(type: .orderHistory)
        self.noDataAlert.isHidden =  !(self.orderList.count == 0)
        
        //　テーブルの一番上にマージンを空ける
        let headerView = UIView(frame:CGRect(x:0, y:0, width:100, height:20))
        headerView.backgroundColor = UIColor.orosyColor(color: .Background)
        MainTableView.tableHeaderView = headerView
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(getData), name: Notification.Name(rawValue:NotificationMessage.SecondDataLoad.rawValue), object: nil)
        nc.addObserver(self, selector: #selector(getData), name: Notification.Name(rawValue:NotificationMessage.RefreshOrderList.rawValue), object: nil)
        nc.addObserver(self, selector: #selector(reset), name: Notification.Name(rawValue:NotificationMessage.Reset.rawValue), object: nil)
        
        MainTableView.refreshControl = UIRefreshControl()
        MainTableView.refreshControl?.addTarget(self, action: #selector(refreshTable), for: .valueChanged)
        

    }
    
    @objc func reset() {
        self.noDataAlert.isHidden = false
        g_orderListObject = nil
        orderList = []
        uuid_orderHistory = nil
        DispatchQueue.main.async {
            self.MainTableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if g_processManager.getStatus(uuid: uuid_orderHistory) == .Running {    // uuid_orderHistory == nil || 
            DispatchQueue.main.async {
                self.waitIndicator.startAnimating()
            }
        }
    }
    
    @objc func getData() {
        if g_orderListObject != nil {
            g_orderListObject = nil
       }
        g_orderListObject = OrderList(size: 10)
        LogUtil.shared.log ("注文履歴の読み込み")
        uuid_orderHistory = g_processManager.addProcess(name:"注文履歴", action:self.getOrderHistory , errorHandlingLevel: .IGNORE, errorCountLimit: -1, execInterval: 5, immediateExec: true, processType:.Once, delegate:self)
    }
    
    func getOrderHistory() -> Result<Any?, OrosyError> {
        
        if let orderHistory = g_orderListObject {
            let success =  orderHistory.getNextOrders()
            DispatchQueue.main.async {
                self.MainTableView.refreshControl?.endRefreshing()
            }
            return success
        }else{
            return .failure(OrosyError.NotInitialized)
        }
    }
    
    func processCompleted(_: String?) {
        LogUtil.shared.log ("注文履歴の表示")
        
        orderList = g_orderListObject.list
        DispatchQueue.main.async {
            
            if self.noDataAlert != nil {    // バックグランドでデータを取得しているので、まだビューが生成されていない場合がある
                self.noDataAlert.isHidden = !(self.orderList.count == 0)
            }
            self.waitIndicator.stopAnimating()
            self.MainTableView.refreshControl?.endRefreshing()
            self.MainTableView.reloadData()
        }
    }
    
    // MARK: リフレッシュコントロールによる読み直し
    @objc func refreshTable() {
        if fetchingNextData {
            DispatchQueue.main.async {
                self.MainTableView.refreshControl?.endRefreshing()
            }
            return
        }
    
        orderList.removeAll()
        DispatchQueue.main.async {
            
            self.MainTableView.reloadData()
        }
        getData()
    }
                               
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height:CGFloat = 170
        
        if self.view.bounds.width > 500 { height = 240}
        return height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
       // let section = indexPath.section
        let row = indexPath.row
        let order = orderList[row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "OrderHistoryCell", for: indexPath)
        
        /*
        // 選択された時のバックグランドカラー
        cell.selectionStyle = .default
        let view = UIView(frame:cell.frame)
        view.backgroundColor = UIColor.orosyColor(color: .Gray300)
        cell.selectedBackgroundView = view
        */
        
        let orderNumber_label = cell.viewWithTag(1) as! UILabel
        let date_label = cell.viewWithTag(2) as! UILabel
        let status_label = cell.viewWithTag(3) as! OrosyLabel10B
        let brand_label = cell.viewWithTag(4) as! UILabel
        let cost_label = cell.viewWithTag(5) as! UILabel
        
        orderNumber_label.text = "注文NO. " + (order.orderNo ?? "")
        date_label.text = Util.formattedDate(order.orderDay)
        brand_label.text = order.supplier?.brandName
        cost_label.text = Util.number2Str( order.totalAmount)
        
        status_label.text = order.orderStatusString
        let status_view = cell.viewWithTag(8) as! OrosyUIView

        
        switch order.orderStatus {
        case .PAYMENT_PENDING:
            status_view.backgroundColor = UIColor.orosyColor(color: .S200)
        case .PENDING:
            status_view.backgroundColor = UIColor.orosyColor(color: .S200)
        case .DONE:
            status_view.backgroundColor = UIColor.orosyColor(color: .S400)
        case .CANCEL:
            status_view.backgroundColor = UIColor.orosyColor(color: .Gray400)
        default:
            status_view.backgroundColor = UIColor.orosyColor(color: .Red)
        }
        
        let stackView = cell.contentView.viewWithTag(10) as! UIStackView
        
        var heightConstraint:NSLayoutConstraint
        var widthConstraint:NSLayoutConstraint

        
        if self.view.bounds.width > 500 {
            stackView.translatesAutoresizingMaskIntoConstraints = false

            heightConstraint = stackView.heightAnchor.constraint(equalToConstant: 100)
            widthConstraint = stackView.widthAnchor.constraint(equalToConstant: 870)

        }else{
            heightConstraint = stackView.heightAnchor.constraint(equalToConstant: 40)
            widthConstraint = stackView.widthAnchor.constraint(equalToConstant: 310)
        }
        NSLayoutConstraint.activate([heightConstraint, widthConstraint])
        var imgCount:Int = 0
        let maxImage = 8
        
        for item in order.itemsWholesale {

            if item.imageUrls.count > 0 && imgCount < maxImage {
                let imageView = stackView.viewWithTag(imgCount + 11) as! OrosyUIImageView100
            //    imageView.drawBorder(cornerRadius: 0, color: UIColor.orosyColor(color: .Gray200), width: 1)
                imageView.image = nil


                let rowPos = row * 10 + imgCount
                imageView.targetRow = rowPos
                imageView.getImageFromUrl(row: rowPos, url: item.imageUrls.first)
                imgCount += 1
            }
        }
        
        let overLabel = stackView.viewWithTag(19) as! UILabel
        
        if imgCount < 8 {
            for ip in imgCount..<maxImage {
                let imageView = stackView.viewWithTag(ip + 11) as! OrosyUIImageView100
                imageView.image = nil
                imageView.drawBorder(cornerRadius: 0, color: UIColor.clear, width: 0)

            }
            overLabel.text = ""         // 非表示にするとオブジェクトが一つ減り、他のオブジェクトの幅が変化してしまうので非表示にはしない
            
        }else{
            overLabel.text = "..."
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "OrderDetailVC") as! OrderDetailVC
        vc.navigationItem.leftItemsSupplementBackButton = true
        //vc.orderNo = orderList[indexPath.row].orderNo ?? ""
        vc.selectedOrder = self.orderList[indexPath.row]
        self.orosyNavigationController?.pushViewController(vc, animated: true)
    
        tableView.deselectRow(at: indexPath, animated: true)

        // バックグランドカラーを消す
        if let view = tableView.cellForRow(at: indexPath)?.selectedBackgroundView {
            view.alpha = 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        fetchingNextData = true
        
        DispatchQueue.global().async{
            let lastIndex = self.orderList.count
            
            if let orderHistory = g_orderListObject {
                let result = orderHistory.getNextOrders()
                
                switch result {
                case .success(let list):    //  cont = false　読み出すデータがなかった
                    if let data = list as? [Order] {
                        if data.count > 0 {
                            self.orderList = orderHistory.list
                            
                            DispatchQueue.main.async{
                                self.MainTableView.beginUpdates()
                                var addedIndexPaths:[IndexPath] = []
                                for ip in 0..<data.count  {
                                    addedIndexPaths.append(IndexPath(row:lastIndex + ip, section: 0))
                                }
                                self.MainTableView.insertRows(at: addedIndexPaths, with: .none)
                                self.MainTableView.endUpdates()

                            }
                            for row in lastIndex..<lastIndex + data.count {
                                if row < self.orderList.count - 1 {
                                    let order = self.orderList[row]
                                    for item in order.itemsWholesale {
                                        OrosyAPI.cacheImage(item.imageUrls.first, imagesize: .Size100)
                                    }
                                }
                            }
                        }
                    }
                    self.fetchingNextData = false
                    
                case .failure(let error):
                    print(error.localizedDescription)
                }
                
            }
        }
    } 

    
}
