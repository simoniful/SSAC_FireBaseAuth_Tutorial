//
//  ViewController.swift
//  SSAC_FireBaseAuth_Tutorial
//
//  Created by Sang hun Lee on 2022/01/17.
//

import UIKit
import FirebaseAuth
import Firebase

class ViewController: UIViewController {

    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var authRequireButton: UIButton!
    @IBOutlet weak var authNumberTextField: UITextField!
    @IBOutlet weak var confirmButton: UIButton!
    
    private var verifyID: String?
    private var isMFAEnabled: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func authRequireButtonClikced(_ sender: UIButton) {
        PhoneAuthProvider.provider()
            .verifyPhoneNumber(phoneNumberTextField.text!, uiDelegate: nil) { verificationID, error in
                if let error = error {
                  print( error.localizedDescription)
                  return
                }
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                print(UserDefaults.standard.string(forKey: "authVerificationID")!)
            }
    }
    
    @IBAction func confirmButtonClicked(_ sender: UIButton) {
        let credential = PhoneAuthProvider.provider().credential(
          withVerificationID: UserDefaults.standard.string(forKey: "authVerificationID")!,
          verificationCode: authNumberTextField.text!
        )
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
              let authError = error as NSError
            if self.isMFAEnabled, authError.code == AuthErrorCode.secondFactorRequired.rawValue {
            // The user is a multi-factor user. Second factor challenge is required.
            let resolver = authError
              .userInfo[AuthErrorUserInfoMultiFactorResolverKey] as! MultiFactorResolver
            var displayNameString = ""
            for tmpFactorInfo in resolver.hints {
              displayNameString += tmpFactorInfo.displayName ?? ""
              displayNameString += " "
            }
            self.showTextInputPrompt(
              withMessage: "Select factor to sign in\n\(displayNameString)",
              completionBlock: { userPressedOK, displayName in
                var selectedHint: PhoneMultiFactorInfo?
                for tmpFactorInfo in resolver.hints {
                  if displayName == tmpFactorInfo.displayName {
                    selectedHint = tmpFactorInfo as? PhoneMultiFactorInfo
                  }
                }
                PhoneAuthProvider.provider()
                  .verifyPhoneNumber(with: selectedHint!, uiDelegate: nil,
                                     multiFactorSession: resolver
                                       .session) { verificationID, error in
                    if error != nil {
                      print(
                        "Multi factor start sign in failed. Error: \(error.debugDescription)"
                      )
                    } else {
                      self.showTextInputPrompt(
                        withMessage: "Verification code for \(selectedHint?.displayName ?? "")",
                        completionBlock: { userPressedOK, verificationCode in
                          let credential: PhoneAuthCredential? = PhoneAuthProvider.provider()
                            .credential(withVerificationID: verificationID!,
                                        verificationCode: verificationCode!)
                          let assertion: MultiFactorAssertion? = PhoneMultiFactorGenerator
                            .assertion(with: credential!)
                          resolver.resolveSignIn(with: assertion!) { authResult, error in
                            if error != nil {
                              print(
                                "Multi factor finanlize sign in failed. Error: \(error.debugDescription)"
                              )
                            } else {
                              self.navigationController?.popViewController(animated: true)
                            }
                          }
                        }
                      )
                    }
                  }
                }
            )
          } else {
            print(error.localizedDescription)
            return
          }
          // ...
          return
        }
        print("인증성공")
        }
    }
    
    func showTextInputPrompt(withMessage message: String,
                               completionBlock: @escaping ((Bool, String?) -> Void)) {
        let prompt = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
          completionBlock(false, nil)
        }
        weak var weakPrompt = prompt
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
          guard let text = weakPrompt?.textFields?.first?.text else { return }
          completionBlock(true, text)
        }
        prompt.addTextField(configurationHandler: nil)
        prompt.addAction(cancelAction)
        prompt.addAction(okAction)
        present(prompt, animated: true, completion: nil)
    }
}

