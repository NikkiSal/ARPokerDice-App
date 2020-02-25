//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {
    
    //MARK: - Properties
    
    var trackingStatus: String = ""
    var diceNodes: [SCNNode] = []
    var focusNode: SCNNode!
    
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
        initSceneView()
        initScene()
        initARSession()
        loadModels() // do you need self?
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
    //MARK: - Inittialization
    
    func initSceneView() {
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [
            SCNDebugOptions.showFeaturePoints,
            SCNDebugOptions.showWorldOrigin,
            //SCNDebugOptions.showBoundingBoxes,
            //SCNDebugOptions.showWireframe
        ]
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
        sceneView.session.run(config)
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
}

extension ViewController: ARSCNViewDelegate {
    
    //MARK: - Scenekit Management
    
    // update the user on what's happening in the app
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.statusLabel.text = self.trackingStatus // huh?
        }
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
    
    
}






