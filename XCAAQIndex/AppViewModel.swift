//
//  AppViewModel.swift
//  XCAAQIndex
//
//  Created by Alfian Losari on 01/10/23.
//

import Foundation
import MapKit
import Observation
import SwiftUI
import XCAAQI

enum LocationStatus: Equatable {
    case requestingLocation
    case locationNotAuthorized(String)
    case error(String)
    case requestingAQIConditions
    case standby
}

@Observable
class AppViewModel: NSObject {
    
    let locationManager = CLLocationManager()
    let aqiClient = AirQualityClient(apiKey: "YOUR_GOOGLE_API_KEY")
    let coordinatesFinder = CoordinatesFinder()
    
    var currentLocation: CLLocationCoordinate2D?
    var locationStatus = LocationStatus.requestingLocation
    var position: MapCameraPosition = .automatic
    var annotations: [AQIResponse] = []
    var selection: AQIResponse?
    var presentationDetent = PresentationDetent.height(176)
    var lat: Double = 0
    var lon: Double = 0
    
    var radiusNArray: [(Double, Int)]
    
    // radiusNArray will provide coordinates around the location. each coordinate will be counted to 1 API Call in Google AQI API Billing. Use accordingly
    init(radiusNArray: [(Double, Int)] = [(4000, 0), (8000, 0)]) {
        self.radiusNArray = radiusNArray
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    @MainActor
    func handleCoordinateChange(_ coordinate: CLLocationCoordinate2D) async {
        do {
            self.locationStatus = .requestingAQIConditions
            self.position = .region(.init(center: coordinate, latitudinalMeters: 0, longitudinalMeters: 16000))
            let coordinates = getCoordinatesAround(coordinate)
            self.annotations = try await aqiClient.getCurrentConditions(coordinates: coordinates.map { ($0.latitude, $0.longitude )})
            self.locationStatus = .standby
        } catch {
            self.locationStatus = .error(error.localizedDescription)
        }
    }
    
    func getCoordinatesAround(_ coordinate: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        var results: [CLLocationCoordinate2D] = [coordinate]
        radiusNArray.forEach {
            results += coordinatesFinder.findCoordinates(coordinate, r: $0.0, n: $0.1)
        }
        return results
    }
}

extension AppViewModel: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            manager.requestLocation()
        default:
            self.locationStatus = .locationNotAuthorized("Unauthorized location access")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.locationStatus = .error(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.first?.coordinate else { return }
        if currentLocation == nil {
            lat = coordinate.latitude
            lon = coordinate.longitude
            Task { await self.handleCoordinateChange(coordinate)}
        }
        currentLocation = coordinate
    }
    
}
