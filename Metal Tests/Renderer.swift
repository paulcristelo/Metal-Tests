//
//  Renderer.swift
//  Metal Tests
//
//  Created by Paul Cristelo on 10/20/23.
//

import Foundation
import Metal
import MetalKit

class Renderer : NSObject, MTKViewDelegate {
	
	let device: MTLDevice
	let commandQueue: MTLCommandQueue
	let pipelineState: MTLRenderPipelineState
	let vertexBuffer: MTLBuffer
	let fragmentUniformsBuffer: MTLBuffer
	let gpuLock = DispatchSemaphore(value: 1)
	var mtkView: MTKView
	
	// This keeps track of the system time of the last render
	var lastRenderTime: CFTimeInterval? = nil
	// This is the current time in our app, starting at 0, in units of seconds
	var currentTime: Double = 0
	
	// This is the initializer for the Renderer class.
	// We will need access to the mtkView later, so we add it as a parameter here.
	init?(mtkView: MTKView) {
		self.mtkView = mtkView
		device = mtkView.device!
		commandQueue = device.makeCommandQueue()!
		
		
		// Create the Render Pipeline
		do {
			pipelineState = try Renderer.buildRenderPipelineWith(device: device, metalKitView: mtkView)
		} catch {
			print("Unable to compile render pipeline state: \(error)")
			return nil
		}
		
		// Create our vertex data
		let vertices = [Vertex(color: [1, 0, 0, 1], pos: [-1, -1], brightness: 1.0),
						Vertex(color: [0, 1, 0, 1], pos: [1, -1], brightness: 1.0),
						Vertex(color: [0, 0, 1, 1], pos: [-1, 1], brightness: 1.0),
						Vertex(color: [1, 0, 1, 1], pos: [1, 1], brightness: 1.0)]
		
		// And copy it to a Metal buffer...
		vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])!
		
		//Create Uniform Buffer
		var initialFragmentUniforms = FragmentUniforms(currentTime: Float(currentTime), dt: Float((lastRenderTime ?? 0)), resolution: [Float(mtkView.drawableSize.width), Float(mtkView.drawableSize.height)])
		fragmentUniformsBuffer = device.makeBuffer(bytes: &initialFragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, options: [])!
	}
	
	// mtkView will automatically call this function
	// whenever it wants new content to be rendered.
	func draw(in view: MTKView) {
		
		gpuLock.wait()
		// Compute dt
		let systemTime = CACurrentMediaTime()
		let timeDifference = (lastRenderTime == nil) ? 0 : (systemTime - lastRenderTime!)
		// Save this system time
		lastRenderTime = systemTime

		// Update state
		update(dt: timeDifference)

		
		// Get an available command buffer
		guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
		
		// Get the default MTLRenderPassDescriptor from the MTKView argument
		guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
		
		// Change default settings. For example, we change the clear color from black to red.
		renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
		
		// We compile renderPassDescriptor to a MTLRenderCommandEncoder.
		guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
		
		/// BETWEEN THESE TWO IS WHERE WE ENCODE DRAWING COMMANDS
		
		// Setup render commands to encode
		
		// We tell it what render pipeline to use
		renderEncoder.setRenderPipelineState(pipelineState)
		// What vertex buffer data to use
		renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
		// What fragment uniform buffer data to use
		renderEncoder.setFragmentBuffer(fragmentUniformsBuffer, offset: 0, index: 0)
		
		
		// And what to draw
		renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
		
		/// BETWEEN THESE TWO IS WHERE WE ENCODE DRAWING COMMANDS
		
		// This finalizes the encoding of drawing commands.
		renderEncoder.endEncoding()
		
		// Tell Metal to send the rendering result to the MTKView when rendering completes
		commandBuffer.present(view.currentDrawable!)
		
		commandBuffer.addCompletedHandler { _ in
			self.gpuLock.signal()
		}
		
		// Finally, send the encoded command buffer to the GPU.
		commandBuffer.commit()
	}
	
	// mtkView will automatically call this function
	// whenever the size of the view changes (such as resizing the window).
	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		
	}
	
	// Create our custom rendering pipeline, which loads shaders using `device`, and outputs to the format of `metalKitView`
	class func buildRenderPipelineWith(device: MTLDevice, metalKitView: MTKView) throws -> MTLRenderPipelineState {
		// Create a new pipeline descriptor
		let pipelineDescriptor = MTLRenderPipelineDescriptor()
		
		// Setup the shaders in the pipeline
		let library = device.makeDefaultLibrary()
		pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
		pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShader")
		
		// Setup the output pixel format to match the pixel format of the metal kit view
		pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
		
		// Compile the configured pipeline descriptor to a pipeline state object
		return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
	}
	
	func update(dt: CFTimeInterval) {
		currentTime += dt
		updateUniforms()  // Update the Metal buffer for the fragment uniforms
	}

	func updateUniforms() {
		var fragmentUniforms = FragmentUniforms(currentTime: Float(currentTime), dt: Float(lastRenderTime ?? 0), resolution: [Float(mtkView.drawableSize.width), Float(mtkView.drawableSize.height)])
		let bufferPointer = fragmentUniformsBuffer.contents()
		memcpy(bufferPointer, &fragmentUniforms, MemoryLayout<FragmentUniforms>.stride)
	}

}

