
import UIKit
import BackgroundTasks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let prefs = UserDefaults.standard
    let center = UNUserNotificationCenter.current()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        registerBackgroundTaks()
        registerLocalNotification()
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        cancelAllPandingBGTask()
        scheduleAppRefresh()
        scheduleImageFetcher()
    }
    
    //MARK: Regiater BackGround Tasks
    private func registerBackgroundTaks() {
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.SO.imagefetcher", using: nil) { task in
            //This task is cast with processing request (BGProcessingTask)
            self.scheduleLocalNotification()
            self.handleImageFetcherTask(task: task as! BGProcessingTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.SO.apprefresh", using: nil) { task in
            //This task is cast with processing request (BGAppRefreshTask)
            self.scheduleLocalNotification()
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }
    }
}

//MARK:- BGTask Helper
extension AppDelegate {
    
    func cancelAllPandingBGTask() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
    
    func scheduleImageFetcher() {
        let request = BGProcessingTaskRequest(identifier: "com.SO.imagefetcher")
        request.requiresNetworkConnectivity = false // Need to true if your task need to network process. Defaults to false.
        request.requiresExternalPower = false
        
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 60) // Featch Image Count after 1 minute.
        print("scheduleImageFetcher");
        //Note :: EarliestBeginDate should not be set to too far into the future.
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule image featch: \(error)")
        }
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.SO.apprefresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60) // App Refresh after 2 minute.
        print("scheduleAppRefresh");
        //Note :: EarliestBeginDate should not be set to too far into the future.
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func handleAppRefreshTask(task: BGAppRefreshTask) {
        print("handleAppRefreshTask");
        //Todo Work
        /*
         //AppRefresh Process
         */
        task.expirationHandler = {
            //This Block call by System
            //Canle your all tak's & queues
        }
        scheduleLocalNotification()
        //
        task.setTaskCompleted(success: true)
    }
    
    func handleImageFetcherTask(task: BGProcessingTask) {
        print("handleImageFetcherTask");
        scheduleImageFetcher() // Recall
        
        //Todo Work
        task.expirationHandler = {
            //This Block call by System
            //Canle your all tak's & queues
        }
        
        //Get & Set New Data
        let interator =  ListInterator()
        let presenter =  ListPresenter()
        presenter.interator = interator
        
        presenter.setNewData()
        
        var value = self.prefs.integer(forKey: "VALUE")
        value = value + 1
        self.prefs.set(value, forKey: "VALUE")
        self.createNotfications(newValue: value, message : "handleImageFetcherTask")
        
        //
        task.setTaskCompleted(success: true)
        
    }
    
    ///Notification oluşturur ve gönderim isteği yapar.
    func createNotfications(newValue:Int, message: String) {
        print("createNotfications")
        
        //Bildirim olarak gönderilmemiş istekleri temizler.
        center.removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Artış yapıldı."
        content.body = "Belirtilen değer arttırıldı. Yeni Değer -> \(String(newValue)) -> Mesaj \(message)"
        content.categoryIdentifier = "alarm"
        content.userInfo = ["customData": "fizzbuzz"]
        content.sound = UNNotificationSound.default
        
        //Takvim Tetikleyicisi
        /*
         var dateComponents = DateComponents()
         dateComponents.hour = 10
         dateComponents.minute = 30
         let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
         */
        
        //Saniye bazında Tetikleyici
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
        
    }
}

//MARK:- Notification Helper

extension AppDelegate {
    
    func registerLocalNotification() {
        let notificationCenter = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
        }
    }
    
    func scheduleLocalNotification() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                self.fireNotification()
            }
        }
    }
    
    func fireNotification() {
        // Create Notification Content
        let notificationContent = UNMutableNotificationContent()
        
        // Configure Notification Content
        notificationContent.title = "Bg"
        notificationContent.body = "BG Notifications."
        
        // Add Trigger
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        
        // Create Notification Request
        let notificationRequest = UNNotificationRequest(identifier: "local_notification", content: notificationContent, trigger: notificationTrigger)
        
        // Add Request to User Notification Center
        UNUserNotificationCenter.current().add(notificationRequest) { (error) in
            if let error = error {
                print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
            }
        }
    }
    
}
