//
//  CroppingVC.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/06/06.
//

import UIKit
// MARK: 画像切り出し


protocol CroppingDelegate:AnyObject {
    func getCoppedImage(_ croppedImage:UIImage )
}

class CroppingVC:OrosyUIViewController {
    
    var circeMode:Bool = false
    var originalImage:UIImage?
    var upperEdge:CGFloat!
    var delegate:CroppingDelegate?
    
    @IBOutlet weak var originalImageVIew: UIImageView!  // 元の画像
    @IBOutlet weak var coverImageVIew: UIImageView!     // 切り取る範囲を示すグレーのビュー
    @IBOutlet weak var saveButton: IndexedButton!
    var radius_org:CGFloat = 0
    var radius:CGFloat!
    var currentCenterPosition:CGPoint!
    var rectangle_org:CGRect!
    var rectangle:CGRect!
    let rectabgleRate:CGFloat = 375 / 102
    
    override func viewDidLoad() {
        
        let baseWidth = originalImageVIew.frame.size.width
        let baseHeight = originalImageVIew.frame.size.height
        
        let imageSize = originalImage!.size
        
        saveButton.layer.borderWidth = 1
        saveButton.layer.borderColor = UIColor.white.cgColor
        saveButton.layer.cornerRadius = saveButton.bounds.height / 2
        
        originalImageVIew.image = originalImage
        originalImageVIew.backgroundColor = UIColor.orosyColor(color: .Gray200)
        upperEdge = ( baseHeight - baseWidth / imageSize.width * imageSize.height) / 2
        
        currentCenterPosition = CGPoint(x:baseWidth / 2, y:baseHeight / 2)
        
        if circeMode {
            radius_org = baseWidth / 2
            radius = radius_org

            coverImageVIew.makeCircleHole(at : currentCenterPosition, radius: radius)
        }else{
            
            let height = baseWidth / rectabgleRate
            rectangle = CGRect(x:0, y:currentCenterPosition.y - height / 2, width:baseWidth, height:height)
            rectangle_org = rectangle
            coverImageVIew.makeRectHole( rect: rectangle)
        }
    }
        
    //ドラッグ時の呼び出しメソッド
      @IBAction func panLabel(sender: UIPanGestureRecognizer) {
          
          //移動量を取得する。
          let move:CGPoint = sender.translation(in: view)
          
          //ドラッグした部品の座標に移動量を加算する。
          currentCenterPosition.x += move.x
          currentCenterPosition.y += move.y
          
          if circeMode {
              if currentCenterPosition.x - radius < 0 {currentCenterPosition.x = radius}
              if currentCenterPosition.x + radius > radius_org * 2 { currentCenterPosition.x = radius_org * 2 - radius}
              coverImageVIew.makeCircleHole(at:currentCenterPosition, radius:radius)
          }else{
              rectangle.origin.x += move.x
              if rectangle.origin.x < 0 { rectangle.origin.x = 0}
              if rectangle.origin.x + rectangle.size.width > rectangle_org.size.width {rectangle.origin.x = rectangle_org.size.width - rectangle.size.width}
              rectangle.origin.y += move.y
              if rectangle.origin.y < 0 { rectangle.origin.y = 0}
              coverImageVIew.makeRectHole(rect: rectangle)
          }
          //移動量を0にする。
          sender.setTranslation(.zero, in:view)
      }
    
    var prevPinch:CGFloat = 1.0
    @IBAction func pinchAction(_ gesture: UIPinchGestureRecognizer ) {
        ////前回の拡大縮小も含めて初期値からの拡大縮小比率を計算
        let rate = gesture.scale - 1 + prevPinch

        if circeMode {
            radius = radius_org * rate
            if radius > radius_org { radius = radius_org }
            coverImageVIew.makeCircleHole(at:currentCenterPosition, radius:radius)
        }else{

            var width = rectangle_org.size.width * rate
            if width > rectangle_org.size.width {
                width = rectangle_org.size.width
            }
            let height = width / rectabgleRate

            let widthDelta = rectangle_org.size.width - width
            let heightDelta = rectangle_org.size.height - height
            print(widthDelta, heightDelta)
            
            rectangle =  CGRect(x:currentCenterPosition.x - rectangle_org.size.width / 2 + widthDelta / 2, y:currentCenterPosition.y - rectangle_org.size.height / 2 + heightDelta / 2, width:width, height:height)
            coverImageVIew.makeRectHole(rect: rectangle)
        }

        if(gesture.state == .ended) {
            //終了時に拡大・縮小率を保存しておいて次回に使いまわす
            prevPinch = rate
        }
    }
    
    func trimmingImage(_ image: UIImage, trimmingArea: CGRect) -> UIImage {
        let imgRef = image.cgImage?.cropping(to: trimmingArea)
        let trimImage = UIImage(cgImage: imgRef!, scale: image.scale, orientation: image.imageOrientation)
        return trimImage
    }
    
    
    
