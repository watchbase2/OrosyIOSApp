//
//  AccountViewController.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/09.
//

import UIKit
import SafariServices
import MessageUI

enum AccountItemType {
    
    case PROFILE
    case COMPANY_INFO
    case DELIVERY_PLACE
    case PAYMENT
    case INFORMATION
    case PASSWORD_CHANGE
    case LOGOUT
    case SEND_LOG
    case PRIVACY_POLICY
    case TERMS_OF_SERVICE_BUYER
    case APP_VERSION
    case RETIRE_ACCOUNT
    case POINT
    
}

class AccountDisplayItem: NSObject {
    var itemType:AccountItemType?
    var title:String?
    var cellType:String?
    var itemObject: NSObject?
    var itemHeight:CGFloat
    

    init( type:AccountItemType, title:String?, cell:String?, height:CGFloat ) {
        
        itemType = type
        self.title = title
        cellType = cell
        itemHeight = height
    }
}

class AccountVC: OrosyUIViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, ConfirmControllerDelegate {

    

    @IBOutlet weak var MainTableView: UITableView!
    var profileDetail:ProfileDetail!
    var profileDetailBank:ProfileDetailBank!
    
    /*
        UITableViewのセクションごとに表示する項目の定義
        タイプによって使用するCELLのデザインなどが異なる
    */
    
    var itemList:[[String:Any]] =
        [
            [
                "TITLE" : "アカウント",
                "DATA" : [
                AccountDisplayItem(type: AccountItemType.POINT, title: "保有ポイント", cell:"PointCell", height:86 )
                ]

            ],
            [
                "TITLE" : "アカウント",
                "DATA" : [
                AccountDisplayItem(type: AccountItemType.PROFILE, title: "プロフィール情報", cell:"AccountCell", height:44),
                AccountDisplayItem(type: AccountItemType.COMPANY_INFO, title: "会社情報", cell:"AccountCell", height:44),
                AccountDisplayItem(type: AccountItemType.DELIVERY_PLACE, title: "納品先情報", cell:"AccountCell", height:44),
                AccountDisplayItem(type: AccountItemType.PAYMENT, title: "支払・払戻情報", cell:"AccountCell", height:44),
             //   AccountDisplayItem(type: AccountItemType.INFORMATION, title: "お知らせ一覧", cell:"AccountCell", height:44),
                AccountDisplayItem(type: AccountItemType.PRIVACY_POLICY, title: "プライバシーポリシー", cell:"AccountCell", height:44),
                AccountDisplayItem(type: AccountItemType.TERMS_OF_SERVICE_BUYER, title: "利用規約", cell:"AccountCell", height:44),
                AccountDisplayItem(type: AccountItemType.PASSWORD_CHANGE, title: "パスワード変更", cell:"AccountCell", height:44),
                AccountDisplayItem(type: AccountItemType.LOGOUT, title: (g_loginMode) ? "ログアウト" : "アカウント作成", cell:"AccountCell", height:44 ),
                ]

            ],
            [
                "TITLE" : "アカウント",
                "DATA" : [
                AccountDisplayItem(type: AccountItemType.RETIRE_ACCOUNT, title: "アカウント削除", cell:"AccountCell", height:44 )
                ]

            ]
        ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNaviTitle(title: "設定")
        
        if #available(iOS 15.0, *) {
            MainTableView.sectionHeaderTopPadding = 0.0 // iOS15から追加された、セクションヘッダーの上のスペースを消す
        }
  
        profileDetailBank = ProfileDetailBank()
        _ = profileDetailBank.getData()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named:"blank"), style:.plain, target: self, action: nil)    // タイトルがセンターになるようにダミーのボタンを配置
      //  self.navigationItem.hidesBackButton = true
     //   self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"backButton"), style:.plain, target: self, action: #selector(closeView))
#if DEBUG
        if var items = itemList[1]["DATA"] as? [AccountDisplayItem] {
            items.append ( AccountDisplayItem(type: AccountItemType.SEND_LOG, title: "ログデータを送信", cell:"AccountCell", height:44) )
            itemList[1]["DATA"] = items
        }
