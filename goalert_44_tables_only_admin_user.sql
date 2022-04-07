--
-- PostgreSQL database dump
--

-- Dumped from database version 14.2 (Ubuntu 14.2-1.pgdg20.04+1+b1)
-- Dumped by pg_dump version 14.2 (Ubuntu 14.2-1.pgdg20.04+1+b1)

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
    'cleanup'
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
    version integer DEFAULT 1 NOT NULL
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
    data jsonb NOT NULL
);


ALTER TABLE public.schedule_data OWNER TO postgres;

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
\.


--
-- Data for Name: alert_status_subscriptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alert_status_subscriptions (id, channel_id, contact_method_id, alert_id, last_alert_status) FROM stdin;
\.


--
-- Data for Name: alerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alerts (id, service_id, source, status, escalation_level, last_escalation, last_processed, created_at, dedup_key, summary, details) FROM stdin;
\.


--
-- Data for Name: auth_basic_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_basic_users (user_id, username, password_hash, id) FROM stdin;
00000000-0000-0000-0000-000000000001	admin	$2a$14$c7zRyLaCxDLuoTEEftPhS.v4aXZuVMYBkxVrCNsf7PDNN0gPu.f9O	1
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
\.


--
-- Data for Name: auth_user_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auth_user_sessions (id, created_at, user_agent, user_id, last_access_at) FROM stdin;
3073396d-6a13-4fa5-ad50-30662dc004af	2022-03-22 10:16:12.656532+00	Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:98.0) Gecko/20100101 Firefox/98.0	00000000-0000-0000-0000-000000000001	2022-03-22 10:48:48.816764+00
\.


--
-- Data for Name: config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.config (id, schema, data, created_at) FROM stdin;
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

COPY public.engine_processing_versions (type_id, version) FROM stdin;
heartbeat	1
np_cycle	2
escalation	3
cleanup	1
verify	2
rotation	2
schedule	3
status_update	3
message	9
\.


--
-- Data for Name: ep_step_on_call_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ep_step_on_call_users (user_id, ep_step_id, start_time, end_time, id) FROM stdin;
\.


--
-- Data for Name: escalation_policies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.escalation_policies (id, name, description, repeat, step_count) FROM stdin;
\.


--
-- Data for Name: escalation_policy_actions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.escalation_policy_actions (id, escalation_policy_step_id, user_id, schedule_id, rotation_id, channel_id) FROM stdin;
\.


--
-- Data for Name: escalation_policy_state; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.escalation_policy_state (escalation_policy_id, escalation_policy_step_id, escalation_policy_step_number, alert_id, last_escalation, loop_count, force_escalation, service_id, next_escalation, id) FROM stdin;
\.


--
-- Data for Name: escalation_policy_steps; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.escalation_policy_steps (id, delay, step_number, escalation_policy_id) FROM stdin;
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
\.


--
-- Data for Name: heartbeat_monitors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.heartbeat_monitors (id, name, service_id, heartbeat_interval, last_state, last_heartbeat) FROM stdin;
\.


--
-- Data for Name: integration_keys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.integration_keys (id, name, type, service_id) FROM stdin;
\.


