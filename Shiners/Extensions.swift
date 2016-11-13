//
//  Extensions.swift
//  Shiners
//
//  Created by Yury Dorofeev on 4/24/16.
//  Copyright © 2016 Involve IT, Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

extension String{
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.max)
        
        let boundingBox = self.boundingRectWithSize(constraintRect, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        
        return boundingBox.height
    }
    
    func toDate() -> NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        return dateFormatter.dateFromString(self)
    }
    
    //Check email isValid
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(self)
    }
}


extension NSDate {
    func toString() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        return dateFormatter.stringFromDate(self)
    }
    
    func toShortDateString() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter.stringFromDate(self)
    }
    
    func toShortTimeString() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.stringFromDate(self)
    }
    
    func toLocalizedString() -> String{
        let locale = NSLocale.currentLocale()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .NoStyle
        dateFormatter.locale = locale
        return dateFormatter.stringFromDate(self)
    }
    
    func toLeftExpiresDatePost() -> String {
        let output: String?
        let dateFormatter = NSDateFormatter()
        let locale = NSLocale.currentLocale()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZZZZ"
        dateFormatter.locale = locale
        
        let dateToday = NSDate()
        let endDate = self
        
        let dateComponentsFormatter = NSDateComponentsFormatter()
        dateComponentsFormatter.unitsStyle = .Full
    
        dateComponentsFormatter.allowedUnits = [
            NSCalendarUnit.Year,
            NSCalendarUnit.Month,
            NSCalendarUnit.Day,
            NSCalendarUnit.Hour,
            NSCalendarUnit.Minute
        ]
        
        //If endDate < Now -> return
        if (endDate.timeIntervalSinceReferenceDate < dateToday.timeIntervalSinceReferenceDate) {
            // postClosed()
            return NSLocalizedString("post closed", comment: "Post info, post closed")
        }
        
        let date = dateComponentsFormatter.stringFromDate(dateToday, toDate: endDate)!
        let formatterArrayWithDate = date.componentsSeparatedByString(",")
        
        output = formatterArrayWithDate[0]
        
        return output!
    }
    
    func toFriendlyDateTimeString() -> String {
        
        let dateFormatter = NSDateFormatter()
        //dateFormatter.dateFormat = "h:mm a"
        
        let elapsedTimeInSeconds = NSDate().timeIntervalSinceDate(self)
        
        let secondsInDay: NSTimeInterval = 60 * 60 * 24
        
        if elapsedTimeInSeconds > 7 * secondsInDay {
            dateFormatter.dateStyle = .ShortStyle
        } else if elapsedTimeInSeconds > secondsInDay {
            dateFormatter.dateFormat = "EEE"
        } else {
            dateFormatter.timeStyle = .ShortStyle
        }
        
        return dateFormatter.stringFromDate(self)
        
        /*
        if NSCalendar.currentCalendar().isDateInToday(self){
            return self.toShortTimeString()
        } else {
            return self.toShortDateString()
        }*/
    }
    
    func toFriendlyLongDateTimeString() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = .ShortStyle
        dateFormatter.dateStyle = .LongStyle
        
        return dateFormatter.stringFromDate(self)
    }
}

extension NSData {
    var hexString: String {
        let bytes = UnsafeBufferPointer<UInt8>(start: UnsafePointer(self.bytes), count:self.length)
        return bytes.map { String(format: "%02hhx", $0) }.reduce("", combine: { $0 + $1 })
    }
}

