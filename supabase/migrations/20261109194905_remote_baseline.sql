


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_vuelta_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
    new.updated_at = now();
    return new;
end;
$$;


ALTER FUNCTION "public"."set_vuelta_updated_at"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."chisme_active" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "contact_id" "uuid",
    "burner_position" integer DEFAULT 4,
    "active_reason" "text",
    "active_owner" "text" DEFAULT 'Daniel'::"text",
    "next_followup_date" "date",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."chisme_active" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."zz_archive_chisme_communication_queue" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "queue_date" "date" DEFAULT CURRENT_DATE,
    "contact_id" bigint,
    "bucket" "text" NOT NULL,
    "reason" "text" NOT NULL,
    "script_hint" "text",
    "priority" integer DEFAULT 50,
    "status" "text" DEFAULT 'queued'::"text",
    "completed_at" timestamp with time zone,
    "outcome" "text",
    "notes" "text",
    "assigned_to" "text"
);


ALTER TABLE "public"."zz_archive_chisme_communication_queue" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."chisme_communication_queue_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."chisme_communication_queue_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."chisme_communication_queue_id_seq" OWNED BY "public"."zz_archive_chisme_communication_queue"."id";



CREATE TABLE IF NOT EXISTS "public"."chisme_contacts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "phone" "text",
    "email" "text",
    "address" "text",
    "source" "text" DEFAULT 'chismebot'::"text",
    "status" "text" DEFAULT 'lead'::"text",
    "hotlist_temperature" integer DEFAULT 50,
    "hotlist_stage" "text" DEFAULT 'New Lead'::"text",
    "next_action" "text" DEFAULT 'Contact customer / schedule site visit'::"text",
    "chisme_summary" "text",
    "last_contact_date" "date",
    "last_outcome" "text",
    "next_contact_date" "date",
    "next_followup_date" "date",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "hcp_customer_id" "text",
    "first_name" "text",
    "last_name" "text",
    "mobile_number" "text",
    "home_number" "text",
    "work_number" "text",
    "company" "text",
    "role" "text",
    "tags" "text",
    "notes" "text",
    "customer_type" "text",
    "lead_source" "text",
    "customer_created_at" timestamp with time zone,
    "last_service_date" timestamp with time zone,
    "lifetime_value" numeric,
    "city" "text",
    "state" "text",
    "postal_code" "text",
    "source_system" "text",
    "do_not_service" boolean,
    "customer_flag" "text",
    "do_not_pursue" boolean DEFAULT false,
    "baseline_temperature" integer DEFAULT 0,
    "pipeline_stage" "text"
);


ALTER TABLE "public"."chisme_contacts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."chisme_contacts_zero_value_backup" (
    "id" "uuid",
    "name" "text",
    "phone" "text",
    "email" "text",
    "address" "text",
    "source" "text",
    "status" "text",
    "hotlist_temperature" integer,
    "hotlist_stage" "text",
    "next_action" "text",
    "chisme_summary" "text",
    "last_contact_date" "date",
    "last_outcome" "text",
    "next_contact_date" "date",
    "next_followup_date" "date",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "hcp_customer_id" "text",
    "first_name" "text",
    "last_name" "text",
    "mobile_number" "text",
    "home_number" "text",
    "work_number" "text",
    "company" "text",
    "role" "text",
    "tags" "text",
    "notes" "text",
    "customer_type" "text",
    "lead_source" "text",
    "customer_created_at" timestamp with time zone,
    "last_service_date" timestamp with time zone,
    "lifetime_value" numeric,
    "city" "text",
    "state" "text",
    "postal_code" "text",
    "source_system" "text",
    "do_not_service" boolean,
    "customer_flag" "text",
    "do_not_pursue" boolean,
    "baseline_temperature" integer
);


ALTER TABLE "public"."chisme_contacts_zero_value_backup" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."chisme_dashboard_contacts" AS
 SELECT "id",
    "name",
    "hotlist_temperature",
    "phone",
    "email",
    "address",
    "do_not_pursue",
    "next_action",
    "last_outcome",
    "chisme_summary",
    "next_followup_date",
    "next_contact_date",
    "lifetime_value",
    "last_service_date",
    "notes",
    "pipeline_stage"
   FROM "public"."chisme_contacts";


ALTER VIEW "public"."chisme_dashboard_contacts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."chisme_interactions" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "contact_id" bigint,
    "interaction_date" "date" DEFAULT CURRENT_DATE,
    "interaction_type" "text",
    "notes" "text",
    "outcome" "text",
    "next_action" "text",
    "next_contact_date" "date",
    "created_by" "text",
    "touch_counts_for_today" boolean DEFAULT true,
    "next_followup_date" "date"
);


ALTER TABLE "public"."chisme_interactions" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."chisme_interactions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."chisme_interactions_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."chisme_interactions_id_seq" OWNED BY "public"."chisme_interactions"."id";



CREATE TABLE IF NOT EXISTS "public"."chisme_journals" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "contact_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "journal_type" "text" DEFAULT 'memory'::"text",
    "title" "text",
    "entry" "text",
    "mood" "text",
    "temperature_before" integer,
    "temperature_after" integer,
    "created_by" "text"
);


ALTER TABLE "public"."chisme_journals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."chisme_leads" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "raw_notes" "text",
    "captured_at" timestamp with time zone DEFAULT "now"(),
    "captured_by" "text",
    "contact_channel" "text",
    "lead_source" "text",
    "source_detail" "text",
    "referrer" "text",
    "contact_id" "uuid",
    "status" "text" DEFAULT 'unprocessed'::"text",
    "next_action" "text",
    "callback_date" "date",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."chisme_leads" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."chisme_load_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_date" "date" NOT NULL,
    "event_type" "text" NOT NULL,
    "contact_id" "uuid",
    "contact_name" "text",
    "description" "text",
    "created_by" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."chisme_load_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."chisme_notes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "journal_id" "uuid",
    "contact_id" "uuid",
    "note_date" "date" DEFAULT CURRENT_DATE,
    "note_type" "text" DEFAULT 'chisme'::"text",
    "note_text" "text" NOT NULL,
    "created_by" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."chisme_notes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."chisme_opportunities" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "lead_id" "uuid",
    "contact_id" "uuid",
    "opportunity_name" "text" NOT NULL,
    "scope_notes" "text",
    "service_address" "text",
    "pipeline_stage" "text" DEFAULT 'New Opportunity'::"text",
    "temperature" integer DEFAULT 50,
    "next_action" "text",
    "callback_date" "date",
    "estimated_value" numeric(12,2),
    "probability" numeric(5,2),
    "status" "text" DEFAULT 'open'::"text",
    "outcome" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "chisme_opportunities_probability_check" CHECK ((("probability" IS NULL) OR (("probability" >= (0)::numeric) AND ("probability" <= (1)::numeric)))),
    CONSTRAINT "chisme_opportunities_temperature_check" CHECK ((("temperature" >= 0) AND ("temperature" <= 100)))
);


ALTER TABLE "public"."chisme_opportunities" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cholo_build_steps" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "template_id" "uuid" NOT NULL,
    "step_key" "text" NOT NULL,
    "sequence" integer NOT NULL,
    "phase" "text" NOT NULL,
    "task_name" "text" NOT NULL,
    "manual_page" "text",
    "dependency_key" "text",
    "notes" "text",
    "required" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."cholo_build_steps" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cholo_build_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "template_key" "text" NOT NULL,
    "title" "text" NOT NULL,
    "manufacturer" "text",
    "model" "text",
    "manual_code" "text",
    "manual_revision" "date",
    "source_filename" "text",
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."cholo_build_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cholo_job_builds" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "text",
    "job_key" "text" NOT NULL,
    "customer_label" "text" NOT NULL,
    "job_title" "text" NOT NULL,
    "template_id" "uuid",
    "planned_start" "date",
    "site_status" "text" DEFAULT 'takeover_review'::"text" NOT NULL,
    "floor_level_verified" boolean DEFAULT false NOT NULL,
    "floor_square_verified" boolean DEFAULT false NOT NULL,
    "support_anchor_verified" boolean DEFAULT false NOT NULL,
    "door_configuration" "text",
    "takeover_notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "cholo_job_builds_door_configuration_check" CHECK ((("door_configuration" = ANY (ARRAY['gable'::"text", 'eave_offset_left'::"text", 'eave_centered'::"text"])) OR ("door_configuration" IS NULL)))
);


ALTER TABLE "public"."cholo_job_builds" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cholo_job_equipment" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "job_id" "uuid" NOT NULL,
    "item_label" "text" NOT NULL,
    "quantity" integer DEFAULT 1 NOT NULL,
    "owner_label" "text",
    "condition" "text" DEFAULT 'unverified'::"text" NOT NULL,
    "loaded" boolean DEFAULT false NOT NULL,
    "checked_out_by" "text",
    "returned" boolean DEFAULT false NOT NULL,
    "notes" "text",
    CONSTRAINT "cholo_job_equipment_quantity_check" CHECK (("quantity" > 0))
);


ALTER TABLE "public"."cholo_job_equipment" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cholo_job_observations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "job_id" "uuid" NOT NULL,
    "category" "text" NOT NULL,
    "summary" "text" NOT NULL,
    "evidence_url" "text",
    "reported_by" "text",
    "recorded_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "cholo_job_observations_category_check" CHECK (("category" = ANY (ARRAY['takeover'::"text", 'inspection'::"text", 'photo'::"text", 'material'::"text", 'safety'::"text", 'change_order'::"text", 'closeout'::"text"])))
);


ALTER TABLE "public"."cholo_job_observations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cholo_job_steps" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "job_id" "uuid" NOT NULL,
    "template_step_id" "uuid",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "assigned_to" "text",
    "planned_for" "date",
    "started_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "actual_minutes" integer,
    "blocker" "text",
    "notes" "text",
    CONSTRAINT "cholo_job_steps_actual_minutes_check" CHECK (("actual_minutes" >= 0)),
    CONSTRAINT "cholo_job_steps_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'ready'::"text", 'in_progress'::"text", 'blocked'::"text", 'completed'::"text", 'not_applicable'::"text"])))
);


