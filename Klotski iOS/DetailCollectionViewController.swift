//
//  DetailCollectionViewController.swift
//  Klotski iOS
//
//  Created by James Coleman on 27/05/2019.
//  Copyright © 2019 James Coleman. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class DetailCollectionViewController: UICollectionViewController {

    var grids: [Grid] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return grids.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let grid = grids[indexPath.row]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        // Configure the cell
        
        cell.subviews.forEach { $0.removeFromSuperview() }
        
        cell.addSubview(grid.view)
    
        return cell
    }
}
