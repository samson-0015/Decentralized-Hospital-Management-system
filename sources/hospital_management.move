#[allow(unused_const)]
module hospital_management::hospital_management {
    use sui::transfer;
    use sui::sui::SUI;
    use std::string::String;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};

    // Errors
    const EInsufficientBalance: u64 = 1;
    const ENotHospital: u64 = 2;
    const ENotStaff: u64 = 3;
    const ENotPatient: u64 = 4;
    const ENotAppointment: u64 = 5;
    const ENotAuthorized: u64 = 6;
    const ERoomUnavailable: u64 = 7;
    const ERoomNotFound: u64 = 8;

    // Structs
    struct Hospital has key, store {
        id: UID,
        name: String,
        address: String,
        balance: Balance<SUI>,
        staff: Table<ID, Staff>,
        patients: Table<ID, Patient>,
        appointments: Table<ID, Appointment>,
        inventory: Table<ID, InventoryItem>,
        rooms: Table<ID, Room>,
        principal: address,
    }

    struct HospitalCap has key {
        id: UID,
        for: ID,
    }

    struct Staff has key, store {
        id: UID,
        name: String,
        role: String,
        principal: address,
        balance: Balance<SUI>,
        department: String,
        hireDate: String,
    }

    struct Patient has key, store {
        id: UID,
        name: String,
        age: u64,
        address: String,
        principal: address,
        medicalHistory: String,
    }

    struct Appointment has key, store {
        id: UID,
        patient: address,
        doctor: address,
        date: String,
        time: String,
        description: String,
    }

    struct InventoryItem has key, store {
        id: UID,
        name: String,
        quantity: u64,
        unit_price: u64,
    }

    struct Room has key, store {
        id: UID,
        room_number: String,
        capacity: u64,
        available: bool,
    }

    // Helper functions
    fun is_authorized(principal: address, authorized: address) {
        assert!(principal == authorized, ENotAuthorized);
    }

    fun add_patient_to_hospital(hospital: &mut Hospital, patient: Patient) {
        table::add(&mut hospital.patients, object::uid_to_inner(&patient.id), patient);
    }

    fun add_staff_to_hospital(hospital: &mut Hospital, staff: Staff) {
        table::add(&mut hospital.staff, object::uid_to_inner(&staff.id), staff);
    }

    // Hospital methods

    /// Adds information about a new hospital.
    ///
    /// Returns a `HospitalCap` object representing the capability to manage the hospital.
    public fun add_hospital_info(
        name: String,
        address: String,
        ctx: &mut TxContext
    ) : HospitalCap {
        let id = object::new(ctx);
        let inner = object::uid_to_inner(&id);
        let hospital = Hospital {
            id,
            name,
            address,
            balance: balance::zero<SUI>(),
            principal: tx_context::sender(ctx),
            staff: table::new<ID, Staff>(ctx),
            patients: table::new<ID, Patient>(ctx),
            appointments: table::new<ID, Appointment>(ctx),
            inventory: table::new<ID, InventoryItem>(ctx),
            rooms: table::new<ID, Room>(ctx),
        };
        transfer::share_object(hospital);

        HospitalCap {
            id: object::new(ctx),
            for: inner,
        }
    }

    /// Deposits funds into the hospital's balance.
    ///
    /// Takes a `Coin<SUI>` amount and adds it to the hospital's balance.
    public fun deposit(
        hospital: &mut Hospital,
        amount: Coin<SUI>,
    ) {
        let coin = coin::into_balance(amount);
        balance::join(&mut hospital.balance, coin);
    }

    // Staff methods

    /// Adds information about a new staff member.
    ///
    /// Returns a `Staff` object representing the newly added staff member.
    public fun add_staff_info(
        name: String,
        role: String,
        department: String,
        hireDate: String,
        ctx: &mut TxContext
    ) : Staff {
        let id = object::new(ctx);
        let staff = Staff {
            id,
            name,
            role,
            principal: tx_context::sender(ctx),
            balance: balance::zero<SUI>(),
            department,
            hireDate,
        };
        add_staff_to_hospital(&mut table::borrow_mut(&mut hospital.staff, id), staff);
        staff
    }

    /// Updates information about an existing staff member.
    ///
    /// Requires authorization from the staff member themselves.
    public fun update_staff_info(
        staff: &mut Staff,
        name: String,
        role: String,
        department: String,
        hireDate: String,
        ctx: &mut TxContext
    ) {
        is_authorized(staff.principal, tx_context::sender(ctx));
        staff.name = name;
        staff.role = role;
        staff.department = department;
        staff.hireDate = hireDate;
    }

    // Pay staff salary

    /// Pays salary to a staff member from the hospital's balance.
    ///
    /// Takes an `amount` to be paid and transfers it from hospital to the staff member.
    public fun pay_staff(
        hospital: &mut Hospital,
        staff: &mut Staff,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(balance::value(&hospital.balance) >= amount, EInsufficientBalance);
        let payment = coin::take(&mut hospital.balance, amount, ctx);
        coin::put(&mut staff.balance, payment);
    }

    // Patient methods

    /// Adds information about a new patient.
    ///
    /// Returns a `Patient` object representing the newly added patient.
    public fun add_patient_info(
        hospital: &mut Hospital,
        name: String,
        age: u64,
        address: String,
        medicalHistory: String,
        ctx: &mut TxContext
    ) : Patient {
        let id = object::new(ctx);
        let patient = Patient {
            id,
            name,
            age,
            address,
            principal: tx_context::sender(ctx),
            medicalHistory,
        };
        add_patient_to_hospital(hospital, patient);
        patient
    }

    /// Updates information about an existing patient.
    ///
    /// Requires authorization from the patient themselves.
    public fun update_patient_info(
        patient: &mut Patient,
        name: String,
        age: u64,
        address: String,
        medicalHistory: String,
        ctx: &mut TxContext
    ) {
        is_authorized(patient.principal, tx_context::sender(ctx));
        patient.name = name;
        patient.age = age;
        patient.address = address;
        patient.medicalHistory = medicalHistory;
    }

    // Appointment methods

    /// Adds information about a new appointment.
    ///
    /// Returns an `Appointment` object representing the newly added appointment.
    public fun add_appointment_info(
        hospital: &mut Hospital,
        patient: &mut Patient,
        doctor: &mut Staff,
        date: String,
        time: String,
        description: String,
        ctx: &mut TxContext
    ) {
        let id = object::new(ctx);
        let appointment = Appointment {
            id,
            patient: patient.principal,
            doctor: doctor.principal,
            date,
            time,
            description,
        };

        table::add<ID, Appointment>(&mut hospital.appointments, object::uid_to_inner(&appointment.id), appointment);
    }

    /// Cancels an existing appointment.
    ///
    /// Removes the appointment from hospital's records and deletes associated data.
    public fun cancel_appointment(
        hospital: &mut Hospital,
        appointment: ID,
    ) {
        let appointment = table::remove(&mut hospital.appointments, appointment);
        let Appointment {
            id,
            patient: _,
            doctor: _,
            date: _,
            time: _,
            description: _,
        } = appointment;
        object::delete(id);
    }

    // Inventory methods

    /// Adds a new item to hospital's inventory.
    ///
    /// Returns nothing.
    public fun add_inventory_item(
        hospital: &mut Hospital,
        name: String,
        quantity: u64,
        unit_price: u64,
        ctx: &mut TxContext
    ) {
        let id = object::new(ctx);
        let item = InventoryItem {
            id,
            name,
            quantity,
            unit_price,
        };

        table::add<ID, InventoryItem>(&mut hospital.inventory, object::uid_to_inner(&item.id), item);
    }

    /// Updates an existing inventory item.
    ///
    /// Takes `item_id`, `name`, `quantity`, `unit_price` and updates corresponding item in inventory.
    public fun update_inventory_item(
        hospital: &mut Hospital,
        item_id: ID,
        name: String,
        quantity: u64,
        unit_price: u64,
    ) {
        let item = table::borrow_mut(&mut hospital.inventory, item_id);
        item.name = name;
        item.quantity = quantity;
        item.unit_price = unit_price;
    }

    /// Removes an item from hospital's inventory.
    ///
    /// Deletes the item from inventory table and associated data.
    public fun remove_inventory_item(
        hospital: &mut Hospital,
        item_id: ID,
    ) {
        let item = table::remove(&mut hospital.inventory, item_id);
        let InventoryItem { id, name: _, quantity: _, unit_price: _ } = item;
        object::delete(id);
    }

    // Room management methods

    /// Adds a new room to the hospital.
    ///
    /// Returns a `Room` object representing the newly added room.
    public fun add_room(
        hospital: &mut Hospital,
        room_number: String,
        capacity: u64,
        ctx: &mut TxContext
    ) : Room {
        let id = object::new(ctx);
        let room = Room {
            id,
            room_number,
            capacity,
            available: true,
        };
        table::add<ID, Room>(&mut hospital.rooms, object::uid_to_inner(&room.id), room);
        room
    }

    /// Updates the availability of a room.
    ///
    /// Takes `room_id` and `available` status to update the room availability.
    public fun update_room_availability(
        hospital: &mut Hospital,
        room_id: ID,
        available: bool,
    ) {
        let room = table::borrow_mut(&mut hospital.rooms, room_id);
        room.available = available;
    }

    /// Assigns a room to a patient.
    ///
    /// Takes `room_id` and `patient_id` to assign the room to the patient.
    public fun assign_room_to_patient(
        hospital: &mut Hospital,
        room_id: ID,
        patient_id: ID,
    ) {
        let room = table::borrow_mut(&mut hospital.rooms, room_id);
        assert!(room.available, ERoomUnavailable);

        let patient = table::borrow(&hospital.patients, patient_id)
            .expect(ENotPatient);

        // Mark the room as unavailable
        room.available = false;

        // Logic for assigning room to patient can be extended here
        // For example, updating a RoomAssignment table or patient record
    }

    // Handle hospital expenses

    /// Pays an expense from hospital's balance.
    ///
    /// Takes `amount` and transfers it out from hospital's balance.
    public fun pay_expense(
        hospital: &mut Hospital,
        amount: u64,
        ctx: &mut TxContext
    ) : Coin<SUI> {
        assert!(balance::value(&hospital.balance) >= amount, EInsufficientBalance);
        let payment = coin::take(&mut hospital.balance, amount, ctx);
        payment
    }

    /// Discharges a patient from the hospital.
    ///
    /// Removes the patient from the hospital's patient table and deletes associated data.
    public fun discharge_patient(
        hospital: &mut Hospital,
        patient_id: ID,
    ) {
        let patient = table::remove(&mut hospital.patients, patient_id);
        let Patient { id, name: _, age: _, address: _, principal: _, medicalHistory: _ } = patient;
        object::delete(id);
    }
}
