//
//  SupplierVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/15.
//  サプライヤページ
//　商品一覧は、 ProductListVC　で制御している

import UIKit
import SafariServices
import WebKit

enum SupplierItemType {
    case TITLE
    case BASIC_INFO
    case SEPARATOR
    case CAMPAIGN_INFO
    case BUTTONS
    case PRODUCTS       // お気に入りでは　これだけしか使っていない
}


class SupplierDisplayItem: NSObject {
    
    var itemType:SupplierItemType?
    var title:String?
    var cellType:String?
    var itemObject: NSObject?
    var itemHeight:CGFloat
    

    init( type:SupplierItemType, title:String?, cell:String?, height:CGFloat ) {
        
        itemType = type
        self.title = title
        cellType = cell
        itemHeight = height
    }
}


class SupplierVC: ProductListVC {
    
    @IBOutlet weak var webView: WKWebView!


    enum BasicInfo {
        case CENCEPT
        case CUSTOMERS
        case COMMITMENT
        case HP
        case SNS
        case OTHERSITE
        case OWNER
    }
    
    var campaignMessage:NSMutableAttributedString?
    
    func getItemidForPageUrl() -> String {

        return supplier?.id ?? ""

    }
    
    override func viewDidLoad() {
        
        LogUtil.shared.log ("サプライヤー画面")
        super.viewDidLoad()
        
        self.setNaviTitle(title: supplier?.brandName ?? "")
     
        displayItemList =
        [
            SupplierDisplayItem(type: .TITLE, title: "タイトル", cell:"TitleCell", height:0),
            SupplierDisplayItem(type: .BASIC_INFO, title: "基本情報", cell:"BasicInfoCell", height:500),
            SupplierDisplayItem(type: .SEPARATOR, title: "セパレータ", cell:"SeparatorCell", height:10),
            SupplierDisplayItem(type: .CAMPAIGN_INFO, title: "キャンペーン情報", cell:"CampaignCell", height:44),
            SupplierDisplayItem(type: .BUTTONS, title: "ボタン", cell:"ButtonCell", height:0),
            SupplierDisplayItem(type: .PRODUCTS, title: "商品一覧", cell:"ProductCell", height:0 )   // 商品数に応じて行数が変わる
        ]

        mainTabelTopConstraint.constant = 0
        
        /*
        if g_loginMode && connectionStatus  == nil {
            confirmAlert(title: "エラー", message: NSLocalizedString("DataDoesNotExist", comment: ""), ok: "確認")
            self.navigationController?.popViewController(animated: true)
        }
        */
        var homeUrl:String?
        
        for url in supplier?.urls ?? [] {
            if url.category == SocialURLType.Home {
                homeUrl = url.url
            }
        }
        
        basicItems = [ ["InfoType":BasicInfo.CENCEPT, "Value":supplier?.concept ?? ""], ["InfoType":BasicInfo.CUSTOMERS, "Value":supplier?.customerBase ?? ""], ["InfoType":BasicInfo.COMMITMENT, "Value":supplier?.commitment ?? ""], ["InfoType":BasicInfo.HP,  "Value":homeUrl as AnyObject]]
        
        if (supplier?.urls.count ?? 0) > 0 {
            for sns in supplier?.urls ?? []  {
                if sns.category != .Others && sns.category != .Home && sns.url != nil && sns.url != "" {
                    basicItems.append(["InfoType":BasicInfo.SNS, "Value":supplier?.urls ?? []])
                    break
                }
            }
        }
        
        for sns in supplier?.urls ?? []  {
            if sns.category == .Others {
                basicItems.append(["InfoType":BasicInfo.OTHERSITE, "Value":sns.url as AnyObject])   // その他のサイトがあれば追加
                break
            }
        }
        
        basicItems.append(["InfoType":BasicInfo.OWNER, "Value":supplier?.companyName ?? ""])
        
        // 最初に表示する分の画像をプリフェッチしておく
        var max = itemParents.count
        if max > 6 { max = 6 }
        for ip in 0..<max {
            let itemParent = itemParents[ip]
            if let _ = itemParent.item {
                OrosyAPI.cacheImage(itemParent.imageUrls.first, imagesize: .Size100)
            }
        }
        
        if let config = AppConfigData.shared.config {
            
            if let cmessage = config["CampaignMessage"] as? [String:[String:Any]] {
                if let brandPageMessage = cmessage["BrandPageMessage"] {
                    var fontSize = brandPageMessage["FontSize"] as? CGFloat ?? 12
                    if UIDevice.current.userInterfaceIdiom == .pad { fontSize += 4 }
                    campaignMessage = Util.makeAttributedText(message:brandPageMessage["Message"] as? String ?? "" , fontSize:fontSize, textColor:.Red)
                }
            }
        }

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(favoriteReset), name: Notification.Name(rawValue:NotificationMessage.FavoriteReset.rawValue), object: nil)
        nc.addObserver(self, selector: #selector(refreshStatus), name: Notification.Name(rawValue:NotificationMessage.RefreshApplyStatus.rawValue), object: nil)
        nc.addObserver(self, selector: #selector(reset), name: Notification.Name(rawValue:NotificationMessage.Reset.rawValue), object: nil)
 
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
      //  _ = g_userLog.sendAccessLog(pageUrl: self.orosyNavigationController?.pageUrl, pageId:supplier?.id ?? ""  ,referer: self.orosyNavigationController?.referer)
        
    }
    @objc func reset() {
        DispatchQueue.main.async{
            self.navigationController?.popToRootViewController(animated: false)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // 基本情報のみ折りたたむので高さを変える。それ以外は自動設定
        
        let section = indexPath.section
        let item = displayItemList[section]
        let itemType = item.itemType
        
        if itemType == .BASIC_INFO {
            return (basicInfoOpen) ? UITableView.automaticDimension : 0
        }else if itemType == .CAMPAIGN_INFO {
            return (campaignMessage != nil) ? UITableView.automaticDimension : 0
        }else{
            return UITableView.automaticDimension //自動設定
        }
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        if tableView != MainTableView { return 0 }
        
        var count = 1
        
        let item = displayItemList[section]
        let itemType = item.itemType

        if itemType == .PRODUCTS {
            count = super.tableView(tableView, numberOfRowsInSection: section)
        }

        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        if tableView != MainTableView { return UITableViewCell() }
        
        var cell:UITableViewCell!
        
       // let row = indexPath.row
        let section = indexPath.section
        let row = indexPath.row
        
        let item = displayItemList[section]
        let itemType = item.itemType
        cell = tableView.dequeueReusableCell(withIdentifier: item.cellType!, for: indexPath)
        
        cell.selectionStyle = .none
        
        switch itemType {
        
        case .TITLE:
            let conceptImageView = cell.contentView.viewWithTag(1) as! OrosyUIImageView
            conceptImageView.getImageFromUrl(url: supplier?.coverImageUrl)
            conceptImageView.drawBorder(cornerRadius: 0)
            
            let imageView = cell.contentView.viewWithTag(2) as! OrosyUIImageView    // サプライヤーアイコン
            imageView.targetRow = row
            imageView.getImageFromUrl( row:row, url: supplier?.iconImageUrl)                  // rowは使わない
            print(imageView.bounds.width)
            imageView.drawBorder(cornerRadius:imageView.bounds.width / 2)           // 丸く切り取る
            
            let circleBack = cell.contentView.viewWithTag(12) as! OrosyUIImageView
            circleBack.drawBorder(cornerRadius:circleBack.bounds.width / 2)         // 丸い背景
            
            let brandNameLabel = cell.contentView.viewWithTag(4) as! UILabel
            brandNameLabel.text = supplier?.brandName

            openCloseButton = cell.contentView.viewWithTag(10) as? UIButton
            openCloseButton.setTitle("", for: .normal)
            
            let stackView = cell.contentView.viewWithTag(3) as! UIStackView

            var count = supplier?.imageUrls.count ?? 0

            if count > 3 {
                count = 3
            }
            
            for ip in 0..<count {
                let url = supplier?.imageUrls[ip]
                let pimageView = stackView.viewWithTag(ip + 11) as! OrosyUIImageView
               // pimageView.image = nil
                pimageView.targetRow = ip
                pimageView.getImageFromUrl(row: ip, url: url)
                pimageView.drawBorder(cornerRadius: 0)
            }
            let pimageView = stackView.viewWithTag(3 + 11) as! OrosyUIImageView
            pimageView.drawBorder(cornerRadius: 0, color: .clear, width: 0)
            
        case .BASIC_INFO:
            basicInfoCell = cell
            
          //  var ip:Int = 1
            for basicItem in basicItems {
                let infoType = basicItem["InfoType"] as! BasicInfo
                
                if infoType == .OTHERSITE {
                    let mainStack = cell.viewWithTag(1000) as! UIStackView  // 一番外側のStack
                    
                    if mainStack.viewWithTag(999) == nil {  // なければ追加する
                        
                        let stackSubView = UIStackView(frame: CGRect(x:0,y:0, width:mainStack.bounds.width, height:34))
                        stackSubView.axis = .vertical
                        stackSubView.tag = 999
                        let frame = stackSubView.frame
                        let title = UILabel(frame:frame)
                        title.text = "その他サイト"
                        title.font = UIFont(name: OrosyFont.Bold.rawValue, size: 14)
                        stackSubView.addArrangedSubview(title)
                        
                        var idx = 0
                        var stackCount = 0
                        var view:UIView!
                        for sns in supplier?.urls ?? [] {
                            if sns.category == .Others {
                                
                                if stackCount == 0 {
                                    view = UIView()
                                    view.tag = 99
                                }
                                
                                let labelFrame = CGRect(x:0, y:CGFloat(stackCount) * 25, width:frame.size.width, height:25)
                                let valueLabel = OrosyLabel14(frame:labelFrame)
                                valueLabel.textColor = UIColor.orosyColor(color: .Blue)
                                valueLabel.text = sns.url ?? ""
                                valueLabel.adjustsFontSizeToFitWidth = false
                                view.addSubview(valueLabel)
                                
                                let button = UIButton(frame:labelFrame)
                                button.setImage(UIImage(named:sns.category.rawValue), for: .normal)
                                button.addTarget(self, action: #selector(snsPushed ), for: .touchUpInside)
                                button.tag = 200 + idx
                                view.addSubview(button)
                                
                                stackCount += 1
                                
                            }
                            idx += 1
                        }
                        
                        if stackCount > 0 {
                            let viewHeight = CGFloat(stackCount) * 25.0
                            view.heightAnchor.constraint(equalToConstant: viewHeight).isActive = true
                            stackSubView.addArrangedSubview(view)
                            stackSubView.heightAnchor.constraint(equalToConstant:viewHeight + 40 ).isActive = true
                        }
                        mainStack.insertArrangedSubview(stackSubView, at:5)
                    }
                    
                }else{
                    
                    switch infoType {

                    case .HP: // ホームページ
                        let stackView = cell.contentView.viewWithTag(4) as! UIStackView
                        if let valueLabel = stackView.viewWithTag(12) as? UILabel {
                            valueLabel.text =   basicItem["Value"] as? String
                        }
                        if let button = stackView.viewWithTag(100) as? UIButton {
                            button.addTarget(self, action: #selector(snsPushed ), for: .touchUpInside)
                        }
                    case .SNS: //  SNS
                        let stackView = cell.contentView.viewWithTag(5) as! UIStackView
                        var idx = 0
                        var buttonIdx = 0
                        for sns in supplier?.urls ?? [] {
                            if sns.category != .Others && sns.category != .Home && sns.url != nil && sns.url ?? "" != "" {
                               // 定義済みのSNSならSNSのアイコン（ボタン）を表示する
                               // let hr_stackView = stackView.viewWithTag(50) as! UIStackView
                                if let button = stackView.viewWithTag(20 + buttonIdx) as? UIButton {
                                    button.setImage(UIImage(named:sns.category.rawValue), for: .normal)
                                    button.contentMode = .center
                                    button.imageView?.contentMode = .scaleAspectFit
                                    button.addTarget(self, action: #selector(snsPushed ), for: .touchUpInside)
                                    button.tag = idx

                                    buttonIdx += 1
                                }
                            }
                            idx += 1
                        }
                    case .OWNER:
                        let stackView = cell.contentView.viewWithTag(6) as! UIStackView
                        if let valueLabel = stackView.viewWithTag(12) as? UILabel {
                            valueLabel.text =  basicItem["Value"] as? String
                        }
                    
                    case .CENCEPT:
                        let stackView = cell.contentView.viewWithTag(1) as! UIStackView
                        if let valueLabel = stackView.viewWithTag(12) as? UILabel {
                            valueLabel.text =  basicItem["Value"] as? String
                        }
                        
                    case .CUSTOMERS:
                        let stackView = cell.contentView.viewWithTag(2) as! UIStackView
                        if let valueLabel = stackView.viewWithTag(12) as? UILabel {
                            valueLabel.text =  basicItem["Value"] as? String
                        }
                        
                    case .COMMITMENT:
                        let stackView = cell.contentView.viewWithTag(3) as! UIStackView
                        if let valueLabel = stackView.viewWithTag(12) as? UILabel {
                            valueLabel.text =  basicItem["Value"] as? String
                        }
                    default:
                        break
                    }
                }
            }
        
        case .BUTTONS:
            
            let sendMessageButton = cell.contentView.viewWithTag(6) as! OrosyButton
            var buttonTitle:String!
            
                
            if let status = connectionStatus {
                if status == .ACCEPTED {
                    buttonTitle = NSLocalizedString("SendMessage", comment: "")
                    sendMessageButton.backgroundColor = UIColor.orosyColor(color: .Blue)
                                    
                }else if status == .REQUEST_PENDING || status == .REQUESTED {
                    buttonTitle = "申請中"
                    sendMessageButton.isEnabled = false
                    sendMessageButton.backgroundColor = UIColor.orosyColor(color: .Gray100)

                }else{
                    buttonTitle = NSLocalizedString("ShowHolesalePrice", comment: "")
                    sendMessageButton.backgroundColor = UIColor.orosyColor(color: .Blue)
                }
            }else{
                buttonTitle = NSLocalizedString("ShowHolesalePrice", comment: "")
                sendMessageButton.backgroundColor = UIColor.orosyColor(color: .Blue)
            }

            
            sendMessageButton.setButtonTitle(title: buttonTitle, fontSize: 14)
            
            let countLabel = cell.contentView.viewWithTag(10) as! UILabel
            countLabel.text = (itemParents.count > 0 ) ? "商品一覧" : ""   // 表示する商品がない場合にはタイトルを非表示にする
            

        case .PRODUCTS:
            cell = super.tableView( tableView ,cellForRowAt: indexPath)
            
        case .CAMPAIGN_INFO:
            if let label = cell.viewWithTag(1) as? UILabel {
                label.attributedText = campaignMessage
            }
        default:
            break
        }

        return cell
    }
    
    
    // お気に入りが更新されたという通知を受けた
    @objc func favoriteReset(notification: Notification) {
        
        guard let userInfo = notification.userInfo else { return }

        if let updatedItemParent = userInfo["itemParent"] as? ItemParent {
            let onOff = userInfo["onOff"] as? Bool ?? false  // true: お気に入りに入れた
                // 今表示しているのと同じならアップデートする
                
            for itemParent in itemParents {
                if updatedItemParent.id == itemParent.id {
                    itemParent.isFavorite = onOff
                    MainTableView.reloadData()
                    break
                }
            }
        }
    }

    //　取引申請状態が変化した（取引を申し込んだ）
    @objc func refreshStatus(notification: Notification) {
        DispatchQueue.main.async {
            _ = self.supplier?.getTradeConnection()
            
            self.connectionStatus = self.supplier?.tradeConnection?.status
            self.MainTableView.reloadData()
        }
    }
    
}

