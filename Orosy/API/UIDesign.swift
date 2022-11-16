//
//  UIDesign.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/11/22.
//
import UIKit
import LinkPresentation
import UserNotifications
import SafariServices
import Kingfisher


// MARK: 色とフォントの定義

enum OrosyColorSets:String {
    case Background = "OrosyBackground"
    case Black600 = "OrosyGray600"                  // 基本テキスト
    case Gray500 = "OrosyGray500"                   // 選択ボタンの枠
    case Gray400 = "OrosyGray400"                   // 未選択アイコン
    case Gray300 = "OrosyGray300"                   // 画像の枠の色
    case Gray200 = "OrosyGray200"                   // カテゴリ検索メニューのセパレータ
    case Gray100 = "OrosyGray100"                   // 下地の色
    case Blue = "OrosyBlue"                         // メインカラー
    case Red = "OrosyRed"                           // 注意
    case R50 = "OrosyR50"
    case S50 = "OrosyS50"                           // カートの配送先、支払い方法で選択されている場合の背景色
    case S400 = "OrosyS400"                         //　オーダステータス
    case S300 = "OrosyS300"
    case S200 = "OrosyS200"
    case S100 = "OrosyS100"

}

enum OrosyFont:String {
    case Regular = "Noto Sans Kannada"
    case Bold = "Noto Sans Kannada Bold"
}

enum OrosyImageSize:String {
    case None = ""
    case Size100 = "?d=100x100"
    case Size200 = "?d=200x200"
    case Size300 = "?d=300x300"
    case Size400 = "?d=400x400"
    case Size500 = "?d=500x500"
    case Size640 = "?d=640x480"
}

extension UIColor {
    
  class func orosyColor(color:OrosyColorSets) -> UIColor {
        
      return  UIColor(named: color.rawValue) ?? UIColor.black
      
  }
}

// MARK: OrosyNavigationController
class OrosyNavigationController:UINavigationController {
    // UserLog用
    var currentUrl:String!          //　現在開いているページのURL
    var referer:String!             //　遷移元のURL
    override func viewDidLoad() {
        self.navigationBar.backgroundColor = .white
        self.navigationBar.tintColor = UIColor.orosyColor(color: .Blue)

    }
    
    func setFirstPageUrl() {
        
        if self.viewControllers.count > 0 {
            if let viewController = self.viewControllers.first {
                self.currentUrl = getNewTargetUrl(viewController)
            }
        }
    }
    
    func pushViewController(_ viewController:OrosyUIViewController, animated: Bool) {
        
        viewController.orosyNavigationController = self
        self.referer = self.currentUrl     // 遷移する前に現在のページURLをrefererにセットしておく
        self.currentUrl = getNewTargetUrl(viewController)  // 遷移先の画面から取得
        
        sendAccessLog()
        
        super.pushViewController(viewController, animated: animated)
        
    }
    
    func getNewTargetUrl(_ viewController:UIViewController) -> String {
        
        var targetUrl:String = ""
        
        switch viewController {
            
        case is HomeVC:
            targetUrl = RETAILER_SITE_URL + "/"
        case is SupplierVC:
            targetUrl = RETAILER_SITE_URL + "/brand/" + (viewController as! SupplierVC).getItemidForPageUrl()
        case is ApplyCoonectionVC:
            targetUrl = RETAILER_SITE_URL + "/brand/" + (viewController as! ApplyCoonectionVC).getItemidForPageUrl() + "/tradeRequest"
        case is ProductDetailVC:
            targetUrl = RETAILER_SITE_URL + "/item/" + (viewController as! ProductDetailVC).getItemidForPageUrl()
        case is SpecialFeatureVC:
            targetUrl = RETAILER_SITE_URL + "/content/" + (viewController as! SpecialFeatureVC).getItemidForPageUrl()
        case is ThreadListVC:
            targetUrl = RETAILER_SITE_URL + "/mesages"
        case is MessageVC:
            targetUrl = RETAILER_SITE_URL + "/mesages/" + (viewController as! MessageVC).getItemidForPageUrl()
        case is FavoriteVC:
            targetUrl = RETAILER_SITE_URL + "/favorite"
        case is CartVC:
            targetUrl = RETAILER_SITE_URL + "/cart"
        case is DeliverySelectVC:
            targetUrl = RETAILER_SITE_URL + "/cart/shippingaddress"
        case is OrderConfirmationVC:
            targetUrl = RETAILER_SITE_URL + "/cart/order"
        case is OrderHistoryVC:
            targetUrl = RETAILER_SITE_URL + "/orders"
        case is OrderDetailVC:
            targetUrl = RETAILER_SITE_URL + "/order/" + (viewController as! OrderDetailVC).getItemidForPageUrl()
        case is AccountVC, is ProfileVC:
            targetUrl = RETAILER_SITE_URL + "/account/profileRegister"
        case is ProfileEditVC:
            targetUrl = RETAILER_SITE_URL + "account/profileRegister"
        case is DeliveryPlaceListVC:
            targetUrl = RETAILER_SITE_URL + "/account/deliveryPlaces"
        case is DeliveryPlaceEditVC:
            targetUrl = RETAILER_SITE_URL + "/account/deliveryPlaces/" + (viewController as! DeliveryPlaceEditVC).getItemidForPageUrl()
        case is LoginVC:
            targetUrl = RETAILER_SITE_URL + "/account/login"
        case is ProfileRequestVC:
            targetUrl = RETAILER_SITE_URL + "/account/profileRequest"
        case is PopupRestrictionVC:
            targetUrl = RETAILER_SITE_URL + "/brand/" + (viewController as! PopupRestrictionVC).getItemidForPageUrl()
        case is ProfileRequestVC:
            targetUrl = RETAILER_SITE_URL + "/profileResuest/"
        case is InitialVC:
            targetUrl = RETAILER_SITE_URL + "/introduction"             // このページはWebには無い
        case is VerifyEmailVC:
            targetUrl = RETAILER_SITE_URL + "/verifyEmail" 
        case is SignupVC:
            targetUrl = RETAILER_SITE_URL + "/account/signup"           //
        case is CompanyProfileVC:
            targetUrl = RETAILER_SITE_URL + "/account/companyRegister"
        case is PaymentInfoVC:
            targetUrl = RETAILER_SITE_URL + "/account/bankRegister"
        case is RefundBankEntryVC:
            targetUrl = RETAILER_SITE_URL + "/account/bankRegister"
        case is EditCreditCardVC:
            targetUrl = RETAILER_SITE_URL + "/account/bankRegister/addCard"
        default:
            targetUrl = "/unknown"
           #if DEBUG
            confirmAlert(title: "", message: "viewControllerのPageUrlが定義されていません", ok:"OK")
            #endif
        }
       
        return targetUrl
    }
    
    // tabSwitch  true:  タブから遷移してきたので、refererをセットしない
    func sendAccessLog(tabSwitch:Bool = false) {
        if let userLog = g_userLog {
            _ = userLog.sendAccessLog(pageUrl:currentUrl, referer: (tabSwitch) ? nil : referer)
        }
    }
    
    // ModalVIewを開く前にコールする。　　そのため、refererは現状のurlをセットしている
    func sendAccessLog(modal:Bool = false, targetUrl:String) {
       _ = g_userLog.sendAccessLog(pageUrl:targetUrl, referer: currentUrl)
        if !modal {
            self.referer = self.currentUrl
            self.currentUrl = targetUrl
        }
    }
    
    //　指定されたビューへジャンプする（通常は、トップへ戻る時に使用する）
    func sendAccessLogForPopToTop(viewController:OrosyUIViewController) {
        self.referer = self.currentUrl
        self.currentUrl =  getNewTargetUrl(viewController)
        _ = g_userLog.sendAccessLog(pageUrl: self.currentUrl, referer: self.referer)
    }
    
    func sendBlogAccessLog(blogId:String) {
        _ = g_userLog.sendAccessLog(pageUrl: BLOG_RETAILER_BASE_URL + blogId, referer: self.referer)
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        
        self.referer = self.currentUrl
        let count = self.viewControllers.count
        if count > 1 {
            let viewController = self.viewControllers[count - 2]
            self.currentUrl = getNewTargetUrl(viewController)
            sendAccessLog()
        }
        return super.popViewController(animated: animated)
    }
    
}


// MARK: OrosyUIViewController
let navigationNormalHeight: CGFloat = 44
let navigationExtendHeight: CGFloat = 84

class OrosyUIViewController:UIViewController, SFSafariViewControllerDelegate {
    
    enum ItemType {
        case TITLE
        case HEADER
        case LOGO
        case BRAND_NAME
        case BUSINESS_FORMAT       // 個人事業主化法人化？
        case BUSINESS_TYPE
        case CATEGORY_MAIN
        case CATEGORY_SUB
        case START_YEAR
        case NUMBER_OF_SHOPS
        case ANUAL_REVENUE
        case WEBSITE
        case ECSITE_URL
        case SHOP_PHOTO
        case CONCEPT
        case TARGET_USER
        case REVENUE_PER_CUSTOMER
        case HOME_URL
        case INSTAGRAM
        case TWITTER
        case FACEBOOK
        case ADD_URL
        case OTHER_URL
        case FOOTER
        
        case COMPANY_NAME
        case POLSTAL_CODE
        case PREFECTURE
        case CITY
        case TOWN
        case FIRMNAME
        case COMPANY_TEL
        case FIRST_NAME
        case LAST_NAME
        case TEL
        case ANNUAL_REVENUE
        
        case DeliveryPlaeName

        case PersonName
        case Memo
        
        case CARD_NUMBER
        case EXPIRE_DATE
        case SECURITY_CODE
        case CARD_OWNER
        case LIMIT_AMOUNT

        case METHOD90_TITLE     // 支払い方法のタイトル
        case EXPLANATION90      // 説明文
        case PAY_INFO90         // 残枠
        case METHOD_TITLE       // 支払い方法のタイトル
        case EXPLANATION        // 説明文
        case PAY_INFO           // 残枠
        case PAY_BUTTON         // クレカ登録ボタン
        case CARD_INFO          // 登録カード情報
        case POINT_HISTORY      // ポイント利用履歴
        case REFUND_INFO
        //
        case BANK_NAME
        case BANK_CODE
        case BRANCH_NAME
        case BRANCH_CODE
        case ACCOUNT_TYPE
        case ACCOUNT_NUMBER
        case ACCOUNT_NAME
  
        case SALE_TYPE
        case ECSITE_NAME
        case CATEGORY
        
