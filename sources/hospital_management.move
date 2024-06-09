module hospital_management::hospital_management {
    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Coin};
    use sui::object::{UID};
    use sui::balance::{Balance};
    use sui::tx_context::{TxContext};
    use sui::table::{Table};
    use sui::address::address;

    // Errors
    const EInsufficientBalance: u64 = 1;
    const ENotAuthorized: u64 = 6;
    const EInvalidData: u64 = 7;
    const EHospitalExists: u64 = 8;
    const EOverflow: u64 = 9;
    const EDataStorage: u64 = 10;

    // Structs
    struct Hospital has key, store {
        id: UID,
        name: String,
        address: String,
        balance: Balance<SUI>,
        staff: Table<UID, Staff>,
        patients: Table<UID, Patient>,
        appointments: Table<UID, Appointment>,
        inventory: Table<UID, InventoryItem>,
        principal: address,
    }

    struct HospitalCap has key {
        id: UID,
        for: UID,
    }

    struct Staff has key, store {
        id: UID,
        name: String,
        role: String,
        principal: address,
        balance: Balance<SUI>,
        department: String,
        hire_date: String,
    }

    struct Patient has key, store {
        id: UID,
        name: String,
        age: u64,
        address: String,
        principal: address,
        medical_history_ref: String, // Reference to encrypted off-chain data
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

    // Validation functions
    public fun validate_string(input: String) {
        assert!(!input.is_empty(), EInvalidData);
    }

    public fun validate_u64(input: u64) {
        assert!(input > 0, EInvalidData);
    }

    public fun validate_no_overflow(value: u64, increment: u64) {
        assert!(value.checked_add(increment).is_some(), EOverflow);
    }

    // Hospital methods
    public fun add_hospital_info(
        name: String,
        address: String,
        ctx: &mut TxContext
    ) : HospitalCap {
        let principal = tx_context::sender(ctx);
        assert!(!hospital_exists(principal), EHospitalExists);

        validate_string(name);
        validate_string(address);

        let id = object::new(ctx);
        let hospital = Hospital {
            id,
            name,
            address,
            balance: balance::zero<SUI>(),
            principal,
            staff: table::new<UID, Staff>(ctx),
            patients: table::new<UID, Patient>(ctx),
            appointments: table::new<UID, Appointment>(ctx),
            inventory: table::new<UID, InventoryItem>(ctx),
        };
        transfer::share_object(&hospital);

        HospitalCap {
            id: object::new(ctx),
            for: id,
        }
    }

    public fun deposit(
        hospital: &mut Hospital,
        amount: Coin<SUI>,
    ) {
        assert!(hospital.principal == tx_context::sender(ctx), ENotAuthorized);

        let coin = coin::into_balance(amount);
        balance::join(&mut hospital.balance, coin);
    }

    // Staff methods
    public fun add_staff_info(
        hospital: &mut Hospital,
        name: String,
        role: String,
        department: String,
        hire_date: String,
        ctx: &mut TxContext
    ) : Staff {
        assert!(hospital.principal == tx_context::sender(ctx), ENotAuthorized);

        validate_string(name);
        validate_string(role);
        validate_string(department);
        validate_string(hire_date);

        let id = object::new(ctx);
        let staff = Staff {
            id,
            name,
            role,
            principal: tx_context::sender(ctx),
            balance: balance::zero<SUI>(),
            department,
            hire_date,
        };
        table::add<UID, Staff>(&mut hospital.staff, id, staff);
        staff
    }

    public fun update_staff_info(
        staff: &mut Staff,
        name: String,
        role: String,
        department: String,
        hire_date: String,
        ctx: &mut TxContext
    ) {
        assert!(staff.principal == tx_context::sender(ctx), ENotAuthorized);

        validate_string(name);
        validate_string(role);
        validate_string(department);
        validate_string(hire_date);

        staff.name = name;
        staff.role = role;
        staff.department = department;
        staff.hire_date = hire_date;
    }

    public fun pay_staff(
        hospital: &mut Hospital,
        staff: &mut Staff,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(hospital.principal == tx_context::sender(ctx), ENotAuthorized);
        assert!(balance::value(&hospital.balance) >= amount, EInsufficientBalance);
        validate_u64(amount);

        let payment = coin::split(&mut hospital.balance, amount, ctx);
        balance::join(&mut staff.balance, payment);
    }

    // Patient methods
    public fun add_patient_info(
        hospital: &mut Hospital,
        name: String,
        age: u64,
        address: String,
        medical_history_ref: String,
        ctx: &mut TxContext
    ) : Patient {
        assert!(hospital.principal == tx_context::sender(ctx), ENotAuthorized);

        validate_string(name);
        validate_u64(age);
        validate_string(address);
        validate_string(medical_history_ref);

        let id = object::new(ctx);
        let patient = Patient {
            id,
            name,
            age,
            address,
            principal: tx_context::sender(ctx),
            medical_history_ref,
        };
        table::add<UID, Patient>(&mut hospital.patients, id, patient);
        patient
    }

    public fun update_patient_info(
        patient: &mut Patient,
        name: String,
        age: u64,
        address: String,
        medical_history_ref: String,
        ctx: &mut TxContext
    ) {
        assert!(patient.principal == tx_context::sender(ctx), ENotAuthorized);

        validate_string(name);
        validate_u64(age);
        validate_string(address);
        validate_string(medical_history_ref);

        patient.name = name;
        patient.age = age;
        patient.address = address;
        patient.medical_history_ref = medical_history_ref;
    }

    // Appointment methods
    public fun add_appointment_info(
        hospital: &mut Hospital,
        patient: &Patient,
        doctor: &Staff,
        date: String,
        time: String,
        description: String,
        ctx: &mut TxContext
    ) {
        assert!(hospital.principal == tx_context::sender(ctx), ENotAuthorized);

        validate_string(date);
        validate_string(time);
        validate_string(description);

        let id = object::new(ctx);
        let appointment = Appointment {
            id,
            patient: patient.principal,
            doctor: doctor.principal,
            date,
            time,
            description,
        };

        table::add<UID, Appointment>(&mut hospital.appointments, id, appointment);
    }

    public fun cancel_appointment(
        hospital: &mut Hospital,
        appointment_id: UID,
        ctx: &mut TxContext
    ) {
        assert!(hospital.principal == tx_context::sender(ctx), ENotAuthorized);

        let appointment = table::remove(&mut hospital.appointments, appointment_id);
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
        assert!(hospital.principal == tx_context::sender(ctx), ENotAuthorized);

        validate_string(name);
        validate_u64(quantity);
        validate_u64(unit_price);
        validate_no_overflow(quantity, unit_price);

        let id = object::new(ctx);
        let item = InventoryItem {
            id,
            name,
            quantity,
            unit_price,
        };

        table::add<UID, InventoryItem>(&mut hospital.inventory, id, item);
    }

    public fun update_inventory_item(
        hospital: &mut Hospital,
        item_id: UID,
        name: String,
        quantity: u64,
        unit_price: u64,
        ctx: &mut TxContext
    ) {
        assert!(hospital.principal == tx_context::sender(ctx), ENotAuthorized);

        validate_string(name);
        validate_u64(quantity);
        validate_u64(unit_price);
        validate_no_overflow(quantity, unit_price);

        let item = table::borrow_mut(&mut hospital.inventory, item_id);
        item.name = name;
        item.quantity = quantity;
        item.unit_price = unit_price;
    }

    public fun remove_inventory_item(
        hospital: &mut Hospital,
        item_id: UID,
        ctx: &mut TxContext
    ) {
        assert!(hospital.principal == tx_context::sender(ctx), ENotAuthorized);

        let item = table::remove(&mut hospital.inventory, item_id);
        object::delete(item.id);
    }

    // Handle hospital expenses
    public fun pay_expense(
        hospital: &mut Hospital
        amount: u64,
        ctx: &mut TxContext
    ) : Coin<SUI> {
        assert!(hospital.principal == tx_context::sender(ctx), ENotAuthorized);
        assert!(balance::value(&hospital.balance) >= amount, EInsufficientBalance);
        validate_u64(amount);

        let payment = coin::split(&mut hospital.balance, amount, ctx);
        payment
    }

    // Patient discharge
    public fun discharge_patient(
        hospital: &mut Hospital,
        patient_id: UID,
        ctx: &mut TxContext
    ) {
        assert!(hospital.principal == tx_context::sender(ctx), ENotAuthorized);

        let patient = table::remove(&mut hospital.patients, patient_id);
        object::delete(patient.id);
    }

    // Helper function to check if a hospital exists for a principal
    public fun hospital_exists(principal: address): bool {
        // This function should check the existence of a hospital for the given principal.
        // The actual implementation will depend on how hospitals are indexed in your system.
        // Assuming there is a global table indexing hospitals by their principal address.
        // Replace this logic with the actual index checking in your system.
        
        let global_hospitals: Table<address, Hospital> = ...; // Define or obtain this table from the context
        global_hospitals.contains_key(&principal)
    }
}
