//
//  GraphViewController.swift
//  Calculator
//
//  Created by CAOYE on 9/6/16.
//  Copyright © 2016 CAOYE. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
            
            // a. Pinching (zooms the entire graph, including the axes, in or out on the graph)
            graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(zoom(_:))))
            
            // b. Panning (moves the entire graph, including the axes, to follow the touch around)
            graphView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(move(_:))))
            
            // c. Double-tapping (moves the origin of the graph to the point of the double tap)
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(center(_:)))
            recognizer.numberOfTapsRequired = 2 // single tap, double tap, etc.
            graphView.addGestureRecognizer(recognizer)
            
            resetStatistics()
            
            if !resetOrigin {
                graphView.origin = origin
            }
            graphView.scale = scale
        }
    }
    
    private struct Keys {
        static let Scale = "GraphViewController.Scale"
        static let Origin = "GraphViewController.Origin"
        static let SegueIdentifier = "Show Statistics"
    }
    
    // MARK - local variables
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    
    private var resetOrigin: Bool {
        get {
            if (defaults.objectForKey(Keys.Origin) as? [CGFloat]) != nil {
                return false
            }
            return true
        }
    }
    
    var scale: CGFloat {
        get { return defaults.objectForKey(Keys.Scale) as? CGFloat ?? 50.0 }
        set { defaults.setObject(newValue, forKey: Keys.Scale) }
    }
    
    private var origin: CGPoint {
        get {
            var origin = CGPoint()
            if let originArray = defaults.objectForKey(Keys.Origin) as? [CGFloat] {
                origin.x = originArray.first!
                origin.y = originArray.last!
            }
            return origin
        }
        set {
            defaults.setObject([newValue.x, newValue.y], forKey: Keys.Origin)
        }
    }
    
    // MARK - Gesture handlers
    
    func zoom(gesture: UIPinchGestureRecognizer) {
        graphView.zoom(gesture)
        if gesture.state == .Ended {
            resetStatistics()
            scale = graphView.scale
            origin = graphView.origin
        }
    }
    
    func move(gesture: UIPanGestureRecognizer) {
        graphView.move(gesture)
        if gesture.state == .Ended {
            resetStatistics()
            origin = graphView.origin
        }
    }
    
    func center(gesture: UITapGestureRecognizer) {
        graphView.center(gesture)
        if gesture.state == .Ended {
            resetStatistics()
            origin = graphView.origin
        }
    }
    
    func y(x: CGFloat) -> CGFloat? {
        model.variableValues["M"] = Double(x)
        if let y = model.evaluate() {
            if let minValue = statistics["min"] {
                statistics["min"] = min(minValue, y)
            } else {
                statistics["min"] = y
            }
            
            if let maxValue = statistics["max"] {
                statistics["max"] = max(maxValue, y)
            } else {
                statistics["max"] = y
            }
            
            if statistics["avg"] != nil {
                statistics["avg"] = statistics["avg"]! + y
                statistics["avgNum"] = statistics["avgNum"]! + 1
            } else {
                statistics["avg"] = y
                statistics["avgNum"] = 1
            }
            return CGFloat(y)
        }
        return nil
    }
    
    private var model = CalculatorModel()
    typealias PropertyList = AnyObject
    var program: PropertyList {
        get {
            return model.program
        }
        set {
            model.program = newValue
        }
    }
    
    // MARK - Popup
    
    // data
    private var statistics = [String: Double]()
    private func resetStatistics() {
        statistics["min"] = nil
        statistics["max"] = nil
        statistics["avg"] = nil
    }
    
    private func finishStatistics() {
        if let num = statistics["avgNum"] {
            if let avgValue = statistics["avg"] {
                statistics["avg"] = avgValue / num
                statistics["avgNum"] = nil
            }
        }
    }
    
    // popup segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifer = segue.identifier {
            switch identifer {
            case Keys.SegueIdentifier:
                if let tvc = segue.destinationViewController as? StatisticsViewController {
                    if let ppc = tvc.popoverPresentationController {
                        ppc.delegate = self
                    }
                    finishStatistics()
                    var texts = [String]()
                    for (key, value) in statistics {
                        texts += ["\(key) = \(value)"]
                    }
                    tvc.text = texts.count > 0 ? tvc.text + "\n \(texts)" : "none"
                }
            default: break
            }
        }
    }
    
    // popup delegate
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    // MARK - View Controller Life Cycle
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        resetStatistics()
    }
}