        case SECTION_HEADER
    }
    
    
    var tabInitialized = false          // 始めたタブ切り替えたら　trueになる。　　falseの時だけ accessLogを残すようにするためのフラグ
    var noDataAlert:EmptyAlertVC!
    var noDataAlertTopGap:CGFloat = 100
    var orosyNavigationController: OrosyNavigationController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"backButton"), style:.plain, target: self, action: #selector(closeView))

        self.orosyNavigationController = self.navigationController as? OrosyNavigationController

        
        let storyboard = UIStoryboard(name: "AlertSB", bundle: nil)
        noDataAlert = storyboard.instantiateViewController(withIdentifier: "EmptyAlertVC") as? EmptyAlertVC
        var frame = noDataAlert.view.frame
        frame.origin.y = noDataAlertTopGap
        noDataAlert.view.frame = frame
        noDataAlert.isHidden = true
        
        self.view.addSubview(noDataAlert.view)
    
    }
    

    
    @objc func closeView() {
        _ = self.orosyNavigationController?.popViewController(animated: true)
    }
    
    // ViewController起動時には必ずネットワークチェックを実施する
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !Network.shared.isOnline() {
            showNetworkAlert()
            return
        }

        g_currentViewController = self
        

    }

    @objc func checkAuth() {
        if !g_loginMode { return }
        /*
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
        if !g_loginMode { return }
        */
        if !g_authChecked {  // バックグランドから戻った時に一度だけチェックする
            // インストール直後以外では、セッションが切れている場合だけログイン画面を表示する。
            let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC

            DispatchQueue.global().async {
                if loginVC.loginCheck() {      // Loginできていると　enteredIntoForeground　が呼ばれて、データ取得処理が開始される
                    // 認証OK
                    if let userId = g_MyId {
                        g_loginMode = true
                        g_userLog = UserLog(userId:userId)
                        let ver = UserDefaultsManager.shared.appVersion ?? ""
                        if ver == ""  {
                            // インストール直後なので無視
                        }else{
                            if ver != Util.getAppVersion() {
                                g_userLog.updateed()            //アプリがバージョンアップされた
                                UserDefaultsManager.shared.updateUserData()    // バージョン情報を更新
                            }
                        }
                    }

                }else{
                    // 認証NG
                    self.showLoginView()
                }
                g_authChecked = true
            }
        }

    }
    
    // アプリ内のログインページ
    @IBAction func showLoginView() {
        DispatchQueue.main.async{

            let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
            loginVC.modalPresentationStyle = .fullScreen
            self.present(loginVC, animated: true, completion: nil)
            self.orosyNavigationController?.viewControllers = [loginVC]
        }
    }
    

    
    // Webサイトのログインページ
    @IBAction func showLoginPage(_ sender: Any) {
        let url = URL(string: ROOT_URL)
        if let url = url {
            let safariViewController = SFSafariViewController(url: url)
            safariViewController.delegate = self
            present(safariViewController, animated: false, completion: nil)
        }
    }
    
    func safariViewControllerDidFinish(_ controller:SFSafariViewController) {
        print("safari closed")
    }
    
    func showCheckProfileVC() {
        // プロフィールの入力を促す
        let storyboard = UIStoryboard(name: "AlertSB", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ProfileRequestVC") as! ProfileRequestVC
        
        // アニメーションを準備
        let transition1 = CATransition()
        transition1.duration = 0.4;
        transition1.timingFunction = CAMediaTimingFunction(name: .easeIn)
        transition1.type = .moveIn          //  現在表示されている画面に、新しい画面がスライドして入るスタイルです。
        transition1.subtype = .fromTop
        self.orosyNavigationController?.view.layer.add(transition1, forKey: "ModalAnimation")
        
        self.orosyNavigationController?.pushViewController(vc, animated: false)     // 別にアニメーションさせるので、ここでは　falseにしておく
    }
    
    // アカウント画面表示
   @IBAction func showAccount() {

        if g_loginMode {
            let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "AccountVC") as! AccountVC
            
            self.orosyNavigationController?.pushViewController(vc, animated: true)
        }else{
            let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "VerifyEmailVC") as! VerifyEmailVC
            vc.displayMode = .requestLogin
          //  let nav = UINavigationController(rootViewController: vc)
          //  nav.modalPresentationStyle = .fullScreen
          //  nav.navigationBar.isHidden = true
            
            present(vc, animated: true, completion: nil)
        }
    }

    class DisplayItem: NSObject {
        var itemType:ItemType
        var isEdited:Bool = false
        var inputStr:String? {
            didSet {
                isEdited = true
            }
        }
        var title:String?
        var placeholder:String?
        var cellType:String?
        var itemObject: NSObject?
        var itemHeight:CGFloat
        var fixed:Bool = false  // フォーカスを当てない行
        var validationType:ValidationType!
        var edited:Bool = false
        var error:Bool = false
        var errorMsg:String?
        var helpButtonEnable:Bool = false
        var indexPath:IndexPath?
        var nextIndexPath:IndexPath?
        var focus:Bool = false      // 最初にフォーカスを当てる行
        
        init( type:ItemType, title:String?, cell:String?, placeholder:String? = nil, height:CGFloat = 0, validationType:ValidationType = .None ,inputStr:String? = nil , fixed:Bool = false, errorMsg:String? = nil,nextIndexPath:IndexPath? = nil, focus:Bool = false, helpButtonEnable:Bool = false) {
            
            self.itemType = type
            self.title = title
            self.placeholder = placeholder
            self.cellType = cell
            self.itemHeight = height
            self.placeholder = placeholder
            self.validationType = validationType
            self.inputStr = inputStr
            self.edited = false
            self.errorMsg = errorMsg
            self.helpButtonEnable = helpButtonEnable
            self.nextIndexPath = nextIndexPath
            self.focus = focus
            self.fixed = fixed
        }
    }
    
    enum ValidationType {
        case NormalString
        case IntNumber
        case IntNumber4
        case IntNumber3
        case IntNumberAllowBlank
        case PhoneNumber
        case PostalCode
        case URL
        case ExpirationDate
        case None
        
    }

    class Validation:NSObject {
        // 入力データのエラーチェック
        // validationに成功した場合は、validation結果を返す
        class func normalize(type:ValidationType, inStr:String?) -> (Bool, String?) {       // true: success
            
            guard let inputText = inStr else { return (false, nil) }
            
            switch type  {
            case .NormalString:
                return (inputText.count > 0 ) ? (true, inputText) : (false, nil)
                
            case .IntNumber, .IntNumberAllowBlank, .IntNumber3, .IntNumber4:
                var valid = inputText.isOnlyNumeric()
                if type == .IntNumberAllowBlank && inputText.count == 0 { valid = true }
                if type == .IntNumber3 && inputText.count == 3 { valid = true }
                if type == .IntNumber4 && inputText.count == 4 { valid = true }
                return (valid) ? (true, inputText) : (false, inputText)
  
            case .PostalCode:    // ハイフン有りに統一する

                var text = inputText.replacingOccurrences(of: "-", with: "")
                if text.count == 7 && text.isOnlyNumeric() {  // ハイフン無しで、7桁,数字のみ
                    text = text.prefix(3) + "-" + text.suffix(4)
                    return (true,text)
                }else{
                    return (false, inStr)
                }

            case .PhoneNumber:  // ハイフンなしに統一する
     
                let cleansedString = inputText.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")

                let length = cleansedString.count
                
                var numberErr = false
                if !cleansedString.hasPrefix("0") {
                    numberErr = true
                }
                if cleansedString.hasPrefix("050") || cleansedString.hasPrefix("060") || cleansedString.hasPrefix("070") || cleansedString.hasPrefix("080") || cleansedString.hasPrefix("090")  {
                    if length != 11 {
                        numberErr = true
                    }
                }else{
                    if length != 10 {
                        numberErr = true
                    }
                }
                if numberErr {
                    // 電話番号が不正
                    return (false, inStr)
                }else{
                    return (true, cleansedString)

                }
                
            case .URL:

                let urlStr = inputText.lowercased()
                if !urlStr.contains("https://")  { return (false, urlStr) }
                    
                guard let url = URL(string: urlStr) else { return (false, urlStr) }

                if UIApplication.shared.canOpenURL(url) {
                    return  (true, urlStr)
                }else{
                    return (false, urlStr)
                }
            
            case .ExpirationDate:
                if !inputText.contains("/") { return (false, inStr) }
                if inputText.count != 7 { return (false, inStr) }
                return (true, inStr)
                
            case .None:
                return (true, inStr)
            }
        }
    }
}


extension UIViewController {
    
    // logo: true 　titleで指定されたファイル名の画像を表示、 false: titleで指定された文字列を表示
    
    // 何故か、他のビューへ宣して戻ってくるとロゴの位置が下にずれるという問題があり、それを回避するため、ロゴのビューは再生性しないようにした（それでも少ししたにずれている・・）
    
