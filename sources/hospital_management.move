module hospital_management::hospital_management {
    use sui::transfer;
    use sui::sui::SUI;
    use std::string::String;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::event;

    // Errors
    const EInsufficientBalance: u64 = 1;
    const ENotAuthorized: u64 = 2;
    const EInvalidRole: u64 = 3;
    const EInvalidQuantity: u64 = 4;

    // Events
    struct AddPatient has copy, drop {
        hospital_id: ID,
        patient_id: ID,
    }

    struct AddStaff has copy, drop {
        hospital_id: ID,
        staff_id: ID,
    }

    struct AddAppointment has copy, drop {
        hospital_id: ID,
        appointment_id: ID,
    }

    struct CancelAppointment has copy, drop {
        hospital_id: ID,
        appointment_id: ID,
    }

    struct AddInventoryItem has copy, drop {
        hospital_id: ID,
        item_id: ID,
    }

    struct RemoveInventoryItem has copy, drop {
        hospital_id: ID,
        item_id: ID,
    }

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
        medicalHistory: String, // Should be encrypted or stored off-chain in real-world scenarios
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
        total_cost: u64,
    }

    // Utility Functions

    fun authorize(hospital: &Hospital, ctx: &TxContext) {
        assert!(tx_context::sender(ctx) == hospital.principal, ENotAuthorized);
    }

    fun authorize_staff(staff: &Staff, ctx: &TxContext) {
        assert!(tx_context::sender(ctx) == staff.principal, ENotAuthorized);
    }

    // Hospital methods

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
        };
        transfer::share_object(hospital);

        HospitalCap {
            id: object::new(ctx),
            for: inner,
        }
    }

    public fun deposit(
        hospital: &mut Hospital,
        amount: Coin<SUI>,
    ) {
        let coin = coin::into_balance(amount);
        balance::join(&mut hospital.balance, coin);
    }

    // Staff methods

    public fun add_staff_info(
        hospital: &mut Hospital,
        name: String,
        role: String,
        department: String,
        hireDate: String,
        ctx: &mut TxContext
    ) : Staff {
        authorize(hospital, ctx);
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
        table::add(&mut hospital.staff, object::uid_to_inner(&staff.id), staff);
        event::emit_event(AddStaff {
            hospital_id: object::uid_to_inner(&hospital.id),
            staff_id: object::uid_to_inner(&staff.id),
        });
        staff
    }

    public fun update_staff_info(
        staff: &mut Staff,
        name: String,
        role: String,
        department: String,
        hireDate: String,
        ctx: &mut TxContext
    ) {
        authorize_staff(staff, ctx);
        staff.name = name;
        staff.role = role;
        staff.department = department;
        staff.hireDate = hireDate;
    }

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

    public fun add_patient_info(
        hospital: &mut Hospital,
        name: String,
        age: u64,
        address: String,
        medicalHistory: String,
        ctx: &mut TxContext
    ) : Patient {
        authorize(hospital, ctx);
        let id = object::new(ctx);
        let patient = Patient {
            id,
            name,
            age,
            address,
            principal: tx_context::sender(ctx),
            medicalHistory, // Should be encrypted or stored off-chain in real-world scenarios
        };
        table::add(&mut hospital.patients, object::uid_to_inner(&patient.id), patient);
        event::emit_event(AddPatient {
            hospital_id: object::uid_to_inner(&hospital.id),
            patient_id: object::uid_to_inner(&patient.id),
        });
        patient
    }

    public fun update_patient_info(
        patient: &mut Patient,
        name: String,
        age: u64,
        address: String,
        medicalHistory: String,
        ctx: &mut TxContext
    ) {
        authorize_staff(patient, ctx); // Assuming staff roles include doctors with relevant permissions
        patient.name = name;
        patient.age = age;
        patient.address = address;
        patient.medicalHistory = medicalHistory; // Should be encrypted or stored off-chain in real-world scenarios
    }

    public fun discharge_patient(
        hospital: &mut Hospital,
        patient_id: ID,
        ctx: &mut TxContext
    ) {
        authorize(hospital, ctx);
        let patient = table::remove(&mut hospital.patients, patient_id);
        object::delete(patient.id);
    }

    // Appointment methods

    public fun add_appointment_info(
        hospital: &mut Hospital,
        patient: &mut Patient,
        doctor: &mut Staff,
        date: String,
        time: String,
        description: String,
        ctx: &mut TxContext
    ) {
        authorize(hospital, ctx);
        let id = object::new(ctx);
        let appointment = Appointment {
            id,
            patient: patient.principal,
            doctor: doctor.principal,
            date,
            time,
            description,
        };
        table::add(&mut hospital.appointments, object::uid_to_inner(&appointment.id), appointment);
        event::emit_event(AddAppointment {
            hospital_id: object::uid_to_inner(&hospital.id),
            appointment_id: object::uid_to_inner(&appointment.id),
        });
    }

    public fun cancel_appointment(
        hospital: &mut Hospital,
        appointment_id: ID,
        ctx: &mut TxContext
    ) {
        authorize(hospital, ctx);
        let appointment = table::remove(&mut hospital.appointments, appointment_id);
        event::emit_event(CancelAppointment {
            hospital_id: object::uid_to_inner(&hospital.id),
            appointment_id: appointment_id,
        });
        object::delete(appointment.id);
    }

    // Inventory methods

    public fun add_inventory_item(
        hospital: &mut Hospital,
        name: String,
        quantity: u64,
        unit_price: u64,
        ctx: &mut TxContext
    ) {
        authorize(hospital, ctx);
        assert!(quantity > 0, EInvalidQuantity);
        let id = object::new(ctx);
        let total_cost = quantity * unit_price;
        let item = InventoryItem {
            id,
            name,
            quantity,
            unit_price,
            total_cost,
        };
        table::add(&mut hospital.inventory, object::uid_to_inner(&item.id), item);
        event::emit_event(AddInventoryItem {
            hospital_id: object::uid_to_inner(&hospital.id),
            item_id: object::uid_to_inner(&item.id),
        });
    }

    public fun update_inventory_item(
        hospital: &mut Hospital,
        item_id: ID,
        name: String,
        quantity: u64,
        unit_price: u64,
        ctx: &mut TxContext
   
    ) {
        authorize(hospital, ctx);
        assert!(quantity > 0, EInvalidQuantity);
        let mut item = table::borrow_mut(&mut hospital.inventory, item_id);
        item.name = name;
        item.quantity = quantity;
        item.unit_price = unit_price;
        item.total_cost = quantity * unit_price;
    }

    public fun remove_inventory_item(
        hospital: &mut Hospital,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        authorize(hospital, ctx);
        let item = table::remove(&mut hospital.inventory, item_id);
        event::emit_event(RemoveInventoryItem {
            hospital_id: object::uid_to_inner(&hospital.id),
            item_id: item_id,
        });
        object::delete(item.id);
    }

    // Role-Based Access Control (RBAC)
    struct Role has copy, drop, store {
        id: u64,
        name: String,
        permissions: vector<String>,
    }

    public fun add_role(
        hospital: &mut Hospital,
        role_name: String,
        permissions: vector<String>,
        ctx: &mut TxContext
    ) : Role {
        authorize(hospital, ctx);
        let role = Role {
            id: vector::length(&hospital.staff),
            name: role_name,
            permissions,
        };
        // Add role to a persistent storage if necessary
        role
    }

    public fun assign_role_to_staff(
        hospital: &mut Hospital,
        staff_id: ID,
        role: Role,
        ctx: &mut TxContext
    ) {
        authorize(hospital, ctx);
        let mut staff = table::borrow_mut(&mut hospital.staff, staff_id);
        // Assuming role is added to staff profile for role-based access control
        // Implement the necessary logic to associate role with staff
    }

    // Utility Function for RBAC
    fun has_permission(
        hospital: &Hospital,
        staff: &Staff,
        permission: String
    ) : bool {
        // Implement the logic to check if the staff has the required permission
        // This is a placeholder, assuming we have a way to check staff permissions
        true
    }

    public fun execute_staff_action(
        hospital: &Hospital,
        staff: &Staff,
        action: String,
        ctx: &TxContext
    ) {
        if !has_permission(hospital, staff, action) {
            assert!(false, ENotAuthorized);
        }
        // Proceed with the action if authorized
    }
}
