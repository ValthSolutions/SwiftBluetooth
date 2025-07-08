
import Foundation
import CoreBluetooth
import Combine

// MARK: – Combine helpers

public extension Peripheral {
    func readValuePublisher(for characteristic: CBCharacteristic) -> AnyPublisher<Data, Error> {
        bridge { completion in
            self.readValue(for: characteristic, completionHandler: completion)
        }
    }

    func writeValuePublisher(_ data: Data,
                             for characteristic: Characteristic,
                             type: CBCharacteristicWriteType = .withResponse) -> AnyPublisher<Void, Error> {
        guard let mapped = knownCharacteristics[characteristic.uuid] else {
            return Fail(error: PeripheralError.unknownCharacteristic).eraseToAnyPublisher()
        }
        return bridgeVoid { completion in
            self.writeValue(data, for: mapped, type: type, completionHandler: completion)
        }
    }

    func notifyPublisher(for characteristic: Characteristic) -> AnyPublisher<Data, Error> {
        NotificationPublisher(parent: self, characteristic: characteristic)
            .eraseToAnyPublisher()
    }

    // Descriptors
    func readDescriptorPublisher(for descriptor: CBDescriptor) -> AnyPublisher<Any?, Error> {
        bridge { completion in
            self.readValue(for: descriptor, completionHandler: completion)
        }
    }

    func writeDescriptorPublisher(_ data: Data, for descriptor: CBDescriptor) -> AnyPublisher<Void, Error> {
        bridgeVoid { completion in
            self.writeValue(data, for: descriptor, completionHandler: completion)
        }
    }

    // Services / Characteristics / Descriptors discovery
    func discoverServicesPublisher(_ serviceUUIDs: [CBUUID]? = nil) -> AnyPublisher<[CBService], Error> {
        bridge { completion in
            self.discoverServices(serviceUUIDs, completionHandler: completion)
        }
    }

    func discoverCharacteristicsPublisher(_ characteristicUUIDs: [CBUUID]? = nil,
                                          for service: CBService) -> AnyPublisher<[CBCharacteristic], Error> {
        bridge { completion in
            self.discoverCharacteristics(characteristicUUIDs, for: service, completionHandler: completion)
        }
    }

    func discoverDescriptorsPublisher(for characteristic: CBCharacteristic) -> AnyPublisher<[CBDescriptor], Error> {
        bridge { completion in
            self.discoverDescriptors(for: characteristic, completionHandler: completion)
        }
    }

    // Toggle notifications
    func setNotifyValuePublisher(_ value: Bool, for characteristic: CBCharacteristic) -> AnyPublisher<Bool, Error> {
        bridge { completion in
            self.setNotifyValue(value, for: characteristic, completionHandler: completion)
        }
    }

    // RSSI
    func readRSSIPublisher() -> AnyPublisher<NSNumber, Error> {
        bridge { completion in
            self.readRSSI(completionHandler: completion)
        }
    }

    // L2CAP (non‑macOS)
#if !os(macOS)
    @available(iOS 11.0, tvOS 11.0, watchOS 4.0, *)
    func openL2CAPChannelPublisher(_ PSM: CBL2CAPPSM) -> AnyPublisher<CBL2CAPChannel, Error> {
        bridge { completion in
            self.openL2CAPChannel(PSM, completionHandler: completion)
        }
    }
#endif

    /// Bridges a Result‑based callback into a publisher.
    private func bridge<T>(_ call: @escaping (@escaping (Result<T, Error>) -> Void) -> Void) -> AnyPublisher<T, Error> {
        Deferred {
            Future { promise in
                call { result in
                    promise(result)
                }
            }
        }
        .subscribe(on: eventQueue)
        .eraseToAnyPublisher()
    }

    /// Bridges an Error? callback returning Void on success.
    private func bridgeVoid(_ call: @escaping (@escaping (Error?) -> Void) -> Void) -> AnyPublisher<Void, Error> {
        Deferred {
            Future { promise in
                call { error in
                    if let error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            }
        }
        .subscribe(on: eventQueue)
        .eraseToAnyPublisher()
    }
}
