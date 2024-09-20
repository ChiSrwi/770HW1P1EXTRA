//
//  ViewController.swift
//  test
//
//  Created by Justin Kwok Lam CHAN on 4/4/21.
//

import DGCharts
import UIKit
import CoreMotion
import Foundation
import Accelerate

class ViewController: UIViewController, ChartViewDelegate {
    
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var label: UILabel!
    
    var ts: Double = 0
    
    var stepCount: Int = 0
    let b: [Double] = [0.0009, 0.0051, 0.0129, 0.0172, 0.0129, 0.0051, 0.0009]
    let a: [Double] = [1.0000, -3.0985, 4.4164, -3.5566, 1.6851, -0.4411, 0.0496]
    
    let windowSize = 8
    var magnitudeValues = [Double]()
    let minPeakHeight = 0.0
    let minPeakDistance = 10
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        self.lineChartView.delegate = self
        
        let set_a: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "x")
        set_a.drawCirclesEnabled = false
        set_a.setColor(UIColor.blue)
        
        let set_b: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "y")
        set_b.drawCirclesEnabled = false
        set_b.setColor(UIColor.red)
        
        let set_c: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "z")
        set_c.drawCirclesEnabled = false
        set_c.setColor(UIColor.green)
        self.lineChartView.data = LineChartData(dataSets: [set_a,set_b,set_c])
    }
    
    @IBAction func startSensors(_ sender: Any) {
        ts=NSDate().timeIntervalSince1970
        label.text=String(format: "%f", ts)
        startAccelerometers()
        startButton.isEnabled = false
        stopButton.isEnabled = true
    }
    
    @IBAction func stopSensors(_ sender: Any) {
        stopAccels()
        startButton.isEnabled = true
        stopButton.isEnabled = false
        
        
//        if magnitudeValues.count >= windowSize {
//            let magnitudeMean = magnitudeValues.reduce(0, +) / Double(magnitudeValues.count)
//            let centeredMagnitude = magnitudeValues.map { $0 - magnitudeMean }
//
//            let filteredMagnitude = filtfilt(data: centeredMagnitude, b: b, a: a)
//            let smoothedMagnitude = movMean(data: filteredMagnitude, windowSize: windowSize)
//
//            let (peaks, _) = findPeaks(data: smoothedMagnitude, minPeakHeight: minPeakHeight, minPeakDistance: minPeakDistance)
//            let steps = peaks.count
//            stepCount = steps
//
//            DispatchQueue.main.async {
//                self.label.text = "Steps: \(self.stepCount)"
//            }
//        }
        
        DispatchQueue.main.async {
            self.label.text = "Steps: \(self.stepCount)"
        }
    }
    
    let motion = CMMotionManager()
    var counter:Double = 0
    
    var timer_accel:Timer?
    var accel_file_url:URL?
    var accel_fileHandle:FileHandle?
    
    let xrange:Double = 500
    
    func startAccelerometers() {
       // Make sure the accelerometer hardware is available.
       if self.motion.isAccelerometerAvailable {
        // sampling rate can usually go up to at least 100 hz
        // if you set it beyond hardware capabilities, phone will use max rate
          self.motion.accelerometerUpdateInterval = 1.0 / 25.0  // 60 Hz
          self.motion.startAccelerometerUpdates()
        
        // create the data file we want to write to
        // initialize file with header line
        do {
            // get timestamp in epoch time
            let file = "accel_file_\(ts).txt"
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                accel_file_url = dir.appendingPathComponent(file)
            }
            
            // write first line of file
            try "ts,x,y,z\n".write(to: accel_file_url!, atomically: true, encoding: String.Encoding.utf8)

            accel_fileHandle = try FileHandle(forWritingTo: accel_file_url!)
            accel_fileHandle!.seekToEndOfFile()
        } catch {
            print("Error writing to file \(error)")
        }
        
          // Configure a timer to fetch the data.
          self.timer_accel = Timer(fire: Date(), interval: (1.0/25.0),
                                   repeats: true, block: { [self] (timer) in
             // Get the accelerometer data.
             if let data = self.motion.accelerometerData {
                let x = data.acceleration.x
                let y = data.acceleration.y
                let z = data.acceleration.z
                
                let timestamp = NSDate().timeIntervalSince1970
                let text = "\(timestamp), \(x), \(y), \(z)\n"
                print ("A: \(text)")
                 
                 
                let magnitude = sqrt(x * x + y * y + z * z)
                magnitudeValues.append(magnitude)
                
                self.accel_fileHandle!.write(text.data(using: .utf8)!)
                 
                  self.lineChartView.data?.appendEntry(ChartDataEntry(x: Double(counter), y: x), toDataSet: ChartData.Index(0))
                 self.lineChartView.data?.appendEntry(ChartDataEntry(x: Double(counter), y: y), toDataSet: ChartData.Index(1))
                 self.lineChartView.data?.appendEntry(ChartDataEntry(x: Double(counter), y: z), toDataSet: ChartData.Index(2))
                
                // refreshes the data in the graph
                self.lineChartView.notifyDataSetChanged()
                 
                 
                 
                 if magnitudeValues.count >= windowSize {
                     let magnitudeMean = magnitudeValues.reduce(0, +) / Double(magnitudeValues.count)
                     let centeredMagnitude = magnitudeValues.map { $0 - magnitudeMean }
                     
                     let filteredMagnitude = filtfilt(data: centeredMagnitude, b: b, a: a)
                     let smoothedMagnitude = movMean(data: filteredMagnitude, windowSize: windowSize)
                     
                     let (peaks, _) = findPeaks(data: smoothedMagnitude, minPeakHeight: minPeakHeight, minPeakDistance: minPeakDistance)
                     let steps = peaks.count
                     stepCount = steps
                     
                     DispatchQueue.main.async {
                         self.label.text = "Steps: \(self.stepCount)"
                     }
                 }
                  
                self.counter = self.counter+1
                
                // needs to come up after notifyDataSetChanged()
                if counter < xrange {
                    self.lineChartView.setVisibleXRange(minXRange: 0, maxXRange: xrange)
                }
                else {
                    self.lineChartView.setVisibleXRange(minXRange: counter, maxXRange: counter+xrange)
                }
             }
          })

          // Add the timer to the current run loop.
        RunLoop.current.add(self.timer_accel!, forMode: RunLoop.Mode.default)
       }
    }
    
    func stopAccels() {
       if self.timer_accel != nil {
          self.timer_accel?.invalidate()
          self.timer_accel = nil

          self.motion.stopAccelerometerUpdates()
        
           accel_fileHandle!.closeFile()
       }
    }
    
    func movMean(data: [Double], windowSize: Int) -> [Double] {
        var meanData: [Double] = []
//        let halfwindow = windowSize / 2
        for i in 0..<data.count {
                let start = max(0, i - windowSize + 1)
                let end = i + 1
//                let start = max(0, i - halfwindow)
//                let end = min(data.count - 1, i + halfwindow)
                
                let window = Array(data[start..<end])
                let mean = window.reduce(0, +) / Double(window.count)
                meanData.append(mean)
            }
            return meanData
        }
    
    func filter(data: [Double], b: [Double], a: [Double]) -> [Double] {
        let n = data.count
        var y = [Double](repeating: 0.0, count: n)
        for i in 0..<n {
            y[i] = b[0] * data[i]
            for j in 1..<b.count {
                if i >= j {
                    y[i] += b[j] * data[i - j]
                }
            }
            for j in 1..<a.count {
                if i >= j {
                    y[i] -= a[j] * y[i - j]
                }
            }
        }
        return y
    }

    func filtfilt(data: [Double], b: [Double], a: [Double]) -> [Double] {
        let forwardFiltered = filter(data: data, b: b, a: a)
        let reversedSignal = forwardFiltered.reversed()
        let reverseFiltered = filter(data: Array(reversedSignal), b: b, a: a)
        return reverseFiltered.reversed()
    }

    
    func findPeaks(data: [Double], minPeakHeight: Double, minPeakDistance: Int) -> (peaks: [Double], locs: [Int]) {
        var peaks: [Double] = []
        var locs: [Int] = []
        
        for i in 1..<data.count - 1 {
            if data[i] > data[i - 1] && data[i] > data[i + 1] {
                if data[i] > minPeakHeight {
                    if locs.isEmpty || i - locs.last! >= minPeakDistance {
                        peaks.append(data[i])
                        locs.append(i)
                    }
                }
            }
        }
        
        return (peaks, locs)
    }
    
//    func zeroCrossingIndices(data: [Double]) -> [Int] {
//        var indices = [Int]()
//        for i in 1..<data.count {
//            if data[i] * data[i - 1] <= 0 {
//                indices.append(i)
//            }
//        }
//        return indices
//    }
//
}

