//
//  MapView.swift
//  Project
//
//  Created by 高見聡 on 2025/06/21.
//
import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var heading: CLHeading?
    @Binding var mapRotation: Double
    @Binding var shouldUpdateRegion: Bool

    let mapView = MKMapView()

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.isRotateEnabled = true
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if shouldUpdateRegion {
            uiView.setCenter(region.center, animated: true)
            DispatchQueue.main.async {
                shouldUpdateRegion = false
            }
        }

        if let heading = heading {
            context.coordinator.updateUserIconRotation(with: heading, mapRotation: mapRotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var annotationView: MKAnnotationView?

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "UserLocation")
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: "UserLocation")

                let size: CGFloat = 40
                let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))

                let circleImageView = UIImageView(image: UIImage(systemName: "circle.fill"))
                circleImageView.frame = CGRect(x: 0, y: 0, width: size, height: size)
                circleImageView.tintColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
                backgroundView.addSubview(circleImageView)

                let arrowImageView = UIImageView(image: UIImage(systemName: "arrow.up"))
                arrowImageView.frame = CGRect(x: (size - 20) / 2, y: (size - 20) / 2, width: 20, height: 20)
                arrowImageView.tintColor = .white
                backgroundView.addSubview(arrowImageView)

                annotationView?.addSubview(backgroundView)
                annotationView?.bounds = backgroundView.bounds
                return annotationView
            }
            return nil
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let camera = mapView.camera
            parent.mapRotation = camera.heading
        }

        func updateUserIconRotation(with heading: CLHeading, mapRotation: Double) {
            let headingRotation = CGFloat(heading.trueHeading / 180.0 * .pi)
            let mapRotationRadians = CGFloat(mapRotation / 180.0 * .pi)
            let totalRotation = headingRotation - mapRotationRadians

            if let annotationView = self.annotationView {
                UIView.animate(withDuration: 0.1) {
                    annotationView.transform = CGAffineTransform(rotationAngle: totalRotation)
                }
            }
        }
    }
}
