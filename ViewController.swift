//
//  ViewController.swift
//  AR
//
//  Created by M-33 on 01/08/2019.
//  Copyright © 2019 M-33. All rights reserved.
//
import UIKit
import SceneKit
import ARKit
import CoreLocation
import Accelerate

var check = false

public struct Matrix: Equatable {

    // MARK: - Properties

    public let rows: Int, columns: Int

    public var grid: [Double]

    

    var isSquare: Bool {

        return rows == columns

    }

   

    // MARK: - Initialization

    

    /**

   

     */

    public init(rows: Int, columns: Int) {

        let grid = Array(repeating: 0.0, count: rows * columns)

        self.init(grid: grid, rows: rows, columns: columns)

    }

    

    /**

     

     */

    public init(grid: [Double], rows: Int, columns: Int) {

        assert(rows * columns == grid.count, "grid size should be rows * column. size")

        self.rows = rows

        self.columns = columns

        self.grid = grid

    }

    

    /**

     

     - parameter vector: array with elements of vector

     */

    public init(vector: [Double]) {

        self.init(grid: vector, rows: vector.count, columns: 1)

    }

    

    /**

     

     */

    public init(vectorOf size: Int) {

        self.init(rows: size, columns: 1)

    }

    

    /**

    

     

     - parameter size: number of rows and columns in matrix

     */

    public init(squareOfSize size: Int) {

        self.init(rows: size, columns: size)

    }

    

    /**

     I

     - parameter size: number of rows and columns in identity matrix

     */

    public init(identityOfSize size: Int) {

        self.init(squareOfSize: size)

        for i in 0..<size {

            self[i, i] = 1

        }

    }

    

    /**

     Convenience initialization from 2D array

     

     - parameter array2d: 2D array representation of matrix

     */

    public init(_ array2d: [[Double]]) {

        self.init(grid: array2d.flatMap({$0}), rows: array2d.count, columns: array2d.first?.count ?? 0)

    }

    

    // MARK: - Public Methods

    /**

     Determines whether element exists at specified row and

     column

     

     - parameter row: row index of element

     - parameter column: column index of element

     - returns: bool indicating whether spicified indeces are valid

     */

    public func indexIsValid(forRow row: Int, column: Int) -> Bool {

        return row >= 0 && row < rows && column >= 0 && column < columns

    }

    

    public subscript(row: Int, column: Int) -> Double {

        get {

            assert(indexIsValid(forRow: row, column: column), "Index out of range")

            return grid[(row * columns) + column]

        }

        set {

            assert(indexIsValid(forRow: row, column: column), "Index out of range")

            grid[(row * columns) + column] = newValue

        }

    }

}



// MARK: - Equatable

public func == (lhs: Matrix, rhs: Matrix) -> Bool {

    return lhs.rows == rhs.rows && lhs.columns == rhs.columns && lhs.grid == rhs.grid

}



// MARK: -  Matrix as KalmanInput

extension Matrix: KalmanInput {


    public var transposed: Matrix {

        var resultMatrix = Matrix(rows: columns, columns: rows)

        let columnLength = resultMatrix.columns

        let rowLength = resultMatrix.rows

        grid.withUnsafeBufferPointer { xp in

            resultMatrix.grid.withUnsafeMutableBufferPointer { rp in

                vDSP_mtransD(xp.baseAddress!, 1, rp.baseAddress!, 1, vDSP_Length(rowLength), vDSP_Length(columnLength))

            }

        }

        return resultMatrix

    }

 
    public var additionToUnit: Matrix {

        assert(isSquare, "Matrix should be square")

        return Matrix(identityOfSize: rows) - self

    }


    public var inversed: Matrix {

        assert(isSquare, "Matrix should be square")

        

        if rows == 1 {

            return Matrix(grid: [1/self[0, 0]], rows: 1, columns: 1)

        }

        

        var inMatrix:[Double] = grid

        // Get the dimensions of the matrix. An NxN matrix has N^2

        // elements, so sqrt( N^2 ) will return N, the dimension

        var N:__CLPK_integer = __CLPK_integer(sqrt(Double(grid.count)))

        var N2:__CLPK_integer = N

        var N3:__CLPK_integer = N

        var lwork = __CLPK_integer(grid.count)

        // Initialize some arrays for the dgetrf_(), and dgetri_() functions

        var pivots:[__CLPK_integer] = [__CLPK_integer](repeating: 0, count: grid.count)

        var workspace:[Double] = [Double](repeating: 0.0, count: grid.count)

        var error: __CLPK_integer = 0

        

        // Perform LU factorization

        dgetrf_(&N, &N2, &inMatrix, &N3, &pivots, &error)

        // Calculate inverse from LU factorization

        dgetri_(&N, &inMatrix, &N2, &pivots, &workspace, &lwork, &error)

        

        if error != 0 {

            assertionFailure("Matrix Inversion Failure")

        }

        return Matrix.init(grid: inMatrix, rows: rows, columns: rows)

    }


