//
//  ViewController.swift
//  QuickCrawProject
//
//  Created by Toby Yu on 2020/8/12.
//  Copyright © 2020 Toby Yu. All rights reserved.
//

import Cocoa
import WebKit
import Alamofire
import Kanna

class ViewController: NSViewController, WKNavigationDelegate {

    @IBOutlet weak var crawWebView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let url = URL(string: "https://www.mvdis.gov.tw/m3-emv-trn/exm/locations#anchor") {
            crawWebView.load(URLRequest(url: url))
        }
        crawWebView.navigationDelegate = self
        crawWebView.addObserver(self, forKeyPath: "URL", options: .new, context: nil) // 偵測頁面改變
    }

    @IBAction func startButton(_ sender: Any) {
        let javascriptString = "document.querySelector('.cont90 .gap_t2 .std_btn').click();"
        crawWebView.evaluateJavaScript(javascriptString){ (value, error) in
            if let err = error {
                print(err)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()+5) {
            let javascriptString2 = "document.documentElement.outerHTML"
            self.crawWebView.evaluateJavaScript(javascriptString2){ (value, error) in
                if let err = error {
                    print(err)
                }
                else
                {
                    self.parsehtml(value as! String)
                }
            }
        }
    }
    
    func continousCraw()
    {
        let javascriptString = "document.querySelector('.cont90 .gap_t2 .std_btn').click();"
        crawWebView.evaluateJavaScript(javascriptString){ (value, error) in
            if let err = error {
                print(err)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+5) {
            let javascriptString2 = "document.documentElement.outerHTML"
            self.crawWebView.evaluateJavaScript(javascriptString2){ (value, error) in
                if let err = error {
                    print(err)
                }
                else
                {
                    self.parsehtml(value as! String)
                }
            }
        }
    }
    
    var success = false
    static var resultDate = [String]()
    static var resultTime = [String]()
    var index = 0
    func parsehtml(_ html1: String)
    {
        let doc = try? Kanna.HTML(html: html1, encoding:.utf8)
        for i in 5...19
        {
            for number in doc!.xpath("//*[@id='trnTable']/tbody/tr[\(i)]/td[3]")
            {
                if number.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "額滿"
                {
                    for date in doc!.xpath("//*[@id='trnTable']/tbody/tr[\(i)]/td[1]")
                    {
                        ViewController.resultDate.append(date.text!.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    for date in doc!.xpath("//*[@id='trnTable']/tbody/tr[\(i)]/td[2]")
                    {
                        let time = date.text!.trimmingCharacters(in: .whitespacesAndNewlines)[26...]
                        ViewController.resultTime.append(time)
                    }
                    success = true
                    break
                }
            }
        }
        if !success
        {
            continousCraw()
        }
        else
        {
            //performSegue(withIdentifier: "success", sender: self)
            success = false
            showNotification()
            //continousCraw()
        }
    }
    
    func showNotification() -> Void {
        let notification = NSUserNotification()
        notification.title = ViewController.resultDate[0]
        notification.subtitle = ViewController.resultTime[0]
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.deliveryDate = Date(timeIntervalSinceNow: 0)
        NSUserNotificationCenter.default.scheduleNotification(notification)
    }
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound,
                                             range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }

    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
         return String(self[start...])
    }
}
