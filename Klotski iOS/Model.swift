//
//  Model.swift
//  Klotski iOS
//
//  Created by James Coleman on 26/05/2019.
//  Copyright © 2019 James Coleman. All rights reserved.
//

import UIKit

/// This is a global constant to control the scale of the UIView representation of the puzzle.
let scale: CGFloat = 50

struct TestStruct: Codable {
    let string: String
    let point: CGPoint
}

enum Direction {
    case up, down, left, right
}

enum BlockType: Int {
    case big = 0 // 2x2 (the goal)
    case small   // 1x1
    case tall    // 1x2
    case wide    // 2x1
    
    /// Might not actually need this anymore?
    var width: Int {
        switch self {
        case .big:
            return 2
        case .small:
            return 1
        case .tall:
            return 1
        case .wide:
            return 2
        }
    }
    
    /// Might not actually need this anymore?
    var height: Int {
        switch self {
        case .big:
            return 2
        case .small:
            return 1
        case .tall:
            return 2
        case .wide:
            return 1
        }
    }
    
    var colour: UIColor {
        switch self {
        case .big:
            return .orange
        case .small:
            return .gray
        case .tall:
            return .darkGray
        case .wide:
            return .lightGray
        }
    }
    
    var text: String {
        switch self {
        case .big:
            return " B "
        case .small:
            return " s "
        case .tall:
            return " T "
        case .wide:
            return " W "
        }
    }
}

extension BlockType: Codable {
    enum Key: CodingKey {
        case rawValue
    }
    
    enum CodingError: Error {
        case unknownValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let rawValue = try container.decode(Int.self, forKey: .rawValue)
        
        guard let newSelf = BlockType(rawValue: rawValue) else { throw CodingError.unknownValue }
        
        self = newSelf
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(rawValue, forKey: .rawValue)
    }
}

extension CGPoint {
    var oneUp: CGPoint {
        return CGPoint(x: self.x, y: self.y - 1)
    }
    
    var oneDown: CGPoint {
        return CGPoint(x: self.x, y: self.y + 1)
    }
    
    var oneLeft: CGPoint {
        return CGPoint(x: self.x - 1, y: self.y)
    }
    
    var oneRight: CGPoint {
        return CGPoint(x: self.x + 1, y: self.y)
    }
    
    func compared(to otherPoint: CGPoint) -> Bool {
        if self.y == otherPoint.y {
            return self.x < otherPoint.x
        } else {
            return self.y < otherPoint.y
        }
    }
}

extension Array where Element == CGPoint {
    var sorted: [CGPoint] {
        return self.sorted { $0.compared(to: $1) }
    }
}

enum BlockError: Swift.Error {
    case doesNotApplyToBlockType(type: BlockType)
    case invalidOriginX(x: CGFloat)
}

struct Block {
    let type: BlockType
    
    let origin: CGPoint
    
    var occupiedPoints: [CGPoint] {
        switch type {
        case .big:
            return [origin,
                    origin.oneRight,
                    origin.oneDown,
                    origin.oneDown.oneRight]
        case .small:
            return [origin]
        case .tall:
            return [origin,
                    origin.oneDown]
        case .wide:
            return [origin,
                    origin.oneRight]
        }
    }
    
    var pointsAbove: [CGPoint] {
        switch type {
        case .big, .wide:
            return [origin.oneUp, origin.oneUp.oneRight]
        case .tall, .small:
            return [origin.oneUp]
        }
    }
    
    var pointsBelow: [CGPoint] {
        switch type {
        case .big:
            return [origin.oneDown.oneDown,
                    origin.oneDown.oneDown.oneRight]
        case .small:
            return [origin.oneDown]
        case .tall:
            return [origin.oneDown.oneDown]
        case .wide:
            return [origin.oneDown,
                    origin.oneDown.oneRight]
        }
    }
    
    var pointsRight: [CGPoint] {
        switch type {
        case .big:
            return [origin.oneRight.oneRight,
                    origin.oneRight.oneRight.oneDown]
        case .small:
            return [origin.oneRight]
        case .tall:
            return [origin.oneRight,
                    origin.oneRight.oneDown]
        case .wide:
            return [origin.oneRight.oneRight]
        }
    }
    
    var pointsLeft: [CGPoint] {
        switch type {
        case .big, .tall:
            return [origin.oneLeft,
                    origin.oneLeft.oneDown]
        case .small, .wide:
            return [origin.oneLeft]
        }
    }
    
