//
//  UIHelpers.swift
//  MQTTool
//
//  Created by Brent Petit on 3/5/16.
//  Copyright © 2016-2019 Brent Petit. All rights reserved.
//

import Foundation
import UIKit

class GradientView: UIView {
    
    let startColor = UIColor(red: (74/255), green: (144/255), blue: (226/255), alpha: 1.0)
    let endColor = UIColor(red: (24/255), green: (94/255), blue: (176/255), alpha: 1.0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        guard let theLayer = self.layer as? CAGradientLayer else {
            return;
        }
        
        theLayer.colors = [startColor.cgColor, endColor.cgColor]
        theLayer.frame = self.bounds
    }
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
}