--
-- Data for Name: keyring; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.keyring (id, verification_keys, signing_key, next_key, next_rotation, rotation_count) FROM stdin;
oauth-state	\\x7b2230223a224d453477454159484b6f5a497a6a3043415159464b344545414345444f6741456662706c736269612f56357775446845477431585a5434664e2f646e67717a377954594a4a706a7933793143706d514e634c523972566c2b675a6d61493068654141724330476b6631466b3d222c2231223a224d453477454159484b6f5a497a6a3043415159464b344545414345444f674145593568494e33555143525952495a4c424e6267474c674256673636366c306d436e4e79437754746a4c762f2b4b513557666153574142766a654a336a667466323249514253685052356e6b3d227d	\\x2d2d2d2d2d424547494e2045434453412050524956415445204b45592d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c64626431613966653864396264353837616231623937653736663536656331650a0a4e7a766c4136654749752b4973724169365a736d7851356a6e7a79737435634b446f576b38697076546a73422b742f4447743957623031434e724677627438390a78646847626f3533756a7a6e52764c6e6d42326e6a52502f69634236394c5973544c655a575373535a786b53347745312b357275646a6755366a647a487069450a564553487663306f6337454c59626f726a765a6c2b513d3d0a2d2d2d2d2d454e442045434453412050524956415445204b45592d2d2d2d2d0a	\\x2d2d2d2d2d424547494e2045434453412050524956415445204b45592d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c32356135633238316163313636346431643939643765643366613637373930610a0a714b7735316361532f6c77314365434f4243704e596b3331536a343461426977594770364c5a4c634d31544f4b6c434268696e6641554c454b6c636b463753650a56425a4179325a6765756e36314b53344a6945554c737977706745485953706978513062594868754b41626273626a643458467856314145586d7430623548350a3537652f4c5242737658644f732f55323864357441413d3d0a2d2d2d2d2d454e442045434453412050524956415445204b45592d2d2d2d2d0a	2022-03-23 10:15:46.064527+00	0
browser-sessions	\\x7b2230223a224d453477454159484b6f5a497a6a3043415159464b344545414345444f6741456d487642682f70384566622f7547772f6e4d6c3770597150487544664e63455472634b6a7a694c4b32773075334a4c61636631646c632b37504a703344657170746f5477307432543248773d222c2231223a224d453477454159484b6f5a497a6a3043415159464b344545414345444f6741456c7a6d5156696868776877454a30754e376875444b65666554625759466f4441623554503062744335556e556b354d346f427778763849534946314f64565267615a5756495766425869303d227d	\\x2d2d2d2d2d424547494e2045434453412050524956415445204b45592d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c36393935653337646161613636356465303766663163323934636530373966330a0a614e6873546747496339785276736d2f33617837584552304f654246573364414d6e35384f71632b2b30462f4e5752577a534e74494e383274326e735a5478770a506255696a4a574a75764e2f6573426f7577714a532f38374774455466576c694c353945705a5a46536f5879792b31372b4e4831546d514b55765438426853660a38736a6f4739614c394158324a36346b4b78697455673d3d0a2d2d2d2d2d454e442045434453412050524956415445204b45592d2d2d2d2d0a	\\x2d2d2d2d2d424547494e2045434453412050524956415445204b45592d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c35343839353964306436626363393361646132313838656637313064383039330a0a374f5653704c6f4c763633506f625643417745724e44684f56723076385133513333654c3853464730526147764b4f6a775054774d49643655734b5a536f76670a394a766c73433774646835353834686b4c51347442325263317644774b4b4f65314346576171703967522f506b74566d57734f614b6658434e666b74346467730a48306e75716f594d6c592b4a377579394c77783170413d3d0a2d2d2d2d2d454e442045434453412050524956415445204b45592d2d2d2d2d0a	2022-03-23 10:15:46.073258+00	0
api-keys	\\x7b2230223a224d453477454159484b6f5a497a6a3043415159464b344545414345444f6741456e6c665236796a6c622f4d553444444a5951453437706d5a752f76763646326466327a44566b4362415930396e54587767792b623466643763634f387939356d704f65486b6c36707953633d222c2231223a224d453477454159484b6f5a497a6a3043415159464b344545414345444f674145443474365261484b6e472b63334d41516430553631713257563276683436445944614c33614c56387a774478434175464c6b764374634f392b706733464f30445a4b7338556753597768453d227d	\\x2d2d2d2d2d424547494e2045434453412050524956415445204b45592d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c61353965333663306662396164313631343533323564333230363833343464610a0a75676b6f682f2f4846347339554f77426f7175496a4d505564443367317a6b68617253324d6837382f704f366f6e7243355253533935457537442f73334858370a666f64617873716b33355066336a4e79683069516844396f31726b683731414e4b4569534e6b784c6a473575496652614c7a7a58574f457862305a4d764e67690a774448765372764556442b6b4c42473436546f6361673d3d0a2d2d2d2d2d454e442045434453412050524956415445204b45592d2d2d2d2d0a	\\x2d2d2d2d2d424547494e2045434453412050524956415445204b45592d2d2d2d2d0a50726f632d547970653a20342c454e435259505445440a44454b2d496e666f3a204145532d3235362d4342432c34643839646334636463386465363032373930663862396232626232656131380a0a4f76596d50513756476f4669326d597576724638565a564c426157444654476245567248633732676a6b7a59395248546f7350362b58717247536356734a73680a58465051584d79574f66726f7765766c4d4a3942396f656c4a31543952675948704267717466465a72475458633953696549783054794b57774f5a716a4b6e790a66553677585a77426338594369424779735a516258773d3d0a2d2d2d2d2d454e442045434453412050524956415445204b45592d2d2d2d2d0a	\N	0
\.


