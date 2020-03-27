//
//  ViewController.swift
//  hello-maps
//
//  Created by Mohammad Azam on 8/5/18.
//  Copyright © 2018 Mohammad Azam. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Firebase
import AVFoundation
import SceneKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var ARMode: UIButton!
    @IBOutlet weak var mapView :MKMapView!
    private let locationManager = CLLocationManager()
    private var Inside = false
    private var pinLat = 0.0
    private var pinLong = 0.0
    private var songName = ""
    private var artistName = ""

  
    var audioPlayer = AVAudioPlayer()


    
    @IBOutlet var pauseButton: UIBarButtonItem!
    
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.ARMode.isHidden = true
        
        self.mapView.delegate = self

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
        
        
        
        self.mapView.showsUserLocation = true
        
        addPointOfInterest()
 
    }
    
    @IBAction func pauseTapped(_ sender: Any) {
        if (audioPlayer.isPlaying == true) {
            audioPlayer.pause()
            Inside = false
            
        }
    }
    
    private func setUpMusic(songFile: String) {
        print(songFile)
        let sound = Bundle.main.path(forResource: "song", ofType: "mp3")
        
              
              do {
                  audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
                  try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: [AVAudioSession.CategoryOptions.mixWithOthers])
              } catch {
                  print(error)
              }
    }
    
    private func songReturn(latcoor: Double, longcoor: Double) {
        var songName: [String]  = []
        let db = Firestore.firestore()
        db.collection("points")
        .getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
           
                for document in querySnapshot!.documents {
                   let locations = document.get("location") as! Array<Any>
                  // print (locations!)
                    //print(locations)
                    let latLoc = locations[0] as? Double
                    let longLoc = locations[1] as? Double
              
                    if (latLoc == latcoor && longLoc == longcoor) {
                        
                       let first = document.get("song") as! [String]
                        songName.append(first[0])
                        songName.append(first[1])
                        print(songName)

                    }
                }
            }
        }
    }
    
  
    
    private func addPointOfInterest() {
        
         let db = Firestore.firestore()
        db.collection("points")
               .getDocuments() { (querySnapshot, err) in
                   if let err = err {
                       print("Error getting documents: \(err)")
                   } else {
                    var count = 1
                       for document in querySnapshot!.documents {
                          let locations = document.get("location") as! Array<Any>
                         // print (locations!)
                        print(locations)
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = CLLocationCoordinate2D(latitude: locations[0] as! CLLocationDegrees, longitude: locations[1] as! CLLocationDegrees)
                        
                        self.mapView.addAnnotation(annotation)
                        
                        
                        
                        let region = CLCircularRegion(center: annotation.coordinate, radius: 70, identifier: "CoffeeShopRegion\(count)")
                        count = count+1
                        
                        region.notifyOnEntry = true
                        region.notifyOnExit = true
                        
                        self.mapView.addOverlay(MKCircle(center: annotation.coordinate, radius: 70))
                        
                        self.locationManager.startMonitoring(for: region)
                    }
                }
        }

    }
    

    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("didEnterRegion")
        Inside = true
    }
    
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("didExitRegion")
        Inside = false
        audioPlayer.pause()
        ARMode.isHidden = true
    
    }


    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKCircle {
            var circleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = UIColor.purple
            circleRenderer.fillColor = UIColor.purple
            circleRenderer.alpha = 0.4
            return circleRenderer
        }
        
        return MKOverlayRenderer() 
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        //let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
        //mapView.setRegion(region, animated: true)
        if(Inside == true) {
            
      
            let pinLoc  = CLLocation(latitude: pinLat, longitude: pinLong)
            let userLoc = CLLocation(latitude: mapView.userLocation.coordinate.latitude, longitude: mapView.userLocation.coordinate.longitude)
            let distanceInMeters = userLoc.distance(from: pinLoc)
            print(distanceInMeters)
            audioPlayer.play()
            audioPlayer.volume = 0.4
            ARMode.isHidden = true
            if (distanceInMeters < 55 && distanceInMeters < 57 ) {
                
                
                print("volume 6")
                audioPlayer.volume = 0.6
                ARMode.isHidden = true
            }
            else if (distanceInMeters < 55 && distanceInMeters > 50 ) {
                print("volume 8")
                audioPlayer.volume = 0.8
                ARMode.isHidden = true
            } else if (distanceInMeters < 50) {
                print("Would you like to enter event?")
                audioPlayer.volume = 1.0
                ARMode.isHidden = false
                
            }

        }
       
        
       
    }
  
    @IBAction func arButtonPressed(_ sender: Any) {
          performSegue(withIdentifier: "name", sender: self)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let loc1lat = view.annotation?.coordinate.latitude ?? 0
        let loc1long = view.annotation?.coordinate.longitude ?? 0
        
        //print(songInfo)
        let loc2 = CLLocation(latitude: self.mapView.userLocation.coordinate.latitude, longitude: self.mapView.userLocation.coordinate.longitude)
        let loc1  = CLLocation(latitude: loc1lat, longitude: loc1long)
        let distanceInMeters = loc1.distance(from: loc2)
     
        if (distanceInMeters > 10 && distanceInMeters < 70) {
            pinLat = view.annotation?.coordinate.latitude ?? 0
            //print(pinLat)
            pinLong = view.annotation?.coordinate.longitude ?? 0
            //print(pinLong)
            //var songName: [String]  = []
            let db = Firestore.firestore()
            db.collection("points")
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
               
                    for document in querySnapshot!.documents {
                       let locations = document.get("location") as! Array<Any>
                      // print (locations!)
                        //print(locations)
                        let latLoc = locations[0] as? Double
                        let longLoc = locations[1] as? Double
                  
                        if (latLoc == self.pinLat && longLoc == self.pinLong) {
                            
                           let first = document.get("song") as! [String]
                            self.songName = first[0]
                            self.artistName = first[1]
                            print(self.songName)
                            print(self.artistName)
                            print("Allow sound")
                            self.setUpMusic(songFile: self.songName)
                            //print(distanceInMeters)
                            self.Inside = true
                        }
                    }
                }
            }
        } else if (distanceInMeters < 10){
            
            pinLat = view.annotation?.coordinate.latitude ?? 0
            //print(pinLat)
            pinLong = view.annotation?.coordinate.longitude ?? 0
            //print(pinLong)
            //var songName: [String]  = []
            let db = Firestore.firestore()
            db.collection("points")
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
               
                    for document in querySnapshot!.documents {
                       let locations = document.get("location") as! Array<Any>
                      // print (locations!)
                        //print(locations)
                        let latLoc = locations[0] as? Double
                        let longLoc = locations[1] as? Double
                  
                        if (latLoc == self.pinLat && longLoc == self.pinLong) {
                            
                           let first = document.get("song") as! [String]
                            self.songName = first[0]
                            self.artistName = first[1]
                            print(self.songName)
                            print(self.artistName)
                            print("Allow sound")

                            print("Enter AR")
                            self.setUpMusic(songFile: self.songName)
                            self.performSegue(withIdentifier: "name", sender: self)
                            self.Inside = true
                        }
                    }
                }
            }


        } else {
            print("Event too far away")
               print(distanceInMeters)
        }
        
    }
    
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            
            if(segue.identifier == "name") {
            var text = self.artistName


            let destinationVC = segue.destination as? ARSceneViewController
                destinationVC!.arName = text
            }
            
    }
    }
    




    


