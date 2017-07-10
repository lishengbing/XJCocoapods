//
//  XJCameraTool.swift
//  XJCameraSerial
//
//  Created by 李胜兵 on 2017/6/5.
//  Copyright © 2017年 shanlin. All rights reserved.
//

import UIKit
import AVFoundation


class XJCameraTool: NSObject {
    
    static let share: XJCameraTool = XJCameraTool()

    
    // 输入端
    fileprivate lazy var input: AVCaptureDeviceInput? = {
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        var input: AVCaptureDeviceInput?
        do {
            try input = AVCaptureDeviceInput(device: device)
            return input
        } catch {
            return nil
        }
    }()
    
    // 音视频采集会话
    fileprivate lazy var session: AVCaptureSession? = {
        let session = AVCaptureSession()
        // 1: 将音视频采集会话的预设设置为高分辨率照片--选择照片分辨率
        session.sessionPreset = AVCaptureSessionPreset1280x720
        return session
    }()
    
    // 创建预览层
    fileprivate lazy var cameraPreviewLayer: AVCaptureVideoPreviewLayer = {
        let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        return cameraPreviewLayer!
    }()
    
    
    // 静态图像输出端
    fileprivate lazy var stillImageOutput: AVCaptureStillImageOutput? = {
        let stillImageOutput = AVCaptureStillImageOutput()
        // 输出图像格式设置
        stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        return stillImageOutput
    }()
    
}

extension XJCameraTool {
    
    // 打开相机
    func  camera_open(vc: UIViewController, parentView: UIView, frame: CGRect){
        
        // 0:判断infolist文件中是否增加了NSCameraUsageDescription配置
        guard let infoDic = Bundle.main.infoDictionary else { return  }
        let photoLibrary = infoDic["NSCameraUsageDescription"]
        if photoLibrary == nil {
            print("XJ_想要使用连续拍照,需要配置info? 你应该, 在info.plist 配置NSCameraUsageDescription")
            return
        }
        
        // 1:如果用户第一次拒绝了不允许了访问相册，提示用户
        if !self.xj_cameraAuthorLicense(vc: vc) { return }
//        let mediaType = AVMediaTypeVideo
//        let authStatus = AVCaptureDevice .authorizationStatus(forMediaType: mediaType)
//        if authStatus == .restricted || authStatus == .denied {
//            print("XJ_应用相机权限受限,请在设置中启用")
//            let alertVc = UIAlertController(title: "", message: "XJ_应用相机权限受限，请前往->设置中启用", preferredStyle: .alert)
//            let goAction = UIAlertAction(title: "设置", style: .default, handler: { (action) in
//                // 前往去设置
//                let url = URL(string: UIApplicationOpenSettingsURLString)
//                if let url = url, UIApplication.shared.canOpenURL(url) {
//                    if #available(iOS 10, *) {
//                        //UIApplication.shared.openURL(url)
//                        
//                        UIApplication.shared.open(url, options: [:],
//                                                  completionHandler: {
//                                                    (success) in
//                        })
// 
//                    } else {
//                        UIApplication.shared.openURL(url)
//                    }
//                }
//            })
//            let cancelAction = UIAlertAction(title: "取消", style: .default, handler: nil)
//            alertVc.addAction(cancelAction)
//            alertVc.addAction(goAction)
//            vc.present(alertVc, animated: true, completion: nil)
//            return
//        }
        
        // 2:加入会话中
        if session!.canAddInput(input), session!.canAddOutput(stillImageOutput) {
            session!.addInput(input)
            session!.addOutput(stillImageOutput)
        }
        
        // 3:创建预览层
        if parentView.layer.sublayers != nil {
            parentView.layer.insertSublayer(cameraPreviewLayer, at: 0)
            cameraPreviewLayer.frame = parentView.layer.bounds
        }else {
            let subLayers = parentView.layer.sublayers
            if !(subLayers?.contains(cameraPreviewLayer))! {
                cameraPreviewLayer.frame = parentView.layer.bounds
                parentView.layer.insertSublayer(cameraPreviewLayer, at: 0)
            }
        }
        
        // 4:启动音视频采集的会话
        self.session?.startRunning()
    }
    
    
    // MARK: - 拍照照片
    func camera_takeCamera(finishedCallBack: @escaping(_ result : UIImage) -> ()) {
    
        // 1: 获得音视频采集设备的连接
        let videoConnect = stillImageOutput?.connection(withMediaType: AVMediaTypeVideo)
        
        // 2: 输出端以异步方式采集静态图像
        stillImageOutput?.captureStillImageAsynchronously(from: videoConnect, completionHandler: { (imageBuffer, error) in
            
            DispatchQueue.global().async {
                if error != nil {
                    print("error:\(error ?? "相机初始化错误" as! Error)")
                    return
                }
                
                // 3: 获取采样缓冲区中的数据
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageBuffer)
                
                // 4: 将数据转化为UIImage
                if let stillImage = UIImage(data: imageData!) {
                    DispatchQueue.main.async {
                        finishedCallBack(stillImage)
                    }
                }
            }
        })
    }
}


extension XJCameraTool {
    func xj_cameraAuthorLicense(vc: UIViewController) -> Bool {
        // 1:如果用户第一次拒绝了不允许了访问相册，提示用户
        let mediaType = AVMediaTypeVideo
        let authStatus = AVCaptureDevice .authorizationStatus(forMediaType: mediaType)
        if authStatus == .restricted || authStatus == .denied {
            print("XJ_应用相机权限受限,请在设置中启用")
            let alertVc = UIAlertController(title: "", message: "XJ_应用相机权限受限，请前往->设置中启用", preferredStyle: .alert)
            let goAction = UIAlertAction(title: "设置", style: .default, handler: { (action) in
                // 前往去设置
                let url = URL(string: UIApplicationOpenSettingsURLString)
                if let url = url, UIApplication.shared.canOpenURL(url) {
                    if #available(iOS 10, *) {
                        //UIApplication.shared.openURL(url)
                        
                        UIApplication.shared.open(url, options: [:],
                                                  completionHandler: {
                                                    (success) in
                        })
                        
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }
            })
            let cancelAction = UIAlertAction(title: "取消", style: .default, handler: nil)
            alertVc.addAction(cancelAction)
            alertVc.addAction(goAction)
            vc.present(alertVc, animated: true, completion: nil)
            return false
        }
        return true
    }
}