    func setNaviTitle(title:String?, logo:Bool? = false) {
        guard let _title = title else { return }
        guard let navi = self.navigationController else{ return }
        
        if self.navigationItem.titleView == nil {
            guard let _title = title else { return }
            guard let navi = self.navigationController else{ return }
            
            var dframe = self.navigationController?.navigationBar.frame
            dframe?.size.height = 50
            self.navigationController?.navigationBar.frame = dframe!
            
            print(self.navigationController?.navigationBar.bounds)
            
            let navbarTitle = PaddingLabel(withInsets: 5, 0, 0, 0)
            navbarTitle.text = _title
            navbarTitle.numberOfLines = 2
            navbarTitle.textColor = UIColor.orosyColor(color: .Blue)
            navbarTitle.font = UIFont(name: OrosyFont.Bold.rawValue, size: 16)
            navbarTitle.frame = CGRect(x:0, y:0, width:self.view.bounds.width - 100, height:40)  // 幅をフルに指定すると、navigationbar Itemを追加したときに、正しくセンタリングされない
            navbarTitle.textAlignment = .center
            navbarTitle.isUserInteractionEnabled = true
            navbarTitle.tag = 1
            let button = UIButton(type: UIButton.ButtonType.custom)
            button.frame = navbarTitle.frame
            button.addTarget(self, action: #selector(titlePushed) , for:.touchUpInside)
            
            navbarTitle.addSubview(button)
            
            //
            if logo! {
                navbarTitle.text = "   "
              

                let image = UIImage(named: "orosy_logo")!
                let width = 14 / image.size.height * image.size.width
                let x = (self.view.bounds.width - width - 113) / 2.0
                
                let imageView = UIImageView(frame:CGRect(x:x, y:14, width:width, height:14))
                imageView.backgroundColor = .clear
                imageView.contentMode = .scaleAspectFit
                //imageView.translatesAutoresizingMaskIntoConstraints = false   // これがあると、画像サイズがimageViewのサイズに合わない
                imageView.clipsToBounds = true
                imageView.image = image  //.withAlignmentRectInsets(UIEdgeInsets(top:-10, left: -x, bottom: 0, right: 0))
                //imageView.sizeToFit()
                imageView.tag = 2
                navbarTitle.addSubview(imageView)
                
             //   imageView.centerXAnchor.constraint(equalTo: navbarTitle.centerXAnchor).isActive = true// これがあるとずれる
                
            }
            
            self.navigationItem.titleView = navbarTitle
            
        }else{
            
            let textView = self.navigationItem.titleView?.viewWithTag(1) as! PaddingLabel
            let imgView = self.navigationItem.titleView?.viewWithTag(2)
            
            if logo! {
                imgView?.isHidden = false
                textView.text = "   "   //　このスペースを消してはいけない
            }else{
                imgView?.isHidden = true
                textView.text = _title
            }
        }

 
        
        navi.setNavigationBarHidden(false, animated: false)
        self.navigationItem.backButtonDisplayMode = .minimal    // 戻るボタンのテキストだけを非表示にする。この設定は、次に遷移した画面で有効となる
        
        // なぜか、ホームタブだけステータスばーが消えたので、以下のコードを追加
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.barTintColor = UIColor.orosyColor(color: .Blue)
        
    }

    @objc func titlePushed() {
        
        // タイトルボタンを押した時の処理は、 この関数をoverrideして実装する
    }
    

    private final class StatusBarView: UIView { }

    func setStatusBarBackgroundColor(_ color: UIColor?) {
        for subView in self.view.subviews where subView is StatusBarView {
            subView.removeFromSuperview()
        }
        guard let color = color else {
            return
        }
        let statusBarView = StatusBarView()
        statusBarView.backgroundColor = color
        self.view.addSubview(statusBarView)
        statusBarView.translatesAutoresizingMaskIntoConstraints = false
        statusBarView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        statusBarView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        statusBarView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        statusBarView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
    }

 
    class PaddingLabel: UILabel {
        
        var topInset: CGFloat
        var bottomInset: CGFloat
        var leftInset: CGFloat
        var rightInset: CGFloat
        
        required init(withInsets top: CGFloat, _ bottom: CGFloat, _ left: CGFloat, _ right: CGFloat) {
            self.topInset = top
            self.bottomInset = bottom
            self.leftInset = left
            self.rightInset = right
            super.init(frame: CGRect.zero)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func drawText(in rect: CGRect) {
            let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
            super.drawText(in: rect.inset(by: insets))
        }
        
        override var intrinsicContentSize: CGSize {
            get {
                var contentSize = super.intrinsicContentSize
                contentSize.height += topInset + bottomInset
                contentSize.width += leftInset + rightInset
                return contentSize
            }
        }
        
    }


    // MARK: アラート表示
    // 1択用　ラート表示
    
    func confirmAlert( title:String, message:String, ok:String = "OK")  {
        
        DispatchQueue.main.async {
            let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle:  UIAlertController.Style.alert)
            alert.view.tintColor = UIColor(named: "OrosyBlue")
            
            let defaultAction: UIAlertAction = UIAlertAction(title: ok, style: UIAlertAction.Style.default, handler:{
                // ボタンが押された時の処理を書く（クロージャ実装）
                (action: UIAlertAction!) -> Void in
            })
            
            alert.addAction(defaultAction)
            alert.showOnTop()
  
        }
    }
 
    func confirmAlert( title:String, message:String, ok:String ,completion: @escaping ( Bool ) -> Void) {
        
        DispatchQueue.main.async {
            let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle:  UIAlertController.Style.alert)
            alert.view.tintColor = UIColor(named: "OrosyBlue")
            
            let defaultAction: UIAlertAction = UIAlertAction(title: ok, style: UIAlertAction.Style.default, handler:{
                // ボタンが押された時の処理を書く（クロージャ実装）
                (action: UIAlertAction!) -> Void in
                completion(true)
            })
            
            alert.addAction(defaultAction)
            alert.showOnTop()
        }
    }
    
    // 2択用　アラート表示
    func selectAlert( title:String, message:String, ok:String, cancel:String, completion: @escaping ( Bool ) -> Void) {
        
        DispatchQueue.main.async {
            let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle:  UIAlertController.Style.alert)
            alert.view.tintColor = UIColor(named: "OrosyBlue")
            
            let defaultAction: UIAlertAction = UIAlertAction(title: ok, style: UIAlertAction.Style.default, handler:{
                // ボタンが押された時の処理を書く（クロージャ実装）
                (action: UIAlertAction!) -> Void in
                
                completion(true)
            })
            alert.addAction(defaultAction)
            //
            let cancelAction: UIAlertAction = UIAlertAction(title: cancel, style: UIAlertAction.Style.cancel, handler:{
                // ボタンが押された時の処理を書く（クロージャ実装）
                (action: UIAlertAction!) -> Void in
                
                completion(false)
            })
            alert.addAction(cancelAction)
            alert.showOnTop()
 
        }
    }
    
    // 待ち状態表示用
    func showBlackCoverView(show:Bool) {
        
        DispatchQueue.main.async {
            if show {
                let frame = self.view.frame
                let coverView = UIView(frame: frame)
                coverView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                coverView.tag = 99999
                self.view.addSubview(coverView)
                
                let waitIndicator = UIActivityIndicatorView(frame: CGRect(x:0, y:0, width:30, height:30))
                waitIndicator.style = .large
                waitIndicator.tintColor = .white
                waitIndicator.center = coverView.center
                waitIndicator.isHidden = false
                waitIndicator.tag = 99998
                self.view.addSubview(waitIndicator)
                waitIndicator.startAnimating()
                
            }else{
                
                let view = self.view.viewWithTag(99999)
                view?.removeFromSuperview()
                let waitIndicator = self.view.viewWithTag(99998)
                waitIndicator?.removeFromSuperview()
                
            }
        }
    }
    
    func showNetworkAlert() {
        DispatchQueue.main.async {
            let alert: UIAlertController = UIAlertController(title: "ネットワークに接続できないためサービスをご利用頂けません", message: "ネットワークに接続されていることを確認してください", preferredStyle:  UIAlertController.Style.alert)
            alert.view.tintColor = UIColor.orosyColor(color: .Gray400)
            
            let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
                    (action: UIAlertAction!) -> Void in
                    
                self.dismiss(animated: true, completion: nil)
                    
            })
            alert.addAction(defaultAction)
                
            self.present(alert, animated: true, completion: nil)
        }
    }

}

// show alert always on current top view
public extension UIAlertController {
    func showOnTop() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        var topController: UIViewController = appDelegate.window!.rootViewController!
        while (topController.presentedViewController != nil) {
            topController = topController.presentedViewController!
        }

        topController.present(self, animated: true, completion: nil)
    }
    
}

extension UIBarButtonItem {
    convenience init(image :UIImage, title :String, target: Any?, action: Selector?) {
        let button = UIButton(type: .custom)
        button.setImage(image, for: .normal)
        button.setTitleColor(.orosyColor(color: .Gray400), for: .normal)
        button.setTitleAttribute(title: title, fontSize: 10)
        
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 35)

        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 25, bottom: 15, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        
        if let target = target, let action = action {
            button.addTarget(target, action: action, for: .touchUpInside)
        }

        self.init(customView: button)
    }
    
}

// MARK: ==========================
// MARK: タブバー

extension UITabBarController {
    
    func setTabbarAppearance() {
        let appearance = UITabBarAppearance()
        setTabBarItemColors(appearance.stackedLayoutAppearance)     // TabBarの色はここでセット
        appearance.backgroundColor = .white
        tabBar.standardAppearance = appearance
        tabBar.backgroundColor = .white
               
    }


    private func setTabBarItemColors(_ itemAppearance: UITabBarItemAppearance) {
        let offColor = UIColor.orosyColor(color: .Gray400)
        let onColor = UIColor.orosyColor(color: .Blue)
        
        itemAppearance.normal.iconColor = offColor
        itemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: offColor]
        
        itemAppearance.selected.iconColor = onColor
        itemAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: onColor]

    }
}
// MARK: ==========================
// MARK: 検索バー
extension UISearchBar {

    func uiSetup() {
        self.backgroundImage = UIImage()    // 上下のラインを消す
        self.searchTextField.backgroundColor = UIColor.white
        self.searchTextField.layer.borderColor = UIColor.orosyColor(color: .Gray300).cgColor
        self.searchTextField.layer.cornerRadius = 5
        self.searchTextField.layer.borderWidth = 1
        UIView.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.orosyColor(color: .Gray400)
    }
}
// MARK: ==========================
// MARK: UILabel

class OrosyLabel:UILabel {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setFont()
    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        setFont()
    }
    private func setFont() {
        self.font = UIFont(name: OrosyFont.Regular.rawValue, size: 14)
    }
    
    func drawBorder(cornerRadius:CGFloat) {
            
        if cornerRadius > 0 {
            // 角丸
            self.layer.cornerRadius = cornerRadius
            self.clipsToBounds = true
        }
    }

}

class OrosyLabel20B:OrosyLabel {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setFont()
    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        setFont()
    }
    
    private func setFont() {
        self.font = UIFont(name: OrosyFont.Bold.rawValue, size: 20)
    }
}

class OrosyLabel20:OrosyLabel {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setFont()
    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        setFont()
    }
    
    private func setFont() {
        self.font = UIFont(name: OrosyFont.Regular.rawValue, size: 20)
    }
}

class OrosyLabel16B:OrosyLabel {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setFont()
    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        setFont()
    }
    
    private func setFont() {
        self.font = UIFont(name: OrosyFont.Bold.rawValue, size: 16)
    }
    
}

class OrosyLabel16:OrosyLabel {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setFont()
    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        setFont()
    }
    
    private func setFont() {
        self.font = UIFont(name: OrosyFont.Regular.rawValue, size: 16)
    }
    
}

class OrosyLabel14:OrosyLabel {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setFont()
    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        setFont()
    }
    
    private func setFont() {
        self.font = UIFont(name: OrosyFont.Regular.rawValue, size: 14)
    }
}

class OrosyLabel14B:OrosyLabel {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setFont()
    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        setFont()
    }
    
    private func setFont() {
        self.font = UIFont(name: OrosyFont.Bold.rawValue, size: 14)
    }
}

class OrosyLabel12:OrosyLabel {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setFont()
    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        setFont()
    }
    
    private func setFont() {
        self.font = UIFont(name: OrosyFont.Regular.rawValue, size: 12)
    }
}

class OrosyLabel12B:OrosyLabel {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setFont()
    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        setFont()
    }
    
    private func setFont() {
        self.font = UIFont(name: OrosyFont.Bold.rawValue, size: 12)
    }
}

class OrosyLabel10:OrosyLabel {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setFont()
    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        setFont()
    }

    private func setFont() {
        self.font = UIFont(name: OrosyFont.Regular.rawValue, size: 10)
    }
}

