//
//  QRScannerView.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import AVFoundation
import SwiftUI

struct QRScannerView: UIViewControllerRepresentable {
  @Binding var scannedCode: String?
  @Environment(\.presentationMode)
  var presentationMode

  func makeUIViewController(context: Context) -> QRScannerViewController {
    let viewController = QRScannerViewController()
    viewController.delegate = context.coordinator
    return viewController
  }

  func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, QRScannerDelegate {
    var parent: QRScannerView

    init(_ parent: QRScannerView) {
      self.parent = parent
    }

    func didFindCode(_ code: String) {
      parent.scannedCode = code
      parent.presentationMode.wrappedValue.dismiss()
    }
  }
}

protocol QRScannerDelegate: AnyObject {
  func didFindCode(_ code: String)
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
  var captureSession: AVCaptureSession!
  var previewLayer: AVCaptureVideoPreviewLayer!
  weak var delegate: QRScannerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = UIColor.black
    captureSession = AVCaptureSession()

    guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
    let videoInput: AVCaptureDeviceInput

    do {
      videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
    } catch {
      return
    }

    if captureSession.canAddInput(videoInput) {
      captureSession.addInput(videoInput)
    } else {
      failed()
      return
    }

    let metadataOutput = AVCaptureMetadataOutput()

    if captureSession.canAddOutput(metadataOutput) {
      captureSession.addOutput(metadataOutput)

      metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
      metadataOutput.metadataObjectTypes = [.qr]
    } else {
      failed()
      return
    }

    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.frame = view.layer.bounds
    previewLayer.videoGravity = .resizeAspectFill
    view.layer.addSublayer(previewLayer)

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      self?.captureSession.startRunning()
    }
  }

  func failed() {
    let ac = UIAlertController(
      title: "Scanning not supported",
      message: "Your device does not support scanning a code from an item. Please use a device with a camera.",
      preferredStyle: .alert
    )
    ac.addAction(UIAlertAction(title: "OK", style: .default))
    present(ac, animated: true)
    captureSession = nil
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    if captureSession?.isRunning == false {
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        self?.captureSession.startRunning()
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    if captureSession?.isRunning == true {
      captureSession.stopRunning()
    }
  }

  func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection
  ) {
    captureSession.stopRunning()

    if let metadataObject = metadataObjects.first {
      guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
      guard let stringValue = readableObject.stringValue else { return }
      AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
      found(code: stringValue)
    }
  }

  func found(code: String) {
    delegate?.didFindCode(code)
  }

  override var prefersStatusBarHidden: Bool {
    return true
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }
}
