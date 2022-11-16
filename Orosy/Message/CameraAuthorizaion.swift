//
//  CameraAuthorizaion.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/11/18.
//

import UIKit
import AVFoundation

private let DEFAULT_TITLE = "カメラ"
private let DEFAULT_MESSAGE = "カメラの使用が許可されていません。プライバシー設定でカメラの使用を許可してください"

/// カメラ使用許可を扱う。

class CameraAuthorization {

    /// カメラの使用許可を求める
    ///
    /// 結果は引数として渡した手続きの呼び出しにより非同期的に返される。
    ///
    /// - parameter vc: ダイアログを表示するとき表示元となるview controller
    /// - parameter mediaType: カメラのメディアタイプ(デフォルト .video)
    /// - parameter title: ダイアログのタイトル (省略可)
    /// - parameter message: ダイアログのメッセージ (省略可)
    /// - parameter completion: 成否の結果を受け取る手続き

    class func request(
        vc: UIViewController,
        mediaType: AVMediaType = .video,
        title: String = DEFAULT_TITLE,
        message: String = DEFAULT_MESSAGE,
        completion: @escaping (Bool) -> Void)
    {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .denied:
            // ユーザがカメラへのアクセスを拒否した
            dialogForConfiguration(vc: vc, title: title, message: message, completion: completion)
        case .restricted:
            // システムによってカメラへのアクセスが拒否された。
            // カメラが存在しない場合も多分ここ
            dialogForConfiguration(vc: vc, title: title, message: message, completion: completion)
        @unknown default:
            break
        }
    }

    /// カメラへのアクセスを許可するようユーザに促す
    private class func dialogForConfiguration(
        vc: UIViewController,
        title: String,
        message: String?,
        completion: @escaping (Bool) -> Void)
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel) { _ in
            completion(false)
        }
        alertController.addAction(okAction)
        let settingsAction = UIAlertAction(title: "設定", style: .default) { _ in
            let url = URL(string: UIApplication.openSettingsURLString)
            UIApplication.shared.open(url!, options: [:]) { _ in
                completion(false)
            }
        }
        alertController.addAction(settingsAction)
        vc.present(alertController, animated: true, completion: nil)
    }
}
