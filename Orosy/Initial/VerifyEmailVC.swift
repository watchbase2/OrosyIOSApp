//
//  VerifyEmailVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/05/05.
//

import UIKit


// メールで送られた認証コードを使って認証する

enum VeryfyEmailDisplayMode {
    case success
    case verified               // メール認証済み
    case codeExpired            //　認証コード期限切れ
    case notConfirmed
    case aleradyConfirmed       // 認証済みなのに認証しようとした
    case waitApprove            //　審査完了待ち
    case otherError             // 認証コードが間違っているとか・・
    case requestLogin           // ログインを要求
}

class VerifyEmailVC:OrosyUIViewController, UITextFieldDelegate {

    @IBOutlet weak var baseView: OrosyUIView!
    @IBOutlet weak var contentAreaHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var logoutButtonForDebug: OrosyButton!
    @IBOutlet weak var codeInputForDebug: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var verifyCode:String?
    
    var displayMode:VeryfyEmailDisplayMode = .success
    
    var imageView:UIImageView!
    var mainLabel:UILabel!
    var subLabel:UILabel!
    var notificaiton:UILabel!
    var sendMailLabel:UILabel!
    var mainButton:OrosyButton!
    var mainButton2:OrosyButton!
    var sentMailButton:OrosyButton!
    var subnButton:OrosyButton!
    
    var timer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.isHidden = true
        
        imageView = self.baseView.viewWithTag(10) as? UIImageView
        mainLabel = self.baseView.viewWithTag(1) as? UILabel
        subLabel = self.baseView.viewWithTag(2) as? UILabel
        notificaiton = self.baseView.viewWithTag(3) as? UILabel
        sendMailLabel = self.baseView.viewWithTag(4) as? UILabel
        
        mainButton = self.baseView.viewWithTag(20) as? OrosyButton
        mainButton2 = self.baseView.viewWithTag(21) as? OrosyButton
        subnButton = self.baseView.viewWithTag(22) as? OrosyButton
        sentMailButton = self.baseView.viewWithTag(23) as? OrosyButton
        
    //    let enc = NotificationCenter.default
   //     enc.addObserver(self, selector: #selector(enteredIntoForeground), name: Notification.Name(rawValue:NotificationMessage.EnteredIntoForeground.rawValue), object: nil)
        
