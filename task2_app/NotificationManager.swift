//
//  NotificationManager.swift
//  task2_app
//
//  Created by samil on 24.01.2024.
//

import UserNotifications
import CoreData

class NotificationManager {
    
    let notificationCenter = UNUserNotificationCenter.current()
    var data = [NSManagedObject]()
    
    func scheduleNotification(forDate date: Date, withTitle title: String, message: String) {
        notificationCenter.getNotificationSettings { (settings) in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized {
                    let content = UNMutableNotificationContent()
                    let identifier = "alarm-identifier"
                    let userAction = "UserActions"
                    
                    content.title = title
                    content.body = message
                    content.sound = .criticalSoundNamed(UNNotificationSoundName("wow.mp3"), withAudioVolume: 0.5)
                    content.categoryIdentifier = userAction
                    
                    let pickedDate = Calendar.current.dateComponents([.hour, .minute], from: date)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: pickedDate, repeats: false)
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    
                    self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
                    self.notificationCenter.add(request) { (error) in
                        if let error = error {
                            print("Error: \(error.localizedDescription)")
                            return
                        }
                    }
                    
                    let snoozeAction = UNNotificationAction(identifier: "Snooze", title: "Отложить", options: [])
                    let deleteAction = UNNotificationAction(identifier: "Delete", title: "Удалить", options: [.destructive])
                    
                    let categoryOptions: UNNotificationCategoryOptions = [.customDismissAction, .allowInCarPlay, .hiddenPreviewsShowTitle]
                    
                    let category = UNNotificationCategory(identifier: userAction, actions: [snoozeAction, deleteAction], intentIdentifiers: [], options: [])
                    self.notificationCenter.setNotificationCategories([category])
                }
            }
        }
    }
}