ALTER TABLE "public"."cholo_job_steps" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cholobots_visitors" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text",
    "email" "text",
    "phone" "text",
    "company" "text",
    "role" "text",
    "how_they_met_heaven" "text",
    "interests" "text"[],
    "work_type" "text",
    "problem_they_described" "text",
    "discord_user" boolean,
    "follow_up_ok" boolean DEFAULT false,
    "follow_up_method" "text",
    "conversation" "text",
    "cholo_summary" "text",
    "follow_up_notes" "text",
    "status" "text" DEFAULT 'new'::"text" NOT NULL
);


ALTER TABLE "public"."cholobots_visitors" OWNER TO "postgres";


ALTER TABLE "public"."cholobots_visitors" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."cholobots_visitors_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."companies" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."companies" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."company_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "company_id" "uuid",
    "user_id" "uuid",
    "role" "text" DEFAULT 'member'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."company_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."crudo_labor_entries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "task_id" "uuid",
    "worker" "text" NOT NULL,
    "started_at" timestamp with time zone,
    "ended_at" timestamp with time zone,
    "actual_minutes" integer,
    "source" "text" DEFAULT 'metiche'::"text",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."crudo_labor_entries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."crudo_material_transaction_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "transaction_id" "uuid" NOT NULL,
    "project_id" "uuid" NOT NULL,
    "project_material_id" "uuid",
    "sku" "text",
    "item_name" "text" NOT NULL,
    "quantity" numeric(12,2),
    "unit" "text",
    "unit_price" numeric(12,2),
    "line_total" numeric(12,2),
    "category" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."crudo_material_transaction_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."crudo_material_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "transaction_type" "text" NOT NULL,
    "vendor" "text",
    "transaction_date" "date",
    "receipt_number" "text",
    "subtotal" numeric(12,2),
    "tax" numeric(12,2),
    "total" numeric(12,2),
    "source" "text" DEFAULT 'receipt_scan'::"text",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "crudo_material_transactions_transaction_type_check" CHECK (("transaction_type" = ANY (ARRAY['purchase'::"text", 'return'::"text"])))
);


ALTER TABLE "public"."crudo_material_transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."crudo_project_materials" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "item_name" "text" NOT NULL,
    "estimated_quantity" numeric(12,2),
    "estimated_unit" "text",
    "estimated_unit_cost" numeric(12,2),
    "estimated_total" numeric(12,2),
    "actual_quantity" numeric(12,2),
    "actual_unit" "text",
    "outcome" "text" DEFAULT 'pending'::"text" NOT NULL,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "crudo_project_materials_outcome_check" CHECK (("outcome" = ANY (ARRAY['pending'::"text", 'purchased'::"text", 'on_hand'::"text", 'not_needed'::"text", 'unplanned'::"text"])))
);


ALTER TABLE "public"."crudo_project_materials" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."crudo_project_tasks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "task_name" "text" NOT NULL,
    "task_order" integer,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "completed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "estimated_minutes" integer,
    "actual_minutes" integer
);


ALTER TABLE "public"."crudo_project_tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."crudo_projects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "contact_id" "uuid" NOT NULL,
    "opportunity_id" "uuid",
    "project_name" "text" NOT NULL,
    "scope_notes" "text",
    "service_address" "text",
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "owner" "text",
    "oven_position" integer,
    "contract_amount" numeric(12,2),
    "estimated_labor" numeric(12,2),
    "estimated_materials" numeric(12,2),
    "approved_at" timestamp with time zone,
    "started_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "closeout_status" "text" DEFAULT 'open'::"text" NOT NULL,
    "invoice_amount" numeric(12,2),
    "invoice_sent_at" timestamp with time zone,
    "amount_collected" numeric(12,2),
    "paid_at" timestamp with time zone,
    "customer_followup_at" timestamp with time zone,
    "customer_followup_notes" "text",
    "closeout_notes" "text",
    CONSTRAINT "crudo_projects_closeout_status_check" CHECK (("closeout_status" = ANY (ARRAY['open'::"text", 'ready'::"text", 'invoice_sent'::"text", 'payment_pending'::"text", 'paid'::"text", 'completed'::"text"]))),
    CONSTRAINT "crudo_projects_oven_position_check" CHECK ((("oven_position" >= 1) AND ("oven_position" <= 4)))
);


ALTER TABLE "public"."crudo_projects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."crudobot_jobs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_slug" "text" NOT NULL,
    "project_name" "text" NOT NULL,
    "quest_id" "text",
    "original_bid" numeric(12,2) DEFAULT 0 NOT NULL,
    "final_invoice" numeric(12,2),
    "amount_collected" numeric(12,2),
    "other_direct_costs" numeric(12,2) DEFAULT 0 NOT NULL,
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "closeout_notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."crudobot_jobs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."daily_tasks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "text" DEFAULT ''::"text" NOT NULL,
    "calendar_key" "text" DEFAULT ''::"text" NOT NULL,
    "date" "date" NOT NULL,
    "task" "text" DEFAULT ''::"text" NOT NULL,
    "completed" boolean DEFAULT false NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"() NOT NULL,
    "company_id" "uuid"
);


ALTER TABLE "public"."daily_tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."garage_zones" (
    "cell" "text" NOT NULL,
    "zone_name" "text" NOT NULL,
    "updated_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."garage_zones" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."guard_job_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "transaction_id" "uuid" NOT NULL,
    "project_name" "text" NOT NULL,
    "vendor" "text" NOT NULL,
    "line_type" "text" DEFAULT 'purchase'::"text" NOT NULL,
    "sku" "text",
    "description" "text" NOT NULL,
    "quantity" numeric(12,3) DEFAULT 1 NOT NULL,
    "unit" "text",
    "unit_price" numeric(12,2) DEFAULT 0 NOT NULL,
    "line_total" numeric(12,2) DEFAULT 0 NOT NULL,
    "category" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "guard_job_items_line_type_check" CHECK (("line_type" = ANY (ARRAY['purchase'::"text", 'return'::"text", 'use'::"text"])))
);


ALTER TABLE "public"."guard_job_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."guard_job_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_name" "text" NOT NULL,
    "vendor" "text" DEFAULT 'Unknown vendor'::"text" NOT NULL,
    "transaction_type" "text" DEFAULT 'purchase'::"text" NOT NULL,
    "transaction_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "subtotal" numeric(12,2) DEFAULT 0 NOT NULL,
    "tax" numeric(12,2) DEFAULT 0 NOT NULL,
    "total" numeric(12,2) NOT NULL,
    "receipt_number" "text",
    "verification_status" "text" DEFAULT 'verified'::"text" NOT NULL,
    "notes" "text",
    "created_by" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "source_filename" "text",
    "source_attachment_url" "text",
    "source_file_sha256" "text",
    "parser_model" "text",
    "raw_parser_json" "jsonb",
    CONSTRAINT "guard_job_transactions_total_check" CHECK (("total" >= (0)::numeric)),
    CONSTRAINT "guard_job_transactions_transaction_type_check" CHECK (("transaction_type" = ANY (ARRAY['purchase'::"text", 'return'::"text", 'exchange'::"text", 'reimbursement'::"text", 'planned'::"text"])))
);


ALTER TABLE "public"."guard_job_transactions" OWNER TO "postgres";


COMMENT ON COLUMN "public"."guard_job_transactions"."raw_parser_json" IS 'User-confirmed structured receipt output retained for debugging and parser improvement.';



CREATE TABLE IF NOT EXISTS "public"."hcp_customer_export" (
    "First Name" "text",
    "Last Name" "text",
    "Display Name" "text",
    "Mobile Number" bigint,
    "Home Number" "text",
    "Email" "text",
    "Additional Emails" "text",
    "Company" "text",
    "Role" "text",
    "Work Number" "text",
    "Bills to" "text",
    "Accepts bills from" "text",
    "Tags" "text",
    "Notes" "text",
    "ID" bigint,
    "Customer Type" "text",
    "Customer notifications enabled" boolean,
    "Customer is Contractor" boolean,
    "Lead Source" "text",
    "Customer created at" timestamp with time zone,
    "Do Not Service" boolean,
    "Last service date" "text",
    "Lifetime value" "text",
    "Address_1 Street Line 1" "text",
    "Address_1 Street Line 2" "text",
    "Address_1 City" "text",
    "Address_1 State" "text",
    "Address_1 Postal Code" "text",
    "Address_1 Billing?" boolean,
    "Address_1 Notes" "text",
    "Address_2 Street Line 1" "text",
    "Address_2 Street Line 2" "text",
    "Address_2 City" "text",
    "Address_2 State" "text",
    "Address_2 Postal Code" "text",
    "Address_2 Billing?" "text",
    "Address_2 Notes" "text",
    "Address_3 Street Line 1" "text",
    "Address_3 Street Line 2" "text",
    "Address_3 City" "text",
    "Address_3 State" "text",
    "Address_3 Postal Code" "text",
    "Address_3 Billing?" "text",
    "Address_3 Notes" "text",
    "Address_4 Street Line 1" "text",
    "Address_4 Street Line 2" "text",
    "Address_4 City" "text",
    "Address_4 State" "text",
    "Address_4 Postal Code" "text",
    "Address_4 Billing?" "text",
    "Address_4 Notes" "text",
    "Address_5 Street Line 1" "text",
    "Address_5 Street Line 2" "text",
    "Address_5 City" "text",
    "Address_5 State" "text",
    "Address_5 Postal Code" "text",
    "Address_5 Billing?" "text",
    "Address_5 Notes" "text",
    "Address_6 Street Line 1" "text",
    "Address_6 Street Line 2" "text",
    "Address_6 City" "text",
    "Address_6 State" "text",
    "Address_6 Postal Code" "text",
    "Address_6 Billing?" "text",
    "Address_6 Notes" "text",
    "Address_7 Street Line 1" "text",
    "Address_7 Street Line 2" "text",
    "Address_7 City" "text",
    "Address_7 State" "text",
    "Address_7 Postal Code" "text",
    "Address_7 Billing?" "text",
    "Address_7 Notes" "text",
    "Address_8 Street Line 1" "text",
    "Address_8 Street Line 2" "text",
    "Address_8 City" "text",
    "Address_8 State" "text",
    "Address_8 Postal Code" "text",
    "Address_8 Billing?" "text",
    "Address_8 Notes" "text",
    "Address_9 Street Line 1" "text",
    "Address_9 Street Line 2" "text",
    "Address_9 City" "text",
    "Address_9 State" "text",
    "Address_9 Postal Code" "text",
    "Address_9 Billing?" "text",
    "Address_9 Notes" "text",
    "Address_10 Street Line 1" "text",
    "Address_10 Street Line 2" "text",
    "Address_10 City" "text",
    "Address_10 State" "text",
    "Address_10 Postal Code" "text",
    "Address_10 Billing?" "text",
    "Address_10 Notes" "text",
    "Address_11 Street Line 1" "text",
    "Address_11 Street Line 2" "text",
    "Address_11 City" "text",
    "Address_11 State" "text",
    "Address_11 Postal Code" "text",
    "Address_11 Billing?" "text",
    "Address_11 Notes" "text",
    "Address_12 Street Line 1" "text",
    "Address_12 Street Line 2" "text",
    "Address_12 City" "text",
    "Address_12 State" "text",
    "Address_12 Postal Code" "text",
    "Address_12 Billing?" "text",
    "Address_12 Notes" "text",
    "Address_13 Street Line 1" "text",
    "Address_13 Street Line 2" "text",
    "Address_13 City" "text",
    "Address_13 State" "text",
    "Address_13 Postal Code" "text",
    "Address_13 Billing?" "text",
    "Address_13 Notes" "text",
    "Address_14 Street Line 1" "text",
    "Address_14 Street Line 2" "text",
    "Address_14 City" "text",
    "Address_14 State" "text",
    "Address_14 Postal Code" "text",
    "Address_14 Billing?" "text",
    "Address_14 Notes" "text",
    "Address_15 Street Line 1" "text",
    "Address_15 Street Line 2" "text",
    "Address_15 City" "text",
    "Address_15 State" "text",
    "Address_15 Postal Code" "text",
    "Address_15 Billing?" "text",
    "Address_15 Notes" "text",
    "Address_16 Street Line 1" "text",
    "Address_16 Street Line 2" "text",
    "Address_16 City" "text",
    "Address_16 State" "text",
    "Address_16 Postal Code" "text",
    "Address_16 Billing?" "text",
    "Address_16 Notes" "text",
    "Address_17 Street Line 1" "text",
    "Address_17 Street Line 2" "text",
    "Address_17 City" "text",
    "Address_17 State" "text",
    "Address_17 Postal Code" "text",
    "Address_17 Billing?" "text",
    "Address_17 Notes" "text"
);


