import XCTest
import Security
@testable import AIQuotaKit

final class KeychainStoreFallbackTests: XCTestCase {
    func testMissingEntitlementFallsBackToTheLegacyKeychain() {
        XCTAssertTrue(KeychainStore.usesLegacyKeychain(probeStatus: errSecMissingEntitlement))
    }

    func testRejectedQueryFallsBackToTheLegacyKeychain() {
        XCTAssertTrue(KeychainStore.usesLegacyKeychain(probeStatus: errSecParam))
    }

    func testAWritableDataProtectionKeychainKeepsLegacyItemsUntouched() {
        XCTAssertFalse(KeychainStore.usesLegacyKeychain(probeStatus: errSecSuccess))
    }

    /// A read of an absent item returns this whether or not the keychain is usable,
    /// so it must never be read as a reason to reach for the legacy keychain.
    func testAbsentItemIsNotTreatedAsAnUnusableKeychain() {
        XCTAssertFalse(KeychainStore.usesLegacyKeychain(probeStatus: errSecItemNotFound))
    }

    func testDuplicateItemIsNotTreatedAsAnUnusableKeychain() {
        XCTAssertFalse(KeychainStore.usesLegacyKeychain(probeStatus: errSecDuplicateItem))
    }
}
