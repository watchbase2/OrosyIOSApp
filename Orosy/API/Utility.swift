//
//  Utility.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2021/10/13.
//

import UIKit
import Network

// ユーティリティ
class Util:NSObject {
    
    // MARK: OS情報
    class func getOSversion() ->String {
        let os = ProcessInfo().operatingSystemVersion
        let ios = String(os.majorVersion) + "." + String(os.minorVersion) + "." + String(os.patchVersion)
        return ios
    }

    class func getAppVersion() -> String {
        return  Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }

    class func getAppBuildNumber() -> String {
        return  Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    }
    
    class func getDeviceId() -> String {
        
        return UIDevice.current.identifierForVendor!.uuidString
    }
    
    enum iOSDevice {
        case iPhone
        case iPad
        case Undefined
    }
    
    class func getDevice() -> iOSDevice {
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .iPhone

        } else if UIDevice.current.userInterfaceIdiom == .pad {
            return .iPad
        }
        return .Undefined
    }
    // MARK: 通過書式制御
    class func number2Str(_ number:NSNumber?,withUnit:Bool = true ) -> String {
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = ","
        numberFormatter.groupingSize = 3
        let formattedNumber = numberFormatter.string(from: number ?? 0)!
        
        return formattedNumber + ((withUnit) ? "円" : "")
    }

    class func decimal2Str(_ number:Decimal?,withUnit:Bool = true ) -> String {
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = ","
        numberFormatter.groupingSize = 3
        let formattedNumber = numberFormatter.string(from: (number ?? 0) as NSNumber)!
        
        return formattedNumber + ((withUnit) ? "円" : "")
    }
    
    
    // MARK: 日付書式制御
    class func formattedDate (_ date:Date? ) -> String? {
        
        guard let dt = date else { return nil }
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy/M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        
        let normalizedStr = formatter.string(from: dt)
        return normalizedStr
        
    }

    static func formattedDateTime (_ date:Date?) -> String? {
        guard let dt = date else { return nil }
        let formatter = DateFormatter()
        
        formatter.dateFormat = "MM/dd HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        
        let normalizedStr = formatter.string(from: dt)
        return normalizedStr
        
    }
    
    class func dateFromDateString(_ dateString: String?) -> Date? {
        
        guard let dt = dateString else { return nil }
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dt)
    }
    
    class func dateFromUTCString(_ dateString: String?) -> Date? {
        
        guard let dt = dateString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let date = formatter.date(from: dt)
        return date
    }
    
    class func dateToAwsTimeStamp(_ date: Date?) -> String? {
        
        guard let dt = date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let dateString = formatter.string(from: dt)
        return dateString.replacingOccurrences(of: "+0000", with: "Z")
        
    }
    
    
    class func getImageFromUrl(url: URL?, row:Int ) -> (UIImage?, Int) {
        imageCache.countLimit = 2000
        
        var image:UIImage? = nil
        
        let urlString = url?.absoluteString
        if urlString == nil {
            return (nil, row)
        }
        
        if let imageFromCache = imageCache.object(forKey: NSString(string: urlString ?? "") ) {
            return (imageFromCache, row)
            
        } else {

            DispatchQueue.global().async {
                do {
                    let imageData: Data? = try Data(contentsOf: url!)

                    if let data = imageData {
                        image = UIImage(data: data)
                        if let _image = image {
                            imageCache.setObject(_image, forKey: NSString(string: urlString ?? "") )
                        }
                    }
                }
                catch {
                    image = nil
                }
            }
        }
        
        return (image, row)
    }
    
    
    class func makeAttributedText(message:String, fontSize:CGFloat, textColor:OrosyColorSets) -> NSMutableAttributedString {
        
        let boldAttribute: [NSAttributedString.Key : Any] = [
            .font : UIFont(name: OrosyFont.Bold.rawValue, size: fontSize)!,
            .foregroundColor : UIColor.orosyColor(color: textColor)
            ]
        let normalAttribute: [NSAttributedString.Key : Any] = [
            .font : UIFont(name: OrosyFont.Regular.rawValue, size: fontSize)!,
            .foregroundColor : UIColor.orosyColor(color: textColor)
            ]
        
        var outstr = NSMutableAttributedString()
        var instr = message
        
        while instr.contains("<b>") {
            let parts = instr.components(separatedBy: "<b>")
            if parts.count > 1 {
                outstr.append(NSAttributedString(string: parts[0], attributes: normalAttribute))
                instr = parts[1]
            }
            let boldParts = instr.components(separatedBy: "</b>")
            if boldParts.count > 1 {
                outstr.append(NSAttributedString(string: boldParts[0], attributes: boldAttribute))
                instr = boldParts[1]
            }
        }
        
        outstr.append(NSAttributedString(string: instr, attributes: normalAttribute))
        
        return outstr
    }

}


