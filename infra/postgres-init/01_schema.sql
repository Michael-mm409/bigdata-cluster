CREATE TABLE patients (
    id TEXT PRIMARY KEY,
    birthdate DATE,
    deathdate DATE,
    ssn TEXT,
    drivers TEXT,
    passport TEXT,
    prefix TEXT,
    first TEXT,
    last TEXT,
    suffix TEXT,
    maiden TEXT,
    marital TEXT,
    race TEXT,
    ethnicity TEXT,
    gender TEXT,
    birthplace TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    county TEXT,
    zip TEXT,
    lat NUMERIC,
    lon NUMERIC,
    healthcare_expenses NUMERIC,
    healthcare_coverage NUMERIC,
    income NUMERIC
);

CREATE TABLE organizations (
    id TEXT,
    name TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    zip TEXT,
    lat NUMERIC,
    lon NUMERIC,
    phone TEXT,
    revenue NUMERIC,
    utilization INTEGER
);

CREATE TABLE payers (
    id TEXT,
    name TEXT,
    address TEXT,
    city TEXT,
    state_headquartered TEXT,
    zip TEXT,
    phone TEXT,
    amount_covered NUMERIC,
    amount_uncovered NUMERIC,
    revenue NUMERIC,
    covered_encounters INTEGER,
    uncovered_encounters INTEGER,
    covered_medications INTEGER,
    uncovered_medications INTEGER,
    covered_procedures INTEGER,
    uncovered_procedures INTEGER,
    covered_immunizations INTEGER,
    uncovered_immunizations INTEGER,
    unique_customers INTEGER,
    qols_avg NUMERIC,
    member_months INTEGER
);

CREATE TABLE providers (
    id TEXT,
    organization TEXT,
    name TEXT,
    gender TEXT,
    speciality TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    zip TEXT,
    lat NUMERIC,
    lon NUMERIC,
    utilization INTEGER
);

CREATE TABLE encounters (
    id TEXT PRIMARY KEY,
    start TIMESTAMPTZ,
    stop TIMESTAMPTZ,
    patient TEXT,
    organization TEXT,
    provider TEXT,
    payer TEXT,
    encounterclass TEXT,
    code TEXT,
    description TEXT,
    base_encounter_cost NUMERIC,
    total_claim_cost NUMERIC,
    payer_coverage NUMERIC,
    reasoncode TEXT,
    reasondescription TEXT
);

CREATE TABLE conditions (
    start DATE,
    stop DATE,
    patient TEXT,
    encounter TEXT,
    code TEXT,
    description TEXT
);

CREATE TABLE medications (
    start TIMESTAMPTZ,
    stop TIMESTAMPTZ,
    patient TEXT,
    payer TEXT,
    encounter TEXT,
    code TEXT,
    description TEXT,
    base_cost NUMERIC,
    payer_coverage NUMERIC,
    dispenses INTEGER,
    totalcost NUMERIC,
    reasoncode TEXT,
    reasondescription TEXT
);

CREATE TABLE procedures (
    start TIMESTAMPTZ,
    stop TIMESTAMPTZ,
    patient TEXT,
    encounter TEXT,
    code TEXT,
    description TEXT,
    base_cost NUMERIC,
    reasoncode TEXT,
    reasondescription TEXT
);

CREATE TABLE immunizations (
    date TIMESTAMPTZ,
    patient TEXT,
    encounter TEXT,
    code TEXT,
    description TEXT,
    base_cost NUMERIC
);

CREATE TABLE careplans (
    id TEXT,
    start DATE,
    stop DATE,
    patient TEXT,
    encounter TEXT,
    code TEXT,
    description TEXT,
    reasoncode TEXT,
    reasondescription TEXT
);

CREATE TABLE allergies (
    start DATE,
    stop DATE,
    patient TEXT,
    encounter TEXT,
    code TEXT,
    system TEXT,
    description TEXT,
    type TEXT,
    category TEXT,
    reaction1 TEXT,
    description1 TEXT,
    severity1 TEXT,
    reaction2 TEXT,
    description2 TEXT,
    severity2 TEXT
);

CREATE TABLE devices (
    start TIMESTAMPTZ,
    stop TIMESTAMPTZ,
    patient TEXT,
    encounter TEXT,
    code TEXT,
    description TEXT,
    udi TEXT
);

CREATE TABLE imaging_studies (
    id TEXT,
    date TIMESTAMPTZ,
    patient TEXT,
    encounter TEXT,
    series_uid TEXT,
    bodysite_code TEXT,
    bodysite_description TEXT,
    modality_code TEXT,
    modality_description TEXT,
    instance_uid TEXT,
    sop_code TEXT,
    sop_description TEXT,
    procedure_code TEXT
);

CREATE TABLE supplies (
    date TIMESTAMPTZ,
    patient TEXT,
    encounter TEXT,
    code TEXT,
    description TEXT,
    quantity INTEGER
);

CREATE TABLE payer_transitions (
    patient TEXT,
    memberid TEXT,
    start_year TIMESTAMPTZ,
    end_year TIMESTAMPTZ,
    payer TEXT,
    secondary_payer TEXT,
    ownership TEXT,
    ownername TEXT
);

CREATE INDEX ON encounters (patient);
CREATE INDEX ON encounters (provider);
CREATE INDEX ON conditions (patient);
CREATE INDEX ON conditions (encounter);
CREATE INDEX ON medications (patient);
CREATE INDEX ON medications (encounter);
CREATE INDEX ON procedures (patient);
CREATE INDEX ON procedures (encounter);
CREATE INDEX ON immunizations (patient);
CREATE INDEX ON careplans (patient);
CREATE INDEX ON allergies (patient);

CREATE TABLE claims (
    id TEXT,
    patientid TEXT,
    providerid TEXT,
    primarypatientinsuranceid TEXT,
    secondarypatientinsuranceid TEXT,
    departmentid TEXT,
    patientdepartmentid TEXT,
    diagnosis1 TEXT,
    diagnosis2 TEXT,
    diagnosis3 TEXT,
    diagnosis4 TEXT,
    diagnosis5 TEXT,
    diagnosis6 TEXT,
    diagnosis7 TEXT,
    diagnosis8 TEXT,
    referringproviderid TEXT,
    appointmentid TEXT,
    currentillnessdate DATE,
    servicedate DATE,
    supervisingproviderid TEXT,
    status1 TEXT,
    status2 TEXT,
    statusp TEXT,
    outstanding1 NUMERIC,
    outstanding2 NUMERIC,
    outstandingp NUMERIC,
    lastbilleddate1 DATE,
    lastbilleddate2 DATE,
    lastbilleddatep DATE,
    healthcareclaimtypeid1 INTEGER,
    healthcareclaimtypeid2 INTEGER
);
