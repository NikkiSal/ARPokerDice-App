//

import UIKit
import SceneKit
import ARKit

//MARK: - Game state

enum GameState: Int16 {
    case detectSurface
    case pointToSurface
    case swipeToPlay
}

class ViewController: UIViewController {
    
    //MARK: - Properties
    
    var gameState: GameState = .detectSurface
    var trackingStatus: String = ""
    var statusMessage: String = ""
    
    var diceNodes: [SCNNode] = []
    var focusNode: SCNNode!
    var focusPoint:CGPoint!
    var diceCount: Int = 5
    var diceStyle: Int = 0
    var diceOffset: [SCNVector3] = [
        SCNVector3(0.0, 0.0, 0.0),
        SCNVector3(-0.15, 0.0, 0.0),
        SCNVector3(0.15, 0.0, 0.0),
        SCNVector3(-0.15, 0.15, 0.12),
        SCNVector3(0.15, 0.15, 0.12)
    ]
    
    //MARK: - Outlets
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var styleButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    //MARK: - Actions
    
    @IBAction func styleButtonPressed(_ sender: Any) {
        diceStyle = diceStyle >= 4 ? 0 : diceStyle + 1 // loops through the styles
        print("Style pressed")
    }
    
    @IBAction func resetButtonPressed(_ sender: Any) {
    }
    
    @IBAction func swipeUpGestureHandler(_ sender: Any) {
        guard let frame = self.sceneView.session.currentFrame else {return}
        for count in 0..<diceCount {
            throwDiceNode(transform: SCNMatrix4(frame.camera.transform), offset: diceOffset[count]) // don't understand transform
        }
    }
    
    //MARK: - View Management
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initSceneView()
        self.initCoachingOverlayView()
        self.initScene()
        self.initARSession()
        self.loadModels() // do you need self?
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("*** ViewWillAppear()")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("*** ViewWillDisappear()")
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func orientationChanged() {
        focusPoint = CGPoint(x: view.center.x , y: view.center.y + view.center.y * 0.25)
    }
    //MARK: - Inittialization
    
    func initSceneView() {
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [
//            SCNDebugOptions.showFeaturePoints,
//            SCNDebugOptions.showWorldOrigin,
            //SCNDebugOptions.showBoundingBoxes,
            //SCNDebugOptions.showWireframe
        ]
        
        focusPoint = CGPoint(x: view.center.x, y: view.center.y + view.center.y * 0.25)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    func initScene() {
        let scene = SCNScene() // tostart off with an empty scene.
        scene.isPaused = false
        sceneView.scene = scene
    }
    
    func initARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            print("*** ARConfig: AR World Tracking Not Supported")
            return
        }
        
