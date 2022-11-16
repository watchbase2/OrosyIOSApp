//
//  ApplyConnection.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/23.
//

import UIKit


protocol ApplyCoonectionDelegate: AnyObject {
    func conectionUpdated()     // 閲覧申請したので、Connection情報をアップデートする必要がある
}

class  ApplyCoonectionVC: OrosyUIViewController {
    // 上位から与えられるパラメータ
    var supplier:Supplier!
    var referer:String?

    //
    @IBOutlet weak var supplier_nameLabel: UILabel!
    @IBOutlet weak var supplier_imageView: OrosyUIImageView!
    @IBOutlet weak var apply_button: OrosyButtonGradient!
    
    
    func getItemidForPageUrl() -> String {
        return supplier.id
    }
    
    override func viewDidLoad() {
        
        self.setNaviTitle(title: "取引申請")
        
        supplier_nameLabel.text = supplier.brandName
        supplier_imageView.getImageFromUrl(url: supplier.imageUrls.first)
        supplier_imageView.drawBorder(cornerRadius: supplier_imageView.bounds.height / 2.0)     // 丸くカット

        apply_button.setButtonTitle(title: "申請する", fontSize: 16)

        self.view.roundCorner(cornerRadius: 14, lower: false)           //　上だけを丸める

    }
    
    @IBAction func showSupplierPage(_ sender: Any) {
    
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SupplierVC") as! SupplierVC
        vc.navigationItem.leftItemsSupplementBackButton = true
        vc.supplierId = supplier.id
        self.orosyNavigationController?.pushViewController(vc, animated: true)

    }
    
    @IBAction func showConditions(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PopupRestrictionVC") as! PopupRestrictionVC
        vc.navigationItem.leftItemsSupplementBackButton = true
        vc.supplier = supplier
        vc.restrictionMode = true
        self.present(vc,animated: true,completion: nil)

    }
    
    @IBAction func apply(_ sender: Any) {

        let result = supplier.askTradeConnection()
        
        switch result {
        case .success(_):
            confirmAlert(title: "ブランドからの回答をお待ち下さい", message: "", ok:"OK") { completion in
                let notification = Notification.Name(NotificationMessage.RefreshApplyStatus.rawValue)   // ステータスの更新を依頼
                NotificationCenter.default.post(name: notification, object: nil, userInfo: ["supplierId":self.supplier.id])
                self.dismiss(animated: true, completion: nil)
                
            }
            g_userLog.askTradeRequest(supplierId: supplier.id, pageUrl: self.orosyNavigationController?.currentUrl ?? "")
            
        case .failure(let error):
            confirmAlert(title: "エラー", message: "申請できませんでした:\(error.localizedDescription)", ok:"OK") { completion in
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
    
        self.dismiss(animated: true, completion: nil)
    }
}
