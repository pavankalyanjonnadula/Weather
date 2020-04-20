//
//  ViewController.swift
//  WeatherApp
//
//  Created by Pavan Kalyan Jonnadula on 18/04/20.
//  Copyright © 2020 Pavan Kalyan Jonnadula. All rights reserved.
//
import UIKit
import GooglePlaces

class ViewController: UIViewController , UICollectionViewDelegate , UICollectionViewDataSource , UICollectionViewDelegateFlowLayout {
    //MARK:- Layouts and Variables
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var backGroundImgaeView: UIImageView!
    @IBOutlet weak var mainCollectionView: UICollectionView!
    @IBOutlet weak var topSpaceToSafeAreaConstrait: NSLayoutConstraint!
    var arrayOfCitiesTemp = [NSDictionary]()
    var activityIndicator: ActivityIndicator?
    
    //MARK: Viewcontoller LifeCycleMethods
    override func viewDidLoad() {
        super.viewDidLoad()
        getTheHeightOFStatusBar()
        activityIndicator = ActivityIndicator(view:self.view)
        arrayOfCitiesTemp.removeAll()
    }
    override func viewWillAppear(_ animated: Bool) {
        AppAuthManager.shared.cities = getObject(forKey: "city") as? [String] ?? []
        var listOfCities = AppAuthManager.shared.cities
        if listOfCities.count == 0{
            listOfCities.append("Bangalore")
            AppAuthManager.shared.cities = listOfCities
        }
        self.mainCollectionView.delegate = self
        self.mainCollectionView.dataSource = self
        activityIndicator?.showActivityIndicator("Loading Data, Please wait...")
        for city in listOfCities{
            getWeatherDeatils(city: city)
        }
        self.activityIndicator?.stopActivityIndicator()
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    func getTheHeightOFStatusBar(){
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        topSpaceToSafeAreaConstrait.constant = -statusBarHeight
    }
    func getObject(forKey:String)->AnyObject? {
        let defaults = UserDefaults.standard
        var decodedArray : AnyObject!
        //Checking if the data exists
        if defaults.data(forKey: forKey) != nil {
            //Getting Encoded Array
            let encodedArray = defaults.data(forKey: forKey)
            //Decoding the Array
            decodedArray = NSKeyedUnarchiver.unarchiveObject(with: encodedArray!) as AnyObject
        }
        return decodedArray
    }
    //MARK: Button Actions
    @IBAction func menuButtonAction(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CitiesListViewController") as! CitiesListViewController
        vc.labelsOfCard = { data in
            self.activityIndicator?.showActivityIndicator("Loading Data, Please wait...")
            self.arrayOfCitiesTemp = AppAuthManager.shared.citiesArray
            self.mainCollectionView.reloadData()
            self.pageControl.numberOfPages = self.arrayOfCitiesTemp.count
            
            self.activityIndicator?.stopActivityIndicator()
        }
        let navigationController: UINavigationController = UINavigationController(rootViewController: vc)
        navigationController.navigationBar.isHidden = true
        
        present(navigationController, animated: true, completion: nil)
        
    }
    //MARK: API Calls
    func getWeatherDeatils(city : String) {
        let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=66c3fd0cb6de2383542585703136321a")!
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            if let error = error {
                print("Error with fetching films: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    print("Error with the response, unexpected status code: \(response)")
                    return
            }
            
            if let data = data,let jsonObj = try? JSONSerialization.jsonObject(with: data,options: JSONSerialization.ReadingOptions.allowFragments){
                print("the details ",jsonObj)
                self.arrayOfCitiesTemp.append(jsonObj as? NSDictionary ?? [:])
                DispatchQueue.main.async {
                    AppAuthManager.shared.citiesArray = self.arrayOfCitiesTemp
                    
                    self.mainCollectionView.reloadData()
                    self.pageControl.numberOfPages = self.arrayOfCitiesTemp.count
                }
                
            }
        })
        task.resume()
    }
    /////////////////////////////////////////////////////////////
    //MARK:- Collection view delegate methods
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        
        return CGSize(width: self.view.frame.width, height: self.view.frame.height - 40)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collection1", for: indexPath) as! MainCollectionCell
        cell.cityDict = arrayOfCitiesTemp[indexPath.item]
        cell.awakeFromNib()
        
