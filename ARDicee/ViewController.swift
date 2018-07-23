//
//  ViewController.swift
//  ARDicee
//
//  Created by wenlong qiu on 7/20/18.
//  Copyright © 2018 wenlong qiu. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    var diceArray = [SCNNode]() //create dicearray to roll all dice at once
    //the view in controller
    @IBOutlet var sceneView: ARSCNView!
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints] //feature points visible in camera when detecting flat surface, so few feature points means surface not getting detected
        
        // Set the view's delegate
        sceneView.delegate = self
        
//        //chamferradius is how round corners are
//        let sphere = SCNSphere(radius: 0.2)
//        //white mat texture default so white cube
//        let material = SCNMaterial()
//        //material.diffuse.contents = UIColor.red
//        material.diffuse.contents = UIImage(named: "art.scnassets/8k_moon.jpg")
//        sphere.materials = [material] //object can have mutiple materials
//        let node = SCNNode() //a point in 3d space, can assign position and object to display
//        node.position = SCNVector3(x: 0, y: 0.1, z: -0.5) //three dimension vector
//        node.geometry = sphere
//        sceneView.scene.rootNode.addChildNode(node) //Each child node’s coordinate system is defined relative to the transformation of its parent node. so jet emitter node is child of jet node
        sceneView.autoenablesDefaultLighting = true //adds light and shadow to scene to make it look 3d
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .horizontal //automatically detect flat surfaces in the camera-captured image. By default, plane detection is off, so objects float in mid air, this enables put ojbect on flat surface
        

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    //converts user touches to locations points in scene
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first { //only one element in the set cuz not multi touch
            let touchLocation = touch.location(in: sceneView) //touch location in the sceneview--2D
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent) //.existingplaneusing extent is a point in detected plane with estimated length and width， convert 2d touch to 3d point
            if let hitResult = results.first { //results is nil if outside the plane
                // Create dice scene to get dice node from it and add it to sceneview
                let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn")! //there can only one scene but there can be many nodes/objects in the scene
                
                if let diceNode = diceScene.rootNode.childNode(withName: "dice", recursively: true) {
                    //identity iin scene graph is dice //recursive means include subtree
                    diceNode.position = SCNVector3(
                        x: hitResult.worldTransform.columns.3.x, //4th column is position
                        y: hitResult.worldTransform.columns.3.y + diceNode.boundingSphere.radius,
                        z: hitResult.worldTransform.columns.3.z
                    )
                    //sceneview is the view on controller
                    sceneView.scene.rootNode.addChildNode(diceNode) //add dice to scene
                    
                    diceArray.append(diceNode)
                    roll(dice: diceNode)
                }
                    
            }
        }
    }
    
    func rollAll() { //need to add bar button to trigger this method, refresh icon
        if !diceArray.isEmpty {
            for dice in diceArray {
                roll(dice: dice)
            }
        }
    }
    
    func roll(dice: SCNNode) {
        let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi/2) //rotate around x-axis
        let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi/2) //roate around z-axis
        dice.runAction(SCNAction.rotateBy(x: CGFloat(randomX * 5), y: 0, z: CGFloat(randomZ * 5), duration: 0.5))
    }
    @IBAction func rollAgain(_ sender: UIBarButtonItem) {
        rollAll()
    }
    
    //new bar button item trash icon
    @IBAction func removeAllDice(_ sender: UIBarButtonItem) {
        if !diceArray.isEmpty {
            for dice in diceArray {
                dice.removeFromParentNode()
            }
        }
    }
    //after shaking ends
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        rollAll()
    }
    
    
    //ARSCNViewDelegate method, detects possible plane, anchor it, triggers this did add node correspond to anchor mehtod, this node added to scene
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //construct planeNode base on anchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}//anchor is location and orientaion of plane in space
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))//because plane is vertitcle standing, extent is estimated width and length
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)//positiive is counter clockwise, rotate around x-axis
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png") //grid.png is transparent grid for testing
        plane.materials = [gridMaterial]
        planeNode.geometry = plane
        node.addChildNode(planeNode) //must addchildnode to establish link, if set, node lost its reference
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
  
}
