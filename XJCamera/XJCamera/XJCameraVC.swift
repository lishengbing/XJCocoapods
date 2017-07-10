//
//  XJCamera.swift
//  XJCameraSerial
//
//  Created by shanlin on 2017/6/5.
//  Copyright © 2017年 shanlin. All rights reserved.
//

import UIKit
private let kMaxAllowPhotos: Int = 9
private let kNavH: CGFloat = 64
private let kCameraClickH: CGFloat = (158 + 100) * UIScreen.main.bounds.width / 375

class XJCameraVC: UIViewController {

    typealias XJCameraVCFinishedCallBack = (_ result: [UIImage]) -> ()
    fileprivate lazy var bottomView: XJCameraBottomView = XJCameraBottomView(frame: CGRect.zero)
    fileprivate lazy var images: [UIImage] = [UIImage]()
    fileprivate var maxAllowPhotos: Int = kMaxAllowPhotos
    
    fileprivate var returnImagesBlock: XJCameraVCFinishedCallBack?
    
    init(maxAllowPhotos: Int? = kMaxAllowPhotos) {
        super.init(nibName: nil, bundle: nil)
        guard let maxAllowPhotos = maxAllowPhotos else { return }
        self.maxAllowPhotos = maxAllowPhotos
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        XJCameraTool.share.camera_open(vc: self, parentView: self.view, frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.height, height: UIScreen.main.bounds.height - kCameraClickH))
    }
}

extension XJCameraVC {
    fileprivate func setupUI() {
        view.backgroundColor = UIColor.black
        navigationItem.title = "连续拍照"
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(named: "XJCameraBundle.bundle/navBlackBg"), for: .any, barMetrics: .default)
        let attrs : [String : Any] = [NSFontAttributeName : UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName : UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = attrs
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "XJCameraBundle.bundle/nav_back"), style: .plain, target: self, action: #selector(closeClick))
        navigationController?.navigationBar.tintColor = UIColor.white
        
        bottomView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - kCameraClickH - kNavH, width: UIScreen.main.bounds.width, height: kCameraClickH)
        view.addSubview(bottomView)
        bottomView.delegate = self
    }
}

extension XJCameraVC {
    @objc fileprivate func closeClick() {
        dismiss(animated: true, completion: nil)
    }
    
    func xj_cameraDidFinishedCallBack(_ lastImages: [UIImage], _ finishedCallBack: @escaping (_ result: [UIImage]) -> ()) {
        
        self.images = lastImages
        self.bottomView.images = self.images
        self.returnImagesBlock = finishedCallBack
    }
}

extension XJCameraVC: AnimatorPresentedDelegate, XJPhotoBrowerVCDelegate {

    func starRect(indexPath: IndexPath) -> CGRect {
      return bottomView.photoBrowerVc.starRect(belowCollection: bottomView.collectionView, indexPath: indexPath)
    }
    
    func endRect(indexPath: IndexPath) -> CGRect {
      return bottomView.photoBrowerVc.endRect(indexPath: indexPath)
    }
    
    func imageView(indexPath: IndexPath) -> UIImageView {
        return bottomView.photoBrowerVc.imageView(indexPath: indexPath)
    }
    
    func photoBrowerVCWithScroll(indexPath: IndexPath) {
        bottomView.collectionView.scrollToItem(at: indexPath, at: .left, animated: true)
    }
    
    func photoBrowerVCUpdataImages(indexPath: IndexPath, _ images: [UIImage]) {
        self.images = images
        self.bottomView.images = self.images
    }
}

extension XJCameraVC: XJCameraBottomViewDelegate {
    func cameraClickSource() {
        if !XJCameraTool.share.xj_cameraAuthorLicense(vc: self) { return }
        if self.images.count < self.maxAllowPhotos {
            XJCameraTool.share.camera_takeCamera { (image) in
                self.images.append(image)
                self.bottomView.images = self.images
            }
        }else {
            let msg = "选择照片不能超过\(self.maxAllowPhotos)张"
            let alertVC = UIAlertController(title: "", message: msg, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "取消", style: .default) { (action) in }
            let okAction = UIAlertAction(title: "好的", style: .default) { (_) in}
            alertVC.addAction(cancelAction)
            alertVC.addAction(okAction)
            present(alertVC, animated: true, completion: nil)
        }
    }
    
    func photoAlbumClickSource(photoAlbumBtn: UIButton) {
        if !XJCameraTool.share.xj_cameraAuthorLicense(vc: self) { return }
        print("相册选择...")
    }
    
    
    func updataImages(_ images: [UIImage]) {
        self.images = images
    }
    
    func userPhotos(_ images: [UIImage]) {
        if images.count == 0 {
            let alertVC = UIAlertController(title: "", message: "当前没有选择任何照片、请拍照选择!", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "取消", style: .default) { (action) in }
            let okAction = UIAlertAction(title: "好的", style: .default) { (_) in}
            alertVC.addAction(cancelAction)
            alertVC.addAction(okAction)
            present(alertVC, animated: true, completion: nil)
        }else {
            if self.returnImagesBlock != nil {
                self.returnImagesBlock!(images)
            }
            dismiss(animated: true, completion: nil)
        }
    }
}