// ボタンのタイトル設定
extension UIButton {
    func setTitleAttribute(title:String, fontSize:CGFloat) {
        
        let textAttributes: [NSAttributedString.Key : Any] = [
                .font : UIFont.systemFont(ofSize: fontSize),
                .foregroundColor : UIColor.black,
            ]

        let newTitle = NSAttributedString(string: title, attributes: textAttributes)
        self.setAttributedTitle(newTitle, for: .normal)
    }
}


//閉じるボタンの付いたキーボード
class DoneTextFierd: UITextField{

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit(){
        let tools = UIToolbar()
        tools.frame = CGRect(x: 0, y: 0, width: frame.width, height: 40)
        tools.backgroundColor = UIColor.clear
        tools.tintColor = UIColor.clear
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        //let closeButton = UIBarButtonItem(barButtonSystemItem: .some("X"), target: self, action: #selector(self.closeButtonTapped))
        let closeButton = UIBarButtonItem(title: "X", style: .plain, target: self, action: #selector(self.closeButtonTapped))
        closeButton.tintColor = UIColor(named: "Dim Gray")
        tools.items = [spacer, closeButton]
        self.inputAccessoryView = tools
    }

    @objc func closeButtonTapped(){
        self.endEditing(true)
        self.resignFirstResponder()
    }
}

// MARK: 角丸定義
@IBDesignable class CustomButton: UIButton {
    var indexPath:IndexPath? = nil
    
    // 角丸の半径(0で四角形)
    @IBInspectable var cornerRadius: CGFloat = 0.0
    
    // 枠
    @IBInspectable var borderColor: UIColor = UIColor.clear
    @IBInspectable var borderWidth: CGFloat = 0.0
    
    override func draw(_ rect: CGRect) {
        // 角丸
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = (cornerRadius > 0)
        
        // 枠線
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
        
        super.draw(rect)
    }
}


@IBDesignable class CustomUIView: UIView {
    
    // 角丸の半径(0で四角形)
    @IBInspectable var cornerRadius: CGFloat = 0.0
    
    // 枠
    @IBInspectable var borderColor: UIColor = UIColor.clear
    @IBInspectable var borderWidth: CGFloat = 0.0
    
    override func draw(_ rect: CGRect) {
        // 角丸
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true
        
        // 枠線
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
        
        super.draw(rect)
    }

}

// NSObjectコピー
extension NSObject {
    func copyObject<T:NSObject>() throws -> T? {
        let data = try NSKeyedArchiver.archivedData(withRootObject:self, requiringSecureCoding:false)
        return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? T
    }
}

// MARK: 画像変換
extension UIImage {

    //上下反転
    func flipVertical() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        let imageRef = self.cgImage
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y:  0)
        context?.scaleBy(x: 1.0, y: 1.0)
        context?.draw(imageRef!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let flipHorizontalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flipHorizontalImage!
    }

    //左右反転
    func flipHorizontal() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        let imageRef = self.cgImage
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: size.width, y:  size.height)
        context?.scaleBy(x: -1.0, y: -1.0)
        context?.draw(imageRef!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let flipHorizontalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flipHorizontalImage!
    }

}


