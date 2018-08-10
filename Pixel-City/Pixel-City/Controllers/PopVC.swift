//
//  PopVC.swift
//  Pixel-City
//
//  Created by Jamil Jalal on 8/10/18.
//  Copyright © 2018 Jamil Jalal. All rights reserved.
//

import UIKit

class PopVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var popImageView: UIImageView!
    var passedImage:  UIImage!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        popImageView.image = passedImage
        addDoubleTap()
    }

    func initData(forImage image: UIImage){
        self.passedImage = image
    }
    
    func addDoubleTap(){
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(screenWasDoubleTaped))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)
    }
    
    @objc func screenWasDoubleTaped(){
        dismiss(animated: true, completion: nil)
    }
}
