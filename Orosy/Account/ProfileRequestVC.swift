//
//  ProfileRequestVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/05/18.
//

import UIKit


class ProfileRequestVC:OrosyUIViewController, ProfileRequestDelegate
{
    
    @IBOutlet weak var imageView:UIImageView!
    @IBOutlet weak var messageLabel1:OrosyLabel16!
    @IBOutlet weak var messageLabel2:OrosyLabel12!
    @IBOutlet weak var profileButton:OrosyButton!
    @IBOutlet weak var companyInfoButton:OrosyButton!
    
    @IBOutlet weak var label1: OrosyLabel14!
    @IBOutlet weak var label21: OrosyLabel14!
    
    @IBOutlet weak var completeView1:UIView!
    @IBOutlet weak var completeView2:UIView!
    
    var isHidden:Bool! {
        didSet {
            if let vw = self.view {
                vw.isHidden = isHidden
            }
        }
    }
    
    var businessCategory:[[String:Any]] = []
    
    override func viewDidLoad() {
       // super.viewDidLoad()
        self.orosyNavigationController?.view.layer.removeAnimation(forKey: "ModalAnimation")    // 画面遷移してくる時に使ったアニメーションを削除する
        
        self.view.isHidden = false
        
        self.tabBarController?.tabBar.isHidden = true
        self.orosyNavigationController!.setNavigationBarHidden(false, animated: true)
        //self.navigationItem.setLeftBarButton(nil, animated: true)        //　バックボタンを消す
        self.navigationItem.hidesBackButton = true
        
        imageView.image = UIImage(named:"no_profile")
        messageLabel1.text = NSLocalizedString("AskInputProfile", comment: "")
        messageLabel2.text = NSLocalizedString("AskInputProfileExplanation", comment: "")
        label1.text = "プロフィール情報"
        label21.text = "会社情報"
        profileButton.setButtonTitle(title: "整える", fontSize: 12)
        companyInfoButton.setButtonTitle(title: "整える", fontSize: 12)
        
        self.completeView1.isHidden = !RetailerDetail.shared.hasInputDone
        self.completeView2.isHidden = !ProfileDetail.shared.hasInputDone
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateStatus()
    }
    
    // CompanyProfileVCの場合にはモーダルで呼び出しているため、戻ってきてもviewWillDisplayが呼ばれないので、delegateでupdateStatusを呼び出す様にしている
    func updateStatus() {
        // 未完了なら完了すみを非表示にする
        DispatchQueue.main.async {
            self.completeView1.isHidden = !RetailerDetail.shared.hasInputDone
            self.completeView2.isHidden = !ProfileDetail.shared.hasInputDone
        }
        
        if RetailerDetail.shared.hasInputDone && ProfileDetail.shared.hasInputDone {
            UserDefaultsManager.shared.accountStatus = .AccountProfiled
            UserDefaultsManager.shared.updateUserData()
        }
        
        if RetailerDetail.shared.hasInputDone && ProfileDetail.shared.hasInputDone {
            
            // 完了していたら2秒後に自動クローズ
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.closeView()
            }
        }
        
    }
    
    @IBAction func showProfileView() {

        showProfileView(profile:true)
    }
    
    @IBAction func showComapnyInfoView() {

        showProfileView(profile:false)
    }
    
   
    func showProfileView(profile:Bool) {
        let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
 
        if profile {
            // プロフィールの入力を促す
            let vc = storyboard.instantiateViewController(withIdentifier: "ProfileVC") as! ProfileVC
            self.orosyNavigationController?.pushViewController(vc, animated: true)
        }else{
            // 会社情報の入力を促す
            let vc = storyboard.instantiateViewController(withIdentifier: "CompanyProfileVC") as! CompanyProfileVC
            vc.delegate = self     // モーダルで呼び出しているため、戻ってきてもviewWillDisplayが呼ばれないので、delegateでupdateStatusを呼び出す様にしている
            self.orosyNavigationController?.pushViewController(vc, animated: true)
        }
        
    }

    
    @IBAction override func closeView() {

        DispatchQueue.main.async {
            let transition2 = CATransition()
            transition2.duration = 0.4;
            transition2.timingFunction = CAMediaTimingFunction(name: .easeIn)
            transition2.type = .reveal  // 新しい画面が裏で準備された状態で、現在表示されている画面が幕のように移動して非表示になるスタイル
            transition2.subtype = .fromBottom
            self.orosyNavigationController?.view.layer.add(transition2, forKey: nil)

            self.tabBarController?.tabBar.isHidden = false
            LogUtil.shared.log("ProfileRequestVC close start")
            _ = self.orosyNavigationController?.popViewController(animated: false)          // 別にアニメーションさせるので、ここでは　falseにしておく
        }
    }
    
}
