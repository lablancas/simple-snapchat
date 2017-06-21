import Foundation
import MapKit
import Firebase

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var fromID : String?
    var toID : String?
    var partnerLocation = kCLLocationCoordinate2DInvalid

    //  3.Create CLLocationManager in order to reach a Location service.
    let locationManager = CLLocationManager()
    
    var mapHasCenteredOnce = false
    var geoFire: GeoFire!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        //  4.Set user tracking mode 
        mapView.userTrackingMode = MKUserTrackingMode.follow
      
        let geofireRef = FIRDatabase.database().reference().child("locations")
        geoFire = GeoFire(firebaseRef: geofireRef)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Camera", style: .plain, target: self, action: #selector(cameraView))
    }
    
    override func viewDidAppear(_ animated: Bool){
        locationAuthStatus()
    }
    
    //  5.Create function Checking authorization status of using a location.
    func locationAuthStatus(){
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            
            /*  6.Allow map view to use Core Location to find the user's location 
                and add an annotation of type MKUserLocation to the map. */
            mapView.showsUserLocation = true
        } else {
            //  6.1.If status isn't authorizedWhenInUse, then ask manager for the author
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    /*  6.2 if authorized status has changed, CLLocation call its 
        delegate after that we will have to set "true" to showsUserLocation */
    func locationManager(_ manager:CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            mapView.showsUserLocation = true 
        }
    }
    
    //  Our function used to set the screen into center of present location
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,2000,2000)
       
        // Use setRegion Method so as to set position and zoom level of our screen.
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if let loc = userLocation.location {
            
            // 7.Check if this is the first opening map, set screen into the present location.
            if !mapHasCenteredOnce {
                centerMapOnLocation(location: loc)
                mapHasCenteredOnce = true
            }
        }
    }
    
    /*  Everytime, when user pan their map, This Function will be called. 
        Then we're going to update observer for around existing annotation based on present location. */
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {     
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        showPostsOnMap(location: loc)
    }
    
    //Create or Update Annotation observer and then Add the Annotation into our mapView if it exist.
    func showPostsOnMap(location: CLLocation) {    
        //  Create observer in order to find annotation around a location (2.5 km)
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        
        /*  observer will be called when it be initialized by (.observe method)
            or location data is added into firebase hosting */
        _ = circleQuery?.observe(GFEventType.keyEntered, with: { (key, location) in
            if let key = key, let location = location {
                let anno = MKPointAnnotation()
                anno.title = key
                anno.coordinate = location.coordinate
                
                //Add annotation to our mapView.
                self.mapView.addAnnotation(anno)
            }
        })
        
        _ = circleQuery?.observe(GFEventType.keyExited, with: { (key, location) in
            print("key exited \(key)")
            if let key = key {
                for anno in self.mapView.annotations
                {
                    if let title = anno.title, key == title {
                        self.mapView.removeAnnotation(anno)
                    }
                }
            }
        })
    }
    
    //  This function will be called when mapView is added a annotation.
    //  used to set custom view for annotation icon.
    func mapView(_ mapView:MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reusableAnnotation = mapView.dequeueReusableAnnotationView(withIdentifier: "post-annotation")
        if reusableAnnotation != nil {
            return reusableAnnotation!
        }
        return MKPinAnnotationView(annotation: annotation, reuseIdentifier: "post-annotation")
    }
    
    // Callout accessory control is tapped !!!!!
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("calloutAccessoryControlTapped \(control)")
        
    }
    
    func cameraView(){
        let scrollView = self.navigationController?.view?.superview as? UIScrollView
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            scrollView!.contentOffset.x = self.view.frame.width
        }, completion: nil)
        
    }
    
}
