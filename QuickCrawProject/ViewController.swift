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
        if let url = URL(string: "https://www.mvdis.gov.tw/m3-emv-trn/exm/locations#anchor") {
            // 載入監理所場次查詢網站
            crawWebView.load(URLRequest(url: url))
        }
    }

    @IBAction func startButton(_ sender: Any) // Start 按鈕
    {
        let javascriptString = "document.querySelector('.cont90 .gap_t2 .std_btn').click();" // 按 "查詢場次" 按鈕
        crawWebView.evaluateJavaScript(javascriptString){ (value, error) in
            if let err = error {
                print(err)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()+5) // 等待五秒
        {
            let javascriptString2 = "document.documentElement.outerHTML"
            self.crawWebView.evaluateJavaScript(javascriptString2){ (value, error) in
                if let err = error {
                    print(err)
                }
                else
                {
                    self.parsehtml(value as! String) // 抓出網頁內容，丟入 kanna 分析
                }
            }
        }
    }
    
    func continousCraw() // 按下按鈕後繼續爬蟲動作
    {
        let javascriptString = "document.querySelector('.cont90 .gap_t2 .std_btn').click();" // 按 "查詢場次" 按鈕
        crawWebView.evaluateJavaScript(javascriptString){ (value, error) in
            if let err = error {
                print(err)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+5) // 等待五秒
        {
            let javascriptString2 = "document.documentElement.outerHTML"
            self.crawWebView.evaluateJavaScript(javascriptString2){ (value, error) in
                if let err = error {
                    print(err)
                }
                else
                {
                    self.parsehtml(value as! String) // 抓出網頁內容，丟入 kanna 分析
                }
            }
        }
    }
    
    var success = false // 已經有找到 available 的場次
    static var resultDate = [String]() // 可以的場次日期
    static var resultTime = [String]() // 可以的場次時間
    func parsehtml(_ html1: String)
    {
        let doc = try? Kanna.HTML(html: html1, encoding:.utf8)
        for i in 5...19 // 只抓 17 號到 20 號
        {
            for number in doc!.xpath("//*[@id='trnTable']/tbody/tr[\(i)]/td[3]")
            {
                if number.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "額滿"
                {
                    for date in doc!.xpath("//*[@id='trnTable']/tbody/tr[\(i)]/td[1]") // 日期
                    {
                        ViewController.resultDate.append(date.text!.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    for date in doc!.xpath("//*[@id='trnTable']/tbody/tr[\(i)]/td[2]") // 時間
                    {
                        let time = date.text!.trimmingCharacters(in: .whitespacesAndNewlines)[26...] // 把前面不需要的訊息去除
                        ViewController.resultTime.append(time)
                    }
                    success = true // 有找到場次
                    break
                }
            }
        }
        if !success // 沒有找到
        {
            continousCraw()
        }
        else // 有找到
        {
            //performSegue(withIdentifier: "success", sender: self)
            success = false
            showNotification() // 顯示場次的 notification
        }
    }
    
    func showNotification() -> Void // notificaiton 設定
    {
        let notification = NSUserNotification()
        notification.title = ViewController.resultDate[0]
        notification.subtitle = ViewController.resultTime[0]
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.deliveryDate = Date(timeIntervalSinceNow: 0)
        NSUserNotificationCenter.default.scheduleNotification(notification)
    }
}

extension String // String 切割
{
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
