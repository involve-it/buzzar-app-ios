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


