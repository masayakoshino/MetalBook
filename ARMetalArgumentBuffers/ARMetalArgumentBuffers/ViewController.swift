//
//  ViewController.swift
//  ARMetalArgumentBuffers
//
//  Created by Shuichi Tsutsumi on 2017/07/17.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Metal
import MetalKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var resetBtn: UIButton!

    @IBOutlet weak var metalView: MetalRenderView!
    
    private var planeNode: SCNNode?
    private var duckNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        duckNode = SCNNode.duckNode()
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.scene = SCNScene()
        sceneView.delegate = self

        label.text = "Wait..."
        
        startRunning()
    }
    
    // MARK: - Private
    
    private func startRunning() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - ARSCNViewDelegate
    
    var isRendering = false
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = sceneView.session.currentFrame else {return}
        let pixelBuffer = frame.capturedImage

        if isRendering {
            return
        }
        isRendering = true
        
        DispatchQueue.main.async(execute: {
            let orientation = UIApplication.shared.statusBarOrientation
            let viewportSize = self.sceneView.bounds.size
            
            // ピクセルバッファからCIImage生成
            var image = CIImage(cvPixelBuffer: pixelBuffer)
            
            // 画面のサイズ・向きに合わせるアフィン変換行列を適用
            let transform = frame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()
            image = image.transformed(by: transform)
            
            let context = CIContext(options:nil)
            guard let cameraImage = context.createCGImage(image, from: image.extent) else {return}

            // スナップショット撮影
            guard let snapshotImage = self.sceneView.snapshot().cgImage else {return}

            self.metalView.registerTexturesFor(cameraImage: cameraImage, snapshotImage: snapshotImage)
            
            self.metalView.time = Float(time)
            
            self.isRendering = false
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
//        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
//        planeAnchor.addPlaneNode(on: node, color: UIColor.arBlue.withAlphaComponent(0.3))
        
        // 黒で塗る
        for child in duckNode.childNodes {
            if let material = child.geometry?.firstMaterial {
                material.diffuse.contents = UIColor.black
            }
        }
        duckNode.scale = SCNVector3Make(2, 2, 2)
        
        DispatchQueue.main.async(execute: {
            node.addChildNode(self.duckNode)
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }

    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        label.text = camera.trackingState.description
    }
    
    // MARK: - Actions

    @IBAction func resetBtnTapped(_ sender: UIButton) {
        // restart
        startRunning()
    }
}