    /// The points around the Block (where the block could move to)
    var surroundingPoints: [CGPoint] {
        return pointsAbove + pointsBelow + pointsRight + pointsLeft
    }
    
    func isAtExit() throws -> Bool {
        guard type == .big else { throw BlockError.doesNotApplyToBlockType(type: type) }
        
        return origin == CGPoint(x: 1, y: 3) // Could theoretically be at CGPoint(x: 1, y: 2) and exit if the route was clear underneath it?
    }
    
    func possibleDirections(freePoints: [CGPoint]) -> [Direction] {
        let sortedFreePoints = freePoints.sorted
        
        switch type {
        case .big:
            if sortedFreePoints == pointsAbove { return [.up] }
            if sortedFreePoints == pointsBelow { return [.down] }
            if sortedFreePoints == pointsLeft  { return [.left] }
            if sortedFreePoints == pointsRight { return [.right] }
        case .small:
            var directions: [Direction] = []
            
            if freePoints.contains(pointsAbove[0]) { directions += [.up] }
            if freePoints.contains(pointsBelow[0]) { directions += [.down] }
            if freePoints.contains(pointsLeft[0])  { directions += [.left] }
            if freePoints.contains(pointsRight[0]) { directions += [.right] }
            
            return directions
        case .tall:
            if sortedFreePoints == pointsLeft { return [.left] }
            if sortedFreePoints == pointsRight { return [.right] }
            
            var directions: [Direction] = []
            
            if freePoints.contains(pointsAbove[0]) { directions += [.up] }
            if freePoints.contains(pointsBelow[0]) { directions += [.down] }
            
            return directions
        case .wide:
            if sortedFreePoints == pointsAbove { return [.up] }
            if sortedFreePoints == pointsBelow { return [.down] }
            
            var directions: [Direction] = []
            
            if freePoints.contains(pointsLeft[0]) { directions += [.left] }
            if freePoints.contains(pointsRight[0]) { directions += [.right] }
            
            return directions
        }
        
        return []
    }
    
    func newBlock(inDirection direction: Direction) -> Block {
        switch direction {
        case .up:
            return Block(type: type, origin: origin.oneUp)
        case .down:
            return Block(type: type, origin: origin.oneDown)
        case .left:
            return Block(type: type, origin: origin.oneLeft)
        case .right:
            return Block(type: type, origin: origin.oneRight)
        }
    }
    
    /**
     Quick and dirty code to return a block which is horizontally symmetrical to this block.
     */
    func mirrorBlock() throws -> Block {
        let originX = origin.x
        
        switch type {
        case .small, .tall:
            switch originX {
            case 0:
                return Block(type: type, origin: CGPoint(x: 3, y: origin.y))
            case 1:
                return Block(type: type, origin: CGPoint(x: 2, y: origin.y))
            case 2:
                return Block(type: type, origin: CGPoint(x: 1, y: origin.y))
            case 3:
                return Block(type: type, origin: CGPoint(x: 0, y: origin.y))
            default:
                throw BlockError.invalidOriginX(x: originX)
            }
        case .big, .wide:
            switch originX {
            case 0:
                return Block(type: type, origin: CGPoint(x: 2, y: origin.y))
            case 1:
                return self
            case 2:
                return Block(type: type, origin: CGPoint(x: 0, y: origin.y))
            default:
                throw BlockError.invalidOriginX(x: originX)
            }
        }
    }
    
    /// A visual representation of the block to allow for easy debugging in a Playground
    var view: UIView {
        let view = UIView(frame: CGRect(x: (origin.x * scale) + scale, y: (origin.y * scale) + scale, width: CGFloat(type.width) * scale, height: CGFloat(type.height) * scale))
        view.backgroundColor = type.colour
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        
        return view
    }
}

extension Block: Equatable {} // This auto conforms because all properties are equatable

extension Block: Codable {}

extension Array where Element == Block {
    var sorted: [Block] {
        return self.sorted(by: { (block1, block2) -> Bool in
            return block1.origin.compared(to: block2.origin)
        })
    }
}

enum GridError: Swift.Error {
    case gridHasWrongNumberOfBigBlocks(grid: Grid, bigBlocksCount: Int)
}

struct Grid {
    let blocks: [Block]
    let previousGenerationsUUIDs: [String]
    let uuid: String
    let generation: Int
    
    var freePoints: [CGPoint]!
    var blocksThatMightMove: [Block]!
    
