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

SET default_tablespace = '';

SET default_table_access_method = heap;

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
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, bio, email, role, name, avatar_url, alert_status_log_contact_method_id) FROM stdin;
ea7e4b42-9594-4d69-9eb2-a64fece9ae31		venugopal.thammala@scriptbees.com	admin	Venu Gopal		4ea6c87e-718c-4f97-9213-5842133707d6
eff381c9-461c-4d84-a061-a3c2ff2c2ce1		gautham.anne@scriptbees.com	admin	Gautham		be681185-17ba-4cfa-8759-c8c15fa5f693
714cf91d-a7d8-40af-9f33-39215b871ca5			admin	Scriptbees-Admin		\N
00000000-0000-0000-0000-000000000001		admin@example.com	admin	Admin McAdminFace		\N
\.


--
-- Name: users goalert_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT goalert_user_pkey PRIMARY KEY (id);


--
-- Name: idx_search_users_name_eng; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_search_users_name_eng ON public.users USING gin (to_tsvector('english'::regconfig, replace(lower(name), '.'::text, ' '::text)));


--
-- Name: idx_user_status_updates; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_status_updates ON public.users USING btree (alert_status_log_contact_method_id) WHERE (alert_status_log_contact_method_id IS NOT NULL);


--
-- Name: users trg_enforce_status_update_same_user; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_enforce_status_update_same_user BEFORE INSERT OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_status_update_same_user();


--
-- Name: users users_alert_status_log_contact_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_alert_status_log_contact_method_id_fkey FOREIGN KEY (alert_status_log_contact_method_id) REFERENCES public.user_contact_methods(id) ON DELETE SET NULL DEFERRABLE;


--
-- PostgreSQL database dump complete
--

