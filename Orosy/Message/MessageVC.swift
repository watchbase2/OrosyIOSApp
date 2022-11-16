//
//  MessageVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/11/13.
//
//  文字数に応じて横幅や高さが変わるため、ラベルのサイズと表示位置とはStoryboardの設定は使わず、ロジックで算出して決定している
// 画像は、最大高さを固定にし、横幅は画像のサイズに応じて調整している


import UIKit
import Amplify

protocol ThreadListDelegate: AnyObject {
    func startGetNewThreads()    // スレッドを読み直す。 MessageVCから呼び出される
}

class MessageVC: OrosyUIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, SubscriptionReceivedDelegate, OrosyProcessManagerDelegate, UIGestureRecognizerDelegate {


    @IBOutlet weak var MainTableView: UITableView!          // メッセージを一覧表示するテーブル
    @IBOutlet weak var mainTableBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainTableTopConstraint:NSLayoutConstraint!

    @IBOutlet weak var templateLabel:UILabel!
    @IBOutlet weak var KeyboadInputView: UIView!
    @IBOutlet weak var messageInputView: UITextView!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var sendPhotoButton: CustomButton!
    @IBOutlet weak var cancelPhotoButton: CustomButton!
    
    @IBOutlet weak var messageInputViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageInputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imagePreviewView: UIView!            // 送信前に画像を確認するためのView
    @IBOutlet weak var imagePreView: UIImageView!           // 自由に移動させるため、制約はセットしない！
    
    @IBOutlet weak var closeButton: UIButton!               // モーダルを閉じる
    @IBOutlet weak var modaiTitleLabel: OrosyLabel16B!      // サプライヤページからModalで開いた時に相手の名前を表示
    
    @IBOutlet weak var waitIndicator: UIActivityIndicatorView!

    
    var longPressRecognizer:UILongPressGestureRecognizer!   // ドラッグダウンでキーボードを閉じる際に、入力エリアをキーボードに追従させるためのドラッグ位置検出用
    var tapRecognizer:UITapGestureRecognizer!               // タップされた画像検出
    
    var delegate:ThreadListDelegate?
    var modalMode:Bool = false                              // 特定のサプライヤーとだけやり取りするためのモーダルモード（サプライヤーViewから呼び出された場合）
    var brandName:String!                                   // サプライヤーベー時から呼び出した時に表示するブランド名
    
    var messageList:MessageList!                            // 指定されたユーザとの間のメッセージ
    
    // サプライヤ画面から遷移する場合
    var supplier:Supplier! {
        didSet {
            messageList = MessageList(size: 10, userId: supplier.id)
        }
    }
    
    func getItemidForPageUrl() -> String {
        return supplier.id
    }
    
    /*
    // スレッド一覧から遷移する場合
    var thread:MessageThread! {
        didSet {
            supplier_id = thread.partnerUserId
            if thread.messageList == nil {
                messageList = MessageList(size: 10, userId: supplier_id)
            }
        }
    }
     */
    
    var maxLabelWidth:CGFloat = 100
    var threadTableHeight:CGFloat!      // メッセージ一覧の初期状態の高さ
    var unreadFlag:Bool = false         // 未読メッセージ有り
    var threadUpdateRequest = false     // メッセージの送受信があったので、スレッド一覧を更新する必要がある
    
    // マージン設定
    var SCREEN_WIDTH:CGFloat!
    let SIDE_MARGIN:CGFloat = 20        // 吹き出しのサイドのマージン
    let INSIDE_MARGIN:CGFloat = 20      // 吹き出しと、その中のラベルとのマージン
    let DATE_LABEL_MERGIN:CGFloat = 4   // 吹き出しと日付の間のマージン
    
    override func viewDidLoad() {
            
        super.viewDidLoad()
        
        
        if !modalMode {
            self.setNaviTitle(title: supplier?.brandName)
        }
        
        if #available(iOS 15.0, *) {
            MainTableView.sectionHeaderTopPadding = 0.0     // iOS15から追加された、セクションヘッダーの上のスペースを消す
        }
        
        SCREEN_WIDTH = self.view.bounds.width
  
      //  closeButton.setTitle("", for:.normal)
        
        imagePreviewView.isHidden = true
        self.imagePreView.isHidden = true
        
        MainTableView.isHidden = true   // 反転する状態などが見えてしまうため、テーブルを一旦非表示にしておく
        MainTableView.transform = CGAffineTransform(a:1, b:0, c:0, d:-1, tx:0, ty:0)    // テーブルを上下反転させる
        
        
        // モーダルモード用の設定
        mainTableTopConstraint.constant = (modalMode) ? 40 : 00
        closeButton.isHidden = (modalMode) ? false : true
        
        if modalMode {
            modaiTitleLabel.text = brandName
            self.isModalInPresentation = true

        }
        
        modaiTitleLabel.isHidden = !modalMode
        
        // メッセージの最大幅
        maxLabelWidth = self.view.bounds.size.width - 80
        messageInputView.translatesAutoresizingMaskIntoConstraints = true
        var frame = messageInputView.frame
        frame.size.width = self.view.bounds.width - (20 + 34 + 14)*2
        messageInputView.frame = frame

