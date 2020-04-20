//
//  CitiesListViewController.swift
//  WeatherApp
//
//  Created by Pavan Kalyan Jonnadula on 20/04/20.
//  Copyright © 2020 Pavan Kalyan Jonnadula. All rights reserved.
//

import UIKit
import GooglePlaces
class CitiesListViewController: UIViewController , UITableViewDelegate , UITableViewDataSource {
    @IBOutlet weak var citiesTableView: UITableView!
    var arrayOfCitiesTemp = [NSDictionary]()
    var labelsOfCard : ((Bool) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        arrayOfCitiesTemp = AppAuthManager.shared.citiesArray
        citiesTableView.delegate = self
        citiesTableView.dataSource = self
    }
    override func viewWillDisappear(_ animated: Bool) {
        self.labelsOfCard?(true)
    }
    @IBAction func addBtnAction(_ sender: Any) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        // Specify the place data types to return.
        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) |
            UInt(GMSPlaceField.placeID.rawValue))!
        autocompleteController.placeFields = fields
        
        // Specify a filter.
        let filter = GMSAutocompleteFilter()
        filter.type = .city
        autocompleteController.autocompleteFilter = filter
        
        // Display the autocomplete view controller.
        present(autocompleteController, animated: true, completion: nil)
    }
    
    //MARK: API Calls
    func getWeatherDeatils(city : String) {
        if let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=66c3fd0cb6de2383542585703136321a"){
        
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
                    AppAuthManager.shared.cities.append(city)

                    self.citiesTableView.reloadData()
                }
           
            }
        })
        task.resume()
        }
    }
    //MARK: Tableview delegate methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfCitiesTemp.count + 1
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == arrayOfCitiesTemp.count{
            return 50
        }
        return 75
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == arrayOfCitiesTemp.count{
            let cell = tableView.dequeueReusableCell(withIdentifier: "add") as! AdditionOfCititesCell
            return cell

        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "citycell") as! CitiesTableViewCell
        let details = arrayOfCitiesTemp[indexPath.row]
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let cityTimezone = TimeZone(secondsFromGMT: details.object(forKey: "timezone") as? Int ?? 0)
        dateFormatterPrint.timeZone = cityTimezone
        let timeZoneDate = dateFormatterPrint.string(from: Date())
        let stringOfImage = getDayOrNight(date: timeZoneDate,index: indexPath.item)
        if stringOfImage == "Day"{
            cell.bgImage.image = UIImage(named: "daytimeClear")
        }else{
            cell.bgImage.image = UIImage(named: "background")
        }
        let kelvinTempDict = details.object(forKey: "main") as? NSDictionary ?? [:]
        let kelvinTemp = kelvinTempDict.object(forKey: "temp") as? Double ?? 0.00
        let celcius = kelvinTemp - 273.15
        cell.tempLabel.text = "\(Int(celcius))°"
        cell.cityLabel.text = details.object(forKey: "name") as? String ?? ""
        cell.time.text = convertTimeStampTimeFormatter(date: timeZoneDate,timezone: cityTimezone ?? TimeZone.current)
        return cell
    }
    
    func convertTimeStampTimeFormatter(date : String , timezone : TimeZone) -> String
      {
          
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"//this your string date format
          dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
          
          let date = dateFormatter.date(from: date)
          dateFormatter.dateFormat = "hh:mm a"///this is what you want to convert format
          dateFormatter.timeZone = timezone
          var timeStamp = ""
          if date != nil{
              timeStamp = dateFormatter.string(from: date!)
          }
          
          return timeStamp
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
}
//MARK: Cells
class CitiesTableViewCell: UITableViewCell {
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var bgImage: UIImageView!
}
class AdditionOfCititesCell: UITableViewCell {
    @IBOutlet weak var addCityBtn: UIButton!
}
extension CitiesListViewController: GMSAutocompleteViewControllerDelegate {

  // Handle the user's selection.
  func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
    print("Place name: \(place.name)")
    getWeatherDeatils(city: place.name ?? "")
    print("Place ID: \(place.placeID)")
    print("Place attributions: \(place.attributions)")
    dismiss(animated: true, completion: nil)
  }

  func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
    // TODO: handle the error.
    print("Error: ", error.localizedDescription)
  }

  // User canceled the operation.
  func wasCancelled(_ viewController: GMSAutocompleteViewController) {
    dismiss(animated: true, completion: nil)
  }

  // Turn the network activity indicator on and off again.
  func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
  }

  func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
  }

}
/*------------------------------------------END--------------------------------------------------------*/
