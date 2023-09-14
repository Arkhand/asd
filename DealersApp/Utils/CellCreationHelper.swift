//
// DealersApp
//
// Created by SAP BTP SDK Assistant for iOS v9.1.3 application on 13/09/23
//

import Foundation
import SAPFiori
import SAPOData
import UIKit

class CellCreationHelper {
    // MARK: - Creating cells

    static func objectCellWithNonEditableContent(tableView: UITableView, indexPath: IndexPath, key: String, value: String) -> FUIObjectTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FUIObjectTableViewCell.reuseIdentifier, for: indexPath as IndexPath) as! FUIObjectTableViewCell
        cell.headlineText = value
        cell.footnoteText = key
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    static func cellForDefault(tableView: UITableView, indexPath: IndexPath, editingIsAllowed: Bool = false) -> FUITextFieldFormCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FUITextFieldFormCell.reuseIdentifier, for: indexPath) as! FUITextFieldFormCell
        cell.textLabel!.text = ""
        cell.textLabel!.numberOfLines = 0
        cell.textLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.keyName = "default"
        cell.isEditable = editingIsAllowed
        return cell
    }

    static func cellForProperty(tableView: UITableView, indexPath: IndexPath, entity: EntityValue, property: Property, value: String, editingIsAllowed: Bool = false, changeHandler: @escaping ((String) -> Bool)) -> UITableViewCell {
        let cell: UITableViewCell!

        if property.dataType.isBasic {
            // The property is a key or we are creating new entity
            if !property.isKey || entity.isNew {
                // .. that CAN be edited
                if property.dataType.code == DataType.boolean {
                    cell = formBooleanCellWithEditableContent(tableView: tableView, indexPath: indexPath, property: property, with: value, editingIsAllowed: editingIsAllowed, changeHandler: changeHandler)
                } else if [DataType.localDateTime, DataType.globalDateTime].contains(property.type.code) {
                    cell = formDateCellWithEditableContent(tableView: tableView, indexPath: indexPath, property: property, with: value, editingIsAllowed: editingIsAllowed, changeHandler: changeHandler)
                } else {
                    cell = formCellWithEditableContent(tableView: tableView, indexPath: indexPath, property: property, with: value, editingIsAllowed: editingIsAllowed, changeHandler: changeHandler)
                }
            } else {
                // .. that CANNOT be edited
                cell = formCellWithNonEditableContent(tableView: tableView, indexPath: indexPath, for: property.name, with: value)
            }
        } else {
            // A complex property
            cell = formCellWithNonEditableContent(tableView: tableView, indexPath: indexPath, for: property.name, with: "...")
        }
        return cell
    }

    private static func formDateCellWithEditableContent(tableView: UITableView, indexPath: IndexPath, property: Property, with value: String, editingIsAllowed: Bool = true, changeHandler: @escaping ((String) -> Bool)) -> FUIDatePickerFormCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FUIDatePickerFormCell.reuseIdentifier, for: indexPath) as! FUIDatePickerFormCell

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        cell.keyName = property.name
        cell.isEditable = editingIsAllowed
        cell.dateFormatter = dateFormatter
        if let date = cell.dateFormatter?.date(from: value) {
            cell.value = date
        }

        // MARK: implement onChangeHandler

        cell.onChangeHandler = { newValue in
            if let selectedValue = cell.dateFormatter?.string(from: newValue) {
                _ = changeHandler(selectedValue)
            }
        }
        return cell
    }

    private static func formBooleanCellWithEditableContent(tableView: UITableView, indexPath: IndexPath, property: Property, with value: String, editingIsAllowed: Bool = true, changeHandler: @escaping ((String) -> Bool)) -> FUIListPickerFormCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FUIListPickerFormCell.reuseIdentifier, for: indexPath) as! FUIListPickerFormCell
        cell.keyName = property.name
        if property.isOptional {
            cell.valueOptions = ["false", "true", "null"]
            cell.value = [cell.valueOptions.firstIndex(of: value) ?? 2]
            cell.onChangeHandler = { newValue in
                let selectedValue = cell.valueOptions[newValue.first ?? 2]
                _ = changeHandler(selectedValue == "null" ? "" : selectedValue)
            }
        } else {
            cell.valueOptions = ["false", "true"]
            cell.value = [cell.valueOptions.firstIndex(of: value) ?? 0]
            cell.onChangeHandler = { newValue in
                let selectedValue = cell.valueOptions[newValue.first ?? 0]
                _ = changeHandler(selectedValue)
            }
        }
        cell.allowsMultipleSelection = false
        cell.allowsEmptySelection = false
        cell.presentsListPickerModally = true
        cell.isUndoEnabled = true
        cell.isEditable = editingIsAllowed
        return cell
    }

    private static func formCellWithEditableContent(tableView: UITableView, indexPath: IndexPath, property: Property, with value: String, editingIsAllowed: Bool = true, changeHandler: @escaping ((String) -> Bool)) -> FUITextFieldFormCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FUITextFieldFormCell.reuseIdentifier, for: indexPath) as! FUITextFieldFormCell

        cell.keyName = property.name
        cell.value = value
        cell.isTrackingLiveChanges = true
        cell.isEditable = editingIsAllowed
        cell.keyboardType = selectKeyboardFor(property.dataType)

        if !property.isOptional {
            cell.valueTextField.placeholder = NSLocalizedString("keyRequiredPlaceholder", value: "Required", comment: "XSEL: Placeholder text for required but currently empty textfield.")
        }

        cell.onChangeHandler = { newValue in
            let isNewValueValid = changeHandler(newValue)
            cell.valueTextField.textColor = isNewValueValid ? UIColor.preferredFioriColor(forStyle: .quaternaryLabel) : UIColor.preferredFioriColor(forStyle: .negativeLabel)
        }

        return cell
    }

    private static func formCellWithNonEditableContent(tableView: UITableView, indexPath: IndexPath, for key: String, with value: String) -> FUITextFieldFormCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FUITextFieldFormCell.reuseIdentifier, for: indexPath) as! FUITextFieldFormCell
        cell.keyName = key
        cell.value = value
        cell.isEditable = false
        return cell
    }

    // MARK: - Parsing default values

    static func defaultValueFor(_ property: Property) -> Double {
        if let defaultValue = property.defaultValue {
            return Double(defaultValue.toString())!
        } else {
            return Double()
        }
    }

    static func defaultValueFor(_ property: Property) -> BigDecimal {
        if let defaultValue = property.defaultValue {
            return (defaultValue as! DecimalValue).value
        } else {
            return BigDecimal.fromDouble(Double())
        }
    }

    static func defaultValueFor(_ property: Property) -> Int {
        if let defaultValue = property.defaultValue {
            return Int(defaultValue.toString())!
        } else {
            return Int()
        }
    }

    static func defaultValueFor(_ property: Property) -> BigInteger {
        if let defaultValue = property.defaultValue {
            return BigInteger(defaultValue.toString())
        } else {
            return BigInteger.fromInt(Int())
        }
    }

    static func defaultValueFor(_ property: Property) -> Int64 {
        if let defaultValue = property.defaultValue {
            return Int64(defaultValue.toString())!
        } else {
            return Int64()
        }
    }

    static func defaultValueFor(_ property: Property) -> Float {
        if let defaultValue = property.defaultValue {
            return Float(defaultValue.toString())!
        } else {
            return Float()
        }
    }

    static func defaultValueFor(_ property: Property) -> LocalDateTime {
        if let defaultValue = property.defaultValue {
            return LocalDateTime.parse(defaultValue.toString())!
        } else {
            return LocalDateTime.now()
        }
    }

    static func defaultValueFor(_ property: Property) -> GlobalDateTime {
        if let defaultValue = property.defaultValue {
            return GlobalDateTime.parse(defaultValue.toString())!
        } else {
            return GlobalDateTime.now()
        }
    }

    static func defaultValueFor(_ property: Property) -> GuidValue {
        if let defaultValue = property.defaultValue {
            return GuidValue.parse(defaultValue.toString())!
        } else {
            return GuidValue.random()
        }
    }

    static func defaultValueFor(_ property: Property) -> String {
        if let defaultValue = property.defaultValue {
            return defaultValue.toString()
        } else {
            return ""
        }
    }

    static func defaultValueFor(_ property: Property) -> Bool {
        if let defaultValue = property.defaultValue {
            return Bool(defaultValue.toString()) ?? false
        } else {
            return Bool()
        }
    }

    private static func selectKeyboardFor(_ type: DataType) -> UIKeyboardType {
        switch type.code {
        case DataType.int, DataType.short, DataType.long, DataType.integer, DataType.unsignedByte:
            return .numberPad
        case DataType.decimal, DataType.double, DataType.float:
            return .decimalPad
        case DataType.localDateTime, DataType.globalDateTime:
            return .numbersAndPunctuation
        default:
            return .default
        }
    }
}
