//
//  PopupRestrictionVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/23.
//

import UIKit
import SafariServices

class PopupRestrictionVC: UITableViewController {
    
    // 外部から渡されるパラメータ
    var restrictionMode:Bool = false
    
    var supplier:Supplier! {
        didSet {
   
            if let restrictions = supplier.restrictions {
                restrictionsValues = [isAllow(restrictions.ecSales), isAllow(restrictions.reprintImages), isAllow(restrictions.dropShipping), true]
            }
        }
    }
    
    
  //  let urlOfcontractPdf = "https://d1nq137rziic2i.cloudfront.net/u/6030b5ec-cd6b-4d05-a51e-777745126c07/p/terms/087d7b58-963c-434b-a48c-e362f4c6eca8.pdf"
    
    let titleStringsForRestriction = [
        "ECサイトでの販売", "画像の転載", "ドロップシッピング対応", "その他の条件"
    ]
    var restrictionsValues:[Bool] = []
    
    let headerHeightForRestriction:CGFloat = 60
    let footerHeightForRestriction:CGFloat = 120
    let headerHeightForShippingFee:CGFloat = 60
    let fotterHeightForShippingFee:CGFloat = 40
    
    var campaignTitle:NSMutableAttributedString?
    var campaignMessage:NSMutableAttributedString?
    
    func isAllow(_ flag:String? ) -> Bool {
        return (flag != nil && flag == "allow")
    }
    
    func getItemidForPageUrl() -> String {
        return supplier.id
    }
    
    override func viewDidLoad() {
        
        self.tableView.layer.cornerRadius = 10
        self.tableView.layer.borderColor = UIColor.lightGray.cgColor
        self.tableView.layer.borderWidth = 1
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
         }
        
        if let config = AppConfigData.shared.config {
            
            if let cmessage = config["CampaignMessage"] as? [String:[String:Any]] {
                if let shippingFeePageMessage = cmessage["ShippingFeeDetailMessage"] {
                    if let ctitle = shippingFeePageMessage["Title"] as? [String:Any] {
                        var fontSize = ctitle["FontSize"] as? CGFloat ?? 12
                        if UIDevice.current.userInterfaceIdiom == .pad { fontSize += 4 }
                        campaignTitle = Util.makeAttributedText(message:ctitle["Message"] as? String ?? "" , fontSize:fontSize, textColor:.Red)
                    }
                    if let cmsg = shippingFeePageMessage["Body"] as? [String:Any] {
                        var fontSize = cmsg["FontSize"] as? CGFloat ?? 12
                        if UIDevice.current.userInterfaceIdiom == .pad { fontSize += 4 }
                        campaignMessage = Util.makeAttributedText(message:cmsg["Message"] as? String ?? "" , fontSize:fontSize, textColor:.Black600)
                    }
                }
            }
        }
    }
    
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var height:CGFloat = 0
        
        if restrictionMode {
            height = headerHeightForRestriction
        }else{
            height = headerHeightForShippingFee
        }

        return height
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        var view:UIView?
        var height:CGFloat!
        var title:String!
 
        if restrictionMode {
            height = headerHeightForRestriction
            title = "商品の販売規制について"
        }else{
            height = headerHeightForShippingFee
            title = "送料（税込）について"
        }
        
        view = UIView.init(frame: CGRect(origin: CGPoint(x: 0,y: 20), size: CGSize(width: tableView.frame.size.width, height: height )))

        let titleLabel = UILabel(frame: CGRect(origin: CGPoint(x:20, y:0), size: CGSize(width: tableView.frame.size.width - 30, height: height)))
        titleLabel.font = UIFont(name: OrosyFont.Bold.rawValue, size: 14)
        titleLabel.textAlignment = .left
        titleLabel.text = title
        view?.addSubview(titleLabel)
        
        let closeButton = UIButton.init(frame: CGRect(origin: CGPoint(x:tableView.frame.size.width - 40, y:10), size: CGSize(width:32, height:32)))
        closeButton.setImage(UIImage(named:"close"), for: .normal)
        closeButton.setTitleColor(.darkGray, for: .normal)
        closeButton.addTarget(self, action: #selector(closeRestrictionsView), for: .touchUpInside)
        
        view?.addSubview(closeButton)
        
        return view
    }
    
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        var view:UIView!
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FooterCell")!
        
        view = cell.contentView
        let title = view.viewWithTag(1) as! OrosyLabel14B
        title.text = ""
        let content = view.viewWithTag(2) as! OrosyLabel12
        content.text = ""
        
        let campaignView = view.viewWithTag(3)!
        let linkLabel = view.viewWithTag(4) as! UILabel
        
        if restrictionMode {
            campaignView.isHidden = true
            linkLabel.isHidden = true
            
            if supplier.tradeConnection?.status == .ACCEPTED && supplier.termFileUrl != nil {
                title.text = "売買契約について"
                content.text = "売買契約をPDFでダウンロード"
            }
            
        }else{
            
            if let rule = supplier.shippingFeeRules.first {
                let price = rule.triggerCount
                print(price)
                if price.isEqual(to: NSDecimalNumber.zero)  {
                   
                }else{
                    title.text = "\(Util.number2Str(price))以上のご購入で送料無料"
                    title.textColor = UIColor.orosyColor(color: .Black600)
                }
            }
            
            if campaignMessage == nil {
                campaignView.isHidden = true
                linkLabel.isHidden = true
            }else{
                campaignView.isHidden = false
                linkLabel.isHidden = false
                
                let campaignTitleLabel = view.viewWithTag(10) as! UILabel
                let campaignMessageLabel = view.viewWithTag(11) as! UILabel
                campaignTitleLabel.attributedText = campaignTitle
                campaignMessageLabel.attributedText = campaignMessage
                
                linkLabel.attributedText = Util.makeAttributedText(message:"ポイントについて詳しくは<b>こちら</b>" , fontSize:13.0, textColor:.Black600)
                
            }
        }
               
        return view
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height:CGFloat = 44
        
        if restrictionMode && indexPath.row == 3 { height = 150 }
        return height
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        if restrictionMode {
            count = titleStringsForRestriction.count
        }else{
            count = supplier.shippingFeeToArea.count
        }

        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell!
        
        let row = indexPath.row
        
        cell = tableView.dequeueReusableCell(withIdentifier: "RestrictionCell", for: indexPath)
        let title1 = cell.contentView.viewWithTag(1) as! UILabel
        let title2 = cell.contentView.viewWithTag(2) as! UILabel
        let title3 = cell.contentView.viewWithTag(3) as! UILabel
        
        if restrictionMode {
            if restrictionsValues.count > 2 {
                title1.text = titleStringsForRestriction[row]
                
                if row == 3 {
                    title2.text = ""
                    title3.text = supplier.otherConditions
                }else{
                    title2.text = (restrictionsValues[row]) ? "許可" : "不可"
                }
            }
        }else{
            let ship = supplier.shippingFeeToArea[row]
            title1.text = ship.name
            title2.text = Util.number2Str(ship.amount)
            title2.textAlignment = .right
        }

        return cell
    }
    
    @IBAction func openContractPdf() {
        
        if restrictionMode {
            guard let url = supplier.termFileUrl else { return }
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: false, completion: nil)
        }else{
            guard let url = URL(string:"https://help.orosy.com/hc/ja/articles/5912277578265-%E3%83%9D%E3%82%A4%E3%83%B3%E3%83%88%E3%81%A8%E3%81%AF-") else { return }
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: false, completion: nil)
        }
    
        
    }
    @objc func closeRestrictionsView(_ sender: Any) {
            self.dismiss(animated: true, completion: nil)
    }
    
}
