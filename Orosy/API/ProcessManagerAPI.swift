//
//  ProcessManager.swift
//  Orosy
//
//  Created by HIdeji Kitamura on 2022/03/20.
//

import UIKit

// MARK: -------------------------------------
// MARK: プロセスマネージャ
// 関数を登録しておくと、それが成功するまで繰り返し実行させることができる

enum ErrorHandling {
    case QUIT           // エラーは発生したら終了
    case IGNORE         // エラーを無視する
    case ALERT          // アラートを表示する
    case ALERT_QUIT     // アラートを表示して終了する
    
}

enum ProcessType {
    case Once      // 1度成功すれば停止
    case Forever    // 永遠に実行
}

enum ProcessStatus {
    case Running
    case Completed
    case ErrorFinished
    case UnDefined
    case Pause
}

class OrosyProcess:NSObject {
    var uuid:String?
    var name:String?
    var processType:ProcessType!
    var execStatus:ProcessStatus = .UnDefined
    var lastExecDate:Date?
    var execInterval:TimeInterval!                      // 実行周期 sec.
    var lastError:Error?                                // 最後のエラーメッセージ
    var errorCounter:Int = 0                            // エラー回数
    var errorCountLimit:Int = 0                         // 許容するエラー回数
    var errorHandlingLevel:ErrorHandling!               // カウントを超えた場合の処理方法
    var action:(() -> Result<Any?,OrosyError>)          // 実行する関数  Class.function
    var delegate:OrosyProcessManagerDelegate?           // nil　以外の場合は、データ取得完了時に呼び出す
    var userObject:AnyObject?

    
    init( name:String, action:@escaping () -> Result<Any?,OrosyError>, errorHandlingLevel:ErrorHandling, errorCountLimit:Int, execInterval:TimeInterval, processType:ProcessType, delegate:OrosyProcessManagerDelegate?, userObject:AnyObject? = nil) {
    
        self.name = name
        self.action = action
        self.execInterval = execInterval
        self.errorCountLimit = errorCountLimit
        self.errorHandlingLevel = errorHandlingLevel
        self.processType = processType
        self.delegate = delegate
        self.uuid = UUID().uuidString
        self.userObject = userObject

    }
    
    // 処理を実行
    func execute() -> Result<Any?,OrosyError> {
        
        if self.execStatus == ProcessStatus.Pause {
            return .failure(OrosyError.PauseProcess)
            
        }else{
            self.execStatus = .Running
            
            let result = self.action
            
            return result()
        }
    }
    
    func convertCfTypeToString(cfValue: Unmanaged<AnyObject>!) -> String?{

        let value = Unmanaged.fromOpaque(
            cfValue.toOpaque()).takeUnretainedValue() as CFString
        if CFGetTypeID(value) == CFStringGetTypeID(){
            return value as String
        } else {
            return nil
        }
    }
    
}

// 指定された条件に従って、登録された関数を実行する

protocol OrosyProcessManagerDelegate: AnyObject {
    func processCompleted(_ :String?)   // 処理を完了したら　uuidを返す
}

enum OP_Status {
    case ready
    case stop
}

class OrosyProcessManager:UIViewController {
      
    var orosyQueue:DispatchQueue?
    var processList:[OrosyProcess] = []
    var processManagerStatus:OP_Status = .ready

    // 監視リストへ追加。　以降、指定された条件に従って関数が実行される
    func addProcess(name:String, action:@escaping () -> Result<Any?,OrosyError>, errorHandlingLevel:ErrorHandling, errorCountLimit:Int, execInterval:TimeInterval, immediateExec:Bool, processType:ProcessType, delegate:OrosyProcessManagerDelegate?, userObject:AnyObject? = nil) -> String? {

        if orosyQueue == nil {
            orosyQueue = DispatchQueue(label: "com.orosy.process",
                                      qos: .default,
                                      attributes: [.concurrent])
        }
        
        let process = OrosyProcess(name:name, action: action, errorHandlingLevel: errorHandlingLevel, errorCountLimit:errorCountLimit, execInterval:execInterval, processType:processType, delegate:delegate, userObject:userObject)
        
        processList.append(process )
        LogUtil.shared.log(" \(process.name ?? "") : 開始")
        
        if immediateExec {
            orosyQueue!.async {
                self.checkStatus(process, result:process.execute())
            }
        }else{
            orosyQueue!.asyncAfter(deadline: .now() + process.execInterval) {
                self.checkStatus(process, result:process.execute() )
            }
        }
        
        return process.uuid
    }
    
    func allStop() {
        processList = []
        
    }
    
    func getStatus(uuid:String?) -> ProcessStatus {
        for process in processList {
            if process.uuid == uuid ?? "" {
                return process.execStatus
            }
        }
        return .UnDefined
    }
    
    func getUserObject(uuid:String?) -> AnyObject? {
        for process in processList {
            if process.uuid == uuid ?? "" {
                return process.userObject
            }
        }
        return nil
    }
    
    func setStatus(uuid:String?, status:ProcessStatus) {
        for process in processList {
            if process.uuid == uuid ?? "" {
                process.execStatus = status
                return
            }
        }
        return
    }
    
    // 処理結果に応じた処理
    private func checkStatus(_ process:OrosyProcess, result:Result<Any?,OrosyError> ) {
        
        var quit = false
        process.lastExecDate = Date()
        
        switch result {
        case .success:
            
            LogUtil.shared.log ("プロセス終了:\(process.name ?? "")")

            // 正常終了
            switch process.processType {
            case .Forever:
                process.errorCounter = 0
                
            case .Once:
                // 終了
                process.execStatus = .Completed
                if let delegate = process.delegate  { delegate.processCompleted(process.uuid) }
                quit = true
            default:
                break
            }
        case .failure(let error):
            LogUtil.shared.log ("プロセスエラー:\(error.errorDescription ?? "")")
            
            if error.errorDescription == OrosyError.PauseProcess.errorDescription {
                // Pause中なので何もしない
                quit = false
            }else if error.errorDescription == OrosyError.AuthError.errorDescription {
                // 認証エラーなのでポーズにする
          //      process.execStatus = .Pause
                quit = false
            }else{
                // 通常のエラー
                let errorMsg = error.localizedDescription
                process.errorCounter += 1
                
                switch process.errorHandlingLevel {
                case .IGNORE:
                    //　リトライ数を超えたので終了する
                    if process.errorCounter > process.errorCountLimit {
                        process.execStatus = .Completed
                        if let delegate = process.delegate  { delegate.processCompleted(process.uuid) }
                        quit = true
                    }
                    // リトライ
                    break
                case .ALERT, .ALERT_QUIT:
                    // アラート表示
                    if  process.errorCountLimit > 0 && process.errorCounter >=  process.errorCountLimit {
                        // エラー超過
                        confirmAlert(title: "", message: errorMsg, ok: "確認") { completion in
                       
                            if process.errorHandlingLevel == .ALERT_QUIT {
                                // 終了
                                process.execStatus = .ErrorFinished
                                quit = true
                                
                            }else{
                                // エラーカウンターをリセットして再実行
                                process.errorCounter = 0
                            }
                        }
                        
                        
                    }
                default:
                    break
                }
            }
        }
        
        if quit {
            process.execStatus = .Completed
            LogUtil.shared.log("\(process.name ?? "") : Finished")
            
        }else{
            LogUtil.shared.log("\(process.name ?? "") : Continued")
            if processManagerStatus == .ready {
                DispatchQueue.global().asyncAfter(deadline: .now() + process.execInterval) {
                    self.checkStatus(process, result:process.execute() )
                }
            }
        }
    }
}
