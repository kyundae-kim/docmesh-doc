--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5 (Debian 17.5-1.pgdg130+1)
-- Dumped by pg_dump version 17.5 (Debian 17.5-1.pgdg130+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
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
-- Name: admin_event_entity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_event_entity (
    id character varying(36) NOT NULL,
    admin_event_time bigint,
    realm_id character varying(255),
    operation_type character varying(255),
    auth_realm_id character varying(255),
    auth_client_id character varying(255),
    auth_user_id character varying(255),
    ip_address character varying(255),
    resource_path character varying(2550),
    representation text,
    error character varying(255),
    resource_type character varying(64),
    details_json text
);


ALTER TABLE public.admin_event_entity OWNER TO postgres;

--
-- Name: associated_policy; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.associated_policy (
    policy_id character varying(36) NOT NULL,
    associated_policy_id character varying(36) NOT NULL
);


ALTER TABLE public.associated_policy OWNER TO postgres;

--
-- Name: authentication_execution; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.authentication_execution (
    id character varying(36) NOT NULL,
    alias character varying(255),
    authenticator character varying(36),
    realm_id character varying(36),
    flow_id character varying(36),
    requirement integer,
    priority integer,
    authenticator_flow boolean DEFAULT false NOT NULL,
    auth_flow_id character varying(36),
    auth_config character varying(36)
);


ALTER TABLE public.authentication_execution OWNER TO postgres;

--
-- Name: authentication_flow; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.authentication_flow (
    id character varying(36) NOT NULL,
    alias character varying(255),
    description character varying(255),
    realm_id character varying(36),
    provider_id character varying(36) DEFAULT 'basic-flow'::character varying NOT NULL,
    top_level boolean DEFAULT false NOT NULL,
    built_in boolean DEFAULT false NOT NULL
);


ALTER TABLE public.authentication_flow OWNER TO postgres;

--
-- Name: authenticator_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.authenticator_config (
    id character varying(36) NOT NULL,
    alias character varying(255),
    realm_id character varying(36)
);


ALTER TABLE public.authenticator_config OWNER TO postgres;

--
-- Name: authenticator_config_entry; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.authenticator_config_entry (
    authenticator_id character varying(36) NOT NULL,
    value text,
    name character varying(255) NOT NULL
);


ALTER TABLE public.authenticator_config_entry OWNER TO postgres;

--
-- Name: broker_link; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.broker_link (
    identity_provider character varying(255) NOT NULL,
    storage_provider_id character varying(255),
    realm_id character varying(36) NOT NULL,
    broker_user_id character varying(255),
    broker_username character varying(255),
    token text,
    user_id character varying(255) NOT NULL
);


ALTER TABLE public.broker_link OWNER TO postgres;

--
-- Name: client; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client (
    id character varying(36) NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    full_scope_allowed boolean DEFAULT false NOT NULL,
    client_id character varying(255),
    not_before integer,
    public_client boolean DEFAULT false NOT NULL,
    secret character varying(255),
    base_url character varying(255),
    bearer_only boolean DEFAULT false NOT NULL,
    management_url character varying(255),
    surrogate_auth_required boolean DEFAULT false NOT NULL,
    realm_id character varying(36),
    protocol character varying(255),
    node_rereg_timeout integer DEFAULT 0,
    frontchannel_logout boolean DEFAULT false NOT NULL,
    consent_required boolean DEFAULT false NOT NULL,
    name character varying(255),
    service_accounts_enabled boolean DEFAULT false NOT NULL,
    client_authenticator_type character varying(255),
    root_url character varying(255),
    description character varying(255),
    registration_token character varying(255),
    standard_flow_enabled boolean DEFAULT true NOT NULL,
    implicit_flow_enabled boolean DEFAULT false NOT NULL,
    direct_access_grants_enabled boolean DEFAULT false NOT NULL,
    always_display_in_console boolean DEFAULT false NOT NULL
);


ALTER TABLE public.client OWNER TO postgres;

--
-- Name: client_attributes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client_attributes (
    client_id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    value text
);


ALTER TABLE public.client_attributes OWNER TO postgres;

--
-- Name: client_auth_flow_bindings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client_auth_flow_bindings (
    client_id character varying(36) NOT NULL,
    flow_id character varying(36),
    binding_name character varying(255) NOT NULL
);


ALTER TABLE public.client_auth_flow_bindings OWNER TO postgres;

--
-- Name: client_initial_access; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client_initial_access (
    id character varying(36) NOT NULL,
    realm_id character varying(36) NOT NULL,
    "timestamp" integer,
    expiration integer,
    count integer,
    remaining_count integer
);


ALTER TABLE public.client_initial_access OWNER TO postgres;

--
-- Name: client_node_registrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client_node_registrations (
    client_id character varying(36) NOT NULL,
    value integer,
    name character varying(255) NOT NULL
);


ALTER TABLE public.client_node_registrations OWNER TO postgres;

--
-- Name: client_scope; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client_scope (
    id character varying(36) NOT NULL,
    name character varying(255),
    realm_id character varying(36),
    description character varying(255),
    protocol character varying(255)
);


ALTER TABLE public.client_scope OWNER TO postgres;

--
-- Name: client_scope_attributes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client_scope_attributes (
    scope_id character varying(36) NOT NULL,
    value character varying(2048),
    name character varying(255) NOT NULL
);


ALTER TABLE public.client_scope_attributes OWNER TO postgres;

--
-- Name: client_scope_client; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client_scope_client (
    client_id character varying(255) NOT NULL,
    scope_id character varying(255) NOT NULL,
    default_scope boolean DEFAULT false NOT NULL
);


ALTER TABLE public.client_scope_client OWNER TO postgres;

--
-- Name: client_scope_role_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.client_scope_role_mapping (
    scope_id character varying(36) NOT NULL,
    role_id character varying(36) NOT NULL
);


ALTER TABLE public.client_scope_role_mapping OWNER TO postgres;

--
-- Name: component; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.component (
    id character varying(36) NOT NULL,
    name character varying(255),
    parent_id character varying(36),
    provider_id character varying(36),
    provider_type character varying(255),
    realm_id character varying(36),
    sub_type character varying(255)
);


ALTER TABLE public.component OWNER TO postgres;

--
-- Name: component_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.component_config (
    id character varying(36) NOT NULL,
    component_id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    value text
);


ALTER TABLE public.component_config OWNER TO postgres;

--
-- Name: composite_role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.composite_role (
    composite character varying(36) NOT NULL,
    child_role character varying(36) NOT NULL
);


ALTER TABLE public.composite_role OWNER TO postgres;

--
-- Name: credential; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.credential (
    id character varying(36) NOT NULL,
    salt bytea,
    type character varying(255),
    user_id character varying(36),
    created_date bigint,
    user_label character varying(255),
    secret_data text,
    credential_data text,
    priority integer,
    version integer DEFAULT 0
);


ALTER TABLE public.credential OWNER TO postgres;

--
-- Name: databasechangelog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.databasechangelog (
    id character varying(255) NOT NULL,
    author character varying(255) NOT NULL,
    filename character varying(255) NOT NULL,
    dateexecuted timestamp without time zone NOT NULL,
    orderexecuted integer NOT NULL,
    exectype character varying(10) NOT NULL,
    md5sum character varying(35),
    description character varying(255),
    comments character varying(255),
    tag character varying(255),
    liquibase character varying(20),
    contexts character varying(255),
    labels character varying(255),
    deployment_id character varying(10)
);


ALTER TABLE public.databasechangelog OWNER TO postgres;

--
-- Name: databasechangeloglock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.databasechangeloglock (
    id integer NOT NULL,
    locked boolean NOT NULL,
    lockgranted timestamp without time zone,
    lockedby character varying(255)
);


ALTER TABLE public.databasechangeloglock OWNER TO postgres;

--
-- Name: default_client_scope; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.default_client_scope (
    realm_id character varying(36) NOT NULL,
    scope_id character varying(36) NOT NULL,
    default_scope boolean DEFAULT false NOT NULL
);


ALTER TABLE public.default_client_scope OWNER TO postgres;

--
-- Name: event_entity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.event_entity (
    id character varying(36) NOT NULL,
    client_id character varying(255),
    details_json character varying(2550),
    error character varying(255),
    ip_address character varying(255),
    realm_id character varying(255),
    session_id character varying(255),
    event_time bigint,
    type character varying(255),
    user_id character varying(255),
    details_json_long_value text
);


ALTER TABLE public.event_entity OWNER TO postgres;

--
-- Name: fed_user_attribute; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fed_user_attribute (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    user_id character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    storage_provider_id character varying(36),
    value character varying(2024),
    long_value_hash bytea,
    long_value_hash_lower_case bytea,
    long_value text
);


ALTER TABLE public.fed_user_attribute OWNER TO postgres;

--
-- Name: fed_user_consent; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fed_user_consent (
    id character varying(36) NOT NULL,
    client_id character varying(255),
    user_id character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    storage_provider_id character varying(36),
    created_date bigint,
    last_updated_date bigint,
    client_storage_provider character varying(36),
    external_client_id character varying(255)
);


ALTER TABLE public.fed_user_consent OWNER TO postgres;

--
-- Name: fed_user_consent_cl_scope; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fed_user_consent_cl_scope (
    user_consent_id character varying(36) NOT NULL,
    scope_id character varying(36) NOT NULL
);


ALTER TABLE public.fed_user_consent_cl_scope OWNER TO postgres;

--
-- Name: fed_user_credential; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fed_user_credential (
    id character varying(36) NOT NULL,
    salt bytea,
    type character varying(255),
    created_date bigint,
    user_id character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    storage_provider_id character varying(36),
    user_label character varying(255),
    secret_data text,
    credential_data text,
    priority integer
);


ALTER TABLE public.fed_user_credential OWNER TO postgres;

--
-- Name: fed_user_group_membership; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fed_user_group_membership (
    group_id character varying(36) NOT NULL,
    user_id character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    storage_provider_id character varying(36)
);


ALTER TABLE public.fed_user_group_membership OWNER TO postgres;

--
-- Name: fed_user_required_action; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fed_user_required_action (
    required_action character varying(255) DEFAULT ' '::character varying NOT NULL,
    user_id character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    storage_provider_id character varying(36)
);


ALTER TABLE public.fed_user_required_action OWNER TO postgres;

--
-- Name: fed_user_role_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fed_user_role_mapping (
    role_id character varying(36) NOT NULL,
    user_id character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    storage_provider_id character varying(36)
);


ALTER TABLE public.fed_user_role_mapping OWNER TO postgres;

--
-- Name: federated_identity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.federated_identity (
    identity_provider character varying(255) NOT NULL,
    realm_id character varying(36),
    federated_user_id character varying(255),
    federated_username character varying(255),
    token text,
    user_id character varying(36) NOT NULL
);


ALTER TABLE public.federated_identity OWNER TO postgres;

--
-- Name: federated_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.federated_user (
    id character varying(255) NOT NULL,
    storage_provider_id character varying(255),
    realm_id character varying(36) NOT NULL
);


ALTER TABLE public.federated_user OWNER TO postgres;

--
-- Name: group_attribute; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.group_attribute (
    id character varying(36) DEFAULT 'sybase-needs-something-here'::character varying NOT NULL,
    name character varying(255) NOT NULL,
    value character varying(255),
    group_id character varying(36) NOT NULL
);


ALTER TABLE public.group_attribute OWNER TO postgres;

--
-- Name: group_role_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.group_role_mapping (
    role_id character varying(36) NOT NULL,
    group_id character varying(36) NOT NULL
);


ALTER TABLE public.group_role_mapping OWNER TO postgres;

--
-- Name: identity_provider; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.identity_provider (
    internal_id character varying(36) NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    provider_alias character varying(255),
    provider_id character varying(255),
    store_token boolean,
    authenticate_by_default boolean,
    realm_id character varying(36),
    add_token_role boolean,
    trust_email boolean,
    first_broker_login_flow_id character varying(36),
    post_broker_login_flow_id character varying(36),
    provider_display_name character varying(255),
    link_only boolean,
    organization_id character varying(255),
    hide_on_login boolean
);


ALTER TABLE public.identity_provider OWNER TO postgres;

--
-- Name: identity_provider_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.identity_provider_config (
    identity_provider_id character varying(36) NOT NULL,
    value text,
    name character varying(255) NOT NULL
);


ALTER TABLE public.identity_provider_config OWNER TO postgres;

--
-- Name: identity_provider_mapper; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.identity_provider_mapper (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    idp_alias character varying(255) NOT NULL,
    idp_mapper_name character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL
);


ALTER TABLE public.identity_provider_mapper OWNER TO postgres;

--
-- Name: idp_mapper_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.idp_mapper_config (
    idp_mapper_id character varying(36) NOT NULL,
    value text,
    name character varying(255) NOT NULL
);


ALTER TABLE public.idp_mapper_config OWNER TO postgres;

--
-- Name: jgroups_ping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jgroups_ping (
    address character varying(200) NOT NULL,
    name character varying(200),
    cluster_name character varying(200) NOT NULL,
    ip character varying(200) NOT NULL,
    coord boolean
);


ALTER TABLE public.jgroups_ping OWNER TO postgres;

--
-- Name: keycloak_group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.keycloak_group (
    id character varying(36) NOT NULL,
    name character varying(255),
    parent_group character varying(36) NOT NULL,
    realm_id character varying(36),
    type integer DEFAULT 0 NOT NULL,
    description character varying(255)
);


ALTER TABLE public.keycloak_group OWNER TO postgres;

--
-- Name: keycloak_role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.keycloak_role (
    id character varying(36) NOT NULL,
    client_realm_constraint character varying(255),
    client_role boolean DEFAULT false NOT NULL,
    description character varying(255),
    name character varying(255),
    realm_id character varying(255),
    client character varying(36),
    realm character varying(36)
);


ALTER TABLE public.keycloak_role OWNER TO postgres;

--
-- Name: migration_model; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.migration_model (
    id character varying(36) NOT NULL,
    version character varying(36),
    update_time bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.migration_model OWNER TO postgres;

--
-- Name: offline_client_session; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.offline_client_session (
    user_session_id character varying(36) NOT NULL,
    client_id character varying(255) NOT NULL,
    offline_flag character varying(4) NOT NULL,
    "timestamp" integer,
    data text,
    client_storage_provider character varying(36) DEFAULT 'local'::character varying NOT NULL,
    external_client_id character varying(255) DEFAULT 'local'::character varying NOT NULL,
    version integer DEFAULT 0
);


ALTER TABLE public.offline_client_session OWNER TO postgres;

--
-- Name: offline_user_session; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.offline_user_session (
    user_session_id character varying(36) NOT NULL,
    user_id character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    created_on integer NOT NULL,
    offline_flag character varying(4) NOT NULL,
    data text,
    last_session_refresh integer DEFAULT 0 NOT NULL,
    broker_session_id character varying(1024),
    version integer DEFAULT 0,
    remember_me boolean
);


ALTER TABLE public.offline_user_session OWNER TO postgres;

--
-- Name: org; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org (
    id character varying(255) NOT NULL,
    enabled boolean NOT NULL,
    realm_id character varying(255) NOT NULL,
    group_id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(4000),
    alias character varying(255) NOT NULL,
    redirect_url character varying(2048)
);


ALTER TABLE public.org OWNER TO postgres;

--
-- Name: org_domain; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_domain (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    verified boolean NOT NULL,
    org_id character varying(255) NOT NULL
);


ALTER TABLE public.org_domain OWNER TO postgres;

--
-- Name: org_invitation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.org_invitation (
    id character varying(36) NOT NULL,
    organization_id character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    created_at integer NOT NULL,
    expires_at integer,
    invite_link character varying(2048)
);


ALTER TABLE public.org_invitation OWNER TO postgres;

--
-- Name: policy_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.policy_config (
    policy_id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    value text
);


ALTER TABLE public.policy_config OWNER TO postgres;

--
-- Name: protocol_mapper; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.protocol_mapper (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    protocol character varying(255) NOT NULL,
    protocol_mapper_name character varying(255) NOT NULL,
    client_id character varying(36),
    client_scope_id character varying(36)
);


ALTER TABLE public.protocol_mapper OWNER TO postgres;

--
-- Name: protocol_mapper_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.protocol_mapper_config (
    protocol_mapper_id character varying(36) NOT NULL,
    value text,
    name character varying(255) NOT NULL
);


ALTER TABLE public.protocol_mapper_config OWNER TO postgres;

--
-- Name: realm; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.realm (
    id character varying(36) NOT NULL,
    access_code_lifespan integer,
    user_action_lifespan integer,
    access_token_lifespan integer,
    account_theme character varying(255),
    admin_theme character varying(255),
    email_theme character varying(255),
    enabled boolean DEFAULT false NOT NULL,
    events_enabled boolean DEFAULT false NOT NULL,
    events_expiration bigint,
    login_theme character varying(255),
    name character varying(255),
    not_before integer,
    password_policy character varying(2550),
    registration_allowed boolean DEFAULT false NOT NULL,
    remember_me boolean DEFAULT false NOT NULL,
    reset_password_allowed boolean DEFAULT false NOT NULL,
    social boolean DEFAULT false NOT NULL,
    ssl_required character varying(255),
    sso_idle_timeout integer,
    sso_max_lifespan integer,
    update_profile_on_soc_login boolean DEFAULT false NOT NULL,
    verify_email boolean DEFAULT false NOT NULL,
    master_admin_client character varying(36),
    login_lifespan integer,
    internationalization_enabled boolean DEFAULT false NOT NULL,
    default_locale character varying(255),
    reg_email_as_username boolean DEFAULT false NOT NULL,
    admin_events_enabled boolean DEFAULT false NOT NULL,
    admin_events_details_enabled boolean DEFAULT false NOT NULL,
    edit_username_allowed boolean DEFAULT false NOT NULL,
    otp_policy_counter integer DEFAULT 0,
    otp_policy_window integer DEFAULT 1,
    otp_policy_period integer DEFAULT 30,
    otp_policy_digits integer DEFAULT 6,
    otp_policy_alg character varying(36) DEFAULT 'HmacSHA1'::character varying,
    otp_policy_type character varying(36) DEFAULT 'totp'::character varying,
    browser_flow character varying(36),
    registration_flow character varying(36),
    direct_grant_flow character varying(36),
    reset_credentials_flow character varying(36),
    client_auth_flow character varying(36),
    offline_session_idle_timeout integer DEFAULT 0,
    revoke_refresh_token boolean DEFAULT false NOT NULL,
    access_token_life_implicit integer DEFAULT 0,
    login_with_email_allowed boolean DEFAULT true NOT NULL,
    duplicate_emails_allowed boolean DEFAULT false NOT NULL,
    docker_auth_flow character varying(36),
    refresh_token_max_reuse integer DEFAULT 0,
    allow_user_managed_access boolean DEFAULT false NOT NULL,
    sso_max_lifespan_remember_me integer DEFAULT 0 NOT NULL,
    sso_idle_timeout_remember_me integer DEFAULT 0 NOT NULL,
    default_role character varying(255)
);


ALTER TABLE public.realm OWNER TO postgres;

--
-- Name: realm_attribute; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.realm_attribute (
    name character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL,
    value text
);


ALTER TABLE public.realm_attribute OWNER TO postgres;

--
-- Name: realm_default_groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.realm_default_groups (
    realm_id character varying(36) NOT NULL,
    group_id character varying(36) NOT NULL
);


ALTER TABLE public.realm_default_groups OWNER TO postgres;

--
-- Name: realm_enabled_event_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.realm_enabled_event_types (
    realm_id character varying(36) NOT NULL,
    value character varying(255) NOT NULL
);


ALTER TABLE public.realm_enabled_event_types OWNER TO postgres;

--
-- Name: realm_events_listeners; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.realm_events_listeners (
    realm_id character varying(36) NOT NULL,
    value character varying(255) NOT NULL
);


ALTER TABLE public.realm_events_listeners OWNER TO postgres;

--
-- Name: realm_localizations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.realm_localizations (
    realm_id character varying(255) NOT NULL,
    locale character varying(255) NOT NULL,
    texts text NOT NULL
);


ALTER TABLE public.realm_localizations OWNER TO postgres;

--
-- Name: realm_required_credential; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.realm_required_credential (
    type character varying(255) NOT NULL,
    form_label character varying(255),
    input boolean DEFAULT false NOT NULL,
    secret boolean DEFAULT false NOT NULL,
    realm_id character varying(36) NOT NULL
);


ALTER TABLE public.realm_required_credential OWNER TO postgres;

--
-- Name: realm_smtp_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.realm_smtp_config (
    realm_id character varying(36) NOT NULL,
    value character varying(255),
    name character varying(255) NOT NULL
);


ALTER TABLE public.realm_smtp_config OWNER TO postgres;

--
-- Name: realm_supported_locales; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.realm_supported_locales (
    realm_id character varying(36) NOT NULL,
    value character varying(255) NOT NULL
);


ALTER TABLE public.realm_supported_locales OWNER TO postgres;

--
-- Name: redirect_uris; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.redirect_uris (
    client_id character varying(36) NOT NULL,
    value character varying(255) NOT NULL
);


ALTER TABLE public.redirect_uris OWNER TO postgres;

--
-- Name: required_action_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.required_action_config (
    required_action_id character varying(36) NOT NULL,
    value text,
    name character varying(255) NOT NULL
);


ALTER TABLE public.required_action_config OWNER TO postgres;

--
-- Name: required_action_provider; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.required_action_provider (
    id character varying(36) NOT NULL,
    alias character varying(255),
    name character varying(255),
    realm_id character varying(36),
    enabled boolean DEFAULT false NOT NULL,
    default_action boolean DEFAULT false NOT NULL,
    provider_id character varying(255),
    priority integer
);


ALTER TABLE public.required_action_provider OWNER TO postgres;

--
-- Name: resource_attribute; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resource_attribute (
    id character varying(36) DEFAULT 'sybase-needs-something-here'::character varying NOT NULL,
    name character varying(255) NOT NULL,
    value character varying(255),
    resource_id character varying(36) NOT NULL
);


ALTER TABLE public.resource_attribute OWNER TO postgres;

--
-- Name: resource_policy; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resource_policy (
    resource_id character varying(36) NOT NULL,
    policy_id character varying(36) NOT NULL
);


ALTER TABLE public.resource_policy OWNER TO postgres;

--
-- Name: resource_scope; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resource_scope (
    resource_id character varying(36) NOT NULL,
    scope_id character varying(36) NOT NULL
);


ALTER TABLE public.resource_scope OWNER TO postgres;

--
-- Name: resource_server; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resource_server (
    id character varying(36) NOT NULL,
    allow_rs_remote_mgmt boolean DEFAULT false NOT NULL,
    policy_enforce_mode smallint NOT NULL,
    decision_strategy smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.resource_server OWNER TO postgres;

--
-- Name: resource_server_perm_ticket; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resource_server_perm_ticket (
    id character varying(36) NOT NULL,
    owner character varying(255) NOT NULL,
    requester character varying(255) NOT NULL,
    created_timestamp bigint NOT NULL,
    granted_timestamp bigint,
    resource_id character varying(36) NOT NULL,
    scope_id character varying(36),
    resource_server_id character varying(36) NOT NULL,
    policy_id character varying(36)
);


ALTER TABLE public.resource_server_perm_ticket OWNER TO postgres;

--
-- Name: resource_server_policy; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resource_server_policy (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    type character varying(255) NOT NULL,
    decision_strategy smallint,
    logic smallint,
    resource_server_id character varying(36) NOT NULL,
    owner character varying(255)
);


ALTER TABLE public.resource_server_policy OWNER TO postgres;

--
-- Name: resource_server_resource; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resource_server_resource (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(255),
    icon_uri character varying(255),
    owner character varying(255) NOT NULL,
    resource_server_id character varying(36) NOT NULL,
    owner_managed_access boolean DEFAULT false NOT NULL,
    display_name character varying(255)
);


ALTER TABLE public.resource_server_resource OWNER TO postgres;

--
-- Name: resource_server_scope; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resource_server_scope (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    icon_uri character varying(255),
    resource_server_id character varying(36) NOT NULL,
    display_name character varying(255)
);


ALTER TABLE public.resource_server_scope OWNER TO postgres;

--
-- Name: resource_uris; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.resource_uris (
    resource_id character varying(36) NOT NULL,
    value character varying(255) NOT NULL
);


ALTER TABLE public.resource_uris OWNER TO postgres;

--
-- Name: revoked_token; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.revoked_token (
    id character varying(255) NOT NULL,
    expire bigint NOT NULL
);


ALTER TABLE public.revoked_token OWNER TO postgres;

--
-- Name: role_attribute; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_attribute (
    id character varying(36) NOT NULL,
    role_id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    value character varying(255)
);


ALTER TABLE public.role_attribute OWNER TO postgres;

--
-- Name: scope_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scope_mapping (
    client_id character varying(36) NOT NULL,
    role_id character varying(36) NOT NULL
);


ALTER TABLE public.scope_mapping OWNER TO postgres;

--
-- Name: scope_policy; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scope_policy (
    scope_id character varying(36) NOT NULL,
    policy_id character varying(36) NOT NULL
);


ALTER TABLE public.scope_policy OWNER TO postgres;

--
-- Name: server_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.server_config (
    server_config_key character varying(255) NOT NULL,
    value text NOT NULL,
    version integer DEFAULT 0
);


ALTER TABLE public.server_config OWNER TO postgres;

--
-- Name: user_attribute; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_attribute (
    name character varying(255) NOT NULL,
    value character varying(255),
    user_id character varying(36) NOT NULL,
    id character varying(36) DEFAULT 'sybase-needs-something-here'::character varying NOT NULL,
    long_value_hash bytea,
    long_value_hash_lower_case bytea,
    long_value text
);


ALTER TABLE public.user_attribute OWNER TO postgres;

--
-- Name: user_consent; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_consent (
    id character varying(36) NOT NULL,
    client_id character varying(255),
    user_id character varying(36) NOT NULL,
    created_date bigint,
    last_updated_date bigint,
    client_storage_provider character varying(36),
    external_client_id character varying(255)
);


ALTER TABLE public.user_consent OWNER TO postgres;

--
-- Name: user_consent_client_scope; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_consent_client_scope (
    user_consent_id character varying(36) NOT NULL,
    scope_id character varying(36) NOT NULL
);


ALTER TABLE public.user_consent_client_scope OWNER TO postgres;

--
-- Name: user_entity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_entity (
    id character varying(36) NOT NULL,
    email character varying(255),
    email_constraint character varying(255),
    email_verified boolean DEFAULT false NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    federation_link character varying(255),
    first_name character varying(255),
    last_name character varying(255),
    realm_id character varying(255),
    username character varying(255),
    created_timestamp bigint,
    service_account_client_link character varying(255),
    not_before integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.user_entity OWNER TO postgres;

--
-- Name: user_federation_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_federation_config (
    user_federation_provider_id character varying(36) NOT NULL,
    value character varying(255),
    name character varying(255) NOT NULL
);


ALTER TABLE public.user_federation_config OWNER TO postgres;

--
-- Name: user_federation_mapper; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_federation_mapper (
    id character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    federation_provider_id character varying(36) NOT NULL,
    federation_mapper_type character varying(255) NOT NULL,
    realm_id character varying(36) NOT NULL
);


ALTER TABLE public.user_federation_mapper OWNER TO postgres;

--
-- Name: user_federation_mapper_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_federation_mapper_config (
    user_federation_mapper_id character varying(36) NOT NULL,
    value character varying(255),
    name character varying(255) NOT NULL
);


ALTER TABLE public.user_federation_mapper_config OWNER TO postgres;

--
-- Name: user_federation_provider; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_federation_provider (
    id character varying(36) NOT NULL,
    changed_sync_period integer,
    display_name character varying(255),
    full_sync_period integer,
    last_sync integer,
    priority integer,
    provider_name character varying(255),
    realm_id character varying(36)
);


ALTER TABLE public.user_federation_provider OWNER TO postgres;

--
-- Name: user_group_membership; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_group_membership (
    group_id character varying(36) NOT NULL,
    user_id character varying(36) NOT NULL,
    membership_type character varying(255) NOT NULL
);


ALTER TABLE public.user_group_membership OWNER TO postgres;

--
-- Name: user_required_action; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_required_action (
    user_id character varying(36) NOT NULL,
    required_action character varying(255) DEFAULT ' '::character varying NOT NULL
);


ALTER TABLE public.user_required_action OWNER TO postgres;

--
-- Name: user_role_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_role_mapping (
    role_id character varying(255) NOT NULL,
    user_id character varying(36) NOT NULL
);


ALTER TABLE public.user_role_mapping OWNER TO postgres;

--
-- Name: web_origins; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.web_origins (
    client_id character varying(36) NOT NULL,
    value character varying(255) NOT NULL
);


ALTER TABLE public.web_origins OWNER TO postgres;

--
-- Name: workflow_state; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow_state (
    execution_id character varying(255) NOT NULL,
    resource_id character varying(255) NOT NULL,
    workflow_id character varying(255) NOT NULL,
    resource_type character varying(255),
    scheduled_step_id character varying(255),
    scheduled_step_timestamp bigint
);


ALTER TABLE public.workflow_state OWNER TO postgres;

--
-- Data for Name: admin_event_entity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_event_entity (id, admin_event_time, realm_id, operation_type, auth_realm_id, auth_client_id, auth_user_id, ip_address, resource_path, representation, error, resource_type, details_json) FROM stdin;
\.


--
-- Data for Name: associated_policy; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.associated_policy (policy_id, associated_policy_id) FROM stdin;
\.


--
-- Data for Name: authentication_execution; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.authentication_execution (id, alias, authenticator, realm_id, flow_id, requirement, priority, authenticator_flow, auth_flow_id, auth_config) FROM stdin;
910a91fd-4333-49fb-bacf-8a6cfa40a2c0	\N	auth-cookie	207d128c-bb74-4e7f-a3e4-f110b22d6159	bfa662ae-0fcb-4e58-9df8-7c8bafc4f46c	2	10	f	\N	\N
a6954896-f216-4e36-a306-0b99af41f5fa	\N	auth-spnego	207d128c-bb74-4e7f-a3e4-f110b22d6159	bfa662ae-0fcb-4e58-9df8-7c8bafc4f46c	3	20	f	\N	\N
5bf01ff4-4515-45d3-aa78-f7291cb0bfc9	\N	identity-provider-redirector	207d128c-bb74-4e7f-a3e4-f110b22d6159	bfa662ae-0fcb-4e58-9df8-7c8bafc4f46c	2	25	f	\N	\N
7a36f699-9880-4bce-9d8e-934de2773f9f	\N	\N	207d128c-bb74-4e7f-a3e4-f110b22d6159	bfa662ae-0fcb-4e58-9df8-7c8bafc4f46c	2	30	t	30a07fa8-1fba-4c23-9bdd-bea5c86068ea	\N
f364538a-7e48-44f0-9fe3-45b1c39f4eea	\N	auth-username-password-form	207d128c-bb74-4e7f-a3e4-f110b22d6159	30a07fa8-1fba-4c23-9bdd-bea5c86068ea	0	10	f	\N	\N
24a3da8f-4e4d-42b0-ba6d-a8dd931d4725	\N	\N	207d128c-bb74-4e7f-a3e4-f110b22d6159	30a07fa8-1fba-4c23-9bdd-bea5c86068ea	1	20	t	878a6c4d-c8ca-4a38-867d-889b7cee064e	\N
12696c67-b9f0-495e-a2d6-e85f670229b6	\N	conditional-user-configured	207d128c-bb74-4e7f-a3e4-f110b22d6159	878a6c4d-c8ca-4a38-867d-889b7cee064e	0	10	f	\N	\N
d23916ba-98d4-4d1f-bdde-59fd22f84173	\N	conditional-credential	207d128c-bb74-4e7f-a3e4-f110b22d6159	878a6c4d-c8ca-4a38-867d-889b7cee064e	0	20	f	\N	12d90226-51e3-4714-b4a5-7e4bb1e0f3a1
d9ce82a1-ba3f-4c6e-94bb-80a61e2a0046	\N	auth-otp-form	207d128c-bb74-4e7f-a3e4-f110b22d6159	878a6c4d-c8ca-4a38-867d-889b7cee064e	2	30	f	\N	\N
5779ebcc-17c4-48b9-a0ee-d781aaca19e6	\N	webauthn-authenticator	207d128c-bb74-4e7f-a3e4-f110b22d6159	878a6c4d-c8ca-4a38-867d-889b7cee064e	3	40	f	\N	\N
ed4a268f-43c3-400d-b1fa-e0084a9fbb18	\N	auth-recovery-authn-code-form	207d128c-bb74-4e7f-a3e4-f110b22d6159	878a6c4d-c8ca-4a38-867d-889b7cee064e	3	50	f	\N	\N
8eb649e5-3ecd-4a82-87fe-290eea506497	\N	direct-grant-validate-username	207d128c-bb74-4e7f-a3e4-f110b22d6159	b217f8a7-b7fe-4de3-9417-2b0921484bf7	0	10	f	\N	\N
b382cd41-dbce-44a4-a329-48f8b893c5e7	\N	direct-grant-validate-password	207d128c-bb74-4e7f-a3e4-f110b22d6159	b217f8a7-b7fe-4de3-9417-2b0921484bf7	0	20	f	\N	\N
66719bfc-b4bb-4ac4-83e9-11047cc20262	\N	\N	207d128c-bb74-4e7f-a3e4-f110b22d6159	b217f8a7-b7fe-4de3-9417-2b0921484bf7	1	30	t	b3f19211-7f66-4eab-9ff1-2cefd835e907	\N
9abe6cf2-77a2-4854-9892-d4b658dfbec0	\N	conditional-user-configured	207d128c-bb74-4e7f-a3e4-f110b22d6159	b3f19211-7f66-4eab-9ff1-2cefd835e907	0	10	f	\N	\N
3c1e5b9d-18a2-4a55-bb13-2469c832b606	\N	direct-grant-validate-otp	207d128c-bb74-4e7f-a3e4-f110b22d6159	b3f19211-7f66-4eab-9ff1-2cefd835e907	0	20	f	\N	\N
1c04fc65-3542-43a6-b7ea-cb1d98ab4e26	\N	registration-page-form	207d128c-bb74-4e7f-a3e4-f110b22d6159	8711b87f-e4b0-4b79-a230-74c1a5f6d6b1	0	10	t	9e878408-18d9-4089-b937-0caa4b6a8654	\N
d62c2832-3b65-4912-aa47-668e4e965c52	\N	registration-user-creation	207d128c-bb74-4e7f-a3e4-f110b22d6159	9e878408-18d9-4089-b937-0caa4b6a8654	0	20	f	\N	\N
edf33427-3f9e-4830-964b-209789ff91ee	\N	registration-password-action	207d128c-bb74-4e7f-a3e4-f110b22d6159	9e878408-18d9-4089-b937-0caa4b6a8654	0	50	f	\N	\N
cc9dcc42-be90-4d1d-bd7c-145917f2cf8a	\N	registration-recaptcha-action	207d128c-bb74-4e7f-a3e4-f110b22d6159	9e878408-18d9-4089-b937-0caa4b6a8654	3	60	f	\N	\N
bebfddc5-2b1f-4a2f-b72b-9b092298fac6	\N	registration-terms-and-conditions	207d128c-bb74-4e7f-a3e4-f110b22d6159	9e878408-18d9-4089-b937-0caa4b6a8654	3	70	f	\N	\N
09e51197-9751-4fd8-b117-f4418ec31a4b	\N	reset-credentials-choose-user	207d128c-bb74-4e7f-a3e4-f110b22d6159	4a7ecad5-d559-494c-a925-ab478496eacb	0	10	f	\N	\N
65bf920a-950d-4e39-8c6c-3c645bb8abbb	\N	reset-credential-email	207d128c-bb74-4e7f-a3e4-f110b22d6159	4a7ecad5-d559-494c-a925-ab478496eacb	0	20	f	\N	\N
7537025d-5077-4a1a-a7ec-e895387b1663	\N	reset-password	207d128c-bb74-4e7f-a3e4-f110b22d6159	4a7ecad5-d559-494c-a925-ab478496eacb	0	30	f	\N	\N
beb5391e-0a57-4be3-bdbd-ba0187cb42db	\N	\N	207d128c-bb74-4e7f-a3e4-f110b22d6159	4a7ecad5-d559-494c-a925-ab478496eacb	1	40	t	4064529e-06d4-452e-97b4-79ec95788c63	\N
3dd3782d-ce55-40dd-846a-917bee19547a	\N	conditional-user-configured	207d128c-bb74-4e7f-a3e4-f110b22d6159	4064529e-06d4-452e-97b4-79ec95788c63	0	10	f	\N	\N
4cf5f6b4-cd38-47d2-a8e2-8213d7a25b53	\N	reset-otp	207d128c-bb74-4e7f-a3e4-f110b22d6159	4064529e-06d4-452e-97b4-79ec95788c63	0	20	f	\N	\N
afba0487-1f0b-4f63-9c46-4d6775d3ede8	\N	client-secret	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ad8e03e-a629-4f31-b86a-80146e9c49e6	2	10	f	\N	\N
05027406-ca58-4687-aa6f-a77d59d7869e	\N	client-jwt	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ad8e03e-a629-4f31-b86a-80146e9c49e6	2	20	f	\N	\N
1f29023b-82f0-4f54-94cf-d94d3dd51101	\N	client-secret-jwt	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ad8e03e-a629-4f31-b86a-80146e9c49e6	2	30	f	\N	\N
e2c0d89a-38da-4159-8180-9e2e6dc7ed04	\N	client-x509	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ad8e03e-a629-4f31-b86a-80146e9c49e6	2	40	f	\N	\N
bfca91fe-eb9f-4cb5-885b-06edb73b6e57	\N	idp-review-profile	207d128c-bb74-4e7f-a3e4-f110b22d6159	13ea6b8b-af26-44ac-ad24-6e6bd7cdbc22	0	10	f	\N	0d7c9b01-b7b6-45a3-a5e0-00f4381083c3
0fd93193-3250-41e6-a28d-a1b46166a03f	\N	\N	207d128c-bb74-4e7f-a3e4-f110b22d6159	13ea6b8b-af26-44ac-ad24-6e6bd7cdbc22	0	20	t	3e582d34-d036-42de-825a-3605b5001478	\N
4fceee4d-e2c5-437d-9f94-35e56d9edba9	\N	idp-create-user-if-unique	207d128c-bb74-4e7f-a3e4-f110b22d6159	3e582d34-d036-42de-825a-3605b5001478	2	10	f	\N	a24c005b-40eb-4b72-b73b-e6c668c4fe34
7ab10c04-e5cf-4d60-8bb7-1697338939dc	\N	\N	207d128c-bb74-4e7f-a3e4-f110b22d6159	3e582d34-d036-42de-825a-3605b5001478	2	20	t	a2046e77-e779-4664-bb89-fb4fb408b038	\N
a9c74893-9c0a-4fe7-960f-8331acdeca5a	\N	idp-confirm-link	207d128c-bb74-4e7f-a3e4-f110b22d6159	a2046e77-e779-4664-bb89-fb4fb408b038	0	10	f	\N	\N
dc9c24a5-84ca-466e-83e8-515ef0d501b7	\N	\N	207d128c-bb74-4e7f-a3e4-f110b22d6159	a2046e77-e779-4664-bb89-fb4fb408b038	0	20	t	fa2073c9-a91b-4e1a-bcd7-4e5d355efdee	\N
3f339bd9-9c65-4247-9b7d-6dd2c2afca70	\N	idp-email-verification	207d128c-bb74-4e7f-a3e4-f110b22d6159	fa2073c9-a91b-4e1a-bcd7-4e5d355efdee	2	10	f	\N	\N
8a1c35b6-073c-4a8c-8041-0fadd7fdfdc4	\N	\N	207d128c-bb74-4e7f-a3e4-f110b22d6159	fa2073c9-a91b-4e1a-bcd7-4e5d355efdee	2	20	t	a7cef596-afa8-4319-9eb2-14e756929215	\N
1b189b57-1989-40c5-8751-81c1b3c7db90	\N	idp-username-password-form	207d128c-bb74-4e7f-a3e4-f110b22d6159	a7cef596-afa8-4319-9eb2-14e756929215	0	10	f	\N	\N
cddfd2fc-29f1-4bc9-a6ec-7249b8d60578	\N	\N	207d128c-bb74-4e7f-a3e4-f110b22d6159	a7cef596-afa8-4319-9eb2-14e756929215	1	20	t	c12236c5-aa69-4692-8a4b-d6c4895fc5b6	\N
73bf2b3d-539f-4181-8df4-9f8e829d6967	\N	conditional-user-configured	207d128c-bb74-4e7f-a3e4-f110b22d6159	c12236c5-aa69-4692-8a4b-d6c4895fc5b6	0	10	f	\N	\N
6b9cc131-d65e-486e-a3ed-d7fa8c858418	\N	conditional-credential	207d128c-bb74-4e7f-a3e4-f110b22d6159	c12236c5-aa69-4692-8a4b-d6c4895fc5b6	0	20	f	\N	597d5d9a-f324-4261-b83f-01fa1b333411
55b09307-e09d-4c00-876a-dddb2478d772	\N	auth-otp-form	207d128c-bb74-4e7f-a3e4-f110b22d6159	c12236c5-aa69-4692-8a4b-d6c4895fc5b6	2	30	f	\N	\N
a823cc9a-0a5a-44a5-af6a-44bb280e86b2	\N	webauthn-authenticator	207d128c-bb74-4e7f-a3e4-f110b22d6159	c12236c5-aa69-4692-8a4b-d6c4895fc5b6	3	40	f	\N	\N
e0bc815e-0a98-4519-849d-5fba915824cf	\N	auth-recovery-authn-code-form	207d128c-bb74-4e7f-a3e4-f110b22d6159	c12236c5-aa69-4692-8a4b-d6c4895fc5b6	3	50	f	\N	\N
0a731bfd-80ce-4ea3-a79a-a60a34be8f57	\N	http-basic-authenticator	207d128c-bb74-4e7f-a3e4-f110b22d6159	e83accf3-b7a8-4632-a7e2-8f83cb6b5a29	0	10	f	\N	\N
08f8861f-8a67-453a-b0a2-68b28b3282a7	\N	docker-http-basic-authenticator	207d128c-bb74-4e7f-a3e4-f110b22d6159	7a9e037a-25a6-4def-90a9-bd00c6bf380b	0	10	f	\N	\N
5d64cabf-85f7-4cd1-9a9e-f1314395caa6	\N	auth-cookie	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	a4530a77-3919-4a8e-9cfc-d663a4e0165a	2	10	f	\N	\N
d4ee6fe9-2fe8-493d-95e3-01fd503c308a	\N	auth-spnego	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	a4530a77-3919-4a8e-9cfc-d663a4e0165a	3	20	f	\N	\N
179036d4-164d-4c2c-8cfc-dccc31028d24	\N	identity-provider-redirector	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	a4530a77-3919-4a8e-9cfc-d663a4e0165a	2	25	f	\N	\N
6d4838c5-c13f-4f9e-a240-9c3b3784bbe6	\N	\N	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	a4530a77-3919-4a8e-9cfc-d663a4e0165a	2	30	t	ff496080-5f66-4828-9b37-3a3cdc78615c	\N
2a3f0402-8836-4a66-92f3-fff648fda27b	\N	auth-username-password-form	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	ff496080-5f66-4828-9b37-3a3cdc78615c	0	10	f	\N	\N
990f2b45-7e49-4dbb-924d-da87c482b97f	\N	\N	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	ff496080-5f66-4828-9b37-3a3cdc78615c	1	20	t	851eb3ac-1fe6-471d-8a50-5b26a6d1b2f9	\N
2680c254-ba51-497b-9e81-2ad1c9c8fdac	\N	conditional-user-configured	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	851eb3ac-1fe6-471d-8a50-5b26a6d1b2f9	0	10	f	\N	\N
00754d78-ec45-42d9-b145-6d129817ead0	\N	conditional-credential	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	851eb3ac-1fe6-471d-8a50-5b26a6d1b2f9	0	20	f	\N	7c1a9fa5-8a50-4b98-b7f1-2a5a7d7b5e6c
19829132-d17d-4557-8dc4-f13e1e0f5f18	\N	auth-otp-form	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	851eb3ac-1fe6-471d-8a50-5b26a6d1b2f9	2	30	f	\N	\N
75ea6ab6-2ea3-4378-aa91-2fbff808c182	\N	webauthn-authenticator	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	851eb3ac-1fe6-471d-8a50-5b26a6d1b2f9	3	40	f	\N	\N
9ddff4a0-0baa-40c0-b2fd-497b1d405b8f	\N	auth-recovery-authn-code-form	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	851eb3ac-1fe6-471d-8a50-5b26a6d1b2f9	3	50	f	\N	\N
ea6cd6d1-937d-496f-8af9-7e5eb08987e1	\N	\N	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	a4530a77-3919-4a8e-9cfc-d663a4e0165a	2	26	t	0e678d2d-37a8-4066-a4db-f94d5c367a65	\N
04e8db2e-d2b7-4c6b-bd42-d9d072527944	\N	\N	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	0e678d2d-37a8-4066-a4db-f94d5c367a65	1	10	t	912c04d3-ab84-4055-8529-2d04f49c9fc6	\N
d0c36b6e-cfcb-4e8e-a5c7-259cded6a5aa	\N	conditional-user-configured	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	912c04d3-ab84-4055-8529-2d04f49c9fc6	0	10	f	\N	\N
0b7fcadf-1d76-46ce-aca1-e4780623d322	\N	organization	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	912c04d3-ab84-4055-8529-2d04f49c9fc6	2	20	f	\N	\N
f347e3f0-f44e-4842-a159-7f89524ffc6d	\N	direct-grant-validate-username	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	0bb4f287-0170-4fcc-83c4-0a16073f7dd4	0	10	f	\N	\N
349acc3f-0162-4b49-bfeb-5a7416aaffa4	\N	direct-grant-validate-password	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	0bb4f287-0170-4fcc-83c4-0a16073f7dd4	0	20	f	\N	\N
4de3f29e-bc70-4888-95a8-d72490622441	\N	\N	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	0bb4f287-0170-4fcc-83c4-0a16073f7dd4	1	30	t	f1e525a4-1446-4dc6-aa6e-27a537013767	\N
703b4891-5871-4639-9004-d3dd634853a8	\N	conditional-user-configured	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	f1e525a4-1446-4dc6-aa6e-27a537013767	0	10	f	\N	\N
d513df4c-a1d9-409a-a088-cff8b79d44fe	\N	direct-grant-validate-otp	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	f1e525a4-1446-4dc6-aa6e-27a537013767	0	20	f	\N	\N
3882b337-3b7b-4ec4-8b2e-4f0daa0f9078	\N	registration-page-form	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	20160cc4-f452-437f-95c1-daf7d1397315	0	10	t	318d7457-0572-4860-8310-49eb85c06bcf	\N
142d207e-1781-4c2d-b3b6-ab515046879e	\N	registration-user-creation	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	318d7457-0572-4860-8310-49eb85c06bcf	0	20	f	\N	\N
4b17e701-c114-4631-9beb-0be0e3222782	\N	registration-password-action	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	318d7457-0572-4860-8310-49eb85c06bcf	0	50	f	\N	\N
14f3f98d-5536-4315-8d23-549e47fb49c6	\N	registration-recaptcha-action	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	318d7457-0572-4860-8310-49eb85c06bcf	3	60	f	\N	\N
ef93c2ec-6905-474b-8b25-f15cfb7f9853	\N	registration-terms-and-conditions	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	318d7457-0572-4860-8310-49eb85c06bcf	3	70	f	\N	\N
80ddd506-4cfa-40f3-bb23-7b8f52b13352	\N	reset-credentials-choose-user	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	df09f8ba-2c5f-4328-aae7-56684bacc86a	0	10	f	\N	\N
2076951a-6814-4a2f-a5d4-766d904e9354	\N	reset-credential-email	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	df09f8ba-2c5f-4328-aae7-56684bacc86a	0	20	f	\N	\N
059a357e-acef-4b0c-ac43-d085be388d00	\N	reset-password	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	df09f8ba-2c5f-4328-aae7-56684bacc86a	0	30	f	\N	\N
a932479e-6a2c-412d-8a74-bcec0ba90487	\N	\N	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	df09f8ba-2c5f-4328-aae7-56684bacc86a	1	40	t	724414fe-4707-40e9-be1d-22e0e8cb2cce	\N
616ff80e-d2c8-4e89-a8ba-ba77793f5953	\N	conditional-user-configured	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	724414fe-4707-40e9-be1d-22e0e8cb2cce	0	10	f	\N	\N
581bb6ba-1532-47d6-9175-2b4d3183400a	\N	reset-otp	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	724414fe-4707-40e9-be1d-22e0e8cb2cce	0	20	f	\N	\N
f199bfa2-84d5-4183-a658-7ed86788de91	\N	client-secret	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	e202c49b-5a43-4085-9a13-f2826fe2e33a	2	10	f	\N	\N
42919483-9505-4806-a888-1398b10c0941	\N	client-jwt	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	e202c49b-5a43-4085-9a13-f2826fe2e33a	2	20	f	\N	\N
893e56ee-5119-448d-9833-3845c3741cf4	\N	client-secret-jwt	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	e202c49b-5a43-4085-9a13-f2826fe2e33a	2	30	f	\N	\N
b650b3e2-8a18-4679-9213-b950c7fe488f	\N	client-x509	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	e202c49b-5a43-4085-9a13-f2826fe2e33a	2	40	f	\N	\N
93d459bd-bb39-4d77-8267-310b17745c18	\N	idp-review-profile	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	46080925-c3c5-44c5-aada-601d3cf538e2	0	10	f	\N	b03c882b-995c-4477-b0e0-064c4ec338d9
f3f19128-c6fc-44d4-8bcc-82127e882532	\N	\N	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	46080925-c3c5-44c5-aada-601d3cf538e2	0	20	t	6870efec-870b-4494-b1b1-3ea256db1b0c	\N
f1390f23-efcd-4197-ae2d-7e25cc437a2b	\N	idp-create-user-if-unique	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	6870efec-870b-4494-b1b1-3ea256db1b0c	2	10	f	\N	a4853c12-f71e-4c4a-9fa4-3fc5a4bbfa34
ed7e3923-5ff0-4a17-9668-f0c2eda1db27	\N	\N	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	6870efec-870b-4494-b1b1-3ea256db1b0c	2	20	t	f26f1111-aae2-42f9-b835-4c95f0532d7c	\N
d61e75d1-8e46-4d45-a27a-48316a0e1727	\N	idp-confirm-link	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	f26f1111-aae2-42f9-b835-4c95f0532d7c	0	10	f	\N	\N
b884d39f-12b4-4c0a-b0c4-a14afeab8bd5	\N	\N	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	f26f1111-aae2-42f9-b835-4c95f0532d7c	0	20	t	b24a7d5f-188c-4b7c-81fb-218252b68929	\N
e9baf023-bc07-4899-a508-bdab9c19229f	\N	idp-email-verification	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	b24a7d5f-188c-4b7c-81fb-218252b68929	2	10	f	\N	\N
af849e6c-3c86-4798-b290-acb5107fcc85	\N	\N	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	b24a7d5f-188c-4b7c-81fb-218252b68929	2	20	t	c6b01ee8-3c61-4c4e-9372-e05c6241cdec	\N
8bf18ce0-2f13-46dd-a84f-1c0eeb945139	\N	idp-username-password-form	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c6b01ee8-3c61-4c4e-9372-e05c6241cdec	0	10	f	\N	\N
c7f91cd3-d789-4f73-b60b-b2f449a38764	\N	\N	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c6b01ee8-3c61-4c4e-9372-e05c6241cdec	1	20	t	9a6cf07c-f26a-4efb-b101-91f2012f2a51	\N
1c0bd9f6-c074-432a-b96f-d5cb728c7afb	\N	conditional-user-configured	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	9a6cf07c-f26a-4efb-b101-91f2012f2a51	0	10	f	\N	\N
71d86cc7-1678-45b5-8662-9f31835de64f	\N	conditional-credential	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	9a6cf07c-f26a-4efb-b101-91f2012f2a51	0	20	f	\N	556ea18d-8bbb-4d44-b9c9-6c216288c8c3
694d3085-9e87-4bb4-93f8-36a89428c77c	\N	auth-otp-form	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	9a6cf07c-f26a-4efb-b101-91f2012f2a51	2	30	f	\N	\N
c9b56308-51a6-4270-b289-1b05f81bea47	\N	webauthn-authenticator	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	9a6cf07c-f26a-4efb-b101-91f2012f2a51	3	40	f	\N	\N
7216b560-efb3-445c-8a98-0e1645b22c7e	\N	auth-recovery-authn-code-form	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	9a6cf07c-f26a-4efb-b101-91f2012f2a51	3	50	f	\N	\N
1506bcae-fe31-4f1b-aa4c-c840fb9f0f86	\N	\N	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	46080925-c3c5-44c5-aada-601d3cf538e2	1	60	t	f5ea53a2-4ed9-4cce-a8d7-e0ca3bc40b3e	\N
8572bfab-0d16-4836-bd7f-41574ee8856b	\N	conditional-user-configured	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	f5ea53a2-4ed9-4cce-a8d7-e0ca3bc40b3e	0	10	f	\N	\N
a7f9f5c8-2ca3-4a4c-8bbf-7d5d55d404a6	\N	idp-add-organization-member	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	f5ea53a2-4ed9-4cce-a8d7-e0ca3bc40b3e	0	20	f	\N	\N
b9798a9a-a740-49bb-850b-11da32ddb95e	\N	http-basic-authenticator	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	5cfbde75-a94f-4712-bb2c-5b7faf79e42f	0	10	f	\N	\N
e7f50d4c-5540-46b9-93b3-71a1484b20b0	\N	docker-http-basic-authenticator	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	11537926-a252-412d-b0fd-e864c4421285	0	10	f	\N	\N
\.


--
-- Data for Name: authentication_flow; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.authentication_flow (id, alias, description, realm_id, provider_id, top_level, built_in) FROM stdin;
bfa662ae-0fcb-4e58-9df8-7c8bafc4f46c	browser	Browser based authentication	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	t	t
30a07fa8-1fba-4c23-9bdd-bea5c86068ea	forms	Username, password, otp and other auth forms.	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	f	t
878a6c4d-c8ca-4a38-867d-889b7cee064e	Browser - Conditional 2FA	Flow to determine if any 2FA is required for the authentication	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	f	t
b217f8a7-b7fe-4de3-9417-2b0921484bf7	direct grant	OpenID Connect Resource Owner Grant	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	t	t
b3f19211-7f66-4eab-9ff1-2cefd835e907	Direct Grant - Conditional OTP	Flow to determine if the OTP is required for the authentication	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	f	t
8711b87f-e4b0-4b79-a230-74c1a5f6d6b1	registration	Registration flow	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	t	t
9e878408-18d9-4089-b937-0caa4b6a8654	registration form	Registration form	207d128c-bb74-4e7f-a3e4-f110b22d6159	form-flow	f	t
4a7ecad5-d559-494c-a925-ab478496eacb	reset credentials	Reset credentials for a user if they forgot their password or something	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	t	t
4064529e-06d4-452e-97b4-79ec95788c63	Reset - Conditional OTP	Flow to determine if the OTP should be reset or not. Set to REQUIRED to force.	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	f	t
5ad8e03e-a629-4f31-b86a-80146e9c49e6	clients	Base authentication for clients	207d128c-bb74-4e7f-a3e4-f110b22d6159	client-flow	t	t
13ea6b8b-af26-44ac-ad24-6e6bd7cdbc22	first broker login	Actions taken after first broker login with identity provider account, which is not yet linked to any Keycloak account	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	t	t
3e582d34-d036-42de-825a-3605b5001478	User creation or linking	Flow for the existing/non-existing user alternatives	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	f	t
a2046e77-e779-4664-bb89-fb4fb408b038	Handle Existing Account	Handle what to do if there is existing account with same email/username like authenticated identity provider	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	f	t
fa2073c9-a91b-4e1a-bcd7-4e5d355efdee	Account verification options	Method with which to verify the existing account	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	f	t
a7cef596-afa8-4319-9eb2-14e756929215	Verify Existing Account by Re-authentication	Reauthentication of existing account	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	f	t
c12236c5-aa69-4692-8a4b-d6c4895fc5b6	First broker login - Conditional 2FA	Flow to determine if any 2FA is required for the authentication	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	f	t
e83accf3-b7a8-4632-a7e2-8f83cb6b5a29	saml ecp	SAML ECP Profile Authentication Flow	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	t	t
7a9e037a-25a6-4def-90a9-bd00c6bf380b	docker auth	Used by Docker clients to authenticate against the IDP	207d128c-bb74-4e7f-a3e4-f110b22d6159	basic-flow	t	t
a4530a77-3919-4a8e-9cfc-d663a4e0165a	browser	Browser based authentication	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	t	t
ff496080-5f66-4828-9b37-3a3cdc78615c	forms	Username, password, otp and other auth forms.	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	f	t
851eb3ac-1fe6-471d-8a50-5b26a6d1b2f9	Browser - Conditional 2FA	Flow to determine if any 2FA is required for the authentication	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	f	t
0e678d2d-37a8-4066-a4db-f94d5c367a65	Organization	\N	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	f	t
912c04d3-ab84-4055-8529-2d04f49c9fc6	Browser - Conditional Organization	Flow to determine if the organization identity-first login is to be used	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	f	t
0bb4f287-0170-4fcc-83c4-0a16073f7dd4	direct grant	OpenID Connect Resource Owner Grant	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	t	t
f1e525a4-1446-4dc6-aa6e-27a537013767	Direct Grant - Conditional OTP	Flow to determine if the OTP is required for the authentication	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	f	t
20160cc4-f452-437f-95c1-daf7d1397315	registration	Registration flow	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	t	t
318d7457-0572-4860-8310-49eb85c06bcf	registration form	Registration form	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	form-flow	f	t
df09f8ba-2c5f-4328-aae7-56684bacc86a	reset credentials	Reset credentials for a user if they forgot their password or something	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	t	t
724414fe-4707-40e9-be1d-22e0e8cb2cce	Reset - Conditional OTP	Flow to determine if the OTP should be reset or not. Set to REQUIRED to force.	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	f	t
e202c49b-5a43-4085-9a13-f2826fe2e33a	clients	Base authentication for clients	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	client-flow	t	t
46080925-c3c5-44c5-aada-601d3cf538e2	first broker login	Actions taken after first broker login with identity provider account, which is not yet linked to any Keycloak account	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	t	t
6870efec-870b-4494-b1b1-3ea256db1b0c	User creation or linking	Flow for the existing/non-existing user alternatives	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	f	t
f26f1111-aae2-42f9-b835-4c95f0532d7c	Handle Existing Account	Handle what to do if there is existing account with same email/username like authenticated identity provider	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	f	t
b24a7d5f-188c-4b7c-81fb-218252b68929	Account verification options	Method with which to verify the existing account	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	f	t
c6b01ee8-3c61-4c4e-9372-e05c6241cdec	Verify Existing Account by Re-authentication	Reauthentication of existing account	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	f	t
9a6cf07c-f26a-4efb-b101-91f2012f2a51	First broker login - Conditional 2FA	Flow to determine if any 2FA is required for the authentication	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	f	t
f5ea53a2-4ed9-4cce-a8d7-e0ca3bc40b3e	First Broker Login - Conditional Organization	Flow to determine if the authenticator that adds organization members is to be used	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	f	t
5cfbde75-a94f-4712-bb2c-5b7faf79e42f	saml ecp	SAML ECP Profile Authentication Flow	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	t	t
11537926-a252-412d-b0fd-e864c4421285	docker auth	Used by Docker clients to authenticate against the IDP	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	basic-flow	t	t
\.


--
-- Data for Name: authenticator_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.authenticator_config (id, alias, realm_id) FROM stdin;
12d90226-51e3-4714-b4a5-7e4bb1e0f3a1	browser-conditional-credential	207d128c-bb74-4e7f-a3e4-f110b22d6159
0d7c9b01-b7b6-45a3-a5e0-00f4381083c3	review profile config	207d128c-bb74-4e7f-a3e4-f110b22d6159
a24c005b-40eb-4b72-b73b-e6c668c4fe34	create unique user config	207d128c-bb74-4e7f-a3e4-f110b22d6159
597d5d9a-f324-4261-b83f-01fa1b333411	first-broker-login-conditional-credential	207d128c-bb74-4e7f-a3e4-f110b22d6159
7c1a9fa5-8a50-4b98-b7f1-2a5a7d7b5e6c	browser-conditional-credential	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a
b03c882b-995c-4477-b0e0-064c4ec338d9	review profile config	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a
a4853c12-f71e-4c4a-9fa4-3fc5a4bbfa34	create unique user config	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a
556ea18d-8bbb-4d44-b9c9-6c216288c8c3	first-broker-login-conditional-credential	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a
\.


--
-- Data for Name: authenticator_config_entry; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.authenticator_config_entry (authenticator_id, value, name) FROM stdin;
0d7c9b01-b7b6-45a3-a5e0-00f4381083c3	missing	update.profile.on.first.login
12d90226-51e3-4714-b4a5-7e4bb1e0f3a1	webauthn-passwordless	credentials
597d5d9a-f324-4261-b83f-01fa1b333411	webauthn-passwordless	credentials
a24c005b-40eb-4b72-b73b-e6c668c4fe34	false	require.password.update.after.registration
556ea18d-8bbb-4d44-b9c9-6c216288c8c3	webauthn-passwordless	credentials
7c1a9fa5-8a50-4b98-b7f1-2a5a7d7b5e6c	webauthn-passwordless	credentials
a4853c12-f71e-4c4a-9fa4-3fc5a4bbfa34	false	require.password.update.after.registration
b03c882b-995c-4477-b0e0-064c4ec338d9	missing	update.profile.on.first.login
\.


--
-- Data for Name: broker_link; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.broker_link (identity_provider, storage_provider_id, realm_id, broker_user_id, broker_username, token, user_id) FROM stdin;
\.


--
-- Data for Name: client; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client (id, enabled, full_scope_allowed, client_id, not_before, public_client, secret, base_url, bearer_only, management_url, surrogate_auth_required, realm_id, protocol, node_rereg_timeout, frontchannel_logout, consent_required, name, service_accounts_enabled, client_authenticator_type, root_url, description, registration_token, standard_flow_enabled, implicit_flow_enabled, direct_access_grants_enabled, always_display_in_console) FROM stdin;
ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	f	master-realm	0	f	\N	\N	t	\N	f	207d128c-bb74-4e7f-a3e4-f110b22d6159	\N	0	f	f	master Realm	f	client-secret	\N	\N	\N	t	f	f	f
c05b475f-598d-429b-80d1-276ca9e572a0	t	f	account	0	t	\N	/realms/master/account/	f	\N	f	207d128c-bb74-4e7f-a3e4-f110b22d6159	openid-connect	0	f	f	${client_account}	f	client-secret	${authBaseUrl}	\N	\N	t	f	f	f
a9243c21-3223-4b2a-92e4-67ebf2d2e151	t	f	account-console	0	t	\N	/realms/master/account/	f	\N	f	207d128c-bb74-4e7f-a3e4-f110b22d6159	openid-connect	0	f	f	${client_account-console}	f	client-secret	${authBaseUrl}	\N	\N	t	f	f	f
339d7cac-6002-4453-9a60-2e10d36ba29c	t	f	broker	0	f	\N	\N	t	\N	f	207d128c-bb74-4e7f-a3e4-f110b22d6159	openid-connect	0	f	f	${client_broker}	f	client-secret	\N	\N	\N	t	f	f	f
6b842f27-4404-4596-ab7a-26c56ffb44b0	t	t	security-admin-console	0	t	\N	/admin/master/console/	f	\N	f	207d128c-bb74-4e7f-a3e4-f110b22d6159	openid-connect	0	f	f	${client_security-admin-console}	f	client-secret	${authAdminUrl}	\N	\N	t	f	f	f
e8f8b34d-3713-42bd-bb36-3b3eb16de6e7	t	t	admin-cli	0	t	\N	\N	f	\N	f	207d128c-bb74-4e7f-a3e4-f110b22d6159	openid-connect	0	f	f	${client_admin-cli}	f	client-secret	\N	\N	\N	f	f	t	f
5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	f	restapi-realm	0	f	\N	\N	t	\N	f	207d128c-bb74-4e7f-a3e4-f110b22d6159	\N	0	f	f	restapi Realm	f	client-secret	\N	\N	\N	t	f	f	f
c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	f	realm-management	0	f	\N	\N	t	\N	f	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	openid-connect	0	f	f	${client_realm-management}	f	client-secret	\N	\N	\N	t	f	f	f
fd19d9b9-ed5b-4fbb-a325-9d49639a74db	t	f	account	0	t	\N	/realms/restapi/account/	f	\N	f	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	openid-connect	0	f	f	${client_account}	f	client-secret	${authBaseUrl}	\N	\N	t	f	f	f
60044973-1f42-41b3-a8ed-dcd5ae7d763c	t	f	account-console	0	t	\N	/realms/restapi/account/	f	\N	f	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	openid-connect	0	f	f	${client_account-console}	f	client-secret	${authBaseUrl}	\N	\N	t	f	f	f
fbd3dabc-3a1a-42da-9a5d-a3bd488842f2	t	f	broker	0	f	\N	\N	t	\N	f	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	openid-connect	0	f	f	${client_broker}	f	client-secret	\N	\N	\N	t	f	f	f
b6f89aba-b213-40cd-abbb-9f80c8e88318	t	t	security-admin-console	0	t	\N	/admin/restapi/console/	f	\N	f	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	openid-connect	0	f	f	${client_security-admin-console}	f	client-secret	${authAdminUrl}	\N	\N	t	f	f	f
5a5f209b-441a-47bc-816d-523d86514cb7	t	t	admin-cli	0	t	\N	\N	f	\N	f	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	openid-connect	0	f	f	${client_admin-cli}	f	client-secret	\N	\N	\N	f	f	t	f
b1a24523-e2b5-4cc6-af64-8364f8882e32	t	t	fastapi	0	t	\N		f		f	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	openid-connect	-1	t	f		f	client-secret			\N	t	f	t	f
\.


--
-- Data for Name: client_attributes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client_attributes (client_id, name, value) FROM stdin;
c05b475f-598d-429b-80d1-276ca9e572a0	post.logout.redirect.uris	+
a9243c21-3223-4b2a-92e4-67ebf2d2e151	post.logout.redirect.uris	+
a9243c21-3223-4b2a-92e4-67ebf2d2e151	pkce.code.challenge.method	S256
6b842f27-4404-4596-ab7a-26c56ffb44b0	post.logout.redirect.uris	+
6b842f27-4404-4596-ab7a-26c56ffb44b0	pkce.code.challenge.method	S256
6b842f27-4404-4596-ab7a-26c56ffb44b0	client.use.lightweight.access.token.enabled	true
e8f8b34d-3713-42bd-bb36-3b3eb16de6e7	client.use.lightweight.access.token.enabled	true
fd19d9b9-ed5b-4fbb-a325-9d49639a74db	post.logout.redirect.uris	+
60044973-1f42-41b3-a8ed-dcd5ae7d763c	post.logout.redirect.uris	+
60044973-1f42-41b3-a8ed-dcd5ae7d763c	pkce.code.challenge.method	S256
b6f89aba-b213-40cd-abbb-9f80c8e88318	post.logout.redirect.uris	+
b6f89aba-b213-40cd-abbb-9f80c8e88318	pkce.code.challenge.method	S256
b6f89aba-b213-40cd-abbb-9f80c8e88318	client.use.lightweight.access.token.enabled	true
5a5f209b-441a-47bc-816d-523d86514cb7	client.use.lightweight.access.token.enabled	true
b1a24523-e2b5-4cc6-af64-8364f8882e32	standard.token.exchange.enabled	false
b1a24523-e2b5-4cc6-af64-8364f8882e32	oauth2.device.authorization.grant.enabled	false
b1a24523-e2b5-4cc6-af64-8364f8882e32	oidc.ciba.grant.enabled	false
b1a24523-e2b5-4cc6-af64-8364f8882e32	dpop.bound.access.tokens	false
b1a24523-e2b5-4cc6-af64-8364f8882e32	oauth2.jwt.authorization.grant.enabled	false
b1a24523-e2b5-4cc6-af64-8364f8882e32	backchannel.logout.session.required	true
b1a24523-e2b5-4cc6-af64-8364f8882e32	backchannel.logout.revoke.offline.tokens	false
b1a24523-e2b5-4cc6-af64-8364f8882e32	realm_client	false
b1a24523-e2b5-4cc6-af64-8364f8882e32	display.on.consent.screen	false
b1a24523-e2b5-4cc6-af64-8364f8882e32	frontchannel.logout.session.required	true
b1a24523-e2b5-4cc6-af64-8364f8882e32	logout.confirmation.enabled	false
b1a24523-e2b5-4cc6-af64-8364f8882e32	client.secret.creation.time	1777599602
b1a24523-e2b5-4cc6-af64-8364f8882e32	use.jwks.url	true
\.


--
-- Data for Name: client_auth_flow_bindings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client_auth_flow_bindings (client_id, flow_id, binding_name) FROM stdin;
\.


--
-- Data for Name: client_initial_access; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client_initial_access (id, realm_id, "timestamp", expiration, count, remaining_count) FROM stdin;
\.


--
-- Data for Name: client_node_registrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client_node_registrations (client_id, value, name) FROM stdin;
\.


--
-- Data for Name: client_scope; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client_scope (id, name, realm_id, description, protocol) FROM stdin;
ead5eaa8-b5a4-4021-afc2-12cc33da2c2d	offline_access	207d128c-bb74-4e7f-a3e4-f110b22d6159	OpenID Connect built-in scope: offline_access	openid-connect
a2b7fe0b-7d98-486d-8ee0-12bd009c3154	role_list	207d128c-bb74-4e7f-a3e4-f110b22d6159	SAML role list	saml
a4f1760c-83a0-4ecc-a455-f2dfa4fd2eef	saml_organization	207d128c-bb74-4e7f-a3e4-f110b22d6159	Organization Membership	saml
d9d47570-32cf-44eb-a329-93be5d5dbd9e	profile	207d128c-bb74-4e7f-a3e4-f110b22d6159	OpenID Connect built-in scope: profile	openid-connect
80597c7a-c1f9-44ab-8f15-31c36ca51cd3	email	207d128c-bb74-4e7f-a3e4-f110b22d6159	OpenID Connect built-in scope: email	openid-connect
67e3ddb1-a977-4fb8-a5c6-a57dd8804cda	address	207d128c-bb74-4e7f-a3e4-f110b22d6159	OpenID Connect built-in scope: address	openid-connect
161747f8-23e3-4e95-a21b-d3675be338e5	phone	207d128c-bb74-4e7f-a3e4-f110b22d6159	OpenID Connect built-in scope: phone	openid-connect
0d9f8c42-cbda-4fa9-8f53-0af2c9dfdde3	roles	207d128c-bb74-4e7f-a3e4-f110b22d6159	OpenID Connect scope for add user roles to the access token	openid-connect
c54f2ec3-1987-4cd0-9dbd-5564abb04e76	web-origins	207d128c-bb74-4e7f-a3e4-f110b22d6159	OpenID Connect scope for add allowed web origins to the access token	openid-connect
8a10c45f-537f-4783-8cc1-34e42626984a	microprofile-jwt	207d128c-bb74-4e7f-a3e4-f110b22d6159	Microprofile - JWT built-in scope	openid-connect
1e3e93ad-a248-44ae-82cb-be42caf1083a	acr	207d128c-bb74-4e7f-a3e4-f110b22d6159	OpenID Connect scope for add acr (authentication context class reference) to the token	openid-connect
5af68cc7-fab6-4258-b5b6-2feb36df3e2a	basic	207d128c-bb74-4e7f-a3e4-f110b22d6159	OpenID Connect scope for add all basic claims to the token	openid-connect
6013a609-8730-4c61-affe-99d3535445ec	service_account	207d128c-bb74-4e7f-a3e4-f110b22d6159	Specific scope for a client enabled for service accounts	openid-connect
88dd4199-b555-4c54-90ad-d87376de9482	organization	207d128c-bb74-4e7f-a3e4-f110b22d6159	Additional claims about the organization a subject belongs to	openid-connect
0718e728-fb10-429c-be7b-795e7dd0a842	offline_access	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	OpenID Connect built-in scope: offline_access	openid-connect
3b010f52-041c-4a7a-9eb9-ae6bab3b9bd1	role_list	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	SAML role list	saml
0492b33d-d297-4009-9bdd-5f1dcf782cf3	saml_organization	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	Organization Membership	saml
fd53d63e-abd9-4923-928a-9fba44904b06	profile	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	OpenID Connect built-in scope: profile	openid-connect
7a56b774-281d-4a64-8c54-2433df97f56f	email	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	OpenID Connect built-in scope: email	openid-connect
d5d4bb63-9d28-4a83-b2ad-ea18d77e3cde	address	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	OpenID Connect built-in scope: address	openid-connect
f5731461-3ade-4754-8d03-799394e6b501	phone	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	OpenID Connect built-in scope: phone	openid-connect
824686d7-ec63-4db4-86ee-daaf860b3340	roles	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	OpenID Connect scope for add user roles to the access token	openid-connect
c72c60f1-de1d-46d7-917d-952d8cb6cb17	web-origins	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	OpenID Connect scope for add allowed web origins to the access token	openid-connect
eb6c56b3-7c18-4f2d-8d01-d4c2fae36bda	microprofile-jwt	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	Microprofile - JWT built-in scope	openid-connect
36504493-b5fa-4be1-8c55-9f9a07182a28	acr	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	OpenID Connect scope for add acr (authentication context class reference) to the token	openid-connect
a63a51b4-5482-4c17-98fa-621abb8905cc	basic	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	OpenID Connect scope for add all basic claims to the token	openid-connect
803f155a-8316-4be0-8ef9-4f23ddc3c2bf	service_account	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	Specific scope for a client enabled for service accounts	openid-connect
7d4db986-2070-44e5-9096-48d2f4a85f47	organization	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	Additional claims about the organization a subject belongs to	openid-connect
\.


--
-- Data for Name: client_scope_attributes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client_scope_attributes (scope_id, value, name) FROM stdin;
ead5eaa8-b5a4-4021-afc2-12cc33da2c2d	true	display.on.consent.screen
ead5eaa8-b5a4-4021-afc2-12cc33da2c2d	${offlineAccessScopeConsentText}	consent.screen.text
a2b7fe0b-7d98-486d-8ee0-12bd009c3154	true	display.on.consent.screen
a2b7fe0b-7d98-486d-8ee0-12bd009c3154	${samlRoleListScopeConsentText}	consent.screen.text
a4f1760c-83a0-4ecc-a455-f2dfa4fd2eef	false	display.on.consent.screen
d9d47570-32cf-44eb-a329-93be5d5dbd9e	true	display.on.consent.screen
d9d47570-32cf-44eb-a329-93be5d5dbd9e	${profileScopeConsentText}	consent.screen.text
d9d47570-32cf-44eb-a329-93be5d5dbd9e	true	include.in.token.scope
80597c7a-c1f9-44ab-8f15-31c36ca51cd3	true	display.on.consent.screen
80597c7a-c1f9-44ab-8f15-31c36ca51cd3	${emailScopeConsentText}	consent.screen.text
80597c7a-c1f9-44ab-8f15-31c36ca51cd3	true	include.in.token.scope
67e3ddb1-a977-4fb8-a5c6-a57dd8804cda	true	display.on.consent.screen
67e3ddb1-a977-4fb8-a5c6-a57dd8804cda	${addressScopeConsentText}	consent.screen.text
67e3ddb1-a977-4fb8-a5c6-a57dd8804cda	true	include.in.token.scope
161747f8-23e3-4e95-a21b-d3675be338e5	true	display.on.consent.screen
161747f8-23e3-4e95-a21b-d3675be338e5	${phoneScopeConsentText}	consent.screen.text
161747f8-23e3-4e95-a21b-d3675be338e5	true	include.in.token.scope
0d9f8c42-cbda-4fa9-8f53-0af2c9dfdde3	true	display.on.consent.screen
0d9f8c42-cbda-4fa9-8f53-0af2c9dfdde3	${rolesScopeConsentText}	consent.screen.text
0d9f8c42-cbda-4fa9-8f53-0af2c9dfdde3	false	include.in.token.scope
c54f2ec3-1987-4cd0-9dbd-5564abb04e76	false	display.on.consent.screen
c54f2ec3-1987-4cd0-9dbd-5564abb04e76		consent.screen.text
c54f2ec3-1987-4cd0-9dbd-5564abb04e76	false	include.in.token.scope
8a10c45f-537f-4783-8cc1-34e42626984a	false	display.on.consent.screen
8a10c45f-537f-4783-8cc1-34e42626984a	true	include.in.token.scope
1e3e93ad-a248-44ae-82cb-be42caf1083a	false	display.on.consent.screen
1e3e93ad-a248-44ae-82cb-be42caf1083a	false	include.in.token.scope
5af68cc7-fab6-4258-b5b6-2feb36df3e2a	false	display.on.consent.screen
5af68cc7-fab6-4258-b5b6-2feb36df3e2a	false	include.in.token.scope
6013a609-8730-4c61-affe-99d3535445ec	false	display.on.consent.screen
6013a609-8730-4c61-affe-99d3535445ec	false	include.in.token.scope
88dd4199-b555-4c54-90ad-d87376de9482	true	display.on.consent.screen
88dd4199-b555-4c54-90ad-d87376de9482	${organizationScopeConsentText}	consent.screen.text
88dd4199-b555-4c54-90ad-d87376de9482	true	include.in.token.scope
0718e728-fb10-429c-be7b-795e7dd0a842	true	display.on.consent.screen
0718e728-fb10-429c-be7b-795e7dd0a842	${offlineAccessScopeConsentText}	consent.screen.text
3b010f52-041c-4a7a-9eb9-ae6bab3b9bd1	true	display.on.consent.screen
3b010f52-041c-4a7a-9eb9-ae6bab3b9bd1	${samlRoleListScopeConsentText}	consent.screen.text
0492b33d-d297-4009-9bdd-5f1dcf782cf3	false	display.on.consent.screen
fd53d63e-abd9-4923-928a-9fba44904b06	true	display.on.consent.screen
fd53d63e-abd9-4923-928a-9fba44904b06	${profileScopeConsentText}	consent.screen.text
fd53d63e-abd9-4923-928a-9fba44904b06	true	include.in.token.scope
7a56b774-281d-4a64-8c54-2433df97f56f	true	display.on.consent.screen
7a56b774-281d-4a64-8c54-2433df97f56f	${emailScopeConsentText}	consent.screen.text
7a56b774-281d-4a64-8c54-2433df97f56f	true	include.in.token.scope
d5d4bb63-9d28-4a83-b2ad-ea18d77e3cde	true	display.on.consent.screen
d5d4bb63-9d28-4a83-b2ad-ea18d77e3cde	${addressScopeConsentText}	consent.screen.text
d5d4bb63-9d28-4a83-b2ad-ea18d77e3cde	true	include.in.token.scope
f5731461-3ade-4754-8d03-799394e6b501	true	display.on.consent.screen
f5731461-3ade-4754-8d03-799394e6b501	${phoneScopeConsentText}	consent.screen.text
f5731461-3ade-4754-8d03-799394e6b501	true	include.in.token.scope
824686d7-ec63-4db4-86ee-daaf860b3340	true	display.on.consent.screen
824686d7-ec63-4db4-86ee-daaf860b3340	${rolesScopeConsentText}	consent.screen.text
824686d7-ec63-4db4-86ee-daaf860b3340	false	include.in.token.scope
c72c60f1-de1d-46d7-917d-952d8cb6cb17	false	display.on.consent.screen
c72c60f1-de1d-46d7-917d-952d8cb6cb17		consent.screen.text
c72c60f1-de1d-46d7-917d-952d8cb6cb17	false	include.in.token.scope
eb6c56b3-7c18-4f2d-8d01-d4c2fae36bda	false	display.on.consent.screen
eb6c56b3-7c18-4f2d-8d01-d4c2fae36bda	true	include.in.token.scope
36504493-b5fa-4be1-8c55-9f9a07182a28	false	display.on.consent.screen
36504493-b5fa-4be1-8c55-9f9a07182a28	false	include.in.token.scope
a63a51b4-5482-4c17-98fa-621abb8905cc	false	display.on.consent.screen
a63a51b4-5482-4c17-98fa-621abb8905cc	false	include.in.token.scope
803f155a-8316-4be0-8ef9-4f23ddc3c2bf	false	display.on.consent.screen
803f155a-8316-4be0-8ef9-4f23ddc3c2bf	false	include.in.token.scope
7d4db986-2070-44e5-9096-48d2f4a85f47	true	display.on.consent.screen
7d4db986-2070-44e5-9096-48d2f4a85f47	${organizationScopeConsentText}	consent.screen.text
7d4db986-2070-44e5-9096-48d2f4a85f47	true	include.in.token.scope
\.


--
-- Data for Name: client_scope_client; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client_scope_client (client_id, scope_id, default_scope) FROM stdin;
c05b475f-598d-429b-80d1-276ca9e572a0	1e3e93ad-a248-44ae-82cb-be42caf1083a	t
c05b475f-598d-429b-80d1-276ca9e572a0	c54f2ec3-1987-4cd0-9dbd-5564abb04e76	t
c05b475f-598d-429b-80d1-276ca9e572a0	5af68cc7-fab6-4258-b5b6-2feb36df3e2a	t
c05b475f-598d-429b-80d1-276ca9e572a0	d9d47570-32cf-44eb-a329-93be5d5dbd9e	t
c05b475f-598d-429b-80d1-276ca9e572a0	0d9f8c42-cbda-4fa9-8f53-0af2c9dfdde3	t
c05b475f-598d-429b-80d1-276ca9e572a0	80597c7a-c1f9-44ab-8f15-31c36ca51cd3	t
c05b475f-598d-429b-80d1-276ca9e572a0	8a10c45f-537f-4783-8cc1-34e42626984a	f
c05b475f-598d-429b-80d1-276ca9e572a0	88dd4199-b555-4c54-90ad-d87376de9482	f
c05b475f-598d-429b-80d1-276ca9e572a0	ead5eaa8-b5a4-4021-afc2-12cc33da2c2d	f
c05b475f-598d-429b-80d1-276ca9e572a0	67e3ddb1-a977-4fb8-a5c6-a57dd8804cda	f
c05b475f-598d-429b-80d1-276ca9e572a0	161747f8-23e3-4e95-a21b-d3675be338e5	f
a9243c21-3223-4b2a-92e4-67ebf2d2e151	1e3e93ad-a248-44ae-82cb-be42caf1083a	t
a9243c21-3223-4b2a-92e4-67ebf2d2e151	c54f2ec3-1987-4cd0-9dbd-5564abb04e76	t
a9243c21-3223-4b2a-92e4-67ebf2d2e151	5af68cc7-fab6-4258-b5b6-2feb36df3e2a	t
a9243c21-3223-4b2a-92e4-67ebf2d2e151	d9d47570-32cf-44eb-a329-93be5d5dbd9e	t
a9243c21-3223-4b2a-92e4-67ebf2d2e151	0d9f8c42-cbda-4fa9-8f53-0af2c9dfdde3	t
a9243c21-3223-4b2a-92e4-67ebf2d2e151	80597c7a-c1f9-44ab-8f15-31c36ca51cd3	t
a9243c21-3223-4b2a-92e4-67ebf2d2e151	8a10c45f-537f-4783-8cc1-34e42626984a	f
a9243c21-3223-4b2a-92e4-67ebf2d2e151	88dd4199-b555-4c54-90ad-d87376de9482	f
a9243c21-3223-4b2a-92e4-67ebf2d2e151	ead5eaa8-b5a4-4021-afc2-12cc33da2c2d	f
a9243c21-3223-4b2a-92e4-67ebf2d2e151	67e3ddb1-a977-4fb8-a5c6-a57dd8804cda	f
a9243c21-3223-4b2a-92e4-67ebf2d2e151	161747f8-23e3-4e95-a21b-d3675be338e5	f
e8f8b34d-3713-42bd-bb36-3b3eb16de6e7	1e3e93ad-a248-44ae-82cb-be42caf1083a	t
e8f8b34d-3713-42bd-bb36-3b3eb16de6e7	c54f2ec3-1987-4cd0-9dbd-5564abb04e76	t
e8f8b34d-3713-42bd-bb36-3b3eb16de6e7	5af68cc7-fab6-4258-b5b6-2feb36df3e2a	t
e8f8b34d-3713-42bd-bb36-3b3eb16de6e7	d9d47570-32cf-44eb-a329-93be5d5dbd9e	t
e8f8b34d-3713-42bd-bb36-3b3eb16de6e7	0d9f8c42-cbda-4fa9-8f53-0af2c9dfdde3	t
e8f8b34d-3713-42bd-bb36-3b3eb16de6e7	80597c7a-c1f9-44ab-8f15-31c36ca51cd3	t
e8f8b34d-3713-42bd-bb36-3b3eb16de6e7	8a10c45f-537f-4783-8cc1-34e42626984a	f
e8f8b34d-3713-42bd-bb36-3b3eb16de6e7	88dd4199-b555-4c54-90ad-d87376de9482	f
e8f8b34d-3713-42bd-bb36-3b3eb16de6e7	ead5eaa8-b5a4-4021-afc2-12cc33da2c2d	f
e8f8b34d-3713-42bd-bb36-3b3eb16de6e7	67e3ddb1-a977-4fb8-a5c6-a57dd8804cda	f
e8f8b34d-3713-42bd-bb36-3b3eb16de6e7	161747f8-23e3-4e95-a21b-d3675be338e5	f
339d7cac-6002-4453-9a60-2e10d36ba29c	1e3e93ad-a248-44ae-82cb-be42caf1083a	t
339d7cac-6002-4453-9a60-2e10d36ba29c	c54f2ec3-1987-4cd0-9dbd-5564abb04e76	t
339d7cac-6002-4453-9a60-2e10d36ba29c	5af68cc7-fab6-4258-b5b6-2feb36df3e2a	t
339d7cac-6002-4453-9a60-2e10d36ba29c	d9d47570-32cf-44eb-a329-93be5d5dbd9e	t
339d7cac-6002-4453-9a60-2e10d36ba29c	0d9f8c42-cbda-4fa9-8f53-0af2c9dfdde3	t
339d7cac-6002-4453-9a60-2e10d36ba29c	80597c7a-c1f9-44ab-8f15-31c36ca51cd3	t
339d7cac-6002-4453-9a60-2e10d36ba29c	8a10c45f-537f-4783-8cc1-34e42626984a	f
339d7cac-6002-4453-9a60-2e10d36ba29c	88dd4199-b555-4c54-90ad-d87376de9482	f
339d7cac-6002-4453-9a60-2e10d36ba29c	ead5eaa8-b5a4-4021-afc2-12cc33da2c2d	f
339d7cac-6002-4453-9a60-2e10d36ba29c	67e3ddb1-a977-4fb8-a5c6-a57dd8804cda	f
339d7cac-6002-4453-9a60-2e10d36ba29c	161747f8-23e3-4e95-a21b-d3675be338e5	f
ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	1e3e93ad-a248-44ae-82cb-be42caf1083a	t
ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	c54f2ec3-1987-4cd0-9dbd-5564abb04e76	t
ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	5af68cc7-fab6-4258-b5b6-2feb36df3e2a	t
ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	d9d47570-32cf-44eb-a329-93be5d5dbd9e	t
ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	0d9f8c42-cbda-4fa9-8f53-0af2c9dfdde3	t
ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	80597c7a-c1f9-44ab-8f15-31c36ca51cd3	t
ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	8a10c45f-537f-4783-8cc1-34e42626984a	f
ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	88dd4199-b555-4c54-90ad-d87376de9482	f
ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	ead5eaa8-b5a4-4021-afc2-12cc33da2c2d	f
ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	67e3ddb1-a977-4fb8-a5c6-a57dd8804cda	f
ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	161747f8-23e3-4e95-a21b-d3675be338e5	f
6b842f27-4404-4596-ab7a-26c56ffb44b0	1e3e93ad-a248-44ae-82cb-be42caf1083a	t
6b842f27-4404-4596-ab7a-26c56ffb44b0	c54f2ec3-1987-4cd0-9dbd-5564abb04e76	t
6b842f27-4404-4596-ab7a-26c56ffb44b0	5af68cc7-fab6-4258-b5b6-2feb36df3e2a	t
6b842f27-4404-4596-ab7a-26c56ffb44b0	d9d47570-32cf-44eb-a329-93be5d5dbd9e	t
6b842f27-4404-4596-ab7a-26c56ffb44b0	0d9f8c42-cbda-4fa9-8f53-0af2c9dfdde3	t
6b842f27-4404-4596-ab7a-26c56ffb44b0	80597c7a-c1f9-44ab-8f15-31c36ca51cd3	t
6b842f27-4404-4596-ab7a-26c56ffb44b0	8a10c45f-537f-4783-8cc1-34e42626984a	f
6b842f27-4404-4596-ab7a-26c56ffb44b0	88dd4199-b555-4c54-90ad-d87376de9482	f
6b842f27-4404-4596-ab7a-26c56ffb44b0	ead5eaa8-b5a4-4021-afc2-12cc33da2c2d	f
6b842f27-4404-4596-ab7a-26c56ffb44b0	67e3ddb1-a977-4fb8-a5c6-a57dd8804cda	f
6b842f27-4404-4596-ab7a-26c56ffb44b0	161747f8-23e3-4e95-a21b-d3675be338e5	f
fd19d9b9-ed5b-4fbb-a325-9d49639a74db	7a56b774-281d-4a64-8c54-2433df97f56f	t
fd19d9b9-ed5b-4fbb-a325-9d49639a74db	fd53d63e-abd9-4923-928a-9fba44904b06	t
fd19d9b9-ed5b-4fbb-a325-9d49639a74db	a63a51b4-5482-4c17-98fa-621abb8905cc	t
fd19d9b9-ed5b-4fbb-a325-9d49639a74db	824686d7-ec63-4db4-86ee-daaf860b3340	t
fd19d9b9-ed5b-4fbb-a325-9d49639a74db	c72c60f1-de1d-46d7-917d-952d8cb6cb17	t
fd19d9b9-ed5b-4fbb-a325-9d49639a74db	36504493-b5fa-4be1-8c55-9f9a07182a28	t
fd19d9b9-ed5b-4fbb-a325-9d49639a74db	f5731461-3ade-4754-8d03-799394e6b501	f
fd19d9b9-ed5b-4fbb-a325-9d49639a74db	0718e728-fb10-429c-be7b-795e7dd0a842	f
fd19d9b9-ed5b-4fbb-a325-9d49639a74db	eb6c56b3-7c18-4f2d-8d01-d4c2fae36bda	f
fd19d9b9-ed5b-4fbb-a325-9d49639a74db	7d4db986-2070-44e5-9096-48d2f4a85f47	f
fd19d9b9-ed5b-4fbb-a325-9d49639a74db	d5d4bb63-9d28-4a83-b2ad-ea18d77e3cde	f
60044973-1f42-41b3-a8ed-dcd5ae7d763c	7a56b774-281d-4a64-8c54-2433df97f56f	t
60044973-1f42-41b3-a8ed-dcd5ae7d763c	fd53d63e-abd9-4923-928a-9fba44904b06	t
60044973-1f42-41b3-a8ed-dcd5ae7d763c	a63a51b4-5482-4c17-98fa-621abb8905cc	t
60044973-1f42-41b3-a8ed-dcd5ae7d763c	824686d7-ec63-4db4-86ee-daaf860b3340	t
60044973-1f42-41b3-a8ed-dcd5ae7d763c	c72c60f1-de1d-46d7-917d-952d8cb6cb17	t
60044973-1f42-41b3-a8ed-dcd5ae7d763c	36504493-b5fa-4be1-8c55-9f9a07182a28	t
60044973-1f42-41b3-a8ed-dcd5ae7d763c	f5731461-3ade-4754-8d03-799394e6b501	f
60044973-1f42-41b3-a8ed-dcd5ae7d763c	0718e728-fb10-429c-be7b-795e7dd0a842	f
60044973-1f42-41b3-a8ed-dcd5ae7d763c	eb6c56b3-7c18-4f2d-8d01-d4c2fae36bda	f
60044973-1f42-41b3-a8ed-dcd5ae7d763c	7d4db986-2070-44e5-9096-48d2f4a85f47	f
60044973-1f42-41b3-a8ed-dcd5ae7d763c	d5d4bb63-9d28-4a83-b2ad-ea18d77e3cde	f
5a5f209b-441a-47bc-816d-523d86514cb7	7a56b774-281d-4a64-8c54-2433df97f56f	t
5a5f209b-441a-47bc-816d-523d86514cb7	fd53d63e-abd9-4923-928a-9fba44904b06	t
5a5f209b-441a-47bc-816d-523d86514cb7	a63a51b4-5482-4c17-98fa-621abb8905cc	t
5a5f209b-441a-47bc-816d-523d86514cb7	824686d7-ec63-4db4-86ee-daaf860b3340	t
5a5f209b-441a-47bc-816d-523d86514cb7	c72c60f1-de1d-46d7-917d-952d8cb6cb17	t
5a5f209b-441a-47bc-816d-523d86514cb7	36504493-b5fa-4be1-8c55-9f9a07182a28	t
5a5f209b-441a-47bc-816d-523d86514cb7	f5731461-3ade-4754-8d03-799394e6b501	f
5a5f209b-441a-47bc-816d-523d86514cb7	0718e728-fb10-429c-be7b-795e7dd0a842	f
5a5f209b-441a-47bc-816d-523d86514cb7	eb6c56b3-7c18-4f2d-8d01-d4c2fae36bda	f
5a5f209b-441a-47bc-816d-523d86514cb7	7d4db986-2070-44e5-9096-48d2f4a85f47	f
5a5f209b-441a-47bc-816d-523d86514cb7	d5d4bb63-9d28-4a83-b2ad-ea18d77e3cde	f
fbd3dabc-3a1a-42da-9a5d-a3bd488842f2	7a56b774-281d-4a64-8c54-2433df97f56f	t
fbd3dabc-3a1a-42da-9a5d-a3bd488842f2	fd53d63e-abd9-4923-928a-9fba44904b06	t
fbd3dabc-3a1a-42da-9a5d-a3bd488842f2	a63a51b4-5482-4c17-98fa-621abb8905cc	t
fbd3dabc-3a1a-42da-9a5d-a3bd488842f2	824686d7-ec63-4db4-86ee-daaf860b3340	t
fbd3dabc-3a1a-42da-9a5d-a3bd488842f2	c72c60f1-de1d-46d7-917d-952d8cb6cb17	t
fbd3dabc-3a1a-42da-9a5d-a3bd488842f2	36504493-b5fa-4be1-8c55-9f9a07182a28	t
fbd3dabc-3a1a-42da-9a5d-a3bd488842f2	f5731461-3ade-4754-8d03-799394e6b501	f
fbd3dabc-3a1a-42da-9a5d-a3bd488842f2	0718e728-fb10-429c-be7b-795e7dd0a842	f
fbd3dabc-3a1a-42da-9a5d-a3bd488842f2	eb6c56b3-7c18-4f2d-8d01-d4c2fae36bda	f
fbd3dabc-3a1a-42da-9a5d-a3bd488842f2	7d4db986-2070-44e5-9096-48d2f4a85f47	f
fbd3dabc-3a1a-42da-9a5d-a3bd488842f2	d5d4bb63-9d28-4a83-b2ad-ea18d77e3cde	f
c560ba3f-d4cd-4075-80f6-541d6faa9d56	7a56b774-281d-4a64-8c54-2433df97f56f	t
c560ba3f-d4cd-4075-80f6-541d6faa9d56	fd53d63e-abd9-4923-928a-9fba44904b06	t
c560ba3f-d4cd-4075-80f6-541d6faa9d56	a63a51b4-5482-4c17-98fa-621abb8905cc	t
c560ba3f-d4cd-4075-80f6-541d6faa9d56	824686d7-ec63-4db4-86ee-daaf860b3340	t
c560ba3f-d4cd-4075-80f6-541d6faa9d56	c72c60f1-de1d-46d7-917d-952d8cb6cb17	t
c560ba3f-d4cd-4075-80f6-541d6faa9d56	36504493-b5fa-4be1-8c55-9f9a07182a28	t
c560ba3f-d4cd-4075-80f6-541d6faa9d56	f5731461-3ade-4754-8d03-799394e6b501	f
c560ba3f-d4cd-4075-80f6-541d6faa9d56	0718e728-fb10-429c-be7b-795e7dd0a842	f
c560ba3f-d4cd-4075-80f6-541d6faa9d56	eb6c56b3-7c18-4f2d-8d01-d4c2fae36bda	f
c560ba3f-d4cd-4075-80f6-541d6faa9d56	7d4db986-2070-44e5-9096-48d2f4a85f47	f
c560ba3f-d4cd-4075-80f6-541d6faa9d56	d5d4bb63-9d28-4a83-b2ad-ea18d77e3cde	f
b6f89aba-b213-40cd-abbb-9f80c8e88318	7a56b774-281d-4a64-8c54-2433df97f56f	t
b6f89aba-b213-40cd-abbb-9f80c8e88318	fd53d63e-abd9-4923-928a-9fba44904b06	t
b6f89aba-b213-40cd-abbb-9f80c8e88318	a63a51b4-5482-4c17-98fa-621abb8905cc	t
b6f89aba-b213-40cd-abbb-9f80c8e88318	824686d7-ec63-4db4-86ee-daaf860b3340	t
b6f89aba-b213-40cd-abbb-9f80c8e88318	c72c60f1-de1d-46d7-917d-952d8cb6cb17	t
b6f89aba-b213-40cd-abbb-9f80c8e88318	36504493-b5fa-4be1-8c55-9f9a07182a28	t
b6f89aba-b213-40cd-abbb-9f80c8e88318	f5731461-3ade-4754-8d03-799394e6b501	f
b6f89aba-b213-40cd-abbb-9f80c8e88318	0718e728-fb10-429c-be7b-795e7dd0a842	f
b6f89aba-b213-40cd-abbb-9f80c8e88318	eb6c56b3-7c18-4f2d-8d01-d4c2fae36bda	f
b6f89aba-b213-40cd-abbb-9f80c8e88318	7d4db986-2070-44e5-9096-48d2f4a85f47	f
b6f89aba-b213-40cd-abbb-9f80c8e88318	d5d4bb63-9d28-4a83-b2ad-ea18d77e3cde	f
b1a24523-e2b5-4cc6-af64-8364f8882e32	7a56b774-281d-4a64-8c54-2433df97f56f	t
b1a24523-e2b5-4cc6-af64-8364f8882e32	fd53d63e-abd9-4923-928a-9fba44904b06	t
b1a24523-e2b5-4cc6-af64-8364f8882e32	a63a51b4-5482-4c17-98fa-621abb8905cc	t
b1a24523-e2b5-4cc6-af64-8364f8882e32	824686d7-ec63-4db4-86ee-daaf860b3340	t
b1a24523-e2b5-4cc6-af64-8364f8882e32	c72c60f1-de1d-46d7-917d-952d8cb6cb17	t
b1a24523-e2b5-4cc6-af64-8364f8882e32	36504493-b5fa-4be1-8c55-9f9a07182a28	t
b1a24523-e2b5-4cc6-af64-8364f8882e32	f5731461-3ade-4754-8d03-799394e6b501	f
b1a24523-e2b5-4cc6-af64-8364f8882e32	0718e728-fb10-429c-be7b-795e7dd0a842	f
b1a24523-e2b5-4cc6-af64-8364f8882e32	eb6c56b3-7c18-4f2d-8d01-d4c2fae36bda	f
b1a24523-e2b5-4cc6-af64-8364f8882e32	7d4db986-2070-44e5-9096-48d2f4a85f47	f
b1a24523-e2b5-4cc6-af64-8364f8882e32	d5d4bb63-9d28-4a83-b2ad-ea18d77e3cde	f
\.


--
-- Data for Name: client_scope_role_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.client_scope_role_mapping (scope_id, role_id) FROM stdin;
ead5eaa8-b5a4-4021-afc2-12cc33da2c2d	1d9236ed-2238-4a3c-be4f-861c9af05d8b
0718e728-fb10-429c-be7b-795e7dd0a842	5e274b31-a53a-4f89-a5cf-103dbae7cb1d
\.


--
-- Data for Name: component; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.component (id, name, parent_id, provider_id, provider_type, realm_id, sub_type) FROM stdin;
b521861c-8ecb-454e-8585-32cff94a8742	Trusted Hosts	207d128c-bb74-4e7f-a3e4-f110b22d6159	trusted-hosts	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	207d128c-bb74-4e7f-a3e4-f110b22d6159	anonymous
cd9a41dd-b921-44f0-b927-328836c703c5	Consent Required	207d128c-bb74-4e7f-a3e4-f110b22d6159	consent-required	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	207d128c-bb74-4e7f-a3e4-f110b22d6159	anonymous
740be1c0-e4c8-401b-a7ee-bbdc3e2f4971	Full Scope Disabled	207d128c-bb74-4e7f-a3e4-f110b22d6159	scope	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	207d128c-bb74-4e7f-a3e4-f110b22d6159	anonymous
4bb5e938-d3c1-45b7-b7c5-2b1e82bd82ef	Max Clients Limit	207d128c-bb74-4e7f-a3e4-f110b22d6159	max-clients	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	207d128c-bb74-4e7f-a3e4-f110b22d6159	anonymous
16407f95-066b-4a4e-84a0-88e03e8543c8	Allowed Protocol Mapper Types	207d128c-bb74-4e7f-a3e4-f110b22d6159	allowed-protocol-mappers	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	207d128c-bb74-4e7f-a3e4-f110b22d6159	anonymous
189793c0-5b5a-478c-9e38-c9ba4be1e496	Allowed Client Scopes	207d128c-bb74-4e7f-a3e4-f110b22d6159	allowed-client-templates	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	207d128c-bb74-4e7f-a3e4-f110b22d6159	anonymous
add71869-78ad-4133-ae9a-3b58c425dddb	Allowed Registration Web Origins	207d128c-bb74-4e7f-a3e4-f110b22d6159	registration-web-origins	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	207d128c-bb74-4e7f-a3e4-f110b22d6159	anonymous
69a6d228-5209-421b-8545-19e579a56450	Allowed Protocol Mapper Types	207d128c-bb74-4e7f-a3e4-f110b22d6159	allowed-protocol-mappers	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	207d128c-bb74-4e7f-a3e4-f110b22d6159	authenticated
4f2b65b3-aa2e-444a-a1ec-3e3047b060c3	Allowed Client Scopes	207d128c-bb74-4e7f-a3e4-f110b22d6159	allowed-client-templates	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	207d128c-bb74-4e7f-a3e4-f110b22d6159	authenticated
a3f8ec17-8910-4a97-ba1d-9a9276e0c093	Allowed Registration Web Origins	207d128c-bb74-4e7f-a3e4-f110b22d6159	registration-web-origins	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	207d128c-bb74-4e7f-a3e4-f110b22d6159	authenticated
e3975523-9e5c-47a8-9c76-57d9b8133423	rsa-generated	207d128c-bb74-4e7f-a3e4-f110b22d6159	rsa-generated	org.keycloak.keys.KeyProvider	207d128c-bb74-4e7f-a3e4-f110b22d6159	\N
f657e5b3-5fc3-4942-b269-50e464c60cb9	rsa-enc-generated	207d128c-bb74-4e7f-a3e4-f110b22d6159	rsa-enc-generated	org.keycloak.keys.KeyProvider	207d128c-bb74-4e7f-a3e4-f110b22d6159	\N
a7df85b2-144a-4cc3-881b-bbe15f2ec97f	hmac-generated-hs512	207d128c-bb74-4e7f-a3e4-f110b22d6159	hmac-generated	org.keycloak.keys.KeyProvider	207d128c-bb74-4e7f-a3e4-f110b22d6159	\N
593e76b5-efdc-4d0e-9556-46eef18ca312	aes-generated	207d128c-bb74-4e7f-a3e4-f110b22d6159	aes-generated	org.keycloak.keys.KeyProvider	207d128c-bb74-4e7f-a3e4-f110b22d6159	\N
c482a6da-0e4f-4add-99ef-7d665a216d35	\N	207d128c-bb74-4e7f-a3e4-f110b22d6159	declarative-user-profile	org.keycloak.userprofile.UserProfileProvider	207d128c-bb74-4e7f-a3e4-f110b22d6159	\N
c68fb833-f176-47da-904c-98e04f097405	rsa-generated	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	rsa-generated	org.keycloak.keys.KeyProvider	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	\N
4224b9ab-3f0b-4f05-a409-1964162b564f	rsa-enc-generated	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	rsa-enc-generated	org.keycloak.keys.KeyProvider	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	\N
f3bcc671-6b70-407c-a1f3-053977a00d94	hmac-generated-hs512	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	hmac-generated	org.keycloak.keys.KeyProvider	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	\N
3f1bc449-0764-4476-bc56-52866e4db433	aes-generated	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	aes-generated	org.keycloak.keys.KeyProvider	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	\N
ac64914e-7b2a-4477-bb98-b5cde29bc860	Trusted Hosts	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	trusted-hosts	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	anonymous
e355f3dc-6dcb-4e8c-8b48-12d69a36d832	Consent Required	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	consent-required	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	anonymous
30055ca8-e564-4c4c-a347-015fb54f4bb1	Full Scope Disabled	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	scope	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	anonymous
da518ae8-b9eb-4ae4-8379-25ef502d7337	Max Clients Limit	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	max-clients	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	anonymous
57755678-bbf7-49a2-b39d-c80df845ba0e	Allowed Protocol Mapper Types	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	allowed-protocol-mappers	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	anonymous
260d9d92-d950-4ada-9ce1-5bdc0032d1d0	Allowed Client Scopes	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	allowed-client-templates	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	anonymous
8d46b4c1-7127-446e-ac28-ce4de5731473	Allowed Registration Web Origins	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	registration-web-origins	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	anonymous
3ee1a946-7bd2-4988-ae15-4c29bc5ee0ac	Allowed Protocol Mapper Types	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	allowed-protocol-mappers	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	authenticated
f17f4d45-e87a-403a-af8d-ed1f35e0b2ca	Allowed Client Scopes	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	allowed-client-templates	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	authenticated
561fb159-a2ff-4f6f-97b7-6525a2e33ff9	Allowed Registration Web Origins	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	registration-web-origins	org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	authenticated
\.


--
-- Data for Name: component_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.component_config (id, component_id, name, value) FROM stdin;
59c4c336-34a1-4114-94ca-63a073c33901	16407f95-066b-4a4e-84a0-88e03e8543c8	allowed-protocol-mapper-types	oidc-usermodel-property-mapper
5328899b-c44b-482f-9e93-c9f71c05bd90	16407f95-066b-4a4e-84a0-88e03e8543c8	allowed-protocol-mapper-types	oidc-usermodel-attribute-mapper
9470294c-a34d-4ed5-abfe-a1b73df737ba	16407f95-066b-4a4e-84a0-88e03e8543c8	allowed-protocol-mapper-types	oidc-full-name-mapper
077b99a3-226c-414f-88e3-83e4af09646c	16407f95-066b-4a4e-84a0-88e03e8543c8	allowed-protocol-mapper-types	oidc-sha256-pairwise-sub-mapper
77401f19-d114-43e3-90dd-38e84d1f06fb	16407f95-066b-4a4e-84a0-88e03e8543c8	allowed-protocol-mapper-types	saml-role-list-mapper
b6a9b6c7-b3d2-43c3-8f4d-06bdf22971d9	16407f95-066b-4a4e-84a0-88e03e8543c8	allowed-protocol-mapper-types	saml-user-attribute-mapper
b4e9f653-de67-42c1-9e61-e98d1887e538	16407f95-066b-4a4e-84a0-88e03e8543c8	allowed-protocol-mapper-types	oidc-address-mapper
193fc0be-6386-4515-89dc-4b74f09229bf	16407f95-066b-4a4e-84a0-88e03e8543c8	allowed-protocol-mapper-types	saml-user-property-mapper
4179882d-720a-4ba8-a958-ed27be62ffb4	4f2b65b3-aa2e-444a-a1ec-3e3047b060c3	allow-default-scopes	true
4064a5ca-744b-4c0e-8572-d4d951919598	b521861c-8ecb-454e-8585-32cff94a8742	host-sending-registration-request-must-match	true
840a81d0-887d-415b-a626-283f70569d74	b521861c-8ecb-454e-8585-32cff94a8742	client-uris-must-match	true
eec9bb30-724d-439b-976a-089d65ebe9ec	189793c0-5b5a-478c-9e38-c9ba4be1e496	allow-default-scopes	true
bd51ff40-51cb-438c-a384-632d93d5f0e7	69a6d228-5209-421b-8545-19e579a56450	allowed-protocol-mapper-types	oidc-sha256-pairwise-sub-mapper
d0bfd74f-3479-4cef-83dc-88e3e466dc44	69a6d228-5209-421b-8545-19e579a56450	allowed-protocol-mapper-types	saml-role-list-mapper
d4d80e74-54b4-485d-8dea-9cf3e4dc5035	69a6d228-5209-421b-8545-19e579a56450	allowed-protocol-mapper-types	oidc-usermodel-property-mapper
903d77ed-e6fb-4d9c-934e-8a39fd999ba5	69a6d228-5209-421b-8545-19e579a56450	allowed-protocol-mapper-types	saml-user-attribute-mapper
099ee9f9-f35a-46be-b287-e9cf806e9a32	69a6d228-5209-421b-8545-19e579a56450	allowed-protocol-mapper-types	oidc-full-name-mapper
cf07da0d-4be3-4f4a-9a7f-db46c44f4ddc	69a6d228-5209-421b-8545-19e579a56450	allowed-protocol-mapper-types	saml-user-property-mapper
c8ce0132-fa22-402e-af55-140075f0ecce	69a6d228-5209-421b-8545-19e579a56450	allowed-protocol-mapper-types	oidc-usermodel-attribute-mapper
f30d98ca-1e69-4402-8545-42d9e0c46faa	69a6d228-5209-421b-8545-19e579a56450	allowed-protocol-mapper-types	oidc-address-mapper
3037afa3-3811-4bd9-847e-27e25b5271d3	4bb5e938-d3c1-45b7-b7c5-2b1e82bd82ef	max-clients	200
3167cef8-160b-4ef1-a28c-7abc9abb2fb4	e3975523-9e5c-47a8-9c76-57d9b8133423	keyUse	SIG
32bcbe29-fb59-4d9d-a238-b65afe53886e	e3975523-9e5c-47a8-9c76-57d9b8133423	privateKey	MIIEogIBAAKCAQEAuUYNMPDPWSt4tJHeaqEZaC1K+7iIcireBhS0m1mR0xUFX+SvQ/zvO1E34WBKUqqfe/QMCLf4Yco4yksVOULYQrYFw++sRAiiLXWgeI0ZbdcXsWt45p72sJV5b3jso+jW0/3NffUVqDOAoRARp/wCb/5++U1702FXrmP4gcDiPeEZ44JARSn+D9u4qY3tZzy50RILI2ipjN6JSlvnkPZwkBaQ296PgizYS7BnGIjS1AWajOfLvnZMX1kHsHiWbxG4UASDzk4cdaZUAqTdJCCbFnk/JKh7lU2Z1WKxZiPpijNip7Pl1AfPtQjk0P253kWk1EYkX5TnPn9JyQtV3ai1iQIDAQABAoIBAAR/Tvup+hvb18gTpbaokXF7bqSx7odNmL/EtJD0JCY1DkEtJRSn6PYOJdFFNpikxqP0y8P8aeg/HJDLMMkyi7BW3cigopRbh0rw3i5+8lKTFDf8zV2qbH+N0/mg5vxK6cgR6EaPR/F3dT8I9lIXERy/LJLdpCIAl2ccIHX52iQOrkml5rq8lf7BpW9/BRqbucdmsfcIXfT/OKn769z/EX5PKfHzjzopxqpfZa468lD3FlVCvvan7ulmaMzNl8nYPGW7Q+03K2ZzZKu19jwTSIwvO+V5iOwmXkOvXZ9TLRlIkmBjItGh29u+dSaIBm6myB72UYFFuccN36Luh6S6rN8CgYEA9GVdhLSSGF64+WSxlqTZ3tNBnMmwfHXYgcXi+z7oGOD0/AvpLY3VOyqlcVp+f4/4iFarK0sMAi1q5ANgn5XTI2AGr80dzZdkjJoOzqU4nDhmmF8Rs+zzPTfDblIKqHD5X8MPbiQ4uGzN1XbO7YlCRLeVwhE7Pz+mvoJUAtZPGIcCgYEAwhIN0i3RJezXgxaMlgIBKsnQUYkcdX/4N8LQ3V43dbBdzj4wd0SB9r0Zph5+GeJwy3UeJkzPf7ObxM4nSm5H9O7CJ3/Yes6uRkB+yQ1K3MHW4fv93fFB6lpBXkU9NK/t7FEnzODqScuLucU4pafTpSKZZ36d01GkiRu5ItFWFW8CgYB/cWht7jeM68ArlN2if755GtLJLseQb2eCbK2rdKdVaeF2mcNzlNWPr/JsBNOYM3xXpFJIFi9h50spMbWuIlPiy41RGXYkIoE1bJSyH6hAloyxgknZ+ILy9mQ74B5creTskew29D57tYk0emr3pS7gZJd8hr3NgqSyDYY/oH/IewKBgAe/IL4bBhY1dgTNiZ8TRWin1aDrkC9AhG/1XtD3Sc9w0s3Avb6FBYsL0VJINVBjMY1th16QAlhemwEoGXlnHYgxX56kA8gjJ+G2AVmVJj/ZnPI4VNHfJ3prT+Crct3/h8e/FY+gCroXXeR0cuZp5JDa6LSw4SvmPmMasDErmfwRAoGAVffeALzYXYbez4ZnvxYN3vWViFnRQ+9MSvSqaTZa9lgKuqIwYb0DLUID1v1bSi8/evHZ6BnAuobZJcEkbISyEWXFO0joxSPIqt9V3WZsLanzKhJoGodV5rF8lkayK/BNYL0OnkxeafGnOxDMmXmPhKJboVNfAJwLTMDSnAdfAlE=
8b48809f-5854-4414-bba0-625174ba972b	e3975523-9e5c-47a8-9c76-57d9b8133423	priority	100
c4c161cf-cc44-4fd7-a083-562e8882adfa	e3975523-9e5c-47a8-9c76-57d9b8133423	certificate	MIICmzCCAYMCBgGdmjprHzANBgkqhkiG9w0BAQsFADARMQ8wDQYDVQQDDAZtYXN0ZXIwHhcNMjYwNDE3MDY1NTEzWhcNMzYwNDE3MDY1NjUzWjARMQ8wDQYDVQQDDAZtYXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC5Rg0w8M9ZK3i0kd5qoRloLUr7uIhyKt4GFLSbWZHTFQVf5K9D/O87UTfhYEpSqp979AwIt/hhyjjKSxU5QthCtgXD76xECKItdaB4jRlt1xexa3jmnvawlXlveOyj6NbT/c199RWoM4ChEBGn/AJv/n75TXvTYVeuY/iBwOI94RnjgkBFKf4P27ipje1nPLnREgsjaKmM3olKW+eQ9nCQFpDb3o+CLNhLsGcYiNLUBZqM58u+dkxfWQeweJZvEbhQBIPOThx1plQCpN0kIJsWeT8kqHuVTZnVYrFmI+mKM2Kns+XUB8+1COTQ/bneRaTURiRflOc+f0nJC1XdqLWJAgMBAAEwDQYJKoZIhvcNAQELBQADggEBABOrlcZDziucy4wg4nQ68HXP0gQO7zoKHxRqytHVxU2NV98UDt17Jg/mJlDNddAL9ZJw+OMS4OJU7MET51ciy7zDknRy5g+yMKc7K3tAhbdRvpVfbfItrY27/D57kGEqEdKLURSJRViiIalzdLe5wZossshT6B3YVoXwt13dB7vm5Gnc6xTLRVU1VXKTVfRcjJtrDrv/cDbwxXE/D/gtA7mVuUVPMcoyJjrvaEXOlruZk4/NqRF7qJz428bLV3kEDtHw88g2gaS1L2h1lhD8ExaSBjKu8BpMj+9ScahdyWOYwdcxll6X+0eDKKDPFq5UqNkNkfafhfW06LbVIaiC8zQ=
6b4a42e8-c019-4455-bab0-fbd84795dcb1	f657e5b3-5fc3-4942-b269-50e464c60cb9	privateKey	MIIEpQIBAAKCAQEAvBZ0GArGbtF6YxR1KYg3yYG6vAYf/Yu1oC89vhEb9HZSViBlbwv2pMfgyp3GQV+sefdBRhw9U2mUOt3erkhk1Ka9sBJ0+xl/CaPrxvuTy0PfLLZ+EYyDIzgdsJO738Xl+gjFum1BWVP0BMd85UjMuQOygkNYtfr5i5zapIEn97i1mHFiE0Q0q7Gdbhb5hcqXwZQa7VM4VBzi2diaS23ouqmdnl5K2elj/eoCebR6Ajk9LqPROFj1V3Z5tZl26V1HZc9qOI/SiPBnRYg1wNJOH2j/+OWhPvnt73z80kfhM5i6nGf02QDUdf3I3P0Em6EU5QgB8rKOCELoj3Mk4t+RCwIDAQABAoIBAFvfa93ChaLj17BF8eTTkMxw/dGR/FZQw+r2qGYK3WjP0vAW6vUPFu7uYzMVVh3gqdL5n3yrlpkD3U/TyE3BNt9YgxdaLKHqlk8TLrwHbu2+vWiNy46u3+94Hah+wSpQ9EDpwAuMCnujsnITL0KgCL/mum8+jjp12ScE+xeXrvok+m0EVi7ph1fobVv613xYRkHiCaTjUQTCW2snrNpuA4TnVMmbS9sxbu5nzZU2F4GokiIWqH13ow1prFH7zJvMlquK3k0slsZvXp5aKUlCDqgblpvKvl26uoKIfIFUIMDRvJ+oGUKvl7pu23MKpDXFyoXSvwjTs9oAbTTO3V0jkkECgYEA/rinYdlt1h4SvmVhOT9uuNCgOsH+rCHm0s8lRtpcC/6pP6paEV8roo1OxK4Fooh4wK7ueeI4xpZbtrv2pehSzB/fw3amfUGPjzc7HNF0G7XJNMNQNGekyxp1TwqDRCvedGk5PLWEJxboxXoSlZA2xA/28LAc9i0j52T6IRnH1xkCgYEAvQgq9oHwzi4K0hNcQL7Dfb6RtVBdXG/8KbdQpJQS3spPLAMtmvWAOcewGQBWfC8PLbDue6x+CAIpjubDGoQFshFNtp+IgX55+mWvp8QgG+AvjuKIMmUwy7f+L6Maze6pPrxPLgYt3xi4Q9O4gaiGPSmqL+hzxsTKkAOz4yhgocMCgYEA2dcxzw0UUjoF7a7mJv+IwaYqYhXmp2+W6FMfnijA78ErHbeir5ikyK/w3WO2jfoIy0DP0o0V4UBVz0GQ/vJhXRElXRTr7dNT4zdo5ox6r/gXy3f979Nzq/9EtARZnsOlzAjxWmoiSwvcpoZvvllHfQXqOo1jN2YDfrFs+UIDFoECgYEAoSwDpaZo8QKkyzUipTmBaQdBKPzafWQl9lOMeKaf6EFKe9ZB3iuQJrOx279D/iIJqQWAcQZDdwSQ9nyewU7rpEXIovsm4nI6AlsNB9fbIKlnI0bWpVFN54R7P5ar1gW1W/4m7LDsD5n+EibE3BgaTK/noW1quYE0zNG7YOUebw0CgYEA6Fdzx6icBJ0mSy5hznUQftU80texC1k+RQer/QsgZmX3I+yWf4znk/+u6Xn3jEAcAWWPnwd8tJZ7u6yaoZo93KHXPVB5lfb4tXj1zmECvcPhqXiZ2XWvOcG/Kr2poAopFGTNFgon2iI0ozve0nhlKE/KVgxvQk8w1EwONleK7o4=
20dc476a-750e-431b-8894-e8e77986ddab	f657e5b3-5fc3-4942-b269-50e464c60cb9	priority	100
d34eff1a-c43a-46fe-993e-8aaca46559fa	f657e5b3-5fc3-4942-b269-50e464c60cb9	keyUse	ENC
74907575-b54d-4ec5-b93b-97ca49697bd6	f657e5b3-5fc3-4942-b269-50e464c60cb9	algorithm	RSA-OAEP
c9870a40-73b9-46b7-b349-193e37ced17c	f657e5b3-5fc3-4942-b269-50e464c60cb9	certificate	MIICmzCCAYMCBgGdmjpsdjANBgkqhkiG9w0BAQsFADARMQ8wDQYDVQQDDAZtYXN0ZXIwHhcNMjYwNDE3MDY1NTEzWhcNMzYwNDE3MDY1NjUzWjARMQ8wDQYDVQQDDAZtYXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC8FnQYCsZu0XpjFHUpiDfJgbq8Bh/9i7WgLz2+ERv0dlJWIGVvC/akx+DKncZBX6x590FGHD1TaZQ63d6uSGTUpr2wEnT7GX8Jo+vG+5PLQ98stn4RjIMjOB2wk7vfxeX6CMW6bUFZU/QEx3zlSMy5A7KCQ1i1+vmLnNqkgSf3uLWYcWITRDSrsZ1uFvmFypfBlBrtUzhUHOLZ2JpLbei6qZ2eXkrZ6WP96gJ5tHoCOT0uo9E4WPVXdnm1mXbpXUdlz2o4j9KI8GdFiDXA0k4faP/45aE++e3vfPzSR+EzmLqcZ/TZANR1/cjc/QSboRTlCAHyso4IQuiPcyTi35ELAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAJMkMybyy1FSRGxWoVUxyjGTObv+URYyUZ8mpMCVNZGobU5XD7w9fGWFdeNBRWklMMu43eA9RHOGQc4/HSNGw4tj4lh4HlJhwggYmTPoa25LZoPBBbbX8Lgr2Y9Eo53NGVhCM2QDHd9IB1kAGIMlunv2U8NA4teepDhr0AS4l4U5vm9t7YsxjpApdQfULWdk9iJKbIIUt3WV82Af/G6ZoylbkmevtXpgX/tZMAMb6dcacmf3MoS1kDjCV/qLPr3IfDohkyDED49SJo3xA4ZbN+H7/vF2NFk+DrNCQCTOizt2MpcbymjDy8mwPJtlVe13khSKEooo/EencSO5HG2WLpA=
4ffdff51-6d37-4f0f-bdb1-0ddb567b5e0e	593e76b5-efdc-4d0e-9556-46eef18ca312	kid	0a41f65c-7012-44c2-87b8-b13796f8fc18
65dd1df4-1289-4ccc-81f2-95ec318667dc	593e76b5-efdc-4d0e-9556-46eef18ca312	secret	O6nFa-M2shsjrHjkm12Ofw
85192ff4-7665-4a03-a6e4-d0a5e377183e	593e76b5-efdc-4d0e-9556-46eef18ca312	priority	100
f2565612-f027-4d00-884c-9e52ece7221d	a7df85b2-144a-4cc3-881b-bbe15f2ec97f	priority	100
22ee5adc-ee44-42a8-9891-83dd54f0f55b	a7df85b2-144a-4cc3-881b-bbe15f2ec97f	algorithm	HS512
f1262fd4-76b7-4b2f-8914-0cd1bb159939	a7df85b2-144a-4cc3-881b-bbe15f2ec97f	secret	idVzw6BtOQZDNOO2Bbuoe2Oj0k-o6bbvKi6TLecgWiM3XHKG_xK1h7f-y_9CCdQ4RZrwzRuGW20w_ff8yu29SF0ShEWdtnysNlptbAVX_zaMNR7kepasr4xsr9ASA8rcN1pB397YKupm6RqibvnKHE9o_YRMounuo9PObeDXvp0
a209ed59-5246-498e-b471-f11b97226a55	a7df85b2-144a-4cc3-881b-bbe15f2ec97f	kid	e268db78-1d52-4855-8eb1-832b1ba45e69
c8915bb9-c07c-4bdc-b909-252aa281a814	c482a6da-0e4f-4add-99ef-7d665a216d35	kc.user.profile.config	{"attributes":[{"name":"username","displayName":"${username}","validations":{"length":{"min":3,"max":255},"username-prohibited-characters":{},"up-username-not-idn-homograph":{}},"permissions":{"view":["admin","user"],"edit":["admin","user"]},"multivalued":false},{"name":"email","displayName":"${email}","validations":{"email":{},"length":{"max":255}},"permissions":{"view":["admin","user"],"edit":["admin","user"]},"multivalued":false},{"name":"firstName","displayName":"${firstName}","validations":{"length":{"max":255},"person-name-prohibited-characters":{}},"permissions":{"view":["admin","user"],"edit":["admin","user"]},"multivalued":false},{"name":"lastName","displayName":"${lastName}","validations":{"length":{"max":255},"person-name-prohibited-characters":{}},"permissions":{"view":["admin","user"],"edit":["admin","user"]},"multivalued":false}],"groups":[{"name":"user-metadata","displayHeader":"User metadata","displayDescription":"Attributes, which refer to user metadata"}]}
3ccbb891-eae3-4913-8508-f43e441d257e	f3bcc671-6b70-407c-a1f3-053977a00d94	algorithm	HS512
411971e3-b460-4a12-9118-3e6c2fe975e7	f3bcc671-6b70-407c-a1f3-053977a00d94	priority	100
965ac250-3c88-4068-a1cd-c34bc4f41a99	f3bcc671-6b70-407c-a1f3-053977a00d94	kid	e3d680fc-a2d5-4ceb-a3d8-883365c055b6
5bf8e552-9a93-42b6-9344-53da5761f988	f3bcc671-6b70-407c-a1f3-053977a00d94	secret	1Edh7wMkX97oTdfRWaJsm2N7BrAR8j8B73-IIRJm33Ha7-OUvz9iobi1rvW1X_WAo7P3F7eLfD2Y2mW-29CWOBkxPNryE-0l20-Iyoh4v4bryprXGZC0gXX4hdNLmFXABbyljXKdjBkORXUgqpXVmNhKcyDFtyxeR4MqorBOIPY
4d38f111-a6a1-4ccf-aae1-49df192d1587	3f1bc449-0764-4476-bc56-52866e4db433	priority	100
faf889bd-f332-48fd-9d97-2b125dfa660f	3f1bc449-0764-4476-bc56-52866e4db433	secret	OOiPd8Uw75sQzaxGHSbSEA
cf2da888-13b3-4945-b510-9d54528463a2	3f1bc449-0764-4476-bc56-52866e4db433	kid	7cc8b51d-382c-413b-9b7d-38740c3b70f4
5a4e4eba-23dd-4121-ac9b-a0a18cc0af52	c68fb833-f176-47da-904c-98e04f097405	keyUse	SIG
47523385-fa88-4f41-85eb-5ecd0d7356d8	c68fb833-f176-47da-904c-98e04f097405	privateKey	MIIEpAIBAAKCAQEAriObhjtSFkxuDImbfn77ij9qTBUX513oAYkzdWlg686h+MjVUOl5w4gvVDLAJ9gVXM4ulSUqgfKjMBgtp2r1bKP0chILZ2NnYEx565zTplvjYJtE8m/RSnJTR0COVzaCP96wrWcRKf6ueT+g6RBqAl3uYn/nnRGi/vf8xbCcgC2qrVvyoiKoELcOCEgKyBXmFO+W+fHG3UmKToep+Jvu9NgmnVJZawO1y5O7pr0WtN0tQIZmlOdITbr3ozaQlb18dqvhtsTPr5u8sFvdOjphSS++pNSM2BzQXN1wyxmgH7eVy1aLFtcAkqL/kv6O15qmb6KdhhZz6GrvpZ5ZcjlSeQIDAQABAoIBAD44uOSAo7cV/ih6rtXHF6fxOtEOpGjmU/TgikOEsL3xKkzTrezoT7q/GXIzZBeYjSGJBnoCOqsOAKM5sG5muGTmPHzZ17tMeG6fRN0cPz/tC1TEhiE+NQEt0nXeKj4dWvLpZiW/cxGXT85BHwTH+aj42SnW2/Jyj9Qc1fPpRDJEBvbUTHdwoxlh9bojgCD5878jaN3VztY0meTXk9SvQW8+zw310J2wQHwwjN1OsvekRyCs5qBuvPEqy/W2hrDPYCZG0rNq0BPGXFp7Ebq0oXaWJaPCnUcfgLofUWUbD35F+yfyRkW/vh5X0M6sFWjdbJ/Pzw1QdDq1vZvnxFQ7EoUCgYEA7rltOM8EUew1d2ie+taya+2k+6I43snf/r2zMhSXHdv+W3Adqv687qIkTTggPbNSjmSW4/dk/A8iGGLc9nuoZ7BMzHfiG+hpANMutUYqYSJaoQO+JduC5hifUq/CNhL80KsVTv986PnFvLjnqlv3Z9IE/rFMTajk4rFxPmiCTgMCgYEAur2vFg1EEZNQi5Hy6uCg61hEH7qyAD8w6kcZDL22GnrKOQ8Ww7PXHUJfDebtN+p4yBtf/+JP+85kQP2oeTxl3B3wWcb0EXMwrVvPioVTdibbzcU0bsX5rBD4UhLwxqRdhjvSOfsliA5XvoMPJAK9btA0kC5A46tIbt3hmua9AtMCgYEAiktlWLmk2Qir2KcFIm9qIVgkcZoCtB3i46Jlwydme+fMLJCAv2Sfcub/fLR9CQFvXAot15akK9lgeRwcwbXVU2wwsWrp1B0JZ27v6hfhyS+rrQeMCkZmSIIPGkmzirvpNcFGsOMVK6o2wSOlIW3xn3Vta1auy3aCUklVP0Av7J0CgYBIx4CjcYwj5Www2TL5g45z6rSyQQr6uaYQyKDkrFN6wnxp/I18vGyMRL/TJTsy3bkxFCo4CjXuB6RfB/1PMtDoFusDslyRKHnCNtQOQqQimkZ0TfV/br096Gc/ZY5dfNXOaSYn3s/j1OMxptaRzFeUBqVVxBEaKjlSrDsvKdpkbQKBgQCv+8g4tt6Maq/mWi7JGWvVUY+yBD3GMb3Cop4WM0KBswk+PaPT7gEkGOtKHUlP4Y6pea0dUXPHQ8SH5NbgHNa7pHpPCc+qS3EutPkHUoWnHJB4mq8zIrRCxAsD5QznxDeU5pldC8sM6V5VwQN9zZ5bEPyEWIwIkmC2kUHaWJ8Y3A==
b4f82ccc-4eb6-40af-b2c6-b525ed03f6fb	c68fb833-f176-47da-904c-98e04f097405	priority	100
98658cc8-c3cd-4fa6-974d-051a7ce43751	c68fb833-f176-47da-904c-98e04f097405	certificate	MIICnTCCAYUCBgGdmmkDnTANBgkqhkiG9w0BAQsFADASMRAwDgYDVQQDDAdyZXN0YXBpMB4XDTI2MDQxNzA3NDYwNloXDTM2MDQxNzA3NDc0NlowEjEQMA4GA1UEAwwHcmVzdGFwaTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK4jm4Y7UhZMbgyJm35++4o/akwVF+dd6AGJM3VpYOvOofjI1VDpecOIL1QywCfYFVzOLpUlKoHyozAYLadq9Wyj9HISC2djZ2BMeeuc06Zb42CbRPJv0UpyU0dAjlc2gj/esK1nESn+rnk/oOkQagJd7mJ/550Rov73/MWwnIAtqq1b8qIiqBC3DghICsgV5hTvlvnxxt1Jik6Hqfib7vTYJp1SWWsDtcuTu6a9FrTdLUCGZpTnSE2696M2kJW9fHar4bbEz6+bvLBb3To6YUkvvqTUjNgc0FzdcMsZoB+3lctWixbXAJKi/5L+jteapm+inYYWc+hq76WeWXI5UnkCAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAMmj0oMl3f/9x99hEf4oJYYXnVyklBJJYMpf1Ho4P8OXN4ypWl4UuBBv50ieDTcT/JPPJTdUeedWDmEEieWDo5ocI6q+C6tz4ffHH3lZJlMYZlXcLN8tLwRxsZc5Hhw7AA6WAjc90M6nSPOyCfsz2sx56sa3PBcV1I28VpTZ8Te5Epr+mtWsk/BdB+9DPD3I4ru3njdp3btHhO9OseZgITqWNQFA6WhTM5R0UrsMaePBPYFfTFwH1sjjzoV6Qm3BPMQI7pueb4msRq5i2bMPqAKtZxqDzEJTYgh9g1lFwOmOX07F+By2uCgprjggLlM3cYaQ/A7GsoZaDxkOG31GF+Q==
d02a344a-4416-4725-bac8-715fdca1b5a8	4224b9ab-3f0b-4f05-a409-1964162b564f	algorithm	RSA-OAEP
96b28ba0-0028-42fe-a834-58a527d455dc	4224b9ab-3f0b-4f05-a409-1964162b564f	priority	100
265e7540-3216-4b7d-96c8-63372278d98e	4224b9ab-3f0b-4f05-a409-1964162b564f	keyUse	ENC
56141318-0e34-44ea-9d31-9114c5ee934b	4224b9ab-3f0b-4f05-a409-1964162b564f	privateKey	MIIEowIBAAKCAQEApoN6kpgfvebw67f0tCJAOJ6wavdoynudIu1vTieQCc4IsQgZLzvQDJ++rsdFuNYmmUAgTS+MiMjAK7l/dNmWIBWyKqHCiXXiF7uTZ2Z2/hkJp+gzpyi6OBXXPP1fHQCuQP9fJ5ifmuXUs6QG3Su+r3fextEZNSrvy5YMJwqbEigxRfEz//2ZxUIrXI9+OJdwQnkMwxcY4WtczfxYq7SJQ6HifLUhBlzc4SkykJz5hH/cLB7lAMTkwUg+4BACzqzJVB4EKvTPdYsrlRjCpeqIcoBmSOe9s+250D320lMzlBd3e6KIHBx4ipwxhQMojx/lBiJcV7IFC08z7S4/pODMkQIDAQABAoIBABPOdOCGFtR8aXDod0OMBW6Wta5rknvvW0Ah1QkLXK9F4jPInlJHf5ZY1BIvIuR7GKlG/vCfdMx6cJ1i2b3Y+eoEGqbGigDW1Fd1WPHGNuY/rS3bSXWbOxdbxbf7/XnSMGgL2FI57dY7e2MI4kYho3N0wzuL+L8hxddGGFj2gn6UtzTaMYJ4BPfOTTY+ZQCON6QpL2tAjpWRdntCYiAkhgiEHo89tqvKd4H4nqKKqr/hkbabe61HZUMrhonmldJSRDKFLoHki+UHwWCb4A9GNFubK6H27fp6jvtOVG4qghp/b0crs91ckfajscGSu99b71Po1TY1qldIUyYqaKUYdmECgYEA0Kjn6RkGpswXipkCTqvniFy+aOBo6ZYs5+Geh5PSwqJx7LraJuW2nZY8H0nKvPf9Wk1ll83sPRwwjo6kU86lYPm3BHGkh6cOz/d/+Qh3dgjSRfEIeBJQZJF1aWdKSRTY1sw79SGK7aPQP/oouXU0o8V6AlwwheJW/Ckvv7ZKP9kCgYEAzEqx1EffeJHpEDxlsC7wj26PdCOSbKJIjaCxP8tUCPbLeADMthFPEKmltjAaU3PrQxdykowE/J1mDaJAOsz+V+Qij4JORJHCvGGsRbGrgJAE8i7WUzrXn9P+5Npx2HwCOhMms0IDTeEDAJcrGxx8nNScS6FVLZ8SPs9azR75N3kCgYEAwaXgBM67A5Wpy3ERWR3k9QLNm9uYwiAjcNhNHhosoYHNJRyMVUkfX8UL6yW6yAGG2YW24Vm1A0nkLolnLHg9t3BJUBB/131NG+jglagr5hltvIdjirvEbHEqfDXmFUkJrN9CTc9hdgZvwNBTdzq1LcCZ6RLR3Y8fl0pKDCwLYJECgYApUYYsACljkmdIAF80xhmjeOIMxFEOJbh05KZU18P0WC4I5GiC/nc2UImSkqIQdOaFWE209BriGNeWNFW3TtS2ZA7VZa580dpIDZ0xL2EXjIljjjOM+962lcL8+G2EMnik1FDEerp+Wt8nlGuEfTt64MmHxmaa5oxjJb8gs34GSQKBgCvIlYeNFRMuyn79Qj1dsYXssYy3edDpQwUraAjHfHDHRHC8H4hr26qeuY5AhULzbKL0mq8IWaEz7Xrer3TmTFljOS9kDjjARAn7VwuVZDD6CICJ79T461eQVq3+91ao32D8GdrYq3iJVoxp1+YYLFhpLFmzmNRD4nmOr9dOIsr1
d3f178f6-372f-4e24-8e83-67ede79a3397	4224b9ab-3f0b-4f05-a409-1964162b564f	certificate	MIICnTCCAYUCBgGdmmkD8zANBgkqhkiG9w0BAQsFADASMRAwDgYDVQQDDAdyZXN0YXBpMB4XDTI2MDQxNzA3NDYwNloXDTM2MDQxNzA3NDc0NlowEjEQMA4GA1UEAwwHcmVzdGFwaTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKaDepKYH73m8Ou39LQiQDiesGr3aMp7nSLtb04nkAnOCLEIGS870Ayfvq7HRbjWJplAIE0vjIjIwCu5f3TZliAVsiqhwol14he7k2dmdv4ZCafoM6coujgV1zz9Xx0ArkD/XyeYn5rl1LOkBt0rvq933sbRGTUq78uWDCcKmxIoMUXxM//9mcVCK1yPfjiXcEJ5DMMXGOFrXM38WKu0iUOh4ny1IQZc3OEpMpCc+YR/3Cwe5QDE5MFIPuAQAs6syVQeBCr0z3WLK5UYwqXqiHKAZkjnvbPtudA99tJTM5QXd3uiiBwceIqcMYUDKI8f5QYiXFeyBQtPM+0uP6TgzJECAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAYGpUQSBLCxmLeOnM2ilqcGMUEVt4ar6mAB5qSy3xeAuvaoGFwErQGgnjPy4CY/Zh0Rn1+Jjj8U35+plwIJYMzPBglmPaj1YoZBL/xr2fS8zJgnJCTbJNArxe9TkMjswdLNV+7MdY13DphW/VqRWNJQLo7nfIWge3GneO2RIvGGy8P3XNHl1DIK8kezbox83BG4RFrvT7z0axGTo+JS/vZawGZDYF8iVsYQO4yi2JihXdO3NZBaPqOBxGGZCmYjgK5qPaISSASN+oBs28tpXMQBlYGfs3niTa9NzliDzywFn/20rtK6zZJf0uwbSqMwExje9ysWySVoeXsWnbvMmU+w==
baa5bb1f-9eca-40cb-81f6-2a1a968c1916	57755678-bbf7-49a2-b39d-c80df845ba0e	allowed-protocol-mapper-types	saml-user-property-mapper
17df72a3-dbf1-4341-a17b-8f9a7b9adab0	57755678-bbf7-49a2-b39d-c80df845ba0e	allowed-protocol-mapper-types	oidc-full-name-mapper
57f94d2d-fb27-4767-b66e-9f15acaaddb0	57755678-bbf7-49a2-b39d-c80df845ba0e	allowed-protocol-mapper-types	oidc-address-mapper
fbd4abd0-83c8-4d94-8f57-511a02c022c0	57755678-bbf7-49a2-b39d-c80df845ba0e	allowed-protocol-mapper-types	oidc-sha256-pairwise-sub-mapper
af7ac34b-ae59-4952-b95f-1a812b5f8bd1	57755678-bbf7-49a2-b39d-c80df845ba0e	allowed-protocol-mapper-types	saml-role-list-mapper
91308f5b-657c-4bb1-9e93-3a8989405d72	57755678-bbf7-49a2-b39d-c80df845ba0e	allowed-protocol-mapper-types	oidc-usermodel-attribute-mapper
4f2bf6fb-7d91-460b-afba-ed313837f336	57755678-bbf7-49a2-b39d-c80df845ba0e	allowed-protocol-mapper-types	saml-user-attribute-mapper
ca70c5f8-48ad-4126-aa4a-181d12ab9914	57755678-bbf7-49a2-b39d-c80df845ba0e	allowed-protocol-mapper-types	oidc-usermodel-property-mapper
9556edd1-f39a-4883-9cbb-516c53f82890	da518ae8-b9eb-4ae4-8379-25ef502d7337	max-clients	200
63b3234c-c5c5-4ecb-a8d2-e8a164d74c37	ac64914e-7b2a-4477-bb98-b5cde29bc860	host-sending-registration-request-must-match	true
309ee602-1c56-4efb-95c8-09669229fb13	ac64914e-7b2a-4477-bb98-b5cde29bc860	client-uris-must-match	true
0cdc5e5f-cfee-4058-a620-83023d23da84	3ee1a946-7bd2-4988-ae15-4c29bc5ee0ac	allowed-protocol-mapper-types	saml-user-property-mapper
b2f56415-2e55-4ada-a20a-659bf2d3eea4	3ee1a946-7bd2-4988-ae15-4c29bc5ee0ac	allowed-protocol-mapper-types	oidc-address-mapper
b53af2c2-dcee-4919-9fc9-3f48c776c508	3ee1a946-7bd2-4988-ae15-4c29bc5ee0ac	allowed-protocol-mapper-types	saml-user-attribute-mapper
b39580d1-402e-4279-9c1e-a90622f221d4	3ee1a946-7bd2-4988-ae15-4c29bc5ee0ac	allowed-protocol-mapper-types	oidc-usermodel-attribute-mapper
f6013169-0aee-4f8e-8627-8cc51c5f386f	3ee1a946-7bd2-4988-ae15-4c29bc5ee0ac	allowed-protocol-mapper-types	oidc-usermodel-property-mapper
2723649d-8510-45e2-9be6-2f725963f349	3ee1a946-7bd2-4988-ae15-4c29bc5ee0ac	allowed-protocol-mapper-types	oidc-full-name-mapper
2d61f735-6f7c-4400-ae68-7812109fb3c6	3ee1a946-7bd2-4988-ae15-4c29bc5ee0ac	allowed-protocol-mapper-types	saml-role-list-mapper
75ad79a2-d2e1-4bb0-a649-ed805470e8ad	3ee1a946-7bd2-4988-ae15-4c29bc5ee0ac	allowed-protocol-mapper-types	oidc-sha256-pairwise-sub-mapper
c6bd6ccf-c2be-4790-9fc7-09f12942586a	260d9d92-d950-4ada-9ce1-5bdc0032d1d0	allow-default-scopes	true
1de40340-c7cc-4463-82e0-00634df02d8c	f17f4d45-e87a-403a-af8d-ed1f35e0b2ca	allow-default-scopes	true
\.


--
-- Data for Name: composite_role; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.composite_role (composite, child_role) FROM stdin;
a91e1103-1927-4338-a982-fcf10d5aa602	e34aa68f-bb34-4c66-b47b-72b578d00924
a91e1103-1927-4338-a982-fcf10d5aa602	2dd20a52-cdd8-43e6-901e-b9678488347f
a91e1103-1927-4338-a982-fcf10d5aa602	df885e16-9dbe-42f8-bfe5-9eef3a251962
a91e1103-1927-4338-a982-fcf10d5aa602	07ecb932-2ec2-472e-90cc-918a0e6dce19
a91e1103-1927-4338-a982-fcf10d5aa602	13a00198-eb31-49d2-b42f-3c678b8ccf72
a91e1103-1927-4338-a982-fcf10d5aa602	b035c13d-c28f-4bd9-9d7e-32e3bd387bf4
a91e1103-1927-4338-a982-fcf10d5aa602	c086bb7f-b16d-463e-bd59-89c142548fe0
a91e1103-1927-4338-a982-fcf10d5aa602	10587816-53d7-47fa-a1ce-77a9513cbdd7
a91e1103-1927-4338-a982-fcf10d5aa602	85ec90e9-9c0c-4190-9c1f-02115cce1069
a91e1103-1927-4338-a982-fcf10d5aa602	0594249a-170e-43cf-bd93-c200d11d5134
a91e1103-1927-4338-a982-fcf10d5aa602	dce18296-0f48-4afc-b52b-ca63eb214b30
a91e1103-1927-4338-a982-fcf10d5aa602	e218922d-f7c2-4a39-bbcc-0fa380e68256
a91e1103-1927-4338-a982-fcf10d5aa602	823c361b-4f1d-4428-9af3-bcc3aecfe5fc
a91e1103-1927-4338-a982-fcf10d5aa602	a3cc1f45-5524-49a6-a7a1-26372dcf7e56
a91e1103-1927-4338-a982-fcf10d5aa602	533c295c-2f87-4bd1-be03-950ded9fe1db
a91e1103-1927-4338-a982-fcf10d5aa602	e96d1862-0b58-465e-a5b8-6fc664c3cc3f
a91e1103-1927-4338-a982-fcf10d5aa602	9766bd62-dccf-4bc5-ae8e-1c5a62c81278
a91e1103-1927-4338-a982-fcf10d5aa602	d151fe6a-c6c5-4aeb-bcaf-cf78ffcb551c
07ecb932-2ec2-472e-90cc-918a0e6dce19	533c295c-2f87-4bd1-be03-950ded9fe1db
07ecb932-2ec2-472e-90cc-918a0e6dce19	d151fe6a-c6c5-4aeb-bcaf-cf78ffcb551c
13a00198-eb31-49d2-b42f-3c678b8ccf72	e96d1862-0b58-465e-a5b8-6fc664c3cc3f
49673cc1-a91d-4029-bb02-bbf4936dc948	407de05d-5409-47a2-8914-792c715494c1
49673cc1-a91d-4029-bb02-bbf4936dc948	c5e9b565-c90e-41e5-8421-61c2b3b46849
c5e9b565-c90e-41e5-8421-61c2b3b46849	8432de7c-27ca-46b1-abfb-cd333b85be3f
b64fc884-a926-44d3-b1c3-f5fc3862ae21	a8340c59-9d27-42cf-bbb8-e020202af824
a91e1103-1927-4338-a982-fcf10d5aa602	f3c54394-9f98-4375-b855-795c2481d292
49673cc1-a91d-4029-bb02-bbf4936dc948	1d9236ed-2238-4a3c-be4f-861c9af05d8b
49673cc1-a91d-4029-bb02-bbf4936dc948	7bb23998-fd6a-4c3a-9c4b-681d0f29f768
a91e1103-1927-4338-a982-fcf10d5aa602	0b9acf79-3ada-4ead-93e6-c5b12cc5f261
a91e1103-1927-4338-a982-fcf10d5aa602	46bfba08-7369-4be1-b940-61cdbb5193f5
a91e1103-1927-4338-a982-fcf10d5aa602	f22a3115-fa6f-47b4-a1cd-6bba0d2d9c25
a91e1103-1927-4338-a982-fcf10d5aa602	7febfbcc-deba-4a3f-ae58-bd61ce0558e7
a91e1103-1927-4338-a982-fcf10d5aa602	14fb8099-cbd9-4c0b-8604-913da53800e4
a91e1103-1927-4338-a982-fcf10d5aa602	d0c0a4ca-5760-4811-a1a1-bae06d1955d4
a91e1103-1927-4338-a982-fcf10d5aa602	07d31104-1aa4-48ef-ace3-6d907b75501b
a91e1103-1927-4338-a982-fcf10d5aa602	b887ac4a-c5df-4c1d-ac15-a303059776cc
a91e1103-1927-4338-a982-fcf10d5aa602	43450182-8aa3-4cdc-a1ca-c8d3e115f56f
a91e1103-1927-4338-a982-fcf10d5aa602	44a15d66-c313-4293-81a0-2d497984c81c
a91e1103-1927-4338-a982-fcf10d5aa602	b535d11e-cf83-4a68-ae4a-b4a92c527e9e
a91e1103-1927-4338-a982-fcf10d5aa602	8d609d14-0a87-4f61-a85a-99e7c5f40940
a91e1103-1927-4338-a982-fcf10d5aa602	21eb514e-3ced-4c9a-8b63-9a5d0c06a3b2
a91e1103-1927-4338-a982-fcf10d5aa602	b2872139-b84f-4016-a6a5-c05d78ad1e16
a91e1103-1927-4338-a982-fcf10d5aa602	ba18dda7-5bac-4525-ab32-79d21e9d6f80
a91e1103-1927-4338-a982-fcf10d5aa602	1d6d3491-540c-4643-940d-1cef1bba6a39
a91e1103-1927-4338-a982-fcf10d5aa602	06356291-7177-4d5f-afd7-e7636f1f4f32
7febfbcc-deba-4a3f-ae58-bd61ce0558e7	ba18dda7-5bac-4525-ab32-79d21e9d6f80
f22a3115-fa6f-47b4-a1cd-6bba0d2d9c25	b2872139-b84f-4016-a6a5-c05d78ad1e16
f22a3115-fa6f-47b4-a1cd-6bba0d2d9c25	06356291-7177-4d5f-afd7-e7636f1f4f32
d5870091-ed66-4991-b602-4725846434a1	d813378e-7717-4b45-8b80-acb330ed19a8
d5870091-ed66-4991-b602-4725846434a1	dd915c0a-2b13-40f1-b7ea-2982fdbc4859
d5870091-ed66-4991-b602-4725846434a1	e9ce8d0d-534e-4b7c-978d-7dc20683deb9
d5870091-ed66-4991-b602-4725846434a1	a410a813-b586-4692-80bb-19f1653b60ce
d5870091-ed66-4991-b602-4725846434a1	ba0e337c-0e9d-4e1d-bf3f-fa40d392f929
d5870091-ed66-4991-b602-4725846434a1	92969131-dbb6-40c0-8e62-39083d55f10d
d5870091-ed66-4991-b602-4725846434a1	d1957bdf-6cf9-484e-8046-f00770fbef13
d5870091-ed66-4991-b602-4725846434a1	c265dee3-8c72-49dd-8fb1-89663b0f5ef1
d5870091-ed66-4991-b602-4725846434a1	654b8d30-489d-449d-ba36-9973716c9ffa
d5870091-ed66-4991-b602-4725846434a1	c72b0c13-e4de-49c0-b314-2b7a0d8ad256
d5870091-ed66-4991-b602-4725846434a1	e84cb593-507e-4af1-b3b2-3ce88baccad6
d5870091-ed66-4991-b602-4725846434a1	11ee0583-ffae-4de2-8923-1d9df3152f6a
d5870091-ed66-4991-b602-4725846434a1	354fa32a-b1a8-43c8-8319-8469601c9545
d5870091-ed66-4991-b602-4725846434a1	5511c2ad-4b7e-4bee-b8ef-05a15458a8f2
d5870091-ed66-4991-b602-4725846434a1	619cf3b7-80e1-4c52-a866-1d2c9d3cc19a
d5870091-ed66-4991-b602-4725846434a1	c6362e0d-4ac7-40fc-8909-b1c4625ee348
d5870091-ed66-4991-b602-4725846434a1	e67fab09-a7c8-4d32-b893-02b04281288c
03e71ffe-54f7-455a-88b8-f7949197653d	53bf6aaf-22ed-4b89-a182-7123ad0305ad
a410a813-b586-4692-80bb-19f1653b60ce	619cf3b7-80e1-4c52-a866-1d2c9d3cc19a
e9ce8d0d-534e-4b7c-978d-7dc20683deb9	5511c2ad-4b7e-4bee-b8ef-05a15458a8f2
e9ce8d0d-534e-4b7c-978d-7dc20683deb9	e67fab09-a7c8-4d32-b893-02b04281288c
03e71ffe-54f7-455a-88b8-f7949197653d	699d2e77-8b2f-4bd1-bd58-71eb020ce953
699d2e77-8b2f-4bd1-bd58-71eb020ce953	44bfd1cc-4be3-4246-9b95-87a84af93bad
0ca0dc88-f0e7-4fef-bff1-2ada64d7c787	0fd3d905-3c53-48e4-ad52-e24b263d035a
a91e1103-1927-4338-a982-fcf10d5aa602	f36f23fd-59e1-45cc-9736-9d5dc46e2b9c
d5870091-ed66-4991-b602-4725846434a1	669afa85-865d-4228-8485-33d8271cf530
03e71ffe-54f7-455a-88b8-f7949197653d	5e274b31-a53a-4f89-a5cf-103dbae7cb1d
03e71ffe-54f7-455a-88b8-f7949197653d	594ff37a-5315-4518-bd00-a52f5d707ec2
\.


--
-- Data for Name: credential; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.credential (id, salt, type, user_id, created_date, user_label, secret_data, credential_data, priority, version) FROM stdin;
021b11c0-08bc-48fe-abbe-fe99034a501e	\N	password	a8d41fc7-b428-451f-aade-6631f5b95e71	1776409013514	\N	{"value":"yFmTHkjNzxjdW035fYKBTFdJG5fGvxzTJecg13RV7L8=","salt":"lA8tsAMXi+GIQRsRzhpDiQ==","additionalParameters":{}}	{"hashIterations":5,"algorithm":"argon2","additionalParameters":{"hashLength":["32"],"memory":["7168"],"type":["id"],"version":["1.3"],"parallelism":["1"]}}	10	0
dd5e6bcc-215d-48f2-b5ea-269fc545ba60	\N	password	7d453f22-6ff1-41b9-98b7-57ceff01f445	1776412298429	My password	{"value":"AOtA0wS/6PsW1KSpf07hy8nX6rBQuN+V4nNQGXZNL/0=","salt":"TYuBvXZhrT5hhDowhblL+w==","additionalParameters":{}}	{"hashIterations":5,"algorithm":"argon2","additionalParameters":{"hashLength":["32"],"memory":["7168"],"type":["id"],"version":["1.3"],"parallelism":["1"]}}	10	1
\.


--
-- Data for Name: databasechangelog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.databasechangelog (id, author, filename, dateexecuted, orderexecuted, exectype, md5sum, description, comments, tag, liquibase, contexts, labels, deployment_id) FROM stdin;
1.0.0.Final-KEYCLOAK-5461	sthorger@redhat.com	META-INF/jpa-changelog-1.0.0.Final.xml	2026-04-17 06:56:45.635338	1	EXECUTED	9:6f1016664e21e16d26517a4418f5e3df	createTable tableName=APPLICATION_DEFAULT_ROLES; createTable tableName=CLIENT; createTable tableName=CLIENT_SESSION; createTable tableName=CLIENT_SESSION_ROLE; createTable tableName=COMPOSITE_ROLE; createTable tableName=CREDENTIAL; createTable tab...		\N	4.33.0	\N	\N	6409001035
1.0.0.Final-KEYCLOAK-5461	sthorger@redhat.com	META-INF/db2-jpa-changelog-1.0.0.Final.xml	2026-04-17 06:56:45.652397	2	MARK_RAN	9:828775b1596a07d1200ba1d49e5e3941	createTable tableName=APPLICATION_DEFAULT_ROLES; createTable tableName=CLIENT; createTable tableName=CLIENT_SESSION; createTable tableName=CLIENT_SESSION_ROLE; createTable tableName=COMPOSITE_ROLE; createTable tableName=CREDENTIAL; createTable tab...		\N	4.33.0	\N	\N	6409001035
1.1.0.Beta1	sthorger@redhat.com	META-INF/jpa-changelog-1.1.0.Beta1.xml	2026-04-17 06:56:45.694647	3	EXECUTED	9:5f090e44a7d595883c1fb61f4b41fd38	delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION; createTable tableName=CLIENT_ATTRIBUTES; createTable tableName=CLIENT_SESSION_NOTE; createTable tableName=APP_NODE_REGISTRATIONS; addColumn table...		\N	4.33.0	\N	\N	6409001035
1.1.0.Final	sthorger@redhat.com	META-INF/jpa-changelog-1.1.0.Final.xml	2026-04-17 06:56:45.718886	4	EXECUTED	9:c07e577387a3d2c04d1adc9aaad8730e	renameColumn newColumnName=EVENT_TIME, oldColumnName=TIME, tableName=EVENT_ENTITY		\N	4.33.0	\N	\N	6409001035
1.2.0.Beta1	psilva@redhat.com	META-INF/jpa-changelog-1.2.0.Beta1.xml	2026-04-17 06:56:45.782481	5	EXECUTED	9:b68ce996c655922dbcd2fe6b6ae72686	delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION; createTable tableName=PROTOCOL_MAPPER; createTable tableName=PROTOCOL_MAPPER_CONFIG; createTable tableName=...		\N	4.33.0	\N	\N	6409001035
1.2.0.Beta1	psilva@redhat.com	META-INF/db2-jpa-changelog-1.2.0.Beta1.xml	2026-04-17 06:56:45.795023	6	MARK_RAN	9:543b5c9989f024fe35c6f6c5a97de88e	delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION; createTable tableName=PROTOCOL_MAPPER; createTable tableName=PROTOCOL_MAPPER_CONFIG; createTable tableName=...		\N	4.33.0	\N	\N	6409001035
1.2.0.RC1	bburke@redhat.com	META-INF/jpa-changelog-1.2.0.CR1.xml	2026-04-17 06:56:45.857317	7	EXECUTED	9:765afebbe21cf5bbca048e632df38336	delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION_NOTE; delete tableName=USER_SESSION; createTable tableName=MIGRATION_MODEL; createTable tableName=IDENTITY_P...		\N	4.33.0	\N	\N	6409001035
1.2.0.RC1	bburke@redhat.com	META-INF/db2-jpa-changelog-1.2.0.CR1.xml	2026-04-17 06:56:45.872379	8	MARK_RAN	9:db4a145ba11a6fdaefb397f6dbf829a1	delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION_NOTE; delete tableName=USER_SESSION; createTable tableName=MIGRATION_MODEL; createTable tableName=IDENTITY_P...		\N	4.33.0	\N	\N	6409001035
1.2.0.Final	keycloak	META-INF/jpa-changelog-1.2.0.Final.xml	2026-04-17 06:56:45.886778	9	EXECUTED	9:9d05c7be10cdb873f8bcb41bc3a8ab23	update tableName=CLIENT; update tableName=CLIENT; update tableName=CLIENT		\N	4.33.0	\N	\N	6409001035
1.3.0	bburke@redhat.com	META-INF/jpa-changelog-1.3.0.xml	2026-04-17 06:56:45.940346	10	EXECUTED	9:18593702353128d53111f9b1ff0b82b8	delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_PROT_MAPPER; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION_NOTE; delete tableName=USER_SESSION; createTable tableName=ADMI...		\N	4.33.0	\N	\N	6409001035
1.4.0	bburke@redhat.com	META-INF/jpa-changelog-1.4.0.xml	2026-04-17 06:56:45.992966	11	EXECUTED	9:6122efe5f090e41a85c0f1c9e52cbb62	delete tableName=CLIENT_SESSION_AUTH_STATUS; delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_PROT_MAPPER; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION_NOTE; delete table...		\N	4.33.0	\N	\N	6409001035
1.4.0	bburke@redhat.com	META-INF/db2-jpa-changelog-1.4.0.xml	2026-04-17 06:56:45.999982	12	MARK_RAN	9:e1ff28bf7568451453f844c5d54bb0b5	delete tableName=CLIENT_SESSION_AUTH_STATUS; delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_PROT_MAPPER; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION_NOTE; delete table...		\N	4.33.0	\N	\N	6409001035
1.5.0	bburke@redhat.com	META-INF/jpa-changelog-1.5.0.xml	2026-04-17 06:56:46.032112	13	EXECUTED	9:7af32cd8957fbc069f796b61217483fd	delete tableName=CLIENT_SESSION_AUTH_STATUS; delete tableName=CLIENT_SESSION_ROLE; delete tableName=CLIENT_SESSION_PROT_MAPPER; delete tableName=CLIENT_SESSION_NOTE; delete tableName=CLIENT_SESSION; delete tableName=USER_SESSION_NOTE; delete table...		\N	4.33.0	\N	\N	6409001035
1.6.1_from15	mposolda@redhat.com	META-INF/jpa-changelog-1.6.1.xml	2026-04-17 06:56:46.050828	14	EXECUTED	9:6005e15e84714cd83226bf7879f54190	addColumn tableName=REALM; addColumn tableName=KEYCLOAK_ROLE; addColumn tableName=CLIENT; createTable tableName=OFFLINE_USER_SESSION; createTable tableName=OFFLINE_CLIENT_SESSION; addPrimaryKey constraintName=CONSTRAINT_OFFL_US_SES_PK2, tableName=...		\N	4.33.0	\N	\N	6409001035
1.6.1_from16-pre	mposolda@redhat.com	META-INF/jpa-changelog-1.6.1.xml	2026-04-17 06:56:46.054681	15	MARK_RAN	9:bf656f5a2b055d07f314431cae76f06c	delete tableName=OFFLINE_CLIENT_SESSION; delete tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	6409001035
1.6.1_from16	mposolda@redhat.com	META-INF/jpa-changelog-1.6.1.xml	2026-04-17 06:56:46.068687	16	MARK_RAN	9:f8dadc9284440469dcf71e25ca6ab99b	dropPrimaryKey constraintName=CONSTRAINT_OFFLINE_US_SES_PK, tableName=OFFLINE_USER_SESSION; dropPrimaryKey constraintName=CONSTRAINT_OFFLINE_CL_SES_PK, tableName=OFFLINE_CLIENT_SESSION; addColumn tableName=OFFLINE_USER_SESSION; update tableName=OF...		\N	4.33.0	\N	\N	6409001035
1.6.1	mposolda@redhat.com	META-INF/jpa-changelog-1.6.1.xml	2026-04-17 06:56:46.073263	17	EXECUTED	9:d41d8cd98f00b204e9800998ecf8427e	empty		\N	4.33.0	\N	\N	6409001035
1.7.0	bburke@redhat.com	META-INF/jpa-changelog-1.7.0.xml	2026-04-17 06:56:46.117731	18	EXECUTED	9:3368ff0be4c2855ee2dd9ca813b38d8e	createTable tableName=KEYCLOAK_GROUP; createTable tableName=GROUP_ROLE_MAPPING; createTable tableName=GROUP_ATTRIBUTE; createTable tableName=USER_GROUP_MEMBERSHIP; createTable tableName=REALM_DEFAULT_GROUPS; addColumn tableName=IDENTITY_PROVIDER; ...		\N	4.33.0	\N	\N	6409001035
1.8.0	mposolda@redhat.com	META-INF/jpa-changelog-1.8.0.xml	2026-04-17 06:56:46.142477	19	EXECUTED	9:8ac2fb5dd030b24c0570a763ed75ed20	addColumn tableName=IDENTITY_PROVIDER; createTable tableName=CLIENT_TEMPLATE; createTable tableName=CLIENT_TEMPLATE_ATTRIBUTES; createTable tableName=TEMPLATE_SCOPE_MAPPING; dropNotNullConstraint columnName=CLIENT_ID, tableName=PROTOCOL_MAPPER; ad...		\N	4.33.0	\N	\N	6409001035
1.8.0-2	keycloak	META-INF/jpa-changelog-1.8.0.xml	2026-04-17 06:56:46.167797	20	EXECUTED	9:f91ddca9b19743db60e3057679810e6c	dropDefaultValue columnName=ALGORITHM, tableName=CREDENTIAL; update tableName=CREDENTIAL		\N	4.33.0	\N	\N	6409001035
22.0.5-24031	keycloak	META-INF/jpa-changelog-22.0.0.xml	2026-04-17 06:56:49.331871	119	MARK_RAN	9:a60d2d7b315ec2d3eba9e2f145f9df28	customChange		\N	4.33.0	\N	\N	6409001035
1.8.0	mposolda@redhat.com	META-INF/db2-jpa-changelog-1.8.0.xml	2026-04-17 06:56:46.184246	21	MARK_RAN	9:831e82914316dc8a57dc09d755f23c51	addColumn tableName=IDENTITY_PROVIDER; createTable tableName=CLIENT_TEMPLATE; createTable tableName=CLIENT_TEMPLATE_ATTRIBUTES; createTable tableName=TEMPLATE_SCOPE_MAPPING; dropNotNullConstraint columnName=CLIENT_ID, tableName=PROTOCOL_MAPPER; ad...		\N	4.33.0	\N	\N	6409001035
1.8.0-2	keycloak	META-INF/db2-jpa-changelog-1.8.0.xml	2026-04-17 06:56:46.195824	22	MARK_RAN	9:f91ddca9b19743db60e3057679810e6c	dropDefaultValue columnName=ALGORITHM, tableName=CREDENTIAL; update tableName=CREDENTIAL		\N	4.33.0	\N	\N	6409001035
1.9.0	mposolda@redhat.com	META-INF/jpa-changelog-1.9.0.xml	2026-04-17 06:56:46.248328	23	EXECUTED	9:bc3d0f9e823a69dc21e23e94c7a94bb1	update tableName=REALM; update tableName=REALM; update tableName=REALM; update tableName=REALM; update tableName=CREDENTIAL; update tableName=CREDENTIAL; update tableName=CREDENTIAL; update tableName=REALM; update tableName=REALM; customChange; dr...		\N	4.33.0	\N	\N	6409001035
1.9.1	keycloak	META-INF/jpa-changelog-1.9.1.xml	2026-04-17 06:56:46.268118	24	EXECUTED	9:c9999da42f543575ab790e76439a2679	modifyDataType columnName=PRIVATE_KEY, tableName=REALM; modifyDataType columnName=PUBLIC_KEY, tableName=REALM; modifyDataType columnName=CERTIFICATE, tableName=REALM		\N	4.33.0	\N	\N	6409001035
1.9.1	keycloak	META-INF/db2-jpa-changelog-1.9.1.xml	2026-04-17 06:56:46.284307	25	MARK_RAN	9:0d6c65c6f58732d81569e77b10ba301d	modifyDataType columnName=PRIVATE_KEY, tableName=REALM; modifyDataType columnName=CERTIFICATE, tableName=REALM		\N	4.33.0	\N	\N	6409001035
1.9.2	keycloak	META-INF/jpa-changelog-1.9.2.xml	2026-04-17 06:56:46.458948	26	EXECUTED	9:fc576660fc016ae53d2d4778d84d86d0	createIndex indexName=IDX_USER_EMAIL, tableName=USER_ENTITY; createIndex indexName=IDX_USER_ROLE_MAPPING, tableName=USER_ROLE_MAPPING; createIndex indexName=IDX_USER_GROUP_MAPPING, tableName=USER_GROUP_MEMBERSHIP; createIndex indexName=IDX_USER_CO...		\N	4.33.0	\N	\N	6409001035
authz-2.0.0	psilva@redhat.com	META-INF/jpa-changelog-authz-2.0.0.xml	2026-04-17 06:56:46.497895	27	EXECUTED	9:43ed6b0da89ff77206289e87eaa9c024	createTable tableName=RESOURCE_SERVER; addPrimaryKey constraintName=CONSTRAINT_FARS, tableName=RESOURCE_SERVER; addUniqueConstraint constraintName=UK_AU8TT6T700S9V50BU18WS5HA6, tableName=RESOURCE_SERVER; createTable tableName=RESOURCE_SERVER_RESOU...		\N	4.33.0	\N	\N	6409001035
authz-2.5.1	psilva@redhat.com	META-INF/jpa-changelog-authz-2.5.1.xml	2026-04-17 06:56:46.503238	28	EXECUTED	9:44bae577f551b3738740281eceb4ea70	update tableName=RESOURCE_SERVER_POLICY		\N	4.33.0	\N	\N	6409001035
2.1.0-KEYCLOAK-5461	bburke@redhat.com	META-INF/jpa-changelog-2.1.0.xml	2026-04-17 06:56:46.543018	29	EXECUTED	9:bd88e1f833df0420b01e114533aee5e8	createTable tableName=BROKER_LINK; createTable tableName=FED_USER_ATTRIBUTE; createTable tableName=FED_USER_CONSENT; createTable tableName=FED_USER_CONSENT_ROLE; createTable tableName=FED_USER_CONSENT_PROT_MAPPER; createTable tableName=FED_USER_CR...		\N	4.33.0	\N	\N	6409001035
2.2.0	bburke@redhat.com	META-INF/jpa-changelog-2.2.0.xml	2026-04-17 06:56:46.569762	30	EXECUTED	9:a7022af5267f019d020edfe316ef4371	addColumn tableName=ADMIN_EVENT_ENTITY; createTable tableName=CREDENTIAL_ATTRIBUTE; createTable tableName=FED_CREDENTIAL_ATTRIBUTE; modifyDataType columnName=VALUE, tableName=CREDENTIAL; addForeignKeyConstraint baseTableName=FED_CREDENTIAL_ATTRIBU...		\N	4.33.0	\N	\N	6409001035
2.3.0	bburke@redhat.com	META-INF/jpa-changelog-2.3.0.xml	2026-04-17 06:56:46.593919	31	EXECUTED	9:fc155c394040654d6a79227e56f5e25a	createTable tableName=FEDERATED_USER; addPrimaryKey constraintName=CONSTR_FEDERATED_USER, tableName=FEDERATED_USER; dropDefaultValue columnName=TOTP, tableName=USER_ENTITY; dropColumn columnName=TOTP, tableName=USER_ENTITY; addColumn tableName=IDE...		\N	4.33.0	\N	\N	6409001035
2.4.0	bburke@redhat.com	META-INF/jpa-changelog-2.4.0.xml	2026-04-17 06:56:46.599868	32	EXECUTED	9:eac4ffb2a14795e5dc7b426063e54d88	customChange		\N	4.33.0	\N	\N	6409001035
2.5.0	bburke@redhat.com	META-INF/jpa-changelog-2.5.0.xml	2026-04-17 06:56:46.618731	33	EXECUTED	9:54937c05672568c4c64fc9524c1e9462	customChange; modifyDataType columnName=USER_ID, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	6409001035
2.5.0-unicode-oracle	hmlnarik@redhat.com	META-INF/jpa-changelog-2.5.0.xml	2026-04-17 06:56:46.635633	34	MARK_RAN	9:f9753208029f582525ed12011a19d054	modifyDataType columnName=DESCRIPTION, tableName=AUTHENTICATION_FLOW; modifyDataType columnName=DESCRIPTION, tableName=CLIENT_TEMPLATE; modifyDataType columnName=DESCRIPTION, tableName=RESOURCE_SERVER_POLICY; modifyDataType columnName=DESCRIPTION,...		\N	4.33.0	\N	\N	6409001035
2.5.0-unicode-other-dbs	hmlnarik@redhat.com	META-INF/jpa-changelog-2.5.0.xml	2026-04-17 06:56:46.65829	35	EXECUTED	9:33d72168746f81f98ae3a1e8e0ca3554	modifyDataType columnName=DESCRIPTION, tableName=AUTHENTICATION_FLOW; modifyDataType columnName=DESCRIPTION, tableName=CLIENT_TEMPLATE; modifyDataType columnName=DESCRIPTION, tableName=RESOURCE_SERVER_POLICY; modifyDataType columnName=DESCRIPTION,...		\N	4.33.0	\N	\N	6409001035
2.5.0-duplicate-email-support	slawomir@dabek.name	META-INF/jpa-changelog-2.5.0.xml	2026-04-17 06:56:46.68569	36	EXECUTED	9:61b6d3d7a4c0e0024b0c839da283da0c	addColumn tableName=REALM		\N	4.33.0	\N	\N	6409001035
2.5.0-unique-group-names	hmlnarik@redhat.com	META-INF/jpa-changelog-2.5.0.xml	2026-04-17 06:56:46.710986	37	EXECUTED	9:8dcac7bdf7378e7d823cdfddebf72fda	addUniqueConstraint constraintName=SIBLING_NAMES, tableName=KEYCLOAK_GROUP		\N	4.33.0	\N	\N	6409001035
2.5.1	bburke@redhat.com	META-INF/jpa-changelog-2.5.1.xml	2026-04-17 06:56:46.727627	38	EXECUTED	9:a2b870802540cb3faa72098db5388af3	addColumn tableName=FED_USER_CONSENT		\N	4.33.0	\N	\N	6409001035
3.0.0	bburke@redhat.com	META-INF/jpa-changelog-3.0.0.xml	2026-04-17 06:56:46.748083	39	EXECUTED	9:132a67499ba24bcc54fb5cbdcfe7e4c0	addColumn tableName=IDENTITY_PROVIDER		\N	4.33.0	\N	\N	6409001035
3.2.0-fix	keycloak	META-INF/jpa-changelog-3.2.0.xml	2026-04-17 06:56:46.751823	40	MARK_RAN	9:938f894c032f5430f2b0fafb1a243462	addNotNullConstraint columnName=REALM_ID, tableName=CLIENT_INITIAL_ACCESS		\N	4.33.0	\N	\N	6409001035
3.2.0-fix-with-keycloak-5416	keycloak	META-INF/jpa-changelog-3.2.0.xml	2026-04-17 06:56:46.768309	41	MARK_RAN	9:845c332ff1874dc5d35974b0babf3006	dropIndex indexName=IDX_CLIENT_INIT_ACC_REALM, tableName=CLIENT_INITIAL_ACCESS; addNotNullConstraint columnName=REALM_ID, tableName=CLIENT_INITIAL_ACCESS; createIndex indexName=IDX_CLIENT_INIT_ACC_REALM, tableName=CLIENT_INITIAL_ACCESS		\N	4.33.0	\N	\N	6409001035
3.2.0-fix-offline-sessions	hmlnarik	META-INF/jpa-changelog-3.2.0.xml	2026-04-17 06:56:46.779118	42	EXECUTED	9:fc86359c079781adc577c5a217e4d04c	customChange		\N	4.33.0	\N	\N	6409001035
3.2.0-fixed	keycloak	META-INF/jpa-changelog-3.2.0.xml	2026-04-17 06:56:47.438151	43	EXECUTED	9:59a64800e3c0d09b825f8a3b444fa8f4	addColumn tableName=REALM; dropPrimaryKey constraintName=CONSTRAINT_OFFL_CL_SES_PK2, tableName=OFFLINE_CLIENT_SESSION; dropColumn columnName=CLIENT_SESSION_ID, tableName=OFFLINE_CLIENT_SESSION; addPrimaryKey constraintName=CONSTRAINT_OFFL_CL_SES_P...		\N	4.33.0	\N	\N	6409001035
3.3.0	keycloak	META-INF/jpa-changelog-3.3.0.xml	2026-04-17 06:56:47.45759	44	EXECUTED	9:d48d6da5c6ccf667807f633fe489ce88	addColumn tableName=USER_ENTITY		\N	4.33.0	\N	\N	6409001035
authz-3.4.0.CR1-resource-server-pk-change-part1	glavoie@gmail.com	META-INF/jpa-changelog-authz-3.4.0.CR1.xml	2026-04-17 06:56:47.481467	45	EXECUTED	9:dde36f7973e80d71fceee683bc5d2951	addColumn tableName=RESOURCE_SERVER_POLICY; addColumn tableName=RESOURCE_SERVER_RESOURCE; addColumn tableName=RESOURCE_SERVER_SCOPE		\N	4.33.0	\N	\N	6409001035
authz-3.4.0.CR1-resource-server-pk-change-part2-KEYCLOAK-6095	hmlnarik@redhat.com	META-INF/jpa-changelog-authz-3.4.0.CR1.xml	2026-04-17 06:56:47.48877	46	EXECUTED	9:b855e9b0a406b34fa323235a0cf4f640	customChange		\N	4.33.0	\N	\N	6409001035
authz-3.4.0.CR1-resource-server-pk-change-part3-fixed	glavoie@gmail.com	META-INF/jpa-changelog-authz-3.4.0.CR1.xml	2026-04-17 06:56:47.500686	47	MARK_RAN	9:51abbacd7b416c50c4421a8cabf7927e	dropIndex indexName=IDX_RES_SERV_POL_RES_SERV, tableName=RESOURCE_SERVER_POLICY; dropIndex indexName=IDX_RES_SRV_RES_RES_SRV, tableName=RESOURCE_SERVER_RESOURCE; dropIndex indexName=IDX_RES_SRV_SCOPE_RES_SRV, tableName=RESOURCE_SERVER_SCOPE		\N	4.33.0	\N	\N	6409001035
authz-3.4.0.CR1-resource-server-pk-change-part3-fixed-nodropindex	glavoie@gmail.com	META-INF/jpa-changelog-authz-3.4.0.CR1.xml	2026-04-17 06:56:47.575377	48	EXECUTED	9:bdc99e567b3398bac83263d375aad143	addNotNullConstraint columnName=RESOURCE_SERVER_CLIENT_ID, tableName=RESOURCE_SERVER_POLICY; addNotNullConstraint columnName=RESOURCE_SERVER_CLIENT_ID, tableName=RESOURCE_SERVER_RESOURCE; addNotNullConstraint columnName=RESOURCE_SERVER_CLIENT_ID, ...		\N	4.33.0	\N	\N	6409001035
authn-3.4.0.CR1-refresh-token-max-reuse	glavoie@gmail.com	META-INF/jpa-changelog-authz-3.4.0.CR1.xml	2026-04-17 06:56:47.593032	49	EXECUTED	9:d198654156881c46bfba39abd7769e69	addColumn tableName=REALM		\N	4.33.0	\N	\N	6409001035
3.4.0	keycloak	META-INF/jpa-changelog-3.4.0.xml	2026-04-17 06:56:47.630925	50	EXECUTED	9:cfdd8736332ccdd72c5256ccb42335db	addPrimaryKey constraintName=CONSTRAINT_REALM_DEFAULT_ROLES, tableName=REALM_DEFAULT_ROLES; addPrimaryKey constraintName=CONSTRAINT_COMPOSITE_ROLE, tableName=COMPOSITE_ROLE; addPrimaryKey constraintName=CONSTR_REALM_DEFAULT_GROUPS, tableName=REALM...		\N	4.33.0	\N	\N	6409001035
3.4.0-KEYCLOAK-5230	hmlnarik@redhat.com	META-INF/jpa-changelog-3.4.0.xml	2026-04-17 06:56:47.795188	51	EXECUTED	9:7c84de3d9bd84d7f077607c1a4dcb714	createIndex indexName=IDX_FU_ATTRIBUTE, tableName=FED_USER_ATTRIBUTE; createIndex indexName=IDX_FU_CONSENT, tableName=FED_USER_CONSENT; createIndex indexName=IDX_FU_CONSENT_RU, tableName=FED_USER_CONSENT; createIndex indexName=IDX_FU_CREDENTIAL, t...		\N	4.33.0	\N	\N	6409001035
3.4.1	psilva@redhat.com	META-INF/jpa-changelog-3.4.1.xml	2026-04-17 06:56:47.81177	52	EXECUTED	9:5a6bb36cbefb6a9d6928452c0852af2d	modifyDataType columnName=VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	6409001035
3.4.2	keycloak	META-INF/jpa-changelog-3.4.2.xml	2026-04-17 06:56:47.822267	53	EXECUTED	9:8f23e334dbc59f82e0a328373ca6ced0	update tableName=REALM		\N	4.33.0	\N	\N	6409001035
3.4.2-KEYCLOAK-5172	mkanis@redhat.com	META-INF/jpa-changelog-3.4.2.xml	2026-04-17 06:56:47.838869	54	EXECUTED	9:9156214268f09d970cdf0e1564d866af	update tableName=CLIENT		\N	4.33.0	\N	\N	6409001035
4.0.0-KEYCLOAK-6335	bburke@redhat.com	META-INF/jpa-changelog-4.0.0.xml	2026-04-17 06:56:47.874633	55	EXECUTED	9:db806613b1ed154826c02610b7dbdf74	createTable tableName=CLIENT_AUTH_FLOW_BINDINGS; addPrimaryKey constraintName=C_CLI_FLOW_BIND, tableName=CLIENT_AUTH_FLOW_BINDINGS		\N	4.33.0	\N	\N	6409001035
4.0.0-CLEANUP-UNUSED-TABLE	bburke@redhat.com	META-INF/jpa-changelog-4.0.0.xml	2026-04-17 06:56:47.889371	56	EXECUTED	9:229a041fb72d5beac76bb94a5fa709de	dropTable tableName=CLIENT_IDENTITY_PROV_MAPPING		\N	4.33.0	\N	\N	6409001035
4.0.0-KEYCLOAK-6228	bburke@redhat.com	META-INF/jpa-changelog-4.0.0.xml	2026-04-17 06:56:47.927	57	EXECUTED	9:079899dade9c1e683f26b2aa9ca6ff04	dropUniqueConstraint constraintName=UK_JKUWUVD56ONTGSUHOGM8UEWRT, tableName=USER_CONSENT; dropNotNullConstraint columnName=CLIENT_ID, tableName=USER_CONSENT; addColumn tableName=USER_CONSENT; addUniqueConstraint constraintName=UK_JKUWUVD56ONTGSUHO...		\N	4.33.0	\N	\N	6409001035
4.0.0-KEYCLOAK-5579-fixed	mposolda@redhat.com	META-INF/jpa-changelog-4.0.0.xml	2026-04-17 06:56:48.110086	58	EXECUTED	9:139b79bcbbfe903bb1c2d2a4dbf001d9	dropForeignKeyConstraint baseTableName=CLIENT_TEMPLATE_ATTRIBUTES, constraintName=FK_CL_TEMPL_ATTR_TEMPL; renameTable newTableName=CLIENT_SCOPE_ATTRIBUTES, oldTableName=CLIENT_TEMPLATE_ATTRIBUTES; renameColumn newColumnName=SCOPE_ID, oldColumnName...		\N	4.33.0	\N	\N	6409001035
authz-4.0.0.CR1	psilva@redhat.com	META-INF/jpa-changelog-authz-4.0.0.CR1.xml	2026-04-17 06:56:48.142383	59	EXECUTED	9:b55738ad889860c625ba2bf483495a04	createTable tableName=RESOURCE_SERVER_PERM_TICKET; addPrimaryKey constraintName=CONSTRAINT_FAPMT, tableName=RESOURCE_SERVER_PERM_TICKET; addForeignKeyConstraint baseTableName=RESOURCE_SERVER_PERM_TICKET, constraintName=FK_FRSRHO213XCX4WNKOG82SSPMT...		\N	4.33.0	\N	\N	6409001035
authz-4.0.0.Beta3	psilva@redhat.com	META-INF/jpa-changelog-authz-4.0.0.Beta3.xml	2026-04-17 06:56:48.160333	60	EXECUTED	9:e0057eac39aa8fc8e09ac6cfa4ae15fe	addColumn tableName=RESOURCE_SERVER_POLICY; addColumn tableName=RESOURCE_SERVER_PERM_TICKET; addForeignKeyConstraint baseTableName=RESOURCE_SERVER_PERM_TICKET, constraintName=FK_FRSRPO2128CX4WNKOG82SSRFY, referencedTableName=RESOURCE_SERVER_POLICY		\N	4.33.0	\N	\N	6409001035
authz-4.2.0.Final	mhajas@redhat.com	META-INF/jpa-changelog-authz-4.2.0.Final.xml	2026-04-17 06:56:48.179931	61	EXECUTED	9:42a33806f3a0443fe0e7feeec821326c	createTable tableName=RESOURCE_URIS; addForeignKeyConstraint baseTableName=RESOURCE_URIS, constraintName=FK_RESOURCE_SERVER_URIS, referencedTableName=RESOURCE_SERVER_RESOURCE; customChange; dropColumn columnName=URI, tableName=RESOURCE_SERVER_RESO...		\N	4.33.0	\N	\N	6409001035
authz-4.2.0.Final-KEYCLOAK-9944	hmlnarik@redhat.com	META-INF/jpa-changelog-authz-4.2.0.Final.xml	2026-04-17 06:56:48.196238	62	EXECUTED	9:9968206fca46eecc1f51db9c024bfe56	addPrimaryKey constraintName=CONSTRAINT_RESOUR_URIS_PK, tableName=RESOURCE_URIS		\N	4.33.0	\N	\N	6409001035
4.2.0-KEYCLOAK-6313	wadahiro@gmail.com	META-INF/jpa-changelog-4.2.0.xml	2026-04-17 06:56:48.215099	63	EXECUTED	9:92143a6daea0a3f3b8f598c97ce55c3d	addColumn tableName=REQUIRED_ACTION_PROVIDER		\N	4.33.0	\N	\N	6409001035
4.3.0-KEYCLOAK-7984	wadahiro@gmail.com	META-INF/jpa-changelog-4.3.0.xml	2026-04-17 06:56:48.224854	64	EXECUTED	9:82bab26a27195d889fb0429003b18f40	update tableName=REQUIRED_ACTION_PROVIDER		\N	4.33.0	\N	\N	6409001035
4.6.0-KEYCLOAK-7950	psilva@redhat.com	META-INF/jpa-changelog-4.6.0.xml	2026-04-17 06:56:48.240914	65	EXECUTED	9:e590c88ddc0b38b0ae4249bbfcb5abc3	update tableName=RESOURCE_SERVER_RESOURCE		\N	4.33.0	\N	\N	6409001035
4.6.0-KEYCLOAK-8377	keycloak	META-INF/jpa-changelog-4.6.0.xml	2026-04-17 06:56:48.273997	66	EXECUTED	9:5c1f475536118dbdc38d5d7977950cc0	createTable tableName=ROLE_ATTRIBUTE; addPrimaryKey constraintName=CONSTRAINT_ROLE_ATTRIBUTE_PK, tableName=ROLE_ATTRIBUTE; addForeignKeyConstraint baseTableName=ROLE_ATTRIBUTE, constraintName=FK_ROLE_ATTRIBUTE_ID, referencedTableName=KEYCLOAK_ROLE...		\N	4.33.0	\N	\N	6409001035
4.6.0-KEYCLOAK-8555	gideonray@gmail.com	META-INF/jpa-changelog-4.6.0.xml	2026-04-17 06:56:48.306856	67	EXECUTED	9:e7c9f5f9c4d67ccbbcc215440c718a17	createIndex indexName=IDX_COMPONENT_PROVIDER_TYPE, tableName=COMPONENT		\N	4.33.0	\N	\N	6409001035
4.7.0-KEYCLOAK-1267	sguilhen@redhat.com	META-INF/jpa-changelog-4.7.0.xml	2026-04-17 06:56:48.329086	68	EXECUTED	9:88e0bfdda924690d6f4e430c53447dd5	addColumn tableName=REALM		\N	4.33.0	\N	\N	6409001035
4.7.0-KEYCLOAK-7275	keycloak	META-INF/jpa-changelog-4.7.0.xml	2026-04-17 06:56:48.362586	69	EXECUTED	9:f53177f137e1c46b6a88c59ec1cb5218	renameColumn newColumnName=CREATED_ON, oldColumnName=LAST_SESSION_REFRESH, tableName=OFFLINE_USER_SESSION; addNotNullConstraint columnName=CREATED_ON, tableName=OFFLINE_USER_SESSION; addColumn tableName=OFFLINE_USER_SESSION; customChange; createIn...		\N	4.33.0	\N	\N	6409001035
4.8.0-KEYCLOAK-8835	sguilhen@redhat.com	META-INF/jpa-changelog-4.8.0.xml	2026-04-17 06:56:48.380967	70	EXECUTED	9:a74d33da4dc42a37ec27121580d1459f	addNotNullConstraint columnName=SSO_MAX_LIFESPAN_REMEMBER_ME, tableName=REALM; addNotNullConstraint columnName=SSO_IDLE_TIMEOUT_REMEMBER_ME, tableName=REALM		\N	4.33.0	\N	\N	6409001035
authz-7.0.0-KEYCLOAK-10443	psilva@redhat.com	META-INF/jpa-changelog-authz-7.0.0.xml	2026-04-17 06:56:48.398435	71	EXECUTED	9:fd4ade7b90c3b67fae0bfcfcb42dfb5f	addColumn tableName=RESOURCE_SERVER		\N	4.33.0	\N	\N	6409001035
8.0.0-adding-credential-columns	keycloak	META-INF/jpa-changelog-8.0.0.xml	2026-04-17 06:56:48.420831	72	EXECUTED	9:aa072ad090bbba210d8f18781b8cebf4	addColumn tableName=CREDENTIAL; addColumn tableName=FED_USER_CREDENTIAL		\N	4.33.0	\N	\N	6409001035
8.0.0-updating-credential-data-not-oracle-fixed	keycloak	META-INF/jpa-changelog-8.0.0.xml	2026-04-17 06:56:48.428493	73	EXECUTED	9:1ae6be29bab7c2aa376f6983b932be37	update tableName=CREDENTIAL; update tableName=CREDENTIAL; update tableName=CREDENTIAL; update tableName=FED_USER_CREDENTIAL; update tableName=FED_USER_CREDENTIAL; update tableName=FED_USER_CREDENTIAL		\N	4.33.0	\N	\N	6409001035
8.0.0-updating-credential-data-oracle-fixed	keycloak	META-INF/jpa-changelog-8.0.0.xml	2026-04-17 06:56:48.439888	74	MARK_RAN	9:14706f286953fc9a25286dbd8fb30d97	update tableName=CREDENTIAL; update tableName=CREDENTIAL; update tableName=CREDENTIAL; update tableName=FED_USER_CREDENTIAL; update tableName=FED_USER_CREDENTIAL; update tableName=FED_USER_CREDENTIAL		\N	4.33.0	\N	\N	6409001035
8.0.0-credential-cleanup-fixed	keycloak	META-INF/jpa-changelog-8.0.0.xml	2026-04-17 06:56:48.476166	75	EXECUTED	9:2b9cc12779be32c5b40e2e67711a218b	dropDefaultValue columnName=COUNTER, tableName=CREDENTIAL; dropDefaultValue columnName=DIGITS, tableName=CREDENTIAL; dropDefaultValue columnName=PERIOD, tableName=CREDENTIAL; dropDefaultValue columnName=ALGORITHM, tableName=CREDENTIAL; dropColumn ...		\N	4.33.0	\N	\N	6409001035
8.0.0-resource-tag-support	keycloak	META-INF/jpa-changelog-8.0.0.xml	2026-04-17 06:56:48.511183	76	EXECUTED	9:91fa186ce7a5af127a2d7a91ee083cc5	addColumn tableName=MIGRATION_MODEL; createIndex indexName=IDX_UPDATE_TIME, tableName=MIGRATION_MODEL		\N	4.33.0	\N	\N	6409001035
9.0.0-always-display-client	keycloak	META-INF/jpa-changelog-9.0.0.xml	2026-04-17 06:56:48.529243	77	EXECUTED	9:6335e5c94e83a2639ccd68dd24e2e5ad	addColumn tableName=CLIENT		\N	4.33.0	\N	\N	6409001035
9.0.0-drop-constraints-for-column-increase	keycloak	META-INF/jpa-changelog-9.0.0.xml	2026-04-17 06:56:48.53448	78	MARK_RAN	9:6bdb5658951e028bfe16fa0a8228b530	dropUniqueConstraint constraintName=UK_FRSR6T700S9V50BU18WS5PMT, tableName=RESOURCE_SERVER_PERM_TICKET; dropUniqueConstraint constraintName=UK_FRSR6T700S9V50BU18WS5HA6, tableName=RESOURCE_SERVER_RESOURCE; dropPrimaryKey constraintName=CONSTRAINT_O...		\N	4.33.0	\N	\N	6409001035
9.0.0-increase-column-size-federated-fk	keycloak	META-INF/jpa-changelog-9.0.0.xml	2026-04-17 06:56:48.55427	79	EXECUTED	9:d5bc15a64117ccad481ce8792d4c608f	modifyDataType columnName=CLIENT_ID, tableName=FED_USER_CONSENT; modifyDataType columnName=CLIENT_REALM_CONSTRAINT, tableName=KEYCLOAK_ROLE; modifyDataType columnName=OWNER, tableName=RESOURCE_SERVER_POLICY; modifyDataType columnName=CLIENT_ID, ta...		\N	4.33.0	\N	\N	6409001035
9.0.0-recreate-constraints-after-column-increase	keycloak	META-INF/jpa-changelog-9.0.0.xml	2026-04-17 06:56:48.565372	80	MARK_RAN	9:077cba51999515f4d3e7ad5619ab592c	addNotNullConstraint columnName=CLIENT_ID, tableName=OFFLINE_CLIENT_SESSION; addNotNullConstraint columnName=OWNER, tableName=RESOURCE_SERVER_PERM_TICKET; addNotNullConstraint columnName=REQUESTER, tableName=RESOURCE_SERVER_PERM_TICKET; addNotNull...		\N	4.33.0	\N	\N	6409001035
9.0.1-add-index-to-client.client_id	keycloak	META-INF/jpa-changelog-9.0.1.xml	2026-04-17 06:56:48.600469	81	EXECUTED	9:be969f08a163bf47c6b9e9ead8ac2afb	createIndex indexName=IDX_CLIENT_ID, tableName=CLIENT		\N	4.33.0	\N	\N	6409001035
9.0.1-KEYCLOAK-12579-drop-constraints	keycloak	META-INF/jpa-changelog-9.0.1.xml	2026-04-17 06:56:48.604884	82	MARK_RAN	9:6d3bb4408ba5a72f39bd8a0b301ec6e3	dropUniqueConstraint constraintName=SIBLING_NAMES, tableName=KEYCLOAK_GROUP		\N	4.33.0	\N	\N	6409001035
9.0.1-KEYCLOAK-12579-add-not-null-constraint	keycloak	META-INF/jpa-changelog-9.0.1.xml	2026-04-17 06:56:48.624514	83	EXECUTED	9:966bda61e46bebf3cc39518fbed52fa7	addNotNullConstraint columnName=PARENT_GROUP, tableName=KEYCLOAK_GROUP		\N	4.33.0	\N	\N	6409001035
9.0.1-KEYCLOAK-12579-recreate-constraints	keycloak	META-INF/jpa-changelog-9.0.1.xml	2026-04-17 06:56:48.640159	84	MARK_RAN	9:8dcac7bdf7378e7d823cdfddebf72fda	addUniqueConstraint constraintName=SIBLING_NAMES, tableName=KEYCLOAK_GROUP		\N	4.33.0	\N	\N	6409001035
9.0.1-add-index-to-events	keycloak	META-INF/jpa-changelog-9.0.1.xml	2026-04-17 06:56:48.673707	85	EXECUTED	9:7d93d602352a30c0c317e6a609b56599	createIndex indexName=IDX_EVENT_TIME, tableName=EVENT_ENTITY		\N	4.33.0	\N	\N	6409001035
map-remove-ri	keycloak	META-INF/jpa-changelog-11.0.0.xml	2026-04-17 06:56:48.692014	86	EXECUTED	9:71c5969e6cdd8d7b6f47cebc86d37627	dropForeignKeyConstraint baseTableName=REALM, constraintName=FK_TRAF444KK6QRKMS7N56AIWQ5Y; dropForeignKeyConstraint baseTableName=KEYCLOAK_ROLE, constraintName=FK_KJHO5LE2C0RAL09FL8CM9WFW9		\N	4.33.0	\N	\N	6409001035
map-remove-ri	keycloak	META-INF/jpa-changelog-12.0.0.xml	2026-04-17 06:56:48.711065	87	EXECUTED	9:a9ba7d47f065f041b7da856a81762021	dropForeignKeyConstraint baseTableName=REALM_DEFAULT_GROUPS, constraintName=FK_DEF_GROUPS_GROUP; dropForeignKeyConstraint baseTableName=REALM_DEFAULT_ROLES, constraintName=FK_H4WPD7W4HSOOLNI3H0SW7BTJE; dropForeignKeyConstraint baseTableName=CLIENT...		\N	4.33.0	\N	\N	6409001035
12.1.0-add-realm-localization-table	keycloak	META-INF/jpa-changelog-12.0.0.xml	2026-04-17 06:56:48.732393	88	EXECUTED	9:fffabce2bc01e1a8f5110d5278500065	createTable tableName=REALM_LOCALIZATIONS; addPrimaryKey tableName=REALM_LOCALIZATIONS		\N	4.33.0	\N	\N	6409001035
default-roles	keycloak	META-INF/jpa-changelog-13.0.0.xml	2026-04-17 06:56:48.754081	89	EXECUTED	9:fa8a5b5445e3857f4b010bafb5009957	addColumn tableName=REALM; customChange		\N	4.33.0	\N	\N	6409001035
default-roles-cleanup	keycloak	META-INF/jpa-changelog-13.0.0.xml	2026-04-17 06:56:48.771378	90	EXECUTED	9:67ac3241df9a8582d591c5ed87125f39	dropTable tableName=REALM_DEFAULT_ROLES; dropTable tableName=CLIENT_DEFAULT_ROLES		\N	4.33.0	\N	\N	6409001035
13.0.0-KEYCLOAK-16844	keycloak	META-INF/jpa-changelog-13.0.0.xml	2026-04-17 06:56:48.816812	91	EXECUTED	9:ad1194d66c937e3ffc82386c050ba089	createIndex indexName=IDX_OFFLINE_USS_PRELOAD, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	6409001035
map-remove-ri-13.0.0	keycloak	META-INF/jpa-changelog-13.0.0.xml	2026-04-17 06:56:48.836495	92	EXECUTED	9:d9be619d94af5a2f5d07b9f003543b91	dropForeignKeyConstraint baseTableName=DEFAULT_CLIENT_SCOPE, constraintName=FK_R_DEF_CLI_SCOPE_SCOPE; dropForeignKeyConstraint baseTableName=CLIENT_SCOPE_CLIENT, constraintName=FK_C_CLI_SCOPE_SCOPE; dropForeignKeyConstraint baseTableName=CLIENT_SC...		\N	4.33.0	\N	\N	6409001035
13.0.0-KEYCLOAK-17992-drop-constraints	keycloak	META-INF/jpa-changelog-13.0.0.xml	2026-04-17 06:56:48.842081	93	MARK_RAN	9:544d201116a0fcc5a5da0925fbbc3bde	dropPrimaryKey constraintName=C_CLI_SCOPE_BIND, tableName=CLIENT_SCOPE_CLIENT; dropIndex indexName=IDX_CLSCOPE_CL, tableName=CLIENT_SCOPE_CLIENT; dropIndex indexName=IDX_CL_CLSCOPE, tableName=CLIENT_SCOPE_CLIENT		\N	4.33.0	\N	\N	6409001035
13.0.0-increase-column-size-federated	keycloak	META-INF/jpa-changelog-13.0.0.xml	2026-04-17 06:56:48.86663	94	EXECUTED	9:43c0c1055b6761b4b3e89de76d612ccf	modifyDataType columnName=CLIENT_ID, tableName=CLIENT_SCOPE_CLIENT; modifyDataType columnName=SCOPE_ID, tableName=CLIENT_SCOPE_CLIENT		\N	4.33.0	\N	\N	6409001035
13.0.0-KEYCLOAK-17992-recreate-constraints	keycloak	META-INF/jpa-changelog-13.0.0.xml	2026-04-17 06:56:48.879643	95	MARK_RAN	9:8bd711fd0330f4fe980494ca43ab1139	addNotNullConstraint columnName=CLIENT_ID, tableName=CLIENT_SCOPE_CLIENT; addNotNullConstraint columnName=SCOPE_ID, tableName=CLIENT_SCOPE_CLIENT; addPrimaryKey constraintName=C_CLI_SCOPE_BIND, tableName=CLIENT_SCOPE_CLIENT; createIndex indexName=...		\N	4.33.0	\N	\N	6409001035
json-string-accomodation-fixed	keycloak	META-INF/jpa-changelog-13.0.0.xml	2026-04-17 06:56:48.903311	96	EXECUTED	9:e07d2bc0970c348bb06fb63b1f82ddbf	addColumn tableName=REALM_ATTRIBUTE; update tableName=REALM_ATTRIBUTE; dropColumn columnName=VALUE, tableName=REALM_ATTRIBUTE; renameColumn newColumnName=VALUE, oldColumnName=VALUE_NEW, tableName=REALM_ATTRIBUTE		\N	4.33.0	\N	\N	6409001035
14.0.0-KEYCLOAK-11019	keycloak	META-INF/jpa-changelog-14.0.0.xml	2026-04-17 06:56:48.966637	97	EXECUTED	9:24fb8611e97f29989bea412aa38d12b7	createIndex indexName=IDX_OFFLINE_CSS_PRELOAD, tableName=OFFLINE_CLIENT_SESSION; createIndex indexName=IDX_OFFLINE_USS_BY_USER, tableName=OFFLINE_USER_SESSION; createIndex indexName=IDX_OFFLINE_USS_BY_USERSESS, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	6409001035
14.0.0-KEYCLOAK-18286	keycloak	META-INF/jpa-changelog-14.0.0.xml	2026-04-17 06:56:48.972979	98	MARK_RAN	9:259f89014ce2506ee84740cbf7163aa7	createIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	6409001035
14.0.0-KEYCLOAK-18286-revert	keycloak	META-INF/jpa-changelog-14.0.0.xml	2026-04-17 06:56:48.99227	99	MARK_RAN	9:04baaf56c116ed19951cbc2cca584022	dropIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	6409001035
14.0.0-KEYCLOAK-18286-supported-dbs	keycloak	META-INF/jpa-changelog-14.0.0.xml	2026-04-17 06:56:49.039829	100	EXECUTED	9:60ca84a0f8c94ec8c3504a5a3bc88ee8	createIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	6409001035
14.0.0-KEYCLOAK-18286-unsupported-dbs	keycloak	META-INF/jpa-changelog-14.0.0.xml	2026-04-17 06:56:49.048198	101	MARK_RAN	9:d3d977031d431db16e2c181ce49d73e9	createIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	6409001035
KEYCLOAK-17267-add-index-to-user-attributes	keycloak	META-INF/jpa-changelog-14.0.0.xml	2026-04-17 06:56:49.082546	102	EXECUTED	9:0b305d8d1277f3a89a0a53a659ad274c	createIndex indexName=IDX_USER_ATTRIBUTE_NAME, tableName=USER_ATTRIBUTE		\N	4.33.0	\N	\N	6409001035
KEYCLOAK-18146-add-saml-art-binding-identifier	keycloak	META-INF/jpa-changelog-14.0.0.xml	2026-04-17 06:56:49.10062	103	EXECUTED	9:2c374ad2cdfe20e2905a84c8fac48460	customChange		\N	4.33.0	\N	\N	6409001035
15.0.0-KEYCLOAK-18467	keycloak	META-INF/jpa-changelog-15.0.0.xml	2026-04-17 06:56:49.117686	104	EXECUTED	9:47a760639ac597360a8219f5b768b4de	addColumn tableName=REALM_LOCALIZATIONS; update tableName=REALM_LOCALIZATIONS; dropColumn columnName=TEXTS, tableName=REALM_LOCALIZATIONS; renameColumn newColumnName=TEXTS, oldColumnName=TEXTS_NEW, tableName=REALM_LOCALIZATIONS; addNotNullConstrai...		\N	4.33.0	\N	\N	6409001035
17.0.0-9562	keycloak	META-INF/jpa-changelog-17.0.0.xml	2026-04-17 06:56:49.148471	105	EXECUTED	9:a6272f0576727dd8cad2522335f5d99e	createIndex indexName=IDX_USER_SERVICE_ACCOUNT, tableName=USER_ENTITY		\N	4.33.0	\N	\N	6409001035
18.0.0-10625-IDX_ADMIN_EVENT_TIME	keycloak	META-INF/jpa-changelog-18.0.0.xml	2026-04-17 06:56:49.17827	106	EXECUTED	9:015479dbd691d9cc8669282f4828c41d	createIndex indexName=IDX_ADMIN_EVENT_TIME, tableName=ADMIN_EVENT_ENTITY		\N	4.33.0	\N	\N	6409001035
18.0.15-30992-index-consent	keycloak	META-INF/jpa-changelog-18.0.15.xml	2026-04-17 06:56:49.202353	107	EXECUTED	9:80071ede7a05604b1f4906f3bf3b00f0	createIndex indexName=IDX_USCONSENT_SCOPE_ID, tableName=USER_CONSENT_CLIENT_SCOPE		\N	4.33.0	\N	\N	6409001035
19.0.0-10135	keycloak	META-INF/jpa-changelog-19.0.0.xml	2026-04-17 06:56:49.209421	108	EXECUTED	9:9518e495fdd22f78ad6425cc30630221	customChange		\N	4.33.0	\N	\N	6409001035
20.0.0-12964-supported-dbs	keycloak	META-INF/jpa-changelog-20.0.0.xml	2026-04-17 06:56:49.232213	109	EXECUTED	9:e5f243877199fd96bcc842f27a1656ac	createIndex indexName=IDX_GROUP_ATT_BY_NAME_VALUE, tableName=GROUP_ATTRIBUTE		\N	4.33.0	\N	\N	6409001035
20.0.0-12964-supported-dbs-edb-migration	keycloak	META-INF/jpa-changelog-20.0.0.xml	2026-04-17 06:56:49.25747	110	EXECUTED	9:a6b18a8e38062df5793edbe064f4aecd	dropIndex indexName=IDX_GROUP_ATT_BY_NAME_VALUE, tableName=GROUP_ATTRIBUTE; createIndex indexName=IDX_GROUP_ATT_BY_NAME_VALUE, tableName=GROUP_ATTRIBUTE		\N	4.33.0	\N	\N	6409001035
20.0.0-12964-unsupported-dbs	keycloak	META-INF/jpa-changelog-20.0.0.xml	2026-04-17 06:56:49.262195	111	MARK_RAN	9:1a6fcaa85e20bdeae0a9ce49b41946a5	createIndex indexName=IDX_GROUP_ATT_BY_NAME_VALUE, tableName=GROUP_ATTRIBUTE		\N	4.33.0	\N	\N	6409001035
client-attributes-string-accomodation-fixed-pre-drop-index	keycloak	META-INF/jpa-changelog-20.0.0.xml	2026-04-17 06:56:49.275212	112	EXECUTED	9:04baaf56c116ed19951cbc2cca584022	dropIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	6409001035
client-attributes-string-accomodation-fixed	keycloak	META-INF/jpa-changelog-20.0.0.xml	2026-04-17 06:56:49.286734	113	EXECUTED	9:3f332e13e90739ed0c35b0b25b7822ca	addColumn tableName=CLIENT_ATTRIBUTES; update tableName=CLIENT_ATTRIBUTES; dropColumn columnName=VALUE, tableName=CLIENT_ATTRIBUTES; renameColumn newColumnName=VALUE, oldColumnName=VALUE_NEW, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	6409001035
client-attributes-string-accomodation-fixed-post-create-index	keycloak	META-INF/jpa-changelog-20.0.0.xml	2026-04-17 06:56:49.292058	114	MARK_RAN	9:bd2bd0fc7768cf0845ac96a8786fa735	createIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	6409001035
21.0.2-17277	keycloak	META-INF/jpa-changelog-21.0.2.xml	2026-04-17 06:56:49.298477	115	EXECUTED	9:7ee1f7a3fb8f5588f171fb9a6ab623c0	customChange		\N	4.33.0	\N	\N	6409001035
21.1.0-19404	keycloak	META-INF/jpa-changelog-21.1.0.xml	2026-04-17 06:56:49.310384	116	EXECUTED	9:3d7e830b52f33676b9d64f7f2b2ea634	modifyDataType columnName=DECISION_STRATEGY, tableName=RESOURCE_SERVER_POLICY; modifyDataType columnName=LOGIC, tableName=RESOURCE_SERVER_POLICY; modifyDataType columnName=POLICY_ENFORCE_MODE, tableName=RESOURCE_SERVER		\N	4.33.0	\N	\N	6409001035
21.1.0-19404-2	keycloak	META-INF/jpa-changelog-21.1.0.xml	2026-04-17 06:56:49.32128	117	MARK_RAN	9:627d032e3ef2c06c0e1f73d2ae25c26c	addColumn tableName=RESOURCE_SERVER_POLICY; update tableName=RESOURCE_SERVER_POLICY; dropColumn columnName=DECISION_STRATEGY, tableName=RESOURCE_SERVER_POLICY; renameColumn newColumnName=DECISION_STRATEGY, oldColumnName=DECISION_STRATEGY_NEW, tabl...		\N	4.33.0	\N	\N	6409001035
22.0.0-17484-updated	keycloak	META-INF/jpa-changelog-22.0.0.xml	2026-04-17 06:56:49.327648	118	EXECUTED	9:90af0bfd30cafc17b9f4d6eccd92b8b3	customChange		\N	4.33.0	\N	\N	6409001035
23.0.0-12062	keycloak	META-INF/jpa-changelog-23.0.0.xml	2026-04-17 06:56:49.341267	120	EXECUTED	9:2168fbe728fec46ae9baf15bf80927b8	addColumn tableName=COMPONENT_CONFIG; update tableName=COMPONENT_CONFIG; dropColumn columnName=VALUE, tableName=COMPONENT_CONFIG; renameColumn newColumnName=VALUE, oldColumnName=VALUE_NEW, tableName=COMPONENT_CONFIG		\N	4.33.0	\N	\N	6409001035
23.0.0-17258	keycloak	META-INF/jpa-changelog-23.0.0.xml	2026-04-17 06:56:49.349078	121	EXECUTED	9:36506d679a83bbfda85a27ea1864dca8	addColumn tableName=EVENT_ENTITY		\N	4.33.0	\N	\N	6409001035
24.0.0-9758	keycloak	META-INF/jpa-changelog-24.0.0.xml	2026-04-17 06:56:49.417519	122	EXECUTED	9:502c557a5189f600f0f445a9b49ebbce	addColumn tableName=USER_ATTRIBUTE; addColumn tableName=FED_USER_ATTRIBUTE; createIndex indexName=USER_ATTR_LONG_VALUES, tableName=USER_ATTRIBUTE; createIndex indexName=FED_USER_ATTR_LONG_VALUES, tableName=FED_USER_ATTRIBUTE; createIndex indexName...		\N	4.33.0	\N	\N	6409001035
24.0.0-9758-2	keycloak	META-INF/jpa-changelog-24.0.0.xml	2026-04-17 06:56:49.423143	123	EXECUTED	9:bf0fdee10afdf597a987adbf291db7b2	customChange		\N	4.33.0	\N	\N	6409001035
24.0.0-26618-drop-index-if-present	keycloak	META-INF/jpa-changelog-24.0.0.xml	2026-04-17 06:56:49.428679	124	MARK_RAN	9:04baaf56c116ed19951cbc2cca584022	dropIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	6409001035
24.0.0-26618-reindex	keycloak	META-INF/jpa-changelog-24.0.0.xml	2026-04-17 06:56:49.457097	125	EXECUTED	9:08707c0f0db1cef6b352db03a60edc7f	createIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	6409001035
24.0.0-26618-edb-migration	keycloak	META-INF/jpa-changelog-24.0.0.xml	2026-04-17 06:56:49.492953	126	EXECUTED	9:2f684b29d414cd47efe3a3599f390741	dropIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES; createIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	6409001035
24.0.2-27228	keycloak	META-INF/jpa-changelog-24.0.2.xml	2026-04-17 06:56:49.498981	127	EXECUTED	9:eaee11f6b8aa25d2cc6a84fb86fc6238	customChange		\N	4.33.0	\N	\N	6409001035
24.0.2-27967-drop-index-if-present	keycloak	META-INF/jpa-changelog-24.0.2.xml	2026-04-17 06:56:49.503026	128	MARK_RAN	9:04baaf56c116ed19951cbc2cca584022	dropIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	6409001035
24.0.2-27967-reindex	keycloak	META-INF/jpa-changelog-24.0.2.xml	2026-04-17 06:56:49.508771	129	MARK_RAN	9:d3d977031d431db16e2c181ce49d73e9	createIndex indexName=IDX_CLIENT_ATT_BY_NAME_VALUE, tableName=CLIENT_ATTRIBUTES		\N	4.33.0	\N	\N	6409001035
25.0.0-28265-tables	keycloak	META-INF/jpa-changelog-25.0.0.xml	2026-04-17 06:56:49.520151	130	EXECUTED	9:deda2df035df23388af95bbd36c17cef	addColumn tableName=OFFLINE_USER_SESSION; addColumn tableName=OFFLINE_CLIENT_SESSION		\N	4.33.0	\N	\N	6409001035
25.0.0-28265-index-creation	keycloak	META-INF/jpa-changelog-25.0.0.xml	2026-04-17 06:56:49.553375	131	EXECUTED	9:3e96709818458ae49f3c679ae58d263a	createIndex indexName=IDX_OFFLINE_USS_BY_LAST_SESSION_REFRESH, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	6409001035
25.0.0-28265-index-cleanup-uss-createdon	keycloak	META-INF/jpa-changelog-25.0.0.xml	2026-04-17 06:56:49.565906	132	EXECUTED	9:78ab4fc129ed5e8265dbcc3485fba92f	dropIndex indexName=IDX_OFFLINE_USS_CREATEDON, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	6409001035
25.0.0-28265-index-cleanup-uss-preload	keycloak	META-INF/jpa-changelog-25.0.0.xml	2026-04-17 06:56:49.577237	133	EXECUTED	9:de5f7c1f7e10994ed8b62e621d20eaab	dropIndex indexName=IDX_OFFLINE_USS_PRELOAD, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	6409001035
25.0.0-28265-index-cleanup-uss-by-usersess	keycloak	META-INF/jpa-changelog-25.0.0.xml	2026-04-17 06:56:49.589785	134	EXECUTED	9:6eee220d024e38e89c799417ec33667f	dropIndex indexName=IDX_OFFLINE_USS_BY_USERSESS, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	6409001035
25.0.0-28265-index-cleanup-css-preload	keycloak	META-INF/jpa-changelog-25.0.0.xml	2026-04-17 06:56:49.602365	135	EXECUTED	9:5411d2fb2891d3e8d63ddb55dfa3c0c9	dropIndex indexName=IDX_OFFLINE_CSS_PRELOAD, tableName=OFFLINE_CLIENT_SESSION		\N	4.33.0	\N	\N	6409001035
25.0.0-28265-index-2-mysql	keycloak	META-INF/jpa-changelog-25.0.0.xml	2026-04-17 06:56:49.605728	136	MARK_RAN	9:b7ef76036d3126bb83c2423bf4d449d6	createIndex indexName=IDX_OFFLINE_USS_BY_BROKER_SESSION_ID, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	6409001035
25.0.0-28265-index-2-not-mysql	keycloak	META-INF/jpa-changelog-25.0.0.xml	2026-04-17 06:56:49.635661	137	EXECUTED	9:23396cf51ab8bc1ae6f0cac7f9f6fcf7	createIndex indexName=IDX_OFFLINE_USS_BY_BROKER_SESSION_ID, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	6409001035
25.0.0-org	keycloak	META-INF/jpa-changelog-25.0.0.xml	2026-04-17 06:56:49.649465	138	EXECUTED	9:5c859965c2c9b9c72136c360649af157	createTable tableName=ORG; addUniqueConstraint constraintName=UK_ORG_NAME, tableName=ORG; addUniqueConstraint constraintName=UK_ORG_GROUP, tableName=ORG; createTable tableName=ORG_DOMAIN		\N	4.33.0	\N	\N	6409001035
unique-consentuser	keycloak	META-INF/jpa-changelog-25.0.0.xml	2026-04-17 06:56:49.661882	139	EXECUTED	9:5857626a2ea8767e9a6c66bf3a2cb32f	customChange; dropUniqueConstraint constraintName=UK_JKUWUVD56ONTGSUHOGM8UEWRT, tableName=USER_CONSENT; addUniqueConstraint constraintName=UK_LOCAL_CONSENT, tableName=USER_CONSENT; addUniqueConstraint constraintName=UK_EXTERNAL_CONSENT, tableName=...		\N	4.33.0	\N	\N	6409001035
unique-consentuser-edb-migration	keycloak	META-INF/jpa-changelog-25.0.0.xml	2026-04-17 06:56:49.6696	140	MARK_RAN	9:5857626a2ea8767e9a6c66bf3a2cb32f	customChange; dropUniqueConstraint constraintName=UK_JKUWUVD56ONTGSUHOGM8UEWRT, tableName=USER_CONSENT; addUniqueConstraint constraintName=UK_LOCAL_CONSENT, tableName=USER_CONSENT; addUniqueConstraint constraintName=UK_EXTERNAL_CONSENT, tableName=...		\N	4.33.0	\N	\N	6409001035
unique-consentuser-mysql	keycloak	META-INF/jpa-changelog-25.0.0.xml	2026-04-17 06:56:49.673586	141	MARK_RAN	9:b79478aad5adaa1bc428e31563f55e8e	customChange; dropUniqueConstraint constraintName=UK_JKUWUVD56ONTGSUHOGM8UEWRT, tableName=USER_CONSENT; addUniqueConstraint constraintName=UK_LOCAL_CONSENT, tableName=USER_CONSENT; addUniqueConstraint constraintName=UK_EXTERNAL_CONSENT, tableName=...		\N	4.33.0	\N	\N	6409001035
25.0.0-28861-index-creation	keycloak	META-INF/jpa-changelog-25.0.0.xml	2026-04-17 06:56:49.731456	142	EXECUTED	9:b9acb58ac958d9ada0fe12a5d4794ab1	createIndex indexName=IDX_PERM_TICKET_REQUESTER, tableName=RESOURCE_SERVER_PERM_TICKET; createIndex indexName=IDX_PERM_TICKET_OWNER, tableName=RESOURCE_SERVER_PERM_TICKET		\N	4.33.0	\N	\N	6409001035
26.0.0-org-alias	keycloak	META-INF/jpa-changelog-26.0.0.xml	2026-04-17 06:56:49.744018	143	EXECUTED	9:6ef7d63e4412b3c2d66ed179159886a4	addColumn tableName=ORG; update tableName=ORG; addNotNullConstraint columnName=ALIAS, tableName=ORG; addUniqueConstraint constraintName=UK_ORG_ALIAS, tableName=ORG		\N	4.33.0	\N	\N	6409001035
26.0.0-org-group	keycloak	META-INF/jpa-changelog-26.0.0.xml	2026-04-17 06:56:49.755602	144	EXECUTED	9:da8e8087d80ef2ace4f89d8c5b9ca223	addColumn tableName=KEYCLOAK_GROUP; update tableName=KEYCLOAK_GROUP; addNotNullConstraint columnName=TYPE, tableName=KEYCLOAK_GROUP; customChange		\N	4.33.0	\N	\N	6409001035
26.0.0-org-indexes	keycloak	META-INF/jpa-changelog-26.0.0.xml	2026-04-17 06:56:49.785862	145	EXECUTED	9:79b05dcd610a8c7f25ec05135eec0857	createIndex indexName=IDX_ORG_DOMAIN_ORG_ID, tableName=ORG_DOMAIN		\N	4.33.0	\N	\N	6409001035
26.0.0-org-group-membership	keycloak	META-INF/jpa-changelog-26.0.0.xml	2026-04-17 06:56:49.798106	146	EXECUTED	9:a6ace2ce583a421d89b01ba2a28dc2d4	addColumn tableName=USER_GROUP_MEMBERSHIP; update tableName=USER_GROUP_MEMBERSHIP; addNotNullConstraint columnName=MEMBERSHIP_TYPE, tableName=USER_GROUP_MEMBERSHIP		\N	4.33.0	\N	\N	6409001035
31296-persist-revoked-access-tokens	keycloak	META-INF/jpa-changelog-26.0.0.xml	2026-04-17 06:56:49.80672	147	EXECUTED	9:64ef94489d42a358e8304b0e245f0ed4	createTable tableName=REVOKED_TOKEN; addPrimaryKey constraintName=CONSTRAINT_RT, tableName=REVOKED_TOKEN		\N	4.33.0	\N	\N	6409001035
31725-index-persist-revoked-access-tokens	keycloak	META-INF/jpa-changelog-26.0.0.xml	2026-04-17 06:56:49.836345	148	EXECUTED	9:b994246ec2bf7c94da881e1d28782c7b	createIndex indexName=IDX_REV_TOKEN_ON_EXPIRE, tableName=REVOKED_TOKEN		\N	4.33.0	\N	\N	6409001035
26.0.0-idps-for-login	keycloak	META-INF/jpa-changelog-26.0.0.xml	2026-04-17 06:56:49.895585	149	EXECUTED	9:51f5fffadf986983d4bd59582c6c1604	addColumn tableName=IDENTITY_PROVIDER; createIndex indexName=IDX_IDP_REALM_ORG, tableName=IDENTITY_PROVIDER; createIndex indexName=IDX_IDP_FOR_LOGIN, tableName=IDENTITY_PROVIDER; customChange		\N	4.33.0	\N	\N	6409001035
26.0.0-32583-drop-redundant-index-on-client-session	keycloak	META-INF/jpa-changelog-26.0.0.xml	2026-04-17 06:56:49.907274	150	EXECUTED	9:24972d83bf27317a055d234187bb4af9	dropIndex indexName=IDX_US_SESS_ID_ON_CL_SESS, tableName=OFFLINE_CLIENT_SESSION		\N	4.33.0	\N	\N	6409001035
26.0.0.32582-remove-tables-user-session-user-session-note-and-client-session	keycloak	META-INF/jpa-changelog-26.0.0.xml	2026-04-17 06:56:49.920997	151	EXECUTED	9:febdc0f47f2ed241c59e60f58c3ceea5	dropTable tableName=CLIENT_SESSION_ROLE; dropTable tableName=CLIENT_SESSION_NOTE; dropTable tableName=CLIENT_SESSION_PROT_MAPPER; dropTable tableName=CLIENT_SESSION_AUTH_STATUS; dropTable tableName=CLIENT_USER_SESSION_NOTE; dropTable tableName=CLI...		\N	4.33.0	\N	\N	6409001035
26.0.0-33201-org-redirect-url	keycloak	META-INF/jpa-changelog-26.0.0.xml	2026-04-17 06:56:49.929629	152	EXECUTED	9:4d0e22b0ac68ebe9794fa9cb752ea660	addColumn tableName=ORG		\N	4.33.0	\N	\N	6409001035
29399-jdbc-ping-default	keycloak	META-INF/jpa-changelog-26.1.0.xml	2026-04-17 06:56:49.93744	153	EXECUTED	9:007dbe99d7203fca403b89d4edfdf21e	createTable tableName=JGROUPS_PING; addPrimaryKey constraintName=CONSTRAINT_JGROUPS_PING, tableName=JGROUPS_PING		\N	4.33.0	\N	\N	6409001035
26.1.0-34013	keycloak	META-INF/jpa-changelog-26.1.0.xml	2026-04-17 06:56:49.948964	154	EXECUTED	9:e6b686a15759aef99a6d758a5c4c6a26	addColumn tableName=ADMIN_EVENT_ENTITY		\N	4.33.0	\N	\N	6409001035
26.1.0-34380	keycloak	META-INF/jpa-changelog-26.1.0.xml	2026-04-17 06:56:49.960606	155	EXECUTED	9:ac8b9edb7c2b6c17a1c7a11fcf5ccf01	dropTable tableName=USERNAME_LOGIN_FAILURE		\N	4.33.0	\N	\N	6409001035
26.2.0-36750	keycloak	META-INF/jpa-changelog-26.2.0.xml	2026-04-17 06:56:49.971344	156	EXECUTED	9:b49ce951c22f7eb16480ff085640a33a	createTable tableName=SERVER_CONFIG		\N	4.33.0	\N	\N	6409001035
26.2.0-26106	keycloak	META-INF/jpa-changelog-26.2.0.xml	2026-04-17 06:56:49.983153	157	EXECUTED	9:b5877d5dab7d10ff3a9d209d7beb6680	addColumn tableName=CREDENTIAL		\N	4.33.0	\N	\N	6409001035
26.2.6-39866-duplicate	keycloak	META-INF/jpa-changelog-26.2.6.xml	2026-04-17 06:56:49.990423	158	EXECUTED	9:1dc67ccee24f30331db2cba4f372e40e	customChange		\N	4.33.0	\N	\N	6409001035
26.2.6-39866-uk	keycloak	META-INF/jpa-changelog-26.2.6.xml	2026-04-17 06:56:50.000842	159	EXECUTED	9:b70b76f47210cf0a5f4ef0e219eac7cd	addUniqueConstraint constraintName=UK_MIGRATION_VERSION, tableName=MIGRATION_MODEL		\N	4.33.0	\N	\N	6409001035
26.2.6-40088-duplicate	keycloak	META-INF/jpa-changelog-26.2.6.xml	2026-04-17 06:56:50.005131	160	EXECUTED	9:cc7e02ed69ab31979afb1982f9670e8f	customChange		\N	4.33.0	\N	\N	6409001035
26.2.6-40088-uk	keycloak	META-INF/jpa-changelog-26.2.6.xml	2026-04-17 06:56:50.014449	161	EXECUTED	9:5bb848128da7bc4595cc507383325241	addUniqueConstraint constraintName=UK_MIGRATION_UPDATE_TIME, tableName=MIGRATION_MODEL		\N	4.33.0	\N	\N	6409001035
26.3.0-groups-description	keycloak	META-INF/jpa-changelog-26.3.0.xml	2026-04-17 06:56:50.034922	162	EXECUTED	9:e1a3c05574326fb5b246b73b9a4c4d49	addColumn tableName=KEYCLOAK_GROUP		\N	4.33.0	\N	\N	6409001035
26.4.0-40933-saml-encryption-attributes	keycloak	META-INF/jpa-changelog-26.4.0.xml	2026-04-17 06:56:50.041208	163	EXECUTED	9:7e9eaba362ca105efdda202303a4fe49	customChange		\N	4.33.0	\N	\N	6409001035
26.4.0-51321	keycloak	META-INF/jpa-changelog-26.4.0.xml	2026-04-17 06:56:50.06481	164	EXECUTED	9:34bab2bc56f75ffd7e347c580874e306	createIndex indexName=IDX_EVENT_ENTITY_USER_ID_TYPE, tableName=EVENT_ENTITY		\N	4.33.0	\N	\N	6409001035
40343-workflow-state-table	keycloak	META-INF/jpa-changelog-26.4.0.xml	2026-04-17 06:56:50.117637	165	EXECUTED	9:ed3ab4723ceed210e5b5e60ac4562106	createTable tableName=WORKFLOW_STATE; addPrimaryKey constraintName=PK_WORKFLOW_STATE, tableName=WORKFLOW_STATE; addUniqueConstraint constraintName=UQ_WORKFLOW_RESOURCE, tableName=WORKFLOW_STATE; createIndex indexName=IDX_WORKFLOW_STATE_STEP, table...		\N	4.33.0	\N	\N	6409001035
26.5.0-index-offline-css-by-client	keycloak	META-INF/jpa-changelog-26.5.0.xml	2026-04-17 06:56:50.15858	166	EXECUTED	9:383e981ce95d16e32af757b7998820f7	createIndex indexName=IDX_OFFLINE_CSS_BY_CLIENT, tableName=OFFLINE_CLIENT_SESSION		\N	4.33.0	\N	\N	6409001035
26.5.0-index-offline-css-by-client-storage-provider	keycloak	META-INF/jpa-changelog-26.5.0.xml	2026-04-17 06:56:50.187301	167	EXECUTED	9:f5bc200e6fa7d7e483854dee535ca425	createIndex indexName=IDX_OFFLINE_CSS_BY_CLIENT_STORAGE_PROVIDER, tableName=OFFLINE_CLIENT_SESSION		\N	4.33.0	\N	\N	6409001035
26.5.0-idp-config-allow-null	keycloak	META-INF/jpa-changelog-26.5.0.xml	2026-04-17 06:56:50.201199	168	EXECUTED	9:b667fb087874303b324c1af7fae4f606	dropDefaultValue columnName=TRUST_EMAIL, tableName=IDENTITY_PROVIDER; dropNotNullConstraint columnName=TRUST_EMAIL, tableName=IDENTITY_PROVIDER; dropNotNullConstraint columnName=STORE_TOKEN, tableName=IDENTITY_PROVIDER; dropDefaultValue columnName...		\N	4.33.0	\N	\N	6409001035
26.5.0-remove-workflow-provider-id-column	keycloak	META-INF/jpa-changelog-26.5.0.xml	2026-04-17 06:56:50.226665	169	EXECUTED	9:d8eeb324484d45e946d03b953e168b21	dropIndex indexName=IDX_WORKFLOW_STATE_PROVIDER, tableName=WORKFLOW_STATE; createIndex indexName=IDX_WORKFLOW_STATE_PROVIDER, tableName=WORKFLOW_STATE; dropColumn columnName=WORKFLOW_PROVIDER_ID, tableName=WORKFLOW_STATE		\N	4.33.0	\N	\N	6409001035
26.5.0-add-remember-me	keycloak	META-INF/jpa-changelog-26.5.0.xml	2026-04-17 06:56:50.24559	170	EXECUTED	9:a7273ea8b21bd2f674c9c49141999f05	addColumn tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	6409001035
26.5.0-add-sess-refresh-idx	keycloak	META-INF/jpa-changelog-26.5.0.xml	2026-04-17 06:56:50.277478	171	EXECUTED	9:ce49383d317ccbcd3434d1f21172b0b7	createIndex indexName=IDX_USER_SESSION_EXPIRATION_CREATED, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	6409001035
26.5.0-add-sess-create-idx	keycloak	META-INF/jpa-changelog-26.5.0.xml	2026-04-17 06:56:50.313612	172	EXECUTED	9:aaee09e23a4d8468fbc5c51b7b314c58	createIndex indexName=IDX_USER_SESSION_EXPIRATION_LAST_REFRESH, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	6409001035
26.5.0-drop-sess-refresh-idx	keycloak	META-INF/jpa-changelog-26.5.0.xml	2026-04-17 06:56:50.339195	173	EXECUTED	9:f0082210b6ccbbaf81287c27aa23753c	dropIndex indexName=IDX_OFFLINE_USS_BY_LAST_SESSION_REFRESH, tableName=OFFLINE_USER_SESSION		\N	4.33.0	\N	\N	6409001035
26.5.0-invitations-table	keycloak	META-INF/jpa-changelog-26.5.0.xml	2026-04-17 06:56:50.415781	174	EXECUTED	9:322cb11fc03181903dcd67a54f8b3cf0	createTable tableName=ORG_INVITATION; addForeignKeyConstraint baseTableName=ORG_INVITATION, constraintName=FK_ORG_INVITATION_ORG, referencedTableName=ORG; createIndex indexName=IDX_ORG_INVITATION_ORG_ID, tableName=ORG_INVITATION; createIndex index...		\N	4.33.0	\N	\N	6409001035
\.


--
-- Data for Name: databasechangeloglock; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.databasechangeloglock (id, locked, lockgranted, lockedby) FROM stdin;
1	f	\N	\N
1000	f	\N	\N
\.


--
-- Data for Name: default_client_scope; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.default_client_scope (realm_id, scope_id, default_scope) FROM stdin;
207d128c-bb74-4e7f-a3e4-f110b22d6159	ead5eaa8-b5a4-4021-afc2-12cc33da2c2d	f
207d128c-bb74-4e7f-a3e4-f110b22d6159	a2b7fe0b-7d98-486d-8ee0-12bd009c3154	t
207d128c-bb74-4e7f-a3e4-f110b22d6159	a4f1760c-83a0-4ecc-a455-f2dfa4fd2eef	t
207d128c-bb74-4e7f-a3e4-f110b22d6159	d9d47570-32cf-44eb-a329-93be5d5dbd9e	t
207d128c-bb74-4e7f-a3e4-f110b22d6159	80597c7a-c1f9-44ab-8f15-31c36ca51cd3	t
207d128c-bb74-4e7f-a3e4-f110b22d6159	67e3ddb1-a977-4fb8-a5c6-a57dd8804cda	f
207d128c-bb74-4e7f-a3e4-f110b22d6159	161747f8-23e3-4e95-a21b-d3675be338e5	f
207d128c-bb74-4e7f-a3e4-f110b22d6159	0d9f8c42-cbda-4fa9-8f53-0af2c9dfdde3	t
207d128c-bb74-4e7f-a3e4-f110b22d6159	c54f2ec3-1987-4cd0-9dbd-5564abb04e76	t
207d128c-bb74-4e7f-a3e4-f110b22d6159	8a10c45f-537f-4783-8cc1-34e42626984a	f
207d128c-bb74-4e7f-a3e4-f110b22d6159	1e3e93ad-a248-44ae-82cb-be42caf1083a	t
207d128c-bb74-4e7f-a3e4-f110b22d6159	5af68cc7-fab6-4258-b5b6-2feb36df3e2a	t
207d128c-bb74-4e7f-a3e4-f110b22d6159	88dd4199-b555-4c54-90ad-d87376de9482	f
c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	0718e728-fb10-429c-be7b-795e7dd0a842	f
c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	3b010f52-041c-4a7a-9eb9-ae6bab3b9bd1	t
c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	0492b33d-d297-4009-9bdd-5f1dcf782cf3	t
c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	fd53d63e-abd9-4923-928a-9fba44904b06	t
c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	7a56b774-281d-4a64-8c54-2433df97f56f	t
c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	d5d4bb63-9d28-4a83-b2ad-ea18d77e3cde	f
c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	f5731461-3ade-4754-8d03-799394e6b501	f
c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	824686d7-ec63-4db4-86ee-daaf860b3340	t
c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c72c60f1-de1d-46d7-917d-952d8cb6cb17	t
c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	eb6c56b3-7c18-4f2d-8d01-d4c2fae36bda	f
c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	36504493-b5fa-4be1-8c55-9f9a07182a28	t
c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	a63a51b4-5482-4c17-98fa-621abb8905cc	t
c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	7d4db986-2070-44e5-9096-48d2f4a85f47	f
\.


--
-- Data for Name: event_entity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.event_entity (id, client_id, details_json, error, ip_address, realm_id, session_id, event_time, type, user_id, details_json_long_value) FROM stdin;
\.


--
-- Data for Name: fed_user_attribute; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fed_user_attribute (id, name, user_id, realm_id, storage_provider_id, value, long_value_hash, long_value_hash_lower_case, long_value) FROM stdin;
\.


--
-- Data for Name: fed_user_consent; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fed_user_consent (id, client_id, user_id, realm_id, storage_provider_id, created_date, last_updated_date, client_storage_provider, external_client_id) FROM stdin;
\.


--
-- Data for Name: fed_user_consent_cl_scope; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fed_user_consent_cl_scope (user_consent_id, scope_id) FROM stdin;
\.


--
-- Data for Name: fed_user_credential; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fed_user_credential (id, salt, type, created_date, user_id, realm_id, storage_provider_id, user_label, secret_data, credential_data, priority) FROM stdin;
\.


--
-- Data for Name: fed_user_group_membership; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fed_user_group_membership (group_id, user_id, realm_id, storage_provider_id) FROM stdin;
\.


--
-- Data for Name: fed_user_required_action; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fed_user_required_action (required_action, user_id, realm_id, storage_provider_id) FROM stdin;
\.


--
-- Data for Name: fed_user_role_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fed_user_role_mapping (role_id, user_id, realm_id, storage_provider_id) FROM stdin;
\.


--
-- Data for Name: federated_identity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.federated_identity (identity_provider, realm_id, federated_user_id, federated_username, token, user_id) FROM stdin;
\.


--
-- Data for Name: federated_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.federated_user (id, storage_provider_id, realm_id) FROM stdin;
\.


--
-- Data for Name: group_attribute; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.group_attribute (id, name, value, group_id) FROM stdin;
\.


--
-- Data for Name: group_role_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.group_role_mapping (role_id, group_id) FROM stdin;
\.


--
-- Data for Name: identity_provider; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.identity_provider (internal_id, enabled, provider_alias, provider_id, store_token, authenticate_by_default, realm_id, add_token_role, trust_email, first_broker_login_flow_id, post_broker_login_flow_id, provider_display_name, link_only, organization_id, hide_on_login) FROM stdin;
\.


--
-- Data for Name: identity_provider_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.identity_provider_config (identity_provider_id, value, name) FROM stdin;
\.


--
-- Data for Name: identity_provider_mapper; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.identity_provider_mapper (id, name, idp_alias, idp_mapper_name, realm_id) FROM stdin;
\.


--
-- Data for Name: idp_mapper_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.idp_mapper_config (idp_mapper_id, value, name) FROM stdin;
\.


--
-- Data for Name: jgroups_ping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.jgroups_ping (address, name, cluster_name, ip, coord) FROM stdin;
\.


--
-- Data for Name: keycloak_group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.keycloak_group (id, name, parent_group, realm_id, type, description) FROM stdin;
\.


--
-- Data for Name: keycloak_role; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.keycloak_role (id, client_realm_constraint, client_role, description, name, realm_id, client, realm) FROM stdin;
49673cc1-a91d-4029-bb02-bbf4936dc948	207d128c-bb74-4e7f-a3e4-f110b22d6159	f	${role_default-roles}	default-roles-master	207d128c-bb74-4e7f-a3e4-f110b22d6159	\N	\N
a91e1103-1927-4338-a982-fcf10d5aa602	207d128c-bb74-4e7f-a3e4-f110b22d6159	f	${role_admin}	admin	207d128c-bb74-4e7f-a3e4-f110b22d6159	\N	\N
e34aa68f-bb34-4c66-b47b-72b578d00924	207d128c-bb74-4e7f-a3e4-f110b22d6159	f	${role_create-realm}	create-realm	207d128c-bb74-4e7f-a3e4-f110b22d6159	\N	\N
2dd20a52-cdd8-43e6-901e-b9678488347f	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_create-client}	create-client	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
df885e16-9dbe-42f8-bfe5-9eef3a251962	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_view-realm}	view-realm	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
07ecb932-2ec2-472e-90cc-918a0e6dce19	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_view-users}	view-users	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
13a00198-eb31-49d2-b42f-3c678b8ccf72	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_view-clients}	view-clients	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
b035c13d-c28f-4bd9-9d7e-32e3bd387bf4	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_view-events}	view-events	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
c086bb7f-b16d-463e-bd59-89c142548fe0	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_view-identity-providers}	view-identity-providers	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
10587816-53d7-47fa-a1ce-77a9513cbdd7	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_view-authorization}	view-authorization	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
85ec90e9-9c0c-4190-9c1f-02115cce1069	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_manage-realm}	manage-realm	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
0594249a-170e-43cf-bd93-c200d11d5134	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_manage-users}	manage-users	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
dce18296-0f48-4afc-b52b-ca63eb214b30	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_manage-clients}	manage-clients	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
e218922d-f7c2-4a39-bbcc-0fa380e68256	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_manage-events}	manage-events	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
823c361b-4f1d-4428-9af3-bcc3aecfe5fc	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_manage-identity-providers}	manage-identity-providers	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
a3cc1f45-5524-49a6-a7a1-26372dcf7e56	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_manage-authorization}	manage-authorization	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
533c295c-2f87-4bd1-be03-950ded9fe1db	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_query-users}	query-users	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
e96d1862-0b58-465e-a5b8-6fc664c3cc3f	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_query-clients}	query-clients	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
9766bd62-dccf-4bc5-ae8e-1c5a62c81278	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_query-realms}	query-realms	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
d151fe6a-c6c5-4aeb-bcaf-cf78ffcb551c	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_query-groups}	query-groups	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
407de05d-5409-47a2-8914-792c715494c1	c05b475f-598d-429b-80d1-276ca9e572a0	t	${role_view-profile}	view-profile	207d128c-bb74-4e7f-a3e4-f110b22d6159	c05b475f-598d-429b-80d1-276ca9e572a0	\N
c5e9b565-c90e-41e5-8421-61c2b3b46849	c05b475f-598d-429b-80d1-276ca9e572a0	t	${role_manage-account}	manage-account	207d128c-bb74-4e7f-a3e4-f110b22d6159	c05b475f-598d-429b-80d1-276ca9e572a0	\N
8432de7c-27ca-46b1-abfb-cd333b85be3f	c05b475f-598d-429b-80d1-276ca9e572a0	t	${role_manage-account-links}	manage-account-links	207d128c-bb74-4e7f-a3e4-f110b22d6159	c05b475f-598d-429b-80d1-276ca9e572a0	\N
ca497e84-0418-42d0-9594-137e404b3204	c05b475f-598d-429b-80d1-276ca9e572a0	t	${role_view-applications}	view-applications	207d128c-bb74-4e7f-a3e4-f110b22d6159	c05b475f-598d-429b-80d1-276ca9e572a0	\N
a8340c59-9d27-42cf-bbb8-e020202af824	c05b475f-598d-429b-80d1-276ca9e572a0	t	${role_view-consent}	view-consent	207d128c-bb74-4e7f-a3e4-f110b22d6159	c05b475f-598d-429b-80d1-276ca9e572a0	\N
b64fc884-a926-44d3-b1c3-f5fc3862ae21	c05b475f-598d-429b-80d1-276ca9e572a0	t	${role_manage-consent}	manage-consent	207d128c-bb74-4e7f-a3e4-f110b22d6159	c05b475f-598d-429b-80d1-276ca9e572a0	\N
4f4ffc4b-957c-4cab-8c17-02f58614d750	c05b475f-598d-429b-80d1-276ca9e572a0	t	${role_view-groups}	view-groups	207d128c-bb74-4e7f-a3e4-f110b22d6159	c05b475f-598d-429b-80d1-276ca9e572a0	\N
1b777901-a351-4a4e-a371-f8a06659ae85	c05b475f-598d-429b-80d1-276ca9e572a0	t	${role_delete-account}	delete-account	207d128c-bb74-4e7f-a3e4-f110b22d6159	c05b475f-598d-429b-80d1-276ca9e572a0	\N
9abcbdbd-2550-4df9-81c7-9a527efd0d77	339d7cac-6002-4453-9a60-2e10d36ba29c	t	${role_read-token}	read-token	207d128c-bb74-4e7f-a3e4-f110b22d6159	339d7cac-6002-4453-9a60-2e10d36ba29c	\N
f3c54394-9f98-4375-b855-795c2481d292	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	t	${role_impersonation}	impersonation	207d128c-bb74-4e7f-a3e4-f110b22d6159	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	\N
1d9236ed-2238-4a3c-be4f-861c9af05d8b	207d128c-bb74-4e7f-a3e4-f110b22d6159	f	${role_offline-access}	offline_access	207d128c-bb74-4e7f-a3e4-f110b22d6159	\N	\N
7bb23998-fd6a-4c3a-9c4b-681d0f29f768	207d128c-bb74-4e7f-a3e4-f110b22d6159	f	${role_uma_authorization}	uma_authorization	207d128c-bb74-4e7f-a3e4-f110b22d6159	\N	\N
03e71ffe-54f7-455a-88b8-f7949197653d	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	f	${role_default-roles}	default-roles-restapi	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	\N	\N
0b9acf79-3ada-4ead-93e6-c5b12cc5f261	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_create-client}	create-client	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
46bfba08-7369-4be1-b940-61cdbb5193f5	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_view-realm}	view-realm	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
f22a3115-fa6f-47b4-a1cd-6bba0d2d9c25	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_view-users}	view-users	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
7febfbcc-deba-4a3f-ae58-bd61ce0558e7	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_view-clients}	view-clients	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
14fb8099-cbd9-4c0b-8604-913da53800e4	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_view-events}	view-events	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
d0c0a4ca-5760-4811-a1a1-bae06d1955d4	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_view-identity-providers}	view-identity-providers	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
07d31104-1aa4-48ef-ace3-6d907b75501b	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_view-authorization}	view-authorization	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
b887ac4a-c5df-4c1d-ac15-a303059776cc	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_manage-realm}	manage-realm	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
43450182-8aa3-4cdc-a1ca-c8d3e115f56f	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_manage-users}	manage-users	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
44a15d66-c313-4293-81a0-2d497984c81c	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_manage-clients}	manage-clients	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
b535d11e-cf83-4a68-ae4a-b4a92c527e9e	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_manage-events}	manage-events	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
8d609d14-0a87-4f61-a85a-99e7c5f40940	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_manage-identity-providers}	manage-identity-providers	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
21eb514e-3ced-4c9a-8b63-9a5d0c06a3b2	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_manage-authorization}	manage-authorization	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
b2872139-b84f-4016-a6a5-c05d78ad1e16	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_query-users}	query-users	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
ba18dda7-5bac-4525-ab32-79d21e9d6f80	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_query-clients}	query-clients	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
1d6d3491-540c-4643-940d-1cef1bba6a39	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_query-realms}	query-realms	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
06356291-7177-4d5f-afd7-e7636f1f4f32	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_query-groups}	query-groups	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
d5870091-ed66-4991-b602-4725846434a1	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_realm-admin}	realm-admin	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
d813378e-7717-4b45-8b80-acb330ed19a8	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_create-client}	create-client	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
dd915c0a-2b13-40f1-b7ea-2982fdbc4859	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_view-realm}	view-realm	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
e9ce8d0d-534e-4b7c-978d-7dc20683deb9	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_view-users}	view-users	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
a410a813-b586-4692-80bb-19f1653b60ce	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_view-clients}	view-clients	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
ba0e337c-0e9d-4e1d-bf3f-fa40d392f929	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_view-events}	view-events	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
92969131-dbb6-40c0-8e62-39083d55f10d	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_view-identity-providers}	view-identity-providers	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
d1957bdf-6cf9-484e-8046-f00770fbef13	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_view-authorization}	view-authorization	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
c265dee3-8c72-49dd-8fb1-89663b0f5ef1	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_manage-realm}	manage-realm	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
654b8d30-489d-449d-ba36-9973716c9ffa	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_manage-users}	manage-users	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
c72b0c13-e4de-49c0-b314-2b7a0d8ad256	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_manage-clients}	manage-clients	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
e84cb593-507e-4af1-b3b2-3ce88baccad6	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_manage-events}	manage-events	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
11ee0583-ffae-4de2-8923-1d9df3152f6a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_manage-identity-providers}	manage-identity-providers	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
354fa32a-b1a8-43c8-8319-8469601c9545	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_manage-authorization}	manage-authorization	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
5511c2ad-4b7e-4bee-b8ef-05a15458a8f2	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_query-users}	query-users	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
619cf3b7-80e1-4c52-a866-1d2c9d3cc19a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_query-clients}	query-clients	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
c6362e0d-4ac7-40fc-8909-b1c4625ee348	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_query-realms}	query-realms	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
e67fab09-a7c8-4d32-b893-02b04281288c	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_query-groups}	query-groups	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
53bf6aaf-22ed-4b89-a182-7123ad0305ad	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	t	${role_view-profile}	view-profile	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	\N
699d2e77-8b2f-4bd1-bd58-71eb020ce953	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	t	${role_manage-account}	manage-account	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	\N
44bfd1cc-4be3-4246-9b95-87a84af93bad	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	t	${role_manage-account-links}	manage-account-links	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	\N
b39e259d-be67-4843-b8b0-b26469a3d198	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	t	${role_view-applications}	view-applications	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	\N
0fd3d905-3c53-48e4-ad52-e24b263d035a	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	t	${role_view-consent}	view-consent	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	\N
0ca0dc88-f0e7-4fef-bff1-2ada64d7c787	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	t	${role_manage-consent}	manage-consent	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	\N
7d846a46-b249-4a44-a876-fe6d75210901	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	t	${role_view-groups}	view-groups	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	\N
cb491e7d-1345-4e4b-a0c7-59a0bd3b6ce0	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	t	${role_delete-account}	delete-account	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	fd19d9b9-ed5b-4fbb-a325-9d49639a74db	\N
f36f23fd-59e1-45cc-9736-9d5dc46e2b9c	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	t	${role_impersonation}	impersonation	207d128c-bb74-4e7f-a3e4-f110b22d6159	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	\N
669afa85-865d-4228-8485-33d8271cf530	c560ba3f-d4cd-4075-80f6-541d6faa9d56	t	${role_impersonation}	impersonation	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	c560ba3f-d4cd-4075-80f6-541d6faa9d56	\N
253f0d50-d45d-47b2-bbae-426b00a73b73	fbd3dabc-3a1a-42da-9a5d-a3bd488842f2	t	${role_read-token}	read-token	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	fbd3dabc-3a1a-42da-9a5d-a3bd488842f2	\N
5e274b31-a53a-4f89-a5cf-103dbae7cb1d	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	f	${role_offline-access}	offline_access	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	\N	\N
594ff37a-5315-4518-bd00-a52f5d707ec2	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	f	${role_uma_authorization}	uma_authorization	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	\N	\N
\.


--
-- Data for Name: migration_model; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.migration_model (id, version, update_time) FROM stdin;
q07ma	26.5.0	1776409012
\.


--
-- Data for Name: offline_client_session; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.offline_client_session (user_session_id, client_id, offline_flag, "timestamp", data, client_storage_provider, external_client_id, version) FROM stdin;
C_mrPI-AEyWn3T_I3PTZG05e	b1a24523-e2b5-4cc6-af64-8364f8882e32	0	1777763799	{"authMethod":"openid-connect","notes":{"clientId":"b1a24523-e2b5-4cc6-af64-8364f8882e32","userSessionStartedAt":"1777763799","iss":"http://keycloak:8080/realms/restapi","startedAt":"1777763799","level-of-authentication":"-1"}}	local	local	0
mT2UeCt3naFOKtse2sqajP1f	b1a24523-e2b5-4cc6-af64-8364f8882e32	0	1777763827	{"authMethod":"openid-connect","notes":{"clientId":"b1a24523-e2b5-4cc6-af64-8364f8882e32","userSessionStartedAt":"1777763827","iss":"http://keycloak:8080/realms/restapi","startedAt":"1777763827","level-of-authentication":"-1"}}	local	local	0
BQGLY3vJdol0ueObbN1Ao1SL	b1a24523-e2b5-4cc6-af64-8364f8882e32	0	1777763841	{"authMethod":"openid-connect","notes":{"clientId":"b1a24523-e2b5-4cc6-af64-8364f8882e32","userSessionStartedAt":"1777763841","iss":"http://keycloak:8080/realms/restapi","startedAt":"1777763841","level-of-authentication":"-1"}}	local	local	0
Y1CdEayhWpvbphDrMtOPTizt	b1a24523-e2b5-4cc6-af64-8364f8882e32	0	1777763853	{"authMethod":"openid-connect","notes":{"clientId":"b1a24523-e2b5-4cc6-af64-8364f8882e32","userSessionStartedAt":"1777763853","iss":"http://keycloak:8080/realms/restapi","startedAt":"1777763853","level-of-authentication":"-1"}}	local	local	0
UggIMxDTN32D9vmIdtD4JL-I	b1a24523-e2b5-4cc6-af64-8364f8882e32	0	1777763922	{"authMethod":"openid-connect","notes":{"clientId":"b1a24523-e2b5-4cc6-af64-8364f8882e32","userSessionStartedAt":"1777763922","iss":"http://keycloak:8080/realms/restapi","startedAt":"1777763922","level-of-authentication":"-1"}}	local	local	0
oCDUH7uH5gkuJtX6QcsuQFMi	b1a24523-e2b5-4cc6-af64-8364f8882e32	0	1777763928	{"authMethod":"openid-connect","notes":{"clientId":"b1a24523-e2b5-4cc6-af64-8364f8882e32","userSessionStartedAt":"1777763928","iss":"http://keycloak:8080/realms/restapi","startedAt":"1777763928","level-of-authentication":"-1"}}	local	local	0
-GeIZDw0un_I_sLrQ_P73NVI	b1a24523-e2b5-4cc6-af64-8364f8882e32	0	1777763992	{"authMethod":"openid-connect","notes":{"clientId":"b1a24523-e2b5-4cc6-af64-8364f8882e32","userSessionStartedAt":"1777763992","iss":"http://keycloak:8080/realms/restapi","startedAt":"1777763992","level-of-authentication":"-1"}}	local	local	0
ffWi7MIuwnUnET2ehxlwGcUS	b1a24523-e2b5-4cc6-af64-8364f8882e32	0	1777763992	{"authMethod":"openid-connect","notes":{"clientId":"b1a24523-e2b5-4cc6-af64-8364f8882e32","userSessionStartedAt":"1777763992","iss":"http://keycloak:8080/realms/restapi","startedAt":"1777763992","level-of-authentication":"-1"}}	local	local	0
kgIQ5VNRJ0f5LWJx5zGiT69G	b1a24523-e2b5-4cc6-af64-8364f8882e32	0	1777764187	{"authMethod":"openid-connect","notes":{"clientId":"b1a24523-e2b5-4cc6-af64-8364f8882e32","userSessionStartedAt":"1777764187","iss":"http://keycloak:8080/realms/restapi","startedAt":"1777764187","level-of-authentication":"-1"}}	local	local	0
ajxAib_iSQDgcK0RPDreTI1C	b1a24523-e2b5-4cc6-af64-8364f8882e32	0	1777764197	{"authMethod":"openid-connect","notes":{"clientId":"b1a24523-e2b5-4cc6-af64-8364f8882e32","userSessionStartedAt":"1777764197","iss":"http://keycloak:8080/realms/restapi","startedAt":"1777764197","level-of-authentication":"-1"}}	local	local	0
duJQIF8Lo-Il1rmWyFuTNCoi	b1a24523-e2b5-4cc6-af64-8364f8882e32	0	1777764231	{"authMethod":"openid-connect","notes":{"clientId":"b1a24523-e2b5-4cc6-af64-8364f8882e32","userSessionStartedAt":"1777764231","iss":"http://keycloak:8080/realms/restapi","startedAt":"1777764231","level-of-authentication":"-1"}}	local	local	0
pP4HIVsEH03SDaAf2WLYo7ed	b1a24523-e2b5-4cc6-af64-8364f8882e32	0	1777764231	{"authMethod":"openid-connect","notes":{"clientId":"b1a24523-e2b5-4cc6-af64-8364f8882e32","userSessionStartedAt":"1777764231","iss":"http://keycloak:8080/realms/restapi","startedAt":"1777764231","level-of-authentication":"-1"}}	local	local	0
\.


--
-- Data for Name: offline_user_session; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.offline_user_session (user_session_id, user_id, realm_id, created_on, offline_flag, data, last_session_refresh, broker_session_id, version, remember_me) FROM stdin;
C_mrPI-AEyWn3T_I3PTZG05e	7d453f22-6ff1-41b9-98b7-57ceff01f445	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	1777763799	0	{"ipAddress":"172.22.0.4","authMethod":"openid-connect","rememberMe":false,"started":0,"notes":{"KC_DEVICE_NOTE":"eyJpcEFkZHJlc3MiOiIxNzIuMjIuMC40Iiwib3MiOiJPdGhlciIsIm9zVmVyc2lvbiI6IlVua25vd24iLCJicm93c2VyIjoiT3RoZXIvVW5rbm93biIsImRldmljZSI6Ik90aGVyIiwibGFzdEFjY2VzcyI6MCwibW9iaWxlIjpmYWxzZX0=","authenticators-completed":"{\\"f347e3f0-f44e-4842-a159-7f89524ffc6d\\":1777763799,\\"349acc3f-0162-4b49-bfeb-5a7416aaffa4\\":1777763799}"},"state":"LOGGED_IN"}	1777763799	\N	0	f
mT2UeCt3naFOKtse2sqajP1f	7d453f22-6ff1-41b9-98b7-57ceff01f445	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	1777763827	0	{"ipAddress":"172.22.0.4","authMethod":"openid-connect","rememberMe":false,"started":0,"notes":{"KC_DEVICE_NOTE":"eyJpcEFkZHJlc3MiOiIxNzIuMjIuMC40Iiwib3MiOiJPdGhlciIsIm9zVmVyc2lvbiI6IlVua25vd24iLCJicm93c2VyIjoiT3RoZXIvVW5rbm93biIsImRldmljZSI6Ik90aGVyIiwibGFzdEFjY2VzcyI6MCwibW9iaWxlIjpmYWxzZX0=","authenticators-completed":"{\\"f347e3f0-f44e-4842-a159-7f89524ffc6d\\":1777763827,\\"349acc3f-0162-4b49-bfeb-5a7416aaffa4\\":1777763827}"},"state":"LOGGED_IN"}	1777763827	\N	0	f
BQGLY3vJdol0ueObbN1Ao1SL	7d453f22-6ff1-41b9-98b7-57ceff01f445	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	1777763841	0	{"ipAddress":"172.22.0.4","authMethod":"openid-connect","rememberMe":false,"started":0,"notes":{"KC_DEVICE_NOTE":"eyJpcEFkZHJlc3MiOiIxNzIuMjIuMC40Iiwib3MiOiJPdGhlciIsIm9zVmVyc2lvbiI6IlVua25vd24iLCJicm93c2VyIjoiT3RoZXIvVW5rbm93biIsImRldmljZSI6Ik90aGVyIiwibGFzdEFjY2VzcyI6MCwibW9iaWxlIjpmYWxzZX0=","authenticators-completed":"{\\"f347e3f0-f44e-4842-a159-7f89524ffc6d\\":1777763841,\\"349acc3f-0162-4b49-bfeb-5a7416aaffa4\\":1777763841}"},"state":"LOGGED_IN"}	1777763841	\N	0	f
Y1CdEayhWpvbphDrMtOPTizt	7d453f22-6ff1-41b9-98b7-57ceff01f445	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	1777763853	0	{"ipAddress":"172.22.0.4","authMethod":"openid-connect","rememberMe":false,"started":0,"notes":{"KC_DEVICE_NOTE":"eyJpcEFkZHJlc3MiOiIxNzIuMjIuMC40Iiwib3MiOiJPdGhlciIsIm9zVmVyc2lvbiI6IlVua25vd24iLCJicm93c2VyIjoiT3RoZXIvVW5rbm93biIsImRldmljZSI6Ik90aGVyIiwibGFzdEFjY2VzcyI6MCwibW9iaWxlIjpmYWxzZX0=","authenticators-completed":"{\\"f347e3f0-f44e-4842-a159-7f89524ffc6d\\":1777763853,\\"349acc3f-0162-4b49-bfeb-5a7416aaffa4\\":1777763853}"},"state":"LOGGED_IN"}	1777763853	\N	0	f
UggIMxDTN32D9vmIdtD4JL-I	7d453f22-6ff1-41b9-98b7-57ceff01f445	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	1777763922	0	{"ipAddress":"172.22.0.4","authMethod":"openid-connect","rememberMe":false,"started":0,"notes":{"KC_DEVICE_NOTE":"eyJpcEFkZHJlc3MiOiIxNzIuMjIuMC40Iiwib3MiOiJPdGhlciIsIm9zVmVyc2lvbiI6IlVua25vd24iLCJicm93c2VyIjoiT3RoZXIvVW5rbm93biIsImRldmljZSI6Ik90aGVyIiwibGFzdEFjY2VzcyI6MCwibW9iaWxlIjpmYWxzZX0=","authenticators-completed":"{\\"f347e3f0-f44e-4842-a159-7f89524ffc6d\\":1777763922,\\"349acc3f-0162-4b49-bfeb-5a7416aaffa4\\":1777763922}"},"state":"LOGGED_IN"}	1777763922	\N	0	f
oCDUH7uH5gkuJtX6QcsuQFMi	7d453f22-6ff1-41b9-98b7-57ceff01f445	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	1777763928	0	{"ipAddress":"172.22.0.4","authMethod":"openid-connect","rememberMe":false,"started":0,"notes":{"KC_DEVICE_NOTE":"eyJpcEFkZHJlc3MiOiIxNzIuMjIuMC40Iiwib3MiOiJPdGhlciIsIm9zVmVyc2lvbiI6IlVua25vd24iLCJicm93c2VyIjoiT3RoZXIvVW5rbm93biIsImRldmljZSI6Ik90aGVyIiwibGFzdEFjY2VzcyI6MCwibW9iaWxlIjpmYWxzZX0=","authenticators-completed":"{\\"f347e3f0-f44e-4842-a159-7f89524ffc6d\\":1777763928,\\"349acc3f-0162-4b49-bfeb-5a7416aaffa4\\":1777763928}"},"state":"LOGGED_IN"}	1777763928	\N	0	f
-GeIZDw0un_I_sLrQ_P73NVI	7d453f22-6ff1-41b9-98b7-57ceff01f445	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	1777763992	0	{"ipAddress":"172.22.0.4","authMethod":"openid-connect","rememberMe":false,"started":0,"notes":{"KC_DEVICE_NOTE":"eyJpcEFkZHJlc3MiOiIxNzIuMjIuMC40Iiwib3MiOiJPdGhlciIsIm9zVmVyc2lvbiI6IlVua25vd24iLCJicm93c2VyIjoiT3RoZXIvVW5rbm93biIsImRldmljZSI6Ik90aGVyIiwibGFzdEFjY2VzcyI6MCwibW9iaWxlIjpmYWxzZX0=","authenticators-completed":"{\\"f347e3f0-f44e-4842-a159-7f89524ffc6d\\":1777763992,\\"349acc3f-0162-4b49-bfeb-5a7416aaffa4\\":1777763992}"},"state":"LOGGED_IN"}	1777763992	\N	0	f
ffWi7MIuwnUnET2ehxlwGcUS	7d453f22-6ff1-41b9-98b7-57ceff01f445	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	1777763992	0	{"ipAddress":"172.22.0.4","authMethod":"openid-connect","rememberMe":false,"started":0,"notes":{"KC_DEVICE_NOTE":"eyJpcEFkZHJlc3MiOiIxNzIuMjIuMC40Iiwib3MiOiJPdGhlciIsIm9zVmVyc2lvbiI6IlVua25vd24iLCJicm93c2VyIjoiT3RoZXIvVW5rbm93biIsImRldmljZSI6Ik90aGVyIiwibGFzdEFjY2VzcyI6MCwibW9iaWxlIjpmYWxzZX0=","authenticators-completed":"{\\"f347e3f0-f44e-4842-a159-7f89524ffc6d\\":1777763992,\\"349acc3f-0162-4b49-bfeb-5a7416aaffa4\\":1777763992}"},"state":"LOGGED_IN"}	1777763992	\N	0	f
kgIQ5VNRJ0f5LWJx5zGiT69G	7d453f22-6ff1-41b9-98b7-57ceff01f445	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	1777764187	0	{"ipAddress":"172.22.0.4","authMethod":"openid-connect","rememberMe":false,"started":0,"notes":{"KC_DEVICE_NOTE":"eyJpcEFkZHJlc3MiOiIxNzIuMjIuMC40Iiwib3MiOiJPdGhlciIsIm9zVmVyc2lvbiI6IlVua25vd24iLCJicm93c2VyIjoiT3RoZXIvVW5rbm93biIsImRldmljZSI6Ik90aGVyIiwibGFzdEFjY2VzcyI6MCwibW9iaWxlIjpmYWxzZX0=","authenticators-completed":"{\\"f347e3f0-f44e-4842-a159-7f89524ffc6d\\":1777764187,\\"349acc3f-0162-4b49-bfeb-5a7416aaffa4\\":1777764187}"},"state":"LOGGED_IN"}	1777764187	\N	0	f
ajxAib_iSQDgcK0RPDreTI1C	7d453f22-6ff1-41b9-98b7-57ceff01f445	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	1777764197	0	{"ipAddress":"172.22.0.4","authMethod":"openid-connect","rememberMe":false,"started":0,"notes":{"KC_DEVICE_NOTE":"eyJpcEFkZHJlc3MiOiIxNzIuMjIuMC40Iiwib3MiOiJPdGhlciIsIm9zVmVyc2lvbiI6IlVua25vd24iLCJicm93c2VyIjoiT3RoZXIvVW5rbm93biIsImRldmljZSI6Ik90aGVyIiwibGFzdEFjY2VzcyI6MCwibW9iaWxlIjpmYWxzZX0=","authenticators-completed":"{\\"f347e3f0-f44e-4842-a159-7f89524ffc6d\\":1777764197,\\"349acc3f-0162-4b49-bfeb-5a7416aaffa4\\":1777764197}"},"state":"LOGGED_IN"}	1777764197	\N	0	f
duJQIF8Lo-Il1rmWyFuTNCoi	7d453f22-6ff1-41b9-98b7-57ceff01f445	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	1777764231	0	{"ipAddress":"172.22.0.4","authMethod":"openid-connect","rememberMe":false,"started":0,"notes":{"KC_DEVICE_NOTE":"eyJpcEFkZHJlc3MiOiIxNzIuMjIuMC40Iiwib3MiOiJPdGhlciIsIm9zVmVyc2lvbiI6IlVua25vd24iLCJicm93c2VyIjoiT3RoZXIvVW5rbm93biIsImRldmljZSI6Ik90aGVyIiwibGFzdEFjY2VzcyI6MCwibW9iaWxlIjpmYWxzZX0=","authenticators-completed":"{\\"f347e3f0-f44e-4842-a159-7f89524ffc6d\\":1777764231,\\"349acc3f-0162-4b49-bfeb-5a7416aaffa4\\":1777764231}"},"state":"LOGGED_IN"}	1777764231	\N	0	f
pP4HIVsEH03SDaAf2WLYo7ed	7d453f22-6ff1-41b9-98b7-57ceff01f445	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	1777764231	0	{"ipAddress":"172.22.0.4","authMethod":"openid-connect","rememberMe":false,"started":0,"notes":{"KC_DEVICE_NOTE":"eyJpcEFkZHJlc3MiOiIxNzIuMjIuMC40Iiwib3MiOiJPdGhlciIsIm9zVmVyc2lvbiI6IlVua25vd24iLCJicm93c2VyIjoiT3RoZXIvVW5rbm93biIsImRldmljZSI6Ik90aGVyIiwibGFzdEFjY2VzcyI6MCwibW9iaWxlIjpmYWxzZX0=","authenticators-completed":"{\\"f347e3f0-f44e-4842-a159-7f89524ffc6d\\":1777764231,\\"349acc3f-0162-4b49-bfeb-5a7416aaffa4\\":1777764231}"},"state":"LOGGED_IN"}	1777764231	\N	0	f
\.


--
-- Data for Name: org; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.org (id, enabled, realm_id, group_id, name, description, alias, redirect_url) FROM stdin;
\.


--
-- Data for Name: org_domain; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.org_domain (id, name, verified, org_id) FROM stdin;
\.


--
-- Data for Name: org_invitation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.org_invitation (id, organization_id, email, first_name, last_name, created_at, expires_at, invite_link) FROM stdin;
\.


--
-- Data for Name: policy_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.policy_config (policy_id, name, value) FROM stdin;
\.


--
-- Data for Name: protocol_mapper; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.protocol_mapper (id, name, protocol, protocol_mapper_name, client_id, client_scope_id) FROM stdin;
a45e7801-d9ff-4c7e-b406-5760815e8621	audience resolve	openid-connect	oidc-audience-resolve-mapper	a9243c21-3223-4b2a-92e4-67ebf2d2e151	\N
ec61bb3d-ed50-4b3b-a470-789e781fcc28	locale	openid-connect	oidc-usermodel-attribute-mapper	6b842f27-4404-4596-ab7a-26c56ffb44b0	\N
0b14f4f1-95dd-44bc-8f29-341feaf0c4b6	role list	saml	saml-role-list-mapper	\N	a2b7fe0b-7d98-486d-8ee0-12bd009c3154
75a5ddbb-6486-4966-8e3f-8ee13e840eab	organization	saml	saml-organization-membership-mapper	\N	a4f1760c-83a0-4ecc-a455-f2dfa4fd2eef
fdba39d3-4229-433f-ad8d-6c2090c6e04b	full name	openid-connect	oidc-full-name-mapper	\N	d9d47570-32cf-44eb-a329-93be5d5dbd9e
126bc118-4725-47dd-a1d0-eb5db503012f	family name	openid-connect	oidc-usermodel-attribute-mapper	\N	d9d47570-32cf-44eb-a329-93be5d5dbd9e
e06309e4-493c-4925-8664-cf54eecb76f6	given name	openid-connect	oidc-usermodel-attribute-mapper	\N	d9d47570-32cf-44eb-a329-93be5d5dbd9e
1fb21fa3-e76a-4dd5-b8aa-70488c9e94f6	middle name	openid-connect	oidc-usermodel-attribute-mapper	\N	d9d47570-32cf-44eb-a329-93be5d5dbd9e
c1f2b034-548b-4957-ba62-c1f825fb3725	nickname	openid-connect	oidc-usermodel-attribute-mapper	\N	d9d47570-32cf-44eb-a329-93be5d5dbd9e
66d04213-2973-4451-b89d-a326cd253a4d	username	openid-connect	oidc-usermodel-attribute-mapper	\N	d9d47570-32cf-44eb-a329-93be5d5dbd9e
10f4567f-94c7-4837-92fd-9f3750c05063	profile	openid-connect	oidc-usermodel-attribute-mapper	\N	d9d47570-32cf-44eb-a329-93be5d5dbd9e
19d9f9c8-71d1-402a-aa3e-b2a73950dc81	picture	openid-connect	oidc-usermodel-attribute-mapper	\N	d9d47570-32cf-44eb-a329-93be5d5dbd9e
e2f624d3-ec4c-48e3-9bba-62313cb46b17	website	openid-connect	oidc-usermodel-attribute-mapper	\N	d9d47570-32cf-44eb-a329-93be5d5dbd9e
065554bd-1af2-4117-9dc0-2fdc0e319bbf	gender	openid-connect	oidc-usermodel-attribute-mapper	\N	d9d47570-32cf-44eb-a329-93be5d5dbd9e
1a81c5a3-935e-43c3-bee2-4d6422f07fed	birthdate	openid-connect	oidc-usermodel-attribute-mapper	\N	d9d47570-32cf-44eb-a329-93be5d5dbd9e
e15bff23-b968-4b4c-9db3-90d5224a2f5f	zoneinfo	openid-connect	oidc-usermodel-attribute-mapper	\N	d9d47570-32cf-44eb-a329-93be5d5dbd9e
3f7e1c36-2df7-4ee4-a6ac-3aa444a8936b	locale	openid-connect	oidc-usermodel-attribute-mapper	\N	d9d47570-32cf-44eb-a329-93be5d5dbd9e
e1e0ee6a-3ee8-486b-a439-cc3280c62e83	updated at	openid-connect	oidc-usermodel-attribute-mapper	\N	d9d47570-32cf-44eb-a329-93be5d5dbd9e
5fcf8f12-c5b0-48f1-96fe-fffd50217b6b	email	openid-connect	oidc-usermodel-attribute-mapper	\N	80597c7a-c1f9-44ab-8f15-31c36ca51cd3
fcccafbf-12b8-46e7-adf2-a5f43b9a5935	email verified	openid-connect	oidc-usermodel-property-mapper	\N	80597c7a-c1f9-44ab-8f15-31c36ca51cd3
14cd8979-d0c2-4a1f-b463-11967c270f59	address	openid-connect	oidc-address-mapper	\N	67e3ddb1-a977-4fb8-a5c6-a57dd8804cda
3be337c0-9de1-47ee-8c7c-8e6cd4b481d2	phone number	openid-connect	oidc-usermodel-attribute-mapper	\N	161747f8-23e3-4e95-a21b-d3675be338e5
9c7f4e98-fb49-4685-af30-39c7e692bc4b	phone number verified	openid-connect	oidc-usermodel-attribute-mapper	\N	161747f8-23e3-4e95-a21b-d3675be338e5
638af2db-cfe1-460f-a385-7e7ceea8e4f1	realm roles	openid-connect	oidc-usermodel-realm-role-mapper	\N	0d9f8c42-cbda-4fa9-8f53-0af2c9dfdde3
941696db-2d97-4cc4-8bb8-07d4d2ec1c7d	client roles	openid-connect	oidc-usermodel-client-role-mapper	\N	0d9f8c42-cbda-4fa9-8f53-0af2c9dfdde3
35eabb12-b130-4245-9e5d-c5ec2e40afec	audience resolve	openid-connect	oidc-audience-resolve-mapper	\N	0d9f8c42-cbda-4fa9-8f53-0af2c9dfdde3
eee08c77-9edf-4c17-b0da-ea0534803652	allowed web origins	openid-connect	oidc-allowed-origins-mapper	\N	c54f2ec3-1987-4cd0-9dbd-5564abb04e76
fcce0fdb-49d0-4dca-81b0-1bb913e1d981	upn	openid-connect	oidc-usermodel-attribute-mapper	\N	8a10c45f-537f-4783-8cc1-34e42626984a
61792fd1-a20c-4f97-8785-201def8964d0	groups	openid-connect	oidc-usermodel-realm-role-mapper	\N	8a10c45f-537f-4783-8cc1-34e42626984a
574403cc-0144-4608-b8cf-f0afd673af0d	acr loa level	openid-connect	oidc-acr-mapper	\N	1e3e93ad-a248-44ae-82cb-be42caf1083a
fbe1fcc8-fd57-4ec6-a906-4b2fd8d4659f	auth_time	openid-connect	oidc-usersessionmodel-note-mapper	\N	5af68cc7-fab6-4258-b5b6-2feb36df3e2a
9ee4538e-ee1e-42da-8e95-58f9aee64a2c	sub	openid-connect	oidc-sub-mapper	\N	5af68cc7-fab6-4258-b5b6-2feb36df3e2a
8cdd562d-55cb-48a0-adaa-69321f6a8c83	Client ID	openid-connect	oidc-usersessionmodel-note-mapper	\N	6013a609-8730-4c61-affe-99d3535445ec
b8b8c28a-00a8-42e4-8853-7d45621fcdb2	Client Host	openid-connect	oidc-usersessionmodel-note-mapper	\N	6013a609-8730-4c61-affe-99d3535445ec
68690a20-f1d9-488f-9755-dd63f0b82e23	Client IP Address	openid-connect	oidc-usersessionmodel-note-mapper	\N	6013a609-8730-4c61-affe-99d3535445ec
114dcdb4-a659-4d2e-ac78-2f6f9b6e64b0	organization	openid-connect	oidc-organization-membership-mapper	\N	88dd4199-b555-4c54-90ad-d87376de9482
e8fb3cbf-664e-4678-bdc3-ccd85fbbebc4	audience resolve	openid-connect	oidc-audience-resolve-mapper	60044973-1f42-41b3-a8ed-dcd5ae7d763c	\N
ba53bf76-19e8-412e-ac9e-4006d959efde	role list	saml	saml-role-list-mapper	\N	3b010f52-041c-4a7a-9eb9-ae6bab3b9bd1
c9ade89e-8b74-41e0-963e-9b5fceb22616	organization	saml	saml-organization-membership-mapper	\N	0492b33d-d297-4009-9bdd-5f1dcf782cf3
68e14830-ff9f-4f34-ab81-e37b2c5b20c3	full name	openid-connect	oidc-full-name-mapper	\N	fd53d63e-abd9-4923-928a-9fba44904b06
a2778d67-5a20-4626-add6-b1333ae79a5f	family name	openid-connect	oidc-usermodel-attribute-mapper	\N	fd53d63e-abd9-4923-928a-9fba44904b06
21492e25-cb0d-4d02-9bbf-8f1826203316	given name	openid-connect	oidc-usermodel-attribute-mapper	\N	fd53d63e-abd9-4923-928a-9fba44904b06
3e3d279b-d89a-49a2-b41c-bdc09fb15ea6	middle name	openid-connect	oidc-usermodel-attribute-mapper	\N	fd53d63e-abd9-4923-928a-9fba44904b06
4e3b1003-25fa-4ebb-958a-b522bae34d74	nickname	openid-connect	oidc-usermodel-attribute-mapper	\N	fd53d63e-abd9-4923-928a-9fba44904b06
bc8ac1b8-214d-4156-8e12-fc2cab6cc086	username	openid-connect	oidc-usermodel-attribute-mapper	\N	fd53d63e-abd9-4923-928a-9fba44904b06
41b40a7b-7dae-4c1c-93d7-6a292c2eacec	profile	openid-connect	oidc-usermodel-attribute-mapper	\N	fd53d63e-abd9-4923-928a-9fba44904b06
739dae6b-a487-4694-bbf4-46c427c0db96	picture	openid-connect	oidc-usermodel-attribute-mapper	\N	fd53d63e-abd9-4923-928a-9fba44904b06
a81c0cd7-4aab-4300-b594-1a1dab8c3c44	website	openid-connect	oidc-usermodel-attribute-mapper	\N	fd53d63e-abd9-4923-928a-9fba44904b06
d32a01d7-6951-42d6-af2f-04d9d24c5aa1	gender	openid-connect	oidc-usermodel-attribute-mapper	\N	fd53d63e-abd9-4923-928a-9fba44904b06
3fe14292-ea36-4e4e-b064-205685ba0bd0	birthdate	openid-connect	oidc-usermodel-attribute-mapper	\N	fd53d63e-abd9-4923-928a-9fba44904b06
f4f72ece-f265-492c-9744-a1b8c9173d35	zoneinfo	openid-connect	oidc-usermodel-attribute-mapper	\N	fd53d63e-abd9-4923-928a-9fba44904b06
443513a6-e908-4325-9155-75b9790296db	locale	openid-connect	oidc-usermodel-attribute-mapper	\N	fd53d63e-abd9-4923-928a-9fba44904b06
751cfaec-f52e-478f-ac1c-81f632fe1654	updated at	openid-connect	oidc-usermodel-attribute-mapper	\N	fd53d63e-abd9-4923-928a-9fba44904b06
94c4d6d8-d60f-4f2b-845d-05e13d91f8d4	email	openid-connect	oidc-usermodel-attribute-mapper	\N	7a56b774-281d-4a64-8c54-2433df97f56f
b3672276-9f76-4ed0-b0b1-8bb43cb5aaa8	email verified	openid-connect	oidc-usermodel-property-mapper	\N	7a56b774-281d-4a64-8c54-2433df97f56f
6af39cdd-39d6-4722-8dd1-1e3261e5f3db	address	openid-connect	oidc-address-mapper	\N	d5d4bb63-9d28-4a83-b2ad-ea18d77e3cde
4f5770ca-ce5a-4b20-a6ee-aba9aa5b5065	phone number	openid-connect	oidc-usermodel-attribute-mapper	\N	f5731461-3ade-4754-8d03-799394e6b501
8ed584c7-1d28-427e-8204-5849f5608476	phone number verified	openid-connect	oidc-usermodel-attribute-mapper	\N	f5731461-3ade-4754-8d03-799394e6b501
2ae9be47-fe31-4c8c-a3c3-5f9edd049959	realm roles	openid-connect	oidc-usermodel-realm-role-mapper	\N	824686d7-ec63-4db4-86ee-daaf860b3340
cbfccd32-a790-4234-adf1-a97aa8343e7f	client roles	openid-connect	oidc-usermodel-client-role-mapper	\N	824686d7-ec63-4db4-86ee-daaf860b3340
bb50cbb9-b34f-47f8-8311-acd34a80835f	audience resolve	openid-connect	oidc-audience-resolve-mapper	\N	824686d7-ec63-4db4-86ee-daaf860b3340
bfc91058-a3ee-4e19-b330-98bef0f86578	allowed web origins	openid-connect	oidc-allowed-origins-mapper	\N	c72c60f1-de1d-46d7-917d-952d8cb6cb17
ccd5aa76-0e5d-4ff3-bc39-da59b3b4aa74	upn	openid-connect	oidc-usermodel-attribute-mapper	\N	eb6c56b3-7c18-4f2d-8d01-d4c2fae36bda
59589433-e486-4255-92be-e811d210a1cd	groups	openid-connect	oidc-usermodel-realm-role-mapper	\N	eb6c56b3-7c18-4f2d-8d01-d4c2fae36bda
efba7018-6af7-455b-9f1c-f52bf8b0c9ef	acr loa level	openid-connect	oidc-acr-mapper	\N	36504493-b5fa-4be1-8c55-9f9a07182a28
40947b8d-83a8-413b-b1e0-447a150aca5e	auth_time	openid-connect	oidc-usersessionmodel-note-mapper	\N	a63a51b4-5482-4c17-98fa-621abb8905cc
982e68f8-f789-406d-9bba-968c3793d324	sub	openid-connect	oidc-sub-mapper	\N	a63a51b4-5482-4c17-98fa-621abb8905cc
2d21e039-6ea3-4542-a582-943aca232383	Client ID	openid-connect	oidc-usersessionmodel-note-mapper	\N	803f155a-8316-4be0-8ef9-4f23ddc3c2bf
69fc7838-9da1-4ad5-97f5-a0d3e71723a3	Client Host	openid-connect	oidc-usersessionmodel-note-mapper	\N	803f155a-8316-4be0-8ef9-4f23ddc3c2bf
9e036b73-f4b2-4a62-9dcc-cb1d906631c8	Client IP Address	openid-connect	oidc-usersessionmodel-note-mapper	\N	803f155a-8316-4be0-8ef9-4f23ddc3c2bf
027ffecd-2a42-4ce7-9900-c3bde061dd86	organization	openid-connect	oidc-organization-membership-mapper	\N	7d4db986-2070-44e5-9096-48d2f4a85f47
c7303aea-5299-4d0c-be8a-8fda0218864f	locale	openid-connect	oidc-usermodel-attribute-mapper	b6f89aba-b213-40cd-abbb-9f80c8e88318	\N
3625ab25-891d-44de-ab90-9eca10e1eba6	fastapi audience	openid-connect	oidc-audience-mapper	b1a24523-e2b5-4cc6-af64-8364f8882e32	\N
\.


--
-- Data for Name: protocol_mapper_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.protocol_mapper_config (protocol_mapper_id, value, name) FROM stdin;
ec61bb3d-ed50-4b3b-a470-789e781fcc28	true	introspection.token.claim
ec61bb3d-ed50-4b3b-a470-789e781fcc28	true	userinfo.token.claim
ec61bb3d-ed50-4b3b-a470-789e781fcc28	locale	user.attribute
ec61bb3d-ed50-4b3b-a470-789e781fcc28	true	id.token.claim
ec61bb3d-ed50-4b3b-a470-789e781fcc28	true	access.token.claim
ec61bb3d-ed50-4b3b-a470-789e781fcc28	locale	claim.name
ec61bb3d-ed50-4b3b-a470-789e781fcc28	String	jsonType.label
0b14f4f1-95dd-44bc-8f29-341feaf0c4b6	false	single
0b14f4f1-95dd-44bc-8f29-341feaf0c4b6	Basic	attribute.nameformat
0b14f4f1-95dd-44bc-8f29-341feaf0c4b6	Role	attribute.name
065554bd-1af2-4117-9dc0-2fdc0e319bbf	true	introspection.token.claim
065554bd-1af2-4117-9dc0-2fdc0e319bbf	true	userinfo.token.claim
065554bd-1af2-4117-9dc0-2fdc0e319bbf	gender	user.attribute
065554bd-1af2-4117-9dc0-2fdc0e319bbf	true	id.token.claim
065554bd-1af2-4117-9dc0-2fdc0e319bbf	true	access.token.claim
065554bd-1af2-4117-9dc0-2fdc0e319bbf	gender	claim.name
065554bd-1af2-4117-9dc0-2fdc0e319bbf	String	jsonType.label
10f4567f-94c7-4837-92fd-9f3750c05063	true	introspection.token.claim
10f4567f-94c7-4837-92fd-9f3750c05063	true	userinfo.token.claim
10f4567f-94c7-4837-92fd-9f3750c05063	profile	user.attribute
10f4567f-94c7-4837-92fd-9f3750c05063	true	id.token.claim
10f4567f-94c7-4837-92fd-9f3750c05063	true	access.token.claim
10f4567f-94c7-4837-92fd-9f3750c05063	profile	claim.name
10f4567f-94c7-4837-92fd-9f3750c05063	String	jsonType.label
126bc118-4725-47dd-a1d0-eb5db503012f	true	introspection.token.claim
126bc118-4725-47dd-a1d0-eb5db503012f	true	userinfo.token.claim
126bc118-4725-47dd-a1d0-eb5db503012f	lastName	user.attribute
126bc118-4725-47dd-a1d0-eb5db503012f	true	id.token.claim
126bc118-4725-47dd-a1d0-eb5db503012f	true	access.token.claim
126bc118-4725-47dd-a1d0-eb5db503012f	family_name	claim.name
126bc118-4725-47dd-a1d0-eb5db503012f	String	jsonType.label
19d9f9c8-71d1-402a-aa3e-b2a73950dc81	true	introspection.token.claim
19d9f9c8-71d1-402a-aa3e-b2a73950dc81	true	userinfo.token.claim
19d9f9c8-71d1-402a-aa3e-b2a73950dc81	picture	user.attribute
19d9f9c8-71d1-402a-aa3e-b2a73950dc81	true	id.token.claim
19d9f9c8-71d1-402a-aa3e-b2a73950dc81	true	access.token.claim
19d9f9c8-71d1-402a-aa3e-b2a73950dc81	picture	claim.name
19d9f9c8-71d1-402a-aa3e-b2a73950dc81	String	jsonType.label
1a81c5a3-935e-43c3-bee2-4d6422f07fed	true	introspection.token.claim
1a81c5a3-935e-43c3-bee2-4d6422f07fed	true	userinfo.token.claim
1a81c5a3-935e-43c3-bee2-4d6422f07fed	birthdate	user.attribute
1a81c5a3-935e-43c3-bee2-4d6422f07fed	true	id.token.claim
1a81c5a3-935e-43c3-bee2-4d6422f07fed	true	access.token.claim
1a81c5a3-935e-43c3-bee2-4d6422f07fed	birthdate	claim.name
1a81c5a3-935e-43c3-bee2-4d6422f07fed	String	jsonType.label
1fb21fa3-e76a-4dd5-b8aa-70488c9e94f6	true	introspection.token.claim
1fb21fa3-e76a-4dd5-b8aa-70488c9e94f6	true	userinfo.token.claim
1fb21fa3-e76a-4dd5-b8aa-70488c9e94f6	middleName	user.attribute
1fb21fa3-e76a-4dd5-b8aa-70488c9e94f6	true	id.token.claim
1fb21fa3-e76a-4dd5-b8aa-70488c9e94f6	true	access.token.claim
1fb21fa3-e76a-4dd5-b8aa-70488c9e94f6	middle_name	claim.name
1fb21fa3-e76a-4dd5-b8aa-70488c9e94f6	String	jsonType.label
3f7e1c36-2df7-4ee4-a6ac-3aa444a8936b	true	introspection.token.claim
3f7e1c36-2df7-4ee4-a6ac-3aa444a8936b	true	userinfo.token.claim
3f7e1c36-2df7-4ee4-a6ac-3aa444a8936b	locale	user.attribute
3f7e1c36-2df7-4ee4-a6ac-3aa444a8936b	true	id.token.claim
3f7e1c36-2df7-4ee4-a6ac-3aa444a8936b	true	access.token.claim
3f7e1c36-2df7-4ee4-a6ac-3aa444a8936b	locale	claim.name
3f7e1c36-2df7-4ee4-a6ac-3aa444a8936b	String	jsonType.label
66d04213-2973-4451-b89d-a326cd253a4d	true	introspection.token.claim
66d04213-2973-4451-b89d-a326cd253a4d	true	userinfo.token.claim
66d04213-2973-4451-b89d-a326cd253a4d	username	user.attribute
66d04213-2973-4451-b89d-a326cd253a4d	true	id.token.claim
66d04213-2973-4451-b89d-a326cd253a4d	true	access.token.claim
66d04213-2973-4451-b89d-a326cd253a4d	preferred_username	claim.name
66d04213-2973-4451-b89d-a326cd253a4d	String	jsonType.label
c1f2b034-548b-4957-ba62-c1f825fb3725	true	introspection.token.claim
c1f2b034-548b-4957-ba62-c1f825fb3725	true	userinfo.token.claim
c1f2b034-548b-4957-ba62-c1f825fb3725	nickname	user.attribute
c1f2b034-548b-4957-ba62-c1f825fb3725	true	id.token.claim
c1f2b034-548b-4957-ba62-c1f825fb3725	true	access.token.claim
c1f2b034-548b-4957-ba62-c1f825fb3725	nickname	claim.name
c1f2b034-548b-4957-ba62-c1f825fb3725	String	jsonType.label
e06309e4-493c-4925-8664-cf54eecb76f6	true	introspection.token.claim
e06309e4-493c-4925-8664-cf54eecb76f6	true	userinfo.token.claim
e06309e4-493c-4925-8664-cf54eecb76f6	firstName	user.attribute
e06309e4-493c-4925-8664-cf54eecb76f6	true	id.token.claim
e06309e4-493c-4925-8664-cf54eecb76f6	true	access.token.claim
e06309e4-493c-4925-8664-cf54eecb76f6	given_name	claim.name
e06309e4-493c-4925-8664-cf54eecb76f6	String	jsonType.label
e15bff23-b968-4b4c-9db3-90d5224a2f5f	true	introspection.token.claim
e15bff23-b968-4b4c-9db3-90d5224a2f5f	true	userinfo.token.claim
e15bff23-b968-4b4c-9db3-90d5224a2f5f	zoneinfo	user.attribute
e15bff23-b968-4b4c-9db3-90d5224a2f5f	true	id.token.claim
e15bff23-b968-4b4c-9db3-90d5224a2f5f	true	access.token.claim
e15bff23-b968-4b4c-9db3-90d5224a2f5f	zoneinfo	claim.name
e15bff23-b968-4b4c-9db3-90d5224a2f5f	String	jsonType.label
e1e0ee6a-3ee8-486b-a439-cc3280c62e83	true	introspection.token.claim
e1e0ee6a-3ee8-486b-a439-cc3280c62e83	true	userinfo.token.claim
e1e0ee6a-3ee8-486b-a439-cc3280c62e83	updatedAt	user.attribute
e1e0ee6a-3ee8-486b-a439-cc3280c62e83	true	id.token.claim
e1e0ee6a-3ee8-486b-a439-cc3280c62e83	true	access.token.claim
e1e0ee6a-3ee8-486b-a439-cc3280c62e83	updated_at	claim.name
e1e0ee6a-3ee8-486b-a439-cc3280c62e83	long	jsonType.label
e2f624d3-ec4c-48e3-9bba-62313cb46b17	true	introspection.token.claim
e2f624d3-ec4c-48e3-9bba-62313cb46b17	true	userinfo.token.claim
e2f624d3-ec4c-48e3-9bba-62313cb46b17	website	user.attribute
e2f624d3-ec4c-48e3-9bba-62313cb46b17	true	id.token.claim
e2f624d3-ec4c-48e3-9bba-62313cb46b17	true	access.token.claim
e2f624d3-ec4c-48e3-9bba-62313cb46b17	website	claim.name
e2f624d3-ec4c-48e3-9bba-62313cb46b17	String	jsonType.label
fdba39d3-4229-433f-ad8d-6c2090c6e04b	true	introspection.token.claim
fdba39d3-4229-433f-ad8d-6c2090c6e04b	true	userinfo.token.claim
fdba39d3-4229-433f-ad8d-6c2090c6e04b	true	id.token.claim
fdba39d3-4229-433f-ad8d-6c2090c6e04b	true	access.token.claim
5fcf8f12-c5b0-48f1-96fe-fffd50217b6b	true	introspection.token.claim
5fcf8f12-c5b0-48f1-96fe-fffd50217b6b	true	userinfo.token.claim
5fcf8f12-c5b0-48f1-96fe-fffd50217b6b	email	user.attribute
5fcf8f12-c5b0-48f1-96fe-fffd50217b6b	true	id.token.claim
5fcf8f12-c5b0-48f1-96fe-fffd50217b6b	true	access.token.claim
5fcf8f12-c5b0-48f1-96fe-fffd50217b6b	email	claim.name
5fcf8f12-c5b0-48f1-96fe-fffd50217b6b	String	jsonType.label
fcccafbf-12b8-46e7-adf2-a5f43b9a5935	true	introspection.token.claim
fcccafbf-12b8-46e7-adf2-a5f43b9a5935	true	userinfo.token.claim
fcccafbf-12b8-46e7-adf2-a5f43b9a5935	emailVerified	user.attribute
fcccafbf-12b8-46e7-adf2-a5f43b9a5935	true	id.token.claim
fcccafbf-12b8-46e7-adf2-a5f43b9a5935	true	access.token.claim
fcccafbf-12b8-46e7-adf2-a5f43b9a5935	email_verified	claim.name
fcccafbf-12b8-46e7-adf2-a5f43b9a5935	boolean	jsonType.label
14cd8979-d0c2-4a1f-b463-11967c270f59	formatted	user.attribute.formatted
14cd8979-d0c2-4a1f-b463-11967c270f59	country	user.attribute.country
14cd8979-d0c2-4a1f-b463-11967c270f59	true	introspection.token.claim
14cd8979-d0c2-4a1f-b463-11967c270f59	postal_code	user.attribute.postal_code
14cd8979-d0c2-4a1f-b463-11967c270f59	true	userinfo.token.claim
14cd8979-d0c2-4a1f-b463-11967c270f59	street	user.attribute.street
14cd8979-d0c2-4a1f-b463-11967c270f59	true	id.token.claim
14cd8979-d0c2-4a1f-b463-11967c270f59	region	user.attribute.region
14cd8979-d0c2-4a1f-b463-11967c270f59	true	access.token.claim
14cd8979-d0c2-4a1f-b463-11967c270f59	locality	user.attribute.locality
3be337c0-9de1-47ee-8c7c-8e6cd4b481d2	true	introspection.token.claim
3be337c0-9de1-47ee-8c7c-8e6cd4b481d2	true	userinfo.token.claim
3be337c0-9de1-47ee-8c7c-8e6cd4b481d2	phoneNumber	user.attribute
3be337c0-9de1-47ee-8c7c-8e6cd4b481d2	true	id.token.claim
3be337c0-9de1-47ee-8c7c-8e6cd4b481d2	true	access.token.claim
3be337c0-9de1-47ee-8c7c-8e6cd4b481d2	phone_number	claim.name
3be337c0-9de1-47ee-8c7c-8e6cd4b481d2	String	jsonType.label
9c7f4e98-fb49-4685-af30-39c7e692bc4b	true	introspection.token.claim
9c7f4e98-fb49-4685-af30-39c7e692bc4b	true	userinfo.token.claim
9c7f4e98-fb49-4685-af30-39c7e692bc4b	phoneNumberVerified	user.attribute
9c7f4e98-fb49-4685-af30-39c7e692bc4b	true	id.token.claim
9c7f4e98-fb49-4685-af30-39c7e692bc4b	true	access.token.claim
9c7f4e98-fb49-4685-af30-39c7e692bc4b	phone_number_verified	claim.name
9c7f4e98-fb49-4685-af30-39c7e692bc4b	boolean	jsonType.label
35eabb12-b130-4245-9e5d-c5ec2e40afec	true	introspection.token.claim
35eabb12-b130-4245-9e5d-c5ec2e40afec	true	access.token.claim
638af2db-cfe1-460f-a385-7e7ceea8e4f1	true	introspection.token.claim
638af2db-cfe1-460f-a385-7e7ceea8e4f1	true	multivalued
638af2db-cfe1-460f-a385-7e7ceea8e4f1	foo	user.attribute
638af2db-cfe1-460f-a385-7e7ceea8e4f1	true	access.token.claim
638af2db-cfe1-460f-a385-7e7ceea8e4f1	realm_access.roles	claim.name
638af2db-cfe1-460f-a385-7e7ceea8e4f1	String	jsonType.label
941696db-2d97-4cc4-8bb8-07d4d2ec1c7d	true	introspection.token.claim
941696db-2d97-4cc4-8bb8-07d4d2ec1c7d	true	multivalued
941696db-2d97-4cc4-8bb8-07d4d2ec1c7d	foo	user.attribute
941696db-2d97-4cc4-8bb8-07d4d2ec1c7d	true	access.token.claim
941696db-2d97-4cc4-8bb8-07d4d2ec1c7d	resource_access.${client_id}.roles	claim.name
941696db-2d97-4cc4-8bb8-07d4d2ec1c7d	String	jsonType.label
eee08c77-9edf-4c17-b0da-ea0534803652	true	introspection.token.claim
eee08c77-9edf-4c17-b0da-ea0534803652	true	access.token.claim
61792fd1-a20c-4f97-8785-201def8964d0	true	introspection.token.claim
61792fd1-a20c-4f97-8785-201def8964d0	true	multivalued
61792fd1-a20c-4f97-8785-201def8964d0	foo	user.attribute
61792fd1-a20c-4f97-8785-201def8964d0	true	id.token.claim
61792fd1-a20c-4f97-8785-201def8964d0	true	access.token.claim
61792fd1-a20c-4f97-8785-201def8964d0	groups	claim.name
61792fd1-a20c-4f97-8785-201def8964d0	String	jsonType.label
fcce0fdb-49d0-4dca-81b0-1bb913e1d981	true	introspection.token.claim
fcce0fdb-49d0-4dca-81b0-1bb913e1d981	true	userinfo.token.claim
fcce0fdb-49d0-4dca-81b0-1bb913e1d981	username	user.attribute
fcce0fdb-49d0-4dca-81b0-1bb913e1d981	true	id.token.claim
fcce0fdb-49d0-4dca-81b0-1bb913e1d981	true	access.token.claim
fcce0fdb-49d0-4dca-81b0-1bb913e1d981	upn	claim.name
fcce0fdb-49d0-4dca-81b0-1bb913e1d981	String	jsonType.label
574403cc-0144-4608-b8cf-f0afd673af0d	true	introspection.token.claim
574403cc-0144-4608-b8cf-f0afd673af0d	true	id.token.claim
574403cc-0144-4608-b8cf-f0afd673af0d	true	access.token.claim
9ee4538e-ee1e-42da-8e95-58f9aee64a2c	true	introspection.token.claim
9ee4538e-ee1e-42da-8e95-58f9aee64a2c	true	access.token.claim
fbe1fcc8-fd57-4ec6-a906-4b2fd8d4659f	AUTH_TIME	user.session.note
fbe1fcc8-fd57-4ec6-a906-4b2fd8d4659f	true	introspection.token.claim
fbe1fcc8-fd57-4ec6-a906-4b2fd8d4659f	true	id.token.claim
fbe1fcc8-fd57-4ec6-a906-4b2fd8d4659f	true	access.token.claim
fbe1fcc8-fd57-4ec6-a906-4b2fd8d4659f	auth_time	claim.name
fbe1fcc8-fd57-4ec6-a906-4b2fd8d4659f	long	jsonType.label
68690a20-f1d9-488f-9755-dd63f0b82e23	clientAddress	user.session.note
68690a20-f1d9-488f-9755-dd63f0b82e23	true	introspection.token.claim
68690a20-f1d9-488f-9755-dd63f0b82e23	true	id.token.claim
68690a20-f1d9-488f-9755-dd63f0b82e23	true	access.token.claim
68690a20-f1d9-488f-9755-dd63f0b82e23	clientAddress	claim.name
68690a20-f1d9-488f-9755-dd63f0b82e23	String	jsonType.label
8cdd562d-55cb-48a0-adaa-69321f6a8c83	client_id	user.session.note
8cdd562d-55cb-48a0-adaa-69321f6a8c83	true	introspection.token.claim
8cdd562d-55cb-48a0-adaa-69321f6a8c83	true	id.token.claim
8cdd562d-55cb-48a0-adaa-69321f6a8c83	true	access.token.claim
8cdd562d-55cb-48a0-adaa-69321f6a8c83	client_id	claim.name
8cdd562d-55cb-48a0-adaa-69321f6a8c83	String	jsonType.label
b8b8c28a-00a8-42e4-8853-7d45621fcdb2	clientHost	user.session.note
b8b8c28a-00a8-42e4-8853-7d45621fcdb2	true	introspection.token.claim
b8b8c28a-00a8-42e4-8853-7d45621fcdb2	true	id.token.claim
b8b8c28a-00a8-42e4-8853-7d45621fcdb2	true	access.token.claim
b8b8c28a-00a8-42e4-8853-7d45621fcdb2	clientHost	claim.name
b8b8c28a-00a8-42e4-8853-7d45621fcdb2	String	jsonType.label
114dcdb4-a659-4d2e-ac78-2f6f9b6e64b0	true	introspection.token.claim
114dcdb4-a659-4d2e-ac78-2f6f9b6e64b0	true	multivalued
114dcdb4-a659-4d2e-ac78-2f6f9b6e64b0	true	id.token.claim
114dcdb4-a659-4d2e-ac78-2f6f9b6e64b0	true	access.token.claim
114dcdb4-a659-4d2e-ac78-2f6f9b6e64b0	organization	claim.name
114dcdb4-a659-4d2e-ac78-2f6f9b6e64b0	String	jsonType.label
ba53bf76-19e8-412e-ac9e-4006d959efde	false	single
ba53bf76-19e8-412e-ac9e-4006d959efde	Basic	attribute.nameformat
ba53bf76-19e8-412e-ac9e-4006d959efde	Role	attribute.name
21492e25-cb0d-4d02-9bbf-8f1826203316	true	introspection.token.claim
21492e25-cb0d-4d02-9bbf-8f1826203316	true	userinfo.token.claim
21492e25-cb0d-4d02-9bbf-8f1826203316	firstName	user.attribute
21492e25-cb0d-4d02-9bbf-8f1826203316	true	id.token.claim
21492e25-cb0d-4d02-9bbf-8f1826203316	true	access.token.claim
21492e25-cb0d-4d02-9bbf-8f1826203316	given_name	claim.name
21492e25-cb0d-4d02-9bbf-8f1826203316	String	jsonType.label
3e3d279b-d89a-49a2-b41c-bdc09fb15ea6	true	introspection.token.claim
3e3d279b-d89a-49a2-b41c-bdc09fb15ea6	true	userinfo.token.claim
3e3d279b-d89a-49a2-b41c-bdc09fb15ea6	middleName	user.attribute
3e3d279b-d89a-49a2-b41c-bdc09fb15ea6	true	id.token.claim
3e3d279b-d89a-49a2-b41c-bdc09fb15ea6	true	access.token.claim
3e3d279b-d89a-49a2-b41c-bdc09fb15ea6	middle_name	claim.name
3e3d279b-d89a-49a2-b41c-bdc09fb15ea6	String	jsonType.label
3fe14292-ea36-4e4e-b064-205685ba0bd0	true	introspection.token.claim
3fe14292-ea36-4e4e-b064-205685ba0bd0	true	userinfo.token.claim
3fe14292-ea36-4e4e-b064-205685ba0bd0	birthdate	user.attribute
3fe14292-ea36-4e4e-b064-205685ba0bd0	true	id.token.claim
3fe14292-ea36-4e4e-b064-205685ba0bd0	true	access.token.claim
3fe14292-ea36-4e4e-b064-205685ba0bd0	birthdate	claim.name
3fe14292-ea36-4e4e-b064-205685ba0bd0	String	jsonType.label
41b40a7b-7dae-4c1c-93d7-6a292c2eacec	true	introspection.token.claim
41b40a7b-7dae-4c1c-93d7-6a292c2eacec	true	userinfo.token.claim
41b40a7b-7dae-4c1c-93d7-6a292c2eacec	profile	user.attribute
41b40a7b-7dae-4c1c-93d7-6a292c2eacec	true	id.token.claim
41b40a7b-7dae-4c1c-93d7-6a292c2eacec	true	access.token.claim
41b40a7b-7dae-4c1c-93d7-6a292c2eacec	profile	claim.name
41b40a7b-7dae-4c1c-93d7-6a292c2eacec	String	jsonType.label
443513a6-e908-4325-9155-75b9790296db	true	introspection.token.claim
443513a6-e908-4325-9155-75b9790296db	true	userinfo.token.claim
443513a6-e908-4325-9155-75b9790296db	locale	user.attribute
443513a6-e908-4325-9155-75b9790296db	true	id.token.claim
443513a6-e908-4325-9155-75b9790296db	true	access.token.claim
443513a6-e908-4325-9155-75b9790296db	locale	claim.name
443513a6-e908-4325-9155-75b9790296db	String	jsonType.label
4e3b1003-25fa-4ebb-958a-b522bae34d74	true	introspection.token.claim
4e3b1003-25fa-4ebb-958a-b522bae34d74	true	userinfo.token.claim
4e3b1003-25fa-4ebb-958a-b522bae34d74	nickname	user.attribute
4e3b1003-25fa-4ebb-958a-b522bae34d74	true	id.token.claim
4e3b1003-25fa-4ebb-958a-b522bae34d74	true	access.token.claim
4e3b1003-25fa-4ebb-958a-b522bae34d74	nickname	claim.name
4e3b1003-25fa-4ebb-958a-b522bae34d74	String	jsonType.label
68e14830-ff9f-4f34-ab81-e37b2c5b20c3	true	introspection.token.claim
68e14830-ff9f-4f34-ab81-e37b2c5b20c3	true	userinfo.token.claim
68e14830-ff9f-4f34-ab81-e37b2c5b20c3	true	id.token.claim
68e14830-ff9f-4f34-ab81-e37b2c5b20c3	true	access.token.claim
739dae6b-a487-4694-bbf4-46c427c0db96	true	introspection.token.claim
739dae6b-a487-4694-bbf4-46c427c0db96	true	userinfo.token.claim
739dae6b-a487-4694-bbf4-46c427c0db96	picture	user.attribute
739dae6b-a487-4694-bbf4-46c427c0db96	true	id.token.claim
739dae6b-a487-4694-bbf4-46c427c0db96	true	access.token.claim
739dae6b-a487-4694-bbf4-46c427c0db96	picture	claim.name
739dae6b-a487-4694-bbf4-46c427c0db96	String	jsonType.label
751cfaec-f52e-478f-ac1c-81f632fe1654	true	introspection.token.claim
751cfaec-f52e-478f-ac1c-81f632fe1654	true	userinfo.token.claim
751cfaec-f52e-478f-ac1c-81f632fe1654	updatedAt	user.attribute
751cfaec-f52e-478f-ac1c-81f632fe1654	true	id.token.claim
751cfaec-f52e-478f-ac1c-81f632fe1654	true	access.token.claim
751cfaec-f52e-478f-ac1c-81f632fe1654	updated_at	claim.name
751cfaec-f52e-478f-ac1c-81f632fe1654	long	jsonType.label
a2778d67-5a20-4626-add6-b1333ae79a5f	true	introspection.token.claim
a2778d67-5a20-4626-add6-b1333ae79a5f	true	userinfo.token.claim
a2778d67-5a20-4626-add6-b1333ae79a5f	lastName	user.attribute
a2778d67-5a20-4626-add6-b1333ae79a5f	true	id.token.claim
a2778d67-5a20-4626-add6-b1333ae79a5f	true	access.token.claim
a2778d67-5a20-4626-add6-b1333ae79a5f	family_name	claim.name
a2778d67-5a20-4626-add6-b1333ae79a5f	String	jsonType.label
a81c0cd7-4aab-4300-b594-1a1dab8c3c44	true	introspection.token.claim
a81c0cd7-4aab-4300-b594-1a1dab8c3c44	true	userinfo.token.claim
a81c0cd7-4aab-4300-b594-1a1dab8c3c44	website	user.attribute
a81c0cd7-4aab-4300-b594-1a1dab8c3c44	true	id.token.claim
a81c0cd7-4aab-4300-b594-1a1dab8c3c44	true	access.token.claim
a81c0cd7-4aab-4300-b594-1a1dab8c3c44	website	claim.name
a81c0cd7-4aab-4300-b594-1a1dab8c3c44	String	jsonType.label
bc8ac1b8-214d-4156-8e12-fc2cab6cc086	true	introspection.token.claim
bc8ac1b8-214d-4156-8e12-fc2cab6cc086	true	userinfo.token.claim
bc8ac1b8-214d-4156-8e12-fc2cab6cc086	username	user.attribute
bc8ac1b8-214d-4156-8e12-fc2cab6cc086	true	id.token.claim
bc8ac1b8-214d-4156-8e12-fc2cab6cc086	true	access.token.claim
bc8ac1b8-214d-4156-8e12-fc2cab6cc086	preferred_username	claim.name
bc8ac1b8-214d-4156-8e12-fc2cab6cc086	String	jsonType.label
d32a01d7-6951-42d6-af2f-04d9d24c5aa1	true	introspection.token.claim
d32a01d7-6951-42d6-af2f-04d9d24c5aa1	true	userinfo.token.claim
d32a01d7-6951-42d6-af2f-04d9d24c5aa1	gender	user.attribute
d32a01d7-6951-42d6-af2f-04d9d24c5aa1	true	id.token.claim
d32a01d7-6951-42d6-af2f-04d9d24c5aa1	true	access.token.claim
d32a01d7-6951-42d6-af2f-04d9d24c5aa1	gender	claim.name
d32a01d7-6951-42d6-af2f-04d9d24c5aa1	String	jsonType.label
f4f72ece-f265-492c-9744-a1b8c9173d35	true	introspection.token.claim
f4f72ece-f265-492c-9744-a1b8c9173d35	true	userinfo.token.claim
f4f72ece-f265-492c-9744-a1b8c9173d35	zoneinfo	user.attribute
f4f72ece-f265-492c-9744-a1b8c9173d35	true	id.token.claim
f4f72ece-f265-492c-9744-a1b8c9173d35	true	access.token.claim
f4f72ece-f265-492c-9744-a1b8c9173d35	zoneinfo	claim.name
f4f72ece-f265-492c-9744-a1b8c9173d35	String	jsonType.label
94c4d6d8-d60f-4f2b-845d-05e13d91f8d4	true	introspection.token.claim
94c4d6d8-d60f-4f2b-845d-05e13d91f8d4	true	userinfo.token.claim
94c4d6d8-d60f-4f2b-845d-05e13d91f8d4	email	user.attribute
94c4d6d8-d60f-4f2b-845d-05e13d91f8d4	true	id.token.claim
94c4d6d8-d60f-4f2b-845d-05e13d91f8d4	true	access.token.claim
94c4d6d8-d60f-4f2b-845d-05e13d91f8d4	email	claim.name
94c4d6d8-d60f-4f2b-845d-05e13d91f8d4	String	jsonType.label
b3672276-9f76-4ed0-b0b1-8bb43cb5aaa8	true	introspection.token.claim
b3672276-9f76-4ed0-b0b1-8bb43cb5aaa8	true	userinfo.token.claim
b3672276-9f76-4ed0-b0b1-8bb43cb5aaa8	emailVerified	user.attribute
b3672276-9f76-4ed0-b0b1-8bb43cb5aaa8	true	id.token.claim
b3672276-9f76-4ed0-b0b1-8bb43cb5aaa8	true	access.token.claim
b3672276-9f76-4ed0-b0b1-8bb43cb5aaa8	email_verified	claim.name
b3672276-9f76-4ed0-b0b1-8bb43cb5aaa8	boolean	jsonType.label
6af39cdd-39d6-4722-8dd1-1e3261e5f3db	formatted	user.attribute.formatted
6af39cdd-39d6-4722-8dd1-1e3261e5f3db	country	user.attribute.country
6af39cdd-39d6-4722-8dd1-1e3261e5f3db	true	introspection.token.claim
6af39cdd-39d6-4722-8dd1-1e3261e5f3db	postal_code	user.attribute.postal_code
6af39cdd-39d6-4722-8dd1-1e3261e5f3db	true	userinfo.token.claim
6af39cdd-39d6-4722-8dd1-1e3261e5f3db	street	user.attribute.street
6af39cdd-39d6-4722-8dd1-1e3261e5f3db	true	id.token.claim
6af39cdd-39d6-4722-8dd1-1e3261e5f3db	region	user.attribute.region
6af39cdd-39d6-4722-8dd1-1e3261e5f3db	true	access.token.claim
6af39cdd-39d6-4722-8dd1-1e3261e5f3db	locality	user.attribute.locality
4f5770ca-ce5a-4b20-a6ee-aba9aa5b5065	true	introspection.token.claim
4f5770ca-ce5a-4b20-a6ee-aba9aa5b5065	true	userinfo.token.claim
4f5770ca-ce5a-4b20-a6ee-aba9aa5b5065	phoneNumber	user.attribute
4f5770ca-ce5a-4b20-a6ee-aba9aa5b5065	true	id.token.claim
4f5770ca-ce5a-4b20-a6ee-aba9aa5b5065	true	access.token.claim
4f5770ca-ce5a-4b20-a6ee-aba9aa5b5065	phone_number	claim.name
4f5770ca-ce5a-4b20-a6ee-aba9aa5b5065	String	jsonType.label
8ed584c7-1d28-427e-8204-5849f5608476	true	introspection.token.claim
8ed584c7-1d28-427e-8204-5849f5608476	true	userinfo.token.claim
8ed584c7-1d28-427e-8204-5849f5608476	phoneNumberVerified	user.attribute
8ed584c7-1d28-427e-8204-5849f5608476	true	id.token.claim
8ed584c7-1d28-427e-8204-5849f5608476	true	access.token.claim
8ed584c7-1d28-427e-8204-5849f5608476	phone_number_verified	claim.name
8ed584c7-1d28-427e-8204-5849f5608476	boolean	jsonType.label
2ae9be47-fe31-4c8c-a3c3-5f9edd049959	true	introspection.token.claim
2ae9be47-fe31-4c8c-a3c3-5f9edd049959	true	multivalued
2ae9be47-fe31-4c8c-a3c3-5f9edd049959	foo	user.attribute
2ae9be47-fe31-4c8c-a3c3-5f9edd049959	true	access.token.claim
2ae9be47-fe31-4c8c-a3c3-5f9edd049959	realm_access.roles	claim.name
2ae9be47-fe31-4c8c-a3c3-5f9edd049959	String	jsonType.label
bb50cbb9-b34f-47f8-8311-acd34a80835f	true	introspection.token.claim
bb50cbb9-b34f-47f8-8311-acd34a80835f	true	access.token.claim
cbfccd32-a790-4234-adf1-a97aa8343e7f	true	introspection.token.claim
cbfccd32-a790-4234-adf1-a97aa8343e7f	true	multivalued
cbfccd32-a790-4234-adf1-a97aa8343e7f	foo	user.attribute
cbfccd32-a790-4234-adf1-a97aa8343e7f	true	access.token.claim
cbfccd32-a790-4234-adf1-a97aa8343e7f	resource_access.${client_id}.roles	claim.name
cbfccd32-a790-4234-adf1-a97aa8343e7f	String	jsonType.label
bfc91058-a3ee-4e19-b330-98bef0f86578	true	introspection.token.claim
bfc91058-a3ee-4e19-b330-98bef0f86578	true	access.token.claim
59589433-e486-4255-92be-e811d210a1cd	true	introspection.token.claim
59589433-e486-4255-92be-e811d210a1cd	true	multivalued
59589433-e486-4255-92be-e811d210a1cd	foo	user.attribute
59589433-e486-4255-92be-e811d210a1cd	true	id.token.claim
59589433-e486-4255-92be-e811d210a1cd	true	access.token.claim
59589433-e486-4255-92be-e811d210a1cd	groups	claim.name
59589433-e486-4255-92be-e811d210a1cd	String	jsonType.label
ccd5aa76-0e5d-4ff3-bc39-da59b3b4aa74	true	introspection.token.claim
ccd5aa76-0e5d-4ff3-bc39-da59b3b4aa74	true	userinfo.token.claim
ccd5aa76-0e5d-4ff3-bc39-da59b3b4aa74	username	user.attribute
ccd5aa76-0e5d-4ff3-bc39-da59b3b4aa74	true	id.token.claim
ccd5aa76-0e5d-4ff3-bc39-da59b3b4aa74	true	access.token.claim
ccd5aa76-0e5d-4ff3-bc39-da59b3b4aa74	upn	claim.name
ccd5aa76-0e5d-4ff3-bc39-da59b3b4aa74	String	jsonType.label
efba7018-6af7-455b-9f1c-f52bf8b0c9ef	true	introspection.token.claim
efba7018-6af7-455b-9f1c-f52bf8b0c9ef	true	id.token.claim
efba7018-6af7-455b-9f1c-f52bf8b0c9ef	true	access.token.claim
40947b8d-83a8-413b-b1e0-447a150aca5e	AUTH_TIME	user.session.note
40947b8d-83a8-413b-b1e0-447a150aca5e	true	introspection.token.claim
40947b8d-83a8-413b-b1e0-447a150aca5e	true	id.token.claim
40947b8d-83a8-413b-b1e0-447a150aca5e	true	access.token.claim
40947b8d-83a8-413b-b1e0-447a150aca5e	auth_time	claim.name
40947b8d-83a8-413b-b1e0-447a150aca5e	long	jsonType.label
982e68f8-f789-406d-9bba-968c3793d324	true	introspection.token.claim
982e68f8-f789-406d-9bba-968c3793d324	true	access.token.claim
2d21e039-6ea3-4542-a582-943aca232383	client_id	user.session.note
2d21e039-6ea3-4542-a582-943aca232383	true	introspection.token.claim
2d21e039-6ea3-4542-a582-943aca232383	true	id.token.claim
2d21e039-6ea3-4542-a582-943aca232383	true	access.token.claim
2d21e039-6ea3-4542-a582-943aca232383	client_id	claim.name
2d21e039-6ea3-4542-a582-943aca232383	String	jsonType.label
69fc7838-9da1-4ad5-97f5-a0d3e71723a3	clientHost	user.session.note
69fc7838-9da1-4ad5-97f5-a0d3e71723a3	true	introspection.token.claim
69fc7838-9da1-4ad5-97f5-a0d3e71723a3	true	id.token.claim
69fc7838-9da1-4ad5-97f5-a0d3e71723a3	true	access.token.claim
69fc7838-9da1-4ad5-97f5-a0d3e71723a3	clientHost	claim.name
69fc7838-9da1-4ad5-97f5-a0d3e71723a3	String	jsonType.label
9e036b73-f4b2-4a62-9dcc-cb1d906631c8	clientAddress	user.session.note
9e036b73-f4b2-4a62-9dcc-cb1d906631c8	true	introspection.token.claim
9e036b73-f4b2-4a62-9dcc-cb1d906631c8	true	id.token.claim
9e036b73-f4b2-4a62-9dcc-cb1d906631c8	true	access.token.claim
9e036b73-f4b2-4a62-9dcc-cb1d906631c8	clientAddress	claim.name
9e036b73-f4b2-4a62-9dcc-cb1d906631c8	String	jsonType.label
027ffecd-2a42-4ce7-9900-c3bde061dd86	true	introspection.token.claim
027ffecd-2a42-4ce7-9900-c3bde061dd86	true	multivalued
027ffecd-2a42-4ce7-9900-c3bde061dd86	true	id.token.claim
027ffecd-2a42-4ce7-9900-c3bde061dd86	true	access.token.claim
027ffecd-2a42-4ce7-9900-c3bde061dd86	organization	claim.name
027ffecd-2a42-4ce7-9900-c3bde061dd86	String	jsonType.label
c7303aea-5299-4d0c-be8a-8fda0218864f	true	introspection.token.claim
c7303aea-5299-4d0c-be8a-8fda0218864f	true	userinfo.token.claim
c7303aea-5299-4d0c-be8a-8fda0218864f	locale	user.attribute
c7303aea-5299-4d0c-be8a-8fda0218864f	true	id.token.claim
c7303aea-5299-4d0c-be8a-8fda0218864f	true	access.token.claim
c7303aea-5299-4d0c-be8a-8fda0218864f	locale	claim.name
c7303aea-5299-4d0c-be8a-8fda0218864f	String	jsonType.label
3625ab25-891d-44de-ab90-9eca10e1eba6	fastapi	included.client.audience
3625ab25-891d-44de-ab90-9eca10e1eba6	false	lightweight.claim
3625ab25-891d-44de-ab90-9eca10e1eba6	true	access.token.claim
3625ab25-891d-44de-ab90-9eca10e1eba6	true	introspection.token.claim
3625ab25-891d-44de-ab90-9eca10e1eba6	false	userinfo.token.claim
3625ab25-891d-44de-ab90-9eca10e1eba6	false	id.token.claim
\.


--
-- Data for Name: realm; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.realm (id, access_code_lifespan, user_action_lifespan, access_token_lifespan, account_theme, admin_theme, email_theme, enabled, events_enabled, events_expiration, login_theme, name, not_before, password_policy, registration_allowed, remember_me, reset_password_allowed, social, ssl_required, sso_idle_timeout, sso_max_lifespan, update_profile_on_soc_login, verify_email, master_admin_client, login_lifespan, internationalization_enabled, default_locale, reg_email_as_username, admin_events_enabled, admin_events_details_enabled, edit_username_allowed, otp_policy_counter, otp_policy_window, otp_policy_period, otp_policy_digits, otp_policy_alg, otp_policy_type, browser_flow, registration_flow, direct_grant_flow, reset_credentials_flow, client_auth_flow, offline_session_idle_timeout, revoke_refresh_token, access_token_life_implicit, login_with_email_allowed, duplicate_emails_allowed, docker_auth_flow, refresh_token_max_reuse, allow_user_managed_access, sso_max_lifespan_remember_me, sso_idle_timeout_remember_me, default_role) FROM stdin;
207d128c-bb74-4e7f-a3e4-f110b22d6159	60	300	60	\N	\N	\N	t	f	0	\N	master	0	\N	f	f	f	f	EXTERNAL	1800	36000	f	f	ca2290a5-e261-4a4b-a561-a5f46b1ebdf1	1800	f	\N	f	f	f	f	0	1	30	6	HmacSHA1	totp	bfa662ae-0fcb-4e58-9df8-7c8bafc4f46c	8711b87f-e4b0-4b79-a230-74c1a5f6d6b1	b217f8a7-b7fe-4de3-9417-2b0921484bf7	4a7ecad5-d559-494c-a925-ab478496eacb	5ad8e03e-a629-4f31-b86a-80146e9c49e6	2592000	f	900	t	f	7a9e037a-25a6-4def-90a9-bd00c6bf380b	0	f	0	0	49673cc1-a91d-4029-bb02-bbf4936dc948
c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	60	300	300	\N	\N	\N	t	f	0	\N	restapi	0	\N	f	f	f	f	EXTERNAL	1800	36000	f	f	5ec2d1e6-857c-4ec2-8302-a12f70ffe727	1800	f	\N	f	f	f	f	0	1	30	6	HmacSHA1	totp	a4530a77-3919-4a8e-9cfc-d663a4e0165a	20160cc4-f452-437f-95c1-daf7d1397315	0bb4f287-0170-4fcc-83c4-0a16073f7dd4	df09f8ba-2c5f-4328-aae7-56684bacc86a	e202c49b-5a43-4085-9a13-f2826fe2e33a	2592000	f	900	t	f	11537926-a252-412d-b0fd-e864c4421285	0	f	0	0	03e71ffe-54f7-455a-88b8-f7949197653d
\.


--
-- Data for Name: realm_attribute; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.realm_attribute (name, realm_id, value) FROM stdin;
_browser_header.contentSecurityPolicyReportOnly	207d128c-bb74-4e7f-a3e4-f110b22d6159	
_browser_header.xContentTypeOptions	207d128c-bb74-4e7f-a3e4-f110b22d6159	nosniff
_browser_header.referrerPolicy	207d128c-bb74-4e7f-a3e4-f110b22d6159	no-referrer
_browser_header.xRobotsTag	207d128c-bb74-4e7f-a3e4-f110b22d6159	none
_browser_header.xFrameOptions	207d128c-bb74-4e7f-a3e4-f110b22d6159	SAMEORIGIN
_browser_header.contentSecurityPolicy	207d128c-bb74-4e7f-a3e4-f110b22d6159	frame-src 'self'; frame-ancestors 'self'; object-src 'none';
_browser_header.strictTransportSecurity	207d128c-bb74-4e7f-a3e4-f110b22d6159	max-age=31536000; includeSubDomains
bruteForceProtected	207d128c-bb74-4e7f-a3e4-f110b22d6159	false
permanentLockout	207d128c-bb74-4e7f-a3e4-f110b22d6159	false
maxTemporaryLockouts	207d128c-bb74-4e7f-a3e4-f110b22d6159	0
bruteForceStrategy	207d128c-bb74-4e7f-a3e4-f110b22d6159	MULTIPLE
maxFailureWaitSeconds	207d128c-bb74-4e7f-a3e4-f110b22d6159	900
minimumQuickLoginWaitSeconds	207d128c-bb74-4e7f-a3e4-f110b22d6159	60
waitIncrementSeconds	207d128c-bb74-4e7f-a3e4-f110b22d6159	60
quickLoginCheckMilliSeconds	207d128c-bb74-4e7f-a3e4-f110b22d6159	1000
maxDeltaTimeSeconds	207d128c-bb74-4e7f-a3e4-f110b22d6159	43200
failureFactor	207d128c-bb74-4e7f-a3e4-f110b22d6159	30
realmReusableOtpCode	207d128c-bb74-4e7f-a3e4-f110b22d6159	false
firstBrokerLoginFlowId	207d128c-bb74-4e7f-a3e4-f110b22d6159	13ea6b8b-af26-44ac-ad24-6e6bd7cdbc22
displayName	207d128c-bb74-4e7f-a3e4-f110b22d6159	Keycloak
displayNameHtml	207d128c-bb74-4e7f-a3e4-f110b22d6159	<div class="kc-logo-text"><span>Keycloak</span></div>
defaultSignatureAlgorithm	207d128c-bb74-4e7f-a3e4-f110b22d6159	RS256
offlineSessionMaxLifespanEnabled	207d128c-bb74-4e7f-a3e4-f110b22d6159	false
offlineSessionMaxLifespan	207d128c-bb74-4e7f-a3e4-f110b22d6159	5184000
_browser_header.contentSecurityPolicyReportOnly	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	
_browser_header.xContentTypeOptions	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	nosniff
_browser_header.referrerPolicy	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	no-referrer
_browser_header.xRobotsTag	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	none
_browser_header.xFrameOptions	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	SAMEORIGIN
_browser_header.contentSecurityPolicy	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	frame-src 'self'; frame-ancestors 'self'; object-src 'none';
_browser_header.strictTransportSecurity	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	max-age=31536000; includeSubDomains
bruteForceProtected	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	false
permanentLockout	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	false
maxTemporaryLockouts	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	0
bruteForceStrategy	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	MULTIPLE
maxFailureWaitSeconds	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	900
minimumQuickLoginWaitSeconds	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	60
waitIncrementSeconds	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	60
quickLoginCheckMilliSeconds	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	1000
maxDeltaTimeSeconds	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	43200
failureFactor	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	30
realmReusableOtpCode	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	false
defaultSignatureAlgorithm	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	RS256
offlineSessionMaxLifespanEnabled	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	false
offlineSessionMaxLifespan	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	5184000
actionTokenGeneratedByAdminLifespan	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	43200
actionTokenGeneratedByUserLifespan	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	300
oauth2DeviceCodeLifespan	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	600
oauth2DevicePollingInterval	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	5
webAuthnPolicyRpEntityName	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	keycloak
webAuthnPolicySignatureAlgorithms	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	ES256,RS256
webAuthnPolicyRpId	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	
webAuthnPolicyAttestationConveyancePreference	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	not specified
webAuthnPolicyAuthenticatorAttachment	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	not specified
webAuthnPolicyRequireResidentKey	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	not specified
webAuthnPolicyUserVerificationRequirement	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	not specified
webAuthnPolicyCreateTimeout	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	0
webAuthnPolicyAvoidSameAuthenticatorRegister	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	false
webAuthnPolicyRpEntityNamePasswordless	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	keycloak
webAuthnPolicySignatureAlgorithmsPasswordless	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	ES256,RS256
webAuthnPolicyRpIdPasswordless	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	
webAuthnPolicyAttestationConveyancePreferencePasswordless	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	not specified
webAuthnPolicyAuthenticatorAttachmentPasswordless	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	not specified
webAuthnPolicyRequireResidentKeyPasswordless	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	Yes
webAuthnPolicyUserVerificationRequirementPasswordless	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	required
webAuthnPolicyCreateTimeoutPasswordless	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	0
webAuthnPolicyAvoidSameAuthenticatorRegisterPasswordless	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	false
cibaBackchannelTokenDeliveryMode	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	poll
cibaExpiresIn	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	120
cibaInterval	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	5
cibaAuthRequestedUserHint	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	login_hint
parRequestUriLifespan	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	60
firstBrokerLoginFlowId	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	46080925-c3c5-44c5-aada-601d3cf538e2
\.


--
-- Data for Name: realm_default_groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.realm_default_groups (realm_id, group_id) FROM stdin;
\.


--
-- Data for Name: realm_enabled_event_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.realm_enabled_event_types (realm_id, value) FROM stdin;
\.


--
-- Data for Name: realm_events_listeners; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.realm_events_listeners (realm_id, value) FROM stdin;
207d128c-bb74-4e7f-a3e4-f110b22d6159	jboss-logging
c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	jboss-logging
\.


--
-- Data for Name: realm_localizations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.realm_localizations (realm_id, locale, texts) FROM stdin;
\.


--
-- Data for Name: realm_required_credential; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.realm_required_credential (type, form_label, input, secret, realm_id) FROM stdin;
password	password	t	t	207d128c-bb74-4e7f-a3e4-f110b22d6159
password	password	t	t	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a
\.


--
-- Data for Name: realm_smtp_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.realm_smtp_config (realm_id, value, name) FROM stdin;
\.


--
-- Data for Name: realm_supported_locales; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.realm_supported_locales (realm_id, value) FROM stdin;
\.


--
-- Data for Name: redirect_uris; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.redirect_uris (client_id, value) FROM stdin;
c05b475f-598d-429b-80d1-276ca9e572a0	/realms/master/account/*
a9243c21-3223-4b2a-92e4-67ebf2d2e151	/realms/master/account/*
6b842f27-4404-4596-ab7a-26c56ffb44b0	/admin/master/console/*
fd19d9b9-ed5b-4fbb-a325-9d49639a74db	/realms/restapi/account/*
60044973-1f42-41b3-a8ed-dcd5ae7d763c	/realms/restapi/account/*
b6f89aba-b213-40cd-abbb-9f80c8e88318	/admin/restapi/console/*
b1a24523-e2b5-4cc6-af64-8364f8882e32	/*
\.


--
-- Data for Name: required_action_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.required_action_config (required_action_id, value, name) FROM stdin;
\.


--
-- Data for Name: required_action_provider; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.required_action_provider (id, alias, name, realm_id, enabled, default_action, provider_id, priority) FROM stdin;
c875f0e4-3bc4-4287-a2fc-602926df18f9	VERIFY_EMAIL	Verify Email	207d128c-bb74-4e7f-a3e4-f110b22d6159	t	f	VERIFY_EMAIL	50
3835f705-9666-47f4-a4a5-1409084b2e35	UPDATE_PROFILE	Update Profile	207d128c-bb74-4e7f-a3e4-f110b22d6159	t	f	UPDATE_PROFILE	40
89c6a939-5844-43d1-b345-6c5b3681a819	CONFIGURE_TOTP	Configure OTP	207d128c-bb74-4e7f-a3e4-f110b22d6159	t	f	CONFIGURE_TOTP	10
fd76936f-07cc-40d6-8253-7c5d09041be8	UPDATE_PASSWORD	Update Password	207d128c-bb74-4e7f-a3e4-f110b22d6159	t	f	UPDATE_PASSWORD	30
270a4d6a-43e9-4d16-9eb7-9d36e6b2adc9	TERMS_AND_CONDITIONS	Terms and Conditions	207d128c-bb74-4e7f-a3e4-f110b22d6159	f	f	TERMS_AND_CONDITIONS	20
4e427535-b39e-469e-b19e-d70bf4eef914	delete_account	Delete Account	207d128c-bb74-4e7f-a3e4-f110b22d6159	f	f	delete_account	60
2493bdb5-22db-4ba8-8565-17caf38cfefd	delete_credential	Delete Credential	207d128c-bb74-4e7f-a3e4-f110b22d6159	t	f	delete_credential	110
e0aa1ebf-6b4c-43db-a708-9665c0bfe8e9	update_user_locale	Update User Locale	207d128c-bb74-4e7f-a3e4-f110b22d6159	t	f	update_user_locale	1000
6c326d17-e117-4a40-ba75-3f30e82d244f	UPDATE_EMAIL	Update Email	207d128c-bb74-4e7f-a3e4-f110b22d6159	f	f	UPDATE_EMAIL	70
7e6e0314-c8c0-4401-983d-961473955bea	CONFIGURE_RECOVERY_AUTHN_CODES	Recovery Authentication Codes	207d128c-bb74-4e7f-a3e4-f110b22d6159	t	f	CONFIGURE_RECOVERY_AUTHN_CODES	130
9627b65e-2412-4dba-9c47-6f4466623f59	webauthn-register	Webauthn Register	207d128c-bb74-4e7f-a3e4-f110b22d6159	t	f	webauthn-register	80
68ebc037-abf4-4369-b471-98c4570fd363	webauthn-register-passwordless	Webauthn Register Passwordless	207d128c-bb74-4e7f-a3e4-f110b22d6159	t	f	webauthn-register-passwordless	90
91708878-2fe9-40a9-bb3e-00dafa6731f3	VERIFY_PROFILE	Verify Profile	207d128c-bb74-4e7f-a3e4-f110b22d6159	t	f	VERIFY_PROFILE	100
68554522-d838-4fde-9ca4-cb7b67b77160	idp_link	Linking Identity Provider	207d128c-bb74-4e7f-a3e4-f110b22d6159	t	f	idp_link	120
053f3673-3c46-4a0b-8b4f-a2d8a451f57d	VERIFY_EMAIL	Verify Email	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	t	f	VERIFY_EMAIL	50
f71a11a0-381f-406a-9992-42f6aaa482b0	UPDATE_PROFILE	Update Profile	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	t	f	UPDATE_PROFILE	40
824a35ea-3106-4f83-8636-b5e889751f9d	CONFIGURE_TOTP	Configure OTP	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	t	f	CONFIGURE_TOTP	10
5ac5d576-d9b9-407e-b652-bef1ca6163eb	UPDATE_PASSWORD	Update Password	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	t	f	UPDATE_PASSWORD	30
4c887e7b-1e93-4616-b8b1-4e38664686ff	TERMS_AND_CONDITIONS	Terms and Conditions	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	f	f	TERMS_AND_CONDITIONS	20
a575df91-23a4-4705-a94a-3d24e0f5151c	delete_account	Delete Account	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	f	f	delete_account	60
158105e2-dae9-4e65-be65-83d05686cd02	delete_credential	Delete Credential	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	t	f	delete_credential	110
58149bfc-559c-4fc1-bec8-369e71353d1c	update_user_locale	Update User Locale	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	t	f	update_user_locale	1000
680e0b2b-e635-4802-a303-9fd367516cbb	UPDATE_EMAIL	Update Email	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	f	f	UPDATE_EMAIL	70
3ea77710-0f23-4f01-856c-cac8dde9d26e	CONFIGURE_RECOVERY_AUTHN_CODES	Recovery Authentication Codes	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	t	f	CONFIGURE_RECOVERY_AUTHN_CODES	130
9b9daf02-e83a-4bd4-af4a-73bd58ad5f14	webauthn-register	Webauthn Register	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	t	f	webauthn-register	80
6289f6b2-7a21-44ad-b3e9-32c8d6a8d5c9	webauthn-register-passwordless	Webauthn Register Passwordless	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	t	f	webauthn-register-passwordless	90
0f4007aa-bc60-4a38-9cec-41671ea15ba9	VERIFY_PROFILE	Verify Profile	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	t	f	VERIFY_PROFILE	100
e080b235-c5e3-429b-a7cb-275d735905bb	idp_link	Linking Identity Provider	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	t	f	idp_link	120
\.


--
-- Data for Name: resource_attribute; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resource_attribute (id, name, value, resource_id) FROM stdin;
\.


--
-- Data for Name: resource_policy; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resource_policy (resource_id, policy_id) FROM stdin;
\.


--
-- Data for Name: resource_scope; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resource_scope (resource_id, scope_id) FROM stdin;
\.


--
-- Data for Name: resource_server; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resource_server (id, allow_rs_remote_mgmt, policy_enforce_mode, decision_strategy) FROM stdin;
\.


--
-- Data for Name: resource_server_perm_ticket; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resource_server_perm_ticket (id, owner, requester, created_timestamp, granted_timestamp, resource_id, scope_id, resource_server_id, policy_id) FROM stdin;
\.


--
-- Data for Name: resource_server_policy; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resource_server_policy (id, name, description, type, decision_strategy, logic, resource_server_id, owner) FROM stdin;
\.


--
-- Data for Name: resource_server_resource; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resource_server_resource (id, name, type, icon_uri, owner, resource_server_id, owner_managed_access, display_name) FROM stdin;
\.


--
-- Data for Name: resource_server_scope; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resource_server_scope (id, name, icon_uri, resource_server_id, display_name) FROM stdin;
\.


--
-- Data for Name: resource_uris; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.resource_uris (resource_id, value) FROM stdin;
\.


--
-- Data for Name: revoked_token; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.revoked_token (id, expire) FROM stdin;
\.


--
-- Data for Name: role_attribute; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role_attribute (id, role_id, name, value) FROM stdin;
\.


--
-- Data for Name: scope_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scope_mapping (client_id, role_id) FROM stdin;
a9243c21-3223-4b2a-92e4-67ebf2d2e151	4f4ffc4b-957c-4cab-8c17-02f58614d750
a9243c21-3223-4b2a-92e4-67ebf2d2e151	c5e9b565-c90e-41e5-8421-61c2b3b46849
60044973-1f42-41b3-a8ed-dcd5ae7d763c	7d846a46-b249-4a44-a876-fe6d75210901
60044973-1f42-41b3-a8ed-dcd5ae7d763c	699d2e77-8b2f-4bd1-bd58-71eb020ce953
\.


--
-- Data for Name: scope_policy; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scope_policy (scope_id, policy_id) FROM stdin;
\.


--
-- Data for Name: server_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.server_config (server_config_key, value, version) FROM stdin;
\.


--
-- Data for Name: user_attribute; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_attribute (name, value, user_id, id, long_value_hash, long_value_hash_lower_case, long_value) FROM stdin;
is_temporary_admin	true	a8d41fc7-b428-451f-aade-6631f5b95e71	df26a18f-b851-45ee-bcdf-9186c886f29a	\N	\N	\N
\.


--
-- Data for Name: user_consent; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_consent (id, client_id, user_id, created_date, last_updated_date, client_storage_provider, external_client_id) FROM stdin;
\.


--
-- Data for Name: user_consent_client_scope; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_consent_client_scope (user_consent_id, scope_id) FROM stdin;
\.


--
-- Data for Name: user_entity; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_entity (id, email, email_constraint, email_verified, enabled, federation_link, first_name, last_name, realm_id, username, created_timestamp, service_account_client_link, not_before) FROM stdin;
a8d41fc7-b428-451f-aade-6631f5b95e71	\N	797b7cc8-6769-47e1-9f0e-292512a09f74	f	t	\N	\N	\N	207d128c-bb74-4e7f-a3e4-f110b22d6159	admin	1776409013432	\N	0
7d453f22-6ff1-41b9-98b7-57ceff01f445	test@example.com	test@example.com	f	t	\N	test	test	c6ab9fba-b91f-4aff-9d2a-37b5eeab6d2a	test	1776412276554	\N	0
\.


--
-- Data for Name: user_federation_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_federation_config (user_federation_provider_id, value, name) FROM stdin;
\.


--
-- Data for Name: user_federation_mapper; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_federation_mapper (id, name, federation_provider_id, federation_mapper_type, realm_id) FROM stdin;
\.


--
-- Data for Name: user_federation_mapper_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_federation_mapper_config (user_federation_mapper_id, value, name) FROM stdin;
\.


--
-- Data for Name: user_federation_provider; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_federation_provider (id, changed_sync_period, display_name, full_sync_period, last_sync, priority, provider_name, realm_id) FROM stdin;
\.


--
-- Data for Name: user_group_membership; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_group_membership (group_id, user_id, membership_type) FROM stdin;
\.


--
-- Data for Name: user_required_action; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_required_action (user_id, required_action) FROM stdin;
\.


--
-- Data for Name: user_role_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_role_mapping (role_id, user_id) FROM stdin;
49673cc1-a91d-4029-bb02-bbf4936dc948	a8d41fc7-b428-451f-aade-6631f5b95e71
a91e1103-1927-4338-a982-fcf10d5aa602	a8d41fc7-b428-451f-aade-6631f5b95e71
03e71ffe-54f7-455a-88b8-f7949197653d	7d453f22-6ff1-41b9-98b7-57ceff01f445
\.


--
-- Data for Name: web_origins; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.web_origins (client_id, value) FROM stdin;
6b842f27-4404-4596-ab7a-26c56ffb44b0	+
b6f89aba-b213-40cd-abbb-9f80c8e88318	+
b1a24523-e2b5-4cc6-af64-8364f8882e32	/*
\.


--
-- Data for Name: workflow_state; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.workflow_state (execution_id, resource_id, workflow_id, resource_type, scheduled_step_id, scheduled_step_timestamp) FROM stdin;
\.


--
-- Name: org_domain ORG_DOMAIN_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_domain
    ADD CONSTRAINT "ORG_DOMAIN_pkey" PRIMARY KEY (id, name);


--
-- Name: org ORG_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org
    ADD CONSTRAINT "ORG_pkey" PRIMARY KEY (id);


--
-- Name: server_config SERVER_CONFIG_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.server_config
    ADD CONSTRAINT "SERVER_CONFIG_pkey" PRIMARY KEY (server_config_key);


--
-- Name: keycloak_role UK_J3RWUVD56ONTGSUHOGM184WW2-2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.keycloak_role
    ADD CONSTRAINT "UK_J3RWUVD56ONTGSUHOGM184WW2-2" UNIQUE (name, client_realm_constraint);


--
-- Name: client_auth_flow_bindings c_cli_flow_bind; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_auth_flow_bindings
    ADD CONSTRAINT c_cli_flow_bind PRIMARY KEY (client_id, binding_name);


--
-- Name: client_scope_client c_cli_scope_bind; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_scope_client
    ADD CONSTRAINT c_cli_scope_bind PRIMARY KEY (client_id, scope_id);


--
-- Name: client_initial_access cnstr_client_init_acc_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_initial_access
    ADD CONSTRAINT cnstr_client_init_acc_pk PRIMARY KEY (id);


--
-- Name: realm_default_groups con_group_id_def_groups; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_default_groups
    ADD CONSTRAINT con_group_id_def_groups UNIQUE (group_id);


--
-- Name: broker_link constr_broker_link_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.broker_link
    ADD CONSTRAINT constr_broker_link_pk PRIMARY KEY (identity_provider, user_id);


--
-- Name: component_config constr_component_config_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_config
    ADD CONSTRAINT constr_component_config_pk PRIMARY KEY (id);


--
-- Name: component constr_component_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component
    ADD CONSTRAINT constr_component_pk PRIMARY KEY (id);


--
-- Name: fed_user_required_action constr_fed_required_action; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fed_user_required_action
    ADD CONSTRAINT constr_fed_required_action PRIMARY KEY (required_action, user_id);


--
-- Name: fed_user_attribute constr_fed_user_attr_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fed_user_attribute
    ADD CONSTRAINT constr_fed_user_attr_pk PRIMARY KEY (id);


--
-- Name: fed_user_consent constr_fed_user_consent_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fed_user_consent
    ADD CONSTRAINT constr_fed_user_consent_pk PRIMARY KEY (id);


--
-- Name: fed_user_credential constr_fed_user_cred_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fed_user_credential
    ADD CONSTRAINT constr_fed_user_cred_pk PRIMARY KEY (id);


--
-- Name: fed_user_group_membership constr_fed_user_group; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fed_user_group_membership
    ADD CONSTRAINT constr_fed_user_group PRIMARY KEY (group_id, user_id);


--
-- Name: fed_user_role_mapping constr_fed_user_role; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fed_user_role_mapping
    ADD CONSTRAINT constr_fed_user_role PRIMARY KEY (role_id, user_id);


--
-- Name: federated_user constr_federated_user; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.federated_user
    ADD CONSTRAINT constr_federated_user PRIMARY KEY (id);


--
-- Name: realm_default_groups constr_realm_default_groups; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_default_groups
    ADD CONSTRAINT constr_realm_default_groups PRIMARY KEY (realm_id, group_id);


--
-- Name: realm_enabled_event_types constr_realm_enabl_event_types; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_enabled_event_types
    ADD CONSTRAINT constr_realm_enabl_event_types PRIMARY KEY (realm_id, value);


--
-- Name: realm_events_listeners constr_realm_events_listeners; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_events_listeners
    ADD CONSTRAINT constr_realm_events_listeners PRIMARY KEY (realm_id, value);


--
-- Name: realm_supported_locales constr_realm_supported_locales; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_supported_locales
    ADD CONSTRAINT constr_realm_supported_locales PRIMARY KEY (realm_id, value);


--
-- Name: identity_provider constraint_2b; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.identity_provider
    ADD CONSTRAINT constraint_2b PRIMARY KEY (internal_id);


--
-- Name: client_attributes constraint_3c; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_attributes
    ADD CONSTRAINT constraint_3c PRIMARY KEY (client_id, name);


--
-- Name: event_entity constraint_4; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_entity
    ADD CONSTRAINT constraint_4 PRIMARY KEY (id);


--
-- Name: federated_identity constraint_40; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.federated_identity
    ADD CONSTRAINT constraint_40 PRIMARY KEY (identity_provider, user_id);


--
-- Name: realm constraint_4a; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm
    ADD CONSTRAINT constraint_4a PRIMARY KEY (id);


--
-- Name: user_federation_provider constraint_5c; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_federation_provider
    ADD CONSTRAINT constraint_5c PRIMARY KEY (id);


--
-- Name: client constraint_7; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT constraint_7 PRIMARY KEY (id);


--
-- Name: scope_mapping constraint_81; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scope_mapping
    ADD CONSTRAINT constraint_81 PRIMARY KEY (client_id, role_id);


--
-- Name: client_node_registrations constraint_84; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_node_registrations
    ADD CONSTRAINT constraint_84 PRIMARY KEY (client_id, name);


--
-- Name: realm_attribute constraint_9; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_attribute
    ADD CONSTRAINT constraint_9 PRIMARY KEY (name, realm_id);


--
-- Name: realm_required_credential constraint_92; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_required_credential
    ADD CONSTRAINT constraint_92 PRIMARY KEY (realm_id, type);


--
-- Name: keycloak_role constraint_a; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.keycloak_role
    ADD CONSTRAINT constraint_a PRIMARY KEY (id);


--
-- Name: admin_event_entity constraint_admin_event_entity; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_event_entity
    ADD CONSTRAINT constraint_admin_event_entity PRIMARY KEY (id);


--
-- Name: authenticator_config_entry constraint_auth_cfg_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authenticator_config_entry
    ADD CONSTRAINT constraint_auth_cfg_pk PRIMARY KEY (authenticator_id, name);


--
-- Name: authentication_execution constraint_auth_exec_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authentication_execution
    ADD CONSTRAINT constraint_auth_exec_pk PRIMARY KEY (id);


--
-- Name: authentication_flow constraint_auth_flow_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authentication_flow
    ADD CONSTRAINT constraint_auth_flow_pk PRIMARY KEY (id);


--
-- Name: authenticator_config constraint_auth_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authenticator_config
    ADD CONSTRAINT constraint_auth_pk PRIMARY KEY (id);


--
-- Name: user_role_mapping constraint_c; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_role_mapping
    ADD CONSTRAINT constraint_c PRIMARY KEY (role_id, user_id);


--
-- Name: composite_role constraint_composite_role; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.composite_role
    ADD CONSTRAINT constraint_composite_role PRIMARY KEY (composite, child_role);


--
-- Name: identity_provider_config constraint_d; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.identity_provider_config
    ADD CONSTRAINT constraint_d PRIMARY KEY (identity_provider_id, name);


--
-- Name: policy_config constraint_dpc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.policy_config
    ADD CONSTRAINT constraint_dpc PRIMARY KEY (policy_id, name);


--
-- Name: realm_smtp_config constraint_e; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_smtp_config
    ADD CONSTRAINT constraint_e PRIMARY KEY (realm_id, name);


--
-- Name: credential constraint_f; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.credential
    ADD CONSTRAINT constraint_f PRIMARY KEY (id);


--
-- Name: user_federation_config constraint_f9; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_federation_config
    ADD CONSTRAINT constraint_f9 PRIMARY KEY (user_federation_provider_id, name);


--
-- Name: resource_server_perm_ticket constraint_fapmt; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server_perm_ticket
    ADD CONSTRAINT constraint_fapmt PRIMARY KEY (id);


--
-- Name: resource_server_resource constraint_farsr; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server_resource
    ADD CONSTRAINT constraint_farsr PRIMARY KEY (id);


--
-- Name: resource_server_policy constraint_farsrp; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server_policy
    ADD CONSTRAINT constraint_farsrp PRIMARY KEY (id);


--
-- Name: associated_policy constraint_farsrpap; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.associated_policy
    ADD CONSTRAINT constraint_farsrpap PRIMARY KEY (policy_id, associated_policy_id);


--
-- Name: resource_policy constraint_farsrpp; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_policy
    ADD CONSTRAINT constraint_farsrpp PRIMARY KEY (resource_id, policy_id);


--
-- Name: resource_server_scope constraint_farsrs; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server_scope
    ADD CONSTRAINT constraint_farsrs PRIMARY KEY (id);


--
-- Name: resource_scope constraint_farsrsp; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_scope
    ADD CONSTRAINT constraint_farsrsp PRIMARY KEY (resource_id, scope_id);


--
-- Name: scope_policy constraint_farsrsps; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scope_policy
    ADD CONSTRAINT constraint_farsrsps PRIMARY KEY (scope_id, policy_id);


--
-- Name: user_entity constraint_fb; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_entity
    ADD CONSTRAINT constraint_fb PRIMARY KEY (id);


--
-- Name: user_federation_mapper_config constraint_fedmapper_cfg_pm; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_federation_mapper_config
    ADD CONSTRAINT constraint_fedmapper_cfg_pm PRIMARY KEY (user_federation_mapper_id, name);


--
-- Name: user_federation_mapper constraint_fedmapperpm; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_federation_mapper
    ADD CONSTRAINT constraint_fedmapperpm PRIMARY KEY (id);


--
-- Name: fed_user_consent_cl_scope constraint_fgrntcsnt_clsc_pm; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fed_user_consent_cl_scope
    ADD CONSTRAINT constraint_fgrntcsnt_clsc_pm PRIMARY KEY (user_consent_id, scope_id);


--
-- Name: user_consent_client_scope constraint_grntcsnt_clsc_pm; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_consent_client_scope
    ADD CONSTRAINT constraint_grntcsnt_clsc_pm PRIMARY KEY (user_consent_id, scope_id);


--
-- Name: user_consent constraint_grntcsnt_pm; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT constraint_grntcsnt_pm PRIMARY KEY (id);


--
-- Name: keycloak_group constraint_group; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.keycloak_group
    ADD CONSTRAINT constraint_group PRIMARY KEY (id);


--
-- Name: group_attribute constraint_group_attribute_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_attribute
    ADD CONSTRAINT constraint_group_attribute_pk PRIMARY KEY (id);


--
-- Name: group_role_mapping constraint_group_role; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_role_mapping
    ADD CONSTRAINT constraint_group_role PRIMARY KEY (role_id, group_id);


--
-- Name: identity_provider_mapper constraint_idpm; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.identity_provider_mapper
    ADD CONSTRAINT constraint_idpm PRIMARY KEY (id);


--
-- Name: idp_mapper_config constraint_idpmconfig; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.idp_mapper_config
    ADD CONSTRAINT constraint_idpmconfig PRIMARY KEY (idp_mapper_id, name);


--
-- Name: jgroups_ping constraint_jgroups_ping; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jgroups_ping
    ADD CONSTRAINT constraint_jgroups_ping PRIMARY KEY (address);


--
-- Name: migration_model constraint_migmod; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migration_model
    ADD CONSTRAINT constraint_migmod PRIMARY KEY (id);


--
-- Name: offline_client_session constraint_offl_cl_ses_pk3; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_client_session
    ADD CONSTRAINT constraint_offl_cl_ses_pk3 PRIMARY KEY (user_session_id, client_id, client_storage_provider, external_client_id, offline_flag);


--
-- Name: offline_user_session constraint_offl_us_ses_pk2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.offline_user_session
    ADD CONSTRAINT constraint_offl_us_ses_pk2 PRIMARY KEY (user_session_id, offline_flag);


--
-- Name: org_invitation constraint_org_invitation; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_invitation
    ADD CONSTRAINT constraint_org_invitation PRIMARY KEY (id);


--
-- Name: protocol_mapper constraint_pcm; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.protocol_mapper
    ADD CONSTRAINT constraint_pcm PRIMARY KEY (id);


--
-- Name: protocol_mapper_config constraint_pmconfig; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.protocol_mapper_config
    ADD CONSTRAINT constraint_pmconfig PRIMARY KEY (protocol_mapper_id, name);


--
-- Name: redirect_uris constraint_redirect_uris; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.redirect_uris
    ADD CONSTRAINT constraint_redirect_uris PRIMARY KEY (client_id, value);


--
-- Name: required_action_config constraint_req_act_cfg_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.required_action_config
    ADD CONSTRAINT constraint_req_act_cfg_pk PRIMARY KEY (required_action_id, name);


--
-- Name: required_action_provider constraint_req_act_prv_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.required_action_provider
    ADD CONSTRAINT constraint_req_act_prv_pk PRIMARY KEY (id);


--
-- Name: user_required_action constraint_required_action; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_required_action
    ADD CONSTRAINT constraint_required_action PRIMARY KEY (required_action, user_id);


--
-- Name: resource_uris constraint_resour_uris_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_uris
    ADD CONSTRAINT constraint_resour_uris_pk PRIMARY KEY (resource_id, value);


--
-- Name: role_attribute constraint_role_attribute_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_attribute
    ADD CONSTRAINT constraint_role_attribute_pk PRIMARY KEY (id);


--
-- Name: revoked_token constraint_rt; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.revoked_token
    ADD CONSTRAINT constraint_rt PRIMARY KEY (id);


--
-- Name: user_attribute constraint_user_attribute_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_attribute
    ADD CONSTRAINT constraint_user_attribute_pk PRIMARY KEY (id);


--
-- Name: user_group_membership constraint_user_group; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_group_membership
    ADD CONSTRAINT constraint_user_group PRIMARY KEY (group_id, user_id);


--
-- Name: web_origins constraint_web_origins; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.web_origins
    ADD CONSTRAINT constraint_web_origins PRIMARY KEY (client_id, value);


--
-- Name: databasechangeloglock databasechangeloglock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.databasechangeloglock
    ADD CONSTRAINT databasechangeloglock_pkey PRIMARY KEY (id);


--
-- Name: client_scope_attributes pk_cl_tmpl_attr; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_scope_attributes
    ADD CONSTRAINT pk_cl_tmpl_attr PRIMARY KEY (scope_id, name);


--
-- Name: client_scope pk_cli_template; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_scope
    ADD CONSTRAINT pk_cli_template PRIMARY KEY (id);


--
-- Name: resource_server pk_resource_server; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server
    ADD CONSTRAINT pk_resource_server PRIMARY KEY (id);


--
-- Name: client_scope_role_mapping pk_template_scope; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_scope_role_mapping
    ADD CONSTRAINT pk_template_scope PRIMARY KEY (scope_id, role_id);


--
-- Name: workflow_state pk_workflow_state; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_state
    ADD CONSTRAINT pk_workflow_state PRIMARY KEY (execution_id);


--
-- Name: default_client_scope r_def_cli_scope_bind; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.default_client_scope
    ADD CONSTRAINT r_def_cli_scope_bind PRIMARY KEY (realm_id, scope_id);


--
-- Name: realm_localizations realm_localizations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_localizations
    ADD CONSTRAINT realm_localizations_pkey PRIMARY KEY (realm_id, locale);


--
-- Name: resource_attribute res_attr_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_attribute
    ADD CONSTRAINT res_attr_pk PRIMARY KEY (id);


--
-- Name: keycloak_group sibling_names; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.keycloak_group
    ADD CONSTRAINT sibling_names UNIQUE (realm_id, parent_group, name);


--
-- Name: identity_provider uk_2daelwnibji49avxsrtuf6xj33; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.identity_provider
    ADD CONSTRAINT uk_2daelwnibji49avxsrtuf6xj33 UNIQUE (provider_alias, realm_id);


--
-- Name: client uk_b71cjlbenv945rb6gcon438at; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT uk_b71cjlbenv945rb6gcon438at UNIQUE (realm_id, client_id);


--
-- Name: client_scope uk_cli_scope; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_scope
    ADD CONSTRAINT uk_cli_scope UNIQUE (realm_id, name);


--
-- Name: user_entity uk_dykn684sl8up1crfei6eckhd7; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_entity
    ADD CONSTRAINT uk_dykn684sl8up1crfei6eckhd7 UNIQUE (realm_id, email_constraint);


--
-- Name: user_consent uk_external_consent; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT uk_external_consent UNIQUE (client_storage_provider, external_client_id, user_id);


--
-- Name: resource_server_resource uk_frsr6t700s9v50bu18ws5ha6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server_resource
    ADD CONSTRAINT uk_frsr6t700s9v50bu18ws5ha6 UNIQUE (name, owner, resource_server_id);


--
-- Name: resource_server_perm_ticket uk_frsr6t700s9v50bu18ws5pmt; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server_perm_ticket
    ADD CONSTRAINT uk_frsr6t700s9v50bu18ws5pmt UNIQUE (owner, requester, resource_server_id, resource_id, scope_id);


--
-- Name: resource_server_policy uk_frsrpt700s9v50bu18ws5ha6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server_policy
    ADD CONSTRAINT uk_frsrpt700s9v50bu18ws5ha6 UNIQUE (name, resource_server_id);


--
-- Name: resource_server_scope uk_frsrst700s9v50bu18ws5ha6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server_scope
    ADD CONSTRAINT uk_frsrst700s9v50bu18ws5ha6 UNIQUE (name, resource_server_id);


--
-- Name: user_consent uk_local_consent; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT uk_local_consent UNIQUE (client_id, user_id);


--
-- Name: migration_model uk_migration_update_time; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migration_model
    ADD CONSTRAINT uk_migration_update_time UNIQUE (update_time);


--
-- Name: migration_model uk_migration_version; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migration_model
    ADD CONSTRAINT uk_migration_version UNIQUE (version);


--
-- Name: org uk_org_alias; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org
    ADD CONSTRAINT uk_org_alias UNIQUE (realm_id, alias);


--
-- Name: org uk_org_group; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org
    ADD CONSTRAINT uk_org_group UNIQUE (group_id);


--
-- Name: org_invitation uk_org_invitation_email; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_invitation
    ADD CONSTRAINT uk_org_invitation_email UNIQUE (organization_id, email);


--
-- Name: org uk_org_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org
    ADD CONSTRAINT uk_org_name UNIQUE (realm_id, name);


--
-- Name: realm uk_orvsdmla56612eaefiq6wl5oi; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm
    ADD CONSTRAINT uk_orvsdmla56612eaefiq6wl5oi UNIQUE (name);


--
-- Name: user_entity uk_ru8tt6t700s9v50bu18ws5ha6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_entity
    ADD CONSTRAINT uk_ru8tt6t700s9v50bu18ws5ha6 UNIQUE (realm_id, username);


--
-- Name: workflow_state uq_workflow_resource; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow_state
    ADD CONSTRAINT uq_workflow_resource UNIQUE (workflow_id, resource_id);


--
-- Name: fed_user_attr_long_values; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fed_user_attr_long_values ON public.fed_user_attribute USING btree (long_value_hash, name);


--
-- Name: fed_user_attr_long_values_lower_case; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fed_user_attr_long_values_lower_case ON public.fed_user_attribute USING btree (long_value_hash_lower_case, name);


--
-- Name: idx_admin_event_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admin_event_time ON public.admin_event_entity USING btree (realm_id, admin_event_time);


--
-- Name: idx_assoc_pol_assoc_pol_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_assoc_pol_assoc_pol_id ON public.associated_policy USING btree (associated_policy_id);


--
-- Name: idx_auth_config_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_auth_config_realm ON public.authenticator_config USING btree (realm_id);


--
-- Name: idx_auth_exec_flow; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_auth_exec_flow ON public.authentication_execution USING btree (flow_id);


--
-- Name: idx_auth_exec_realm_flow; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_auth_exec_realm_flow ON public.authentication_execution USING btree (realm_id, flow_id);


--
-- Name: idx_auth_flow_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_auth_flow_realm ON public.authentication_flow USING btree (realm_id);


--
-- Name: idx_cl_clscope; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cl_clscope ON public.client_scope_client USING btree (scope_id);


--
-- Name: idx_client_att_by_name_value; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_client_att_by_name_value ON public.client_attributes USING btree (name, substr(value, 1, 255));


--
-- Name: idx_client_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_client_id ON public.client USING btree (client_id);


--
-- Name: idx_client_init_acc_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_client_init_acc_realm ON public.client_initial_access USING btree (realm_id);


--
-- Name: idx_clscope_attrs; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clscope_attrs ON public.client_scope_attributes USING btree (scope_id);


--
-- Name: idx_clscope_cl; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clscope_cl ON public.client_scope_client USING btree (client_id);


--
-- Name: idx_clscope_protmap; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clscope_protmap ON public.protocol_mapper USING btree (client_scope_id);


--
-- Name: idx_clscope_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clscope_role ON public.client_scope_role_mapping USING btree (scope_id);


--
-- Name: idx_compo_config_compo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compo_config_compo ON public.component_config USING btree (component_id);


--
-- Name: idx_component_provider_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_component_provider_type ON public.component USING btree (provider_type);


--
-- Name: idx_component_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_component_realm ON public.component USING btree (realm_id);


--
-- Name: idx_composite; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_composite ON public.composite_role USING btree (composite);


--
-- Name: idx_composite_child; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_composite_child ON public.composite_role USING btree (child_role);


--
-- Name: idx_defcls_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_defcls_realm ON public.default_client_scope USING btree (realm_id);


--
-- Name: idx_defcls_scope; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_defcls_scope ON public.default_client_scope USING btree (scope_id);


--
-- Name: idx_event_entity_user_id_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_event_entity_user_id_type ON public.event_entity USING btree (user_id, type, event_time);


--
-- Name: idx_event_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_event_time ON public.event_entity USING btree (realm_id, event_time);


--
-- Name: idx_fedidentity_feduser; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fedidentity_feduser ON public.federated_identity USING btree (federated_user_id);


--
-- Name: idx_fedidentity_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fedidentity_user ON public.federated_identity USING btree (user_id);


--
-- Name: idx_fu_attribute; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fu_attribute ON public.fed_user_attribute USING btree (user_id, realm_id, name);


--
-- Name: idx_fu_cnsnt_ext; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fu_cnsnt_ext ON public.fed_user_consent USING btree (user_id, client_storage_provider, external_client_id);


--
-- Name: idx_fu_consent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fu_consent ON public.fed_user_consent USING btree (user_id, client_id);


--
-- Name: idx_fu_consent_ru; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fu_consent_ru ON public.fed_user_consent USING btree (realm_id, user_id);


--
-- Name: idx_fu_credential; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fu_credential ON public.fed_user_credential USING btree (user_id, type);


--
-- Name: idx_fu_credential_ru; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fu_credential_ru ON public.fed_user_credential USING btree (realm_id, user_id);


--
-- Name: idx_fu_group_membership; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fu_group_membership ON public.fed_user_group_membership USING btree (user_id, group_id);


--
-- Name: idx_fu_group_membership_ru; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fu_group_membership_ru ON public.fed_user_group_membership USING btree (realm_id, user_id);


--
-- Name: idx_fu_required_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fu_required_action ON public.fed_user_required_action USING btree (user_id, required_action);


--
-- Name: idx_fu_required_action_ru; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fu_required_action_ru ON public.fed_user_required_action USING btree (realm_id, user_id);


--
-- Name: idx_fu_role_mapping; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fu_role_mapping ON public.fed_user_role_mapping USING btree (user_id, role_id);


--
-- Name: idx_fu_role_mapping_ru; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fu_role_mapping_ru ON public.fed_user_role_mapping USING btree (realm_id, user_id);


--
-- Name: idx_group_att_by_name_value; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_group_att_by_name_value ON public.group_attribute USING btree (name, ((value)::character varying(250)));


--
-- Name: idx_group_attr_group; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_group_attr_group ON public.group_attribute USING btree (group_id);


--
-- Name: idx_group_role_mapp_group; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_group_role_mapp_group ON public.group_role_mapping USING btree (group_id);


--
-- Name: idx_id_prov_mapp_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_id_prov_mapp_realm ON public.identity_provider_mapper USING btree (realm_id);


--
-- Name: idx_ident_prov_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ident_prov_realm ON public.identity_provider USING btree (realm_id);


--
-- Name: idx_idp_for_login; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_idp_for_login ON public.identity_provider USING btree (realm_id, enabled, link_only, hide_on_login, organization_id);


--
-- Name: idx_idp_realm_org; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_idp_realm_org ON public.identity_provider USING btree (realm_id, organization_id);


--
-- Name: idx_keycloak_role_client; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_keycloak_role_client ON public.keycloak_role USING btree (client);


--
-- Name: idx_keycloak_role_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_keycloak_role_realm ON public.keycloak_role USING btree (realm);


--
-- Name: idx_offline_css_by_client; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_offline_css_by_client ON public.offline_client_session USING btree (client_id, offline_flag) WHERE ((client_id)::text <> 'external'::text);


--
-- Name: idx_offline_css_by_client_storage_provider; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_offline_css_by_client_storage_provider ON public.offline_client_session USING btree (client_storage_provider, external_client_id, offline_flag) WHERE ((client_storage_provider)::text <> 'internal'::text);


--
-- Name: idx_offline_uss_by_broker_session_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_offline_uss_by_broker_session_id ON public.offline_user_session USING btree (broker_session_id, realm_id);


--
-- Name: idx_offline_uss_by_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_offline_uss_by_user ON public.offline_user_session USING btree (user_id, realm_id, offline_flag);


--
-- Name: idx_org_domain_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_org_domain_org_id ON public.org_domain USING btree (org_id);


--
-- Name: idx_org_invitation_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_org_invitation_email ON public.org_invitation USING btree (email);


--
-- Name: idx_org_invitation_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_org_invitation_expires ON public.org_invitation USING btree (expires_at);


--
-- Name: idx_org_invitation_org_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_org_invitation_org_id ON public.org_invitation USING btree (organization_id);


--
-- Name: idx_perm_ticket_owner; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_perm_ticket_owner ON public.resource_server_perm_ticket USING btree (owner);


--
-- Name: idx_perm_ticket_requester; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_perm_ticket_requester ON public.resource_server_perm_ticket USING btree (requester);


--
-- Name: idx_protocol_mapper_client; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_protocol_mapper_client ON public.protocol_mapper USING btree (client_id);


--
-- Name: idx_realm_attr_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_realm_attr_realm ON public.realm_attribute USING btree (realm_id);


--
-- Name: idx_realm_clscope; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_realm_clscope ON public.client_scope USING btree (realm_id);


--
-- Name: idx_realm_def_grp_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_realm_def_grp_realm ON public.realm_default_groups USING btree (realm_id);


--
-- Name: idx_realm_evt_list_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_realm_evt_list_realm ON public.realm_events_listeners USING btree (realm_id);


--
-- Name: idx_realm_evt_types_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_realm_evt_types_realm ON public.realm_enabled_event_types USING btree (realm_id);


--
-- Name: idx_realm_master_adm_cli; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_realm_master_adm_cli ON public.realm USING btree (master_admin_client);


--
-- Name: idx_realm_supp_local_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_realm_supp_local_realm ON public.realm_supported_locales USING btree (realm_id);


--
-- Name: idx_redir_uri_client; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_redir_uri_client ON public.redirect_uris USING btree (client_id);


--
-- Name: idx_req_act_prov_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_req_act_prov_realm ON public.required_action_provider USING btree (realm_id);


--
-- Name: idx_res_policy_policy; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_res_policy_policy ON public.resource_policy USING btree (policy_id);


--
-- Name: idx_res_scope_scope; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_res_scope_scope ON public.resource_scope USING btree (scope_id);


--
-- Name: idx_res_serv_pol_res_serv; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_res_serv_pol_res_serv ON public.resource_server_policy USING btree (resource_server_id);


--
-- Name: idx_res_srv_res_res_srv; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_res_srv_res_res_srv ON public.resource_server_resource USING btree (resource_server_id);


--
-- Name: idx_res_srv_scope_res_srv; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_res_srv_scope_res_srv ON public.resource_server_scope USING btree (resource_server_id);


--
-- Name: idx_rev_token_on_expire; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_rev_token_on_expire ON public.revoked_token USING btree (expire);


--
-- Name: idx_role_attribute; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_role_attribute ON public.role_attribute USING btree (role_id);


--
-- Name: idx_role_clscope; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_role_clscope ON public.client_scope_role_mapping USING btree (role_id);


--
-- Name: idx_scope_mapping_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scope_mapping_role ON public.scope_mapping USING btree (role_id);


--
-- Name: idx_scope_policy_policy; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scope_policy_policy ON public.scope_policy USING btree (policy_id);


--
-- Name: idx_update_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_update_time ON public.migration_model USING btree (update_time);


--
-- Name: idx_usconsent_clscope; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_usconsent_clscope ON public.user_consent_client_scope USING btree (user_consent_id);


--
-- Name: idx_usconsent_scope_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_usconsent_scope_id ON public.user_consent_client_scope USING btree (scope_id);


--
-- Name: idx_user_attribute; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_attribute ON public.user_attribute USING btree (user_id);


--
-- Name: idx_user_attribute_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_attribute_name ON public.user_attribute USING btree (name, value);


--
-- Name: idx_user_consent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_consent ON public.user_consent USING btree (user_id);


--
-- Name: idx_user_credential; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_credential ON public.credential USING btree (user_id);


--
-- Name: idx_user_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_email ON public.user_entity USING btree (email);


--
-- Name: idx_user_group_mapping; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_group_mapping ON public.user_group_membership USING btree (user_id);


--
-- Name: idx_user_reqactions; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_reqactions ON public.user_required_action USING btree (user_id);


--
-- Name: idx_user_role_mapping; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_role_mapping ON public.user_role_mapping USING btree (user_id);


--
-- Name: idx_user_service_account; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_service_account ON public.user_entity USING btree (realm_id, service_account_client_link);


--
-- Name: idx_user_session_expiration_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_session_expiration_created ON public.offline_user_session USING btree (realm_id, offline_flag, remember_me, created_on, user_session_id, user_id);


--
-- Name: idx_user_session_expiration_last_refresh; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_session_expiration_last_refresh ON public.offline_user_session USING btree (realm_id, offline_flag, remember_me, last_session_refresh, user_session_id, user_id);


--
-- Name: idx_usr_fed_map_fed_prv; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_usr_fed_map_fed_prv ON public.user_federation_mapper USING btree (federation_provider_id);


--
-- Name: idx_usr_fed_map_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_usr_fed_map_realm ON public.user_federation_mapper USING btree (realm_id);


--
-- Name: idx_usr_fed_prv_realm; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_usr_fed_prv_realm ON public.user_federation_provider USING btree (realm_id);


--
-- Name: idx_web_orig_client; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_web_orig_client ON public.web_origins USING btree (client_id);


--
-- Name: idx_workflow_state_provider; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_workflow_state_provider ON public.workflow_state USING btree (resource_id);


--
-- Name: idx_workflow_state_step; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_workflow_state_step ON public.workflow_state USING btree (workflow_id, scheduled_step_id);


--
-- Name: user_attr_long_values; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_attr_long_values ON public.user_attribute USING btree (long_value_hash, name);


--
-- Name: user_attr_long_values_lower_case; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_attr_long_values_lower_case ON public.user_attribute USING btree (long_value_hash_lower_case, name);


--
-- Name: identity_provider fk2b4ebc52ae5c3b34; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.identity_provider
    ADD CONSTRAINT fk2b4ebc52ae5c3b34 FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: client_attributes fk3c47c64beacca966; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_attributes
    ADD CONSTRAINT fk3c47c64beacca966 FOREIGN KEY (client_id) REFERENCES public.client(id);


--
-- Name: federated_identity fk404288b92ef007a6; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.federated_identity
    ADD CONSTRAINT fk404288b92ef007a6 FOREIGN KEY (user_id) REFERENCES public.user_entity(id);


--
-- Name: client_node_registrations fk4129723ba992f594; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_node_registrations
    ADD CONSTRAINT fk4129723ba992f594 FOREIGN KEY (client_id) REFERENCES public.client(id);


--
-- Name: redirect_uris fk_1burs8pb4ouj97h5wuppahv9f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.redirect_uris
    ADD CONSTRAINT fk_1burs8pb4ouj97h5wuppahv9f FOREIGN KEY (client_id) REFERENCES public.client(id);


--
-- Name: user_federation_provider fk_1fj32f6ptolw2qy60cd8n01e8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_federation_provider
    ADD CONSTRAINT fk_1fj32f6ptolw2qy60cd8n01e8 FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: realm_required_credential fk_5hg65lybevavkqfki3kponh9v; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_required_credential
    ADD CONSTRAINT fk_5hg65lybevavkqfki3kponh9v FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: resource_attribute fk_5hrm2vlf9ql5fu022kqepovbr; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_attribute
    ADD CONSTRAINT fk_5hrm2vlf9ql5fu022kqepovbr FOREIGN KEY (resource_id) REFERENCES public.resource_server_resource(id);


--
-- Name: user_attribute fk_5hrm2vlf9ql5fu043kqepovbr; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_attribute
    ADD CONSTRAINT fk_5hrm2vlf9ql5fu043kqepovbr FOREIGN KEY (user_id) REFERENCES public.user_entity(id);


--
-- Name: user_required_action fk_6qj3w1jw9cvafhe19bwsiuvmd; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_required_action
    ADD CONSTRAINT fk_6qj3w1jw9cvafhe19bwsiuvmd FOREIGN KEY (user_id) REFERENCES public.user_entity(id);


--
-- Name: keycloak_role fk_6vyqfe4cn4wlq8r6kt5vdsj5c; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.keycloak_role
    ADD CONSTRAINT fk_6vyqfe4cn4wlq8r6kt5vdsj5c FOREIGN KEY (realm) REFERENCES public.realm(id);


--
-- Name: realm_smtp_config fk_70ej8xdxgxd0b9hh6180irr0o; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_smtp_config
    ADD CONSTRAINT fk_70ej8xdxgxd0b9hh6180irr0o FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: realm_attribute fk_8shxd6l3e9atqukacxgpffptw; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_attribute
    ADD CONSTRAINT fk_8shxd6l3e9atqukacxgpffptw FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: composite_role fk_a63wvekftu8jo1pnj81e7mce2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.composite_role
    ADD CONSTRAINT fk_a63wvekftu8jo1pnj81e7mce2 FOREIGN KEY (composite) REFERENCES public.keycloak_role(id);


--
-- Name: authentication_execution fk_auth_exec_flow; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authentication_execution
    ADD CONSTRAINT fk_auth_exec_flow FOREIGN KEY (flow_id) REFERENCES public.authentication_flow(id);


--
-- Name: authentication_execution fk_auth_exec_realm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authentication_execution
    ADD CONSTRAINT fk_auth_exec_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: authentication_flow fk_auth_flow_realm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authentication_flow
    ADD CONSTRAINT fk_auth_flow_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: authenticator_config fk_auth_realm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authenticator_config
    ADD CONSTRAINT fk_auth_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: user_role_mapping fk_c4fqv34p1mbylloxang7b1q3l; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_role_mapping
    ADD CONSTRAINT fk_c4fqv34p1mbylloxang7b1q3l FOREIGN KEY (user_id) REFERENCES public.user_entity(id);


--
-- Name: client_scope_attributes fk_cl_scope_attr_scope; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_scope_attributes
    ADD CONSTRAINT fk_cl_scope_attr_scope FOREIGN KEY (scope_id) REFERENCES public.client_scope(id);


--
-- Name: client_scope_role_mapping fk_cl_scope_rm_scope; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_scope_role_mapping
    ADD CONSTRAINT fk_cl_scope_rm_scope FOREIGN KEY (scope_id) REFERENCES public.client_scope(id);


--
-- Name: protocol_mapper fk_cli_scope_mapper; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.protocol_mapper
    ADD CONSTRAINT fk_cli_scope_mapper FOREIGN KEY (client_scope_id) REFERENCES public.client_scope(id);


--
-- Name: client_initial_access fk_client_init_acc_realm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_initial_access
    ADD CONSTRAINT fk_client_init_acc_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: component_config fk_component_config; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component_config
    ADD CONSTRAINT fk_component_config FOREIGN KEY (component_id) REFERENCES public.component(id);


--
-- Name: component fk_component_realm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.component
    ADD CONSTRAINT fk_component_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: realm_default_groups fk_def_groups_realm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_default_groups
    ADD CONSTRAINT fk_def_groups_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: user_federation_mapper_config fk_fedmapper_cfg; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_federation_mapper_config
    ADD CONSTRAINT fk_fedmapper_cfg FOREIGN KEY (user_federation_mapper_id) REFERENCES public.user_federation_mapper(id);


--
-- Name: user_federation_mapper fk_fedmapperpm_fedprv; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_federation_mapper
    ADD CONSTRAINT fk_fedmapperpm_fedprv FOREIGN KEY (federation_provider_id) REFERENCES public.user_federation_provider(id);


--
-- Name: user_federation_mapper fk_fedmapperpm_realm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_federation_mapper
    ADD CONSTRAINT fk_fedmapperpm_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: associated_policy fk_frsr5s213xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.associated_policy
    ADD CONSTRAINT fk_frsr5s213xcx4wnkog82ssrfy FOREIGN KEY (associated_policy_id) REFERENCES public.resource_server_policy(id);


--
-- Name: scope_policy fk_frsrasp13xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scope_policy
    ADD CONSTRAINT fk_frsrasp13xcx4wnkog82ssrfy FOREIGN KEY (policy_id) REFERENCES public.resource_server_policy(id);


--
-- Name: resource_server_perm_ticket fk_frsrho213xcx4wnkog82sspmt; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server_perm_ticket
    ADD CONSTRAINT fk_frsrho213xcx4wnkog82sspmt FOREIGN KEY (resource_server_id) REFERENCES public.resource_server(id);


--
-- Name: resource_server_resource fk_frsrho213xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server_resource
    ADD CONSTRAINT fk_frsrho213xcx4wnkog82ssrfy FOREIGN KEY (resource_server_id) REFERENCES public.resource_server(id);


--
-- Name: resource_server_perm_ticket fk_frsrho213xcx4wnkog83sspmt; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server_perm_ticket
    ADD CONSTRAINT fk_frsrho213xcx4wnkog83sspmt FOREIGN KEY (resource_id) REFERENCES public.resource_server_resource(id);


--
-- Name: resource_server_perm_ticket fk_frsrho213xcx4wnkog84sspmt; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server_perm_ticket
    ADD CONSTRAINT fk_frsrho213xcx4wnkog84sspmt FOREIGN KEY (scope_id) REFERENCES public.resource_server_scope(id);


--
-- Name: associated_policy fk_frsrpas14xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.associated_policy
    ADD CONSTRAINT fk_frsrpas14xcx4wnkog82ssrfy FOREIGN KEY (policy_id) REFERENCES public.resource_server_policy(id);


--
-- Name: scope_policy fk_frsrpass3xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scope_policy
    ADD CONSTRAINT fk_frsrpass3xcx4wnkog82ssrfy FOREIGN KEY (scope_id) REFERENCES public.resource_server_scope(id);


--
-- Name: resource_server_perm_ticket fk_frsrpo2128cx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server_perm_ticket
    ADD CONSTRAINT fk_frsrpo2128cx4wnkog82ssrfy FOREIGN KEY (policy_id) REFERENCES public.resource_server_policy(id);


--
-- Name: resource_server_policy fk_frsrpo213xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server_policy
    ADD CONSTRAINT fk_frsrpo213xcx4wnkog82ssrfy FOREIGN KEY (resource_server_id) REFERENCES public.resource_server(id);


--
-- Name: resource_scope fk_frsrpos13xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_scope
    ADD CONSTRAINT fk_frsrpos13xcx4wnkog82ssrfy FOREIGN KEY (resource_id) REFERENCES public.resource_server_resource(id);


--
-- Name: resource_policy fk_frsrpos53xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_policy
    ADD CONSTRAINT fk_frsrpos53xcx4wnkog82ssrfy FOREIGN KEY (resource_id) REFERENCES public.resource_server_resource(id);


--
-- Name: resource_policy fk_frsrpp213xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_policy
    ADD CONSTRAINT fk_frsrpp213xcx4wnkog82ssrfy FOREIGN KEY (policy_id) REFERENCES public.resource_server_policy(id);


--
-- Name: resource_scope fk_frsrps213xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_scope
    ADD CONSTRAINT fk_frsrps213xcx4wnkog82ssrfy FOREIGN KEY (scope_id) REFERENCES public.resource_server_scope(id);


--
-- Name: resource_server_scope fk_frsrso213xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_server_scope
    ADD CONSTRAINT fk_frsrso213xcx4wnkog82ssrfy FOREIGN KEY (resource_server_id) REFERENCES public.resource_server(id);


--
-- Name: composite_role fk_gr7thllb9lu8q4vqa4524jjy8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.composite_role
    ADD CONSTRAINT fk_gr7thllb9lu8q4vqa4524jjy8 FOREIGN KEY (child_role) REFERENCES public.keycloak_role(id);


--
-- Name: user_consent_client_scope fk_grntcsnt_clsc_usc; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_consent_client_scope
    ADD CONSTRAINT fk_grntcsnt_clsc_usc FOREIGN KEY (user_consent_id) REFERENCES public.user_consent(id);


--
-- Name: user_consent fk_grntcsnt_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_consent
    ADD CONSTRAINT fk_grntcsnt_user FOREIGN KEY (user_id) REFERENCES public.user_entity(id);


--
-- Name: group_attribute fk_group_attribute_group; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_attribute
    ADD CONSTRAINT fk_group_attribute_group FOREIGN KEY (group_id) REFERENCES public.keycloak_group(id);


--
-- Name: group_role_mapping fk_group_role_group; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_role_mapping
    ADD CONSTRAINT fk_group_role_group FOREIGN KEY (group_id) REFERENCES public.keycloak_group(id);


--
-- Name: realm_enabled_event_types fk_h846o4h0w8epx5nwedrf5y69j; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_enabled_event_types
    ADD CONSTRAINT fk_h846o4h0w8epx5nwedrf5y69j FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: realm_events_listeners fk_h846o4h0w8epx5nxev9f5y69j; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_events_listeners
    ADD CONSTRAINT fk_h846o4h0w8epx5nxev9f5y69j FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: identity_provider_mapper fk_idpm_realm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.identity_provider_mapper
    ADD CONSTRAINT fk_idpm_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: idp_mapper_config fk_idpmconfig; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.idp_mapper_config
    ADD CONSTRAINT fk_idpmconfig FOREIGN KEY (idp_mapper_id) REFERENCES public.identity_provider_mapper(id);


--
-- Name: web_origins fk_lojpho213xcx4wnkog82ssrfy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.web_origins
    ADD CONSTRAINT fk_lojpho213xcx4wnkog82ssrfy FOREIGN KEY (client_id) REFERENCES public.client(id);


--
-- Name: org_invitation fk_org_invitation_org; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.org_invitation
    ADD CONSTRAINT fk_org_invitation_org FOREIGN KEY (organization_id) REFERENCES public.org(id) ON DELETE CASCADE;


--
-- Name: scope_mapping fk_ouse064plmlr732lxjcn1q5f1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scope_mapping
    ADD CONSTRAINT fk_ouse064plmlr732lxjcn1q5f1 FOREIGN KEY (client_id) REFERENCES public.client(id);


--
-- Name: protocol_mapper fk_pcm_realm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.protocol_mapper
    ADD CONSTRAINT fk_pcm_realm FOREIGN KEY (client_id) REFERENCES public.client(id);


--
-- Name: credential fk_pfyr0glasqyl0dei3kl69r6v0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.credential
    ADD CONSTRAINT fk_pfyr0glasqyl0dei3kl69r6v0 FOREIGN KEY (user_id) REFERENCES public.user_entity(id);


--
-- Name: protocol_mapper_config fk_pmconfig; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.protocol_mapper_config
    ADD CONSTRAINT fk_pmconfig FOREIGN KEY (protocol_mapper_id) REFERENCES public.protocol_mapper(id);


--
-- Name: default_client_scope fk_r_def_cli_scope_realm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.default_client_scope
    ADD CONSTRAINT fk_r_def_cli_scope_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: required_action_provider fk_req_act_realm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.required_action_provider
    ADD CONSTRAINT fk_req_act_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: resource_uris fk_resource_server_uris; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.resource_uris
    ADD CONSTRAINT fk_resource_server_uris FOREIGN KEY (resource_id) REFERENCES public.resource_server_resource(id);


--
-- Name: role_attribute fk_role_attribute_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_attribute
    ADD CONSTRAINT fk_role_attribute_id FOREIGN KEY (role_id) REFERENCES public.keycloak_role(id);


--
-- Name: realm_supported_locales fk_supported_locales_realm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.realm_supported_locales
    ADD CONSTRAINT fk_supported_locales_realm FOREIGN KEY (realm_id) REFERENCES public.realm(id);


--
-- Name: user_federation_config fk_t13hpu1j94r2ebpekr39x5eu5; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_federation_config
    ADD CONSTRAINT fk_t13hpu1j94r2ebpekr39x5eu5 FOREIGN KEY (user_federation_provider_id) REFERENCES public.user_federation_provider(id);


--
-- Name: user_group_membership fk_user_group_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_group_membership
    ADD CONSTRAINT fk_user_group_user FOREIGN KEY (user_id) REFERENCES public.user_entity(id);


--
-- Name: policy_config fkdc34197cf864c4e43; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.policy_config
    ADD CONSTRAINT fkdc34197cf864c4e43 FOREIGN KEY (policy_id) REFERENCES public.resource_server_policy(id);


--
-- Name: identity_provider_config fkdc4897cf864c4e43; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.identity_provider_config
    ADD CONSTRAINT fkdc4897cf864c4e43 FOREIGN KEY (identity_provider_id) REFERENCES public.identity_provider(internal_id);


--
-- PostgreSQL database dump complete
--