class Network {
    static let shared = Network() //シングルトン
    private let monitor = NWPathMonitor()
    func setUp() {
        monitor.pathUpdateHandler = { _ in
        }
        let queue = DispatchQueue(label: "Monitor")
        // ネットワーク監視開始
        monitor.start(queue: queue)
    }
    
    func isOnline() -> Bool {
        return monitor.currentPath.status == .satisfied
    }
    
}


final public class LogUtil {
    
    public static let shared = LogUtil()
    
    var fileHnadle:FileHandle!
    let fileName = "log.txt"
    var fileUrl:URL!
    
    private init() {
        let dir = FileManager.default.urls(
          for: .documentDirectory,
          in: .userDomainMask
        ).first!
        
        fileUrl = dir.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: fileUrl)
        }catch{
            
        }
        
        open()
        log("iOS ver:\(Util.getOSversion())")
        log("App ver:\(Util.getAppVersion())  \(Util.getAppBuildNumber())")
                
    }
    
    public func open() {
        let dir = FileManager.default.urls(
          for: .documentDirectory,
          in: .userDomainMask
        ).first!
        
        fileUrl = dir.appendingPathComponent(fileName)
        
        do {
            fileHnadle = try FileHandle(forUpdating: fileUrl)

        }catch{
            if FileManager.default.createFile(
                            atPath: fileUrl.path,
                            contents: "".data(using: .utf8),
                            attributes: nil
                            ) {
                fileHnadle = try! FileHandle(forUpdating: fileUrl)
            }
        }
    }
    
    public func close() {
        fileHnadle.closeFile()
    }
    

    public func getLogData() -> Data? {
        close()
        open()
        let contentData = try! fileHnadle.readToEnd()

        return contentData
    }
    /// ログ出力
    public func log(_ message: String = "", file: String = #file, function: String = #function, line: Int = #line) {
        let logMessage = createLogMessage(message, file: file, function: function, line: line)
        print(logMessage)
        let contentData = logMessage.data(using: .utf8)!

        if LOG_ENABLED {
            fileHnadle.write(contentData)
        }
    }

    /// ログ＋エラー出力
    public func errorLog(_ message: String = "", error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        let logMessage = createLogMessage(message, error: error, file: file, function: function, line: line)
        print(logMessage)
        let contentData = logMessage.data(using: .utf8)!
        if LOG_ENABLED {
            fileHnadle.write(contentData)
        }
    }

    /// 現在時刻の取得
    private func nowDateTime() -> String {
        /// 日付の出力フォーマット
        let dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = dateFormat
        return formatter.string(from: Date())
    }

    /// ログに表示する文字列を生成
    private func createLogMessage(_ message: String, error: Error? = nil, file: String, function: String, line: Int) -> String {
        var logMessage = nowDateTime()

        if let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            logMessage += " [\(bundleName)]"
        }
        
        if let swiftFile = file.split(separator: "/").last?.split(separator: ".").first {   // ここで落ちたが原因不明
            logMessage += " [\(String(swiftFile))]"
        }

        logMessage += " <\(function)>"
        logMessage += " [l: \(line)] "
        logMessage += message

        if let error = error {
            logMessage += "\n\(error)"
        }

        return logMessage + "\n"
    }

}

extension String {
    var escaped: String {
        if let data = try? JSONEncoder().encode(self) {
            let escaped = String(data: data, encoding: .utf8)!
            // Remove leading and trailing quotes
            let set = CharacterSet(charactersIn: "\"")
            return escaped.trimmingCharacters(in: set)
        }
        return self
    }
    
    public func isOnly(_ characterSet: CharacterSet) -> Bool {
        return self.trimmingCharacters(in: characterSet).count <= 0
    }
    public func isOnlyNumeric() -> Bool {
        if self.count == 0 { return false }
        return isOnly(.decimalDigits)
    }
    public func isOnly(_ characterSet: CharacterSet, _ additionalString: String) -> Bool {
        var replaceCharacterSet = characterSet
        replaceCharacterSet.insert(charactersIn: additionalString)
        return isOnly(replaceCharacterSet)
    }
    

}