class OrosyLabel10B:OrosyLabel {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setFont()
    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        setFont()
    }

    private func setFont() {
        self.font = UIFont(name: OrosyFont.Bold.rawValue, size: 10)
    }
}

// MARK: ==========================
// MARK: UITextField
@IBDesignable class OrosyTextField:UITextField {

    var indexPath:IndexPath?
    var underLineView:UIImageView?
  
    var underlineColor:UIColor = .clear {
        didSet {
            if let line = underLineView {
                line.backgroundColor = underlineColor
            }
        }
    }
    var error:Bool = false {
        didSet {
            let color = (error) ? errorLineColor : normalLinelColor
            self.textColor = color
            self.setLineColor(color)
        }
    }
    @IBInspectable var underline: Bool = false {
        didSet {
            if underline {
                underLineView!.backgroundColor = normalLinelColor
            }else{
                underLineView!.backgroundColor = .clear
            }
        }
    }
    @IBInspectable var topPadding: CGFloat = 10
    @IBInspectable var bottomPadding: CGFloat = 10
    @IBInspectable var leftPadding: CGFloat = 10
    @IBInspectable var rightPadding: CGFloat = 10
    @IBInspectable var fontSize: CGFloat = 14
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        drawUnderLine(.zero)
        keyboardInit()
    }

    override init(frame:CGRect) {
        super.init(frame:frame)
        drawUnderLine(frame)
        keyboardInit()
    }
    
    
    override func draw(_ rect: CGRect) {
        
        drawUnderLine(rect)
    }
    
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
         return bounds.inset(by: UIEdgeInsets.init(top: topPadding, left: leftPadding, bottom: bottomPadding, right: rightPadding))
     }

     override open func editingRect(forBounds bounds: CGRect) -> CGRect {
         return bounds.inset(by: UIEdgeInsets.init(top: topPadding, left: leftPadding, bottom: bottomPadding, right: rightPadding))
     }
    
    func drawUnderLine(_ rect: CGRect) {
        self.font = UIFont(name: OrosyFont.Regular.rawValue, size: fontSize)
        self.clipsToBounds = true
        
        let size = rect.size
        let frame = CGRect(x:0, y: size.height - 1, width: size.width, height:1 )
        
        if let lineView = underLineView{
            lineView.frame = frame
            
        }else{
            underLineView = UIImageView(frame: frame)
            underLineView?.backgroundColor = underlineColor
            self.addSubview(underLineView!)
        }

    }

    func setLineColor(_ color: UIColor) {
    
        if underline {
            underLineView!.backgroundColor = color
        }
    }
    
    private func keyboardInit(){
        let tools = UIToolbar()
        tools.frame = CGRect(x: 0, y: 0, width: frame.width, height: 40)
        tools.backgroundColor = UIColor.clear
        tools.tintColor = UIColor.clear
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        

        let closeButton = UIBarButtonItem(image: UIImage(named: "expand_more"), style: .plain, target: self, action: #selector(self.closeButtonTapped))
        closeButton.tintColor = UIColor.orosyColor(color: .Gray500)
        tools.items = [spacer, closeButton]
        self.inputAccessoryView = tools
    }

    @objc func closeButtonTapped(){
        self.endEditing(true)
        self.resignFirstResponder()
    }
}

let errorLineColor = UIColor.orosyColor(color: .Red)
let normalLinelColor = UIColor.orosyColor(color: .S400)

// ラベル付きのテキスト入力フィールド    高さは68固定
@objc protocol OrosyTextFieldLabelDelegate: AnyObject {
    func orosyTextFieldDidBeginEditing(_ _orosyTextFieldLabel: OrosyTextFieldLabel)
    func orosyTextFieldDidChangeSelection(_ _orosyTextFieldLabel: OrosyTextFieldLabel)
    func orosyTextFieldButton(_ button:IndexedButton)
    func orosyTextFieldShouldReturn(_ _orosyTextFieldLabel: OrosyTextFieldLabel) -> Bool
}

@IBDesignable class OrosyTextFieldLabel:UIView, UITextFieldDelegate {
    @IBOutlet var delegate: OrosyTextFieldLabelDelegate?
    
    @IBInspectable var underline: Bool = false {
        didSet {
            textField?.underline = self.underline
        }
    }
    @IBInspectable var withTitle: Bool = true
    
    var titleLabel:OrosyLabel12?
    var textField:OrosyTextField?
    var helpButton:IndexedButton?
    var errorLabel:OrosyLabel12?
    var focus:Bool = false {
        didSet {
            textField?.backgroundColor = (focus) ? UIColor.orosyColor(color: .S50) : UIColor.orosyColor(color: .Gray100)
        }
    }
    
    var text:String {
        set {
            textField?.text = newValue
        }
        get {
            return textField?.text ?? ""
        }
    }
    
    var title:String = "" {
        didSet {
            titleLabel?.text = title
            titleLabel?.sizeToFit()
        }
    }
    
    var errorText:String = "" {
        didSet {
            errorLabel?.text = errorText
        }
    }
    var errorHidden:Bool = true{
        didSet {
           errorLabel?.isHidden = errorHidden
        }
    }
    var helpButtonEnable:Bool = true {
        didSet {
            helpButton?.isHidden = !helpButtonEnable
        }
    }
    var indexPath:IndexPath? {
        didSet {
            textField?.indexPath = indexPath
        }
    }
    var error:Bool = false {
        didSet {
            let color = (error) ? errorLineColor : normalLinelColor
            //titleLabel.textColor = color
            textField!.textColor = color
            textField!.setLineColor(color)
            errorHidden = !error
        }
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        setLabel(.zero)
    }

    override init(frame:CGRect) {
        super.init(frame:frame)
        setLabel(frame)
    }
    
    override func draw(_ rect: CGRect) {
        
        setLabel(rect)
    }
    
    func setLabel(_ rect: CGRect) {
        
        let size = rect.size
        
        if withTitle {
            let frame = CGRect(x:0, y: 4, width: size.width, height:20 )
            if titleLabel == nil {
                titleLabel = OrosyLabel12(frame: frame)
                titleLabel!.textColor = normalLinelColor
                self.addSubview(titleLabel!)
            }else{
                titleLabel?.frame = frame
            }
        }
        if errorLabel == nil {
            errorLabel = OrosyLabel12(frame: .zero)
            errorLabel!.textColor = UIColor.orosyColor(color: .Red)
            errorLabel!.isHidden = true
            self.addSubview(errorLabel!)
            errorLabel!.translatesAutoresizingMaskIntoConstraints = false
        }

            
        let buttonHeight:CGFloat = 20
        if helpButton == nil {
            helpButton = IndexedButton(frame:.zero )
            if let hbutton = helpButton {
                hbutton.setImage(UIImage(named:"help")  , for: .normal)
                hbutton.addTarget(self, action: #selector(textFieldButton), for: .touchUpInside)
                hbutton.isHidden = true
                self.addSubview(hbutton)
                hbutton.translatesAutoresizingMaskIntoConstraints = false
            }
        }
        
        let frame = CGRect(x:0, y: 28, width: size.width, height:40 )
        if textField == nil {
            textField = OrosyTextField(frame: frame)
            if let tfield = textField {
                tfield.delegate = self
                tfield.textColor = normalLinelColor
                tfield.underline = self.underline
                tfield.backgroundColor = UIColor.orosyColor(color: .Gray100)
                tfield.fontSize = 16
                tfield.topPadding = 4
                tfield.bottomPadding = 0
                self.addSubview(tfield)
            }
        }else{
            textField?.frame = frame
        }
        
        let constraints = [
            errorLabel!.leadingAnchor.constraint(equalTo: self.titleLabel!.trailingAnchor, constant:10),
            errorLabel!.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 3),
            errorLabel!.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant:20),
            errorLabel!.heightAnchor.constraint(equalToConstant:21),
            
            helpButton!.leadingAnchor.constraint(equalTo: self.titleLabel!.trailingAnchor, constant:10),
            helpButton!.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0),
            helpButton!.heightAnchor.constraint(equalToConstant:buttonHeight),
            helpButton!.widthAnchor.constraint(equalToConstant: buttonHeight)
        ]
        
        NSLayoutConstraint.activate(constraints)
  
    }
    
    @objc func textFieldButton() {
        delegate?.orosyTextFieldButton(helpButton!)
    }
    
    func textFieldDidBeginEditing(_ _textField: UITextField) {
        if let delg = self.delegate {
            delg.orosyTextFieldDidBeginEditing(self)
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let delg = self.delegate {
            return delg.orosyTextFieldShouldReturn(self)
        }
        return false
    }
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let delg = self.delegate {
            delg.orosyTextFieldDidChangeSelection(self)
        }
    }
}

// MARK: UITextView
@IBDesignable class OrosyTextView:UITextView {
    var indexPath:IndexPath? = nil
    var placeLabel:UITextView?
    var placeholder:String? {
        didSet {
            placeLabel?.text = placeholder
        }
    }

    
    @IBInspectable var topPadding: CGFloat = 10
    @IBInspectable var bottomPadding: CGFloat = 10
    @IBInspectable var leftPadding: CGFloat = 10
    @IBInspectable var rightPadding: CGFloat = 10
    @IBInspectable var fontSize: CGFloat = 16

    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.font = UIFont(name: OrosyFont.Regular.rawValue, size: fontSize)
        keyboardInit()
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        keyboardInit()
    }

    /*
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
         return bounds.inset(by: UIEdgeInsets.init(top: topPadding, left: leftPadding, bottom: bottomPadding, right: rightPadding))
     }

     override open func editingRect(forBounds bounds: CGRect) -> CGRect {
         return bounds.inset(by: UIEdgeInsets.init(top: topPadding, left: leftPadding, bottom: bottomPadding, right: rightPadding))
     }
    */
    override func draw(_ rect: CGRect) {
        
        self.font = UIFont(name: OrosyFont.Regular.rawValue, size: fontSize)
        
        let size = rect.size
        let frame = CGRect(x:0, y:0, width: size.width - 20, height: size.height - 1 )
        
        if placeLabel == nil {
            placeLabel = UITextView(frame: frame)
            placeLabel!.isUserInteractionEnabled = false
            placeLabel!.textContainer.lineBreakMode = .byTruncatingTail
            placeLabel!.font = self.font
            placeLabel!.textColor = UIColor.orosyColor(color: .Gray400)
            placeLabel!.backgroundColor = .clear
            placeLabel!.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(placeLabel!)
            placeLabel?.text = placeholder
        }else{
            placeLabel?.frame = frame
        }

    }
    private func keyboardInit(){
        let tools = UIToolbar()
        tools.frame = CGRect(x: 0, y: 0, width: frame.width, height: 40)
        tools.backgroundColor = UIColor.clear
        tools.tintColor = UIColor.clear
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        

        let closeButton = UIBarButtonItem(image: UIImage(named: "expand_more"), style: .plain, target: self, action: #selector(self.closeButtonTapped))
        closeButton.tintColor = UIColor.orosyColor(color: .Gray500)
        tools.items = [spacer, closeButton]
        self.inputAccessoryView = tools
    }

    @objc func closeButtonTapped(){
        self.endEditing(true)
        self.resignFirstResponder()
    }
    
    @objc private func textDidChanged() {
        placeLabel?.isHidden = true
    }
    
    /*
    func underlineColor(_ color:UIColor) {
        if let line = underLineView {
            line.backgroundColor = color
        }
    }
    */

}

