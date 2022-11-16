//
//  CommonEditVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/07/24.
//

import UIKit


class CommonEditVC:OrosyUIViewController, OrosyTextFieldLabelDelegate, OrosyTextViewLabelDelegate {
    
    @IBOutlet weak var MainTableView: UITableView!
    var MainTableBottomConstraint: NSLayoutConstraint!
    var toBeSaved = false
    

    var selectedItem:DisplayItem!
    var itemList:[[String:Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 15.0, *) {
            MainTableView.sectionHeaderTopPadding = 0.0 // iOS15から追加された、セクションヘッダーの上のスペースを消す
        }
        
        MainTableView.translatesAutoresizingMaskIntoConstraints = false
        MainTableBottomConstraint = MainTableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        let constraints = [MainTableBottomConstraint!,
                           MainTableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0),
                           MainTableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant:0),
                           MainTableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant:0)
        ]
        NSLayoutConstraint.activate(constraints)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    

    func getItemData(_ indexPath:IndexPath) -> DisplayItem  {
        let section = indexPath.section
        let row = indexPath.row
        let display_data = itemList[section]["DATA"] as! [DisplayItem]
        return display_data[row]
    }
    

    func moveToNextField() {

        var nextIndexPath:IndexPath?

        unfocusedOnCurrentCell()

        for section in 0..<itemList.count {
            let row_items = itemList[section]["DATA"] as! [DisplayItem]
            for row in 0..<row_items.count {
                let row_data = row_items[row]
                
                if find_currentPos && row_data.fixed == false {
                    nextIndexPath = IndexPath(row:row, section:section)
                    find_currentPos = false
                    break
                }
                
                if row_data.itemType == selectedItem.itemType {
                    find_currentPos = true
                }
            }
        }
        
        if let indexPath = nextIndexPath {
            MainTableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.middle, animated: true)
            
            if let cell = MainTableView.cellForRow(at: indexPath) {
                
                let row_data = getItemData(indexPath)
                selectedItem = row_data
                
                //　次の移動先にフォーカスを当てる
               // if row_data.cellType == "NORMAL_CELL" {
                    if let textField = cell.viewWithTag(1) as? OrosyTextFieldLabel {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {     // キーボードに隠れない様になってからbecomeFirstResponderを実行しないとキーボードが隠れるので、上実行したスクロールが完了するのを待つ
                            textField.textField?.becomeFirstResponder()
                            textField.focus = true
                        }
                    }
              //  }
               // if row_data.cellType == "TEXTVIEW_CELL" {
                    if let textView = cell.viewWithTag(1) as? OrosyTextViewLabel {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {     // キーボードに隠れない様になってからbecomeFirstResponderを実行しないとキーボードが隠れるので、上実行したスクロールが完了するのを待つ
                            textView.textView?.becomeFirstResponder()
                            textView.focus = true
                            
                        }
                    }
               // }else{
                    if let buttonWithLabel = cell.viewWithTag(10) as? OrosyMenuButtonWithLabel {
                        buttonWithLabel.focus = true
                    }
               // }
        }
        
        find_currentPos = false
            
        }
    }

    var indexPathBeingEdited:IndexPath?     // 編集中の行

    func orosyTextFieldDidBeginEditing(_ _orotyTextFieldLabel: OrosyTextFieldLabel) {
        indexPathBeingEdited = _orotyTextFieldLabel.indexPath
        
        _orotyTextFieldLabel.focus = true

        unfocusedOnCurrentCell()

        if let indexPath = _orotyTextFieldLabel.indexPath {
            let row_data = getItemData(indexPath)
            selectedItem = row_data
        }
    }

    func unfocusedOnCurrentCell() {
        
        if selectedItem == nil { return }
        if let selectedIndexPath = selectedItem.indexPath {
            if let cell = MainTableView.cellForRow(at: selectedIndexPath) {

                // 現在の行からフォーカスを外す
                if selectedItem.cellType == "NORMAL_CELL" {
                    if let textField = cell.viewWithTag(1) as? OrosyTextFieldLabel {
                        textField.focus = false
                    }
                }else if selectedItem.cellType == "TEXTVIEW_CELL" {
                    if let textView = cell.viewWithTag(1) as? OrosyTextViewLabel {
                        textView.focus = false
                    }
                }else{
                    if let buttonWithLabel = cell.viewWithTag(10) as? OrosyMenuButtonWithLabel {
                        buttonWithLabel.focus = false
                    }
                }
            }
        }
    }
    
    // 入力が変化するたびにチェックする
    func orosyTextFieldDidChangeSelection(_ _orosyTextFieldLabel: OrosyTextFieldLabel) {
        setTextFieldData(orosyTextFieldLabel: _orosyTextFieldLabel)
        if  _orosyTextFieldLabel.text.count > 0 { toBeSaved = true }
    }
    
    func setTextFieldData(orosyTextFieldLabel:OrosyTextFieldLabel) {
        
        if let indexPath = orosyTextFieldLabel.indexPath {
           let row_data = getItemData(indexPath)
            row_data.edited = true
            let preText = row_data.inputStr  ?? "" // 以前のテキスト
            print(preText)
            row_data.inputStr = orosyTextFieldLabel.text // 入力されたデータをセット
            let (success, _ ) = Validation.normalize(type: row_data.validationType, inStr: orosyTextFieldLabel.text)
            orosyTextFieldLabel.error = !success

            if row_data.itemType == .WEBSITE || row_data.itemType == .ECSITE_URL {
                if row_data.inputStr == "" {
                    orosyTextFieldLabel.error = true
                    orosyTextFieldLabel.errorText = "入力してください"
                }else{
                    let urlStr = (row_data.inputStr ?? "").lowercased()
                    if !urlStr.contains("http://") && !urlStr.contains("https://") {
                        orosyTextFieldLabel.error = true
                        orosyTextFieldLabel.errorText = "https://を先頭に記載してください。"
                    }
                }
            }
  
            if row_data.itemType == .EXPIRE_DATE {
                
                orosyTextFieldLabel.delegate = nil
                
                let text = orosyTextFieldLabel.text
                var last:String = ""
                if text.count > 0 { last = String(text.suffix(1)) }   // 最後に入力された文字
                print(last)
                if preText.count == 1 && text.count == 2 {   //1 文字入力された
                    if last == "/" || last == " " {
                        if preText == "0" {
                            orosyTextFieldLabel.text = "0"      // 0 / にならないようにす
                        }else{
                            orosyTextFieldLabel.text = "0" + preText + " / "
                        }
                    }else{
                        orosyTextFieldLabel.text = text + " / " // 1から2文字へ増えたら　/ をつける
                    }
                }else
                if preText.count == 2 && text.count == 3 {
                    if last == "/" || last == " " {
                        orosyTextFieldLabel.text = text.prefix(2) + " / "      // 2から3文字へ増えたら　/ をつける
                    }else{
                        orosyTextFieldLabel.text = text.prefix(2) + " / " + last
                    }
                }else
                if preText.count == 6 && text.count == 5 { orosyTextFieldLabel.text = String(text.prefix(2))      // 削除しようとしたら　/ を取り除く
                }else
                if preText.count == 5 && text.count == 4 { orosyTextFieldLabel.text = String(text.prefix(2))      // 削除しようとしたら　/ を取り除く
                }else{
                    if last == "/" || last == " " {
                        orosyTextFieldLabel.text = String(text.dropLast())
                    }
                }
                
                row_data.inputStr = orosyTextFieldLabel.text
                orosyTextFieldLabel.delegate = self
            }
        }
    }

    var find_currentPos = false
    
    func orosyTextFieldShouldReturn(_ _orosyTextFieldLabel: OrosyTextFieldLabel) -> Bool {
        _orosyTextFieldLabel.resignFirstResponder()
        _orosyTextFieldLabel.focus = false
        
        moveToNextField()
        return false
    }
    
    
    func orosyTextViewDidBeginEditing(_ _orosyTextViewLabel: OrosyTextViewLabel) {
        toBeSaved = true
        _orosyTextViewLabel.focus = true
        
        unfocusedOnCurrentCell()
        
        if let indexPath = _orosyTextViewLabel.indexPath {
           let row_data = getItemData(indexPath)
            row_data.edited = true
            selectedItem = row_data
            row_data.inputStr = _orosyTextViewLabel.text // 入力されたデータをセット
            let (success, _ ) = Validation.normalize(type: row_data.validationType, inStr: _orosyTextViewLabel.text)
            _orosyTextViewLabel.error = !success
            
        }
   
    }
    
    func orosyTextViewDidEndEditing(_ _orosyTextViewLabel: OrosyTextViewLabel) {
        _orosyTextViewLabel.focus = false

    }
    
    func orosyTextViewDidChangeSelection(_ _orosyTextViewLabel: OrosyTextViewLabel) {

        if let indexPath = _orosyTextViewLabel.indexPath {
            
           let row_data = getItemData(indexPath)
            row_data.edited = true
            row_data.inputStr = _orosyTextViewLabel.text // 入力されたデータをセット
            selectedItem = row_data
            let blank = (row_data.inputStr?.count == 0) ? true : false
            row_data.error = blank
            _orosyTextViewLabel.error = blank
            
            if _orosyTextViewLabel.text.count > 0 { toBeSaved = true }
        }
    }
    

    func orosyTextFieldButton(_ button:IndexedButton) {
        
    }

    // MARK: キーボード制御
    @objc func keyboardWillShow(notification: NSNotification) {
          if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
              MainTableBottomConstraint.constant = 0 - keyboardSize.height + 90
   
          }
      }
    @objc func keyboardWillHide() {
        MainTableBottomConstraint.constant = 0

    }

    
}