ALTER TABLE "public"."hcp_customer_export" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inventory_items" (
    "id" bigint NOT NULL,
    "item_name" "text" NOT NULL,
    "quantity" numeric DEFAULT 0,
    "unit" "text" DEFAULT ''::"text",
    "location" "text" DEFAULT ''::"text",
    "category" "text" DEFAULT ''::"text",
    "notes" "text" DEFAULT ''::"text",
    "updated_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."inventory_items" OWNER TO "postgres";


ALTER TABLE "public"."inventory_items" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."inventory_items_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."material_events" (
    "id" bigint NOT NULL,
    "event_type" "text" NOT NULL,
    "item_name" "text" NOT NULL,
    "quantity" numeric DEFAULT 0,
    "unit" "text" DEFAULT ''::"text",
    "location" "text" DEFAULT ''::"text",
    "job" "text" DEFAULT ''::"text",
    "vendor" "text" DEFAULT ''::"text",
    "cost" numeric DEFAULT 0,
    "notes" "text" DEFAULT ''::"text",
    "ts" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."material_events" OWNER TO "postgres";


ALTER TABLE "public"."material_events" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."material_events_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."metiche_goals" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp without time zone NOT NULL,
    "user_id" "text" NOT NULL,
    "channel_id" "text" NOT NULL,
    "week_of" "date" NOT NULL,
    "quarterly_goals" "jsonb" DEFAULT '[]'::"jsonb",
    "yearly_goals" "jsonb" DEFAULT '[]'::"jsonb"
);


ALTER TABLE "public"."metiche_goals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."metiche_important_items" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "person" "text",
    "discord_user" "text",
    "channel_id" "text",
    "item" "text" NOT NULL,
    "status" "text" DEFAULT 'open'::"text",
    "resolved_at" timestamp with time zone,
    "resolved_by" "text",
    "resolution_note" "text"
);


ALTER TABLE "public"."metiche_important_items" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."metiche_important_items_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."metiche_important_items_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."metiche_important_items_id_seq" OWNED BY "public"."metiche_important_items"."id";



CREATE TABLE IF NOT EXISTS "public"."metiche_ping_preferences" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "text" NOT NULL,
    "interval_minutes" integer NOT NULL,
    "is_enabled" boolean DEFAULT true,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."metiche_ping_preferences" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."metiche_ping_schedules" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "updated_at" timestamp without time zone DEFAULT "now"() NOT NULL,
    "channel_id" "text" NOT NULL,
    "user_id" "text" NOT NULL,
    "is_on" boolean DEFAULT false,
    "next_checkin" timestamp without time zone,
    "interval_hours" smallint[],
    "status" "text" DEFAULT 'active'::"text",
    "interval_minutes" integer,
    "next_ping_at" timestamp with time zone,
    "person" "text",
    "prompt" "text",
    "source" "text"
);


ALTER TABLE "public"."metiche_ping_schedules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."metiche_project_tasks" (
    "id" bigint NOT NULL,
    "contact_id" "uuid" NOT NULL,
    "project_name" "text" NOT NULL,
    "task_text" "text" NOT NULL,
    "sort_order" integer DEFAULT 0,
    "completed" boolean DEFAULT false,
    "actual_minutes" integer DEFAULT 0,
    "estimated_minutes" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."metiche_project_tasks" OWNER TO "postgres";


ALTER TABLE "public"."metiche_project_tasks" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."metiche_project_tasks_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."metiche_reprogramming_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "channel_id" "text" NOT NULL,
    "discord_user_id" "text" NOT NULL,
    "person" "text" NOT NULL,
    "statement" "text" NOT NULL,
    "reason" "text",
    "status" "text" DEFAULT 'open'::"text" NOT NULL
);


ALTER TABLE "public"."metiche_reprogramming_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."metiche_routines" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "text" DEFAULT 'NOT NULL'::"text" NOT NULL,
    "routine_name" "text" DEFAULT 'NOT NULL'::"text",
    "routine_text" "text" DEFAULT 'NOT NULL'::"text",
    "active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."metiche_routines" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."metiche_time_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "channel_id" "text" DEFAULT ''::"text" NOT NULL,
    "user_id" "text",
    "person" "text" DEFAULT ''::"text" NOT NULL,
    "date" "date",
    "task_text" "text",
    "status" "text" DEFAULT ''::"text" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"(),
    "ended_at" timestamp with time zone,
    "duration_minutes" bigint,
    "source" "text",
    "notes" "text"
);


ALTER TABLE "public"."metiche_time_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."metiche_wakeups" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "channel_id" "text" NOT NULL,
    "person" "text" DEFAULT 'Daniel'::"text" NOT NULL,
    "wake_time" timestamp without time zone NOT NULL,
    "status" "text" DEFAULT 'scheduled'::"text" NOT NULL,
    "set_by" "text",
    "sent_at" timestamp without time zone,
    "created_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."metiche_wakeups" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."metiche_weekly" (
    "id" bigint NOT NULL,
    "ts" "text" NOT NULL,
    "discord_user" "text",
    "channel_id" "text",
    "week_of" "date" NOT NULL,
    "weekly_goal" numeric,
    "jobs_json" "jsonb" DEFAULT '[]'::"jsonb",
    "pending_estimates_json" "jsonb" DEFAULT '[]'::"jsonb",
    "invoices_to_send_json" "jsonb" DEFAULT '[]'::"jsonb",
    "calendar_json" "jsonb" DEFAULT '{}'::"jsonb",
    "task_summary_json" "jsonb" DEFAULT '{}'::"jsonb",
    "quarterly_goals_json" "jsonb" DEFAULT '[]'::"jsonb",
    "yearly_goals_json" "jsonb" DEFAULT '[]'::"jsonb",
    "wants_accountant" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."metiche_weekly" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."metiche_weekly_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."metiche_weekly_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."metiche_weekly_id_seq" OWNED BY "public"."metiche_weekly"."id";



CREATE TABLE IF NOT EXISTS "public"."metiche_weekly_plans" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"() NOT NULL,
    "user_id" "text" NOT NULL,
    "channel_id" "text" NOT NULL,
    "week_of" "date" NOT NULL,
    "weekly_goal" numeric DEFAULT '0'::numeric,
    "jobs" "jsonb" DEFAULT '[]'::"jsonb",
    "invoices_to_send" "jsonb" DEFAULT '[]'::"jsonb",
    "updated_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."metiche_weekly_plans" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."obijuan_owner_time" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "quest_id" "text" NOT NULL,
    "owner_name" "text" NOT NULL,
    "quantity" numeric(10,2) DEFAULT 0 NOT NULL,
    "unit" "text" DEFAULT 'days'::"text" NOT NULL,
    "notes" "text",
    "created_by" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."obijuan_owner_time" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."obijuan_quest_assignments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "quest_id" "text" NOT NULL,
    "worker_id" "text" NOT NULL,
    "worker_name" "text" NOT NULL,
    "accepted_price" numeric(12,2) DEFAULT 0 NOT NULL,
    "paid_amount" numeric(12,2),
    "status" "text" DEFAULT 'accepted'::"text" NOT NULL,
    "notes" "text",
    "payout_notes" "text",
    "accepted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "paid_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."obijuan_quest_assignments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."obijuan_quest_notes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "quest_id" "text" NOT NULL,
    "author_id" "text",
    "author_name" "text",
    "note_type" "text" DEFAULT 'note'::"text" NOT NULL,
    "body" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."obijuan_quest_notes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."obijuan_quest_updates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "quest_id" "text" NOT NULL,
    "author_id" "text",
    "author_name" "text",
    "body" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."obijuan_quest_updates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."obijuan_quests" (
    "quest_id" "text" NOT NULL,
    "customer_name" "text" NOT NULL,
    "title" "text" NOT NULL,
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "location" "text",
    "customer_budget" "text",
    "customer_willingness" "text",
    "job_summary" "text",
    "accepted_by_user_id" bigint,
    "accepted_by_name" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."obijuan_quests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."obijuan_timecards" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "clock_in_at" timestamp with time zone NOT NULL,
    "clock_out_at" timestamp with time zone,
    "channel_id" "text" NOT NULL,
    "discord_user_id" "text" NOT NULL,
    "person" "text",
    "customer" "text",
    "project" "text",
    "notes" "text",
    "status" "text" DEFAULT 'open'::"text" NOT NULL
);