    public var determinant: Double {

        assert(isSquare, "Matrix should be square")

        var result = 0.0

        if rows == 1 {

            result = self[0, 0]

        } else {

            for i in 0..<rows {

                let sign = i % 2 == 0 ? 1.0 : -1.0

                result += sign * self[i, 0] * additionalMatrix(row: i, column: 0).determinant

            }

        }

        return result

    }

    

    public func additionalMatrix(row: Int, column: Int) -> Matrix {

        assert(indexIsValid(forRow: row, column: column), "Invalid arguments")

        var resultMatrix = Matrix(rows: rows - 1, columns: columns - 1)

        for i in 0..<rows {

            if i == row {

                continue

            }

            for j in 0..<columns {

                if j == column {

                    continue

                }

                let resI = i < row ? i : i - 1

                let resJ = j < column ? j : j - 1

                resultMatrix[resI, resJ] = self[i, j]

            }

        }

        return resultMatrix

    }

    

    fileprivate func operate(with otherMatrix: Matrix, closure: (Double, Double) -> Double) -> Matrix {

        assert(rows == otherMatrix.rows && columns == otherMatrix.columns, "Matrices should be of equal size")

        var resultMatrix = Matrix(rows: rows, columns: columns)

        

        for i in 0..<rows {

            for j in 0..<columns {

                resultMatrix[i, j] = closure(self[i, j], otherMatrix[i, j])

            }

        }

        

        return resultMatrix

    }

}



public func + (lhs: Matrix, rhs: Matrix) -> Matrix {

    assert(lhs.rows == rhs.rows && lhs.columns == rhs.columns, "Matrices should be of equal size")

    var resultMatrix = Matrix(rows: lhs.rows, columns: lhs.columns)

    vDSP_vaddD(lhs.grid, vDSP_Stride(1), rhs.grid, vDSP_Stride(1), &resultMatrix.grid, vDSP_Stride(1), vDSP_Length(lhs.rows * lhs.columns))

    return resultMatrix

}



public func - (lhs: Matrix, rhs: Matrix) -> Matrix {

    assert(lhs.rows == rhs.rows && lhs.columns == rhs.columns, "Matrices should be of equal size")

    var resultMatrix = Matrix(rows: lhs.rows, columns: lhs.columns)

    vDSP_vsubD(rhs.grid, vDSP_Stride(1), lhs.grid, vDSP_Stride(1), &resultMatrix.grid, vDSP_Stride(1), vDSP_Length(lhs.rows * lhs.columns))

    return resultMatrix

}



public func * (lhs: Matrix, rhs: Matrix) -> Matrix {

    assert(lhs.columns == rhs.rows, "Left matrix columns should be the size of right matrix's rows")

    var resultMatrix = Matrix(rows: lhs.rows, columns: rhs.columns)

    let order = CblasRowMajor

    let atrans = CblasNoTrans

    let btrans = CblasNoTrans

    let α = 1.0

    let β = 1.0

    let resultColumns = resultMatrix.columns

    lhs.grid.withUnsafeBufferPointer { pa in

        rhs.grid.withUnsafeBufferPointer { pb in

            resultMatrix.grid.withUnsafeMutableBufferPointer { pc in

                cblas_dgemm(order, atrans, btrans, Int32(lhs.rows), Int32(rhs.columns), Int32(lhs.columns), α, pa.baseAddress!, Int32(lhs.columns), pb.baseAddress!, Int32(rhs.columns), β, pc.baseAddress!, Int32(resultColumns))

            }

        }

    }

    

    return resultMatrix

}



public func * (lhs: Matrix, rhs: Double) -> Matrix {

    return Matrix(grid: lhs.grid.map({ $0*rhs }), rows: lhs.rows, columns: lhs.columns)

}



public func * (lhs: Double, rhs: Matrix) -> Matrix {

    return rhs * lhs

}




extension Matrix: CustomStringConvertible {

    public var description: String {

        var description = ""

        

        for i in 0..<rows {

            let contents = (0..<columns).map{"\(self[i, $0])"}.joined(separator: "\t")

            

            switch (i, rows) {

            case (0, 1):

                description += "(\t\(contents)\t)"

            case (0, _):

                description += "⎛\t\(contents)\t⎞"

            case (rows - 1, _):

                description += "⎝\t\(contents)\t⎠"

            default:

                description += "⎜\t\(contents)\t⎥"

            }

            description += "\n"

        }

        

        return description

    }

}







// MARK: Double as Kalman input

extension Double: KalmanInput {

    public var transposed: Double {

        return self

    }

    

    public var inversed: Double {

        return 1 / self

    }

    

    public var additionToUnit: Double {

        return 1 - self

    }

}



public protocol KalmanInput {

    var transposed: Self { get }

    var inversed: Self { get }

    var additionToUnit: Self { get }

    

    static func + (lhs: Self, rhs: Self) -> Self

    static func - (lhs: Self, rhs: Self) -> Self

    static func * (lhs: Self, rhs: Self) -> Self

}



public protocol KalmanFilterType {

    associatedtype Input: KalmanInput

    

    var stateEstimatePrior: Input { get }

    var errorCovariancePrior: Input { get }

    

