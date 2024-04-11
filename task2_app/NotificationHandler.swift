//
//  NotificationHandler.swift
//  task2_app
//
//  Created by samil on 24.01.2024.
//

import UserNotifications
import AVFoundation
import CoreData
import UIKit

class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {

    var audioPlayer: AVAudioPlayer?
    var alarmTime: Date?
    var pickedDate: Date?
    var data = [NSManagedObject]()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if chechForAlarmTime() {
            // ваша логика
        }
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            print("Действие отклонено")
        case UNNotificationDefaultActionIdentifier:
            print("Выбрано стандартное действие")
        case "Snooze":
            print("Выбрана кнопка Повтор")
            scheduleSnoozeNotification()
        case "Delete":
            print("Выбрана кнопка Удалить")
            removeNotification(withIdentifier: "alarm-identifier")
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["alarm-identifier"])
        default:
            print("Неизвестное действие")
        }
        
        ChechForAlarmState()
        completionHandler()
    }
    //удалить
    func removeNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    //повтор
    func scheduleSnoozeNotification() {
        let content = UNMutableNotificationContent()
        content.title = "время пришло"
        content.body = "вставай!"
        content.sound = .criticalSoundNamed(UNNotificationSoundName("wow.mp3"), withAudioVolume: 0.5)
        content.categoryIdentifier = "UserActionsCategory"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30, repeats: false)
        
        let request = UNNotificationRequest(identifier: "snooze-identifier", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("Ошибка при установке повторного уведомления: \(error.localizedDescription)")
            }
        }
    }
    
    //проверка состояния будильника
    func ChechForAlarmState(){
        if( audioPlayer?.isPlaying == true){
            setAlarmButton.tintColor = .systemRed
            setAlarmButton.setTitle("остановить", for: [])
            
        } else if(audioPlayer?.isPlaying == false){
            setAlarmButton.tintColor = .systemBlue
            setAlarmButton.setTitle("поставить", for: [])
        }
    }
    func fetch(){
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let menagedObjectContext = appDelegate?.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Entity")
        data = try! menagedObjectContext!.fetch(fetchRequest)//////////////
        let lastDate = data.first
        alarmTime = lastDate?.value(forKey: "lastAlarm") as? Date
        print(alarmTime as Any)
    }
    func chechForAlarmTime() -> Bool{
        fetch()
        print(alarmTime ?? "no alarm was settled")
        pickedDate = self.timePicker.date
        print("picked date \(String(describing: pickedDate)) and fetched date \(String(describing: alarmTime))")
        let p1 = Calendar.current.dateComponents([.hour,.minute], from: pickedDate!)
        let p2 = Calendar.current.dateComponents([.hour, .minute], from: alarmTime ?? .distantPast)
        if p1 == p2 {
            return true
        }
        else {
            return false
}
}
}
