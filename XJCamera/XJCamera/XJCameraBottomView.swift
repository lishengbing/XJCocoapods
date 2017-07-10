//
//  XJCameraBottomView.swift
//  XJCameraSerial
//
//  Created by shanlin on 2017/6/5.
//  Copyright © 2017年 shanlin. All rights reserved.
//

import UIKit

private let kCellId = "kCellId"

private let kColumn: CGFloat = 4
private let kLeftMargin: CGFloat = 13
private let kRightMargin: CGFloat = 12
private let kMiddleMargin: CGFloat = 10
private let kSizeW: CGFloat = (UIScreen.main.bounds.width - kLeftMargin - kRightMargin - (kColumn - 1) * kMiddleMargin) / kColumn

// 667
private let kPhotoAreaH: CGFloat = 100


protocol XJCameraBottomViewDelegate: class {
    func cameraClickSource()
    func photoAlbumClickSource(photoAlbumBtn: UIButton)
    func updataImages(_ images: [UIImage])
    func userPhotos(_ images: [UIImage])
}
class XJCameraBottomView: UIView {

    fileprivate lazy var bgView: UIView = UIView()
    lazy var collectionView: UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: XJCameraLayout())
    
    fileprivate lazy var bgViewTwo: UIView = UIView()
    fileprivate lazy var cameraBtn: UIButton = UIButton()
    fileprivate lazy var userLabel: UILabel = UILabel()
    fileprivate lazy var selectedPhotoBtn: UIButton = UIButton()
    
    lazy var photoBrowerVc = XJPhotoBrowerVC()
    fileprivate var closeIndexPath: IndexPath?
    
    weak var delegate: XJCameraBottomViewDelegate?
    var images: [UIImage]? {
        didSet {
            guard let images = images  else { return }
            collectionView.reloadData()
            userLabel.text = "使用照片\n(\(images.count))"
            
            if images.count >= 1 {
                let indexPath = IndexPath(item: images.count - 1, section: 0)
                collectionView.scrollToItem(at: indexPath, at: .left, animated: true)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bgView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: kPhotoAreaH)
        collectionView.frame = bgView.bounds
        
        bgViewTwo.frame = CGRect(x: 0, y: kPhotoAreaH, width: UIScreen.main.bounds.width, height: self.frame.height - kPhotoAreaH)
        
        cameraBtn.setImage(UIImage(named: "XJCameraBundle.bundle/icon_45"), for: .normal)
        let cameraBtn_w: CGFloat = 66
        let camera_y: CGFloat = (self.frame.height - kPhotoAreaH - cameraBtn_w) - 15
        cameraBtn.frame = CGRect(x: 0, y: camera_y, width: cameraBtn_w, height: cameraBtn_w)
        cameraBtn.center.x = UIScreen.main.bounds.width * 0.5
        
        userLabel.sizeToFit()
        userLabel.frame = CGRect(x: UIScreen.main.bounds.width - 30 - userLabel.bounds.width, y: self.frame.height - kPhotoAreaH - 17 - userLabel.bounds.height, width: userLabel.bounds.width, height: userLabel.bounds.height)
        selectedPhotoBtn.sizeToFit()
        selectedPhotoBtn.frame = CGRect(x: 35, y: self.frame.height - kPhotoAreaH - 17 - selectedPhotoBtn.bounds.height, width: selectedPhotoBtn.bounds.width, height: selectedPhotoBtn.bounds.height)
        
       
    }
}

extension XJCameraBottomView {
    fileprivate func setupUI() {
        
        self.backgroundColor = UIColor.clear
        bgView.backgroundColor = UIColor.clear
        collectionView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        self.addSubview(bgView)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(XJCameraCell.self, forCellWithReuseIdentifier: kCellId)
        self.bgView.addSubview(collectionView)
        
        self.addSubview(bgViewTwo)
        bgViewTwo.backgroundColor = UIColor.black
        
        self.bgViewTwo.addSubview(cameraBtn)
        cameraBtn.addTarget(self, action: #selector(cameraClick), for: .touchUpInside)
        
        userLabel.text = "使用照片\n(0)"
        userLabel.numberOfLines = 0
        userLabel.textColor = UIColor.white
        userLabel.font = UIFont.systemFont(ofSize: 14)
        userLabel.textAlignment = .center
        bgViewTwo.addSubview(userLabel)
        
        bgViewTwo.addSubview(selectedPhotoBtn)
        selectedPhotoBtn.setTitle("从相机\n选择", for: .normal)
        selectedPhotoBtn.setTitleColor(UIColor.white, for: .normal)
        selectedPhotoBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        selectedPhotoBtn.titleLabel?.numberOfLines = 0
        selectedPhotoBtn.titleLabel?.textAlignment = .center
        selectedPhotoBtn.contentEdgeInsets = UIEdgeInsetsMake(2, 0, -2, 0)
        selectedPhotoBtn.addTarget(self, action: #selector(photoAlbumClick(sender:)), for: .touchUpInside)
        
        let userTap = UITapGestureRecognizer(target: self, action: #selector(userPhotoGes(_:)))
        userLabel.addGestureRecognizer(userTap)
        userLabel.isUserInteractionEnabled = true
    
    }
}


extension XJCameraBottomView {
    @objc fileprivate func cameraClick() {
        delegate?.cameraClickSource()
    }
    
    @objc fileprivate func photoAlbumClick(sender: UIButton) {
        delegate?.photoAlbumClickSource(photoAlbumBtn: sender)
    }
    
    fileprivate func removeCell() {
        let alertVC = UIAlertController(title: "", message: "放弃上传这张照片吗?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "确认", style: .default) { (action) in
            self.removeToData(i: (self.closeIndexPath?.item)!)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .default, handler: nil)
        alertVC.addAction(cancelAction)
        alertVC.addAction(okAction)
        self.viewController?.present(alertVC, animated: true, completion: nil)
    }
    
    func removeToData(i: Int) {
        // 1.0移除数据
        self.images?.remove(at: i)
        
        // 2.0刷新表格
        self.collectionView.reloadData()
        
        // 3.0代理告诉外界数组同步数量
        self.delegate?.updataImages(self.images ?? [])
    }
    
    @objc fileprivate func userPhotoGes(_ sender: UITapGestureRecognizer) {
        delegate?.userPhotos(self.images ?? [])
    }
}

extension XJCameraBottomView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCellId, for: indexPath) as! XJCameraCell
        cell.backgroundColor = UIColor.random()
        cell.imageV.image = images?[indexPath.item]
        cell.indexPath = indexPath
        cell.myblock = { [unowned self] (indexP) in
            self.closeIndexPath = indexP
            self.removeCell()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoBrowerVc = XJPhotoBrowerVC(indexPath: indexPath, images: images!, vc: self.viewController!)
        photoBrowerVc.modalPresentationStyle = .custom
        self.photoBrowerVc = photoBrowerVc
        photoBrowerVc.delegate = self.viewController as? XJPhotoBrowerVCDelegate
        self.viewController?.present(photoBrowerVc, animated: true, completion: nil)
    }
}


class XJCameraLayout: UICollectionViewFlowLayout {
    override func prepare() {
        super.prepare()
        itemSize = CGSize(width: kPhotoAreaH - 17, height: kPhotoAreaH - 17)
        minimumLineSpacing = 5
        minimumInteritemSpacing = 0
        sectionInset = UIEdgeInsetsMake(9, 12, 8, 12)
        scrollDirection = .horizontal
        
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.alwaysBounceHorizontal = true
    }
}
