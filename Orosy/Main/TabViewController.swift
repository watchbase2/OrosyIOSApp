//
//  TabViewController.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/09.
//

import UIKit
import WebKit
import Network
import Amplify

// タブ
enum TabPosition: Int {
    case Home = 0
    case Message = 1
    case Cart = 2
    case Favorite = 3
    case OrderHistory = 4
}

class TabBarViewController: UITabBarController, UITabBarControllerDelegate {
       
    var selectedTab:TabPosition!
    private let monitor = NWPathMonitor()
    
    override func viewDidLoad() {
        
        LogUtil.shared.log("TabBarVC loaded")
        
        g_tabbarController = self
        
        setStatusBarBackgroundColor(.white)     // ステータスバーが透けていると、UITableなどのがスクロールした時に見えてしまうため、背景色を白色にしている
        
        setTabbarAppearance()
               
        changeTab(index: TabPosition.Home )
        
        // ローカル処理
        g_defaultImage = UIImage.init(named: "defaultImage")

        g_localNotificationManager = LocalNotificationManager()
        
        // お気に入りビューのセットアップ

        let navigationControllerForFavorite = self.viewControllers![TabPosition.Favorite.rawValue] as! OrosyNavigationController
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ProductListVC") as! ProductListVC    // ProductListVCを継承しているのでこのVCで生成する
        vc.productListMode = .Favorite
        object_setClass(vc.self, FavoriteVC.self)       // FavoriteVCヘ付け替える
        navigationControllerForFavorite.viewControllers = [vc]  // RootViewControllerとしてセットする
        
        // TabBarのIconをセットする
        tabBarController?.tabBar.items![TabPosition.Favorite.rawValue].title = "お気に入り"
        tabBarController?.tabBar.items![TabPosition.Favorite.rawValue].image = UIImage(named: "icons4-fav")

        
        // 各 ViewControllerを先に初期化しておく　　　これをしておかないと、アプリ起動後、メッセージタブを開いていない状態でメッセージを受信したときに、メッセージ一覧へ遷移しない

        for navViewController in self.viewControllers! {
            _ = navViewController.children[0].view
            if let navi = navViewController as? OrosyNavigationController {
                navi.setFirstPageUrl()
            }
        }
        
       let refresh = Notification.Name(NotificationMessage.EnteredIntoForeground.rawValue)  // データ更新を依頼
        NotificationCenter.default.post(name: refresh, object: nil)
        
       test()
    }
    
    func test() {

    }

    @objc func reset() {    // 再ログインしたので、全てトップページへ戻す
        
        for vc in g_tabbarController?.viewControllers ?? [] {
            let nav = vc.navigationController
            nav?.popToRootViewController(animated: false)
            print("test")
            
        }
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
 
        let indexOfTab = tabBar.items?.firstIndex(of: item)
        print("pushed tab \(String(describing: indexOfTab))")

        if selectedTab == TabPosition(rawValue: indexOfTab!) {
            // 同じタブが選択された   TabViewControllerの機能で　rootViewControllerへ自動的に遷移する。
            if selectedTab == .Home {
                // 検索結果表示ではなく、ホーム表示へ戻す
                g_homeTabVC.changeDisplayModeToHome()
            }
            if let newNavi = self.viewControllers?[selectedTab.rawValue] as? OrosyNavigationController {
                if newNavi.viewControllers.count > 1 {  // すでにトップにいる場合に、画面遷移を伴わないのでログは残さない
                    if let vc = newNavi.viewControllers.first as? OrosyUIViewController {
                        
                        if vc is FavoriteVC && (vc as! FavoriteVC).favoriteMode == false {  // お気に入りタブの場合には、商品/取引ブランドの状態も記録できるようにする
                            newNavi.sendAccessLog(targetUrl:RETAILER_SITE_URL + "/brands")
                        }else{
                            newNavi.sendAccessLogForPopToTop(viewController: vc)
                        }
                    }
                }
            }
            
        }else{
        
            selectedTab = TabPosition(rawValue: indexOfTab!)
            if let newNavi = self.viewControllers?[selectedTab.rawValue] as? OrosyNavigationController {
                // タブを切り替えた場合には、最初だけアクセスログを残すが、それ以降は、そこから他へ遷移して戻った時にしか残さない。
                if let vc = newNavi.viewControllers.first as? OrosyUIViewController {
                    if !vc.tabInitialized {
                        vc.tabInitialized = true
                        newNavi.sendAccessLog(tabSwitch:true)
                    }
                }
            }
        }
    }
    

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        return true

    }
    
    func setTabBarItem(index: Int, titile: String, image: UIImage, selectedImage: UIImage) -> Void {
        let tabBarItem = self.tabBar.items![index]
        tabBarItem.title = nil
        tabBarItem.image = image

    }

    // 強制的に各種データをアップデートする
    func foreceUpdate() {
        
        _ = g_categoryDisplayName?.get(forceGetFromServer:true)
        
    }

    
}


extension UITabBarController {
    // タブを切り替える
    func changeTab(index:TabPosition) {
        
        self.selectedIndex = index.rawValue
    }
}
