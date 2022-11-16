//
//  DeliveryPlaceListVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/20.
//

import UIKit


class DeliveryPlaceListVC: OrosyUIViewController, UITableViewDataSource, UITableViewDelegate, DeliveryPlaceListVCDelegate {

    @IBOutlet weak var MainTableView: UITableView!
    
    var placeList:[DeliveryPlace] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNaviTitle(title: "納品先情報")
        
        if #available(iOS 15.0, *) {
            MainTableView.sectionHeaderTopPadding = 0.0 // iOS15から追加された、セクションヘッダーの上のスペースを消す
        }
  
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    func refresh() {
        let deliveryPlaces = DeliveryPlaces()
        let result = deliveryPlaces.getDeliveryPlaces()
        switch result {
        case .success(let places):
            placeList = places
            MainTableView.reloadData()
            
        case .failure(_):
            break
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
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
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension //自動設定
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return placeList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let row = indexPath.row
        
        var cell:UITableViewCell!
                
        cell = tableView.dequeueReusableCell(withIdentifier: "DeliveryListCell", for: indexPath)
        let place = placeList[row]
        
        let baseView = cell.viewWithTag(1000)!
        
        if row == 0 {
            baseView.roundCorner(cornerRadius: 4, lower: false)   // 上の両端だけ丸める
        }else if row == placeList.count - 1 {
            baseView.roundCorner(cornerRadius: 4, lower: true)   // 上の両端だけ丸める
        }
        
        let company = cell.viewWithTag(1) as! UILabel
        let address = cell.viewWithTag(2) as! UILabel
        let name = cell.viewWithTag(3) as! UILabel
        
        company.text = place.name
        address.text = (place.shippingAddress?.postalCode ?? "") + "\n" + (place.shippingAddress?.concatinated ?? "")     // 住所と建物名の間て改行させる
        name.text = place.shippingAddressName
        
        return cell
    }
    
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      
        let row = indexPath.row
        let place = placeList[row]
        
        // 配送先登録画面へ遷移
        let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DeliveryPlaceEditVC") as! DeliveryPlaceEditVC
        vc.selectedPlace = place
        vc.delegate = self
        
        // AccessLogに残す
        let targetUrl = (self.orosyNavigationController?.getNewTargetUrl(vc) ?? "")     //+ (place.deliveryPlaceId ?? "")
        self.orosyNavigationController?.sendAccessLog(modal:true, targetUrl:targetUrl)
        
        self.orosyNavigationController?.pushViewController(vc, animated: true)

    }

    @IBAction func addDeliveryPlace(_ sender: Any) {
        // 配送先登録画面へ遷移
        let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DeliveryPlaceEditVC") as! DeliveryPlaceEditVC
        vc.selectedPlace = nil
        vc.delegate = self
        let targetUrl = (self.orosyNavigationController?.getNewTargetUrl(self) ?? "") + "/add"
        self.orosyNavigationController?.sendAccessLog(modal:true, targetUrl:targetUrl)
        
        self.orosyNavigationController?.pushViewController(vc, animated: true)

    }
    
}
