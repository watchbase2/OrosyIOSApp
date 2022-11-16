//
//  BreadCrumbVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/11/08.
//

import UIKit


var breadCrumLastPosition = 0   //

class BreadCrumbVC: UIViewController {
    
    @IBOutlet weak var breadCrumbView: UIView!
    
    let selectedFontSize:CGFloat = 17                                       // 選択時のフォントサイズ
    let normalFontSize:CGFloat = 12                                         //　選択時以外のフォントサイズ
    let selectedColor:UIColor = UIColor.orosyColor(color: .Black600)         // 選択位置より前の色
    let normalColor:UIColor = UIColor.orosyColor(color: .Gray400)            // 選択位置より後ろの色
    let allowGoAhead = true                                                  // 前方への移動を許可するかどうか
    
    // 親ビューから指定されたパンくずの現在位置に基づいて初期化
    var selectedPosition:Int = 0 {
        didSet {
            showBreadCrumbs()
        }
    }

    func showBreadCrumbs() {
        if selectedPosition > breadCrumLastPosition { breadCrumLastPosition = selectedPosition }
        
        // 選択したポジションに応じてフォントサイズと色を変える
        for pos in 0..<4 {
            
            let item = breadCrumbView.viewWithTag(pos + 1) as? UILabel
            item?.font = UIFont.systemFont(ofSize: ((pos == selectedPosition) ? selectedFontSize : normalFontSize) )
            item?.textColor = (pos <= ((allowGoAhead) ? breadCrumLastPosition : selectedPosition)) ? selectedColor : normalColor

        }
    }
    
    func resetBreadCrumbs() {
        selectedPosition = 0
        breadCrumLastPosition = 0
        showBreadCrumbs()
    }
    // タッチされた位置が、現在地より前ならそのビューへ遷移
    @IBAction func touchOnLabel(sender: UITapGestureRecognizer) {
        
        if let label = sender.view as? UILabel {
            let targetPosition = label.tag - 1
            
            if targetPosition == selectedPosition { return }
            
            if targetPosition < selectedPosition {
                let targetViewController = navigationController!.viewControllers[targetPosition]    // Root（カートページ）から数えたビューコントローラの位置
                navigationController?.popToViewController(targetViewController, animated: true)
                
            }else if allowGoAhead && targetPosition <= breadCrumLastPosition {
                var viewControllers:[UIViewController] = []
                
                viewControllers.append(navigationController!.viewControllers[0] )
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                // CartViewControllerは初期化すると選択していた条件が消えるので初期化せずに再利用する
                
                if selectedPosition == 0 || targetPosition > 0 {
                    let vc = storyboard.instantiateViewController(withIdentifier: "DeliverySelectVC") as! DeliverySelectVC
                    vc.navigationItem.leftItemsSupplementBackButton = true
                    viewControllers.append(vc)
                }
                if selectedPosition == 1 || targetPosition > 1 {
                    let vc = storyboard.instantiateViewController(withIdentifier: "PaymentSelectVC") as! PaymentSelectVC
                    vc.navigationItem.leftItemsSupplementBackButton = true
                    viewControllers.append(vc)
                }
                if selectedPosition == 2 || targetPosition > 2 {
                    let vc = storyboard.instantiateViewController(withIdentifier: "OrderConfirmationVC") as! OrderConfirmationVC
                    vc.navigationItem.leftItemsSupplementBackButton = true
                    viewControllers.append(vc)
                }
                navigationController?.setViewControllers(viewControllers, animated: true)
            }
        }
    }
}
