//
//  PaymentSelectVC.swift   購入フロー中の支払い方法選択画面
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/11/08.
//

import UIKit
import WebKit

class PaymentSelectVC: OrosyUIViewController, UITableViewDelegate, UITableViewDataSource, WKUIDelegate, WKNavigationDelegate {
    
    @IBOutlet weak var MainTableView: UITableView!
    @IBOutlet weak var breadCrumbs: UIView!
    

    var selectedPaymentPoint = 0
    var paymentList:[Payment] = []
    
    override func viewDidLoad() {
        
        self.setNaviTitle(title: "支払い方法選択")
        
        if #available(iOS 15.0, *) {
            MainTableView.sectionHeaderTopPadding = 0.0 // iOS15から追加された、セクションヘッダーの上のスペースを消す
        }

        paymentList = g_paymentList.payments
        
        var find = false
        for payment in paymentList {
            if payment.type == g_cart.payment?.type ?? .NONE {
                find = true
                break
            }
            selectedPaymentPoint += 1
        }
        if !find {
            selectedPaymentPoint = 0
        }
        
        MainTableView.reloadData()
    }
   
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // パンくずをセット
        let breadCrum = self.children[0] as! BreadCrumbVC
        breadCrum.selectedPosition = 2
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // 画面から抜ける時に選択していた支払い方法を保存しておく
        g_userDefaults?.selectedPayment = paymentList[selectedPaymentPoint].type
        g_userDefaults?.setUserData()
        g_cart.payment = paymentList[selectedPaymentPoint]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let count = paymentList.count
        return count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = indexPath.section
        
        let payment = paymentList[section]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentCell", for: indexPath)
        
        let button = cell.viewWithTag(1) as! UIButton
        let label1 = cell.viewWithTag(2) as! UILabel
        let label2 = cell.viewWithTag(3) as! UILabel
        let imageView = cell.viewWithTag(4) as! OrosyUIImageView
        
        button.setTitle("", for: .normal)
        button.setImage(UIImage(named: "radio-button-unchecked"), for: .normal)
        button.setImage(UIImage(named: "radio-button-checked"), for: .selected)
        
        button.isSelected = (section == selectedPaymentPoint)
 
        label1.text = payment.name
        
        if payment.available {
            label2.text = ""
            imageView.isHidden = false
            imageView.getImageFromUrl(url: payment.imageUrl)
            cell.contentView.backgroundColor = .white
            
        }else{
            label2.text = "※準備中"
            imageView.isHidden = true
            cell.contentView.backgroundColor = UIColor.init(named: "Light Gray")

        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  
        let payment = paymentList[indexPath.section]
        
        if payment.available {
            selectedPaymentPoint = indexPath.section
            MainTableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let payment = paymentList[section]
        let view = tableView.dequeueReusableCell(withIdentifier: "FooterCell")?.contentView

        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
     
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        let payment = paymentList[section]
        
        var height:CGFloat = 0
        
  
        return height
    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {

    }
    
    @IBAction func gotoOrderComfirmationVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "OrderConfirmationVC") as! OrderConfirmationVC
        vc.navigationItem.leftItemsSupplementBackButton = true


        self.navigationController?.pushViewController(vc, animated: true)
    }
    

}