    func predict(stateTransitionModel: Input, controlInputModel: Input, controlVector: Input, covarianceOfProcessNoise: Input) -> Self

    func update(measurement: Input, observationModel: Input, covarienceOfObservationNoise: Input) -> Self

}

public struct KalmanFilter<Type: KalmanInput>: KalmanFilterType {

    /// x̂_k|k-1

    public let stateEstimatePrior: Type

    /// P_k|k-1

    public let errorCovariancePrior: Type

    

    public init(stateEstimatePrior: Type, errorCovariancePrior: Type) {

        self.stateEstimatePrior = stateEstimatePrior

        self.errorCovariancePrior = errorCovariancePrior

    }

    


    public func predict(stateTransitionModel: Type, controlInputModel: Type, controlVector: Type, covarianceOfProcessNoise: Type) -> KalmanFilter {


        let predictedStateEstimate = stateTransitionModel * stateEstimatePrior + controlInputModel * controlVector

        let predictedEstimateCovariance = stateTransitionModel * errorCovariancePrior * stateTransitionModel.transposed + covarianceOfProcessNoise

        

        return KalmanFilter(stateEstimatePrior: predictedStateEstimate, errorCovariancePrior: predictedEstimateCovariance)

    }


    public func update(measurement: Type, observationModel: Type, covarienceOfObservationNoise: Type) -> KalmanFilter {

        let observationModelTransposed = observationModel.transposed


        let measurementResidual = measurement - observationModel * stateEstimatePrior


        let residualCovariance = observationModel * errorCovariancePrior * observationModelTransposed + covarienceOfObservationNoise

        let kalmanGain = errorCovariancePrior * observationModelTransposed * residualCovariance.inversed


        let posterioriStateEstimate = stateEstimatePrior + kalmanGain * measurementResidual


        let posterioriEstimateCovariance = (kalmanGain * observationModel).additionToUnit * errorCovariancePrior

        

        return KalmanFilter(stateEstimatePrior: posterioriStateEstimate, errorCovariancePrior: posterioriEstimateCovariance)

    }

}





var measurements: Array<Double> = Array()

var measurements1: Array<Double> = Array()

var measurements2: Array<Double> = Array()



// 사용자 위치
var X = Double()
var Y = Double()






class ViewController: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate, HomeModelProtocol {
    var feedItems: NSArray = NSArray()
    
    func itemsDownloaded(items: NSArray) {
        feedItems = items
        
    }

    @IBOutlet weak var distance1: UILabel!
    @IBOutlet weak var distance2: UILabel!
    @IBOutlet weak var distance3: UILabel!
    
    @IBOutlet weak var myXX: UILabel!
    @IBOutlet weak var myYY: UILabel!
    
    
    @IBOutlet weak var lable: UILabel!
    
    @IBOutlet weak var nearest_beacon1: UILabel!
    
    @IBOutlet weak var image: UIImageView!
    
    @IBOutlet weak var floor: UITextField!
    
    @IBOutlet weak var textview: UITextView!
    
    @IBOutlet weak var ask: UILabel!
    @IBOutlet weak var showfloor: UILabel!
    
    @IBOutlet weak var detailbutton: UIButton!
    
    var txt = String()
    var textview_txt = String()
    var txt2 = String() // developer
    var txt3 = String() // advisor
    var txt4 = String() // tool
    
    @IBOutlet weak var floorinput: UIButton!
    
    @IBOutlet weak var enter: UIButton!
    
