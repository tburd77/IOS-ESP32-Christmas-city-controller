//
//  LEDS_TableViewController.swift
//  Christmas City Controller
//
//  Created by Terry Burdett on 1/1/26.
//

import UIKit
import CoreBluetooth

class LEDS_TableViewController: UITableViewController {
   
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
       //  self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        ledsInfo_Array.count
    }

    override func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        var str = ""
        if ledsInfo_Array[row].house == 1 {
            str = "LED \(row + 1): House"
        }else {
            str = "LED\(row + 1): Background"
        }
        
        cell.textLabel?.text = str

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        led_Selected = indexPath.row
        let vc = storyboard?.instantiateViewController(
            withIdentifier: "LED_Parameters"
        )
        navigationController?.pushViewController(vc!, animated: true)
    }
    
    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {

    //    let device = BLEDeviceStore.shared.devices[indexPath.row]

        // TEST action
        let testAction = UIContextualAction(
            style: .normal,
            title: "Test"
        ) { [weak self] _, _, completion in

            // Example: test LED by row index
            let message = "test \(indexPath.row)"
            self?.sendText(message)
           // NotificationCenter.default.post(name: Notification.Name(rawValue: "testLED"), object: nil)
            completion(true)
        }

        testAction.backgroundColor = .systemBlue

        // STOP action
        let stopAction = UIContextualAction(
            style: .destructive,
            title: "Stop"
        ) { [weak self] _, _, completion in

          //  self?.sendText("stop")
          //  NotificationCenter.default.post(name: Notification.Name(rawValue: "testLED"), object: nil)
            completion(true)
        }

        stopAction.backgroundColor = .systemRed

        let config = UISwipeActionsConfiguration(actions: [stopAction, testAction])
        config.performsFirstActionWithFullSwipe = false

        return config
    }

   // extension AvailableDevices_ViewController {
        func sendText(_ message: String) {
            guard let textRxChar = textRxChar,
                  let peripheral = connectedPeripheral else { return }

            print("➡️ TEXT:", message)
            let data = message.data(using: .utf8)!
            peripheral.writeValue(data, for: textRxChar, type: .withResponse)
        }

   // }
    
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
