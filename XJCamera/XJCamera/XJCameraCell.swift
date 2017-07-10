//
//  XJCameraCell.swift
//  XJCameraSerial
//
//  Created by 李胜兵 on 2017/6/6.
//  Copyright © 2017年 shanlin. All rights reserved.
//

import UIKit

class XJCameraCell: UICollectionViewCell {
    
    
    fileprivate lazy var closeBtn: UIButton = UIButton()
    lazy var imageV: UIImageView = UIImageView()
    
    typealias XJCameraCellBlock = (_ indexP: IndexPath?) -> ()
    var myblock: XJCameraCellBlock?
    var indexPath: IndexPath?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension XJCameraCell {
    fileprivate func setupUI() {
        addSubview(imageV)
        imageV.frame = bounds
        imageV.contentMode = .scaleAspectFill
        imageV.clipsToBounds = true
        imageV.isUserInteractionEnabled = true
        
        
        closeBtn.isUserInteractionEnabled = true
        closeBtn.setImage(UIImage(named: "XJCameraBundle.bundle/close"), for: .normal)
        imageV.addSubview(closeBtn)
        closeBtn.sizeToFit()
        closeBtn.frame = CGRect(x: imageV.bounds.width - closeBtn.bounds.width - 1, y: 1, width: closeBtn.bounds.width, height: closeBtn.bounds.width)
        closeBtn.addTarget(self, action: #selector(closeClick), for: .touchUpInside)
        
    }
}

extension XJCameraCell {
    @objc fileprivate func closeClick() {
        if myblock != nil {
            myblock!(indexPath)
            
        }
    }
}
