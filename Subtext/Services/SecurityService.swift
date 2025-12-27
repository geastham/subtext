//
//  SecurityService.swift
//  Subtext
//
//  Created by Codegen
//  Phase 1: Foundation & Data Layer
//

import CryptoKit
import Foundation
import Security

actor SecurityService {
    static let shared = SecurityService()
    
    private init() {}
    
    // MARK: - Encryption
    
    func encrypt(_ text: String) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let data = Data(text.utf8)
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined ?? Data()
    }
    
    func decrypt(_ data: Data) throws -> String {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return String(data: decryptedData, encoding: .utf8) ?? ""
    }
    
    // MARK: - Keychain Management
    
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "SubtextEncryptionKey",
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &item)
        
        if status == errSecSuccess {
            guard let keyData = item as? Data else {
                throw SecurityError.invalidKeyData
            }
            return SymmetricKey(data: keyData)
        } else {
            let key = SymmetricKey(size: .bits256)
            let keyData = key.withUnsafeBytes { Data($0) }
            
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "SubtextEncryptionKey",
                kSecValueData as String: keyData
            ]
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw SecurityError.keychainError
            }
            
            return key
        }
    }
    
    func deleteEncryptionKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "SubtextEncryptionKey"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecurityError.keychainError
        }
    }
    
    enum SecurityError: Error {
        case invalidKeyData
        case keychainError
        case encryptionFailed
        case decryptionFailed
    }
}
