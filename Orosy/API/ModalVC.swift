//
//  ModalVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/10/08.
//

import UIKit
import SafariServices

enum modalDisplayMode {
    case PointCampaign
}

var displayMode:modalDisplayMode = .PointCampaign




class ModalVC:UIViewController {
    
    
    @IBAction func closeCampaignHelp() {
        
        self.dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        
        switch displayMode {
            
        case .PointCampaign:
            if let titleLabell = self.view.viewWithTag(1) as? UILabel {
                titleLabell.text = "初めて仕入れるブランドがお得"
            }
            if let line1 = self.view.viewWithTag(2) as? UILabel {
                line1.text = "1.購入代金の20％をポイントで還元（上限10,000円還元）"
            }
            if let line1_1 = self.view.viewWithTag(3) as? UILabel {
                line1_1.text =
                """
                対象ブランド：初めてご購入される全てのブランド
                ポイント還元対象金額：購入商品代金(税金,送料を除きます)の20%
                ポイント還元上限：10,000ポイント/1ブランド
                ポイント還元日：購入日より10日以内に付与
                """
            }
            if let line2 = self.view.viewWithTag(4) as? UILabel {
                line2.text = "2.売れ残った場合、発注時から60日間返品可能"
            }
            if let button = self.view.viewWithTag(5) as? OrosyButton {
                button.setButtonTitle(title: "さらに詳しくはこちら", fontSize: 12)
            }
        }
        
    }
    
    
    @IBAction func popupExplain(_ sender: Any) {
        
        if let url = URL(string: "https://announcekit.co/orosy/feed/chu-metegou-ru-suruburandohafan-pin-ke-neng-20-pointohuan-yuan-4ge4N2") {
            
            let safariViewController = SFSafariViewController(url: url)
            present(safariViewController, animated: false, completion: nil)
        }
    }
 
    
    
}