        displayUpdate(mode:displayMode)

#if DEBUG
   //     logoutButtonForDebug.isHidden = false
   //     codeInputForDebug.isHidden = false
#endif
    }
    
    func displayUpdate(mode:VeryfyEmailDisplayMode) {
        
        displayMode = mode
        
        switch mode {
        case .success:          showSentEmail()          // emails送信済み
        case .notConfirmed:     showSentEmail()
        case .verified:         vefiryCompleted()        // 認証済み（正常）
        case .aleradyConfirmed: showAlreadyVerified()    // 認証すみのメアドでアカウントを作成しようとした
        case .codeExpired:      urlExpired()             // コードが期限切れになっている
        case .waitApprove:      waitApprove()            // 申請完了待ち
        case .requestLogin:     requestLogin()
        default:                showSentEmail()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {

        if displayMode == .waitApprove {
            /*
            if timer == nil {
                fetchApproval()
                
                timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(fetchApproval), userInfo:nil, repeats: true)
            }
             */
        }else if displayMode == .requestLogin {
            
        }else if displayMode == .notConfirmed {
            if timer == nil {
                fetchLogin()
                
                timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(fetchLogin), userInfo:nil, repeats: true)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopTImer()
    }
    
    func stopTImer() {
        if let tm = timer {
            tm.invalidate()
        }
    }
    
    @objc func enteredIntoForeground() {
        /*
        // ログインに成功した
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewControllerName = storyboard.instantiateInitialViewController() {
            self.orosyNavigationController?.setViewControllers([viewControllerName], animated: true)
            return
        }
         */
    }
    
    // 審査待ち
    @objc func fetchApproval() {
        ProfileDetail.shared.getData()
        let brokerStatus = ProfileDetail.shared.brokerStatus
        //let brokerStatus = ProfileStatus.approved // テスト用
        
        if brokerStatus == .approved {
            UserDefaultsManager.shared.accountStatus = .AccountApproved
            UserDefaultsManager.shared.updateUserData()
            
            DispatchQueue.main.async {
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let vc = storyboard.instantiateInitialViewController() {
                    (UIApplication.shared.delegate as! AppDelegate).setRootViewController(viewControllerName: vc)       // ルートをProfileInputVCにする
                }
                if let tm = self.timer {
                    tm.invalidate()
                }
            }
        }
    }
    
    // 定期的にログインが可能になったか認証コードを受信したかをチェック
    @objc func fetchLogin() {
        
        var success:Bool = false
        if let code = self.verifyCode {
            success = self.verifyCode(code:code)
        }
        
        if success {
            return
        }
        // ID, Passwdをキーチェインから取得
        let userid = KeyChainManager.shared.load(id:.loginId) ?? ""
        let passwd = KeyChainManager.shared.load(id:.password) ?? ""
        
        if userid == "" || passwd == "" {
            // ありえない?
            if let tm = timer {
                tm.invalidate()
            }
            return

        }
        
        // チェックするが、ログイン状態にはしない
        OrosyAPI.signIn(userId:userid , password:passwd ) { completion in
            
            switch completion {
            case .success(_):
                
                if UserDefaultsManager.shared.accountStatus == .AccountVerified {
                    DispatchQueue.main.async {
                        self.vefiryCompleted()
                        if let tm = self.timer {
                            tm.invalidate()
                        }
                    }
                }
                
            case .failure(_):

            break
            }
        }
    }
    
    
    // Verify用email送信済み
    @IBAction func showSentEmail() {
        contentAreaHeightConstraint.constant = 298
        imageView.image = UIImage(named:"waitEmailValidation")
        mainLabel.text = NSLocalizedString("EmailSentOut", comment: "")
        subLabel.text = NSLocalizedString("EmailSentOutExplanation", comment: "")
        notificaiton.text = NSLocalizedString("EmailNotification", comment: "")
        mainButton.isHidden = true
        mainButton2.isHidden = true
        
        subnButton.isHidden = false
        subnButton.setButtonTitle(title: "アカウントを作成", fontSize: 12)
        sentMailButton.isHidden = false
        sentMailButton.setButtonTitle(title: "メールを再送する", fontSize: 12)
        sendMailLabel.isHidden = false
        sendMailLabel.text = NSLocalizedString("ReSentEmail", comment: "")
    }
    
    @IBAction func showAlreadyVerified() {
        contentAreaHeightConstraint.constant = 378
        imageView.image = UIImage(named:"alreadyVerifyed")      // すでにメール認証済み
        mainLabel.text = NSLocalizedString("AlreadyVerified", comment: "")
        subLabel.text = NSLocalizedString("AlreadyVerifiedExplanation", comment: "")
        notificaiton.text = ""
        mainButton.setButtonTitle(title: "利用を開始", fontSize: 12)
        mainButton.isHidden = false
        mainButton2.isHidden = true
        subnButton.isHidden = true
        sentMailButton.isHidden = true
        sendMailLabel.isHidden = true
    }
    
    @IBAction func urlExpired() {
        contentAreaHeightConstraint.constant = 378
        imageView.image = UIImage(named:"urlExpired")
        mainLabel.text = NSLocalizedString("UrlExpired", comment: "")
        subLabel.text = NSLocalizedString("UrlExpiredExplanation", comment: "")
        notificaiton.text = ""
        mainButton.isHidden = true
        mainButton2.isHidden = false
        mainButton2.setButtonTitle(title: "アカウント作成", fontSize: 12)
        subnButton.isHidden = true
        sentMailButton.isHidden = true
        sendMailLabel.isHidden = true
    }
    
    @IBAction func vefiryCompleted() {
        displayMode = .verified
        contentAreaHeightConstraint.constant = 378
        imageView.image = UIImage(named:"verifyCompleted")
        mainLabel.text = NSLocalizedString("EmailVerified", comment: "")
        subLabel.text = NSLocalizedString("EmailVerifiedExplanation", comment: "")
        notificaiton.text = ""
        mainButton.isHidden = false
        mainButton.setButtonTitle(title: "利用を開始", fontSize: 12)
        mainButton2.isHidden = true
        subnButton.isHidden = true
        sentMailButton.isHidden = true
        sendMailLabel.isHidden = true
    }
    
    @IBAction func waitApprove() {
        
        contentAreaHeightConstraint.constant = 280
        imageView.image = UIImage(named:"no_profile")
        mainLabel.text = NSLocalizedString("WaitApprove", comment: "")
        subLabel.text = NSLocalizedString("WaitApproveExplanation", comment: "")
        notificaiton.text = ""
        mainButton.isHidden = true
        mainButton2.isHidden = true
        subnButton.isHidden = true
        sentMailButton.isHidden = true
    }
    
    @IBAction func requestLogin() {
        
        contentAreaHeightConstraint.constant = 378
        imageView.image = UIImage(named:"no_profile")
        mainLabel.text = NSLocalizedString("", comment: "")
        subLabel.text = NSLocalizedString("LetStartLogin", comment: "")
        notificaiton.text = ""
        mainButton.isHidden = true
        mainButton2.setButtonTitle(title: "新規登録/ログインする", fontSize: 12)
        mainButton2.isHidden = false
        subnButton.isHidden = true
        sentMailButton.isHidden = true
        closeButton.isHidden = false
        
    }
    
    @IBAction func showSignupView(_ sender: Any) {
        
        showSignupView()
    }
    
    @IBAction func showLoginView(_ sender: Any) {
        
        switch displayMode {

        case .codeExpired:      showSignupView()
        case .notConfirmed:     showSignupView()
        case .verified:         showSLoginView()
        case .aleradyConfirmed: showSLoginView()
           
        case .otherError:       showSLoginView()

        default:
            break
        }

    }
 
    @IBAction func resendEmail() {

        // 認証メールを再送
        let userid = KeyChainManager.shared.load(id:.loginId) ?? ""
        OrosyAPI.resend(userId: userid) { completion in
            switch completion {
            case .success(_):
                DispatchQueue.main.async {
                    let dialog =  SmoothDialog()
                    self.view.addSubview(dialog)
                    dialog.show(message: NSLocalizedString("確認メールを送信しました", comment: ""))
                }
            case .failure(_):
                DispatchQueue.main.async {
                    let dialog =  SmoothDialog()
                    self.view.addSubview(dialog)
                    dialog.show(message: NSLocalizedString("確認メールを送信できませんでした。アカウント作成をやり直してください", comment: ""))
                }
                break
            }
        }

    }
            
    func showSignupView() {

        if displayMode == .requestLogin {
            self.dismiss(animated: false)
            let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)

            if let nav = storyboard.instantiateInitialViewController() as? OrosyNavigationController {
                let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                let signupVC = storyboard.instantiateViewController(withIdentifier: "SignupVC") as! SignupVC
                var viewControllers = nav.viewControllers
                viewControllers.append(loginVC)
                viewControllers.append(signupVC)
                nav.viewControllers = viewControllers

                let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
                appDelegate.setRootViewController(viewControllerName: nav)
                
                if let window = appDelegate.window {
                    UIView.transition(with: window,
                                      duration: 0.3,
                                      options: .transitionCrossDissolve,
                                      animations: nil,
                                      completion: nil)
                }
            }
            return 
        }

        /*
        if displayMode == .requestLogin {
            self.dismiss(animated: true)
            
            let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
            let loginvc = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
            let vc = storyboard.instantiateViewController(withIdentifier: "SignupVC") as! SignupVC
            self.orosyNavigationController?.viewControllers = [loginvc]
            self.orosyNavigationController?.pushViewController(vc , animated:true)
            
            return
        }
         */
         
        let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SignupVC") as! SignupVC
        self.orosyNavigationController?.viewControllers.removeLast()
        self.orosyNavigationController?.pushViewController(vc, animated: true)
    }
    
    func showSLoginView() {
        /*
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
            
            let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "SignupVC") as! SignupVC
            self.orosyNavigationController?.viewControllers.removeLast()
            self.orosyNavigationController?.pushViewController(loginVC, animated: true)
            return
        }
         */
        // ID, Passwdをキーチェインから取得
        let userid = KeyChainManager.shared.load(id:.loginId) ?? ""
        let passwd = KeyChainManager.shared.load(id:.password) ?? ""
        
        if userid == "" || passwd == "" {
            let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "SignupVC") as! SignupVC
            self.orosyNavigationController?.viewControllers.removeLast()
            self.orosyNavigationController?.pushViewController(loginVC, animated: true) 

        }else{
            // オートログイン
            let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
            loginVC.login(userid: userid, passwd: passwd)
        }

    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
 
        if let code = textField.text {
            verifyCode(code:code)
        }
        
        return true
    }
    
    func verifyCode(code:String)  -> Bool {
        stopTImer()
        
        let userid = KeyChainManager.shared.load(id:.loginId) ?? ""
        let result = OrosyAPI.confirmSignUp(for: userid, with: code)
        
        switch result {
        case .success:
            displayUpdate(mode:.verified)
            UserDefaultsManager.shared.accountStatus = .AccountVerified
            UserDefaultsManager.shared.updateUserData()
            
            return true
        case .codeExpired:
            displayUpdate(mode:.codeExpired)
        default:
            //　コードが間違っている
            break
        }
        return false
    }
    
    @IBAction func logout() {
        OrosyAPI.signOut() { completion in
            
        }
    }
    @IBOutlet weak var closeButton: UIButton!
    @IBAction func closeView(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
