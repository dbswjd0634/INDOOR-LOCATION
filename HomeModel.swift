//
//  HomeModel.swift
//  AR
//  Copyright © 2019 M-33. All rights reserved.
//

import Foundation


class LocationModel: NSObject {
    
    //properties
    
    var major: Double?
    var minor: Double?
    var x: Double?
    var z: Double?
    var name: String?
    var developer: String?
    var advisor: String?
    var tool: String?
    var motivation: String?
    var summary: String?

    //empty constructor
    
    override init()
    {
        
    }
    
    //construct with @name, @address, @latitude, and @longitude parameters
    
    init(major: Double, minor: Double, x: Double, z: Double, name: String, developer: String, advisor: String, tool: String, motivation: String, summary: String) {
        
        self.major = major
        self.minor = minor
        self.x = x
        self.z = z
        self.name = name
        self.developer = developer
        self.advisor = advisor
        self.tool = tool
        self.motivation = motivation
        self.summary = summary
        
    }
    
    
    //prints object's current state

    override var description: String {
        return "Major: \(String(describing: major)), Minor: \(String(describing: minor)), X: \(String(describing: x)), z: \(String(describing: z)), name: \(String(describing: name)), developer: \(String(describing: developer)), advisor: \(String(describing: advisor)), tool: \(String(describing: tool)), motivation: \(String(describing: motivation)), summary: \(String(describing: summary))"
        
    }
    
}


protocol HomeModelProtocol: class {
    func itemsDownloaded(items: NSArray)
}
 
 
class HomeModel: NSObject, URLSessionDataDelegate {
    
    //properties
    
    weak var delegate: HomeModelProtocol!
    
    var data = Data()
    
    let urlPath: String = "http://52.79.227.81/storevalues.php" //this will be changed to the path where service.php lives

    func downloadItems() {
        
        let url: URL = URL(string: urlPath)!
        let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
        
        let task = defaultSession.dataTask(with: url) { (data, response, error) in
            
            if error != nil {
                print("Failed to download data")
            }else {
                print("Data downloaded")
                self.parseJSON(data!)
            }
            
        }
        
        task.resume()
    }
    
    func parseJSON(_ data:Data) {
        
        class Square {
          var sideLength: Double
          init(sideLength: Double){
            self.sideLength = sideLength
          }
        }
        
        var jsonResult = NSArray()
        
        do{
            jsonResult = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.allowFragments) as! NSArray
            
        } catch let error as NSError {
            print(error)
            
        }
        
        var jsonElement = NSDictionary()
        let locations = NSMutableArray()
        
        for i in 0 ..< jsonResult.count
        {
            
            jsonElement = jsonResult[i] as! NSDictionary
            
            let location = LocationModel()
            
            // 숫자 만들기
            let major = String(describing: jsonElement["major"])
            let x = String(describing: jsonElement["x"])
            let z = String(describing: jsonElement["z"])
            var major2=""
            var x2=""
            var z2=""
            
            // 테스트
            let name = String(describing: jsonElement["name"])
            var name2 = ""
            let developer = String(describing: jsonElement["developer"])
            var developer2 = ""
            let advisor = String(describing: jsonElement["advisor"])
            var advisor2 = ""
            let tool = String(describing: jsonElement["tool"])
            var tool2 = ""
            let motivation = String(describing: jsonElement["motivation"])
            var motivation2 = ""
            let summary = String(describing: jsonElement["summary"])
            var summary2 = ""
            
            var tf=0;
            for s in major{
                if(s=="("){
                    tf=1;
                }
                else if(s==")"){
                    
                }
                else if(tf==1){
                    major2 = major2 + String(s)
                }
            }
            
            tf=0;
            for s in x{
                if(s=="("){
                    tf=1;
                }
                else if(s==")"){
                    
                }
                else if(tf==1){
                    x2 = x2 + String(s)
                }
            }
            
            tf=0;
            for s in z{
                if(s=="("){
                    tf=1;
                }
                else if(s==")"){
                    
                }
                else if(tf==1){
                    z2 = z2 + String(s)
                }
            }
            
            tf=0;
            for s in name{
                if(s=="("){
                    tf=1;
                }
                else if(s==")"){
                    
                }
                else if(tf==1){
                    name2 = name2 + String(s)
                }
            }
           // print(name2)
            
            tf=0;
            for s in developer{
                if(s=="("){
                    tf=1;
                }
                else if(s==")"){
                    
                }
                else if(tf==1){
                    developer2 = developer2 + String(s)
                }
            }
            
            tf=0;
            for s in advisor{
                if(s=="("){
                    tf=1;
                }
                else if(s==")"){
                    
                }
                else if(tf==1){
                    advisor2 = advisor2 + String(s)
                }
            }
            
            tf=0;
            for s in tool{
                if(s=="("){
                    tf=1;
                }
                else if(s==")"){
                    
                }
                else if(tf==1){
                    tool2 = tool2 + String(s)
                }
            }
            
            tf=0;
            for s in motivation{
                if(s=="("){
                    tf=1;
                }
                else if(s==")"){
                    
                }
                else if(tf==1){
                    motivation2 = motivation2 + String(s)
                }
            }
            
            tf=0;
            for s in summary{
                if(s=="("){
                    tf=1;
                }
                else if(s==")"){
                    
                }
                else if(tf==1){
                    summary2 = summary2 + String(s)
                }
            }
            
            let major_num = Double(major2)
            let x_num = Double(x2)
            let z_num = Double(z2)
            
            // 숫자 뽑아낸거 최종
            let majorSquare: Square? = Square(sideLength: major_num ?? 0 )
            let majorSquare2 = majorSquare!.sideLength
            //print(majorSquare2)
            
            let xSquare: Square? = Square(sideLength: x_num ?? 0 )
            let xSquare2 = xSquare!.sideLength
           // print(xSquare2)
            
            let zSquare: Square? = Square(sideLength: z_num ?? 0 )
            let zSquare2 = zSquare!.sideLength
            //print(zSquare2)
            //print(jsonElement["name"])

        
            // 출력은 String으로
            location.major=majorSquare2
            location.x=xSquare2
            location.z=zSquare2
            location.name=name2
            location.developer=developer2
            location.advisor=advisor2
            location.tool=tool2
            location.motivation=motivation2
            location.summary=summary2
            
            locations.add(location)
            
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            
            self.delegate.itemsDownloaded(items: locations)
            
        })
    }
}
