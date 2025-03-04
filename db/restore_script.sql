PGDMP                         {            test_db    15.2    15.2 9    \           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            ]           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            ^           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            _           1262    16839    test_db    DATABASE     �   CREATE DATABASE test_db WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
    DROP DATABASE test_db;
                postgres    false                        2615    16840    transactions    SCHEMA        CREATE SCHEMA transactions;
    DROP SCHEMA transactions;
             	   test_user    false            `           0    0    SCHEMA transactions    ACL     �   REVOKE ALL ON SCHEMA transactions FROM test_user;
GRANT CREATE ON SCHEMA transactions TO test_user;
GRANT USAGE ON SCHEMA transactions TO test_user WITH GRANT OPTION;
                	   test_user    false    7                        3079    16841    pldbgapi 	   EXTENSION     <   CREATE EXTENSION IF NOT EXISTS pldbgapi WITH SCHEMA public;
    DROP EXTENSION pldbgapi;
                   false            a           0    0    EXTENSION pldbgapi    COMMENT     Y   COMMENT ON EXTENSION pldbgapi IS 'server-side support for debugging PL/pgSQL functions';
                        false    2                       1255    16878    func_get_account_by_id(integer)    FUNCTION     r  CREATE FUNCTION transactions.func_get_account_by_id(p_acc_id integer) RETURNS TABLE(accountid integer, currencyid integer, currencycode character varying, currency character varying, balance real, userid integer, userfullname character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN query
		SELECT 
			a.id as AccountId,
			c.id as CurrencyId,
			a.currency_code as CurrencyCode,
			c.description as Currency,
			a.balance,
			a.user_id as UserId,
			a.user_full_name as UserFullName	
		FROM
			transactions.accounts a
		INNER JOIN transactions.currencies c
			ON c.id = a.currency_id
		WHERE a.id = p_acc_id;
END;
$$;
 E   DROP FUNCTION transactions.func_get_account_by_id(p_acc_id integer);
       transactions          postgres    false    7                       1255    16879    func_get_commission_rate()    FUNCTION     �   CREATE FUNCTION transactions.func_get_commission_rate() RETURNS real
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN 0.01;
END;
$$;
 7   DROP FUNCTION transactions.func_get_commission_rate();
       transactions          postgres    false    7                       1255    16880    func_get_user_by_email(text)    FUNCTION     T  CREATE FUNCTION transactions.func_get_user_by_email(p_email text) RETURNS TABLE(userid integer, username character varying, usersurname character varying, useremail text, creationdate timestamp without time zone, lastlogindate timestamp without time zone, pwdhash text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN query
		SELECT
			u.id AS UserId,
			u.name AS UserName,
			u.surname as UserSurname,
			u.email as UserEmail,
			u.creation_date as CreationDate,
			u.last_login_date as LastLoginDate,
			u.pwd_hash as PwdHash
		FROM
			transactions.users u
		WHERE
			u.email = p_email;
END;
$$;
 A   DROP FUNCTION transactions.func_get_user_by_email(p_email text);
       transactions          postgres    false    7                       1255    16955 d   func_search_transactions(integer, timestamp without time zone, timestamp without time zone, integer)    FUNCTION     G  CREATE FUNCTION transactions.func_search_transactions(p_user_id integer, p_from timestamp without time zone, p_to timestamp without time zone, p_srcaccid integer) RETURNS TABLE(transactionid integer, originaccid integer, origincurrcode character varying, destaccid integer, destcurrcode character varying, transactionamount real, transactiondate timestamp without time zone, transactiondescrip character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE

BEGIN
	RETURN query
		SELECT 
			t.id as TransactionId,
			t.origin_acc_id as OriginAccId,
			t.origin_currency_code as OriginCurrCode,
			t.dest_acc_id as DestAccId,
			t.dest_currency_code as DestCurrCode,
			t.amount as TransactionAmount,
			t.date as TransactionDate,
			t.description as TransactionDescrip			
		FROM
			transactions.transfers t
		INNER JOIN transactions.accounts accFrom
			ON accFrom.id = t.origin_acc_id
		WHERE
			accFrom.user_id = p_user_id AND
			(p_from is null or t.date >= p_from) AND
			(p_to is null or t.date < p_to) AND
			(p_srcAccId is null or t.origin_acc_id = p_srcAccId)
		ORDER BY date ASC;			
END;
$$;
 �   DROP FUNCTION transactions.func_search_transactions(p_user_id integer, p_from timestamp without time zone, p_to timestamp without time zone, p_srcaccid integer);
       transactions          postgres    false    7            	           1255    16882 �   func_transfer_amount(integer, character varying, integer, character varying, real, real, timestamp without time zone, character varying, real)    FUNCTION     �  CREATE FUNCTION transactions.func_transfer_amount(p_acc_from integer, p_origin_curr_code character varying, p_acc_to integer, p_dest_curr_code character varying, p_amount_to_debit_on_origin real, p_amount_to_add_on_dest real, p_date timestamp without time zone, p_descrip character varying, p_commission_amount real) RETURNS TABLE(transactionid integer, amountdebited real, commissiondebited real, amounttransferred real)
    LANGUAGE plpgsql
    AS $$
DECLARE	
    v_transaction_id integer;
BEGIN	
	UPDATE transactions.accounts
	SET balance = balance + p_amount_to_add_on_dest
	WHERE id = p_acc_to;
	
	UPDATE transactions.accounts
	SET balance = balance - p_amount_to_debit_on_origin - (p_commission_amount)
	WHERE id = p_acc_from;
	
	INSERT INTO transactions.transfers
	(origin_acc_id, origin_currency_code, dest_acc_id, dest_currency_code, amount, date, description)
	VALUES
	(
		p_acc_from,
		p_origin_curr_code,
		p_acc_to,
		p_dest_curr_code,
		p_amount_to_debit_on_origin,
		p_date,
		p_descrip
	)
	RETURNING id INTO v_transaction_id;
	
	RETURN query
		SELECT 
			v_transaction_id AS TransactionId,
			p_amount_to_debit_on_origin AS AmountDebited,
			p_commission_amount AS CommissionDebited,
			p_amount_to_add_on_dest AS AmountTransferred;	
END;
$$;
 <  DROP FUNCTION transactions.func_transfer_amount(p_acc_from integer, p_origin_curr_code character varying, p_acc_to integer, p_dest_curr_code character varying, p_amount_to_debit_on_origin real, p_amount_to_add_on_dest real, p_date timestamp without time zone, p_descrip character varying, p_commission_amount real);
       transactions          postgres    false    7            
           1255    16883 -   proc_login(text, timestamp without time zone) 	   PROCEDURE     �   CREATE PROCEDURE transactions.proc_login(IN p_email text, IN p_login_date timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE transactions.users
	SET last_login_date = p_login_date
	WHERE email = p_email;
END;
$$;
 f   DROP PROCEDURE transactions.proc_login(IN p_email text, IN p_login_date timestamp without time zone);
       transactions          postgres    false    7            �            1255    16884 ?   proc_register(character varying, character varying, text, text) 	   PROCEDURE     _  CREATE PROCEDURE transactions.proc_register(IN p_name character varying, IN p_surname character varying, IN p_email text, IN p_pwd_hash text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO transactions.users
	(name, surname, email, pwd_hash, creation_date)
	VALUES
	(
		p_name,
		p_surname,
		p_email,
		p_pwd_hash,
		NOW()::timestamp
	);
END;
$$;
 �   DROP PROCEDURE transactions.proc_register(IN p_name character varying, IN p_surname character varying, IN p_email text, IN p_pwd_hash text);
       transactions          postgres    false    7            �            1259    16885    accounts    TABLE       CREATE TABLE transactions.accounts (
    id integer NOT NULL,
    currency_id integer NOT NULL,
    balance real DEFAULT 0,
    user_id integer,
    currency_code character varying,
    user_full_name character varying,
    last_updt_date timestamp without time zone
);
 "   DROP TABLE transactions.accounts;
       transactions         heap    postgres    false    7            b           0    0    TABLE accounts    ACL     Z   GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE transactions.accounts TO test_user;
          transactions          postgres    false    221            �            1259    16891    accounts_id_seq    SEQUENCE     �   ALTER TABLE transactions.accounts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME transactions.accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            transactions          postgres    false    221    7            �            1259    16892 
   currencies    TABLE     �   CREATE TABLE transactions.currencies (
    id integer NOT NULL,
    code character varying NOT NULL,
    description character varying NOT NULL
);
 $   DROP TABLE transactions.currencies;
       transactions         heap    postgres    false    7            c           0    0    TABLE currencies    ACL     \   GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE transactions.currencies TO test_user;
          transactions          postgres    false    223            �            1259    16897    currencies_id_seq    SEQUENCE     �   ALTER TABLE transactions.currencies ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME transactions.currencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            transactions          postgres    false    7    223            �            1259    16898 	   transfers    TABLE     A  CREATE TABLE transactions.transfers (
    id integer NOT NULL,
    origin_acc_id integer NOT NULL,
    dest_acc_id integer NOT NULL,
    amount real DEFAULT 0,
    date timestamp without time zone,
    description character varying,
    origin_currency_code character varying,
    dest_currency_code character varying
);
 #   DROP TABLE transactions.transfers;
       transactions         heap    postgres    false    7            d           0    0    TABLE transfers    ACL     [   GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE transactions.transfers TO test_user;
          transactions          postgres    false    225            �            1259    16904    transactions_id_seq    SEQUENCE     �   ALTER TABLE transactions.transfers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME transactions.transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            transactions          postgres    false    225    7            �            1259    16905    users    TABLE       CREATE TABLE transactions.users (
    id integer NOT NULL,
    name character varying,
    surname character varying,
    email text NOT NULL,
    pwd_hash text NOT NULL,
    creation_date timestamp without time zone NOT NULL,
    last_login_date timestamp without time zone
);
    DROP TABLE transactions.users;
       transactions         heap    postgres    false    7            e           0    0    TABLE users    ACL     W   GRANT SELECT,INSERT,REFERENCES,DELETE,UPDATE ON TABLE transactions.users TO test_user;
          transactions          postgres    false    227            �            1259    16910    users_id_seq    SEQUENCE     �   ALTER TABLE transactions.users ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME transactions.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            transactions          postgres    false    227    7            R          0    16885    accounts 
   TABLE DATA                 transactions          postgres    false    221   �Q       T          0    16892 
   currencies 
   TABLE DATA                 transactions          postgres    false    223   S       V          0    16898 	   transfers 
   TABLE DATA                 transactions          postgres    false    225   �S       X          0    16905    users 
   TABLE DATA                 transactions          postgres    false    227   �T       f           0    0    accounts_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('transactions.accounts_id_seq', 14, true);
          transactions          postgres    false    222            g           0    0    currencies_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('transactions.currencies_id_seq', 3, true);
          transactions          postgres    false    224            h           0    0    transactions_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('transactions.transactions_id_seq', 1, true);
          transactions          postgres    false    226            i           0    0    users_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('transactions.users_id_seq', 10, true);
          transactions          postgres    false    228            �           2606    16912    accounts accounts_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY transactions.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);
 F   ALTER TABLE ONLY transactions.accounts DROP CONSTRAINT accounts_pkey;
       transactions            postgres    false    221            �           2606    16914    accounts accounts_unique_key 
   CONSTRAINT     q   ALTER TABLE ONLY transactions.accounts
    ADD CONSTRAINT accounts_unique_key UNIQUE (id) INCLUDE (currency_id);
 L   ALTER TABLE ONLY transactions.accounts DROP CONSTRAINT accounts_unique_key;
       transactions            postgres    false    221    221            �           2606    16916    accounts curr_user_unique_key 
   CONSTRAINT     n   ALTER TABLE ONLY transactions.accounts
    ADD CONSTRAINT curr_user_unique_key UNIQUE (user_id, currency_id);
 M   ALTER TABLE ONLY transactions.accounts DROP CONSTRAINT curr_user_unique_key;
       transactions            postgres    false    221    221            �           2606    16918    currencies currencies_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY transactions.currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY transactions.currencies DROP CONSTRAINT currencies_pkey;
       transactions            postgres    false    223            �           2606    16920    users email_unique_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY transactions.users
    ADD CONSTRAINT email_unique_pkey UNIQUE (email);
 G   ALTER TABLE ONLY transactions.users DROP CONSTRAINT email_unique_pkey;
       transactions            postgres    false    227            j           0    0 %   CONSTRAINT email_unique_pkey ON users    COMMENT     i   COMMENT ON CONSTRAINT email_unique_pkey ON transactions.users IS 'An email can be registered only once';
          transactions          postgres    false    3259            �           2606    16922    transfers transactions_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY transactions.transfers
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);
 K   ALTER TABLE ONLY transactions.transfers DROP CONSTRAINT transactions_pkey;
       transactions            postgres    false    225            �           2606    16924    users user_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY transactions.users
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);
 ?   ALTER TABLE ONLY transactions.users DROP CONSTRAINT user_pkey;
       transactions            postgres    false    227            �           1259    16925    accounts_curr_idx    INDEX     S   CREATE INDEX accounts_curr_idx ON transactions.accounts USING btree (currency_id);
 +   DROP INDEX transactions.accounts_curr_idx;
       transactions            postgres    false    221            �           1259    16926    accounts_pkey_idx    INDEX     J   CREATE INDEX accounts_pkey_idx ON transactions.accounts USING btree (id);
 +   DROP INDEX transactions.accounts_pkey_idx;
       transactions            postgres    false    221            �           1259    16927    accounts_user_idx    INDEX     O   CREATE INDEX accounts_user_idx ON transactions.accounts USING btree (user_id);
 +   DROP INDEX transactions.accounts_user_idx;
       transactions            postgres    false    221            �           1259    16928    curr_id_code_idx    INDEX     e   CREATE INDEX curr_id_code_idx ON transactions.currencies USING btree (id, code varchar_pattern_ops);
 *   DROP INDEX transactions.curr_id_code_idx;
       transactions            postgres    false    223    223            �           1259    16929    curr_pkey_idx    INDEX     H   CREATE INDEX curr_pkey_idx ON transactions.currencies USING btree (id);
 '   DROP INDEX transactions.curr_pkey_idx;
       transactions            postgres    false    223            �           1259    16930    transac_date_idx    INDEX     L   CREATE INDEX transac_date_idx ON transactions.transfers USING btree (date);
 *   DROP INDEX transactions.transac_date_idx;
       transactions            postgres    false    225            �           1259    16931    transac_origin_acc_idx    INDEX     [   CREATE INDEX transac_origin_acc_idx ON transactions.transfers USING btree (origin_acc_id);
 0   DROP INDEX transactions.transac_origin_acc_idx;
       transactions            postgres    false    225            �           1259    16932    transac_pkey_idx    INDEX     J   CREATE INDEX transac_pkey_idx ON transactions.transfers USING btree (id);
 *   DROP INDEX transactions.transac_pkey_idx;
       transactions            postgres    false    225            �           1259    16933    users_email_idx    INDEX     Y   CREATE INDEX users_email_idx ON transactions.users USING btree (email text_pattern_ops);
 )   DROP INDEX transactions.users_email_idx;
       transactions            postgres    false    227            �           1259    16934    users_pkey_idx    INDEX     D   CREATE INDEX users_pkey_idx ON transactions.users USING btree (id);
 (   DROP INDEX transactions.users_pkey_idx;
       transactions            postgres    false    227            �           2606    16935    accounts currency_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY transactions.accounts
    ADD CONSTRAINT currency_id_fkey FOREIGN KEY (currency_id) REFERENCES transactions.currencies(id) NOT VALID;
 I   ALTER TABLE ONLY transactions.accounts DROP CONSTRAINT currency_id_fkey;
       transactions          postgres    false    3252    221    223            �           2606    16940    transfers dest_acc_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY transactions.transfers
    ADD CONSTRAINT dest_acc_fkey FOREIGN KEY (dest_acc_id) REFERENCES transactions.accounts(id) NOT VALID;
 G   ALTER TABLE ONLY transactions.transfers DROP CONSTRAINT dest_acc_fkey;
       transactions          postgres    false    3242    221    225            �           2606    16945    transfers origin_acc_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY transactions.transfers
    ADD CONSTRAINT origin_acc_fkey FOREIGN KEY (origin_acc_id) REFERENCES transactions.accounts(id);
 I   ALTER TABLE ONLY transactions.transfers DROP CONSTRAINT origin_acc_fkey;
       transactions          postgres    false    225    3242    221            �           2606    16950    accounts user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY transactions.accounts
    ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id) REFERENCES transactions.users(id) NOT VALID;
 E   ALTER TABLE ONLY transactions.accounts DROP CONSTRAINT user_id_fkey;
       transactions          postgres    false    3261    227    221            R   %  x����j�0�{�bnN@Z��TjSZ�r2��Ҁ+/��}�zH{5Ҍt��'I�8+ I�=��2���3VZw�X�jz�����j�T��nLC�W��uW_�ߧ�����s�����걪��l`��,����c^įpx|)�˙�:@@mBx��X:��u���{F��e��
�)���a�,QE��!�7V���B�ax���8[lva�����e6k�T�ޑ!q�u�]���e�u)�%��7�N����.al�2z^E��\T�]�Ke���9���!�D�      T   �   x���A
�0�}O�wm��ҕ� m%i
]��S��O��\�������<�w��x7����Q��w&�7#T�6`��,FC�'5�#��������n0����SB�o�T�*׺c�(�I�BY�
��{Ȯl��~�M�q�6$�,��[��fJd�%��-�/f�q�      V   �   x�UN=�0��+�V���
�$��-4m���4J������Ə�ý��q��%UyQ��S�q'���7�	ca!���w�:�y�i/��	{�Q�IdN�-n��[���?;�{�M�i�-����'�WZ���sC>��"�!���(�#�JP���f�W;�-7�4�����^2��Y�$��m��?�Ta���sP�      X   �  x���K��@ ໿�&�$������(f x1-�
�<��/��ɮ޽twu�ҕ/]�ai�tÞ�,a���YR!O�$/o���&H��v�"�Mp,��g��nⱪh�YV�C�f�0�n�`:�LS��� X�ek0W�3��Z���Q��ދ�jە!����S�G�]�:B��P�F;zDPvI�,�sx��JF�^������⋋�bB������7H�0�v�@,`�*�Xf��x����?�R��eI���-�<��-s�/U2d}E��lkz���.ו�`�V�W���Qh�>�Wt��rP$�"D�}'K*,�F��$L�mNX�};���2|�$�̍���-�-�_����O=�څʣ=w�R>v�ݼ_�8�igs��+!u�܁� #	�?�a	)Ҧ=��\M;x?��0�󐟧�i*+2���A�2W�ƀ��&y_�̄�0r�����"����,H"��x�	w 0��(UL��_VV     