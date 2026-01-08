//
//  SelectableObject.swift
//  Christmas Light Controller
//
//  Created by Terry Burdett on 12/13/25.
//


import UIKit



class LED_Parameters: UIViewController {

    // MARK: - UI

    @IBOutlet weak var previewView: UIView!
    @IBAction func redSlider(_ sender: Any) {
    }
    @IBAction func greenSlider(_ sender: Any) {
    }
    @IBAction func blueSlider(_ sender: Any) {
    }
    
    @IBOutlet weak var house_Outlet: UISegmentedControl!
    @IBAction func house_Action(_ sender: Any) {
       // house = house_Outlet.selectedSegmentIndex
        if ledsInfo_Array[led_Selected].house != house_Outlet.selectedSegmentIndex {
            update_Outlet.isEnabled = true
        }else {
            update_Outlet.isEnabled = false
        }

    }
   
    @IBOutlet weak var blueSlider_Outlet: UISlider!
    @IBOutlet weak var greenSlider_Outlet: UISlider!
    @IBOutlet weak var redSlider_Outlet: UISlider!
  
    @IBOutlet weak var update_Outlet: UIButton!
    @IBAction func upDate(_ sender: Any) {
        ledsInfo_Array[led_Selected].house = UInt8(house_Outlet.selectedSegmentIndex)
        /*ledsInfo_Array[led_Selected].baseBrightness = UInt8(100)
        ledsInfo_Array[led_Selected].interval = UInt32(100)
        ledsInfo_Array[led_Selected].candleRed = Int32(100)
        ledsInfo_Array[led_Selected].candleGreen = Int32(100)
        ledsInfo_Array[led_Selected].lastUpdate = UInt32(100)*/
        update_Outlet.isEnabled = false
        setupUI()
        updateArray()
        
    }
    
    // MARK: - Data
  
  //  var house = 0
  

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        if ledsInfo_Array[led_Selected].house == 0 {
            title = ("LED  \(led_Selected + 1) Background")// selectedDeviceID//"RGB Controller"
        } else {
            title = ("LED  \(led_Selected + 1) House")
        }
        view.backgroundColor = .systemBackground
        update_Outlet.isEnabled = false
        //setupUI()
        updatePreview()
    }
    
    override func viewWillAppear(_ animated: Bool) {

        setupUI()
    }
    
    func updateArray() {
        
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "upDateESPArray"), object: nil)
    }
    
    @objc private func sliderChanged() {
        updatePreview()
    
    }

    private func updatePreview() {
        previewView.backgroundColor = currentColor
    }

    private var currentColor: UIColor {
        UIColor(
            red: CGFloat(redSlider_Outlet.value),// / 255),
            green: CGFloat(greenSlider_Outlet.value),// / 255),
            blue: CGFloat(blueSlider_Outlet.value),// / 255),
            alpha: 1
        )
    }

    private func sendColorIfReady() {
   

            let r = Int(redSlider_Outlet.value)
            let g = Int(greenSlider_Outlet.value)
            let b = Int(blueSlider_Outlet.value)
            
            var command = ""
          /*  if selectedRow == 0 {
                command = "\(channelSelected) RGB \(r) \(g) \(b)\n"
            }else {
              //  if selectedRow == 0 {
               //     command = "\(channelSelected) STEADY \(r) \(g) \(b)\n"
               // }else {
                command = String(channelSelected) + " " + objects[selectedRow]
               // }
            }*/
            bleSendText = command
       //     NotificationCenter.default.post(name: Notification.Name(rawValue: "setColor"), object: nil)
  
    }



    
}

private extension LED_Parameters {

    func setupUI() {

        previewView.layer.cornerRadius = 12
        previewView.layer.borderWidth = 1
        previewView.layer.borderColor = UIColor.secondaryLabel.cgColor

        [redSlider_Outlet, greenSlider_Outlet, blueSlider_Outlet].forEach {
            $0.minimumValue = 0
            $0.maximumValue = 255
            $0.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        }
        
        redSlider_Outlet.value = Float(ledsInfo_Array[led_Selected].candleRed)
        greenSlider_Outlet.value = Float(ledsInfo_Array[led_Selected].candleGreen)
        blueSlider_Outlet.value = Float(ledsInfo_Array[led_Selected].candleBlue)
       // if ledsInfo_Array[led_Selected].house == 1 {
           // redSlider_Outlet.value = Float(ledsInfo_Array[led_Selected].candleRed)
           // greenSlider_Outlet.value = Float(ledsInfo_Array[led_Selected].candleGreen)
         //   blueSlider_Outlet.value = 0//Float(ledsInfo_Array[led_Selected].candleBlue)
      //  }else {
           // redSlider_Outlet.value = 211
          //  greenSlider_Outlet.value = 211
        //    blueSlider_Outlet.value = 211
       // }
        
       // blueSlider_Outlet.value = 255

        redSlider_Outlet.tintColor = .systemRed
        greenSlider_Outlet.tintColor = .systemGreen
        blueSlider_Outlet.tintColor = .systemBlue
        
        house_Outlet.selectedSegmentIndex = Int(ledsInfo_Array[led_Selected].house)
        
    }

}

/*extension LED_Parameters: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {

        ledsInfo_Array.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var str = ""
        if ledsInfo_Array[row].house == 1 {
            str = "\(row) House"
        }else {
            str = "\(row) Background"
        }
        
        cell.textLabel?.text = str

        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        
        selectedRow = indexPath.row
        selectedIndexPath = indexPath
        
        tableView.reloadData()
        
       // sendColorIfReady()
    }
}*/