    var possibleNextGrids: [Grid] {
        return blocksThatMightMove.flatMap { $0.possibleNextGrids(from: self) }
    }
    
    func isSolved() throws -> Bool {
        let bigBlocks = blocks.filter { $0.type == .big }
        
        guard bigBlocks.count == 1, let bigBlock = bigBlocks.first else { throw GridError.gridHasWrongNumberOfBigBlocks(grid: self, bigBlocksCount: bigBlocks.count) }
        
        return bigBlock.origin == CGPoint(x: 1, y: 3) || (bigBlock.origin == CGPoint(x: 1, y: 2) && freePoints.sorted == [CGPoint(x: 1, y: 4), CGPoint(x: 2, y: 4)].sorted)
        
        //        return try bigBlock.isAtExit()
    }
    
    func mirrorGrid() throws -> Grid {
        return try Grid(blocks: blocks.map { try $0.mirrorBlock() }, previousGenerationsUUIDs: previousGenerationsUUIDs, generation: generation)
    }
    
    func blockAt(point: CGPoint) -> Block? {
        return blocks.first { $0.occupiedPoints.contains(point) }
    }
    
    init(blocks: [Block], previousGenerationsUUIDs: [String], generation: Int = 0, uuid: String = UUID().uuidString) {
        let blocksSorted = blocks.sorted
        
        self.blocks = blocksSorted
        self.previousGenerationsUUIDs = previousGenerationsUUIDs
        self.uuid = uuid
        self.generation = generation
        
        // I can't find a clean way of making the freePoints and blocksThatMightMove into lazy computed constants,
        // so this is my solution.
        // It will be calculated every time a Grid is instantaited,
        // but will definitely only be done once.
        
        let allOccupiedPoints = blocksSorted.flatMap { $0.occupiedPoints }
        freePoints = Grid.allPoints.filter { allOccupiedPoints.contains($0) == false }
        
        blocksThatMightMove = blocksSorted.filter { block in
            block.surroundingPoints.contains(where: { (point) -> Bool in
                return freePoints.contains(point)
            })
        }
    }
    
    /// A visual representation of the puzzle.
    /// Allows it to be viewed and verified in a playground.
    var view: UIView {
        let background = UIView(frame: CGRect(x: 0, y: 0, width: 6 * scale, height: 7 * scale))
        background.backgroundColor = .black
        
        let centre = UIView(frame: CGRect(x: scale, y: scale, width: 4 * scale, height: 5 * scale))
        centre.backgroundColor = .white
        background.addSubview(centre)
        
        let exit = UIView(frame: CGRect(x: 2 * scale, y: 6 * scale, width: 2 * scale, height: scale))
        exit.backgroundColor = .white
        background.addSubview(exit)
        
        blocks.forEach { block in
            background.addSubview(block.view)
        }
        
        return background
    }
    
    static var startingGrid: Grid {
        return Grid(blocks: [Block(type: .tall,  origin: CGPoint(x: 0, y: 0)),
                             Block(type: .big,   origin: CGPoint(x: 1, y: 0)),
                             Block(type: .tall,  origin: CGPoint(x: 3, y: 0)),
                             Block(type: .tall,  origin: CGPoint(x: 0, y: 2)),
                             Block(type: .wide,  origin: CGPoint(x: 1, y: 2)),
                             Block(type: .tall,  origin: CGPoint(x: 3, y: 2)),
                             Block(type: .small, origin: CGPoint(x: 1, y: 3)),
                             Block(type: .small, origin: CGPoint(x: 2, y: 3)),
                             Block(type: .small, origin: CGPoint(x: 0, y: 4)),
                             Block(type: .small, origin: CGPoint(x: 3, y: 4))],
                    previousGenerationsUUIDs: [])
    }
    
    static var allPoints: [CGPoint] {
        return [Int](0...3).flatMap { x in
            return [Int](0...4).map { y in
                return CGPoint(x: x, y: y)
            }
        }
    }
}

extension Grid: Equatable {
    static func ==(lhs: Grid, rhs: Grid) -> Bool {
        return lhs.blocks == rhs.blocks
    }
}

extension Grid: CustomStringConvertible {
    var description: String {
        var string = """
        ■  ■  ■  ■  ■  ■
        
        """ + "■ "
        
        for point in Grid.allPoints.sorted {
            if let block = blockAt(point: point) {
                string += block.type.text
            } else {
                string += "   "
            }
            
            if point.x == 3 {
                string += " ■\n■ "
            }
            
            if point == CGPoint(x: 3, y: 4) {
                string += " ■        ■  ■"
            }
        }
        
        return string
    }
}

