//
//  DummyVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/12/14.
//  Favoriteを呼び出すための中継用。 タブを押すとNavigationControllerが DummyVCを起動し、そこからFavoriteを起動させている

import UIKit

class DummyVC: UIViewController, OrosyProcessManagerDelegate  {
    
    var uuid_favoriteList:String?
    
    override func viewDidLoad() {

        
        let nc = NotificationCenter.default
         nc.addObserver(self, selector: #selector(getData), name: Notification.Name(rawValue:NotificationMessage.SecondDataLoad.rawValue), object: nil)

        
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ProductListVC") as! ProductListVC
            vc.productListMode = .Favorite
            vc.itemParents = g_favoriteItems
            object_setClass(vc.self, FavoriteVC.self)
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        

    }
    
    @objc func getData() {

        g_logger.log ("お気に入りの読み込み")
        uuid_favoriteList = g_processManager.addProcess(name:"お気に入り", action:self.getFavoriteListsAndData , errorHandlingLevel: .IGNORE, errorCountLimit: -1, execInterval: 5, immediateExec: true, processType:.Once, delegate:self)
    }
    
    func processCompleted(_: String?) {
 
        
        DispatchQueue.global().async {
            for item in g_favoriteItems {
                OrosyAPI.cacheImage(item.imageUrls.first)
            }
        }
    }
    
    let DEFAULT_FAVORITE_LISTNAME = "お気に入りリスト"
    
    func getFavoriteListsAndData() -> Result<Any?, OrosyError> {

        if let favorlite = g_favoriteLists {

            if favorlite.list.count == 0 {
                let result = favorlite.createFavoriteList(name: DEFAULT_FAVORITE_LISTNAME)
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    return .failure(error)
                }
            }
            
            // お気に入りデータを取得
            let favor = favorlite.list.first      // v1ではお気に入りリストは一つしかサポートしていない
            var completed = false
            
            while !completed {
                let resultF = favor?.getFavoriteItem(full:true, limit: 10)  // お気に入りの最小限の情報だけを取得
                switch resultF {
                case .success(let items):
                    if items.count == 0 {
                        completed = true
                    }else{
                        g_favoriteItems.append(contentsOf: items)
                    }
                case .failure(let error):
                    return .failure(error)
                default:
                    break
                }
            }
            return .success(nil)
 
        }else{
            //　お気に入りリストを取得
            let favoriteList = FavoriteLists()
            let result = favoriteList.getFavoriteList()
            switch result {
            case .success(_):
                g_favoriteLists = favoriteList
            case .failure(_):
                g_favoriteLists = nil
            }
        }
        
        return .failure(OrosyError.NotInitialized)
        
    }
}

