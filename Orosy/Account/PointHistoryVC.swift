//
//  PointHistoryVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/10/11.
//

import UIKit
import SafariServices

class PointHistoryVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var pointExplanation: UILabel!
    @IBOutlet weak var MainTableView:UITableView!
    
    var creditHistory:[CreditData] = []
    var profileDetailBank:ProfileDetailBank?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.setNaviTitle(title: "ポイント履歴")
        
        if #available(iOS 15.0, *) {
            MainTableView.sectionHeaderTopPadding = 0.0 // iOS15から追加された、セクションヘッダーの上のスペースを消す
        }
  
    }
    
    override func viewWillAppear(_ animated: Bool) {

        creditHistory = CreditHistory().getData()
        profileDetailBank = ProfileDetailBank()
        _ = profileDetailBank?.getData()
        
        MainTableView.reloadData()
              
        self.pointExplanation.text = "ポイント付与・利用履歴を表示いたします。1ポイントあたり1円でご利用できます。ポイントは支払い時に自動的に全額使用されます。"
        
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "POINT_HEADER_CELL")!
        let pointValue = cell.viewWithTag(2) as! OrosyLabel20
        pointValue.text = String(profileDetailBank?.profileDetail?.credit ?? 0) + "pt"
        let contentView = cell.contentView
        contentView.roundCorner(cornerRadius: 4, lower: false)
        
        return contentView
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension //自動設定
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  creditHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        
        // ポイント履歴
        let cell = tableView.dequeueReusableCell(withIdentifier: "POINT_HISTORY_CELL", for: indexPath)

        
        if row == 0 {
            cell.roundCorner(cornerRadius: 4, lower: false)
        }else if row == creditHistory.count - 1 {
            cell.roundCorner(cornerRadius: 4, lower: true)
        }else{
            cell.roundCorner(cornerRadius: 0)
        }
        cell.clipsToBounds = true
        
        if row < creditHistory.count {
            let credit = creditHistory[row]
            if let dateLabel = cell.viewWithTag(1) as? UILabel {
                dateLabel.text = Util.formattedDate(credit.createdAt)
            }
            if let memoLabel = cell.viewWithTag(2) as? UILabel {
                memoLabel.text = credit.creditDescription
            }
            if let pointLabel = cell.viewWithTag(3) as? UILabel {
                pointLabel.text = Util.number2Str(NSNumber(value: credit.additionalCredits))
            }
 
        }
        
        return cell
    }
    
    
    
    

}
