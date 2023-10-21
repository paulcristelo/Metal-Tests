//
//  ViewController.swift
//  Metal Tests
//
//  Created by Paul Cristelo on 10/20/23.
//

import Cocoa
import Metal
import MetalKit

class ViewController: NSViewController {

	var mtkView: MTKView!
	var renderer: Renderer!

	override func viewDidLoad() {
		super.viewDidLoad()

		// First we save the MTKView to a convenient instance variable
		guard let mtkViewTemp = self.view as? MTKView else {
			print("View attached to ViewController is not an MTKView!")
			return
		}
		mtkView = mtkViewTemp

		// Then we create the default device, and configure mtkView with it
		guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
			print("Metal is not supported on this device")
			return
		}

		
		mtkView.device = defaultDevice

		// Lastly we create an instance of our Renderer object,
		// and set it as the delegate of mtkView
		guard let tempRenderer = Renderer(mtkView: mtkView) else {
			print("Renderer failed to initialize")
			return
		}
		renderer = tempRenderer

		mtkView.delegate = renderer
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}


}

