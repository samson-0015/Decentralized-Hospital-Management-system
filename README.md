# SUI Hospital Management Module

The SUI Hospital Management module facilitates the comprehensive management of hospital operations within a decentralized system. It offers functionalities for managing hospital information, staff, patients, appointments, inventory, financial transactions, and more. This module ensures efficient and secure management of hospital resources while maintaining transparency and accountability.

## Struct Definitions

### Hospital
- **id**: Unique identifier for each hospital.
- **name**: Name of the hospital.
- **address**: Physical address of the hospital.
- **balance**: Balance of SUI tokens held by the hospital.
- **staff**: Table containing staff members associated with the hospital.
- **patients**: Table containing patient records associated with the hospital.
- **appointments**: Table containing appointment details within the hospital.
- **inventory**: Table containing inventory items managed by the hospital.
- **principal**: Address of the primary administrator managing the hospital.

### HospitalCap
- **id**: Unique identifier for capabilities related to hospital management.
- **for**: ID associated with the specific hospital instance.

### Staff
- **id**: Unique identifier for each staff member.
- **name**: Name of the staff member.
- **role**: Role or position held by the staff member.
- **principal**: Address of the staff member's identity within the system.
- **balance**: Balance of SUI tokens attributed to the staff member.
- **department**: Department or unit within the hospital where the staff member operates.
- **hireDate**: Date when the staff member joined the hospital.

### Patient
- **id**: Unique identifier for each patient.
- **name**: Name of the patient.
- **age**: Age of the patient.
- **address**: Address of the patient.
- **principal**: Address of the patient's identity within the system.
- **medicalHistory**: Medical history and relevant health information of the patient.

### Appointment
- **id**: Unique identifier for each appointment.
- **patient**: Address of the patient associated with the appointment.
- **doctor**: Address of the doctor responsible for the appointment.
- **date**: Date of the appointment.
- **time**: Time of the appointment.
- **description**: Description or purpose of the appointment.

### InventoryItem
- **id**: Unique identifier for each inventory item.
- **name**: Name or description of the inventory item.
- **quantity**: Quantity of the inventory item available in stock.
- **unit_price**: Price per unit of the inventory item.

## Public - Entry Functions

### add_hospital_info
Creates a new hospital instance with specified name and address, initializing associated tables and setting the principal administrator.

### deposit
Adds SUI tokens to the hospital's balance.

### add_staff_info
Adds a new staff member to the hospital with specified name, role, department, and hire date.

### update_staff_info
Updates information about an existing staff member, requiring authorization from the staff member themselves.

### pay_staff
Pays salary to a staff member from the hospital's balance.

### add_patient_info
Adds a new patient to the hospital with specified name, age, address, and medical history.

### update_patient_info
Updates information about an existing patient, requiring authorization from the patient themselves.

### add_appointment_info
Creates a new appointment within the hospital, associating a patient, doctor, date, time, and description.

### cancel_appointment
Removes an existing appointment from the hospital's records.

### add_inventory_item
Adds a new item to the hospital's inventory with specified name, quantity, and unit price.

### update_inventory_item
Updates information about an existing inventory item, such as its name, quantity, and unit price.

### remove_inventory_item
Removes an item from the hospital's inventory.

### pay_expense
Pays an expense from the hospital's balance.

### discharge_patient
Discharges a patient from the hospital, removing associated records and data.

## Setup

### Prerequisites

1. **Rust and Cargo**: Install Rust and Cargo on your development machine by following the official Rust installation instructions.

2. **SUI Blockchain**: Set up a local instance of the SUI blockchain for development and testing purposes. Refer to the SUI documentation for installation instructions.

### Build and Deploy

1. Clone the SUI Hospital Management repository and navigate to the project directory on your local machine.

2. Compile the smart contract code using below command

   ```bash
   sui move build
   ```

3. Deploy the compiled smart contract to your local SUI blockchain node using the SUI CLI or other deployment tools.

4. Note the contract address and other relevant identifiers for interacting with the deployed contract.

## Usage

### Adding New Hospital Information

To create a new hospital instance, call the `add_hospital_info` function with the hospital's name, address, and a transaction context.

### Managing Staff

Add new staff members using `add_staff_info` and update their information with `update_staff_info`. Pay staff salaries using `pay_staff`.

### Managing Patients and Appointments

Add new patients using `add_patient_info`, update patient information with `update_patient_info`, and manage appointments by adding (`add_appointment_info`) or canceling (`cancel_appointment`) them.

### Managing Inventory

Add new items to the hospital's inventory using `add_inventory_item`, update item details with `update_inventory_item`, and remove items using `remove_inventory_item`.

### Financial Transactions and Expenses

Deposit funds into the hospital's balance using `deposit` and pay expenses using `pay_expense`.

### Discharging Patients

Discharge patients from the hospital using `discharge_patient`, removing their records from the system.

## Interacting with the Smart Contract

### Using the SUI CLI

1. Utilize the SUI CLI to interact with the deployed smart contract, providing function arguments and transaction contexts as required.

2. Monitor transaction outputs and blockchain events to track hospital operations, staff management, patient care, inventory management, and financial transactions.

## Conclusion

The SUI Hospital Management module provides a robust solution for decentralized management of hospital operations, ensuring efficient resource utilization, patient care, staff management, and inventory control. By leveraging blockchain technology, this module enhances transparency, security, and accountability in hospital administration, facilitating seamless interaction and management of hospital resources within a decentralized ecosystem.