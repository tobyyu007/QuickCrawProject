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
import SwiftSMTP

class ViewController: NSViewController, WKNavigationDelegate {

    @IBOutlet weak var crawWebView: WKWebView!
    @IBOutlet weak var dateFrom: NSDatePicker!
    @IBOutlet weak var dateTo: NSDatePicker!
    @IBOutlet weak var resultDisplayLabel: NSTextField!
    
    var dateFromFormatted = ""
    var dateToFormatted = ""
    var stopCrawing = false // 是否要爬蟲
    var previousDateData = ""
    var previousTimeData = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = URL(string: "https://www.mvdis.gov.tw/m3-emv-trn/exm/locations#anchor") {
            // 載入監理所場次查詢網站
            crawWebView.load(URLRequest(url: url))
        }
        
        
        clear(cache: true, cookies: true)
    }
    
    func clear(cache: Bool, cookies: Bool) {
        if cache { clearCache() }
        if cookies { clearCookies() }
    }

    fileprivate func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }

    fileprivate func clearCookies() {
        let cookieStorage = HTTPCookieStorage.shared

        guard let cookies = cookieStorage.cookies else { return }

        for cookie in cookies {
            cookieStorage.deleteCookie(cookie)
        }
    }

    @IBAction func startButton(_ sender: Any) // Start 按鈕
    {
        stopCrawing = false
        previousTimeData = "" // 上次搜尋到的時間
        previousDateData = "" // 上次搜尋到的日期
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
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyy年M月d日"
        dateFormatter.locale = Locale(identifier: "zh_Hant_TW") // 設定地區(台灣)
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Taipei") // 設定時區(台灣)
        dateFormatter.calendar = Calendar(identifier: Calendar.Identifier.republicOfChina)
        dateFromFormatted = dateFormatter.string(from: dateFrom.dateValue)
        dateToFormatted = dateFormatter.string(from: dateTo.dateValue)
    }
    @IBAction func stopButton(_ sender: Any) // stop 按鈕
    {
        stopCrawing = true
    }
    
    func continousCraw() // 按下按鈕後繼續爬蟲動作
    {
        if !stopCrawing // 還要繼續爬蟲
        {
            searchDateRange.removeAll()
            resultTime.removeAll()
            resultDate.removeAll()
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
    }
    
    var success = false // 已經有找到 available 的場次
    var resultDate = [String]() // 可以的場次日期
    var resultTime = [String]() // 可以的場次時間
    var searchDateRange = [Int]()
    func parsehtml(_ html1: String)
    {
        let doc = try? Kanna.HTML(html: html1, encoding:.utf8)
        for i in 1...81 // 搜尋包含所要日期的 index
        {
            for date in doc!.xpath("//*[@id='trnTable']/tbody/tr[\(i)]/td[1]")
            {
                if date.text!.trimmingCharacters(in: .whitespacesAndNewlines).contains(dateFromFormatted)
                {
                    searchDateRange.append(i)
                }
                else if date.text!.trimmingCharacters(in: .whitespacesAndNewlines).contains(dateToFormatted)
                {
                    searchDateRange.append(i)
                }
            }
        }
        print("range is")
        print(searchDateRange)
        
        if !searchDateRange.isEmpty
        {
            for i in searchDateRange[0]...searchDateRange[searchDateRange.count-1]
            {
                for number in doc!.xpath("//*[@id='trnTable']/tbody/tr[\(i)]/td[3]")
                {
                    if number.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "額滿"
                    {
                        for date in doc!.xpath("//*[@id='trnTable']/tbody/tr[\(i)]/td[1]") // 日期
                        {
                            resultDate.append(date.text!.trimmingCharacters(in: .whitespacesAndNewlines) + "苓雅監理所")
                        }
                        for date in doc!.xpath("//*[@id='trnTable']/tbody/tr[\(i)]/td[2]") // 時間
                        {
                            let time = date.text!.trimmingCharacters(in: .whitespacesAndNewlines)[26...] // 把前面不需要的訊息去除
                            resultTime.append(time + "\nhttps://www.mvdis.gov.tw/m3-emv-trn/exm/locations#anchor")
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
                success = false
                if previousDateData == "" && previousTimeData == "" // 如果是第一次跑
                {
                    previousDateData = resultDate[0]
                    previousTimeData = resultTime[0]
                    sendMail(subject: resultDate[0], text: resultTime[0])
                }
                else
                {
                    if previousDateData != resultDate[0] || previousTimeData != resultTime[0] // 跟之前得資訊不一樣
                    {
                        sendMail(subject: resultDate[0], text: resultTime[0])
                        previousDateData = resultDate[0]
                        previousTimeData = resultTime[0]
                    }
                }
                showNotification() // 顯示場次的 notification
                continousCraw()
            }
        }
        else
        {
            continousCraw()
        }
    }
    
    func sendMail(subject: String, text: String)
    {
        let smtp = SMTP(
            hostname: "smtp.gmail.com",     // SMTP server address
            email: "iansweb.asuscomm.com@gmail.com",        // username to login
            password: "9zh-Ac2-3Nx-dQC"            // password to login
        )
        
        let Skynet = Mail.User(name: "Skynet", email: "iansweb.asuscomm.com@gmail.com")
        let TobyYu = Mail.User(name: "Toby Yu", email: "tobyyu007@hotmail.com")

        let mail = Mail(
            from: Skynet,
            to: [TobyYu],
            subject: subject,
            text: text
        )

        smtp.send(mail) { (error) in
            if let error = error {
                print(error)
            }
        }
    }
    
    func showNotification() -> Void // notificaiton 設定
    {
        let notification = NSUserNotification()
        notification.title = resultDate[0] + ""
        notification.subtitle = resultTime[0]
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.deliveryDate = Date(timeIntervalSinceNow: 0)
        NSUserNotificationCenter.default.scheduleNotification(notification)
        
        resultDisplayLabel.stringValue = resultDate[0] + " " + resultTime[0]
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
