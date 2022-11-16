//
//  SearchBarVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/04/22.
//
//  キーワーお検索バーの制御


import UIKit
import SceneKit

protocol SearchBaDelegate: AnyObject {
    func searchExec(searchWord:String, targetMode:HomeDisplayMode, categoryKey: SearchKey?, categoryId:String?)
    func keywordSearching(_ show:Bool)         // 検索ダイアログ表示中
    func setupDisplay(_ _currentMode:HomeDisplayMode)
}

class SearchBarVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var searchBarView: UIView!
    @IBOutlet weak var searchBarImageView: UIImageView!
    @IBOutlet weak var searchBarInputField: OrosyTextField!
    @IBOutlet weak var productModeButton:OrosyButtonWhite!
    @IBOutlet weak var brandModeButton:OrosyButtonWhite!
    @IBOutlet weak var categoryButton: OrosySelectButton!
    @IBOutlet weak var detailButton: OrosySelectButton!
    @IBOutlet weak var viewHiehgtConstraint: NSLayoutConstraint!
    @IBOutlet weak var closeButton: IndexedButton!

    
    enum DisplayMode {
        case CloaseBar           // クローズボタンも隠す
        case SearchBar          // クローズボタン表示
        case TargetSelector
        case LargeCategory
        case DetailCategory
    }
    
    var selectedLargeCategory:Category!
    var selectedDetailCategory:Category!
    var categoryList:[Category] = []
    
    var setCategoryList:[Category] = [] {
        didSet {
            categoryList = setCategoryList
            // 先頭に「全商品」を追加
            if let category = Category(title:"全ての商品") {
                categoryList.insert(category, at: 0)
            }
            
            setupButton()
        }
    }
  
    var isHidden:Bool {
        set {
            self.view.isHidden = newValue
        }
        get {
            return self.view.isHidden
        }
    }
    var text:String {
        set {
            searchBarInputField.text = newValue
        }
        get {
            return searchBarInputField.text ?? ""
        }
    }
    
    var delegate:SearchBaDelegate!
    var isTextEditing = false
    var targetMode:HomeDisplayMode = .KeywordSearchProduct      // 商品一覧、ブランド一覧の切り替え
    var displayMode:DisplayMode = .SearchBar
    var lastDisplayMode:DisplayMode = .LargeCategory            //　商品モード用：最初は「商品」のモードにするので、大カテゴリの選択まで開いておく
    let miniHeight:CGFloat = 54
    
    override func viewDidLoad() {
        
    //    let barImage = UIImage(named:"searchBar")!
    //    let cap = 100
     //   searchBarImageView.image = barImage.stretchableImage(withLeftCapWidth: cap, topCapHeight: cap)
        
        changeMode(.SearchBar)  // 最初は検索バーだけを表示する
        
       // TextFieldLeadingConstraint.isActive = false
        
        productModeButton.isSelected = true
        brandModeButton.isSelected = false
        
        closeButton.setButtonTitle(title: "キャンセル", fontSize:14, color:UIColor.orosyColor(color: .S400))
    }
    
    
    func changeMode(_ _dispplayode:DisplayMode) {
        
        UIView.animate(withDuration: 0.3,  delay: 0.0,  options: [.curveEaseOut],animations: {
            
            switch _dispplayode {
            case .CloaseBar:
                self.viewHiehgtConstraint.constant = 56
                self.searchBarInputField.resignFirstResponder()
            case .SearchBar:
                self.viewHiehgtConstraint.constant = 56
                self.searchBarInputField.resignFirstResponder()
            case .TargetSelector:
                self.viewHiehgtConstraint.constant = 102
            case .LargeCategory:
                self.viewHiehgtConstraint.constant = self.categoryButton.frame.origin.y + self.categoryButton.frame.size.height + 18
            case .DetailCategory:
                self.viewHiehgtConstraint.constant = self.detailButton.frame.origin.y + self.detailButton.frame.size.height + 18
            }
            self.view.layoutIfNeeded()  // これがないとアニメーションしない
            
        }, completion: { (finished: Bool) in
           
        })

        if targetMode == .KeywordSearchProduct && _dispplayode != .CloaseBar && _dispplayode != .SearchBar {
            self.lastDisplayMode = _dispplayode
        }
    }
    
    @IBAction func searchExec() {
        
        if let keyStr = searchBarInputField.text {
            
            if keyStr == "" { return }
                
            if targetMode == .KeywordSearchProduct {
                    
                var cid:String?
                var skey:SearchKey!
                
                if selectedDetailCategory != nil && selectedDetailCategory.id != "" {   // idが""は「全ての商品」
                    // 詳細カテゴリまで指定
                    cid = selectedDetailCategory.id
                    skey = .Middle
                }else{
                    cid = selectedLargeCategory?.id
                    skey = .Large
                }
                
                if cid == "" {
                    cid = nil
                    skey = nil
                }
                
                isTextEditing = false
                self.searchBarInputField.resignFirstResponder()
                changeMode(.SearchBar)  // 検索バーだけを残す
                delegate.searchExec(searchWord:keyStr , targetMode: targetMode, categoryKey: skey, categoryId:cid)
           
            }
            if targetMode == .KeywardSearchBrand {
                
                isTextEditing = false
                self.searchBarInputField.resignFirstResponder()
                changeMode(.SearchBar)  // 検索バーだけを残す
                delegate.searchExec(searchWord:keyStr , targetMode: targetMode, categoryKey: nil, categoryId:nil )


            }
        }

    }
    
    
    // 商品/ブランドの切り替え
    @IBAction func changeTarget(_ button: OrosyButtonWhite) {
        targetMode = (button.tag == 1) ? .KeywordSearchProduct : .KeywardSearchBrand

        if targetMode == .KeywardSearchBrand {
            productModeButton.isSelected = false
            brandModeButton.isSelected = true
            changeMode(.TargetSelector)
            
        }else{
            productModeButton.isSelected = true
            brandModeButton.isSelected = false
            changeMode(lastDisplayMode)
        }
  
    }
    

    // 検索バーのクローズボタンが押されたとき
    @IBAction func closeSearch() {
        
        self.closeSearchBar()
        
        DispatchQueue.main.async {
            self.delegate.setupDisplay(.Home)           // ホームの表示を通常状態へ戻す
        }
    }
    
    func closeSearchBar() {
        DispatchQueue.main.async {
            self.isTextEditing = false
            self.searchBarInputField.text = ""
            self.delegate.keywordSearching(false)       // ゼロデータ表示を消す
            self.searchBarInputField.resignFirstResponder()
            self.changeMode(.CloaseBar)                 // 検索バーをテキスト入力エリアだけにする

        }
    }
    
    @IBAction func deitalChanged(_ sender: Any) {
    
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if isTextEditing {
         
        }else{
            isTextEditing = true
          
            if targetMode == .KeywordSearchProduct {
                changeMode(lastDisplayMode) //　以前の状態へ戻す
            }else{
                changeMode(.TargetSelector)
            }
            delegate.keywordSearching(true)

        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        changeMode(.SearchBar)
        isTextEditing = false
        textField.resignFirstResponder()
        searchExec()
        
        return true
    }
    

    var hasDetailCategory:[String] = []
    
    func setupButton() {
        
        // カテゴリボタンの設定
        if categoryList.count > 0 {
            
            if let config = AppConfigData.shared.config {
                hasDetailCategory = config["LargeCategoryHasDetail"] as? [String] ?? []
            }
            
            if selectedLargeCategory == nil {
                selectedLargeCategory = categoryList.first
            }
            
            //メニュー項目をセット
            var actions = [UIMenuElement]()
            
            for category in categoryList {

                actions.append(UIAction(title: category.name, image: nil, state: category == selectedLargeCategory ? .on : .off, handler: { (_) in
                    self.categoryButton.setTitle(category.name, for: .normal)
                    
                    self.selectedLargeCategory = category
                    self.setupButton()
                    
                    // 詳細カテゴリを選択可能にするかチェック
                    var detailExist = false
                    
                    for categoryName in self.hasDetailCategory {
                        if self.selectedLargeCategory.name == categoryName {
                            self.setDetailButton(parentCategory: self.selectedLargeCategory)
                            detailExist = true
                            break
                        }
                    }
                    
                    if detailExist {
                        self.changeMode(.DetailCategory)
                    }else{
                        self.changeMode(.LargeCategory)
                        self.selectedDetailCategory = nil
                      //  self.searchExec()
                    }
                }))
            }

            if actions.count > 0 {
                // UIButtonにUIMenuを設定
                categoryButton.menu = UIMenu(title:"" , options: .displayInline, children: actions)
                // こちらを書かないと表示できない場合があるので注意
                categoryButton.showsMenuAsPrimaryAction = true

                // ボタンの表示を変更
                // 初期状態では、先頭の項目を選択状態にする
                categoryButton.setButtonTitle(title:selectedLargeCategory.name, fontSize:12)

            }
        }
    }
    
    func setDetailButton(parentCategory:Category) {
        
        // カテゴリボタンの設定
        if categoryList.count > 0 {
        
            if selectedDetailCategory == nil {
                selectedDetailCategory = categoryList.first
            }
            
            if let catFirst = parentCategory.children.first {
                if catFirst.name != "全ての商品" {
                    if let category = Category(title:"全ての商品") {
                        parentCategory.children.insert(category, at: 0)
                    }
                }
            }
            
            var actions = [UIMenuElement]()
      
            for category in parentCategory.children {

                actions.append(UIAction(title: category.name, image: nil, state: category == selectedLargeCategory ? .on : .off, handler: { (_) in
                    self.detailButton.setTitle(category.name, for: .normal)
                    
                    self.selectedDetailCategory = category
                    self.setDetailButton(parentCategory:parentCategory)
                 //   self.searchExec()
                    
                }))
            }

            if actions.count > 0 {
                // UIButtonにUIMenuを設定
                detailButton.menu = UIMenu(title:"" , options: .displayInline, children: actions)
                // こちらを書かないと表示できない場合があるので注意
                detailButton.showsMenuAsPrimaryAction = true

                // ボタンの表示を変更
                // 初期状態では、先頭の項目を選択状態にする
                detailButton.setButtonTitle(title:selectedDetailCategory.name, fontSize:12)
            }
        }

    }
    
}