@objc protocol OrosyTextViewLabelDelegate: AnyObject {
    func orosyTextViewDidBeginEditing(_ _orosyTextViewLabel: OrosyTextViewLabel)
    func orosyTextViewDidChangeSelection(_ _orosyTextViewLabel: OrosyTextViewLabel)
    func orosyTextViewDidEndEditing(_ _orosyTextViewLabel: OrosyTextViewLabel)
}

@IBDesignable class OrosyTextViewLabel:UIView, UITextViewDelegate {
    @IBOutlet var delegate: OrosyTextViewLabelDelegate?
    
    var underlineColor:UIColor = .clear {
        didSet {
            if let line = underLineView {
                line.backgroundColor = underlineColor
            }
        }
    }

    @IBInspectable var underline: Bool = false {
        didSet {
            if underline {
                underLineView!.backgroundColor = normalLinelColor
            }else{
                underLineView!.backgroundColor = .clear
            }
        }
    }

    var underLineView:UIImageView?
    var titleLabel:OrosyLabel12?
    var textView:OrosyTextView?
    var errorLabel:OrosyLabel12?
    
    var placeholder:String = "" {
        didSet {
            textView?.placeholder = placeholder
        }
    }
    var text:String {
        set {
            textView?.text = newValue
        }
        get {
            return textView?.text ?? ""
        }
    }
    
    var title:String = "" {
        didSet {
            titleLabel?.text = title
            titleLabel?.sizeToFit()
        }
    }
    
    var indexPath:IndexPath? {
        didSet {
            textView?.indexPath = indexPath
        }
    }
    var error:Bool = false {
        didSet {
            let color = (error) ? errorLineColor : normalLinelColor
            textView?.textColor = color
            setLineColor(color)
            errorHidden = !error
        }
    }
    var errorText:String = "" {
        didSet {
            errorLabel?.text = errorText
        }
    }
    var errorHidden:Bool = true{
        didSet {
           errorLabel?.isHidden = errorHidden
        }
    }
    var focus:Bool = false {
        didSet {
            textView?.backgroundColor = (focus) ? UIColor.orosyColor(color: .S50) : UIColor.orosyColor(color: .Gray100)
        }
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setLabel(frame)
        drawUnderLine()
    }

    override init(frame:CGRect) {
        super.init(frame:frame)
        setLabel(frame)
        drawUnderLine()
    }
    
    override func draw(_ rect: CGRect) {
        
        setLabel(frame)
        drawUnderLine()
    }
    
    func setLabel(_ rect: CGRect) {
        
        let size = self.frame.size
        
        if titleLabel == nil {
            titleLabel = OrosyLabel12(frame: .zero)
            titleLabel!.textColor = normalLinelColor
            self.addSubview(titleLabel!)
        }
        
        let frame = CGRect(x:0, y: 22, width: size.width, height:size.height - 22 )
        
        if textView == nil {
            textView = OrosyTextView(frame: frame)
            if let txv = textView {
                txv.delegate = self
                txv.textColor = normalLinelColor
                txv.textContainer.lineBreakMode = .byTruncatingTail
                txv.backgroundColor = UIColor.orosyColor(color: .Gray100)
                txv.fontSize = 16
                txv.topPadding = 7
                txv.bottomPadding = 3
                self.addSubview(txv)
            }
        }else{
            textView?.frame = frame
        }
        
        if errorLabel == nil {
            errorLabel = OrosyLabel12(frame: .zero)
            if let elabel = errorLabel {
                elabel.textColor = UIColor.orosyColor(color: .Red)
                elabel.isHidden = true
                self.addSubview(elabel)
                elabel.translatesAutoresizingMaskIntoConstraints = false
                
                let constraints = [
                    elabel.leadingAnchor.constraint(equalTo: self.titleLabel!.trailingAnchor, constant:10),
                    elabel.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: -2),
                    elabel.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant:20),
                    elabel.heightAnchor.constraint(equalToConstant:21),
                ]
                NSLayoutConstraint.activate(constraints)
            }
        }
        
    }
    
    func drawUnderLine() {

        let size = self.frame.size
        underLineView = UIImageView(frame: CGRect(x:0, y: size.height - 1, width: size.width, height:1 ))
        underLineView!.backgroundColor = underlineColor
        self.addSubview(underLineView!)

    }
    func setLineColor(_ color: UIColor) {
    
        if underline {
            underLineView!.backgroundColor = color
        }
    }
    func textViewDidBeginEditing(_ _testView: UITextView) {
        if let delg = self.delegate {
            delg.orosyTextViewDidBeginEditing(self)
        }
        textView?.placeholder  = ""
    }

    func textViewDidChangeSelection(_ _testView: UITextView) {
        if let delg = self.delegate {
            delg.orosyTextViewDidChangeSelection(self)
        }
        textView?.placeholder = (_testView.text.count == 0) ? placeholder : ""
    }
    
    func textViewDidEndEditing(_ _testView: UITextView) {
        if let delg = self.delegate {
            delg.orosyTextViewDidEndEditing(self)
        }
    }
}

// MARK: ==========================
// MARK: UIButton

// UITableViewCell上に配置したボタンを識別可能にする拡張ボタン
class IndexedButton: UIButton {
    var indexPath:IndexPath? = nil
    var selectedItemParent:ItemParent?
    var baseView:UIView? = nil
    var open:Bool = false
    var collectionView:OrosyUICollectionView!
    var activityIndicator:UIActivityIndicatorView!
    var cell:UITableViewCell!
    var displayMode:HomeDisplayMode = .Home
    var height:CGFloat = 0
    var underLineView:UIImageView?
    var leftInset:CGFloat = 0
    var underlineColor:UIColor = normalLinelColor {
        didSet {
            if let line = underLineView {
                line.backgroundColor = underlineColor
            }
        }
    }
    @IBInspectable var underline: Bool = false
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.contentMode = .scaleAspectFill

    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        self.contentMode = .scaleAspectFill
    }
    
    override func draw(_ rect: CGRect) {

        if underline {
            let size = self.frame.size
            underLineView = UIImageView(frame: CGRect(x:0, y: size.height - 1, width: size.width, height:1 ))
            underLineView?.backgroundColor = normalLinelColor
            self.addSubview(underLineView!)
        }
    }
    
    func setButtonTitle(title:String, fontSize:CGFloat, color:UIColor = UIColor.orosyColor(color: .Black600)) {
        
        let textAttributes: [NSAttributedString.Key : Any] = [
                .font : UIFont(name: OrosyFont.Regular.rawValue, size: fontSize)!,
                .foregroundColor : ((self.isEnabled) ? color : UIColor.orosyColor(color: .Gray400)),
            ]

        let newTitle = NSAttributedString(string: title, attributes: textAttributes)
        self.setAttributedTitle(newTitle, for: .normal)
        self.titleEdgeInsets = UIEdgeInsets(top: 7.0, left: leftInset, bottom: 0.0, right: 0.0)  // ボタンのタイトルが上にズレているので補正する. StoryboardのAlign設定がupperになっている必要がある ->機能していない。　Button TypeをCustomにすると改善する
         
    }
}

// ラベル付きのボタン    高さは68固定

@IBDesignable class OrosyMenuButtonWithLabel:UIView, UITextFieldDelegate {
    
    @IBInspectable var withLabel:Bool = true
    
    @IBInspectable var underline: Bool = false{
        didSet {
            button.underline = self.underline
        }
    }
    var focus:Bool = false {
        didSet {
            button.backgroundColor = (focus) ? UIColor.orosyColor(color: .S50) : .white
        }
    }
    
    var titleLabel:OrosyLabel12!
    var button:IndexedButton!
    var errorLabel:OrosyLabel12!
    var title:String = "" {
        didSet {
            if let label = titleLabel {
                label.text = title
                label.sizeToFit()
                label.layoutIfNeeded()
            }
        }
    }
    var errorText:String = "" {
        didSet {
            errorLabel.text = errorText
        }
    }
    var errorHidden:Bool = true{
        didSet {
           errorLabel.isHidden = errorHidden
        }
    }
    var error:Bool = false {
        didSet {
            let color = (error) ? errorLineColor : normalLinelColor
            if let label = titleLabel {
            //    label.textColor = color
            }
            button.underlineColor = color
           // button.setTitleColor(color, for: .normal)
            errorHidden = !error
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setLabel(.zero)
    }

    override init(frame:CGRect) {
        super.init(frame:frame)
        setLabel(frame)
    }
    
    func setLabel(_ rect: CGRect) {
        
        let size = self.frame.size
        print(size)
        if withLabel {
            titleLabel = OrosyLabel12(frame:CGRect(x:0, y: size.height - 60, width: 10, height:40 ) )       // 制約を使うと、sizetofitが機能しなくなるので、使っていない
            titleLabel.textColor = normalLinelColor
            titleLabel.numberOfLines = 1
            self.addSubview(titleLabel!)
        }
        
        button = IndexedButton(frame:  .zero)   // CGRect(x:0, y: 22, width: size.width, height:40 ))
        button.contentHorizontalAlignment = .left
        button.leftInset = 10
        self.addSubview(button!)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        let buttonHeight:CGFloat = 40   //self.bounds.height - ((withLabel) ? 20 : 0)  //40
        
        //
        errorLabel = OrosyLabel12(frame: .zero)
        errorLabel.textColor = UIColor.orosyColor(color: .Red)
        errorLabel.isHidden = false
        self.addSubview(errorLabel!)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false

        var constraints = [
          
            button.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant:0),
            button.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant:30),
            button.heightAnchor.constraint(equalToConstant:buttonHeight),
            button.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            
            errorLabel.leadingAnchor.constraint(equalTo: self.titleLabel.trailingAnchor, constant:10),
            errorLabel.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant:20),
            errorLabel.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            errorLabel.heightAnchor.constraint(equalToConstant:21),
    

        ]
        
        //constraints.append(button.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 20))


        let height = self.bounds.height - 32
        let imageView = UIImageView(frame:CGRect(x:size.width - 30, y: height, width: 18, height:18 ))
        imageView.image = UIImage(named:"expand_more")
        self.addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(imageView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -10))
        constraints.append(imageView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -10))
        
        NSLayoutConstraint.activate(constraints)
    }
    
    func setButtonTitle(title:String, fontSize:CGFloat) {
    
//        button.setButtonTitle(title:title, fontSize:fontSize, color:((self.error) ? UIColor.orosyColor(color: .Red) : UIColor.orosyColor(color: .Black600)) )
        button.setButtonTitle(title:title, fontSize:fontSize, color: UIColor.orosyColor(color: .Black600))

    }
}

