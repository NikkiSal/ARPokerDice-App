//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {
    
    //MARK: - Properties
    
    var trackingStatus : String = ""
    
    //MARK: - Outlets
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var styleButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    //MARK: - Actions
    
    @IBAction func styleButtonPressed(_ sender: Any) {
    }
    
    @IBAction func resetButtonPressed(_ sender: Any) {
    }
    
    //MARK: - View Management
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSceneView()
        initScene()
        initARSession()
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
            SCNDebugOptions.showBoundingBoxes,
            SCNDebugOptions.showWireframe
        ]
    }
    
    func initScene() {
        let scene = SCNScene(named: "PokerDice.scnassets/SimpleScene.scn")!
        scene.isPaused = false
        sceneView.scene = scene
    }
    
    func initARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            print("*** ARConfig: AR World Tracking Not Supported")
            return
        }
        
        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravity
        config.providesAudioData = false
        sceneView.session.run(config)
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






