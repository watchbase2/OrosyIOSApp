//
//  ShippingToVC.swift      購入フロー中の配送先選択画面
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/11/07.
//　配送先と支払い方法の選択画面
//
//  支払い方法の箇条書きの説明文はHTMLで作成してあり、s3からダウンロードして表示している。

import UIKit
import WebKit
import SafariServices

class DeliverySelectVC: OrosyUIViewController, UITableViewDelegate, UITableViewDataSource, DeliveryPlaceListVCDelegate {
    
    @IBOutlet weak var MainTableView: UITableView!
    
    var minimumChargeAmountError = false
    var placeList:[DeliveryPlace] = []
    var selectedPlacePointer:Int = 0

    var selectedPaymentPoint = 0
    var paymentList:[Payment] = []

    var tableHeight:[CGFloat] = []
    @IBOutlet weak var confirmButton: OrosyButton!
    
    var availablePaymentList:[Payment] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNaviTitle(title: "配送先と支払方法")
        
        if #available(iOS 15.0, *) {
            MainTableView.sectionHeaderTopPadding = 0.0 // iOS15から追加された、セクションヘッダーの上のスペースを消す
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"blank"), style:.plain, target: self, action: nil)    // タイトルがセンターになるようにダミーのボタンを配置
    
        confirmButton.setButtonTitle(title: "確認画面へ進む", fontSize: 16)
         
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(reset), name: Notification.Name(rawValue:NotificationMessage.Reset.rawValue), object: nil)

    }

    @objc func reset() {
        DispatchQueue.main.async{
            self.navigationController?.popToRootViewController(animated: false)
        }
    }

    func paymentRefresh() {
        //支払い方法
        let result = g_paymentList.getPaymentData
        paymentList = g_paymentList.payments
        
        var ip = 0
        selectedPaymentPoint = -1
        var tempArray:[Payment] = []
        
        for payment in paymentList {
            if payment.type ==  g_cart.payment?.type ?? UserDefaultsManager.shared.selectedPayment {       //　カートに設定がなければ前回の選択を使う
                selectedPaymentPoint = ip
            }
            
            if payment.available {
                ip += 1
                tempArray.append(payment)
            }
        }
        
        availablePaymentList = tempArray
        if selectedPaymentPoint > availablePaymentList.count - 1 { selectedPaymentPoint = -1 }
        
        ProfileDetail.shared.getData()
        print(ProfileDetail.shared.stripeAuthorized)
    }
    
    func refresh() {
        // 配送先を更新、追加から戻ってくるときに必要
        let deliveryPlaces = DeliveryPlaces()
        let result = deliveryPlaces.getDeliveryPlaces()
        switch result {
        case .success(let places):
            placeList = places
            break
        case .failure(_):
            break
        }
        
        // カートに保存されている配送先を選択状態にしておく
        var find = false
        for place in placeList {
            if place.name == g_cart.deliveryPlace?.name ?? "" {
                find = true
                break
            }
            selectedPlacePointer += 1
        }
        if !find { selectedPlacePointer = 0 }
        if placeList.count < selectedPlacePointer - 1 || placeList.count == 1 { selectedPlacePointer = 0 }
            
        confirmButton.isEnabled = (placeList.count > 0) ? true : false
        
  
        MainTableView.reloadData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        refresh()
        paymentRefresh()
        
        tableHeight = []
        MainTableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
                
        // 画面から抜ける時に選択していた配送先を保存しておく
        
        if placeList.count > 0 {
            if selectedPlacePointer > placeList.count - 1 { selectedPlacePointer = 0 }
            g_cart.deliveryPlace = placeList[selectedPlacePointer]
            let result = g_cart.deliveryPlace?.setDeliveryPlace()
            
            switch result {
            case .success(_):
                break
            case .failure(let error):
                confirmAlert(title: "エラー", message: error.localizedDescription, ok: "確認")
            case .none:
                break
            }
        }
        
        // 画面から抜ける時に選択していた支払い方法を保存しておく
        if selectedPaymentPoint > availablePaymentList.count - 1 { selectedPaymentPoint = 0 }
        if availablePaymentList.count > 0 && selectedPaymentPoint >= 0{
            UserDefaultsManager.shared.selectedPayment = availablePaymentList[selectedPaymentPoint].type
            UserDefaultsManager.shared.updateUserData()
            g_cart.payment = availablePaymentList[selectedPaymentPoint]
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 2
    }
    

    let HeaderHight:CGFloat = 60
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let label = UILabel(frame: CGRect(x:20, y:0, width:tableView.bounds.width - 40, height:HeaderHight))
        if section == 0 {
            label.text = "配送先情報"
        }else{
            label.text = "支払い方法"
        }
        label.textAlignment = .center
        label.font = UIFont(name: OrosyFont.Bold.rawValue, size: 16)
        label.backgroundColor = UIColor.orosyColor(color: .Background)
        
        return label

    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
     
        return HeaderHight
    }
 
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        if section == 0 {
            count = placeList.count
            if count == 0 { count = 1 } // 配送先追加ボタンを表示するため
        }else{
            count = availablePaymentList.count
        }
        return count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension //自動設定
 
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = indexPath.section
        let row = indexPath.row
        
        var cell:UITableViewCell!
                
        if section == 0 {
            
            if placeList.count == 0 {
                
                cell = tableView.dequeueReusableCell(withIdentifier: "DelieryPlaceAddCell", for: indexPath)
                let baseView = cell.viewWithTag(1000)!
                baseView.layer.cornerRadius = 5
                
            }else{
                cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath)
                let place = placeList[row]
                
                let baseView = cell.viewWithTag(1000)!
                
                baseView.layer.cornerRadius = 5
                
                let button = cell.viewWithTag(1) as! UIButton
                let label1 = cell.viewWithTag(2) as! UILabel

                if row == selectedPlacePointer {
                    button.isSelected = true
                    baseView.backgroundColor = UIColor.orosyColor(color: .S50)
                    baseView.layer.borderWidth = 1
                    baseView.layer.borderColor = UIColor.orosyColor(color: .Blue).cgColor
                }else{
                    button.isSelected = false
                    baseView.backgroundColor = .white
                    baseView.layer.borderWidth = 1
                    baseView.layer.borderColor = UIColor.white.cgColor
                }
                
                label1.text = place.name

                let label2 = cell.viewWithTag(3) as! UILabel
                label2.text = (place.shippingAddress?.postalCode ?? "") + "\n" + (place.shippingAddress?.concatinated ?? "")     // 住所と建物名の間て改行させる
                

            }

        }else{
            if row == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "PaymentCellWG", for: indexPath)
            }else{
                cell = tableView.dequeueReusableCell(withIdentifier: "PaymentCell", for: indexPath)
            }
            let payment = availablePaymentList[row]
            
            let baseView = cell.viewWithTag(1000)!
            baseView.layer.cornerRadius = 5
            baseView.layer.borderWidth = 1
            
            let button = cell.viewWithTag(1) as! UIButton
            let label1 = cell.viewWithTag(2) as! UILabel
            let bankLabel = cell.viewWithTag(4) as! UILabel
            let otherLabel = cell.viewWithTag(6) as! UILabel
            let contentLabel = cell.viewWithTag(7) as! UILabel
            let separatorLine = cell.viewWithTag(99) as! UIImageView


            label1.text = payment.name
            
            if row == 0 {
                //　翌月末支払い
                
                let npImage = cell.viewWithTag(10) as! OrosyUIImageView
                npImage.getImageFromUrl(row:row, url: payment.imageUrl)
                let npMessageLabel = cell.viewWithTag(12) as! UILabel
                
               // ProfileDetail.shared.npStatus = .requested

                if ProfileDetail.shared.npStatus == .approved {
                    //支払いOK
                    npMessageLabel.text = ""
                    
                    if row == selectedPaymentPoint {
                        button.isSelected = true
                        baseView.backgroundColor = UIColor.orosyColor(color: .S50)
                        baseView.layer.borderColor = UIColor.orosyColor(color: .Blue).cgColor
                    }else{
                        button.isSelected = false
                        baseView.backgroundColor = UIColor.white
                        baseView.layer.borderColor = UIColor.white.cgColor
                    }
                    
                    label1.textColor = UIColor.orosyColor(color: .Black600)
                    bankLabel.textColor = UIColor.orosyColor(color: .Black600)
                    otherLabel.textColor = UIColor.orosyColor(color: .Black600)
                    contentLabel.textColor = UIColor.orosyColor(color: .Black600)
                    separatorLine.backgroundColor = UIColor.orosyColor(color: .Background)
                    
                }else{
                    
                    if selectedPaymentPoint == 0 {selectedPaymentPoint = -1}    // approveでなければ選択できない
                    // 支払いできない
                    baseView.backgroundColor = UIColor.orosyColor(color: .Background)
                    baseView.layer.borderColor = UIColor.orosyColor(color: .Gray400).cgColor
                    button.isSelected = false
                    
                    label1.textColor = UIColor.orosyColor(color: .Gray400)
                    bankLabel.textColor = UIColor.orosyColor(color: .Gray400)
                    otherLabel.textColor = UIColor.orosyColor(color: .Gray400)
                    contentLabel.textColor = UIColor.orosyColor(color: .Gray400)
                    separatorLine.backgroundColor = UIColor.orosyColor(color: .Gray400)
                    
                    let textAttributes1: [NSAttributedString.Key : Any] = [
                        .font : UIFont(name: OrosyFont.Bold.rawValue, size: 14)!,
                        .foregroundColor : UIColor.orosyColor(color: .Red)
                        ]
                    let line1 = NSAttributedString(string: "\n" + NSLocalizedString("WaitApproveNP", comment: "") + "\n", attributes: textAttributes1)
                    
                    let textAttributes2: [NSAttributedString.Key : Any] = [
                        .font : UIFont(name: OrosyFont.Regular.rawValue, size: 10)!,
                        .foregroundColor : UIColor.orosyColor(color: .Black600)
                        ]
                    let line2 = NSAttributedString(string: NSLocalizedString("WaitApproveNPMessage", comment: "") + "\n", attributes: textAttributes2)
                    
                    let combination = NSMutableAttributedString()
                    combination.append(line1)
                    combination.append(line2)
                    npMessageLabel.attributedText = combination
                    
                }
            }else{
                // 90日支払い
                let messageView = cell.viewWithTag(200)!
                               
                if ProfileDetail.shared.stripeAuthorized && !minimumChargeAmountError {
                    //支払いOK
                    if row == selectedPaymentPoint {
                        button.isSelected = true
                        baseView.backgroundColor = UIColor.orosyColor(color: .S50)
                        baseView.layer.borderColor = UIColor.orosyColor(color: .Blue).cgColor
                    }else{
                        button.isSelected = false
                        baseView.backgroundColor = UIColor.white
                        baseView.layer.borderColor = UIColor.white.cgColor
                    }
                    
                    label1.textColor = UIColor.orosyColor(color: .Black600)
                    bankLabel.textColor = UIColor.orosyColor(color: .Black600)
                    otherLabel.textColor = UIColor.orosyColor(color: .Black600)
                    contentLabel.textColor = UIColor.orosyColor(color: .Black600)
                    separatorLine.backgroundColor = UIColor.orosyColor(color: .Background)
                    
                    messageView.isHidden = true
                }else{
                    // 支払いできない
                    baseView.backgroundColor = UIColor.orosyColor(color: .Background)
                    baseView.layer.borderColor = UIColor.orosyColor(color: .Gray400).cgColor
                    button.isSelected = false
                    
                    label1.textColor = UIColor.orosyColor(color: .Gray400)
                    bankLabel.textColor = UIColor.orosyColor(color: .Gray400)
                    otherLabel.textColor = UIColor.orosyColor(color: .Gray400)
                    contentLabel.textColor = UIColor.orosyColor(color: .Gray400)
                    separatorLine.backgroundColor = UIColor.orosyColor(color: .Gray400)
        
                    messageView.isHidden = false
                    let messageLabel = messageView.viewWithTag(201) as! OrosyLabel14B
                    messageLabel.text = NSLocalizedString("StripeNotAuthorized", comment: "")
                    
                    let loginButton = messageView.viewWithTag(202) as! OrosyButtonWhite
                    loginButton.setButtonTitle(title: "申し込む", fontSize: 12)
                   
                }
                
            }

           contentLabel.text = payment.description_text
           tableView.beginUpdates()
           tableView.setNeedsDisplay()
           tableView.endUpdates()
        }


        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  
        let section = indexPath.section
        let row = indexPath.row
        
        // テーブルをリロードすると、ラベルのサイズが予期せぬ変化をするので、リロードせずにここで必要な部分だけを更新するようにした
        if section == 0 {
                        
            selectedPlacePointer = row
 
            for ip in 0..<placeList.count {
                if let cell = tableView.cellForRow(at: IndexPath(row:ip, section:section)) {
                    let button = cell.viewWithTag(1) as! UIButton
                    let baseView = cell.viewWithTag(1000)!
                    
                    if ip == selectedPlacePointer {
                        button.isSelected = true
                        baseView.backgroundColor = UIColor.orosyColor(color: .S50)
                        baseView.layer.borderColor = UIColor.orosyColor(color: .Blue).cgColor
                    }else{
                        button.isSelected = false
                        baseView.backgroundColor = UIColor.white
                        baseView.layer.borderColor = UIColor.white.cgColor
                    }
                }
            }
        }else{
            
            if row == 0 && ProfileDetail.shared.npStatus != .approved { return }
            if row == 1 && !ProfileDetail.shared.stripeAuthorized { return }
            
            selectedPaymentPoint = row
            
            for ip in 0..<paymentList.count {
                if let cell = tableView.cellForRow(at: IndexPath(row:ip, section:section)) {
                    let button = cell.viewWithTag(1) as! UIButton
                    let baseView = cell.viewWithTag(1000)!
                    
                    if ip == selectedPaymentPoint {
                        button.isSelected = true
                        baseView.backgroundColor = UIColor.orosyColor(color: .S50)
                        baseView.layer.borderColor = UIColor.orosyColor(color: .Blue).cgColor
                    }else{
                        button.isSelected = false
                        baseView.backgroundColor = UIColor.white
                        baseView.layer.borderColor = UIColor.white.cgColor
                    }
                }
            }

        }
 
    }

    
    @IBAction func gotoOrderComfirmationVC() {
        
        if selectedPaymentPoint == -1 {
            let dialog =  SmoothDialog()
            self.view.addSubview(dialog)
            dialog.show(message: NSLocalizedString("PaymentNotSelected", comment: ""))
            
        }else{
            let storyboard = UIStoryboard(name: "CartSB", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "OrderConfirmationVC") as! OrderConfirmationVC
            vc.navigationItem.leftItemsSupplementBackButton = true

            self.orosyNavigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func helpForDeferedPayment(_ sender: Any) {
    
        let url = URL(string: "https://help.orosy.com/hc/ja/articles/4409342048665")
        if let url = url {
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: false, completion: nil)
        }
    }
    
    @IBAction func helpFor90DaysPayment(_ sender: Any) {
    
        let url = URL(string: "https://help.orosy.com/hc/ja/articles/4408486253977")
        if let url = url {
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: false, completion: nil)
        }
    }
    
    @IBAction func showAddDeliveryPlace() {
        let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DeliveryPlaceEditVC") as! DeliveryPlaceEditVC
        vc.delegate = self
        
        self.orosyNavigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func showAddCreditCardView() {
        
       // self.showLoginView()
        
        let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PaymentInfoVC") as! PaymentInfoVC
         
        self.orosyNavigationController?.pushViewController(vc, animated: true)
        
    }
}