#endif
        
        let headerView = UIView(frame:CGRect(x:0, y:0, width:100, height:20))
        headerView.backgroundColor = UIColor.orosyColor(color: .Background)
        MainTableView.tableFooterView = headerView
        MainTableView.reloadData()
        
        let enc = NotificationCenter.default
        enc.addObserver(self, selector: #selector(enteredIntoForeground), name: Notification.Name(rawValue:NotificationMessage.EnteredIntoForeground.rawValue), object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        MainTableView.reloadData()
    }
    
    @objc func enteredIntoForeground() {
        DispatchQueue.main.async {
            LogUtil.shared.log ("プロフィール情報の読み込み")
            //ProfileDetail.shared.getData()
            self.MainTableView.reloadData()
        }
        
    }
    
    func numberOfSections(in: UITableView) -> Int {
        return itemList.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        20
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView(frame: CGRect(x:0,y:0,width:10,height:20))
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension //自動設定
        
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        let display_data = itemList[section]["DATA"] as! [AccountDisplayItem]
        
        count = display_data.count
        
        return count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        let display_data = itemList[section]["DATA"] as! [AccountDisplayItem]
        let row_data = display_data[row]
 
        let cell = tableView.dequeueReusableCell(withIdentifier: row_data.cellType!, for: indexPath)
        let titleLabel = cell.viewWithTag(1) as! UILabel
        let valueLabel = cell.viewWithTag(2) as! UILabel
        valueLabel.text = ""

        titleLabel.text = row_data.title
        
        let baseView = cell.viewWithTag(100)!
        
        if section == 0 {
            baseView.layer.cornerRadius = 4
            baseView.clipsToBounds = true
        }else{
            if row == 0 {
                baseView.roundCorner(cornerRadius: 4, lower: false)
            }else if row == display_data.count - 1 {
                baseView.roundCorner(cornerRadius: 4, lower: true)
            }else{
                baseView.roundCorner(cornerRadius: 0)
            }
        }
        
        if row_data.itemType == .POINT {
            valueLabel.text = String(profileDetailBank.profileDetail?.credit ?? 0) + "pt"
            
        }else{
            if section == 2 && row == 0 {
                titleLabel.textColor = UIColor.orosyColor(color: .Red)
            }else{
                titleLabel.textColor = UIColor.orosyColor(color: .S400)
            }
        }
            
        return cell
    }
    
    var logoutExec = false
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath)
        let waitIndicator = cell?.viewWithTag(5) as! UIActivityIndicatorView
        
        let section = indexPath.section
        let row = indexPath.row

        let display_data = itemList[section]["DATA"] as! [AccountDisplayItem]
        let row_data = display_data[row]
    
        let itemType = row_data.itemType
        
        switch itemType {
        case .PROFILE:
            waitIndicator.startAnimating()

            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "ProfileVC") as! ProfileVC
                    vc.navigationItem.leftItemsSupplementBackButton = true
                    self.orosyNavigationController?.pushViewController(vc, animated: true)
                }
            }
            
        case .COMPANY_INFO:
            waitIndicator.startAnimating()

            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "CompanyProfileVC") as! CompanyProfileVC
                    self.orosyNavigationController?.pushViewController(vc, animated: true)
                }
            }
        case .PAYMENT:
            waitIndicator.startAnimating()

            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "PaymentInfoVC") as! PaymentInfoVC
                    self.orosyNavigationController?.pushViewController(vc, animated: true)
                }
            }
            
        case .INFORMATION:
            break
        case .PASSWORD_CHANGE:
            break
            
        case .TERMS_OF_SERVICE_BUYER:
            if let url = URL(string: termsForBuyerURL) {
                let safariViewController = SFSafariViewController(url: url)
                present(safariViewController, animated: false, completion: nil)
                self.orosyNavigationController?.sendAccessLog(modal:true, targetUrl:termsForBuyerURL)
            }
        case .PRIVACY_POLICY:
            if let url = URL(string: privacyPlicyURL) {
                let safariViewController = SFSafariViewController(url: url)
                present(safariViewController, animated: false, completion: nil)
                self.orosyNavigationController?.sendAccessLog(modal:true, targetUrl:privacyPlicyURL)
            }
            
        case .LOGOUT:
            logout()

        case .SEND_LOG:
            sendLog()
            
        case .DELIVERY_PLACE:
            // 配送先情報画面へ遷移
            let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "DeliveryPlaceListVC") as! DeliveryPlaceListVC
            vc.navigationItem.leftItemsSupplementBackButton = true

            self.orosyNavigationController?.pushViewController(vc, animated: true)
        
        case .RETIRE_ACCOUNT:
            
            openConfirmVC(title:"アカウントを削除", message:"orosyから退会してアカウントを削除します。\nよろしいですか？", mainButtonTitle:"削除", cancelButtonTitle:"キャンセル")
        
        case .POINT:
            
            waitIndicator.startAnimating()

            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "AccountSB", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "PointHistoryVC") as! PointHistoryVC
                    self.orosyNavigationController?.pushViewController(vc, animated: true)
                }
            }
                    
        default:
            print("nothing to do")
        }
    
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func resetPersonalData() {

        g_MyId = nil
        ProfileDetail.shared.reset()        // アカウントのプロフィール情報
        g_userLog = nil
        
        UserDefaultsManager.shared.reset()

        
        let refresh = Notification.Name(NotificationMessage.Reset.rawValue)     // 各ビューへ初期状態へ戻すように指示する
        NotificationCenter.default.post(name: refresh, object: nil)
        
    }
    
    func logout() {
        
        if g_loginMode {
            if !logoutExec {
                logoutExec = true
                
                if g_userLog != nil {
                    g_userLog.logout()
                }

                OrosyAPI.signOut() { completion in
                    g_processManager.allStop()
                    
                    self.resetPersonalData()
                    self.confirmAlert(title: "", message: "ログアウトしました", ok: "確認") { completion in
                        let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
                        if let vc = storyboard.instantiateInitialViewController() {
                            (UIApplication.shared.delegate as! AppDelegate).setRootViewController(viewControllerName: vc)       // ルート画面へ戻る
                        }
                        UserDefaultsManager.shared.appInitiated = false
                        UserDefaultsManager.shared.updateUserData()
                        g_loginMode = false
                        self.logoutExec = false
                        RetailerDetail.shared.reset()
                        ProfileDetail.shared.reset()
                    }
                }
            }
        }else{
            let storyboard = UIStoryboard(name: "InitialSB", bundle: nil)
            if let vc = storyboard.instantiateInitialViewController() {
                (UIApplication.shared.delegate as! AppDelegate).setRootViewController(viewControllerName: vc)       // ルート画面へ戻る
            }

        }

    }
    
    //
    let receipientAddress = "watchbase@gmail.com"
    var sendLogMode = false
    
    func sendLog() {
        
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setSubject("Orosyのログデータ")
            mailComposer.setToRecipients([receipientAddress])
            if let fileData = LogUtil.shared.getLogData() {
            
                mailComposer.addAttachmentData(fileData, mimeType: "capplication/sv", fileName: "log.text")
                mailComposer.setMessageBody("データは添付ファイルに入っています。", isHTML: false)
            
                sendLogMode = true
                present(mailComposer, animated: true)
            }
        }else{
            confirmAlert(title: "メールを送信できません", message: "iPhoneの設定アプリでメールを送信できるように設定してください。", ok: "確認")
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        switch result {
        case MFMailComposeResult.sent:
            controller.dismiss(animated: true)
            if !sendLogMode {
                openConfirmVC(title:"アカウントを削除", message:"アカウントの削除を承りました。アカウントは最大14日以内に削除されます", mainButtonTitle:"確認")
                retireRequested = true
            }
        default:
            controller.dismiss(animated: true)
            break
        }
        
    }

    var retireRequested = false
    
    func send_retire_request() {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setSubject("アカウント削除希望")
            mailComposer.setToRecipients(["support@orosy.com"])   //
   
            let email = KeyChainManager.shared.load(id:.loginId) ?? ""
            mailComposer.setMessageBody("ID:\(email)", isHTML: false)
            present(mailComposer, animated: true)
            
        }else{
            confirmAlert(title: "メールを送信できません", message: "iPhoneの設定アプリでメールを送信できるように設定してください。", ok: "確認")
        }
    }
    
    func openConfirmVC(title:String, message:String, mainButtonTitle:String, cancelButtonTitle:String? = nil) {

          let storyboard = UIStoryboard(name: "AlertSB", bundle: nil)
          let vc = storyboard.instantiateViewController(withIdentifier: "ConfirmVC") as! ConfirmVC
          vc.message_title = title
          vc.message_body = message
          vc.mainButtonTitle = mainButtonTitle
          vc.cancelButtonTitle = cancelButtonTitle
          vc.delegate = self

          self.present(vc, animated: true, completion: nil)

      }
      
    
    func selectedAction(sel: Bool) {
        if sel {
            if retireRequested {
                logout()
            }else{
                send_retire_request()
            }
        }
    }
    /*
    @objc func closeView() {
        self.orosyNavigationController?.popViewController(animated: true)
    }
     */
    @IBAction func showPointHistory(_ sender: Any) {
    }
}
