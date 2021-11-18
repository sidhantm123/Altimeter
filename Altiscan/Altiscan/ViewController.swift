//
//  ViewController.swift
//  Altiscan
//
//  Created by Sidhant Moola on 20/10/21.
//

import UIKit
import CoreBluetooth
import Charts

import Foundation
import CoreBluetooth

struct CBUUIDs{

    static let kBLEService_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
    static let kBLE_Characteristic_uuid_Tx = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
    static let kBLE_Characteristic_uuid_Rx = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"

    static let BLEService_UUID = CBUUID(string: kBLEService_UUID)
    static let BLE_Characteristic_uuid_Tx = CBUUID(string: kBLE_Characteristic_uuid_Tx)//(Property = Write without response)
    static let BLE_Characteristic_uuid_Rx = CBUUID(string: kBLE_Characteristic_uuid_Rx)// (Property = Read/Notify)

}

class ViewController: UIViewController {
    
    var centralManager: CBCentralManager!
    private var bluefruitPeripheral: CBPeripheral!
    private var txCharacteristic: CBCharacteristic!
    private var rxCharacteristic: CBCharacteristic!
    
    var chartArray: [Int] = []
    
    @IBOutlet weak var LineChartBox: LineChartView!
    @IBOutlet weak var AltitudeLabel: UILabel!
    @IBOutlet weak var Altitude: UILabel!
    
    
    
    override func viewDidLoad() {
       super.viewDidLoad()
       centralManager = CBCentralManager(delegate: self, queue: nil)
     }
    
    
    
    //THIS IS THE FUNCTION THAT READS DATA OVER BLUETOOTH
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

          var characteristicASCIIValue = NSString()

          guard characteristic == rxCharacteristic,

          let characteristicValue = characteristic.value,
                
          //READING THE DATA OVER BLUETOOTH AND SAVING IT AS A STRING
          let ASCIIstring = NSString(data: characteristicValue, encoding: String.Encoding.utf8.rawValue) else { return }

          characteristicASCIIValue = ASCIIstring
        
        let myInt = (characteristicASCIIValue as NSString).integerValue
        
        chartArray.append(myInt)
        
        graphLineChart(dataArray: chartArray)
        
        let xNSNumber = myInt as NSNumber
        let alt : String = xNSNumber.stringValue
        
        Altitude.text = alt

          print("Value Recieved: \((characteristicASCIIValue as String))")
    }
    
    
    
    //THIS IS THE FUNCTION THAT ALLOWS YOU TO WRITE DATA OVER BLUETOOTH
    func writeOutgoingValue(data: String){
          
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        
        if let bluefruitPeripheral = bluefruitPeripheral {
              
          if let txCharacteristic = txCharacteristic {
                  
            bluefruitPeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
              }
          }
      }
    
    func graphLineChart(dataArray: [Int]){
        //Make LineChartBox have width same as screen and height = half of width of screen
        LineChartBox.frame = CGRect(x: 0, y:0,
                                    width: self.view.frame.size.width,
                                    height: self.view.frame.size.width / 2)
        
        //Make LineChartBox centered horizontally
        //Make LineChartBox to be near the top of the screen
        LineChartBox.center.x = self.view.center.x
        LineChartBox.center.y = self.view.center.y
        
        //Settings when LineChart has no data
        LineChartBox.noDataText = "No Data Available"
        LineChartBox.noDataTextColor = UIColor.black
        
        //Initialize Array that will eventually be displayed no graph
        var entries = [ChartDataEntry]()
        
        //For every element in the dataset
        //set the X and Y coordinates in a data chart entry
        //and add it to the enrty list
        for i in 0..<dataArray.count {
            let value = ChartDataEntry(x: Double(i), y: Double(dataArray[i]))
            entries.append(value)
        }
        
        //Use the entries object and a label string to make a LineChartData object
        let dataSet = LineChartDataSet(entries: entries, label: "Line Chart")
        
        //Customise the chart colors
        dataSet.colors = ChartColorTemplates.joyful()
        
        //Make object that will be added to the chart
        //and set it to the variable in the storyboard
        let data = LineChartData(dataSet: dataSet)
        LineChartBox.data = data
        
        //Add settings for the Chart box
        LineChartBox.chartDescription?.text = "Pi values"
        
        //Add animations
        LineChartBox.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: .linear)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //BLUETOOTH FUNCTIONS THAT WON'T BE USED
    func startScanning() -> Void {
      // Start Scanning
      centralManager?.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {

        bluefruitPeripheral = peripheral
        bluefruitPeripheral.delegate = self

        print("Peripheral Discovered: \(peripheral)")
          print("Peripheral name: \(peripheral.name)")
        print ("Advertisement Data : \(advertisementData)")
        
        centralManager?.connect(bluefruitPeripheral!, options: nil)

       }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
       bluefruitPeripheral.discoverServices([CBUUIDs.BLEService_UUID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            print("*******************************************************")

            if ((error) != nil) {
                print("Error discovering services: \(error!.localizedDescription)")
                return
            }
            guard let services = peripheral.services else {
                return
            }
            //We need to discover the all characteristic
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
            print("Discovered Services: \(services)")
        }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
           
               guard let characteristics = service.characteristics else {
              return
          }

          print("Found \(characteristics.count) characteristics.")

          for characteristic in characteristics {

            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Rx)  {

              rxCharacteristic = characteristic

              peripheral.setNotifyValue(true, for: rxCharacteristic!)
              peripheral.readValue(for: characteristic)

              print("RX Characteristic: \(rxCharacteristic.uuid)")
            }

            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Tx){
              
              txCharacteristic = characteristic
              
              print("TX Characteristic: \(txCharacteristic.uuid)")
            }
          }
    }
    
    func disconnectFromDevice () {
        if bluefruitPeripheral != nil {
        centralManager?.cancelPeripheralConnection(bluefruitPeripheral!)
        }
     }
    
    
}

extension ViewController: CBCentralManagerDelegate {

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    
     switch central.state {
          case .poweredOff:
              print("Is Powered Off.")
          case .poweredOn:
              print("Is Powered On.")
              startScanning()
          case .unsupported:
              print("Is Unsupported.")
          case .unauthorized:
          print("Is Unauthorized.")
          case .unknown:
              print("Unknown")
          case .resetting:
              print("Resetting")
          @unknown default:
            print("Error")
          }
  }

}

extension ViewController: CBPeripheralDelegate {
}


extension ViewController: CBPeripheralManagerDelegate {

  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    switch peripheral.state {
    case .poweredOn:
        print("Peripheral Is Powered On.")
    case .unsupported:
        print("Peripheral Is Unsupported.")
    case .unauthorized:
    print("Peripheral Is Unauthorized.")
    case .unknown:
        print("Peripheral Unknown")
    case .resetting:
        print("Peripheral Resetting")
    case .poweredOff:
      print("Peripheral Is Powered Off.")
    @unknown default:
      print("Error")
    }
  }
}
