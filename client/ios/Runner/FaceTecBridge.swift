import FaceTecSDK
import Flutter
import Foundation
import UIKit

final class FaceTecBridge: NSObject {
    static let channelName = "com.honestdating/facetec-test"

    private weak var presentingViewController: UIViewController?
    private var channel: FlutterMethodChannel?
    private var configuration: FaceTecTestConfiguration?
    private var sdkInstance: FaceTecSDKInstance?
    private var initializationProcessor: FaceTecTestSessionProcessor?
    private var livenessProcessor: FaceTecTestSessionProcessor?
    private var pendingResult: FlutterResult?

    func register(
        messenger: FlutterBinaryMessenger,
        presentingViewController: UIViewController
    ) {
        self.presentingViewController = presentingViewController

        let channel = FlutterMethodChannel(
            name: Self.channelName,
            binaryMessenger: messenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else {
                result(FlutterError(
                    code: "bridge_unavailable",
                    message: "Selfie verification is unavailable.",
                    details: nil
                ))
                return
            }

            guard call.method == "startLivenessCheck" else {
                result(FlutterMethodNotImplemented)
                return
            }

            self.startLivenessCheck(result: result)
        }
        self.channel = channel
    }

    private func startLivenessCheck(result: @escaping FlutterResult) {
        guard pendingResult == nil else {
            result(FlutterError(
                code: "session_in_progress",
                message: "A selfie check is already in progress.",
                details: nil
            ))
            return
        }

        guard let configuration = FaceTecTestConfiguration.load() else {
            result(FlutterError(
                code: "test_configuration_unavailable",
                message: "FaceTec test configuration is unavailable.",
                details: nil
            ))
            return
        }

        pendingResult = result
        self.configuration = configuration

        if let sdkInstance {
            launchLivenessCheck(with: sdkInstance, configuration: configuration)
            return
        }

        let processor = makeSessionProcessor(configuration: configuration)
        initializationProcessor = processor
        FaceTec.sdk.initializeWithSessionRequest(
            deviceKeyIdentifier: configuration.deviceKeyIdentifier,
            sessionRequestProcessor: processor,
            completion: self
        )
    }

    private func launchLivenessCheck(
        with sdkInstance: FaceTecSDKInstance,
        configuration: FaceTecTestConfiguration
    ) {
        guard let presentingViewController else {
            finish(with: "failed")
            return
        }

        let processor = makeSessionProcessor(configuration: configuration)
        livenessProcessor = processor
        let faceTecViewController = sdkInstance.start3DLiveness(with: processor)
        presentingViewController.present(faceTecViewController, animated: true)
    }

    private func makeSessionProcessor(
        configuration: FaceTecTestConfiguration
    ) -> FaceTecTestSessionProcessor {
        FaceTecTestSessionProcessor(configuration: configuration) {
            [weak self] status,
            requestFailure in
            self?.finish(with: status, requestFailure: requestFailure)
        }
    }

    private func finish(
        with sessionStatus: FaceTecSessionStatus,
        requestFailure: FaceTecTestRequestFailure?
    ) {
        switch sessionStatus {
        case .sessionCompleted:
            finish(with: "verified")
        case .userCancelledFaceScan, .userCancelledIDScan:
            finish(with: "cancelled")
        case .cameraPermissionsDenied:
            finish(with: "cameraPermissionDenied")
        case .requestAborted:
            switch requestFailure {
            case .network:
                finish(with: "networkFailed")
            case .service:
                finish(with: "serviceFailed")
            case nil:
                finish(with: "failed")
            }
        case .lockedOut:
            finish(with: "lockedOut")
        case .cameraError:
            finish(with: "cameraError")
        case .unknownInternalError:
            finish(with: "failed")
        @unknown default:
            finish(with: "failed")
        }
    }

    private func finish(with outcome: String) {
        DispatchQueue.main.async {
            guard let pendingResult = self.pendingResult else {
                return
            }

            self.pendingResult = nil
            self.initializationProcessor = nil
            self.livenessProcessor = nil
            pendingResult(["outcome": outcome])
        }
    }
}

extension FaceTecBridge: FaceTecInitializeCallback {
    func onFaceTecSDKInitializeSuccess(sdkInstance: FaceTecSDKInstance) {
        self.sdkInstance = sdkInstance
        initializationProcessor = nil

        guard let configuration else {
            finish(with: "failed")
            return
        }

        DispatchQueue.main.async {
            self.launchLivenessCheck(
                with: sdkInstance,
                configuration: configuration
            )
        }
    }

