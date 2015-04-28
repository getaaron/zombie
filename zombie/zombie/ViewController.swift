//
//  ViewController.swift
//  zombie
//
//  Created by Aaron on 4/27/15.
//  Copyright (c) 2015 Aaron Brager. All rights reserved.
//

import UIKit
import ResearchKit

class ViewController: UIViewController, ORKTaskViewControllerDelegate {

    var taskViewController : ORKTaskViewController!
    var PDFData : NSData?
    
    @IBOutlet weak var viewPDFButton: UIButton!
    
    @IBAction func consentTapped(sender: UIButton) {
        let task = consentTask()
        
        taskViewController = ORKTaskViewController(task: task, taskRunUUID: NSUUID())
        taskViewController.delegate = self
        presentViewController(taskViewController, animated: true, completion: nil)
    }
    
    @IBAction func viewPDFTapped(sender: UIButton) {
        let webVC = self.storyboard!.instantiateViewControllerWithIdentifier("webViewController") as! UIViewController
        let webView = webVC.view as! UIWebView
        webView.loadData(PDFData, MIMEType: "application/pdf", textEncodingName: "UTF-8", baseURL: nil)
        self.navigationController?.pushViewController(webVC, animated: true)
    }
    
    func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        
        if taskViewController.task?.identifier == "ordered task identifier" {
            generatePDFData()
        }
        
        taskViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func generatePDFData() {
        // let document = consentDocument.copy() as! ORKConsentDocument // This works
        
        if let signatureResult = taskViewController.result.stepResultForStepIdentifier("consent review step identifier")?.firstResult as? ORKConsentSignatureResult {
            signatureResult.applyToDocument(consentDocument)
        }
        
        consentDocument.makePDFWithCompletionHandler { (data, error) -> Void in
            if let data = data where data.length > 0 {
                // data is not nil
                self.PDFData = data
                self.viewPDFButton.hidden = false
            }
        }
    }

    func consentTask() -> ORKOrderedTask {
        var steps = consentSteps()
        return ORKOrderedTask(identifier: "ordered task identifier", steps: steps)
    }
    
    func consentSteps () -> [ORKStep] {
        var steps = [ORKStep]()

        // A visual consent step describes the technical consent document simply
        let visualConsentStep = ORKVisualConsentStep(identifier: "visual consent step identifier", document: consentDocument)
        
        steps += [visualConsentStep]
        
        // A consent sharing step tells the user how you'll share their stuff
        let sharingConsentStep = ORKConsentSharingStep(identifier: "consent sharing step identifier",
            investigatorShortDescription: "Zombie Research Corp™",
            investigatorLongDescription: "The Zombie Research Corporation™ and related undead research partners",
            localizedLearnMoreHTMLContent: "Zombie Research Corporation™ will only transmit your personal data to other partners that also study the undead, including the Werewolf Research Corporation™ and Vampire Research Corporation™.")

        steps += [sharingConsentStep]
        
        // A consent review step reviews the consent document and gets a signature
        let signature = consentDocument.signatures!.first as! ORKConsentSignature
        
        let reviewConsentStep = ORKConsentReviewStep(identifier: "consent review step identifier", signature: signature, inDocument: consentDocument)

        reviewConsentStep.text = "I love, and agree to perform, zombie research."
        reviewConsentStep.reasonForConsent = "Zombie research is important."
        
        steps += [reviewConsentStep]

        return steps
    }
    
    private var consentDocument: ORKConsentDocument {
        // Create the document
        let consentDocument = ORKConsentDocument()
        consentDocument.title = "Consent to Zombie Research"
        consentDocument.signaturePageTitle = "Consent Signature"
        consentDocument.signaturePageContent = "I agree to participate in this zombie-related research study."

        // Add participant signature
        let participantSignature = ORKConsentSignature(forPersonWithTitle: "Participant", dateFormatString: nil, identifier: "participant signature identifier")
        
        consentDocument.addSignature(participantSignature)
        
        // Add investigator signature for the PDF.
        let investigatorSignature = ORKConsentSignature(forPersonWithTitle: "Zombie Investigator",
            dateFormatString: nil,
            identifier: "investigator signature identifier",
            givenName: "George",
            familyName: "A. Romero",
            signatureImage: UIImage(named: "signature")!,
            dateString: "10/1/1968")
        
        consentDocument.addSignature(investigatorSignature)
        
        // Create "consent sections" in case the user wants more details before giving consent
        let consentOverview = ORKConsentSection(type: .Overview)
        consentOverview.content = "It's important to research zombies so we can get rid of them. Thanks in advance for all of your help researching them."
        
        let consentPrivacy = ORKConsentSection(type: .Privacy)
        consentPrivacy.content = "All information will be strictly confidential, unless a zombie eats your braaaaaaaaains…"

        let consentTimeCommitment = ORKConsentSection(type: .TimeCommitment)
        consentTimeCommitment.content = "This shouldn't take too long… as long as the zombies don't move too fast."

        consentDocument.sections = [consentOverview, consentPrivacy, consentTimeCommitment]
        
        return consentDocument
    }
}