        // キーボードの表示動作を監視
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        
        // 下方向へドラッグすることでキーボードを閉じると同時に、ドラッグ処理に追従させて入力エリアの位置を下へ移動させるための処理用
        MainTableView.keyboardDismissMode = .interactive  // スクロールダウンに応じてキーボードを閉じる

        
        // メッセージの受信
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(enteredIntoForeground), name: Notification.Name(rawValue:NotificationMessage.EnteredIntoForeground.rawValue), object: nil)
        nc.addObserver(self, selector: #selector(reset), name: Notification.Name(rawValue:NotificationMessage.Reset.rawValue), object: nil)

        setRecognizer()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        SubscriptionManager.shared.delegate = self
        
    }
    
    @objc func reset() {
        DispatchQueue.main.async{
            self.navigationController?.popToRootViewController(animated: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {

        threadTableHeight = MainTableView.bounds.height     // スレッドテーブルビューの初期高さを取得 (viewDidload内だと制約が反映されていないのでここで取得）
        //if supplier_id != nil {
            self.showSupplierMessage()
        //}     // サプライヤページから遷移してきた時にはsupplier_id　がセットされている

    }
    
    override func viewWillDisappear(_ animated: Bool) {

        if threadUpdateRequest {
            if let _delegate = delegate {
                _delegate.startGetNewThreads()  // ThreadListVCへアップデートをリクエストする
                threadUpdateRequest = false
            }
        }
        if let _ = navigationController?.viewControllers.last {
            // ThreadVCから呼ばれた場合
        }else{
            // ModalViewとして呼ばれた場合
            g_currentViewController = g_preViewController
        }
        
    }
    
    // アプリ起動時 & フォアグランドへ復帰時に実行
    @objc func enteredIntoForeground() {

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var count = 0
        
        if tableView == MainTableView {
            if let  _ = messageList {
                count = messageList.messages.count
                noDataAlert.isHidden = (count > 0)
                
                if count > 0 {
                    self.noDataAlert.isHidden = true
                }else{
                    self.noDataAlert.isHidden = false
                    noDataAlert.selectType(type: .message)
                }
            }else{
                self.noDataAlert.isHidden = false
                noDataAlert.selectType(type: .message)
            }
        }else{
            count = g_threadList.count
        }
        return count
    }
    
    let ImageContentSize:CGFloat = 150
    let ImageMarginHorizon:CGFloat = 18   // 吹き出し画像とラベルとのマージン
    let ImageMarginVertical:CGFloat = 9   // 吹き出し画像とラベルとのマージン
    let buttomMagin:CGFloat = 55   // 日付表示エリアとそのマージンの合計
    let MinWidth:CGFloat = 50
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height:CGFloat = 0
        
        let row = indexPath.row
        
        if tableView == MainTableView {
            // ダミーのラベルを使って表示に必要な高さを求めて、それをセルの高さにする
            let message = messageList.messages[row]
            
            if message.mediaType == .text {
                templateLabel.text = message.text
                height = setLabelSize(templateLabel, left: true).size.height + buttomMagin
            }else{
                height = ImageContentSize + buttomMagin
            }
            
        }else{
            height = 70     // サプライヤー一覧の行の高さ
        }
        
        return height
    }
    
    
    // フォントサイズを変更したら templateLabelのサイズも変更すること！！
    func setLabelSize(_ label:UILabel, left:Bool) -> CGRect {
        // 表示可能な最大行数を無制限にする
        label.numberOfLines = 0
        // 文字列が width を超える場合に、単語単位で改行
        label.lineBreakMode = .byWordWrapping
        // 表示フレームを作成。CGSizeMake(最大幅, 最大高さ)
        let size = CGSize.init(width: maxLabelWidth, height: 5000)
        // 文字列の幅に調節したサイズを取得
        var rect = label.sizeThatFits(size)
        if rect.width < MinWidth { rect.width = MinWidth }      // 最小幅　これが小さいと丸くならない
        if rect.height < 17 { rect.height = 17 }    // 最小高さ
        // UILabel の width の制約に、調節済みの width を設定
        var frame = label.frame
        //
        let labelMargin:CGFloat = SIDE_MARGIN + INSIDE_MARGIN       // 20は端から吹き出しまでのマージン、＋20は吹き出し内のマージン
        if left {
            frame.origin.x = labelMargin
        }else{
            frame.origin.x = SCREEN_WIDTH - rect.width - labelMargin  // frame.origin.x + frame.size.width - rect.width - labelMargin // 右側は、幅に応じて開始点xを変える
        }
        
        frame.size = rect
        
        return frame
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell!

        let row = indexPath.row

        if tableView == MainTableView {
            // メッセージのリスト
            
            if row < messageList.messages.count {
                let message = messageList.messages[row]
                
                cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
                cell.selectionStyle = .none     //　セルをタップしたときに色が変化しないようにする
                cell.transform = CGAffineTransform(a:1, b:0, c:0, d:-1, tx:0, ty:0)    // セルを上下反転させる
                
                var leftMode:Bool!
                var backImage:UIImage!
                
                // 相手か自分かを判定、相手のメッセージは左側に表示する
                if message.sendBy == supplier.id {
                    leftMode = true
                    // 相手側
                    backImage = UIImage(named:"LeftFloat")!
                }else{
                    // 自分側
                    leftMode = false
                    backImage = UIImage(named:"RightFloat")!
                }
                
                let messageLabel = cell.viewWithTag(1) as! UILabel
                let dateLabel = cell.viewWithTag(2) as! UILabel
                let floatImageView = cell.viewWithTag(3) as! UIImageView
                let imageView = cell.viewWithTag(4) as! OrosyUIImageView
                let imageButton = cell.viewWithTag(5 ) as! IndexedButton
                
                // 日付
                dateLabel.text = Util.formattedDateTime(message.timestamp)
                var frame_date = dateLabel.frame

     
                var frame:CGRect!
                
                if message.mediaType == .text {
                    // テキストメッセージの表示設定
                    messageLabel.text = message.text
                    frame = setLabelSize(messageLabel,left:leftMode)
                    messageLabel.frame = frame
                    imageView.isHidden = true
                    
                    // 最小幅の場合はセンタリングし、それ以外は左寄せにする
                    if messageLabel.bounds.size.width == MinWidth {
                        messageLabel.textAlignment = .center
                    }else{
                        messageLabel.textAlignment = .left
                    }
                    if leftMode{
                        messageLabel.textColor = UIColor.orosyColor(color: .Black600)
                    }else{
                        messageLabel.textColor = .white
                    }
                    // 前後上下に一定のマージンをとって吹き出しの画像をセット
                    floatImageView.isHidden = false
                    floatImageView.frame = CGRect(x:frame.origin.x - ImageMarginHorizon, y:frame.origin.y - ImageMarginVertical, width: frame.size.width + ImageMarginHorizon * 2 , height: frame.size.height + ImageMarginVertical * 2)
                    
                    // コーナーは拡大されないようにキャップを指定してから画像をセット
                    let cap:Int = Int(backImage.size.height / 2)
                    floatImageView.image = backImage.stretchableImage(withLeftCapWidth: cap, topCapHeight: cap)

                    frame_date.origin.y = floatImageView.frame.origin.y + floatImageView.frame.size.height + DATE_LABEL_MERGIN
                    
                }else if message.mediaType == .imagePng || message.mediaType == .imageJpeg {

                    // 画像の表示設定
                    imageView.isHidden = false
                    imageView.targetRow = row
                    imageView.getImageFromUrl(row: row, url: message.url, defaultUIImage: nil, radius: 10, fitImage: true, maxWidth:self.view.bounds.width * 0.7, left:leftMode )
                    // imageView.layer.borderWidth = 1
                    // imageView.layer.borderColor = UIColor.lightGray.cgColor
                    
                    var frame_image = imageView.frame
                    if leftMode{
                        frame_image.origin.x = SIDE_MARGIN
                    }else{
                        frame_image.origin.x = SCREEN_WIDTH - frame_image.size.width - SIDE_MARGIN
                    }
                    imageView.frame = frame_image
                    messageLabel.text = ""
                    
                    
                    imageButton.indexPath = indexPath
                    imageButton.isUserInteractionEnabled = true
                    imageButton.frame = frame_image
                    
                    floatImageView.isHidden = true  // 吹き出しは表示しない
                    frame_date.origin.y = frame_image.origin.y + frame_image.size.height + DATE_LABEL_MERGIN
                    
                }
                
               
                if leftMode{
                    frame_date.origin.x = SIDE_MARGIN
                    dateLabel.textAlignment = .left
                }else{
                    frame_date.origin.x = SCREEN_WIDTH - frame_date.size.width - SIDE_MARGIN
                    dateLabel.textAlignment = .right
                }
     
                dateLabel.frame = frame_date
                
            }

            
        }else{
            // メッセージ可能なサプライヤーのリスト
            let thread = g_threadList[row]
            cell = tableView.dequeueReusableCell(withIdentifier: "SupplierCell", for: indexPath)
            let imageView = cell.viewWithTag(1) as! OrosyUIImageView
            let label = cell.viewWithTag(2) as! UILabel
            let messageLabel = cell.viewWithTag(3) as! UILabel
            let dataLabel = cell.viewWithTag(4) as! UILabel
            
            let supplier = g_connectedSuppliers?.getSupplier(supplier_id: thread.partnerUserId)   //　取引を許可されている取引先から該当する取引先を探す
            
            label.text = supplier?.brandName
            messageLabel.text = thread.text
            var fontSize = messageLabel.font.pointSize
            messageLabel.font = (thread.unread) ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)

            fontSize = dataLabel.font.pointSize
            dataLabel.text = Util.formattedDateTime(thread.timestamp)
            dataLabel.font = (thread.unread) ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
        
            imageView.getImageFromUrl(url: supplier?.iconImageUrl)
            //loadImageFromUrl(url: supplier?.iconImageUrl, defaultUIImage: nil)
            imageView.layer.cornerRadius = imageView.bounds.height / 2.0        // 丸く切り抜くために高さの半分をセット
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if tableView == MainTableView {
            // キーボードを閉じる
            self.messageInputView.resignFirstResponder()
            self.view.endEditing(true)
        }
    }
    
    
    func enlargeButtonTapped(_ indexPath:IndexPath) {
 
       // guard let indexPath = button.indexPath else { return }
      //  let row = indexPath.row
        
        // 画像の場合は画像を拡大表示する
       // let message = messageList.messages[row]
        
        if imagePreviewView.isHidden == false { return } // プレビュー表示中は無視する
            
        let tableView = MainTableView!
        let cell = tableView.cellForRow(at: indexPath)
        
        /*
        // セルに表示しているものを拡大表示するので、必ずキャッシュにあるはずだから、キャッシュから取得して表示する
        if let imageFromCache = imageCache.object(forKey: NSString(string: message.url?.absoluteString ?? "") ) {
            showImagePeview(sendMode: false, image: imageFromCache)
        }
        */

        if let imageView = cell?.viewWithTag(4) as? UIImageView {
   
            if imageView.image == nil { return }
            
            
            var cellPosition = tableView.rectForRow(at: indexPath)
            cellPosition = tableView.convert(cell!.frame, to: self.view)

            selectedImageOnCell = imageView
            
            var frame = imageView.frame
            frame.origin.x += cellPosition.origin.x
            frame.origin.y += cellPosition.origin.y
            
            originalPositionOnCell = frame
            showImagePeview(sendMode: false, image: imageView.image)
        }
    }
   

    // スクロールしてテーブルの端に近づいたら、次のデータを取得
    // スクロールしてキーボードに触れたら、キーボードを隠す
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
         let scrollPosY = scrollView.contentOffset.y //スクロール位置
         let maxOffsetY = scrollView.contentSize.height - scrollView.frame.size.height //スクロール領域の高さからスクロール画面の高さを引いた値
         let distanceToBottom = maxOffsetY - scrollPosY //スクロール領域下部までの距離

        //スクロール領域下部に近づいたら追加で取得する
        if distanceToBottom < 400 {
            DispatchQueue.main.async{
                
                let lastIndex = self.messageList.messages.count
                let count = self.getData()
                if  count > 0 {
                    var addedIndexPaths:[IndexPath] = []
                    for ip in 0..<count  {
                        addedIndexPaths.append(IndexPath(row:lastIndex + ip, section: 0))
                    }
                    self.MainTableView.insertRows(at: addedIndexPaths, with: .none)
                    //   self.MainTableView.reloadData() // データを取得した時だけ更新
                }
            }
        }
    }
    
    
    // MARK: 画像のプレビュー表示
    // 　カメラ画像の表示と、受信したメッセージ中の画像を拡大表示
    var selectedImageOnCell:UIImageView!    // 選択したセル上の画像
    var originalPositionOnCell:CGRect!
    
    func showImagePeview(sendMode:Bool, image:UIImage?) {
            
        guard let img = image else { return }
        
        let sendButton = imagePreviewView?.viewWithTag(2) as! UIButton
        let cancelButton = imagePreviewView?.viewWithTag(3) as! UIButton
        let closeButton = imagePreviewView?.viewWithTag(4) as! UIButton
       
        // 画像の表示位置をセット
        var imageFrame = imagePreviewView.frame
        self.imagePreView.isHidden = false
        
        let gap:CGFloat = 20
        imageFrame.origin.y += gap   // gap
        imageFrame.size.height = img.size.height / img.size.width * imageFrame.size.width
        
        // 画像の縦横比に合わせることでボタンに被るようなら、高さを制限してそれに合わせて横幅を狭める
        if closeButton.frame.origin.y - gap < (imageFrame.origin.y + imageFrame.size.height) {
            imageFrame.size.height = closeButton.frame.origin.y - gap - gap
            imageFrame.size.width = img.size.width / img.size.height * imageFrame.size.height
            imageFrame.origin.x = (imagePreviewView.bounds.width - imageFrame.size.width) / 2.0
        }
        
        if sendMode {
            // ライブラリから画像を選択したので画像を表示する場合
            sendButton.isHidden = false
            cancelButton.isHidden = false
            closeButton.isHidden = true
            
            imagePreView.image = image
            self.imagePreView.frame = imageFrame
            self.imagePreviewView.isHidden = false
            
        }else{
            // メッセージ中の画像を拡大表示する場合
            selectedImageOnCell?.isHidden = true          // セル状の画像は、すぐに非表示にする
            
            self.imagePreView.isHidden = false

            sendButton.isHidden = true
            cancelButton.isHidden = true
         //   closeButton.isHidden = false
              
            // プレビューの位置をセル上の画像に重ねた状態で画像を表示させてから、拡大表示ポジションへ遷移させる

            imagePreView.frame = originalPositionOnCell
            imagePreView.image = selectedImageOnCell?.image
            
            // アニメーション表示させる
            UIView.animate(withDuration: 0.3, // アニメーションの秒数
                           delay: 0.0, // アニメーションが開始するまでの秒数
                           options: [.curveEaseOut], // アニメーションのオプション 等速 | 繰り返し
                           animations: {
                self.imagePreView.frame = imageFrame

            }, completion: { (finished: Bool) in
                self.imagePreviewView.isHidden = false
 
            })
        }
    }
    
    func closeImageViewWithAnimation() {
        //　元の位置へ戻るようにアニメーションさせる
        
        if self.imagePreviewView.isHidden { return }  // 2度推し防止
        
        if photoMode { return }                      // このアクションは写真撮影時には適用しない
        
        self.imagePreviewView.isHidden = true
        print(self.imagePreView.frame)
         
        UIView.animate(withDuration: 0.3,           // アニメーションの秒数
                       delay: 0.0,                  // アニメーションが開始するまでの秒数
                       options: [.curveEaseOut],    // アニメーションのオプション 等速 | 繰り返し
                       animations: {
            
            self.imagePreView.frame = self.originalPositionOnCell

        }, completion: { (finished: Bool) in
            self.imagePreviewView.isHidden = true
            self.imagePreView.isHidden = true
            self.selectedImageOnCell.isHidden = false

        })

    }
    
    // MARK: サプライヤーとのメッセージ一覧
    // 選択されたているプライヤーのメッセージ表示に切り替える
    func showSupplierMessage() {

        DispatchQueue.global().async {
            LogUtil.shared.log("メッセージ取得")
            if let supplier = Supplier(supplierId: self.supplier.id) {
                DispatchQueue.main.async {
                  //  self.setNaviTitle(title: supplier.brandName)
                    self.refreshMessageTable()
                }
            }
        }
    }
    
    func refreshMessageTable() {
        // 表示する行に応じてテーブルの高さを決める

        var height:CGFloat = 0
        
        for message in messageList.messages {
            
            if message.mediaType == .text {
                templateLabel.text = message.text
                height = height + setLabelSize(templateLabel, left: true).size.height + buttomMagin
            }else{
                height = height + ImageContentSize + buttomMagin
            }
        }
        
        /*
        // メッセージが少ない場合は、テーブルの高さを減らすことで、メッセージが上の方に表示されるようにする
        if threadTableHeight > height {
            mainTableBottomConstraint.constant = threadTableHeight - height
        }else{
            mainTableBottomConstraint.constant = 0
        }
         */
        self.waitIndicator.stopAnimating()
        MainTableView.reloadData()
        MainTableView.isHidden = false
    }
    
    // 次のメッセージを取得。取得したデータがあれば trueを返す
    func getData() -> Int {
        let semaphore = DispatchSemaphore(value: 0)
        var exist = -1
        
        DispatchQueue.global().async {
            
            let result = self.messageList?.getNext()
            
            switch result {
            case .success(let newItems):
                exist = newItems.count
            case .failure(_):
                exist = -1

            case .none:
                exist = -1
            }

            semaphore.signal()
            
         }
        semaphore.wait()
        
        return exist
    }
    

    // モーダルビューで遷移してきた用の閉じるボタン
    @IBAction func closeModalView() {
        self.dismiss(animated: true, completion: nil)
        
    }
    // MARK: カメラ関連
    var imagePicker: UIImagePickerController!
    var cameraPicker:UIImagePickerController!
    var photoMode = false
    @IBAction func photoSelectButtonPushed(_ sender:UIView? ) {
        
        CameraAuthorization.request(vc: self) { allow in
            
            if !allow { return  }
            
            DispatchQueue.main.async {
                // キーボードを消す
                self.messageInputView?.resignFirstResponder()

                // styleをActionSheetに設定
                let alertSheet = UIAlertController(title: "写真を選択してください", message: "", preferredStyle: .actionSheet)

                // 自分の選択肢を生成
                let action1 = UIAlertAction(title: "ライブラリから選択", style: .default, handler: {
                    (action: UIAlertAction!) in
                     
                    self.imagePicker = UIImagePickerController()
                    self.imagePicker.delegate = self
                    self.imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
                    self.imagePicker.allowsEditing = true
                    self.imagePicker.view.backgroundColor = .white
                    self.imagePicker.navigationBar.isTranslucent = false
                    self.imagePicker.navigationBar.barTintColor = .blue
                    self.imagePicker.navigationBar.tintColor = .white
                    self.imagePicker.navigationBar.titleTextAttributes = [
                         NSAttributedString.Key.foregroundColor: UIColor.white
                     ] // Title color
                    self.photoMode = true
                    self.present(self.imagePicker, animated: true, completion: nil)
                })
                let action2 = UIAlertAction(title: "写真を撮る", style: .default, handler: {
                    (action: UIAlertAction!) in
                    
                    self.cameraPicker = UIImagePickerController()
                    self.cameraPicker.sourceType = .camera
                    self.cameraPicker.delegate = self
                    // UIImagePickerController カメラを起動する
                    self.photoMode = true
                    self.present(self.cameraPicker, animated: true, completion: nil)
                    
                })

                let action3 = UIAlertAction(title: "キャンセル", style: .cancel, handler: {
                    (action: UIAlertAction!) in
                    
                })

                // アクションを追加.
                alertSheet.addAction(action1)
                alertSheet.addAction(action2)
                alertSheet.addAction(action3)
                
                // iPad support
                if let senderView = sender {
                    alertSheet.popoverPresentationController?.sourceView = senderView
                    alertSheet.popoverPresentationController?.sourceRect = senderView.bounds
                }else{
                    // xは画面中央、yは画面下部になる様に指定
                    alertSheet.popoverPresentationController?.sourceView = self.view
                    let screenSize = UIScreen.main.bounds
                    alertSheet.popoverPresentationController?.sourceRect = CGRect(x: 0, y: screenSize.size.height, width: 0, height: 0)
                }
  
                self.present(alertSheet, animated: true, completion: nil)
            }

        }

    }

    func closePreviewView() {
        imagePreviewView.isHidden = true
        self.imagePreView.isHidden = true
    }
    // 画像選択画面でキャンセルした
    @IBAction func sendCancel() {
        closePreviewView()
    }
    
    // 画像選択画面で「送信」を実行したので、画像を送信する
    @IBAction func sendImage() {
        
        imagePreviewView.isHidden = true
        
        if let image = imagePreView.image {
            
            guard let jpegData = image.jpegData(compressionQuality: 1) else { return }
            
            let result = messageList.sendMessage(message: "image.jpg", type: .imageJpeg, receiver: supplier.id)
            switch result {
            case .success(let message):
                if let uploadUrl = message?.url {
                    self.fileUpload(uploadUrl, data: jpegData, userId:g_MyId!, partnerId:supplier.id) { (data, response, error) in
                        if let response = response as? HTTPURLResponse, let _: Data = data , error == nil {
                            if response.statusCode == 200 {
                                print("Upload done")
                            } else {
                                print(response.statusCode)
                            }
                        }
                    }

                    messageInputView.text = ""

                    //　送信した画像をそのまま受信欄に表示する
                    // 先にキャッシュへ入れておく
                    if let image = UIImage(data: jpegData) {
                        imageCache.setObject(image , forKey: NSString(string: uploadUrl.absoluteString) )    // imagesizeは　この画像を表示させるStoryboardのimageViewで設定しているsizeと同じでないといけない
                    
                        let newMessage = Message()
                        newMessage.mediaType = .imageJpeg
                        newMessage.sendBy = g_MyId
                        newMessage.url = uploadUrl
                        newMessage.timestamp = Date()
                   //     newMessage.threadId = thread.threadId
                        newMessage.status = .None
                  
                        messageList.messages.insert(newMessage, at:0 )
                        MainTableView.reloadData()
                    }

                }
                
            case .failure(let error):
                self.confirmAlert(title: "エラー", message: "送信できませんでした:\(error.localizedDescription)", ok:"確認")
   
            }
        }
        closePreviewView()
    }

    
    func fileUpload(_ url: URL, data: Data, userId:String, partnerId:String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"      //  これ注意！　POSTではなく、PUTにする必要がある

        let headers = ["Content-Type": "image/jpeg", "Accept": "application/json","x-amz-meta-sendby":userId, "x-amz-meta-userid":partnerId]
        let urlConfig = URLSessionConfiguration.default
        urlConfig.httpAdditionalHeaders = headers
         
        let session = Foundation.URLSession(configuration: urlConfig)
        let task = session.uploadTask(with: request, from: data)
            
        task.resume()
    }
    
    // 画像が選択された時に呼ばれる
     func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

         //選択された画像を表示
         showImagePeview(sendMode: true, image:info[UIImagePickerController.InfoKey.originalImage] as? UIImage)
           
         self.dismiss(animated: true, completion: nil)
         
     }

     // 画像選択がキャンセルされた時に呼ばれる.
     func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {

         // モーダルビューを閉じる
         self.dismiss(animated: true, completion: nil)
     }

    // MARK: メッセージ送信

    
    @IBAction func sendMessageButtonPushed() {
                
        let message = messageInputView.text ?? ""
        
        if message.count == 0 { return }
        
        // 送信する前に、表示へ反映させる

        let newMessage = Message()
        
        newMessage.mediaType = .text
        newMessage.sendBy = g_MyId
        newMessage.text = message
        //newMessage.url:URL?
        newMessage.timestamp = Date()
      //  newMessage.threadId = thread.threadId     // 何故必要？
        newMessage.status = .None
        
        messageList.messages.insert(newMessage, at:0 )
        MainTableView.reloadData()
        
        // 送信する  エラーリトライして、それでもダメならエラー終了させる
        if let uuid = g_processManager.addProcess(name:"メッセージ送信", action:self.sendMessage , errorHandlingLevel: .ALERT_QUIT, errorCountLimit: 3, execInterval: 2, immediateExec: true, processType:.Once, delegate:self, userObject:newMessage ) {

            g_uuid_Message_queue.append(uuid)
        }
        
        messageInputView.text = ""
        self.textViewDidChange(messageInputView)
        
        // キーボードを閉じる
        // inputMessageField.resignFirstResponder()
        // self.view.endEditing(true)
    }
    
    func sendMessage() -> Result<Any?,OrosyError> {
    
        let message = messageList.messages.first?.text ?? ""
        
        let result = messageList.sendMessage(message:message.escaped , type: .text, receiver: supplier.id)
        
        switch result {
        case .success:
            return .success(true)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func processCompleted(_ _uuid:String? ) {
        
        if let uuid = _uuid {
            var tempArray:[String] = []
            for uu in g_uuid_Message_queue {
                if uu == uuid {
                    let status = g_processManager.getStatus(uuid: uuid)
                    if status == .Completed {
                        if let message = g_processManager.getUserObject(uuid: uuid) as? Message {
                            message.status = .Finished
                            self.threadUpdateRequest = true
                        }
                    }else if status == .ErrorFinished {
                        tempArray.append(uuid)
                    }
                }
            }
            
            g_uuid_Message_queue = tempArray
            
        }
    }
    
    func messageReceived(message:Message) {
        
        // 自分が送信したものか、今、選択しているパートナーからのメッセージだけを表示に反映する
        if  message.sendBy == supplier.id {    //  message.sendBy == g_MyId //自分が送信したメッセージは無視する
            DispatchQueue.main.async{
            
                self.messageList.addMessage(message)
                self.refreshMessageTable()
                self.threadUpdateRequest = true
                //self.MainTableView.reloadData() //　行数が変化するため、先頭行だけを更新するためのメソッドは使えない
            }
        }
    }
    

    // MARK: キーボード表示
    var keyboardHeight:CGFloat = 0  // ゼロでなければキーホードが表示されている
    
    @objc dynamic func keyboardWillShow(_ notification: NSNotification) {
        
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        setRecognizer()
        
        keyboardHeight = keyboardSize.height - g_tabbarController.tabBar.bounds.height
        animateWithKeyboard(notification: notification) { keyboardFrame in
            self.messageInputViewBottomConstraint.constant = self.keyboardHeight + ((self.modalMode) ? 50 : 0)       // メッセージ入力エリアをキーボードに合わせて上へスライドさせる。サプライヤページから開く場合にmodalModaになる
            
            if self.mainTableBottomConstraint.constant > 0 {
                if self.mainTableBottomConstraint.constant > keyboardSize.height {
                    self.mainTableBottomConstraint.constant -= keyboardSize.height
                }else{
                    self.mainTableBottomConstraint.constant = 0
                }
            }
        }
    }
    
 
    // キーボードを閉じる
    var mainTableBottomConstraint_org:CGFloat = 0
    @objc dynamic func keyboardWillHide( _ notification: NSNotification) {
 
        UIView.setAnimationsEnabled(false)
        self.mainTableBottomConstraint.constant = 0
        self.messageInputViewBottomConstraint.constant = 0
        keyboardHeight = 0

    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        sendMessageButtonPushed()
        
        return true
    }

    var preHeight:CGFloat = 0
    func textViewDidChange(_ textView: UITextView) {
        self.messageInputView.translatesAutoresizingMaskIntoConstraints = true
        self.messageInputView.sizeToFit()
        var height = messageInputView.contentSize.height

        preHeight = height

        var frame = messageInputView.frame
        frame.size.width = self.view.bounds.width - (20 + 34 + 14)*2
        
        if height > 200 {
            self.messageInputView.isScrollEnabled = true
            height = 200
        }else{
            self.messageInputView.isScrollEnabled = false
        }
        frame.size.height = height
        messageInputView.frame = frame
    }
    

    // ドラッグ処理に追従させて入力エリアの位置を下へ移動させるための処理
    
    func setRecognizer() {
        if longPressRecognizer == nil {
            longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(dragGesture(_:)))
            longPressRecognizer.minimumPressDuration = 0            // 長押ししなくても反応させる
            longPressRecognizer.delegate = self
            self.view.addGestureRecognizer(longPressRecognizer)     // tableViewの上におくと、メッセージがないときに、テーブルビューの高さがゼロになるため反応しなくなる。
        }

        if tapRecognizer == nil {
            tapRecognizer = UITapGestureRecognizer(target: self, action:  #selector(tapGesture(_:)))        // タップでキーボードを閉じれるようにする
            self.view.addGestureRecognizer(tapRecognizer)
        }

    }
    
    
    var scrollBeginingPoint:CGFloat = -1
    var startConstraint:CGFloat = -1

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer)  -> Bool {
        
        return true

    }
    
    enum DragState {
        case OutofArea
        case Start
        case Dragging

    }
    
    // タップでキーボードを閉じる。　　写真をタップしたら拡大表示する。　　キーボード表示中は画像拡大はしない
    var inPreviewing = false
    @IBAction func tapGesture(_ gestureRecognizer: UILongPressGestureRecognizer) {
        
        let point = gestureRecognizer.location(in: MainTableView )
        
        // 送信ボタンの上か？
        let size = sendButton.bounds
        let ps = MainTableView.convert(point, to: sendButton)
        
        if (0 <= ps.x && ps.x <= size.width) && ( 0 <= ps.y && ps.y <= size.height) {
            sendMessageButtonPushed()
            print("in send button")
            return
        }else{
            // 送信ボタンの上か？
            if checkArea(point:point, object:sendButton) {
                sendMessageButtonPushed()
                return
            }
            // 写真選択ボタンの上か？
            if checkArea(point:point, object:photoButton) {
                photoSelectButtonPushed(photoButton)
                return
            }
            // 写真送信ボタンの上か？
            if checkArea(point:point, object:sendPhotoButton) {
                sendImage()
                return
            }
            // 写真送信キャンセルボタンの上か？
            if checkArea(point:point, object:cancelPhotoButton) {
                sendCancel()
                return
            }
            // closeButtonボタンの上か？// モーダル画面のクローズ
            if checkArea(point:point, object:closeButton) {
                if modalMode { closeModalView() }else{ closeView() }
                return
            }
        }
        
        if keyboardHeight > 0 {
            // キーボードを消す
            messageInputView?.resignFirstResponder()
            return
        }else{
            
            if let indexPath = MainTableView.indexPathForRow(at: point) {
                print(indexPath)
                
                if inPreviewing {
                    closeImageViewWithAnimation()
                    inPreviewing = false
                    
                }else{
                    // 画像の上か？
                    if let cell = MainTableView.cellForRow(at: indexPath) {
                        let imageButton = cell.viewWithTag(5 ) as! IndexedButton
                        let size = imageButton.bounds
                        let ps = MainTableView.convert(point, to: imageButton)
                        print ("in button: \(ps)")
                        
                        if (0 <= ps.x && ps.x <= size.width) && ( 0 <= ps.y && ps.y <= size.height) {
                            // 画像の上なので拡大表示させる
                            photoMode = false
                            enlargeButtonTapped(indexPath)
                            inPreviewing = true
                            print("find button")
                        }
                    }
                }
            }
        }
    }
    
    //　タップされた場所が、指定されたオブジェクトの範囲内かどうかをチェック
    func checkArea(point:CGPoint, object:UIView) -> Bool {
        let size = object.bounds
        let ps = MainTableView.convert(point, to: object)
        
        if (0 <= ps.x && ps.x <= size.width) && ( 0 <= ps.y && ps.y <= size.height) {
            return true
        }
        return false
    }
    
    var dragState:DragState = .OutofArea
    var dragStartPos:CGFloat!
    
    @IBAction func dragGesture(_ gestureRecognizer: UILongPressGestureRecognizer) {

        if keyboardHeight == 0 { return }   // キーボードが表示されていないのなら何もしない
        
        switch gestureRecognizer.state {
        case .began:
            //開始時の処理
            let pos = gestureRecognizer.location(in: self.view ).y
            if pos < KeyboadInputView.frame.origin.y {
                //　キーボードより上から開始した場合
                print("start drag")
                
                dragState = .Start
                startConstraint = messageInputViewBottomConstraint.constant
                
            }else{
                
                scrollBeginingPoint = 0
                dragState = .OutofArea
            }
                
        case .changed:
            let pos = gestureRecognizer.location(in: self.view ).y
            
            //ドラッグ中の処理
            if dragState == .Start {
                if pos > (KeyboadInputView.frame.origin.y + KeyboadInputView.frame.size.height) {     // ドラッグして、入力エリアの下端に達した
                    scrollBeginingPoint = pos
                    dragState = .Dragging
                }
            }
            if dragState == .Dragging {
                let newConstraint = startConstraint - ( pos - scrollBeginingPoint)
                
                if newConstraint < startConstraint {
                    messageInputViewBottomConstraint.constant = newConstraint
                }
            }
            
            let mes = (dragState == .Start) ? "Started" : "Dragging"
            print("\(mes): \(pos)")
            
        case .ended:
            //ドラッグ終了時の処理
            scrollBeginingPoint = 0
            dragState = .OutofArea
        default:
            break
        }

    }

    var lockGotoSupplierPageButton = false
    // ブランド一覧でサプライヤを選択した場合にはsupplierが特定されているのでsupplierオブジェクトが渡されるようにしていたが、この方法だとWeb側でお気に入り情報が変化した場合、それを反映できないので、結局、毎回サプライヤー情報を読み直すこととした。
    // 新着情報やバナーの場合には、supplier idと画像ぐらいしか情報を持っていないので、supplier idが渡される
    public func showSupplierPage(supplier:Supplier, activityIndicator:UIActivityIndicatorView? = nil) {

        if lockGotoSupplierPageButton { return }         //　2度押し防止
        lockGotoSupplierPageButton = true
        
        if let act = activityIndicator  {
            DispatchQueue.main.async{
                act.startAnimating()
            }
        }
        
        DispatchQueue.global().async{

            if supplier.getAllInfo(wholeData: true) {
 
                // サプライヤーページへ遷移
                DispatchQueue.main.async{
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "ProductListVC") as! ProductListVC
                    object_setClass(vc.self, SupplierVC.self)
                    
                    vc.navigationItem.leftItemsSupplementBackButton = true
                    vc.productListMode = .ProductList
                    vc.supplier = supplier
                    
                    self.orosyNavigationController?.pushViewController(vc, animated: true)
                    
                    if let act = activityIndicator  {
                        act.stopAnimating()
                    }

                }
            }
            self.lockGotoSupplierPageButton = false
        }
    }
    
    @objc override func titlePushed() {
    
        showSupplierPage(supplier: supplier )
    }
    
}


 
extension OrosyUIViewController {
    func animateWithKeyboard(
        notification: NSNotification,
        animations: ((_ keyboardFrame: CGRect) -> Void)?
    ) {
        // Extract the duration of the keyboard animation
        let durationKey = UIResponder.keyboardAnimationDurationUserInfoKey
        let duration = notification.userInfo![durationKey] as! Double
        
        // Extract the final frame of the keyboard
        let frameKey = UIResponder.keyboardFrameEndUserInfoKey
        let keyboardFrameValue = notification.userInfo![frameKey] as! NSValue
        
        // Extract the curve of the iOS keyboard animation
        let curveKey = UIResponder.keyboardAnimationCurveUserInfoKey
        let curveValue = notification.userInfo![curveKey] as! Int
        let curve = UIView.AnimationCurve(rawValue: curveValue)!

        // Create a property animator to manage the animation
        let animator = UIViewPropertyAnimator(
            duration: duration,
            curve: curve
        ) {
            // Perform the necessary animation layout updates
            animations?(keyboardFrameValue.cgRectValue)
            
            // Required to trigger NSLayoutConstraint changes
            // to animate
            self.view?.layoutIfNeeded()
        }
        
        // Start the animation
        animator.startAnimation()
    }
    

}