    @IBAction func enter(_ sender: Any) {
        
        txt=floor.text!
        let txt1="This floor is " + txt
        
        
        
        showfloor.text=txt1
       
        showfloor.isHidden=false
        ask.isHidden=true
        floor.isHidden=true
        enter.isHidden=true
        //floorinput.isHidden=true
        floor.text=""
        self.view.endEditing(true) //키보드 내리기
        
        
        
        
        if txt=="5"{
            lable.isHidden=false
            lable.text="Loading..."
            locationManager = CLLocationManager.init()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            startScanningForBeaconRegion(beaconRegion: getBeaconRegion())
        }
        
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
        
    {
        
        let allowedCharacters = CharacterSet.decimalDigits
        
        let characterSet = CharacterSet(charactersIn: string)
        
        return allowedCharacters.isSuperset(of: characterSet)
        
    }
    
    @IBAction func floor_button(_ sender: UIButton) {
        
        ask.isHidden=false
        floor.isHidden=false
        enter.isHidden=false
        showfloor.isHidden=true
        lable.isHidden=true
        
    }
    
    
    //글자 터치 했을 경우
    @objc func didTap(withGestureRecognizer recognizer: UIGestureRecognizer) {
        
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation)
        guard let node = hitTestResults.first?.node else { return }
  
        //노드 위치 저장
        let Nodename = node.name.self
        let xx = node.position.x
        let yy = node.position.y
        let zz = node.position.z
    

        node.removeFromParentNode()//노드 없애기
 
        //글자 누르면 길찾기 OR 관련 정보
        //지정된 노드 이름 -> 데이터베이스 name 부분
        if(Nodename == "취업 가즈아"){
            let text = SCNText(string : "취업 가즈아", extrusionDepth: 1)
            node.name.self="취업 가즈아1"
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.red
            text.materials = [material]
            // node.position = SCNVector3(x: Float(tapLocation.x), y: Float(tapLocation.y), z:-1.5)
            node.position = SCNVector3(x: Float(xx), y: Float(yy), z: Float(zz))
            node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
            node.geometry = text
            

            for i in 0..<major_x_zs.count{
                    let mm: LocationModel = major_x_zs[i] as! LocationModel
                    if (String(mm.name ?? "") == Nodename){
                        print(mm.name)
                
                        txt2=String(mm.developer ?? "AAA") //상세정보
                        txt3 = String(mm.advisor ?? "AAA")
                        txt4 = String(mm.tool ?? "AAA")
                        print(txt3)
                        
                        textview_txt = txt2 + "\n" + txt3 + "\n" + txt4
                        
                        
                        textview.text=textview_txt
                        textview.isHidden=false
                        detailbutton.isHidden=false
                        
                        myname = String(mm.name ?? "")
                        mydeveloper = String(mm.developer ?? "")
                        myadvisor = String(mm.advisor ?? "")
                        mytool = String(mm.tool ?? "")
                        mymotivation = String(mm.motivation ?? "")
                        mysummary = String(mm.summary ?? "")
                        
                        //print("에러안남")
                        
                }
            }
            
        }
        else if(Nodename == "Plainbot"){
                let text = SCNText(string : "Plainbot", extrusionDepth: 1)
                node.name.self="Plainbot1"
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.red
                text.materials = [material]
                // node.position = SCNVector3(x: Float(tapLocation.x), y: Float(tapLocation.y), z:-1.5)
                node.position = SCNVector3(x: Float(xx), y: Float(yy), z: Float(zz))
                node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
                node.geometry = text
            

            for i in 0..<major_x_zs.count{
                    let mm: LocationModel = major_x_zs[i] as! LocationModel
                    if (String(mm.name ?? "") == Nodename){
                        print(mm.name)
                
                        txt2=String(mm.developer ?? "AAA") //상세정보
                        txt3 = String(mm.advisor ?? "AAA")
                        txt4 = String(mm.tool ?? "AAA")
                        print(txt3)
                        
                        textview_txt = txt2 + "\n" + txt3 + "\n" + txt4
                        
                        
                        textview.text=textview_txt
                        textview.isHidden=false
                        detailbutton.isHidden=false
                        
                        myname = String(mm.name ?? "")
                        mydeveloper = String(mm.developer ?? "")
                        myadvisor = String(mm.advisor ?? "")
                        mytool = String(mm.tool ?? "")
                        mymotivation = String(mm.motivation ?? "")
                        mysummary = String(mm.summary ?? "")
                        
                        //print("에러안남")
                        
                }
            }
                
            }
        else if(Nodename == "도와줄게, 지니!"){
                       let text = SCNText(string : "도와줄게, 지니!", extrusionDepth: 1)
                       node.name.self="도와줄게, 지니!1"
                       let material = SCNMaterial()
                       material.diffuse.contents = UIColor.red
                       text.materials = [material]
                       // node.position = SCNVector3(x: Float(tapLocation.x), y: Float(tapLocation.y), z:-1.5)
                       node.position = SCNVector3(x: Float(xx), y: Float(yy), z: Float(zz))
                       node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
                       node.geometry = text
                       

            for i in 0..<major_x_zs.count{
                    let mm: LocationModel = major_x_zs[i] as! LocationModel
                    if (String(mm.name ?? "") == Nodename){
                        print(mm.name)
                
                        txt2=String(mm.developer ?? "AAA") //상세정보
                        txt3 = String(mm.advisor ?? "AAA")
                        txt4 = String(mm.tool ?? "AAA")
                        print(txt3)
                        
                        textview_txt = txt2 + "\n" + txt3 + "\n" + txt4
                        
                        
                        textview.text=textview_txt
                        textview.isHidden=false
                        detailbutton.isHidden=false
                        
                        myname = String(mm.name ?? "")
                        mydeveloper = String(mm.developer ?? "")
                        myadvisor = String(mm.advisor ?? "")
                        mytool = String(mm.tool ?? "")
                        mymotivation = String(mm.motivation ?? "")
                        mysummary = String(mm.summary ?? "")
                        
                        //print("에러안남")
                        
                }
            }
                      
                   }
        else if(Nodename == "AR memo"){
                let text = SCNText(string : "AR memo", extrusionDepth: 1)
                node.name.self="AR memo1"
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.red
                text.materials = [material]
                // node.position = SCNVector3(x: Float(tapLocation.x), y: Float(tapLocation.y), z:-1.5)
                node.position = SCNVector3(x: Float(xx), y: Float(yy), z: Float(zz))
                node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
                node.geometry = text
            

            for i in 0..<major_x_zs.count{
                    let mm: LocationModel = major_x_zs[i] as! LocationModel
                    if (String(mm.name ?? "") == Nodename){
                        print(mm.name)
                
                        txt2=String(mm.developer ?? "AAA") //상세정보
                        txt3 = String(mm.advisor ?? "AAA")
                        txt4 = String(mm.tool ?? "AAA")
                        print(txt3)
                        
                        textview_txt = txt2 + "\n" + txt3 + "\n" + txt4
                        
                        
                        textview.text=textview_txt
                        textview.isHidden=false
                        detailbutton.isHidden=false
                        
                        myname = String(mm.name ?? "")
                        mydeveloper = String(mm.developer ?? "")
                        myadvisor = String(mm.advisor ?? "")
                        mytool = String(mm.tool ?? "")
                        mymotivation = String(mm.motivation ?? "")
                        mysummary = String(mm.summary ?? "")
                        
                        //print("에러안남")
                        
                }
            }
                
            }
        else if(Nodename == "원예 작물 관리 모바일 애플리케이션"){
                let text = SCNText(string : "원예 작물 관리 모바일 애플리케이션", extrusionDepth: 1)
                node.name.self="원예 작물 관리 모바일 애플리케이션1"
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.red
                text.materials = [material]
                // node.position = SCNVector3(x: Float(tapLocation.x), y: Float(tapLocation.y), z:-1.5)
                node.position = SCNVector3(x: Float(xx), y: Float(yy), z: Float(zz))
                node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
                node.geometry = text
                
            

            for i in 0..<major_x_zs.count{
                    let mm: LocationModel = major_x_zs[i] as! LocationModel
                    if (String(mm.name ?? "") == Nodename){
                        print(mm.name)
                
                        txt2=String(mm.developer ?? "AAA") //상세정보
                        txt3 = String(mm.advisor ?? "AAA")
                        txt4 = String(mm.tool ?? "AAA")
                        print(txt3)
                        
                        textview_txt = txt2 + "\n" + txt3 + "\n" + txt4
                        
                        
                        textview.text=textview_txt
                        textview.isHidden=false
                        detailbutton.isHidden=false
                        
                        myname = String(mm.name ?? "")
                        mydeveloper = String(mm.developer ?? "")
                        myadvisor = String(mm.advisor ?? "")
                        mytool = String(mm.tool ?? "")
                        mymotivation = String(mm.motivation ?? "")
                        mysummary = String(mm.summary ?? "")
                        
                        //print("에러안남")
                        
                }
            }
               
            }
        if(Nodename == "취업 가즈아1"){
                let text = SCNText(string : "취업 가즈아", extrusionDepth: 1)
                node.name.self="취업 가즈아"
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.blue
                text.materials = [material]
                // node.position = SCNVector3(x: Float(tapLocation.x), y: Float(tapLocation.y), z:-1.5)
                node.position = SCNVector3(x: Float(xx), y: Float(yy), z: Float(zz))
                node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
                node.geometry = text
            textview.isHidden=true
                textview.isHidden=true
                
            }
            else if(Nodename == "Plainbot1"){
                    let text = SCNText(string : "Plainbot", extrusionDepth: 1)
                    node.name.self="Plainbot"
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor.blue
                    text.materials = [material]
                    // node.position = SCNVector3(x: Float(tapLocation.x), y: Float(tapLocation.y), z:-1.5)
                    node.position = SCNVector3(x: Float(xx), y: Float(yy), z: Float(zz))
                    node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
                    node.geometry = text
            textview.isHidden=true
                    textview.isHidden=true
                }
            else if(Nodename == "도와줄게, 지니!1"){
                           let text = SCNText(string : "도와줄게, 지니!", extrusionDepth: 1)
                           node.name.self="도와줄게, 지니!"
                           let material = SCNMaterial()
                           material.diffuse.contents = UIColor.blue
                           text.materials = [material]
                           // node.position = SCNVector3(x: Float(tapLocation.x), y: Float(tapLocation.y), z:-1.5)
                           node.position = SCNVector3(x: Float(xx), y: Float(yy), z: Float(zz))
                           node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
                           node.geometry = text
               textview.isHidden=true
            textview.isHidden=true
                           
                       }
            else if(Nodename == "AR memo1"){
                    let text = SCNText(string : "AR memo", extrusionDepth: 1)
                    node.name.self="AR memo"
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor.blue
                    text.materials = [material]
                    // node.position = SCNVector3(x: Float(tapLocation.x), y: Float(tapLocation.y), z:-1.5)
                    node.position = SCNVector3(x: Float(xx), y: Float(yy), z: Float(zz))
                    node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
                    node.geometry = text
                    detailbutton.isHidden = true
                   textview.isHidden=true
                }
            else if(Nodename == "원예 작물 관리 모바일 애플리케이션1"){
                    let text = SCNText(string : "원예 작물 관리 모바일 애플리케이션", extrusionDepth: 1)
                    node.name.self="원예 작물 관리 모바일 애플리케이션"
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor.blue
                    text.materials = [material]
                    // node.position = SCNVector3(x: Float(tapLocation.x), y: Float(tapLocation.y), z:-1.5)
                    node.position = SCNVector3(x: Float(xx), y: Float(yy), z: Float(zz))
                    node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
                    node.geometry = text
            detailbutton.isHidden = true
                    textview.isHidden=true
                }
        
        
            
        
         sceneView.scene.rootNode.addChildNode(node)
    }
    
