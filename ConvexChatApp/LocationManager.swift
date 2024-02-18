import SwiftUI
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    @Published var degrees: Double = 0
    @Published var locations: [CLLocation]?
    @Published var newDist: String?
    let radius: CLLocationDistance = 222.638
        
    override init() {
        super.init()
        manager.delegate = self
        manager.startUpdatingHeading()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.requestWhenInUseAuthorization()
        print("\(manager.accuracyAuthorization)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        degrees = newHeading.trueHeading
    }
    
    func requestLocation() {
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locations = locations
        if let locations = self.locations {
            if locations.count >= 2 {
                newDist = ("\(locations[locations.count-1].distance(from: locations[locations.count-2]))")
            }
        }
        print("Locations: \(locations)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func checkLocationAuthorization() -> CLAuthorizationStatus {
        return manager.authorizationStatus
    }
    
    func createGridRegion(centerCoordinate: CLLocationCoordinate2D, spanDegrees: CLLocationDegrees) -> MKCoordinateRegion {
        let region = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: spanDegrees * 111000, longitudinalMeters: spanDegrees * 111000)
        return region
    }
}