    @IBAction func saveData(_ sender: Any) {
        let size = originalImage?.size
        
        let imgRate = size!.width / originalImageVIew.bounds.width
        
        var croppedImage:UIImage!
        
        if circeMode {
            let cropRect = CGRect(x:(currentCenterPosition.x - radius) * imgRate, y:(currentCenterPosition.y - radius - upperEdge) * imgRate, width:radius * 2 * imgRate, height:radius * 2 * imgRate)
    
            let sourceImage = trimmingImage(originalImage!, trimmingArea: cropRect)   // 正方形に切り出した画像
            // A circular crop results in some transparency in the
            // cropped image, so set opaque to false to ensure the
            // cropped image does not include a background fill
            let imageRendererFormat = sourceImage.imageRendererFormat
            imageRendererFormat.opaque = false

            // UIGraphicsImageRenderer().image provides a block
            // interface to draw into in a new UIImage
            croppedImage = UIGraphicsImageRenderer(
                // The cropRect.size is the size of
                // the resulting circleCroppedImage
                size: cropRect.size,
                format: imageRendererFormat).image { context in
               
                // The drawRect is the cropRect starting at (0,0)
                let drawRect = CGRect(
                    origin: .zero,
                    size: cropRect.size
                )
             
                // addClip on a UIBezierPath will clip all contents
                // outside of the UIBezierPath drawn after addClip
                // is called, in this case, drawRect is a circle so
                // the UIBezierPath clips drawing to the circle
                UIBezierPath(ovalIn: drawRect).addClip()

                // The drawImageRect is offsets the image’s bounds
                // such that the circular clip is at the center of
                // the image
                let drawImageRect = CGRect(
                    origin: CGPoint(
                        x: 0,
                        y: 0
                    ),
                    size: sourceImage.size
                )

                // Draws the sourceImage inside of the
                // circular clip
                sourceImage.draw(in: drawImageRect)
                }
            
        }else{
            let cropRect = CGRect(x:rectangle.origin.x * imgRate, y:(rectangle.origin.y - upperEdge) * imgRate, width:rectangle.size.width * imgRate, height:rectangle.size.height * imgRate)
 
            croppedImage = trimmingImage(originalImage!, trimmingArea: cropRect)
        }
        
        if let ret = delegate {
            ret.getCoppedImage(croppedImage)
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func closeThisView(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
}

public extension UIImage {
    /// Returns a circle image with diameter, color and optional padding
    class func circle(_ color: UIColor, diameter: CGFloat, padding: CGFloat = .zero) -> UIImage {
        let rectangle = CGSize(width: diameter + padding * 2, height: diameter + padding * 2)
        return UIGraphicsImageRenderer(size: rectangle).image { context in
            let rect = CGRect(x: padding, y: padding, width: diameter + padding, height: diameter + padding)
            color.setFill()
            UIBezierPath(ovalIn: rect).fill()
        }
    }

}

public extension UIView {
    func makeCircleHole(at point: CGPoint, radius: CGFloat) {
         
         let maskLayer = CAShapeLayer()

         // fillはPathの内部を指定の色で塗りつぶします
         // そのためには内部かどうかの判定が必要になりますが、fillRuleはこの判定方法です
         // .evenOddはある点Pから任意の方向へ無限遠点に射線を引きPathとの交差回数を数えます
         // Pathとの交差回数が奇数回の場合は内側、偶数回の場合は外側と判定します
         // 詳細は参考文献を参照ください
         maskLayer.fillRule = .evenOdd
         maskLayer.fillColor = UIColor.black.cgColor
         
         // 画面全体にPathを描きます
         print( self.frame)
         let maskPath = UIBezierPath(rect: self.frame)
         maskPath.move(to: point)
         
         // addArcで弧形を描画します
         // centerとradiusを指定し、 0.0 ~ 2πで描画するため円形となります
         maskPath.addArc(withCenter: point, radius: radius, startAngle: 0.0, endAngle: 2.0 * CGFloat.pi, clockwise: true)
         
         // 上記から円の内側から無限遠まで射線を引くと、円のPathと画面全体の外縁のPathとで2回交わるため
         // 外側に、円の外側から無限遠まで射線を引くと、奇数回Pathと交わるため内側になります
         // すなわち画面全体のうち円以外の部分が黒色に塗りつぶされます
         maskLayer.path = maskPath.cgPath
         
         // 自身のlayerのmaskとして上記で作成したmask用のlayerを指定しました
         // maskの黒色の部分と重複している箇所の色が残るため、
         // 結果として円の内側は色がなくなり、円形の穴があくことになります
         self.layer.mask = maskLayer
     }
    
    func makeRectHole(rect:CGRect) {
        let maskLayer = CAShapeLayer()
        maskLayer.fillRule = .evenOdd
        maskLayer.fillColor = UIColor.black.cgColor
        print( self.frame)
        
        let maskPath = UIBezierPath(rect: self.frame)
        maskPath.move(to: CGPoint(x:rect.minX, y:rect.minY))
        maskPath.addLine(to: CGPoint(x:rect.maxX, y:rect.minY))
        maskPath.addLine(to: CGPoint(x:rect.maxX, y:rect.maxY))
        maskPath.addLine(to: CGPoint(x:rect.minX, y:rect.maxY))
        maskPath.addLine(to: CGPoint(x:rect.minX, y:rect.minY))
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
    }
}
    
