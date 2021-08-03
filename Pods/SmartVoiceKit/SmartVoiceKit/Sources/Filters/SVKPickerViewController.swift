//
//
// Software Name: Smart Voice Kit - SmartvoiceKit
//
// SPDX-FileCopyrightText: Copyright (c) 2017-2021 Orange
//
// This software is confidential and proprietary information of Orange.
// You are not allowed to disclose such Confidential Information nor to copy, use,
// modify, or distribute it in whole or in part without the prior written
// consent of Orange.
//
// Author: The current developers of this code can be
// found in the authors.txt file at the root of the project
//
// Software description: Smart Voice Kit is the iOS SDK that allows to
// integrate the Smart Voice Hub voice assistant into your app.
//
// Module description: The main framework for the Smart Voice Kit is the iOS SDK
// to integrate the Smart Voice Hub Audio Assistant inside your App.
//


import UIKit

protocol SVKPickerViewable where Self: UIViewController {
    func displayPicker(type: SVKFilterType, delegate: SVKFilterDelegate?) -> SVKPickerViewController?
}

extension SVKPickerViewable {
    func displayPicker(type: SVKFilterType, delegate: SVKFilterDelegate?) -> SVKPickerViewController? {
        let pickerStoryboard = UIStoryboard(name: "SVKConversationStoryboard", bundle: SVKBundle)
        guard let pickerView = pickerStoryboard.instantiateViewController(withIdentifier: String(describing: SVKPickerViewController.self)) as? SVKPickerViewController else {
            return nil
        }

        pickerView.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        pickerView.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        pickerView.filterType = type
        pickerView.delegate = delegate
        self.present(pickerView, animated: true, completion: nil)
        return pickerView
    }
}

enum SVKFilterType {
    case time, speaker
}


class SVKPickerViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    var pickerData: [(SVKFilterRange,String)] = [(SVKFilterRange,String)]()
    var speakerPickerData: [(SVKFilterDevice?,String)] = [(SVKFilterDevice,String)]()

    var filterType: SVKFilterType = .time

    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField.isHidden = true
        }
    }

    lazy var timePickerView: UIPickerView = {
       let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        return picker
    }()

    lazy var speakerPickerView: UIPickerView = {
       let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        return picker
    }()

    lazy var toolBar: UIToolbar = {
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = SVKAppearanceBox.ToolBarStyle.tintColor
        toolBar.sizeToFit()
        return toolBar
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        timePickerView.backgroundColor = {
            if #available(iOS 13, *){
                return .systemBackground
            }
            return .white
        }()
        speakerPickerView.backgroundColor = {
            if #available(iOS 13, *){
                return .systemBackground
            }
            return .white
        }()

        toolBar.backgroundColor = SVKAppearanceBox.ToolBarStyle.backgroundColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.7)

        SVKAnalytics.shared.startActivity(name: "myactivity_filter_selection", with: nil)

        for type in SVKFilterRange.allCases {
            let filterString = ("Filters.enum.\(type)").localized
            pickerData.append((type, filterString))
        }

        speakerPickerData.append((nil,"Filters.speaker.all".localized))
        speakerPickerView.selectRow(0, inComponent: 0, animated: false)

        let doneButton = UIBarButtonItem(title: "Filter.button.done".localized, style: UIBarButtonItem.Style.done, target: self, action: #selector(didTapOnDone))
        doneButton.setTitleTextAttributes([.font: SVKAppearanceBox.shared.appearance.toolBarStyle.font.font], for: .normal)
        doneButton.setTitleTextAttributes([.font: SVKAppearanceBox.shared.appearance.toolBarStyle.font.font], for: .selected)
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        toolBar.setItems([spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true

        if filterType == .time {
            textField.inputView = timePickerView
        } else {
            textField.inputView = speakerPickerView
        }
        textField.inputAccessoryView = toolBar
        textField.becomeFirstResponder()
    }

    var delegate: SVKFilterDelegate?

    func setTimeFilterPicker(list: [SVKFilterRange], selectedTimeFilter: SVKFilterRange) {
        pickerData = []
        for item in list {
            let filterString = ("Filters.enum.\(item)").localized
            pickerData.append((item, filterString))
        }

        if selectedTimeFilter.rawValue < pickerData.count {
            timePickerView.selectRow(selectedTimeFilter.rawValue, inComponent: 0, animated: false)
        }
    }

    func updateSpeaker(sourceList: [SVKFilterDevice], defaultDeviceSerialNumber: String?) {
        speakerPickerData = []
        speakerPickerData.append((nil,"Filters.speaker.all".localized))
        speakerPickerView.reloadComponent(0)
        speakerPickerView.selectRow(0, inComponent: 0, animated: false)
        var selectedIndex = 0
        var index = 0
        for (_, device) in sourceList.enumerated().sorted(by: { (device1, device2) -> Bool in
            return device1.element.name < device2.element.name
        }) {
            if !device.serialNumber.isEmpty && !device.name.isEmpty {
                self.speakerPickerData.append((device, device.name))
                if defaultDeviceSerialNumber == device.serialNumber {
                    selectedIndex = index + 1
                }
                index += 1
            }
        }
        self.speakerPickerView.reloadComponent(0)
        self.speakerPickerView.selectRow(selectedIndex, inComponent: 0, animated: false)
    }

    @objc
    private func didTapOnDone() {
        if filterType == .time {
            delegate?.updateRangeFilter(value: pickerData[timePickerView.selectedRow(inComponent: 0)].0)
        } else {
            delegate?.updatePeriodFilter(value: speakerPickerData[speakerPickerView.selectedRow(inComponent: 0)].0)
        }

       let filterValue = SVKFilter(range: pickerData[timePickerView.selectedRow(inComponent: 0)].0,
                                   device: speakerPickerData[speakerPickerView.selectedRow(inComponent: 0)].0 )
        log(filterValue: filterValue)
        self.dismiss(animated: true, completion: nil)
    }
  
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == timePickerView {
            return pickerData.count
        } else {
            return speakerPickerData.count
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)-> String? {
        if pickerView == timePickerView {
            return pickerData[row].1
        } else {
            return speakerPickerData[row].1
        }
    }

    private func log(filterValue: SVKFilter) {
        var event:String = ""
        switch filterValue.range {
        case .all:
            event = "myactivity_filter_all"
        case .today:
            event = "myactivity_filter_today"
        case .yesterday:
            event = "myactivity_filter_yesterday"
        case .last7days:
            event = "myactivity_filter_last7days"
        case .thisMonth:
            event = "myactivity_filter_this_month"
        case .lastMonth:
            event = "myactivity_filter_last_month"
        }
        SVKAnalytics.shared.log(event: event)
    }
}
