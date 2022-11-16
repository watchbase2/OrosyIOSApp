//
//  ProductCollectionVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/01/31.
//
//  商品を2列表示するCollection VC。　　検索結果と特集の表示で使用
// このVCは、特定のNibとは紐づいてはいない。　表示の制御だけを行っている

import UIKit


protocol ProductSelectedDelegate: AnyObject {
    func showProduct(itemParent:ItemParent, waitIndicator:UIActivityIndicatorView? )
    func openCloseProductBrandSelectView(close:Bool)
}

class ProductCollectionVC: OrosyUIViewController ,UICollectionViewDelegate, UICollectionViewDataSource,  UICollectionViewDelegateFlowLayout {

    var currentDisplayMode:HomeDisplayMode!
    var delegate:ProductSelectedDelegate?
    var collectionView:UICollectionView!
    var currentPageUrl:String?              // このVCをコール元のページのURL
    var ProductBrandSelectViewisHidden = false
    
    var searchItems:SearchItems! {
        didSet {
            itemParents = searchItems.itemParents
            collectionView.reloadData()
            
            let nc = NotificationCenter.default
            nc.addObserver(self, selector: #selector(favoriteReset), name: Notification.Name(rawValue:NotificationMessage.FavoriteReset.rawValue), object: nil)
        }
    }
    
    var searchIems:SearchItems! {
        didSet {
            itemParents = searchIems.itemParents
        }
        
    }
    var itemParents:[ItemParent] = []
    let cellGap:CGFloat = 10
  

    // MARK: コレクションビュー
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return itemParents.count
    }

    // セルのサイズをセット
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = (collectionView.bounds.width - self.cellGap - 40) / 2.0    // 左右は,CollectionViewそのものの制約指定で20空けている
        
