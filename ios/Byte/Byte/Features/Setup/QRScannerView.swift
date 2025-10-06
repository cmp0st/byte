//
//  QRScannerView.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import AVFoundation
import SwiftUI

/// QR code scanner view
struct QRScannerView: UIViewControllerRepresentable {
  // MARK: - Properties

  @Binding var scannedCode: String?
  @Environment(\.presentationMode)
  var presentationMode

  // MARK: - UIViewControllerRepresentable

  func makeUIViewController(context: Context) -> QRScannerViewController {
    let viewController = QRScannerViewController()
    viewController.delegate = context.coordinator
    return viewController
  }

  func updateUIViewController(
    _ uiViewController: QRScannerViewController,
    context: Context
  ) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  // MARK: - Coordinator

  final class Coordinator: NSObject, QRScannerDelegate {
    let parent: QRScannerView

    init(_ parent: QRScannerView) {
      self.parent = parent
    }

    func didFindCode(_ code: String) {
      parent.scannedCode = code
      parent.presentationMode.wrappedValue.dismiss()
    }
  }
}

// MARK: - QR Scanner Delegate

protocol QRScannerDelegate: AnyObject {
  func didFindCode(_ code: String)
}

// MARK: - QR Scanner View Controller

final class QRScannerViewController: UIViewController {
  // MARK: - Properties

  var captureSession: AVCaptureSession!
  var previewLayer: AVCaptureVideoPreviewLayer!
  weak var delegate: QRScannerDelegate?

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    setupCamera()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    startScanning()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopScanning()
  }

  override var prefersStatusBarHidden: Bool {
    true
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    .portrait
  }

  // MARK: - Setup

  private func setupCamera() {
    view.backgroundColor = .black
    captureSession = AVCaptureSession()

    guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
      showCameraError()
      return
    }

    let videoInput: AVCaptureDeviceInput

    do {
      videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
    } catch {
      showCameraError()
      return
    }

    guard captureSession.canAddInput(videoInput) else {
      showCameraError()
      return
    }

    captureSession.addInput(videoInput)

    let metadataOutput = AVCaptureMetadataOutput()

    guard captureSession.canAddOutput(metadataOutput) else {
      showCameraError()
      return
    }

    captureSession.addOutput(metadataOutput)
    metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
    metadataOutput.metadataObjectTypes = [.qr]

    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.frame = view.layer.bounds
    previewLayer.videoGravity = .resizeAspectFill
    view.layer.addSublayer(previewLayer)
  }

  private func startScanning() {
    guard captureSession?.isRunning == false else { return }

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      self?.captureSession.startRunning()
    }
  }

  private func stopScanning() {
    guard captureSession?.isRunning == true else { return }
    captureSession.stopRunning()
  }

  private func showCameraError() {
    let alert = UIAlertController(
      title: "Scanning not supported",
      message: AppError.cameraNotSupported.localizedDescription,
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
    captureSession = nil
  }
}

// MARK: - Metadata Output Delegate

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
  func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection
  ) {
    captureSession.stopRunning()

    guard
      let metadataObject = metadataObjects.first,
      let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
      let stringValue = readableObject.stringValue
    else {
      return
    }

    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    delegate?.didFindCode(stringValue)
  }
}