    func onFaceTecSDKInitializeError(error: FaceTecInitializationError) {
        finish(with: "initializationFailed")
    }
}

private struct FaceTecTestConfiguration {
    let deviceKeyIdentifier: String
    let testApiBaseUrl: URL

    static func load() -> FaceTecTestConfiguration? {
        guard
            let configurationUrl = Bundle.main.url(
                forResource: "FaceTecTestConfiguration",
                withExtension: "plist"
            ),
            let values = NSDictionary(contentsOf: configurationUrl),
            let deviceKeyIdentifier = values["deviceKeyIdentifier"] as? String,
            !deviceKeyIdentifier.isEmpty,
            let testApiBaseUrlString = values["testApiBaseUrl"] as? String,
            let testApiBaseUrl = URL(string: testApiBaseUrlString)
        else {
            return nil
        }

        return FaceTecTestConfiguration(
            deviceKeyIdentifier: deviceKeyIdentifier,
            testApiBaseUrl: testApiBaseUrl
        )
    }
}

private final class FaceTecTestSessionProcessor: NSObject,
    FaceTecSessionRequestProcessor,
    URLSessionTaskDelegate {
    private static let maximumNetworkAttempts = 4

    private let configuration: FaceTecTestConfiguration
    private let onExit: (FaceTecSessionStatus, FaceTecTestRequestFailure?) -> Void
    private var activeCallback: FaceTecSessionRequestProcessorCallback?
    private var requestFailure: FaceTecTestRequestFailure?

    init(
        configuration: FaceTecTestConfiguration,
        onExit: @escaping (FaceTecSessionStatus, FaceTecTestRequestFailure?) -> Void
    ) {
        self.configuration = configuration
        self.onExit = onExit
    }

    func onSessionRequest(
        sessionRequestBlob: String,
        sessionRequestCallback: FaceTecSessionRequestProcessorCallback
    ) {
        activeCallback = sessionRequestCallback
        send(
            sessionRequestBlob: sessionRequestBlob,
            sessionRequestCallback: sessionRequestCallback,
            attempt: 1
        )
    }

    func onFaceTecExit(sessionResult: FaceTecSessionResult) {
        onExit(sessionResult.sessionStatus, requestFailure)
    }

    private func send(
        sessionRequestBlob: String,
        sessionRequestCallback: FaceTecSessionRequestProcessorCallback,
        attempt: Int
    ) {
        var request = URLRequest(url: configuration.testApiBaseUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(
            configuration.deviceKeyIdentifier,
            forHTTPHeaderField: "X-Device-Key"
        )
        request.setValue(
            FaceTec.sdk.getTestingAPIHeader(),
            forHTTPHeaderField: "X-Testing-API-Header"
        )

        guard let body = try? JSONSerialization.data(
            withJSONObject: ["requestBlob": sessionRequestBlob]
        ) else {
            sessionRequestCallback.abortOnCatastrophicError()
            return
        }
        request.httpBody = body

        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForResource = 120
        let session = URLSession(
            configuration: sessionConfiguration,
            delegate: self,
            delegateQueue: OperationQueue.main
        )

        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else {
                return
            }

            if error != nil, attempt < Self.maximumNetworkAttempts {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + self.retryDelay(for: attempt)
                ) {
                    self.send(
                        sessionRequestBlob: sessionRequestBlob,
                        sessionRequestCallback: sessionRequestCallback,
                        attempt: attempt + 1
                    )
                }
                return
            }

            guard error == nil else {
                self.abort(
                    sessionRequestCallback,
                    failure: .network
                )
                return
            }

            guard
                let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode),
                let data,
                let response = try? JSONSerialization.jsonObject(with: data)
                    as? [String: Any],
                let responseBlob = response["responseBlob"] as? String,
                !responseBlob.isEmpty
            else {
                self.abort(
                    sessionRequestCallback,
                    failure: .service
                )
                return
            }

            sessionRequestCallback.processResponse(responseBlob)
        }.resume()
    }

    private func abort(
        _ sessionRequestCallback: FaceTecSessionRequestProcessorCallback,
        failure: FaceTecTestRequestFailure
    ) {
        requestFailure = failure
        sessionRequestCallback.abortOnCatastrophicError()
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        guard totalBytesExpectedToSend > 0 else {
            return
        }

        activeCallback?.updateProgress(
            Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        )
    }

    private func retryDelay(for attempt: Int) -> TimeInterval {
        switch attempt {
        case 1:
            return 0
        case 2:
            return 2
        case 3:
            return 5
        default:
            return 10
        }
    }
}

private enum FaceTecTestRequestFailure {
    case network
    case service
}