@IBDesignable class OrosyMenuButton:UIView, UITextFieldDelegate {

    var button:IndexedButton!
    
    var error:Bool = false {
        didSet {
            let color = (error) ? errorLineColor : normalLinelColor
            button.underlineColor = color
            //button.setTitleColor(color, for: .normal)
        }
    }
    
    @IBInspectable var underline: Bool = false{
        didSet {
            button.underline = self.underline
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setLabel(frame)
    }

    override init(frame:CGRect) {
        error = false
        super.init(frame:frame)
        setLabel(frame)
    }
    
    func setLabel(_ rect: CGRect) {
        
        let size = self.frame.size

        button = IndexedButton(frame:  .zero)   // CGRect(x:0, y: 22, width: size.width, height:40 ))
        button.contentHorizontalAlignment = .left
        button.leftInset = 10
        self.addSubview(button!)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        let buttonHeight:CGFloat = 50
        
        let constraints = [
            button.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant:0),
            button.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant:30),
            button.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0),
            button.heightAnchor.constraint(equalToConstant:buttonHeight),
        ]

        NSLayoutConstraint.activate(constraints)

        let imageView = UIImageView(frame:CGRect(x:size.width - 30, y: 14, width: 18, height:18 ))
        imageView.image = UIImage(named:"expand_more")
        self.addSubview(imageView)
    }
    
    func setButtonTitle(title:String, fontSize:CGFloat) {
    
        button.setButtonTitle(title:title, fontSize:fontSize, color:((self.error) ? UIColor.orosyColor(color: .Red) : UIColor.orosyColor(color: .Black600)) )
    
    }
}
// 背景がブルーで、白文字のボタン      // 
class OrosyButton:IndexedButton {
    var textColor:UIColor!

    
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                self.backgroundColor = UIColor.orosyColor(color: .Blue)
                self.titleLabel?.textColor = UIColor.white
            }else{
                self.backgroundColor = UIColor.orosyColor(color: .Gray200)
                self.titleLabel?.textColor = UIColor.orosyColor(color: .Gray400)
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        // 角丸
        self.layer.cornerRadius = rect.size.height / 2.0    //　両サイドを丸くする
        self.clipsToBounds = true
        
        // 枠線
        self.layer.borderColor = ((self.isEnabled) ? UIColor.orosyColor(color: .Blue) :  UIColor.orosyColor(color: .Gray400)).cgColor
        self.layer.borderWidth = 1
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = (self.isEnabled) ? UIColor.orosyColor(color: .Blue) : UIColor.orosyColor(color: .Gray300)

    }
    
    func setButtonTitle(title:String, fontSize:CGFloat) {
    
        super.setButtonTitle(title:title, fontSize:fontSize, color:((self.isEnabled) ? UIColor.white : UIColor.orosyColor(color: .Gray400)) )
    
    }

}

// 背景が白で、ブルーの枠、文字のボタン
class OrosyButtonWhite:OrosyButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = UIColor.white
    }
    
     override func setButtonTitle(title:String, fontSize:CGFloat) {
        
        super.setButtonTitle(title:title, fontSize:fontSize, color:UIColor.orosyColor(color: .S400))
    }
    
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                self.backgroundColor = .white
                self.titleLabel?.textColor = UIColor.orosyColor(color: .S400)
            }else{
                self.backgroundColor = UIColor.orosyColor(color: .Gray300)
                self.titleLabel?.textColor = UIColor.orosyColor(color: .Gray400)
            }
            self.layer.borderColor = ((isEnabled) ? UIColor.orosyColor(color: .S400) :  UIColor.orosyColor(color: .Gray400)).cgColor
        }
    }
    
    override var isSelected:  Bool {
        didSet {
            
            super.isSelected = isSelected
            if isSelected {
      //          self.backgroundColor = .white
                self.titleLabel?.textColor = UIColor.orosyColor(color: .S400)
            }else{
        //        self.backgroundColor = UIColor.orosyColor(color: .Gray300)
                self.titleLabel?.textColor = UIColor.orosyColor(color: .Gray400)
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        // 角丸
        self.layer.cornerRadius = rect.size.height / 2.0    //　両サイドを丸くする
        self.clipsToBounds = true
        
        // 枠線
        self.layer.borderColor = ((self.isSelected) ? UIColor.orosyColor(color: .S400) :  UIColor.orosyColor(color: .Gray400)).cgColor
        self.layer.borderWidth = 1
        
        self.backgroundColor = ((isEnabled) ? .white :  UIColor.orosyColor(color: .Gray300))
    }
}

// 背景が白で、グレーの枠、文字のボタン
class OrosySelectButton:OrosyButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = UIColor.white
    }
    
    override func draw(_ rect: CGRect) {
        // 角丸
        self.layer.cornerRadius = 4
        self.clipsToBounds = true
        
        // 枠線
        self.layer.borderColor =  UIColor.orosyColor(color: .Gray500).cgColor
        self.layer.borderWidth = 0.5
    }
    
    override func setButtonTitle(title:String, fontSize:CGFloat) {
        
         super.setButtonTitle(title:title, fontSize:fontSize, color:UIColor.orosyColor(color: .Black600))

    }
}

class OrosyButtonGradient:OrosyButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = UIColor.white
        self.layer.borderColor = UIColor.clear.cgColor
        
        let color1 = UIColor(hex: "eaa123", alpha: 1.0)
        let color2 = UIColor(hex: "ce7150", alpha: 1.0)
        let color3 = UIColor(hex: "aa3166", alpha: 1.0)
        let color4 = UIColor(hex: "91137a", alpha: 1.0)
        
        self.withGradienBackground(color1: color1, color2: color2, color3: color3, color4: color4)
        
    }
    
    override func draw(_ rect: CGRect) {
            
        // 角丸
        self.layer.cornerRadius = rect.size.height / 2.0    //　両サイドを丸くする
        self.clipsToBounds = true
        
        // 枠線
        self.layer.borderColor = UIColor.clear.cgColor
        self.layer.borderWidth = 1
        
    }
    
    override func setButtonTitle(title:String, fontSize:CGFloat) {
               
        super.setButtonTitle(title:title, fontSize:fontSize, color:.white)
    }

}


// ステートに応じて背景色を切り替える
extension UIButton {

    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {

        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        setBackgroundImage(colorImage, for: state)
    }
}


// MARK: ==========================
// MARK: UICollectionView
class OrosyUICollectionView:UICollectionView {
 //   var type:HomeItemType = .NEWER
    var indexPath:IndexPath? = nil
    var displayMode:HomeDisplayMode = .Home
    var total:Int = 0       // 商品点数
    var error:Bool = false
}

// MARK: ==========================
// MARK: UIView
@IBDesignable class OrosyUIView:UIView {

    // 角丸の半径(0で四角形)
    @IBInspectable var cornerRadius: CGFloat = 0.0
    
    // 枠
    @IBInspectable var borderColor: UIColor = UIColor.clear
    @IBInspectable var borderWidth: CGFloat = 0.0
    
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

    override init(frame:CGRect) {
        super.init(frame:frame)
    }
    
    override func draw(_ rect: CGRect) {
        // 角丸
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = (cornerRadius > 0)
        
        // 枠線
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
        
        super.draw(rect)
    }
    
    func drawBorder(cornerRadius:CGFloat) {
            
        if cornerRadius > 0 {
            // 角丸
            self.layer.cornerRadius = cornerRadius
            self.clipsToBounds = true
        }
        
        // 枠線
        self.layer.borderColor = UIColor.orosyColor(color: .Gray300).cgColor
        self.layer.borderWidth = 1
        self.layoutSubviews()
    }

    func drawBorder(cornerRadius:CGFloat, color:UIColor, width:CGFloat) {
        
        if cornerRadius > 0 {
            // 角丸
            self.layer.cornerRadius = cornerRadius    //　両サイドを丸くする
            self.clipsToBounds = true
        }
        
        // 枠線
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
        self.layoutSubviews()
    }

    
}

extension UIView {
    func withGradienBackground(color1: UIColor, color2: UIColor, color3: UIColor, color4: UIColor) {

        let layerGradient = CAGradientLayer()

        layerGradient.colors = [color1.cgColor, color2.cgColor, color3.cgColor, color4.cgColor]
        layerGradient.frame = bounds
        layerGradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        layerGradient.endPoint = CGPoint(x: 1.0, y: 0.5)

        layer.insertSublayer(layerGradient, at: 0)
    }

    func roundCorner(cornerRadius:CGFloat) {
        
        // 角丸
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true
        self.layoutSubviews()

    }
    
    // StoryboardでCornarRadiusをセットしておかないと効かない？
    func roundCorner(cornerRadius:CGFloat, lower:Bool) {
        
        // 角丸
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true

        if lower {
            self.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }else{
            self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        self.layoutSubviews()

    }
}
// MARK: ==========================
// MARK: UIImageView

enum FitDirection {     // 
    case Left
    case Right
    case None
}

let imageCache = NSCache<NSString, UIImage>()

class OrosyUIImageView100:OrosyUIImageView {
     required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        imgeSize = OrosyImageSize.Size100
         drawBorder(cornerRadius:0, color:UIColor.orosyColor(color: .Gray300), width:1)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentMode = .scaleAspectFill //.scaleAspectFit
        imgeSize = OrosyImageSize.Size100
        drawBorder(cornerRadius:0, color:UIColor.orosyColor(color: .Gray300), width:1)
    }
    
}

class OrosyUIImageView200:OrosyUIImageView {
     required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        imgeSize = OrosyImageSize.Size200
    }
}

class OrosyUIImageView300:OrosyUIImageView {
     required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        imgeSize = OrosyImageSize.Size300
    }
}

class OrosyUIImageView400:OrosyUIImageView {
     required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        imgeSize = OrosyImageSize.Size400
    }
}

class OrosyUIImageView500:OrosyUIImageView {

     required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        imgeSize = OrosyImageSize.Size500
    }
}

class OrosyUIImageView640:OrosyUIImageView {

     required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        imgeSize = OrosyImageSize.Size640
    }
}


