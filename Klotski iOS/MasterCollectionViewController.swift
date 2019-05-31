//
//  MasterCollectionViewController.swift
//  Klotski iOS
//
//  Created by James Coleman on 27/05/2019.
//  Copyright © 2019 James Coleman. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class MasterCollectionViewController: UICollectionViewController {

    var gridGenerations: [GridGeneration] = []
    
    var individualGrids: [String: Grid] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let targetGeneration = 150
        
        let path = Bundle.main.path(forResource: "Klotski", ofType: "json")
        
        if let path = path {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode([GridGeneration].self, from: data)
                
                if decodedData.count < targetGeneration + 1 { // +1 due to generation 0 making the count 1 higher than the generation.
                    if let lastGeneration = decodedData.last {
                        let allGrids = decodedData.flatMap { $0.grids }
                        
                        let newGenerations = try Grid.recursiveSolve(startingGrids: lastGeneration.grids, stopAtGeneration: targetGeneration, currentGeneration: lastGeneration.generation + 1, knownGrids: allGrids)
                        
                        let allGenerations = decodedData + newGenerations
                        
                        gridGenerations = allGenerations
                        
                        save(gridGenerations: allGenerations)
                    } else {
                        let gridGenerations = try Grid.recursiveSolve(startingGrids: [Grid.startingGrid], stopAtGeneration: targetGeneration)
                        self.gridGenerations = gridGenerations
                        
                        save(gridGenerations: gridGenerations)
                    }
                } else {
                    gridGenerations = decodedData
                }
            } catch {
                print(error)
            }
        } else {
            do {
                let gridGenerations = try Grid.recursiveSolve(startingGrids: [Grid.startingGrid], stopAtGeneration: targetGeneration)
                self.gridGenerations = gridGenerations
                
                save(gridGenerations: gridGenerations)
            } catch {
                print(error)
            }
        }
        
        let allGrids = gridGenerations.flatMap { $0.grids }
        
        allGrids.forEach { individualGrids[$0.uuid] = $0 }
        
        gridGenerations.reverse()
        
        collectionView.reloadData()
    
    }
    
    func save(gridGenerations: [GridGeneration]) {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(gridGenerations)
            
            if let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Klotski.json") {
                try encodedData.write(to: documentURL)
            }
            
        } catch {
            print(error)
        }

    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return gridGenerations.count
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
        
        header.subviews.forEach { $0.removeFromSuperview() }
        
        let generation = gridGenerations[indexPath.section]
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: header.frame.width, height: header.frame.height))
        label.text = "Generation \(generation.generation)"
        
        header.addSubview(label)
        
        return header
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let generation = gridGenerations[section]
        return generation.grids.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let grid = gridGenerations[indexPath.section].grids[indexPath.row]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        cell.subviews.forEach { $0.removeFromSuperview() }
        cell.addSubview(grid.view)
        
        return cell
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        guard let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first else { return }
        
        switch segue.identifier {
        case "showDetail":
            guard let destination = segue.destination as? DetailCollectionViewController else { break }
            let selectedGrid = gridGenerations[selectedIndexPath.section].grids[selectedIndexPath.row]
            let previousGrids = individualGrids
                .filter { selectedGrid.previousGenerationsUUIDs.contains($0.key) }
                .map { $0.value }
                .sorted { $0.generation < $1.generation }
            destination.grids = previousGrids + [selectedGrid]
        default:
            break
        }
    }
}
