import XCTest
import AsyncHTTPClient
import NIO
import Logging

@testable import AcmeSwift

final class OrderTests: XCTestCase {
    var logger: Logger!
    var http: HTTPClient!
    
    override func setUp() async throws {
        self.logger = Logger.init(label: "acme-swift-tests")
        self.logger.logLevel = .trace
        
        var config = HTTPClient.Configuration(certificateVerification: .fullVerification, backgroundActivityLogger: self.logger)
        self.http = HTTPClient(
            eventLoopGroupProvider: .createNew,
            configuration: config
        )
    }
    
    func testCreateOrder() async throws {
        let client = try await AcmeSwift(client: self.http, acmeEndpoint: AcmeServer.letsEncryptStaging, logger: logger)
        defer{try? client.syncShutdown()}
        do {
            let newAccount = try await client.account.create(contacts: ["bonsouere3456@gmail.com", "bonsouere+299@gmail.com"], acceptTOS: true)
            
            let acme = try await AcmeSwift(login: .init(contacts: newAccount.contact, pemKey: newAccount.privateKeyPem!), client: self.http, acmeEndpoint: AcmeServer.letsEncryptStaging, logger: logger)
            defer{try? acme.syncShutdown()}
            
            let order = try await acme.orders.create(domains: ["www.mydomain.com"])
            print("\n••• Order: \(order)")
            XCTAssert(order.status == .pending, "Ensure order is pending")
            XCTAssert(order.expires > Date(), "Ensure order expiry is parsed")
            XCTAssert(order.identifiers.first?.value == "www.mydomain.com", "Ensure order domains match request")
            
        }
        catch(let error) {
            print("\n•••• BOOM! \(error)")
            throw error
        }
    }
}