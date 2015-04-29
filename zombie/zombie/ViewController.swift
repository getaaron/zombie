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
    @IBOutlet weak var surveyButton: UIButton!
    @IBOutlet weak var walkingTestButton: UIButton!
    
    // MARK: - Button Outlets
    
    @IBAction func consentTapped(sender: UIButton) {
        presentTask(consentTask())
    }
    
    @IBAction func viewPDFTapped(sender: UIButton) {
        let webVC = self.storyboard!.instantiateViewControllerWithIdentifier("webViewController") as! UIViewController
        let webView = webVC.view as! UIWebView
        webView.loadData(PDFData, MIMEType: "application/pdf", textEncodingName: "UTF-8", baseURL: nil)
        self.navigationController?.pushViewController(webVC, animated: true)
    }
    
    @IBAction func surveyTapped(sender: UIButton) {
        presentTask(surveyTask())
    }
    
    @IBAction func walkingTestTapped(sender: UIButton) {
        presentTask(walkTask())
    }
    
    func presentTask(task : ORKTask) {
        taskViewController = ORKTaskViewController(task: task, taskRunUUID: NSUUID())
        taskViewController.outputDirectory = path()
        taskViewController.delegate = self
        presentViewController(taskViewController, animated: true, completion: nil)
    }
    // MARK: - ORKTaskViewControllerDelegate methods
    
    func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        
        switch taskViewController.task?.identifier {
        case .Some("ordered task identifier"):
            generatePDFData()
        default:
            break
        }

        printDataWithResult(taskViewController.result)
        
        taskViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func path() -> NSURL {
        return NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String, isDirectory: true)!
    }
    
    func printDataWithResult(result : ORKResult) {
        var error : NSError? = nil

        if let object = ORKESerializer.JSONObjectForObject(result, error: &error) {
            println("Results JSON:\n\n\(object)")
        } else {
            println("Error:\n\n\(error)")
        }
    }
}

// MARK: - Consent functions

extension ViewController {
    func generatePDFData() {
        let document = consentDocument.copy() as! ORKConsentDocument // This works
        
        if let signatureResult = taskViewController.result.stepResultForStepIdentifier("consent review step identifier")?.firstResult as? ORKConsentSignatureResult {
            signatureResult.applyToDocument(document)
        }
        
        document.makePDFWithCompletionHandler { (data, error) -> Void in
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

// MARK: - Survey functions

extension ViewController {
    
    func surveyTask() -> ORKOrderedTask {
        var steps = surveySteps()
        return ORKOrderedTask(identifier: "ordered task identifier", steps: steps)
    }

    func surveySteps () -> [ORKStep] {
        var steps = [ORKStep]()

        // ORKQuestionStep asks questions and accepts answers based on the ORKAnswerFormat provided
        
        // ORKScaleAnswerFormat presents a slider to pick a number from a scale
        let scaleAnswerFormat = ORKAnswerFormat.scaleAnswerFormatWithMaximumValue(10, minimumValue: 1, defaultValue: NSInteger.max, step: 1, vertical: false)
        let scaleQuestionStep = ORKQuestionStep(identifier: "scale question step identifier", title: "Likelihood to Eat Brains", answer: scaleAnswerFormat)
        scaleQuestionStep.text = "If presented with a giant plate of delicious brains, how likely would you be to eat them?"

        steps += [scaleQuestionStep]
        
        // ORKValuePickerAnswerFormat lets the user pick from a list
        
        let choices = [ORKTextChoice(text: "Angry and Vindictive", value: "angry"),
            ORKTextChoice(text: "Extremely Hungry", value: "hungry"),
            ORKTextChoice(text: "Even-Tempered", value: "normal")]
        let valuePickerAnswerFormat = ORKAnswerFormat.valuePickerAnswerFormatWithTextChoices(choices)
        let valuePickerQuestionStep = ORKQuestionStep(identifier: "value picker question step identifier", title: "Current Feelings", answer: valuePickerAnswerFormat)
        valuePickerQuestionStep.text = "What's the primary emotion you're feeling right now?"
        
        steps += [valuePickerQuestionStep]
        
        // ORKBooleanAnswerFormat lets the user pick Yes or No

        let booleanAnswerFormat = ORKBooleanAnswerFormat()
        
        let booleanQuestionStep = ORKQuestionStep(identifier: "boolean question step identifier", title: "Is your body fully intact?", answer: booleanAnswerFormat)
        
        steps += [booleanQuestionStep]

        // ORKCompletionStep lets the user know they've finished a task
        
        let completionStep = ORKCompletionStep(identifier: "completion step identifier")
        completionStep.title = "Hey, Thanks!"
        completionStep.text = "Thank you for your continued efforts to eradicate zombies."

        steps += [completionStep]
        
        return steps
    }
}

// MARK: - AMC's The Walking Test

extension ViewController {
    
    func walkTask() -> ORKOrderedTask {
        // Creates a pre-defined Active Task to measure walking
        return ORKOrderedTask.shortWalkTaskWithIdentifier("short walk task identifier", intendedUseDescription: "Zombies and humans walk differently. Take this test to measure how you walk.", numberOfStepsPerLeg: 20, restDuration: 20, options: nil)
    }
}