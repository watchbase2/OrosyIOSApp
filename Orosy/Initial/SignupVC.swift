//
//  SignupVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/05/05.
//

import UIKit
import SafariServices

class SignupVC:OrosyUIViewController {

    @IBOutlet weak var login_id_field: OrosyTextField!
    @IBOutlet weak var password_field: OrosyTextField!
    @IBOutlet weak var waitIndicator: UIActivityIndicatorView!
    @IBOutlet weak var environment_field: UILabel!
    @IBOutlet weak var error_field: OrosyLabel12!
    @IBOutlet weak var explanation_field: OrosyLabel14!
    @IBOutlet weak var login_button: OrosyButton!
    @IBOutlet weak var signup_button: OrosyButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
               
        let boldAttribute: [NSAttributedString.Key : Any] = [
            .font : UIFont(name: OrosyFont.Bold.rawValue, size: 14)!,
            .foregroundColor : UIColor.orosyColor(color: .Blue)
            ]
        let normalAttribute: [NSAttributedString.Key : Any] = [
            .font : UIFont(name: OrosyFont.Regular.rawValue, size: 14)!,
            .foregroundColor : UIColor.orosyColor(color: .Black600)
            ]
   
        //"PolicyAckMessage" = "ご利用には $(利用規約) と $(プライバシーポリシー) への 同意が必要です。";
        
        let userAck = NSAttributedString(string: "利用規約", attributes: boldAttribute)
        let policy = NSAttributedString(string: "プライバシーポリシー", attributes: boldAttribute)
        
        let text1 = NSAttributedString(string: "ご利用には ", attributes: normalAttribute)
        let text2 = NSAttributedString(string: " と ", attributes: normalAttribute)
        let text3 = NSAttributedString(string: " への\n同意が必要です。", attributes: normalAttribute)
        
        let combination = NSMutableAttributedString()
        combination.append(text1)
        combination.append(userAck)
        combination.append(text2)
        combination.append(policy)
        combination.append(text3)
        
        explanation_field.attributedText = combination
        
        error_field.isHidden = false
        error_field.text = NSLocalizedString("SignupSubTitle", comment: "")
        
        environment_field.text = (DEVELOP_MODE) ? "開発環境" : ""
        login_button.setButtonTitle(title: "アカウントを作成", fontSize: 12)
        signup_button.setButtonTitle(title: "既にアカウントをお持ちの方はこちら", fontSize: 12)
        
    }
    

    @IBAction func closeKeyboard(_ sender: Any) {
        if let field = login_id_field {
            field.resignFirstResponder()
        }
        if let field = password_field {
            field.resignFirstResponder()
        }
    }
    @IBAction func policyBrowser(_ sender: Any) {
        
        let button = sender as! UIButton
        
        var urlStr = termsForBuyerURL
        if button.tag == 2 {
            urlStr = privacyPlicyURL
        }
        
        let url = URL(string: urlStr)
        if let url = url {
            let safariViewController = SFSafariViewController(url: url)
            safariViewController.delegate = self
            present(safariViewController, animated: false, completion: nil)
        }
    }
    
    @IBAction func signupButtonPushed(_ sender: Any) {
        self.error_field.isHidden = true
        self.waitIndicator.startAnimating()
        
        let loginId = self.login_id_field.text ?? ""
        let passwd = self.password_field.text ?? ""
        
        if loginId.count == 0 || passwd.count == 0 {
            self.error_field.isHidden = false
            self.error_field.text = NSLocalizedString("LoginError" , comment: "")
            self.login_id_field.setLineColor(UIColor.orosyColor(color: .Red))
            self.password_field.setLineColor(UIColor.orosyColor(color: .Red))
            return
        }

        // ID, Passwdをキーチェインに保存
        KeyChainManager.shared.save(id:.loginId, value:loginId)
        KeyChainManager.shared.save(id:.password, value:passwd)
        
        DispatchQueue.global().async {
            OrosyAPI.signOut() { completion in
                
                OrosyAPI.signUp(userId:loginId , password:passwd , email: loginId ) { completion in
                    
                    switch completion {
                    case .success:
                        LogUtil.shared.log("Signup success: \(loginId)")
                        UserDefaultsManager.shared.appInitiated = true
                        UserDefaultsManager.shared.updateUserData()
                        
                        //　メール認証待ち画面を表示
                        UserDefaultsManager.shared.accountStatus = .AccountNotVerified
                        UserDefaultsManager.shared.updateUserData()
                
                        self.showVerifyEmailVIew(displayMode: .notConfirmed)
                        
                    case .failure(let _):
                        // signupできなかった
                        
                        var displayMode:VeryfyEmailDisplayMode = .otherError
                        
                        OrosyAPI.signIn(userId: loginId, password: passwd) { signinResult in
                        
                            switch signinResult {
                            case .success:
                                //　認証済みなのでログインへ誘導
                                LogUtil.shared.log("認証済みのIDでSignupしようとしました")
                                displayMode = .aleradyConfirmed
                                UserDefaultsManager.shared.appInitiated = true
                                UserDefaultsManager.shared.updateUserData()
                            case .failure(let orosyError):
                                
                                switch orosyError {
                                    
                                case OrosyError.UserNotConfirmed:
                                    //　メール認証が完了していない

                                    displayMode = .notConfirmed
                                    OrosyAPI.resend(userId:loginId) { completion in
                                        LogUtil.shared.log("認証メールを再送した")
                                    }
                                default:
                                    
                                        DispatchQueue.main.async {
                                            self.error_field.isHidden = false
                                            self.error_field.text = NSLocalizedString("SinupError" , comment: "")
                                            self.error_field.textColor = UIColor.orosyColor(color: .Red)
                                            self.login_id_field.setLineColor(UIColor.orosyColor(color: .Red))
                                            self.password_field.setLineColor(UIColor.orosyColor(color: .Red))
                                            self.waitIndicator.startAnimating()
                                        }
                                    return
                                }

                            }
                            self.showVerifyEmailVIew(displayMode: displayMode)
                        }
                    }
                }
            }
        }

    }

    
    @IBAction func returnToTutorial(_ sender: Any) {
        // アプリのインストール直後状態へ戻す
        UserDefaultsManager.shared.accountStatus = .AppInstalled
        UserDefaultsManager.shared.updateUserData()
        
        let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
        if let vc = storyboard.instantiateInitialViewController() {
           // (UIApplication.shared.delegate as! AppDelegate).setRootViewController(viewControllerName: vc)
            let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
            appDelegate.setRootViewController(viewControllerName: vc)
            
            if let window = appDelegate.window {
                UIView.transition(with: window,
                                  duration: 0.5,
                                  options: .transitionCrossDissolve,
                                  animations: nil,
                                  completion: nil)
            }
            
        }
    }
    
    @IBAction func returnToLoginPage(_ sender: Any) {
        
        self.orosyNavigationController?.popViewController(animated: true)
        /*
        let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
        loginVC.modalPresentationStyle = .fullScreen
        if var viewControllers = self.orosyNavigationController?.viewControllers {
            viewControllers.removeLast()
            self.orosyNavigationController?.viewControllers = viewControllers
            self.orosyNavigationController?.pushViewController(loginVC, animated: true)
        }
         */
    }
    
    @IBAction func gotoHomePage() {
        g_loginMode = false
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
    
    func showVerifyEmailVIew(displayMode:VeryfyEmailDisplayMode) {
        
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "VerifyEmailVC") as! VerifyEmailVC
            vc.displayMode = displayMode
            self.orosyNavigationController?.pushViewController(vc, animated: true)
        }
    }
}
