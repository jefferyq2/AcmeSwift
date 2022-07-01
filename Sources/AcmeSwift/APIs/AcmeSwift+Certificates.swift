import Foundation
import Crypto

extension AcmeSwift {
    /// APIs related to ACMEv2 certificates management.
    public var certificates: CertificatesAPI {
        .init(client: self)
    }
    
    public struct CertificatesAPI {
        private let separator = "-----END CERTIFICATE-----\n"
        fileprivate var client: AcmeSwift
        
        /// Downloads the certificate chain for a finalized Order.
        /// The certificates are returned a a list of PEM strings.
        /// The first item is the final certificate for the domain.
        /// The second item, if any, is the issuer certificate.
        public func download(`for` order: AcmeOrderInfo) async throws -> [String] {
            try await self.client.ensureLogged()
            
            guard order.status == .valid, let certURL = order.certificate else {
                throw AcmeError.certificateNotReady(order.status, "Order must have a `valid` status. Some challenges might not have been completed yet")
            }

            
            let ep = DownloadCertificateEndpoint(certURL: certURL)
            let (certificateChain, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
            var certificates: [String] = []
            for certificate in  certificateChain.components(separatedBy: self.separator) {
                if certificate != "" {
                    certificates.append("\(certificate)\(separator)".trimmingCharacters(in: .newlines))
                }
            }
            return certificates
        }
        
        /// Revokes a previously issued certificate.
        public func revoke(certificatePEM: String, reason: AcmeRevokeReason? = nil) async throws {
            try await self.client.ensureLogged()
            
            let csrBytes = withPemCsr.pemToData()
            let pemStr = csrBytes.toBase64UrlString()
            
            let ep = RevokeCertificateEndpoint(
                directory: self.client.directory, 
                spec: .init(certificate: pemStr, reason: reason)
            )
            let (_, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
        }
    }
}
