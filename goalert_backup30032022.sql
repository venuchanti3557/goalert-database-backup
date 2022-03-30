--
-- PostgreSQL database dump
--

-- Dumped from database version 14.2 (Ubuntu 14.2-1.pgdg20.04+1)
-- Dumped by pg_dump version 14.2 (Ubuntu 14.2-1.pgdg20.04+1)

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

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: engine_processing_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.engine_processing_type AS ENUM (
    'escalation',
    'heartbeat',
    'np_cycle',
    'rotation',
    'schedule',
    'status_update',
    'verify',
    'message',
    'cleanup',
    'metrics'
);


ALTER TYPE public.engine_processing_type OWNER TO postgres;

--
-- Name: enum_alert_log_event; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_alert_log_event AS ENUM (
    'created',
    'reopened',
    'status_changed',
    'assignment_changed',
    'escalated',
    'closed',
    'notification_sent',
    'response_received',
    'acknowledged',
    'policy_updated',
    'duplicate_suppressed',
    'escalation_request',
    'no_notification_sent'
);


ALTER TYPE public.enum_alert_log_event OWNER TO postgres;

--
-- Name: enum_alert_log_subject_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_alert_log_subject_type AS ENUM (
    'user',
    'integration_key',
    'heartbeat_monitor',
    'channel'
);


ALTER TYPE public.enum_alert_log_subject_type OWNER TO postgres;

--
-- Name: enum_alert_source; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_alert_source AS ENUM (
    'grafana',
    'manual',
    'generic',
    'email',
    'site24x7',
    'prometheusAlertmanager'
);


ALTER TYPE public.enum_alert_source OWNER TO postgres;

--
-- Name: enum_alert_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_alert_status AS ENUM (
    'triggered',
    'active',
    'closed'
);


ALTER TYPE public.enum_alert_status OWNER TO postgres;

--
-- Name: enum_heartbeat_state; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_heartbeat_state AS ENUM (
    'inactive',
    'healthy',
    'unhealthy'
);


ALTER TYPE public.enum_heartbeat_state OWNER TO postgres;

--
-- Name: enum_integration_keys_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_integration_keys_type AS ENUM (
    'grafana',
    'generic',
    'email',
    'site24x7',
    'prometheusAlertmanager'
);


ALTER TYPE public.enum_integration_keys_type OWNER TO postgres;

--
-- Name: enum_limit_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_limit_type AS ENUM (
    'notification_rules_per_user',
    'contact_methods_per_user',
    'ep_steps_per_policy',
    'ep_actions_per_step',
    'participants_per_rotation',
    'rules_per_schedule',
    'integration_keys_per_service',
    'unacked_alerts_per_service',
    'targets_per_schedule',
    'heartbeat_monitors_per_service',
    'user_overrides_per_schedule',
    'calendar_subscriptions_per_user'
);


ALTER TYPE public.enum_limit_type OWNER TO postgres;

--
-- Name: enum_notif_channel_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_notif_channel_type AS ENUM (
    'SLACK'
);


ALTER TYPE public.enum_notif_channel_type OWNER TO postgres;

--
-- Name: enum_outgoing_messages_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_outgoing_messages_status AS ENUM (
    'pending',
    'sending',
    'queued_remotely',
    'sent',
    'delivered',
    'failed',
    'bundled'
);


ALTER TYPE public.enum_outgoing_messages_status OWNER TO postgres;

--
-- Name: enum_outgoing_messages_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_outgoing_messages_type AS ENUM (
    'alert_notification',
    'verification_message',
    'test_notification',
    'alert_status_update',
    'alert_notification_bundle',
    'alert_status_update_bundle',
    'schedule_on_call_notification'
);


ALTER TYPE public.enum_outgoing_messages_type OWNER TO postgres;

--
-- Name: enum_rotation_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_rotation_type AS ENUM (
    'weekly',
    'daily',
    'hourly'
);


ALTER TYPE public.enum_rotation_type OWNER TO postgres;

--
-- Name: enum_switchover_state; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_switchover_state AS ENUM (
    'idle',
    'in_progress',
    'use_next_db'
);


ALTER TYPE public.enum_switchover_state OWNER TO postgres;

--
-- Name: enum_throttle_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_throttle_type AS ENUM (
    'notifications',
    'notifications_2'
);


ALTER TYPE public.enum_throttle_type OWNER TO postgres;

--
-- Name: enum_user_contact_method_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_user_contact_method_type AS ENUM (
    'PUSH',
    'EMAIL',
    'VOICE',
    'SMS',
    'WEBHOOK'
);


ALTER TYPE public.enum_user_contact_method_type OWNER TO postgres;

--
-- Name: enum_user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.enum_user_role AS ENUM (
    'unknown',
    'user',
    'admin'
);


ALTER TYPE public.enum_user_role OWNER TO postgres;