        let config = ARWorldTrackingConfiguration()
        config.environmentTexturing = .automatic // setting up an environment map for your AR scene.
        config.worldAlignment = .gravity
        config.providesAudioData = false
        config.planeDetection = .horizontal
        sceneView.session.run(config)
    }
    
    func initCoachingOverlayView() {
        
        //initialize
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = self.sceneView.session
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.delegate = self
        self.sceneView.addSubview(coachingOverlay)
        
        //add constraints
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([NSLayoutConstraint(item: coachingOverlay, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: coachingOverlay, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0),
         NSLayoutConstraint(item: coachingOverlay, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0),
         NSLayoutConstraint(item: coachingOverlay, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
        ])
        
    }
    //MARK: - Load Models
    
    func loadModels() {
        let diceScene = SCNScene(named: "PokerDice.scnassets/Models/DiceScene.scn")!
        for count in 0..<5 {
            diceNodes.append(diceScene.rootNode.childNode(withName: "dice\(count)", recursively: false)!)
        }
        
        let focusScene = SCNScene(named: "PokerDice.scnassets/Models/FocusScene.scn")!
        focusNode = focusScene.rootNode.childNode(withName: "focus", recursively: false)!
        sceneView.scene.rootNode.addChildNode(focusNode)
    }
    //MARK: - Helper Functions
    
    func throwDiceNode(transform: SCNMatrix4, offset: SCNVector3) { // don't understand this!
        let position = SCNVector3(transform.m41 + offset.x,
                                  transform.m42 + offset.y,
                                  transform.m43 + offset.z)
        
        let diceNode = diceNodes[diceStyle].clone()
        diceNode.name = "dice"
        diceNode.position = position
        
        sceneView.scene.rootNode.addChildNode(diceNode)
        //diceCount -= 1
    }
    
    func createARPlaneNode(planeAnchor: ARPlaneAnchor, color: UIColor) -> SCNNode {
        
        let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height:CGFloat(planeAnchor.extent.z))
        
        //material
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = "PokerDice.scnassets/Textures/Surface_DIFFUSE.png"
        planeGeometry.materials = [planeMaterial]
        
        //node
        let planeNode = SCNNode(geometry: planeGeometry)
        // anchor's center point
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        // by default the SCNPlane is upright, so it needs to be rotated by 90 around the x-axis
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0,0)
        
        return planeNode
    }
    
    func updateARPlaneNode(planeNode: SCNNode, planeAnchor: ARPlaneAnchor) {
        let planeGeometry = planeNode.geometry as! SCNPlane // huh?
        planeGeometry.width = CGFloat(planeAnchor.extent.x)
        planeGeometry.height = CGFloat(planeAnchor.extent.z)
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0 , planeAnchor.center.z)
    }
    
      func removeARPlaneNode(node: SCNNode) {
        for childNode in node.childNodes {
            childNode.removeFromParentNode()
        }
    }
    
    
    func updateFocusNode () {
        let results = self.sceneView.hitTest(self.focusPoint, types: [.existingPlaneUsingExtent])
        if results.count == 1 {
            if let match = results.first {
                let t = match.worldTransform
                self.focusNode.position = SCNVector3(x:t.columns.3.x, y: t.columns.3.y, z: t.columns.3.z)
                self.gameState = .swipeToPlay
                focusNode.isHidden = false
            }
        } else {
            self.gameState = .pointToSurface
            focusNode.isHidden = true
        }
    }
    
   
    
    
    
    
}

extension ViewController: ARCoachingOverlayViewDelegate {
    
    //MARK: - AR Coaching Overlay View
    
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        
    }
    
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        
    }
    
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        
    }
}

extension ViewController: ARSCNViewDelegate {
    
    //MARK: - Scenekit Management
    
    // update the user on what's happening in the app
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            // self.statusLabel.text = self.trackingStatus // huh?
            self.updateStatus()
            self.updateFocusNode()
        }
    }
    
    func updateStatus() {
        switch gameState {
        case .detectSurface:
            statusMessage = "Scan entire table surface..."
        case .pointToSurface:
            statusMessage = "Point at the designated surface first"
        case .swipeToPlay:
            statusMessage = "Swipe Up to throw!\nTap dice to collect"
        }
        statusLabel.text = trackingStatus != "" ? "\(trackingStatus)" : "\(statusMessage)"
    }
    
    //MARK: - Session State Management
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            trackingStatus = "Tracking: Not available"
            break
        case .normal:
            trackingStatus = ""
            break
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                trackingStatus = "Tracking: Limited due to excessie motion!"
            case .insufficientFeatures:
                trackingStatus = "Tracking: Limited due to insufficient features!"
            case .initializing:
                trackingStatus = "Tracking: Initializing..."
            case .relocalizing:
                trackingStatus = "Tracking: Relocalizing..."
            @unknown default:
                trackingStatus = "Tracking: unknown..."
            }
        }
    }
    
    //MARK: - Session Error Management
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        trackingStatus = "AR Session Failure: \(error)"
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        trackingStatus = "AR Session Was Interrupted!"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        trackingStatus = "AR Session Interruption Ended"
    }
    
    //MARK: - Plane Management
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return} // only interested in this anchor
        DispatchQueue.main.async { // visual components only can be created within the main thread.
            let planeNode = self.createARPlaneNode(planeAnchor: planeAnchor, color: UIColor.yellow.withAlphaComponent(0.5))
            node.addChildNode(planeNode)
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            self.updateARPlaneNode(planeNode: node.childNodes[0], planeAnchor: planeAnchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return} // interesting
        DispatchQueue.main.async {
            self.removeARPlaneNode(node: node)
        }
    }
    
}








