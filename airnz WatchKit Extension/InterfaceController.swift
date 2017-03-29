//
//  InterfaceController.swift
//  airnz WatchKit Extension
//
//  Created by Claudius Mbemba on 3/23/17.
//  Copyright © 2017 Claudius Mbemba. All rights reserved.
//

import WatchKit
import Foundation

let TEXT_ENDPOINT = "http://wavy.azurewebsites.net/speech/text"
let AUDIO_ENDPOINT = "http://wavy.azurewebsites.net/speech/audio"
let RESPONSE_FILE = "airnz_response.wav"
let FILE_NAME = "audioFile.wav"
let APP_GROUP = "group.com.airnz"

class InterfaceController: WKInterfaceController {
    
    @IBOutlet var recordButton: WKInterfaceButton!
    @IBOutlet var playButton: WKInterfaceButton!
    @IBOutlet var resultLabel: WKInterfaceLabel!
    
    var saveUrl: NSURL?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        //        self.playButton.setEnabled(false)
        let fileManager = FileManager.default
        
        let container =
            fileManager.containerURL(forSecurityApplicationGroupIdentifier: APP_GROUP)

        let fileName = FILE_NAME
        
        saveUrl = container?.appendingPathComponent(fileName) as NSURL?;
        
        NSLog("%@", "\n==========================================\n\n\n Claudius Logging:\n @file: \(#file)\n @func: \(#function)\n @line: \(#line)\n @data: \(saveUrl)   \n\n\n==========================================\n");
    }
    
    @IBAction func recordAudio() {
        self.resultLabel.setText("");
        let duration = TimeInterval(10)
        
        let recordOptions =
            [WKAudioRecorderControllerOptionsMaximumDurationKey : duration,
             WKAudioRecorderControllerOptionsActionTitleKey: "Save"] as [String : Any]
        
        presentAudioRecorderController(
            withOutputURL: saveUrl! as URL,
            preset: .narrowBandSpeech,
            options: recordOptions,
            completion: {
                saved, error in
                
                if let err = error {
                    print(err.localizedDescription)
                }
                
                if saved {
                    //  self.playButton.setEnabled(true)
                    self.postToApi(api: AUDIO_ENDPOINT)
                }
        })
        
    }
    
    @IBAction func playAudio() {
        playAudioWithMediaPlayer(url: saveUrl as! URL)
        //        let fileURL = Bundle.main.url(forResource: "b001", withExtension: "wav")
        //        playRecordedAudio(url: fileURL!)
        
    }
    
    func playAudioWithMediaPlayer(url: URL) {
        let options = [WKMediaPlayerControllerOptionsAutoplayKey : "true"]
        
        presentMediaPlayerController(
            with: url,
            options: options,
            completion: { didPlayToEnd, endTime, error in
                if let err = error {
                    NSLog("%@", "\n==========================================\n\n\n Claudius Logging:\n @file: \(#file)\n @func: \(#function)\n @line: \(#line)\n @data: \(err)   \n\n\n==========================================\n");
                }
        })
    }
    
    @IBAction func postToSpeech(){
        postToApi(api: AUDIO_ENDPOINT)
    }
    
    //Manually builds the headers needed
    //Adapted from https://stackoverflow.com/questions/4674982/uploading-audio-file-using-http-post-in-objective-c
    func prepareHttpBody(data: NSData) -> NSData {
        
        let boundary = "---------------------------14737809831466499882746641449"
        
        let postData = NSMutableData.init()
        let header: String = String.init(format: "--%@\r\n", boundary)
        postData.append(header.data(using: String.Encoding.utf8)!)
        
        let contentDisposition = String.init(format: "Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", "watch.wav", "watch.wav")
        
        postData.append(contentDisposition.data(using: .utf8)!)
        
        postData.append(data as Data)
        
        let footer = String.init(format: "\r\n--%@\r\n", boundary)
        
        postData.append(footer.data(using: .utf8)!)
        return postData
    }
    
    //Makes Http request
    //Adapted from http://jamesonquave.com/blog/making-a-post-request-in-swift/
    func postToApi(api:String){
        
        let request = NSMutableURLRequest(url: NSURL(string: api) as! URL)
        let session = URLSession.shared
        request.httpMethod = "POST"
        
        var data: NSData? = nil;
        data = NSData.init(contentsOf: self.saveUrl as! URL)
        
        request.httpBody = prepareHttpBody(data: data!) as Data
        NSLog("%@", "\n==========================================\n\n\n Claudius Logging:\n @file: \(#file)\n @func: \(#function)\n @line: \(#line)\n @data: \(request.httpBody)   \n\n\n==========================================\n");
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error -> Void in
            
            NSLog("%@", "\n==========================================\n\n\n Claudius Logging:\n @file: \(#file)\n @func: \(#function)\n @line: \(#line)\n @data: \(data) \n @resp: \(response) \n @err: \(error)   \n\n\n==========================================\n");
            if let realData = data {
                self.writeReturnedAudioToFile(audioData:  realData)
            }
        })
        
        task.resume()
    }
    
    
    func writeReturnedAudioToFile(audioData: Data){
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let filePath = documentsPath.appending(RESPONSE_FILE)
        let fileURL = URL(fileURLWithPath: filePath)
        
        do {
            try audioData.write(to: fileURL)
            self.playAudioWithMediaPlayer(url: fileURL)
        } catch {
            NSLog("%@", "\n==========================================\n\n\n Claudius Logging:\n @file: \(#file)\n @func: \(#function)\n @line: \(#line)\n @data: Error writing data to file   \n\n\n==========================================\n");
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
}