        return CGSize(width: width, height: self.cellGap + width + 128)
    }
    
    //　セル間スペース調整
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {

        return cellGap
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let row = indexPath.row
        var cell:UICollectionViewCell!

        
        collectionView.register(UINib(nibName: "ProductCellSB", bundle: nil), forCellWithReuseIdentifier: "ProductCell-M")
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCell-M", for: indexPath)
        
        let contentView = cell.contentView
        contentView.layer.cornerRadius = 4
        
        let imageView = cell.contentView.viewWithTag(1) as! OrosyUIImageView
        let brand = cell.contentView.viewWithTag(2) as! UILabel
        let title = cell.contentView.viewWithTag(3) as! UILabel
        let catarogPrice = cell.contentView.viewWithTag(5) as! UILabel
        let wholesalePrice = cell.contentView.viewWithTag(7) as! UILabel
        //let showShopPage = cell.contentView.viewWithTag(7) as! UILabel
        let favoriteButton = cell.contentView.viewWithTag(10) as! IndexedButton
        favoriteButton.indexPath = indexPath
        favoriteButton.addTarget(self, action: #selector(favoriteButtonPushed), for: .touchUpInside)
       
        let lockIcon = cell.contentView.viewWithTag(8) as! UIImageView

        imageView.targetRow = row
        
        let itemParent = itemParents[row]
        favoriteButton.isSelected = itemParent.isFavorite

        if let item = itemParent.item {
            
            imageView.image = nil
            
            let itemUrl = (itemParent.imageUrls.count > 0 ) ? itemParent.imageUrls.first : ( (item.imageUrls.count > 0) ? item.imageUrls.first : nil)   // itemParentに画像がなければ、itemの中の画像を使う
            imageView.getImageFromUrl(row: row, url: itemUrl, defaultUIImage: g_defaultImage)
            imageView.drawBorder(cornerRadius: 0, color: UIColor.orosyColor(color: .Gray300), width: 1)
            
            brand.text = itemParent.supplier?.brandName
            title.text = item.title
            catarogPrice.text = Util.number2Str(item.catalogPrice)
            
            if item.wholesalePrice == 0 {
             //   wholesalePrice.textAlignment = .left
                wholesalePrice.font = UIFont(name: OrosyFont.Regular.rawValue, size: 10)
                wholesalePrice.textColor = UIColor.orosyColor(color: .Gray400)
                wholesalePrice.text = NSLocalizedString("ConnectionMessage", comment: "")
                lockIcon.isHidden = false

            }else{
              //  wholesalePrice.textAlignment = .right
                wholesalePrice.font = UIFont(name: OrosyFont.Regular.rawValue, size: 12)

                wholesalePrice.textColor = UIColor.orosyColor(color: .Black600)
                wholesalePrice.text = Util.number2Str(item.wholesalePrice)
                lockIcon.isHidden = true
            }
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let row = indexPath.row
 
        let itemParent = itemParents[row]
        if let _delegate = self.delegate {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCell-M", for: indexPath)
            let waitIndicator = cell.contentView.viewWithTag(110) as! UIActivityIndicatorView
            
            waitIndicator.startAnimating()
            DispatchQueue.global().async {
                _delegate.showProduct( itemParent: itemParent, waitIndicator: nil)  // 呼び出し元を呼び出す
            }
        }
    }
    
    //
    var fetchingNextDataForSearchresultTable = false

    var scrollBeginingPoint: CGPoint = CGPoint(x:0, y:0)
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        //　カテゴリ検索、キーワード検索のときの商品一覧の場合
 
        let indixes = collectionView.indexPathsForVisibleItems    // 見えている範囲の行
        for index in indixes {
            let section = index.section
            let row = index.row
            
            if let itemParent = itemParents.first {
                
                DispatchQueue.global().async {
                    
                    for url in itemParent.imageUrls {
                        OrosyAPI.cacheImage(url, imagesize: .Size500)   // 商品ページのトップの商品サンプル画像
                        
                    }
                }
            }
        }
        
    }
        
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let collectionView = scrollView as! UICollectionView
        let scrollPosY = collectionView.contentOffset.y //スクロール位置
        let maxOffsetY = collectionView.contentSize.height - collectionView.frame.size.height //スクロール領域の高さからスクロール画面の高さを引いた値
        let distanceToBottom = maxOffsetY - scrollPosY //スクロール領域下部までの距離
        let currentPoint = collectionView.contentOffset;    //スクロール位置

        let targetSection = 0   // データを追加するセクション　　ここでは　1列しか使っていないので　ゼロで固定
        
        //スクロール領域下部に近づいたら追加で取得する
        if distanceToBottom < 600 && !fetchingNextDataForSearchresultTable {
            DispatchQueue.global().async {
                                
                if self.currentDisplayMode == .CategorySearchProduct {
                    if let cat = self.searchItems {
                        print("次のデータをフェッチ")
                        self.fetchingNextDataForSearchresultTable = true
                        let lastIndex = self.searchItems.itemParents.count
                        let result = cat.getNext()
                        
                        switch result {
                        case .success(let newItemParents):
                            let count = newItemParents.count // 新たに取得した件数
                            if count > 0 {
                                self.itemParents = self.searchItems.itemParents
                                
                                DispatchQueue.main.async {
                                    
                                    LogUtil.shared.log("current count:\(lastIndex),  add count:\(count) ")
                                    var addedIndexPaths:[IndexPath] = []
                                    for ip in 0..<count  {
                                        addedIndexPaths.append(IndexPath(row:lastIndex + ip, section: targetSection))
                                    }
                                    self.collectionView.insertItems(at: addedIndexPaths)
                                    self.fetchingNextDataForSearchresultTable = false

                                }
                            }
                        case .failure(_):
                            break
                        }
                        
                    }
                }else if self.currentDisplayMode == .KeywordSearchProduct {
                    
                    if !self.searchIems.hasAllItemParents {
                        
                        let lastIndex = self.searchIems.itemParents.count
                        
                        print("次のデータをフェッチ完了")
                        self.fetchingNextDataForSearchresultTable = true
                        let result = self.searchIems.getNext()

                        
                        switch result {
                        case .success(let itemParents):
                            let count = itemParents.count
                            
                           DispatchQueue.main.async{
                               self.itemParents = self.searchIems.itemParents
                               
                               var addedIndexPaths:[IndexPath] = []
                               for ip in 0..<count  {
                                   addedIndexPaths.append(IndexPath(row:lastIndex + ip, section: targetSection))
                               }
                               self.collectionView.insertItems(at: addedIndexPaths)
                               
                               self.fetchingNextDataForSearchresultTable = false
                           }
                        case .failure(_):
                           break
                       }
                    }
                }
            }
        }
        
        // ==============================
        // スクロール方向によって検索バーを非表示にする。

        if !self.ProductBrandSelectViewisHidden && self.scrollBeginingPoint.y < currentPoint.y - 20 {    // 少しスクロールしてから反応させる　- 20
            // 下へスクロール
  
            self.ProductBrandSelectViewisHidden = true
            
        }else if self.ProductBrandSelectViewisHidden && self.scrollBeginingPoint.y > currentPoint.y + 10 {
            // 上へスクロール
            self.ProductBrandSelectViewisHidden = false      // これだけだと、少しだけ下へすくろーつしてスクロールする量が

        }else{
            return
        }
        if let _delegate = delegate {
            _delegate.openCloseProductBrandSelectView(close:self.ProductBrandSelectViewisHidden)        // 呼び出し元は　Home　か　Favorite
        }
    }
    
    
    // MARK: ==========================================
    // MARK: お気に入り
    // ハートボタンが押された
    @IBAction func favoriteButtonPushed(_ button: IndexedButton) {
        
        if let indexPath = button.indexPath {
            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }

            let row = indexPath.row
     
            let itemParent = itemParents[row]
            let fvc = FavoriteVC()
            let favoriteFlag = fvc.changeFavorite(itemParent: itemParent, callFromSelf: false, referer:self.currentPageUrl ?? "" )   // お気に入りVCを呼び出す
                        
            itemParent.isFavorite = favoriteFlag

            DispatchQueue.main.async {
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
    }
    
    // お気に入りが更新されたという通知を受けた(ホームとカテゴリ検索結果一覧と共有）
    @objc func favoriteReset(notification: Notification) {
        
        guard let userInfo = notification.userInfo else { return }
        
        if let updatedItemParent = userInfo["itemParent"] as? ItemParent {
            let onOff = userInfo["onOff"] as? Bool ?? false  // true: お気に入りに入れた
            
            // 今表示しているのと同じならアップデートする
            var row = 0
            for item in itemParents {
                if item.id == updatedItemParent.id {
                    item.isFavorite = onOff
                    // データを更新する

                    self.collectionView.reloadItems(at:[IndexPath(row:row, section:0)])
                    break
                }
                row += 1
            }

        }
    }
}