--
-- Name: aquire_user_contact_method_lock(uuid, bigint, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.aquire_user_contact_method_lock(_client_id uuid, _alert_id bigint, _contact_method_id uuid) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
        DECLARE
            lock_id UUID = gen_random_uuid();
        BEGIN
            DELETE FROM user_contact_method_locks WHERE alert_id = _alert_id
                AND contact_method_id = _contact_method_id
                AND (timestamp + '5 minutes'::interval) < now();

            INSERT INTO user_contact_method_locks (id, alert_id, contact_method_id, client_id) 
                VALUES (lock_id, _alert_id, _contact_method_id, _client_id)
                RETURNING id INTO lock_id;

            INSERT INTO sent_notifications (id, alert_id, contact_method_id, cycle_id, notification_rule_id)
			SELECT lock_id, _alert_id, _contact_method_id, cycle_id, notification_rule_id
			FROM needs_notification_sent n
			WHERE n.alert_id = _alert_id AND n.contact_method_id = _contact_method_id
			ON CONFLICT DO NOTHING;

            RETURN lock_id;
        END;
    $$;


ALTER FUNCTION public.aquire_user_contact_method_lock(_client_id uuid, _alert_id bigint, _contact_method_id uuid) OWNER TO postgres;

--
-- Name: escalate_alerts(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.escalate_alerts() RETURNS void
    LANGUAGE plpgsql
    AS $$
        BEGIN
            UPDATE alerts
            SET escalation_level = escalation_level + 1, last_escalation = now()
            FROM alert_escalation_policy_snapshots e
            WHERE (last_escalation + e.step_delay) < now()
                AND status = 'triggered'
                AND id = e.alert_id
                AND e.step_number = (escalation_level % e.step_max)
                AND (e.repeat = -1 OR (escalation_level+1) / e.step_max <= e.repeat);
        END;
    $$;


ALTER FUNCTION public.escalate_alerts() OWNER TO postgres;

--
-- Name: fn_advance_or_end_rot_on_part_del(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_advance_or_end_rot_on_part_del() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_part UUID;
    active_part UUID;
BEGIN

    SELECT rotation_participant_id
    INTO active_part
    FROM rotation_state
    WHERE rotation_id = OLD.rotation_id;

    IF active_part != OLD.id THEN
        RETURN OLD;
    END IF;

    IF OLD.rotation_id NOT IN (
       SELECT id FROM rotations
    ) THEN
        DELETE FROM rotation_state
        WHERE rotation_id = OLD.rotation_id;
    END IF;

    SELECT id
    INTO new_part
    FROM rotation_participants
    WHERE
        rotation_id = OLD.rotation_id AND
        id != OLD.id AND
        position IN (0, OLD.position+1)
    ORDER BY position DESC
    LIMIT 1;

     IF new_part ISNULL THEN
        DELETE FROM rotation_state
        WHERE rotation_id = OLD.rotation_id;
    ELSE
        UPDATE rotation_state
        SET rotation_participant_id = new_part
        WHERE rotation_id = OLD.rotation_id;
    END IF;

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.fn_advance_or_end_rot_on_part_del() OWNER TO postgres;

--
-- Name: fn_clear_dedup_on_close(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_clear_dedup_on_close() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.dedup_key = NULL;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_clear_dedup_on_close() OWNER TO postgres;

--
-- Name: fn_clear_ep_state_on_alert_close(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_clear_ep_state_on_alert_close() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM escalation_policy_state
    WHERE alert_id = NEW.id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_clear_ep_state_on_alert_close() OWNER TO postgres;

--
-- Name: fn_clear_ep_state_on_svc_ep_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_clear_ep_state_on_svc_ep_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE escalation_policy_state
    SET
        escalation_policy_id = NEW.escalation_policy_id,
        escalation_policy_step_id = NULL,
        loop_count = 0,
        last_escalation = NULL,
        next_escalation = NULL,
        force_escalation = false,
        escalation_policy_step_number = 0
    WHERE service_id = NEW.id
    ;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_clear_ep_state_on_svc_ep_change() OWNER TO postgres;

--
-- Name: fn_clear_next_esc_on_alert_ack(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_clear_next_esc_on_alert_ack() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    UPDATE escalation_policy_state
    SET next_escalation = null
    WHERE alert_id = NEW.id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_clear_next_esc_on_alert_ack() OWNER TO postgres;

--
-- Name: fn_decr_ep_step_count_on_del(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_decr_ep_step_count_on_del() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE escalation_policies
    SET step_count = step_count - 1
    WHERE id = OLD.escalation_policy_id;

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.fn_decr_ep_step_count_on_del() OWNER TO postgres;

--
-- Name: fn_decr_ep_step_number_on_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_decr_ep_step_number_on_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    LOCK escalation_policy_steps IN EXCLUSIVE MODE;

    UPDATE escalation_policy_steps
    SET step_number = step_number - 1
    WHERE
        escalation_policy_id = OLD.escalation_policy_id AND
        step_number > OLD.step_number;

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.fn_decr_ep_step_number_on_delete() OWNER TO postgres;

--
-- Name: fn_decr_part_count_on_del(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_decr_part_count_on_del() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE rotations
    SET participant_count = participant_count - 1
    WHERE id = OLD.rotation_id;

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.fn_decr_part_count_on_del() OWNER TO postgres;

--
-- Name: fn_decr_rot_part_position_on_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_decr_rot_part_position_on_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    LOCK rotation_participants IN EXCLUSIVE MODE;

    UPDATE rotation_participants
    SET position = position - 1
    WHERE
        rotation_id = OLD.rotation_id AND
        position > OLD.position;

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.fn_decr_rot_part_position_on_delete() OWNER TO postgres;

--
-- Name: fn_disable_inserts(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_disable_inserts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'inserts are disabled on this table';
END;
$$;


ALTER FUNCTION public.fn_disable_inserts() OWNER TO postgres;

--
-- Name: fn_enforce_alert_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_alert_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'unacked_alerts_per_service';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM alerts
    WHERE service_id = NEW.service_id AND "status" = 'triggered';

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='unacked_alerts_per_service_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_alert_limit() OWNER TO postgres;

--
-- Name: fn_enforce_calendar_subscriptions_per_user_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_calendar_subscriptions_per_user_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'calendar_subscriptions_per_user';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM user_calendar_subscriptions
    WHERE user_id = NEW.user_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='calendar_subscriptions_per_user_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_calendar_subscriptions_per_user_limit() OWNER TO postgres;

--
-- Name: fn_enforce_contact_method_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_contact_method_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'contact_methods_per_user';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM user_contact_methods
    WHERE user_id = NEW.user_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='contact_methods_per_user_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_contact_method_limit() OWNER TO postgres;

--
-- Name: fn_enforce_ep_step_action_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_ep_step_action_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'ep_actions_per_step';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM escalation_policy_actions
    WHERE escalation_policy_step_id = NEW.escalation_policy_step_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='ep_actions_per_step_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_ep_step_action_limit() OWNER TO postgres;

--
-- Name: fn_enforce_ep_step_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_ep_step_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'ep_steps_per_policy';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM escalation_policy_steps
    WHERE escalation_policy_id = NEW.escalation_policy_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='ep_steps_per_policy_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_ep_step_limit() OWNER TO postgres;

--
-- Name: fn_enforce_ep_step_number_no_gaps(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_ep_step_number_no_gaps() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_pos INT := -1;
    step_count INT := 0;
BEGIN
    IF NEW.escalation_policy_id != OLD.escalation_policy_id THEN
        RAISE 'must not change escalation_policy_id of existing step';
    END IF;

    SELECT max(step_number), count(*)
    INTO max_pos, step_count
    FROM escalation_policy_steps
    WHERE escalation_policy_id = NEW.escalation_policy_id;

    IF max_pos >= step_count THEN
        RAISE 'must not have gap in step_numbers';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_ep_step_number_no_gaps() OWNER TO postgres;

--
-- Name: fn_enforce_heartbeat_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_heartbeat_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'heartbeat_monitors_per_service';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM heartbeat_monitors
    WHERE service_id = NEW.service_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='heartbeat_monitors_per_service_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_heartbeat_limit() OWNER TO postgres;

--
-- Name: fn_enforce_integration_key_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_integration_key_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'integration_keys_per_service';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM integration_keys
    WHERE service_id = NEW.service_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='integration_keys_per_service_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_integration_key_limit() OWNER TO postgres;

--
-- Name: fn_enforce_notification_rule_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_notification_rule_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'notification_rules_per_user';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM user_notification_rules
    WHERE user_id = NEW.user_id;

    IF max_count != -1 AND val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='notification_rules_per_user_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_notification_rule_limit() OWNER TO postgres;

--
-- Name: fn_enforce_rot_part_position_no_gaps(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_rot_part_position_no_gaps() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_pos INT := -1;
    part_count INT := 0;
BEGIN
    IF NEW.rotation_id != OLD.rotation_id THEN
        RAISE 'must not change rotation_id of existing participant';
    END IF;

    SELECT max(position), count(*)
    INTO max_pos, part_count
    FROM rotation_participants
    WHERE rotation_id = NEW.rotation_id;

    IF max_pos >= part_count THEN
        RAISE 'must not have gap in participant positions';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_rot_part_position_no_gaps() OWNER TO postgres;

--
-- Name: fn_enforce_rotation_participant_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_rotation_participant_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'participants_per_rotation';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM rotation_participants
    WHERE rotation_id = NEW.rotation_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='participants_per_rotation_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_rotation_participant_limit() OWNER TO postgres;

--
-- Name: fn_enforce_schedule_rule_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_schedule_rule_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'rules_per_schedule';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM schedule_rules
    WHERE schedule_id = NEW.schedule_id;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='rules_per_schedule_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_schedule_rule_limit() OWNER TO postgres;

--
-- Name: fn_enforce_schedule_target_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_schedule_target_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'targets_per_schedule';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM (
        SELECT DISTINCT tgt_user_id, tgt_rotation_id
        FROM schedule_rules
        WHERE schedule_id = NEW.schedule_id
    ) as tmp;

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='targets_per_schedule_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_schedule_target_limit() OWNER TO postgres;

--
-- Name: fn_enforce_status_update_same_user(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_status_update_same_user() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    _cm_user_id UUID;
BEGIN
    IF NEW.alert_status_log_contact_method_id ISNULL THEN
        RETURN NEW;
    END IF;

    SELECT INTO _cm_user_id user_id
    FROM user_contact_methods
    WHERE id = NEW.alert_status_log_contact_method_id;

    IF NEW.id != _cm_user_id THEN
        RAISE 'wrong user_id' USING ERRCODE='check_violation', CONSTRAINT='alert_status_user_id_match';
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_status_update_same_user() OWNER TO postgres;

--
-- Name: fn_enforce_user_overide_no_conflict(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_user_overide_no_conflict() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    conflict UUID := NULL;
BEGIN
    EXECUTE 'LOCK user_overrides IN EXCLUSIVE MODE';

    SELECT id INTO conflict
    FROM user_overrides
    WHERE
        id != NEW.id AND
        tgt_schedule_id = NEW.tgt_schedule_id AND
        (
            add_user_id in (NEW.remove_user_id, NEW.add_user_id) OR
            remove_user_id in (NEW.remove_user_id, NEW.add_user_id)
        ) AND
        (start_time, end_time) OVERLAPS (NEW.start_time, NEW.end_time)
    LIMIT 1;
  
    IF conflict NOTNULL THEN
        RAISE 'override conflict' USING ERRCODE='check_violation', CONSTRAINT='user_override_no_conflict_allowed', HINT='CONFLICTING_ID='||conflict::text;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_user_overide_no_conflict() OWNER TO postgres;

--
-- Name: fn_enforce_user_override_schedule_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_enforce_user_override_schedule_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    max_count INT := -1;
    val_count INT := 0;
BEGIN
    SELECT INTO max_count max
    FROM config_limits
    WHERE id = 'user_overrides_per_schedule';

    IF max_count = -1 THEN
        RETURN NEW;
    END IF;

    SELECT INTO val_count COUNT(*)
    FROM user_overrides
    WHERE
        tgt_schedule_id = NEW.tgt_schedule_id AND
        end_time > now();

    IF val_count > max_count THEN
        RAISE 'limit exceeded' USING ERRCODE='check_violation', CONSTRAINT='user_overrides_per_schedule_limit', HINT='max='||max_count;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_enforce_user_override_schedule_limit() OWNER TO postgres;

--
-- Name: fn_inc_ep_step_number_on_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_inc_ep_step_number_on_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    LOCK escalation_policy_steps IN EXCLUSIVE MODE;

    SELECT count(*)
    INTO NEW.step_number
    FROM escalation_policy_steps
    WHERE escalation_policy_id = NEW.escalation_policy_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_inc_ep_step_number_on_insert() OWNER TO postgres;

--
-- Name: fn_inc_rot_part_position_on_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_inc_rot_part_position_on_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    LOCK rotation_participants IN EXCLUSIVE MODE;

    SELECT count(*)
    INTO NEW.position
    FROM rotation_participants
    WHERE rotation_id = NEW.rotation_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_inc_rot_part_position_on_insert() OWNER TO postgres;

--
-- Name: fn_incr_ep_step_count_on_add(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_incr_ep_step_count_on_add() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE escalation_policies
    SET step_count = step_count + 1
    WHERE id = NEW.escalation_policy_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_incr_ep_step_count_on_add() OWNER TO postgres;

--
-- Name: fn_incr_part_count_on_add(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_incr_part_count_on_add() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE rotations
    SET participant_count = participant_count + 1
    WHERE id = NEW.rotation_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_incr_part_count_on_add() OWNER TO postgres;

--
-- Name: fn_insert_basic_user(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_insert_basic_user() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    INSERT INTO auth_subjects (provider_id, subject_id, user_id)
    VALUES ('basic', NEW.username, NEW.user_id)
    ON CONFLICT (provider_id, subject_id) DO UPDATE
    SET user_id = NEW.user_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_insert_basic_user() OWNER TO postgres;

--
-- Name: fn_insert_ep_state_on_alert_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_insert_ep_state_on_alert_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    INSERT INTO escalation_policy_state (alert_id, service_id, escalation_policy_id)
    SELECT NEW.id, NEW.service_id, svc.escalation_policy_id
    FROM services svc
    JOIN escalation_policies ep ON ep.id = svc.escalation_policy_id AND ep.step_count > 0
    WHERE svc.id = NEW.service_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_insert_ep_state_on_alert_insert() OWNER TO postgres;

--
-- Name: fn_insert_ep_state_on_step_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_insert_ep_state_on_step_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    INSERT INTO escalation_policy_state (alert_id, service_id, escalation_policy_id)
    SELECT a.id, a.service_id, NEW.escalation_policy_id
    FROM alerts a
    JOIN services svc ON
        svc.id = a.service_id AND
        svc.escalation_policy_id = NEW.escalation_policy_id
    WHERE a.status != 'closed';

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_insert_ep_state_on_step_insert() OWNER TO postgres;

--
-- Name: fn_insert_user_last_alert_log(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_insert_user_last_alert_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    INSERT INTO user_last_alert_log (user_id, alert_id, log_id, next_log_id)
    VALUES (NEW.sub_user_id, NEW.alert_id, NEW.id, NEW.id)
    ON CONFLICT DO NOTHING;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_insert_user_last_alert_log() OWNER TO postgres;

--
-- Name: fn_lock_svc_on_force_escalation(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_lock_svc_on_force_escalation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    -- lock service first
    PERFORM 1
    FROM services svc
    WHERE svc.id = NEW.service_id
    FOR UPDATE;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_lock_svc_on_force_escalation() OWNER TO postgres;

--
-- Name: fn_notification_rule_same_user(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_notification_rule_same_user() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    _cm_user_id UUID;
BEGIN
    SELECT INTO _cm_user_id user_id
    FROM user_contact_methods
    WHERE id = NEW.contact_method_id;

    IF NEW.user_id != _cm_user_id THEN
        RAISE 'wrong user_id' USING ERRCODE='check_violation', CONSTRAINT='notification_rule_user_id_match';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_notification_rule_same_user() OWNER TO postgres;

--
-- Name: fn_notify_config_refresh(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_notify_config_refresh() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        NOTIFY "/goalert/config-refresh";
        RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.fn_notify_config_refresh() OWNER TO postgres;

--
-- Name: fn_prevent_reopen(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_prevent_reopen() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF OLD.status = 'closed' THEN
            RAISE EXCEPTION 'cannot change status of closed alert';
        END IF;
        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.fn_prevent_reopen() OWNER TO postgres;

--
-- Name: fn_set_ep_state_svc_id_on_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_set_ep_state_svc_id_on_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    SELECT service_id INTO NEW.service_id
    FROM alerts
    WHERE id = NEW.alert_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_set_ep_state_svc_id_on_insert() OWNER TO postgres;

--
-- Name: fn_set_rot_state_pos_on_active_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_set_rot_state_pos_on_active_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    SELECT position INTO NEW.position
    FROM rotation_participants
    WHERE id = NEW.rotation_participant_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_set_rot_state_pos_on_active_change() OWNER TO postgres;

--
-- Name: fn_set_rot_state_pos_on_part_reorder(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_set_rot_state_pos_on_part_reorder() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE rotation_state
    SET position = NEW.position
    WHERE rotation_participant_id = NEW.id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_set_rot_state_pos_on_part_reorder() OWNER TO postgres;

--
-- Name: fn_start_rotation_on_first_part_add(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_start_rotation_on_first_part_add() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    first_part UUID;
BEGIN
    SELECT id
    INTO first_part
    FROM rotation_participants
    WHERE rotation_id = NEW.rotation_id AND position = 0;

    INSERT INTO rotation_state (
        rotation_id, rotation_participant_id, shift_start
    ) VALUES (
        NEW.rotation_id, first_part, now()
    ) ON CONFLICT DO NOTHING;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_start_rotation_on_first_part_add() OWNER TO postgres;

--
-- Name: fn_trig_alert_on_force_escalation(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_trig_alert_on_force_escalation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    UPDATE alerts
    SET "status" = 'triggered'
    WHERE id = NEW.alert_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_trig_alert_on_force_escalation() OWNER TO postgres;

--
-- Name: fn_update_user_last_alert_log(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_update_user_last_alert_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    UPDATE user_last_alert_log last
    SET next_log_id = NEW.id
    WHERE
        last.alert_id = NEW.alert_id AND
        NEW.id > last.next_log_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_update_user_last_alert_log() OWNER TO postgres;

--
-- Name: move_escalation_policy_step(uuid, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.move_escalation_policy_step(_id uuid, _new_pos integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
  DECLARE
    _old_pos INT;
    _epid UUID;
  BEGIN
    SELECT step_number, escalation_policy_id into _old_pos, _epid FROM escalation_policy_steps WHERE id = _id;
    IF _old_pos > _new_pos THEN
      UPDATE escalation_policy_steps
      SET step_number = step_number + 1
      WHERE escalation_policy_id = _epid
        AND step_number < _old_pos
        AND step_number >= _new_pos;
    ELSE
      UPDATE escalation_policy_steps
      SET step_number = step_number - 1
      WHERE escalation_policy_id = _epid
        AND step_number > _old_pos
        AND step_number <= _new_pos;
    END IF;
    UPDATE escalation_policy_steps
    SET step_number = _new_pos
    WHERE id = _id;
  END;
  $$;


ALTER FUNCTION public.move_escalation_policy_step(_id uuid, _new_pos integer) OWNER TO postgres;

--
-- Name: move_rotation_position(uuid, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.move_rotation_position(_id uuid, _new_pos integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
    DECLARE
        _old_pos INT;
        _rid UUID;
    BEGIN
        SELECT position,rotation_id into _old_pos, _rid FROM rotation_participants WHERE id = _id;
        IF _old_pos > _new_pos THEN
            UPDATE rotation_participants SET position = position + 1 WHERE rotation_id = _rid AND position < _old_pos AND position >= _new_pos;
        ELSE
            UPDATE rotation_participants SET position = position - 1 WHERE rotation_id = _rid AND position > _old_pos AND position <= _new_pos;
        END IF;
        UPDATE rotation_participants SET position = _new_pos WHERE id = _id;
    END;
    $$;


ALTER FUNCTION public.move_rotation_position(_id uuid, _new_pos integer) OWNER TO postgres;

--
-- Name: release_user_contact_method_lock(uuid, uuid, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.release_user_contact_method_lock(_client_id uuid, _id uuid, success boolean) RETURNS void
    LANGUAGE plpgsql
    AS $$
        BEGIN
            DELETE FROM user_contact_method_locks WHERE id = _id AND client_id = _client_id;
            IF success
            THEN
                UPDATE sent_notifications SET sent_at = now() WHERE id = _id;
            ELSE
                DELETE FROM sent_notifications WHERE id = _id;
            END IF;
        END;
    $$;


ALTER FUNCTION public.release_user_contact_method_lock(_client_id uuid, _id uuid, success boolean) OWNER TO postgres;

--
-- Name: remove_rotation_participant(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.remove_rotation_participant(_id uuid) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
    DECLARE
        _old_pos INT;
        _rid UUID;
    BEGIN
        SELECT position,rotation_id into _old_pos, _rid FROM rotation_participants WHERE id = _id;
        DELETE FROM rotation_participants WHERE id = _id;
        UPDATE rotation_participants SET position = position - 1 WHERE rotation_id = _rid AND position > _old_pos;
        RETURN _rid;
    END;
    $$;


ALTER FUNCTION public.remove_rotation_participant(_id uuid) OWNER TO postgres;

--
-- Name: update_notification_cycles(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_notification_cycles() RETURNS void
    LANGUAGE plpgsql
    AS $$
        BEGIN
			INSERT INTO user_notification_cycles (user_id, alert_id, escalation_level)
			SELECT user_id, alert_id, escalation_level
			FROM on_call_alert_users
			WHERE status = 'triggered'
                AND user_id IS NOT NULL
			ON CONFLICT DO NOTHING;

			UPDATE user_notification_cycles c
			SET escalation_level = a.escalation_level
			FROM
				alerts a,
				user_notification_cycle_state s
			WHERE a.id = c.alert_id
				AND s.user_id = c.user_id
				AND s.alert_id = c.alert_id;

			DELETE FROM user_notification_cycles c
			WHERE (
				SELECT count(notification_rule_id)
				FROM user_notification_cycle_state s
				WHERE s.alert_id = c.alert_id AND s.user_id = c.user_id
				LIMIT 1
			) = 0
				AND c.escalation_level != (SELECT escalation_level FROM alerts WHERE id = c.alert_id);

        END;
    $$;


ALTER FUNCTION public.update_notification_cycles() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alert_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alert_logs (
    id bigint NOT NULL,
    alert_id bigint,
    "timestamp" timestamp with time zone DEFAULT now(),
    event public.enum_alert_log_event NOT NULL,
    message text NOT NULL,
    sub_type public.enum_alert_log_subject_type,
    sub_user_id uuid,
    sub_integration_key_id uuid,
    sub_classifier text DEFAULT ''::text NOT NULL,
    meta json,
    sub_hb_monitor_id uuid,
    sub_channel_id uuid
);


ALTER TABLE public.alert_logs OWNER TO postgres;

--
-- Name: alert_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.alert_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.alert_logs_id_seq OWNER TO postgres;

--
-- Name: alert_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.alert_logs_id_seq OWNED BY public.alert_logs.id;


--
-- Name: alert_metrics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alert_metrics (
    id bigint NOT NULL,
    alert_id bigint NOT NULL,
    service_id uuid NOT NULL,
    time_to_ack interval,
    time_to_close interval,
    escalated boolean DEFAULT false NOT NULL
);


ALTER TABLE public.alert_metrics OWNER TO postgres;

--
-- Name: alert_metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.alert_metrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.alert_metrics_id_seq OWNER TO postgres;

--
-- Name: alert_metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.alert_metrics_id_seq OWNED BY public.alert_metrics.id;


--
-- Name: alert_status_subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alert_status_subscriptions (
    id bigint NOT NULL,
    channel_id uuid,
    contact_method_id uuid,
    alert_id bigint NOT NULL,
    last_alert_status public.enum_alert_status NOT NULL,
    CONSTRAINT alert_status_subscriptions_check CHECK (((channel_id IS NULL) <> (contact_method_id IS NULL)))
);


ALTER TABLE public.alert_status_subscriptions OWNER TO postgres;

--
-- Name: alert_status_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.alert_status_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.alert_status_subscriptions_id_seq OWNER TO postgres;

--
-- Name: alert_status_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.alert_status_subscriptions_id_seq OWNED BY public.alert_status_subscriptions.id;


--
-- Name: alerts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alerts (
    id bigint NOT NULL,
    service_id uuid,
    source public.enum_alert_source DEFAULT 'manual'::public.enum_alert_source NOT NULL,
    status public.enum_alert_status DEFAULT 'triggered'::public.enum_alert_status NOT NULL,
    escalation_level integer DEFAULT 0 NOT NULL,
    last_escalation timestamp with time zone DEFAULT now(),
    last_processed timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    dedup_key text,
    summary text NOT NULL,
    details text DEFAULT ''::text NOT NULL,
    CONSTRAINT dedup_key_only_for_open_alerts CHECK (((status = 'closed'::public.enum_alert_status) = (dedup_key IS NULL)))
);


ALTER TABLE public.alerts OWNER TO postgres;

--
-- Name: alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.alerts_id_seq OWNER TO postgres;

--
-- Name: alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.alerts_id_seq OWNED BY public.alerts.id;


--
-- Name: auth_basic_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_basic_users (
    user_id uuid NOT NULL,
    username text NOT NULL,
    password_hash text NOT NULL,
    id bigint NOT NULL
);


ALTER TABLE public.auth_basic_users OWNER TO postgres;

--
-- Name: auth_basic_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_basic_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_basic_users_id_seq OWNER TO postgres;

--
-- Name: auth_basic_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_basic_users_id_seq OWNED BY public.auth_basic_users.id;


--
-- Name: auth_nonce; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_nonce (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.auth_nonce OWNER TO postgres;

--
-- Name: auth_subjects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_subjects (
    provider_id text NOT NULL,
    subject_id text NOT NULL,
    user_id uuid NOT NULL,
    id bigint NOT NULL
)
WITH (fillfactor='80');


ALTER TABLE public.auth_subjects OWNER TO postgres;

--
-- Name: auth_subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.auth_subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_subjects_id_seq OWNER TO postgres;

--
-- Name: auth_subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.auth_subjects_id_seq OWNED BY public.auth_subjects.id;


--
-- Name: auth_user_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auth_user_sessions (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_agent text DEFAULT ''::text NOT NULL,
    user_id uuid,
    last_access_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.auth_user_sessions OWNER TO postgres;

--
-- Name: config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.config (
    id integer NOT NULL,
    schema integer NOT NULL,
    data bytea NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.config OWNER TO postgres;

--
-- Name: config_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.config_id_seq OWNER TO postgres;

--
-- Name: config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.config_id_seq OWNED BY public.config.id;


--
-- Name: config_limits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.config_limits (
    id public.enum_limit_type NOT NULL,
    max integer DEFAULT '-1'::integer NOT NULL
);


ALTER TABLE public.config_limits OWNER TO postgres;

--
-- Name: engine_processing_versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.engine_processing_versions (
    type_id public.engine_processing_type NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    state jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE public.engine_processing_versions OWNER TO postgres;

--
-- Name: ep_step_on_call_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ep_step_on_call_users (
    user_id uuid NOT NULL,
    ep_step_id uuid NOT NULL,
    start_time timestamp with time zone DEFAULT now() NOT NULL,
    end_time timestamp with time zone,
    id bigint NOT NULL
);


ALTER TABLE public.ep_step_on_call_users OWNER TO postgres;

--
-- Name: ep_step_on_call_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ep_step_on_call_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ep_step_on_call_users_id_seq OWNER TO postgres;

--
-- Name: ep_step_on_call_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ep_step_on_call_users_id_seq OWNED BY public.ep_step_on_call_users.id;


--
-- Name: escalation_policies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.escalation_policies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    repeat integer DEFAULT 0 NOT NULL,
    step_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.escalation_policies OWNER TO postgres;

--
-- Name: escalation_policy_actions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.escalation_policy_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    escalation_policy_step_id uuid NOT NULL,
    user_id uuid,
    schedule_id uuid,
    rotation_id uuid,
    channel_id uuid,
    CONSTRAINT epa_there_can_only_be_one CHECK (((((
CASE
    WHEN (user_id IS NOT NULL) THEN 1
    ELSE 0
END +
CASE
    WHEN (schedule_id IS NOT NULL) THEN 1
    ELSE 0
END) +
CASE
    WHEN (rotation_id IS NOT NULL) THEN 1
    ELSE 0
END) +
CASE
    WHEN (channel_id IS NOT NULL) THEN 1
    ELSE 0
END) = 1))
);


ALTER TABLE public.escalation_policy_actions OWNER TO postgres;

--
-- Name: escalation_policy_state; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.escalation_policy_state (
    escalation_policy_id uuid NOT NULL,
    escalation_policy_step_id uuid,
    escalation_policy_step_number integer DEFAULT 0 NOT NULL,
    alert_id bigint NOT NULL,
    last_escalation timestamp with time zone,
    loop_count integer DEFAULT 0 NOT NULL,
    force_escalation boolean DEFAULT false NOT NULL,
    service_id uuid NOT NULL,
    next_escalation timestamp with time zone,
    id bigint NOT NULL
)
WITH (fillfactor='85');


ALTER TABLE public.escalation_policy_state OWNER TO postgres;

--
-- Name: escalation_policy_state_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.escalation_policy_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.escalation_policy_state_id_seq OWNER TO postgres;

--
-- Name: escalation_policy_state_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.escalation_policy_state_id_seq OWNED BY public.escalation_policy_state.id;


--
-- Name: escalation_policy_steps; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.escalation_policy_steps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    delay integer DEFAULT 1 NOT NULL,
    step_number integer DEFAULT '-1'::integer NOT NULL,
    escalation_policy_id uuid NOT NULL
);


ALTER TABLE public.escalation_policy_steps OWNER TO postgres;

--
-- Name: gorp_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gorp_migrations (
    id text NOT NULL,
    applied_at timestamp with time zone
);


ALTER TABLE public.gorp_migrations OWNER TO postgres;

--
-- Name: heartbeat_monitors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.heartbeat_monitors (
    id uuid NOT NULL,
    name text NOT NULL,
    service_id uuid NOT NULL,
    heartbeat_interval interval NOT NULL,
    last_state public.enum_heartbeat_state DEFAULT 'inactive'::public.enum_heartbeat_state NOT NULL,
    last_heartbeat timestamp with time zone
);


ALTER TABLE public.heartbeat_monitors OWNER TO postgres;

--
-- Name: incident_number_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.incident_number_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.incident_number_seq OWNER TO postgres;

--
-- Name: integration_keys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integration_keys (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    type public.enum_integration_keys_type NOT NULL,
    service_id uuid NOT NULL
);


ALTER TABLE public.integration_keys OWNER TO postgres;

--
-- Name: keyring; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.keyring (
    id text NOT NULL,
    verification_keys bytea NOT NULL,
    signing_key bytea NOT NULL,
    next_key bytea NOT NULL,
    next_rotation timestamp with time zone,
    rotation_count bigint NOT NULL
);


ALTER TABLE public.keyring OWNER TO postgres;

--
-- Name: labels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.labels (
    id bigint NOT NULL,
    tgt_service_id uuid NOT NULL,
    key text NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.labels OWNER TO postgres;

--
-- Name: labels_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.labels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.labels_id_seq OWNER TO postgres;

--
-- Name: labels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.labels_id_seq OWNED BY public.labels.id;


--
-- Name: notification_channels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_channels (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    type public.enum_notif_channel_type NOT NULL,
    name text NOT NULL,
    value text NOT NULL,
    meta jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE public.notification_channels OWNER TO postgres;

--
-- Name: notification_policy_cycles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_policy_cycles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    alert_id integer NOT NULL,
    repeat_count integer DEFAULT 0 NOT NULL,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    checked boolean DEFAULT true NOT NULL,
    last_tick timestamp with time zone
)
WITH (fillfactor='65');


ALTER TABLE public.notification_policy_cycles OWNER TO postgres;

--
-- Name: outgoing_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.outgoing_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    message_type public.enum_outgoing_messages_type NOT NULL,
    contact_method_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_status public.enum_outgoing_messages_status DEFAULT 'pending'::public.enum_outgoing_messages_status NOT NULL,
    last_status_at timestamp with time zone DEFAULT now(),
    status_details text DEFAULT ''::text NOT NULL,
    fired_at timestamp with time zone,
    sent_at timestamp with time zone,
    retry_count integer DEFAULT 0 NOT NULL,
    next_retry_at timestamp with time zone,
    sending_deadline timestamp with time zone,
    user_id uuid,
    alert_id bigint,
    cycle_id uuid,
    service_id uuid,
    escalation_policy_id uuid,
    alert_log_id bigint,
    user_verification_code_id uuid,
    provider_msg_id text,
    provider_seq integer DEFAULT 0 NOT NULL,
    channel_id uuid,
    status_alert_ids bigint[],
    schedule_id uuid,
    src_value text,
    CONSTRAINT om_alert_svc_ep_ids CHECK (((message_type <> 'alert_notification'::public.enum_outgoing_messages_type) OR ((alert_id IS NOT NULL) AND (service_id IS NOT NULL) AND (escalation_policy_id IS NOT NULL)))),
    CONSTRAINT om_no_status_bundles CHECK (((message_type <> 'alert_status_update_bundle'::public.enum_outgoing_messages_type) OR (last_status <> 'pending'::public.enum_outgoing_messages_status))),
    CONSTRAINT om_pending_no_fired_no_sent CHECK (((last_status <> 'pending'::public.enum_outgoing_messages_status) OR ((fired_at IS NULL) AND (sent_at IS NULL)))),
    CONSTRAINT om_processed_no_fired_sent CHECK (((last_status = ANY (ARRAY['pending'::public.enum_outgoing_messages_status, 'sending'::public.enum_outgoing_messages_status, 'failed'::public.enum_outgoing_messages_status, 'bundled'::public.enum_outgoing_messages_status])) OR ((fired_at IS NULL) AND (sent_at IS NOT NULL)))),
    CONSTRAINT om_sending_deadline_reqd CHECK (((last_status <> 'sending'::public.enum_outgoing_messages_status) OR (sending_deadline IS NOT NULL))),
    CONSTRAINT om_sending_fired_no_sent CHECK (((last_status <> 'sending'::public.enum_outgoing_messages_status) OR ((fired_at IS NOT NULL) AND (sent_at IS NULL)))),
    CONSTRAINT om_status_alert_ids CHECK (((message_type <> 'alert_status_update_bundle'::public.enum_outgoing_messages_type) OR (status_alert_ids IS NOT NULL))),
    CONSTRAINT om_status_update_log_id CHECK (((message_type <> 'alert_status_update'::public.enum_outgoing_messages_type) OR (alert_log_id IS NOT NULL))),
    CONSTRAINT om_user_cm_or_channel CHECK ((((user_id IS NOT NULL) AND (contact_method_id IS NOT NULL) AND (channel_id IS NULL)) OR ((channel_id IS NOT NULL) AND (contact_method_id IS NULL) AND (user_id IS NULL)))),
    CONSTRAINT verify_needs_id CHECK (((message_type <> 'verification_message'::public.enum_outgoing_messages_type) OR (user_verification_code_id IS NOT NULL)))
)
WITH (fillfactor='85');


ALTER TABLE public.outgoing_messages OWNER TO postgres;

--
-- Name: region_ids; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.region_ids (
    name text NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.region_ids OWNER TO postgres;

--
-- Name: region_ids_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.region_ids_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.region_ids_id_seq OWNER TO postgres;

--
-- Name: region_ids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.region_ids_id_seq OWNED BY public.region_ids.id;


--
-- Name: rotation_participants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rotation_participants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    rotation_id uuid NOT NULL,
    "position" integer NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.rotation_participants OWNER TO postgres;

--
-- Name: rotation_state; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rotation_state (
    rotation_id uuid NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    rotation_participant_id uuid NOT NULL,
    shift_start timestamp with time zone NOT NULL,
    id bigint NOT NULL,
    version integer DEFAULT 2 NOT NULL
);


ALTER TABLE public.rotation_state OWNER TO postgres;

--
-- Name: rotation_state_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rotation_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rotation_state_id_seq OWNER TO postgres;

--
-- Name: rotation_state_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rotation_state_id_seq OWNED BY public.rotation_state.id;


--
-- Name: rotations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rotations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    type public.enum_rotation_type NOT NULL,
    start_time timestamp with time zone DEFAULT now() NOT NULL,
    shift_length bigint DEFAULT 1 NOT NULL,
    time_zone text NOT NULL,
    last_processed timestamp with time zone,
    participant_count integer DEFAULT 0 NOT NULL,
    CONSTRAINT rotations_shift_length_check CHECK ((shift_length > 0))
);


ALTER TABLE public.rotations OWNER TO postgres;

--
-- Name: schedule_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schedule_data (
    schedule_id uuid NOT NULL,
    last_cleanup_at timestamp with time zone,
    data jsonb NOT NULL,
    id bigint NOT NULL
);


ALTER TABLE public.schedule_data OWNER TO postgres;

--
-- Name: schedule_data_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.schedule_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.schedule_data_id_seq OWNER TO postgres;

--
-- Name: schedule_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.schedule_data_id_seq OWNED BY public.schedule_data.id;


--
-- Name: schedule_on_call_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schedule_on_call_users (
    schedule_id uuid NOT NULL,
    start_time timestamp with time zone DEFAULT now() NOT NULL,
    end_time timestamp with time zone,
    user_id uuid NOT NULL,
    id bigint NOT NULL,
    CONSTRAINT schedule_on_call_users_check CHECK (((end_time IS NULL) OR (end_time > start_time)))
);


ALTER TABLE public.schedule_on_call_users OWNER TO postgres;

--
-- Name: schedule_on_call_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.schedule_on_call_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.schedule_on_call_users_id_seq OWNER TO postgres;

--
-- Name: schedule_on_call_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.schedule_on_call_users_id_seq OWNED BY public.schedule_on_call_users.id;


--
-- Name: schedule_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schedule_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    schedule_id uuid NOT NULL,
    sunday boolean DEFAULT true NOT NULL,
    monday boolean DEFAULT true NOT NULL,
    tuesday boolean DEFAULT true NOT NULL,
    wednesday boolean DEFAULT true NOT NULL,
    thursday boolean DEFAULT true NOT NULL,
    friday boolean DEFAULT true NOT NULL,
    saturday boolean DEFAULT true NOT NULL,
    start_time time without time zone DEFAULT '00:00:00'::time without time zone NOT NULL,
    end_time time without time zone DEFAULT '23:59:59'::time without time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tgt_user_id uuid,
    tgt_rotation_id uuid,
    is_active boolean DEFAULT false NOT NULL,
    CONSTRAINT schedule_rules_check CHECK ((((tgt_user_id IS NULL) AND (tgt_rotation_id IS NOT NULL)) OR ((tgt_user_id IS NOT NULL) AND (tgt_rotation_id IS NULL))))
);


ALTER TABLE public.schedule_rules OWNER TO postgres;

--
-- Name: schedules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schedules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    time_zone text NOT NULL,
    last_processed timestamp with time zone
);


ALTER TABLE public.schedules OWNER TO postgres;

--
-- Name: services; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.services (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    escalation_policy_id uuid NOT NULL
);


ALTER TABLE public.services OWNER TO postgres;

--
-- Name: switchover_state; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.switchover_state (
    ok boolean NOT NULL,
    current_state public.enum_switchover_state NOT NULL,
    CONSTRAINT switchover_state_ok_check CHECK (ok)
);


ALTER TABLE public.switchover_state OWNER TO postgres;

--
-- Name: twilio_sms_callbacks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.twilio_sms_callbacks (
    phone_number text NOT NULL,
    callback_id uuid NOT NULL,
    code integer NOT NULL,
    id bigint NOT NULL,
    sent_at timestamp with time zone DEFAULT now() NOT NULL,
    alert_id bigint,
    service_id uuid
);


ALTER TABLE public.twilio_sms_callbacks OWNER TO postgres;

--
-- Name: twilio_sms_callbacks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.twilio_sms_callbacks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.twilio_sms_callbacks_id_seq OWNER TO postgres;

--
-- Name: twilio_sms_callbacks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.twilio_sms_callbacks_id_seq OWNED BY public.twilio_sms_callbacks.id;


--
-- Name: twilio_sms_errors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.twilio_sms_errors (
    phone_number text NOT NULL,
    error_message text NOT NULL,
    outgoing boolean NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    id bigint NOT NULL
);


ALTER TABLE public.twilio_sms_errors OWNER TO postgres;

--
-- Name: twilio_sms_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.twilio_sms_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.twilio_sms_errors_id_seq OWNER TO postgres;

--
-- Name: twilio_sms_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.twilio_sms_errors_id_seq OWNED BY public.twilio_sms_errors.id;


--
-- Name: twilio_voice_errors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.twilio_voice_errors (
    phone_number text NOT NULL,
    error_message text NOT NULL,
    outgoing boolean NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    id bigint NOT NULL
);


ALTER TABLE public.twilio_voice_errors OWNER TO postgres;

--
-- Name: twilio_voice_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.twilio_voice_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.twilio_voice_errors_id_seq OWNER TO postgres;

--
-- Name: twilio_voice_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.twilio_voice_errors_id_seq OWNED BY public.twilio_voice_errors.id;


--
-- Name: user_calendar_subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_calendar_subscriptions (
    id uuid NOT NULL,
    name text NOT NULL,
    user_id uuid NOT NULL,
    last_access timestamp with time zone,
    last_update timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    disabled boolean DEFAULT false NOT NULL,
    schedule_id uuid NOT NULL,
    config jsonb NOT NULL
);


ALTER TABLE public.user_calendar_subscriptions OWNER TO postgres;

--
-- Name: user_contact_methods; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_contact_methods (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    type public.enum_user_contact_method_type NOT NULL,
    value text NOT NULL,
    disabled boolean DEFAULT false NOT NULL,
    user_id uuid NOT NULL,
    last_test_verify_at timestamp with time zone,
    metadata jsonb
);


ALTER TABLE public.user_contact_methods OWNER TO postgres;

--
-- Name: user_favorites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_favorites (
    user_id uuid NOT NULL,
    tgt_service_id uuid,
    id bigint NOT NULL,
    tgt_rotation_id uuid,
    tgt_schedule_id uuid,
    tgt_escalation_policy_id uuid,
    tgt_user_id uuid
);


ALTER TABLE public.user_favorites OWNER TO postgres;

--
-- Name: user_favorites_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_favorites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_favorites_id_seq OWNER TO postgres;

--
-- Name: user_favorites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_favorites_id_seq OWNED BY public.user_favorites.id;


--
-- Name: user_notification_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_notification_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    delay_minutes integer DEFAULT 0 NOT NULL,
    contact_method_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.user_notification_rules OWNER TO postgres;

--
-- Name: user_overrides; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_overrides (
    id uuid NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    add_user_id uuid,
    remove_user_id uuid,
    tgt_schedule_id uuid NOT NULL,
    CONSTRAINT user_overrides_check CHECK ((end_time > start_time)),
    CONSTRAINT user_overrides_check1 CHECK ((COALESCE(add_user_id, remove_user_id) IS NOT NULL)),
    CONSTRAINT user_overrides_check2 CHECK ((add_user_id <> remove_user_id))
);


ALTER TABLE public.user_overrides OWNER TO postgres;

--
-- Name: user_slack_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_slack_data (
    id uuid NOT NULL,
    access_token text NOT NULL
);


ALTER TABLE public.user_slack_data OWNER TO postgres;

--
-- Name: user_verification_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_verification_codes (
    id uuid NOT NULL,
    code integer NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    contact_method_id uuid NOT NULL,
    sent boolean DEFAULT false NOT NULL
);


ALTER TABLE public.user_verification_codes OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    bio text DEFAULT ''::text NOT NULL,
    email text DEFAULT ''::text NOT NULL,
    role public.enum_user_role DEFAULT 'unknown'::public.enum_user_role NOT NULL,
    name text NOT NULL,
    avatar_url text DEFAULT ''::text NOT NULL,
    alert_status_log_contact_method_id uuid
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: alert_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_logs ALTER COLUMN id SET DEFAULT nextval('public.alert_logs_id_seq'::regclass);


--
-- Name: alert_metrics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_metrics ALTER COLUMN id SET DEFAULT nextval('public.alert_metrics_id_seq'::regclass);


--
-- Name: alert_status_subscriptions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_status_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.alert_status_subscriptions_id_seq'::regclass);


--
-- Name: alerts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts ALTER COLUMN id SET DEFAULT nextval('public.alerts_id_seq'::regclass);


--
-- Name: auth_basic_users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_basic_users ALTER COLUMN id SET DEFAULT nextval('public.auth_basic_users_id_seq'::regclass);


--
-- Name: auth_subjects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_subjects ALTER COLUMN id SET DEFAULT nextval('public.auth_subjects_id_seq'::regclass);


--
-- Name: config id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.config ALTER COLUMN id SET DEFAULT nextval('public.config_id_seq'::regclass);


--
-- Name: ep_step_on_call_users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ep_step_on_call_users ALTER COLUMN id SET DEFAULT nextval('public.ep_step_on_call_users_id_seq'::regclass);


--
-- Name: escalation_policy_state id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_state ALTER COLUMN id SET DEFAULT nextval('public.escalation_policy_state_id_seq'::regclass);


--
-- Name: labels id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.labels ALTER COLUMN id SET DEFAULT nextval('public.labels_id_seq'::regclass);


--
-- Name: region_ids id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.region_ids ALTER COLUMN id SET DEFAULT nextval('public.region_ids_id_seq'::regclass);


--
-- Name: rotation_state id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rotation_state ALTER COLUMN id SET DEFAULT nextval('public.rotation_state_id_seq'::regclass);


--
-- Name: schedule_data id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_data ALTER COLUMN id SET DEFAULT nextval('public.schedule_data_id_seq'::regclass);


--
-- Name: schedule_on_call_users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_on_call_users ALTER COLUMN id SET DEFAULT nextval('public.schedule_on_call_users_id_seq'::regclass);


--
-- Name: twilio_sms_callbacks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.twilio_sms_callbacks ALTER COLUMN id SET DEFAULT nextval('public.twilio_sms_callbacks_id_seq'::regclass);


--
-- Name: twilio_sms_errors id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.twilio_sms_errors ALTER COLUMN id SET DEFAULT nextval('public.twilio_sms_errors_id_seq'::regclass);


--
-- Name: twilio_voice_errors id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.twilio_voice_errors ALTER COLUMN id SET DEFAULT nextval('public.twilio_voice_errors_id_seq'::regclass);


--
-- Name: user_favorites id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites ALTER COLUMN id SET DEFAULT nextval('public.user_favorites_id_seq'::regclass);


--
-- Data for Name: alert_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alert_logs (id, alert_id, "timestamp", event, message, sub_type, sub_user_id, sub_integration_key_id, sub_classifier, meta, sub_hb_monitor_id, sub_channel_id) FROM stdin;
1	79672	2022-03-28 13:19:51.750287+00	created	Created by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	{"EPNoSteps":false}	\N	\N
2	79672	2022-03-28 13:19:54.717206+00	escalated	Escalated to step #1	\N	\N	\N		{"NewStepIndex":0,"Repeat":false,"Forced":false,"Deleted":false,"OldDelayMinutes":0,"NoOneOnCall":false}	\N	\N
3	79672	2022-03-28 13:19:56.711274+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"064590e1-2d21-4c10-a320-6d33e1817a77"}	\N	\N
4	79672	2022-03-28 13:20:33.137363+00	acknowledged	Acknowledged by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
5	79672	2022-03-28 13:21:03.077041+00	escalation_request	Escalation requested by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
6	79672	2022-03-28 13:21:04.758586+00	escalated	Escalated to step #1 (policy repeat) due to manual escalation	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":true,"Deleted":false,"OldDelayMinutes":5,"NoOneOnCall":false}	\N	\N
7	79672	2022-03-28 13:21:06.916383+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"d5bc08f6-e663-4981-a71d-c61413776616"}	\N	\N
8	79672	2022-03-28 13:26:04.759494+00	escalated	Escalated to step #1 (policy repeat) automatically after 5 minutes	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":false,"Deleted":false,"OldDelayMinutes":5,"NoOneOnCall":false}	\N	\N
9	79672	2022-03-28 13:26:06.788391+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"6c274572-5040-4deb-a23b-262db0923d7a"}	\N	\N
10	79672	2022-03-28 13:27:06.559193+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"cbe29367-6ae3-4c25-aeb7-9292f116dba9"}	\N	\N
11	79672	2022-03-28 13:28:09.179878+00	acknowledged	Acknowledged by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
12	79672	2022-03-28 13:28:17.039413+00	escalation_request	Escalation requested by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
13	79672	2022-03-28 13:28:19.942198+00	escalated	Escalated to step #1 (policy repeat) due to manual escalation	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":true,"Deleted":false,"OldDelayMinutes":5,"NoOneOnCall":false}	\N	\N
14	79672	2022-03-28 13:28:22.106125+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"2f0a36c3-5634-48e2-89b1-c9e2c20fdc51"}	\N	\N
15	79672	2022-03-28 13:32:05.50452+00	acknowledged	Acknowledged by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
16	79673	2022-03-29 05:39:17.265827+00	created	Created via [unknown] integration (Grafana)	integration_key	\N	e8da7b1f-68be-4124-a357-62f0e6e32614	Grafana	{"EPNoSteps":false}	\N	\N
17	79673	2022-03-29 05:39:18.032405+00	escalated	Escalated to step #1	\N	\N	\N		{"NewStepIndex":0,"Repeat":false,"Forced":false,"Deleted":false,"OldDelayMinutes":0,"NoOneOnCall":false}	\N	\N
18	79673	2022-03-29 05:39:20.312368+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"b34be805-5470-4e3e-a6fb-bf5c0270895d"}	\N	\N
19	79673	2022-03-29 05:40:16.195294+00	acknowledged	Acknowledged by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
20	79673	2022-03-29 05:40:31.215529+00	escalation_request	Escalation requested by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
21	79673	2022-03-29 05:40:32.346131+00	acknowledged	Acknowledged by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
22	79673	2022-03-29 05:40:33.041448+00	escalated	Escalated to step #1 (policy repeat) due to manual escalation	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":true,"Deleted":false,"OldDelayMinutes":8,"NoOneOnCall":false}	\N	\N
23	79673	2022-03-29 08:47:52.717263+00	duplicate_suppressed	Suppressed duplicate: created via [unknown] integration (Grafana)	integration_key	\N	e8da7b1f-68be-4124-a357-62f0e6e32614	Grafana	{"EPNoSteps":false}	\N	\N
24	79673	2022-03-29 09:13:21.80349+00	duplicate_suppressed	Suppressed duplicate: created via [unknown] integration (Grafana)	integration_key	\N	e8da7b1f-68be-4124-a357-62f0e6e32614	Grafana	{"EPNoSteps":false}	\N	\N
25	79673	2022-03-29 14:02:03.499701+00	escalation_request	Escalation requested by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
26	79673	2022-03-29 14:02:04.635388+00	escalated	Escalated to step #1 (policy repeat) due to manual escalation	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":true,"Deleted":false,"OldDelayMinutes":8,"NoOneOnCall":false}	\N	\N
27	79673	2022-03-29 14:02:07.362973+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"36f15d2b-fbf2-4b7d-a27d-3f32fa699ae5"}	\N	\N
28	79673	2022-03-29 14:03:01.548539+00	acknowledged	Acknowledged by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
29	79673	2022-03-29 14:14:13.912061+00	escalation_request	Escalation requested by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
30	79673	2022-03-29 14:14:14.437617+00	escalated	Escalated to step #1 (policy repeat) due to manual escalation	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":true,"Deleted":false,"OldDelayMinutes":1,"NoOneOnCall":false}	\N	\N
31	79673	2022-03-29 14:14:16.554836+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"81531730-ea2a-4251-8475-b5a1b96a1a4a"}	\N	\N
32	79673	2022-03-29 14:14:35.36419+00	acknowledged	Acknowledged by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
33	79673	2022-03-29 14:14:46.645514+00	closed	Closed by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
34	79674	2022-03-29 14:21:00.405403+00	created	Created by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	{"EPNoSteps":true}	\N	\N
35	79674	2022-03-29 14:32:02.003593+00	acknowledged	Acknowledged by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
36	79674	2022-03-29 14:32:05.384009+00	closed	Closed by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
37	79675	2022-03-29 14:33:31.58286+00	created	Created by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	{"EPNoSteps":true}	\N	\N
38	79675	2022-03-29 14:34:53.694427+00	policy_updated	Policy updated by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	null	\N	\N
39	79675	2022-03-29 14:34:54.42983+00	escalated	Escalated to step #1	\N	\N	\N		{"NewStepIndex":0,"Repeat":false,"Forced":false,"Deleted":false,"OldDelayMinutes":0,"NoOneOnCall":false}	\N	\N
40	79675	2022-03-29 14:34:56.485712+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"a1b23a7c-c438-4e4d-8eb1-0d6eb9829fa9"}	\N	\N
41	79675	2022-03-29 14:35:54.433411+00	escalated	Escalated to step #1 (policy repeat) automatically after 1 minutes	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":false,"Deleted":false,"OldDelayMinutes":1,"NoOneOnCall":false}	\N	\N
42	79675	2022-03-29 14:36:01.393169+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"aa75c6ae-6dee-4205-b245-31b0dd6fea17"}	\N	\N
43	79675	2022-03-29 14:36:23.004909+00	acknowledged	Acknowledged by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
44	79675	2022-03-29 14:38:56.819283+00	closed	Closed by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
45	79672	2022-03-29 14:38:56.819283+00	closed	Closed by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
46	79676	2022-03-29 14:39:22.564384+00	created	Created by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	{"EPNoSteps":false}	\N	\N
47	79676	2022-03-29 14:39:24.541578+00	escalated	Escalated to step #1	\N	\N	\N		{"NewStepIndex":0,"Repeat":false,"Forced":false,"Deleted":false,"OldDelayMinutes":0,"NoOneOnCall":false}	\N	\N
48	79676	2022-03-29 14:39:26.647726+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"fb1452b9-255b-423b-989e-24353490b41a"}	\N	\N
49	79676	2022-03-29 14:39:35.888338+00	acknowledged	Acknowledged by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
50	79677	2022-03-29 14:44:17.969203+00	created	Created via [unknown] integration	integration_key	\N	b76ba992-a4d3-492d-b449-4abd1ca5a205		{"EPNoSteps":false}	\N	\N
51	79677	2022-03-29 14:44:19.420447+00	escalated	Escalated to step #1	\N	\N	\N		{"NewStepIndex":0,"Repeat":false,"Forced":false,"Deleted":false,"OldDelayMinutes":0,"NoOneOnCall":false}	\N	\N
55	79677	2022-03-29 14:46:19.428561+00	escalated	Escalated to step #1 (policy repeat) automatically after 1 minutes	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":false,"Deleted":false,"OldDelayMinutes":1,"NoOneOnCall":false}	\N	\N
57	79677	2022-03-29 14:49:56.841261+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"ab0221a1-03bb-456a-822d-5e4f938d89c0"}	\N	\N
61	79678	2022-03-29 15:09:47.483125+00	created	Created via [unknown] integration	integration_key	\N	b76ba992-a4d3-492d-b449-4abd1ca5a205		{"EPNoSteps":false}	\N	\N
65	79679	2022-03-29 15:34:40.629816+00	created	Created via [unknown] integration (Grafana)	integration_key	\N	e8da7b1f-68be-4124-a357-62f0e6e32614	Grafana	{"EPNoSteps":false}	\N	\N
66	79679	2022-03-29 15:34:44.4198+00	escalated	Escalated to step #1	\N	\N	\N		{"NewStepIndex":0,"Repeat":false,"Forced":false,"Deleted":false,"OldDelayMinutes":0,"NoOneOnCall":false}	\N	\N
67	79679	2022-03-29 15:34:46.347556+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"5e14d2ea-08a1-4338-9a63-f4e18bfacd64"}	\N	\N
52	79677	2022-03-29 14:44:21.560571+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"60bb6f3f-4eaf-4973-8da0-63db6136feb6"}	\N	\N
56	79677	2022-03-29 14:47:24.425793+00	escalated	Escalated to step #1 (policy repeat) automatically after 1 minutes	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":false,"Deleted":false,"OldDelayMinutes":1,"NoOneOnCall":false}	\N	\N
53	79677	2022-03-29 14:45:19.427903+00	escalated	Escalated to step #1 (policy repeat) automatically after 1 minutes	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":false,"Deleted":false,"OldDelayMinutes":1,"NoOneOnCall":false}	\N	\N
54	79677	2022-03-29 14:45:26.379777+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"3ffd1153-2c7b-4c51-b62d-cb1a41bcc6a4"}	\N	\N
58	79677	2022-03-29 14:51:01.65497+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"f1c2ae43-f592-46c4-ba18-a4c6d8e9b4bb"}	\N	\N
59	79677	2022-03-29 14:53:25.879456+00	duplicate_suppressed	Suppressed duplicate: created via [unknown] integration	integration_key	\N	b76ba992-a4d3-492d-b449-4abd1ca5a205		{"EPNoSteps":false}	\N	\N
60	79677	2022-03-29 14:54:31.238628+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"4ce8cbe1-cd73-4e96-84c1-b183b560386b"}	\N	\N
62	79678	2022-03-29 15:09:49.421027+00	escalated	Escalated to step #1	\N	\N	\N		{"NewStepIndex":0,"Repeat":false,"Forced":false,"Deleted":false,"OldDelayMinutes":0,"NoOneOnCall":false}	\N	\N
63	79678	2022-03-29 15:09:51.410664+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"e5c2fdf8-c5ce-4c57-8cde-74a69984f7fe"}	\N	\N
64	79678	2022-03-29 15:10:47.473786+00	closed	Closed via [unknown] integration	integration_key	\N	b76ba992-a4d3-492d-b449-4abd1ca5a205		\N	\N	\N
68	79679	2022-03-29 15:35:49.428561+00	escalated	Escalated to step #1 (policy repeat) automatically after 1 minutes	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":false,"Deleted":false,"OldDelayMinutes":1,"NoOneOnCall":false}	\N	\N
69	79679	2022-03-29 15:35:51.285503+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"f65a21d9-f7d3-45b4-8cf0-4ac946095e32"}	\N	\N
70	79679	2022-03-29 15:36:38.354824+00	acknowledged	Acknowledged by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
71	79677	2022-03-29 15:49:17.47449+00	acknowledged	Acknowledged by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
72	79680	2022-03-30 05:17:53.798641+00	created	Created via [unknown] integration	integration_key	\N	b76ba992-a4d3-492d-b449-4abd1ca5a205		{"EPNoSteps":false}	\N	\N
73	79680	2022-03-30 05:17:54.873557+00	escalated	Escalated to step #1	\N	\N	\N		{"NewStepIndex":0,"Repeat":false,"Forced":false,"Deleted":false,"OldDelayMinutes":0,"NoOneOnCall":false}	\N	\N
74	79680	2022-03-30 05:17:57.251213+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"2e228e5d-0e1d-462f-acdf-7bda57d2e2ae"}	\N	\N
75	79680	2022-03-30 05:18:58.87307+00	escalated	Escalated to step #1 (policy repeat) automatically after 1 minutes	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":false,"Deleted":false,"OldDelayMinutes":1,"NoOneOnCall":false}	\N	\N
76	79680	2022-03-30 05:19:01.122493+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"93c5934c-ff67-4464-a105-61a47e48b140"}	\N	\N
77	79680	2022-03-30 05:19:59.115603+00	escalated	Escalated to step #1 (policy repeat) automatically after 1 minutes	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":false,"Deleted":false,"OldDelayMinutes":1,"NoOneOnCall":false}	\N	\N
78	79680	2022-03-30 05:20:00.907069+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"771dac47-7a8f-44f1-9d99-5cb4795c8ae5"}	\N	\N
79	79680	2022-03-30 05:20:59.143113+00	escalated	Escalated to step #1 (policy repeat) automatically after 1 minutes	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":false,"Deleted":false,"OldDelayMinutes":1,"NoOneOnCall":false}	\N	\N
80	79680	2022-03-30 05:21:06.893004+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"d03533d2-9c99-48bd-88f2-f4aecdb4836c"}	\N	\N
81	79680	2022-03-30 05:21:56.768464+00	acknowledged	Acknowledged by [unknown] (Web)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	Web	\N	\N	\N
82	79681	2022-03-30 06:01:54.387778+00	created	Created via [unknown] integration	integration_key	\N	b76ba992-a4d3-492d-b449-4abd1ca5a205		{"EPNoSteps":false}	\N	\N
83	79681	2022-03-30 06:02:06.292851+00	escalated	Escalated to step #1	\N	\N	\N		{"NewStepIndex":0,"Repeat":false,"Forced":false,"Deleted":false,"OldDelayMinutes":0,"NoOneOnCall":false}	\N	\N
84	79681	2022-03-30 06:02:08.629359+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"3551a9e7-34b6-4aa2-949e-b3aa260d2e41"}	\N	\N
85	79681	2022-03-30 06:03:09.232467+00	escalated	Escalated to step #1 (policy repeat) automatically after 1 minutes	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":false,"Deleted":false,"OldDelayMinutes":1,"NoOneOnCall":false}	\N	\N
86	79681	2022-03-30 06:03:11.611027+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"0f872cb1-3a92-4cd3-ade7-3a644618833f"}	\N	\N
87	79681	2022-03-30 06:08:12.964435+00	escalated	Escalated to step #1 (policy repeat) automatically after 1 minutes	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":false,"Deleted":false,"OldDelayMinutes":1,"NoOneOnCall":false}	\N	\N
88	79681	2022-03-30 06:08:15.424234+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"cb16d29f-bc99-44d0-92ef-e55e8b6f5c7f"}	\N	\N
89	79681	2022-03-30 06:09:13.844361+00	escalated	Escalated to step #1 (policy repeat) automatically after 1 minutes	\N	\N	\N		{"NewStepIndex":0,"Repeat":true,"Forced":false,"Deleted":false,"OldDelayMinutes":1,"NoOneOnCall":false}	\N	\N
90	79681	2022-03-30 06:09:15.388384+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"7d6e8b4e-06f2-4429-9ba2-eb122282140b"}	\N	\N
91	79681	2022-03-30 06:13:22.393677+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"a4f6f84e-8fbe-459b-bb50-3c19797708a6"}	\N	\N
92	79681	2022-03-30 06:17:10.95609+00	notification_sent	Notification sent to [unknown] (SMS)	user	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	SMS	{"MessageID":"25f7e277-fe11-4122-9651-24e517c7ac08"}	\N	\N
\.


--
-- Data for Name: alert_metrics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alert_metrics (id, alert_id, service_id, time_to_ack, time_to_close, escalated) FROM stdin;
76910	79673	66f85992-4ad0-4f05-9a20-54e8587900fa	00:00:58.929467	08:35:29.379687	t
76911	79674	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	00:11:01.59819	00:11:04.978606	f
76912	79672	bf3124c9-722e-42fb-9177-eff6a7008bf8	00:00:41.387076	1 day 01:19:05.068996	t
76913	79675	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	00:02:51.422049	00:05:25.236423	t
76914	79678	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	\N	00:00:59.990661	f
\.


--
-- Data for Name: alert_status_subscriptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alert_status_subscriptions (id, channel_id, contact_method_id, alert_id, last_alert_status) FROM stdin;
4	\N	be681185-17ba-4cfa-8759-c8c15fa5f693	79676	active
7	\N	be681185-17ba-4cfa-8759-c8c15fa5f693	79679	active
5	\N	be681185-17ba-4cfa-8759-c8c15fa5f693	79677	active
8	\N	be681185-17ba-4cfa-8759-c8c15fa5f693	79680	active
9	\N	be681185-17ba-4cfa-8759-c8c15fa5f693	79681	triggered
\.


--
-- Data for Name: alerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alerts (id, service_id, source, status, escalation_level, last_escalation, last_processed, created_at, dedup_key, summary, details) FROM stdin;
79673	66f85992-4ad0-4f05-9a20-54e8587900fa	grafana	closed	0	2022-03-29 05:39:17.265827+00	\N	2022-03-29 05:39:17.265827+00	\N	Test notification	http://localhost:3000/\n\nSomeone is testing the alert notification within Grafana.
79674	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	manual	closed	0	2022-03-29 14:21:00.405403+00	\N	2022-03-29 14:21:00.405403+00	\N	test_aleert	
79675	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	manual	closed	0	2022-03-29 14:33:31.58286+00	\N	2022-03-29 14:33:31.58286+00	\N	first_alert	
79672	bf3124c9-722e-42fb-9177-eff6a7008bf8	manual	closed	0	2022-03-28 13:19:51.750287+00	\N	2022-03-28 13:19:51.750287+00	\N	sample_alert	
79676	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	manual	active	0	2022-03-29 14:39:22.564384+00	\N	2022-03-29 14:39:22.564384+00	auto:1:104642fe04cd432d12e979a4ffcd2270ed4d36c6dabaf9cbea850c3ff4e416c5d1f1a5f582333e3874daa5cc8c7ed886d751d423947768ceea1c41e3424e3c52	test one	
79677	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	prometheusAlertmanager	active	0	2022-03-29 14:44:17.969203+00	\N	2022-03-29 14:44:17.969203+00	user:1:InstanceDown 35.154.26.190:3000,35.154.26.190:9100,35.154.26.190:9090	InstanceDown 35.154.26.190:3000,35.154.26.190:9100,35.154.26.190:9090	[Prometheus Alertmanager UI](http://ip-172-31-41-41:9093)\n\nInstanceDown 35.154.26.190:3000 [View](http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0&g0.tab=1)\n\nInstanceDown 35.154.26.190:9100 [View](http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0&g0.tab=1)\n\nInstanceDown 35.154.26.190:9090 [View](http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0&g0.tab=1)\n\n## Payload\n\n```json\n{\n  "receiver": "web\\\\.hook",\n  "status": "firing",\n  "alerts": [\n    {\n      "status": "resolved",\n      "labels": {\n        "alertname": "InstanceDown",\n        "instance": "35.154.26.190:3000",\n        "job": "graffana"\n      },\n      "annotations": {},\n      "startsAt": "2022-03-29T14:43:47.413Z",\n      "endsAt": "2022-03-29T14:44:02.413Z",\n      "generatorURL": "http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0\\u0026g0.tab=1",\n      "fingerprint": "414c6765fd10b194"\n    },\n    {\n      "status": "firing",\n      "labels": {\n        "alertname": "InstanceDown",\n        "instance": "35.154.26.190:9100",\n        "job": "node_exporter"\n      },\n      "annotations": {},\n      "startsAt": "2022-03-29T14:43:47.413Z",\n      "endsAt": "0001-01-01T00:00:00Z",\n      "generatorURL": "http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0\\u0026g0.tab=1",\n      "fingerprint": "2ac45f602535309f"\n    },\n    {\n      "status": "resolved",\n      "labels": {\n        "alertname": "InstanceDown",\n        "instance": "35.154.26.190:9090",\n        "job": "prometheus"\n      },\n      "annotations": {},\n      "startsAt": "2022-03-29T14:43:47.413Z",\n      "endsAt": "2022-03-29T14:44:02.413Z",\n      "generatorURL": "http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0\\u0026g0.tab=1",\n      "fingerprint": "8fd9d7f719fe5165"\n    }\n  ],\n  "groupLabels": {\n    "alertname": "InstanceDown"\n  },\n  "commonLabels": {\n    "alertname": "InstanceDown"\n  },\n  "commonAnnotations": {},\n  "externalURL": "http://ip-172-31-41-41:9093",\n  "version": "4",\n  "groupKey": "{}:{alertname=\\"InstanceDown\\"}",\n  "truncatedAlerts": 0\n}\n\n```
79678	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	prometheusAlertmanager	closed	0	2022-03-29 15:09:47.483125+00	\N	2022-03-29 15:09:47.483125+00	\N	InstanceDown 35.154.26.190:9100	[Prometheus Alertmanager UI](http://ip-172-31-41-41:9093)\n\nInstanceDown 35.154.26.190:9100 [View](http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0&g0.tab=1)\n\n## Payload\n\n```json\n{\n  "receiver": "web\\\\.hook",\n  "status": "firing",\n  "alerts": [\n    {\n      "status": "firing",\n      "labels": {\n        "alertname": "InstanceDown",\n        "instance": "35.154.26.190:9100",\n        "job": "node_exporter"\n      },\n      "annotations": {},\n      "startsAt": "2022-03-29T15:09:17.413Z",\n      "endsAt": "0001-01-01T00:00:00Z",\n      "generatorURL": "http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0\\u0026g0.tab=1",\n      "fingerprint": "2ac45f602535309f"\n    }\n  ],\n  "groupLabels": {\n    "alertname": "InstanceDown"\n  },\n  "commonLabels": {\n    "alertname": "InstanceDown",\n    "instance": "35.154.26.190:9100",\n    "job": "node_exporter"\n  },\n  "commonAnnotations": {},\n  "externalURL": "http://ip-172-31-41-41:9093",\n  "version": "4",\n  "groupKey": "{}:{alertname=\\"InstanceDown\\"}",\n  "truncatedAlerts": 0\n}\n\n```
79679	66f85992-4ad0-4f05-9a20-54e8587900fa	grafana	active	0	2022-03-29 15:34:40.629816+00	\N	2022-03-29 15:34:40.629816+00	auto:1:e5863b29d00678f1f55eba2fc7a0d282c4ba36565431e3ccacacb2a4812bf4c7f8acde55cd50cbe5a1216eea891c218453c2e40cf0e77967199359cec2abb5f5	Test notification	http://localhost:3000/\n\nSomeone is testing the alert notification within Grafana.
79680	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	prometheusAlertmanager	active	0	2022-03-30 05:17:53.798641+00	\N	2022-03-30 05:17:53.798641+00	user:1:InstanceDown 35.154.26.190:9093,35.154.26.190:3000,35.154.26.190:9187	InstanceDown 35.154.26.190:9093,35.154.26.190:3000,35.154.26.190:9187	[Prometheus Alertmanager UI](http://ip-172-31-41-41:9093)\n\nInstanceDown 35.154.26.190:9093 [View](http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0&g0.tab=1)\n\nInstanceDown 35.154.26.190:3000 [View](http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0&g0.tab=1)\n\nInstanceDown 35.154.26.190:9187 [View](http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0&g0.tab=1)\n\n## Payload\n\n```json\n{\n  "receiver": "web\\\\.hook",\n  "status": "firing",\n  "alerts": [\n    {\n      "status": "firing",\n      "labels": {\n        "alertname": "InstanceDown",\n        "instance": "35.154.26.190:9093",\n        "job": "alertmanager"\n      },\n      "annotations": {},\n      "startsAt": "2022-03-30T05:17:47.413Z",\n      "endsAt": "0001-01-01T00:00:00Z",\n      "generatorURL": "http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0\\u0026g0.tab=1",\n      "fingerprint": "a89dd2e376f0c1f7"\n    },\n    {\n      "status": "resolved",\n      "labels": {\n        "alertname": "InstanceDown",\n        "instance": "35.154.26.190:3000",\n        "job": "graffana"\n      },\n      "annotations": {},\n      "startsAt": "2022-03-30T05:13:47.413Z",\n      "endsAt": "2022-03-30T05:14:02.413Z",\n      "generatorURL": "http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0\\u0026g0.tab=1",\n      "fingerprint": "414c6765fd10b194"\n    },\n    {\n      "status": "resolved",\n      "labels": {\n        "alertname": "InstanceDown",\n        "instance": "35.154.26.190:9187",\n        "job": "postgres_exporter"\n      },\n      "annotations": {},\n      "startsAt": "2022-03-30T05:13:47.413Z",\n      "endsAt": "2022-03-30T05:14:02.413Z",\n      "generatorURL": "http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0\\u0026g0.tab=1",\n      "fingerprint": "5085e967177034cb"\n    }\n  ],\n  "groupLabels": {\n    "alertname": "InstanceDown"\n  },\n  "commonLabels": {\n    "alertname": "InstanceDown"\n  },\n  "commonAnnotations": {},\n  "externalURL": "http://ip-172-31-41-41:9093",\n  "version": "4",\n  "groupKey": "{}:{alertname=\\"InstanceDown\\"}",\n  "truncatedAlerts": 0\n}\n\n```
79681	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	prometheusAlertmanager	triggered	0	2022-03-30 06:01:54.387778+00	\N	2022-03-30 06:01:54.387778+00	user:1:InstanceDown 35.154.26.190:3000	InstanceDown 35.154.26.190:3000	[Prometheus Alertmanager UI](http://ip-172-31-41-41:9093)\n\nInstanceDown 35.154.26.190:3000 [View](http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0&g0.tab=1)\n\n## Payload\n\n```json\n{\n  "receiver": "web\\\\.hook",\n  "status": "firing",\n  "alerts": [\n    {\n      "status": "firing",\n      "labels": {\n        "alertname": "InstanceDown",\n        "instance": "35.154.26.190:3000",\n        "job": "graffana"\n      },\n      "annotations": {},\n      "startsAt": "2022-03-30T06:00:32.413Z",\n      "endsAt": "0001-01-01T00:00:00Z",\n      "generatorURL": "http://ip-172-31-41-41:9090/graph?g0.expr=up+%3D%3D+0\\u0026g0.tab=1",\n      "fingerprint": "414c6765fd10b194"\n    }\n  ],\n  "groupLabels": {\n    "alertname": "InstanceDown"\n  },\n  "commonLabels": {\n    "alertname": "InstanceDown",\n    "instance": "35.154.26.190:3000",\n    "job": "graffana"\n  },\n  "commonAnnotations": {},\n  "externalURL": "http://ip-172-31-41-41:9093",\n  "version": "4",\n  "groupKey": "{}:{alertname=\\"InstanceDown\\"}",\n  "truncatedAlerts": 0\n}\n\n```
\.


--
-- Data for Name: auth_basic_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_basic_users (user_id, username, password_hash, id) FROM stdin;
00000000-0000-0000-0000-000000000001	admin	$2a$14$c7zRyLaCxDLuoTEEftPhS.v4aXZuVMYBkxVrCNsf7PDNN0gPu.f9O	1
714cf91d-a7d8-40af-9f33-39215b871ca5	scriptbees	$2a$14$cXz.5doXX9M7BG3x.2u0DeivmI8izu8pR4OmqWFh5H9yosBvpF67u	2
ea7e4b42-9594-4d69-9eb2-a64fece9ae31	venugopal	$2a$14$S9ikwMSJB322P8XCFkAhAu686owfDl9IaxJ3wRDaUHZOOtENqk5X6	3
eff381c9-461c-4d84-a061-a3c2ff2c2ce1	gautham	$2a$14$N9g/tgGidoLEK4Z2RlvaIOUP4C9jgXXFjSoHJWHQr5QIk0SM1f0q2	4
02f90772-f8b0-42de-a6e7-cdd267454a13	kalyan	$2a$14$zY.J7NYxWpckDUgEBCrrsOJhS.y3cB6Td26LzTvZT3CT4TBzNxpSC	5
\.


--
-- Data for Name: auth_nonce; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_nonce (id, created_at) FROM stdin;
\.


--
-- Data for Name: auth_subjects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_subjects (provider_id, subject_id, user_id, id) FROM stdin;
basic	admin	00000000-0000-0000-0000-000000000001	1
basic	scriptbees	714cf91d-a7d8-40af-9f33-39215b871ca5	2
basic	venugopal	ea7e4b42-9594-4d69-9eb2-a64fece9ae31	3
basic	gautham	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	4
basic	kalyan	02f90772-f8b0-42de-a6e7-cdd267454a13	5
\.


--
-- Data for Name: auth_user_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_user_sessions (id, created_at, user_agent, user_id, last_access_at) FROM stdin;
3073396d-6a13-4fa5-ad50-30662dc004af	2022-03-22 10:16:12.656532+00	Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:98.0) Gecko/20100101 Firefox/98.0	00000000-0000-0000-0000-000000000001	2022-03-22 10:48:48.816764+00
72031be1-6069-4438-bf09-360b180785e5	2022-03-28 13:31:55.332044+00	Mozilla/5.0 (iPhone; CPU iPhone OS 15_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.3 Mobile/15E148 Safari/604.1	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	2022-03-30 05:58:32.138748+00
5f6d0b59-88b2-46eb-ae1c-035ac30ae703	2022-03-28 12:44:04.143802+00	Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:98.0) Gecko/20100101 Firefox/98.0	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	2022-03-30 10:17:19.043828+00
\.


--
-- Data for Name: config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.config (id, schema, data, created_at) FROM stdin;
1	1	\\x2d2d2d2d2d424547494e20434f4e4649472d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c62373436306536656633653031633630393666363135616430373935333030350a0a69574d4b41612b65545a30446b652b38534a7959794a41706e6a527855764a6a4434483339764e656f4f71304737754b674658726155655a437472772f6e65330a756d4a49684c563264357455556c47424c65746a71537a314c706d6744453535344c52734545594b526230377563646371794438464265586a787a73443031520a69526c5970683041796f6a3462534833577871526d4249766f33367553386346336253664d6973623674685974746f566d6d30447173436639564a46306f72300a3357384c57365161466c545a4c4b57463362706d5567665376497a556c7237445475444577526c56684a46684454796837696267715a456a532f4a6e4b3262440a5a686b53526536574e787563727538645070415a3942574a2b655857642f58564242617435454f5064775461327033704737384d50566556453731543841466d0a676e6a687344434e347172416f574c4a702f6f4b6574637a4f6e56646879596b575442544c6d3971456c724e3843526163356369776578767876646c767857380a6b415a38715a53766d2b4d524c63664c74675855465045332b63556d36374b41624b7551355630516c304157456d4a524b573230416539746c6d5a302b6837550a66633362446d5331655450347736422f7476742f644d63656b775374324d636b6c2b77707a5a6247746a4f682b676e68746f5266332b57626f4e446e464964470a396e6f4c5449787a5a41596d6b6a58694a4443664e2b6f614e66756d5a7a306e787251374570614a6f792b384158674a335955513651372f4a6c2f5343432f360a4a5273664a6c58434f3165786d6953454d336a314e5574416e6236646d644161704741683876704f366d676f4f624d7453536e70645a464f3378366c6947375a0a72716930626c3377774c47624359586a516f4e354d712b614349424f5566463466317753782b6f53356c41544d7a64794f57485069536a4e63527674397538390a743554687865526b696479664d6d784156634366685a6431446333394a543057736f595733752f786238696e684b4134526b45744e365a304862464741636a4f0a54726275636b6d7678474939494c6c3278694c4b49376942784261627737427949656938484b5754322f44706d7868556d57645a334f386f4d6957755a7a42320a5279397168494170725659744e572b4c566e33387470744f5a4f486a51366f2b726d494a4e4e61747053773730744e6a6f702f4e36376a56487467696b684d710a4f796e6b2b4c4c5976356f562b714e6c793561613465715246574131436f76594a705a356f76526e49484b684c344350753954774a2b486b5a5074614c4362670a673845704735392b344b797539753935753179706e6b2f6954334239734d44596a5748517245426c495234685a615a2f674b6d6a624943724a4468434c4838730a35536e62334b534b77394a686f743066746e6b496767637766376a4637796b3365534c4159334968326753625a72574475332f54686e536874344b624f5968490a4456795a5a6d3338326a44396f3363624b7434694d6b64456f583474492b536944376e5936346b77366b32504a7135664453697a59376b6a4f6c6f784c5a34490a3973775638363631705041764466542b57546b6b4765476673497765586935697750784e725a584a43325858554f4b453969755061396f6a55697a56716779410a7a527a34685745555266722b623839323830613264506d54516c4f5a5a55782f5131797446454c57455a703046736d367765685a7443345658522b45475041730a45615a2f30317731626d4d4452452f6b453236575a5434512f5a6557525366746278494d37445a6e5850414673385a736b63596b48774d777177337137786c410a55382b4e4b3966506d713962504f6f30663643526d684c42506a754b6f42747073486d4c45625865535851414676716a68574b2b53456d45693362444a644f350a7036384f71625877736a6e782f517a734f566b545774583941782f34763056762f7a776d79503473647045516b5777705369433043424e53472f4a7a34666b660a326f624952474b70456a4749726963396c544f57675437527a4979494750346d54794847687861504f6533427036483576636f446c6c542b44637666394b6d520a4b586d337951395a6a376e57446c383869425356706763443972724c7433343752464551394563326557512b6c7153566a3178515346594d36785751745363320a467a6d49694f6551726d513275456c50696a3069514a524768396d6e494d5641707554497847524f50796853716b527a327453636953456770732b614f6b64640a596e45515739437072485969355164554b576968364f34456e6669633152544b53714b725534376e44346e4a7a72564463546d6a4c7a7151754a3141656333740a546a6a4179523575472b547a566a2b46694d506236625465652b6c684544566a5a473253586a347965426c31384267424a54652f7a5151736e69714d484f444e0a663443305172705a483353424f36736869626f36334b496d6735323756774a64663034413455456a737a6f3d0a2d2d2d2d2d454e4420434f4e4649472d2d2d2d2d0a	2022-03-28 12:05:29.052176+00
2	1	\\x2d2d2d2d2d424547494e20434f4e4649472d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c35396439633363616538316235346336363031323934383337646335373531310a0a6832566861742b6b6771316d65595477466e68324f43764c6b533865714f534c4536493343632f4c695a495178384831374f75655076514a4c52636e633946420a55686c424a3449794c6857364e6957575a5555527732704c6163784c59355462536c3876735179512f434e6c3077593977776945436a6c686a59472f31772b580a5a725966546e6a534a652b4852745777722f6a3572636b454c4f4f6b4f5449446f706756706f35772f553077364b6542586a30775153702b2f45657956574e670a4867664558655a76416d43304c63592f497a7a584e4d52756669596b5333556f7252636556365a3279414a664a55643953772b504a75306d316c6332597656770a6a4273564c78566766665776666b4361776273654b522b7754783969737879526b53683544474c7a78563658765a786444632f725450644b36657166534d46620a35644a42703930476e73546d4267464c2b52532b6d3441765561775a3673654f686c6a3241394f4d504b454c674e636a3253544538782f4d354a6b42562b61430a61427330396f7634545242674434466574574835565372634f37782b6d6f583948374b31674563445a383778516b2f3741633862753658623753674c396e32360a73643654757172304d62312b4d4b4552314b756661745a414a424d7931455879387562796d4e6d32346b61574458554e7646496f74656170374d444e6e3056520a4f4570785252484a683368474e625a647678384f6476506c72536149736f724c664d7a63656a434973347259582f336341376f4a583333514b6d7a395336645a0a70684a6c554372755541654f49636e41542f6f6e6d472f6d7633577a594338617962657472453832694c664b414c52316448344a44746c55684242537a554e370a42635855624234624e664973322f62476b67384456566b5a6d5467723347374a6d7667472b7a3858435039367a76326d4a45342f76774a72373341654973384e0a48576766364b66327749335138556b4e764e4549746a376d5230733050787a6d4b4b544847527468736c5563694d3863357861795439545759653377695943410a42624a454477794437594b787333732f6a793755362f3778584c74663430705a725a5a336b496d64514b736f4e312f7339473747722b624e477150636547682b0a36515a56776878486756777a3748465862417a56554d61534c4478692f534631576f58504f2f6f573879596e384c654d4f7142446e76324c70703078782f4b4e0a5a78703465617264365155726a384c2b65357368374a2f537839787032787a574876373466676c676a664f6b7275343473324a2f34532b5452645a783358504d0a374a51743753424a754a5377536568505a304b682b534142684c6457742f5564622f646951362b4f2b4843754a3047382b757836797a476877457836656249480a667a785a6564306a6775717562597663512b7168664f5a52787741747a4864706e574c47383450515463692f6a755537337a2f4d4254317730384e49304278780a695a51352b6e34534a6a6c672b554234662f5733676b42553977613134476e4461316c487453386c67316745687a70323778454c6e41737a6f435239673438680a34426848514f582f364354702f6c7837634c3246467742486e45627148594a7752357553575150642b6732754d41664138324846463453395a7a7a47337270520a354e636d44394769557078462f36736575324b554b41337639486b6c516f7a47675530627333615477337a6932646576434b7753675a6344514c4d33624d35300a7a79494d6b5a336e47762b445a636b6e4d64716a2f6d614a6642366364525261623476514269584e424b424f42746b45574e564a666655636a4375572b6535650a58652f6871375a526535567631504c5967626458372b5147374e53385a377a58444564584936564a4972305151495177594472306e592f6463363750305433760a65523537433251584a724f2b7a686e356f3752447877544b6a39653745504d41423557764747324e4c5338556d4c617861504c526f2f772f3974785742794e480a726f62797759382f76577262386d6877616f64584965375a6d627836613058436f325a6d64364e335851596b555373654b56465969486654384a58352f61384a0a4f5249573077686472585446334974374c694855706438334241784c4c796c684568644e7659316555664569674679334142466f356143336342552b337763720a63567053706c584a712b586a5443496c6f582f686f446e5971505662576762556c4774704a30355056614c3251747647337a6a7461766368776279536a482b710a38376a304476742b344a616778487a496c7857316d494c3043754f732f4c743975313047722f6c444f2b6d36763753736f446361387a597578746e446272434a0a78462f634a6c522b304d516f71785170327849314b476959414a68494136545a63684a59336d562f796258524e74646847345161427230544a77362b77464c620a3848315430304342736d68797653584b4353636b2f4f397946474c7042472b497274666747496a6c6462747767474f686e787a327473646e5465423646424f490a596e6c454b552f445a4b344e75585a43632b2f4c52513d3d0a2d2d2d2d2d454e4420434f4e4649472d2d2d2d2d0a	2022-03-28 12:06:08.061105+00
3	1	\\x2d2d2d2d2d424547494e20434f4e4649472d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c38626335383162353831386366313432323936666539396461313863333633630a0a4e625379713266574e4f79413359696f73485051344548314343394a306458624968414835646c59396a313353304f564a427139464e2b4c4a385869324a6e490a6b576c313069306f75617967723967615a4c4653476244722f683072474b5a7a79456c3773446a334333522f6d2f47647a374a484255676b7334722b636c4f6b0a5a6b685a397a7a6577725348732f51637052575a726345374155364278644f412f77506c78384941322f31562b487057476f494f45664c69434b6c72623165390a3148336c775955724b3657784f457372696a427474454f4f6e553753555954474174457471632b337a4c326d4530464f68786b3439733248332f68386f444a720a693852796d33776652646c5861537178334c62685a425275536b46586b326a45586d64592f4471534844424c433763566a773039717270646f4466367a7469420a6c6244794a634834524d494b71303952456e6d6d694b2f6959516962617430435351584d39397a437656496e342b7131656c555a673451646c4a5a4b5861654b0a6977303231596c57513769732b586534664858612b763676746a6c6f59736c7a7969794d57365745794e69413975484969744669627a343976646f4b463055410a4c446773314d48305a62794b377241365543767634433159666f464d696d49474f6e6a32494e53696939314d51634a4b326f3349376a485a546a4b3671724c7a0a61542f753736464b4d7443426c7159336c795a546b6943675a737874512f546d37567948753841573363756979773633744372745657664e4359513157516a540a5861455656424b5145784936796e746e4b38582f544574424c4a354f3070566e37464e59373755734143553559306a566a334d6f2f566252614a6f626b4557320a3764737533434841716a45454a4e742f776d49707478663844486f533456416b38765679764c316977447077594837464977395762724d78705178694542476f0a325839696154384c7079446d7a534146663774546a764c35355a7236726a6e5555747937764364415043613268597a6f2f787467477934473331716c4a7047540a6a576c6d584a4877346356353268416c4c4549737a504754674d615a4250676c764850444565536562796a4f615871643345766f766847456572624d757933790a71396e397552722b3876434876742f647a75776a6f35645a596368796c2f6e3278515a4c5669452b634162612f6f3335463478754b4643462b787a6c6a634a420a707468714b4e6b4a3650486b5a73563567556864674f6c53534b76467a42313131676355536e505a77703069456f3269544f484c70727173544438534e326e750a426d524149476a7648696270753548413253484532523353536c463566754a333875626a754c4a453052346d48394a2b625271616a724d376c6a6f6f56746f440a564b793249323967796b6649645438584c2f79574d4f485164582b6b5672316a6847724f714c534773503064356b4a4c734b6e424e6b5a41377569496b68415a0a7a453049486d6e4c395357334e7362556335303137553231504f6c302f496842644d4a2b4e4c4b472f59534d52525279556c71684c4b424f586753684f7434380a496c524567346f6271694c6c30454f7351482f4b50766d634d675267306d6f6b587a536f464470436c333467657a3455325970574d4741516f41617273734a700a6170776e486f4c63436166326763542b684859746c79347878554249437041627430435945445a32363262556d7735797359453541435542453652472b436b310a304237446b2b57386d773378306b4b47734d514571796775746b425942466c51644f36564a456c4956764147704c712f6c58615a68506c6c516a63634459774f0a5535314943554b4d38425a34614749347052416a772f6166336869336661466676497156576b36502f30682b55684c476d64434e346c58764157746b596570430a327a7631594255786e37644b6e2f4248666e787158366b486e2b42503875594a5570787978344846395a7478754d6a706c76665966743655413471364c3677470a4d2b6979594f3331626e614c6b6a485132376c796d547a433842544573385557756e2b445466756d32454e676f4730504f5363746b38316932387a55384979340a334f375a5a467451457a793832724479757973686f636f7053796238546271635738574d5439726e2f2f4f2b2b417a745439336f6f526f5958594e49445a59790a616c31584a577167616f43786441322f5964656f6c70367539336d7663476f554668354a46645354704747782b425468662f4e734946786a6a662f30707471580a6267462f3354652f4c564537716465576a6649642b4f583265596270732b514a6e5273686d373042776c43415064352f59626b664b36585a513557786352672f0a566b2b7135424b4f6e38676f456e78663145424d77466b30676f5634394d6d6e36464e44386477377653646765354946515657533950437973644e747450642b0a6f653156716759717355385273614444356c424a5148566d656e6562757958335945426d45514c4e367a7046544155363349434b50433079636e5574733749550a69636246537942396867526a47436f6c6f5172627642646a654c72456863325855543858362b3852747652474a6b6c63546c433341462f453466496a6e70322b0a3964725863392b424f492b484931717a33783576537a41426241773946446d6f6d6b7a57504c7878684935697a6748524571687057685735796c686c346b6b720a2d2d2d2d2d454e4420434f4e4649472d2d2d2d2d0a	2022-03-30 05:42:42.896017+00
4	1	\\x2d2d2d2d2d424547494e20434f4e4649472d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c30353439353963626566343937653937623839663565663663643565363132370a0a6e6f6e384171552f7734594f664a4e454259494e752b7073626a614779714a564c2b7652743633746952384e5750612b3543485238534f43566d6a6c434158650a36465747495a432f6572695669655a715156642b386c34456d706863746f7568626142356148364b647a342b4170466273505454324f30704b4e524966434c410a515571594172472b387132666a4c537a564f595562666348354b44447a787346516c2b67595942644c3636473459366e62376e4a7861336e4c475a4f354a59560a5334416c6e5a73657a5537484d4f52786f6c786a79612f3370424b79476163566b6f30587a5668325a38306c4f4379702b5a6239314a572b4d526d65554b4b660a4b7a724f7a30764142505245636a43695266646c4c7657463739686b567051662f6735767243546a4c484c3244654275634a356450425650413730534d7054730a31476d6842696d642b2f50396555714e696941677554376b6935655a76344f4d7332586e3465334f622f4d4a6c393148614535646a6f3865696e33674165724a0a4443644c4b726f435a306679534235375453744c6d35624865317068364a6853504264444e6b454b6d4c33527268423561564c79464e4c745161642b384b762b0a70503476384d57385a595a592b5738554c3274596f4c4b4e376674754637447254626a6f593134484b65764948506f505435386d796a6368636f7a5737506e630a4333714b4d4477464e6373626f415a37714f55636d596b78594a34694c55656d4538507a692f63433367597036574d79643864315664465748415151416775650a7142693044396a71635a61574b505466473544746f6979452f39493967685868374d67727930357a2f594775665878766a4d456f49314b4d31517451396b62700a3366537758433372334e473651656a6f3746644f7a4e666b6c5a47414f347531354c377957482f58724e4f71325a79324f554d2f645156734339555a31355a6c0a7330304c363130577766365477736e777473797a416678367579794456686f73535348792f31556c4b39316447534b2f41586a675252675462456a336e486b310a5a434a6a38554d506b755455397765777972644366614175595a696949446e554735642f556e5341325a6534525372447976686b6f757771346c79435067507a0a692f6a4f554b48426d784e5870446a55496d757757576445496c35363742414550583536686e41697a4577713572643766536141484e7a7355437643655832560a456a674578714c4c634a7a57712b33786271514c384d4b2f484c304b78732b4f4b774f6a6e694751494c4c31432f416866743147396d5170696b6f7937586b350a3178494c34304773716437724b4155364e724d4d3870414d3253367679704b5a746b71574f6e4448336e517639396e35624732334839506a6356426468744f6f0a2b727642562b794e4831366e62314d587a534f6e32526e6d47554177484865784567373832572f653437683951764576632f6e476430722b664277596a7768370a686f47496a384b77446a4b422b6f723532454833336454386f52566732467a2b394631763174676863494f54714d387737316a674157396d4a2f4f656d484e350a456e6e506974666471756e7238373177794e4165797549542b3938746549444a46572f324750777668445263786b694f74385057313341544f7265702f3653520a7864486d36445750597877387265454b6a45314c72566e6a416962462b4f3130436a39333953664e64632f44453737715054566f376f6d722b73494d58387a6e0a74643944436a6d756a2f78676d39466c786630434b6c72516865616436617a3944466c794a73476a754c35495a476553697078353158734e634a7775597331700a4c32426d4b68686c644934514779585a3761766e494e7756414d7258453079556c384535556b646c554a393853536758736245575a306b496e3637436c466c480a2f784c495a584675525866362b68395744334f77776b6c31765546437759724f4757417044334e6a344877377944313770304867526d6363644661505a62334e0a3933666b637853697a30797855686d487a737670625a33473938794b58517a36615133624b396c637954626b524963465551766538314d2b57316248444951750a3530694e48705949696167654e794f6b6c5a466c6c636d4a7461504d75727249374772774e5077303338325a6b6b494e4e557844776a75777a7748664f5472350a782f734b646b676951536c2b4b6d31457439487331656b3141476b4e747930724a4a366470424d74396a7559564c2f50415165414d6b463373456b34483666470a6944337a5651544f7570794b4a442f6c692b6e52484250326b4171675a4d4348752f437547714649362f465832643572425936366345636f4d6c6e6c787773680a4a4373314161307158484e43525462314a6a792b6952384b4274504c516b792b3262416d432f6355706a4357484370364e4539695964682f522b4f3945304b460a2b59797635445945463958727056476a656769513744684a6a796a324464674a6c63795536686a424c4f444d4748567076334e5343416e357a6c6374322f76460a56614570395a4b3353476d6f6a4e716c6f43376a754c516b466b50566143645733464d6b4f72685453762f657a39477166314b6951486d4b4b72454e474d66660a6734445346797a69777a72725a567433334f392b6c4b687a306b2b73797748323564622b4248372b4866444d6146384269697a5043596a49465549444b51484a0a2d2d2d2d2d454e4420434f4e4649472d2d2d2d2d0a	2022-03-30 05:42:53.682552+00
5	1	\\x2d2d2d2d2d424547494e20434f4e4649472d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c36366265356463653639373463376364383432623532636364666561393330320a0a68796d78454f6a3058425376625a433045703131676f6544686e58464f70425146697362794c53504a3670505477447766633631476433435a42706e496a43790a77754c514141645854397671504669487870645434446f72665032516663627967456b314c327848772f643342774867446b66653277396d306d4149417441530a735278466464385371723567425349364c7630446f596a50644656486c4a5a7a4d677936304458763837626c2f3656685a4b6b63446974316135645a656f664e0a5149542b3941636162474973744e39744e6b446551383530466254367a71702f704d6349775473444b7244764c6e6f3837515555716457794e77324b504530770a6a51763154687a422b64654b644b456d6e487835725931664d69316f76355439617a6b327a6a7241342b48594661454a54474f437036666d5232396b62594f350a4f7a776b5452554f353273555971396c56724e447153335a34326e6e3863763076506f5857384c75644e3841634b6c55484b6745596d2f3339312f4b526f4d340a3235595648327737776b2f786f31345475365232664b546b4b54374b4439424d776f545055786c744378477167456a515156547a564677634a575762787a56640a5344756370464b774c6134304e526d734f4776546662714d3636667a624b4356736556496d344875366a69645572543353333737456a614d64515a4f7a6944350a4c624d6d5a525a486d7259504253666d50474871546473513635667657542f30783239475562766146684a6d774a546d6143424b54344a5750725a39617236620a3346733951787a64476766577757724c4d35494958354c53634e4239616e4b6b7858334f34397431796d6f67677276556f2b58584c73356b38372f77382f32750a6e5a3675413942504a31677041376c52796d67362f67626c316c754c4750784955653830687430776f4b3231736d5630735144305567364e423342494c4c47340a56354769743464506d4d636d436448365444383677357a446e5668447231526a46635874696e733345726d6d4e71706456382f524370666449454773566b51340a6b3553384c3464434f676d535648473748356f694c594161566c71464937363447446d334a70506975736c53426337482f4f5061636a2f532f383536727665330a49704e416373396b4b2f52376b52572b30514b372f655376502f2f677331692f543942322f3758647a7a522f4a31657a5350524d7962454d67392b547a5864790a4a36507267756c783030564f377a77776b4d6843524a31616b677a46374f6657724c6b44586e715556386a524a7766366664502f596839632b4c4a61534938430a532f76473762435839722b6e4456305336467561594d367776566c7851644d556f6d44395477567842785439454d48694f5447374a3368775955644f505744370a5a4c7532436967535a716c4f59346d4a715554322b627131564c5850595967476c6d302f5743556933667a336853425457304f384133786d706f4e57614a39390a566a52476736774c5a364e4849624a4d757531656f65333736655767323952466f654b566247596a79456176516771506d6177796c4a786f38594668414239460a4343346f2b7054516663526b4365516163715a32397244747a7a367056354e5a34532b72455050554338774f6a38692b622f30356f4d684d42305233486d4c470a4d33705a4e524e4d2f38776f312f4d794f48682b65507938624f576450624d68465a4f6d7a5343423648486646662b374f58444d7a797a5971653477506458570a4f6e715a6230394c58496d4461676776515471346169664d6a735a394233306c44504645784e636e74346c372f664379764b5534653130565933783664416c560a4453654f4b324f6b7037746c53756f4b4b33445630684d652b77524f396c747247422f435a2f4451513666714f6b59585373733577422f51494b336c464d6f560a674478506d68724b706a4a526b465a4d66772b476d455566654266554b6c376b7478567875576853545130446978496137697774384e314445706e6a4d7357640a4448497532577a73555266556e50534b574463487157784b69666a694638456a7569662f62443538377846645073734b4232306a42507a484d7848452f4774640a395757466367747837556d2b715057494b52364631333478424e7a64677a366455705465357333326d49523279356e362b48505a396c5846574d466a327768350a694f46374d72736e41363531695973523158363939634b6d304a32596a4f4f6139555170515631566641444b4d7541704333675371333576692f314b6c6175460a685052753363626463766e327246486f6c6637576a636b63345657313647693464302f304e6148712f43717353384a56732f336a3678324259314143635a49770a385a7330694d384336433374784439735a464f497153516d3673704e30576848397171445133543363554973646c363242433433306e6a676937665545334a330a727731456c527248767a43733266636c4738777a62354e516e57454b33556d4e7739554437662b76374639776b5074514e336a61794b536752545231323755320a4a4c52644e356b62434e385776475a4c6c454b69754536764b3958376b636d36574b75744d6e5836555863376f77424878373847414e7943594f6976535a46590a74746f434a6534524d4a7a4b67354d6c316d6555646971445448352f67596230564f3462367875634f785275564968416e6c6d4678304d573568506f467562430a3251547637726b3731414478472f6a68453234424f673d3d0a2d2d2d2d2d454e4420434f4e4649472d2d2d2d2d0a	2022-03-30 06:21:28.608975+00
6	1	\\x2d2d2d2d2d424547494e20434f4e4649472d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c64313861346134326562626132666333313766303861313565346636356230300a0a6a4a5939456c64316e6a593475657a6d52317a4f664e4d474961614b4473335850414c72457a53302b2b4b756b3132724f327073544b324e6877502b355146490a6738585441425869454f366a6f6572656b2f79665137704b54647150397a6f444c6c586d5741636d4c3071656d70693753526536644133562f43417a386938730a67746c627330485a636970543553454d51482f61457033367243706e4143656d34657447504e534e45773271516f6b797a53354e5837534e4d78775a39516b650a4b5053454171775167724865734c7434696f3271434a69386142326165514f443146394b742b304248796a456f57367152306d34463551385156504b30547a4a0a2f41754b486e424b5946646371764a674c5656616d4e4b4779725466396d6c6f494a2f6e4a6246447678392b556a562b377274725742384253435559305764450a6f316f6954625951384b6d6178716936514966524e506d3639537033512b4832513455795a2f52754633453054332b70657045412b4a6e30675a4b6d724f61470a33314f30434168506353434251456d743535576d6b353657662b54786f47587747674c455a4e69657569366c69494b78373878697a74724c6470587133646f2f0a44775a564f41375331497a63513347615275745241426f416b4a75586550364a347a4d516379664a434c614d4f714e53796b6b67677a48304b566d74796c6f310a744738574f7879494f51685a65754255416866474c6773682f6c6231465a4e6b7147697243686d5673456e4b31686b574e766f6a666f41446c306f3655366d350a657731715139584567324f4c795031766b366e5161764b4e47733173724552484a6d65706c4550696249612f734b735a3479516939726f4d33356857457a512b0a7134396e522f78426263426b412f66686857447348614e4a56304b6270446834715530752b35472b54554257744d6b324b534d4d4353756b58455163556b31760a7a6d526a4a72424c3744612f595633425a41584330355038495266687a6b34463457684a557549727a36555932494e4b416b3066363948626e43342b6b7372340a717468345478644d54506843454355675650626155424550737a31477736597a5937337247464a746c76574a684c6b656c706c4379704c5379513959314679460a764657535139484e2b58665662312f664330304849354b6f4650493753507447755348424c504f4f3334556d6751447a4f4f525a6d344c4e4e716342585548790a305a2f584b71343677526667664356616c723661533554593334497548346a354970326855476337613346715465304a6c6c71554b5251736f48774b4d3775390a636e4334424656433772414268455956762f536f472f4e465a554675426e6f4c4b5864587370597146376d43747133612b756c36762b3958545143304e5375580a6852587143566b6257554444554c614d67323730567a414b2b6b4758435a4a797a6d5239675a6d784f612f5255396531446e5461336f3433442f4241535335700a445657766334324a56497570732b7365582b61476932527476446635624748626a44466d32696d6370487937556172794336756d346a766c6d747437424d43680a6b73505655394c6b326c483230334932507243514448677572683733486f4134454f574d6a69347651704d556c42333656447a6f2b3558395a4a325a564348540a4a736d544e4b4a58536d66732b685a344836724b36507436504a51436168625063304f5a3564436745637141544d6a69776c515653756b58706e645433597a320a52546c6a4576724a6f454254617275495937677758354856512b4f7570414530533430413443642f39306a556d53577a7a48362f704e63305a4b434d335a46460a75695549504366596a3969716e576879423532332f7570716d544b56757448646d785a4a594f727130424d6d3574664170734a6c413234306c374b75576561410a506a387a6b544f7850527044306d78526c6b71625945735a725a49674446304c4b4d6b797a737751493271706972416d446772596959635862694566752f54470a537a57577a7631316361734c466a6f444f5665744848526f524e412f2b4f49714b424a4b6d6a31643179704373516c3947504b4553664368485967575764786f0a637a4c774e625a7144766b376d4d6c7735697a6c577132476232736d2f335752495870587148436c46793859726f4d2b7a532f7046704f725a465941765255630a6250384e46514649717169474f452f4a33635a786551303061554f31646b4c33432f414f6c62796b30726a327a705561307251746b7361677a6a4b53434b6e750a75786a6b474f576c4c70307556796d3774776e5731736e625037733252487074314f474e487a4762675477346d4a3961517244684454696f7774333550324d6a0a62754c7170492f3150463745726f63332f6a47746257795a2b412b6558616d6d6d36655967326d587343764458364439507163664e577176633730506b2b58500a727a7146616332582f64796443776137514172457061646154676567714634513844346763617a7944542b70757851792f6f777430757534726334475168726f0a74566e3141567058646b55376b64654571775068383279736964713652567533356970425a636c6c74705352454e63584465656d4942314532416f33455164410a4f564874495a4f557a6e30534d66496d615455334c6856464a594f726441486141316e70324e5563585975536a676b79586d64676830486f364c35645a334c6d0a6a34492b38314d6f453267555a6e676438774e4846673d3d0a2d2d2d2d2d454e4420434f4e4649472d2d2d2d2d0a	2022-03-30 06:33:25.768919+00
7	1	\\x2d2d2d2d2d424547494e20434f4e4649472d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c37623136343963633839623938336665623039383331376636626339643266630a0a782f3339414e494e684255504857636d32494445494a53586d646f596f626443312f33517a524d706e6144773769504e63396159454c69424c435341736d36620a3133614f4a45704755536b35754c5035426c4a374a39494853662b48474777304d4e53484b3634476362714e506578774c4b4c61507070376f6e424e7a312b4e0a616e5530356a52506c7a75387a4f30524479685046634c35546851746e56587233754538532b7052566d2b4e596935574874306653683137714f5250532b49650a7156466b4764726334377963694568795631354565355a4c535a754b462f4842335a7a713376524d4e6945695a335a4733754c384c476b42766e46363577716f0a33664d426475532b49577166615a49753267354a6d61786c667337774c2b784d382f7a5a513946753831536e56355364584d693359697632346e5564315a75440a4678334145303071513173664b787852504362304567516472306a39796931486e68484973434643735558595a5463334d5a4d49684a70514a522f67675754370a6e6b496934505570674e2b6b4252706f4f5346504d6872374971384a42316351684b6549686b58526974593268744c766e484748374570394b4f6a596f4550660a39387257765259546b625a35527477573635306e5855596235533064376e6e7779486d6a4347566e2f794e7a647937364d6e7a4854675653654c58434c6f43700a4c56524736502f794b5352493073316646374f5579374a743878434c574a555150435165544d3672587a7470326e444b79314d35693276775a4d6474357041370a2f6554762b2f61646b52647a4167436c452f45616873354f767347447433542b64584d6e7a3763396979654572323439776a6e597a426c6a6e4f6345714943590a44765544564c71747a43554c7a544248702b6f7a38506a555a626d567064396e333864306f472b303958535a4f4e78357337595a78516e39584b3873387363460a6b3955476656356c594e4a37776a4c7853667230426b702f71546b434873493944383162647765576b7a764a354f67556847307356637a7544325143787066330a4c464859333733744a4d6658765146663230393067556b5776557364412f666f722f717570437a4959796d6d526f425644364950333152554c44626e514758530a362b764c6b42476a435a582f67535a456d3568554f454c734b2f646d674f4259653136624f516e6a376b78424d49515473375178444f4b387534746d30504f6b0a476b472b5168656b2f41367830354966787a734a4d6a69677662336b7047686b676563336d64786e5a554b33625857526e644e784636473465736635586876350a6a79426a6a55522b2b47326e4d5938665769434c79687a6d576558715848444f5543634d56455835553445547a6f34703463706b4d38524a456336784d524a530a3074777a31684c70684a31634f46613749376134766c693150746c4a37776a50657074686244765249526d7a4a716c31614a3936717849456931396c374d47340a4268444b666d314348314e7a64395954617a66437150642f356369686c2b6e3765734636396c567a3553754968513645515971644170486e624c4857426458670a37576444484e527436764667546c5249373250624c76792b6b56462b6b57614545386e654f414a3547325942673568764c517173474c59537859616b6450316e0a6d527a61516a7853346b4f4b617146744e6455434b4d664f62377172334539664748344c55574b45705937426243626a32447473416572627a6c5136353561470a386f65316b355837792f554d4e42654151344c52344754306d396273734d7374732f4872574172727647494e543353704c744575617868704b34554a512b69340a776f496131376c46536e44707471464f3057496f4a31534c74785671633861463548386a756b486471466e5964396b5545644b68684e537743533943725546780a7669786a3761543454486e6342547076584e5864767a574531585065536a72584a395534392f6836666a495751584b79777a7a42454a546f474256546c5a72720a58634e2b7873535961366555506d733934384d317a36645a74614978377754657479713975736b6d7535477a58725441536d567464766a4a733572326e3347560a64506b4c6b7141763735427162574d66776e7a6b376d635273572b732f7358376b3651634458474d754c4b5149655a516e6b2b4e7661636c5031387639595a330a556374693935616d352b33534a6c544b6e614e304266776b512f78446f4e4c33575a6e7a2f4f6e4e305161387456356354444e6c4d4871514c427a592f4e39650a6962346f676172315a374e4938426e6a4e4279592b4d507753306e465646392f7a36644d5341765342336e345234336a33646a45734970635a6d3943484f516c0a3852545a71353658634d644474432f6448795337614f79596c4b76306f414c506b4b354d552f436e505653713558556937717a59414730765767584f436462310a535a5a666f6147383230535631304b37687338734478456144476844575a5665495742317368356a4a3159627136506375744a7a50643262354b76547847556f0a782f6861676573566749727364507537784c6468354439685475657141765a526b73705062482b484d7135674e4d33446936624a505a4677544356552b456c510a655176425951324e41752f615074557053764f2b522f6d6d416a356a795a52564336303368796544586653454f694d75334239724a6658476d337a7978744d4c0a7743497669597a6953653735326970464c2f356532673d3d0a2d2d2d2d2d454e4420434f4e4649472d2d2d2d2d0a	2022-03-30 06:39:24.233199+00
8	1	\\x2d2d2d2d2d424547494e20434f4e4649472d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c62386238363830303662383137623262393335326138333462363266646562620a0a396b4a4557357476764a3339414c57326f6a2f334a69445958664a4d7757376b5175627849516d4247762b492b362f756554564c713832317270764f522f695a0a6842702f746c6c355350387467734c4b335673336c3161716456327a64776c47565a764b36585039377a5a6c777467397175734c5966306f6b387563594769590a6a35795265544d2b682f776a745448364c78626f6a6562764d38632f33492b5157416631546c7238747a4649395259467441434a3050677a7569585057756f770a4c7657786e6659443358487043566d73597772684d315868443034337a494a5550396744715448786d4e3879326767683868764f74356a6d6264496f716f68510a35304f78413157413370664a6c53783061744a655a5869644f713572597175583971434a78385a35615734686a344f7548557a5968794a3232474f69414f696a0a44773261546c4d38636f6736394b496f724a6e39486d2f6976746d727565445566497335647a42463646726f697975726e4333384a68787a4755616c772b6a460a6e70504d38426d45354a47356b656961647572516644336f7a5a7447757a372f776e645355766452665932776e484c576f76393237364b706375463838582f480a73674161636352422f6f624b494b532f576a564278494b6c3666494a4649566a696c6d4f61303375564b5639456d5253384243442f5464756a4f5469435130410a516477517645784449726648564d696756443258504d33426b4b524f752f35356a5a7845324b30766d663731695032766d4a2f6d71716b655277766e6f3374500a754f50555a7930374c4d7a2b6565716974504a57504a66774e732f386b4f496c37634e596c6249515447646938583271352f36574d5a476e3046547a7372502f0a493076547353374e655355573656344c616a32494d685464566f56737a4a4675794d7a45636b4f2b6954536357392b7a4b2b6749624842453361526c644652680a716d70535545614661737048396a65304b6e39713153696f565943526f5343625a486b495677654f4c7469326974367433364c57633065344c34346854446a720a73415739376d353755736631643165354c59514b384736725433454d393045313959316b4f56543753694631376b7030576e42364e63326552483450666374550a67716b767467487a31304664577937325731686245524142794b526a6c75457143683979717175665a5571754368387142636679664d4b4c4f436d426d4d37710a4d483571492b524d454448646e76354c7878374344786d712b315238582b32706477594375704a3851795952425958726249543730495568656a42504b6b56710a432f564347713046586967626651536859704961684e5642306f6f77694d7a454c6c6a55772f39666e68612b5167655a366e537756627862326f4573502b46740a736a6b414668506947436f2b57694d734f323468784e372f4b6f5a77506135666c4a4e6c64774e4e464e4d7661567633694c334659327772496b4f527648375a0a5a4f51574b796e496535516655317835523461537a7032684a442f44483770663567717059306c4957446245624454622f35702f444a714449494d56456755490a5259356b666f703734787343533077733671706a517158493239667a52706d705770495773364661664857425a4f584b32716c4d66534e5643697756313477540a74636f396379586d6a73396a4d764155522b6b4d6f4f6b6732524c45366c4a754f4b4d6150714a414b696a595732475033757237394b786f595a323067734e630a6175455a2f7a632f4b2f7a5036666b4c76794b6842396136656e547643784c7a6e4f2b5431796b30444b733647474861613235687756576642546976724c714e0a766b762f5a574847763835594e477754443755775438365930524c48513574747230625545565153476a2b2f384d6c57325231732f68316d51587851374e6e550a3946774d34505847425137714835684c2f72757151747149535a384d39453037716b785458554c4c3279396f4f6b78464e47715a67394a3448495a6d764c45530a2b4c636b4c464946443246424667756d677256316c4b3445534257595879336875622f694261575557576a506e4a70574d6e4b4d31423468535a5644336332470a6f4b30625a432b62746d586c776f30694841686939334438515a5741304e395057544262494e426b737368573765525a7a53524b326949592b54594f733437480a7351556a687965524462625a45756f41316f6f57774b595a654e4c303465433744714d533545376e384332754f7552445661474975696d796d4b6467357450770a6f696157577854513053583834726d56734a324473656f47707a6f5430514e4d524c6a7970613033716b32364e4c6f3336744a614971396465706e4d37626e700a6244765a6e6f5161564442724b523535742b576b35366e496f367573506735475976363937595a6670583459424c58424f6475697955565762724a4a595a70790a70444555364564375033757835304662657047505652794f6251566c326475665a31367a446749695a5649677765424d3666574c6c7453744241374d4a694c330a31315754376e69376f6167314f494c4465465271334775482b366e41784864787464565667546f76444262504464646a36333072496d6443776c30736b576b540a2b536746556433652f4c6f6a594c594b5a41653552307a6d333738536d6c75355a6d724442315938484c6c724f5069344a364e62497730752b6a4633446539360a54496b376e70305364577755714a64506931625676413d3d0a2d2d2d2d2d454e4420434f4e4649472d2d2d2d2d0a	2022-03-30 06:39:24.589846+00
9	1	\\x2d2d2d2d2d424547494e20434f4e4649472d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c37353238353564346132656337383539393066396664326338303432643261360a0a70496a552f2f6a72355a74746e6d4d7361504d6546764774312b53567255546c7a6c37735949545a3742673232333153734e484f6b654b4e5853564c496e4d450a2f4b346551762f3271694f7a664752666250576b4b372f795571334b666f6d4a784943752f4b62523131694f62347a6451324b72327941654c476f70726c724c0a74474f51364361355a4772544673493354515a50583744526d376b544a3547506b422b772b4872564b3458794d797367366b742b4d76634279655139365850730a543654756b336c32736e36315172636e316f754d456a7733546742755562566134485258313373455a3358706f5a3343595745574d6c71436d655973477463650a694d526e346f624c6239734777336b4e72574655314a312b374978364141527155676147795a48664b7566374d7362557a3546434435486d554955626a5251670a4a35366e79484c5a616c645147496c3945336b337068307a46663557642b564c2f4d584a5562414d52742f77557a4b4e574b36504c4a6f2b6c486457307344670a54416b57704b5463615645644544754548536f344a33416c396b6864684c6f77365378564d36626c6a4649634d74615330582f4f486e7a6e3867344f2b5a68670a4a464e632b764b334f36496252704c343767416a3147674b547350395939773358554553716d49484f3745463870384f6e6c47643462474432774c2b304e6a350a4d5772394633394955434632716872572f523241443944573436324a4153734c47532b38696b74624e657253626d6f304d6c7256705944707a675579443436570a344c482f726b5941494d4d33532f5975674a35765a686b707a5642524b6c736b76454b6d62694c43313634726e7065747a4f6c5277453067355263524f5844390a5a515362455453366a337a536d6d444d5944484757546c3377377165634e7a435572675141394b556e6479723571524b444a78524434366d4259312f6c594f6c0a316841643645675a715a53444b6a57657941714d32376b6a53416d482b57514c7a395459636859344632502f5251534d5a59384a713441556d543868595032420a654a716a6266736d5655433337622b437a7a5a2f4f69494d364c38503579477062486566473456777861625169756a71772f664c4232327953617a78312f6d350a527637636755376d6e5456625162495275567a466535645a77624848343379636e75336c4768656f74497a615853435255796870474c667777673134314342570a33536e536f57776f304e6936317338304b6d376470364967665547743431554b564850316c38764e5832494262506d383037676a74504e5979764f327636426d0a5056466176687239475a386356536c4d3239447a47484e617a4f736161736663554e354c377967786148746c414c6542366f4e5953777a644869306c4a2f424f0a326f72683336776b7963577a69756e513043665a6a312f4e486d6237477248462b4c2b51636c394c5573542b2f39722f3643503663467a2b78552b64702f4d480a646d793070736654444b5a6141467854556c4471394c74576e5a6b555232527248496564702f64694e622b757259396a766b76394c38646476636530726350560a56346f4a62454a44794a66364a5a5667684f3231454748692f764f5074344d707278716c71713937512b4d78544e77436b3768776d694669444142744f7646700a3575372b6d7a576c53377a7a3951696232415559385851455a77775068337a654e3666524a7a6f6f7264616c6d53424a775339506347634138464f4b436d66540a656557443566324a63476338624262616656655473703739595758456d72746f546f4c796651384c386b75426c58757335304e6c3368367351396c57484b76660a7433693374776c727a534e456236317a30412f5632724b486f7a71412f44564f31664b74776c436961656d4c6d646c324a4570717744612f56774d464f724a6e0a63785453516c6a48696b37644d4c6942704c7473716b446a6955623158333833417530476f7965332b634f35574977425a6d756b61554739465470335a52304b0a5367337a2f55796a7945372f66637762534e68656c2f4d5970464a694e6d5379556946324351727738566c4b7348505872744f78747230653556754c376868530a5969636771666143653450686a2b372b696d76646b4c7832426a48454f504e355361516c766c69536879594e5a517073586d39477655532f31722b67796d75580a6d39624848335246554b597956624e42684d684f466f6366462b43354549575056656a42374762366f63676e3855635a796572496b33737270317a747038537a0a4143474567546f5055744f564532473836576437386f4779635036677778546b515343326a6c4e412f775536786a7743315351486c477674424743434646426c0a4d65692b4244667a67555a38515851586a37785657414b326b31482f4f32537159724864515457755a6c5631516843684453626c2b6e31744e3975717777686f0a6548694e327253354b666364536e614858432b61314f754963725737746e6c6436695432396f72442b476465336555327554485958754e4e3454445a57766e550a426369514538774d4e79624650626f507734624b7262784a572b33734f6a376f6a62794a377178782f782f757958556e7958562f556e6f3377624562713362730a7758373564626a6a767854616e2f7171646d7a3562332b7437355736304f62782b756b566133474b774c65636937377756737778796e646478337065376c6f490a474934596e4e414276326636457857744f79776136413d3d0a2d2d2d2d2d454e4420434f4e4649472d2d2d2d2d0a	2022-03-30 06:39:24.675936+00
10	1	\\x2d2d2d2d2d424547494e20434f4e4649472d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c35313431383362626163626534333061616136663932306163323338383132640a0a6c446b794d5030584c42613749356566617755702b663251416f78574d494967562b614e5a2f454b426b483448326c53646c43786545455579614c506b39734a0a703237596f5679734b744b66496755625872616b657076316c696535676168594c507162643945467a6354305937526b6771513569676836756e6d44344a6c470a6e49685145366565376e56476557354a4237414f6256563856525672665a536c316b4a5443594f344b3170322f593568595557692f777272397636426c7039690a7439545444537a477651642b6a4d4d307859776d71342f544431746752612f5a6848395438785651624c32617a4e366d4d4c62534a4b4d50397755634e4a64330a45494a52423534754e72586661616c3646735663665036793835555056326c746b79622b50566a2b61686a786c6f5770336950633549484e2b516c362f754a450a75612b2f544e6746587a58665a6f794641616561495438514d5577304d4f6a2b466c65446e6e3161376173633564413752614b6c6b537770617361746c4562580a4e4261636237777a4b357445537551375048496b38325141345243707a622f2b34512b38765470622b505373755537706832594a684469757961324655366c460a6d383264534a697a36645a456e657264535a50626d796d3678424f6c47556d78663150796a4574734136496e2f43696470336736347876784a644736643768420a50777a30707033374b5034386e524a4752515138477447362b477870773472582b6275567156396263523647396f5273346673316d6232536c2b797a332b617a0a52454870544f464a52574437565a6b423957636d5a33317461714f446557357047612f6e55466e3259674d6c67706c524e564c764f41376f7a627770434d6f560a2b62676d712b384a344f726e47456b573363737475582b50347037752f46657147532b7845504130426863377a414e34556c50443339514d5264316d362b53560a47744d324934653038596a2f4e6a67384f4f752b38675468376c36555877674e3072494f52334c58664c4d6a547359535042443542527251416a6f53673958340a7a6f746f4742666945313959393237532f705258724e396b30477863552b7230344a50342b6c6f357a4d6948596f7a326b625972674f5a43584e3734552b77520a6b64417439596e335471483467562f554a676c634c4c344d6b3636377574482f764b353465336a307559516c67737748375247694d6b3031763137304c7741690a4b5665516539344b615574556770746e6c466a5a47437a6d39367347362b6c53773461453646534f6a326879674f4d523078506b465a4978364b4834676530520a7935357a724d30342f742b435944637664526b32395a6e6a536873384876536c523530717a463573673350784d722f2b796d6a4f64456b486d305246484e4d6d0a6549524350396b4a67433741417032576d4f634a4367384a342b4c58574633707168354f50653453357072716346427337437147556431354a353263596b43450a4a6e475a77383078496a756a474962537a3235712f3647343273466e5642626b514d7a4e51477868527658504f6c53733671684c70676775714e5a6c655a2b4b0a4a536e7a75654b555278365662552f4c787a4941684875676f684446513341536d6558496831654f2b5757525973506c474f61493476684f574558645a61386b0a6b6c6f4a4e6e71486531706a2b6d5642654a6b474e5a435a614b7839683841426a665152485632333032692b3147414a666853746b693563336251367a4852770a7165747337334b6853364a4f524d77453938583632574e744e6147563479514a4255786452416f3466706c45657879756d57532b517553436470536170652b410a417a7673695531764f56635a374f38625a45783346415367636a324d327a6370644c615577616e584837666a564d6c68527274326f596f414b4f7a45464e35500a68485139433156473530466f34724b35776757664d415471645043715a494e4d626f77526f4658424933474365616e7670494c726b4257664b6f424f747357300a665970686b32323130556a534f4650766d6e4633394e325372307a31446f677a535a43615072455a4a5765686b426872636d6853557234362b4674724946464c0a3137374338745a39585361523354784c514336596e6b4d6a70434c4b4a45532f6543367650696e50372f4d7a5450546e334e2f316d3435717a535433644878460a544a3978454547304b6a75586c75563469486e6841545256485472416d35315178565a77526b6457566f30384752776f79693661587545587a433466622f79660a6a2f64796268443847673159616c34744e456a45316130416b5875416d797a6453426c415032545531643554475855587175326566387476644e596c516c39520a535a373675465972756362574255622f7a387465764d712b713257582b7567656a666c7534516c4570457a345533306e476b597162316a4c583968696a76375a0a4f76452b744947636f4f366f32717058724931317279493753786a5269786c43317a5772524f527362705959662f4d3267374f58596c73312f744830685a53700a625444706667586c62315a382f4769467143534a347735656a644747393142416f4d397555656f4b477a4f4565587a664a3153447578767959314d4c686e35440a76666f3162387a303966767655666e4153567432594d646457416638564f7275577944726c4b71705746522f4c4e61702f384c53524f6b45506e54516133682f0a6e513632426d755630686e6578786e45414b623245513d3d0a2d2d2d2d2d454e4420434f4e4649472d2d2d2d2d0a	2022-03-30 06:39:24.736714+00
11	1	\\x2d2d2d2d2d424547494e20434f4e4649472d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c38313034363361373965626364636138636463643237633135313334303234640a0a614c527a506a325972436950476b4c503130694773734a61782f5a7033316c364935392b36524d512f58436c7151517a75693172504165503170343056724c6f0a48316d6c5345655432334f447262597348424e74574b526646434d47584e466b735259395a714351574a3553554748574854337a505857354a477958644a76520a41396f54476e4134763043566c492b486c3956582f394355515a6279564e4254793931523146423430485045354d36765a53756253504e4d65744b714e75462f0a79637a73745851556578396b454565447356624e64714f6a5a544b43307a395349746c706d5851724b323442716a6b305a7734545153686c696f592b417a4c4e0a694a2b6d4a6730366738773265584a2b4a433030494d536857366e3639352b645247423131765368735665754272516d475966734f67314d72334e31326763340a4566334d632f4b4737654d4878693165372b662f7a35635578376d594236484b587746566f2f316b58485155684d37503341696d3062336c45472f67343559550a7371514667655a485730624c595537462b396f7676544f45334a6843335858622f61785073324d506d75556f333543514738762b4d4c314676692f416b6b6d340a4969764756666a4d3747563864524c4f306c68464e3955724f71324f456576764f784b317545437255336969316932654545525a66546e3330376a4d684638580a424e646e5647586f53736e7a426a4657442b50756b526769397a5835536b776e354c677a7537576b4a416f314151615851466d51394d4c51346a515a30654d350a50643951624d6b584559465232385832714c6b6b6b72375369657070776853736934737235434b46743966684d494b2f38514f306e624864394c4951756972410a42342b6454306761304c396564783547676e646b50584a2f45704f6e6c79544a33795552765959572f482b427a51356c644f7541317062654351364675576b520a4c385a686e685443445666344b784b6d6a6e4e684d4d6652683577664949672f4d555645327448375a5237546b4b41503934636b4d4979623630444c684b55460a45484a775559462f2b4b4c53734b5978507841347a6d50544d5032304251494f78566947734831714763792b452b2f2b61634e70784d4d70566672447146384d0a7770646671564b654b6f7a665065576c38484c53356a4a53397856664773597336374e38673134426e344e374c72366c6c7144526c53315679536d7a4c46624c0a4534446975464d323964755434485436346575636668574c697833505831646a4f474d7a76706c615063444c576c7376526a7078516d72303273484e754c43470a523657304f65796430644f6f6a2f7a413067657263635563733741694953727643306e387135435130367a325a694c77576f79437433696b6b514865304b47570a494e725246512b6478324e776a795367342f3649736f31314f41504251505272585a52426b65796e3672414575466f556b444d51792b6952643946535a5465570a4830392b6a37566752734862747531786158443679536e37756a336b32697078784234695857534e4758655047664241495a337761643571393730306a5468470a434d62453848624f64387a337a5845642b3163377a78357a683552336e644b4b636b35333667495a557a717958364c7072784c78564a55766f377235627043550a744a74745a4f33497a4a707167537447594c50536c6d46466b4a575274514b2f2f777a66304d33386e7a394167434266544b3156344f7178464541364e30494c0a474f765a575678434a6e66582f36354876413858704d3838347156667a65514e526f396d4b434e704f324c36524167764945555a7a4b6a59646f322f5a7a304f0a72746576347a6d3231594b4c456d314166735137724b4f33704e4a6871566436364f4e787a61633843492b4f464d7236465a39645151796c785444564143722b0a4d6a2b695757544579394c484d796c63616b5061504179537a46696f42696e434847614a6e6f5555677a7a5a44356e55615445455249557264506530443251440a704866344e5944465a624a364d78307a6f375274444e30706a754178787376785a4a6b305a4e66486f3631314575715563745741676e3447736b6e47786e53310a59713439706f396f6c496677774c36633467385a5a787478794e62346a4968652f6b68326b3330466953556d59614663306267447637784a75364772493435650a4a6d61565366585a4e646251694f53504759464d653658714b745167517369325267553451326558526f6a692f3636456d7a33666e50664a7a2f7a5051756b4c0a536a3478756e3333764f3743656f6e6a6f7a574d302f5636744e4c4d7178624b565077542b444b455444734770585956597a7a66692f78536a586d68576d42750a2b7270625075796652477152724f55514c776c35714a51623579473936476b757974316f36426451777139676e36627355453657337a4e442f3150314d7735300a546e6d3346564d756951507738787a545543363342794a446a7a50726d6e7354776a596c566e68556147644d757278486b67424d6b2b344f4b69366d627051750a6d355a59474376494b31337530343249764f5a2b7a6f2f4a316c6f686253664466634a334d7367316969556e76484f494c757a4a53503734766b574f555641300a2b34655a5247424e38537a72667478642f69664e79302f434d30355462493851732f456a302f7252575a57314b65314865484a5a64363339417a4b576d422b460a3241485636535a5a4a70636634422b536652642f79513d3d0a2d2d2d2d2d454e4420434f4e4649472d2d2d2d2d0a	2022-03-30 06:39:24.857151+00
\.


--
-- Data for Name: config_limits; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.config_limits (id, max) FROM stdin;
notification_rules_per_user	15
contact_methods_per_user	10
ep_steps_per_policy	10
ep_actions_per_step	20
participants_per_rotation	50
rules_per_schedule	30
integration_keys_per_service	30
unacked_alerts_per_service	200
targets_per_schedule	10
heartbeat_monitors_per_service	30
user_overrides_per_schedule	35
calendar_subscriptions_per_user	15
\.


--
-- Data for Name: engine_processing_versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.engine_processing_versions (type_id, version, state) FROM stdin;
heartbeat	1	{}
np_cycle	2	{}
escalation	3	{}
cleanup	1	{}
verify	2	{}
rotation	2	{}
schedule	3	{}
status_update	3	{}
message	9	{}
metrics	1	{"V1": {"NextAlertID": 79671}}
\.


--
-- Data for Name: ep_step_on_call_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ep_step_on_call_users (user_id, ep_step_id, start_time, end_time, id) FROM stdin;
eff381c9-461c-4d84-a061-a3c2ff2c2ce1	1003cff9-b733-4ab2-ac37-9a723b123f2f	2022-03-28 13:14:49.55227+00	\N	13930510
eff381c9-461c-4d84-a061-a3c2ff2c2ce1	114f686a-84ef-4878-8350-ac71623c4db3	2022-03-28 13:24:14.747844+00	\N	13930624
eff381c9-461c-4d84-a061-a3c2ff2c2ce1	7971f95e-649a-4f4a-9d54-f4b72bd5e139	2022-03-29 14:34:54.421455+00	\N	13949427
\.


--
-- Data for Name: escalation_policies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.escalation_policies (id, name, description, repeat, step_count) FROM stdin;
48e321d3-e708-47e1-acf5-83d47964da42	sample Policy	Auto-generated policy for sample	3	1
f8c83ea0-4acd-4eda-bd24-3fb2b9473bc5	devops Escalation Policy	Generated by Setup Wizard	1	1
2942d789-a34c-44ab-be77-812eea9d4119	test_escalation		3	1
\.


--
-- Data for Name: escalation_policy_actions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.escalation_policy_actions (id, escalation_policy_step_id, user_id, schedule_id, rotation_id, channel_id) FROM stdin;
d5c8b40c-7867-4d88-8a81-2a3ae8bc7f4a	1003cff9-b733-4ab2-ac37-9a723b123f2f	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	\N	\N
9d178679-1ea2-42c2-ab70-202066ac532f	114f686a-84ef-4878-8350-ac71623c4db3	\N	721b3f02-03a3-468b-b031-e0782afce47d	\N	\N
76d328d7-d5d2-4f8b-88b0-4e0e42becd51	114f686a-84ef-4878-8350-ac71623c4db3	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	\N	\N
73b0ff05-7155-4312-ac62-3cde67d774a5	114f686a-84ef-4878-8350-ac71623c4db3	\N	\N	3f28fd16-2ade-44ce-80d8-e93fcbd60851	\N
414f5b75-cd63-430b-8ccd-fff33e0ff6cd	7971f95e-649a-4f4a-9d54-f4b72bd5e139	\N	cc3f6acd-4491-49f1-8703-0cfc7863b2a4	\N	\N
6e4091ea-75fd-4ae7-9f16-acb97aa92c42	7971f95e-649a-4f4a-9d54-f4b72bd5e139	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	\N	\N
\.


--
-- Data for Name: escalation_policy_state; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.escalation_policy_state (escalation_policy_id, escalation_policy_step_id, escalation_policy_step_number, alert_id, last_escalation, loop_count, force_escalation, service_id, next_escalation, id) FROM stdin;
2942d789-a34c-44ab-be77-812eea9d4119	7971f95e-649a-4f4a-9d54-f4b72bd5e139	0	79676	2022-03-29 14:39:24.541578+00	0	f	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2022-03-29 14:40:24.541578+00	2267
2942d789-a34c-44ab-be77-812eea9d4119	7971f95e-649a-4f4a-9d54-f4b72bd5e139	0	79677	2022-03-29 14:47:24.425793+00	3	f	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2022-03-29 14:48:24.425793+00	2268
f8c83ea0-4acd-4eda-bd24-3fb2b9473bc5	114f686a-84ef-4878-8350-ac71623c4db3	0	79679	2022-03-29 15:35:49.428561+00	1	f	66f85992-4ad0-4f05-9a20-54e8587900fa	2022-03-29 15:36:49.428561+00	2270
2942d789-a34c-44ab-be77-812eea9d4119	7971f95e-649a-4f4a-9d54-f4b72bd5e139	0	79680	2022-03-30 05:20:59.143113+00	3	f	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2022-03-30 05:21:59.143113+00	2271
2942d789-a34c-44ab-be77-812eea9d4119	7971f95e-649a-4f4a-9d54-f4b72bd5e139	0	79681	2022-03-30 06:09:13.844361+00	3	f	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2022-03-30 06:10:13.844361+00	2272
\.


--
-- Data for Name: escalation_policy_steps; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.escalation_policy_steps (id, delay, step_number, escalation_policy_id) FROM stdin;
1003cff9-b733-4ab2-ac37-9a723b123f2f	5	0	48e321d3-e708-47e1-acf5-83d47964da42
114f686a-84ef-4878-8350-ac71623c4db3	1	0	f8c83ea0-4acd-4eda-bd24-3fb2b9473bc5
7971f95e-649a-4f4a-9d54-f4b72bd5e139	1	0	2942d789-a34c-44ab-be77-812eea9d4119
\.


--
-- Data for Name: gorp_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gorp_migrations (id, applied_at) FROM stdin;
20170426134008-init.sql	2022-03-22 10:15:09.442848+00
20170428154209-users-table.sql	2022-03-22 10:15:09.587714+00
20170502172843-user-settings.sql	2022-03-22 10:15:09.609918+00
20170503144542-remove-carrier.sql	2022-03-22 10:15:09.657764+00
20170503144821-remove-email-verified.sql	2022-03-22 10:15:09.659497+00
20170503154907-delay-minutes.sql	2022-03-22 10:15:09.660783+00
20170509154250-alerts.sql	2022-03-22 10:15:09.661378+00
20170515120511-escalation-policy-actions.sql	2022-03-22 10:15:09.690537+00
20170515162554-user-notifications.sql	2022-03-22 10:15:09.70752+00
20170518142432-alert-assignments.sql	2022-03-22 10:15:09.74978+00
20170530135027-schedule-rotation.sql	2022-03-22 10:15:09.755416+00
20170605131920-twilio-sms.sql	2022-03-22 10:15:09.822055+00
20170605131942-twilio-voice.sql	2022-03-22 10:15:09.829591+00
20170607103917-throttle.sql	2022-03-22 10:15:09.836949+00
20170612101232-escalation-tweaks.sql	2022-03-22 10:15:09.845805+00
20170613122551-auth-token.sql	2022-03-22 10:15:09.850411+00
20170619123628-add-constraints.sql	2022-03-22 10:15:09.859996+00
20170619164449-bobby-tables.sql	2022-03-22 10:15:09.863065+00
20170620104459-contact-constraints.sql	2022-03-22 10:15:09.892738+00
20170621141923-notification-query-fixes.sql	2022-03-22 10:15:09.897888+00
20170621170744-add-country-code.sql	2022-03-22 10:15:09.905272+00
20170623151348-on-call-alert-distinct.sql	2022-03-22 10:15:09.907599+00
20170623155346-delete-keys-with-service.sql	2022-03-22 10:15:09.91105+00
20170629104138-escalation-policy-tweak.sql	2022-03-22 10:15:09.915748+00
20170630095448-integration-to-integration-keys.sql	2022-03-22 10:15:09.916495+00
20170706102439-esc-zero-index.sql	2022-03-22 10:15:09.925122+00
20170707135355-esc-cascade-steps-actions.sql	2022-03-22 10:15:09.95182+00
20170707153545-limit-cm-per-interval.sql	2022-03-22 10:15:09.95636+00
20170710155447-fix-escalations.sql	2022-03-22 10:15:09.957986+00
20170712094434-notification-policy-updates.sql	2022-03-22 10:15:09.95871+00
20170713113728-escalation-schema-hardening.sql	2022-03-22 10:15:10.019104+00
20170714155817-notification-rule-tweak.sql	2022-03-22 10:15:10.022578+00
20170717151241-remove-old-esc-columns.sql	2022-03-22 10:15:10.026848+00
20170717151336-remove-old-service-columns.sql	2022-03-22 10:15:10.029744+00
20170717151358-remove-old-tables.sql	2022-03-22 10:15:10.035608+00
20170717152954-ids-to-uuids.sql	2022-03-22 10:15:10.049964+00
20170724162219-fix-alert-escalations.sql	2022-03-22 10:15:10.135907+00
20170725105059-rotations-shift-length-check.sql	2022-03-22 10:15:10.136837+00
20170725105905-fix-shift-calculation.sql	2022-03-22 10:15:10.137973+00
20170726141849-handle-missing-users.sql	2022-03-22 10:15:10.142683+00
20170726143800-no-oncall-for-future-rotations.sql	2022-03-22 10:15:10.143464+00
20170726155056-twilio-sms-errors.sql	2022-03-22 10:15:10.148086+00
20170726155351-twilio-voice-errors.sql	2022-03-22 10:15:10.153135+00
20170802114735-alert_logs_enum_update.sql	2022-03-22 10:15:10.158026+00
20170802160314-add-timezones.sql	2022-03-22 10:15:10.167673+00
20170808110638-user-email-nullable-allowed.sql	2022-03-22 10:15:10.192651+00
20170811110036-add-generic-integration-key.sql	2022-03-22 10:15:10.194752+00
20170817102712-atomic-escalation-policies.sql	2022-03-22 10:15:10.214897+00
20170818135106-add-gravatar-col-to-user.sql	2022-03-22 10:15:10.235121+00
20170825124926-escalation-policy-step-reorder.sql	2022-03-22 10:15:10.236172+00
20171024114842-adjust-notification-create-at-check.sql	2022-03-22 10:15:10.241529+00
20171027145352-dont-notify-disabled-cms.sql	2022-03-22 10:15:10.245639+00
20171030130758-ev3-drop-views.sql	2022-03-22 10:15:10.252271+00
20171030130759-ev3-schedule-rules.sql	2022-03-22 10:15:10.260731+00
20171030130800-ev3-notification-policy.sql	2022-03-22 10:15:10.277019+00
20171030130801-ev3-escalation-policy-state.sql	2022-03-22 10:15:10.286171+00
20171030130802-ev3-rotations.sql	2022-03-22 10:15:10.295805+00
20171030130804-ev3-assign-schedule-rotations.sql	2022-03-22 10:15:10.301388+00
20171030130806-ev3-add-rotation-ep-action.sql	2022-03-22 10:15:10.307945+00
20171030130810-ev3-notification-logs.sql	2022-03-22 10:15:10.3159+00
20171030130811-ev3-drop-ep-snapshot-trigger.sql	2022-03-22 10:15:10.323724+00
20171030130812-ev3-rotation-state.sql	2022-03-22 10:15:10.324722+00
20171030130813-ev3-throttle-locks.sql	2022-03-22 10:15:10.327519+00
20171030150519-ev3-remove-status-trigger.sql	2022-03-22 10:15:10.339428+00
20171126093536-schedule-rule-processing.sql	2022-03-22 10:15:10.340443+00
20171201104359-structured-alert-logs.sql	2022-03-22 10:15:10.346935+00
20171201104433-add-alert-log-types.sql	2022-03-22 10:15:10.357994+00
20171205125227-twilio-egress-sms-tracking.sql	2022-03-22 10:15:10.358079+00
20171211101108-twilio-egress-voice-tracking.sql	2022-03-22 10:15:10.363693+00
20171213141802-add-alert-source-email.sql	2022-03-22 10:15:10.370267+00
20171220113439-add-alert-dedup-keys.sql	2022-03-22 10:15:10.370351+00
20171221134500-limit-configuration.sql	2022-03-22 10:15:10.374007+00
20171221138101-notification-rule-limit.sql	2022-03-22 10:15:10.378739+00
20171221140906-contact-method-limit.sql	2022-03-22 10:15:10.38681+00
20171221142234-ep-step-limit.sql	2022-03-22 10:15:10.393708+00
20171221142553-ep-step-action-limit.sql	2022-03-22 10:15:10.396405+00
20171221150317-rotation-participant-limit.sql	2022-03-22 10:15:10.399076+00
20171221150825-schedule-rule-limit.sql	2022-03-22 10:15:10.401242+00
20171221150955-integration-key-limit.sql	2022-03-22 10:15:10.404072+00
20171221151358-unacked-alert-limit.sql	2022-03-22 10:15:10.406247+00
20171221162356-case-insenstive-name-constraints.sql	2022-03-22 10:15:10.409032+00
20180103113251-schedule-target-limit.sql	2022-03-22 10:15:10.416166+00
20180104114110-disable-process-alerts-queue.sql	2022-03-22 10:15:10.4188+00
20180104122450-wait-alert-queue-finished.sql	2022-03-22 10:15:10.421526+00
20180104123517-outgoing-messages.sql	2022-03-22 10:15:10.421776+00
20180104124640-ncycle-tick.sql	2022-03-22 10:15:10.450048+00
20180104125444-twilio-sms-multiple-callbacks.sql	2022-03-22 10:15:10.456423+00
20180109114058-email-integration-key.sql	2022-03-22 10:15:10.459123+00
20180110155110-alert-unique-dedup-service.sql	2022-03-22 10:15:10.45924+00
20180117110856-status-update-message-type.sql	2022-03-22 10:15:10.464236+00
20180117115123-alert-status-updates.sql	2022-03-22 10:15:10.464407+00
20180118112019-restrict-cm-to-same-user.sql	2022-03-22 10:15:10.480271+00
20180126162030-heartbeat-auth-log-subject-type.sql	2022-03-22 10:15:10.483755+00
20180126162093-heartbeats.sql	2022-03-22 10:15:10.483838+00
20180126162144-heartbeat-auth-log-data.sql	2022-03-22 10:15:10.492125+00
20180130123755-heartbeat-limit-key.sql	2022-03-22 10:15:10.496043+00
20180130123852-heartbeat-limit.sql	2022-03-22 10:15:10.496122+00
20180201180221-add-verification-code.sql	2022-03-22 10:15:10.498325+00
20180207113632-ep-step-number-consistency.sql	2022-03-22 10:15:10.509972+00
20180207124220-rotation-participant-position-consistency.sql	2022-03-22 10:15:10.51542+00
20180216104945-alerts-split-summary-details.sql	2022-03-22 10:15:10.519235+00
20180228103159-schedule-overrides-limit-key.sql	2022-03-22 10:15:10.523173+00
20180228111204-schedule-overrides.sql	2022-03-22 10:15:10.523419+00
20180313152132-schedule-on-call-users.sql	2022-03-22 10:15:10.535745+00
20180315113303-strict-rotation-state.sql	2022-03-22 10:15:10.544644+00
20180320153326-npcycle-indexes.sql	2022-03-22 10:15:10.557921+00
20180321143255-ep-step-count.sql	2022-03-22 10:15:10.562283+00
20180321145054-strict-ep-state.sql	2022-03-22 10:15:10.566238+00
20180326154252-move-rotation-triggers.sql	2022-03-22 10:15:10.576477+00
20180330110116-move-ep-triggers.sql	2022-03-22 10:15:10.578936+00
20180403113645-fix-rot-part-delete.sql	2022-03-22 10:15:10.579955+00
20180417142940-region-processing.sql	2022-03-22 10:15:10.581291+00
20180517100033-clear-cycles-on-policy-change.sql	2022-03-22 10:15:10.58765+00
20180517135700-policy-reassignment-trigger-fix.sql	2022-03-22 10:15:10.589011+00
20180517210000-auth2.sql	2022-03-22 10:15:10.595088+00
20180517220000-keyring.sql	2022-03-22 10:15:10.611461+00
20180517230000-auth-nonce.sql	2022-03-22 10:15:10.615825+00
20180521124533-UserFavorites.sql	2022-03-22 10:15:10.618503+00
20180710110438-engine-processing-versions.sql	2022-03-22 10:15:10.623798+00
20180720121433-increment-module-versions.sql	2022-03-22 10:15:10.629803+00
20180720121533-drop-dedup-trigger.sql	2022-03-22 10:15:10.631106+00
20180720121633-drop-description-col.sql	2022-03-22 10:15:10.63205+00
20180720121733-fix-svc-ep-state-trigger.sql	2022-03-22 10:15:10.633947+00
20180720121833-create-ep-state-on-alert.sql	2022-03-22 10:15:10.636251+00
20180720121933-store-next-escalation-time.sql	2022-03-22 10:15:10.640811+00
20180720122033-ep-step-on-call.sql	2022-03-22 10:15:10.643187+00
20180720122133-clear-next-esc-on-ack.sql	2022-03-22 10:15:10.649077+00
20180720122233-drop-unique-cycles-constraint.sql	2022-03-22 10:15:10.650505+00
20180720122333-fix-schedule-index.sql	2022-03-22 10:15:10.652045+00
20180720122433-trig-alert-on-force-escalation.sql	2022-03-22 10:15:10.655099+00
20180720122533-drop-ep-state-np-trig.sql	2022-03-22 10:15:10.657365+00
20180720122633-update-existing-escalations.sql	2022-03-22 10:15:10.658421+00
20180728150427-add-provider-msg-id.sql	2022-03-22 10:15:10.66437+00
20180803090205-drop-alert-assignments.sql	2022-03-22 10:15:10.667561+00
20180803090305-drop-alert-escalation-policy-snapshots.sql	2022-03-22 10:15:10.672889+00
20180803090405-drop-notification-logs.sql	2022-03-22 10:15:10.679303+00
20180803090505-drop-process-alerts.sql	2022-03-22 10:15:10.685467+00
20180803090605-drop-process-rotations.sql	2022-03-22 10:15:10.69023+00
20180803090705-drop-process-schedules.sql	2022-03-22 10:15:10.695021+00
20180803090805-drop-sent-notifications.sql	2022-03-22 10:15:10.700321+00
20180803090905-drop-throttle.sql	2022-03-22 10:15:10.707989+00
20180803091005-drop-user-contact-method-locks.sql	2022-03-22 10:15:10.710366+00
20180803110851-drop-twilio-egress-sms-status.sql	2022-03-22 10:15:10.717051+00
20180803110859-drop-twilio-egress-voice-status.sql	2022-03-22 10:15:10.721264+00
20180806092512-incr-message-version.sql	2022-03-22 10:15:10.726379+00
20180806102513-drop-twilio-voice-callbacks.sql	2022-03-22 10:15:10.727022+00
20180806102620-drop-user-notification-cycles.sql	2022-03-22 10:15:10.732303+00
20180806102708-drop-auth-github-users.sql	2022-03-22 10:15:10.738817+00
20180806102923-drop-auth-token-codes.sql	2022-03-22 10:15:10.745161+00
20180816094955-switchover-state.sql	2022-03-22 10:15:10.751348+00
20180816095055-add-row-ids.sql	2022-03-22 10:15:10.845253+00
20180816095155-change-log.sql	2022-03-22 10:15:10.873832+00
20180816164203-drop-end-time-check.sql	2022-03-22 10:15:10.873936+00
20180821150330-deferable-status-cm.sql	2022-03-22 10:15:10.874665+00
20180822153707-defer-rotation-state.sql	2022-03-22 10:15:10.875339+00
20180822153914-defer-ep-state.sql	2022-03-22 10:15:10.880152+00
20180831132457-user-last-alert-log-indexes.sql	2022-03-22 10:15:10.886773+00
20180831132707-alerts-service-index.sql	2022-03-22 10:15:10.891482+00
20180831132743-np-cycle-alert-index.sql	2022-03-22 10:15:10.895055+00
20180831132927-alert-logs-index.sql	2022-03-22 10:15:10.910449+00
20180831143308-outgoing-messages-index.sql	2022-03-22 10:15:10.91808+00
20180907111203-schedule-rule-endtime-fix.sql	2022-03-22 10:15:10.91821+00
20180918102226-add-service-label.sql	2022-03-22 10:15:10.92079+00
20181004032148-labels-switchover-trigger.sql	2022-03-22 10:15:10.932484+00
20181004145558-fix-deleting-participants.sql	2022-03-22 10:15:10.935691+00
20181008111401-twilio-sms-short-reply.sql	2022-03-22 10:15:10.936663+00
20181018131939-fix-rotation-deletions.sql	2022-03-22 10:15:10.949266+00
20181107133329-notification-channels.sql	2022-03-22 10:15:10.950397+00
20181107155035-nc-id-to-ep-action.sql	2022-03-22 10:15:10.955688+00
20181107155229-om-notification-channel.sql	2022-03-22 10:15:10.961227+00
20190117130422-notif-chan-engine-versions.sql	2022-03-22 10:15:10.964947+00
20190129110250-add-cleanup-module.sql	2022-03-22 10:15:10.966221+00
20190201104727-alert-logs-channel.sql	2022-03-22 10:15:10.970421+00
20190201142137-drop-sub-constraint.sql	2022-03-22 10:15:10.97053+00
20190225112925-config-table.sql	2022-03-22 10:15:10.973774+00
20190312153204-slack-api-change.sql	2022-03-22 10:15:10.980429+00
20190313125552-slack-user-link.sql	2022-03-22 10:15:10.982785+00
20190404105850-nc-no-meta.sql	2022-03-22 10:15:10.988324+00
20190517144224-trigger-config-sync.sql	2022-03-22 10:15:10.989357+00
20190613114217-remove-switchover-triggers.sql	2022-03-22 10:15:11.007379+00
20190613120345-drop-switchover-resources.sql	2022-03-22 10:15:11.007478+00
20190701111645-add-rotation-favorite.sql	2022-03-22 10:15:11.01243+00
20190702161722-add-schedule-favorites.sql	2022-03-22 10:15:11.01626+00
20190715130233-verification-codes-update.sql	2022-03-22 10:15:11.019394+00
20190725124750-cascade-heartbeat-delete.sql	2022-03-22 10:15:11.033131+00
20190807210857-set-default-system-limits.sql	2022-03-22 10:15:11.042722+00
20190815160200-site24x7-integration.sql	2022-03-22 10:15:11.04661+00
20191016162114-om-status-index.sql	2022-03-22 10:15:11.046809+00
20191021145356-message-bundle-versions.sql	2022-03-22 10:15:11.050122+00
20191021145357-message-bundle-types.sql	2022-03-22 10:15:11.052472+00
20191021145358-message-bundles.sql	2022-03-22 10:15:11.052609+00
20191216145826-calendar-subscriptions.sql	2022-03-22 10:15:11.061582+00
20200204140537-calendar-subscriptions-per-user-limit-key.sql	2022-03-22 10:15:11.072531+00
20200204152220-calendar-subscriptions-per-user.sql	2022-03-22 10:15:11.07261+00
20200413113132-add-no-notification-alert-log.sql	2022-03-22 10:15:11.074788+00
20200702112635-contact-method-metadata.sql	2022-03-22 10:15:11.074867+00
20200716212352-prometheus-alertmanager-integration.sql	2022-03-22 10:15:11.076042+00
20200805132936-test-verify-index.sql	2022-03-22 10:15:11.076118+00
20200908095243-session-access-time.sql	2022-03-22 10:15:11.078912+00
20200922140909-session-last-access-time.sql	2022-03-22 10:15:11.079595+00
20201123172337-alert-cleanup-index.sql	2022-03-22 10:15:11.081134+00
20201209112322-alert-logs-drop-fkeys.sql	2022-03-22 10:15:11.08397+00
20210309144821-rotation-module-update.sql	2022-03-22 10:15:11.09319+00
20210323155516-temp-schedules.sql	2022-03-22 10:15:11.095639+00
20210420100139-sched-module-v3.sql	2022-03-22 10:15:11.103641+00
20210601113520-override-lock.sql	2022-03-22 10:15:11.104183+00
20210609113508-add-escalation-policies-favorite.sql	2022-03-22 10:15:11.105205+00
20210609140958-message-type-schedule-on-call.sql	2022-03-22 10:15:11.111538+00
20210609141058-outgoing-messages-schedule-id.sql	2022-03-22 10:15:11.111647+00
20210623104011-disable-user-last-alert-log.sql	2022-03-22 10:15:11.115234+00
20210623104111-alert-status-subscriptions.sql	2022-03-22 10:15:11.116592+00
20210719132553-webhook-user-contact-method-type.sql	2022-03-22 10:15:11.145001+00
20210806074405-outgoing-source-value.sql	2022-03-22 10:15:11.145094+00
20210811110849-valid-status-updates-indexes.sql	2022-03-22 10:15:11.146557+00
20210811141518-search-indexes.sql	2022-03-22 10:15:11.17434+00
20210813131213-sched-query-index.sql	2022-03-22 10:15:11.177426+00
20210817132557-add-user-favorite.sql	2022-03-22 10:15:11.177643+00
20220224125018-schedule-data-id.sql	2022-03-28 10:56:52.766521+00
20220307103153-add-metrics-proctype.sql	2022-03-28 10:56:52.8117+00
20220307103253-add-alert-metrics.sql	2022-03-28 10:56:52.813161+00
\.


--
-- Data for Name: heartbeat_monitors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.heartbeat_monitors (id, name, service_id, heartbeat_interval, last_state, last_heartbeat) FROM stdin;
f3576ffa-a3f2-4a59-a4c6-90b1b2468809	DevopsTeam - Webhook	66f85992-4ad0-4f05-9a20-54e8587900fa	00:15:00	inactive	\N
\.


--
-- Data for Name: integration_keys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.integration_keys (id, name, type, service_id) FROM stdin;
8a1ae596-84d0-4c9a-96ce-70da2bd6a836	sample	prometheusAlertmanager	bf3124c9-722e-42fb-9177-eff6a7008bf8
77ab5e02-ebbc-4d57-883e-817b7658126e	Prometheus Alertmanager Webhook URL Integration Key	prometheusAlertmanager	66f85992-4ad0-4f05-9a20-54e8587900fa
e8da7b1f-68be-4124-a357-62f0e6e32614	Devops team shits	grafana	66f85992-4ad0-4f05-9a20-54e8587900fa
b76ba992-a4d3-492d-b449-4abd1ca5a205	test one	prometheusAlertmanager	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09
\.


--
-- Data for Name: keyring; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.keyring (id, verification_keys, signing_key, next_key, next_rotation, rotation_count) FROM stdin;
api-keys	\\x7b2230223a224d453477454159484b6f5a497a6a3043415159464b344545414345444f6741456e6c665236796a6c622f4d553444444a5951453437706d5a752f76763646326466327a44566b4362415930396e54587767792b623466643763634f387939356d704f65486b6c36707953633d222c2231223a224d453477454159484b6f5a497a6a3043415159464b344545414345444f674145443474365261484b6e472b63334d41516430553631713257563276683436445944614c33614c56387a774478434175464c6b764374634f392b706733464f30445a4b7338556753597768453d227d	\\x2d2d2d2d2d424547494e2045434453412050524956415445204b45592d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c61353965333663306662396164313631343533323564333230363833343464610a0a75676b6f682f2f4846347339554f77426f7175496a4d505564443367317a6b68617253324d6837382f704f366f6e7243355253533935457537442f73334858370a666f64617873716b33355066336a4e79683069516844396f31726b683731414e4b4569534e6b784c6a473575496652614c7a7a58574f457862305a4d764e67690a774448765372764556442b6b4c42473436546f6361673d3d0a2d2d2d2d2d454e442045434453412050524956415445204b45592d2d2d2d2d0a	\\x2d2d2d2d2d424547494e2045434453412050524956415445204b45592d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c34643839646334636463386465363032373930663862396232626232656131380a0a4f76596d50513756476f4669326d597576724638565a564c426157444654476245567248633732676a6b7a59395248546f7350362b58717247536356734a73680a58465051584d79574f66726f7765766c4d4a3942396f656c4a31543952675948704267717466465a72475458633953696549783054794b57774f5a716a4b6e790a66553677585a77426338594369424779735a516258773d3d0a2d2d2d2d2d454e442045434453412050524956415445204b45592d2d2d2d2d0a	\N	0
oauth-state	\\x7b2231223a224d453477454159484b6f5a497a6a3043415159464b344545414345444f674145593568494e33555143525952495a4c424e6267474c674256673636366c306d436e4e79437754746a4c762f2b4b513557666153574142766a654a336a667466323249514253685052356e6b3d222c2232223a224d453477454159484b6f5a497a6a3043415159464b344545414345444f674145315442503832674f2f387863637766334454576f59424f6d347032716163564765435635626f5a65662f5a684e43666e383179646c6574435274694f5358735649386a5876777074706d413d222c2233223a224d453477454159484b6f5a497a6a3043415159464b344545414345444f674145377554326c61665577757577564678323775556f49302b7546795339706d4e376f6955324d2f584c4c794b614278572b5870625676656a6c44305950467535524d3667515a3852726c4c383d227d	\\x2d2d2d2d2d424547494e2045434453412050524956415445204b45592d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c65393737626163326639633666643130396534343036663232343739666661310a0a59795836623032484a6359336d534956707578427446414e4d677279636f617636786d7576437872347339616a742f4b41546d79754b4e643777536c516344420a6853326b313070436671366f446367417068736a4f714d623545654a493373423147656d304a515071454f4176636237522f437342564454574467614d4143730a6c66763476564177344c36467553596850576d3763773d3d0a2d2d2d2d2d454e442045434453412050524956415445204b45592d2d2d2d2d0a	\\x2d2d2d2d2d424547494e2045434453412050524956415445204b45592d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c38663764313665363265633761313739633636316237633033653939303731350a0a3732644a645353674c547368674668346d3443612b5565627742355a68466f4c4b38776e51554f4d33325531346f31546c6b4145444b6966356b4a6961344e680a305a716c5961374d545950683846725a4c714c46687a56664b345646696f3350536e4845307349684a494875773356336e39756d513853302f5166744a32492f0a366d4a32586b79434d4964314d492b7043326c4938773d3d0a2d2d2d2d2d454e442045434453412050524956415445204b45592d2d2d2d2d0a	2022-03-30 13:32:53.993753+00	2
browser-sessions	\\x7b2230223a224d453477454159484b6f5a497a6a3043415159464b344545414345444f6741456d487642682f70384566622f7547772f6e4d6c3770597150487544664e63455472634b6a7a694c4b32773075334a4c61636631646c632b37504a703344657170746f5477307432543248773d222c2231223a224d453477454159484b6f5a497a6a3043415159464b344545414345444f6741456c7a6d5156696868776877454a30754e376875444b65666554625759466f4441623554503062744335556e556b354d346f427778763849534946314f64565267615a5756495766425869303d222c2232223a224d453477454159484b6f5a497a6a3043415159464b344545414345444f6741453143576a77725865786143487556345733644f43564b41793573495358786976684f49636d306436476f485472574c665239666d435534367578484361464674586c466c41647a4e2b31383d222c2233223a224d453477454159484b6f5a497a6a3043415159464b344545414345444f674145352b3670564e5665484d68463843545a45712b7a726f444736593051783450326e7a2b67686a695a776f44735a2f713463666d3845426f47623352427361372f50317a32373341305167593d227d	\\x2d2d2d2d2d424547494e2045434453412050524956415445204b45592d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c62376435303139343966633033353137623330353631356338663133363261650a0a3235304f42726a394e486d44474966576a566b7275494c54425263516d516d6e49516452472f7746324236687051742b6a46534561716843302f45416d7367610a6232304c6d7954714163486a577550632b6f6e4368506f474c3438686b7a684c67356d625272343347335a7965714442594c474663764a6a776d533772374b740a3442764f644b5650456356524f625a646f465a4653413d3d0a2d2d2d2d2d454e442045434453412050524956415445204b45592d2d2d2d2d0a	\\x2d2d2d2d2d424547494e2045434453412050524956415445204b45592d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c35656661656661343363643966366132346163306633323731303836643233340a0a4945712f664a4569326c423638626d487257364f53305034306e4e624879572b6b77383966734c6a7564644f73354c484e496a3969316c6d4167426f747054520a684a6973527255376c687750764d5a4a626d6936346a3053786f4c32627755745456457a54364134712b627532766d615056616c74566b52746361736b79544d0a6e6b4968567944627a6f576a563869453946703476673d3d0a2d2d2d2d2d454e442045434453412050524956415445204b45592d2d2d2d2d0a	2022-03-30 13:32:54.00472+00	2
\.


--
-- Data for Name: labels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.labels (id, tgt_service_id, key, value) FROM stdin;
761	66f85992-4ad0-4f05-9a20-54e8587900fa	volty/simplytrack	simplytrack
762	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	volty/simplytrack	test
763	bf3124c9-722e-42fb-9177-eff6a7008bf8	volty/simplytrack	tesrt
\.


--
-- Data for Name: notification_channels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification_channels (id, created_at, type, name, value, meta) FROM stdin;
\.


--
-- Data for Name: notification_policy_cycles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification_policy_cycles (id, user_id, alert_id, repeat_count, started_at, checked, last_tick) FROM stdin;
12fdee76-a264-4535-b79c-067e428636ad	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79681	0	2022-03-30 06:03:09.232467+00	t	2022-03-30 10:15:43.543032+00
bb595ea3-925a-47d7-aa71-80f6e36fbea4	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79681	0	2022-03-30 06:02:06.292851+00	t	2022-03-30 10:15:43.543032+00
1f64e70a-a035-426b-bf55-c10a4464018a	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79681	0	2022-03-30 06:09:13.844361+00	t	2022-03-30 10:15:43.543032+00
63096246-ee9b-4385-98f5-d2b346e5f32a	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79681	0	2022-03-30 06:08:12.964435+00	t	2022-03-30 10:15:43.543032+00
\.


--
-- Data for Name: outgoing_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.outgoing_messages (id, message_type, contact_method_id, created_at, last_status, last_status_at, status_details, fired_at, sent_at, retry_count, next_retry_at, sending_deadline, user_id, alert_id, cycle_id, service_id, escalation_policy_id, alert_log_id, user_verification_code_id, provider_msg_id, provider_seq, channel_id, status_alert_ids, schedule_id, src_value) FROM stdin;
6dde074a-75d1-4d31-bb90-a0097d7b7c54	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 14:47:24.432375+00	bundled	2022-03-29 14:47:25.50089+00	ab0221a1-03bb-456a-822d-5e4f938d89c0	\N	\N	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79677	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	\N	0	\N	\N	\N	\N
b34be805-5470-4e3e-a6fb-bf5c0270895d	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 05:39:18.048007+00	delivered	2022-03-29 05:39:33.722607+00	delivered	\N	2022-03-29 05:39:19.124617+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79673	\N	66f85992-4ad0-4f05-9a20-54e8587900fa	f8c83ea0-4acd-4eda-bd24-3fb2b9473bc5	\N	\N	Twilio-SMS:SM6a567aa8737840518c824e023ef6a860	0	\N	\N	\N	+16106006812
4cf9c2c5-ab8d-47bd-b920-af679ed05226	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 14:49:34.425093+00	bundled	2022-03-29 14:49:35.413724+00	ab0221a1-03bb-456a-822d-5e4f938d89c0	\N	\N	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79677	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	\N	0	\N	\N	\N	\N
913cc37f-90fd-4a47-b54d-de8a73377e4e	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-30 06:08:12.976816+00	bundled	2022-03-30 06:08:14.488801+00	cb16d29f-bc99-44d0-92ef-e55e8b6f5c7f	\N	\N	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79681	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	\N	0	\N	\N	\N	\N
66ebc248-8d36-4134-ba98-916fed52de19	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-30 06:08:12.976816+00	bundled	2022-03-30 06:08:14.488801+00	cb16d29f-bc99-44d0-92ef-e55e8b6f5c7f	\N	\N	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79681	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	\N	0	\N	\N	\N	\N
ab0221a1-03bb-456a-822d-5e4f938d89c0	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 14:46:19.435246+00	delivered	2022-03-29 14:50:04.905881+00	delivered	\N	2022-03-29 14:49:55.684019+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79677	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SM7d559a24495c4d96b2b22d6791f55559	0	\N	\N	\N	+16106006812
cb16d29f-bc99-44d0-92ef-e55e8b6f5c7f	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-30 06:08:12.976816+00	delivered	2022-03-30 06:08:23.902991+00	delivered	\N	2022-03-30 06:08:14.511011+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79681	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SMbb99e809752d4f64b4c55a1fb23e18f8	0	\N	\N	\N	+16106006812
064590e1-2d21-4c10-a320-6d33e1817a77	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-28 13:19:54.730206+00	delivered	2022-03-28 13:20:06.422214+00	delivered	\N	2022-03-28 13:19:55.745452+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79672	\N	bf3124c9-722e-42fb-9177-eff6a7008bf8	48e321d3-e708-47e1-acf5-83d47964da42	\N	\N	Twilio-SMS:SM165de8d45fa9492680f7f6b50649fab1	0	\N	\N	\N	+16106006812
a4f6f84e-8fbe-459b-bb50-3c19797708a6	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-30 06:13:19.025176+00	delivered	2022-03-30 06:13:32.122039+00	delivered	\N	2022-03-30 06:13:21.464143+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79681	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SMa4db20767473475b97fff9d1226e3bf8	0	\N	\N	\N	+16106006812
6c274572-5040-4deb-a23b-262db0923d7a	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-28 13:26:04.771584+00	delivered	2022-03-28 13:26:17.574276+00	delivered	\N	2022-03-28 13:26:05.823559+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79672	\N	bf3124c9-722e-42fb-9177-eff6a7008bf8	48e321d3-e708-47e1-acf5-83d47964da42	\N	\N	Twilio-SMS:SM2314ff3fded8406c80591ffd1903597c	0	\N	\N	\N	+16106006812
d5bc08f6-e663-4981-a71d-c61413776616	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-28 13:21:04.763199+00	delivered	2022-03-28 13:21:14.207017+00	delivered	\N	2022-03-28 13:21:05.925143+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79672	\N	bf3124c9-722e-42fb-9177-eff6a7008bf8	48e321d3-e708-47e1-acf5-83d47964da42	\N	\N	Twilio-SMS:SM7e0b257a76cd48a6b73a0a81ffbf677f	0	\N	\N	\N	+16106006812
0e991b33-e0e2-4678-a249-d932313a2c87	alert_status_update	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-28 13:21:05.521294+00	delivered	2022-03-28 13:22:18.755634+00	delivered	\N	2022-03-28 13:22:10.720859+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79672	\N	\N	\N	6	\N	Twilio-SMS:SMde2add0d7c294048944c96f207a69b49	0	\N	\N	\N	+16106006812
cbe29367-6ae3-4c25-aeb7-9292f116dba9	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-28 13:26:14.759096+00	delivered	2022-03-28 13:27:15.642215+00	delivered	\N	2022-03-28 13:27:06.169448+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79672	\N	bf3124c9-722e-42fb-9177-eff6a7008bf8	48e321d3-e708-47e1-acf5-83d47964da42	\N	\N	Twilio-SMS:SM28b7bfd369024012bc81010f8360ddc1	0	\N	\N	\N	+16106006812
2f0a36c3-5634-48e2-89b1-c9e2c20fdc51	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-28 13:28:19.956228+00	delivered	2022-03-28 13:30:35.981194+00	delivered	\N	2022-03-28 13:28:21.125302+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79672	\N	bf3124c9-722e-42fb-9177-eff6a7008bf8	48e321d3-e708-47e1-acf5-83d47964da42	\N	\N	Twilio-SMS:SM209394321dbe4a009e319bf6741e3bf4	0	\N	\N	\N	+16106006812
67d2fd45-7e24-4cb7-89d2-fcecdaa4c6c3	alert_status_update	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-28 13:28:20.693771+00	delivered	2022-03-28 13:35:06.030845+00	delivered	\N	2022-03-28 13:34:55.79869+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79672	\N	\N	\N	13	\N	Twilio-SMS:SMe04f8c2d726d40089e698530944014e2	0	\N	\N	\N	+16106006812
36f15d2b-fbf2-4b7d-a27d-3f32fa699ae5	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 14:02:04.653683+00	sent	2022-03-29 14:02:08.951461+00	sent	\N	2022-03-29 14:02:06.058585+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79673	\N	66f85992-4ad0-4f05-9a20-54e8587900fa	f8c83ea0-4acd-4eda-bd24-3fb2b9473bc5	\N	\N	Twilio-SMS:SMa836619158744fbfb81b134d9f66d0b5	0	\N	\N	\N	+16106006812
e24a180a-3850-4cbb-ae00-865fd4d183a9	alert_status_update	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 14:14:15.200556+00	delivered	2022-03-29 14:15:26.358638+00	delivered	\N	2022-03-29 14:15:15.678161+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79673	\N	\N	\N	30	\N	Twilio-SMS:SM21983eac9ee44e70830727c74f4274ba	0	\N	\N	\N	+16106006812
e2d84213-3030-424e-a34b-b539d1a63de0	alert_status_update	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 14:02:05.606121+00	delivered	2022-03-29 14:03:15.609205+00	delivered	\N	2022-03-29 14:03:06.656904+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79673	\N	\N	\N	26	\N	Twilio-SMS:SM03c0dbccaf8c4e039d2e5850f5190cc9	0	\N	\N	\N	+16106006812
81531730-ea2a-4251-8475-b5a1b96a1a4a	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 14:14:14.444961+00	delivered	2022-03-29 14:14:26.38213+00	delivered	\N	2022-03-29 14:14:15.613007+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79673	\N	66f85992-4ad0-4f05-9a20-54e8587900fa	f8c83ea0-4acd-4eda-bd24-3fb2b9473bc5	\N	\N	Twilio-SMS:SMad9a8e3e89fa45ce9ce706ffce58824d	0	\N	\N	\N	+16106006812
a1b23a7c-c438-4e4d-8eb1-0d6eb9829fa9	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 14:34:54.447774+00	delivered	2022-03-29 14:35:04.949231+00	delivered	\N	2022-03-29 14:34:55.549268+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79675	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SMa3873f19cdb2454bb507f75e824b781a	0	\N	\N	\N	+16106006812
aa75c6ae-6dee-4205-b245-31b0dd6fea17	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 14:35:54.443412+00	delivered	2022-03-29 14:36:10.386978+00	delivered	\N	2022-03-29 14:36:00.465447+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79675	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SM0c9d410d15c14e42b6d3e6244d218254	0	\N	\N	\N	+16106006812
fb1452b9-255b-423b-989e-24353490b41a	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 14:39:24.557837+00	delivered	2022-03-29 14:39:34.831092+00	delivered	\N	2022-03-29 14:39:25.702844+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79676	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SMce02fee8ca96467fbeda3bf9b1fb9744	0	\N	\N	\N	+16106006812
60bb6f3f-4eaf-4973-8da0-63db6136feb6	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 14:44:19.431072+00	delivered	2022-03-29 14:44:32.40815+00	delivered	\N	2022-03-29 14:44:20.599721+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79677	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SM83219b92a6ca4a1b9019ae1ecbf73e55	0	\N	\N	\N	+16106006812
3ffd1153-2c7b-4c51-b62d-cb1a41bcc6a4	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 14:45:19.43331+00	delivered	2022-03-29 14:45:37.244558+00	delivered	\N	2022-03-29 14:45:25.418763+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79677	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SMce54644aae864ac397d0a327a00cd1bc	0	\N	\N	\N	+16106006812
5e14d2ea-08a1-4338-9a63-f4e18bfacd64	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 15:34:44.431704+00	delivered	2022-03-29 15:34:55.290939+00	delivered	\N	2022-03-29 15:34:45.364153+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79679	\N	66f85992-4ad0-4f05-9a20-54e8587900fa	f8c83ea0-4acd-4eda-bd24-3fb2b9473bc5	\N	\N	Twilio-SMS:SM6c880764a5354947bb49ba7cc66bdf59	0	\N	\N	\N	+16106006812
f1c2ae43-f592-46c4-ba18-a4c6d8e9b4bb	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 14:50:34.431183+00	delivered	2022-03-29 14:51:09.089644+00	delivered	\N	2022-03-29 14:51:00.687146+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79677	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SM81af148c59c247c39d461f86c510a8af	0	\N	\N	\N	+16106006812
7d6e8b4e-06f2-4429-9ba2-eb122282140b	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-30 06:09:13.849248+00	delivered	2022-03-30 06:09:23.438604+00	delivered	\N	2022-03-30 06:09:15.051295+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79681	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SMfa782a670a1447079cca8dcacf584425	0	\N	\N	\N	+16106006812
72224c05-a169-46ca-88db-a07b79d9619c	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 14:53:26.8572+00	bundled	2022-03-29 14:53:27.835638+00	4ce8cbe1-cd73-4e96-84c1-b183b560386b	\N	\N	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79677	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	\N	0	\N	\N	\N	\N
4ce8cbe1-cd73-4e96-84c1-b183b560386b	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 14:51:34.474156+00	delivered	2022-03-29 14:54:41.723285+00	delivered	\N	2022-03-29 14:54:30.34429+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79677	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SM62d768c29ff04918bd9dd4c48d667d0e	0	\N	\N	\N	+16106006812
25f7e277-fe11-4122-9651-24e517c7ac08	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-30 06:14:19.237143+00	delivered	2022-03-30 06:17:18.79625+00	delivered	\N	2022-03-30 06:17:10.029052+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79681	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SM6b43335918ce4080ae4c652ff5bce2f0	0	\N	\N	\N	+16106006812
e5c2fdf8-c5ce-4c57-8cde-74a69984f7fe	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 15:09:49.437642+00	delivered	2022-03-29 15:10:01.455117+00	delivered	\N	2022-03-29 15:09:50.404869+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79678	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SM89471b1f946342abad43ab21d33b1993	0	\N	\N	\N	+16106006812
cc043184-40e9-410e-92b8-56c8b6e71307	alert_status_update	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 15:10:50.003306+00	delivered	2022-03-29 15:11:05.285856+00	delivered	\N	2022-03-29 15:10:55.315066+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79678	\N	\N	\N	64	\N	Twilio-SMS:SM951ed51180974730b7cefcef576fc747	0	\N	\N	\N	+16106006812
f65a21d9-f7d3-45b4-8cf0-4ac946095e32	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-29 15:35:49.437079+00	delivered	2022-03-29 15:36:01.612578+00	delivered	\N	2022-03-29 15:35:50.371989+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79679	\N	66f85992-4ad0-4f05-9a20-54e8587900fa	f8c83ea0-4acd-4eda-bd24-3fb2b9473bc5	\N	\N	Twilio-SMS:SM366109b3a8db4a87a8a5f916a8c08936	0	\N	\N	\N	+16106006812
771dac47-7a8f-44f1-9d99-5cb4795c8ae5	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-30 05:19:59.150038+00	delivered	2022-03-30 05:20:08.095321+00	delivered	\N	2022-03-30 05:20:00.548354+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79680	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SM9cfb90535c9446ceb5a4be26057cfb2b	0	\N	\N	\N	+16106006812
2e228e5d-0e1d-462f-acdf-7bda57d2e2ae	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-30 05:17:54.902977+00	delivered	2022-03-30 05:18:05.347697+00	delivered	\N	2022-03-30 05:17:56.136478+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79680	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SMd8ddf0c5c3804ceeb400eacdf9324a46	0	\N	\N	\N	+16106006812
93c5934c-ff67-4464-a105-61a47e48b140	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-30 05:18:58.891283+00	delivered	2022-03-30 05:19:11.95525+00	delivered	\N	2022-03-30 05:19:00.172875+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79680	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SM7e3d2bb1d57f449ab942acf8ea1def3d	0	\N	\N	\N	+16106006812
0f872cb1-3a92-4cd3-ade7-3a644618833f	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-30 06:03:09.252484+00	delivered	2022-03-30 06:03:22.043125+00	delivered	\N	2022-03-30 06:03:10.665166+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79681	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SM7f4fe8031694403c904a800da799f3dd	0	\N	\N	\N	+16106006812
d03533d2-9c99-48bd-88f2-f4aecdb4836c	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-30 05:20:59.159746+00	delivered	2022-03-30 05:21:34.096302+00	delivered	\N	2022-03-30 05:21:05.862853+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79680	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SM013c153e7e214d9ba5826228c912deaf	0	\N	\N	\N	+16106006812
3551a9e7-34b6-4aa2-949e-b3aa260d2e41	alert_notification	be681185-17ba-4cfa-8759-c8c15fa5f693	2022-03-30 06:02:06.307609+00	delivered	2022-03-30 06:02:17.738835+00	delivered	\N	2022-03-30 06:02:07.658626+00	0	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	79681	\N	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	2942d789-a34c-44ab-be77-812eea9d4119	\N	\N	Twilio-SMS:SM47e35a310c934f01b94d7fa7349f983d	0	\N	\N	\N	+16106006812
\.


--
-- Data for Name: region_ids; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.region_ids (name, id) FROM stdin;
default	1
\.


--
-- Data for Name: rotation_participants; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rotation_participants (id, rotation_id, "position", user_id) FROM stdin;
1476a473-613c-427c-b686-97a3e5609850	3f28fd16-2ade-44ce-80d8-e93fcbd60851	0	eff381c9-461c-4d84-a061-a3c2ff2c2ce1
cb644c79-0f02-425e-a412-6994f7b5941c	e8f5884e-6267-452f-bb2e-5a5ea2c0a30f	0	eff381c9-461c-4d84-a061-a3c2ff2c2ce1
\.


--
-- Data for Name: rotation_state; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rotation_state (rotation_id, "position", rotation_participant_id, shift_start, id, version) FROM stdin;
3f28fd16-2ade-44ce-80d8-e93fcbd60851	0	1476a473-613c-427c-b686-97a3e5609850	2022-03-28 13:30:01.054428+00	12788	2
e8f5884e-6267-452f-bb2e-5a5ea2c0a30f	0	cb644c79-0f02-425e-a412-6994f7b5941c	2022-03-29 14:30:04.236784+00	12789	2
\.


--
-- Data for Name: rotations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rotations (id, name, description, type, start_time, shift_length, time_zone, last_processed, participant_count) FROM stdin;
3f28fd16-2ade-44ce-80d8-e93fcbd60851	sample_rotation	sample weekly roattion	weekly	2022-03-28 13:30:00+00	1	Asia/Kolkata	\N	1
e8f5884e-6267-452f-bb2e-5a5ea2c0a30f	test_rotatiom	test_rotation	daily	2022-03-29 14:30:00+00	1	Asia/Kolkata	\N	1
\.


--
-- Data for Name: schedule_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schedule_data (schedule_id, last_cleanup_at, data, id) FROM stdin;
\.


--
-- Data for Name: schedule_on_call_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schedule_on_call_users (schedule_id, start_time, end_time, user_id, id) FROM stdin;
339709ad-3de5-478b-b464-1434953ae641	2022-03-28 13:17:29.544316+00	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	1812
721b3f02-03a3-468b-b031-e0782afce47d	2022-03-28 13:24:14.543484+00	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	1813
cc3f6acd-4491-49f1-8703-0cfc7863b2a4	2022-03-29 14:19:24.240651+00	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	1814
\.


--
-- Data for Name: schedule_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schedule_rules (id, schedule_id, sunday, monday, tuesday, wednesday, thursday, friday, saturday, start_time, end_time, created_at, tgt_user_id, tgt_rotation_id, is_active) FROM stdin;
4bc6f909-04e6-481b-a96d-61ba978f09cb	339709ad-3de5-478b-b464-1434953ae641	t	t	t	t	t	t	t	00:00:00	00:00:00	2022-03-28 13:17:28.656673+00	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	f
02c2cc72-b3ff-4443-a933-9f8ba9040a53	721b3f02-03a3-468b-b031-e0782afce47d	t	t	t	t	t	t	t	00:00:00	00:00:00	2022-03-28 13:24:12.063888+00	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	f
0ffb2d53-3467-4088-8692-355aa03850d4	cc3f6acd-4491-49f1-8703-0cfc7863b2a4	t	t	t	t	t	t	t	00:00:00	00:00:00	2022-03-29 14:19:21.065262+00	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	f
\.


--
-- Data for Name: schedules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schedules (id, name, description, time_zone, last_processed) FROM stdin;
339709ad-3de5-478b-b464-1434953ae641	sampleschedule		Asia/Kolkata	\N
721b3f02-03a3-468b-b031-e0782afce47d	devops Primary Schedule	Generated by Setup Wizard	Asia/Kolkata	\N
cc3f6acd-4491-49f1-8703-0cfc7863b2a4	test_schedule		Asia/Kolkata	\N
\.


--
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.services (id, name, description, escalation_policy_id) FROM stdin;
bf3124c9-722e-42fb-9177-eff6a7008bf8	sample		48e321d3-e708-47e1-acf5-83d47964da42
66f85992-4ad0-4f05-9a20-54e8587900fa	devops Service	Generated by Setup Wizard	f8c83ea0-4acd-4eda-bd24-3fb2b9473bc5
68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	DevopsTeam - Webhook		2942d789-a34c-44ab-be77-812eea9d4119
\.


--
-- Data for Name: switchover_state; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.switchover_state (ok, current_state) FROM stdin;
t	idle
\.


--
-- Data for Name: twilio_sms_callbacks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.twilio_sms_callbacks (phone_number, callback_id, code, id, sent_at, alert_id, service_id) FROM stdin;
\.


--
-- Data for Name: twilio_sms_errors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.twilio_sms_errors (phone_number, error_message, outgoing, occurred_at, id) FROM stdin;
\.


--
-- Data for Name: twilio_voice_errors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.twilio_voice_errors (phone_number, error_message, outgoing, occurred_at, id) FROM stdin;
\.


--
-- Data for Name: user_calendar_subscriptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_calendar_subscriptions (id, name, user_id, last_access, last_update, created_at, disabled, schedule_id, config) FROM stdin;
\.


--
-- Data for Name: user_contact_methods; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_contact_methods (id, name, type, value, disabled, user_id, last_test_verify_at, metadata) FROM stdin;
f4c1f8ad-c4ee-4b9c-aa3d-803b8b4ac56c	Myriam	SMS	+17633524631	t	00000000-0000-0000-0000-000000000001	\N	\N
d102ec2d-e6da-498e-85f7-52a8976782e6	Isabelle	VOICE	+17633918312	t	00000000-0000-0000-0000-000000000001	\N	\N
f4638acf-0378-4a30-84c4-11457ef90649	Garrison	VOICE	+17633029175	t	00000000-0000-0000-0000-000000000001	\N	\N
4ea6c87e-718c-4f97-9213-5842133707d6	venu gopal	SMS	+919848087949	f	ea7e4b42-9594-4d69-9eb2-a64fece9ae31	2022-03-28 12:07:27.77032+00	{"CarrierV1": {"Name": "Bharti Airtel Ltd", "Type": "mobile", "UpdatedAt": "2022-03-28T12:07:32.014429Z", "MobileCountryCode": "404", "MobileNetworkCode": "49"}}
be681185-17ba-4cfa-8759-c8c15fa5f693	Gautham	SMS	+917330808801	f	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	2022-03-28 12:44:44.287093+00	{"CarrierV1": {"Name": "Bharti Airtel Ltd", "Type": "mobile", "UpdatedAt": "2022-03-28T12:44:46.945331Z", "MobileCountryCode": "404", "MobileNetworkCode": "49"}}
\.


--
-- Data for Name: user_favorites; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_favorites (user_id, tgt_service_id, id, tgt_rotation_id, tgt_schedule_id, tgt_escalation_policy_id, tgt_user_id) FROM stdin;
714cf91d-a7d8-40af-9f33-39215b871ca5	\N	20743	\N	\N	\N	ea7e4b42-9594-4d69-9eb2-a64fece9ae31
eff381c9-461c-4d84-a061-a3c2ff2c2ce1	bf3124c9-722e-42fb-9177-eff6a7008bf8	20745	\N	\N	\N	\N
eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	20750	\N	\N	\N	02f90772-f8b0-42de-a6e7-cdd267454a13
eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	20752	\N	\N	2942d789-a34c-44ab-be77-812eea9d4119	\N
00000000-0000-0000-0000-000000000001	\N	6	\N	\N	\N	\N
00000000-0000-0000-0000-000000000001	\N	8	\N	\N	\N	\N
714cf91d-a7d8-40af-9f33-39215b871ca5	\N	20744	\N	\N	\N	eff381c9-461c-4d84-a061-a3c2ff2c2ce1
eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	20746	\N	339709ad-3de5-478b-b464-1434953ae641	\N	\N
eff381c9-461c-4d84-a061-a3c2ff2c2ce1	68cb36e8-e45e-41c7-ac5a-87fe91e2fc09	20753	\N	\N	\N	\N
eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	20755	e8f5884e-6267-452f-bb2e-5a5ea2c0a30f	\N	\N	\N
eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	20747	3f28fd16-2ade-44ce-80d8-e93fcbd60851	\N	\N	\N
eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	20748	\N	721b3f02-03a3-468b-b031-e0782afce47d	\N	\N
eff381c9-461c-4d84-a061-a3c2ff2c2ce1	66f85992-4ad0-4f05-9a20-54e8587900fa	20749	\N	\N	\N	\N
eff381c9-461c-4d84-a061-a3c2ff2c2ce1	\N	20754	\N	cc3f6acd-4491-49f1-8703-0cfc7863b2a4	\N	\N
00000000-0000-0000-0000-000000000001	\N	20742	\N	\N	\N	714cf91d-a7d8-40af-9f33-39215b871ca5
\.


--
-- Data for Name: user_notification_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_notification_rules (id, delay_minutes, contact_method_id, user_id, created_at) FROM stdin;
613191a2-f4d9-4570-b534-ca1a3588658f	43	f4c1f8ad-c4ee-4b9c-aa3d-803b8b4ac56c	00000000-0000-0000-0000-000000000001	2022-03-22 10:15:19.115288+00
518d45d5-aeb2-42bb-b605-4840d603ca0c	23	d102ec2d-e6da-498e-85f7-52a8976782e6	00000000-0000-0000-0000-000000000001	2022-03-22 10:15:19.115288+00
b7479039-4ad1-450a-8173-9adbcdee99fe	19	f4638acf-0378-4a30-84c4-11457ef90649	00000000-0000-0000-0000-000000000001	2022-03-22 10:15:19.115288+00
7744054e-3e9f-4c3d-9c98-69fc8c3a459c	16	f4638acf-0378-4a30-84c4-11457ef90649	00000000-0000-0000-0000-000000000001	2022-03-22 10:15:19.115288+00
347cdb09-4d1a-4c03-9430-690d9187e671	1	f4638acf-0378-4a30-84c4-11457ef90649	00000000-0000-0000-0000-000000000001	2022-03-22 10:15:19.115288+00
e44ab64e-80d9-4228-9e96-9c1e9e6d1a2b	48	f4638acf-0378-4a30-84c4-11457ef90649	00000000-0000-0000-0000-000000000001	2022-03-22 10:15:19.115288+00
59178148-9c5c-4d96-9651-669a178d51da	40	f4c1f8ad-c4ee-4b9c-aa3d-803b8b4ac56c	00000000-0000-0000-0000-000000000001	2022-03-22 10:15:19.115288+00
0c408030-0d9c-4440-82c6-7caee80a155d	35	d102ec2d-e6da-498e-85f7-52a8976782e6	00000000-0000-0000-0000-000000000001	2022-03-22 10:15:19.115288+00
7723dbed-a6e3-4bed-bc39-04356d321d89	28	d102ec2d-e6da-498e-85f7-52a8976782e6	00000000-0000-0000-0000-000000000001	2022-03-22 10:15:19.115288+00
cf9360eb-7108-470d-8b5d-c8ff34e5293a	0	4ea6c87e-718c-4f97-9213-5842133707d6	ea7e4b42-9594-4d69-9eb2-a64fece9ae31	2022-03-28 12:07:27.253595+00
c8ba5eed-e1b8-406b-aaaa-e481f7bcb497	0	be681185-17ba-4cfa-8759-c8c15fa5f693	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	2022-03-28 12:44:43.738045+00
21d6a5ee-2099-4d98-b0df-ea9dec2267f0	5	be681185-17ba-4cfa-8759-c8c15fa5f693	eff381c9-461c-4d84-a061-a3c2ff2c2ce1	2022-03-28 13:16:21.537629+00
\.


--
-- Data for Name: user_overrides; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_overrides (id, start_time, end_time, add_user_id, remove_user_id, tgt_schedule_id) FROM stdin;
\.


--
-- Data for Name: user_slack_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_slack_data (id, access_token) FROM stdin;
\.


--
-- Data for Name: user_verification_codes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_verification_codes (id, code, expires_at, contact_method_id, sent) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, bio, email, role, name, avatar_url, alert_status_log_contact_method_id) FROM stdin;
02f90772-f8b0-42de-a6e7-cdd267454a13			user	Kalyan		\N
ea7e4b42-9594-4d69-9eb2-a64fece9ae31		venugopal.thammala@scriptbees.com	admin	Venu Gopal		4ea6c87e-718c-4f97-9213-5842133707d6
eff381c9-461c-4d84-a061-a3c2ff2c2ce1		gautham.anne@scriptbees.com	admin	Gautham		be681185-17ba-4cfa-8759-c8c15fa5f693
00000000-0000-0000-0000-000000000001		admin@example.com	admin	Admin McAdminFace		\N
714cf91d-a7d8-40af-9f33-39215b871ca5			admin	Scriptbees-Admin		\N
\.


--
-- Name: alert_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.alert_logs_id_seq', 92, true);


--
-- Name: alert_metrics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.alert_metrics_id_seq', 76914, true);


--
-- Name: alert_status_subscriptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.alert_status_subscriptions_id_seq', 9, true);


--
-- Name: alerts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.alerts_id_seq', 79681, true);


--
-- Name: auth_basic_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_basic_users_id_seq', 6, true);


--
-- Name: auth_subjects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_subjects_id_seq', 6, true);


--
-- Name: config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.config_id_seq', 11, true);


--
-- Name: ep_step_on_call_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ep_step_on_call_users_id_seq', 13965814, true);


--
-- Name: escalation_policy_state_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.escalation_policy_state_id_seq', 2272, true);


--
-- Name: incident_number_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.incident_number_seq', 1, false);


--
-- Name: labels_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.labels_id_seq', 763, true);


--
-- Name: region_ids_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.region_ids_id_seq', 1, true);


--
-- Name: rotation_state_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.rotation_state_id_seq', 12789, true);


--
-- Name: schedule_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.schedule_data_id_seq', 1, false);


--
-- Name: schedule_on_call_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.schedule_on_call_users_id_seq', 1814, true);


--
-- Name: twilio_sms_callbacks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.twilio_sms_callbacks_id_seq', 1, false);


--
-- Name: twilio_sms_errors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.twilio_sms_errors_id_seq', 1, false);


--
-- Name: twilio_voice_errors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.twilio_voice_errors_id_seq', 1, false);


--
-- Name: user_favorites_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_favorites_id_seq', 20755, true);


--
-- Name: alert_logs alert_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_logs
    ADD CONSTRAINT alert_logs_pkey PRIMARY KEY (id);


--
-- Name: alert_metrics alert_metrics_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_metrics
    ADD CONSTRAINT alert_metrics_id_key UNIQUE (id);


--
-- Name: alert_metrics alert_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_metrics
    ADD CONSTRAINT alert_metrics_pkey PRIMARY KEY (alert_id);


--
-- Name: alert_status_subscriptions alert_status_subscriptions_channel_id_contact_method_id_ale_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_status_subscriptions
    ADD CONSTRAINT alert_status_subscriptions_channel_id_contact_method_id_ale_key UNIQUE (channel_id, contact_method_id, alert_id);


--
-- Name: alert_status_subscriptions alert_status_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_status_subscriptions
    ADD CONSTRAINT alert_status_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: auth_basic_users auth_basic_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_basic_users
    ADD CONSTRAINT auth_basic_users_pkey PRIMARY KEY (user_id);


--
-- Name: auth_basic_users auth_basic_users_uniq_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_basic_users
    ADD CONSTRAINT auth_basic_users_uniq_id UNIQUE (id);


--
-- Name: auth_basic_users auth_basic_users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_basic_users
    ADD CONSTRAINT auth_basic_users_username_key UNIQUE (username);


--
-- Name: auth_nonce auth_nonce_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_nonce
    ADD CONSTRAINT auth_nonce_pkey PRIMARY KEY (id);


--
-- Name: auth_subjects auth_subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_subjects
    ADD CONSTRAINT auth_subjects_pkey PRIMARY KEY (provider_id, subject_id);


--
-- Name: auth_subjects auth_subjects_uniq_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_subjects
    ADD CONSTRAINT auth_subjects_uniq_id UNIQUE (id);


--
-- Name: auth_user_sessions auth_user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_sessions
    ADD CONSTRAINT auth_user_sessions_pkey PRIMARY KEY (id);


--
-- Name: config_limits config_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.config_limits
    ADD CONSTRAINT config_limits_pkey PRIMARY KEY (id);


--
-- Name: config config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.config
    ADD CONSTRAINT config_pkey PRIMARY KEY (id);


--
-- Name: engine_processing_versions engine_processing_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.engine_processing_versions
    ADD CONSTRAINT engine_processing_versions_pkey PRIMARY KEY (type_id);


--
-- Name: ep_step_on_call_users ep_step_on_call_users_uniq_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ep_step_on_call_users
    ADD CONSTRAINT ep_step_on_call_users_uniq_id UNIQUE (id);


--
-- Name: escalation_policy_actions epa_no_duplicate_channels; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT epa_no_duplicate_channels UNIQUE (escalation_policy_step_id, channel_id);


--
-- Name: escalation_policy_actions epa_no_duplicate_rotations; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT epa_no_duplicate_rotations UNIQUE (escalation_policy_step_id, rotation_id);


--
-- Name: escalation_policy_actions epa_no_duplicate_schedules; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT epa_no_duplicate_schedules UNIQUE (escalation_policy_step_id, schedule_id);


--
-- Name: escalation_policy_actions epa_no_duplicate_users; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT epa_no_duplicate_users UNIQUE (escalation_policy_step_id, user_id);


--
-- Name: escalation_policies escalation_policies_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policies
    ADD CONSTRAINT escalation_policies_name_key UNIQUE (name);


--
-- Name: escalation_policies escalation_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policies
    ADD CONSTRAINT escalation_policies_pkey PRIMARY KEY (id);


--
-- Name: escalation_policy_actions escalation_policy_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT escalation_policy_actions_pkey PRIMARY KEY (id);


--
-- Name: escalation_policy_state escalation_policy_state_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_state
    ADD CONSTRAINT escalation_policy_state_pkey PRIMARY KEY (alert_id);


--
-- Name: escalation_policy_state escalation_policy_state_uniq_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_state
    ADD CONSTRAINT escalation_policy_state_uniq_id UNIQUE (id);


--
-- Name: escalation_policy_steps escalation_policy_steps_escalation_policy_id_step_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_steps
    ADD CONSTRAINT escalation_policy_steps_escalation_policy_id_step_number_key UNIQUE (escalation_policy_id, step_number) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: escalation_policy_steps escalation_policy_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_steps
    ADD CONSTRAINT escalation_policy_steps_pkey PRIMARY KEY (id);


--
-- Name: users goalert_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT goalert_user_pkey PRIMARY KEY (id);


--
-- Name: gorp_migrations gorp_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gorp_migrations
    ADD CONSTRAINT gorp_migrations_pkey PRIMARY KEY (id);


--
-- Name: heartbeat_monitors heartbeat_monitors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.heartbeat_monitors
    ADD CONSTRAINT heartbeat_monitors_pkey PRIMARY KEY (id);


--
-- Name: integration_keys integration_keys_name_service_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integration_keys
    ADD CONSTRAINT integration_keys_name_service_id_key UNIQUE (name, service_id);


--
-- Name: integration_keys integration_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integration_keys
    ADD CONSTRAINT integration_keys_pkey PRIMARY KEY (id);


--
-- Name: keyring keyring_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.keyring
    ADD CONSTRAINT keyring_pkey PRIMARY KEY (id);


--
-- Name: labels labels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.labels
    ADD CONSTRAINT labels_pkey PRIMARY KEY (id);


--
-- Name: labels labels_tgt_service_id_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.labels
    ADD CONSTRAINT labels_tgt_service_id_key_key UNIQUE (tgt_service_id, key);


--
-- Name: notification_channels notification_channels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_channels
    ADD CONSTRAINT notification_channels_pkey PRIMARY KEY (id);


--
-- Name: notification_policy_cycles notification_policy_cycles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_policy_cycles
    ADD CONSTRAINT notification_policy_cycles_pkey PRIMARY KEY (id);


--
-- Name: outgoing_messages outgoing_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_pkey PRIMARY KEY (id);


--
-- Name: region_ids region_ids_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.region_ids
    ADD CONSTRAINT region_ids_id_key UNIQUE (id);


--
-- Name: region_ids region_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.region_ids
    ADD CONSTRAINT region_ids_pkey PRIMARY KEY (name);


--
-- Name: rotation_participants rotation_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rotation_participants
    ADD CONSTRAINT rotation_participants_pkey PRIMARY KEY (id);


--
-- Name: rotation_participants rotation_participants_rotation_id_position_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rotation_participants
    ADD CONSTRAINT rotation_participants_rotation_id_position_key UNIQUE (rotation_id, "position") DEFERRABLE INITIALLY DEFERRED;


--
-- Name: rotation_state rotation_state_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rotation_state
    ADD CONSTRAINT rotation_state_pkey PRIMARY KEY (rotation_id);


--
-- Name: rotation_state rotation_state_uniq_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rotation_state
    ADD CONSTRAINT rotation_state_uniq_id UNIQUE (id);


--
-- Name: rotations rotations_name_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rotations
    ADD CONSTRAINT rotations_name_unique UNIQUE (name);


--
-- Name: rotations rotations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rotations
    ADD CONSTRAINT rotations_pkey PRIMARY KEY (id);


--
-- Name: schedule_data schedule_data_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_data
    ADD CONSTRAINT schedule_data_id_key UNIQUE (id);


--
-- Name: schedule_data schedule_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_data
    ADD CONSTRAINT schedule_data_pkey PRIMARY KEY (schedule_id);


--
-- Name: schedule_on_call_users schedule_on_call_users_uniq_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_on_call_users
    ADD CONSTRAINT schedule_on_call_users_uniq_id UNIQUE (id);


--
-- Name: schedule_rules schedule_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_rules
    ADD CONSTRAINT schedule_rules_pkey PRIMARY KEY (id);


--
-- Name: schedules schedules_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedules
    ADD CONSTRAINT schedules_name_key UNIQUE (name);


--
-- Name: schedules schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedules
    ADD CONSTRAINT schedules_pkey PRIMARY KEY (id);


--
-- Name: services services_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_name_key UNIQUE (name);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: services svc_ep_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT svc_ep_uniq UNIQUE (id, escalation_policy_id);


--
-- Name: switchover_state switchover_state_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.switchover_state
    ADD CONSTRAINT switchover_state_pkey PRIMARY KEY (ok);


--
-- Name: twilio_sms_callbacks twilio_sms_callbacks_uniq_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.twilio_sms_callbacks
    ADD CONSTRAINT twilio_sms_callbacks_uniq_id UNIQUE (id);


--
-- Name: twilio_sms_errors twilio_sms_errors_uniq_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.twilio_sms_errors
    ADD CONSTRAINT twilio_sms_errors_uniq_id UNIQUE (id);


--
-- Name: twilio_voice_errors twilio_voice_errors_uniq_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.twilio_voice_errors
    ADD CONSTRAINT twilio_voice_errors_uniq_id UNIQUE (id);


--
-- Name: user_calendar_subscriptions user_calendar_subscriptions_name_schedule_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_calendar_subscriptions
    ADD CONSTRAINT user_calendar_subscriptions_name_schedule_id_user_id_key UNIQUE (name, schedule_id, user_id);


--
-- Name: user_calendar_subscriptions user_calendar_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_calendar_subscriptions
    ADD CONSTRAINT user_calendar_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: user_contact_methods user_contact_methods_name_type_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_contact_methods
    ADD CONSTRAINT user_contact_methods_name_type_user_id_key UNIQUE (name, type, user_id);


--
-- Name: user_contact_methods user_contact_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_contact_methods
    ADD CONSTRAINT user_contact_methods_pkey PRIMARY KEY (id);


--
-- Name: user_contact_methods user_contact_methods_type_value_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_contact_methods
    ADD CONSTRAINT user_contact_methods_type_value_key UNIQUE (type, value);


--
-- Name: user_favorites user_favorites_uniq_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_uniq_id UNIQUE (id);


--
-- Name: user_favorites user_favorites_user_id_tgt_escalation_policy_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_user_id_tgt_escalation_policy_id_key UNIQUE (user_id, tgt_escalation_policy_id);


--
-- Name: user_favorites user_favorites_user_id_tgt_rotation_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_user_id_tgt_rotation_id_key UNIQUE (user_id, tgt_rotation_id);


--
-- Name: user_favorites user_favorites_user_id_tgt_schedule_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_user_id_tgt_schedule_id_key UNIQUE (user_id, tgt_schedule_id);


--
-- Name: user_favorites user_favorites_user_id_tgt_service_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_user_id_tgt_service_id_key UNIQUE (user_id, tgt_service_id);


--
-- Name: user_favorites user_favorites_user_id_tgt_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_user_id_tgt_user_id_key UNIQUE (user_id, tgt_user_id);


--
-- Name: user_notification_rules user_notification_rules_contact_method_id_delay_minutes_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_notification_rules
    ADD CONSTRAINT user_notification_rules_contact_method_id_delay_minutes_key UNIQUE (contact_method_id, delay_minutes);


--
-- Name: user_notification_rules user_notification_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_notification_rules
    ADD CONSTRAINT user_notification_rules_pkey PRIMARY KEY (id);


--
-- Name: user_overrides user_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_overrides
    ADD CONSTRAINT user_overrides_pkey PRIMARY KEY (id);


--
-- Name: user_slack_data user_slack_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_slack_data
    ADD CONSTRAINT user_slack_data_pkey PRIMARY KEY (id);


--
-- Name: user_verification_codes user_verification_codes_contact_method_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_verification_codes
    ADD CONSTRAINT user_verification_codes_contact_method_id_key UNIQUE (contact_method_id);


--
-- Name: user_verification_codes user_verification_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_verification_codes
    ADD CONSTRAINT user_verification_codes_pkey PRIMARY KEY (id);


--
-- Name: escalation_policies_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX escalation_policies_name ON public.escalation_policies USING btree (lower(name));


--
-- Name: escalation_policy_state_next_escalation_force_escalation_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX escalation_policy_state_next_escalation_force_escalation_idx ON public.escalation_policy_state USING btree (next_escalation, force_escalation);


--
-- Name: heartbeat_monitor_name_service_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX heartbeat_monitor_name_service_id ON public.heartbeat_monitors USING btree (lower(name), service_id);


--
-- Name: idx_alert_cleanup; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alert_cleanup ON public.alerts USING btree (id, created_at) WHERE (status = 'closed'::public.enum_alert_status);


--
-- Name: idx_alert_logs_alert_event; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alert_logs_alert_event ON public.alert_logs USING btree (alert_id, event);


--
-- Name: idx_alert_logs_alert_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alert_logs_alert_id ON public.alert_logs USING btree (alert_id);


--
-- Name: idx_alert_logs_channel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alert_logs_channel_id ON public.alert_logs USING btree (sub_channel_id);


--
-- Name: idx_alert_logs_hb_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alert_logs_hb_id ON public.alert_logs USING btree (sub_hb_monitor_id);


--
-- Name: idx_alert_logs_int_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alert_logs_int_id ON public.alert_logs USING btree (sub_integration_key_id);


--
-- Name: idx_alert_logs_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alert_logs_user_id ON public.alert_logs USING btree (sub_user_id);


--
-- Name: idx_alert_service_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alert_service_id ON public.alerts USING btree (service_id);


--
-- Name: idx_closed_events; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_closed_events ON public.alert_logs USING btree ("timestamp") WHERE (event = 'closed'::public.enum_alert_log_event);


--
-- Name: idx_contact_method_users; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_contact_method_users ON public.user_contact_methods USING btree (user_id);


--
-- Name: idx_dedup_alerts; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dedup_alerts ON public.alerts USING btree (dedup_key);


--
-- Name: idx_ep_action_steps; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ep_action_steps ON public.escalation_policy_actions USING btree (escalation_policy_step_id);


--
-- Name: idx_ep_step_on_call; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_ep_step_on_call ON public.ep_step_on_call_users USING btree (user_id, ep_step_id) WHERE (end_time IS NULL);


--
-- Name: idx_ep_step_policies; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ep_step_policies ON public.escalation_policy_steps USING btree (escalation_policy_id);


--
-- Name: idx_escalation_policy_state_policy_ids; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_escalation_policy_state_policy_ids ON public.escalation_policy_state USING btree (escalation_policy_id, service_id);


--
-- Name: idx_heartbeat_monitor_service; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_heartbeat_monitor_service ON public.heartbeat_monitors USING btree (service_id);


--
-- Name: idx_integration_key_service; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_integration_key_service ON public.integration_keys USING btree (service_id);


--
-- Name: idx_labels_service_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_labels_service_id ON public.labels USING btree (tgt_service_id);


--
-- Name: idx_no_alert_duplicates; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_no_alert_duplicates ON public.alerts USING btree (service_id, dedup_key);


--
-- Name: idx_notif_rule_creation_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notif_rule_creation_time ON public.user_notification_rules USING btree (user_id, created_at);


--
-- Name: idx_notification_rule_users; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notification_rule_users ON public.user_notification_rules USING btree (user_id);


--
-- Name: idx_np_cycle_alert_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_np_cycle_alert_id ON public.notification_policy_cycles USING btree (alert_id);


--
-- Name: idx_om_alert_log_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_om_alert_log_id ON public.outgoing_messages USING btree (alert_log_id);


--
-- Name: idx_om_alert_sent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_om_alert_sent ON public.outgoing_messages USING btree (alert_id, sent_at);


--
-- Name: idx_om_cm_sent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_om_cm_sent ON public.outgoing_messages USING btree (contact_method_id, sent_at);


--
-- Name: idx_om_ep_sent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_om_ep_sent ON public.outgoing_messages USING btree (escalation_policy_id, sent_at);


--
-- Name: idx_om_last_status_sent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_om_last_status_sent ON public.outgoing_messages USING btree (last_status, sent_at);


--
-- Name: idx_om_service_sent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_om_service_sent ON public.outgoing_messages USING btree (service_id, sent_at);


--
-- Name: idx_om_user_sent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_om_user_sent ON public.outgoing_messages USING btree (user_id, sent_at);


--
-- Name: idx_om_vcode_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_om_vcode_id ON public.outgoing_messages USING btree (user_verification_code_id);


--
-- Name: idx_outgoing_messages_notif_cycle; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_outgoing_messages_notif_cycle ON public.outgoing_messages USING btree (cycle_id);


--
-- Name: idx_outgoing_messages_provider_msg_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_outgoing_messages_provider_msg_id ON public.outgoing_messages USING btree (provider_msg_id);


--
-- Name: idx_participant_rotation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_participant_rotation ON public.rotation_participants USING btree (rotation_id);


--
-- Name: idx_rule_schedule; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_rule_schedule ON public.schedule_rules USING btree (schedule_id);


--
-- Name: idx_sched_oncall_times; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sched_oncall_times ON public.schedule_on_call_users USING spgist (tstzrange(start_time, end_time));


--
-- Name: idx_schedule_on_call_once; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_schedule_on_call_once ON public.schedule_on_call_users USING btree (schedule_id, user_id) WHERE (end_time IS NULL);


--
-- Name: idx_search_alerts_summary_eng; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_search_alerts_summary_eng ON public.alerts USING gin (to_tsvector('english'::regconfig, replace(lower(summary), '.'::text, ' '::text)));


--
-- Name: idx_search_escalation_policies_desc_eng; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_search_escalation_policies_desc_eng ON public.escalation_policies USING gin (to_tsvector('english'::regconfig, replace(lower(description), '.'::text, ' '::text)));


--
-- Name: idx_search_escalation_policies_name_eng; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_search_escalation_policies_name_eng ON public.escalation_policies USING gin (to_tsvector('english'::regconfig, replace(lower(name), '.'::text, ' '::text)));


--
-- Name: idx_search_rotations_desc_eng; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_search_rotations_desc_eng ON public.rotations USING gin (to_tsvector('english'::regconfig, replace(lower(description), '.'::text, ' '::text)));


--
-- Name: idx_search_rotations_name_eng; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_search_rotations_name_eng ON public.rotations USING gin (to_tsvector('english'::regconfig, replace(lower(name), '.'::text, ' '::text)));


--
-- Name: idx_search_schedules_desc_eng; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_search_schedules_desc_eng ON public.schedules USING gin (to_tsvector('english'::regconfig, replace(lower(description), '.'::text, ' '::text)));


--
-- Name: idx_search_schedules_name_eng; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_search_schedules_name_eng ON public.schedules USING gin (to_tsvector('english'::regconfig, replace(lower(name), '.'::text, ' '::text)));


--
-- Name: idx_search_services_desc_eng; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_search_services_desc_eng ON public.services USING gin (to_tsvector('english'::regconfig, replace(lower(description), '.'::text, ' '::text)));


--
-- Name: idx_search_services_name_eng; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_search_services_name_eng ON public.services USING gin (to_tsvector('english'::regconfig, replace(lower(name), '.'::text, ' '::text)));


--
-- Name: idx_search_users_name_eng; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_search_users_name_eng ON public.users USING gin (to_tsvector('english'::regconfig, replace(lower(name), '.'::text, ' '::text)));


--
-- Name: idx_target_schedule; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_target_schedule ON public.schedule_rules USING btree (schedule_id, tgt_rotation_id, tgt_user_id);


--
-- Name: idx_twilio_sms_alert_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_twilio_sms_alert_id ON public.twilio_sms_callbacks USING btree (alert_id);


--
-- Name: idx_twilio_sms_codes; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_twilio_sms_codes ON public.twilio_sms_callbacks USING btree (phone_number, code);


--
-- Name: idx_twilio_sms_service_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_twilio_sms_service_id ON public.twilio_sms_callbacks USING btree (service_id);


--
-- Name: idx_unacked_alert_service; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_unacked_alert_service ON public.alerts USING btree (status, service_id);


--
-- Name: idx_user_overrides_schedule; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_overrides_schedule ON public.user_overrides USING btree (tgt_schedule_id, end_time);


--
-- Name: idx_user_status_updates; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_status_updates ON public.users USING btree (alert_status_log_contact_method_id) WHERE (alert_status_log_contact_method_id IS NOT NULL);


--
-- Name: idx_valid_contact_methods; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_valid_contact_methods ON public.user_contact_methods USING btree (id) WHERE (NOT disabled);


--
-- Name: integration_keys_name_service_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX integration_keys_name_service_id ON public.integration_keys USING btree (lower(name), service_id);


--
-- Name: om_cm_time_test_verify_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX om_cm_time_test_verify_idx ON public.outgoing_messages USING btree (contact_method_id, created_at) WHERE (message_type = ANY (ARRAY['test_notification'::public.enum_outgoing_messages_type, 'verification_message'::public.enum_outgoing_messages_type]));


--
-- Name: rotations_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX rotations_name ON public.rotations USING btree (lower(name));


--
-- Name: schedules_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX schedules_name ON public.schedules USING btree (lower(name));


--
-- Name: services_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX services_name ON public.services USING btree (lower(name));


--
-- Name: twilio_sms_errors_phone_number_outgoing_occurred_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX twilio_sms_errors_phone_number_outgoing_occurred_at_idx ON public.twilio_sms_errors USING btree (phone_number, outgoing, occurred_at);


--
-- Name: twilio_voice_errors_phone_number_outgoing_occurred_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX twilio_voice_errors_phone_number_outgoing_occurred_at_idx ON public.twilio_voice_errors USING btree (phone_number, outgoing, occurred_at);


--
-- Name: alerts trg_10_clear_ep_state_on_alert_close; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_10_clear_ep_state_on_alert_close AFTER UPDATE ON public.alerts FOR EACH ROW WHEN (((old.status <> new.status) AND (new.status = 'closed'::public.enum_alert_status))) EXECUTE FUNCTION public.fn_clear_ep_state_on_alert_close();


--
-- Name: services trg_10_clear_ep_state_on_svc_ep_change; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_10_clear_ep_state_on_svc_ep_change AFTER UPDATE ON public.services FOR EACH ROW WHEN ((old.escalation_policy_id <> new.escalation_policy_id)) EXECUTE FUNCTION public.fn_clear_ep_state_on_svc_ep_change();


--
-- Name: escalation_policy_steps trg_10_decr_ep_step_count_on_del; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_10_decr_ep_step_count_on_del BEFORE DELETE ON public.escalation_policy_steps FOR EACH ROW EXECUTE FUNCTION public.fn_decr_ep_step_count_on_del();


--
-- Name: rotation_participants trg_10_decr_part_count_on_del; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_10_decr_part_count_on_del BEFORE DELETE ON public.rotation_participants FOR EACH ROW EXECUTE FUNCTION public.fn_decr_part_count_on_del();


--
-- Name: escalation_policy_steps trg_10_incr_ep_step_count_on_add; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_10_incr_ep_step_count_on_add BEFORE INSERT ON public.escalation_policy_steps FOR EACH ROW EXECUTE FUNCTION public.fn_incr_ep_step_count_on_add();


--
-- Name: alerts trg_10_insert_ep_state_on_alert_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_10_insert_ep_state_on_alert_insert AFTER INSERT ON public.alerts FOR EACH ROW WHEN ((new.status <> 'closed'::public.enum_alert_status)) EXECUTE FUNCTION public.fn_insert_ep_state_on_alert_insert();


--
-- Name: escalation_policy_steps trg_10_insert_ep_state_on_step_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_10_insert_ep_state_on_step_insert AFTER INSERT ON public.escalation_policy_steps FOR EACH ROW WHEN ((new.step_number = 0)) EXECUTE FUNCTION public.fn_insert_ep_state_on_step_insert();


--
-- Name: escalation_policy_state trg_10_set_ep_state_svc_id_on_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_10_set_ep_state_svc_id_on_insert BEFORE INSERT ON public.escalation_policy_state FOR EACH ROW WHEN ((new.service_id IS NULL)) EXECUTE FUNCTION public.fn_set_ep_state_svc_id_on_insert();


--
-- Name: alerts trg_20_clear_next_esc_on_alert_ack; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_20_clear_next_esc_on_alert_ack AFTER UPDATE ON public.alerts FOR EACH ROW WHEN (((new.status <> old.status) AND (old.status = 'active'::public.enum_alert_status))) EXECUTE FUNCTION public.fn_clear_next_esc_on_alert_ack();


--
-- Name: rotation_participants trg_20_decr_rot_part_position_on_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_20_decr_rot_part_position_on_delete AFTER DELETE ON public.rotation_participants FOR EACH ROW EXECUTE FUNCTION public.fn_decr_rot_part_position_on_delete();


--
-- Name: escalation_policy_state trg_20_lock_svc_on_force_escalation; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_20_lock_svc_on_force_escalation BEFORE UPDATE ON public.escalation_policy_state FOR EACH ROW WHEN (((new.force_escalation <> old.force_escalation) AND new.force_escalation)) EXECUTE FUNCTION public.fn_lock_svc_on_force_escalation();


--
-- Name: rotation_participants trg_30_advance_or_end_rot_on_part_del; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_30_advance_or_end_rot_on_part_del BEFORE DELETE ON public.rotation_participants FOR EACH ROW EXECUTE FUNCTION public.fn_advance_or_end_rot_on_part_del();


--
-- Name: escalation_policy_state trg_30_trig_alert_on_force_escalation; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_30_trig_alert_on_force_escalation AFTER UPDATE ON public.escalation_policy_state FOR EACH ROW WHEN (((new.force_escalation <> old.force_escalation) AND new.force_escalation)) EXECUTE FUNCTION public.fn_trig_alert_on_force_escalation();


--
-- Name: alerts trg_clear_dedup_on_close; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_clear_dedup_on_close BEFORE UPDATE ON public.alerts FOR EACH ROW WHEN (((new.status <> old.status) AND (new.status = 'closed'::public.enum_alert_status))) EXECUTE FUNCTION public.fn_clear_dedup_on_close();


--
-- Name: config trg_config_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_config_update AFTER INSERT ON public.config FOR EACH ROW EXECUTE FUNCTION public.fn_notify_config_refresh();


--
-- Name: escalation_policy_steps trg_decr_ep_step_number_on_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_decr_ep_step_number_on_delete AFTER DELETE ON public.escalation_policy_steps FOR EACH ROW EXECUTE FUNCTION public.fn_decr_ep_step_number_on_delete();


--
-- Name: alerts trg_enforce_alert_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_enforce_alert_limit AFTER INSERT ON public.alerts NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_alert_limit();


--
-- Name: user_calendar_subscriptions trg_enforce_calendar_subscriptions_per_user_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_enforce_calendar_subscriptions_per_user_limit AFTER INSERT ON public.user_calendar_subscriptions NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_calendar_subscriptions_per_user_limit();


--
-- Name: user_contact_methods trg_enforce_contact_method_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_enforce_contact_method_limit AFTER INSERT ON public.user_contact_methods NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_contact_method_limit();


--
-- Name: escalation_policy_actions trg_enforce_ep_step_action_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_enforce_ep_step_action_limit AFTER INSERT ON public.escalation_policy_actions NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_ep_step_action_limit();


--
-- Name: escalation_policy_steps trg_enforce_ep_step_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_enforce_ep_step_limit AFTER INSERT ON public.escalation_policy_steps NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_ep_step_limit();


--
-- Name: heartbeat_monitors trg_enforce_heartbeat_monitor_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_enforce_heartbeat_monitor_limit AFTER INSERT ON public.heartbeat_monitors NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_heartbeat_limit();


--
-- Name: integration_keys trg_enforce_integration_key_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_enforce_integration_key_limit AFTER INSERT ON public.integration_keys NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_integration_key_limit();


--
-- Name: user_notification_rules trg_enforce_notification_rule_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_enforce_notification_rule_limit AFTER INSERT ON public.user_notification_rules NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_notification_rule_limit();


--
-- Name: rotation_participants trg_enforce_rot_part_position_no_gaps; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_enforce_rot_part_position_no_gaps AFTER UPDATE ON public.rotation_participants DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_rot_part_position_no_gaps();


--
-- Name: rotation_participants trg_enforce_rotation_participant_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_enforce_rotation_participant_limit AFTER INSERT ON public.rotation_participants NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_rotation_participant_limit();


--
-- Name: schedule_rules trg_enforce_schedule_rule_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_enforce_schedule_rule_limit AFTER INSERT ON public.schedule_rules NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_schedule_rule_limit();


--
-- Name: schedule_rules trg_enforce_schedule_target_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_enforce_schedule_target_limit AFTER INSERT ON public.schedule_rules NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_schedule_target_limit();


--
-- Name: users trg_enforce_status_update_same_user; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_enforce_status_update_same_user BEFORE INSERT OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_status_update_same_user();


--
-- Name: user_overrides trg_enforce_user_overide_no_conflict; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_enforce_user_overide_no_conflict AFTER INSERT OR UPDATE ON public.user_overrides NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_user_overide_no_conflict();


--
-- Name: user_overrides trg_enforce_user_override_schedule_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_enforce_user_override_schedule_limit AFTER INSERT ON public.user_overrides NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_user_override_schedule_limit();


--
-- Name: escalation_policy_steps trg_ep_step_number_no_gaps; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER trg_ep_step_number_no_gaps AFTER UPDATE ON public.escalation_policy_steps DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_ep_step_number_no_gaps();


--
-- Name: escalation_policy_steps trg_inc_ep_step_number_on_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_inc_ep_step_number_on_insert BEFORE INSERT ON public.escalation_policy_steps FOR EACH ROW EXECUTE FUNCTION public.fn_inc_ep_step_number_on_insert();


--
-- Name: rotation_participants trg_inc_rot_part_position_on_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_inc_rot_part_position_on_insert BEFORE INSERT ON public.rotation_participants FOR EACH ROW EXECUTE FUNCTION public.fn_inc_rot_part_position_on_insert();


--
-- Name: rotation_participants trg_incr_part_count_on_add; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_incr_part_count_on_add BEFORE INSERT ON public.rotation_participants FOR EACH ROW EXECUTE FUNCTION public.fn_incr_part_count_on_add();


--
-- Name: auth_basic_users trg_insert_basic_user; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_insert_basic_user AFTER INSERT ON public.auth_basic_users FOR EACH ROW EXECUTE FUNCTION public.fn_insert_basic_user();


--
-- Name: user_notification_rules trg_notification_rule_same_user; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_notification_rule_same_user BEFORE INSERT OR UPDATE ON public.user_notification_rules FOR EACH ROW EXECUTE FUNCTION public.fn_notification_rule_same_user();


--
-- Name: alerts trg_prevent_reopen; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_prevent_reopen BEFORE UPDATE OF status ON public.alerts FOR EACH ROW EXECUTE FUNCTION public.fn_prevent_reopen();


--
-- Name: rotation_state trg_set_rot_state_pos_on_active_change; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_set_rot_state_pos_on_active_change BEFORE UPDATE ON public.rotation_state FOR EACH ROW WHEN ((new.rotation_participant_id <> old.rotation_participant_id)) EXECUTE FUNCTION public.fn_set_rot_state_pos_on_active_change();


--
-- Name: rotation_participants trg_set_rot_state_pos_on_part_reorder; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_set_rot_state_pos_on_part_reorder BEFORE UPDATE ON public.rotation_participants FOR EACH ROW WHEN ((new."position" <> old."position")) EXECUTE FUNCTION public.fn_set_rot_state_pos_on_part_reorder();


--
-- Name: rotation_participants trg_start_rotation_on_first_part_add; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_start_rotation_on_first_part_add AFTER INSERT ON public.rotation_participants FOR EACH ROW EXECUTE FUNCTION public.fn_start_rotation_on_first_part_add();


--
-- Name: alert_metrics alert_metrics_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_metrics
    ADD CONSTRAINT alert_metrics_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- Name: alert_status_subscriptions alert_status_subscriptions_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_status_subscriptions
    ADD CONSTRAINT alert_status_subscriptions_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- Name: alert_status_subscriptions alert_status_subscriptions_channel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_status_subscriptions
    ADD CONSTRAINT alert_status_subscriptions_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES public.notification_channels(id) ON DELETE CASCADE;


--
-- Name: alert_status_subscriptions alert_status_subscriptions_contact_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_status_subscriptions
    ADD CONSTRAINT alert_status_subscriptions_contact_method_id_fkey FOREIGN KEY (contact_method_id) REFERENCES public.user_contact_methods(id) ON DELETE CASCADE;


--
-- Name: alerts alerts_services_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_services_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: auth_basic_users auth_basic_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_basic_users
    ADD CONSTRAINT auth_basic_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: auth_subjects auth_subjects_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_subjects
    ADD CONSTRAINT auth_subjects_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: auth_user_sessions auth_user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auth_user_sessions
    ADD CONSTRAINT auth_user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: ep_step_on_call_users ep_step_on_call_users_ep_step_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ep_step_on_call_users
    ADD CONSTRAINT ep_step_on_call_users_ep_step_id_fkey FOREIGN KEY (ep_step_id) REFERENCES public.escalation_policy_steps(id) ON DELETE CASCADE;


--
-- Name: ep_step_on_call_users ep_step_on_call_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ep_step_on_call_users
    ADD CONSTRAINT ep_step_on_call_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_actions escalation_policy_actions_channel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT escalation_policy_actions_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES public.notification_channels(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_actions escalation_policy_actions_escalation_policy_step_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT escalation_policy_actions_escalation_policy_step_id_fkey FOREIGN KEY (escalation_policy_step_id) REFERENCES public.escalation_policy_steps(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_actions escalation_policy_actions_rotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT escalation_policy_actions_rotation_id_fkey FOREIGN KEY (rotation_id) REFERENCES public.rotations(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_actions escalation_policy_actions_schedule_id_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT escalation_policy_actions_schedule_id_fkey1 FOREIGN KEY (schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_actions escalation_policy_actions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_actions
    ADD CONSTRAINT escalation_policy_actions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_state escalation_policy_state_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_state
    ADD CONSTRAINT escalation_policy_state_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_state escalation_policy_state_escalation_policy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_state
    ADD CONSTRAINT escalation_policy_state_escalation_policy_id_fkey FOREIGN KEY (escalation_policy_id) REFERENCES public.escalation_policies(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_state escalation_policy_state_escalation_policy_step_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_state
    ADD CONSTRAINT escalation_policy_state_escalation_policy_step_id_fkey FOREIGN KEY (escalation_policy_step_id) REFERENCES public.escalation_policy_steps(id) ON DELETE SET NULL;


--
-- Name: escalation_policy_state escalation_policy_state_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_state
    ADD CONSTRAINT escalation_policy_state_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: escalation_policy_steps escalation_policy_steps_escalation_policy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_steps
    ADD CONSTRAINT escalation_policy_steps_escalation_policy_id_fkey FOREIGN KEY (escalation_policy_id) REFERENCES public.escalation_policies(id) ON DELETE CASCADE;


--
-- Name: heartbeat_monitors heartbeat_monitors_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.heartbeat_monitors
    ADD CONSTRAINT heartbeat_monitors_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: integration_keys integration_keys_services_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integration_keys
    ADD CONSTRAINT integration_keys_services_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: labels labels_tgt_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.labels
    ADD CONSTRAINT labels_tgt_service_id_fkey FOREIGN KEY (tgt_service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: notification_policy_cycles notification_policy_cycles_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_policy_cycles
    ADD CONSTRAINT notification_policy_cycles_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- Name: notification_policy_cycles notification_policy_cycles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_policy_cycles
    ADD CONSTRAINT notification_policy_cycles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_alert_log_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_alert_log_id_fkey FOREIGN KEY (alert_log_id) REFERENCES public.alert_logs(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_channel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES public.notification_channels(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_contact_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_contact_method_id_fkey FOREIGN KEY (contact_method_id) REFERENCES public.user_contact_methods(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_cycle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_cycle_id_fkey FOREIGN KEY (cycle_id) REFERENCES public.notification_policy_cycles(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_escalation_policy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_escalation_policy_id_fkey FOREIGN KEY (escalation_policy_id) REFERENCES public.escalation_policies(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: outgoing_messages outgoing_messages_user_verification_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_messages
    ADD CONSTRAINT outgoing_messages_user_verification_code_id_fkey FOREIGN KEY (user_verification_code_id) REFERENCES public.user_verification_codes(id) ON DELETE CASCADE;


--
-- Name: rotation_participants rotation_participants_rotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rotation_participants
    ADD CONSTRAINT rotation_participants_rotation_id_fkey FOREIGN KEY (rotation_id) REFERENCES public.rotations(id) ON DELETE CASCADE;


--
-- Name: rotation_participants rotation_participants_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rotation_participants
    ADD CONSTRAINT rotation_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: rotation_state rotation_state_rotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rotation_state
    ADD CONSTRAINT rotation_state_rotation_id_fkey FOREIGN KEY (rotation_id) REFERENCES public.rotations(id) ON DELETE CASCADE;


--
-- Name: rotation_state rotation_state_rotation_participant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rotation_state
    ADD CONSTRAINT rotation_state_rotation_participant_id_fkey FOREIGN KEY (rotation_participant_id) REFERENCES public.rotation_participants(id) DEFERRABLE;


--
-- Name: schedule_data schedule_data_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_data
    ADD CONSTRAINT schedule_data_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: schedule_on_call_users schedule_on_call_users_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_on_call_users
    ADD CONSTRAINT schedule_on_call_users_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: schedule_on_call_users schedule_on_call_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_on_call_users
    ADD CONSTRAINT schedule_on_call_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: schedule_rules schedule_rules_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_rules
    ADD CONSTRAINT schedule_rules_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: schedule_rules schedule_rules_tgt_rotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_rules
    ADD CONSTRAINT schedule_rules_tgt_rotation_id_fkey FOREIGN KEY (tgt_rotation_id) REFERENCES public.rotations(id) ON DELETE CASCADE;


--
-- Name: schedule_rules schedule_rules_tgt_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_rules
    ADD CONSTRAINT schedule_rules_tgt_user_id_fkey FOREIGN KEY (tgt_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: services services_escalation_policy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_escalation_policy_id_fkey FOREIGN KEY (escalation_policy_id) REFERENCES public.escalation_policies(id);


--
-- Name: escalation_policy_state svc_ep_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.escalation_policy_state
    ADD CONSTRAINT svc_ep_fkey FOREIGN KEY (service_id, escalation_policy_id) REFERENCES public.services(id, escalation_policy_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- Name: twilio_sms_callbacks twilio_sms_callbacks_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.twilio_sms_callbacks
    ADD CONSTRAINT twilio_sms_callbacks_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- Name: twilio_sms_callbacks twilio_sms_callbacks_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.twilio_sms_callbacks
    ADD CONSTRAINT twilio_sms_callbacks_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: user_calendar_subscriptions user_calendar_subscriptions_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_calendar_subscriptions
    ADD CONSTRAINT user_calendar_subscriptions_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: user_calendar_subscriptions user_calendar_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_calendar_subscriptions
    ADD CONSTRAINT user_calendar_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_contact_methods user_contact_methods_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_contact_methods
    ADD CONSTRAINT user_contact_methods_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_favorites user_favorites_tgt_escalation_policy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_tgt_escalation_policy_id_fkey FOREIGN KEY (tgt_escalation_policy_id) REFERENCES public.escalation_policies(id) ON DELETE CASCADE;


--
-- Name: user_favorites user_favorites_tgt_rotation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_tgt_rotation_id_fkey FOREIGN KEY (tgt_rotation_id) REFERENCES public.rotations(id) ON DELETE CASCADE;


--
-- Name: user_favorites user_favorites_tgt_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_tgt_schedule_id_fkey FOREIGN KEY (tgt_schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: user_favorites user_favorites_tgt_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_tgt_service_id_fkey FOREIGN KEY (tgt_service_id) REFERENCES public.services(id) ON DELETE CASCADE;


--
-- Name: user_favorites user_favorites_tgt_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_tgt_user_id_fkey FOREIGN KEY (tgt_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_favorites user_favorites_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_favorites
    ADD CONSTRAINT user_favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_notification_rules user_notification_rules_contact_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_notification_rules
    ADD CONSTRAINT user_notification_rules_contact_method_id_fkey FOREIGN KEY (contact_method_id) REFERENCES public.user_contact_methods(id) ON DELETE CASCADE;


--
-- Name: user_notification_rules user_notification_rules_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_notification_rules
    ADD CONSTRAINT user_notification_rules_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_overrides user_overrides_add_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_overrides
    ADD CONSTRAINT user_overrides_add_user_id_fkey FOREIGN KEY (add_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_overrides user_overrides_remove_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_overrides
    ADD CONSTRAINT user_overrides_remove_user_id_fkey FOREIGN KEY (remove_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_overrides user_overrides_tgt_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_overrides
    ADD CONSTRAINT user_overrides_tgt_schedule_id_fkey FOREIGN KEY (tgt_schedule_id) REFERENCES public.schedules(id) ON DELETE CASCADE;


--
-- Name: user_slack_data user_slack_data_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_slack_data
    ADD CONSTRAINT user_slack_data_id_fkey FOREIGN KEY (id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_verification_codes user_verification_codes_contact_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_verification_codes
    ADD CONSTRAINT user_verification_codes_contact_method_id_fkey FOREIGN KEY (contact_method_id) REFERENCES public.user_contact_methods(id) ON DELETE CASCADE;


--
-- Name: users users_alert_status_log_contact_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_alert_status_log_contact_method_id_fkey FOREIGN KEY (alert_status_log_contact_method_id) REFERENCES public.user_contact_methods(id) ON DELETE SET NULL DEFERRABLE;


--
-- PostgreSQL database dump complete
--

