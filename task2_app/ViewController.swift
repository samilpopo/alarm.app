//
//  ViewController.swift
//  task2_app
//
//  Created by samil on 5.01.2024.
//

import UIKit
import UserNotifications
import AVFoundation
import CoreData

class ViewController: UIViewController, UNUserNotificationCenterDelegate {
    
    // Массив для хранения данных из Core Data
    var data = [NSManagedObject]()
    
    // Аудио-плеер для воспроизведения сигнала будильника
    var audioPlayer: AVAudioPlayer?
    
    // Время установленного будильника и выбранное пользователем время
    var alarmTime: Date?
    var pickedDate: Date?
    
    // Outlets для интерфейса
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var setAlarmButton: UIButton!
    
    // Центр уведомлений
    let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - View Lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        // Проверка и обновление состояния будильника при появлении экрана
        ChechForAlarmState()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Установка делегата для UNUserNotificationCenter
        UNUserNotificationCenter.current().delegate = self
        
        // Проверка и обновление состояния будильника при загрузке экрана
        ChechForAlarmState()
        
        // Запрос разрешений на уведомления
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { (_, _) in }
    }
    
    // MARK: - User Actions
    
    @IBAction func setAlertClicked(_ sender: Any) {
        // Обработка действия при нажатии кнопки установки будильника
        if audioPlayer?.isPlaying == true {
            // Остановка воспроизведения аудио, если оно уже запущено
            audioPlayer?.stop()
            setAlarmButton.setTitle("поставить", for: [])
            setAlarmButton.tintColor = .systemBlue
        } else {
            // Запланировать новое уведомление и сохранить установленное время будильника
            let title = "время пришло"
            let message = "вставай!"
            let date = timePicker.date
            scheduleNotification(forDate: date, title: title, message: message)
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let managedObjectContext = appDelegate?.persistentContainer.viewContext
            
            // Удаление существующих данных и сохранение нового времени будильника
            for item in data {
                managedObjectContext?.delete(item)
            }
            
            let entity = NSEntityDescription.entity(forEntityName: "Entity", in: managedObjectContext!)
            let item = NSManagedObject(entity: entity!, insertInto: managedObjectContext)
            item.setValue(date, forKey: "lastAlarm")
            print("Сохранение успешно \(String(describing: date))")
            
            try? managedObjectContext?.save()
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Обработка ответа пользователя на уведомление
        if chechForAlarmTime() { }
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
        
        // Обновление состояния будильника и вызов завершающего обработчика
        ChechForAlarmState()
        completionHandler()
    }
    
    // MARK: - Notification Actions
    
    func removeNotification(withIdentifier identifier: String) {
        // Удаление запланированного уведомления по идентификатору
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func scheduleSnoozeNotification() {
        // Запланировать уведомление для повтора будильника
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
    
    // MARK: - Alarm State
    
    func ChechForAlarmState() {
        // Проверка и обновление состояния будильника, адаптация интерфейса
        if audioPlayer?.isPlaying == true {
            setAlarmButton.tintColor = .systemRed
            setAlarmButton.setTitle("остановить", for: [])
        } else {
            setAlarmButton.tintColor = .systemBlue
            setAlarmButton.setTitle("поставить", for: [])
        }
    }
    
    // MARK: - Core Data
    
    func fetch() {
        // Получение последнего сохраненного времени будильника из Core Data
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let managedObjectContext = appDelegate?.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Entity")
        
        data = try! managedObjectContext!.fetch(fetchRequest)
        let lastDate = data.first
        alarmTime = lastDate?.value(forKey: "lastAlarm") as? Date
        print(alarmTime as Any)
    }
    
    func chechForAlarmTime() -> Bool {
        // Проверка соответствия выбранного времени последнему сохраненному времени будильника
        fetch()
        print(alarmTime ?? "будильник не установлен")
        pickedDate = self.timePicker.date
        print("выбранное время \(String(describing: pickedDate)) и сохраненное время \(String(describing: alarmTime))")
        
        let p1 = Calendar.current.dateComponents([.hour, .minute], from: pickedDate!)
        let p2 = Calendar.current.dateComponents([.hour, .minute], from: alarmTime ?? .distantPast)
        
        return p1 == p2
    }
    
    // MARK: - Presentation Options
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Обработка отображения уведомления, когда приложение активно
        completionHandler([.alert, .badge, .sound])
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleNotification(forDate date: Date, title: String, message: String) {
        // Запланировать уведомление на указанное время
        notificationCenter.getNotificationSettings { (settings) in
            DispatchQueue.main.async {
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
                        print("Ошибка: \(error.localizedDescription)")
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



