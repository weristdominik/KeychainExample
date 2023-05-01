//
//  ViewController.swift
//  KeyChainExample
//
//  Created by Dominik on 29.04.23.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Save
        do {
            try Keychain.add()
        } catch {
            print(error)
        }
        
        //Read
        do {
            try Keychain.read()
        } catch {
            print(error)
        }
        
        //Delete
        //do { try Keychain.delete(username: "Dominik", secret: "mysecretKey") }
        //catch {print(error)}
        
        
    }


}


class Keychain {
    
    struct Credentials {
        var username: String
        var password: String
    }
    
    enum KeychainError: Error {
        case noPassword
        case unexpectedPasswordData
        case unhandledError(status: OSStatus)
        case duplicateEntry
    }
    
    static let server = "www.fitreps.de"
    
    static func add() throws -> Int {
        
        //Return Values:
            //0 = Error
            //1 = Created Successfully
            //2 = DuplicateEntry
        var response = 1
        var credentials = Credentials(username: "Doiminik", password: "mysecretKey")
        let account = credentials.username
        let password = credentials.password.data(using: String.Encoding.utf8)!
        var query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: account,
                                    kSecAttrServer as String: server,
                                    kSecValueData as String: password]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status != errSecDuplicateItem else {
            response = 2
            throw KeychainError.duplicateEntry }
        
        guard status == errSecSuccess else {
            response = 0
            throw KeychainError.unhandledError(status: status) }
        
        return response
    }
    
    static func read() throws -> Bool {
        
        //Return Values:
            //true = Read successfully
            //false = Error while Reading
        
        var response = true
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            response = false
            throw KeychainError.noPassword }
        guard status == errSecSuccess else {
            response = false
            throw KeychainError.unhandledError(status: status) }
        
        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: String.Encoding.utf8),
            let account = existingItem[kSecAttrAccount as String] as? String
        else {
            response = false
            throw KeychainError.unexpectedPasswordData
        }
        let foundcredentials = Credentials(username: account, password: password)
        
        print("Data read: \(account)")
        return response
    }
    
    
    static func delete(username: String, secret: String) throws -> Bool {
        
        //Return Values:
            //true = deleted successfully
            //false = Error while deletion
        
        var response = true
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server]
        
        let account = username
        let password = secret.data(using: String.Encoding.utf8)!
        let attributes: [String: Any] = [kSecAttrAccount as String: account,
                                         kSecValueData as String: password]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            response = false
            throw KeychainError.unhandledError(status: status) }
        print("Key deleted successfully: \(username)")
        return response
    }
}
