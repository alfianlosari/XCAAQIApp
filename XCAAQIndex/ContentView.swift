//
//  ContentView.swift
//  XCAAQIndex
//
//  Created by Alfian Losari on 01/10/23.
//

import MapKit
import SwiftUI
import XCAAQI

struct ContentView: View {
    
    @State var vm = AppViewModel()
    
    var body: some View {
        Map(position: $vm.position, selection: $vm.selection) {
            ForEach(vm.annotations) { aqi in
                Annotation(aqi.aqiDisplay, coordinate: aqi.coordinate) {
                    CircleAQIView(aqi: aqi, isSelected: aqi == vm.selection)
                }
                .tag(aqi)
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.hybrid(elevation: .flat, pointsOfInterest: .all, showsTraffic: false))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onChange(of: vm.selection) { _, _ in
            if vm.selection != nil {
                vm.presentationDetent = .height(176)
            }
        }
        .sheet(isPresented: .constant(true)) {
            ScrollView {
                VStack {
                    if let selection = vm.selection {
                        selectedAQIView(aqi: selection)
                    } else {
                        if vm.locationStatus != .requestingLocation && vm.locationStatus != .requestingAQIConditions {
                            locationFormView
                        }
                        
                        if vm.locationStatus == .requestingAQIConditions {
                            ProgressView("Requesting AQI Conditions...")
                        }
                        
                        if vm.locationStatus == .requestingLocation {
                            ProgressView("Requesting Current Location...")
                        }
                        
                        if case let .locationNotAuthorized(text) = vm.locationStatus {
                            Text(text)
                        }
                        
                        if case let .error(text) = vm.locationStatus {
                            Text(text)
                        }
                        
                    }
                }
                
            }
            .padding()
            .safeAreaPadding(.top)
            .presentationDetents([.height(24), .height(176)], selection: $vm.presentationDetent)
            .presentationBackground(.ultraThinMaterial)
            .presentationBackgroundInteraction(.enabled(upThrough: .height(176)))
            .interactiveDismissDisabled()
        }
      
        .navigationTitle("XCA AirQuality IDX")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
    
    func selectedAQIView(aqi: AQIResponse) -> some View {
        HStack(spacing: 16) {
            CircleAQIView(aqi: aqi, size: CGSize(width: 80, height: 80))
            VStack(alignment: .leading) {
                Text("Coordinate: \(aqi.coordinate.latitude), \(aqi.coordinate.longitude)")
                Text(aqi.category)
                Text("Dominant Pollutant: \(aqi.dominantPollutant)")
                Text(aqi.displayName)
            }
        }
        .padding(.top)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    var locationFormView: some View {
        Text("Get Current AQI aroud a coordinate")
            .font(.headline)
            .padding(.bottom, 8)
        
        HStack {
            Text("Lat")
            TextField("Enter Latitude", value: $vm.lat, format: .number)
            Text("Lon")
            TextField("Enter Longitude", value: $vm.lon, format: .number)
        }
        .keyboardType(.decimalPad)
        .textFieldStyle(.roundedBorder)
        .padding(.bottom, 8)
        
        HStack {
            Button("Use current loc") {
                vm.lat = vm.currentLocation?.latitude ?? 0
                vm.lon = vm.currentLocation?.longitude ?? 0
                Task {
                    await vm.handleCoordinateChange(.init(latitude: vm.lat, longitude: vm.lon))
                }
            }.buttonStyle(.borderedProminent)
            
            Button("Refresh AQI") {
                Task {
                    await vm.handleCoordinateChange(.init(latitude: vm.lat, longitude: vm.lon))
                }
            }.buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    NavigationStack {
        ContentView(vm: .init(radiusNArray: [(4000, 0), (8000, 0)]))
    }
}
