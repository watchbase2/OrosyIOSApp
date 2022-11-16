//
//  LoginVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/17.
//

import UIKit

class LoginVC: OrosyUIViewController {
    
    @IBOutlet weak var login_id_field: OrosyTextField!
    @IBOutlet weak var password_field: OrosyTextField!
    @IBOutlet weak var waitIndicator: UIActivityIndicatorView!
    @IBOutlet weak var environment_field: UILabel!
    @IBOutlet weak var error_field: OrosyLabel12!
    @IBOutlet weak var explanation_field: OrosyLabel14!
    @IBOutlet weak var login_button: OrosyButton!
    @IBOutlet weak var signup_button: OrosyButton!
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
#if DEBUG
    #if DEVELOP
        login_id_field.text = "kanji@orosy.com"
        password_field.text = "W3d2zDW96uhy7MukB"
    #else
        login_id_field.text = "support-retail@orosy.com"
        password_field.text = "*vpxY34N6U-Wxg.V"
    #endif
#endif
        
        explanation_field.text = NSLocalizedString("RequestSignUp" , comment: "")
        error_field.isHidden = true
        environment_field.text = (DEVELOP_MODE) ? "開発環境" : ""
        login_button.setButtonTitle(title: "ログイン", fontSize: 12)
        signup_button.setButtonTitle(title: "初めて利用する方はこちら", fontSize: 12)
        
    }
    
    @IBAction func returnToTutorial(_ sender: Any) {
        self.orosyNavigationController?.popToRootViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func closeKeyboard(_ sender: Any) {
        if let field = login_id_field {
            field.resignFirstResponder()
        }
        if let field = password_field {
            field.resignFirstResponder()
        }
    }
    
    func loginCheck() -> Bool {
        // ログイン状態チェック
        var success = false
        LogUtil.shared.log("loginCheck")
        
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            let result = OrosyAPI.fetchCurrentAuthSession()
                        
            switch result {
            case .success(_):
                LogUtil.shared.log("success: fetchCurrentAuthSession")

                success = true
                semaphore.signal()
                
            case .failure(_):
                LogUtil.shared.log("fail: fetchCurrentAuthSession")
                semaphore.signal()

            }
        }
        
        semaphore.wait()

        if success {
            ProfileDetail.shared.getData()                       //　ログインしているユーザのプロファイル
        }
        
        return success
    }


    
    @IBAction func loginButtonPushed() {
        
        let userId = self.login_id_field.text ?? ""
        let passwd = self.password_field.text ?? ""
        
        waitIndicator.startAnimating()
        error_field.isHidden = true
        
        DispatchQueue.global().async {
   
           self.login(userid:userId, passwd:passwd )
        }
    }
    
    func login(userid:String, passwd:String ) {
        
        // すでにログイン中の場合でもエラーになるので、一旦ログアウトしてから再度ログインする
       OrosyAPI.signOut() { completion in
           
            OrosyAPI.signIn(userId:userid , password:passwd ) { completion in
                
                switch completion {
                case .success(let uid):
                    g_MyId = uid    // 内部ID
                    LogUtil.shared.log("signIn success")
                    UserDefaultsManager.shared.appInitiated = true
                    UserDefaultsManager.shared.updateUserData()
                    
                    DispatchQueue.main.async {
                        
                        // キーチェインに保存
                        KeyChainManager.shared.save(id:.loginId, value:userid)
                        KeyChainManager.shared.save(id:.password, value:passwd)
                        
                        if let userId = g_MyId {
                            LogUtil.shared.log("init UserLog")
                            g_userLog = UserLog(userId: userId)
                            if !UserDefaultsManager.shared.appInitiated {
                                g_userLog.installed()        // インストールしたことを送信
                            }
                            UserDefaultsManager.shared.loginId  = userid
                            UserDefaultsManager.shared.updateUserData()
                            g_loginMode = true
                            g_userLog.login()                // ログインしたことを送信
                            
                            let refresh = Notification.Name(NotificationMessage.EnteredIntoForeground.rawValue)  // データ更新を依頼
                            NotificationCenter.default.post(name: refresh, object: nil)
                        }
                        
                        ProfileDetail.shared.getData()         //　ログインしているユーザのプロファイルを取得
  

                        // 認証情報登録画面へ遷移　　　　　（遷移後、brokerステータスによって分岐）
                        DispatchQueue.main.async {
                        
                            let accountStatus = UserDefaultsManager.shared.accountStatus
                            
                            if accountStatus == .ApproveRequested {
                                if let _ = self.waitIndicator {
                                    self.waitIndicator.stopAnimating()
                                }
                                
                                // メール認証待ち画面へ
                                let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
                                let vc = storyboard.instantiateViewController(withIdentifier: "VerifyEmailVC") as! VerifyEmailVC
                                vc.displayMode = .notConfirmed
                                (UIApplication.shared.delegate as! AppDelegate).setRootViewController(viewControllerName: vc)
                                
                            }else{
                                ProfileDetail.shared.getData()
                                let brokerStatus = ProfileDetail.shared.brokerStatus
                                
                                if let _ = self.waitIndicator {
                                    self.waitIndicator.stopAnimating()
                                }
                                
                                if brokerStatus == .requested {
                                    // 利用開始！
                                    g_loginMode = true
                                    self.gotoHomePage()
                                    /*
                                    // 審査待ち画面へ
                                    LogUtil.shared.log("call vc from appDeegate: 審査待ち画面へ")
                                    let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
                                    let vc = storyboard.instantiateViewController(withIdentifier: "VerifyEmailVC") as! VerifyEmailVC
                                    vc.displayMode = .waitApprove
                                    (UIApplication.shared.delegate as! AppDelegate).setRootViewController(viewControllerName: vc)
                                     */
                                }else if  brokerStatus == .approved {
                                    // 審査済み
                                    UserDefaultsManager.shared.accountStatus = .AccountApproved
                                    
                                    // 利用開始！
                                    g_loginMode = true
                                    self.gotoHomePage()
                                }else{
                                    // 利用開始！
                                    g_loginMode = true
                                    // 審査入力画面へ
                                    let storyboard = UIStoryboard(name: "RetailerSB", bundle: nil)
                                    let vc = storyboard.instantiateViewController(withIdentifier: "RetailerInfoVC") as! RetailerInfoVC
                                    (UIApplication.shared.delegate as! AppDelegate).setRootViewController(viewControllerName: vc)
                                     
                                }
                            }
                        }
                    }
                    
                case .failure(let err):
                    LogUtil.shared.errorLog(error: err)
                    
                    DispatchQueue.main.async {
                        
                        if let _ = self.waitIndicator {
                            self.waitIndicator.stopAnimating()
                            self.error_field.isHidden = false
                            self.error_field.text = NSLocalizedString("LoginError" , comment: "")
                            self.login_id_field.setLineColor(UIColor.orosyColor(color: .Red))
                            self.password_field.setLineColor(UIColor.orosyColor(color: .Red))
                            
                        }
                    }
                }
            }
        }
    }
    
     func gotoHomePage() {
      //  g_loginMode = false
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateInitialViewController() {
            
            let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
            appDelegate.setRootViewController(viewControllerName: vc)   // ホームを開く
            if let window = appDelegate.window {
                UIView.transition(with: window,
                                  duration: 0.5,
                                  options: .transitionCrossDissolve,
                                  animations: nil,
                                  completion: nil)
            }
        }
    }
    
    @IBAction func showSignupView(_ sender: Any) {
        let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SignupVC") as! SignupVC
     //   vc.navigationItem.leftItemsSupplementBackButton = true
        self.orosyNavigationController?.pushViewController(vc, animated: true)
    }
}