--
-- Data for Name: labels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.labels (id, tgt_service_id, key, value) FROM stdin;
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
\.


--
-- Data for Name: outgoing_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.outgoing_messages (id, message_type, contact_method_id, created_at, last_status, last_status_at, status_details, fired_at, sent_at, retry_count, next_retry_at, sending_deadline, user_id, alert_id, cycle_id, service_id, escalation_policy_id, alert_log_id, user_verification_code_id, provider_msg_id, provider_seq, channel_id, status_alert_ids, schedule_id, src_value) FROM stdin;
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
\.


--
-- Data for Name: rotation_state; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rotation_state (rotation_id, "position", rotation_participant_id, shift_start, id, version) FROM stdin;
\.


--
-- Data for Name: rotations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rotations (id, name, description, type, start_time, shift_length, time_zone, last_processed, participant_count) FROM stdin;
\.


--
-- Data for Name: schedule_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schedule_data (schedule_id, last_cleanup_at, data) FROM stdin;
\.


--
-- Data for Name: schedule_on_call_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schedule_on_call_users (schedule_id, start_time, end_time, user_id, id) FROM stdin;
\.


--
-- Data for Name: schedule_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schedule_rules (id, schedule_id, sunday, monday, tuesday, wednesday, thursday, friday, saturday, start_time, end_time, created_at, tgt_user_id, tgt_rotation_id, is_active) FROM stdin;
\.


--
-- Data for Name: schedules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schedules (id, name, description, time_zone, last_processed) FROM stdin;
\.


--
-- Data for Name: services; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.services (id, name, description, escalation_policy_id) FROM stdin;
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
\.


--
-- Data for Name: user_favorites; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_favorites (user_id, tgt_service_id, id, tgt_rotation_id, tgt_schedule_id, tgt_escalation_policy_id, tgt_user_id) FROM stdin;
00000000-0000-0000-0000-000000000001	\N	6	\N	\N	\N	\N
00000000-0000-0000-0000-000000000001	\N	8	\N	\N	\N	\N
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
00000000-0000-0000-0000-000000000001		admin@example.com	admin	Admin McAdminFace		\N
\.


--
-- Name: alert_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.alert_logs_id_seq', 1, false);


--
-- Name: alert_status_subscriptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.alert_status_subscriptions_id_seq', 1, false);


--
-- Name: alerts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.alerts_id_seq', 79671, true);


--
-- Name: auth_basic_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_basic_users_id_seq', 1, true);


--
-- Name: auth_subjects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auth_subjects_id_seq', 1, true);


--
-- Name: config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.config_id_seq', 1, false);


--
-- Name: ep_step_on_call_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ep_step_on_call_users_id_seq', 7441474, true);


--
-- Name: escalation_policy_state_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.escalation_policy_state_id_seq', 2263, true);


--
-- Name: incident_number_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.incident_number_seq', 1, false);


--
-- Name: labels_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.labels_id_seq', 760, true);


--
-- Name: region_ids_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.region_ids_id_seq', 1, true);


--
-- Name: rotation_state_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.rotation_state_id_seq', 12787, true);


--
-- Name: schedule_on_call_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.schedule_on_call_users_id_seq', 1252, true);


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

SELECT pg_catalog.setval('public.user_favorites_id_seq', 20741, true);


--
-- Name: alert_logs alert_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_logs
    ADD CONSTRAINT alert_logs_pkey PRIMARY KEY (id);


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

