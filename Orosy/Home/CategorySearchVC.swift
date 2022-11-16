//
//  SearchViewController.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/09.
// カテゴリ検索用メニュー生成

import UIKit

protocol CategorySelectedDelegate: AnyObject {
    func categorySelected(category:Category, waitIndicator:UIActivityIndicatorView? )
}

class CategorySearchVC: OrosyUIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var searchResultView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var menuToButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var waitIndigator: UIActivityIndicatorView!
    
    var categoryMenuTableView: UITableView!
    var delegate:CategorySelectedDelegate? = nil

    var setCategoryList:[Category] = [] {
        didSet {
            categoryList = setCategoryList
            setupView()
        }
    }
  
    var categoryList:[Category] = []
    var expand:[Bool] = []      // セクションヘッダの開閉状態
    let sectionHeight = 50.0    // セクションヘッダの高さ
    
    var items:[Item] = []
    var categoryMenuHeight:CGFloat!
    
    var timer:Timer?

    
    func setupView() {
        // 先頭に「全商品」を追加
        if let category = Category(title:"全商品") {
            categoryList.insert(category, at: 0)
        }
        // メニューを全てクローズにセット
        expand = []
        for _ in categoryList {     // +1は「全商品」用
            expand.append(false)
        }
        categoryMenuTableView.reloadData()
    }


    func numberOfSections(in tableView: UITableView) -> Int {
        return categoryList.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        return sectionHeight
    }

    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        var view:UIView? = nil
        
        view = UIView.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: tableView.frame.size.width, height: sectionHeight)))
        view?.backgroundColor = .white
   
        let label = OrosyLabel14(frame: CGRect(origin: CGPoint(x: 30, y: 5), size: CGSize(width: tableView.frame.size.width , height: sectionHeight)))
        label.textColor = UIColor.orosyColor(color: .Black600)
        label.backgroundColor = UIColor.clear
        view!.addSubview(label)

   
        let button = UIButton(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: tableView.frame.size.width, height: sectionHeight)))
        button.addTarget(self, action: #selector(sectionTitlePushed(_:)), for:.touchUpInside)
        button.tag = section
        view!.addSubview(button)
        
        let category = categoryList[section]
        label.text = category.name
        
        if !category.isHome() {
            let openButton = UIButton(frame: CGRect(origin: CGPoint(x: tableView.frame.size.width - 50, y: 6), size: CGSize(width: 40, height: 40)))
            openButton.setImage(UIImage(named: "expand_more"), for: .normal)
            openButton.setImage(UIImage(named: "close_more"), for: .selected)
            openButton.isSelected = expand[section]
            openButton.isUserInteractionEnabled = false

            view!.addSubview(openButton)
        }
        
        // separator line
        if section != 0 {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 1, width: view!.frame.size.width, height: 1))
            imageView.backgroundColor = UIColor.orosyColor(color:.Gray200)
            view!.addSubview(imageView)
        }
        
        return view
        
    }
    

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // viewForFooterInSection　を使わないと、高さは指定できない
        return (expand[section]) ? 15 : 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let view = UIView.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: tableView.frame.size.width, height: sectionHeight)))
        view.backgroundColor = .white

        return view
    }
    
    var pre_expanded_index:Int = -1
    var last_expanted_index:Int = -1
    var searching = false
    
    @objc func sectionTitlePushed(_ button:UIButton!) {
        
     //   if searching { return }
        
        searching = true
        let section = button.tag
        
        let category = categoryList[section]
        // 先頭にある「全商品」を選択した場合
        if category.isHome() {
            self.categorySelected(categoryList[0])
        }
        
        if category.children.count == 0 { return } // 中分類が存在しないのなら何もしない
            
        // 以下のコードは、中分類の選択を可能とする場合
        expand[section] = !expand[section]

        categoryMenuTableView.performBatchUpdates({
            self.categoryMenuTableView.reloadSections(IndexSet(integer: section), with: .none)
            
        }) { (finished) in
            
            /* 前に開いていたセクションを閉じる
            if self.pre_expanded_index >= 0 && self.pre_expanded_index != section {
                
                self.expand[self.pre_expanded_index] = false
                
                self.categoryMenuTableView.performBatchUpdates({
                    self.categoryMenuTableView.reloadSections(IndexSet(integer: self.pre_expanded_index), with: .none)
                }) { (finished) in
                    self.searching = false
                }
                 
            }else{
                self.searching = false
            }
            if self.expand[section] { self.pre_expanded_index = section }
             */
        }

        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    let LARGE_CATEGORY_SUPPORT = true
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var count = 0
        
        if expand[section] {
            count = categoryList[section].children.count + ((LARGE_CATEGORY_SUPPORT) ? 1 : 0)
        }else{
            count = 0
        }

        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell!

        let row = indexPath.row
        let section = indexPath.section
        
        var category:Category!
        if LARGE_CATEGORY_SUPPORT && row > 0 {
            category = categoryList[section].children[row - 1]
        }else{
            category = categoryList[section].children[row]
        }
        
        cell = tableView.dequeueReusableCell(withIdentifier: "CategoryListCell", for: indexPath)
        
        // 選択された時のバックグランドカラー
        cell.selectionStyle = .default
        
        let view = UIView(frame:cell.frame)
        view.backgroundColor = UIColor.orosyColor(color: .Gray300)
        cell.selectedBackgroundView = view   
        
        let title = cell.viewWithTag(1) as! UILabel
        if LARGE_CATEGORY_SUPPORT && row == 0 {
            title.text = "全ての\(categoryList[section].name ?? "")"
        }else{
            title.text = category.name
        }
    
        return cell
    }
  
    var categoryItems:CategoryItems!
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        let section = indexPath.section

        last_expanted_index = section
        LogUtil.shared.log("didSelectRowAt")


        //
        if self.LARGE_CATEGORY_SUPPORT {
   
            var wid:UIActivityIndicatorView? = nil
            if let cell = tableView.cellForRow(at: indexPath) {
                wid = cell.viewWithTag(10) as? UIActivityIndicatorView  // 使っていない
            }

            if row == 0 {
                let category:Category = self.categoryList[section]
                category.isLargeKey = true
                self.categorySelected(category, waitIndicator:wid)
            }else{
                let category:Category = self.categoryList[section].children[row - 1]
                category.isLargeKey = false
                self.categorySelected(category, waitIndicator:wid)
            }
            
        }else{
            let category:Category = self.categoryList[section].children[row]
            category.isLargeKey = false
            self.categorySelected(category)
        }

        // バックグランドカラーを消す
        if let view = tableView.cellForRow(at: indexPath)?.selectedBackgroundView {
            view.alpha = 0
        }
    }

    func categorySelected(_ category:Category, waitIndicator:UIActivityIndicatorView? = nil) {

        LogUtil.shared.log("category Selected")
        
        DispatchQueue.global().async {
            
            self.delegate?.categorySelected(category:category, waitIndicator: waitIndicator)

            // 最後に選択されていたもの以外を閉じる
            for exp in 0..<self.expand.count {
                if exp != self.last_expanted_index {
                    self.expand[exp] = false
                }
            }
            DispatchQueue.main.async {
                self.categoryMenuTableView.reloadData()
            }
        }
        
    }

}