extension Grid: Codable {}

extension Block {
    /// Get the possible directions this block can move in
    /// Filter out this block from the input Grid
    /// Add in the new block(s) to the output Grid
    func possibleNextGrids(from oldGrid: Grid) -> [Grid] {
        let nextDirections = possibleDirections(freePoints: oldGrid.freePoints)
        if nextDirections.isEmpty { return [] } // Guard against an empty array of next directions
        
        let nextGrids = nextDirections.map { direction -> Grid in
            let newBlock = self.newBlock(inDirection: direction)
            var newBlocks = oldGrid.blocks.filter { $0 != self }
            newBlocks += [newBlock]
            return Grid(blocks: newBlocks, previousGenerationsUUIDs: oldGrid.previousGenerationsUUIDs + [oldGrid.uuid], generation: oldGrid.generation + 1)
        }
        
        return nextGrids
    }
}

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct GridGeneration {
    let generation: Int
    let grids: [Grid]
}

extension GridGeneration: Codable {}

extension Grid {
    static func recursiveSolve(startingGrids: [Grid], stopAtGeneration: Int, currentGeneration: Int = 0, knownGrids: [Grid] = [], knownMirrorGrids: [Grid] = [], startTime: Date = Date(), previousGenerations: [GridGeneration] = []) throws -> [GridGeneration] {
        let thisGenerationStartTime = Date()
        
        if currentGeneration == stopAtGeneration {
            return previousGenerations
        }
        
        if startingGrids == [] {
            return previousGenerations
        }
        
        for grid in startingGrids {
            if try grid.isSolved() {
                return previousGenerations
            }
        }
        
        var newStartingGrids = [Grid]()
        var newKnownGrids = knownGrids + startingGrids
        var newKnownMirrorGrids = knownMirrorGrids
        
        outerLoop: for grid in startingGrids {
            let nextGenGrids = grid.possibleNextGrids
            innerLoop: for newGrid in nextGenGrids {
                if newKnownGrids.contains(newGrid) || newKnownMirrorGrids.contains(newGrid) {
                    //                    print("Either \n", newKnownGrids, "\n or \n", newKnownMirrorGrids, "\n contains the new grid \n", newGrid, "\n")
                    continue innerLoop
                } else {
                    //                    print("Neither \n", newKnownGrids, "\n nor \n", newKnownMirrorGrids, "\n contain the new grid \n", newGrid, "\n")
                    let mirrorGrid = try newGrid.mirrorGrid()
                    if newKnownGrids.contains(mirrorGrid) || newKnownMirrorGrids.contains(mirrorGrid) { // Use the new arrays because they will be updated for this generation
                        //                        print("Either \n", newKnownGrids, "\n or \n", newKnownMirrorGrids, "\n contains the mirrored grid \n", mirrorGrid, "\n")
                        continue innerLoop
                    } else {
                        //                        print("Neither \n", newKnownGrids, "\n nor \n", newKnownMirrorGrids, "\n contain the mirrored grid \n", mirrorGrid, "\n")
                        newStartingGrids += [newGrid]
                        newKnownGrids += [newGrid]
                        newKnownMirrorGrids += [mirrorGrid]
                    }
                }
            }
        }
        
        let newGeneration = GridGeneration(generation: currentGeneration, grids: newStartingGrids)
        let startGenerations = previousGenerations.count == 0 ? [GridGeneration(generation: currentGeneration, grids: startingGrids)] : []
        let newGenerations = startGenerations + previousGenerations + [newGeneration]
        
        let endTime = Date()
        
        let totalTimeTaken = endTime.timeIntervalSince(startTime)
        let thisGenerationTimeTaken = endTime.timeIntervalSince(thisGenerationStartTime)
        
        print("""
            \(newStartingGrids.count) grids in generation \(currentGeneration + 1)
            found in
            \(totalTimeTaken) total seconds
            \(thisGenerationTimeTaken) seconds since last generation
            
            """)
        
        return try Grid.recursiveSolve(startingGrids: newStartingGrids, stopAtGeneration: stopAtGeneration, currentGeneration: currentGeneration + 1, knownGrids: newKnownGrids, knownMirrorGrids: newKnownMirrorGrids, startTime: startTime, previousGenerations: newGenerations)
    }
}
