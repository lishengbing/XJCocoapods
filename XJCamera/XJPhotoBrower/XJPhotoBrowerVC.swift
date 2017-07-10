//
//  XJPhotoBrowerVC.swift
//  XJPhotoBrower
//
//  Created by shanlin on 2017/6/3.
//  Copyright © 2017年 shanlin. All rights reserved.
//

import UIKit
private let kCellId = "kCellId"


protocol XJPhotoBrowerVCDelegate: class {
    func photoBrowerVCWithScroll(indexPath: IndexPath)
    func photoBrowerVCUpdataImages(indexPath: IndexPath, _ images: [UIImage])
}
class XJPhotoBrowerVC: UIViewController {

    var indexPath: IndexPath!
    var images: [UIImage]!
    var photoBrowerAnimatorDelegate: XJPhotoBrowerAnimator?
    var belowVC: UIViewController!
    fileprivate var currentIndex: Int = 0
    fileprivate var isReload: Bool = false
    
    fileprivate lazy var photoBrowerAnimator : XJPhotoBrowerAnimator = XJPhotoBrowerAnimator()
    fileprivate lazy var collectionView: UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: XJPhotoBrowerLayout())
    fileprivate lazy var topBgView: UIView = UIView()
    fileprivate lazy var pageLabel: UILabel = UILabel()
    fileprivate lazy var selectBtn: UIButton = UIButton()
    fileprivate var  belowCollectionView: UICollectionView!
    fileprivate var isForbittenScroll: Bool = false
    
    weak var delegate: XJPhotoBrowerVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        setupUI()
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    init(indexPath: IndexPath, images: [UIImage], vc: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        self.indexPath = indexPath
        self.images = images
        self.belowVC = vc
        self.transitioningDelegate = photoBrowerAnimator
        photoBrowerAnimator.presentedDelegate = belowVC as? AnimatorPresentedDelegate
        photoBrowerAnimator.dismissDelegate = self
        photoBrowerAnimator.indexPath = indexPath
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        view.frame.size.width += 20
    }
}

extension XJPhotoBrowerVC {
    fileprivate func setupUI() {
        collectionView.frame = view.bounds
        view.addSubview(collectionView)
        collectionView.register(XJPhotoBrowerCell.self, forCellWithReuseIdentifier: kCellId)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(topBgView)
        topBgView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.6)
        topBgView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 64)
        
        pageLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
        pageLabel.center = CGPoint(x: UIScreen.main.bounds.width * 0.5, y: 40)
        pageLabel.text = "\(indexPath.item + 1) / \(images.count)"
        pageLabel.textColor = UIColor.white
        pageLabel.textAlignment = .center
        pageLabel.font = UIFont.boldSystemFont(ofSize: 14)
        topBgView.addSubview(pageLabel)
        
        selectBtn.setImage(UIImage(named: "XJCameraBundle.bundle/choose_light"), for: .normal)
        selectBtn.sizeToFit()
        selectBtn.frame = CGRect(x: UIScreen.main.bounds.width - selectBtn.bounds.width - 15, y: 0, width: selectBtn.bounds.width, height: selectBtn.bounds.height)
        selectBtn.center.y = pageLabel.center.y + 2
        topBgView.addSubview(selectBtn)
        selectBtn.addTarget(self, action: #selector(cancelSelectClick), for: .touchUpInside)
        
        
        selectBtn.tag = self.indexPath.item
        collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
    }
}

extension XJPhotoBrowerVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCellId, for: indexPath) as! XJPhotoBrowerCell
        if isReload {
            cell.isScaleBig = false
            cell.scrollView.setZoomScale(1.0, animated: false)
        }
        cell.photoBrowerImage = images[indexPath.item]
        cell.delegate = self
        return cell
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isForbittenScroll = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if !isForbittenScroll {
            let offsetX = scrollView.contentOffset.x + scrollView.bounds.width * 0.5
            let pageIndex = Int(offsetX / scrollView.bounds.width)
            pageLabel.text = "\(pageIndex + 1) / \(images.count)"
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let index = Int(offsetX / (scrollView.bounds.width))
        isReload = false
        if index != self.currentIndex {
            isReload = true
            collectionView.reloadData()
        }
        self.currentIndex = index
        
        self.selectBtn.tag = index
        let indexPath = IndexPath(item: index, section: 0)
        delegate?.photoBrowerVCWithScroll(indexPath: indexPath)
    }
}

// MARK: ----XJPhotoBrowerCellDelegate 代理
extension XJPhotoBrowerVC: XJPhotoBrowerCellDelegate {
    func cellWithTapGestureImageView(_ photoBrowerCell: XJPhotoBrowerCell) {
        dismiss(animated: true, completion: nil)
    }
    
