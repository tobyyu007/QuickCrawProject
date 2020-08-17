# QuickCrawProject
一個快速拼裝起來的爬蟲程式

## 功能
- 從 [監理所查詢場次網站](https://www.mvdis.gov.tw/m3-emv-trn/exm/locations#anchor) 爬回剩餘人數的資料
- 找到有剩餘的場次後，使用 notification 推播的方式顯示 (必須是在背景執行的時候才可以)
- 使用 Kanna 分析網頁 xpath
- 使用 SMTP 方式傳送爬到的場次訊息

## 系統需求
1. macOS 10.15 以上

## 編譯方法
### 專案用到 CocoaPods 和 Swift Package Manager，必須安裝才可以使用
#### 使用的 CocoaPods 套件
1. [Alamofire](https://github.com/Alamofire/Alamofire)
2. [Kanna](https://github.com/tid-kijyun/Kanna)
#### 使用的 Swift Package Manager 套件
1. [Swift-SMTP](https://github.com/IBM-Swift/Swift-SMTP)

## 安裝 CocoaPods 方法
1. 打開 terminal，輸入以下指令安裝
```console
sudo gem install cocoapods
```
2. 在 terminal 中 cd 到專案資料夾
3. 建立專案 Podfile
```console
pod init
```
4. 編輯 Podfile
```console
open Podfile
```
5. 加入專案所需要的套件
```console
pod 'Alamofire', '~> 5.2'
pod 'Kanna', '~> 5.2.2'
```
6. 安裝套件
```console
pod install
```
7. 使用 xcworkspace 檔開啟專案

## 設定 Swift Package Manager 方法
1. 設定 Swift Package Manager
- [Medium 教學](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/使用-spm-安裝第三方套件-xcode-11-新功能-2c4ffcf85b4b)

2. 安裝 Swift-SMTP 網址
```console
https://github.com/IBM-Swift/Swift-SMTP
```
