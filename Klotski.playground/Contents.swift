import UIKit
import PlaygroundSupport

var str = "Hello, playground"

let encoder = JSONEncoder()
let decoder = JSONDecoder()

struct TestStruct: Codable {
    let string: String
    let point: CGPoint
}

do {
    let testData = try encoder.encode(TestStruct(string: "Test String", point: CGPoint(x: 0, y: 0)))
    testData.base64EncodedString()
    String(data: testData, encoding: .utf8)
    try decoder.decode(TestStruct.self, from: testData)
} catch {
    print(error)
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

do {
    if let block = BlockType(rawValue: 0) {
        let testData = try encoder.encode(block)
        testData.base64EncodedString()
        String(data: testData, encoding: .utf8)
        try decoder.decode(BlockType.self, from: testData)
    }
} catch {
    print(error)
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

/// This is a global constant to control the scale of the UIView representation of the puzzle.
let scale: CGFloat = 50

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

do {
    let testData = try encoder.encode(Block(type: .tall, origin: CGPoint(x: 0, y: 0)))
    testData.base64EncodedString()
    String(data: testData, encoding: .utf8)
    try decoder.decode(Block.self, from: testData)
} catch {
    print(error)
}

extension Array where Element == Block {
    var sorted: [Block] {
        return self.sorted(by: { (block1, block2) -> Bool in
            return block1.origin.compared(to: block2.origin)
        })
    }
}

Block(type: .tall, origin: CGPoint(x: 0, y: 0)) == Block(type: .tall, origin: CGPoint(x: 0, y: 0))
Block(type: .tall, origin: CGPoint(x: 0, y: 0)) == Block(type: .tall, origin: CGPoint(x: 0, y: 1)) // Move origin and it's not equal
Block(type: .tall, origin: CGPoint(x: 0, y: 0)) == Block(type: .wide, origin: CGPoint(x: 0, y: 0)) // Change type and it's not equal

enum GridError: Swift.Error {
    case gridHasWrongNumberOfBigBlocks(grid: Grid, bigBlocksCount: Int)
}

struct Grid {
    let blocks: [Block]
    let previousGenerations: [Grid]
    
    var freePoints: [CGPoint]!
    var blocksThatMightMove: [Block]!
    
    /*
    lazy var freePointsCalc: [CGPoint] = {
        print("Calculating free points")
        let allOccupiedPoints = blocks.flatMap { $0.occupiedPoints }
        return Grid.allPoints.filter { allOccupiedPoints.contains($0) == false }
    }()
    
    lazy var blocksThatMightMoveCalc: [Block] = {
        print("Calculating blocks that might move")
        return blocks.filter { block in
            block.surroundingPoints.contains(where: { (point) -> Bool in
                var selfCopy = self
                return selfCopy.freePoints.contains(point)
            })
        }
    }()
    */
    
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
        return try Grid(blocks: blocks.map { try $0.mirrorBlock() }, previousGenerations: previousGenerations)
    }
    
    func blockAt(point: CGPoint) -> Block? {
        return blocks.first { $0.occupiedPoints.contains(point) }
    }
    
    init(blocks: [Block], previousGenerations: [Grid]) {
        let blocksSorted = blocks.sorted
        
        self.blocks = blocksSorted
        self.previousGenerations = previousGenerations
        
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
                    previousGenerations: [])
    }
    
    static var allPoints: [CGPoint] {
        return [Int](0...3).flatMap { x in
            return [Int](0...4).map { y in
                return CGPoint(x: x, y: y)
            }
        }
    }
    
    static func recursiveSolve(startingGrids: [Grid], stopAtGeneration: Int, currentGeneration: Int = 0, knownGrids: [Grid] = [], knownMirrorGrids: [Grid] = [], startTime: Date = Date()) throws -> [Grid] {
        let thisGenerationStartTime = Date()
        
        if currentGeneration == stopAtGeneration {
            return startingGrids
        }
        
        for grid in startingGrids {
            if try grid.isSolved() {
                return [grid]
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
        
        let endTime = Date()
        
        let totalTimeTaken = endTime.timeIntervalSince(startTime)
        let thisGenerationTimeTaken = endTime.timeIntervalSince(thisGenerationStartTime)
        
        print("""
            \(newStartingGrids.count) grids in generation \(currentGeneration + 1)
            found in
            \(totalTimeTaken) total seconds
            \(thisGenerationTimeTaken) seconds since last generation
            
            """)
        
        return try Grid.recursiveSolve(startingGrids: newStartingGrids, stopAtGeneration: stopAtGeneration, currentGeneration: currentGeneration + 1, knownGrids: newKnownGrids, knownMirrorGrids: newKnownMirrorGrids, startTime: startTime)
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

do {
    let testData = try encoder.encode(Grid.startingGrid)
    testData.base64EncodedString()
    String(data: testData, encoding: .utf8)
    let testGrid = try decoder.decode(Grid.self, from: testData)
    testGrid.freePoints
} catch {
    print(error)
}


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
            return Grid(blocks: newBlocks, previousGenerations: oldGrid.previousGenerations + [oldGrid])
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

do {
    let testData = try encoder.encode(GridGeneration(generation: 0, grids: [Grid.startingGrid]))
    testData.base64EncodedString()
    String(data: testData, encoding: .utf8)
    let testGrid = try decoder.decode(GridGeneration.self, from: testData)
} catch {
    print(error)
}

/// This has to be a var due to the lazy vars inside it.
var startingGrid = Grid.startingGrid
//print(startingGrid)
startingGrid.freePoints
startingGrid.blocksThatMightMove
Grid.allPoints.sorted

//for point in Grid.allPoints.sorted {
//    print(point)
//    print("x: \(point.x) y: \(point.y)")
//}

//PlaygroundPage.current.liveView = startingGrid.view

//let generation1Grids = startingGrid.blocks
//                        .flatMap { $0.possibleNextGrids(from: startingGrid) }


let generation1Grids = startingGrid.possibleNextGrids
generation1Grids

//generation1Grids.forEach { print($0, "\n") }

/*
if let testGen1 = generation1Grids[safe: 0] {
    PlaygroundPage.current.liveView = testGen1.view
    
    let generation2Grids = testGen1.possibleNextGrids
    
    if let testGen2 = generation2Grids[safe: 4] {
        testGen2.blocks
        //        PlaygroundPage.current.liveView = testGen2.view
        
        do {
            let mirror = try testGen2.mirrorGrid()
            //            PlaygroundPage.current.liveView = mirror.view
        } catch {
            print(error)
        }
    }
}
*/

//let before = Date()

do {
    let generation = 2
    
    let gridGeneration = try Grid.recursiveSolve(startingGrids: [startingGrid], stopAtGeneration: generation)
    
//    let timeTaken = Date().timeIntervalSince(before)
    
    if let chosenGrid = gridGeneration[safe: 2] {
        PlaygroundPage.current.liveView = chosenGrid.view
    }
    
//    print("--- Final Answer ---")
    
//    gridGeneration.forEach { print($0, "\n") }
    
//    print("\(timeTaken) seconds taken")
//    print("\(gridGeneration.count) grids in generation \(generation)")
} catch {
    print(error)
}

Block(type: .wide, origin: CGPoint(x: 3, y: 4)).occupiedPoints

let onePoint = CGPoint(x: 1, y: 2)
let twoPoint = CGPoint(x: 1, y: 2)

onePoint == twoPoint

let threePoint = CGPoint(x: 1, y: 3)

onePoint == threePoint

let pointArray = [onePoint, twoPoint]
pointArray.contains(onePoint)
pointArray.contains(threePoint)

let differentPointArray = [onePoint, threePoint]
let reversedPointArray = [threePoint, onePoint]
differentPointArray == reversedPointArray
differentPointArray.sorted == reversedPointArray.sorted

let aBlock = Block(type: .tall, origin: CGPoint(x: 0, y: 0))
let bBlock = Block(type: .big, origin: CGPoint(x: 1, y: 0))

[aBlock, bBlock] == [bBlock, aBlock]

//let pointSet = Set(arrayLiteral: onePoint, twoPoint) // CGPoint is not Hashable

let testGrid1 = Grid(blocks: [Block(type: .tall,  origin: CGPoint(x: 0, y: 0)),
                             Block(type: .big,   origin: CGPoint(x: 1, y: 0)),
                             Block(type: .tall,  origin: CGPoint(x: 3, y: 0)),
                             Block(type: .tall,  origin: CGPoint(x: 0, y: 2)),
                             Block(type: .wide,  origin: CGPoint(x: 1, y: 2)),
                             Block(type: .tall,  origin: CGPoint(x: 3, y: 2)),
                             Block(type: .small, origin: CGPoint(x: 1, y: 3)),
                             Block(type: .small, origin: CGPoint(x: 2, y: 4)), // 2,3 became 2,4
                             Block(type: .small, origin: CGPoint(x: 0, y: 4)),
                             Block(type: .small, origin: CGPoint(x: 3, y: 4))],
                     previousGenerations: [])

let testGrid2 = Grid(blocks: [Block(type: .tall,  origin: CGPoint(x: 0, y: 0)),
                              Block(type: .big,   origin: CGPoint(x: 1, y: 0)),
                              Block(type: .tall,  origin: CGPoint(x: 3, y: 0)),
                              Block(type: .tall,  origin: CGPoint(x: 0, y: 2)),
                              Block(type: .wide,  origin: CGPoint(x: 1, y: 2)),
                              Block(type: .tall,  origin: CGPoint(x: 3, y: 2)),
                              Block(type: .small, origin: CGPoint(x: 1, y: 3)),
                              Block(type: .small, origin: CGPoint(x: 2, y: 4)), // 2,3 became 2,4
    Block(type: .small, origin: CGPoint(x: 0, y: 4)),
    Block(type: .small, origin: CGPoint(x: 3, y: 4))],
                     previousGenerations: [])

let testGrid3Blocks = [Block(type: .tall,  origin: CGPoint(x: 0, y: 0)),
                       Block(type: .big,   origin: CGPoint(x: 1, y: 0)),
                       Block(type: .tall,  origin: CGPoint(x: 3, y: 0)),
                       Block(type: .tall,  origin: CGPoint(x: 0, y: 2)),
                       Block(type: .wide,  origin: CGPoint(x: 1, y: 2)),
                       Block(type: .tall,  origin: CGPoint(x: 3, y: 2)),
                       Block(type: .small, origin: CGPoint(x: 2, y: 4)), // 2,3 became 2,4. Moved up in array
    Block(type: .small, origin: CGPoint(x: 1, y: 3)),
    Block(type: .small, origin: CGPoint(x: 0, y: 4)),
    Block(type: .small, origin: CGPoint(x: 3, y: 4))]

let testGrid3BlocksSorted = testGrid3Blocks.sorted

testGrid3Blocks == testGrid3BlocksSorted

let testGrid3BlocksSortedSorted = testGrid3BlocksSorted.sorted

testGrid3BlocksSorted == testGrid3BlocksSortedSorted

let testGrid3 = Grid(blocks: testGrid3Blocks, previousGenerations: [])

testGrid3.blocks == testGrid3Blocks

testGrid3.blocks == testGrid3BlocksSorted

testGrid2.blocks == testGrid3BlocksSorted

//PlaygroundPage.current.liveView = testGrid1.view

testGrid1 == testGrid2
testGrid1 == testGrid3

testGrid1.blocks == testGrid3.blocks
testGrid1.blocksThatMightMove == testGrid3.blocksThatMightMove
testGrid1.freePoints == testGrid3.freePoints

[testGrid1].contains(testGrid2)
[testGrid1].contains(testGrid3)
