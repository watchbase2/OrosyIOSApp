//
//  SpecialFeatureVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/23.
//
// 商品の部分で左右に20pt 開けるため、Viewの設定でマージンを開けている。一方、バナー画像は左右目一杯に広げるため、マイナスのマージンをセットして広げている。このため、 collectionVIewのclipToBoundを falseにセットしている
// ヘッダー部は　section=0、　商品部はsection=1


import UIKit
import SafariServices

class SpecialFeatureVC: OrosyUIViewController,  UICollectionViewDelegate, UICollectionViewDataSource ,  UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var ContentCollectionView: UICollectionView!
    
    var selectedContent:Content!
    var productCollectionVC:ProductCollectionVC!
    
    func getItemidForPageUrl() -> String {
        return selectedContent.contentId ?? ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNaviTitle(title: "特集")

        if selectedContent.blogIds == nil || selectedContent.blogIds.count == 0 {
           // let accountMenu = UIImage(named: "share")?.withRenderingMode(.alwaysOriginal)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(), style:.plain, target: self, action: #selector(self.shareAction))
            
        }else{
            let accountMenu = UIImage(named: "icons7-share-1")?.withRenderingMode(.alwaysOriginal)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: accountMenu, style:.plain, target: self, action: #selector(self.shareAction))
        }
        
        
        //　cellの設定だけ、ProductCollectionVCに任せる
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ProductCollectionVC") as! ProductCollectionVC

        productCollectionVC = vc
        productCollectionVC.collectionView = ContentCollectionView
        productCollectionVC.itemParents = selectedContent.items
        productCollectionVC.currentPageUrl = self.orosyNavigationController?.currentUrl
        
        ContentCollectionView.delegate = self
        ContentCollectionView.dataSource = self
        
        ContentCollectionView.reloadData()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(favoriteReset), name: Notification.Name(rawValue:NotificationMessage.FavoriteReset.rawValue), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
      //  _ = g_userLog.sendAccessLog(pageUrl: .featurePage, pageId:selectedContent.contentId  ,referer: .homePage)
    }


    // MARK: 商品一覧
    let cellGap:CGFloat = 10
    
    // セルのサイズをセット
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let section = indexPath.section
        var size:CGSize!
        
        if section == 0 {
            size = CGSize(width: ContentCollectionView.bounds.width, height: 300)
        }else{
            let width = (ContentCollectionView.bounds.width - 40 - self.cellGap ) / 2.0    // 左右は,CollectionViewそのものの制約指定で20空けている
            size =  CGSize(width: width, height: self.cellGap + width + 128)
        }
        
        return size
    }
    
    //　セル間スペース調整
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {

        return cellGap
    }
    
    func numberOfSections (in collectionView: UICollectionView) -> Int {
        return 2
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count:Int!
        
        if section == 0 {
            count = 1
        }else{
            count = productCollectionVC.collectionView(collectionView, numberOfItemsInSection: section)
        }
        
        return count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let section = indexPath.section
        let row = indexPath.row
        
        var cell:UICollectionViewCell!
        
        if section == 0 {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContentCell", for: indexPath)
         
            
            let imageView = cell.contentView.viewWithTag(1) as! OrosyUIImageView
       //     let title = cell.contentView.viewWithTag(2) as! OrosyLabel14B
            let content = cell.contentView.viewWithTag(3) as! OrosyLabel14
            let linkTitle = cell.contentView.viewWithTag(4) as! OrosyLabel14
            let button = cell.contentView.viewWithTag(10) as! UIButton
            
            
            if selectedContent.blogIds == nil || selectedContent.blogIds.count == 0 {
                linkTitle.text = ""
                button.isHidden = true
            }else{
                button.isHidden = false
            }
            
            imageView.targetRow = row
            imageView.getImageFromUrl(row: row, url: selectedContent.imageUrl)
       //     title.text = selectedContent.title
            content.text = selectedContent.content_description
            
        }else{
            cell = productCollectionVC.collectionView(collectionView, cellForItemAt: indexPath )
            
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 0 { return }
        
        let itemParent = selectedContent.items[row]
        showProduct( itemParent: itemParent)  // 呼び出し元を呼び出す
        
    }
    
    // MARK: 　＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
    // MARK: お気にり
 
    // ハートボタンが押された時の処理はProductCollectionVで処理

    
    // 他のビューでお気に入りのステータスが変更された場合
    @objc func favoriteReset(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        if let updatedItemParent = userInfo["itemParent"] as? ItemParent {
            let onOff = userInfo["onOff"] as? Bool ?? false  // true: お気に入りに入れた
            
            // 今表示しているのと同じならアップデートする
            var row = 0
            for item in selectedContent.items {
                if item.id == updatedItemParent.id {
                    item.isFavorite = onOff
                    // データを更新する

                    self.ContentCollectionView.reloadItems(at:[IndexPath(row:row, section:1)])     // sectionが異なるので、ProductCollectionVCを呼び出せない
                    break
                }
                row += 1
            }

        }
        
    }
    
    // 商品ページへ遷移
    func showProduct(itemParent:ItemParent) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ProductDetailVC") as! ProductDetailVC
        vc.navigationItem.leftItemsSupplementBackButton = true
        
        let supplier = Supplier(supplierId: itemParent.supplier?.id ?? "")          // これを先に指定しておく必要がある
        _ = supplier?.getNextSupplierItemParents()
        vc.supplier = supplier
        vc.connectionStatus = supplier?.connectionStatus ?? .UNREQUESTED
        vc.itemParent = itemParent
      //  vc.selectedItem = itemParent.item
       // vc.itemParent_id = itemParent.id
        
        self.orosyNavigationController?.pushViewController(vc, animated: true)
    }
    
    
    // ブログコンテンツをブラウザで表示
    @IBAction func showBlogPage(_ sender: Any) {
        
        if selectedContent.blogIds.count > 0 {
            if let blogId = selectedContent.blogIds.first {
                if let url = URL(string:   BLOG_RETAILER_BASE_URL + blogId) {
                    let safariViewController = SFSafariViewController(url: url)
                    present(safariViewController, animated: false, completion: nil)
                    self.orosyNavigationController?.sendBlogAccessLog(blogId: blogId)
                }
            }
        }

    }
    
    // 商品ページのURLをシェア
    @IBAction func shareAction() {
        LogUtil.shared.log ("商品画面：シェア")
        if selectedContent.blogIds.count > 0 {
            if let blogId = selectedContent.blogIds.first {
                let textData = (selectedContent.title ?? "") +  "\n\n" + BLOG_RETAILER_BASE_URL + blogId
                let shareItem = ShareItem(text:textData, title:NSLocalizedString("ShareThisBlog", comment: "") )
                
                // 共有する項目
                let activityItems = [shareItem ] as [Any]
                //let activityItems = [shareText, shareUrl ] as [Any]
                
                // 初期化処理
                let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)

                // 使用しないアクティビティタイプ
                //let excludedActivityTypes = [ UIActivity.ActivityType.message ]
                //  activityVC.excludedActivityTypes = excludedActivityTypes

                // UIActivityViewControllerを表示
                DispatchQueue.main.async {
                    self.present(activityVC, animated: true, completion: nil)
                }
                g_userLog.shareContent(contentId:blogId, pageUrl: self.orosyNavigationController?.currentUrl ?? "")
                
            }
        }
    }

}