        return cell
    }
    func getDayOrNight(date : String,index : Int) -> String{
        let timeString = date.components(separatedBy: "T")
        let time = timeString[1]
        let againSep = time.components(separatedBy: ":")
        let hour = Int(againSep[0]) ?? 0
        
        switch hour {
        case 6..<17 : return "Day"
        case 17..<23 : return "Night"
        default: return "Night"
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.pageControl.currentPage = indexPath.item
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatterPrint.timeZone = TimeZone(secondsFromGMT: arrayOfCitiesTemp[indexPath.item].object(forKey: "timezone") as? Int ?? 0)
        let timeZoneDate = dateFormatterPrint.string(from: Date())
        let stringOfImage = getDayOrNight(date: timeZoneDate,index: indexPath.item)
        if stringOfImage == "Day"{
            backGroundImgaeView.image = UIImage(named: "daytimeClear")
        }else{
            backGroundImgaeView.image = UIImage(named: "background")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrayOfCitiesTemp.count
    }
}
//MARK: Cell Class

class MainCollectionCell : UICollectionViewCell , UITableViewDelegate , UITableViewDataSource{
    
    @IBOutlet weak var mainTableView: UITableView!
    var cityDict = NSDictionary()
    
    override func awakeFromNib() {
        mainTableView.delegate = self
        mainTableView.dataSource = self
        mainTableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return 1
        }else{
            return 2
        }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 110
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0{
            return 120
        }
        if indexPath.row == 0 && indexPath.section == 1{
            return 280
        }else{
            return 340
        }
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0{
            let cityCell = tableView.dequeueReusableCell(withIdentifier: "city") as! CityTableCell
            cityCell.cityName.text = cityDict.object(forKey: "name") as? String ?? ""
            if let weatherDesp = cityDict.object(forKey: "weather") as? [NSDictionary] {
                let descripttion = weatherDesp[0].object(forKey: "description") as? String ?? ""
                cityCell.temDescription.text = descripttion.capitalizingFirstLetter()
                
            }
            return cityCell.contentView
        }
        let numOfHrsCell = tableView.dequeueReusableCell(withIdentifier: "hourscell") as! NumOfHoursTempCell
        return numOfHrsCell
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0{
            let tempCell = tableView.dequeueReusableCell(withIdentifier: "temp1") as! TempTableCell
            let kelvinTempDict = cityDict.object(forKey: "main") as? NSDictionary ?? [:]
            let kelvinTemp = kelvinTempDict.object(forKey: "temp") as? Double ?? 0.00
            let celcius = kelvinTemp - 273.15
            tempCell.temperature.text = "\(Int(celcius))°C"
            let dateFormatterPrint = DateFormatter()
            dateFormatterPrint.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            dateFormatterPrint.timeZone = TimeZone(secondsFromGMT: cityDict.object(forKey: "timezone") as? Int ?? 0)
            let timeZoneDate = dateFormatterPrint.string(from: Date())
            tempCell.dayCell.text = getDayOfWeekString(today: timeZoneDate) ?? "Monday"
            return tempCell
            
        }else{
            if indexPath.row == 0{
                let sevenDays = tableView.dequeueReusableCell(withIdentifier: "seven") as! sevenDaysTempCell
                return sevenDays
            }else{
                let sevenDayscell = tableView.dequeueReusableCell(withIdentifier: "desp") as! DescriptionCell
                return sevenDayscell
                
            }
        }
        
    }
    func getDayOfWeekString(today:String)->String? {
        let formatter  = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let todayDate = formatter.date(from: today) {
            let myCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
            let myComponents = myCalendar.components(.weekday, from: todayDate)
            let weekDay = myComponents.weekday
            switch weekDay {
            case 1:
                return "Sunday"
            case 2:
                return "Monday"
            case 3:
                return "Tuesday"
            case 4:
                return "Wednesday"
            case 5:
                return "Thursday"
            case 6:
                return "Friday"
            case 7:
                return "Saturday"
            default:
                print("Error fetching days")
                return "Monday"
            }
        } else {
            return nil
        }
    }
}
class CityTableCell : UITableViewCell{
    @IBOutlet weak var temDescription: UILabel!
    @IBOutlet weak var cityName: UILabel!
}
class TempTableCell : UITableViewCell{
    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var dayCell: UILabel!
    @IBOutlet weak var maxandminTemp: UILabel!
}
class NumOfHoursTempCell : UITableViewCell , UICollectionViewDelegate , UICollectionViewDataSource , UICollectionViewDelegateFlowLayout{
    @IBOutlet weak var tempCollectionView: UICollectionView!
    
    override func awakeFromNib() {
        tempCollectionView.delegate = self
        tempCollectionView.dataSource = self
        tempCollectionView.reloadData()
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 48
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 80, height: 110)
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tempCell = collectionView.dequeueReusableCell(withReuseIdentifier: "tempollectioncell", for: indexPath) as! TempCollectionCell
        if indexPath.item % 2 == 0{
            tempCell.temImage.image = UIImage(named: "sunny")
        }else{
            tempCell.temImage.image = UIImage(named: "dayPartlyCloudy")
            
        }
        tempCell.tempIndegree.text = "\(14 * indexPath.item + 1)°C"
        return tempCell
    }
}
class sevenDaysTempCell : UITableViewCell{
}
class DescriptionCell : UITableViewCell{
}
class TempCollectionCell : UICollectionViewCell{
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var temImage: UIImageView!
    @IBOutlet weak var tempIndegree: UILabel!
}

/*--------------------------------------END---------------------------------------------*/

/*--------------------------------------Singleton class---------------------------------------------*/

class AppAuthManager {
    static let shared = AppAuthManager()
    var citiesArray = [NSDictionary]()
    var cities = [String]()
}

/*--------------------------------------Extensions---------------------------------------------*/

extension UIView {
    
    @IBInspectable var cornerRadiusV: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidthV: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColorV: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}
extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}

struct ActivityIndicator {
    let activityIndicator = UIActivityIndicatorView()
    let strLabel = UILabel()
    let activityView = UIView()
    let view: UIView
    
    func showActivityIndicator(_ withText:String) {
        
        activityView.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
        activityView.backgroundColor = UIColor.white
        view.addSubview(activityView)
        
        activityIndicator.center = CGPoint(x: view.frame.size.width / 2.0, y: (view.frame.size.height) / 2.0)
        strLabel.textColor = UIColor.black
        strLabel.text = withText
        strLabel.sizeToFit()
        strLabel.center = CGPoint(x: activityIndicator.center.x, y: activityIndicator.center.y + 30)
        activityView.addSubview(strLabel)
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .gray
        activityView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    func stopActivityIndicator() {
        activityView.removeFromSuperview()
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
}