class OrosyUIImageView: UIImageView {

    
    var imgeSize:OrosyImageSize = .None    // 圧縮なし
    var targetRow:Int = 0
    /*
     テーブルやCollectionView上の場合は、画像をダウンロード中にスクロールされてセルが解放され、それが他の行で再利用されるため、異なる位置に画像が表示される場合がある。
     これを防ぐため、getImageFromUrlでは画像の読み込みを開始した時の行番号を指定し、それとは別にCELLを更新するたびに、
     　　imgView.targetRow = row　　（セルが再利用されるとtargetRowの値が変化する）
     としてセルの位置を更新する。そして、getImageFromUrlで受け取った行番号と、画像のダウンロードを完了した時のtargetRowが同じである場合だけ画像をセットするようにしている。
     
      指定されたサイズの角丸をつける。　画像とビューの縦横比が一致していないと、角丸がうまくできないため、画像の縦横比に合わせてビューの幅を調整する。
     　この時、幅をどちら側へ広げるのかをfixtToLeftで指定し、trueなら左固定（つまり右側に広げる）とする。
      この機能はメッセージ一覧で使っている
     */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentMode = .scaleAspectFill //.scaleAspectFit
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.contentMode = .scaleAspectFill //.scaleAspectFit
        
    }
    
    func drawBorder(cornerRadius:CGFloat, color:UIColor, width:CGFloat) {
        
        if cornerRadius > 0 {
            // 角丸
            self.layer.cornerRadius = cornerRadius    //　両サイドを丸くする
            self.clipsToBounds = true
        }
        
        // 枠線
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
    }
    
    func hideBorder() {
        self.layer.borderWidth = 0
    }
    // UIImageViewのサブクラスではdrawは呼び出されないため独自の関数を準備
    func drawBorder(cornerRadius:CGFloat) {
        
        if cornerRadius > 0 {
            // 角丸
            self.layer.cornerRadius = cornerRadius
            self.clipsToBounds = true
        }
        
        // 枠線
     //   self.layer.borderColor = UIColor.orosyColor(color: .Gray300).cgColor
      //  self.layer.borderWidth = 1
    }
    
    // maxWidth: ImageViewのサイズに対して、高さを合わせて横幅を調整するが、もし、その横幅がmaxWidthより超えていたら、その分だけ高さを減らす。
    // left: ImageViewの表示位置を基準にどちらへ広げるかの指定
    func getImageFromUrl(row:Int = -1, url: URL?, defaultUIImage: UIImage? = nil, radius:CGFloat = 0, fitImage:Bool = false, maxWidth:CGFloat = 0, left:Bool = false ) {
        
        self.layer.cornerRadius = radius
        self.clipsToBounds = true
        self.contentMode = .scaleAspectFill

        DispatchQueue.global().async {
            
            OrosyAPI.getImageFromCache(url, imagesize:self.imgeSize) {  completion in
                
                if let image = completion {
                    
                    DispatchQueue.main.async {
                        if row == -1 || self.targetRow == row {  // 画像を読み込み始めた時と、完了時で選択されているテーブル上の行が同じなら反映する
                            self.image = image
                            if fitImage { self.fitImageSize(image, maxWidth:maxWidth, left:left) }
                        }else{
                            print("Ignore due to different cell")
                        }
                    }
                }else{

                    DispatchQueue.main.async {
                        self.image = defaultUIImage
                        if fitImage { self.fitImageSize(defaultUIImage, maxWidth:maxWidth, left:left) }
                    }
                }
            }

        }
 
    }
    
    
    // 画像の縦横比に合わせて、imageViewのサイズを調整する（高さは変えずに横幅を調整する）
    func fitImageSize(_ _image:UIImage?, maxWidth:CGFloat, left:Bool) {
        
        if let image = _image {
            var frame = self.frame
            var viewSize = self.frame.size
            let imageSize = image.size
        
            viewSize.width = viewSize.height / imageSize.height * imageSize.width
            
            // 最大幅以上になる場合は、高さを調整して最大幅に収まるようにする
            if viewSize.width > maxWidth {
                viewSize.height = viewSize.height * maxWidth / viewSize.width
                viewSize.width = maxWidth
            }
            if !left {
                frame.origin.x += (self.frame.size.width - viewSize.width)
            }
            frame.size = viewSize
            self.frame = frame
        }
    }
}

// MARK: UITableView
class OrosyUITableView: UITableView  {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         let selectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
        selectedCell.contentView.backgroundColor = UIColor.orosyColor(color: .Gray100)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
         let selectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
         selectedCell.contentView.backgroundColor = UIColor.clear
    }
}


// MARK: UIPageControl
class OrosyPageContorl:UIPageControl {
    
    override var currentPage:Int {
        didSet {
            self.setDots(index: currentPage)
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setDots(index: 0)

    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.setDots(index: 0)

    }
    
    public func setDots(index:Int) {
        self.preferredIndicatorImage = UIImage(named: "page_circle")
        for idx in 0..<self.numberOfPages {
            if idx == index {
                self.setIndicatorImage(UIImage(named: "page_filledCircle"), forPage: idx)
            }else{
                self.setIndicatorImage(UIImage(named: "page_circle"), forPage: idx)
            }
        }
    }
}

// MARK: シェア
class ShareItem: NSObject, UIActivityItemSource {
    var url:URL!
    var text:String!
    var title:String!
    
    init(text:String, title:String) {
        self.text = text
        self.title = title
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return  text ?? ""  // 文字列を一つ渡すだけなら、ここでそれを返せば良いが、複数のオブジェクトを返す場合にはShareItemとして定義する必要がある
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return  activityViewControllerPlaceholderItem(activityViewController)
    }
    
    // メールのsubjectにセットする文字列を返す
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "Ososyのおすすめ情報です"
    }
    
    /*
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "この商品をシェアする" // シェアするオブジェクトがテキストだけだとこれがタイトルとして表示されるが、そうでないと"2 Links"のように表示されてしまい、ここでセットしたタイトルは表示されない
    }
    */
    
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {

        let metadata = LPLinkMetadata()
        metadata.title = self.title //"この商品をシェアする"
        
        metadata.iconProvider = NSItemProvider.init(contentsOf:Bundle.main.url(forResource: "AppIcon", withExtension: "png"))   //　アプリのアイコンを表示させる
        //metadata.originalURL = URL(string: ROOT_URL)      // 表示用？
        //metadata.url = metadata.originalURL             // 実際に飛ぶ先のURL?
        return metadata
    }
 
}


// MARK: ローカル通知関連
class LocalNotificationManager:NSObject, UNUserNotificationCenterDelegate {
    // MARK:ローカル通知

    func setAppNotification(title:String, body:String, userInfo:[String:Any]? ) {

        
        DispatchQueue.main.async {
          //  let status = UIApplication.shared.applicationState
            
          //  switch status {
         //   case .active:
                // アプリ起動中の受信
                let content = UNMutableNotificationContent()
                content.categoryIdentifier = NotificationCategory.SubscriptionMessage.rawValue
                content.title = title
                content.body = body
                content.sound = UNNotificationSound.default
                if let uinfo = userInfo {
                    content.userInfo = uinfo
                }
                // 直ぐに通知を表示
                let request = UNNotificationRequest(identifier: "immediately", content: content, trigger: nil)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                
          //  case.background:
                //setNofitication(msg: "メッセージを受信しました")
          //      break
         //   default:
         //       break
                
           /// }
        }
    }
}



//閉じるボタンの付いたキーボード -->　使っていない
class CustomTextField: UITextField {

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit(){
        let width = window?.bounds.width ?? 0
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 50))
        customView.backgroundColor = UIColor.orosyColor(color: .Gray100)
        
        let textField = UITextField(frame: CGRect(x: 20, y: 0, width: width - 60, height: 50))
 
        customView.addSubview(textField)
        
        let closeButton = UIButton(frame: CGRect(x: width - 60, y: 0, width: 60, height: 50))
        closeButton.setImage(UIImage(named: "close"), for: .normal)
        closeButton.addTarget(self, action: #selector(self.closeButtonTapped), for: .touchUpInside)
        closeButton.setTitleColor ( UIColor.orosyColor(color: .Black600) , for:.normal)
        customView.addSubview(closeButton)
        
        self.inputAccessoryView = customView
    }

    @objc func closeButtonTapped(){
        self.endEditing(true)
        self.resignFirstResponder()
    }
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let v = Int("000000" + hex, radix: 16) ?? 0
        let r = CGFloat(v / Int(powf(256, 2)) % 256) / 255
        let g = CGFloat(v / Int(powf(256, 1)) % 256) / 255
        let b = CGFloat(v / Int(powf(256, 0)) % 256) / 255
        self.init(red: r, green: g, blue: b, alpha: min(max(alpha, 0), 1))
    }
}

//　自動的に消えるメッセージボックス
class SmoothDialog:UIView {
    
    var label:UILabel!

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!

    }
    
    init () {
        
        let SideMargin:CGFloat = 20
        let HEIGHT:CGFloat = 100
        let CornerRadius:CGFloat = 4
        let screenWidth = UIScreen.main.bounds.size.width
        
        var frame = CGRect(x: SideMargin, y: 0, width: screenWidth - SideMargin * 2, height: HEIGHT)
        super.init(frame: frame)

        self.backgroundColor = .white
        self.alpha = 0
        
        // 角丸
        self.layer.cornerRadius = CornerRadius
        self.clipsToBounds = true

        // 枠線
        self.layer.borderColor = UIColor.orosyColor(color: .Gray300).cgColor
        self.layer.borderWidth = 1
        self.layer.masksToBounds = false
        
        // 影の方向（width=右方向、height=下方向、CGSize.zero=方向指定なし）
        self.layer.shadowOffset = CGSize(width: 4.0, height: 4.0)
        self.layer.shadowColor = UIColor.orosyColor(color: .Gray300).cgColor
        self.layer.shadowOpacity = 0.8
        self.layer.shadowRadius = 4
        
        frame.origin.x = 20
        frame.origin.y = 10
        frame.size.width = frame.size.width - 40
        label = UILabel(frame:frame )
        label.textAlignment = .center
        label.font = UIFont(name: OrosyFont.Regular.rawValue, size: 14)
        label.textColor = UIColor.orosyColor(color: .Gray400)
        label.numberOfLines = 0
        
        self.addSubview(label)
        
    }
    
    func show(message:String, pointY:CGFloat = -1) {
        
        var frame = self.frame
        frame.origin.y = (pointY == -1) ? UIScreen.main.bounds.size.height / 2.0 : pointY
        self.frame = frame
        
        label.text = message
        
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        self.alpha = 0
        UIView.animate(withDuration: 0.3, // アニメーションの秒数
                            delay: 0.0, // アニメーションが開始するまでの秒数
                           options: [.curveEaseOut], // アニメーションのオプション 等速 | 繰り返し
                           animations: {
            
            self.alpha = 1
            
        }, completion: { (finished: Bool) in

            UIView.animate(withDuration: 0.3, // アニメーションの秒数
                                delay: 1.5, // アニメーションが開始するまでの秒数
                               options: [.curveEaseOut], // アニメーションのオプション 等速 | 繰り返し
                               animations: {
                
                self.alpha = 0
                
            }, completion: { (finished: Bool) in

            })
         
        })
    }
    
}

