//
//  Initial.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/05/01.
//

import UIKit


class InitialVC:OrosyUIViewController, UIScrollViewDelegate {

  
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
    @IBOutlet weak var login_button: OrosyButton!
    @IBOutlet weak var signup_button: OrosyButton!
    @IBOutlet weak var startOrosyButton: OrosyButtonGradient!
    @IBOutlet weak var startupView: UIView!
    @IBOutlet weak var startupMessageLabel: OrosyLabel16!
    @IBOutlet weak var splashImage: UIImageView!
    @IBOutlet weak var whiteBackground: UIView!
    
    
    @IBOutlet var contentViews:[UIView]!
    
    let numberOfPages:Int = 4
    override func viewDidLoad() {
        super.viewDidLoad()


        // pageControlのページ数を設定
        pageControl.numberOfPages = numberOfPages
        // pageControlのドットの色
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        // pageControlの現在のページのドットの色
        pageControl.currentPageIndicatorTintColor = UIColor.black
        //  self.view.addSubview(pageControl)
        
        if g_gotInitialData {   //　初期データの読み込みを完了していれば表示する。もし完了していなければ、gotInitialDataイベント待ちにする
            gotInitialData()
        }
        
        
        let enc = NotificationCenter.default
        enc.addObserver(self, selector: #selector(gotInitialData), name: Notification.Name(rawValue:NotificationMessage.GotInitialData.rawValue), object: nil)

    }
    
    @objc func gotInitialData() {
   
        DispatchQueue.main.async {
            var messages:[[String:String]] = []
            if let config = AppConfigData.shared.config {
                messages = config["IntroductionMessage"] as? [[String:String]] ?? []
            }
                                                                                                    
            var ip = 0
            for contentView in self.contentViews {
                if ip == 0 {
                    self.startupMessageLabel.text = "厳選されたブランドの\n仕入れサービス"
                    self.startOrosyButton.setButtonTitle(title: "orosyを始める", fontSize: 14)
                    self.login_button.isHidden = true
     
                }else{
            
                    if let backImage = contentView.viewWithTag(11) as? OrosyUIImageView {
                        backImage.image = UIImage(named: "initial_back" + String(ip))
                       // backImage.layer.cornerRadius = 17
                        self.login_button.isHidden = false
                        backImage.clipsToBounds = true
                    }
                   
                }
                
                if let circleImage = contentView.viewWithTag(12) as? OrosyUIImageView {

                        circleImage.image = UIImage(named: "initial_circle" + String(ip))
                        circleImage.layer.cornerRadius = circleImage.bounds.height / 2
                        circleImage.clipsToBounds = true
                }
                
                if ip == 0 {
                    
                }else{
                    if messages.count > ip - 1 {
                        let msgDic = messages[ip-1]
                        
                        if let mainMsg = contentView.viewWithTag(13) as? OrosyLabel20B {
                            mainMsg.text = msgDic["main"] ?? ""
                        }
                        if let subMsg = contentView.viewWithTag(14) as? OrosyLabel12 {
                            subMsg.text = msgDic["sub"] ?? ""
                        }
                    }
                }
                    
                ip += 1
                
            }
            
            self.login_button.setButtonTitle(title: "ログイン", fontSize: 14)
            
            if ip == 3 {
                self.signup_button.isHidden = false
                self.signup_button.setButtonTitle(title: "アカウント作成", fontSize: 14)
            }else{
                self.signup_button.isHidden = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
                
        let status = UserDefaultsManager.shared.accountStatus
/*
        if !UserDefaultsManager.shared.appInitiated  {
            startupMessageLabel.text = "厳選されたブランドの\n仕入れサービス"
            startOrosyButton.setButtonTitle(title: "orosyを始める", fontSize: 12)
            self.startupView.isHidden = false
            self.startupView.alpha = 1.0
        }else{
            self.startupView.isHidden = true
            self.splashImage.isHidden = true
            self.whiteBackground.isHidden = true
        }
  */
      
        if  status == .AccountNotVerified {
            //　メール認証待ちなら「メール認証待ち」画面へ遷移する
            let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "VerifyEmailVC") as! VerifyEmailVC
            vc.displayMode = .notConfirmed
            self.orosyNavigationController?.pushViewController(vc, animated: true)
           
            return

        }else
        if status == .AccountVerified {
            
            gotoHomePage()
            /*
            // 審査情報入力画面へ
            let storyboard = UIStoryboard(name: "RetailerSB", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "RetailerInfoVC") as! RetailerInfoVC
            self.orosyNavigationController?.viewControllers = [vc]
            return
             */
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
       pageControl.currentPage = Int(scrollView.contentOffset.x / scrollView.frame.size.width)

        
        /*
        if pageControl.currentPage == 2 {
            login_button.setButtonTitle(title: "アカウントを作成せずに始める", fontSize: 12)
        }else{
            login_button.setButtonTitle(title: "ログイン", fontSize: 12)
        }
         */
    }
    func scrollToPage(_ page: Int) {
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentOffset.x = self.scrollView.frame.width * CGFloat(page)
        }
    }
    
    @IBAction func startButtonPushed() {
        g_loginMode = false
        UserDefaultsManager.shared.appInitiated = true
        UserDefaultsManager.shared.updateUserData()
        
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
    
    @IBAction func signupButtonPushed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
        let signupVC = storyboard.instantiateViewController(withIdentifier: "SignupVC") as! SignupVC
        if var viewControllers = self.orosyNavigationController?.viewControllers {
            viewControllers.append(loginVC)
            self.navigationController?.viewControllers = viewControllers
            self.orosyNavigationController?.pushViewController(signupVC, animated: true)
        }
    }
    
    @IBAction func showLoginViewForInitial() {
        DispatchQueue.main.async{
            /*
            if self.pageControl.currentPage == 2 {
                self.startButtonPushed()
                
            }else{
             */
                let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
                let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                loginVC.modalPresentationStyle = .fullScreen
                self.orosyNavigationController?.pushViewController(loginVC, animated: true)
            //}
        }
    }
    @IBAction func closeStartupView(_ sender: Any) {
        scrollToPage(1)
        
        /*
        UIView.animate(withDuration:1.5, // アニメーションの秒数
                            delay: 0.0, // アニメーションが開始するまでの秒数
                           options: [.curveEaseOut], // アニメーションのオプション 等速 | 繰り返し
                           animations: {
            
            self.startupView.alpha = 0
            self.splashImage.alpha = 0
            self.whiteBackground.alpha = 0
            
            
            }, completion: { (finished: Bool) in
                UserDefaultsManager.shared.appInitiated = true
                UserDefaultsManager.shared.updateUserData()
            })
      */
        
    }
    

}

