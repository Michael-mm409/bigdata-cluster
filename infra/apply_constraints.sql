-- Finish applying constraints to the existing csc6002 database.
-- Safe to re-run — each block skips gracefully if the constraint already exists.
--
-- Usage:
--   docker exec -i course-postgres psql -U postgres -d csc6002 < infra/apply_constraints.sql

-- Step 1: Deduplicate organizations (CSV contains duplicate rows)
DELETE FROM organizations
WHERE ctid NOT IN (
    SELECT MIN(ctid) FROM organizations GROUP BY id
);

-- Step 2: Add organizations PK (was blocked by duplicates above)
DO $$ BEGIN
    ALTER TABLE organizations ADD PRIMARY KEY (id);
EXCEPTION WHEN others THEN
    RAISE NOTICE 'organizations PK already exists, skipping';
END $$;

-- Step 3: FK from providers.organization — depends on organizations PK
DO $$ BEGIN
    ALTER TABLE providers ADD CONSTRAINT fk_providers_organization
        FOREIGN KEY (organization) REFERENCES organizations(id);
EXCEPTION WHEN duplicate_object THEN
    RAISE NOTICE 'fk_providers_organization already exists, skipping';
END $$;

-- Step 4: FK from encounters.organization — depends on organizations PK
DO $$ BEGIN
    ALTER TABLE encounters ADD CONSTRAINT fk_encounters_organization
        FOREIGN KEY (organization) REFERENCES organizations(id);
EXCEPTION WHEN duplicate_object THEN
    RAISE NOTICE 'fk_encounters_organization already exists, skipping';
END $$;

-- Step 5: Null out Synthea sentinel '0' values before constraining claims insurance columns
UPDATE claims SET primarypatientinsuranceid   = NULL WHERE primarypatientinsuranceid   = '0';
UPDATE claims SET secondarypatientinsuranceid = NULL WHERE secondarypatientinsuranceid = '0';

-- Step 6: FK on claims insurance columns (were blocked by the '0' sentinel)
DO $$ BEGIN
    ALTER TABLE claims ADD CONSTRAINT fk_claims_primary_payer
        FOREIGN KEY (primarypatientinsuranceid) REFERENCES payers(id);
EXCEPTION WHEN duplicate_object THEN
    RAISE NOTICE 'fk_claims_primary_payer already exists, skipping';
END $$;

DO $$ BEGIN
    ALTER TABLE claims ADD CONSTRAINT fk_claims_secondary_payer
        FOREIGN KEY (secondarypatientinsuranceid) REFERENCES payers(id);
EXCEPTION WHEN duplicate_object THEN
    RAISE NOTICE 'fk_claims_secondary_payer already exists, skipping';
END $$;