extension UIImage {
    func correctlyOrientedImage() -> UIImage{
        if self.imageOrientation == .Up{
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.drawInRect(CGRectMake(0, 0, self.size.width, self.size.height))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return normalizedImage;
    }
    
    func resizeImage() -> UIImage {
        var actualHeight = self.size.height
        var actualWidth = self.size.width
        let maxHeight = CGFloat(1024)
        let maxWidth = CGFloat(768)
        let actualRatio = actualWidth / actualHeight
        var ratio = maxWidth / maxHeight
        
        if actualHeight > maxHeight || actualWidth > maxWidth {
            if actualRatio < ratio {
                ratio = maxHeight / actualHeight
                actualWidth = ratio * actualWidth
                actualHeight = maxHeight
            } else if actualRatio > ratio {
                ratio = maxWidth / actualWidth
                actualWidth = maxWidth
                actualHeight = ratio * actualHeight
            } else {
                actualHeight = maxHeight
                actualWidth = maxWidth
            }
        }
        
        let rect = CGRectMake(0, 0, actualWidth, actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        self.drawInRect(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        if let data = UIImageJPEGRepresentation(image, 0.7){
            return UIImage(data: data)!
        } else {
            return image
        }
    }
}

extension CLLocation{
    func distanceFromLocationFormatted(other: CLLocation) -> String{
        let distance = self.distanceFromLocation(other)
        if NSLocale.currentLocale().objectForKey(NSLocaleUsesMetricSystem) as! Bool {
            if distance < 1000 {
                return String(format: "%.0f m", distance)
            } else if distance < 10000 {
                return String(format: "%.1f km", distance / 1000)
            } else {
                return String(format: "%.0f km", distance / 1000)
            }
        } else {
            let miles = distance.mi
            if miles < 0.5 {
                return String(format: "%.0f ft", distance.ft)
            } else if miles < 10 {
                return String(format: "%.1f mi", miles)
            } else {
                return String(format: "%.0f mi", miles)
            }
        }
    }
}

extension Double {
    var km: Double { return self * 1_000.0 }
    var m: Double { return self }
    var cm: Double { return self / 100.0 }
    var mm: Double { return self / 1_000.0 }
    var ft: Double { return self / 3.28084 }
    var mi: Double { return self * 0.000621371}
}

extension NSDictionary{
    func javaScriptDateFromFirstElement() -> NSDate?{
        if self.count == 1 {
            if let dateNumber = self.allValues[0] as? Int {
                return NSDate(timeIntervalSince1970: Double(dateNumber) / 1000)
            }
        }
        return nil
    }
}

extension UIView {
    func addConstraintsWithFormat(format: String, views: UIView...) {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerate() {
            let key = "v\(index)"
            viewsDictionary[key] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary))
    }
    
    func anchorToTop(top: NSLayoutYAxisAnchor? = nil, left: NSLayoutXAxisAnchor? = nil, bottom: NSLayoutYAxisAnchor? = nil, right: NSLayoutXAxisAnchor? = nil) {
        
        anchorWithConstantsToTop(top, left: left, bottom: bottom, right: right, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0)
    }
    
    func anchorWithConstantsToTop(top: NSLayoutYAxisAnchor? = nil, left: NSLayoutXAxisAnchor? = nil, bottom: NSLayoutYAxisAnchor? = nil, right: NSLayoutXAxisAnchor? = nil, topConstant: CGFloat = 0, leftConstant: CGFloat = 0, bottomConstant: CGFloat = 0, rightConstant: CGFloat = 0) {
        
        _ = anchor(top, left: left, bottom: bottom, right: right, topConstant: topConstant, leftConstant: leftConstant, bottomConstant: bottomConstant, rightConstant: rightConstant)
    }
    
    func anchor(top: NSLayoutYAxisAnchor? = nil, left: NSLayoutXAxisAnchor? = nil, bottom: NSLayoutYAxisAnchor? = nil, right: NSLayoutXAxisAnchor? = nil, topConstant: CGFloat = 0, leftConstant: CGFloat = 0, bottomConstant: CGFloat = 0, rightConstant: CGFloat = 0, widthConstant: CGFloat = 0, heightConstant: CGFloat = 0) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        
        var anchors = [NSLayoutConstraint]()
        
        if let top = top {
            anchors.append(topAnchor.constraintEqualToAnchor(top, constant: topConstant))
        }
        
        if let left = left {
            anchors.append(leftAnchor.constraintEqualToAnchor(left, constant: leftConstant))
        }
        
        if let bottom = bottom {
            anchors.append(bottomAnchor.constraintEqualToAnchor(bottom, constant: -bottomConstant))
        }
        
        if let right = right {
            anchors.append(rightAnchor.constraintEqualToAnchor(right, constant: -rightConstant))
        }
        
        if widthConstant > 0 {
            anchors.append(widthAnchor.constraintEqualToConstant(widthConstant))
        }
        
        if heightConstant > 0 {
            anchors.append(heightAnchor.constraintEqualToConstant(heightConstant))
        }
        
        anchors.forEach({$0.active = true})
        
        return anchors
    }
}

extension UIButton {
    
    func centerTextButton() {
        let spacing: CGFloat = 6.0
        let imageSize: CGSize = self.imageView!.image!.size
        self.titleEdgeInsets = UIEdgeInsetsMake(0.0, -imageSize.width, -(imageSize.height + spacing), 0.0)
        let labelString = NSString(string: self.titleLabel!.text!)
        let titleSize = labelString.sizeWithAttributes([NSFontAttributeName: self.titleLabel!.font])
        self.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + spacing), 0.0, 0.0, -titleSize.width)
        let edgeOffset = abs(titleSize.height - imageSize.height) / 2.0;
        self.contentEdgeInsets = UIEdgeInsetsMake(edgeOffset, 0.0, edgeOffset, 0.0)
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 where value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
    
}

//Set gradient color for view
extension GradientView {
    func setGradientBlueColor() {
        startColor = UIColor(netHex: 0x5DBDF6)
        midColor = UIColor(netHex: 0x57B8F5)
        endColor = UIColor(netHex: 0x4EB2F4)
    }
}