    func cellWithLongGestureImageView(_ photoBrowerCell: XJPhotoBrowerCell) {
        let alertVC = UIAlertController(title: "", message: "善林（上海）金融信息服务有限公司", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "取消", style: .default) { (action) in }
        let saveAction = UIAlertAction(title: "保存图片", style: .default) { (_) in
            self.savePhotoToLocal()
        }
        alertVC.addAction(saveAction)
        alertVC.addAction(cancelAction)
        present(alertVC, animated: true, completion: nil)
    }
}

// MARK: ----对内的dismissDelegate要实现的方法 代理
extension XJPhotoBrowerVC: AnimatorDismissDelegate {
    func indexPathForDismissView() -> IndexPath {
        if let cell = collectionView.visibleCells.first as? XJPhotoBrowerCell {
            return collectionView.indexPath(for: cell)!
        }
        return IndexPath()
    }
    
    func imageViewForDismissView() -> UIImageView {
        if let cell = collectionView.visibleCells.first as? XJPhotoBrowerCell {
            let imageView = UIImageView()
            imageView.frame = cell.imgView.frame
            imageView.image = cell.imgView.image
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            return imageView 
        }
        return UIImageView()
    }
}

// MARK: ----对外的presentDelegate要实现的方法 代理
extension XJPhotoBrowerVC {
    func starRect(belowCollection: UICollectionView, indexPath: IndexPath) -> CGRect {
        self.belowCollectionView = belowCollection
        let cell = belowCollection.cellForItem(at: indexPath)
        let cellFrame = cell?.frame ?? CGRect.zero
        let starFrame = belowCollection.convert(cellFrame, to: UIApplication.shared.keyWindow)
        return starFrame
    }
    
    func endRect(indexPath: IndexPath) -> CGRect {
        let image = images[indexPath.item]
        let w : CGFloat = UIScreen.main.bounds.width
        let h : CGFloat = w / image.size.width * image.size.height
        var y : CGFloat = 0
        if h > UIScreen.main.bounds.height {
            y = 0
        }else {
            y = (UIScreen.main.bounds.height - h) * 0.5
        }
        return CGRect(x: 0, y: y, width: w, height: h)
    }
    
    func imageView(indexPath: IndexPath) -> UIImageView {
        let newImageView = UIImageView()
        let image = images[indexPath.item]
        newImageView.image = image
        newImageView.contentMode = .scaleAspectFill
        newImageView.clipsToBounds = true
        return newImageView
    }
}

extension XJPhotoBrowerVC {
    fileprivate func savePhotoToLocal() {
        guard let infoDic = Bundle.main.infoDictionary else { return  }
        let photoLibrary = infoDic["NSPhotoLibraryUsageDescription"]
        if photoLibrary == nil {
            print("XJ_想要使用保存照片,需要配置info? 你应该, 在info.plist 配置NSPhotoLibraryUsageDescription")
            return
        }
        let cell = collectionView.visibleCells.first as! XJPhotoBrowerCell
        guard let image = cell.imgView.image else { return }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(image:didFinishSavingWithError:contextInfo:)), nil)
    }
    @objc fileprivate func image(image: UIImage, didFinishSavingWithError error: Error?, contextInfo: Any) {
        if error != nil {
            print("保存失败")
        }else {
            print("保存成功")
        }
    }
    
    @objc fileprivate func cancelSelectClick() {
        let alertVC = UIAlertController(title: "", message: "要删除这张照片吗?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "删除", style: .default) { (action) in

            // 1: 根据按钮tag值得到下标
            let dele_i = self.selectBtn.tag
            let dele_indexPath = IndexPath(item: dele_i, section: 0)
            
            // 2: 删除数组值
            self.images.remove(at: dele_i)
            
            // 3: 重新设置page值
            var i: Int = 0
            if dele_i == 0{
                i = dele_i + 1
            }else{
                if self.images.count != dele_i {
                    i = dele_i + 1
                }else {
                    i = dele_i
                }
            }
            self.pageLabel.text = "\(i) / \(self.images.count)"
            
            // 4: 删除以后重新赋值按钮的tag值
            self.selectBtn.tag = i - 1
            
            // 5: 静止滑动
            self.isForbittenScroll = true
            
            // 6: 刷新表格
            self.collectionView.reloadData()
            
            // 7: 弹下大图展示
            if self.images.count == 0 {
                self.dismiss(animated: true, completion: nil)
            }
            
            // 8: 通知preVC传来的值同步
            self.delegate?.photoBrowerVCUpdataImages(indexPath: dele_indexPath, self.images)
            
        }
        let cancelAction = UIAlertAction(title: "取消", style: .default, handler: nil)
        alertVC.addAction(cancelAction)
        alertVC.addAction(okAction)
        self.present(alertVC, animated: true, completion: nil)
    }
}

class XJPhotoBrowerLayout: UICollectionViewFlowLayout {
    override func prepare() {
        super.prepare()
        itemSize = collectionView!.bounds.size
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        scrollDirection = .horizontal
        
        collectionView?.isPagingEnabled = true
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.bounces = false
    }
}
