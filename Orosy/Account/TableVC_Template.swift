//
//  TableVC_Template.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/05/23.
//

import UIKit



class TemplateVC: OrosyUIViewController, UITableViewDataSource, UITableViewDelegate  {
    

    @IBOutlet weak var MainTableView: UITableView!

    enum ItemType {
        
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
        
    }

    class DisplayItem: NSObject {
        var itemType:ItemType?
        var inputStr:String?
        var title:String?
        var placeholder:String?
        var cellType:String?
        var itemObject: NSObject?
        var itemHeight:CGFloat
        var validationType:ValidationType!
        var error:Bool = false
        
        
        init( type:ItemType, title:String?, placeholder:String? = nil, cell:String?, height:CGFloat = 0, validationType:ValidationType = .None ,inputStr:String? = nil ) {
            
            self.itemType = type
            self.title = title
            self.placeholder = placeholder
            self.cellType = cell
            self.itemHeight = height
            self.validationType = validationType
            self.inputStr = inputStr
        }
    }
    
    /*
        UITableViewのセクションごとに表示する項目の定義
        タイプによって使用するCELLのデザインなどが異なる
    */
    
    var itemList:[String:Any] =
        [
                "TITLE" : "アカウント",
                "DATA" : [
                DisplayItem(type: ItemType.PROFILE, title: "プロフィール情報", cell:"AccountCell", height:44),
                ]
        ]
    
    
    override func viewDidLoad() {

        self.setNaviTitle(title: "")
        
        if #available(iOS 15.0, *) {
            MainTableView.sectionHeaderTopPadding = 0.0 // iOS15から追加された、セクションヘッダーの上のスペースを消す
        }
  
        navigationItem.setRightBarButtonItems(nil, animated: false) // ProductListVCを継承しているのでシェアボタンが表示されるのを消す
        

        let headerView = UIView(frame:CGRect(x:0, y:0, width:100, height:20))
        headerView.backgroundColor = UIColor.orosyColor(color: .Background)
        MainTableView.tableHeaderView = headerView
        MainTableView.tableFooterView = headerView
        MainTableView.reloadData()

    }
    

    func numberOfSections(in: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension //自動設定
        
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        let display_data = itemList["DATA"] as! [DisplayItem]
        
        count = display_data.count
        
        return count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let row = indexPath.row
        
        let display_data = itemList["DATA"] as! [DisplayItem]
        let row_data = display_data[row]
 
        let cell = tableView.dequeueReusableCell(withIdentifier: row_data.cellType!, for: indexPath)
        let titleLabel = cell.viewWithTag(1) as! UILabel
        let valueLabel = cell.viewWithTag(2) as! UILabel
        valueLabel.text = ""
        
        titleLabel.text = row_data.title
        
        let itemType = row_data.itemType
        switch itemType {

            
        default:
            print("nothing to do")
        }
        
        return cell
    }
    
    var logoutExec = false
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row

        let display_data = itemList["DATA"] as! [DisplayItem]
        let row_data = display_data[row]
    
        let itemType = row_data.itemType
        
        switch itemType {

        default:
            print("nothing to do")
        }
    
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