// MARK: セレクトボタン
@IBDesignable final class OrosySwitchButton:UIButton {
    
    // isSelect  false: 商品   true: ブランド
    @IBInspectable var leftLabel:String = ""
    @IBInspectable var rightLabel:String = ""
    public var indexPath:IndexPath?
    
    private var leftButton:UIButton!
    private var rightButton:UIButton!
    private var fontSize:CGFloat = 14
    private var borderArea:UIView!      // 2つのボタンの間のエリア（ボタンがラウンドしているので、背景が見えてしまうのを防ぐために埋める）
    
    private let onColor = UIColor.orosyColor(color: .Blue)
    private let offColor = UIColor.white

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ rect: CGRect) {
        
        let HEIGHT:CGFloat = 40
        let BORDER_WIDTH:CGFloat = 40
        let width = self.bounds.width

        if borderArea == nil {
            borderArea = UIView(frame: CGRect(x:width / 2 - BORDER_WIDTH / 2, y:0, width:BORDER_WIDTH, height:HEIGHT ))
            borderArea.backgroundColor = .white
            self.addSubview(borderArea)
        }
        
        if rightButton == nil {
            rightButton = UIButton(type:.custom)
            rightButton.isUserInteractionEnabled = false
            rightButton.frame = CGRect(x: width - width / 2 , y: 0 , width: width / 2  , height: HEIGHT)
            rightButton.layer.cornerRadius = HEIGHT / 2.0
            rightButton.clipsToBounds = true

            self.addSubview(rightButton)
            setColor(rightButton, label:rightLabel)

        }

        if leftButton == nil {
            leftButton = UIButton(type:.custom)
            leftButton.isUserInteractionEnabled = false     //　これを有効にしていると、メインのボタンタッチに反応しなくなる
            leftButton.frame = CGRect(x: 0, y:0, width: width / 2  , height: HEIGHT)
            //leftButton.layer.borderWidth = 1
            leftButton.layer.cornerRadius = HEIGHT / 2.0
            leftButton.clipsToBounds = true

            self.addSubview(leftButton)
            setColor(leftButton, label:leftLabel)
        }
        

        leftButton.isSelected = !isSelected
        rightButton.isSelected = isSelected
        
        if isSelected {
            self.bringSubviewToFront(rightButton)
            leftButton.titleEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
            rightButton.titleEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        }else{
            self.bringSubviewToFront(leftButton)
            leftButton.titleEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
            rightButton.titleEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
            
        }
    }
    
    // ステートに応じて、文字の色を切り替えるための設定
    func setColor(_ button:UIButton, label:String) {

        // for Normal State
        button.setBackgroundColor( offColor, for: .normal)

        let textAttributes_off: [NSAttributedString.Key : Any] = [
            .font : UIFont(name: OrosyFont.Bold.rawValue, size: self.fontSize)!,
                .foregroundColor : onColor
            ]

        let newTitle_off = NSAttributedString(string: label, attributes: textAttributes_off)
        button.setAttributedTitle(newTitle_off, for: .normal)

        
       // for Selected State
        button.setBackgroundColor( onColor, for: .selected)

        let textAttributes_on: [NSAttributedString.Key : Any] = [
            .font : UIFont(name: OrosyFont.Bold.rawValue, size: self.fontSize)!,
                .foregroundColor : offColor
            ]

        let newTitle_on = NSAttributedString(string: label, attributes: textAttributes_on)
        button.setAttributedTitle(newTitle_on, for: .selected)
    }
}


// 確認メッセージ
protocol ConfirmControllerDelegate: AnyObject {
    func selectedAction(sel:Bool)
}


// 確認ダイアログ
// メッセージ部は行数に応じて高さが変わるようになっている
// 
class ConfirmVC:UIViewController  {
    
    var enableCloseGesture = true
    var image:UIImage?
    var message_title:String = ""
    var message_body:String = ""
    var mainButtonTitle:String?
    var cancelButtonTitle:String?
    var return_code:Bool = false
    var delegate:ConfirmControllerDelegate? = nil
    @IBOutlet var bottomConstraintForMainButton: NSLayoutConstraint!
    
    @IBOutlet weak var topConstraintForTitleLabel: NSLayoutConstraint!
    
    override func viewDidLoad() {
        let confTitle = self.view.viewWithTag(1) as! UILabel
        let message = self.view.viewWithTag(2) as! UILabel
        let mainButton = self.view.viewWithTag(3) as! OrosyButton
        let cancelButton = self.view.viewWithTag(4) as! OrosyButton
        let imageView = self.view.viewWithTag(10) as! OrosyUIImageView500
        
        confTitle.text = message_title
        message.text = message_body
        mainButton.setButtonTitle(title: mainButtonTitle ?? "", fontSize: 16)
        mainButton.titleEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        cancelButton.titleEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        
        if mainButtonTitle == nil {
            mainButton.isHidden = true
            bottomConstraintForMainButton.isActive = true
        }else{
            mainButton.isHidden = false
            mainButton.setButtonTitle(title: mainButtonTitle!, fontSize: 16)
        }
        
        if cancelButtonTitle == nil {
            cancelButton.isHidden = true
            bottomConstraintForMainButton.isActive = false
        }else{
            cancelButton.isHidden = false
            cancelButton.setButtonTitle(title: cancelButtonTitle!, fontSize: 16)
        }
        
        if let img = image {
            imageView.contentMode = .scaleAspectFit
            imageView.image = img
            
        }else{
            topConstraintForTitleLabel.isActive = false
        }
    }
    
    
    @IBAction func execRemoveItem(_ sender: Any) {

        self.dismiss(animated: true, completion: {
            if let _delegate = self.delegate {
                _delegate.selectedAction(sel: true)
            }
        })
    }
    
    @IBAction func closeConfirmView() {
        if let _delegate = delegate {
            _delegate.selectedAction(sel: false)
        }
        self.dismiss(animated: true, completion: nil)
    }
}

extension UIStackView {
    
    func removeFully(view: UIView) {
        removeArrangedSubview(view)
        view.removeFromSuperview()
    }
    
    func removeFullyAllArrangedSubviews() {
        arrangedSubviews.forEach { (view) in
            removeFully(view: view)
        }
    }
    
}

enum EmptyAlertType {
    case searchProduct
    case searchBrand
    case favoriteProduct
    case favoriteBrand
    case thread
    case message
    case noProfile
    case orderHistory
    case cart

}

class EmptyAlertVC:UIViewController {
    
    @IBOutlet weak var imageView:UIImageView!
    @IBOutlet weak var messageLabel:OrosyLabel16!
    
    var isHidden:Bool! {
        didSet {
            DispatchQueue.main.async {
                if let vw = self.view {
                    vw.isHidden = self.isHidden
                }
            }
        }
    }
    
    //ログインしていないときだけ表示する
    @IBAction func loginButtonPushed(_ sender: Any) {
        /*
        let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
        if let vc = storyboard.instantiateInitialViewController() {
            (UIApplication.shared.delegate as! AppDelegate).setRootViewController(viewControllerName: vc)       // ルート画面へ戻る
        }
        */
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
                                  duration: 0.5,
                                  options: .transitionCrossDissolve,
                                  animations: nil,
                                  completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        self.view.isHidden = false
        
        let loginMessage = self.view.viewWithTag(3) as! OrosyLabel14
        loginMessage.isHidden = g_loginMode
        loginMessage.text = ""  //NSLocalizedString("LetStartLogin", comment: "")
        
        let button = self.view.viewWithTag(10) as! OrosyButton
        
        button.isHidden = (g_loginMode) ? true : false
        button.setButtonTitle(title: "新規登録/ログインする", fontSize: 14)
    }
    
    func selectType(type:EmptyAlertType) {
        var message:String!
        var imageName:String!
        var topMargin:CGFloat = 100
        
        switch type {
        case .searchProduct:
            message = NSLocalizedString("NoSearchProduct", comment: "")
            imageName = "no_search_result"
            topMargin = 150
        case .searchBrand:
            message = NSLocalizedString("NoSearchBrand", comment: "")
            imageName = "no_search_result"
            topMargin = 150
            
        case .favoriteProduct:
            message = NSLocalizedString("NoFavoriteProduct", comment: "")
            imageName = "no_favorite_product"
            topMargin = 150
        case .favoriteBrand:
            message = NSLocalizedString("NoFavoriteBrand", comment: "")
            imageName = "no_favorite_brand"
            topMargin = 150
        case .thread:
            message = NSLocalizedString("NoThread", comment: "")
            imageName = "no_message"
            topMargin = 100
        case .message:
            message = NSLocalizedString("NoMessage", comment: "")
            imageName = "no_message"
            topMargin = 150
        case .noProfile:
            message = NSLocalizedString("LoginToInput", comment: "")
            imageName = "no_profile"
            topMargin = 150
        case .orderHistory:
            message = NSLocalizedString("NoOrderHistory", comment: "")
            imageName = "no_order"
            topMargin = 100
        case .cart:
            message = NSLocalizedString("NoCart", comment: "")
            imageName = "no_cart"
            topMargin = 100
        }
        
        imageView.image = UIImage(named:imageName)
        messageLabel.text = message
        
        var frame = self.view.frame
        frame.origin.y = topMargin
        self.view.frame = frame
    }

    func setTopMargine(top:CGFloat) {
        var frame = self.view.frame
        frame.origin.y = top
        self.view.frame = frame
    }
    
}


class PopoverVC:OrosyUIViewController {
    
    enum POPUP_HELP:String {
        case INSTAGRAM = "Instagram_id"
        case TWITTER = "Twitter_id"
        case FACEBOOK = "Facebook_id"
        case STRING = ""
    }
    
    @IBOutlet var imageView:UIImageView!
    @IBOutlet var textLabel:OrosyLabel14!
    
    var mode:POPUP_HELP!
    var text:String = ""
    
    override func viewDidLoad() {

        
        if mode != .STRING {
            imageView.isHidden = false
            textLabel.isHidden = true
            
            var frame = self.view.frame
            frame.size.height = frame.size.width / 335 * 260
            self.view.frame = frame
            
            imageView.image = UIImage(named:mode.rawValue)

        }else{
            imageView.isHidden = true
            textLabel.isHidden = false
            textLabel.text = text
            
            var frame = self.view.frame
            frame.size.height = 150
            self.view.frame = frame
            
        }
    }
    
    @IBAction func closePopOverView(_ sender: Any) {
        self.dismiss(animated: true)
    }
}