ALTER TABLE "public"."obijuan_timecards" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."transport_gigs" (
    "id" bigint NOT NULL,
    "item_id" "text" NOT NULL,
    "claim_id" "text",
    "buyer_discord_id" "text" NOT NULL,
    "seller_discord_id" "text",
    "driver_discord_id" "text",
    "pickup_area" "text",
    "dropoff_area" "text",
    "pickup_details" "text",
    "dropoff_details" "text",
    "delivery_offer" numeric(10,2) DEFAULT 0 NOT NULL,
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "gig_channel_id" "text",
    "gig_message_id" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "claimed_at" timestamp with time zone,
    "picked_up_at" timestamp with time zone,
    "delivered_at" timestamp with time zone,
    CONSTRAINT "transport_gigs_status_check" CHECK (("status" = ANY (ARRAY['open'::"text", 'claimed'::"text", 'picked_up'::"text", 'delivered'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."transport_gigs" OWNER TO "postgres";


ALTER TABLE "public"."transport_gigs" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."transport_gigs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "display_name" "text" NOT NULL,
    "discord_user_id" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."vuelta_interests" (
    "id" bigint NOT NULL,
    "discord_user_id" "text" NOT NULL,
    "discord_user_name" "text",
    "description" "text" NOT NULL,
    "category" "text",
    "subcategory" "text",
    "match_keywords" "text",
    "alert_enabled" boolean DEFAULT true NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "vuelta_interests_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'matched'::"text", 'paused'::"text", 'closed'::"text"])))
);


ALTER TABLE "public"."vuelta_interests" OWNER TO "postgres";


ALTER TABLE "public"."vuelta_interests" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."vuelta_interests_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."vuelta_items" (
    "id" bigint NOT NULL,
    "seller_discord_id" "text" NOT NULL,
    "seller_discord_name" "text",
    "owner_name" "text",
    "item_name" "text",
    "description" "text" NOT NULL,
    "category" "text",
    "subcategory" "text",
    "brand" "text",
    "condition" "text",
    "quantity" "text",
    "asking_price" numeric(10,2),
    "minimum_price" numeric(10,2),
    "desired_outcome" "text" DEFAULT 'local_transfer'::"text",
    "pickup_area" "text",
    "pickup_notes" "text",
    "status" "text" DEFAULT 'available'::"text" NOT NULL,
    "local_first_until" timestamp with time zone,
    "external_platform_recommended" "text",
    "external_price_recommended" numeric(10,2),
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "source_system" "text",
    "source_item_code" "text",
    "source_status" "text",
    "original_cost" numeric(10,2),
    "photo_url" "text",
    CONSTRAINT "vuelta_items_status_check" CHECK (("status" = ANY (ARRAY['available'::"text", 'claimed'::"text", 'pending_transport'::"text", 'in_transit'::"text", 'sold'::"text", 'given'::"text", 'closed'::"text", 'expired'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."vuelta_items" OWNER TO "postgres";


ALTER TABLE "public"."vuelta_items" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."vuelta_items_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."vuelta_routes" (
    "id" bigint NOT NULL,
    "item_id" bigint NOT NULL,
    "route_type" "text" NOT NULL,
    "platform_name" "text",
    "status" "text" DEFAULT 'recommended'::"text" NOT NULL,
    "listed_price" numeric(10,2),
    "listed_at" timestamp with time zone,
    "sold_price" numeric(10,2),
    "sold_at" timestamp with time zone,
    "platform_fees" numeric(10,2) DEFAULT 0,
    "seller_tax" numeric(10,2) DEFAULT 0,
    "net_proceeds" numeric(10,2),
    "recommended_price" numeric(10,2),
    "recommendation_score" numeric(6,2),
    "recommendation_reason" "text",
    "source_system" "text",
    "source_platform_text" "text",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "vuelta_routes_route_type_check" CHECK (("route_type" = ANY (ARRAY['local_marketplace'::"text", 'external_marketplace'::"text", 'consignment'::"text", 'direct'::"text", 'donation'::"text", 'recycling'::"text", 'reuse'::"text", 'other'::"text"]))),
    CONSTRAINT "vuelta_routes_status_check" CHECK (("status" = ANY (ARRAY['recommended'::"text", 'offered'::"text", 'listed'::"text", 'claimed'::"text", 'sold'::"text", 'closed'::"text", 'failed'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."vuelta_routes" OWNER TO "postgres";


ALTER TABLE "public"."vuelta_routes" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."vuelta_routes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."vuelta_transactions" (
    "id" bigint NOT NULL,
    "item_id" bigint NOT NULL,
    "seller_discord_id" "text" NOT NULL,
    "seller_discord_name" "text",
    "buyer_discord_id" "text" NOT NULL,
    "buyer_discord_name" "text",
    "agreed_price" numeric(10,2),
    "transaction_type" "text" DEFAULT 'sale'::"text" NOT NULL,
    "transport_required" boolean DEFAULT false NOT NULL,
    "status" "text" DEFAULT 'claimed'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "completed_at" timestamp with time zone,
    CONSTRAINT "vuelta_transactions_status_check" CHECK (("status" = ANY (ARRAY['claimed'::"text", 'awaiting_transport'::"text", 'transport_assigned'::"text", 'in_transit'::"text", 'completed'::"text", 'cancelled'::"text"]))),
    CONSTRAINT "vuelta_transactions_transaction_type_check" CHECK (("transaction_type" = ANY (ARRAY['sale'::"text", 'giveaway'::"text", 'trade'::"text", 'donation'::"text"])))
);


ALTER TABLE "public"."vuelta_transactions" OWNER TO "postgres";


ALTER TABLE "public"."vuelta_transactions" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."vuelta_transactions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."vuelta_transport_bids" (
    "id" bigint NOT NULL,
    "transport_job_id" bigint NOT NULL,
    "driver_discord_id" "text" NOT NULL,
    "driver_discord_name" "text",
    "bid_amount" numeric(10,2) NOT NULL,
    "notes" "text",
    "status" "text" DEFAULT 'submitted'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "vuelta_transport_bids_bid_amount_check" CHECK (("bid_amount" >= (0)::numeric)),
    CONSTRAINT "vuelta_transport_bids_status_check" CHECK (("status" = ANY (ARRAY['submitted'::"text", 'accepted'::"text", 'rejected'::"text", 'withdrawn'::"text"])))
);


ALTER TABLE "public"."vuelta_transport_bids" OWNER TO "postgres";


ALTER TABLE "public"."vuelta_transport_bids" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."vuelta_transport_bids_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."vuelta_transport_jobs" (
    "id" bigint NOT NULL,
    "transaction_id" bigint NOT NULL,
    "item_id" bigint NOT NULL,
    "requester_discord_id" "text" NOT NULL,
    "requester_discord_name" "text",
    "pickup_area" "text",
    "dropoff_area" "text",
    "item_description" "text",
    "size_notes" "text",
    "pickup_notes" "text",
    "delivery_notes" "text",
    "selected_bid_id" bigint,
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "assigned_at" timestamp with time zone,
    "picked_up_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    CONSTRAINT "vuelta_transport_jobs_status_check" CHECK (("status" = ANY (ARRAY['open'::"text", 'bidding'::"text", 'assigned'::"text", 'picked_up'::"text", 'delivered'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."vuelta_transport_jobs" OWNER TO "postgres";


ALTER TABLE "public"."vuelta_transport_jobs" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."vuelta_transport_jobs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."wtp_category_keyword_rules" (
    "id" bigint NOT NULL,
    "category" "text",
    "keyword" "text",
    "priority" integer
);


ALTER TABLE "public"."wtp_category_keyword_rules" OWNER TO "postgres";


ALTER TABLE "public"."wtp_category_keyword_rules" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."wtp_category_keyword_rules_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."wtp_category_pricing_rules" (
    "category" "text" NOT NULL,
    "sample_size" integer,
    "min_amount" numeric,
    "p25_amount" numeric,
    "median_amount" numeric,
    "p75_amount" numeric,
    "p90_amount" numeric,
    "max_amount" numeric,
    "recommended_floor" numeric,
    "recommended_starting_price" numeric,
    "recommended_premium_anchor" numeric,
    "pricing_confidence" "text",
    "guardabot_note" "text",
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."wtp_category_pricing_rules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wtp_estimate_events" (
    "id" bigint NOT NULL,
    "source_system" "text",
    "source_id" "text",
    "customer_name" "text",
    "customer_email" "text",
    "event_date" "date",
    "scheduled_date" "date",
    "status" "text",
    "description" "text",
    "address" "text",
    "zip_code" "text",
    "quoted_amount" numeric,
    "invoice_amount" numeric,
    "category" "text",
    "acceptance_signal" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."wtp_estimate_events" OWNER TO "postgres";


ALTER TABLE "public"."wtp_estimate_events" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."wtp_estimate_events_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE ONLY "public"."chisme_interactions" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."chisme_interactions_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."metiche_important_items" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."metiche_important_items_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."metiche_weekly" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."metiche_weekly_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."zz_archive_chisme_communication_queue" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."chisme_communication_queue_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."chisme_active"
    ADD CONSTRAINT "chisme_active_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."zz_archive_chisme_communication_queue"
    ADD CONSTRAINT "chisme_communication_queue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chisme_contacts"
    ADD CONSTRAINT "chisme_contacts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chisme_interactions"
    ADD CONSTRAINT "chisme_interactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chisme_journals"
    ADD CONSTRAINT "chisme_journals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chisme_leads"
    ADD CONSTRAINT "chisme_leads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chisme_load_events"
    ADD CONSTRAINT "chisme_load_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chisme_notes"
    ADD CONSTRAINT "chisme_notes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chisme_opportunities"
    ADD CONSTRAINT "chisme_opportunities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cholo_build_steps"
    ADD CONSTRAINT "cholo_build_steps_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cholo_build_steps"
    ADD CONSTRAINT "cholo_build_steps_template_id_sequence_key" UNIQUE ("template_id", "sequence");



ALTER TABLE ONLY "public"."cholo_build_steps"
    ADD CONSTRAINT "cholo_build_steps_template_id_step_key_key" UNIQUE ("template_id", "step_key");



ALTER TABLE ONLY "public"."cholo_build_templates"
    ADD CONSTRAINT "cholo_build_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cholo_build_templates"
    ADD CONSTRAINT "cholo_build_templates_template_key_key" UNIQUE ("template_key");



ALTER TABLE ONLY "public"."cholo_job_builds"
    ADD CONSTRAINT "cholo_job_builds_job_key_key" UNIQUE ("job_key");



ALTER TABLE ONLY "public"."cholo_job_builds"
    ADD CONSTRAINT "cholo_job_builds_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cholo_job_equipment"
    ADD CONSTRAINT "cholo_job_equipment_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cholo_job_observations"
    ADD CONSTRAINT "cholo_job_observations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cholo_job_steps"
    ADD CONSTRAINT "cholo_job_steps_job_id_template_step_id_key" UNIQUE ("job_id", "template_step_id");



ALTER TABLE ONLY "public"."cholo_job_steps"
    ADD CONSTRAINT "cholo_job_steps_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cholobots_visitors"
    ADD CONSTRAINT "cholobots_visitors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."company_members"
    ADD CONSTRAINT "company_members_company_id_user_id_key" UNIQUE ("company_id", "user_id");



ALTER TABLE ONLY "public"."company_members"
    ADD CONSTRAINT "company_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."crudo_labor_entries"
    ADD CONSTRAINT "crudo_labor_entries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."crudo_material_transaction_items"
    ADD CONSTRAINT "crudo_material_transaction_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."crudo_material_transactions"
    ADD CONSTRAINT "crudo_material_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."crudo_project_materials"
    ADD CONSTRAINT "crudo_project_materials_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."crudo_project_tasks"
    ADD CONSTRAINT "crudo_project_tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."crudo_projects"
    ADD CONSTRAINT "crudo_projects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."crudobot_jobs"
    ADD CONSTRAINT "crudobot_jobs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."crudobot_jobs"
    ADD CONSTRAINT "crudobot_jobs_project_slug_key" UNIQUE ("project_slug");



ALTER TABLE ONLY "public"."daily_tasks"
    ADD CONSTRAINT "daily_tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."garage_zones"
    ADD CONSTRAINT "garage_zones_pkey" PRIMARY KEY ("cell");



ALTER TABLE ONLY "public"."guard_job_items"
    ADD CONSTRAINT "guard_job_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."guard_job_transactions"
    ADD CONSTRAINT "guard_job_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory_items"
    ADD CONSTRAINT "inventory_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."material_events"
    ADD CONSTRAINT "material_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."metiche_ping_schedules"
    ADD CONSTRAINT "metiche_bodydouble_state_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."metiche_ping_schedules"
    ADD CONSTRAINT "metiche_bodydouble_state_user_id_key" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."metiche_goals"
    ADD CONSTRAINT "metiche_goals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."metiche_important_items"
    ADD CONSTRAINT "metiche_important_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."metiche_ping_preferences"
    ADD CONSTRAINT "metiche_ping_preferences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."metiche_ping_preferences"
    ADD CONSTRAINT "metiche_ping_preferences_user_id_key" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."metiche_ping_schedules"
    ADD CONSTRAINT "metiche_ping_schedules_channel_person_key" UNIQUE ("channel_id", "person");



ALTER TABLE ONLY "public"."metiche_project_tasks"
    ADD CONSTRAINT "metiche_project_tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."metiche_reprogramming_logs"
    ADD CONSTRAINT "metiche_reprogramming_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."metiche_routines"
    ADD CONSTRAINT "metiche_routines_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."metiche_time_sessions"
    ADD CONSTRAINT "metiche_time_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."metiche_wakeups"
    ADD CONSTRAINT "metiche_wakeups_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."metiche_weekly"
    ADD CONSTRAINT "metiche_weekly_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."metiche_weekly_plans"
    ADD CONSTRAINT "metiche_weekly_plans_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."obijuan_owner_time"
    ADD CONSTRAINT "obijuan_owner_time_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."obijuan_quest_assignments"
    ADD CONSTRAINT "obijuan_quest_assignments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."obijuan_quest_assignments"
    ADD CONSTRAINT "obijuan_quest_assignments_quest_id_worker_id_key" UNIQUE ("quest_id", "worker_id");



ALTER TABLE ONLY "public"."obijuan_quest_notes"
    ADD CONSTRAINT "obijuan_quest_notes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."obijuan_quest_updates"
    ADD CONSTRAINT "obijuan_quest_updates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."obijuan_quests"
    ADD CONSTRAINT "obijuan_quests_pkey" PRIMARY KEY ("quest_id");



ALTER TABLE ONLY "public"."obijuan_timecards"
    ADD CONSTRAINT "obijuan_timecards_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."transport_gigs"
    ADD CONSTRAINT "transport_gigs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_discord_user_id_key" UNIQUE ("discord_user_id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vuelta_interests"
    ADD CONSTRAINT "vuelta_interests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vuelta_items"
    ADD CONSTRAINT "vuelta_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vuelta_routes"
    ADD CONSTRAINT "vuelta_routes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vuelta_transactions"
    ADD CONSTRAINT "vuelta_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vuelta_transport_bids"
    ADD CONSTRAINT "vuelta_transport_bids_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vuelta_transport_jobs"
    ADD CONSTRAINT "vuelta_transport_jobs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wtp_category_keyword_rules"
    ADD CONSTRAINT "wtp_category_keyword_rules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wtp_category_pricing_rules"
    ADD CONSTRAINT "wtp_category_pricing_rules_pkey" PRIMARY KEY ("category");



ALTER TABLE ONLY "public"."wtp_estimate_events"
    ADD CONSTRAINT "wtp_estimate_events_pkey" PRIMARY KEY ("id");



CREATE INDEX "crudo_labor_entries_project_idx" ON "public"."crudo_labor_entries" USING "btree" ("project_id");



CREATE INDEX "crudo_labor_entries_task_idx" ON "public"."crudo_labor_entries" USING "btree" ("task_id");



CREATE INDEX "crudo_material_transaction_items_material_idx" ON "public"."crudo_material_transaction_items" USING "btree" ("project_material_id");



CREATE INDEX "crudo_material_transaction_items_project_idx" ON "public"."crudo_material_transaction_items" USING "btree" ("project_id");



CREATE INDEX "crudo_material_transaction_items_transaction_idx" ON "public"."crudo_material_transaction_items" USING "btree" ("transaction_id");



CREATE INDEX "crudo_material_transactions_date_idx" ON "public"."crudo_material_transactions" USING "btree" ("transaction_date");



CREATE INDEX "crudo_material_transactions_project_idx" ON "public"."crudo_material_transactions" USING "btree" ("project_id");



CREATE INDEX "crudo_project_materials_item_idx" ON "public"."crudo_project_materials" USING "btree" ("item_name");



CREATE INDEX "crudo_project_materials_project_idx" ON "public"."crudo_project_materials" USING "btree" ("project_id");



CREATE INDEX "guard_job_items_description_idx" ON "public"."guard_job_items" USING "btree" ("lower"("description"));



CREATE INDEX "guard_job_items_project_idx" ON "public"."guard_job_items" USING "btree" ("lower"("project_name"));



CREATE UNIQUE INDEX "guard_job_transactions_file_hash_uidx" ON "public"."guard_job_transactions" USING "btree" ("source_file_sha256") WHERE ("source_file_sha256" IS NOT NULL);



CREATE INDEX "guard_job_transactions_project_idx" ON "public"."guard_job_transactions" USING "btree" ("lower"("project_name"));



CREATE INDEX "guard_job_transactions_receipt_number_idx" ON "public"."guard_job_transactions" USING "btree" ("receipt_number");



CREATE INDEX "idx_chisme_interactions_contact" ON "public"."chisme_interactions" USING "btree" ("contact_id", "created_at" DESC);



CREATE INDEX "idx_chisme_interactions_today_touch" ON "public"."chisme_interactions" USING "btree" ("interaction_date", "touch_counts_for_today");



CREATE INDEX "idx_chisme_leads_callback" ON "public"."chisme_leads" USING "btree" ("callback_date");



CREATE INDEX "idx_chisme_leads_contact" ON "public"."chisme_leads" USING "btree" ("contact_id");



CREATE INDEX "idx_chisme_leads_status" ON "public"."chisme_leads" USING "btree" ("status");



CREATE INDEX "idx_chisme_opportunities_callback" ON "public"."chisme_opportunities" USING "btree" ("callback_date");



CREATE INDEX "idx_chisme_opportunities_contact" ON "public"."chisme_opportunities" USING "btree" ("contact_id");



CREATE INDEX "idx_chisme_opportunities_lead" ON "public"."chisme_opportunities" USING "btree" ("lead_id");



CREATE INDEX "idx_chisme_opportunities_status" ON "public"."chisme_opportunities" USING "btree" ("status");



CREATE INDEX "idx_chisme_queue_bucket" ON "public"."zz_archive_chisme_communication_queue" USING "btree" ("bucket");



CREATE INDEX "idx_chisme_queue_date_status" ON "public"."zz_archive_chisme_communication_queue" USING "btree" ("queue_date", "status");



CREATE INDEX "idx_cholo_equipment_job" ON "public"."cholo_job_equipment" USING "btree" ("job_id");



CREATE INDEX "idx_cholo_steps_job_status" ON "public"."cholo_job_steps" USING "btree" ("job_id", "status");



CREATE INDEX "idx_crudo_project_tasks_project" ON "public"."crudo_project_tasks" USING "btree" ("project_id");



CREATE INDEX "idx_crudo_project_tasks_status" ON "public"."crudo_project_tasks" USING "btree" ("status");



CREATE INDEX "idx_crudo_projects_contact" ON "public"."crudo_projects" USING "btree" ("contact_id");



CREATE INDEX "idx_crudo_projects_opportunity" ON "public"."crudo_projects" USING "btree" ("opportunity_id");



CREATE INDEX "idx_crudo_projects_status" ON "public"."crudo_projects" USING "btree" ("status");



CREATE INDEX "idx_interactions_contact_time" ON "public"."chisme_interactions" USING "btree" ("contact_id", "created_at" DESC);



CREATE INDEX "idx_metiche_wakeups_due" ON "public"."metiche_wakeups" USING "btree" ("status", "wake_time");



CREATE INDEX "idx_metiche_weekly_created_at" ON "public"."metiche_weekly" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_metiche_weekly_week_of" ON "public"."metiche_weekly" USING "btree" ("week_of");



CREATE INDEX "idx_vuelta_interests_category" ON "public"."vuelta_interests" USING "btree" ("category");



CREATE INDEX "idx_vuelta_interests_status" ON "public"."vuelta_interests" USING "btree" ("status");



CREATE INDEX "idx_vuelta_interests_user" ON "public"."vuelta_interests" USING "btree" ("discord_user_id");



CREATE INDEX "idx_vuelta_items_category" ON "public"."vuelta_items" USING "btree" ("category");



CREATE INDEX "idx_vuelta_items_seller" ON "public"."vuelta_items" USING "btree" ("seller_discord_id");



CREATE INDEX "idx_vuelta_items_status" ON "public"."vuelta_items" USING "btree" ("status");



CREATE INDEX "idx_vuelta_routes_item" ON "public"."vuelta_routes" USING "btree" ("item_id");



CREATE INDEX "idx_vuelta_routes_platform" ON "public"."vuelta_routes" USING "btree" ("platform_name");



CREATE INDEX "idx_vuelta_routes_status" ON "public"."vuelta_routes" USING "btree" ("status");



CREATE INDEX "idx_vuelta_routes_type" ON "public"."vuelta_routes" USING "btree" ("route_type");



CREATE INDEX "idx_vuelta_transactions_item" ON "public"."vuelta_transactions" USING "btree" ("item_id");



CREATE INDEX "idx_vuelta_transport_bids_job" ON "public"."vuelta_transport_bids" USING "btree" ("transport_job_id");



CREATE INDEX "idx_vuelta_transport_jobs_status" ON "public"."vuelta_transport_jobs" USING "btree" ("status");



CREATE INDEX "idx_wtp_events_category" ON "public"."wtp_estimate_events" USING "btree" ("category");



CREATE INDEX "idx_wtp_events_source" ON "public"."wtp_estimate_events" USING "btree" ("source_system", "source_id");



CREATE INDEX "idx_wtp_events_zip" ON "public"."wtp_estimate_events" USING "btree" ("zip_code");



CREATE INDEX "metiche_project_tasks_contact_id_idx" ON "public"."metiche_project_tasks" USING "btree" ("contact_id");



CREATE INDEX "obijuan_assignments_quest_idx" ON "public"."obijuan_quest_assignments" USING "btree" ("quest_id");



CREATE INDEX "obijuan_notes_quest_idx" ON "public"."obijuan_quest_notes" USING "btree" ("quest_id");



CREATE INDEX "obijuan_owner_time_quest_idx" ON "public"."obijuan_owner_time" USING "btree" ("quest_id");



CREATE INDEX "obijuan_updates_quest_idx" ON "public"."obijuan_quest_updates" USING "btree" ("quest_id");



CREATE OR REPLACE TRIGGER "trg_vuelta_interests_updated_at" BEFORE UPDATE ON "public"."vuelta_interests" FOR EACH ROW EXECUTE FUNCTION "public"."set_vuelta_updated_at"();



CREATE OR REPLACE TRIGGER "trg_vuelta_items_updated_at" BEFORE UPDATE ON "public"."vuelta_items" FOR EACH ROW EXECUTE FUNCTION "public"."set_vuelta_updated_at"();



ALTER TABLE ONLY "public"."chisme_active"
    ADD CONSTRAINT "chisme_active_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."chisme_contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."chisme_journals"
    ADD CONSTRAINT "chisme_journals_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."chisme_contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."chisme_leads"
    ADD CONSTRAINT "chisme_leads_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."chisme_contacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."chisme_notes"
    ADD CONSTRAINT "chisme_notes_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."chisme_contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."chisme_notes"
    ADD CONSTRAINT "chisme_notes_journal_id_fkey" FOREIGN KEY ("journal_id") REFERENCES "public"."chisme_journals"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."chisme_opportunities"
    ADD CONSTRAINT "chisme_opportunities_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."chisme_contacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."chisme_opportunities"
    ADD CONSTRAINT "chisme_opportunities_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "public"."chisme_leads"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."cholo_build_steps"
    ADD CONSTRAINT "cholo_build_steps_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "public"."cholo_build_templates"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cholo_job_builds"
    ADD CONSTRAINT "cholo_job_builds_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "public"."cholo_build_templates"("id");



ALTER TABLE ONLY "public"."cholo_job_equipment"
    ADD CONSTRAINT "cholo_job_equipment_job_id_fkey" FOREIGN KEY ("job_id") REFERENCES "public"."cholo_job_builds"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cholo_job_observations"
    ADD CONSTRAINT "cholo_job_observations_job_id_fkey" FOREIGN KEY ("job_id") REFERENCES "public"."cholo_job_builds"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cholo_job_steps"
    ADD CONSTRAINT "cholo_job_steps_job_id_fkey" FOREIGN KEY ("job_id") REFERENCES "public"."cholo_job_builds"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cholo_job_steps"
    ADD CONSTRAINT "cholo_job_steps_template_step_id_fkey" FOREIGN KEY ("template_step_id") REFERENCES "public"."cholo_build_steps"("id");



ALTER TABLE ONLY "public"."company_members"
    ADD CONSTRAINT "company_members_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."company_members"
    ADD CONSTRAINT "company_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."crudo_labor_entries"
    ADD CONSTRAINT "crudo_labor_entries_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."crudo_projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."crudo_labor_entries"
    ADD CONSTRAINT "crudo_labor_entries_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "public"."crudo_project_tasks"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."crudo_material_transaction_items"
    ADD CONSTRAINT "crudo_material_transaction_items_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."crudo_projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."crudo_material_transaction_items"
    ADD CONSTRAINT "crudo_material_transaction_items_project_material_id_fkey" FOREIGN KEY ("project_material_id") REFERENCES "public"."crudo_project_materials"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."crudo_material_transaction_items"
    ADD CONSTRAINT "crudo_material_transaction_items_transaction_id_fkey" FOREIGN KEY ("transaction_id") REFERENCES "public"."crudo_material_transactions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."crudo_material_transactions"
    ADD CONSTRAINT "crudo_material_transactions_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."crudo_projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."crudo_project_materials"
    ADD CONSTRAINT "crudo_project_materials_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."crudo_projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."crudo_project_tasks"
    ADD CONSTRAINT "crudo_project_tasks_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."crudo_projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."crudo_projects"
    ADD CONSTRAINT "crudo_projects_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."chisme_contacts"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."crudo_projects"
    ADD CONSTRAINT "crudo_projects_opportunity_id_fkey" FOREIGN KEY ("opportunity_id") REFERENCES "public"."chisme_opportunities"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."daily_tasks"
    ADD CONSTRAINT "daily_tasks_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id");



ALTER TABLE ONLY "public"."guard_job_items"
    ADD CONSTRAINT "guard_job_items_transaction_id_fkey" FOREIGN KEY ("transaction_id") REFERENCES "public"."guard_job_transactions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."metiche_project_tasks"
    ADD CONSTRAINT "metiche_project_tasks_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."chisme_contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."obijuan_owner_time"
    ADD CONSTRAINT "obijuan_owner_time_quest_id_fkey" FOREIGN KEY ("quest_id") REFERENCES "public"."obijuan_quests"("quest_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."obijuan_quest_assignments"
    ADD CONSTRAINT "obijuan_quest_assignments_quest_id_fkey" FOREIGN KEY ("quest_id") REFERENCES "public"."obijuan_quests"("quest_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."obijuan_quest_notes"
    ADD CONSTRAINT "obijuan_quest_notes_quest_id_fkey" FOREIGN KEY ("quest_id") REFERENCES "public"."obijuan_quests"("quest_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."obijuan_quest_updates"
    ADD CONSTRAINT "obijuan_quest_updates_quest_id_fkey" FOREIGN KEY ("quest_id") REFERENCES "public"."obijuan_quests"("quest_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."vuelta_routes"
    ADD CONSTRAINT "vuelta_routes_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "public"."vuelta_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."vuelta_transactions"
    ADD CONSTRAINT "vuelta_transactions_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "public"."vuelta_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."vuelta_transport_bids"
    ADD CONSTRAINT "vuelta_transport_bids_transport_job_id_fkey" FOREIGN KEY ("transport_job_id") REFERENCES "public"."vuelta_transport_jobs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."vuelta_transport_jobs"
    ADD CONSTRAINT "vuelta_transport_jobs_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "public"."vuelta_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."vuelta_transport_jobs"
    ADD CONSTRAINT "vuelta_transport_jobs_selected_bid_id_fkey" FOREIGN KEY ("selected_bid_id") REFERENCES "public"."vuelta_transport_bids"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."vuelta_transport_jobs"
    ADD CONSTRAINT "vuelta_transport_jobs_transaction_id_fkey" FOREIGN KEY ("transaction_id") REFERENCES "public"."vuelta_transactions"("id") ON DELETE CASCADE;



CREATE POLICY "Allow anon delete chisme active" ON "public"."chisme_active" FOR DELETE TO "anon" USING (true);



CREATE POLICY "Allow anon deletes from chisme active" ON "public"."chisme_active" FOR DELETE TO "anon" USING (true);



CREATE POLICY "Allow anon read chisme active" ON "public"."chisme_active" FOR SELECT TO "anon" USING (true);



CREATE POLICY "Allow anon read chisme_load_events" ON "public"."chisme_load_events" FOR SELECT TO "anon" USING (true);



CREATE POLICY "Allow anon updates to chisme contacts" ON "public"."chisme_contacts" FOR UPDATE TO "anon" USING (true) WITH CHECK (true);



CREATE POLICY "Allow public read chisme communication queue" ON "public"."zz_archive_chisme_communication_queue" FOR SELECT USING (true);



CREATE POLICY "Allow public read chisme interactions" ON "public"."chisme_interactions" FOR SELECT USING (true);



CREATE POLICY "Allow public read crudo project tasks" ON "public"."crudo_project_tasks" FOR SELECT TO "anon" USING (true);



CREATE POLICY "Allow public read crudo projects" ON "public"."crudo_projects" FOR SELECT TO "anon" USING (true);



CREATE POLICY "Allow public read metiche important items" ON "public"."metiche_important_items" FOR SELECT USING (true);



CREATE POLICY "Allow public read metiche weekly" ON "public"."metiche_weekly" FOR SELECT USING (true);



CREATE POLICY "Allow public read of daily tasks" ON "public"."daily_tasks" FOR SELECT TO "anon" USING (true);



CREATE POLICY "Allow public read project tasks" ON "public"."metiche_project_tasks" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Customer workflow records can be read" ON "public"."chisme_contacts" FOR SELECT TO "anon" USING (((COALESCE("lifetime_value", (0)::numeric) > (0)::numeric) AND (("hotlist_temperature" >= '-10'::integer) AND ("hotlist_temperature" <= 100))));



CREATE POLICY "Enable read access for all users" ON "public"."crudo_material_transactions" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."garage_zones" FOR SELECT USING (true);



CREATE POLICY "Enable read access for all users" ON "public"."inventory_items" FOR SELECT USING (true);



CREATE POLICY "Refrigerator customers can update temperature" ON "public"."chisme_contacts" FOR UPDATE TO "anon" USING (((COALESCE("lifetime_value", (0)::numeric) > (0)::numeric) AND (COALESCE("do_not_pursue", false) = false) AND (("hotlist_temperature" >= 0) AND ("hotlist_temperature" <= 50)))) WITH CHECK ((("hotlist_temperature" >= '-10'::integer) AND ("hotlist_temperature" <= 100)));



CREATE POLICY "Refrigerator journals can be read" ON "public"."chisme_journals" FOR SELECT TO "anon" USING ((EXISTS ( SELECT 1
   FROM "public"."chisme_contacts" "c"
  WHERE (("c"."id" = "chisme_journals"."contact_id") AND (COALESCE("c"."do_not_pursue", false) = false) AND (COALESCE("c"."lifetime_value", (0)::numeric) > (0)::numeric) AND (("c"."hotlist_temperature" >= 0) AND ("c"."hotlist_temperature" <= 50))))));



CREATE POLICY "Refrigerator notes can be read" ON "public"."chisme_notes" FOR SELECT TO "anon" USING ((EXISTS ( SELECT 1
   FROM ("public"."chisme_journals" "j"
     JOIN "public"."chisme_contacts" "c" ON (("c"."id" = "j"."contact_id")))
  WHERE (("j"."id" = "chisme_notes"."journal_id") AND (COALESCE("c"."do_not_pursue", false) = false) AND (COALESCE("c"."lifetime_value", (0)::numeric) > (0)::numeric) AND (("c"."hotlist_temperature" >= 0) AND ("c"."hotlist_temperature" <= 50))))));



ALTER TABLE "public"."chisme_active" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chisme_contacts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chisme_contacts_zero_value_backup" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chisme_interactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chisme_journals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chisme_leads" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chisme_load_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chisme_notes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chisme_opportunities" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cholo_build_steps" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cholo_build_templates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cholo_job_builds" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cholo_job_equipment" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cholo_job_observations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cholo_job_steps" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cholobots_visitors" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."companies" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."company_members" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."crudo_labor_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."crudo_material_transaction_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."crudo_material_transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."crudo_project_materials" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."crudo_project_tasks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."crudo_projects" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "crudobot jobs readable by app" ON "public"."crudobot_jobs" FOR SELECT TO "anon" USING (true);



ALTER TABLE "public"."crudobot_jobs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."daily_tasks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."garage_zones" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."guard_job_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."guard_job_transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."hcp_customer_export" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."inventory_items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "job items readable by app" ON "public"."guard_job_items" FOR SELECT TO "anon" USING (true);



CREATE POLICY "job transactions readable by app" ON "public"."guard_job_transactions" FOR SELECT TO "anon" USING (true);



ALTER TABLE "public"."material_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."metiche_goals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."metiche_important_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."metiche_ping_preferences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."metiche_ping_schedules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."metiche_project_tasks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."metiche_reprogramming_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."metiche_routines" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."metiche_time_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."metiche_wakeups" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."metiche_weekly" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."metiche_weekly_plans" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."obijuan_owner_time" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."obijuan_quest_assignments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."obijuan_quest_notes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."obijuan_quest_updates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."obijuan_quests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."obijuan_timecards" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "owner time readable by app" ON "public"."obijuan_owner_time" FOR SELECT TO "anon" USING (true);



CREATE POLICY "quest assignments readable by app" ON "public"."obijuan_quest_assignments" FOR SELECT TO "anon" USING (true);



ALTER TABLE "public"."transport_gigs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."vuelta_interests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."vuelta_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."vuelta_routes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."vuelta_transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."vuelta_transport_bids" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."vuelta_transport_jobs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."wtp_category_keyword_rules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."wtp_category_pricing_rules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."wtp_estimate_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."zz_archive_chisme_communication_queue" ENABLE ROW LEVEL SECURITY;


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_vuelta_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_vuelta_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_vuelta_updated_at"() TO "service_role";



GRANT ALL ON TABLE "public"."chisme_active" TO "anon";
GRANT ALL ON TABLE "public"."chisme_active" TO "authenticated";
GRANT ALL ON TABLE "public"."chisme_active" TO "service_role";



GRANT ALL ON TABLE "public"."zz_archive_chisme_communication_queue" TO "anon";
GRANT ALL ON TABLE "public"."zz_archive_chisme_communication_queue" TO "authenticated";
GRANT ALL ON TABLE "public"."zz_archive_chisme_communication_queue" TO "service_role";



GRANT ALL ON SEQUENCE "public"."chisme_communication_queue_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."chisme_communication_queue_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."chisme_communication_queue_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."chisme_contacts" TO "anon";
GRANT ALL ON TABLE "public"."chisme_contacts" TO "authenticated";
GRANT ALL ON TABLE "public"."chisme_contacts" TO "service_role";



GRANT UPDATE("hotlist_temperature") ON TABLE "public"."chisme_contacts" TO "anon";



GRANT UPDATE("do_not_pursue") ON TABLE "public"."chisme_contacts" TO "anon";



GRANT ALL ON TABLE "public"."chisme_contacts_zero_value_backup" TO "anon";
GRANT ALL ON TABLE "public"."chisme_contacts_zero_value_backup" TO "authenticated";
GRANT ALL ON TABLE "public"."chisme_contacts_zero_value_backup" TO "service_role";



GRANT ALL ON TABLE "public"."chisme_dashboard_contacts" TO "anon";
GRANT ALL ON TABLE "public"."chisme_dashboard_contacts" TO "authenticated";
GRANT ALL ON TABLE "public"."chisme_dashboard_contacts" TO "service_role";



GRANT ALL ON TABLE "public"."chisme_interactions" TO "anon";
GRANT ALL ON TABLE "public"."chisme_interactions" TO "authenticated";
GRANT ALL ON TABLE "public"."chisme_interactions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."chisme_interactions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."chisme_interactions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."chisme_interactions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."chisme_journals" TO "anon";
GRANT ALL ON TABLE "public"."chisme_journals" TO "authenticated";
GRANT ALL ON TABLE "public"."chisme_journals" TO "service_role";



GRANT ALL ON TABLE "public"."chisme_leads" TO "anon";
GRANT ALL ON TABLE "public"."chisme_leads" TO "authenticated";
GRANT ALL ON TABLE "public"."chisme_leads" TO "service_role";



GRANT ALL ON TABLE "public"."chisme_load_events" TO "anon";
GRANT ALL ON TABLE "public"."chisme_load_events" TO "authenticated";
GRANT ALL ON TABLE "public"."chisme_load_events" TO "service_role";



GRANT ALL ON TABLE "public"."chisme_notes" TO "anon";
GRANT ALL ON TABLE "public"."chisme_notes" TO "authenticated";
GRANT ALL ON TABLE "public"."chisme_notes" TO "service_role";



GRANT ALL ON TABLE "public"."chisme_opportunities" TO "anon";
GRANT ALL ON TABLE "public"."chisme_opportunities" TO "authenticated";
GRANT ALL ON TABLE "public"."chisme_opportunities" TO "service_role";



GRANT ALL ON TABLE "public"."cholo_build_steps" TO "service_role";



GRANT ALL ON TABLE "public"."cholo_build_templates" TO "service_role";



GRANT ALL ON TABLE "public"."cholo_job_builds" TO "service_role";



GRANT ALL ON TABLE "public"."cholo_job_equipment" TO "service_role";



GRANT ALL ON TABLE "public"."cholo_job_observations" TO "service_role";



GRANT ALL ON TABLE "public"."cholo_job_steps" TO "service_role";



GRANT ALL ON TABLE "public"."cholobots_visitors" TO "anon";
GRANT ALL ON TABLE "public"."cholobots_visitors" TO "authenticated";
GRANT ALL ON TABLE "public"."cholobots_visitors" TO "service_role";



GRANT ALL ON SEQUENCE "public"."cholobots_visitors_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."cholobots_visitors_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."cholobots_visitors_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."companies" TO "anon";
GRANT ALL ON TABLE "public"."companies" TO "authenticated";
GRANT ALL ON TABLE "public"."companies" TO "service_role";



GRANT ALL ON TABLE "public"."company_members" TO "anon";
GRANT ALL ON TABLE "public"."company_members" TO "authenticated";
GRANT ALL ON TABLE "public"."company_members" TO "service_role";



GRANT ALL ON TABLE "public"."crudo_labor_entries" TO "anon";
GRANT ALL ON TABLE "public"."crudo_labor_entries" TO "authenticated";
GRANT ALL ON TABLE "public"."crudo_labor_entries" TO "service_role";



GRANT ALL ON TABLE "public"."crudo_material_transaction_items" TO "anon";
GRANT ALL ON TABLE "public"."crudo_material_transaction_items" TO "authenticated";
GRANT ALL ON TABLE "public"."crudo_material_transaction_items" TO "service_role";



GRANT ALL ON TABLE "public"."crudo_material_transactions" TO "anon";
GRANT ALL ON TABLE "public"."crudo_material_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."crudo_material_transactions" TO "service_role";



GRANT ALL ON TABLE "public"."crudo_project_materials" TO "anon";
GRANT ALL ON TABLE "public"."crudo_project_materials" TO "authenticated";
GRANT ALL ON TABLE "public"."crudo_project_materials" TO "service_role";



GRANT ALL ON TABLE "public"."crudo_project_tasks" TO "anon";
GRANT ALL ON TABLE "public"."crudo_project_tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."crudo_project_tasks" TO "service_role";



GRANT ALL ON TABLE "public"."crudo_projects" TO "anon";
GRANT ALL ON TABLE "public"."crudo_projects" TO "authenticated";
GRANT ALL ON TABLE "public"."crudo_projects" TO "service_role";



GRANT ALL ON TABLE "public"."crudobot_jobs" TO "anon";
GRANT ALL ON TABLE "public"."crudobot_jobs" TO "authenticated";
GRANT ALL ON TABLE "public"."crudobot_jobs" TO "service_role";



GRANT ALL ON TABLE "public"."daily_tasks" TO "anon";
GRANT ALL ON TABLE "public"."daily_tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."daily_tasks" TO "service_role";



GRANT ALL ON TABLE "public"."garage_zones" TO "anon";
GRANT ALL ON TABLE "public"."garage_zones" TO "authenticated";
GRANT ALL ON TABLE "public"."garage_zones" TO "service_role";



GRANT ALL ON TABLE "public"."guard_job_items" TO "anon";
GRANT ALL ON TABLE "public"."guard_job_items" TO "authenticated";
GRANT ALL ON TABLE "public"."guard_job_items" TO "service_role";



GRANT ALL ON TABLE "public"."guard_job_transactions" TO "anon";
GRANT ALL ON TABLE "public"."guard_job_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."guard_job_transactions" TO "service_role";



GRANT ALL ON TABLE "public"."hcp_customer_export" TO "anon";
GRANT ALL ON TABLE "public"."hcp_customer_export" TO "authenticated";
GRANT ALL ON TABLE "public"."hcp_customer_export" TO "service_role";



GRANT ALL ON TABLE "public"."inventory_items" TO "anon";
GRANT ALL ON TABLE "public"."inventory_items" TO "authenticated";
GRANT ALL ON TABLE "public"."inventory_items" TO "service_role";



GRANT ALL ON SEQUENCE "public"."inventory_items_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."inventory_items_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."inventory_items_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."material_events" TO "anon";
GRANT ALL ON TABLE "public"."material_events" TO "authenticated";
GRANT ALL ON TABLE "public"."material_events" TO "service_role";



GRANT ALL ON SEQUENCE "public"."material_events_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."material_events_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."material_events_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."metiche_goals" TO "anon";
GRANT ALL ON TABLE "public"."metiche_goals" TO "authenticated";
GRANT ALL ON TABLE "public"."metiche_goals" TO "service_role";



GRANT ALL ON TABLE "public"."metiche_important_items" TO "anon";
GRANT ALL ON TABLE "public"."metiche_important_items" TO "authenticated";
GRANT ALL ON TABLE "public"."metiche_important_items" TO "service_role";



GRANT ALL ON SEQUENCE "public"."metiche_important_items_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."metiche_important_items_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."metiche_important_items_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."metiche_ping_preferences" TO "anon";
GRANT ALL ON TABLE "public"."metiche_ping_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."metiche_ping_preferences" TO "service_role";



GRANT ALL ON TABLE "public"."metiche_ping_schedules" TO "anon";
GRANT ALL ON TABLE "public"."metiche_ping_schedules" TO "authenticated";
GRANT ALL ON TABLE "public"."metiche_ping_schedules" TO "service_role";



GRANT ALL ON TABLE "public"."metiche_project_tasks" TO "anon";
GRANT ALL ON TABLE "public"."metiche_project_tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."metiche_project_tasks" TO "service_role";



GRANT ALL ON SEQUENCE "public"."metiche_project_tasks_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."metiche_project_tasks_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."metiche_project_tasks_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."metiche_reprogramming_logs" TO "anon";
GRANT ALL ON TABLE "public"."metiche_reprogramming_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."metiche_reprogramming_logs" TO "service_role";



GRANT ALL ON TABLE "public"."metiche_routines" TO "anon";
GRANT ALL ON TABLE "public"."metiche_routines" TO "authenticated";
GRANT ALL ON TABLE "public"."metiche_routines" TO "service_role";



GRANT ALL ON TABLE "public"."metiche_time_sessions" TO "anon";
GRANT ALL ON TABLE "public"."metiche_time_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."metiche_time_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."metiche_wakeups" TO "anon";
GRANT ALL ON TABLE "public"."metiche_wakeups" TO "authenticated";
GRANT ALL ON TABLE "public"."metiche_wakeups" TO "service_role";



GRANT ALL ON TABLE "public"."metiche_weekly" TO "anon";
GRANT ALL ON TABLE "public"."metiche_weekly" TO "authenticated";
GRANT ALL ON TABLE "public"."metiche_weekly" TO "service_role";



GRANT ALL ON SEQUENCE "public"."metiche_weekly_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."metiche_weekly_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."metiche_weekly_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."metiche_weekly_plans" TO "anon";
GRANT ALL ON TABLE "public"."metiche_weekly_plans" TO "authenticated";
GRANT ALL ON TABLE "public"."metiche_weekly_plans" TO "service_role";



GRANT ALL ON TABLE "public"."obijuan_owner_time" TO "anon";
GRANT ALL ON TABLE "public"."obijuan_owner_time" TO "authenticated";
GRANT ALL ON TABLE "public"."obijuan_owner_time" TO "service_role";



GRANT ALL ON TABLE "public"."obijuan_quest_assignments" TO "anon";
GRANT ALL ON TABLE "public"."obijuan_quest_assignments" TO "authenticated";
GRANT ALL ON TABLE "public"."obijuan_quest_assignments" TO "service_role";



GRANT ALL ON TABLE "public"."obijuan_quest_notes" TO "anon";
GRANT ALL ON TABLE "public"."obijuan_quest_notes" TO "authenticated";
GRANT ALL ON TABLE "public"."obijuan_quest_notes" TO "service_role";



GRANT ALL ON TABLE "public"."obijuan_quest_updates" TO "anon";
GRANT ALL ON TABLE "public"."obijuan_quest_updates" TO "authenticated";
GRANT ALL ON TABLE "public"."obijuan_quest_updates" TO "service_role";



GRANT ALL ON TABLE "public"."obijuan_quests" TO "anon";
GRANT ALL ON TABLE "public"."obijuan_quests" TO "authenticated";
GRANT ALL ON TABLE "public"."obijuan_quests" TO "service_role";



GRANT ALL ON TABLE "public"."obijuan_timecards" TO "anon";
GRANT ALL ON TABLE "public"."obijuan_timecards" TO "authenticated";
GRANT ALL ON TABLE "public"."obijuan_timecards" TO "service_role";



GRANT ALL ON TABLE "public"."transport_gigs" TO "anon";
GRANT ALL ON TABLE "public"."transport_gigs" TO "authenticated";
GRANT ALL ON TABLE "public"."transport_gigs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."transport_gigs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."transport_gigs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."transport_gigs_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";



GRANT ALL ON TABLE "public"."vuelta_interests" TO "anon";
GRANT ALL ON TABLE "public"."vuelta_interests" TO "authenticated";
GRANT ALL ON TABLE "public"."vuelta_interests" TO "service_role";



GRANT ALL ON SEQUENCE "public"."vuelta_interests_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."vuelta_interests_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."vuelta_interests_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."vuelta_items" TO "anon";
GRANT ALL ON TABLE "public"."vuelta_items" TO "authenticated";
GRANT ALL ON TABLE "public"."vuelta_items" TO "service_role";



GRANT ALL ON SEQUENCE "public"."vuelta_items_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."vuelta_items_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."vuelta_items_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."vuelta_routes" TO "anon";
GRANT ALL ON TABLE "public"."vuelta_routes" TO "authenticated";
GRANT ALL ON TABLE "public"."vuelta_routes" TO "service_role";



GRANT ALL ON SEQUENCE "public"."vuelta_routes_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."vuelta_routes_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."vuelta_routes_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."vuelta_transactions" TO "anon";
GRANT ALL ON TABLE "public"."vuelta_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."vuelta_transactions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."vuelta_transactions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."vuelta_transactions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."vuelta_transactions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."vuelta_transport_bids" TO "anon";
GRANT ALL ON TABLE "public"."vuelta_transport_bids" TO "authenticated";
GRANT ALL ON TABLE "public"."vuelta_transport_bids" TO "service_role";



GRANT ALL ON SEQUENCE "public"."vuelta_transport_bids_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."vuelta_transport_bids_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."vuelta_transport_bids_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."vuelta_transport_jobs" TO "anon";
GRANT ALL ON TABLE "public"."vuelta_transport_jobs" TO "authenticated";
GRANT ALL ON TABLE "public"."vuelta_transport_jobs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."vuelta_transport_jobs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."vuelta_transport_jobs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."vuelta_transport_jobs_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."wtp_category_keyword_rules" TO "anon";
GRANT ALL ON TABLE "public"."wtp_category_keyword_rules" TO "authenticated";
GRANT ALL ON TABLE "public"."wtp_category_keyword_rules" TO "service_role";



GRANT ALL ON SEQUENCE "public"."wtp_category_keyword_rules_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."wtp_category_keyword_rules_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."wtp_category_keyword_rules_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."wtp_category_pricing_rules" TO "anon";
GRANT ALL ON TABLE "public"."wtp_category_pricing_rules" TO "authenticated";
GRANT ALL ON TABLE "public"."wtp_category_pricing_rules" TO "service_role";



GRANT ALL ON TABLE "public"."wtp_estimate_events" TO "anon";
GRANT ALL ON TABLE "public"."wtp_estimate_events" TO "authenticated";
GRANT ALL ON TABLE "public"."wtp_estimate_events" TO "service_role";



GRANT ALL ON SEQUENCE "public"."wtp_estimate_events_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."wtp_estimate_events_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."wtp_estimate_events_id_seq" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