    @IBOutlet var sceneView: ARSCNView!
    
    var locationManager : CLLocationManager!
   
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let homeModel = HomeModel()
        homeModel.delegate = self
        homeModel.downloadItems()
        
        detailbutton.isHidden=true
        lable.isHidden=true
        ask.isHidden=true
        floor.isHidden=true
        enter.isHidden=true
        textview.isHidden=true

        
        
        let major_x_z = LocationModel()
        major_x_z.major = 4660
        major_x_z.x = 0
        major_x_z.z = 0
        major_x_zs.add(major_x_z)
        
        let major_x_z1 = LocationModel()
        major_x_z1.major = 4663
        major_x_z1.x = -0.64
        major_x_z1.z = 0
        major_x_zs.add(major_x_z1)
        
        let major_x_z2 = LocationModel()
        major_x_z2.major = 4661
        major_x_z2.x = -0.64
        major_x_z2.z = -0.57
        major_x_zs.add(major_x_z2)
                
        addTapGestureToSceneView()
        
    }
    
    var come=0
    
    func View(){
        
        class Square_Double{
            var sideLength: Double
            init(sideLength: Double){
                self.sideLength = sideLength
            }
        }
        
        
        sceneView.delegate = self
        //sceneView.showsStatistics = true
        if(X==0&&Y==0) {return}
        if come==1 {return}
        
        come=1
        
        
        print(major_x_zs.count)
        
        //데이터베이스에 있는 정보 가져오기
        for i in 0..<major_x_zs.count{
            
            
            let mm: LocationModel = major_x_zs[i] as! LocationModel
            
            let mmxSquare: Square_Double? = Square_Double(sideLength: Double(mm.x ?? 0))
            let mmxSquare2 = mmxSquare!.sideLength
            
            let mmzSquare: Square_Double? = Square_Double(sideLength: Double(mm.z ?? 0))
            let mmzSquare2 = mmzSquare!.sideLength
            
            //let text = SCNText(string : mm.name, extrusionDepth: 1)
            if(mm.name == nil){
                let text = SCNText(string : (mm.name ?? ""), extrusionDepth: 1)
                
                let material = SCNMaterial()
                
                       
                         
                material.diffuse.contents = UIColor.blue
                text.materials = [material]
                
                let node = SCNNode()
                node.position = SCNVector3(x: Float(mmxSquare2+X*(-1)), y: 0, z: Float(mmzSquare2+Y*(-1))) //위치
                node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
                node.geometry = text
                node.name = mm.name //노드 이름 지정
                     
                lable.isHidden = true // 로딩 레이블 사라짐
                
                sceneView.scene.rootNode.addChildNode(node)
            }
            else{
                let text = SCNText(string : (mm.name ?? "")+"↓", extrusionDepth: 1)
                
                let material = SCNMaterial()
                
                       
                         
                material.diffuse.contents = UIColor.blue
                text.materials = [material]
                
                let node = SCNNode()
                node.position = SCNVector3(x: Float(mmxSquare2+X*(-1)), y: 0, z: Float(mmzSquare2+Y*(-1))) //위치
                node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
                node.geometry = text
                node.name = mm.name //노드 이름 지정
                     
                lable.isHidden = true // 로딩 레이블 사라짐
                
                sceneView.scene.rootNode.addChildNode(node)
                
            }
            
            

        }
          
          sceneView.autoenablesDefaultLighting = true
     
        
    }
    

    
    

    func calculateNewDistance(txCalibratedPower: Int, rssi: Int) -> Double{

        

        if (rssi == 0)

            { return -1}

        let ratio = Double(exactly:rssi)!/Double(txCalibratedPower)



        return pow(10.0, ratio)/20

        

    }

    

    func getBeaconRegion() -> CLBeaconRegion {

        let beaconRegion = CLBeaconRegion.init(proximityUUID: UUID.init(uuidString: "74278BDA-B644-4520-8F0C-720EAF059935")!,

                                               identifier: "com.yunjeong.AR")

        return beaconRegion

    }

    

    func startScanningForBeaconRegion(beaconRegion: CLBeaconRegion) {

        //print(beaconRegion)

        locationManager.startMonitoring(for: beaconRegion)

        locationManager.startRangingBeacons(in: beaconRegion)

    }

    
    
    
    func PointFGetLocationWithCenterOfGravity(PointF a: PointF, PointF b: PointF, PointF c: PointF, Double dA: Double, Double dB: Double, Double dC:Double)->PointF
      {
        
          //http://.com/questions/20332856/triangulate-example-for-ibeacons

          var METERS_IN_COORDINATE_UNITS_RATIO = 1.0

          
          //http://.com/a/524770/663941

          //Find Center of Gravity

          let cogX = (a.X + b.X + c.X) / 3;
          let cogY = (a.Y + b.Y + c.Y) / 3;
          let cog = PointF(x: cogX,y: cogY);



          //Nearest Beacon

          let nearestBeacon:PointF
          let shortestDistanceInMeters: Double;

          if (dA < dB && dA < dC)
          {
              nearestBeacon = a;
              shortestDistanceInMeters = dA;
          }
          else if (dB < dC)
          {
              nearestBeacon = b;
              shortestDistanceInMeters = dB;
          }
          else
          {
              nearestBeacon = c;
              shortestDistanceInMeters = dC;
          }



          //http://www.mathplanet.com/education/algebra-2/conic-sections/distance-between-two-points-and-the-midpoint

          //Distance between nearest beacon and COG

          let distanceToCog =  (Double)(sqrt(pow(Double(cog.X - nearestBeacon.X), 2)

              + pow(Double(cog.Y - nearestBeacon.Y), 2)));


          //Convert shortest distance in meters into coordinates units.

          let shortestDistanceInCoordinationUnits = shortestDistanceInMeters * METERS_IN_COORDINATE_UNITS_RATIO;

        

          //http://math.stackexchange.com/questions/46527/coordinates-of-point-on-a-line-defined-by-two-other-points-with-a-known-distance?rq=1

          //On the line between Nearest Beacon and COG find shortestDistance point apart from Nearest Beacon

          let t = shortestDistanceInCoordinationUnits / distanceToCog;
          let pointsDiff = PointF(x: cog.X - nearestBeacon.X, y: cog.Y - nearestBeacon.Y);
          let tTimesDiff = PointF(x: pointsDiff.X * t, y: pointsDiff.Y * t);

          //Add t times diff with nearestBeacon to find coordinates at a distance from nearest beacon in line to COG.

          let userLocation = PointF(x: nearestBeacon.X + tTimesDiff.X, y: nearestBeacon.Y + tTimesDiff.Y);

          return userLocation;


      }
    
    
    
    

    let major_x_zs = NSMutableArray()


    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {

        
        //print(homemodel.x)

         class Square {

                   var sideLength: Int

                   init(sideLength: Int){

                       self.sideLength = sideLength

                   }
        }
        
        class Square_Double{
            var sideLength: Double
            init(sideLength: Double){
                self.sideLength = sideLength
            }
        }


               if beacons.count > 2 {
                
                let beacon = beacons.first
                let beacon1 = beacons[1]
                let beacon2 = beacons[2]
                
                print(beacon?.major)
                print(beacon?.rssi)
                print(beacon1.major)
                print(beacon1.rssi)
                print(beacon2.major)
                print(beacon2.rssi)
                if(beacon?.rssi == 0){
                    return
                }
                else if(beacon1.rssi == 0){
                    return
                }
                else if(beacon2.rssi == 0){
                    return
                }
                else{
                let optionalSquare2: Square? = Square(sideLength: beacon?.rssi ?? 0)
                    let sideLength2 = optionalSquare2!.sideLength

                    let optionalSquare3: Square? = Square(sideLength: beacon1.rssi)
                    let sideLength3 = optionalSquare3!.sideLength

                    let optionalSquare4: Square? = Square(sideLength: beacon2.rssi)
                    let sideLength4 = optionalSquare4!.sideLength

 
                    
                    if(calculateNewDistance(txCalibratedPower: -59, rssi: sideLength2)<0) {return}
                    if(calculateNewDistance(txCalibratedPower: -59, rssi: sideLength3)<0) {return}
                    if(calculateNewDistance(txCalibratedPower: -59, rssi: sideLength4)<0) {return}


                   

                   if(measurements.count>5){
                               let temp = measurements[5]
                               measurements.removeAll()
                               measurements.append(temp)
                    }

                   measurements.append(calculateNewDistance(txCalibratedPower: -59, rssi: sideLength2))

                

                    if(measurements1.count>5){
                            let temp = measurements1[5]
                            measurements1.removeAll()
                            measurements1.append(temp)
                        }

                    measurements1.append(calculateNewDistance(txCalibratedPower: -59, rssi: sideLength3))

                

                    if(measurements2.count>5){
                            let temp = measurements2[5]
                            measurements2.removeAll()
                            measurements2.append(temp)
                        }

                    measurements2.append(calculateNewDistance(txCalibratedPower: -59, rssi: sideLength4))

                
            //   let measurements = [calculateNewDistance(txCalibratedPower: -59, rssi: sideLength2)]
               

            var filter = KalmanFilter(stateEstimatePrior: 0.0, errorCovariancePrior: 1)
            var filter1 = KalmanFilter(stateEstimatePrior: 0.0, errorCovariancePrior: 1)
            var filter2 = KalmanFilter(stateEstimatePrior: 0.0, errorCovariancePrior: 1)
                
                

                //칼만필터 적용
                
            for measurement in measurements {
                    let prediction = filter.predict(stateTransitionModel: 1, controlInputModel: 0, controlVector: 0, covarianceOfProcessNoise: 0)
                    let update = prediction.update(measurement: measurement, observationModel: 1, covarienceOfObservationNoise: 0.1)
                    filter = update
                }
            for measurement in measurements1 {
                    let prediction = filter1.predict(stateTransitionModel: 1, controlInputModel: 0, controlVector: 0, covarianceOfProcessNoise: 0)
                    let update = prediction.update(measurement: measurement, observationModel: 1, covarienceOfObservationNoise: 0.1)
                    filter1 = update
                }
            for measurement in measurements2 {
                    let prediction = filter2.predict(stateTransitionModel: 1, controlInputModel: 0, controlVector: 0, covarianceOfProcessNoise: 0)
                    let update = prediction.update(measurement: measurement, observationModel: 1, covarienceOfObservationNoise: 0.1)
                    filter2 = update

                }
            
                if major_x_zs.count==3{
                    for i in 0..<feedItems.count{
                        let major_x_z = LocationModel()
                        let item: LocationModel = feedItems[i] as! LocationModel
                        major_x_z.major = item.major
                        major_x_z.x = item.x
                        major_x_z.z = item.z
                        major_x_z.name = item.name
                        major_x_z.developer = item.developer
                        major_x_z.advisor = item.advisor
                        major_x_z.tool = item.tool
                        major_x_z.motivation = item.motivation
                        major_x_z.summary = item.summary
                        major_x_zs.add(major_x_z)
                    }
                    
                }
                
                let a = PointF(x: Double(0),y: Double(0))//beacon
                let b = PointF(x: Double(0),y: Double(0))//beacon1
                let c = PointF(x: Double(0),y: Double(0))//beacon2

                
                //위치 적용
                for i in 0..<major_x_zs.count{
                    let mm: LocationModel = major_x_zs[i] as! LocationModel
                    
                    let mmSquare: Square_Double? = Square_Double(sideLength: Double(mm.major ?? 0))
                    let mmSquare2 = mmSquare!.sideLength
                    
                    //print(mm.major)
                    if mmSquare2==Double(beacon?.major ?? 0){
                        let mmxSquare: Square_Double? = Square_Double(sideLength: Double(mm.x ?? 0))
                        let mmxSquare2 = mmxSquare!.sideLength
                        
                        let mmzSquare: Square_Double? = Square_Double(sideLength: Double(mm.z ?? 0))
                        let mmzSquare2 = mmzSquare!.sideLength
                        
                        a.X = mmxSquare2
                        a.Y = mmzSquare2
                        
                    }
                    else if mmSquare2==Double(beacon1.major ?? 0){
                        let mmxSquare: Square_Double? = Square_Double(sideLength: Double(mm.x ?? 0))
                        let mmxSquare2 = mmxSquare!.sideLength
                        
                        let mmzSquare: Square_Double? = Square_Double(sideLength: Double(mm.z ?? 0))
                        let mmzSquare2 = mmzSquare!.sideLength
                        
                        b.X = mmxSquare2
                        b.Y = mmzSquare2
                        
                    }
                    else if mmSquare2==Double(beacon2.major ?? 0){
                        
                        let mmxSquare: Square_Double? = Square_Double(sideLength: Double(mm.x ?? 0))
                        let mmxSquare2 = mmxSquare!.sideLength
                        
                        let mmzSquare: Square_Double? = Square_Double(sideLength: Double(mm.z ?? 0))
                        let mmzSquare2 = mmzSquare!.sideLength
    
                        c.X = mmxSquare2
                        c.Y = mmzSquare2
                        
                    }
                }
              
               // let mylocation = PointFGetLocationWithCenterOfGravity(PointF: a, PointF: b, PointF: c, Double: filter.stateEstimatePrior, Double: filter1.stateEstimatePrior, Double: filter2.stateEstimatePrior)
                    
                let mylocation = PointFGetLocationWithCenterOfGravity(PointF: a, PointF: b, PointF: c, Double: calculateNewDistance(txCalibratedPower: -59, rssi: sideLength2), Double: calculateNewDistance(txCalibratedPower: -59, rssi: sideLength3), Double: calculateNewDistance(txCalibratedPower: -59, rssi: sideLength4))
                
                print(mylocation.X)
                print(mylocation.Y)
                myXX.text = String(describing: mylocation.X)
                myYY.text = String(describing: mylocation.Y)
                
                print("        ")
                
                print(Double(filter.stateEstimatePrior))
                print(Double(filter1.stateEstimatePrior))
                print(Double(filter2.stateEstimatePrior))
                
                distance1.text = String(filter.stateEstimatePrior)
                distance2.text = String(filter1.stateEstimatePrior)
                distance3.text = String(filter2.stateEstimatePrior)
                
                
                print("-----------")
                
                
                X = mylocation.X
                Y = mylocation.Y
                
                if(measurements.count>4){
                    if(measurements1.count>4){
                        if(measurements2.count>4){
                            if(major_x_zs.count>0){
                                    View()
                            }
                        }
                    }
                }
                }
                
             }

               else {
                
                    print("NO 3 BEACON")
               }
               

               //print("Ranging")



    }

    

    class PointF {

        var X: Double
        var Y: Double
        init(x: Double,y: Double){
            self.X = x
            self.Y = y
        }
    }

   

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
  
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTap(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    

    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }

}
