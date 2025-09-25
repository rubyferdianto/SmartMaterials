CREATE OR REPLACE PACKAGE BODY M_SYS.M_PCK_PO_CUSTOM IS
  /*
  || ****************************************************************************
  ||
  || Author:      Nicole Riedel
  ||
  || Purpose:     Contains all procedures and functions for procurement
  ||              which can be customized
  ||
  || Change history:
  ||
  || When           Who             What
  || -----------    -----------     ---------------------------------------------
  || 17-Feb-1999    NRiedel         Created
  || 24-Sep-1999    NRiedel         Added function assigned_rlis
  || 26-Mar-2002    HB              Add function Check_Create_PO
  || 31-Jul-2003    DST             Add procedure execute_cip
  || 23-Jan-2004    NRiedel         Added function check_rev_app_allowed
  ||                                (5.5.3, build 2)
  || 26-Oct-2004    NRiedel         Added procedure renumber_pos (5.5.3, build 3)
  || 25-Aug-2005    NRiedel         Added procedures exec_general_cip and
  ||                                delete_order (6.1.2, build 1)
  || 13-Jul-2007    NRiedel         Added procedure post_approval (6.2.3, build 1)
  || 18-Mar-2008    NRiedel         Added procedures gen_inq_number,
  ||                                gen_order_number, check_rfa and
  ||                                check_print_order (6.2.5, build 1)
  || 26-Sep-2008    MKordt          V-ID 3453: added CIP 'import_pb_items_cip'
  ||                                (6.3.3, build 1)
  || 02-May-2009    rw              6.3.4 new functions/procedures used in P5007
  || 04-May-2009    NRiedel         6.3.4, build 1:
  ||                                - Added parameter p_inq_id (gen_inq_number)
  ||                                - Added parameter p_poh_id (gen_order_number)
  || 28-Jun-2009    rw              6.3.5, build 1: changed parameter list of
  ||                                update_values
  || 02-Sep-2009    NRiedel         6.3.6, build 1:
  ||                                - Added function check_set_issue_date
  ||                                - Added procedures post_set_issue_date and
  ||                                  post_reverse_approval
  || 25-Nov-2009    MKordt          CR-MA9678: renamed function 'check_create_po'
  ||                                to 'agreement_approval' and added new
  ||                                parameter 'p_check_only_ind'
  ||                                (6.3.7, build 1)
  || 20-Oct-2010    NRiedel         Added procedure post_poh_creation
  ||                                (7.0.2, build 1)
  || 25-Aug-2011    NRiedel         Added procedure before_poh_creation
  ||                                (7.0.5, build 1)
  || 31-Oct-2011    NRiedel         Added function get_po_status (7.0.5, build 2)
  || 11-Mar-2012    TrinaH      7.0.5 Code verification
  || 17-Jul-2012    NRiedel         Added functions get_tree_column_label and
  ||                                get_tree_column_value (7.0.7, build 1)
  || 14-Dec-2012    NRiedel         Added functions get_suppl_status and
  ||                                get_suppl_delv_status (CR-MA18894)
  ||                                (7.0.8, build 1)
  || 08-Jun-2013    TrinaH      7.0.8 Code verification
  || 15-Sep-2013    TrinaH          Support Center_0341
  || 08-Jan-2013    TrinaH          Support Center-0362
  ||                                Allow more than 949 lines if project is not interfacing to JDE
  || 04-Apr-2014    PCEZ            SC_0368 and 0376: Modified agreement_approval
  ||                                                  for multiple changes
  || 30-Sep-2014    TrinaH          Hague-0412: Modified Post_poh_creation
  ||                                            Set poh.budget to 0
  || 14-Apr-2014    CMaassen        CR-MA24583: new CIP post_apply_prices
  ||                                (7.1.1, build 1)  ||
  || 05-Oct-2014    TrinaH      7.1.1 Code verification
  || 17-Dec-2014    PCEZ            PLF0086-Hou0775
  ||                                allow multiple contracts on a PO, not projects
  || 23-Jul-2014    PCEZ/Thua       Hague-0509 Modified agreement_approval
  ||                                allow approving 3W match orders with no
  ||                                Progress Payement Events.
  || 28-Nov-2014    NRiedel         Reduced number of statuses for performance
  ||                                reasons  and getting data just once
  ||                                (get_po_status, get_suppl_status)
  ||                                (TR-MA26531) (7.1.3, build 1)
  || SC-0417   01-Aug-2015  Thua    Code verification for SPM 7.1.3 upgrade
  || PLF-0087  01-Nov-2015  THua    Modified agreement_approval and post_approval
  || SC-0448   15-May-2016  Thua    Code verification for SPM 8.0.3 upgrade
  ||                                Modified agreement_approval
  || HOU_0863   27-Jul-2016 THua    allow unapprove when Order not yet submitted to JDE
  || SC_0491   27-Jul-2016  THua    test PO title on unprintbables
  ||                                Created convert_unit function
  || TYLER-0013 13-Dec-2016 THua    Modified agreement_approval to
  ||                                force filling JDE int flag
  || SC_0537    08-Aug_2017 PCEZ    Test on Field2 in M_JOBS to be Y,, chargeable
  ||                                On @way match test on JDE paid amount > new PO line value
  || CBI137555  26-Feb-2018 PCEZ    Simplify 2Way Match check on JDE Paid AMt > SPM order amount, no longer go out to JDE, use Attribute instead
  || CBI161335  20-Jul-2018 Thua    Modified agreement_approval to validate budget_provided field.
  || CBI204602  11-Dec-2018 Thua    Modified Post_poh_creation
  ||                                to set budget_provided value
  || McDermott    16-Dec-2019 8.2 - 1 Added 7.1 procedures.
  || McDermott    07-Jan-2020 8.2 - 2 Added logic for Purchase Order number.
  || McDermott  07-Sep-2020 Ruby    INC1049320 Modified to Merge with One MDR
  || INC1109215/INC1214827
  ||            16-Mar-2021 THua Modified agreement_approval to check if exped/insp level exists
  || INC1138288/INC1214827
  ||            24-Mar-2021 Thua Modified post_poh_approval to set Budget Provided value based on the default setting of the attribute
  || McDermott  27-Jul-2021 McDermott Added procedure during RFA for validating the negative amounts in case of milestone progress payments.
  || TASK0139926    09-Sep-2021  Thua Modifed Mdr_check_agreement to validate PO cancellation,routing method,block users from modifying PO qty to a lesser value than the invoice qty.
  || INC1204327     15-Sep-2021  Ruby Modified Gen Order Number and Expediting/Inspection Level Retired
  || INC1226800     05-Nov-2021  Thua Modified Mdr_check_agreemennt to allow approve PO on PP approved are less than the rev
  || INC1228546     27-Sep-2021  Ruby Modified to include OLIVES for QMW Project
  || INC1250217     06-Jan-2021  Ruby Modified for Multiple PO Item POS allowed for JDE
  || INC1247526     06-Jan-2021  Ruby Modified for PO Number get replaced from Requisition Workload if PO is not Approved yet
  || ****************************************************************************
  */

  PROCEDURE VERSION(version OUT varchar2,
                    build   OUT varchar2,
                    lmod    OUT date,
                    name    OUT varchar2,
                    text    OUT varchar2) IS
  BEGIN
    version := '8.2.0'; /* version for which the package was changed */
    build   := '2'; /* change within one version */
    lmod    := TO_DATE('07.01.20', 'DD.MM.YY'); /* date of last change */
    name    := 'MDR'; /* person that made last change */
    text    := 'PO Number Logic'; /* comment about change */
  END;


-- 16-Dec-2019 8.2 - 1 Added 7.1 procedures.
FUNCTION get_project_attribute
    (
        p_proj_id                        m_sys.m_projects.proj_id%TYPE,
        p_attr_code                        m_sys.m_attrs.attr_code%TYPE
    )
    RETURN m_sys.m_projects.attr_char1%TYPE
IS
    v_attr_id                            m_sys.m_attrs.attr_id%TYPE;
    v_tab_id                            m_sys.m_dict_tabs.tab_id%TYPE;
    v_physical_attribute                m_sys.m_dict_tab_attrs.physical_attribute%TYPE;
    v_attr_value                        m_sys.m_projects.attr_char1%TYPE;
BEGIN
    BEGIN
        SELECT tab_id
          INTO v_tab_id
          FROM m_sys.m_dict_tabs
         WHERE table_name = 'M_PROJECTS'
           AND proj_id = 'GLOBAL';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_tab_id := 0;
    END;

    IF NVL(v_tab_id, 0) > 0 THEN
        BEGIN
            SELECT attr_id
              INTO v_attr_id
              FROM m_sys.m_attrs
             WHERE attr_code = p_attr_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_attr_id := 0;
        END;

        IF NVL(v_attr_id, 0) > 0 THEN
            BEGIN
                SELECT physical_attribute
                  INTO v_physical_attribute
                  FROM m_sys.m_dict_tab_attrs
                 WHERE tab_id = v_tab_id
                   AND attr_id = v_attr_id;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_physical_attribute := NULL;
            END;

            IF NVL(v_physical_attribute, '#$%') <> '#$%' THEN
                BEGIN
                    SELECT DECODE(v_physical_attribute, 'ATTR_CHAR1', attr_char1, 'ATTR_CHAR2', attr_char2, 'ATTR_CHAR3', attr_char3, 'ATTR_CHAR4', attr_char4, 'ATTR_CHAR5', attr_char5, 'ATTR_CHAR6', attr_char6, 'ATTR_CHAR7', attr_char7, 'ATTR_CHAR8', attr_char8, 'ATTR_CHAR9', attr_char9, 'ATTR_CHAR10', attr_char10, 'ATTR_CHAR11', attr_char11, 'ATTR_CHAR12', attr_char12, 'ATTR_CHAR13', attr_char13, 'ATTR_CHAR14', attr_char14, 'ATTR_CHAR15', attr_char15, 'ATTR_CHAR16', attr_char16, 'ATTR_CHAR17', attr_char17, 'ATTR_CHAR18', attr_char18, 'ATTR_CHAR19', attr_char19, 'ATTR_CHAR20', attr_char20)
                      INTO v_attr_value
                      FROM m_sys.m_projects
                     WHERE proj_id = p_proj_id;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_attr_value := NULL;
                END;
            END IF;
        END IF;
    END IF;
    RETURN v_attr_value;
END get_project_attribute;


FUNCTION get_attribute_value
    (
        p_used_type                        m_sys.m_used_values.used_type%TYPE,
        p_pk_id                            m_sys.m_used_values.pk_id%TYPE,
        p_attr_code                        m_sys.m_attrs.attr_code%TYPE
    )
    RETURN m_sys.m_used_values.attr_value%TYPE
IS
    v_attr_id                            m_sys.m_attrs.attr_id%TYPE;
    v_attr_value                        m_sys.m_used_values.attr_value%TYPE;
BEGIN
    BEGIN
        SELECT attr_id
          INTO v_attr_id
          FROM m_sys.m_attrs
         WHERE attr_code = p_attr_code;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_attr_id := 0;
    END;

    IF NVL(v_attr_id, 0) > 0 THEN
        BEGIN
            SELECT MAX(attr_value)
              INTO v_attr_value
              FROM m_sys.m_used_values
             WHERE used_type = p_used_type
               AND pk_id = p_pk_id
               AND attr_id = v_attr_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_attr_value := NULL;
        END;
    END IF;
    RETURN v_attr_value;
END get_attribute_value;


FUNCTION get_attribute_number_value
    (
        p_used_type                        m_sys.m_used_values.used_type%TYPE,
        p_pk_id                            m_sys.m_used_values.pk_id%TYPE,
        p_attr_code                        m_sys.m_attrs.attr_code%TYPE
    )
    RETURN m_sys.m_used_values.number_value%TYPE
IS
    v_attr_id                            m_sys.m_attrs.attr_id%TYPE;
    v_attr_value                        m_sys.m_used_values.number_value%TYPE;
BEGIN
    BEGIN
        SELECT attr_id
          INTO v_attr_id
          FROM m_sys.m_attrs
         WHERE attr_code = p_attr_code;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_attr_id := 0;
    END;

    IF NVL(v_attr_id, 0) > 0 THEN
        BEGIN
            SELECT MAX(number_value)
              INTO v_attr_value
              FROM m_sys.m_used_values
             WHERE used_type = p_used_type
               AND pk_id = p_pk_id
               AND attr_id = v_attr_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_attr_value := NULL;
        END;
    END IF;
    RETURN v_attr_value;
END get_attribute_number_value;


FUNCTION get_table_detail_attribute
(
    p_proj_id                IN        m_sys.m_projects.proj_id%TYPE,
    p_table_name            IN        m_sys.m_dict_tabs.table_name%TYPE,
    p_attr_code                IN        m_sys.m_attrs.attr_code%TYPE,
    p_table_group_code        IN        m_sys.m_table_groups.table_group_code%TYPE,
    p_td_code                IN        m_sys.m_table_details.td_code%TYPE
)
    RETURN m_sys.m_table_details.attr_char1%TYPE
IS
    v_attr_id                            m_sys.m_attrs.attr_id%TYPE;
    v_tab_id                            m_sys.m_dict_tabs.tab_id%TYPE;
    v_tab_group_id                        m_sys.m_table_groups.tab_group_id%TYPE;
    v_physical_attribute                m_sys.m_dict_tab_attrs.physical_attribute%TYPE;
    v_attr_value                        m_sys.m_table_details.attr_char1%TYPE;
BEGIN
    BEGIN
        SELECT tab_id
          INTO v_tab_id
          FROM m_sys.m_dict_tabs
         WHERE table_name = p_table_name
           AND proj_id = p_proj_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_tab_id := 0;
    END;

    IF NVL(v_tab_id, 0) <> 0 THEN
        BEGIN
            SELECT attr_id
              INTO v_attr_id
              FROM m_sys.m_attrs
             WHERE attr_code = p_attr_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_attr_id := 0;
        END;

        IF NVL(v_attr_id, 0) <> 0 THEN
            BEGIN
                SELECT physical_attribute
                  INTO v_physical_attribute
                  FROM m_sys.m_dict_tab_attrs
                 WHERE tab_id = v_tab_id
                   AND attr_id = v_attr_id;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_physical_attribute := NULL;
            END;

            IF NVL(v_physical_attribute, '#$%') <> '#$%' THEN
                BEGIN
                    SELECT tab_group_id
                      INTO v_tab_group_id
                      FROM m_sys.m_table_groups
                     WHERE proj_id = p_proj_id
                       AND tab_id = v_tab_id
                       AND table_group_code = p_table_group_code;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_tab_group_id := 0;
                END;

                IF NVL(v_tab_group_id, 0) <> 0 THEN
                    BEGIN
                        SELECT DECODE(v_physical_attribute, 'TD.CHAR1', attr_char1, 'TD.CHAR2', attr_char2, 'TD.CHAR3', attr_char3, 'TD.NUM1', attr_num1, 'TD.NUM2', attr_num2, 'TD.NUM3', attr_num3)
                          INTO v_attr_value
                          FROM m_sys.m_table_details
                         WHERE proj_id = p_proj_id
                           AND tab_id = v_tab_id
                           AND tab_group_id = v_tab_group_id
                           AND td_code = p_td_code;
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            v_attr_value := NULL;
                    END;
                END IF;
            END IF;
        END IF;
    END IF;
    RETURN v_attr_value;
END get_table_detail_attribute;


FUNCTION mdr_convert_units (
    p_from_unit_id        IN                    m_sys.m_unit_to_units.unit_id%TYPE,
    p_to_unit_id        IN                    m_sys.m_unit_to_units.to_unit_id%TYPE,
    p_original_value    IN                    m_sys.m_used_values.number_value%TYPE,
    p_proj_id        IN                    m_sys.m_projects.proj_id%TYPE
    )
    RETURN m_used_values.number_value%TYPE
IS
    v_coverted_value                        m_sys.m_used_values.number_value%TYPE    DEFAULT -1;
    v_addend                            m_sys.m_unit_to_units.addend%TYPE        DEFAULT 0;
    v_addend1                            m_sys.m_unit_to_units.addend1%TYPE        DEFAULT 0;
    v_factor                            m_sys.m_unit_to_units.factor%TYPE        DEFAULT 1;
    v_rowcount                            NUMBER    DEFAULT 0;
    v_count                                NUMBER;
BEGIN
    IF p_from_unit_id = p_to_unit_id THEN
        v_coverted_value := p_original_value;
    ELSE
        BEGIN

            SELECT COUNT(*)
              INTO v_count
              FROM m_sys.m_unit_to_units
             WHERE unit_id = p_from_unit_id
               AND to_unit_id = p_to_unit_id
               AND proj_id = p_proj_id;

            IF v_count = 0 THEN

                SELECT COUNT(*)
                INTO v_count
                FROM m_sys.m_unit_to_units
                WHERE unit_id = p_from_unit_id
                AND to_unit_id = p_to_unit_id
                AND proj_id IN (SELECT pg_code FROM m_sys.m_project_product_disciplines WHERE proj_id =  p_proj_id);

                IF v_count = 0 THEN

                    SELECT COUNT(*)
                    INTO    v_count
                    FROM m_sys.m_unit_to_units
                    WHERE unit_id = p_to_unit_id
                    AND to_unit_id = p_from_unit_id
                    AND proj_id = p_proj_id;

                    IF v_count = 0 THEN

                        SELECT COUNT(*)
                        INTO    v_count
                        FROM m_sys.m_unit_to_units
                        WHERE unit_id = p_to_unit_id
                        AND to_unit_id = p_from_unit_id
                        AND proj_id IN (SELECT pg_code FROM m_sys.m_project_product_disciplines WHERE proj_id =  p_proj_id);

                        IF v_count = 0 THEN
                            v_coverted_value := -3;
                        ELSE
                            SELECT NVL(addend, 0), NVL(addend1, 0), NVL(factor, 0)
                            INTO v_addend, v_addend1, v_factor
                            FROM m_sys.m_unit_to_units
                            WHERE unit_id = p_to_unit_id
                            AND to_unit_id = p_from_unit_id
                            AND proj_id IN (SELECT pg_code FROM m_sys.m_project_product_disciplines WHERE proj_id =  p_proj_id);

                            IF NVL(v_factor, 0) = 0 THEN
                                v_coverted_value := -2;
                            ELSE
                                v_coverted_value := ((p_original_value - v_addend1) / v_factor) - v_addend;
                            END IF;
                        END IF;
                    ELSE
                        SELECT NVL(addend, 0), NVL(addend1, 0), NVL(factor, 0)
                        INTO v_addend, v_addend1, v_factor
                        FROM m_sys.m_unit_to_units
                        WHERE unit_id = p_to_unit_id
                        AND to_unit_id = p_from_unit_id
                        AND proj_id = p_proj_id;

                        IF NVL(v_factor, 0) = 0 THEN
                            v_coverted_value := -2;
                        ELSE
                            v_coverted_value := ((p_original_value - v_addend1) / v_factor) - v_addend;
                        END IF;
                    END IF;
                ELSE

                    SELECT NVL(addend, 0), NVL(addend1, 0), NVL(factor, 0)
                    INTO v_addend, v_addend1, v_factor
                    FROM m_sys.m_unit_to_units
                    WHERE unit_id = p_from_unit_id
                    AND to_unit_id = p_to_unit_id
                    AND proj_id IN (SELECT pg_code FROM m_sys.m_project_product_disciplines WHERE proj_id =  p_proj_id);

                    v_coverted_value := (p_original_value + v_addend) * v_factor + v_addend1;
                END IF;
            ELSE

                SELECT NVL(addend, 0), NVL(addend1, 0), NVL(factor, 0)
                INTO v_addend, v_addend1, v_factor
                FROM m_sys.m_unit_to_units
                WHERE unit_id = p_from_unit_id
                AND to_unit_id = p_to_unit_id
                AND proj_id = p_proj_id;

                v_coverted_value := (p_original_value + v_addend) * v_factor + v_addend1;
            END IF;
        EXCEPTION
        WHEN OTHERS THEN
            v_coverted_value := -3;
        END;
    END IF;

    RETURN v_coverted_value;
END;

-- Get Job ID
FUNCTION get_job_id (
    p_ac_job_number            IN        m_sys.m_jobs.job_number%TYPE
)
    RETURN m_sys.m_jobs.job_id%TYPE
IS
    v_job_id                            m_sys.m_jobs.job_id%TYPE                        DEFAULT 0;
    v_ac_job_number                m_sys.m_jobs.job_number%TYPE;
  v_ac_inactive                        m_sys.m_jobs.FIELD7%TYPE; ---New variable as per new POET structure for8.x consolidation -01/16/20- CG
    v_search_ac_job_number                m_sys.m_jobs.job_number%TYPE;
BEGIN
    v_ac_job_number := UPPER(p_ac_job_number);
    v_search_ac_job_number := v_ac_job_number;

    -- Check if the Closed status is included in the Job Number, if not then search for Open A/C Distribution
    IF v_ac_inactive <> 'Y' AND v_ac_inactive <> 'N' THEN
        v_search_ac_job_number := v_ac_job_number ;
    END IF;

    SELECT MAX(job_id)
      INTO v_job_id
      FROM m_sys.m_jobs
     WHERE job_number = v_search_ac_job_number;

    -- If A/C Distribution not found and the Closed status was not passed then search for Closed A/C Distribution
    IF NVL(v_job_id, 0) = 0 AND v_search_ac_job_number <> v_ac_job_number THEN
        /*v_search_ac_job_number := v_ac_job_number || '-YES'; ---*******Logic change as per new POET structure for8.x consolidation -01/16/20- CG */
    v_search_ac_job_number := v_ac_job_number ;

        SELECT MAX(job_id)
          INTO v_job_id
          FROM m_sys.m_jobs
    /* WHERE job_number = v_search_ac_job_number and FIELD7 = 'Y'; ---*******Logic change as per new POET structure for8.x consolidation -01/16/20- CG */
         WHERE job_number = v_search_ac_job_number ;
    END IF;

    RETURN v_job_id;
END get_job_id;


    FUNCTION get_commodity_attribute
        (
            p_commodity_id                    m_sys.m_commodity_codes.commodity_id%TYPE,
            p_attr_code                        m_sys.m_attrs.attr_code%TYPE
        )
        RETURN m_sys.m_commodity_codes.attr_char1%TYPE
    IS
        v_attr_id                            m_sys.m_attrs.attr_id%TYPE;
        v_tab_id                            m_sys.m_dict_tabs.tab_id%TYPE;
        v_physical_attribute                m_sys.m_dict_tab_attrs.physical_attribute%TYPE;
        v_attr_value                        m_sys.m_commodity_codes.attr_char1%TYPE;
    BEGIN
        BEGIN
            SELECT tab_id
              INTO v_tab_id
              FROM m_sys.m_dict_tabs
             WHERE table_name = 'M_COMMODITY_CODES'
               AND proj_id = 'GLOBAL';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_tab_id := 0;
        END;

        IF NVL(v_tab_id, 0) > 0 THEN
            BEGIN
                SELECT attr_id
                  INTO v_attr_id
                  FROM m_sys.m_attrs
                 WHERE attr_code = p_attr_code;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_attr_id := 0;
            END;

            IF NVL(v_attr_id, 0) > 0 THEN
                BEGIN
                    SELECT physical_attribute
                      INTO v_physical_attribute
                      FROM m_sys.m_dict_tab_attrs
                     WHERE tab_id = v_tab_id
                       AND attr_id = v_attr_id;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_physical_attribute := NULL;
                END;

                IF NVL(v_physical_attribute, '#$%') <> '#$%' THEN
                    BEGIN
                        SELECT DECODE(v_physical_attribute, 'ATTR_CHAR1', attr_char1, 'ATTR_CHAR2', attr_char2, 'ATTR_CHAR3', attr_char3, 'ATTR_CHAR4', attr_char4, 'ATTR_CHAR5', attr_char5, 'ATTR_CHAR6', attr_char6, 'ATTR_CHAR7', attr_char7, 'ATTR_CHAR8', attr_char8, 'ATTR_CHAR9', attr_char9, 'ATTR_CHAR10', attr_char10, 'ATTR_CHAR11', attr_char11, 'ATTR_CHAR12', attr_char12, 'ATTR_CHAR13', attr_char13, 'ATTR_CHAR14', attr_char14, 'ATTR_CHAR15', attr_char15, NULL)
                          INTO v_attr_value
                          FROM m_sys.m_commodity_codes
                         WHERE commodity_id = p_commodity_id;
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            v_attr_value := NULL;
                    END;
                END IF;
            END IF;
        END IF;
        RETURN v_attr_value;
    END get_commodity_attribute;


    PROCEDURE set_commodity_attribute
        (
            p_commodity_id                m_sys.m_commodity_codes.commodity_id%TYPE,
            p_attr_code                        m_sys.m_attrs.attr_code%TYPE,
            p_attr_value                    m_sys.m_commodity_codes.attr_char1%TYPE
        )
    IS
        v_attr_id                            m_sys.m_attrs.attr_id%TYPE;
        v_tab_id                            m_sys.m_dict_tabs.tab_id%TYPE;
        v_physical_attribute                m_sys.m_dict_tab_attrs.physical_attribute%TYPE;
    BEGIN
        BEGIN
            SELECT tab_id
              INTO v_tab_id
              FROM m_sys.m_dict_tabs
             WHERE table_name = 'M_COMMODITY_CODES'
               AND proj_id = 'GLOBAL';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_tab_id := 0;
        END;

        IF NVL(v_tab_id, 0) > 0 THEN
            BEGIN
                SELECT attr_id
                  INTO v_attr_id
                  FROM m_sys.m_attrs
                 WHERE attr_code = p_attr_code;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_attr_id := 0;
            END;

            IF NVL(v_attr_id, 0) > 0 THEN
                BEGIN
                    SELECT physical_attribute
                      INTO v_physical_attribute
                      FROM m_sys.m_dict_tab_attrs
                     WHERE tab_id = v_tab_id
                       AND attr_id = v_attr_id;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_physical_attribute := NULL;
                END;

                IF NVL(v_physical_attribute, '#$%') <> '#$%' THEN
                    IF v_physical_attribute = 'ATTR_CHAR1' THEN
                        UPDATE m_sys.m_commodity_codes SET attr_char1 = p_attr_value WHERE commodity_id = p_commodity_id;
                    ELSIF v_physical_attribute = 'ATTR_CHAR2' THEN
                        UPDATE m_sys.m_commodity_codes SET attr_char2 = p_attr_value WHERE commodity_id = p_commodity_id;
                    ELSIF v_physical_attribute = 'ATTR_CHAR3' THEN
                        UPDATE m_sys.m_commodity_codes SET attr_char3 = p_attr_value WHERE commodity_id = p_commodity_id;
                    ELSIF v_physical_attribute = 'ATTR_CHAR4' THEN
                        UPDATE m_sys.m_commodity_codes SET attr_char4 = p_attr_value WHERE commodity_id = p_commodity_id;
                    ELSIF v_physical_attribute = 'ATTR_CHAR5' THEN
                        UPDATE m_sys.m_commodity_codes SET attr_char5 = p_attr_value WHERE commodity_id = p_commodity_id;
                    ELSIF v_physical_attribute = 'ATTR_CHAR6' THEN
                        UPDATE m_sys.m_commodity_codes SET attr_char6 = p_attr_value WHERE commodity_id = p_commodity_id;
                    ELSIF v_physical_attribute = 'ATTR_CHAR7' THEN
                        UPDATE m_sys.m_commodity_codes SET attr_char7 = p_attr_value WHERE commodity_id = p_commodity_id;
                    ELSIF v_physical_attribute = 'ATTR_CHAR8' THEN
                        UPDATE m_sys.m_commodity_codes SET attr_char8 = p_attr_value WHERE commodity_id = p_commodity_id;
                    ELSIF v_physical_attribute = 'ATTR_CHAR9' THEN
                        UPDATE m_sys.m_commodity_codes SET attr_char9 = p_attr_value WHERE commodity_id = p_commodity_id;
                    ELSIF v_physical_attribute = 'ATTR_CHAR10' THEN
                        UPDATE m_sys.m_commodity_codes SET attr_char10 = p_attr_value WHERE commodity_id = p_commodity_id;
                    ELSIF v_physical_attribute = 'ATTR_CHAR11' THEN
                        UPDATE m_sys.m_commodity_codes SET attr_char11 = p_attr_value WHERE commodity_id = p_commodity_id;
                    ELSIF v_physical_attribute = 'ATTR_CHAR12' THEN
                        UPDATE m_sys.m_commodity_codes SET attr_char12 = p_attr_value WHERE commodity_id = p_commodity_id;
                    ELSIF v_physical_attribute = 'ATTR_CHAR13' THEN
                        UPDATE m_sys.m_commodity_codes SET attr_char13 = p_attr_value WHERE commodity_id = p_commodity_id;
                    ELSIF v_physical_attribute = 'ATTR_CHAR14' THEN
                        UPDATE m_sys.m_commodity_codes SET attr_char14 = p_attr_value WHERE commodity_id = p_commodity_id;
                    ELSIF v_physical_attribute = 'ATTR_CHAR15' THEN
                        UPDATE m_sys.m_commodity_codes SET attr_char15 = p_attr_value WHERE commodity_id = p_commodity_id;
                    END IF;
                END IF;
            END IF;
        END IF;
    END set_commodity_attribute;


    FUNCTION get_ident_attribute
        (
            p_ident                            m_sys.m_idents.ident%TYPE,
            p_attr_code                    m_sys.m_attrs.attr_code%TYPE
        )
        RETURN m_sys.m_ident_values.attr_value%TYPE
    IS
        v_attr_value                        m_sys.m_ident_values.attr_value%TYPE;
    BEGIN
        BEGIN
            SELECT attr_value
              INTO v_attr_value
              FROM m_sys.m_ident_values i, m_sys.m_attrs a
             WHERE i.ident = p_ident
               AND a.attr_code = p_attr_code
               AND i.attr_id = a.attr_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_attr_value := NULL;
        END;
        RETURN v_attr_value;
    END get_ident_attribute;


    PROCEDURE set_ident_attribute
        (
            p_ident                            m_sys.m_idents.ident%TYPE,
            p_attr_code                    m_sys.m_attrs.attr_code%TYPE,
            p_attr_value                m_sys.m_ident_values.attr_value%TYPE
        )
    IS
        v_attr_id                            m_sys.m_attrs.attr_id%TYPE;
        v_unit_id                            m_sys.m_units.unit_id%TYPE;
        v_rowcount                        NUMBER;
    BEGIN
        BEGIN
            SELECT attr_id, unit_id
              INTO v_attr_id, v_unit_id
              FROM m_sys.m_attrs
             WHERE attr_code = p_attr_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_attr_id := 0;
        END;

        IF NVL(v_attr_id, 0) > 0 THEN
            SELECT count(*)
              INTO v_rowcount
              FROM m_sys.m_ident_values
             WHERE ident = p_ident
               AND attr_id = v_attr_id;

            -- Add the Ident Attribute Value if it does not exist
            IF NVL(v_rowcount, 0) = 0 THEN
                INSERT INTO m_sys.m_ident_values (iv_id, proj_id, ident, attr_id, attr_value, unit_id, dp_id, created_by)
                SELECT m_sys.m_seq_iv_id.nextval, i.proj_id, p_ident, v_attr_id, p_attr_value, v_unit_id, c.dp_id, user
                  FROM m_sys.m_idents i, m_sys.m_commodity_codes c
                 WHERE i.ident = p_ident
                   AND c.commodity_id = i.commodity_id;
            ELSE
                UPDATE m_sys.m_ident_values
                   SET attr_value = p_attr_value
                 WHERE ident = p_ident
                   AND attr_id = v_attr_id;
            END IF;
            COMMIT;
        END IF;
    END set_ident_attribute;

    PROCEDURE mdr_oc_check (p_poh_id IN                    m_po_headers.poh_id%TYPE)
    IS
        CURSOR header_uoc_cur (p_base_poh_id NUMBER)
        IS
        SELECT oc_code, cost_value
        FROM    (
            SELECT oc.oc_code, NVL(SUM(uoc.cost_value),0) cost_value
            FROM m_sys.m_used_other_costs uoc,
                 (SELECT poh_id
                FROM m_sys.m_po_headers
                   WHERE base_poh_id = p_base_poh_id
                 AND poh_id <= p_poh_id
                 ) poh,
                 m_sys.m_other_costs oc
            WHERE uoc.term_type = 'PO'
            AND uoc.pk_id = poh.poh_id
            AND uoc.oc_id = oc.oc_id
            GROUP BY oc_code
            )
        WHERE    cost_value < 0
        ORDER BY oc_code;

        CURSOR    item_uoc_cur(p_poli_id NUMBER, p_parent_poli_id NUMBER)
        IS
        SELECT    oc_code, cost_value
        FROM    (
            SELECT    oc.oc_code, NVL(SUM(uoc.cost_value),0) cost_value
            FROM    m_sys.m_used_other_costs uoc,
                m_sys.m_other_costs oc
            WHERE    uoc.term_type = 'PLI'
            AND    uoc.pk_id IN (SELECT poli_id
                      FROM     m_sys.m_po_line_items
                      WHERE  poli_id = p_parent_poli_id
                      OR (poli_id <= p_poli_id AND parent_poli_id = p_parent_poli_id)
                     )
            AND uoc.oc_id = oc.oc_id
            GROUP BY oc_code
            )
        WHERE    cost_value < 0
        ORDER BY oc_code;


        CURSOR    poli_cur
        IS
        SELECT    poli.poli_id,
            poli.poli_pos,
            poli.poli_sub_pos,
            poli.tag_number,
            poli.parent_poli_id
        FROM    m_sys.m_po_line_items poli
        WHERE    poli.poh_id = p_poh_id
        ORDER BY poli.poli_pos,poli.poli_sub_pos;

        v_base_poh_id m_po_headers.base_poh_id%TYPE;



    BEGIN

        SELECT    base_poh_id
        INTO    v_base_poh_id
        FROM    m_po_headers
        WHERE    poh_id = p_poh_id;


        -- SD, Added to check negative other costs.
        FOR header_uoc_rec IN header_uoc_cur(v_base_poh_id) LOOP
            --Ruby No MP070 and MP071 change to MP066
            --RAISE_APPLICATION_ERROR(-20000,'MAR-MP070 #1' ||header_uoc_rec.oc_code||'#2'||header_uoc_rec.cost_value);
            RAISE_APPLICATION_ERROR(-20000,'MAR-MP066 #1' ||header_uoc_rec.oc_code||'#2'||header_uoc_rec.cost_value);
        END LOOP;

        FOR poli_rec IN poli_cur LOOP
            FOR item_uoc_rec IN item_uoc_cur (poli_rec.poli_id, poli_rec.parent_poli_id) LOOP
                --RAISE_APPLICATION_ERROR(-20000,'MAR-MP071 #1' ||item_uoc_rec.oc_code||'#2'||poli_rec.poli_pos||'#3'||item_uoc_rec.cost_value);
                RAISE_APPLICATION_ERROR(-20000,'MAR-MP066 #1' ||item_uoc_rec.oc_code||'#2'||poli_rec.poli_pos||'#3'||item_uoc_rec.cost_value);
            END LOOP;
        END LOOP;

    END;



/*
|| ***********************************************************************************************************************************
|| mdr_check_agreement
|| ===================||
|| Intended to perform MDR specific Checks prior to approval / issuing of agreement
||
|| 2014                 RC      Original
|| 20-Feb-2015        MZ      IR132513: Allow listing of multiple approvers from approval template -- MZiyad
|| 01-Mar-2015        MZ      IR140094: Separate approval template for Subcontract 'SC'
|| 08-Jul-2015        MZ      IR200059: Selection of approvers based on Title
|| 08-Jul-2015        MZ      IR200059: Added low monetary value for MRO project PO
||    Jul-2015        MZ      IR205109: PO validation for milestone pay events
||    Aug-2015        MZ      IR212743: Validation - Milestone pay events validation only for PO type, should not be for BO
||    Oct-2015    MZ        IR245967: PO Audit requirement, Requistion approver and PO approver can not be same.
||    Feb-2016    MZ        IR268997: IR308096-PO Audit requirement, Buyer should not be able to approve PO for requiston approved by him.
||    Jun-2016         MZ        INC0017326: Three way match modifications for tolerance.  - MZZ
||    Dec-2016         MZ        CHG0010659: Tolerance for MRR Qty.  - MZZ
||    Mar-2017         MZ        CHG0011065: Filter the Vendor Selection Codes -- MZ-VSC
||    May-2017         MZ        CHG0011486: -- MZ-3wayFix
||    OCT-2018         SK        CHG0014894: To fix UOM, logic chnaged to latest PO rev.
||    SEP-2019         MZ        CHG0019085: Restrict number of PO Lines exceeds 800.
|| ***********************************************************************************************************************************
*/
FUNCTION mdr_check_agreement (
    p_poh_id        IN                    m_po_headers.poh_id%TYPE,
    p_action        IN                    VARCHAR2                    DEFAULT 'approved'
    )
    RETURN NUMBER
IS
    v_rowcount                            NUMBER                                            DEFAULT 0;
    v_header_job_id                        m_sys.m_po_headers.job_id%TYPE;
    v_base_poh_id                        m_sys.m_po_headers.base_poh_id%TYPE;
    v_po_supp                            m_sys.m_po_headers.po_supp%TYPE;
    v_order_type                        m_sys.m_po_headers.order_type%TYPE;
    v_base_order_type                    m_sys.m_po_headers.order_type%TYPE;
    v_base_order_sub_type                m_sys.m_po_headers.order_sub_type%TYPE;
    v_cy_id                                m_sys.m_po_headers.cy_id%TYPE;
    v_buyer                                m_sys.m_po_headers.buyer%TYPE;
    v_last_prom_contr_date                m_sys.m_po_headers.last_prom_contr_date%TYPE;
    v_expediter                            m_sys.m_po_headers.expediter%TYPE;
    v_proj_id                            m_sys.m_po_headers.proj_id%TYPE;
    v_sup_id                            m_sys.m_po_headers.sup_id%TYPE;
    v_prev_rev_sup_id                    m_sys.m_po_headers.sup_id%TYPE;
    --v_po_close_date                        m_sys.m_po_headers.po_close_date%TYPE; -- MZZ
    v_currency_code                        m_sys.m_units.unit_code%TYPE;
    v_currency_id                        m_sys.m_po_headers.currency_id%TYPE;
    v_usd_currency_id                    m_sys.m_po_headers.currency_id%TYPE;
    v_prev_rev_currency_id                m_sys.m_po_headers.currency_id%TYPE;
    v_poli_pos                            m_sys.m_po_line_items.poli_pos%TYPE;
    v_poli_qty                            m_sys.m_po_line_items.poli_qty%TYPE;
    v_recv_qty                            m_sys.m_inv_receipts.recv_qty%TYPE;
    v_tolerance_qty                        m_sys.m_osds.osd_qty%TYPE; -- MZZ2
    v_recv_tolerance_ind                VARCHAR2(3) DEFAULT 'NO'; -- MZZ3
    v_oc_code                            m_sys.m_other_costs.oc_code%TYPE;

  /*****Entity Attribute is obsolete for 8.x consolidation -01/15/2020 - CG
  v_entity                            m_sys.m_jobs.field1%TYPE;
    v_po_number_entity                    m_sys.m_jobs.field1%TYPE;
    v_prev_rev_entity                    m_sys.m_jobs.field1%TYPE;
  *******************************************************************/
    v_select_code                        m_sys.m_used_values.attr_value%TYPE;
    v_select_code_full                    m_sys.m_used_values.attr_value%TYPE;
    v_lowest_supplier_price                m_sys.m_used_values.number_value%TYPE;
    v_lowest_supplier_name                m_sys.m_used_values.attr_value%TYPE;
    v_payment_mode_attr_id                m_sys.m_attrs.attr_id%TYPE;
    v_payment_mode                        m_sys.m_used_values.attr_value%TYPE;
    v_prev_rev_payment_mode                m_sys.m_used_values.attr_value%TYPE;
    v_payment_mode_code                    m_sys.m_used_values.attr_value%TYPE;
    v_payment_type                        m_sys.m_po_headers.payment_type%TYPE;
    v_total_price                        m_sys.m_po_total_costs.total_price%TYPE;
    v_total_usd_price                    m_sys.m_po_total_costs.total_price%TYPE;
    v_total_ordered_value                m_sys.m_po_total_costs.total_price%TYPE;
    v_original_budget                    m_sys.m_reqs.original_budget%TYPE;
    v_last_original_budget                m_sys.m_reqs.original_budget%TYPE;
    v_pp_value                            m_sys.m_po_total_costs.total_price%TYPE;
    v_oc_value                            m_sys.m_used_other_costs.cost_value%TYPE;
    v_disused                            m_sys.m_commodity_codes.disused%TYPE;
    v_commodity_code                    m_sys.m_commodity_codes.commodity_code%TYPE;
    v_quantity_invoiced                    interface.invoice_items.quantity_invoiced%TYPE;
    v_invoiced_amount                    interface.invoice_headers.invoiced_amount%TYPE;
    v_invoiced_pp_amount                interface.invoice_period_progress.invoiced_amount%TYPE;
    v_three_way_match                    interface.mdr_used_values.attr_value%TYPE        DEFAULT 'NO';
    v_three_way_match_item                interface.mdr_used_values.attr_value%TYPE        DEFAULT 'NO';
    v_three_way_match_pp                interface.mdr_used_values.attr_value%TYPE        DEFAULT 'NO';
    v_error_message                        VARCHAR2(4000)                                     DEFAULT 'SUCCESS';
    v_update_status                        VARCHAR2(20)                                     DEFAULT 'SUCCESS';
/*    v_upd_ac_dist_attr_id                m_sys.m_attrs.attr_id%TYPE; --- Logic to be relooked after Oracle confirms they can accept the updated a/c distribution from 8.x - 01/16- Cissy ***/
    v_three_way_match_attr_id            m_sys.m_attrs.attr_id%TYPE;
    v_three_way_match_pp_attr_id        m_sys.m_attrs.attr_id%TYPE;
    v_poli_id                            m_sys.m_po_line_items.poli_id%TYPE;
    v_rev_poli                            m_sys.m_po_line_items.poli_id%TYPE; -- SPK MRR.
    v_export_license_req_ind            m_sys.m_po_line_items.export_license_req_ind%TYPE;
    v_frt_id                            m_sys.m_po_line_items.frt_id%TYPE;
    v_po_number                            m_sys.m_po_headers.po_number%TYPE;
    --v_project_type                        m_sys.m_used_values.attr_value%TYP DEFAULT 'PROJECT';/**Obsolete Attribute for 8.x -01/15-CG **/
    v_tm_id                                m_sys.m_terms.tm_id%TYPE;
    v_tm_code                            m_sys.m_terms.tm_code%TYPE;
    v_tm_revision_id                    m_sys.m_terms.revision_id%TYPE;
    v_r_code                            m_sys.m_reqs.r_code%TYPE;
    v_last_r_code                        m_sys.m_reqs.r_code%TYPE;
    v_r_id                                m_sys.m_reqs.r_id%TYPE;
    v_last_r_id                            m_sys.m_reqs.r_id%TYPE;
    v_addend                            m_sys.m_unit_to_units.addend%TYPE;
    v_factor                            m_sys.m_unit_to_units.factor%TYPE;
    v_addend1                            m_sys.m_unit_to_units.addend1%TYPE;
    v_pgr_id                            m_sys.m_projects.pgr_id%TYPE;
    /*** GL Are and pomfloc are obsolete for 8.x consolidation - 01/15/2020- CG
  v_gl_area                            m_sys.m_table_details.attr_char1%TYPE;
    v_pomfloc                            m_sys.m_table_details.attr_char1%TYPE;
  ******************************************************************/
    v_tab_id                            m_sys.m_dict_tabs.tab_id%TYPE;
    v_item_mdr_packing_quantity            m_sys.m_used_values.number_value%TYPE; --MDR_PACKING_QUANTITY
    v_item_mdr_packing_factor            m_sys.m_used_values.number_value%TYPE; --MDR_PACKING_FACTOR
    v_item_mdr_packing_uom                m_sys.m_used_values.attr_value%TYPE; --MDR_PACKING_UOM
    v_item_mdr_packing_uom_id            m_sys.m_units.unit_id%TYPE;

    v_min_order_seq                        m_sys.m_att_terms.order_seq%TYPE;

    v_toggle_complete_id                m_sys.m_used_values.number_value%TYPE; --MZZ
    v_toggle_complete                    m_sys.m_used_values.attr_value%TYPE        DEFAULT 'NO'; --MZZ
  v_received_complete_id                m_sys.m_used_values.number_value%TYPE; --MZZ
  v_received_complete                    m_sys.m_used_values.attr_value%TYPE        DEFAULT 'NO'; --MZZ

    v_pp_id                                m_sys.mvp_pno_to_attps.pno_id%TYPE DEFAULT 0;  -- MZZ1
    v_pp_item_amount                    m_sys.mvp_pno_to_attps.actual_prog_val%TYPE   DEFAULT 0; -- MZZ1
    v_pp_item_invoiced_amount            interface.invoice_period_progress.invoiced_amount%TYPE   DEFAULT 0; -- MZZ1
    v_selection_code_attr_id            m_sys.m_attrs.attr_id%TYPE;
    v_by_pass_sel_code_filter            NUMBER DEFAULT 0;
    v_invoiced_oc_amount                interface.invoice_period_progress.invoiced_amount%TYPE;
    v_last_poh_id                        m_sys.m_po_headers.base_poh_id%TYPE;


    CURSOR mdr_po_items IS
    SELECT poli_id
      FROM (
            SELECT MAX(i.poli_id) poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL GROUP BY i.parent_poli_id
            UNION
            SELECT i.poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NULL
            MINUS
            SELECT DISTINCT i.parent_poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL)
     ORDER BY 1;

    --Revised PO items  ------SPK MRR
    CURSOR mdr_revpo_items IS
    SELECT poli_id
      FROM m_sys.m_po_line_items poli where poh_id =p_poh_id;

    -- Requisition Items that have updated A/C Distribution after the Order is generated
  /* Review logic for a/c update after business discussion for 8.x consolidation - Cissy- 01/16/20- Sandeep
    CURSOR req_upd_ac_dist IS
    SELECT v.pk_id
      FROM m_sys.m_used_values v,  m_sys.m_req_li_to_polis r
     WHERE v.attr_id = v_upd_ac_dist_attr_id
       AND v.used_type = 'ERLI'
       AND v.attr_value = 'YES'
       AND v.pk_id = r.rli_id
       AND r.poh_id = v_base_poh_id
     ORDER BY v.pk_id; */

     -- To update PP POs -- MZZ1
     CURSOR c_pp_items IS
     SELECT MAX(pta.pno_id) pp_id, ROUND(SUM(pta.actual_prog_val),4) pp_amount
      FROM m_sys.mvp_pno_to_attps pta,
           m_sys.m_progress_numbers  pn,
           m_sys.m_po_headers        poh
           WHERE pta.pk_type = 'POH'
       AND pn.pno_id = pta.pno_id
             AND pn.poh_id = pta.pk_id
             AND pn.poh_id = poh.poh_id
             AND pn.poh_id in (select distinct poh_id FROM m_sys.m_po_headers where base_poh_id = v_base_poh_id)
             AND pta.pk_id = poh.base_poh_id
             AND pn.approved_date IS NOT NULL
             AND poh.base_poh_id = v_base_poh_id
             GROUP BY pta.pno_id;

    --v_mdr_apr                    m_sys.m_ppd_defaults.parm_value%TYPE;   /**Obsolete for 8.x - 1/15- CG**/
  v_mdr_apr                    VARCHAR2(20)                         DEFAULT 'PROJECT';  --Defaulting to PROJECT for 8.x - 1/15- CG
    v_atpl_code                    m_sys.m_approval_templates.atpl_code%TYPE;
    v_atpl_id                      m_sys.m_approval_templates.atpl_id%TYPE;
    v_atd_id                      m_sys.m_approval_template_details.atd_id%TYPE;
    v_atd_currency_id            m_sys.m_approval_template_details.currency_id%TYPE;
    v_t_atd_currency_id        m_sys.m_approval_template_details.currency_id%TYPE; --SPK
    v_atd_currency                m_sys.m_units.unit_code%TYPE;
    v_atd_amount                  m_sys.m_approval_template_details.amount%TYPE;
    v_t_atd_amount                m_sys.m_approval_template_details.amount%TYPE; --SPK
    v_converted_amount        m_sys.m_approval_template_details.amount%TYPE;
    v_distrib_id                  m_sys.m_approval_template_details.distrib_id%TYPE;
    v_usr_id                   m_sys.m_approval_template_details.m_usr_id%TYPE;--SPK
    v_approver                    m_sys.m_approval_template_details.m_usr_id%TYPE;
    v_buyer_ut_id                m_sys.m_user_titles.ut_id%TYPE;
    v_ut_id                          m_sys.m_user_titles.ut_id%TYPE;
    v_t_ut_id                        m_sys.m_user_titles.ut_id%TYPE; ---SPK
    v_dp_id                          m_sys.m_disciplines.dp_id%TYPE;
    v_dp_code                      m_sys.m_disciplines.dp_code%TYPE;
    v_dp_abbrev                    m_sys.m_disciplines.dp_abbrev%TYPE;
    v_pk_id                          m_sys.m_used_values.pk_id%TYPE;

  /****Obsolete attributes for 8.x, should be replaced by POET attributes 01/15/20-CG- Sandeep ***
    v_template_suffix            m_sys.m_used_values.attr_value%TYPE            DEFAULT 'STD';
  v_req_entity                m_sys.m_used_values.attr_value%TYPE;
    v_req_account_type            m_sys.m_used_values.attr_value%TYPE;
    v_req_job                    m_sys.m_used_values.attr_value%TYPE;
    v_req_sub_function            m_sys.m_used_values.attr_value%TYPE;
    v_req_feature                m_sys.m_used_values.attr_value%TYPE;
  *******************************************************************************************/
    v_req_rev_project            m_sys.m_used_values.attr_value%TYPE;    -- MZ

    v_req_job_number            m_sys.m_jobs.job_number%TYPE;
    v_req_header_job_id            m_sys.m_jobs.job_id%TYPE                    DEFAULT 0;
    v_req_item_job_id            m_sys.m_jobs.job_id%TYPE                    DEFAULT 0;
    v_ident_unit_code            m_sys.m_units.unit_code%TYPE;
    v_commodity_unit_code        m_sys.m_units.unit_code%TYPE;
    v_item_qty_unit_code        m_sys.m_units.unit_code%TYPE;
    v_item_qty_unit_id            m_sys.m_units.unit_id%TYPE;

    v_item_commodity_id            m_sys.m_commodity_codes.commodity_id%TYPE;
    v_item_ident                    m_sys.m_idents.ident%TYPE;
    v_ident_cms_ind                  m_sys.m_idents.cms_ind%TYPE;
    v_approver_ut_id              m_sys.m_user_titles.ut_id%TYPE; -- MZ Approver's Title
    v_approver_title_name        m_sys.m_user_titles.title_name%TYPE;
    v_approver_f_title_name    m_sys.m_user_titles.title_name%TYPE;
    v_buyer_title_name            m_sys.m_user_titles.title_name%TYPE; -- MZ Buyer's Title
    v_order_seq                        m_sys.m_approval_users.order_seq%Type;
    v_po_approvers                NUMBER                    DEFAULT 0;     -- MZ    PO approvers
    v_atpl_approvers            NUMBER                    DEFAULT 0;     -- MZ    Template approvers
    v_au_id                          m_sys.m_approval_users.au_id%TYPE;
    v_r_dp_id                          m_sys.m_disciplines.dp_id%TYPE;
    v_r_dp_code                        m_sys.m_disciplines.dp_code%TYPE;
    v_r_dp_abbrev                    m_sys.m_disciplines.dp_abbrev%TYPE;
    v_def_buyer_title              m_sys.m_user_titles.title_name%TYPE DEFAULT 'BUYER';
    v_job_id                          m_sys.m_jobs.job_id%TYPE;
    v_r_approver                    m_sys.m_approval_template_details.m_usr_id%TYPE;  -- MZ req approver
    v_r_approver_ut_id            m_sys.m_user_titles.ut_id%TYPE; -- MZ req Approver's Title
    v_approver_d_title_name        m_sys.m_user_titles.title_name%TYPE DEFAULT '$$$'; -- MZ
    v_mdr_sel5_max_amt_prj        m_sys.m_ppd_defaults.parm_value%TYPE; -- MZ Low monetary allowed amount for project
    v_mdr_sel5_max_amt_mro        m_sys.m_ppd_defaults.parm_value%TYPE; -- MZ Low monetary allowed amount for mro
    v_error_3way_message        VARCHAR2(4000)                         DEFAULT 'SUCCESS'; -- MZ-3wayFix
    v_poli_count                    NUMBER;

    CURSOR non_buy_aprv_template_details IS
    SELECT m_usr_id, atd_id, currency_id, amount, distrib_id, ut_id
      FROM m_sys.m_approval_template_details
     WHERE proj_id = v_proj_id
       AND atpl_id = v_atpl_id
       AND ut_id <> v_buyer_ut_id
    ORDER BY amount;

    -- MZ existing approvers
    CURSOR approver_cur IS
    SELECT au_id, currency_id, amount, distrib_id,m_usr_id,ut_id
        FROM m_sys.m_approval_users
      WHERE proj_id = v_proj_id
         AND pk_type = 'PO'
         AND pk_id = p_poh_id
    ORDER BY amount;



    --Ruby One MDR--
    mdr_fin_sys_           VARCHAR2(255);
    rm_exist_              NUMBER;
    incoterm_exist_        NUMBER;
    delv_place_exist_      NUMBER;
    po_desc_len_           NUMBER;
    po_short_len_          NUMBER;
    po_desc_               m_sys.m_po_header_nls.description%TYPE;
    po_short_              m_sys.m_po_header_nls.short_desc%TYPE;
    po_nls_                NUMBER;
    len_client_po_number_  NUMBER;
    client_po_number_      VARCHAR2(50);
    l_unprintable_         NUMBER;
    prev_po_number_        VARCHAR2(50);
    l_exped_ilv_id_        NUMBER;
    l_ilv_id_              NUMBER;
    po_budget_             NUMBER;
    attr_budget_           VARCHAR2(10);
    l_cbi_po_              VARCHAR2(30);
    job_number_            VARCHAR2(70);
    field7_                VARCHAR2(100);
    field6_                VARCHAR2(100);
    field1_                VARCHAR2(100);
    field2_                VARCHAR2(100);
    field3_                VARCHAR2(100);
    l_pos_subpos_count_    NUMBER;
    total_po_line_items_   NUMBER;
    jde_ac_project_count_  NUMBER;
    mdr_fin_sys_id_        NUMBER;
    acc_attr_value_        VARCHAR2(30);
    poli_fin_sys_          NUMBER;
    check_poli_ac_         NUMBER;
    check_poli_ac2_        NUMBER;
    cnt_poli_id_           NUMBER;
    v_header_prev_job_id_  NUMBER;
    get_acc_uval_id_       NUMBER;
    oracle_entity_         NUMBER;
    olives_entity_         NUMBER;
    len_po_num_            NUMBER;
    jde_int_flag_          NUMBER;
    counterpart_           VARCHAR2(10);
    jde_disc_int_          VARCHAR2(10);
    interface_switch_po_   VARCHAR2(10);
    purchase_contract_     VARCHAR2(10);
    prior_contract_        VARCHAR2(10);
    l_replace_acc1_        NUMBER;
    l_replace_acc2_        NUMBER;
    l_job_id_              NUMBER;
    match_type_now_        VARCHAR2(10);
    match_type_init_       VARCHAR2(10);
    l_missing_account_     VARCHAR2(70);
    jde_vendorid_          NUMBER;
    jde_buyerid_           NUMBER;
    l_line_count_          NUMBER;
    l_currency_code        VARCHAR2(10);
    sup_use_count_         NUMBER;
    l_cur_use_count        NUMBER;
    other_costs_count_     NUMBER;
    other_costs_           NUMBER;
    payment_terms_         VARCHAR2(255);
    jde_match_type_        VARCHAR2(255);
    tot_spm_amount_        NUMBER;
    paid_amount_           NUMBER;
    prog_payments_         NUMBER;
    l_poli_account         NUMBER;
    ora_ss_attr_value_     VARCHAR2(100);
    ora_ss_attr_id_        NUMBER;
    v_company_id           NUMBER;
    prev_field3_           VARCHAR2(100);
    prev_field7_           VARCHAR2(100);
    prev_field6_           VARCHAR2(100);
    prev_field1_           VARCHAR2(100);
    po_any_spaces_         NUMBER;
    discount_percent_      NUMBER;
    discount_amount_       NUMBER;
    buyer_active_          NUMBER;
    l_insp_lv   m_sys.m_po_headers.ilv_id%TYPE;  --INC1109215
      l_exped_lv    m_sys.m_po_headers.exped_ilv_id%TYPE;  --INC1109215
    check_mdr_fin_sys_     NUMBER;
    req_mdr_fin_sys_       VARCHAR2(30);
    check_po_entity_       VARCHAR2(255);
    check_oc_mdr_fin_sys_  NUMBER;
    max_oc_mdr_fin_sys_    VARCHAR2(30);

    CURSOR Check_RM_Empty(base_poh_id_ IN NUMBER) IS
        SELECT MAX(p.poli_pos)
        FROM m_sys.m_item_ships s, m_sys.m_po_line_items p
        WHERE s.poli_id IN (SELECT MAX(i.poli_id) poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL GROUP BY i.parent_poli_id
                            UNION
                            SELECT i.poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NULL
                            MINUS
                            SELECT DISTINCT i.parent_poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL)
        AND s.rm_id IS NULL
        AND s.poli_id = p.poli_id;

    CURSOR Check_Incoterm_Empty(base_poh_id_ IN NUMBER) IS
        SELECT MAX(p.poli_pos)
        FROM m_sys.m_po_line_items p
        WHERE p.poli_id IN (SELECT MAX(i.poli_id) poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL GROUP BY i.parent_poli_id
                            UNION
                            SELECT i.poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NULL
                            MINUS
                            SELECT DISTINCT i.parent_poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL)
        AND frt_id IS NULL;

    CURSOR Check_Delv_Place_Empty(base_poh_id_ IN NUMBER) IS
        SELECT MAX(p.poli_pos)
        FROM m_sys.m_po_line_items p
        WHERE p.poli_id IN (SELECT MAX(i.poli_id) poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL GROUP BY i.parent_poli_id
                            UNION
                            SELECT i.poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NULL
                            MINUS
                            SELECT DISTINCT i.parent_poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL)
        AND freight_value IS NULL;

    CURSOR Check_PO_NLS IS
        SELECT COUNT(1)
        FROM m_sys.m_po_header_nls
        WHERE poh_id = p_poh_id
        AND nls_id   = MPCK_LOGIN.NLS_ID
        AND short_desc  IS NOT NULL
        AND description IS NOT NULL;

    CURSOR Check_PO_Desc_Char IS
        SELECT LENGTH(description), description, LENGTH(short_desc), short_desc
        FROM m_sys.m_po_header_nls
        WHERE poh_id = p_poh_id
        AND nls_id   = MPCK_LOGIN.NLS_ID;

    CURSOR Get_Prev_PO_No IS
        SELECT po_number
        FROM m_sys.m_po_headers
        WHERE poh_id = v_base_poh_id;

    CURSOR Check_Expediting_Level IS
        SELECT exped_ilv_id, ilv_id
        FROM m_sys.m_po_headers
        WHERE poh_id = p_poh_id;

    CURSOR Check_AC_PO_Header IS
        SELECT job_number, field7, field6, field1, field2, field3
        FROM m_sys.m_po_headers poh, m_sys.m_jobs j
        WHERE poh.poh_id = p_poh_id
        AND   poh.job_id = j.job_id(+);

    CURSOR Check_Prev_AC(base_poh_id_ IN NUMBER) IS
        SELECT j.job_id, field3, field7, TRIM(UPPER(field6)) field6, UPPER(TRIM(field1)) field1
        FROM m_sys.m_po_headers poh, m_sys.m_jobs j
        WHERE poh.job_id = j.job_id
        AND   poh.poh_id = (SELECT MAX(poh_id)
                            FROM m_sys.m_po_headers poh1
                            WHERE poh1.base_poh_id = base_poh_id_
                            AND   poh1.poh_id < p_poh_id);

    CURSOR Check_POLI_AC IS
        SELECT COUNT(poli_id) cnt_poli_id,
               COUNT(field7)  cnt_field7,
               COUNT(field6)  cnt_field6
        FROM m_sys.m_po_line_items poli, m_sys.m_jobs j
        WHERE poli.poh_id = p_poh_id
        AND   poli.job_id  = j.job_id(+);

    CURSOR Check_curr_MDR_FIN_SYS(proj_id_ IN VARCHAR2, attr_id_ IN NUMBER)  IS
        SELECT MAX(uval_id)
        FROM m_sys.m_used_values
        WHERE attr_id   = attr_id_
        AND   used_type = 'PO'
        AND   proj_id   = proj_id_
        AND   pk_id     = p_poh_id;

    CURSOR Get_POLI_ACC(attr_id_ IN NUMBER) IS
        SELECT poli.poli_id,
              (SELECT MAX(uval_id)
               FROM m_sys.m_used_values uv
               WHERE uv.proj_id = poli.proj_id
               AND uv.attr_id   = attr_id_
               AND uv.pk_id     = poli.poli_id
               AND uv.used_type = 'POLI') get_acc_uval_id
        FROM m_sys.m_po_line_items poli, m_sys.m_jobs j
        WHERE poli.poh_id   = p_poh_id
        AND   poli.job_id   = j.job_id;

    CURSOR Check_RH_POLI_AC IS
        SELECT DECODE(MAX(field7), NULL, 'JDE', 'ORACLE')
        FROM m_sys.m_po_line_items poli, m_sys.m_jobs j
        WHERE poli.poh_id   = p_poh_id
        AND   poli.job_id   = j.job_id;

    CURSOR c1 IS
        SELECT pol.proj_id,
             pol.poli_id,
             pol.poli_pos,
             pol.poli_sub_pos,
             pol.job_id,
             j.job_number account,
             u.unit_code qty_uom,
             pol.poli_qty * pol.poli_unit_price poli_amount
        FROM m_sys.m_po_line_items pol, m_sys.m_jobs j, m_sys.m_units u
        WHERE pol.poh_id = p_poh_id
        AND j.job_id = pol.job_id
        AND u.unit_id = pol.qty_unit_id
        ORDER BY pol.poli_pos, pol.poli_sub_pos;

    CURSOR c2 IS
        SELECT uoc.proj_id, uoc.uoc_id, rownum, uoc.job_id, j.job_number account, cost_value
        FROM m_sys.m_used_other_costs uoc, m_sys.m_jobs j
        WHERE uoc.pk_id = p_poh_id
        AND uoc.term_type = 'PO'
        AND j.job_id = uoc.job_id;

    CURSOR Check_Buyer_Active(proj_id_ IN VARCHAR2, buyer_ IN VARCHAR2) IS
        SELECT COUNT(1)
        FROM m_sys.m_user_securities
        WHERE proj_id  = proj_id_
        AND   m_usr_id = buyer_
        AND   aktiv    = 'ON';
    --TASK0139926
    CURSOR mdr_cancelled_items IS
    SELECT i.POLI_QTY ,i.poli_pos,i.poli_sub_pos,i.poli_id,h.po_supp  from m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE
    i.poh_id = p_poh_id and h.poh_id = i.poh_id;  --t
    v_poli_pos_last_rev   m_sys.m_po_line_items.poli_pos%TYPE;
    v_prev_poh_id         m_sys.m_po_line_items.poh_id%TYPE;
    v_poli_supp           m_sys.m_po_headers.po_supp%TYPE;
    --t v_poli_pos                m_sys.m_po_line_items.poli_pos%TYPE;
    v_poli_sub_pos        m_sys.m_po_line_items.poli_sub_pos%TYPE;
    v_last_qty            m_sys.m_po_line_items.poli_qty%TYPE;
    --
    -- Sandeep, Added on 28-Jul-2021
    v_co_total_price     m_po_total_costs.total_price%TYPE;
    v_appr_pno_tot_cost m_po_total_costs.total_price%TYPE;
    --End One MDR--

     CURSOR Check_IS_POLI_ORACLE IS
        SELECT COUNT(1)
        FROM m_sys.m_po_line_items poli, m_sys.m_jobs j
        WHERE poli.poh_id = p_poh_id
        AND   poli.job_id = j.job_id
        AND   field7 IS NOT NULL;

     CURSOR Check_IS_POLI_OLIVES IS
        SELECT COUNT(1)
        FROM m_sys.m_po_line_items poli, m_sys.m_jobs j
        WHERE poli.poh_id = p_poh_id
        AND   poli.job_id = j.job_id
        AND   (field7 IS NULL AND (field6 IS NOT NULL AND field6 IN ('YES', 'NO')));

     CURSOR Check_IS_POLI_JDE IS
        SELECT COUNT(1)
        FROM m_sys.m_po_line_items poli, m_sys.m_jobs j
        WHERE poli.poh_id = p_poh_id
        AND   poli.job_id = j.job_id
        AND   ((field7 IS NULL AND (field6 IS NOT NULL AND field6 NOT IN ('YES', 'NO')))
               OR
               (field7 IS NULL AND field6 IS NULL));

     CURSOR Get_Req_MDR_Fin_Sys(base_poh_id_ IN NUMBER) IS
        SELECT DISTINCT
             (CASE
                 WHEN (TRIM(j.field7) IS NOT NULL) THEN 'ORACLE'
                 WHEN (TRIM(j.field7) IS NULL AND TRIM(j.field6) IS NOT NULL AND UPPER(TRIM(j.field6)) IN ('YES', 'NO')) THEN 'OLIVES'
                 ELSE 'JDE'
             END) mdr_fin_sys
        FROM
            (SELECT poli_id, rli_id
            FROM m_sys.m_po_line_items p
            WHERE p.poli_id IN (SELECT MAX(i.poli_id) poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL GROUP BY i.parent_poli_id
                                UNION
                                SELECT i.poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NULL
                                MINUS
                                SELECT DISTINCT i.parent_poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL)) get_poli,
            m_sys.m_req_line_items rli, m_sys.m_jobs j
            WHERE get_poli.rli_id = rli.rli_id
            AND   rli.job_id = j.job_id;

     CURSOR Check_Req_MDR_Fin_Sys(base_poh_id_ IN NUMBER) IS
        SELECT COUNT(DISTINCT
             (CASE
                 WHEN (TRIM(j.field7) IS NOT NULL) THEN 'ORACLE'
                 WHEN (TRIM(j.field7) IS NULL AND TRIM(j.field6) IS NOT NULL AND UPPER(TRIM(j.field6)) IN ('YES', 'NO')) THEN 'OLIVES'
                 ELSE 'JDE'
             END)) cnt_mdr_fin_sys
        FROM
            (SELECT poli_id, rli_id
            FROM m_sys.m_po_line_items p
            WHERE p.poli_id IN (SELECT MAX(i.poli_id) poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL GROUP BY i.parent_poli_id
                                UNION
                                SELECT i.poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NULL
                                MINUS
                                SELECT DISTINCT i.parent_poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL)) get_poli,
            m_sys.m_req_line_items rli, m_sys.m_jobs j
            WHERE get_poli.rli_id = rli.rli_id
            AND   rli.job_id = j.job_id;

     CURSOR Check_Req_Entity_Oracle(base_poh_id_ IN NUMBER) IS
        SELECT MAX(field3)
        FROM
            (SELECT poli_id, rli_id
            FROM m_sys.m_po_line_items p
            WHERE p.poli_id IN (SELECT MAX(i.poli_id) poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL GROUP BY i.parent_poli_id
                                UNION
                                SELECT i.poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NULL
                                MINUS
                                SELECT DISTINCT i.parent_poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL)) get_poli,
            m_sys.m_req_line_items rli, m_sys.m_jobs j
            WHERE get_poli.rli_id = rli.rli_id
            AND   rli.job_id = j.job_id
            AND   ROWNUM < 2;

     CURSOR Check_Req_Entity_Olives(base_poh_id_ IN NUMBER) IS
        SELECT MAX(field1)
        FROM
            (SELECT poli_id, rli_id
            FROM m_sys.m_po_line_items p
            WHERE p.poli_id IN (SELECT MAX(i.poli_id) poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL GROUP BY i.parent_poli_id
                                UNION
                                SELECT i.poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NULL
                                MINUS
                                SELECT DISTINCT i.parent_poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = base_poh_id_ AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL)) get_poli,
            m_sys.m_req_line_items rli, m_sys.m_jobs j
            WHERE get_poli.rli_id = rli.rli_id
            AND   rli.job_id = j.job_id
            AND   ROWNUM < 2;
     
     CURSOR Check_OC_MDR_Fin_Sys(base_poh_id_ IN NUMBER) IS
        SELECT COUNT(DISTINCT
             (CASE
                 WHEN (TRIM(j.field7) IS NOT NULL) THEN 'ORACLE'
                 WHEN (TRIM(j.field7) IS NULL AND TRIM(j.field6) IS NOT NULL AND UPPER(TRIM(j.field6)) IN ('YES', 'NO')) THEN 'OLIVES'
                 ELSE 'JDE'
             END)) cnt_mdr_fin_sys,
             MAX(CASE
                 WHEN (TRIM(j.field7) IS NOT NULL) THEN 'ORACLE'
                 WHEN (TRIM(j.field7) IS NULL AND TRIM(j.field6) IS NOT NULL AND UPPER(TRIM(j.field6)) IN ('YES', 'NO')) THEN 'OLIVES'
                 ELSE 'JDE'
             END) max_mdr_fin_sys
        FROM m_sys.m_used_other_costs oc, m_sys.m_jobs j        
        WHERE oc.pk_id     = p_poh_id
        AND   oc.job_id    = j.job_id
        AND   oc.term_type = 'PO';

BEGIN
    BEGIN
        ----SPK MRR.
            v_error_message := 'Item Already Recieived ';
        -- 2.3.12.    Set the 'Exp Lic Req' checkbox for items where the Commodity Code has LTC_ECL_CLASS Attribute set to any value. Do not reset the checkbox if the LTC_ECL_CLASS is not set.
        OPEN mdr_revpo_items;
        LOOP
            FETCH mdr_revpo_items INTO v_poli_id;
            EXIT WHEN mdr_revpo_items%NOTFOUND;

            select max(ish.poli_id) into v_rev_poli
              from m_sys.m_po_line_items poli, m_sys.m_item_ships ish
              where ish.poli_id = poli.poli_id
              and   poli.poli_qty < m_pck_mscm.get_mrr_qty(v_order_type,ish.poli_id, ish.item_ship_pos, ish.item_ship_sub_pos)
              and   poh_id =p_poh_id;

            IF NVL(v_rev_poli, 0) > 0 THEN
            v_error_message := 'Item quantity reduced in the change order and we already have received the items';
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

        END LOOP;

        CLOSE mdr_revpo_items;
        ---SPK MRR.

        v_error_message := 'Attribute PAYMENT_MODE not defined';
        SELECT MAX(attr_id)
          INTO v_payment_mode_attr_id
          FROM m_sys.m_attrs
         WHERE attr_code = 'PAYMENT_MODE';

        -- Check TOGGLE_COMPLETE table is setup  -- MZZ
        v_error_message := 'TOGGLE_COMPLETE entry not found in A5001';

        SELECT MAX(attr_id)
          INTO v_toggle_complete_id
          FROM m_sys.m_attrs
         WHERE attr_code = 'TOGGLE_COMPLETE';

        IF NVL(v_toggle_complete_id, 0) = 0 THEN    -- MZZ
            v_error_message := 'MAR-MP066 #1p_action #2v_error_message';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;

        -- Check RECEIVED_COMPLETE table is setup
        v_error_message := 'RECEIVED_COMPLETE entry not found in A5001';
        SELECT MAX(attr_id)
          INTO v_received_complete_id
          FROM m_sys.m_attrs
         WHERE attr_code = 'RECEIVED_COMPLETE';

        IF NVL(v_received_complete_id, 0) = 0 THEN
            v_error_message := 'MAR-MP066 #1p_action #2v_error_message';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;

        v_error_message := 'Attribute THREE_WAY_MATCH not defined';
        SELECT MAX(attr_id)
          INTO v_three_way_match_attr_id
          FROM m_sys.m_attrs
         WHERE attr_code = 'THREE_WAY_MATCH';

        v_error_message := 'Attribute THREE_WAY_MATCH_PP not defined';
        SELECT MAX(attr_id)
          INTO v_three_way_match_pp_attr_id
          FROM m_sys.m_attrs
         WHERE attr_code = 'THREE_WAY_MATCH_PP';

/*******Revalidate the ability for Oracle to accept change after PO generated as part of 8.x- 01/16/20- Cissy  -----
        v_error_message := 'Attribute MDR_UPDATE_AC_DISTRIBUTION not defined';
        SELECT MAX(attr_id)
          INTO v_upd_ac_dist_attr_id
          FROM m_sys.m_attrs
         WHERE attr_code = 'MDR_UPDATE_AC_DISTRIBUTION';
**********************************************************************************************/

        v_error_message := 'Attribute Selection Code not defined';
        SELECT MAX(attr_id)
          INTO v_selection_code_attr_id
          FROM m_sys.m_attrs
         WHERE attr_code = 'SELECT_CODE';


        v_error_message := 'Attribute MDR_FIN_SYS not defined';
        mdr_fin_sys_id_ := 0;
        SELECT MAX(attr_id)
            INTO mdr_fin_sys_id_
            FROM m_sys.m_attrs
            WHERE attr_code = 'MDR_FIN_SYS';

        IF NVL(mdr_fin_sys_id_, 0) = 0 THEN    -- MZZ
            v_error_message := 'MAR-MP066 #1'||p_action||' #2v_error_message';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;

        v_error_message       := 'PO ' || p_poh_id || ' not found';
        len_client_po_number_ := 0;
        po_budget_            := 0;
        len_po_num_           := 0;
        discount_percent_     := 0;
        discount_amount_      := 0;

        SELECT po_supp, currency_id, sup_id, order_type, base_poh_id, payment_type, po_number, buyer, expediter, last_prom_contr_date, proj_id, dp_id, job_id, client_po_number, length(client_po_number), NVL(budget ,0), LENGTH(po_number),
               discount_percent, discount_amount
            INTO v_po_supp, v_currency_id, v_sup_id, v_order_type, v_base_poh_id, v_payment_type, v_po_number, v_buyer, v_expediter, v_last_prom_contr_date,
                 v_proj_id, v_dp_id, v_job_id, client_po_number_, len_client_po_number_, po_budget_, len_po_num_, discount_percent_, discount_amount_
            FROM m_sys.m_po_headers
            WHERE poh_id = p_poh_id;

        IF NVL(v_currency_id, 0) > 0 THEN
            SELECT unit_code
              INTO v_currency_code
              FROM m_sys.m_units
             WHERE unit_id = v_currency_id;
        END IF;

        SELECT pgr_id
        INTO v_pgr_id
        FROM m_sys.m_projects
        WHERE proj_id = v_proj_id;

        /* Start, 27-Jul, Added by Sandeep to validate total cost of the CO with milestone progress total payment. */

        BEGIN
            IF v_order_type = 'CO' THEN

                SELECT    total_price
                INTO    v_co_total_price
                FROM     m_po_total_costs
                WHERE    poh_id = p_poh_id;

                --SELECT     SUM(tot_matl_cost)
                SELECT  SUM(period_auth_total) --INC1226800 TOT_MATL_COST is from PO and if multiple progress it will muliple PO total costs which always failed
                INTO    v_appr_pno_tot_cost
                FROM     MV_PROGRESS_NUMBERS
                WHERE     poh_id = v_base_poh_id
                AND        approved_date IS NOT NULL;

                IF v_co_total_price < v_appr_pno_tot_cost THEN
                    v_error_message := 'Total Price of Agreement is lower than approved milestone progress payments.';
                    v_error_message := 'MAR-MP066 #1'||p_action||' #2'||v_error_message;
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;
            END IF;
        END;
        /* End, 27-Jul, Added by Sandeep to validate total cost of the CO with milestone progress total payment. */


        /**** There will be a default template for Procurement for 8.x - 01/15/2020 - CG*****
        /* Sandeep, Commented as ZX_MDR_APR is not in use.
        v_error_message := 'Default ZX_MDR_APR not found';
        v_mdr_apr := UPPER(m_sys.m_pck_ppd_defaults.get_value(v_pgr_id, v_proj_id, v_dp_id, 'ZX_MDR_APR'));
        *******************************************************************/
        --v_error_message := 'Default ZP_MDR_S5M not found'; -- MZ
        --v_mdr_sel5_max_amt_mro := m_sys.m_pck_ppd_defaults.get_value(v_pgr_id, NULL, NULL, 'ZP_MDR_S5M');


        v_error_message := 'Default ZP_MDR_S5P not found'; -- MZ
        --Ruby Put v_proj_id instead of NULL as it will overide the value in the Group
        v_mdr_sel5_max_amt_prj := m_sys.m_pck_ppd_defaults.get_value(v_pgr_id, v_proj_id, NULL, 'ZP_MDR_S5P');


        IF NVL(v_mdr_sel5_max_amt_prj, 0) = 0 THEN    -- MZZ
            v_error_message := 'MAR-MP066 #1'||p_action||' #2'||v_error_message;
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;

    /****Obsolete code for 8.x consolidation scope as POET doesnt need this field validation -- 01/16/20- CG *******
        IF NVL(v_job_id, 0) > 0 THEN
            SELECT field1
              INTO v_entity
              FROM m_sys.m_jobs
             WHERE job_id = v_job_id;
        END IF;
    ************************************************************************************/
    /***********************Obsolete Attribute for 8.x -01/15-CG *************************
        v_project_type := NVL(get_project_attribute (v_proj_id, 'PROJECT_TYPE'), 'PROJECT');
    ************************************************************************************/

        v_error_message := 'Base PO ' || v_base_poh_id || ' not found';
        SELECT NVL(order_type, '#$%'), NVL(order_sub_type, '#$%')
          INTO v_base_order_type, v_base_order_sub_type
          FROM m_sys.m_po_headers
         WHERE poh_id = v_base_poh_id;

        v_error_message := 'PO Requistion number.'; -- MZ
        BEGIN
            SELECT MIN(r_id)
              INTO v_r_id
              FROM m_sys.m_req_li_to_polis
             WHERE poh_id = v_base_poh_id;
        EXCEPTION
            WHEN OTHERS THEN
                v_r_id := NULL;
        END;

        v_error_message := 'PO Requistion approver.'; -- MZ
        BEGIN
            SELECT approved_by
              INTO v_r_approver
              FROM m_sys.m_reqs
             WHERE r_id = v_r_id;
        EXCEPTION
            WHEN OTHERS THEN
                v_r_approver := NULL;
        END;



        --Ruby One MDR--
        OPEN  Check_AC_PO_Header;
        FETCH Check_AC_PO_Header INTO job_number_, field7_, field6_, field1_, field2_, field3_;
        CLOSE Check_AC_PO_Header;

        IF (job_number_ IS NULL) THEN
           v_error_message := 'MAR-MP066 #1' || p_action || ' #2PO Header A/C is missing';
           RAISE_APPLICATION_ERROR(-20000, v_error_message);
           RETURN 1;
        END IF;

        IF (field7_ IS NOT NULL) THEN
           --ORACLE
           IF (field7_ = 'Y') THEN
               v_error_message := 'MAR-MP001 #1' || p_action;
               RAISE_APPLICATION_ERROR(-20000, v_error_message);
               RETURN 1;
           END IF;
        ELSE
           IF (field6_ IS NOT NULL) THEN
           --OLIVES
              IF (field6_ = 'NO') THEN
                  v_error_message := 'MAR-MP001 #1' || p_action;
                  RAISE_APPLICATION_ERROR(-20000, v_error_message);
                  RETURN 1;
              END IF;
           END IF;

           IF (UPPER(field1_) LIKE '%DELETED%') THEN
              --JDE
              v_error_message := 'MAR-MP001 #1' || p_action;
              RAISE_APPLICATION_ERROR(-20000, v_error_message);
              RETURN 1;
           END IF;
        END IF;


        IF (field7_ IS NOT NULL) THEN
            acc_attr_value_ := 'ORACLE';
        ELSE
            IF (field6_ IS NOT NULL) AND (field6_ = 'YES' OR field6_ = 'NO') THEN
               acc_attr_value_ := 'OLIVES';
            ELSE
               acc_attr_value_ := 'JDE';
            END IF;
        END IF;
        
        check_mdr_fin_sys_ := 0;
        OPEN  Check_Req_MDR_Fin_Sys(v_base_poh_id);
        FETCH Check_Req_MDR_Fin_Sys INTO check_mdr_fin_sys_;
        CLOSE Check_Req_MDR_Fin_Sys;

        IF (check_mdr_fin_sys_ > 1) THEN
            v_error_message := 'MAR-MP066 #1' || p_action||' #2Mulitple Finance System exists in Req item for PO item';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;
        
        --INC1250217
        check_oc_mdr_fin_sys_ := 0;
        OPEN  Check_OC_MDR_Fin_Sys(v_base_poh_id);
        FETCH Check_OC_MDR_Fin_Sys INTO check_oc_mdr_fin_sys_, max_oc_mdr_fin_sys_;
        CLOSE Check_OC_MDR_Fin_Sys;

        IF (check_oc_mdr_fin_sys_ > 1) THEN
            v_error_message := 'MAR-MP066 #1' || p_action||' #2Mulitple A/C Finance System exists in Other Cost';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;
        
        
        IF (max_oc_mdr_fin_sys_ != acc_attr_value_) THEN
            v_error_message := 'MAR-MP066 #1' || p_action||' #2Other Cost Finance System must same with PO header';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;


        OPEN  Get_Req_MDR_Fin_Sys(v_base_poh_id);
        FETCH Get_Req_MDR_Fin_Sys INTO req_mdr_fin_sys_;
        CLOSE Get_Req_MDR_Fin_Sys;

        IF (acc_attr_value_ != req_mdr_fin_sys_) THEN
            v_error_message := 'MAR-MP066 #1' || p_action||' #2PO Finance System must same with Requisition';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;
        
 
        IF (acc_attr_value_ = 'ORACLE') THEN
            OPEN  Check_Req_Entity_Oracle(v_base_poh_id);
            FETCH Check_Req_Entity_Oracle INTO check_po_entity_;
            CLOSE Check_Req_Entity_Oracle;

            IF (NVL(field3_, '!@#') != NVL(check_po_entity_, '!@#$%')) THEN
                v_error_message := 'MAR-MP066 #1' || p_action||' #2PO A/C Entity must same with Requisition';
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;
        END IF;

        IF (acc_attr_value_ = 'OLIVES') THEN
            OPEN  Check_Req_Entity_Olives(v_base_poh_id);
            FETCH Check_Req_Entity_Olives INTO check_po_entity_;
            CLOSE Check_Req_Entity_Olives;

            IF (NVL(field1_, '!@#') != NVL(check_po_entity_, '!@#$%')) THEN
                v_error_message := 'MAR-MP066 #1' || p_action||' #2PO A/C Entity must same with Requisition';
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;
        END IF;


        IF (v_po_supp > 0) THEN
            v_header_prev_job_id_ := 0;
            OPEN  Check_Prev_AC(v_base_poh_id);
            FETCH Check_Prev_AC INTO v_header_prev_job_id_, prev_field3_, prev_field7_, prev_field6_, prev_field1_;
            CLOSE Check_Prev_AC;

            IF (
                (field7_ IS NULL AND prev_field7_ IS NOT NULL) OR
                (field7_ IS NOT NULL AND prev_field7_ IS NULL)
               ) THEN
                IF (v_job_id != v_header_prev_job_id_) THEN
                   v_error_message := 'MAR-MP066 #1' || p_action||' #2Account Code finance system must same with previous revision';
                   RAISE_APPLICATION_ERROR(-20000, v_error_message);
                   RETURN 1;
                END IF;
            END IF;

            IF (
                (field6_ IS NULL AND prev_field6_ IS NOT NULL) OR
                (field6_ IS NOT NULL AND prev_field6_ IS NULL)
               ) THEN
                IF (v_job_id != v_header_prev_job_id_) THEN
                   v_error_message := 'MAR-MP066 #1' || p_action||' #2Account Code finance system must same with previous revision';
                   RAISE_APPLICATION_ERROR(-20000, v_error_message);
                   RETURN 1;
                END IF;
            END IF;

            IF (acc_attr_value_ = 'ORACLE') THEN
                IF (field3_ != prev_field3_) AND (field3_ IS NOT NULL) AND (prev_field3_ IS NOT NULL) THEN
                   v_error_message := 'MAR-MP066 #1' || p_action||' #2Account Code must same entities with previous revision';
                   RAISE_APPLICATION_ERROR(-20000, v_error_message);
                   RETURN 1;
                END IF;
            END IF;

            IF (acc_attr_value_ = 'OLIVES') THEN
                IF (field1_ != prev_field1_) AND (field1_ IS NOT NULL) AND (prev_field1_ IS NOT NULL) THEN
                   v_error_message := 'MAR-MP066 #1' || p_action||' #2Account Code must same entities with previous revision';
                   RAISE_APPLICATION_ERROR(-20000, v_error_message);
                   RETURN 1;
                END IF;
            END IF;
        END IF;

        UPDATE m_sys.m_po_line_items
           SET job_id   = v_job_id
           WHERE poh_id = p_poh_id
           AND   job_id IS NULL;

        --RFERDIANTO: Other Cost and Job Number is Unique- if empty will get from Parent
        BEGIN         
            UPDATE m_sys.m_used_other_costs
                SET job_id    = v_job_id
                WHERE pk_id   = p_poh_id
                AND term_type = 'PO'
                AND job_id IS NULL;
        EXCEPTION
           WHEN OTHERS THEN NULL;
        END;

        check_poli_ac_  := 0;
        check_poli_ac2_ := 0;
        cnt_poli_id_    := 0;

        OPEN  Check_POLI_AC;
        FETCH Check_POLI_AC INTO cnt_poli_id_, check_poli_ac_, check_poli_ac2_;
        CLOSE Check_POLI_AC;

        IF ((cnt_poli_id_ > 0) AND
             ((check_poli_ac_ > 0 AND check_poli_ac_ != cnt_poli_id_)
              OR
             (check_poli_ac2_ > 0 AND check_poli_ac2_ != cnt_poli_id_))) THEN

           v_error_message := SUBSTR('MAR-MP066 #1' || p_action||' #2PO Item(s) having mulitple entities exists in A/C distribution', 1, 1000);
           RAISE_APPLICATION_ERROR(-20000, v_error_message);
           RETURN 1;
        END IF;



        IF (cnt_poli_id_ > 0) THEN
           poli_fin_sys_ := 0;

           IF (acc_attr_value_ = 'ORACLE') THEN
              OPEN  Check_IS_POLI_ORACLE;
              FETCH Check_IS_POLI_ORACLE INTO poli_fin_sys_;
              CLOSE Check_IS_POLI_ORACLE;

           ELSIF (acc_attr_value_ = 'JDE') THEN
              OPEN  Check_IS_POLI_JDE;
              FETCH Check_IS_POLI_JDE INTO poli_fin_sys_;
              CLOSE Check_IS_POLI_JDE;

           ELSE
              OPEN  Check_IS_POLI_OLIVES;
              FETCH Check_IS_POLI_OLIVES INTO poli_fin_sys_;
              CLOSE Check_IS_POLI_OLIVES;
           END IF;


           IF (cnt_poli_id_ != poli_fin_sys_) OR (poli_fin_sys_ = 0) THEN
               v_error_message := SUBSTR('MAR-MP066 #1' || p_action||' #2PO Header and Item(s) must have same entity', 1, 1000);
               RAISE_APPLICATION_ERROR(-20000, v_error_message);
               RETURN 1;
           END IF;
        END IF;


        po_any_spaces_ := 0;
        SELECT COUNT(1)
        INTO po_any_spaces_
        FROM m_sys.m_po_headers
        WHERE poh_id    = p_poh_id
        AND po_supp     = 0
        AND po_number LIKE '% %';

        IF po_any_spaces_ = 0 THEN
           NULL;
        ELSE
            v_error_message := SUBSTR('MAR-MP066 #1' || p_action||' #2PO Number cannot contains spaces, please update', 1, 1000);
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;



        get_acc_uval_id_      := 0;
        OPEN  Check_curr_MDR_FIN_SYS(v_proj_id, mdr_fin_sys_id_);
        FETCH Check_curr_MDR_FIN_SYS INTO get_acc_uval_id_;
        CLOSE Check_curr_MDR_FIN_SYS;

        IF (get_acc_uval_id_ IS NOT NULL) AND (get_acc_uval_id_ > 0) THEN
            UPDATE m_sys.m_used_values
               SET   attr_value = acc_attr_value_,
                     lock_ind   = 'Y'
               WHERE uval_id    = get_acc_uval_id_
               AND   NVL(attr_value, '~!@#$%^&*') != acc_attr_value_;
        ELSE
            INSERT INTO m_sys.m_used_values(uval_id, proj_id, used_type, pk_id, attr_id, attr_value, lock_ind)
                VALUES(M_SYS.M_SEQ_UVAL_ID.NEXTVAL, v_proj_id, 'PO', p_poh_id, mdr_fin_sys_id_, acc_attr_value_, 'Y');
        END IF;


        FOR rec_acc_ IN Get_POLI_ACC(mdr_fin_sys_id_) LOOP
            IF (rec_acc_.get_acc_uval_id IS NOT NULL) AND (rec_acc_.get_acc_uval_id > 0) THEN
                UPDATE m_sys.m_used_values
                   SET   attr_value = acc_attr_value_,
                         lock_ind   = 'Y'
                   WHERE uval_id    = rec_acc_.get_acc_uval_id
                   AND   NVL(attr_value, '~!@#$%^&*') != acc_attr_value_;
            ELSE
                INSERT INTO m_sys.m_used_values(uval_id, proj_id, used_type, pk_id, attr_id, attr_value, lock_ind)
                   VALUES(M_SYS.M_SEQ_UVAL_ID.NEXTVAL, v_proj_id, 'POLI', rec_acc_.poli_id, mdr_fin_sys_id_, acc_attr_value_, 'Y');
            END IF;
        END LOOP;


        COMMIT;

        SELECT MDR_CUST.MDR_GET_ATTR_VALUE(proj_id, p_poh_id, 'PO', 'MDR_FIN_SYS')
            INTO mdr_fin_sys_
            FROM m_sys.m_po_headers
            WHERE poh_id = p_poh_id;

        IF mdr_fin_sys_ IS NULL THEN
            v_error_message := 'MAR-MP066 #1' || p_action ||' #2Attribute value MDR_FIN_SYS in PO Header is missing, please change and select Account Code';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;


        IF (mdr_fin_sys_ = 'JDE') THEN

            IF (discount_percent_ > 0 AND discount_percent_ IS NOT NULL) OR (discount_amount_ > 0 AND discount_amount_ IS NOT NULL) THEN
                v_error_message := 'MAR-MP066 #1' || p_action ||' #2PO Header not allowed to have discount for JDE, please change discount to 0';
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;


            jde_ac_project_count_ := 0;

            SELECT COUNT(1)
            INTO jde_ac_project_count_
            FROM    (SELECT DISTINCT PROJECT
                    FROM m_abb_sys.SPM_JDE_INT_ACCOUNTS a,
                        (SELECT DISTINCT job_id
                        FROM m_sys.m_po_line_items i -- SC_0341  use MV view, not table to check whole PO, all supplements
                        WHERE poh_id IN (SELECT DISTINCT POH_ID
                                        FROM m_sys.m_po_headers
                                        WHERE base_poh_id = v_base_poh_id) -- Support center-0341
                        UNION
                        SELECT DISTINCT uoc.job_id
                        FROM m_sys.M_USED_OTHER_COSTS UOC
                        WHERE uoc.PK_ID IN (SELECT DISTINCT POH_ID
                                            FROM m_sys.m_po_headers
                                            WHERE base_poh_id = v_base_poh_id) -- Support center-0341
                        AND term_type = 'PO') i,
                        m_sys.m_jobs j
                    WHERE a.account = j.job_number
                    AND j.job_id    = i.job_id);

            IF jde_ac_project_count_ > 1 THEN
                v_error_message := 'MAR-MP066 #1' || p_action ||' #2Multiple account projects per PO not allowed';
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

        ELSIF (mdr_fin_sys_ = 'ORACLE') THEN
            oracle_entity_ := 0;
            SELECT COUNT(1)
            INTO oracle_entity_
            FROM (SELECT DISTINCT j.field3 field3 FROM m_sys.m_po_headers r,   m_jobs j WHERE r.poh_id = p_poh_id AND r.job_id = j.job_id
                  UNION
                  SELECT DISTINCT j.field3 field3 FROM m_sys.m_po_line_items r, m_jobs j WHERE r.poh_id = p_poh_id AND r.job_id = j.job_id);

            IF (NVL(oracle_entity_, 0) > 1) THEN
                v_error_message := 'MAR-MP008 #1' || p_action;
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

        ELSIF (mdr_fin_sys_ = 'OLIVES') THEN
            olives_entity_ := 0;
            SELECT COUNT(1)
            INTO olives_entity_
            FROM (SELECT DISTINCT j.field1 field1 FROM m_sys.m_po_headers r,   m_jobs j WHERE r.poh_id = p_poh_id AND r.job_id = j.job_id
                  UNION
                  SELECT DISTINCT j.field1 field1 FROM m_sys.m_po_line_items r, m_jobs j WHERE r.poh_id = p_poh_id AND r.job_id = j.job_id);

            IF (NVL(olives_entity_, 0) > 1) THEN
                v_error_message := 'MAR-MP008 #1' || p_action;
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;
        END IF;


        total_po_line_items_ := 0;
        SELECT    COUNT(*)
        INTO    total_po_line_items_
        FROM    mvp_poli_workload
        WHERE    poh_id IN (SELECT poh_id FROM m_po_headers WHERE base_poh_id = (SELECT base_poh_id FROM m_po_headers WHERE poh_id = p_poh_id));

        IF (total_po_line_items_ = 0) THEN
            v_error_message := 'MAR-MP066 #1' || p_action ||' #2PO must have line item(s)';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        ELSE
            IF (mdr_fin_sys_ = 'ORACLE') OR (mdr_fin_sys_ = 'OLIVES') THEN
                IF total_po_line_items_ >= 800 THEN
                    v_error_message := 'MAR-MP069 #1' || p_action;
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;
            END IF;
        END IF;


        -- Check PO number to be max 22 positions when old project, for all projects since 01-sep-2013 length may be 25
        IF len_po_num_ > 25 THEN
            v_error_message := 'MAR-MP066 #1' || p_action || ' #2PO Number cannot longer than 25 chars';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;


        po_nls_ := 0;
        OPEN  Check_PO_NLS;
        FETCH Check_PO_NLS INTO po_nls_;
        CLOSE Check_PO_NLS;

        IF (po_nls_ = 0) OR (po_nls_ IS NULL) THEN
            v_error_message := 'MAR-MP011 #1' || p_action || ' #2PO Header Short and Description is missing';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;


        IF len_client_po_number_ > 25 THEN
            v_error_message := 'MAR-MP011 #1' || p_action || '#2Client PO Number cannot longer than 25 char';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;


        IF (v_po_supp = 0) THEN
            --Only for PO revision 0
            IF (len_client_po_number_ > 0) AND (len_client_po_number_ IS NOT NULL) THEN
                l_unprintable_ := 0;
                IF len_client_po_number_ > 0 THEN
                    FOR i IN 1 .. len_client_po_number_ LOOP
                        IF ASCII(SUBSTR(client_po_number_, i)) < 32 OR ASCII(SUBSTR(client_po_number_, i)) > 126 THEN
                            l_unprintable_ := l_unprintable_ + 1;
                      END IF;
                    END LOOP;
                END IF;

                IF l_unprintable_ > 0 THEN
                    v_error_message := 'MAR-MP011 #1' || p_action || '#2Client PO Number has unprintable chars, please update';
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;
            END IF;


            IF (len_po_num_ > 0) AND (len_po_num_ IS NOT NULL) THEN
                l_unprintable_ := 0;
                IF len_po_num_ > 0 THEN
                    FOR i IN 1 .. len_po_num_ LOOP
                        IF ASCII(SUBSTR(v_po_number, i)) < 32 OR ASCII(SUBSTR(v_po_number, i)) > 126 THEN
                            l_unprintable_ := l_unprintable_ + 1;
                      END IF;
                    END LOOP;
                END IF;

                IF l_unprintable_ > 0 THEN
                    v_error_message := 'MAR-MP011 #1' || p_action || '#PO Number has unprintable chars, please update';
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;
            END IF;


        ELSE
            prev_po_number_ := '!@#$%^&*';
            OPEN  Get_Prev_PO_No;
            FETCH Get_Prev_PO_No INTO prev_po_number_;
            CLOSE Get_Prev_PO_No;

            IF v_po_number <> prev_po_number_ THEN
                v_error_message := 'MAR-MP011 #1' || p_action || '#2PO Number cannot be changed, please use previous PO Number: '||prev_po_number_;
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;
        END IF;


        po_desc_len_   := 0;
        po_short_len_  := 0;
        po_desc_       := '';
        po_short_      := '';

        OPEN  Check_PO_Desc_Char;
        FETCH Check_PO_Desc_Char INTO po_desc_len_, po_desc_, po_short_len_, po_short_;
        CLOSE Check_PO_Desc_Char;

        IF (po_desc_len_ > 0) AND (po_desc_len_ IS NOT NULL) THEN
            l_unprintable_ := 0;
            FOR I IN 1 .. po_desc_len_ LOOP
                IF ASCII(SUBSTR(po_desc_, i)) < 32 OR ASCII(SUBSTR(po_desc_, i)) > 126 THEN
                    l_unprintable_ := l_unprintable_ + 1;
                END IF;
            END LOOP;

            IF l_unprintable_ > 0 THEN
                v_error_message := 'MAR-MP011 #1' || p_action || '#2PO Description has unprintable chars, please update';
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;
        END IF;

        IF (po_short_len_ > 0) AND (po_short_len_ IS NOT NULL) THEN
            l_unprintable_ := 0;
            FOR I IN 1 .. po_short_len_ LOOP
                IF ASCII(SUBSTR(po_short_, i)) < 32 OR ASCII(SUBSTR(po_short_, i)) > 126 THEN
                    l_unprintable_ := l_unprintable_ + 1;
                END IF;
            END LOOP;

            IF l_unprintable_ > 0 THEN
                v_error_message := 'MAR-MP011 #1' || p_action || '#2PO Short Description has unprintable chars, please update';
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;
        END IF;


        SELECT MDR_CUST.MDR_GET_ATTR_VALUE(proj_id, poh_id, 'PO', 'BUDGET_PROVIDED')
            INTO attr_budget_
            FROM m_sys.m_po_headers
            WHERE poh_id = p_poh_id;


        IF (attr_budget_ IS NOT NULL) THEN
            IF (attr_budget_ = 'Y') AND (po_budget_ IS NULL OR po_budget_ = 0) THEN
                v_error_message := 'MAR-MP066 #1' || p_action || '#2Please Enter Budget because Budget Provided is Y';
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            ELSIF (attr_budget_ = 'N') AND (po_budget_ <> 0) THEN
                v_error_message := 'MAR-MP066 #1' || p_action || '#2Please Change Budget Provided to Y because Budget > 0';
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;
        ELSE
            v_error_message := 'MAR-MP066 #1' || p_action || '#2Budget Provided is not Y or N, please update';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;

      -- PO exped/insp level  INC1109215/INC1214827
        select nvl(EXPED_ILV_ID, 0),nvl(ILV_ID, 0)
         into l_exped_lv, l_insp_lv
          from m_sys.m_po_headers poh
         where poh.poh_id = p_poh_id;
         IF l_exped_lv = 0 then
           v_error_message := 'MAR-MP011 #1' || p_action || '#2Expediting level is null.' ;  -- Agreement cannot be approved as expedite level is not specified
           RAISE_APPLICATION_ERROR(-20000, v_error_message);
           RETURN 1;
         END IF;

         IF l_insp_lv = 0 then
           v_error_message := 'MAR-MP011 #1' || p_action || '#2.Inspection level is null.' ;  -- Agreement cannot be approved as inspection level is not specified
           RAISE_APPLICATION_ERROR(-20000, v_error_message);
           RETURN 1;
         END IF;
        --

        IF (mdr_fin_sys_ = 'JDE') THEN
            l_cbi_po_ := 'Y';
            BEGIN
                SELECT NVL(SUBSTR(MIN(d.parm_value), 1, 1), 'Y')
                    INTO l_cbi_po_
                    FROM m_sys.M_APPL_PARM p, m_sys.m_ppd_defaults d, m_sys.m_po_headers poh
                    WHERE p.parm_id = d.parm_id
                    AND p.parm_code = 'ZP_CBI_PO'
                    AND parm_value != './.'
                    AND nvl(d.dp_id, poh.dp_id) = poh.dp_id
                    AND d.proj_id  = poh.proj_id
                    AND poh.poh_id = p_poh_id;
            EXCEPTION
                WHEN no_data_found THEN
                    l_cbi_po_ := 'Y';
            END;

            IF l_cbi_po_ = 'Y' AND v_po_number LIKE '%-MR-%' THEN
                v_error_message := 'MAR-MP011 #1' || p_action || '#2PO-Number contains -MR- that indicates req, requery and change';
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;



            IF v_order_type <> 'SC' THEN
                -- PLF-0087 do not test this on sub-contracts
                l_exped_ilv_id_ := 0;
                l_ilv_id_       := 0;

                --RFERDIANTO 15-SEP-2021
                OPEN  Check_Expediting_Level;
                FETCH Check_Expediting_Level INTO l_exped_ilv_id_, l_ilv_id_;
                CLOSE Check_Expediting_Level;

                IF (l_exped_ilv_id_ = 5694) AND (l_exped_ilv_id_ IS NOT NULL) THEN
                    -- 5694=DEFAULT
                    v_error_message := 'MAR-MP011 #1' || p_action || '#2Retired Expediting Level found, please change.';
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;

                IF (l_ilv_id_ = 5695) AND (l_ilv_id_ IS NOT NULL) THEN
                    -- 5695=DEFAULT
                    v_error_message := 'MAR-MP011 #1' || p_action || '#2Retired Inspection Level found, please change.';
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;
            END IF;


    -- Check Routing Method is entered or not -- THUA TASK0139926

        v_error_message := 'Routing Method not found';
        v_poli_pos := 0;
            SELECT MIN(p.poli_pos)
            INTO v_poli_pos
            FROM m_sys.m_item_ships s, m_sys.m_po_line_items p
            WHERE s.poli_id IN (SELECT MAX(i.poli_id) poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL GROUP BY i.parent_poli_id
                               UNION
                               SELECT i.poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NULL
                               MINUS
                               SELECT DISTINCT i.parent_poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL)
                AND s.rm_id IS NULL
                AND s.poli_id = p.poli_id;

            IF v_poli_pos IS NOT NULL THEN
                v_error_message := 'MAR-MP038 #1' || p_action || '#2Routing Method is#3' || v_poli_pos;  -- Agreement cannot be approved as Routing Method is not specified for item
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

----

            jde_int_flag_ := 0;
            SELECT COUNT(1)
                INTO jde_int_flag_
                FROM m_abb_sys.spm_jde_project_defaults jpd,
                     m_sys.m_po_headers poh
                WHERE jpd.proj_id          = poh.proj_id
                AND jpd.jde_interface_flag = 'Y'
                AND poh.poh_id             = p_poh_id;

            If jde_int_flag_ > 0 THEN

                SELECT counterpart
                    INTO counterpart_
                    FROM m_abb_sys.spm_jde_project_defaults jpd,
                        m_sys.m_po_headers poh
                    WHERE jpd.proj_id = poh.proj_id
                    AND poh.poh_id    = p_poh_id;

                -- Project or Discipline deafult set to NO ?
                BEGIN
                    jde_disc_int_ := 'N';

                    SELECT UPPER(MIN(d.parm_value))
                        INTO jde_disc_int_
                        FROM m_sys.m_appl_parm p, m_sys.m_ppd_defaults d
                        WHERE p.parm_id = d.parm_id
                        AND p.parm_code = 'ZJ_JDE_INT'
                        AND parm_value != './.'
                        AND NVL(d.dp_id, v_dp_id) = v_dp_id
                        AND d.proj_id  = v_proj_id;

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        jde_disc_int_ := 'Y';
                END;


                IF jde_disc_int_ = 'Y' THEN
                    BEGIN
                        interface_switch_po_ := NULL;

                        SELECT v.attr_value
                            INTO interface_switch_po_
                            FROM m_sys.m_used_values v
                            WHERE v.used_type = 'PO'
                            AND v.pk_id       = p_poh_id
                            AND v.attr_id     = (SELECT attr_id FROM m_sys.m_attrs WHERE attr_code = 'JDE_INTF_PO');

                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                        interface_switch_po_ := NULL;
                    END;


                    IF NVL(interface_switch_po_, 'NULL') NOT IN ('Y', 'N') then
                        v_error_message := 'MAR-MP066 #1' || p_action || '#2Attribute JDE_INTF_PO must set with value Y or N';
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;


                    IF interface_switch_po_ = 'Y' THEN
                        l_pos_subpos_count_ := 0;

                        SELECT COUNT(1)
                            INTO l_pos_subpos_count_
                            FROM m_sys.m_po_line_items poli
                            WHERE poli.poh_id = p_poh_id
                            AND (poli.poli_pos > 949 OR poli.poli_sub_pos > 999)
                            AND poli.poli_unit_price <> 0.0;

                        IF (l_pos_subpos_count_ > 0) AND (l_pos_subpos_count_ IS NOT NULL) THEN
                            v_error_message := 'MAR-MP066 #1' || p_action ||' #2 PO line items cannot more than 949 ';
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;



                        -- Support_Center_0368
                        -- check attribute JDE_PURCH_CONTRACT is overwrite contract,
                        -- when value exists then update all accounts on po-lines and other_cost
                        BEGIN
                            SELECT NVL(v.attr_value, 'X')
                                INTO purchase_contract_
                                FROM m_sys.m_used_values v
                                WHERE v.used_type = 'PO'
                                AND v.pk_id       = p_poh_id
                                AND v.attr_id     = (SELECT attr_id FROM m_sys.m_attrs WHERE attr_code = 'JDE_PURCH_CONTRACT');
                        EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                                purchase_contract_ := 'X';
                        END;


--Ruby need to check with Robert about JDE_PURCH_CONTRACT should we just disabled because it is updating the account code in PO item and Other Cost also
                        IF purchase_contract_ <> 'X' THEN
                            -- first see if it deviates from suppl 0, is not allowed
                            SELECT NVL(v.attr_value, 'X')
                                INTO prior_contract_
                                FROM m_sys.m_used_values v
                                WHERE v.used_type = 'PO'
                                AND v.pk_id       = v_base_poh_id
                                AND v.attr_id     = (SELECT attr_id FROM m_sys.m_attrs WHERE attr_code = 'JDE_PURCH_CONTRACT');


                            IF purchase_contract_ <> prior_contract_ THEN
                                v_error_message := 'MAR-MP066 #1' || p_action ||' #2Override Contract is not equal to value on prior supplements ';
                                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                RETURN 1;
                            END IF;

                            -- value given and equal to earlier value, need to check and update the po-lines and other_cost
                            l_replace_acc1_ := -1;
                            l_replace_acc2_ := 0;

                            FOR c1r IN c1 LOOP
                                -- check and update po_lines
                                l_job_id_ := 0;

                                IF c1r.account LIKE purchase_contract_ || '%' THEN
                                    NULL; -- no need to update, account belongs to purchase contract
                                ELSE
                                    l_replace_acc1_ := 1;

                                    SELECT job_id
                                    INTO l_job_id_
                                    FROM m_sys.m_jobs
                                    WHERE job_number = REPLACE(c1r.account, SUBSTR(c1r.account, 1, INSTR(c1r.account, '.') - 1), purchase_contract_)
                                    AND proj_id      = c1r.proj_id;

                                    IF l_job_id_ > 0 THEN
                                        UPDATE m_sys.m_po_line_items
                                        SET job_id    = l_job_id_
                                        WHERE poli_id = c1r.poli_id;
                                    ELSE
                                        l_replace_acc2_ := l_replace_acc2_ + 1;
                                    END IF;
                                END IF;
                            END LOOP;


                            FOR c2r IN c2 LOOP
                                -- now check and update other_cost
                                l_job_id_ := 0;
                                IF c2r.account LIKE purchase_contract_ || '%' THEN
                                    NULL; -- no need to update, account belongs to purchase contract
                                ELSE
                                    SELECT job_id
                                    INTO l_job_id_
                                    FROM m_sys.m_jobs
                                    WHERE job_number = REPLACE(c2r.account, SUBSTR(c2r.account, 1, INSTR(c2r.account, '.') - 1), purchase_contract_)
                                    AND proj_id      = c2r.proj_id;

                                    IF l_job_id_ > 0 THEN
                                        UPDATE m_sys.m_used_other_costs
                                            SET job_id   = l_job_id_
                                            WHERE uoc_id = c2r.uoc_id;
                                    ELSE
                                        l_replace_acc2_    := l_replace_acc2_ + 1;
                                        l_missing_account_ := REPLACE(c2r.account, SUBSTR(c2r.account, 1, INSTR(c2r.account, '.') - 1), purchase_contract_);
                                    END IF;
                                END IF;
                            END LOOP;


                            IF l_replace_acc1_ > 0 THEN
                                -- override to be done
                                IF l_replace_acc2_ > 0 THEN
                                    -- not all accounts where found
                                    v_error_message := 'MAR-MP066 #1' || p_action ||' #2WARNING-Override Contract applied but not all replacement accounts found';
                                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                    RETURN 1;
                                END IF;
                            END IF;
                        END IF;--END SC-0368


                        IF v_order_type <> 'SC' THEN

                            BEGIN
                                SELECT attr_value
                                    INTO match_type_now_
                                    FROM m_sys.m_used_values v
                                    WHERE v.used_type = 'PO'
                                    AND v.pk_id       = p_poh_id
                                    AND v.attr_id     = (SELECT attr_id FROM m_sys.m_attrs WHERE attr_code = 'JDE_MATCH_TYPE');

                            EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                    v_error_message := 'MAR-MP066 #1' || p_action ||' #2Attribute AP Match Type (JDE_MATCH_TYPE) is missing  ';
                                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                    RETURN 1;
                            END;

                            SELECT attr_value
                                INTO match_type_init_
                                FROM m_sys.m_used_values v
                                WHERE v.used_type = 'PO'
                                AND v.pk_id       = v_base_poh_id
                                AND v.attr_id     = (SELECT attr_id FROM m_sys.m_attrs WHERE attr_code = 'JDE_MATCH_TYPE');

                            IF match_type_now_ <> match_type_init_ THEN
                                v_error_message := 'MAR-MP066 #1' || p_action ||' #2Attribute AP Match Type (JDE_MATCH_TYPE) cannot be change on the revision';
                                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                RETURN 1;
                            END IF;
                        END IF;

                        --Ruby not requires as PO Number is generated automatically
                        --                            SELECT COUNT(*)
                        --                            INTO l_used_before_count
                        --                            FROM m_abb_sys.spm_jde_int_F4301z1       z,
                        --                                  m_abb_sys.spm_jde_int_process_items i
                        --                            WHERE z.vr01 IN ((SELECT po_number
                        --                                              FROM m_sys.m_po_headers
                        --                                             WHERE poh_id = p_poh_id),
                        --                                            (SELECT po_number || '-00'
                        --                                               FROM m_sys.m_po_headers
                        --                                              WHERE poh_id = p_poh_id))
                        --                            AND z.record_id <> (SELECT base_poh_id
                        --                                   FROM m_sys.m_po_headers
                        --                                  WHERE poh_id = p_poh_id)
                        --                            AND i.process_id = z.process_id
                        --                            AND i.status = 'C'; -- Support center-0341
                        --
                        --                            IF l_used_before_count > 0 THEN
                        --                                v_error_message := 'MAR-MP066 #1' || p_action ||' #2This PO-Number has been used before, requery and modify.';
                        --                                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        --                                RETURN 1;
                        --                            END IF;

                        --A JDE_Vendor_id must be found for the SPM Vendor and Currency_code of the POother
                        BEGIN
                            jde_vendorid_ := 0;

                            SELECT NVL(sjv.jde_vendor_id, 0)
                                INTO jde_vendorid_
                                FROM m_abb_sys.spm_jde_vendors sjv,
                                     m_sys.m_po_headers        poh,
                                     m_sys.m_units             c
                                WHERE sjv.company_id  = poh.company_id
                                AND sjv.currency_code = c.unit_code
                                AND c.unit_id         = poh.currency_id
                                AND poh.poh_id        = p_poh_id
                                AND NVL(sjv.counterpart, 'CBI') = counterpart_;
                        EXCEPTION
                            WHEN OTHERS THEN
                                jde_vendorid_ := 0;
                        END;

                        IF jde_vendorid_ <> 0 THEN
                            NULL;
                        ELSE
                            v_error_message := 'MAR-MP066 #1' || p_action || '#2Valid JDE VendorID not found or duplicate exists';
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;



                        --A JDE_Buyer_id must be found for the SPM Buyer on the PO
                        IF counterpart_ LIKE 'CBI%' THEN
                            -- sc_0368  other parties do not neet buyer_id
                            BEGIN
                                jde_buyerid_ := 0;
                                SELECT NVL(jde_buyer_id, 0)
                                    INTO jde_buyerid_
                                    FROM m_abb_sys.spm_jde_buyers sjb, m_sys.m_po_headers poh
                                    WHERE sjb.spm_buyer = poh.buyer
                                    AND poh.poh_id      = p_poh_id;
                            EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                jde_buyerid_ := 0;
                            END;

                            IF jde_buyerid_ <> 0 THEN
                                NULL; --PCEZ
                            ELSE
                                v_error_message := 'MAR-MP066 #1' || p_action || '#2Buyer is not registered with in SPM_JDE_BUYERS table';
                                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                RETURN 1;
                            END IF;
                        END IF;


                        --A Valid Match_Type must be found for the PO
                        -- SC_0368  changed from LS and PP to 2W
                        IF v_order_type <> 'SC' THEN
                            -- PLF-0087 do not test this on sub-contracts, set for INCOTERM, DELPLACE Aand ROUTING METHOD
                            BEGIN
                                SELECT NVL(v.attr_value, 'X')
                                    INTO jde_match_type_
                                    FROM m_sys.m_used_values v,
                                         m_sys.m_po_headers  poh,
                                         m_sys.m_attrs       a
                                    WHERE v.used_type = 'PO'
                                    AND v.pk_id       = poh.poh_id
                                    AND a.attr_id     = v.attr_id
                                    AND a.attr_code   = 'JDE_MATCH_TYPE'
                                    AND UPPER(attr_value) IN ('2W', '3W')
                                    AND poh.poh_id    = p_poh_id;
                            EXCEPTION
                                WHEN NO_DATA_FOUND then
                                    jde_match_type_ := 'X';
                                NULL;
                            END;

                            IF jde_match_type_ = 'X' THEN
                                v_error_message := 'MAR-MP066 #1' || p_action || '#2Attribute AP Match Type (JDE_MATCH_TYPE) is missing';
                                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                RETURN 1;
                            END IF;
                        END IF;


                        -- On 2W match we want to see at least 1 progress payment line
                        IF v_order_type <> 'SC' THEN
                            -- PLF-0087 do not test this on sub-contracts, set for INCOTERM, DELPLACE Aand ROUTING METHOD
                            prog_payments_ := 0;

                            SELECT COUNT(1)
                                INTO prog_payments_
                                FROM m_sys.m_att_ppes
                                WHERE pk_type = 'POH'
                                AND pk_id     = p_poh_id;

                            IF jde_match_type_ = '2W' AND prog_payments_ = 0 THEN
                                v_error_message := 'MAR-MP066 #1' || p_action || '#2Attribute AP Match Type (JDE_MATCH_TYPE) 2W but no Progress Payment Lines exist';
                                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                RETURN 1;
                                RAISE_APPLICATION_ERROR(-20000,
                                      'ERROR- MatchType 2W but no Progress Payment Lines exist.');
                                RETURN 1;
                            END IF;

                            IF jde_match_type_ = '3W' AND prog_payments_ > 0 THEN
                                v_error_message := 'MAR-MP066 #1' || p_action || '#2Attribute AP Match Type (JDE_MATCH_TYPE) 3W while Progress Payment Lines exist';
                                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                RETURN 1;
                            END IF;
                        END IF;


                        -- Now test on PO and OC cost value lower than paid amount in JDE, if then block approval
                        -- only do for 2way match order ..SC_0537 // CBI137555
                        IF jde_match_type_ = '2W' THEN
                            tot_spm_amount_ := 0;
                            paid_amount_    := 0;

                            SELECT tot_matl_cost
                                INTO tot_spm_amount_
                                FROM m_sys.m_po_headers
                                WHERE poh_id = p_poh_id;

                            SELECT NVL(number_value,0)
                                INTO paid_amount_
                                FROM m_sys.m_used_values v
                                WHERE v.used_type = 'PO'
                                AND v.pk_id       = p_poh_id
                                AND v.attr_id     = (SELECT attr_id FROM m_sys.m_attrs WHERE attr_code = 'JDE_PAID_AMOUNT');

                            IF paid_amount_ > tot_spm_amount_ THEN
                                v_error_message := 'MAR-MP066 #1' || p_action || '#2Attribute JDE Paid amount > New SPM PO total amount';
                                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                RETURN 1;
                            END IF;
                        END IF;

                        -- Valid AP_Payment_Terms_code
                        BEGIN
                            SELECT NVL(v.attr_value, 'X')
                                INTO payment_terms_
                                FROM m_sys.m_used_values v
                                WHERE v.used_type = 'PO'
                                AND v.pk_id       = p_poh_id
                                AND v.attr_id     = (SELECT attr_id FROM m_sys.m_attrs WHERE attr_code = 'JDE_PAY_TERMS');
                        EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                                payment_terms_ := 'X';
                        END;

                        IF payment_terms_ <> 'X' THEN
                            NULL; --PCEZ
                        ELSE
                            v_error_message := 'MAR-MP066 #1' || p_action || '#2Attribute AP Pay Terms (JDE_PAY_TERMS) is missing';
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;

                        -- Other cost may only be created at the PO_header level
                        other_costs_ := 0;
                        SELECT NVL(MIN(poli_pos), 0)
                            INTO other_costs_
                            FROM m_sys.m_used_other_costs o, m_sys.m_po_line_items i
                            WHERE i.poh_id  = p_poh_id
                            AND o.pk_id     = i.poli_id
                            AND o.term_type = 'PLI';

                        IF (other_costs_ = 0) OR (other_costs_ IS NULL)THEN
                            NULL; --PCEZ
                        ELSE
                            v_error_message := 'MAR-MP066 #1' || p_action || '#2Other Cost found on PO Item POS:'||other_costs_;
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;

                        -- Other cost may not exceed 999 lines
                        other_costs_count_ := 0;
                        SELECT COUNT(*)
                            INTO other_costs_count_
                            FROM m_sys.m_used_other_costs o, m_sys.m_po_line_items i
                            WHERE i.poh_id  = p_poh_id
                            AND o.pk_id     = i.poli_id
                            AND o.term_type = 'PO';

                        IF other_costs_count_ < 1000 THEN
                            NULL;
                        ELSE
                            v_error_message := 'MAR-MP066 #1' || p_action || '#2Too many Other Cost lines, max 999';
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;

                        --SC_0368 PCEZ Apr-2014
                        --Test on Supplier updated
                        sup_use_count_ := 0;
                        SELECT COUNT(*)
                            INTO sup_use_count_
                            FROM m_abb_sys.spm_jde_int_F4301z1
                            WHERE an8 <> jde_vendorid_
                            AND record_id = v_base_poh_id;

                        IF sup_use_count_ > 0 THEN
                            v_error_message := 'MAR-MP066 #1' || p_action || '#2Supplier change, update in JDE, then ask Support to Sync hist in SPM';
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;

                        --Test on Currency updated
                        SELECT unit_code
                        INTO l_currency_code
                        FROM m_sys.m_units
                        WHERE unit_id = (SELECT currency_id
                                        FROM m_sys.m_po_headers
                                        WHERE poh_id = p_poh_id);

                        l_cur_use_count := 0;
                        SELECT COUNT(1)
                        INTO l_cur_use_count
                        FROM m_abb_sys.spm_jde_int_F4301z1
                        WHERE CRCD <> m_pck_po_custom.convert_unit(v_proj_id, l_currency_code)
                        AND record_id = v_base_poh_id;

                        IF l_cur_use_count > 0 THEN
                            -- other currency used before
                            v_error_message := 'MAR-MP066 #1' || p_action || '#2Currency changed, update in JDE, then ask Support to Sync history in SPM';
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;
                        -- end of SC_0368

                        -- SC_0491  test po lines UOM on validity using function convert_unit
                        l_line_count_ := 0;
                        SELECT COUNT(1)
                            INTO l_line_count_
                            FROM m_sys.m_po_line_items pol, m_sys.m_units u
                            WHERE pol.poh_id = p_poh_id
                            AND u.unit_id    = pol.qty_unit_id
                            AND m_pck_po_custom.convert_unit(pol.proj_id, u.unit_code) = 'XXX';

                        IF l_line_count_ > 0 THEN
                            v_error_message := 'MAR-MP066 #1' || p_action || '#2Invalid UOM found, contact support';
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;
                    END IF;
                END IF;   --ZJ_JDE_INT
            END IF; --JDE Interface Flag

        END IF;  --End JDE



--        -- Check PO items max allowed range  -- MZZZ
--        v_error_message := 'Check PO items max allowed range';
--
--        SELECT MAX(POLI.POLI_POS)   -- get the max poli pos count
--            INTO v_poli_count
--            FROM M_SYS.MV_ORDER_HEADERS POH, M_SYS.MV_ORDER_LINE_ITEMS POLI
--            WHERE POH.POH_ID = POLI.POH_ID
--            AND POH.PROJ_ID  = POLI.PROJ_ID
--            AND POH.POH_ID   = v_base_poh_id;  -- this is based on base table
--
--        IF NVL(v_poli_count, 0) > 800 THEN
--            v_error_message := 'MAR-MP069 #1' || p_action;
--            RAISE_APPLICATION_ERROR(-20000, v_error_message);
--            RETURN 1;
--        END IF;

        -- Check PO items max allowed range  -- MZ  ends here
/******Obsolete code for 8.x - 01/15/20 - CG *********************************************************************
        IF (v_base_order_type <> 'BO') AND (v_base_order_sub_type NOT IN ('MA', 'SV')) THEN

      IF v_project_type = 'PROJECT' THEN
                -- Corporate Warehouse Agreement (sup_id = 100) does not have entity in agreement number
                IF NVL(INSTR(v_po_number, '-',1, 2), 0) > 0 AND NVL(v_sup_id, 0) <> 100 THEN
                    v_po_number_entity := SUBSTR(v_po_number, INSTR(v_po_number, '-', 1, 2) + 1, 4);
                END IF;
            ELSE
                -- Corporate Warehouse Agreement (sup_id = 100) does not have entity in agreement number
                IF NVL(v_sup_id, 0) <> 100 THEN
                    v_po_number_entity := SUBSTR(v_po_number, 1, 4);
                END IF;
            END IF;

            -- Default the Header A/C Distribution entity as the Header entity to cater for CWH
            IF NVL(v_po_number_entity, '#$%') = '#$%' THEN
                v_po_number_entity := v_entity;
            END IF;

            IF NVL(v_po_number_entity, '#$%') = '#$%' THEN
                v_error_message := 'MAR-MP032 #1' || p_action || ' #2' || v_po_number || ' or header A/C Dist';  -- Agreement cannot be approved as it does not have an entity in the number
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

            v_error_message := 'MDR_ENTITY table not found';
            v_pomfloc := NULL;
            -- Check if MDR_ENTITY table is setup
            SELECT MAX(tab_id)
              INTO v_tab_id
              FROM m_sys.m_dict_tabs
             WHERE proj_id = 'GLOBAL'
               AND table_name = 'MDR_ENTITY';

            -- Check if Entity is valid
            IF NVL(v_tab_id, 0) = 0 THEN
                v_error_message := 'MAR-MP058 #1' || p_action;   -- Agreement cannot be approved as table MDR_ENTITY is not setup
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

            IF NVL(v_po_number_entity, '#$%') <> '#$%' THEN
                v_error_message := 'G/L Area not found for ' || v_po_number_entity;
                v_gl_area := get_table_detail_attribute('GLOBAL', 'MDR_ENTITY', 'LEGACY_GLAREA', 'ALL', v_po_number_entity);

                -- Check if G/L Area setup
                IF NVL(v_gl_area, '#$%') = '#$%' THEN
                    v_error_message := 'MAR-MP059 #1' || p_action || ' #2G/L Area for entity ' || v_po_number_entity;  -- Agreement cannot be approved as entity is not setup in S.20.02 MDR_ENTITY table
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;
            END IF;

            -- Check MDR_GL_AREA table is setup
            v_error_message := 'MDR_GL_AREA table not found';
            v_tab_id := 0;
            SELECT MAX(tab_id)
              INTO v_tab_id
              FROM m_sys.m_dict_tabs
             WHERE proj_id = 'GLOBAL'
               AND table_name = 'MDR_GL_AREA';

            -- Check if POMFLOC is defined for G/L Area
            IF NVL(v_tab_id, 0) = 0 THEN
                v_error_message := 'MAR-MP060 #1' || p_action;  -- Agreement cannot be approved as table MDR_GL_AREA is not setup
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

            v_error_message := 'POMFLOC not found for G/L Area ' || v_gl_area;
            v_pomfloc := get_table_detail_attribute('GLOBAL', 'MDR_GL_AREA', 'LEGACY_POMFLOC', 'ALL', v_gl_area);

            IF NVL(v_pomfloc, '#$%') = '#$%' THEN
                v_error_message := 'MAR-MP061 #1' || p_action || ' #2POMFLOC for G/L Area ' || v_gl_area;  -- Agreement cannot be approved as pomfloc not defined for G/L Area in S.20.02 MDR_GL_AREA table
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;
    END IF;
    ******************************************************************************* ***/

        -- Added by McDermott to check if values of Oracle Interfacec attributes exists or not.

        IF NVL(v_buyer, '#$%') = '#$%' THEN
            v_error_message := 'MAR-MP035 #1' || p_action;  -- Agreement cannot be approved as it does not have a Buyer
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;

        buyer_active_ := 0;
        OPEN  Check_Buyer_Active(v_proj_id, v_buyer);
        FETCH Check_Buyer_Active INTO buyer_active_;
        CLOSE Check_Buyer_Active;

        IF (buyer_active_ = 0) OR (buyer_active_ IS NULL) THEN
             v_error_message := 'MAR-MP066 #1' || p_action || '#2Buyer is NOT active user, please change';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;

        IF NVL(v_currency_id, 0) = 0 THEN
            v_error_message := 'MAR-MP036 #1' || p_action;  -- Agreement cannot be approved as Currency is not specified
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;


        v_error_message := 'Item ' || v_poli_pos || ' currency does not match PO currency';
        -- Check if Item currency matches PO Currency
        BEGIN
            v_poli_pos := 0;
            SELECT MAX(poli_pos)
              INTO v_poli_pos
              FROM m_sys.m_po_line_items
             WHERE poh_id = p_poh_id
               AND currency_id <> v_currency_id;

            IF NVL(v_poli_pos, 0) <> 0 THEN
                v_error_message := 'MAR-MP054 #1' || p_action || ' #2' || v_poli_pos;  -- Agreement cannot be approved as Currency is not specified
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
            NULL;
        END;


        -- Account Code on Other Cost lines
        l_poli_account := 0;
        SELECT COUNT(*)
            INTO l_poli_account
            FROM m_sys.m_used_other_costs uoc
            WHERE uoc.pk_id   = p_poh_id
            AND uoc.term_type = 'PO'
            AND job_id IS NULL;

        IF l_poli_account > 0 THEN
            v_error_message := 'MAR-MP066 #1' || p_action || '#2Not all Other Cost lines have an account-code';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;


        -- Do not perform various checks for Blanket Orders, Master Agreements and Service Agreements.
        IF (v_base_order_type <> 'BO') AND (v_base_order_sub_type NOT IN ('MA', 'SV')) THEN

----Canceled PO Items  Thua TASK0139926
        v_error_message := 'Item Already Cancelled ';
        OPEN mdr_cancelled_items;
        LOOP
            FETCH mdr_cancelled_items INTO v_poli_qty,v_poli_pos, v_poli_sub_pos,v_poli_id, v_poli_supp;
            EXIT WHEN mdr_cancelled_items%NOTFOUND;
            if v_poli_supp > 0 THEN
    --Select to PULL previous revision POH ID
               select poh.POH_ID into v_prev_poh_id from M_SYS.m_po_headers poh where
               poh.po_supp = ( v_poli_supp -1) and poh.BASE_poh_id = (select poh1.PARENT_poh_id from M_SYS.M_PO_HEADERS poh1 where poh1.poh_id = p_poh_id);

    --Select to PULL previous revision PO's Maximum Position from previous revision . Rest all are new so skip from validation
               select MAX(POLI.POLI_POS) into v_poli_pos_last_rev from M_SYS.M_PO_LINE_ITEMS POLI where /*POLI.POLI_ID = v_poli_id and */poli.poh_id = v_prev_poh_id ;


               if /*v_poli_supp > 0 and */v_poli_pos_last_rev >= v_poli_pos/*and  v_poli_sub_pos = 1*/ THEN
               select m_pck_mscm.get_last_qty(v_poli_id) into v_last_qty from m_sys.m_po_line_items poli, m_sys.M_PO_HEADERS po
               where Poli.poh_id = p_poh_id and po.poh_id = poli.poh_id and poli.poli_id = v_poli_id;
     -- v_error_message := 'LAST_QTY ' || v_last_qty ;

               if NVL(v_last_qty,0) = 0 and  NVL(v_poli_qty,0) > 0 /*and v_poli_supp > 0 */THEN

                  v_error_message := 'Item quantity increased in the change order and we already have cancelled the items for Line Item at position: ' || v_poli_pos ;
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);

                  RETURN 1;
               END IF;
            END IF;
        END IF;
    END LOOP;
    CLOSE mdr_cancelled_items;
----
            -- 2.3.9.    Check if the Agreement has an address for MAIL_TO, BILL_TO address types.
            v_rowcount      := 0;
            v_error_message := 'MAIL TO address not found';
            SELECT COUNT(*)
              INTO v_rowcount
              FROM m_sys.m_poh_addrs pa, m_sys.m_addr_types a
             WHERE pa.poh_id = p_poh_id
               AND pa.address_type_id = a.address_type_id
               AND a.address_type_code = 'MAIL TO';

            IF NVL(v_rowcount, 0) = 0 THEN
                v_error_message := 'MAR-MP013 #1' || p_action;
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

            v_rowcount      := 0;
            v_error_message := 'BILL TO address not found';
            SELECT COUNT(*)
              INTO v_rowcount
              FROM m_sys.m_poh_addrs pa, m_sys.m_addr_types a
             WHERE pa.poh_id = p_poh_id
               AND pa.address_type_id = a.address_type_id
               AND a.address_type_code = 'BILL TO';

            IF NVL(v_rowcount, 0) = 0 THEN
                v_error_message := 'MAR-MP014 #1' || p_action;
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

            -- Do not check the Promised Contract Delivery Date for Blanket Orders, Master Agreements and Service Agreements.
            --v_error_message := 'Promised Delivery Date not found';
            v_poli_pos      := 0;
            SELECT MAX(p.poli_pos)
            INTO v_poli_pos
            FROM m_sys.m_item_ships s, m_sys.m_po_line_items p
            WHERE s.poli_id IN (SELECT MAX(i.poli_id) poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL GROUP BY i.parent_poli_id
                               UNION
                               SELECT i.poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NULL
                               MINUS
                               SELECT DISTINCT i.parent_poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL)
            AND s.prom_contract_date IS NULL
            AND s.poli_id = p.poli_id;

            IF (v_poli_pos IS NOT NULL) AND (v_poli_pos > 0) THEN
                v_error_message := 'MAR-MP038 #1' || p_action || ' #2Promised Delivery Date #3' || v_poli_pos;  -- Agreement cannot be approved as Promised Delivery Date is not specified for item
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;


            rm_exist_ := 0;
            OPEN  Check_RM_Empty(v_base_poh_id);
            FETCH Check_RM_Empty INTO rm_exist_;
            CLOSE Check_RM_Empty;

            IF (rm_exist_ IS NOT NULL) AND (rm_exist_ > 0) THEN
                v_error_message := 'MAR-MP038 #1' || p_action || ' #2Routing Method #3' || v_poli_pos;
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

            incoterm_exist_ := 0;
            OPEN  Check_Incoterm_Empty(v_base_poh_id);
            FETCH Check_Incoterm_Empty INTO incoterm_exist_;
            CLOSE Check_Incoterm_Empty;

            IF (incoterm_exist_ IS NOT NULL) AND (incoterm_exist_ > 0) THEN
                v_error_message := 'MAR-MP038 #1' || p_action || ' #2Incoterm #3' || v_poli_pos;
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

            delv_place_exist_ := 0;
            OPEN  Check_Delv_Place_Empty(v_base_poh_id);
            FETCH Check_Delv_Place_Empty INTO delv_place_exist_;
            CLOSE Check_Delv_Place_Empty;

            IF (delv_place_exist_ IS NOT NULL) AND (delv_place_exist_ > 0) THEN
                v_error_message := 'MAR-MP038 #1' || p_action || ' #2Delivery Place #3' || v_poli_pos;
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;


            -- Assign Approval Sequence based on Template if buyer is flagging for RfA
            IF UPPER(p_action) = 'FLAGGED AS RFA' THEN

                --IF NVL(v_mdr_apr, '#$%') IN ('PROJECT', 'NON PROJECT') THEN

                IF NVL(v_dp_id, 0) > 0 THEN
                    SELECT dp_code, dp_abbrev
                        INTO v_dp_code, v_dp_abbrev
                        FROM m_sys.m_disciplines
                        WHERE dp_id = v_dp_id;
                END IF;

                IF NVL(v_dp_abbrev, '#$%') = '#$%' THEN
                    v_dp_abbrev := SUBSTR(v_dp_code, 1, 2);
                END IF;

                -- MZ, check if requistion discipline is Subcontract
                BEGIN
                    SELECT MIN(dp_id)
                        INTO v_r_dp_id
                        FROM m_sys.m_reqs
                        WHERE r_id = v_r_id;
                EXCEPTION
                    WHEN OTHERS THEN
                        v_r_id := NULL;
                END;

                -- MZ, check if SC
                IF NVL(v_r_dp_id, 0) > 0 THEN
                    SELECT dp_code, dp_abbrev
                        INTO v_r_dp_code, v_r_dp_abbrev
                        FROM m_sys.m_disciplines
                        WHERE dp_id = v_r_dp_id;
                END IF;

                IF NVL(v_r_dp_abbrev, '#$%') = '#$%' THEN
                    v_r_dp_abbrev := SUBSTR(v_dp_code, 1, 2);
                END IF;



                /**** for 8.x, it will always be PROJECT specific and SUBCON POs will not be operated through SPM8.x as per Business agreement -01/15/20 - CG ********
                IF v_mdr_apr = 'NON PROJECT' THEN
                    v_atpl_code := SUBSTR(v_dp_abbrev || v_template_suffix, 1, 10);
                ELSIF
                    IF v_mdr_apr = 'PROJECT' AND NVL(v_r_dp_abbrev, '#$%') = 'SC' THEN -- MZ, for SubContract
                        v_atpl_code := 'SUBCON_PO';
                ELSE  *********/

                    /***END IF;*********/
                -- debug := '1-' || v_atpl_code || '  2-' || v_mdr_apr || '  3-' ||  v_r_dp_abbrev;


                v_rowcount := 0;
                v_atpl_code := SUBSTR(v_dp_code, 1, 10);

                -- Check if the Approval Template exists
                BEGIN
                    SELECT atpl_id
                        INTO v_atpl_id
                        FROM m_sys.m_approval_templates
                        WHERE proj_id = v_proj_id
                        AND atpl_code = v_atpl_code;
                EXCEPTION
                    WHEN OTHERS THEN
                        v_atpl_id := 0;
                END;

                IF NVL(v_atpl_id, 0) = 0 THEN
                    v_error_message := 'MAR-MP049 #1' || p_action || ' #2' || v_atpl_code;  -- Agreement cannot be approved as Discipline specific Approval Template does not exists
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;


                IF NVL(v_r_dp_abbrev, '#$%') = 'SC' THEN -- MZ, for SubContract
                    v_def_buyer_title := 'SC SPECIALIST';
                ELSE
                    v_def_buyer_title := 'BUYER';
                END IF;

                BEGIN
                    SELECT ut_id, UPPER(title_name)
                        INTO v_buyer_ut_id, v_buyer_title_name
                        FROM m_sys.m_user_titles
                        WHERE UPPER(title_name) = v_def_buyer_title;
                EXCEPTION
                    WHEN OTHERS THEN
                        v_buyer_ut_id := 0;
                END;

                IF NVL(v_buyer_ut_id, 0) = 0 THEN
                    v_error_message := 'MAR-MP050 #1' || p_action || ' #2' || v_buyer_title_name;   -- Buyer User Title not setup
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;


                v_error_message := 'Total Ammount not found for PO ' || p_poh_id;
                v_total_price   := 0;
                SELECT total_price
                    INTO v_total_price
                    FROM m_sys.m_po_total_costs t
                    WHERE poh_id = p_poh_id;

                -- Check if the Buyer exists in Approval Template as a Buyer
                BEGIN
                    SELECT MAX(atd_id)
                        INTO v_atd_id
                        FROM m_sys.m_approval_template_details
                        WHERE proj_id = v_proj_id
                        AND atpl_id   = v_atpl_id
                        AND m_usr_id  = v_buyer
                        AND ut_id     = v_buyer_ut_id;
                EXCEPTION
                    WHEN OTHERS THEN
                        v_atd_id := 0;
                END;

                IF NVL(v_atd_id, 0) = 0 THEN
                    v_error_message := 'MAR-MP051 #1' || p_action || ' #2' || v_buyer || ' #3' || v_def_buyer_title || ' in Approval Template ' || v_atpl_code;  -- Buyer not defined in the Approval Template
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;


                SELECT currency_id, amount, distrib_id
                    INTO v_atd_currency_id, v_atd_amount, v_distrib_id
                    FROM m_sys.m_approval_template_details
                    WHERE atd_id = v_atd_id;

                --If no amount is specified, then it means Buyer can approve any value
                --IF NVL(v_atd_amount, 0) > 0 THEN
                --If Approver currency is different than the Buyer Currency check existence of exchange rate

                IF NVL(v_currency_id, 0) <> NVL(v_atd_currency_id, 0) THEN
                    BEGIN
                        v_rowcount := 0;
                        v_error_message := 'Exchange Rate 1 for ' || v_currency_id || ' to ' || v_atd_currency_id || ' not found';
                        SELECT COUNT(*), MAX(addend), MAX(factor), MAX(addend1)
                            INTO v_rowcount, v_addend, v_factor, v_addend1
                            FROM m_sys.m_unit_to_units
                            WHERE unit_id  = v_currency_id
                            AND to_unit_id = v_atd_currency_id;
                    EXCEPTION
                        WHEN OTHERS THEN
                            v_rowcount := 0;
                    END;

                    IF NVL(v_rowcount, 0) = 0 THEN
                        IF NVL(v_atd_currency_id, 0) > 0 THEN
                            SELECT unit_code
                                INTO v_atd_currency
                                FROM m_sys.m_units
                                WHERE unit_id = v_atd_currency_id;
                        END IF;
                        v_error_message := 'MAR-MP052 #1' || p_action || ' #2' || v_currency_code || ' #3' || v_atd_currency;  -- Agreement Currency to Approver Currency Exchange Rate not defined
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    ELSE
                        v_converted_amount := (v_total_price + v_addend) * v_factor + v_addend1;
                    END IF;
                ELSE
                    v_converted_amount := v_total_price;
                    v_atd_currency     := v_currency_code;
                END IF;

                v_error_message  := 'Buyers limit not found';
                v_approver_ut_id := 0;--MZ, Clear the approver's title
                v_order_seq      := 0;-- MZ, approver seq number
                v_po_approvers   := 0;
                v_atpl_approvers := 0;

                SELECT COUNT(*)
                    INTO v_po_approvers
                    FROM m_sys.m_approval_users
                    WHERE proj_id = v_proj_id
                    AND pk_type   = 'PO'
                    AND pk_id     = p_poh_id;

                SELECT COUNT(*)
                    INTO v_atpl_approvers
                    FROM m_sys.m_approval_template_details
                    WHERE proj_id = v_proj_id
                    AND atpl_id   =  (SELECT MAX(atpl_id) FROM m_sys.m_approval_templates
                                      WHERE proj_id = v_proj_id
                                      AND atpl_code = SUBSTR(v_dp_code, 1, 10));

                -- debug := ' v_po_approvers - ' || to_char(v_po_approvers) || ' v_atpl_approvers - ' || to_char(v_atpl_approvers) || ' v_atpl_id- ' || to_char(v_atpl_id) || ' v_proj_id- ' || to_char(v_proj_id);

                -- MZ, clear if first time RFA
                IF NVL(v_po_approvers, 0) = NVL(v_atpl_approvers, 0) THEN
                -- debug := to_char(v_po_approvers) || ' MZ-2 ' || to_char(v_atpl_approvers);
                    DELETE m_sys.m_approval_users
                        WHERE proj_id = v_proj_id
                        AND pk_type   = 'PO'
                        AND pk_id     = p_poh_id;
                    COMMIT;
                ELSE
                    -- MZ, check existing approvers in line with PO value
                    OPEN approver_cur;
                        LOOP
                            FETCH approver_cur
                            INTO v_au_id, v_atd_currency_id, v_atd_amount, v_distrib_id,v_usr_id,v_t_ut_id;
                            EXIT WHEN approver_cur%NOTFOUND;

                            BEGIN
                                ----SPK , Check whether apporval limit is change
                                --SPK , Also check whether approval limit is changed in the template
                                SELECT currency_id, amount
                                    INTO v_t_atd_currency_id, v_t_atd_amount
                                    FROM m_sys.m_approval_template_details
                                    WHERE atpl_id   = v_atpl_id
                                    AND ut_id       = v_t_ut_id
                                    AND currency_id = v_atd_currency_id
                                    AND m_usr_id    = v_usr_id
                                    AND proj_id     = v_proj_id;

                            EXCEPTION    WHEN OTHERS THEN
                                DELETE m_sys.m_approval_users
                                    WHERE proj_id = v_proj_id
                                    AND pk_type   = 'PO'
                                    AND pk_id     = p_poh_id;

                                COMMIT;

                                v_error_message := 'The Approval Template Changed. Please do the RFA Again';
                                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                RETURN 1;
                            END;

                            IF NVL(v_t_atd_amount, 0) > 0 THEN
                                -- If Approver currency is different than the Approval template Currency check existence of exchange rate
                                IF NVL(v_t_atd_currency_id, 0) <> NVL(v_currency_id, 0) THEN
                                    BEGIN
                                        v_rowcount := 0;
                                        SELECT COUNT(*), MAX(addend), MAX(factor), MAX(addend1)
                                            INTO v_rowcount, v_addend, v_factor, v_addend1
                                            FROM m_sys.m_unit_to_units
                                            WHERE unit_id  = v_currency_id
                                            AND to_unit_id = v_t_atd_currency_id;

                                        v_rowcount := 1;
                                    EXCEPTION
                                        WHEN OTHERS THEN
                                           v_rowcount := 0;
                                    END;
                                    IF NVL(v_rowcount, 0) > 0 THEN
                                        v_converted_amount := (v_total_price + v_addend) * v_factor + v_addend1;
                                    END IF;
                                ELSE
                                    v_rowcount := 1;
                                    v_converted_amount := v_total_price;
                                END IF;
                            ELSE
                                v_t_atd_amount := NULL;
                                v_rowcount := 1;
                            END IF;

                            IF NVL(v_rowcount, 0) > 0 THEN

                                -- Check if Total Price is more than Approver Limit
                                IF NVL(v_converted_amount, 0) > NVL(v_t_atd_amount, 0) THEN

                                    DELETE m_sys.m_approval_users
                                        WHERE proj_id = v_proj_id
                                        AND pk_type = 'PO'
                                        AND pk_id   = p_poh_id;

                                    COMMIT;
                                    v_error_message := 'The Approval Template Limit Changed. Please do the RFA Again';
                                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                    RETURN 1;

                                END IF;
                            END IF;

                            IF NVL(v_atd_currency_id, 0) > 0 THEN
                                SELECT unit_code
                                    INTO v_atd_currency
                                    FROM m_sys.m_units
                                    WHERE unit_id = v_atd_currency_id;
                            END IF;

                            IF NVL(v_atd_amount, 0) > 0 THEN
                                -- If Approver currency is different than the PO Currency check existence of exchange rate
                                IF NVL(v_currency_id, 0) <> NVL(v_atd_currency_id, 0) THEN
                                    BEGIN
                                        v_rowcount := 0;
                                        SELECT COUNT(*), MAX(addend), MAX(factor), MAX(addend1)
                                            INTO v_rowcount, v_addend, v_factor, v_addend1
                                            FROM m_sys.m_unit_to_units
                                            WHERE unit_id  = v_currency_id
                                            AND to_unit_id = v_atd_currency_id;
                                        v_rowcount := 1;
                                    EXCEPTION
                                        WHEN OTHERS THEN
                                        v_rowcount := 0;
                                    END;
                                    IF NVL(v_rowcount, 0) > 0 THEN
                                        v_converted_amount := (v_total_price + v_addend) * v_factor + v_addend1;
                                    END IF;
                                ELSE
                                    v_rowcount := 1;
                                    v_converted_amount := v_total_price;
                                END IF;
                            ELSE
                                v_atd_amount := NULL;
                                v_rowcount := 1;
                            END IF;

                            IF NVL(v_rowcount, 0) > 0 THEN
                                -- Check if Total Price is more than Approver Limit
                                IF NVL(v_converted_amount, 0) > NVL(v_atd_amount, 0) THEN

                                    DELETE m_sys.m_approval_users
                                        WHERE proj_id = v_proj_id
                                        AND pk_type = 'PO'
                                        AND pk_id   = p_poh_id
                                        AND au_id   = v_au_id;
                                    COMMIT;

                                END IF;
                            END IF;
                        END LOOP;
                    CLOSE approver_cur;
                END IF;

                SELECT COUNT(*)
                    INTO v_po_approvers
                    FROM m_sys.m_approval_users
                    WHERE proj_id = v_proj_id
                    AND pk_type   = 'PO'
                    AND pk_id     = p_poh_id;

                -- MZ, If no approver yet, allow to insert approvers
                IF NVL(v_po_approvers, 0) = 0 THEN
                    -- Select from Non Buyer if
                    -- 1. PO Total is more than Buyer's limit OR 2.Buyers approval limit is 0 OR 3.Buyer and Req Approver is same
                    IF NVL(v_atd_amount, 0) = 0 OR NVL(v_converted_amount, 0) > NVL(v_atd_amount, 0) OR (v_buyer = NVL(v_r_approver,'!NDF')) THEN
                        -- Check if there is any Non Buyer approver detail with amount greater than Total Price
                        OPEN non_buy_aprv_template_details;
                        LOOP
                        -- debug := 'v_atpl_id= ' || to_char(v_atpl_id);
                            FETCH non_buy_aprv_template_details
                             INTO v_approver, v_atd_id, v_atd_currency_id, v_atd_amount, v_distrib_id, v_ut_id;
                            EXIT WHEN non_buy_aprv_template_details%NOTFOUND;

                            IF NVL(v_atd_currency_id, 0) > 0 THEN
                                SELECT unit_code
                                INTO v_atd_currency
                                FROM m_sys.m_units
                                WHERE unit_id = v_atd_currency_id;
                            END IF;

                            IF NVL(v_atd_amount, 0) > 0 THEN
                                -- If PO currency is different than the Buyer Currency check existence of exchange rate
                                IF NVL(v_currency_id, 0) <> NVL(v_atd_currency_id, 0) THEN
                                    BEGIN
                                        v_rowcount := 0;
                                        SELECT COUNT(*), MAX(addend), MAX(factor), MAX(addend1)
                                        INTO v_rowcount, v_addend, v_factor, v_addend1
                                        FROM m_sys.m_unit_to_units
                                        WHERE unit_id  = v_currency_id
                                        AND to_unit_id = v_atd_currency_id;
                                        v_rowcount := 1;
                                    EXCEPTION
                                        WHEN OTHERS THEN
                                            v_rowcount := 0;
                                    END;
                                    IF NVL(v_rowcount, 0) > 0 THEN
                                        v_converted_amount := (v_total_price + v_addend) * v_factor + v_addend1;
                                    END IF;
                                ELSE
                                    v_rowcount := 1;
                                    v_converted_amount := v_total_price;
                                END IF;
                            ELSE
                                v_atd_amount := NULL;
                                v_rowcount := 1;
                            END IF;

                            IF NVL(v_rowcount, 0) > 0 THEN
                                -- Check if Total Price is more than Approval Limit
                                IF NVL(v_atd_amount, 0) = 0 OR NVL(v_converted_amount, 0) <= NVL(v_atd_amount, 0) THEN

                                    -- MZ, get approver's title
                                    SELECT UPPER(SUBSTR(title_name,instr(title_name, ' ',-1)+1))
                                        INTO v_approver_title_name
                                        FROM m_sys.m_user_titles
                                        WHERE ut_id = v_ut_id;

                                    -- MZ, If Req and PO approver is same person
                                    IF NVL(v_r_approver,'!NDF') = v_approver THEN
                                        -- Clear the parameters
                                        v_approver_ut_id := 0;
                                        v_approver_f_title_name := '';
                                        v_approver_d_title_name := v_approver_title_name;
                                    ELSE
                                        -- MZ, first approver's title
                                        IF v_approver_ut_id = 0 AND v_approver_d_title_name <> v_approver_title_name THEN  -- MZ
                                            v_approver_ut_id := v_ut_id;
                                            v_approver_f_title_name := v_approver_title_name;
                                        END IF;

                                        -- MZ, only those approver's who matches with first approver's title.
                                        IF v_approver_f_title_name = v_approver_title_name OR v_approver_d_title_name = v_approver_title_name THEN
                                            v_order_seq := v_order_seq + 1;

                                            v_error_message := 'approver ' || v_approver || ' could not be added as an Approver';

                                            INSERT INTO m_sys.m_approval_users (au_id, proj_id, pk_type, pk_id, order_seq, m_usr_id, approved_ind, rejected_ind, amount, currency_id, distrib_id, ut_id)
                                                SELECT m_sys.m_seq_au_id.nextval, v_proj_id, 'PO', p_poh_id, v_order_seq, v_approver, 'N', 'N', v_atd_amount, v_atd_currency_id, v_distrib_id, v_ut_id
                                                FROM DUAL;
                                            COMMIT;
                                        END IF;
                                    END IF;

                                END IF;
                            END IF;
                        END LOOP;
                        CLOSE non_buy_aprv_template_details;
                    ELSE
                        IF v_buyer <> NVL(v_r_approver,'!NDF') Then
                            v_error_message := 'buyer ' || v_buyer || ' could not be added as an Approver';
                            INSERT INTO m_sys.m_approval_users (au_id, proj_id, pk_type, pk_id, order_seq, m_usr_id, approved_ind, rejected_ind, amount, currency_id, distrib_id, ut_id)
                                SELECT m_sys.m_seq_au_id.nextval, v_proj_id, 'PO', p_poh_id, 1, v_buyer, 'N', 'N', v_atd_amount, v_atd_currency_id, v_distrib_id, v_buyer_ut_id
                                FROM DUAL;
                            COMMIT;
                        ELSE
                            IF INSTR(v_po_number,'-MO-PROC-') = 0 THEN
                                v_error_message := 'Buyer ' || v_buyer || ' and Requisition approver is same.';
                                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                RETURN 1;
                            END IF;
                        END IF;
                    END IF;
                END IF;


                -- At this point if there are no entries in Approval Sequence, then it means we were not able to create entries from Template due to approval limits being less than Total Price
                v_rowcount := 0;
                SELECT COUNT(*)
                    INTO v_rowcount
                    FROM m_sys.m_approval_users
                    WHERE proj_id = v_proj_id
                    AND pk_type   = 'PO'
                    AND pk_id     = p_poh_id;

                IF NVL(v_rowcount, 0) = 0 THEN
                    v_error_message := 'MAR-MP053 #1' || p_action || ' #2Approval Template ' ||  v_atpl_code || ' is less than ' || v_total_price || ' ' || v_currency_code || ' (' || v_converted_amount || ' ' || v_atd_currency || ')';  -- Buyer Approval Limit less than Total Price
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;

                -- MZ, Check if multiple approvers
                IF NVL(v_rowcount, 0) > 1 THEN
                    v_error_message := 'MAR-MP067 #1' || p_action || ' #2Approval sequence contains multiple approvers.';
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;
            END IF;


            IF (mdr_fin_sys_ = 'OLIVES') THEN
                ora_ss_attr_id_ := 0;
                SELECT  NVL(MAX(attr_id),0)
                INTO    ora_ss_attr_id_
                FROM    m_sys.m_attrs
                WHERE   attr_code = 'LEGACY_POVENDOR';

                IF (ora_ss_attr_id_ = 0) OR (ora_ss_attr_id_ IS NULL) THEN
                    v_error_message := 'MAR-MP066 #1' || p_action || ' #2Attribute LEGACY_POVENDOR is not exists';
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;

                SELECT NVL(MAX(attr_value),'!NDF')
                    INTO   ora_ss_attr_value_
                    FROM   m_sys.m_used_values
                    WHERE  used_type  = 'SUP'
                    AND    pk_id      = v_sup_id
                    AND    attr_value IS NOT NULL
                    AND    attr_id    = ora_ss_attr_id_;

                IF ora_ss_attr_value_ = '!NDF' THEN
                    v_error_message := 'MAR-MP066 #1' || p_action || ' #Olives Supplier Code (LEGACY_POVENDOR) attribute value is not found for the supplier';
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;
            END IF;


            IF (mdr_fin_sys_ = 'ORACLE') THEN

                IF v_sup_id <> 100 AND v_sup_id <> 200 THEN

                    SELECT    company_id
                    INTO    v_company_id
                    FROM    m_sys.m_suppliers
                    WHERE    sup_id = v_sup_id;

                    ora_ss_attr_id_ := 0;
                    SELECT    NVL(MAX(attr_id),0)
                    INTO    ora_ss_attr_id_
                    FROM    m_sys.m_attrs
                    WHERE    attr_code = 'ORACLE_SUPPLIER_SITE_CODE';

                    IF (ora_ss_attr_id_ = 0) OR (ora_ss_attr_id_ IS NULL) THEN
                        v_error_message := 'MAR-MP066 #1' || p_action || ' #2Attribute ORACLE_SUPPLIER_SITE_CODE is not exists';
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;

                    SELECT    NVL(MAX(attr_value),'!NDF')
                        INTO    ora_ss_attr_value_
                        FROM    m_sys.m_used_values
                        WHERE    used_type = 'COM'
                        AND        pk_id     = v_company_id
                        AND        attr_id   = ora_ss_attr_id_;

                    IF ora_ss_attr_value_ = '!NDF' THEN
                        v_error_message := 'MAR-MP066 #1' || p_action || ' #2Oracle Supplier Site Code attribute value is not found for the supplier';
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;
                END IF;
            END IF;

            IF (mdr_fin_sys_ = 'ORACLE') OR (mdr_fin_sys_ = 'OLIVES') THEN
                v_payment_mode_code := get_attribute_value ('PO', p_poh_id, 'PAYMENT_MODE');
                IF v_payment_mode_code IN ('31', '32', '33') THEN
                    v_payment_mode := 'M';
                ELSE
                    v_payment_mode := 'Q';
                END IF;

                IF NVL(v_payment_mode_code, '#$%') = '#$%' THEN
                    -- If Agreement is of Type PO, Raise an error, otherwise add set Payment Mode to 31
                    IF v_base_order_type = 'PO' THEN
                        v_error_message := 'MAR-MP029 #1' || p_action;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    ELSE
                        v_payment_mode_code := '31';
                        v_payment_mode := 'M';
                        v_error_message := 'Payment Mode ' || v_payment_mode_code || ' could not be set';
                        INSERT INTO m_sys.m_used_values (uval_id, proj_id, used_type, pk_id, attr_id, attr_value, attr_data_type, number_value, nls_id)
                        SELECT m_sys.m_seq_uval_id.NEXTVAL, v_proj_id, 'PO', p_poh_id, v_payment_mode_attr_id, v_payment_mode_code, 'C', null, 1
                          FROM dual;
                    END IF;
                END IF;

                IF v_payment_mode = 'M' AND v_payment_type <> 'MP' THEN
                    v_error_message := 'MAR-MP056 #1' || p_action;  -- Agreement cannot be approved as Payment Type is not Milestone Progress for Type 31, 32, 33 PO
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                ELSIF v_payment_mode <> 'M' AND v_payment_type = 'MP' THEN
                    v_error_message := 'MAR-MP057 #1' || p_action;  -- Agreement cannot be approved as Payment Type is Milestone Progress for Non Type 31, 32, 33 PO
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;
            END IF;
        END IF;--Check BO


        IF (v_base_order_type <> 'BO') AND (v_base_order_sub_type NOT IN ('MA', 'SV')) THEN
            v_error_message := 'SELECT_CODE not found';
            -- Vendor Select Code
            v_select_code_full := get_attribute_value ('PO', p_poh_id, 'SELECT_CODE');

            IF NVL(v_select_code_full, '#$%') <> '#$%' THEN
                v_select_code := substr(v_select_code_full, 1, 1);
            ELSE
                v_error_message := 'MAR-MP062 #1' || p_action;   -- Vendor Select Code not specified
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

            -- LOWEST_SUPPLIER_PRICE
            v_lowest_supplier_price := get_attribute_number_value ('PO', p_poh_id, 'LOWEST_SUPPLIER_PRICE');

            -- LOWEST_SUPPLIER_NAME
            v_lowest_supplier_name := get_attribute_value ('PO', p_poh_id, 'LOWEST_SUPPLIER_NAME');

            -- RC/7/10/2014 - Do not copy Manadatory clauses as per Cissy
            --Check if all the manadatory clauses (text / terms) are attached to the Agreement
            v_rowcount := 0;
            v_tm_id := 0;
            v_error_message := 'Mandatory terms could not be added';

            SELECT MAX(order_seq)
                INTO v_min_order_seq
                FROM m_sys.m_att_terms
                WHERE pk_type = 'POH'
                AND pk_id = p_poh_id
                AND order_seq >= 9000
                AND order_seq <> 9099;

            v_min_order_seq := NVL(v_min_order_seq, 0);

            IF v_min_order_seq = 0 THEN
                v_min_order_seq := 9000;
            END IF;

            INSERT INTO m_sys.m_att_terms (attt_id, proj_id, pk_type, pk_id, term_placement, tm_id, order_seq, dp_id)
                SELECT m_sys.m_seq_attt_id.nextval, v_proj_id, 'POH', p_poh_id, 'F', tm_id, v_min_order_seq + rownum, v_dp_id
                FROM (SELECT t.tm_id, t.tm_code FROM (SELECT distinct tsd.tm_id tm_id FROM m_sys.m_term_sets ts, m_sys.m_term_set_details tsd WHERE ts.proj_id = v_proj_id AND ts.ts_id = tsd.ts_id AND ts.ts_code = 'MDR_MC_SET'
                      MINUS
                      SELECT distinct tm_id FROM m_sys.m_att_terms WHERE pk_type = 'POH' AND pk_id = p_poh_id) a, m_sys.m_terms t
                WHERE a.tm_id = t.tm_id
                ORDER by t.tm_code);

            v_error_message := 'Mandatory term descriptions could not be added';
            INSERT INTO m_sys.m_att_term_nls (attt_id, nls_id, short_desc, description)
                SELECT a.attt_id, t.nls_id, t.short_desc, t.description
                FROM m_sys.m_att_terms a, m_sys.m_term_nls t
                WHERE a.proj_id = v_proj_id
                AND a.pk_type = 'POH'
                AND a.pk_id = p_poh_id
                AND a.order_seq >= 9000
                AND a.tm_id = t.tm_id
                AND NOT EXISTS (SELECT 1 FROM m_sys.m_att_term_nls n WHERE n.attt_id = a.attt_id);

            v_error_message := 'last term could not be added';
            UPDATE m_sys.m_att_terms
                SET order_seq = 9099
                WHERE proj_id = v_proj_id
                AND pk_type = 'POH'
                AND pk_id = p_poh_id
                AND order_seq <> 9099
                AND tm_id IN (SELECT t.tm_id FROM m_sys.m_terms t, m_sys.m_att_terms a WHERE a.proj_id = v_proj_id AND a.pk_type = 'POH' AND a.pk_id = p_poh_id AND a.tm_id = t.tm_id AND t.use_param = 'LAST')
                AND NOT EXISTS (SELECT 1 FROM m_sys.m_att_terms WHERE proj_id = v_proj_id AND pk_type = 'POH' AND pk_id = p_poh_id AND order_seq = 9099);

            -- Filter the Vendor Selection code. Out of 10 allow only below 5, as requested by Internal Control Audit 02-Mar-2017. -- MZ-VSC
            -- Check if previous version of PO contain Obsolete selection code. If YES, by pass the sel_code_filter.
            v_by_pass_sel_code_filter := 0;

            SELECT NVL(MAX(uval_id),0)
                INTO v_by_pass_sel_code_filter
                FROM m_sys.m_used_values
                WHERE proj_id = v_proj_id AND attr_id = v_selection_code_attr_id AND pk_id = v_base_poh_id AND pk_id <> p_poh_id
                AND attr_value IN ('0 - BLANKET / CONTRACT / AGREEMENT', '1 - PRIORITY HANDLING', '3 - INTERNAL CUSTOMER MANDATE', '4 - CLIENT MANDATE', '8 - TECHNICALLY ACCEPTABLE LOW BID');

            IF NVL(v_select_code, '#$%') NOT IN ('2', '5', '6', '7', '9') and v_by_pass_sel_code_filter = 0 THEN
                v_error_message := 'Invalid Vendor Selection code. ' || v_select_code_full || '. Valid Vendor Selection codes are 2, 5, 6, 7 and 9.';
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;
        END IF; --Check BO
        -- Ends here -- MZ-VSC


        -- Do not perform various checks for Blanket Orders, Master Agreements and Service Agreements.
        --IF (v_base_order_type <> 'BO') AND (v_base_order_sub_type NOT IN ('MA', 'SV')) THEN

            -- Check if the A/C Distribution of the requisition header was updated after Agreement was created
            --v_rowcount := 0;

            /***********Logic to be relooked after Oracle confirms if that logic is possible - 01/15- Cissy - Sandeep
            SELECT COUNT(*)
              INTO v_rowcount
              FROM m_sys.m_used_values
             WHERE attr_id = v_upd_ac_dist_attr_id
               AND used_type = 'ER'
               AND attr_value = 'YES'
               AND pk_id = v_r_id;


            -- Update the A/C Distribution of associated agreements
            IF NVL(v_rowcount, 0) <> 0 THEN
                v_error_message := 'error encountered while getting Req A/C Dist';

                v_req_entity := get_attribute_value ('ER', v_r_id, 'MDR_ENTITY');
                v_req_account_type := get_attribute_value ('ER', v_r_id, 'MDR_ACCOUNT_TYPE');
                v_req_job := get_attribute_value ('ER', v_r_id, 'MDR_JOB');
                v_req_sub_function := get_attribute_value ('ER', v_r_id, 'MDR_SUB_FUNCTION');
                v_req_feature := get_attribute_value ('ER', v_r_id, 'MDR_FEATURE');

                v_req_job_number := v_req_entity || '-' || v_req_account_type || '-' || v_req_job || '-' || v_req_sub_function || '-' || v_req_feature;

                v_req_header_job_id := get_job_id(v_req_job_number);

                -- Update the A/C Distribution of associated agreements
                IF NVL(v_req_header_job_id, 0) <> 0 THEN
                    -- Update Requisition Header and Items
                    UPDATE m_sys.m_req_line_items rli
                      SET rli.job_id = v_req_header_job_id
                    WHERE rli.r_id = v_r_id
                      AND NVL(rli.job_id, 0) <> NVL(v_req_header_job_id, 0)
                      AND (NVL(rli.job_id, 0) = 0 OR EXISTS (SELECT 1 FROM m_sys.m_reqs h WHERE h.r_id = v_r_id AND h.job_id = rli.job_id));

                    v_rowcount := SQL%ROWCOUNT;
                    COMMIT;

                    UPDATE m_sys.m_reqs
                      SET job_id = v_req_header_job_id
                    WHERE r_id = v_r_id;

                    v_rowcount := SQL%ROWCOUNT;
                    COMMIT;

                    v_error_message := 'error encountered while updating Item A/C Dist';

                    -- Update the PO Header and Item A/C Distribution
                    UPDATE m_sys.m_po_line_items pli
                      SET pli.job_id = v_req_header_job_id
                    WHERE NVL(pli.job_id, 0) <> NVL(v_req_header_job_id, 0)
                      AND (NVL(pli.job_id, 0) = 0 OR EXISTS (SELECT 1 FROM m_sys.m_po_headers h WHERE h.poh_id = pli.poh_id AND h.job_id = pli.job_id))
                      AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values u WHERE u.used_type = 'PO' AND u.pk_id = pli.poh_id AND u.attr_id = v_three_way_match_attr_id and u.attr_value = 'YES')
                      AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values u WHERE u.used_type = 'POLI' AND u.pk_id = pli.poli_id AND u.attr_id = v_three_way_match_attr_id and u.attr_value = 'YES')
                      AND pli.poh_id IN (SELECT poh_id
                                           FROM m_sys.m_po_headers h
                                          WHERE h.base_poh_id = v_base_poh_id);

                    v_rowcount := SQL%ROWCOUNT;
                    COMMIT;

                    v_error_message := 'error encountered while updating Other Cost A/C Dist';
                    UPDATE m_sys.m_used_other_costs c
                      SET c.job_id = v_req_header_job_id
                    WHERE c.term_type = 'PO'
                      AND NVL(job_id, 0) <> NVL(v_req_header_job_id, 0)
                      AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values u WHERE u.used_type = 'PO' AND u.pk_id = c.pk_id AND u.attr_id = v_three_way_match_attr_id and u.attr_value = 'YES')
                      AND c.pk_id IN (SELECT poh_id FROM m_sys.m_po_headers WHERE base_poh_id = v_base_poh_id);

                    v_rowcount := SQL%ROWCOUNT;
                    COMMIT;

                    v_error_message := 'error encountered while updating header A/C Dist';
                    UPDATE m_sys.m_po_headers h
                      SET h.job_id = v_req_header_job_id
                    WHERE NVL(h.job_id, 0) <> NVL(v_req_header_job_id, 0)
                      AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values u WHERE u.used_type = 'PO' AND u.pk_id = h.poh_id AND u.attr_id = v_three_way_match_attr_id and u.attr_value = 'YES')
                      AND h.poh_id IN (SELECT poh_id FROM m_sys.m_po_headers WHERE base_poh_id = v_base_poh_id);
                    v_rowcount := SQL%ROWCOUNT;
                    COMMIT;
                END IF;
            END IF;
            v_error_message := 'error encountered while getting Req Item A/C Dist';


            -- Check if any item needs to be updated
            v_rowcount := 0;
            SELECT COUNT(*)
              INTO v_rowcount
              FROM m_sys.m_used_values v, m_sys.m_req_li_to_polis r
             WHERE v.attr_id = v_upd_ac_dist_attr_id
               AND v.used_type = 'ERLI'
               AND v.attr_value = 'YES'
               AND v.pk_id = r.rli_id
               AND r.poh_id = v_base_poh_id;

            IF NVL(v_rowcount, 0) > 0 THEN
                -- Loop through Agreement's that need to be updated with new A/C dist
                OPEN req_upd_ac_dist;
                LOOP
                    FETCH req_upd_ac_dist INTO v_pk_id;
                    EXIT WHEN req_upd_ac_dist%NOTFOUND;

                    v_error_message := 'error encountered while getting Req Item ' || v_pk_id || ' A/C Dist';

                    v_req_entity := get_attribute_value ('ERLI', v_pk_id, 'MDR_ENTITY');
                    v_req_account_type := get_attribute_value ('ERLI', v_pk_id, 'MDR_ACCOUNT_TYPE');
                    v_req_job := get_attribute_value ('ERLI', v_pk_id, 'MDR_JOB');
                    v_req_sub_function := get_attribute_value ('ERLI', v_pk_id, 'MDR_SUB_FUNCTION');
                    v_req_feature := get_attribute_value ('ERLI', v_pk_id, 'MDR_FEATURE');

                    v_req_job_number := v_req_entity || '-' || v_req_account_type || '-' || v_req_job || '-' || v_req_sub_function || '-' || v_req_feature;

                    v_req_item_job_id := get_job_id(v_req_job_number);

                    v_error_message := 'error encountered while updating Req Item ' || v_pk_id || ' A/C Dist';
                    -- Update Requisition Items
                    UPDATE m_sys.m_req_line_items
                      SET job_id = v_req_item_job_id
                    WHERE rli_id = v_pk_id
                      AND NVL(job_id, 0) <> NVL(v_req_item_job_id, 0);

                    v_rowcount := SQL%ROWCOUNT;
                    COMMIT;

                    v_error_message := 'error encountered while updating PO Item A/C Dist for Req Item ' || v_pk_id;
                    -- Update the Item A/C Distribution
                    UPDATE m_sys.m_po_line_items i
                      SET i.job_id = v_req_item_job_id
                    WHERE NVL(i.job_id, 0) <> NVL(v_req_item_job_id, 0)
                      AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values u WHERE u.used_type = 'PO' AND u.pk_id = i.poh_id AND u.attr_id = v_three_way_match_attr_id and u.attr_value = 'YES')
                      AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values u WHERE u.used_type = 'POLI' AND u.pk_id = i.poli_id AND u.attr_id = v_three_way_match_attr_id and u.attr_value = 'YES')
                      AND i.poli_id IN (SELECT DISTINCT poli_id
                                          FROM m_sys.m_req_li_to_polis
                                         WHERE rli_id = v_pk_id
                                         UNION
                                        SELECT DISTINCT poli_id
                                          FROM m_sys.m_po_line_items
                                         WHERE rli_id = v_pk_id);
                    v_rowcount := SQL%ROWCOUNT;
                    COMMIT;
                END LOOP;

                CLOSE req_upd_ac_dist;
            END IF;
            *** Logic to be relooked after Oracle confirms it is possble to make change after PO creation- 01/15/20-CG-Sandeep ****/

            --2.3.1.    Check if the Agreement header has a Job Code (Accounting Distribution) assigned to it and that the job code is valid and open (m_sys.m_jobs.field6 = NO). Do not flag an error if the Agreement header does not have a Job Code.

            /*    SELECT SUM(DECODE(NVL(j.field6, 'NO'), 'NO', 0, 1)), MAX(h.job_id)-- COrrected column and value for 8.x based on m_jobs- 01/15-CG**/



        -- Do not perform various checks for Blanket Orders, Master Agreements and Service Agreements.
        IF (v_base_order_type <> 'BO') AND (v_base_order_sub_type NOT IN ('MA', 'SV')) THEN

            --Ruby commented this as checking PO closed already happend in above
            -- Check if the A/C Distribution of the requisition header was updated after Agreement was created
--            v_rowcount := 0;
--            v_error_message := 'PO A/C not found';
--            v_rowcount := 0;
--
--            SELECT SUM(DECODE(NVL(j.field7, 'N'), 'N', 0, 1)), MAX(h.job_id)
--                INTO v_rowcount, v_header_job_id
--                FROM m_sys.m_po_headers h, m_sys.m_jobs j
--                WHERE h.poh_id = p_poh_id
--                AND h.job_id = j.job_id
--                AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values u WHERE u.used_type = 'PO' AND u.pk_id = h.poh_id AND u.attr_id = v_three_way_match_attr_id and u.attr_value = 'YES');
--
--            IF NVL(v_rowcount, 0) > 0 THEN
--                v_error_message := 'MAR-MP001 #1' || p_action;
--                RAISE_APPLICATION_ERROR(-20000, v_error_message);
--                RETURN 1;
--            END IF;
            --End comment


            IF (mdr_fin_sys_ = 'ORACLE') OR (mdr_fin_sys_ = 'OLIVES') THEN
                -- Check if MS Pay events entered. Required only for PO type.  --MZ 201804
                v_error_message := 'Checking MS Pay Events.';
                v_rowcount      := 0;
                IF v_order_type = 'PO' THEN
                    SELECT COUNT(*)
                        INTO v_rowcount
                        FROM m_sys.m_att_ppes
                        WHERE proj_id = v_proj_id
                        AND pk_id     = p_poh_id;

                    IF NVL(v_rowcount, 0) = 0 THEN
                        v_error_message := 'MAR-MP068 #1' || p_action;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;
                END IF;
            
            
                --INC1250217
                -- 2.3.10.    Check if the Item Position Number is unique.
                v_poli_pos := 0;
                BEGIN
                    SELECT MAX(poli_pos)
                        INTO v_poli_pos
                        FROM m_sys.m_po_line_items
                        WHERE poli_id IN (SELECT MAX(i.poli_id) poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL GROUP BY i.parent_poli_id
                                           UNION
                                           SELECT i.poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NULL
                                           MINUS
                                           SELECT DISTINCT i.parent_poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL)
                        GROUP BY poli_pos
                        HAVING COUNT(*) > 1;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_poli_pos := 0;
                    WHEN OTHERS THEN
                        v_error_message := 'MAR-MP015 #1' || p_action || ' #2' || SQLERRM;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                END;

                IF NVL(v_poli_pos, 0) > 0 THEN
                    v_error_message := 'MAR-MP015 #1' || p_action || ' #2' || v_poli_pos;
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;


                -- 2.3.10.    Check if the Other Cost Codes is unique.
                v_error_message := 'duplicate Other Cost found';
                v_poli_pos := 0;
                BEGIN

                    SELECT MAX(o.oc_code)
                        INTO v_oc_code
                        FROM (SELECT oc_id
                                FROM (SELECT oc_id, job_id, unit_id, SUM(cost_value)
                                        FROM (SELECT u.oc_id, NVL2(u.job_id, u.job_id, (SELECT h.job_id FROM m_sys.m_po_headers h WHERE h.poh_id = u.pk_id)) job_id, u.unit_id, u.cost_value
                                                FROM m_sys.m_used_other_costs u
                                                WHERE u.term_type = 'PO'
                                                AND u.pk_id IN (SELECT poh_id FROM m_sys.m_po_headers WHERE base_poh_id = v_base_poh_id))
                                        GROUP BY oc_id, job_id, unit_id
                                        HAVING SUM(cost_value) > 0)
                                GROUP by oc_id
                                HAVING COUNT(*) > 1) uo, m_sys.m_other_costs o
                         WHERE uo.oc_id = o.oc_id;

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_oc_code := NULL;
                    WHEN OTHERS THEN
                        v_error_message := 'MAR-MP030 #1' || p_action || ' #2' || SQLERRM;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                END;

                IF NVL(v_oc_code, '#$%') <> '#$%' THEN
                    v_error_message := 'MAR-MP030 #1' || p_action || ' #2' || v_oc_code;
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;
        
            END IF;
        END IF;

        -- Do not perform various checks for Blanket Orders, Master Agreements and Service Agreements.
        IF (v_base_order_type <> 'BO') AND (v_base_order_sub_type NOT IN ('MA', 'SV')) THEN
            -- 2.3.2.    Check if all the Items have a Job Code (Accounting Distribution) assigned to them and that the job code is valid and open (m_sys.m_jobs.field6 = NO). If an item does not have a Job Code, the header must have a default Job Code.

--Ruby comment as PO Header A/C is mandatory so this conditions is never TRUE and if PO item A/C if empty will get copy from Header
--            v_rowcount := 0;
--            v_error_message := 'Item A/C Dist not found';
--
--            SELECT COUNT(*), MAX(i.poli_pos)
--                INTO v_rowcount, v_poli_pos
--                FROM m_sys.m_po_line_items i, m_sys.m_jobs j
--                WHERE i.poh_id = p_poh_id
--                AND i.job_id   = j.job_id
--                   /*AND NVL(j.field6, 'NO') = 'YES' -- CHanged column which indicates Active account -01/15/202 - CG*/
--                AND NVL(j.field7, 'N') = 'Y'
--                AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values u WHERE u.used_type = 'PO' AND u.pk_id = i.poh_id AND u.attr_id = v_three_way_match_attr_id and u.attr_value = 'YES')
--                AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values u WHERE u.used_type = 'POLI' AND u.pk_id = i.poli_id AND u.attr_id = v_three_way_match_attr_id and u.attr_value = 'YES');
--
--            IF NVL(v_rowcount, 0) > 0 THEN
--                v_error_message := 'MAR-MP002 #1' || p_action || ' #2' || v_poli_pos;
--                RAISE_APPLICATION_ERROR(-20000, v_error_message);
--                RETURN 1;
--            END IF;

--            IF NVL(v_header_job_id, 0) = 0 THEN
--                v_rowcount := 0;
--
--                SELECT COUNT(*), MAX(i.poli_pos)
--                    INTO v_rowcount, v_poli_pos
--                    FROM m_sys.m_po_line_items i
--                    WHERE i.poh_id = p_poh_id
--                    AND i.job_id IS NULL
--                    AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values u WHERE u.used_type = 'PO' AND u.pk_id = i.poh_id AND u.attr_id = v_three_way_match_attr_id and u.attr_value = 'YES')
--                    AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values u WHERE u.used_type = 'POLI' AND u.pk_id = i.poli_id AND u.attr_id = v_three_way_match_attr_id and u.attr_value = 'YES');
--
--                IF NVL(v_rowcount, 0) > 0 THEN
--                    v_error_message := 'MAR-MP003 #1' || p_action || ' #2' || v_poli_pos;
--                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
--                    RETURN 1;
--                END IF;
--            ELSE
--                v_error_message := 'Item A/C Dist could not be updated from Header';
--                UPDATE m_sys.m_po_line_items i
--                    SET i.job_id   = v_header_job_id
--                    WHERE i.poh_id = p_poh_id
--                    AND i.job_id IS NULL
--                    AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values u WHERE u.used_type = 'PO' AND u.pk_id = i.poh_id AND u.attr_id = v_three_way_match_attr_id and u.attr_value = 'YES')
--                    AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values u WHERE u.used_type = 'POLI' AND u.pk_id = i.poli_id AND u.attr_id = v_three_way_match_attr_id and u.attr_value = 'YES');
--            END IF;
--End here

            -- 2.3.3.    Check if all the Other Cost have a Job Code (Accounting Distribution) assigned to them and that the job code is valid and open (m_sys.m_jobs.field6 = NO). If an Other Cost does not have a Job Code, the header must have a default Job Code.
            v_rowcount := 0;

            v_error_message := 'Other Cost A/C Dist not found';

            IF (mdr_fin_sys_ = 'ORACLE') THEN
                SELECT COUNT(*), MAX(o.oc_code)
                    INTO v_rowcount, v_oc_code
                    FROM m_sys.m_used_other_costs u, m_sys.m_jobs j, m_sys.m_other_costs o
                    WHERE u.pk_id   = p_poh_id
                    AND u.term_type = 'PO'
                    AND u.job_id    = j.job_id
                    AND u.oc_id     = o.oc_id
                    /*AND NVL(j.field6, 'NO') = 'YES' -- CHanged column which indicates Active account -01/15/202 - CG*/
                    AND NVL(j.field7, 'N') = 'Y'
                    AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values WHERE used_type = 'PO' AND pk_id = p_poh_id AND attr_id = v_three_way_match_attr_id AND attr_value = 'YES');

                IF NVL(v_rowcount, 0) > 0 THEN
                    v_error_message := 'MAR-MP004 #1' || p_action || ' #2' || v_oc_code;
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;

--Ruby Other Cost in PO Item level is not allowed in JDE and also in ORACLE (by disabled the screen)
--                v_rowcount := 0;
--                SELECT COUNT(*), MAX(o.oc_code)
--                    INTO v_rowcount, v_oc_code
--                    FROM m_sys.m_used_other_costs u, m_sys.m_jobs j, m_sys.m_other_costs o, m_sys.m_po_line_items i
--                    WHERE i.poh_id  = p_poh_id
--                    AND u.pk_id     = i.poli_id
--                    AND u.term_type = 'PLI'
--                    AND u.oc_id      = o.oc_id
--                    AND u.job_id     = j.job_id
--                    /*AND NVL(j.field6, 'NO') = 'YES' -- CHanged column which indicates Active account -01/15/202 - CG*/
--                    AND NVL(j.field7, 'N') = 'Y'
--                    AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values WHERE used_type = 'PO' AND pk_id = p_poh_id AND attr_id = v_three_way_match_attr_id AND attr_value = 'YES');
--
--                IF NVL(v_rowcount, 0) > 0 THEN
--                    v_error_message := 'MAR-MP005 #1' || p_action || ' #2' || v_oc_code;
--                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
--                    RETURN 1;
--                END IF;

            ELSIF (mdr_fin_sys_ = 'JDE') THEN
                SELECT COUNT(*), MAX(o.oc_code)
                    INTO v_rowcount, v_oc_code
                    FROM m_sys.m_used_other_costs u, m_sys.m_jobs j, m_sys.m_other_costs o
                    WHERE u.pk_id   = p_poh_id
                    AND u.term_type = 'PO'
                    AND u.job_id    = j.job_id
                    AND u.oc_id     = o.oc_id
                    AND j.field7 IS NULL
                    AND ((UPPER(j.field1) LIKE '%DELETED%') OR (UPPER(j.field2) != 'Y'));

                IF NVL(v_rowcount, 0) > 0 THEN
                    v_error_message := 'MAR-MP004 #1' || p_action || ' #2' || v_oc_code;
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;

            ELSE
               SELECT COUNT(*), MAX(o.oc_code)
                    INTO v_rowcount, v_oc_code
                    FROM m_sys.m_used_other_costs u, m_sys.m_jobs j, m_sys.m_other_costs o
                    WHERE u.pk_id   = p_poh_id
                    AND u.term_type = 'PO'
                    AND u.job_id    = j.job_id
                    AND u.oc_id     = o.oc_id
                    AND j.field7 IS NULL
                    AND j.field6    = 'NO';

                IF NVL(v_rowcount, 0) > 0 THEN
                    v_error_message := 'MAR-MP004 #1' || p_action || ' #2' || v_oc_code;
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;
            END IF;

--Ruby Other Cost in PO Item level is not allowed in JDE and also in ORACLE (by disabled the screen)
--                v_rowcount := 0;
--                SELECT COUNT(*), MAX(o.oc_code)
--                    INTO v_rowcount, v_oc_code
--                    FROM m_sys.m_used_other_costs u, m_sys.m_jobs j, m_sys.m_other_costs o, m_sys.m_po_line_items i
--                    WHERE i.poh_id  = p_poh_id
--                    AND u.pk_id     = i.poli_id
--                    AND u.term_type = 'PLI'
--                    AND u.oc_id      = o.oc_id
--                    AND u.job_id     = j.job_id
--                    /*AND NVL(j.field6, 'NO') = 'YES' -- CHanged column which indicates Active account -01/15/202 - CG*/
--                    AND NVL(j.field7, 'N') = 'Y'
--                    AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values WHERE used_type = 'PO' AND pk_id = p_poh_id AND attr_id = v_three_way_match_attr_id AND attr_value = 'YES');
--
--                IF NVL(v_rowcount, 0) > 0 THEN
--                    v_error_message := 'MAR-MP005 #1' || p_action || ' #2' || v_oc_code;
--                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
--                    RETURN 1;
--                END IF;


--Ruby comment as PO Header is mandatory so this conditions is never TRUE
--            IF NVL(v_header_job_id, 0) = 0 THEN
--                v_rowcount := 0;
--
--                SELECT COUNT(*), MAX(o.oc_code)
--                    INTO v_rowcount, v_oc_code
--                    FROM m_sys.m_used_other_costs u, m_sys.m_other_costs o
--                    WHERE u.pk_id   = p_poh_id
--                    AND u.term_type = 'PO'
--                    AND u.oc_id     = o.oc_id
--                    AND u.job_id IS NULL
--                    AND NOT EXISTS (SELECT 1 FROM m_sys.m_used_values WHERE used_type = 'PO' AND pk_id = p_poh_id AND attr_id = v_three_way_match_attr_id AND attr_value = 'YES');
--
--                IF NVL(v_rowcount, 0) > 0 THEN
--                    v_error_message := 'MAR-MP006 #1' || p_action || ' #2' || v_oc_code;
--                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
--                    RETURN 1;
--                END IF;
--            END IF;
--End here
        END IF;

            /****************************************************************************
            -- Get the Previous Rev PO Entity ID
            BEGIN
                v_rowcount := 0;
                v_prev_rev_entity := 0;
                IF NVL(v_po_supp, 0) > 0 THEN
                    v_error_message := 'PO Rev A/C not found';
                    SELECT COUNT(*), MAX(field1)
                      INTO v_rowcount, v_prev_rev_entity
                      FROM (SELECT DISTINCT j.field1 FROM m_sys.m_po_headers h, m_sys.m_used_other_costs u, m_sys.m_jobs j WHERE h.base_poh_id = v_base_poh_id AND h.po_supp = (v_po_supp - 1) AND u.pk_id = h.poh_id AND u.term_type = 'PO' AND u.job_id = j.job_id
                            UNION
                            SELECT DISTINCT j.field1 FROM m_sys.m_po_line_items i, m_sys.m_po_line_items hi, m_sys.m_jobs j WHERE i.poh_id = p_poh_id AND hi.poli_id = i.parent_poli_id AND hi.job_id = j.job_id
                            UNION
                            SELECT DISTINCT j.field1 FROM m_sys.m_po_headers h, m_sys.m_jobs j WHERE h.base_poh_id = v_base_poh_id AND h.po_supp = (v_po_supp - 1) AND h.job_id = j.job_id
                            );

                    -- If no record found go back to rev 0
                    IF NVL(v_rowcount, 0) = 0 THEN
                        v_rowcount := 0;
                        v_prev_rev_entity := 0;
                        SELECT COUNT(*), MAX(field1)
                          INTO v_rowcount, v_prev_rev_entity
                          FROM (SELECT DISTINCT j.field1 FROM m_sys.m_used_other_costs u, m_sys.m_jobs j WHERE u.pk_id = v_base_poh_id AND u.term_type = 'PO' AND u.job_id = j.job_id
                                UNION
                                SELECT DISTINCT j.field1 FROM m_sys.m_po_line_items i, m_sys.m_jobs j WHERE i.poh_id = v_base_poh_id AND i.job_id = j.job_id
                                UNION
                                SELECT DISTINCT j.field1 FROM m_sys.m_po_headers h, m_sys.m_jobs j WHERE h.base_poh_id = v_base_poh_id AND h.job_id = j.job_id
                                );
                    END IF;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_rowcount := 0;
                    v_prev_rev_entity := 0;
                WHEN OTHERS THEN
                    v_error_message := 'MAR-MP025 #1' || p_action || ' ' || SQLERRM;
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
            END;

            v_error_message := 'header and item entity not same';

            -- 2.3.4.    Check if the Entity (m_sys.m_jobs.field1) of the Header, Item and Other Cost Job Codes are the same.
            v_rowcount := 0;
            v_entity := 0;

            SELECT COUNT(*), MAX(field1)
              INTO v_rowcount, v_entity
              FROM (SELECT DISTINCT j.field1 FROM m_sys.m_used_other_costs u, m_sys.m_jobs j WHERE u.pk_id = p_poh_id AND u.term_type = 'PO' AND u.job_id = j.job_id
                    UNION
                    SELECT DISTINCT j.field1 FROM m_sys.m_po_line_items i, m_sys.m_jobs j WHERE i.poh_id = p_poh_id AND i.job_id = j.job_id
                    UNION
                    SELECT DISTINCT j.field1 FROM m_sys.m_po_headers h, m_sys.m_jobs j WHERE h.poh_id = p_poh_id AND h.job_id = j.job_id
                    );

            IF NVL(v_rowcount, 0) > 1 THEN
                v_error_message := 'MAR-MP008 #1' || p_action || ' #2' || v_rowcount;
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

            SELECT MAX(j.field1)
              INTO v_entity
              FROM m_sys.m_po_headers h, m_sys.m_jobs j
             WHERE h.poh_id = p_poh_id
               AND h.job_id = j.job_id;

            -- CWH Agreement does not have Entity in Agreement Number
            IF v_project_type = 'PROJECT' AND NVL(v_entity, '#$%') <> NVL(v_po_number_entity, '#$%') AND NVL(v_sup_id, 0) <> 100 THEN
                v_error_message := 'MAR-MP031 #1' || p_action || ' #2header A/C Dist entity ' || trim(v_entity) || ' #3' || NVL(v_po_number_entity, 'null'); --Agreement cannot be approved as Agreement Number entity does not match header entity
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

            -- If there were not item, header or OC changes then no entity will be returned. In which case use the base entity_id
            IF NVL(v_rowcount, 0) = 0 THEN
                v_entity := v_prev_rev_entity;
            END IF;
         ****************************************************************************/


        -- 2.3.5.    Check if all items with Zero '0' Value have a comment.
        v_rowcount := 0;

        v_error_message := 'item comment not found';
        SELECT COUNT(*), MAX(poli_pos)
            INTO v_rowcount, v_poli_pos
            FROM m_sys.m_po_line_items
            WHERE poh_id = p_poh_id
            AND (NVL(poli_qty, 0) = 0 OR NVL(poli_unit_price, 0) = 0)
            AND NVL(poli_comment, '#$%') = '#$%';

        IF NVL(v_poli_pos, 0) > 0 THEN
            v_error_message := 'MAR-MP009 #1' || p_action || ' #2' || v_poli_pos;
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;

        -- Get the Order Value
        SELECT NVL(SUM(total_price),0)
            INTO v_total_price
            FROM m_sys.m_po_total_costs
            WHERE poh_id = p_poh_id;

        BEGIN
            SELECT MAX(unit_id)
                INTO v_usd_currency_id
                FROM m_sys.m_units
                WHERE unit_code = 'USD';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_usd_currency_id := 0;
        END;

        -- Covert to USD
        IF NVL(v_usd_currency_id, 0) > 0 THEN
            v_total_usd_price := mdr_convert_units (v_currency_id, v_usd_currency_id, v_total_price, v_proj_id);

            IF NVL(v_total_usd_price, 0) < 0 THEN
                v_error_message := 'MAR-MP046 #1' || p_action || ' #2' || v_currency_code || ' (' || v_currency_id || ') to USD (' || v_usd_currency_id || ') ' || v_total_usd_price;
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;
        ELSE
            v_error_message := 'MAR-MP045 #1' || p_action;
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
        END IF;


        /**************************************Obsolete attribute for 8.x consolidation -01/16/20- CG********************************
          v_req_rev_project := NVL(get_attribute_value ('ER', v_r_id, 'REVENUE_PROJECT'), '#$#');  -- MZ, Get revenue project name from requistion
        ***************************************************************************************************************************************/

        -- 3.3.21.2. If select code is '8' or '9' the Agreement Header Attributes LOWEST_SUPPLIER_PRICE and LOWEST_SUPPLIER_NAME must be specified.
        -- TECHNICALLY ACCEPTABLE LOW BID, BEST DELIVERY


        v_error_message := 'PO Select Code not found';

        IF NVL(v_select_code, '#$%') IN ('8', '9') THEN
            IF NVL(v_lowest_supplier_price, 0) = 0 OR NVL(v_lowest_supplier_name, '#$%') = '#$%' THEN
                v_error_message := 'MAR-MP044 #1' || p_action || ' #2not specified for Select Code ' || v_select_code_full || ' Agreement';
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;
        ELSIF NVL(v_select_code, '#$%') = '5' THEN
            -- 3.3.21.3. If select code is not '8' or '9' the Agreement Header Attributes LOWEST_SUPPLIER_PRICE and LOWEST_SUPPLIER_NAME must be cleared.
            IF NVL(v_lowest_supplier_price, 0) <> 0 OR NVL(v_lowest_supplier_name, '#$%') <> '#$%' THEN
                v_error_message := 'MAR-MP044 #1' || p_action || ' #2specified for Select Code ' || v_select_code_full || ' Agreement';
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

            -- If Sole Source, Agreement cannot be > $v_mdr_sel5_max_amt_prj for Project
            -- and $v_mdr_sel5_max_amt_mro for Non Project -- MZ
            /*    IF v_project_type = 'PROJECT' THEN ***Obsolete attribute for 8.x consolidation-01/16- CG ********/

            IF NVL(v_total_usd_price, 0) > NVL(v_mdr_sel5_max_amt_prj, 0) THEN    -- Allowed amount for Project PO
                v_error_message := 'MAR-MP042 #1' || p_action || ' #2' || v_total_usd_price || ' USD is #3'   || NVL(v_mdr_sel5_max_amt_prj, 0) || '#4 Select Code ' || v_select_code_full;
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;

            /**********Obsolete attribute for 8.x consolidation-01/16- CG ************************
            ELSE
                IF INSTR(v_po_number, v_req_rev_project) > 0 THEN -- MZ, Check Project PO in Non Project
                    IF NVL(v_total_usd_price, 0) > v_mdr_sel5_max_amt_prj THEN  -- Allowed amount for Project PO
                        v_error_message := 'MAR-MP042 #1' || p_action || ' #2' || v_total_usd_price || ' USD is #3'   || v_mdr_sel5_max_amt_prj || '#4 Select Code ' || v_select_code_full;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;
                ELSE
                    IF NVL(v_total_usd_price, 0) > v_mdr_sel5_max_amt_mro THEN -- Allowed amount for Non Project PO
                        v_error_message := 'MAR-MP043 #1' || p_action || ' #2' || ' USD is #3'   || v_mdr_sel5_max_amt_mro || '#4 Select Code ' || v_select_code_full;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;
                END IF;
            END IF; ************************************************************************/
        ELSE
            -- 3.3.21.3. If select code is not '8' or '9' the Agreement Header Attributes LOWEST_SUPPLIER_PRICE and LOWEST_SUPPLIER_NAME must be cleared.
            IF NVL(v_lowest_supplier_price, 0) <> 0 OR NVL(v_lowest_supplier_name, '#$%') <> '#$%' THEN
                v_error_message := 'MAR-MP044 #1' || p_action || ' #2specified for Select Code ' || v_select_code_full || ' Agreement';
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;
        END IF;

        v_error_message := 'item Export Lic not found';
        -- 2.3.12.    Set the 'Exp Lic Req' checkbox for items where the Commodity Code has LTC_ECL_CLASS Attribute set to any value. Do not reset the checkbox if the LTC_ECL_CLASS is not set.
        OPEN mdr_po_items;
            LOOP
                FETCH mdr_po_items INTO v_poli_id;
                EXIT WHEN mdr_po_items%NOTFOUND;

                v_error_message := 'item ' || v_poli_id || ' Export Lic not found';
                SELECT MAX(c.disused), MAX(c.commodity_code), MAX(p.poli_pos)
                    INTO v_disused, v_commodity_code, v_poli_pos
                    FROM m_sys.m_po_line_items p, m_sys.m_commodity_codes c, m_sys.m_idents i
                    WHERE p.poli_id    = v_poli_id
                    AND i.ident        = p.ident
                    AND c.commodity_id = i.commodity_id;

                IF NVL(v_commodity_code, '#$%') = '#$%' THEN
                    v_error_message := 'MAR-MP040 #1' || p_action || ' #2' || v_poli_pos;  -- Commodity Code not specified
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;

                IF NVL(v_disused, 'N') = 'Y' THEN
                    v_error_message := 'MAR-MP041 #1' || p_action || ' #2' || v_poli_pos || '-' || v_commodity_code;  -- Disused Commodity Code specified
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    RETURN 1;
                END IF;

                v_export_license_req_ind := 'N';

                SELECT MAX('Y')
                    INTO v_export_license_req_ind
                    FROM m_sys.m_po_line_items p, m_sys.m_commodity_codes c, m_sys.m_idents i
                    WHERE p.poli_id    = v_poli_id
                    AND i.ident        = p.ident
                    AND c.commodity_id = i.commodity_id
                    AND c.attr_char2 IS NOT NULL;

                IF NVL(v_export_license_req_ind, 'N') = 'Y' THEN
                    BEGIN
                        v_error_message := 'item ' || v_poli_id || ' Export Lic could not be updated';
                        UPDATE m_sys.m_po_line_items
                            SET export_license_req_ind = 'Y'
                            WHERE poli_id = v_poli_id
                            AND export_license_req_ind = 'N';

                        UPDATE m_sys.m_item_ships
                            SET export_license_req_ind = 'Y'
                            WHERE poli_id = v_poli_id
                            AND export_license_req_ind = 'N';
                    EXCEPTION
                        WHEN OTHERS THEN
                            v_error_message := 'MAR-MP017 #1' || p_action || ' #2' || SQLERRM;
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                    END;
                END IF;
            END LOOP;
        CLOSE mdr_po_items;


        -- Do not make certain checks for Blanket Orders, Master Agreement, Service Orders
        IF (v_base_order_type <> 'BO') AND (v_base_order_sub_type NOT IN ('MA', 'SV')) THEN
            -- Check if all items have Country of Origin
            v_error_message := 'PO Country of Origin not found';
            SELECT COUNT(*), MAX(poli_pos)
                INTO v_rowcount, v_poli_pos
                FROM m_sys.m_po_line_items
                WHERE poh_id = p_poh_id
                AND cy_id IS NULL;

            IF NVL(v_rowcount, 0) > 0 THEN
                v_error_message := 'MAR-MP034 #1' || p_action || ' #2' || v_poli_pos;  -- Agreement cannot be approved as it does not have a Country of Origin Code
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN 1;
            END IF;


            IF (mdr_fin_sys_ = 'ORACLE') OR (mdr_fin_sys_ = 'OLIVES')  THEN
                v_error_message := 'regular invoice not found';
                -- Get the Regular Invoiced Amount
                SELECT NVL(SUM(invoiced_amount), 0)
                    INTO v_invoiced_amount
                    FROM interface.invoice_headers
                    WHERE base_poh_id = v_base_poh_id
                    AND invoice_type  = 'R';

                -- Get the Regular Invoiced PP Amount
                SELECT NVL(SUM(p.invoiced_amount), 0)
                    INTO v_invoiced_pp_amount
                    FROM interface.invoice_headers h, interface.invoice_period_progress p
                    WHERE h.base_poh_id   = v_base_poh_id
                    AND h.invoice_type    = 'R'
                    AND h.olives_instance = p.olives_instance
                    AND h.invoice_control = p.invoice_control;

                v_three_way_match := 'NO';
                v_three_way_match_pp := 'NO';

                -- Get latest poh_id
                SELECT NVL(MAX(poh_id),0)
                    INTO v_last_poh_id
                    FROM m_sys.m_po_headers
                    WHERE base_poh_id = v_base_poh_id
                    AND po_issue_date IS NOT NULL;

                -- Get the Approved Period Progres Amount for 31, 32 and 33 PO's
                IF v_payment_mode = 'M' THEN

                -- 1. Get the Approved Period Progres Amount
                    SELECT NVL(SUM(decode(pn.approved_by, NULL, 0, round(m_sys.m_pck_contract.pno_period_auth_total(pn.pno_id, v_payment_type), 4))), 0)
                        INTO v_pp_value
                        FROM m_sys.m_progress_numbers pn, m_sys.m_po_headers h
                        WHERE h.base_poh_id = v_base_poh_id
                        AND h.poh_id        = pn.poh_id
                        AND pn.approved_date IS NOT NULL;

                    -- 2.3.16.    Set THREE_WAY_MATCH Attribute for a Sub Contract Agreement, if Agreement Amount = Approved Period Progress Amount = Invoiced Amount.
                    v_update_status := 'SUCCESS';
                    IF (TRUNC(NVL(v_total_price, 0)) = TRUNC(NVL(v_pp_value, 0)) AND TRUNC(NVL(v_pp_value, 0)) = TRUNC(NVL(v_invoiced_amount, 0))) OR
                       (ROUND(NVL(v_total_price, 0)) = ROUND(NVL(v_pp_value, 0)) AND ROUND(NVL(v_pp_value, 0)) = ROUND(NVL(v_invoiced_amount, 0))) THEN
                        v_three_way_match := 'YES';
                    ELSIF (TRUNC(NVL(v_total_price, 0)) < TRUNC(NVL(v_invoiced_amount, 0)) OR TRUNC(NVL(v_pp_value, 0)) < TRUNC(NVL(v_invoiced_amount, 0))) OR
                          (ROUND(NVL(v_total_price, 0)) < ROUND(NVL(v_invoiced_amount, 0)) OR ROUND(NVL(v_pp_value, 0)) < ROUND(NVL(v_invoiced_amount, 0))) THEN
                        v_three_way_match := 'ERROR';
                        v_error_3way_message := 'PP Header Amount or Approved Amount is less than Invoiced Amount.'; -- MZ-3wayFix
                    ELSE
                        v_three_way_match := 'NO';
                    END IF;

                    -- MZ-3wayFix
                    v_update_status := interface.mdr_interface_utl8x.log_po_message (0, v_base_poh_id, p_poh_id, v_po_number, v_po_supp, v_payment_mode_code,
                                -- POLI_ID, PP_ID, UOC_ID, POLI_NO,  (PP_ID = -1, PP header record.)
                                0, -1, 0, 0,
                                -- PO_AMOUNT, PO_APPROVED_AMOUNT, PO_QUANTITY, MRR_QUANTITY, INVOICE_QUANTITY, INVOICE_AMOUNT,
                                v_total_price, v_pp_value, 0, 0, 0, v_invoiced_amount,
                                -- RECORD_STATUS, COMMENTS
                                v_three_way_match, v_error_3way_message);


                    -- 2.3.8.    Check if Agreement Amount and SUM(Approved Period Progress Amount) >= SUM(Invoiced Amount) is true for Sub Contract Agreement.
                    IF TRUNC(NVL(v_total_price, 0)) < TRUNC(NVL(v_invoiced_amount, 0))   OR ROUND(NVL(v_total_price, 0)) < ROUND(NVL(v_invoiced_amount, 0)) THEN
                        v_error_message := 'MAR-MP012 #1' || p_action || ' #2SC Agreement Amount ' || v_total_price || ' < PP Invoiced Amount ' || v_invoiced_amount;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;
                    IF TRUNC(NVL(v_pp_value, 0)) < TRUNC(NVL(v_invoiced_amount, 0))  OR ROUND(NVL(v_pp_value, 0)) < ROUND(NVL(v_invoiced_amount, 0))THEN
                        v_error_message := 'MAR-MP012 #1' || p_action || ' #2SC Period Progress Amount ' || v_pp_value || ' < PP Invoiced Amount ' || v_invoiced_amount;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;

                    v_pp_value := 0;
                    v_error_message := 'Item Recv Qty not found';

                    -- 2. Loop through all PP for PO  -- MZZ1
                    OPEN c_pp_items;
                    LOOP
                        FETCH c_pp_items INTO  v_pp_id, v_pp_item_amount;
                        EXIT WHEN c_pp_items%NOTFOUND;

                        SELECT ROUND(SUM(p.invoiced_amount),4)
                            INTO v_pp_item_invoiced_amount
                            FROM interface.invoice_period_progress p, interface.invoice_headers h
                            WHERE p.period_progress_id = v_pp_id
                            AND p.olives_instance = h.olives_instance
                            AND p.invoice_control = h.invoice_control
                            AND p.base_poh_id     = h.base_poh_id
                            AND h.base_poh_id     = v_base_poh_id
                            AND h.invoice_type    = 'R';

                        IF TRUNC(NVL(v_pp_item_amount,0)) = TRUNC(NVL(v_pp_item_invoiced_amount,0)) OR ROUND(NVL(v_pp_item_amount,0)) = ROUND(NVL(v_pp_item_invoiced_amount,0)) THEN
                            v_three_way_match_pp := 'YES';
                        ELSIF TRUNC(NVL(v_pp_item_amount,0)) < TRUNC(NVL(v_pp_item_invoiced_amount,0)) OR ROUND(NVL(v_pp_item_amount,0)) < ROUND(NVL(v_pp_item_invoiced_amount,0)) THEN
                            v_three_way_match_pp := 'ERROR';
                            v_three_way_match := 'ERROR';
                            v_error_3way_message := 'PP item Amount less than Invoiced Quantity.'; -- MZ-3wayFix
                        ELSE
                            v_three_way_match_pp := 'NO';
                            IF v_three_way_match_pp = 'NO' AND v_three_way_match = 'YES' THEN
                                v_three_way_match := v_three_way_match_pp;
                            END IF;
                        END IF;

                        -- MZ-3wayFix
                        v_update_status := interface.mdr_interface_utl8x.log_po_message (0, v_base_poh_id, p_poh_id, v_po_number, v_po_supp, v_payment_mode_code,
                                -- POLI_ID, PP_ID, UOC_ID, POLI_NO,
                                0, v_pp_id, 0, 0,
                                -- PO_AMOUNT, PO_APPROVED_AMOUNT, PO_QUANTITY, MRR_QUANTITY, INVOICE_QUANTITY, INVOICE_AMOUNT,
                                0, 0, v_pp_item_amount, 0, 0, v_pp_item_invoiced_amount,
                                -- RECORD_STATUS, COMMENTS
                                v_three_way_match_pp, v_error_3way_message);


                        v_update_status := 'SUCCESS';

                    END LOOP; -- end of PP loop
                    CLOSE c_pp_items;

                    -- 3. Loop through PP Agreement Items for items received -- MZZ2
                    OPEN mdr_po_items;
                    LOOP
                        FETCH mdr_po_items INTO v_poli_id;
                        EXIT WHEN mdr_po_items%NOTFOUND;

                        v_error_message := 'Item ' || v_poli_id || ' Recv Qty not found';
                        v_poli_pos := 0;
                        v_poli_qty := 0;
                        v_recv_qty := 0;
                        v_tolerance_qty := -9999; -- MZZ2
                        v_recv_tolerance_ind := 'NO'; --MZZ3
                        v_quantity_invoiced := 0;
                        v_three_way_match_item := 'NO';
                        v_error_3way_message := ''; -- MZ-3wayFix

                        SELECT MAX(poli_qty), MAX(poli_pos), MAX(frt_id), MAX(qty_unit_id), MAX(ident)
                            INTO v_poli_qty, v_poli_pos, v_frt_id, v_item_qty_unit_id, v_item_ident
                            FROM m_sys.m_po_line_items
                            WHERE poli_id = v_poli_id;

                        SELECT NVL((SELECT SUM(recv_qty)
                                    FROM m_sys.m_inv_receipts r, m_sys.m_item_ships s, m_sys.m_po_line_items p, m_sys.m_po_headers h, m_sys.m_matl_recv_rpts g
                                    WHERE h.base_poh_id = v_base_poh_id
                                    AND p.poh_id        = h.poh_id
                                    AND p.poli_pos      = v_poli_pos
                                    AND s.poli_id       = p.poli_id
                                    AND r.item_ship_id  = s.item_ship_id
                                    AND g.mrr_id        = r.mrr_id
                                    AND g.posted_date IS NOT NULL), 0) + NVL((SELECT SUM(recv_qty * -1)
                                                                              FROM m_sys.m_inv_receipts
                                                                              WHERE inv_receipt_id IN (SELECT r.last_inv_receipt_id
                                                                                                        FROM m_sys.m_inv_receipts r, m_sys.m_item_ships s, m_sys.m_po_line_items p, m_sys.m_po_headers h, m_sys.m_matl_recv_rpts g
                                                                                                        WHERE h.base_poh_id = v_base_poh_id
                                                                                                        AND p.poh_id        = h.poh_id
                                                                                                        AND p.poli_pos      = v_poli_pos
                                                                                                        AND s.poli_id       = p.poli_id
                                                                                                        AND g.mrr_id        = r.mrr_id
                                                                                                        AND r.item_ship_id  = s.item_ship_id)), 0)
                        INTO v_recv_qty
                        FROM DUAL;

                        -- Get tolerance Qty from OSD type Completely Received. -- MZZ3
                        SELECT NVL(SUM(osd.osd_qty),-9999)
                            INTO v_tolerance_qty
                            FROM m_sys.m_inv_receipts r, m_sys.m_item_ships s, m_sys.m_po_line_items p, m_sys.m_po_headers h, m_sys.m_matl_recv_rpts g, m_sys.m_osds osd
                            WHERE h.base_poh_id    = v_base_poh_id
                            AND p.poh_id           = h.poh_id
                            AND p.poli_pos         = v_poli_pos
                            AND s.poli_id          = p.poli_id
                            AND r.item_ship_id     = s.item_ship_id
                            AND g.mrr_id           = r.mrr_id
                            AND g.posted_date IS NOT NULL
                            AND osd.proj_id        = r.proj_id
                            AND osd.item_ship_id   = r.item_ship_id
                            AND osd.inv_receipt_id = r.inv_receipt_id
                            AND osd.osd_closed_date IS NOT NULL
                            AND g.revision_id      = (SELECT MAX(revision_id) FROM m_sys.m_matl_recv_rpts WHERE proj_id = g.proj_id AND mrr_id = g.mrr_id);  -- Tolerance for MRR Qty

                        IF v_tolerance_qty <> -9999 THEN
                            v_recv_tolerance_ind:= 'YES';
                        END IF;

                        v_error_message := 'Item ' || v_poli_pos || ' Invoice Qty not found';
                        SELECT SUM(i.quantity_invoiced)
                            INTO v_quantity_invoiced
                            FROM interface.invoice_items i, interface.invoice_headers h
                            WHERE h.base_poh_id   = v_base_poh_id
                            AND h.invoice_type    = 'R'
                            AND i.olives_instance = h.olives_instance
                            AND i.invoice_control = h.invoice_control
                            AND i.poli_pos        = v_poli_pos;

                        -- Get TOGGLE_COMPLETE -- MZZ

                        v_toggle_complete := 'NO';

                        v_toggle_complete := interface.mdr_interface_utl8x.get_toggle_complete_attribute('IRC_A', v_toggle_complete_id, v_base_poh_id, v_poli_pos);

                        v_received_complete := 'NO';
                        -- Check if PO item fully received. -- MZZ
                        IF v_toggle_complete = 'YES' OR NVL(v_poli_qty, 0) = NVL(v_recv_qty, 0) OR v_recv_tolerance_ind = 'YES' THEN
                            v_received_complete := 'YES';
                            v_update_status := 'SUCCESS';
                          v_update_status := get_attribute_value ('POLI', v_poli_id, 'RECEIVED_COMPLETE');

                            IF v_update_status <> 'YES' THEN
                                v_update_status := 'SUCCESS';
                                v_update_status := interface.mdr_interface_utl8x.set_attribute_value_no_log (v_received_complete, 'POLI', v_poli_id, v_received_complete_id);

                                IF NVL(v_update_status, 'SUCCESS') <> 'SUCCESS' THEN
                                    v_error_message := 'MAR-MP010 #1' || p_action || ' #2' || v_poli_pos || '-' || v_update_status;
                                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                    RETURN 1;
                                END IF;
                            END IF;
                        END IF;

                        IF NVL(v_poli_qty, 0) = NVL(v_recv_qty, 0) THEN
                            v_three_way_match_item := 'YES';
                        ELSIF v_recv_tolerance_ind = 'YES' THEN -- Tolerance adjusted via OSD - MZZ3
                            v_three_way_match_item := 'YES';
                        ELSIF v_toggle_complete = 'YES' AND (NVL(v_recv_qty, 0) BETWEEN (NVL(v_poli_qty, 0) * 0.9) AND (NVL(v_poli_qty, 0) * 1.1)) THEN -- 11/9/15: Received within 10% of Ordered
                            v_three_way_match_item := 'YES';
                        ELSIF (NVL(v_recv_qty, 0) BETWEEN (NVL(v_poli_qty, 0) * 0.9) AND (NVL(v_poli_qty, 0) * 1.1)) THEN -- 10% MRR tolerance
                            v_three_way_match_item := 'NO';
                            IF v_three_way_match_item = 'NO' AND v_three_way_match = 'YES' THEN
                                v_three_way_match := v_three_way_match_item;
                            END IF;
                        ELSIF NVL(v_poli_qty, 0) < NVL(v_recv_qty, 0) AND v_recv_tolerance_ind <> 'YES' THEN
                            v_three_way_match_item := 'ERROR';
                            v_three_way_match := 'ERROR';
                            v_error_3way_message := 'PP Item Quantity less than Received Quantity. Tolerance set -  ' || v_recv_tolerance_ind  || '.'; -- MZ-3wayFix
                        END IF;

---Added to block users from reducing PO quantity below invoiced quantity - Thua TASK0139926
IF (NVL(v_poli_qty, 0) < NVL(v_quantity_invoiced, 0)) THEN
    v_error_message :=
'MAR-MP066 #1approved. Revise the invoice first before reducing PO Item quantity #2PO Order Quantity < PO Item Invoiced Quantity.';
    RAISE_APPLICATION_ERROR(-20000, v_error_message);
    RETURN 1;
    END IF;

----
                        -- MZ-3wayFix
                        v_update_status := interface.mdr_interface_utl8x.log_po_message (0, v_base_poh_id, p_poh_id, v_po_number, v_po_supp, v_payment_mode_code,
                                    -- POLI_ID, PP_ID, UOC_ID, POLI_NO,
                                    v_poli_id, 0, 0, v_poli_pos,
                                    -- PO_AMOUNT, , PO_APPROVED_AMOUNT, PO_QUANTITY, MRR_QUANTITY, INVOICE_QUANTITY, INVOICE_AMOUNT,
                                    0, 0, v_poli_qty, v_recv_qty, v_quantity_invoiced, 0,
                                    -- RECORD_STATUS, COMMENTS
                                    v_three_way_match_item, v_error_3way_message);

                        v_update_status := 'SUCCESS';
                        v_update_status := interface.mdr_interface_utl8x.set_attribute_value_no_log (v_three_way_match_item, 'POLI', v_poli_id, v_three_way_match_attr_id);

                        IF NVL(v_update_status, 'SUCCESS') <> 'SUCCESS' THEN
                            v_error_message := 'MAR-MP010 #1' || p_action || ' #2' || v_poli_pos || '-' || v_update_status;
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;

                    END LOOP;
                    CLOSE mdr_po_items;


                    -- 4. Get the Other Cost and Approved Period Progres Amount for 31, 32 and 33 PO's
                    v_pp_value := 0;
                    v_oc_value := 0;
                    v_error_message := 'Other Cost Three Way Match not found';

                    SELECT NVL(SUM(o.cost_value), 0), NVL(SUM(DECODE(o.prog_pay_ind, 'Y', o.cost_value, 0)), 0)
                      INTO v_oc_value, v_pp_value
                      FROM m_sys.m_used_other_costs o, m_sys.m_po_headers h
                     WHERE h.base_poh_id = v_base_poh_id
                       AND h.poh_id = o.pk_id
                       AND o.term_type = 'PO';

                    -- Get the OC Invoiced Amount
                    SELECT NVL(SUM(p.invoiced_amount), 0)
                      INTO v_invoiced_oc_amount
                      FROM interface.invoice_headers h, interface.invoice_period_progress p
                     WHERE h.base_poh_id = v_base_poh_id
                       AND h.invoice_type = 'R'
                       AND h.olives_instance = p.olives_instance
                       AND h.invoice_control = p.invoice_control
                       AND p.period_progress_id < 0;

                    IF NVL(ROUND(v_oc_value, 2), 0) > 0 THEN
                        v_three_way_match_pp := 'NO';
                    ELSE
                        v_three_way_match_pp := 'YES';
                    END IF;
                    v_error_message := 'Test 1';

                    -- 2.3.7.    Check if SUM (Header Other Cost Amount) >= SUM(Approved Period Progress Amount) >= SUM(Period Progress Invoiced Amount) is true for Purchase Order Agreement.
                    IF (TRUNC(NVL(v_oc_value, 0)) = TRUNC(NVL(v_pp_value, 0)) AND TRUNC(NVL(v_pp_value, 0)) = TRUNC(NVL(v_invoiced_oc_amount, 0))) OR
                       (ROUND(NVL(v_oc_value, 0)) = ROUND(NVL(v_pp_value, 0)) AND ROUND(NVL(v_pp_value, 0)) = ROUND(NVL(v_invoiced_oc_amount, 0))) THEN
                        v_three_way_match_pp := 'YES';
                    ELSIF TRUNC(NVL(v_oc_value, 0)) < TRUNC(NVL(v_invoiced_oc_amount, 0)) OR TRUNC(NVL(v_pp_value, 0)) < TRUNC(NVL(v_invoiced_oc_amount, 0)) OR
                          ROUND(NVL(v_oc_value, 0)) < ROUND(NVL(v_invoiced_oc_amount, 0)) OR ROUND(NVL(v_pp_value, 0)) < ROUND(NVL(v_invoiced_oc_amount, 0)) THEN
                        v_three_way_match_pp := 'ERROR';
                        v_three_way_match := 'ERROR';
                        v_error_3way_message := 'Header Other Cost Amount or Approved Amount less than Invoiced Amount.'; -- MZ 3wayFix
                    ELSE
                        v_three_way_match_pp := v_three_way_match_pp;
                    END IF;

                    IF v_three_way_match_pp = 'NO' AND v_three_way_match = 'YES' THEN
                        v_three_way_match := v_three_way_match_pp;
                    END IF;
                    v_error_message := 'Test 2';
                    -- MZ-3wayFix
                    v_update_status := interface.mdr_interface_utl8x.log_po_message (0, v_base_poh_id, p_poh_id, v_po_number, v_po_supp, v_payment_mode_code,
                        -- POLI_ID, PP_ID, UOC_ID, POLI_NO,     (UOC_ID = -1 to indicate header UOC total)
                        0, 0, -1, 0,
                        -- PO_AMOUNT, PO_APPROVED_AMOUNT, PO_QUANTITY, MRR_QUANTITY, INVOICE_QUANTITY, INVOICE_AMOUNT,
                        v_oc_value, v_pp_value, 0, 0, 0, v_invoiced_oc_amount,
                        -- RECORD_STATUS, COMMENTS
                        v_three_way_match_pp, v_error_3way_message);

                    -- 2.3.7.    Check if SUM (Header Other Cost Amount) and SUM(Approved Period Progress Amount) >= SUM(Period Progress Invoiced Amount) is true for Purchase Order Agreement.
                    IF NVL(v_three_way_match_pp, '#$%') = 'ERROR' THEN

                        IF TRUNC(NVL(v_oc_value, 0)) < TRUNC(NVL(v_invoiced_oc_amount, 0)) OR ROUND(NVL(v_oc_value, 0)) < ROUND(NVL(v_invoiced_oc_amount, 0)) THEN
                            v_error_message := 'MAR-MP011 #1' || p_action || '#2PO Other Cost ' || v_oc_value || ' < OC Invoice amount ' || v_invoiced_oc_amount;
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;

                        IF TRUNC(NVL(v_pp_value, 0)) < TRUNC(NVL(v_invoiced_oc_amount, 0)) OR ROUND(NVL(v_pp_value, 0)) < ROUND(NVL(v_invoiced_oc_amount, 0)) THEN
                            v_error_message := 'MAR-MP011 #1' || p_action || '#2PO Other Cost Approved Amount ' || v_pp_value || ' < OC Invoice amount ' || v_invoiced_oc_amount;
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;
                    END IF;

                    v_error_message := 'PO Three Way Match could not be set';
                    -- Check if Invoiced Amount <  PO Amount, then keep the PO Open
                    IF (NVL(v_total_price,0) = 0 OR TRUNC(NVL(v_invoiced_amount, 0)) < TRUNC(NVL(v_total_price, 0)) OR ROUND(NVL(v_invoiced_amount, 0)) < ROUND(NVL(v_total_price, 0)) )  AND v_three_way_match = 'YES' THEN
                        v_three_way_match := 'NO';
                    END IF;

                    -- Check if PO Rev <  PO latest Rev, then clear the error from previous rev --MZ2018
                    IF  NVL(v_last_poh_id, 0) > 0 and p_poh_id < v_last_poh_id AND v_three_way_match = 'ERROR' THEN
                        v_three_way_match := 'NO';
                    END IF;

                    v_update_status := interface.mdr_interface_utl8x.set_attribute_value_no_log (v_three_way_match, 'PO', v_base_poh_id, v_three_way_match_attr_id, 'C', 0, 1, 'INTERFACE');

                    IF NVL(v_update_status, 'SUCCESS') <> 'SUCCESS' THEN
                        v_error_message := 'MAR-MP021 #1' || p_action;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;

                    v_update_status := interface.mdr_interface_utl8x.set_attribute_value_no_log (v_three_way_match, 'PO', p_poh_id, v_three_way_match_attr_id, 'C', 0, 1, 'SPMAT');

                    IF NVL(v_update_status, 'SUCCESS') <> 'SUCCESS' THEN
                        v_error_message := 'MAR-MP021 #1' || p_action;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;


                    IF v_payment_mode_code <> '31' THEN -- Do not update 31 type PO -- MZZ2
                        IF v_three_way_match = 'YES' THEN     -- Update PO close date -- MZZ1
                            UPDATE m_sys.m_po_headers
                                SET po_close_date = SYSDATE
                                WHERE base_poh_id = v_base_poh_id
                                AND poh_id = p_poh_id
                                AND po_close_date IS NULL;
                            COMMIT;

                            -- MZ-3wayFix
                            v_update_status := interface.mdr_interface_utl8x.log_po_message (0, v_base_poh_id, p_poh_id, '', 0, v_payment_mode_code,
                                        0, 0, 0, 0,
                                        0, 0, 0, 0, 0, 0, v_three_way_match, 'CLEAR_ALL');
                        ELSE
                            UPDATE m_sys.m_po_headers
                                SET po_close_date = NULL
                                WHERE base_poh_id = v_base_poh_id
                                AND poh_id <= p_poh_id
                                AND po_close_date IS NOT NULL;
                            COMMIT;
                        END IF;
                    END IF;


                ELSE  -- v_payment_mode <> 'M'
                    -- 2.3.11.    For Purchase Order Agreements only (not for Sub Contracts) set the Progress Payment flag
                    BEGIN
                        UPDATE m_sys.m_used_other_costs
                            SET pp_cost_ind = 'Y'
                            WHERE term_type = 'PO'
                            AND pk_id = p_poh_id
                            AND pp_cost_ind = 'N';

                        UPDATE m_sys.m_used_other_costs
                            SET prog_pay_ind = 'Y'
                            WHERE term_type = 'PO'
                            AND pk_id = p_poh_id
                            AND prog_pay_ind = 'N';
                    EXCEPTION
                        WHEN OTHERS THEN
                            v_error_message := 'MAR-MP016 #1' || p_action || ' #2' || LTRIM(RTRIM(SQLERRM));
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                    END;

                    v_error_message := 'Other Cost Three Way Match not found';
                    -- 2.3.15.    Set THREE_WAY_MATCH Attribute for a Purchase Order Agreement, if THREE_WAY_MATCH_PP attribute is set (if it has Other Cost at header level) and THREE_WAY_MATCH is set for all the items.
                    -- Get the Other Cost and Approved Period Progres Amount for Non 31, 32 and 33 PO's

                    -- 1. Get the Other Cost amount for Regular PO
                    SELECT NVL(SUM(o.cost_value), 0), NVL(SUM(DECODE(o.prog_pay_ind, 'Y', o.cost_value, 0)), 0)
                        INTO v_oc_value, v_pp_value
                        FROM m_sys.m_used_other_costs o, m_sys.m_po_headers h
                        WHERE h.base_poh_id = v_base_poh_id
                        AND h.poh_id        = o.pk_id
                        AND o.term_type     = 'PO';

                    -- Get the Regular Invoiced PP Amount
                    SELECT NVL(SUM(p.invoiced_amount), 0)
                        INTO v_invoiced_oc_amount
                        FROM interface.invoice_headers h, interface.invoice_period_progress p
                        WHERE h.base_poh_id   = v_base_poh_id
                        AND h.invoice_type    = 'R'
                        AND h.olives_instance = p.olives_instance
                        AND h.invoice_control = p.invoice_control
                        AND p.period_progress_id < 0;

                    v_error_message := 'Test 3';
                    -- IF there are no other cost assume we have a Three Match PP
                    IF NVL(ROUND(v_oc_value, 2), 0) > 0 THEN
                        v_three_way_match_pp := 'NO';
                    ELSE
                        v_three_way_match_pp := 'YES';
                    END IF;

                    -- 2.3.7.    Check if SUM (Header Other Cost Amount) >= SUM(Approved Period Progress Amount) >= SUM(Period Progress Invoiced Amount) is true for Purchase Order Agreement.
                    IF TRUNC(NVL(v_oc_value, 0)) = TRUNC(NVL(v_pp_value, 0)) AND TRUNC(NVL(v_pp_value, 0)) = TRUNC(NVL(v_invoiced_oc_amount, 0)) THEN
                        v_three_way_match_pp := 'YES';
                    ELSIF TRUNC(NVL(v_oc_value, 0)) < TRUNC(NVL(v_invoiced_oc_amount, 0)) OR TRUNC(NVL(v_pp_value, 0)) < TRUNC(NVL(v_invoiced_oc_amount, 0)) THEN
                        v_three_way_match_pp := 'ERROR';
                        v_error_3way_message := 'Header Other Cost Amount or Approved Amount less than Invoiced Amount.'; -- MZ 3wayFix
                    ELSE
                        v_three_way_match_pp := v_three_way_match_pp;
                    END IF;

                    v_error_message := 'Test 4'||v_base_poh_id||','||p_poh_id||','||v_po_number||','||v_po_supp||','||v_payment_mode_code||','||v_oc_value||','||v_pp_value||','||v_invoiced_oc_amount||','||v_three_way_match_pp||','||v_error_3way_message;
                    -- MZ-3wayFix
                    v_update_status := interface.mdr_interface_utl8x.log_po_message (0, v_base_poh_id, p_poh_id, v_po_number, v_po_supp, v_payment_mode_code,
                        -- POLI_ID, PP_ID, UOC_ID, POLI_NO,     (UOC_ID = -1 to indicate header UOC total)
                        0, 0, -1, 0,
                        -- PO_AMOUNT, PO_APPROVED_AMOUNT, PO_QUANTITY, MRR_QUANTITY, INVOICE_QUANTITY, INVOICE_AMOUNT,
                        v_oc_value, v_pp_value, 0, 0, 0, v_invoiced_oc_amount,
                        -- RECORD_STATUS, COMMENTS
                        v_three_way_match_pp, v_error_3way_message);
                    v_error_message := 'Test 5'||v_update_status;
                    v_three_way_match := v_three_way_match_pp;

                    v_error_message := 'PO Three Way Match could not be set';

                    -- 2.3.7.    Check if SUM (Header Other Cost Amount) and SUM(Approved Period Progress Amount) >= SUM(Period Progress Invoiced Amount) is true for Purchase Order Agreement.
                    IF NVL(v_three_way_match_pp, '#$%') = 'ERROR' THEN
                        IF NVL(TRUNC(v_oc_value), 0) < NVL(TRUNC(v_invoiced_oc_amount), 0) THEN
                            v_error_message := 'MAR-MP011 #1' || p_action || '#2PO Other Cost ' || v_oc_value || ' < OC Invoice amount ' || v_invoiced_oc_amount;
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;

                        IF NVL(TRUNC(v_pp_value), 0) < NVL(TRUNC(v_invoiced_oc_amount), 0) THEN
                            v_error_message := 'MAR-MP011 #1' || p_action || '#2PO Other Cost Approved Amount ' || v_pp_value || ' < OC Invoice amount ' || v_invoiced_oc_amount;
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;
                    END IF;

                    v_error_message := 'Test 5';
                    -- 2.3.6.    Check if Quantity Ordered and Quantity Received >= Quantity Invoiced is true for all items for Purchase Order Agreement.
                    -- 2.3.17.4.    Check if the Ordered quantity >= Invoiced Quantity for all item that have been invoiced. No need to check for Rev 0 as Regular Invoice cannot be assigned to a regular Agreement as quantity and price is not exported until it is issued.

                    v_error_message := 'Item Recv Qty not found';
                    -- 2. Loop through PP Agreement Items for items received
                    OPEN mdr_po_items;
                    LOOP
                        FETCH mdr_po_items INTO v_poli_id;
                        EXIT WHEN mdr_po_items%NOTFOUND;

                        v_error_message := 'Item ' || v_poli_id || ' Recv Qty not found';
                        v_poli_pos := 0;
                        v_poli_qty := 0;
                        v_recv_qty := 0;
                        v_tolerance_qty := -9999;  -- MZZ2
                        v_recv_tolerance_ind:= 'NO'; -- MZZ3
                        v_quantity_invoiced := 0;
                        v_three_way_match_item := 'NO';

                        SELECT MAX(poli_qty), MAX(poli_pos), MAX(frt_id), MAX(qty_unit_id), MAX(ident)
                            INTO v_poli_qty, v_poli_pos, v_frt_id, v_item_qty_unit_id, v_item_ident
                            FROM m_sys.m_po_line_items
                            WHERE poli_id = v_poli_id;

                        SELECT NVL((SELECT SUM(recv_qty)
                                    FROM m_sys.m_inv_receipts r, m_sys.m_item_ships s, m_sys.m_po_line_items p, m_sys.m_po_headers h, m_sys.m_matl_recv_rpts g
                                    WHERE h.base_poh_id = v_base_poh_id
                                    AND p.poh_id        = h.poh_id
                                    AND p.poli_pos      = v_poli_pos
                                    AND s.poli_id       = p.poli_id
                                    AND r.item_ship_id  = s.item_ship_id
                                    AND g.mrr_id        = r.mrr_id
                                    AND g.posted_date IS NOT NULL), 0) +
                                    NVL((SELECT SUM(recv_qty * -1)
                                        FROM m_sys.m_inv_receipts
                                        WHERE inv_receipt_id IN (SELECT r.last_inv_receipt_id
                                                                FROM m_sys.m_inv_receipts r, m_sys.m_item_ships s, m_sys.m_po_line_items p, m_sys.m_po_headers h, m_sys.m_matl_recv_rpts g
                                                                WHERE h.base_poh_id = v_base_poh_id
                                                                AND p.poh_id        = h.poh_id
                                                                AND p.poli_pos      = v_poli_pos
                                                                AND s.poli_id       = p.poli_id
                                                                AND g.mrr_id        = r.mrr_id
                                                                AND r.item_ship_id  = s.item_ship_id)), 0)
                        INTO v_recv_qty
                        FROM DUAL;

                        -- Get tolerance Qty from OSD type Completely Received. -- MZZ3
                        SELECT NVL(SUM(osd.osd_qty),-9999)
                            INTO v_tolerance_qty
                            FROM m_sys.m_inv_receipts r, m_sys.m_item_ships s, m_sys.m_po_line_items p, m_sys.m_po_headers h, m_sys.m_matl_recv_rpts g, m_sys.m_osds osd
                            WHERE h.base_poh_id    = v_base_poh_id
                            AND p.poh_id           = h.poh_id
                            AND p.poli_pos         = v_poli_pos
                            AND s.poli_id          = p.poli_id
                            AND r.item_ship_id     = s.item_ship_id
                            AND g.mrr_id           = r.mrr_id
                            AND g.posted_date IS NOT NULL
                            AND osd.proj_id        = r.proj_id
                            AND osd.item_ship_id   = r.item_ship_id
                            AND osd.inv_receipt_id = r.inv_receipt_id
                            AND osd.osd_closed_date IS NOT NULL
                            --AND osd.osd_type = 'C'
                            AND g.revision_id      = (SELECT MAX(revision_id) FROM m_sys.m_matl_recv_rpts WHERE proj_id = g.proj_id AND mrr_id = g.mrr_id); -- Tolerance for MRR Qty

                        IF v_tolerance_qty <> -9999 THEN
                            v_recv_tolerance_ind:= 'YES';
                        END IF;

                        v_error_message := 'Item ' || v_poli_pos || ' Invoice Qty not found';
                        SELECT SUM(i.quantity_invoiced)
                            INTO v_quantity_invoiced
                            FROM interface.invoice_items i, interface.invoice_headers h
                            WHERE h.base_poh_id   = v_base_poh_id
                            AND h.invoice_type    = 'R'
                            AND i.olives_instance = h.olives_instance
                            AND i.invoice_control = h.invoice_control
                            AND i.poli_pos        = v_poli_pos;

                        -- Get TOGGLE_COMPLETE -- MZZ
                        v_toggle_complete := 'NO';

                        v_toggle_complete := interface.mdr_interface_utl8x.get_toggle_complete_attribute('IRC_A', v_toggle_complete_id, v_base_poh_id, v_poli_pos);

                        v_received_complete := 'NO';
                        -- Check if PO item fully received. -- MZZ
                            IF v_toggle_complete = 'YES' OR NVL(v_poli_qty, 0) = NVL(v_recv_qty, 0) OR v_recv_tolerance_ind = 'YES' THEN
                                v_received_complete := 'YES';

                                v_update_status := 'SUCCESS';

                                v_update_status := get_attribute_value ('POLI', v_poli_id, 'RECEIVED_COMPLETE');

                                IF v_update_status <> 'YES' THEN
                                    v_update_status := 'SUCCESS';
                                    v_update_status := interface.mdr_interface_utl8x.set_attribute_value_no_log (v_received_complete, 'POLI', v_poli_id, v_received_complete_id);

                                    IF NVL(v_update_status, 'SUCCESS') <> 'SUCCESS' THEN
                                        v_error_message := 'MAR-MP010 #1' || p_action || ' #2' || v_poli_pos || '-' || v_update_status;
                                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                        RETURN 1;
                                    END IF;
                                END IF;
                            END IF;

                        IF NVL(v_poli_qty, 0) = NVL(v_recv_qty, 0) AND NVL(v_recv_qty, 0) = NVL(v_quantity_invoiced, 0) THEN
                            v_three_way_match_item := 'YES';
                        ELSIF NVL(v_poli_qty, 0) = NVL(v_recv_qty, 0) AND (NVL(v_quantity_invoiced, 0) BETWEEN (NVL(v_recv_qty, 0)) AND (NVL(v_recv_qty, 0) * 1.02)) THEN  -- 11/9/15: Recvd = Ordered and Invoiced is within 2% of Received
                            v_three_way_match_item := 'YES';
                        ELSIF v_recv_tolerance_ind = 'YES' AND (NVL(v_quantity_invoiced, 0) BETWEEN (NVL(v_recv_qty, 0)) AND (NVL(v_recv_qty, 0) * 1.02)) THEN  -- Tolerance adjusted via OSD - MZZ2
                            v_three_way_match_item := 'YES';
                        ELSIF v_toggle_complete = 'YES' AND (NVL(v_recv_qty, 0) BETWEEN (NVL(v_poli_qty, 0) * 0.9) AND (NVL(v_poli_qty, 0) * 1.1)) AND NVL(v_recv_qty, 0) = NVL(v_quantity_invoiced, 0) THEN -- 11/9/15: Received within 10% of Ordered and Inoviced = Received
                            v_three_way_match_item := 'YES';   -- Not in Use, replaced with recv_tolerance
                        ELSIF (NVL(v_recv_qty, 0) BETWEEN (NVL(v_poli_qty, 0) * 0.9) AND (NVL(v_poli_qty, 0) * 1.1)) THEN -- 10% MRR tolerance
                            v_three_way_match_item := 'NO';
                            IF v_three_way_match_item = 'NO' AND v_three_way_match = 'YES' THEN
                                v_three_way_match := v_three_way_match_item;
                            END IF;
                        ELSIF (NVL(v_poli_qty, 0) < NVL(v_recv_qty, 0)) AND v_recv_tolerance_ind <> 'YES' THEN
                            v_three_way_match_item := 'ERROR';
                            v_three_way_match := 'ERROR';
                            v_error_3way_message := 'PO Item Received Quantity > PO Quantity. Tolerance set - ' || v_recv_tolerance_ind  || '.'; -- MZ-3wayFix
                        ELSIF (NVL(v_quantity_invoiced, 0) > (NVL(v_recv_qty, 0) * 1.02)) THEN
                            v_three_way_match_item := 'ERROR';
                            v_three_way_match := 'ERROR';
                            v_error_3way_message := 'PO Item Invoiced Quantity > Received Quantity.'; -- MZ-3wayFix
                        END IF;

                        -- MZ-3wayFix
                        v_update_status := interface.mdr_interface_utl8x.log_po_message (0, v_base_poh_id, p_poh_id, v_po_number, v_po_supp, v_payment_mode_code,
                                    -- POLI_ID, PP_ID, UOC_ID, POLI_NO,
                                    v_poli_id, 0, 0, v_poli_pos,
                                    -- PO_AMOUNT, , PO_APPROVED_AMOUNT, PO_QUANTITY, MRR_QUANTITY, INVOICE_QUANTITY, INVOICE_AMOUNT,
                                    0, 0, v_poli_qty, v_recv_qty, v_quantity_invoiced, 0,
                                    -- RECORD_STATUS, COMMENTS
                                    v_three_way_match_item, v_error_3way_message);

                        v_update_status := 'SUCCESS';
                        v_update_status := interface.mdr_interface_utl8x.set_attribute_value_no_log (v_three_way_match_item, 'POLI', v_poli_id, v_three_way_match_attr_id);

                        IF NVL(v_update_status, 'SUCCESS') <> 'SUCCESS' THEN
                            v_error_message := 'MAR-MP010 #1' || p_action || ' #2' || v_poli_pos || '-' || v_update_status;
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;

                        -- 2.3.13.    Set the THREE_WAY_MATCH Attribute for the item, if the Quantity Ordered = Quantity Received = Quantity Invoiced.
                        -- We do not have to set the attribute as this will be set during the PO Approval, MRR posting and Invoice import process.
                        IF NVL(v_three_way_match_item, '#$%') = 'ERROR' THEN
                            v_three_way_match := v_three_way_match_item;
                            v_update_status := interface.mdr_interface_utl8x.set_attribute_value_no_log (v_three_way_match, 'PO', v_base_poh_id, v_three_way_match_attr_id, 'C', 0, 1, 'INTERFACE');

                            IF NVL(v_update_status, 'SUCCESS') <> 'SUCCESS' THEN
                                v_error_message := 'MAR-MP021 #1' || p_action;
                                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                RETURN 1;
                            END IF;

                            v_update_status := interface.mdr_interface_utl8x.set_attribute_value_no_log (v_three_way_match, 'PO', p_poh_id, v_three_way_match_attr_id, 'C', 0, 1, 'SPMAT');

                            IF NVL(v_update_status, 'SUCCESS') <> 'SUCCESS' THEN
                                v_error_message := 'MAR-MP021 #1' || p_action;
                                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                RETURN 1;
                            END IF;

                            v_error_message := 'MAR-MP018 #1' || p_action || ' #2' || v_poli_pos || '(Ordered=' || v_poli_qty || ',Received=' || v_recv_qty || ',Invoiced=' || v_quantity_invoiced || ')';
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;

                        IF NVL(v_frt_id, 0) = 0 THEN
                            v_error_message := 'MAR-MP039 #1' || p_action || ' #2' || v_poli_pos; -- Delivery Terms / Inco Terms not specified
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            RETURN 1;
                        END IF;
                    END LOOP;

                    CLOSE mdr_po_items;

                    -- Check if Invoiced Amount <  PO Amount, then keep the PO Open
                    IF (NVL(v_total_price,0) = 0 OR TRUNC(NVL(v_invoiced_amount, 0)) < TRUNC(NVL(v_total_price, 0)) OR ROUND(NVL(v_invoiced_amount, 0)) < ROUND(NVL(v_total_price, 0)))  AND v_three_way_match = 'YES' THEN
                        v_three_way_match := 'NO';
                    END IF;

                    -- Check if PO Rev <  PO latest Rev, then clear the error from previous rev --MZ2018
                    IF  NVL(v_last_poh_id, 0) > 0 and p_poh_id < v_last_poh_id AND v_three_way_match = 'ERROR' THEN
                        v_three_way_match := 'NO';
                    END IF;

                    v_update_status := 'SUCCESS';
                    v_update_status := interface.mdr_interface_utl8x.set_attribute_value_no_log (v_three_way_match, 'PO', v_base_poh_id, v_three_way_match_attr_id, 'C', 0, 1, 'INTERFACE');
                    IF NVL(v_update_status, 'SUCCESS') <> 'SUCCESS' THEN
                        v_error_message := 'MAR-MP020 #1' || p_action;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;

                    v_update_status := interface.mdr_interface_utl8x.set_attribute_value_no_log (v_three_way_match, 'PO', p_poh_id, v_three_way_match_attr_id, 'C', 0, 1, 'SPMAT');

                    IF NVL(v_update_status, 'SUCCESS') <> 'SUCCESS' THEN
                        v_error_message := 'MAR-MP020 #1' || p_action;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;

                    IF v_three_way_match = 'YES' THEN  -- Update PO close date -- MZZ
                        UPDATE m_sys.m_po_headers
                            SET po_close_date = SYSDATE
                            WHERE base_poh_id = v_base_poh_id
                            AND poh_id = p_poh_id
                            AND po_close_date IS NULL;
                        COMMIT;

                        -- MZ-3wayFix
                        v_update_status := interface.mdr_interface_utl8x.log_po_message (0, v_base_poh_id, p_poh_id, '', 0, v_payment_mode_code,
                                    0, 0, 0, 0,
                                    0, 0, 0, 0, 0, 0, v_three_way_match, 'CLEAR_ALL');
                    ELSE
                        UPDATE m_sys.m_po_headers
                            SET po_close_date = NULL
                        WHERE base_poh_id = v_base_poh_id
                        AND poh_id <= p_poh_id
                        AND po_close_date IS NOT NULL;
                        COMMIT;
                    END IF;
                END IF; -- End of v_payment_mode = 'M'

                -- 2.3.17.    For Agreements at Rev 1 or higher with regular invoice:
                IF NVL(v_po_supp, 0) > 0 THEN
                    v_error_message := 'PO Rev Supplier not found';
                    SELECT MAX(currency_id), MAX(sup_id)
                        INTO v_prev_rev_currency_id, v_prev_rev_sup_id
                        FROM m_sys.m_po_headers
                        WHERE base_poh_id = v_base_poh_id
                        AND po_supp = (v_po_supp - 1);

                    SELECT MAX(DECODE(v.attr_value, '31', 'M', '32', 'M', '33', 'M', 'Q'))   -- Milestone Based: 31, 32, 33. Quantity Based: Any other value
                        INTO v_prev_rev_payment_mode
                        FROM m_sys.m_used_values v, m_sys.m_attrs a, m_sys.m_po_headers h
                        WHERE h.base_poh_id = v_base_poh_id
                        AND h.po_supp = (v_po_supp - 1)
                        AND v.pk_id = h.poh_id
                        AND v.used_type = 'PO'
                        AND v.attr_id = a.attr_id
                        AND a.attr_code = 'PAYMENT_MODE';

                    -- 2.3.17.1.    Check if the Supplier (POVENDOR) matches previous revision if there is an invoice related to the Agreement. No need to check for Rev 0 as POVENDOR is assigned during the export process after the Rev 0 of Agreement is issued.
                    IF NVL(v_prev_rev_sup_id, 0) <> NVL(v_sup_id, 0) THEN
                        v_error_message := 'MAR-MP022 #1' || p_action;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;

                    -- 2.3.17.2.    Check if the Currency matches previous revision if there is an invoice related to the Agreement. No need to check for Rev 0 as Regular Invoice cannot be assigned to a regular Agreement as quantity and price is not exported until it is issued.
                    IF NVL(v_prev_rev_currency_id, 0) <> NVL(v_currency_id, 0) THEN
                        v_error_message := 'MAR-MP023 #1' || p_action;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;

                    v_error_message := 'Item Net Unit Price or dicsount does not match prev revision';
                    -- 2.3.17.3.    Check if the Net Unit price and unit of measure for item matches previous revision if there is an invoice related to the item. No need to check for Rev 0 as Regular Invoice cannot be assigned to a regular Agreement as quantity and price is not exported until it is issued.
                    v_poli_pos := 0;

                    SELECT MAX(p.poli_pos)
                        INTO v_poli_pos
                        FROM m_sys.m_po_line_items p, m_sys.m_po_line_items h
                        WHERE p.poh_id = p_poh_id
                        AND p.poli_pos = h.poli_pos
                        AND h.poh_id   = (SELECT MAX(poh_id)
                                            FROM m_sys.m_po_line_items l
                                            WHERE l.poh_id <> p.poh_id
                                            AND poh_id IN (SELECT poh_id
                                                           FROM m_sys.m_po_headers
                                                           WHERE base_poh_id = v_base_poh_id)
                                            AND l.poli_pos = p.poli_pos)
                        AND (NVL(p.poli_unit_price, 0) <> NVL(h.poli_unit_price, 0) OR NVL(p.discount_percent, 0) <> NVL(h.discount_percent, 0))
                        -- NVL(p.discount_amount, 0) <> NVL(h.discount_amount, 0))
                        AND EXISTS (SELECT 1
                                    FROM interface.invoice_headers ih, interface.invoice_items i,m_sys.m_po_line_items l, m_sys.m_po_headers o
                                    WHERE o.base_poh_id = v_base_poh_id
                                    AND l.poh_id = o.poh_id
                                    AND l.poli_pos = p.poli_pos
                                    AND l.poli_id = i.agreement_item_id
                                    AND i.olives_instance = ih.olives_instance
                                    AND i.invoice_control = ih.invoice_control
                                    AND ih.invoice_type = 'R');

                    IF NVL(v_poli_pos, 0) > 0 THEN
                        v_error_message := 'MAR-MP024 #1' || p_action || ' #2' || v_poli_pos;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;

                    v_poli_pos := 0;
                    SELECT MAX(p.poli_pos)
                        INTO v_poli_pos
                        FROM m_sys.m_po_line_items p, m_sys.m_po_line_items h
                        WHERE p.poh_id = p_poh_id
                        --AND h.poli_id = p.parent_poli_id -- Commented by Shruti
                        AND p.poli_pos = h.poli_pos
                        AND h.poh_id = (SELECT MAX(poh_id) FROM m_sys.m_po_line_items l WHERE l.poh_id <> p.poh_id
                        AND poh_id IN (SELECT poh_id FROM m_sys.m_po_headers WHERE base_poh_id = v_base_poh_id) and l.poli_pos = p.poli_pos)
                        AND (NVL(p.qty_unit_id, 0) <> NVL(h.qty_unit_id, 0))
                        AND EXISTS (SELECT 1 FROM interface.invoice_headers ih, interface.invoice_items i, m_sys.m_po_line_items l, m_sys.m_po_headers o WHERE o.base_poh_id = v_base_poh_id AND l.poh_id = o.poh_id AND l.poli_pos = p.poli_pos AND l.poli_id = i.agreement_item_id AND i.olives_instance = ih.olives_instance AND i.invoice_control = ih.invoice_control AND ih.invoice_type = 'R');

                    IF NVL(v_poli_pos, 0) > 0 THEN
                        v_error_message := 'MAR-MP055 #1' || p_action || ' #2' || v_poli_pos;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;

                    /********Obsolete code for 8.x consolidation -01/16/20- CG******O******O
                    -- 2.3.17.6.    The Entity of Job Codes associated with Header, Items or Other Cost in Rev 1 or higher cannot be different than the Entity of the previous rev.
                    IF NVL(v_prev_rev_entity, 0) <> NVL(v_entity, 0) THEN
                        v_error_message := 'MAR-MP025 #1' || p_action || ' #2' || NVL(v_prev_rev_entity, 0) || ' #3' || NVL(v_entity, 0);
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;
                    ******************O******O******/

                    v_error_message := 'invoice found for deleted item';
                    -- 2.3.17.5. Check for deletion of an Item if it has been invoiced
                    v_rowcount := 0;
                    SELECT COUNT(*)
                        INTO v_rowcount
                        FROM interface.invoice_items i
                        WHERE i.base_poh_id = v_base_poh_id
                        AND NOT EXISTS (SELECT 1 FROM m_sys.m_po_line_items p WHERE p.poli_id = i.agreement_item_id);

                    IF NVL(v_poli_pos, 0) > 0 THEN
                        v_error_message := 'MAR-MP027 #1' || p_action || ' #2' || v_rowcount;
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;

                    -- 2.3.17.7.    The value of the PAYMENT_MODE cannot be changed from Milestone based agreement (31, 32, 33) to non Milestone based agreements (other than 31, 32, 33) or vice versa Entity of Job Codes associated with Header, Items or Other Cost in Rev 1 or higher cannot be different than the Entity of the previous rev.
                    IF NVL(v_prev_rev_payment_mode, '#$%') <> NVL(v_payment_mode, '#$%') THEN
                        v_error_message := 'MAR-MP026 #1' || p_action || ' as Payment Mode basis';
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        RETURN 1;
                    END IF;
                END IF;
             END IF; --End of Oracle

        END IF;
        v_error_message := 'No Error';
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            -- Raise an Unknown error
            IF SUBSTR(v_error_message, 1, 4) <> 'MAR-' THEN
                v_error_message := 'MAR-MP066 #1' || p_action || '#2' || v_error_message || '-' || SQLERRM;
            END IF;
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
            RETURN 1;
    END;
END mdr_check_agreement;


PROCEDURE test_mdr_check_agreement (
    p_poh_id                 IN        m_sys.m_po_headers.poh_id%TYPE,
    p_check_only_ind         IN        VARCHAR2
)
IS
    v_message             VARCHAR2 (1000);
BEGIN
    v_message := mdr_check_agreement (p_poh_id, p_check_only_ind);

    update m_sys.m_po_headers
       set comments = v_message
     where poh_id = p_poh_id;
    COMMIT;
END test_mdr_check_agreement;
-- 16-Dec-2019 8.2 - 1 Added 7.1 procedures.

/*
  || ****************************************************************************
  ||
  || gen_inq_number
  || ==============
  ||
  || Intended for generating an inquiry number based on custom specific rules.
  ||
  || This function is called each time an inquiry (supplement) is created.
  ||
  || If NULL is returned the standard default number is taken.
  ||
  || Change history:
  ||
  || When          Who             What
  || -----------   -------------   ----------------------------------------------
  || 04-May-2008   NRiedel         Added parameter p_inq_id
  ||
  || ****************************************************************************
  */
  FUNCTION gen_inq_number(p_inq_id IN m_inquiries.inq_id%TYPE,
                          p_i_supp IN m_inquiries.i_supp%TYPE DEFAULT 0)
    RETURN m_inquiries.inq_code%TYPE IS

    v_proj_id                    m_sys.m_reqs.proj_id%TYPE;
--    v_project_status            m_sys.m_used_values.attr_value%TYPE    DEFAULT 'REGULAR';/******Obsolete attributes for 8.x consolidation -01/16/20 - CG *******/
--    v_project_type                m_sys.m_used_values.attr_value%TYPE    DEFAULT 'PROJECT';/******Obsolete attributes for 8.x consolidation -01/16/20 - CG *******/
    v_name_parts_array            APEX_APPLICATION_GLOBAL.VC_ARR2;
    v_inq_code                    m_sys.m_inquiries.inq_code%TYPE;
    v_new_inq_code                m_sys.m_inquiries.inq_code%TYPE;
    v_rowcount                    NUMBER                            DEFAULT 0;
    v_seq                        VARCHAR2(10);
BEGIN
    -- 16-Dec-2019 8.2 - 1 Added 7.1 procedures.
    IF m_pck_ppd_defaults.get_value('ZO_MDR_PJ') = 'MERGE' THEN
         IF NVL(p_i_supp, 0) > 0 THEN
        RETURN NULL;
    ELSE
        BEGIN
            SELECT proj_id, inq_code
              INTO v_proj_id, v_inq_code
              FROM m_sys.m_inquiries
             WHERE inq_id = p_inq_id;

            /*******Obsolete logic for 8.x consolidation -01/16/20 - CG *******
      v_project_status := NVL(get_project_attribute (v_proj_id, 'PROJECT_STATUS'), 'REGULAR');
            v_project_type := NVL(get_project_attribute (v_proj_id, 'PROJECT_TYPE'), 'PROJECT');
      ***********************/

            v_name_parts_array := APEX_UTIL.STRING_TO_TABLE(v_inq_code, '-');

            v_new_inq_code := v_name_parts_array(1);

            /*******Obsolete logic for 8.x consolidation -01/16/20 - CG *******
      IF v_project_type = 'TENDER' THEN
                v_new_inq_code := v_new_inq_code || '-RFQT';
            ELSE *****************/
                v_new_inq_code := v_new_inq_code || '-RFQ';
    /*    END IF;*/

            IF v_name_parts_array.count > 2 THEN
                FOR i IN 3..v_name_parts_array.count
                LOOP
                    v_new_inq_code := v_new_inq_code || '-' || v_name_parts_array(i);
                END LOOP;
            END IF;

            -- Check if the inquiry code has been previously assigned
            SELECT COUNT(*)
              INTO v_rowcount
              FROM m_sys.m_inquiries
             WHERE proj_id = v_proj_id
               AND inq_code = v_new_inq_code;

            IF NVL(v_rowcount, 0) > 0 THEN
                -- If yes get the next sequence number
                v_inq_code := v_new_inq_code || '-%';

                SELECT COUNT(*)
                  INTO v_rowcount
                  FROM m_sys.m_inquiries
                 WHERE proj_id = v_proj_id
                   AND inq_code LIKE v_inq_code;

                v_rowcount := NVL(v_rowcount, 0) + 1;
                IF v_rowcount < 10 THEN
                    v_seq := '0' || v_rowcount;
                ELSE
                    v_seq := v_rowcount;
                END IF;
                v_new_inq_code := v_new_inq_code || '-' || v_seq;
            END IF;

            RETURN v_new_inq_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN NULL;
        END;
    END IF;
    ELSE
RETURN NULL;
END    IF;
  END; /* gen_inq_number */

  /*
  || ****************************************************************************
  ||
  || gen_order_number
  || ================
  ||
  || Intended for generating an order number based on custom specific rules.
  ||
  || This function is called each time an order (supplement) is created.
  ||
  || If NULL is returned the standard default number is taken.
  ||
  || Change history:
  ||
  || When          Who             What
  || -----------   -------------   ----------------------------------------------
  || 04-May-2008   NRiedel         Added parameter p_poh_id
  ||
  || ****************************************************************************
  */
  FUNCTION gen_order_number(p_poh_id  IN m_po_headers.poh_id%TYPE,
                            p_po_supp IN m_po_headers.po_supp%TYPE DEFAULT 0,
                            p_r_id    IN m_reqs.r_id%TYPE DEFAULT NULL)
    RETURN m_po_headers.po_number%TYPE IS
/********************************SANDEEP to finalise the numbering as requested ************8.x consolidation **************/
    -- SC_0368 replace -MR- with -PO-
    --
    l_po_number  varchar2(50);
    l_cbi_po     varchar2(1);
    l_order_type varchar2(2);

--
    v_base_poh_id               m_sys.m_po_headers.base_poh_id%TYPE;
    v_req_number                m_sys.m_reqs.r_code%TYPE;
    v_name_parts_array            APEX_APPLICATION_GLOBAL.VC_ARR2;
    v_search_str                VARCHAR2(255);
    v_po_last_seq                NUMBER                            DEFAULT 0;
    v_po_new_seq                m_sys.m_po_headers.po_number%TYPE;
    v_new_po_number                m_sys.m_po_headers.po_number%TYPE;
    v_purchase_order_type        VARCHAR2(255);
    v_proj_id                    m_sys.m_reqs.proj_id%TYPE;
    v_mg_id                        m_sys.m_reqs.mg_id%TYPE;
    v_mg_code                    m_sys.m_material_groups.mg_code%TYPE;
    v_project_type                m_sys.m_used_values.attr_value%TYPE    DEFAULT 'PROJECT';
    v_payment_mode_code            m_sys.m_used_values.attr_value%TYPE;
    v_mdr_region                m_sys.m_used_values.attr_value%TYPE;
    v_req_sub_function            m_sys.m_used_values.attr_value%TYPE;
    v_order_type                m_sys.m_po_headers.order_type%TYPE;
    v_order_sub_type            m_sys.m_po_headers.order_sub_type%TYPE;
    v_last_po_number            m_sys.m_po_headers.po_number%TYPE;
    v_sup_id                    m_sys.m_po_headers.sup_id%TYPE;
    v_gl_area                    m_sys.m_table_details.attr_char1%TYPE;
    v_entity                    m_sys.m_table_details.td_code%TYPE;
    v_r_id                        m_sys.m_reqs.r_id%TYPE;

    v_r_code                            m_sys.m_reqs.r_code%TYPE;
    v_order_no                m_sys.m_po_headers.po_number%TYPE;
    v_po_counter                VARCHAR2(10);


  begin



    -- 16-Dec-2019 8.2 - 1 Added 7.1 procedures.
    IF m_pck_ppd_defaults.get_value('ZO_MDR_PJ') = 'MERGE' THEN
        BEGIN
            SELECT base_poh_id, order_type, sup_id, order_sub_type
              INTO v_base_poh_id, v_order_type, v_sup_id, v_order_sub_type
              FROM m_sys.m_po_headers
             WHERE poh_id = p_poh_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;


        IF p_po_supp = 0 THEN
            -- If BOR
            IF v_order_sub_type = 'BOR' THEN

                BEGIN
                    SELECT MAX(r_id)
                      INTO v_r_id
                      FROM m_sys.m_req_to_pos
                     WHERE base_poh_id = p_poh_id;
                EXCEPTION
                    WHEN OTHERS THEN
                    v_r_id := NULL;
                END;

                IF NVL(v_r_id, 0) = 0 THEN
                    BEGIN
                    SELECT MAX(r_id)
                      INTO v_r_id
                      FROM m_sys.m_req_li_to_polis
                     WHERE poh_id = p_poh_id;
                    EXCEPTION
                    WHEN OTHERS THEN
                        v_r_id := 0;
                    END;
                END IF;


                SELECT MAX(proj_id), MAX(r_code)
                INTO   v_proj_id, v_r_code
                FROM   m_reqs
                WHERE  r_id = v_r_id;


                SELECT    REPLACE(SUBSTR(v_r_code,0,INSTR(v_r_code,'-',-1)-1),'-PR-','-PO-')
                INTO    v_r_code
                FROM    dual;

                v_order_no :=  v_r_code||'-';

                SELECT    LPAD(NVL(MAX(TO_NUMBER(SUBSTR(po_number,INSTR(po_number, '-', -1, 1)+1)))+1,1),2,'0')
                INTO    v_po_counter
                FROM    m_po_headers r
                WHERE    po_number LIKE v_order_no||'%'
                AND    poh_id <> p_poh_id;

                -- v_order_no :=  v_order_no||v_po_counter||'-'||p_po_supp; -- Removed supplement from PO numbering.
                v_order_no :=  v_order_no||v_po_counter;

            ELSE

                IF p_r_id IS NOT NULL THEN
                    SELECT MAX(proj_id), MAX(r_code)
                    INTO   v_proj_id, v_r_code
                    FROM   m_reqs
                    WHERE  r_id = p_r_id;

                    IF (INSTR(v_r_code, '-', 1, 4) > 0) THEN
                        -- Corporate Warehouse PO Number Project-CWH-Region-SubFn-Seq
                        IF NVL(v_sup_id, 0) = 100 THEN
                            v_r_code := SUBSTR(v_r_code,0,INSTR(v_r_code,'-',1)-1)||'-CW-'||SUBSTR(v_r_code,INSTR(v_r_code,'-',1,2)+1,(INSTR(v_r_code,'-',-1)-1)-(INSTR(v_r_code,'-',1,2)));
                        ELSIF NVL(v_sup_id, 0) = 200 THEN
                            v_r_code := SUBSTR(v_r_code,0,INSTR(v_r_code,'-',1)-1)||'-FM-'||SUBSTR(v_r_code,INSTR(v_r_code,'-',1,2)+1,(INSTR(v_r_code,'-',-1)-1)-(INSTR(v_r_code,'-',1,2)));
                        ELSIF v_order_type = 'BO' THEN
                            v_r_code := SUBSTR(v_r_code,0,INSTR(v_r_code,'-',1)-1)||'-BO-'||SUBSTR(v_r_code,INSTR(v_r_code,'-',1,2)+1,(INSTR(v_r_code,'-',-1)-1)-(INSTR(v_r_code,'-',1,2)));
                        ELSE
                            v_r_code := SUBSTR(v_r_code,0,INSTR(v_r_code,'-',1)-1)||'-PO-'||SUBSTR(v_r_code,INSTR(v_r_code,'-',1,2)+1,(INSTR(v_r_code,'-',-1)-1)-(INSTR(v_r_code,'-',1,2)));
                        END IF;

                    ELSE
                        --RFERDIANTO 15-SEP-2021: New Standard without Revision--
                        -- Corporate Warehouse PO Number Project-CWH-Region-SubFn-Seq
                        IF NVL(v_sup_id, 0) = 100 THEN
                            v_r_code := SUBSTR(v_r_code,0,INSTR(v_r_code,'-',1)-1)||'-CW-'||SUBSTR(v_r_code,INSTR(v_r_code,'-',1,2)+1,LENGTH(v_r_code)-INSTR(v_r_code,'-',1,2));
                        ELSIF NVL(v_sup_id, 0) = 200 THEN
                            v_r_code := SUBSTR(v_r_code,0,INSTR(v_r_code,'-',1)-1)||'-FM-'||SUBSTR(v_r_code,INSTR(v_r_code,'-',1,2)+1,LENGTH(v_r_code)-INSTR(v_r_code,'-',1,2));
                        ELSIF v_order_type = 'BO' THEN
                            v_r_code := SUBSTR(v_r_code,0,INSTR(v_r_code,'-',1)-1)||'-BO-'||SUBSTR(v_r_code,INSTR(v_r_code,'-',1,2)+1,LENGTH(v_r_code)-INSTR(v_r_code,'-',1,2));
                        ELSE
                            v_r_code := SUBSTR(v_r_code,0,INSTR(v_r_code,'-',1)-1)||'-PO-'||SUBSTR(v_r_code,INSTR(v_r_code,'-',1,2)+1,LENGTH(v_r_code)-INSTR(v_r_code,'-',1,2));
                        END IF;
                    END IF;

                    v_order_no :=  v_r_code||'-';

                --RFERDIANTO: INC1247526 
                --ELSE 
                --    v_order_no :=  mpck_login.proj_id||'-MO-PROC-';
                END IF;

            END IF;

            RETURN v_order_no;

        END IF;

    /*
    v_r_id := p_r_id;

    -- If Requisition Id is not specified get the Requisition from the Item
    IF NVL(v_r_id, 0) = 0 THEN
        SELECT MAX(ri.r_id)
          INTO v_r_id
          FROM m_sys.m_req_line_items ri, m_sys.m_po_line_items i, m_sys.m_reqs r
         WHERE i.poh_id = p_poh_id
           AND ri.rli_id = i.rli_id
           and r.r_id = ri.r_id;
    END IF;

    -- For Revisions return the same number
    IF NVL(p_po_supp, 0) > 0 THEN
        SELECT base_poh_id, order_type, order_sub_type, sup_id
          INTO v_base_poh_id, v_order_type, v_order_sub_type, v_sup_id
          FROM m_sys.m_po_headers
         WHERE poh_id = p_poh_id;

        SELECT po_number
          INTO v_new_po_number
          FROM m_sys.m_po_headers
         WHERE base_poh_id = v_base_poh_id
           AND po_supp = 0;

        RETURN v_new_po_number;
    ELSE
        BEGIN
            SELECT base_poh_id, order_type, order_sub_type, sup_id
              INTO v_base_poh_id, v_order_type, v_order_sub_type, v_sup_id
              FROM m_sys.m_po_headers
             WHERE poh_id = p_poh_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;

        -- Get Requisition associated with the Order
        BEGIN
            SELECT r_code, proj_id, mg_id, order_type
              INTO v_req_number, v_proj_id, v_mg_id, v_purchase_order_type
              FROM m_sys.m_reqs
             WHERE r_id = v_r_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_purchase_order_type := 'PO';
        END;

        v_purchase_order_type := NVL(v_purchase_order_type, 'PO');

        v_payment_mode_code := get_attribute_value ('PO', p_poh_id, 'PAYMENT_MODE');

        IF NVL(v_order_type, '#$%') = 'BO' AND v_purchase_order_type <> 'BO' THEN
            v_purchase_order_type := 'BO';
        END IF;

        -- Corporate Warehouse PO Number Project-CWH-Region-SubFn-Seq
        IF NVL(v_sup_id, 0) = 100 THEN
            v_purchase_order_type := 'CWH';
        END IF;

        IF NVL(v_req_number, '#$%') = '#$%' THEN
            RETURN NULL;
        ELSE
            IF NVL(v_mg_id, 0) > 0 THEN
                SELECT mg_code
                  INTO v_mg_code
                  FROM m_sys.m_material_groups
                 WHERE mg_id = v_mg_id;
            END IF;

            v_mg_code := NVL(v_mg_code, 'ALL');

            v_project_type := NVL(get_project_attribute (v_proj_id, 'PROJECT_TYPE'), 'PROJECT');
            v_name_parts_array := APEX_UTIL.STRING_TO_TABLE(v_req_number, '-');
            IF v_name_parts_array.count < 5 THEN
                -- DBMS_OUTPUT.PUT_LINE('Requisition ' || v_req_number || ' does not comply with numbering format rules.');
                RETURN NULL;
            ELSE
                -- Get last sequence
                IF v_purchase_order_type = 'BO' THEN
                    IF NVL(v_r_id, 0) <> 0 THEN
                        -- Check if MDR Region Attribute assigned to the Requisition
                        v_mdr_region := get_attribute_value ('ER', v_r_id, 'MDR_REGION');
                        -- If MDR_REGION not assigned to Requisition, check the region of the entity
                        IF NVL(v_mdr_region, '#$%') = '#$%' THEN
                            IF v_project_type = 'PROJECT' THEN
                                v_entity := SUBSTR(v_name_parts_array(3), 1, 4);
                            ELSE
                                v_entity := SUBSTR(v_name_parts_array(1), 1, 4);
                            END IF;
                            IF NVL(v_entity, '#$%') <> '#$%' THEN
                                v_gl_area := get_table_detail_attribute('GLOBAL', 'MDR_ENTITY', 'LEGACY_GLAREA', 'ALL', v_entity);
                                IF NVL(v_gl_area, '#$%') <> '#$%' THEN
                                    v_mdr_region := NVL(get_table_detail_attribute('GLOBAL', 'MDR_GL_AREA', 'MDR_REGION', 'ALL', v_gl_area), 'GLOB');
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                    v_mdr_region := NVL(v_mdr_region, 'GLOB');
                    v_new_po_number := 'BO-' || v_mdr_region || '-' || v_mg_code;

                ELSIF v_purchase_order_type = 'CWH' THEN
                    IF NVL(v_r_id, 0) <> 0 THEN
                        -- Get the Requisition Sub Function
                        v_req_sub_function := get_attribute_value ('ER', v_r_id, 'MDR_SUB_FUNCTION');
                        IF NVL(v_req_sub_function, '#$%') = '#$%' AND v_project_type = 'PROJECT' THEN
                            v_req_sub_function := v_name_parts_array(5);
                        END IF;

                        -- Get the Requisition Entity
                        v_entity := get_attribute_value ('ER', v_r_id, 'MDR_ENTITY');
                        IF NVL(v_entity, '#$%') = '#$%' THEN
                            IF v_project_type = 'PROJECT' THEN
                                v_entity := SUBSTR(v_name_parts_array(3), 1, 4);
                            ELSE
                                v_entity := SUBSTR(v_name_parts_array(1), 1, 4);
                            END IF;
                        END IF;

                        -- Check if MDR Region Attribute assigned to the Requisition
                        v_mdr_region := get_attribute_value ('ER', v_r_id, 'MDR_REGION');

                        -- If MDR_REGION not assigned to Requisition, check the region of the entity
                        IF NVL(v_mdr_region, '#$%') = '#$%' AND NVL(v_entity, '#$%') <> '#$%' THEN
                            v_gl_area := get_table_detail_attribute('GLOBAL', 'MDR_ENTITY', 'LEGACY_GLAREA', 'ALL', v_entity);
                            IF NVL(v_gl_area, '#$%') <> '#$%' THEN
                                v_mdr_region := NVL(get_table_detail_attribute('GLOBAL', 'MDR_GL_AREA', 'MDR_REGION', 'ALL', v_gl_area), 'GLOB');
                            END IF;
                        END IF;
                    END IF;
                    v_mdr_region := NVL(v_mdr_region, 'GLOB');
                    v_new_po_number := v_proj_id || '-' || v_purchase_order_type || '-' || v_mdr_region || '-' || v_req_sub_function;
                ELSE
                    v_new_po_number := SUBSTR(v_req_number, 1, INSTR(v_req_number, '-', 1)) || v_purchase_order_type || SUBSTR(v_req_number, INSTR(v_req_number, '-', 1, 2));
                END IF;

                v_search_str := v_new_po_number || '-%';

                IF NVL(v_search_str, '#$%') <> '#$%' THEN
                    -- Get the Max PO Number for the next sequence
                    IF v_purchase_order_type = 'BO' THEN
                        -- Count Agreements for all projects which match the search string
                        SELECT MAX(po_number)
                          INTO v_last_po_number
                          FROM m_sys.m_po_headers
                         WHERE po_number LIKE v_search_str
                           AND po_supp = 0;
                    ELSE
                        -- Count Project Agreements which match the search string
                        SELECT MAX(po_number)
                          INTO v_last_po_number
                          FROM m_sys.m_po_headers
                         WHERE proj_id = v_proj_id
                           AND po_number LIKE v_search_str
                           AND po_supp = 0;
                    END IF;

                    -- Determine the next Sequence
                    IF NVL(v_last_po_number, '#$%') <> '#$%' THEN
                        BEGIN
                            v_po_last_seq := SUBSTR(v_last_po_number, INSTR(v_last_po_number, '-', -1, 1) + 1);
                            NULL;
                        EXCEPTION
                            WHEN OTHERS THEN
                                v_po_last_seq := 0;
                        END;
                    END IF;
                END IF;

                v_po_last_seq := NVL(v_po_last_seq, 0) + 1;

                IF v_purchase_order_type = 'BO' THEN
                    v_po_new_seq := lpad('0', 6 - length(v_po_last_seq), '0') || v_po_last_seq;
                ELSE
                    IF v_project_type = 'PROJECT' THEN
                        v_po_new_seq := lpad('0', 2 - length(v_po_last_seq), '0') || v_po_last_seq;
                    ELSE
                        v_po_new_seq := lpad('0', 4 - length(v_po_last_seq), '0') || v_po_last_seq;
                    END IF;
                END IF;

                v_new_po_number := SUBSTR(v_new_po_number, 1, 49 - length(v_po_new_seq)) || '-' || v_po_new_seq;
            END IF;
        END IF;
    END IF;

    RETURN v_new_po_number;
    */
ELSE

-- check project default
    begin
      select nvl(substr(min(d.parm_value), 1, 1), 'Y')
        into l_cbi_po
        from M_APPL_PARM p, M_PPD_DEFAULTS d, m_sys.M_PO_HEADERS poh
       where p.parm_id = d.parm_id
         and p.parm_code = 'ZP_CBI_PO'
         and parm_value != './.'
         and nvl(d.dp_id, poh.dp_id) = poh.dp_id
         and d.proj_id = poh.proj_id
         and poh.poh_id = p_poh_id;
    exception
      when no_data_found then
        l_cbi_po := 'Y';
        null;
    end;
    if l_cbi_po = 'N' then
      -- let SPM do its own thing, no change of PO-number
      NULL;
    else
      select R_code, 'PO' --decode(order_type, 'CO','PO', order_type)
        into l_po_number, l_order_type
        from m_sys.m_reqs
       where r_id = p_r_id;
      if l_po_number like '%-MR-%' then
        l_po_number := replace(l_po_number,
                               '-MR-',
                               '-' || l_order_type || '-');
        return l_po_number;
      else
        RETURN NULL;
      end if;
    end if;
END    IF;
  END; /* gen_order_number */


    -- 16-Dec-2019 8.2 - 1 Added 7.1 procedures.

PROCEDURE assign_manual_order_number
    (p_poh_id       IN            m_po_headers.poh_id%TYPE)
IS
    v_base_poh_id               m_sys.m_po_headers.base_poh_id%TYPE;
    v_search_str                VARCHAR2(255);
    v_po_last_seq                NUMBER                            DEFAULT 0;
    v_proj_id                    m_sys.m_projects.proj_id%TYPE;
    v_po_new_seq                m_sys.m_po_headers.po_number%TYPE;
    v_new_po_number                m_sys.m_po_headers.po_number%TYPE;
    v_entity                    m_sys.m_used_values.attr_value%TYPE;
    v_contract_type                m_sys.m_used_values.attr_value%TYPE;
    v_contract                    m_sys.m_used_values.attr_value%TYPE;
    v_sub_function                m_sys.m_used_values.attr_value%TYPE;
    v_last_po_number            m_sys.m_po_headers.po_number%TYPE;
    v_po_supp                    m_sys.m_po_headers.po_supp%TYPE;
    v_order_type                m_sys.m_po_headers.order_type%TYPE;
    v_po_number                    m_sys.m_po_headers.po_number%TYPE;
    v_po_number_attr_id            m_sys.m_attrs.attr_id%TYPE;
    v_error_message                VARCHAR2(4000);
    v_update_status                VARCHAR2(20);
BEGIN
    SELECT po_supp, order_type, po_number, base_poh_id
      INTO v_po_supp, v_order_type, v_po_number, v_base_poh_id
      FROM m_sys.m_po_headers
     WHERE poh_id = p_poh_id;

   /********************************SANDEEP to finalise the numbering as requested ************8.x consolidation **************/

    IF NVL(v_po_supp, 0) = 0 AND v_order_type = 'MP' THEN
        -- Assign a number for MP at Revision 0
        SELECT MAX(attr_id)
          INTO v_po_number_attr_id
          FROM m_sys.m_attrs
         WHERE attr_code = 'MDR_PO_NUMBER';

        IF NVL(v_po_number_attr_id, 0) = 0 THEN
            v_error_message := 'MAR-MP066 #1approved #2MDR_PO_NUMBER attribute not setup';
            RAISE_APPLICATION_ERROR(-20000, v_error_message);
        /***************New logic to be developed for 8.x - CG -01/16- Sandeep*************
    ELSE

            -- IF PO Number previously assigned do not reassign a number
            v_new_po_number := get_attribute_value ('PO', p_poh_id, 'MDR_PO_NUMBER');
            IF NVL(v_new_po_number, '#$%') = '#$%' THEN
                v_entity := get_attribute_value ('PO', p_poh_id, 'MDR_ENTITY');
                IF NVL(v_entity, '#$%') = '#$%' THEN
                    v_error_message := 'MAR-MP066 #1flagged as RfA #Entity attribute not specified';
                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                ELSE
                    v_contract_type := get_attribute_value ('PO', p_poh_id, 'MDR_CONTRACT_TYPE');
                    IF NVL(v_contract_type, '#$%') = '#$%' THEN
                        v_error_message := 'MAR-MP066 #1flagged as RfA #2Contract Type attribute not specified';
                        RAISE_APPLICATION_ERROR(-20000, v_error_message);
                    ELSE
                        v_contract := get_attribute_value ('PO', p_poh_id, 'MDR_CONTRACT');
                        IF NVL(v_contract, '#$%') = '#$%' THEN
                            v_error_message := 'MAR-MP066 #1flagged as RfA #2Contract attribute not specified';
                            RAISE_APPLICATION_ERROR(-20000, v_error_message);
                        ELSE
                            v_sub_function := get_attribute_value ('PO', p_poh_id, 'MDR_SUB_FUNCTION');
                            IF NVL(v_sub_function, '#$%') = '#$%' THEN
                                v_error_message := 'MAR-MP066 #1flagged as RfA #Sub Function attribute not specified';
                                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                            ELSE
                                -- Get last sequence
                                v_new_po_number := v_entity || '-' || v_contract_type || '-' || v_contract || '-' || v_sub_function;

                                v_search_str := v_new_po_number || '-%';

                                IF NVL(v_search_str, '#$%') <> '#$%' THEN
                                    -- Get the Max PO Number for the next sequence
                                    -- Count Project Agreements which match the search string
                                    SELECT MAX(po_number)
                                      INTO v_last_po_number
                                      FROM m_sys.m_po_headers
                                     WHERE proj_id = v_proj_id
                                       AND order_type = 'MP'
                                       AND po_number LIKE v_search_str
                                       AND poh_id <> p_poh_id
                                       AND po_supp = 0;

                                    -- Determine the next Sequence
                                    IF NVL(v_last_po_number, '#$%') <> '#$%' THEN
                                        BEGIN
                                            v_po_last_seq := SUBSTR(v_last_po_number, INSTR(v_last_po_number, '-', -1, 1) + 1);
                                        EXCEPTION
                                            WHEN OTHERS THEN
                                                v_po_last_seq := 0;
                                        END;
                                    END IF;
                                END IF;

                                v_po_last_seq := NVL(v_po_last_seq, 0) + 1;

                                v_po_new_seq := lpad('0', 3 - length(v_po_last_seq), '0') || v_po_last_seq;

                                v_new_po_number := SUBSTR(v_new_po_number, 1, 49 - length(v_po_new_seq)) || '-' || v_po_new_seq;

                                UPDATE m_sys.m_po_headers
                                   SET po_number = v_new_po_number
                                 WHERE poh_id = p_poh_id;
                                COMMIT;

                                v_update_status := interface.mdr_interface_utl8x.set_attribute_value_no_log (v_new_po_number, 'PO', v_base_poh_id, v_po_number_attr_id, 'C', 0, 1, 'SPMAT');
                                COMMIT;

                                IF NVL(v_update_status, 'SUCCESS') <> 'SUCCESS' THEN
                                    v_error_message := 'MAR-MP066 #1approved #2PO Number attribute could not be set';
                                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                ELSE
                                    v_error_message := 'MAR-MP066 #1approved #2PO Number updated to ' || v_new_po_number || '. Please refresh screen and retry.';
                                    RAISE_APPLICATION_ERROR(-20000, v_error_message);
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;*****************/
        END IF;
    END IF;
END assign_manual_order_number;

  /*
  || ****************************************************************************
  || Called before creating an agreement
  || ****************************************************************************
  */
  PROCEDURE before_poh_creation(p_poh_id     IN m_po_headers.poh_id%TYPE,
                                p_po_supp    IN m_po_headers.po_supp%TYPE,
                                p_order_type IN m_po_headers.order_type%TYPE,
                                p_sup_id     IN m_po_headers.sup_id%TYPE) IS



    l_allowed_ind m_suppliers.allowed_ind%TYPE;
    v_supp_sitecd_attr_id    NUMBER;
    v_supp_siteid_attr_id    NUMBER;
    v_supp_sitecd_attr_value m_used_values.attr_value%TYPE;
    v_supp_siteid_attr_value m_used_values.attr_value%TYPE;
    v_old_po_number                m_sys.m_po_headers.po_number%TYPE;
    v_po_number                    m_sys.m_po_headers.po_number%TYPE;
    v_po_supp                    m_sys.m_po_headers.po_supp%TYPE;
    v_sup_id                m_sys.m_po_headers.sup_id%TYPE;
    v_order_type                m_sys.m_po_headers.order_type%TYPE;
    v_r_id                        m_sys.m_reqs.r_id%TYPE;
    v_order_sub_type            m_sys.m_po_headers.order_sub_type%TYPE;
    v_company_id                m_sys.m_companies.company_id%TYPE;



  BEGIN
    NULL;

    --Ruby commented because we need to filter only for ORACLE finance system and the parameter do not have job_id so need to create different trigger and procedure
    --16-Dec-2019 8.2 - 1 Added 7.1 procedures.
--    IF m_pck_ppd_defaults.get_value('ZO_MDR_PJ') = 'MERGE' THEN
--
--        v_sup_id := p_sup_id;
--
--        IF v_sup_id <> 100 AND v_sup_id <> 200 THEN
--
--            SELECT    company_id
--            INTO    v_company_id
--            FROM    m_sys.m_suppliers
--            WHERE    sup_id = v_sup_id;
--
--
--            BEGIN
--
--                SELECT    NVL(MAX(attr_id),0)
--                INTO    v_supp_sitecd_attr_id
--                FROM    m_sys.m_attrs
--                WHERE    attr_code = 'ORACLE_SUPPLIER_SITE_CODE';
--
--                IF v_supp_sitecd_attr_id = 0 THEN
--                    RAISE_APPLICATION_ERROR(-20000,'MAR-25353 #1Oracle Supplier Site Code attribute is not found');
--                END IF;
--
--                /*SELECT    NVL(MAX(attr_id),0)
--                INTO    v_supp_siteid_attr_id
--                FROM    m_sys.m_attrs
--                WHERE    attr_code = 'ORACLE_SUPPLIER_SITE_ID';
--
--                IF v_supp_siteid_attr_id = 0 THEN
--                    RAISE_APPLICATION_ERROR(-20000,'Oracle Supplier Site ID attribute is not found');
--                END IF;*/
--
--                SELECT    NVL(MAX(attr_value),'!NDF')
--                INTO    v_supp_sitecd_attr_value
--                FROM    m_sys.m_used_values
--                WHERE    used_type = 'COM'
--                AND    pk_id = v_company_id
--                AND    attr_id = v_supp_sitecd_attr_id;
--
--                /*SELECT    NVL(MAX(attr_value),'!NDF')
--                INTO    v_supp_siteid_attr_value
--                FROM    m_sys.m_used_values
--                WHERE    used_type = 'SUP'
--                AND    pk_id = v_sup_id
--                AND    attr_id = v_supp_siteid_attr_id;*/
--
--                IF v_supp_sitecd_attr_value = '!NDF' THEN --OR v_supp_siteid_attr_value = '!NDF' THEN
--
--                    RAISE_APPLICATION_ERROR(-20000,'MAR-25353 #1Oracle Supplier Site Code attribute value is not found for the supplier.');
--                END IF;
--            EXCEPTION
--            WHEN OTHERS THEN
--                RAISE_APPLICATION_ERROR(-20000,'MAR-25353 #1Oracle Supplier Site Code attribute value is not found for the supplier.');
--            END;
--        END IF;
--
--    END IF;


  END;

  /*
  || ****************************************************************************
  ||
  || post_poh_creation
  || =================
  ||
  || Called after an agreement has been created when button 'Create Agreement'
  || has been pressed in screen P.50.01.
  ||
  || ****************************************************************************
  */
  PROCEDURE post_poh_creation(p_poh_id IN m_po_headers.poh_id%TYPE) IS
  l_uval_id number;
  l_attr_id number;
  l_attr_value varchar2(5);

    v_old_po_number                m_sys.m_po_headers.po_number%TYPE;
    v_po_number                    m_sys.m_po_headers.po_number%TYPE;
    v_po_supp                    m_sys.m_po_headers.po_supp%TYPE;
    v_sup_id                m_sys.m_po_headers.sup_id%TYPE;
    v_order_type                m_sys.m_po_headers.order_type%TYPE;
    v_r_id                        m_sys.m_reqs.r_id%TYPE;
    v_po_counter                VARCHAR2(10);
    v_order_sub_type            m_sys.m_po_headers.order_sub_type%TYPE;
    v_proj_id                   m_sys.m_projects.proj_id%TYPE;

  BEGIN


    -- 16-Dec-2019 8.2 - 1 Added 7.1 procedures.
    IF m_pck_ppd_defaults.get_value('ZO_MDR_PJ') = 'MERGE' THEN

        SELECT   proj_id, po_supp, po_number, order_type, sup_id, order_sub_type
        INTO    v_proj_id, v_po_supp, v_old_po_number, v_order_type, v_sup_id, v_order_sub_type
        FROM    m_sys.m_po_headers
        WHERE    poh_id = p_poh_id;

         IF v_po_supp = 0 THEN

            IF NVL(v_order_sub_type,'!NDF') <> 'BOR' THEN


                IF INSTR(v_old_po_number,'-MO-') = 0 THEN
                    -- Corporate Warehouse PO Number Project-CWH-Region-SubFn-Seq
                    IF NVL(v_sup_id, 0) = 100 THEN
                        v_old_po_number := SUBSTR(v_old_po_number,0,INSTR(v_old_po_number,'-',1)-1)||'-CW-'||SUBSTR(v_old_po_number,INSTR(v_old_po_number,'-',1,2)+1,(INSTR(v_old_po_number,'-',-1)-1)-(INSTR(v_old_po_number,'-',1,2)));
                    ELSIF NVL(v_sup_id, 0) = 200 THEN
                        v_old_po_number := SUBSTR(v_old_po_number,0,INSTR(v_old_po_number,'-',1)-1)||'-FM-'||SUBSTR(v_old_po_number,INSTR(v_old_po_number,'-',1,2)+1,(INSTR(v_old_po_number,'-',-1)-1)-(INSTR(v_old_po_number,'-',1,2)));
                    ELSIF v_order_type = 'BO' THEN
                        v_old_po_number := SUBSTR(v_old_po_number,0,INSTR(v_old_po_number,'-',1)-1)||'-BO-'||SUBSTR(v_old_po_number,INSTR(v_old_po_number,'-',1,2)+1,(INSTR(v_old_po_number,'-',-1)-1)-(INSTR(v_old_po_number,'-',1,2)));
                    ELSE
                        v_old_po_number := SUBSTR(v_old_po_number,0,INSTR(v_old_po_number,'-',1)-1)||'-PO-'||SUBSTR(v_old_po_number,INSTR(v_old_po_number,'-',1,2)+1,(INSTR(v_old_po_number,'-',-1)-1)-(INSTR(v_old_po_number,'-',1,2)));
                    END IF;

                    v_old_po_number := v_old_po_number||'-';
                END IF;

                BEGIN
                    SELECT order_type
                      INTO v_order_type
                      FROM m_sys.m_po_headers
                     WHERE poh_id = p_poh_id;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        NULL;
                END;

                IF v_order_type = 'BO' THEN
                    v_old_po_number := REPLACE(v_old_po_number, '-PO-','-BO-');
                END IF;

                IF INSTR(v_old_po_number,'-MO-') = 0 THEN
                    SELECT    LPAD(NVL(MAX(TO_NUMBER(SUBSTR(po_number,INSTR(po_number, '-', -1, 1)+1)))+1,1),2,'0')
                    INTO    v_po_counter
                    FROM    m_po_headers r
                    WHERE    po_number LIKE v_old_po_number||'%'
                    AND    poh_id <> p_poh_id;
                ELSE
                    SELECT    LPAD(NVL(MAX(TO_NUMBER(SUBSTR(po_number,INSTR(po_number, '-', -1, 1)+1)))+1,1),5,'0')
                    INTO    v_po_counter
                    FROM    m_po_headers r
                    WHERE    po_number LIKE v_old_po_number||'%'
                    AND    poh_id <> p_poh_id;

                END IF;
                -- Commented because PO supp is removed.
                /*UPDATE    m_po_headers
                SET    po_number = v_old_po_number||v_po_counter||'-'||v_po_supp
                WHERE    poh_id = p_poh_id;  */

                UPDATE    m_po_headers
                SET    po_number = v_old_po_number||v_po_counter
                WHERE    poh_id = p_poh_id;
            END IF;
        ELSE
            -- Commented because PO supp is removed.
            /*UPDATE    m_po_headers
            SET    po_number = substr(po_number,0,INSTR(po_number,'-',-1))||v_po_supp
            WHERE    poh_id = p_poh_id;
            */
            NULL;

        END IF;

    END IF;


    --ELSE --Ruby One MDR to include Budget Provided
    /* Hague-0412 18Aug2014 Thua */
        /* Reset PO/CO header budget to 0,allowing user update to suppl budget as needed */

        Begin
        Update m_po_headers set BUDGET = 0  where poh_id = p_poh_id;
         EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                      'ERROR- Reset PO BUDGET to 0.' ||
                      SUBSTR(sqlerrm, 12) || ' ' || sqlcode);
        End;

        Begin  -- CBI204602
           select attr_id into l_attr_id
            from m_attrs
            where attr_code ='BUDGET_PROVIDED';

           select proj_id into v_proj_id  -- INC1214827 Thua
         from     m_sys.m_po_headers
         where poh_id = p_poh_id;

          /* INC1138288 Thua */
           --select decode (budget,0,'N','Y') into l_attr_value from m_po_headers where poh_id = p_poh_id;
           select nvl(min(attrv.attr_value),'Y') into l_attr_value
           from m_sys.m_attrs attr , m_sys.M_ATTR_VALUES attrv
           where attr.attr_code like 'BUDGET_PROVIDED'
           and attr.attr_id = attrv.attr_id and attrv.default_ind = 'Y';
           --

           Select nvl(max(uval_id),'-1') into l_uval_id
           from m_sys.m_used_values v,
            m_sys.m_attrs       a,
            m_sys.m_po_headers  poh
           where v.used_type = 'PO'
         and v.pk_id = poh.poh_id
         and a.attr_id = v.attr_id
         and a.attr_code = 'BUDGET_PROVIDED'
         and poh.poh_id = p_poh_id;

         if l_uval_id = '-1' then --this attr does not existed at all
        INSERT INTO M_SYS.M_USED_VALUES (
           UVAL_ID, USR_ID, USED_TYPE, PROJ_ID, PK_ID, PARENT_UVAL_ID,
           NUMBER_VALUE, NLS_ID, LOCK_IND, LMOD, KIND_OF_ATTR, INT_REV,
           DP_ID, DATE_VALUE, ATTR_VALUE, ATTR_ID, ATTR_DATA_TYPE, ASD_ID)
        VALUES ( m_seq_uval_id.nextval,
          'M_SYS','PO',v_proj_id,p_POH_ID,NULL,
          0,1,'N',SYSDATE,'O',1,
          5011,NULL,l_ATTR_VALUE,l_ATTR_ID,'C',NULL);
--        else --RFERDIANTO: Commented because new revisions will be follow previous rev without user re-enter again
--           Update m_sys.m_used_values
--           set attr_value = L_ATTR_VALUE
--           where uval_id = l_uval_id;
        end if;
        EXCEPTION
          WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                      'ERROR- Reset Budget_provided to NULL. ' ||SUBSTR(sqlerrm, 12) || ' ' || sqlcode);
        End;
    --END IF; --End Ruby

    Commit;
    --
  END;

  /*
  || ****************************************************************************
  ||
  || agreement_approval
  || ==================
  ||
  || This CIP function is called during the approval of an agreement.
  ||
  || Return value is BOOLEAN.
  || If the return value is FALSE the approval procedure will be stopped;
  || if the return value is TRUE the approval procedure will continue.
  ||
  || Parameter 'p_check_only_ind' will be 'Y' or 'N', depending on the point of
  || time within the approval procedure where this function is called.
  || When checking the RfA checkbox in P.50.07, this function will be called with
  || 'p_check_only_ind' set to 'Y'. When pressing button 'Approve' (or, in cases
  || where an approval sequence is used, button 'Finalize Approval'), this
  || function will be called with 'p_check_only_ind' set to 'N'.
  ||
  || ****************************************************************************
  */
  FUNCTION agreement_approval(p_poh_id         IN m_po_headers.poh_id%TYPE,
                              p_check_only_ind IN VARCHAR2) RETURN BOOLEAN IS
    /* 6.2  17Jan2010 upgrade Hagud-0072 */
    /* 7.0.5 05Apr2011 */
    /* 7.0.8 08jUN2013 */
    /* -- Replaced with code --
    BEGIN
      NULL;
      RETURN TRUE;
    */
    /*8.0.2  CBI161355 Thua 20Jul2018 */
    cursor c1 is
      select pol.proj_id,
             pol.poli_id,
             pol.poli_pos,
             pol.poli_sub_pos,
             pol.job_id,
             j.job_number account,
             u.unit_code qty_uom,
             pol.poli_qty * pol.poli_unit_price poli_amount
        from m_sys.m_po_line_items pol, m_sys.m_jobs j, m_sys.m_units u
       where pol.poh_id = p_poh_id
         and j.job_id = pol.job_id
         and u.unit_id = pol.qty_unit_id
       order by pol.poli_pos, pol.poli_sub_pos;

    cursor c2 is
      select uoc.proj_id, uoc.uoc_id, rownum, uoc.job_id, j.job_number account, cost_value
        from m_sys.m_used_other_costs uoc, m_sys.m_jobs j
       where uoc.pk_id = p_poh_id
         and uoc.term_type = 'PO'
         and j.job_id = uoc.job_id;

    cursor c3 is
      select job_id, job_number
        from m_sys.m_jobs j
       where (field1 like '%DELETED%' or field2 <> 'Y')
         and job_id in (select poli.job_id
                          from m_sys.m_po_line_items poli
                         where poli.poh_id = p_poh_id);
    cursor c4 is
      select job_id, job_number
        from m_sys.m_jobs j
       where (field1 like '%DELETED%' or field2 <> 'Y')
         and job_id in (select uoc.job_id
                          from m_sys.m_used_other_costs uoc
                         where uoc.pk_id = p_poh_id
                           and uoc.term_type = 'PO');
    --TASK0139926
    CURSOR mdr_cancelled_items IS
    SELECT i.POLI_QTY ,i.poli_pos,i.poli_sub_pos,i.poli_id,h.po_supp  from m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE
    i.poh_id = p_poh_id and h.poh_id = i.poh_id;  --t
    v_poli_pos_last_rev   m_sys.m_po_line_items.poli_pos%TYPE;
    v_prev_poh_id         m_sys.m_po_line_items.poh_id%TYPE;
    v_poli_supp           m_sys.m_po_headers.po_supp%TYPE;
    --t v_poli_pos                m_sys.m_po_line_items.poli_pos%TYPE;
    v_poli_sub_pos        m_sys.m_po_line_items.poli_sub_pos%TYPE;
    v_last_qty            m_sys.m_po_line_items.poli_qty%TYPE;
    v_poli_pos                            m_sys.m_po_line_items.poli_pos%TYPE;
    v_poli_qty                            m_sys.m_po_line_items.poli_qty%TYPE;
    v_base_poh_id m_po_headers.base_poh_id%TYPE;
    v_poli_id                            m_sys.m_po_line_items.poli_id%TYPE;
    v_error_message                        VARCHAR2(4000)                                     DEFAULT 'SUCCESS';
    --

    l_incoterm            number;
    l_delv_place          number;
    l_pos_subpos_count    number;
    l_currency            number;
    l_acc_required        varchar2(1);
    l_poli_account        number;
    l_jde_deleted_acc     number;
    l_max_poli_count      number;
    l_jdedel_account      m_jobs.job_number%type;
    l_interface_switch_po varchar2(2);
    l_jde_int_flag        varchar2(2);
    l_jde_disc_int        varchar2(2);
    l_routing_method      number;
    l_po_num_length       number;
    l_jde_vendorid        number;
    l_jde_buyerid         number;
    l_match_typ           varchar2(2);
    l_prog_payments       number;
    l_payment_terms       varchar2(20);
    l_other_costs         number;
    l_other_costs_count   number;
    l_po_issue_date       varchar2(40);
    i                     number;
    l_project_count       number; -- support center-0035 -- PLF0086-Hou0775
    l_used_before_count   number; -- support center-0036
    l_proj_date           date; -- support center-0341
    l_base_poh_id         number; -- support center-0341
    l_sup_use_count       number; --SC_0368
    l_cur_use_count       number; --SC_0368
    l_currency_code       varchar2(10); -- SC_0368
    l_job_id              number; --SC_0368
    l_purchase_contract   varchar2(12); --SC_0368
    l_prior_contract      varchar2(12); --SC_0368
    l_missing_account     m_jobs.job_number%type; -- SC_0368
    l_spaces              number; --SC_0368
    l_invalid_uom_code    varchar2(10); -- SC_0368
    l_invalid_uom_count   number; -- SC_0368
    l_po_num_now          varchar2(50); -- SC_0368
    l_po_num_base         varchar2(50); -- SC0368
    l_cc_disc_count       number; -- SC_0368
    l_replace_acc1        number; -- SC_0368
    l_replace_acc2        number; -- SC_0368
    l_match_type_init     varchar2(2); -- SC_0368
    l_match_type_now      varchar2(2); -- SC_0368
    l_cbi_po              varchar2(1); -- SC_0368
    l_counterpart         varchar2(10); --SC_0368
    l_exped_ilv_id        number; -- PLF0086-Hou0775
    l_ilv_id              number; -- PLF0086-Hou0775
    l_line_count          number; -- HAG_0503
    l_other_cost_count    number; -- HAG_0503
    l_shiploose           number; -- HAG_0503
    l_order_type          varchar2(2); -- HAG_0509
    l_nls                 number; --SC_0448
    l_unprintable         number; --SC_0491
    l_string              varchar2(2000); --SC_0491
    l_unit_code           varchar2(10); --SC_0491
    l_proj_id             varchar2(10); --SC_0491
    l_doco                number;
    l_paid_amount         number;
    l_tot_spm_amount      number;
    l_budget_provided     varchar2(1);
    l_budget              number;
    v_count        NUMBER;
    v_po_number m_po_headers.po_number%TYPE;
    l_insp_lv   m_sys.m_po_headers.ilv_id%TYPE;  --INC1109215
    l_exped_lv    m_sys.m_po_headers.exped_ilv_id%TYPE;  --INC1109215

  BEGIN
    -- 16-Dec-2019 8.2 - 1 Added 7.1 procedures.
    IF m_pck_ppd_defaults.get_value('ZO_MDR_PJ') = 'MERGE' THEN

        SELECT    po_number
        INTO    v_po_number
        FROM    m_po_headers
        WHERE    poh_id = p_poh_id;

        mdr_oc_check (p_poh_id);

        IF INSTR(v_po_number,'-ZZ-') > 0 OR INSTR(v_po_number,'-FI-') > 0 THEN

            UPDATE m_po_headers
            SET    po_issue_date = SYSDATE
            WHERE    poh_id = p_poh_id;

            COMMIT;

            RETURN TRUE;

        ELSE
            IF mdr_check_agreement (p_poh_id, 'approved') = 1 THEN
                RETURN FALSE;
            ELSE
                RETURN TRUE;
            END IF;
        END IF;

    ELSE
        -- Is the user just clicking RFA or actually Approving the order? If just RFA then do nothing.
       /* if p_check_only_ind = 'Y' then
          RETURN TRUE;
        end if;*/
        -- First see if this PO is a supplement created by ShipLoose,, if so then just allow approval, no more checks
        select count(*)
          into l_shiploose
          from (select distinct rcat.rcat_code
              from m_sys.m_reqs            r,
               m_sys.m_req_li_to_polis rtp,
               m_sys.m_po_line_items   poli,
               m_sys.m_req_categories  rcat
             where poli.poh_id = p_poh_id
               and rtp.poli_id = poli.poli_id
               and r.r_id = rtp.r_id
               and rcat.rcat_id = r.rcat_id
               and (rcat.rcat_code = 'ZZ' or rcat.rcat_code like '%CAT_SL')); -- determine if source is ShipLoose, if so then do not create event.. HAG_0503
        if l_shiploose > 0 then
          return TRUE;
        end if;

        -- Get order type, later used to drive what is tested and what not, liek for SC not all tests are to be done
        -- Get the order type from the actual PO header, not the supplement,,only at header we will find PO,SC,MP etc
        select order_type, proj_id
          into l_order_type, l_proj_id --SC_0491 get proj_id into variable for later use
          from m_sys.m_po_headers
         where poh_id = (select base_poh_id
                   from m_sys.m_po_headers
                  where poh_id = p_poh_id);
        -- Next is a test on order type, for now only deal with PO and CO  (Hag_0509)
        -- later add order types for sub-Contracts and adpat code to specifically deal with those types

        if l_order_type not in ('PO', 'MP', 'SC') then
          --Purchase Order, Manual PO, SubContract
          return TRUE;
        end if;

        -- PO approval validity checks
        -- Check on spaces in PO-number, is not allowed -- SC_0368
        select count(*)
          into l_spaces
          from m_sys.m_po_headers
         where poh_id = p_poh_id
           and revision_id = 0 -- only do this test on new PO's,,for supplements we do have the test on PO_number change.
           and po_number like '% %';
        if l_spaces = 0 then
          NULL;
        else
          RAISE_APPLICATION_ERROR(-20000,
                      'ERROR- PO-Number contains one or more spaces, please update.');
          RETURN FALSE;
        end if;

        -- SC_0491 Check on unprintable characters in PO-number, is not allowed
        select count(*)
          into i
          from m_sys.m_po_headers
         where poh_id = p_poh_id
           and revision_id = 0;
        if i > 0 then
          -- this is sup 0
          select length(po_number), po_number
        into l_po_num_length, l_string
        from m_sys.m_po_headers
           where poh_id = p_poh_id
         and revision_id = 0; -- only do this test on new PO's,,for supplements we do have the test on PO_number change.
          l_unprintable := 0;
          for i in 1 .. l_po_num_length loop
        if ascii(substr(l_string, i)) < 32 or
           ascii(substr(l_string, i)) > 126 then
          l_unprintable := l_unprintable + 1;
        end if;
          end loop;
          if l_unprintable > 0 then
        RAISE_APPLICATION_ERROR(-20000,
                    'ERROR- PO-Number contains unprintable chars, please update.');
        RETURN FALSE;
          end if;

          -- Check on unprintable characters in client_PO_number, is not allowed -- SC_0491
          select length(client_po_number), client_po_number
        into l_po_num_length, l_string
        from m_sys.m_po_headers
           where poh_id = p_poh_id
         and revision_id = 0; -- only do this test on new PO's,,for supplements we do have the test on PO_number change.
          l_unprintable := 0;
          if l_po_num_length > 0 then
        for i in 1 .. l_po_num_length loop
          if ascii(substr(l_string, i)) < 32 or
             ascii(substr(l_string, i)) > 126 then
            l_unprintable := l_unprintable + 1;
          end if;
        end loop;
          end if;
          if l_unprintable > 0 then
        RAISE_APPLICATION_ERROR(-20000,
                    'ERROR- Client-PO-Number has unprintable chars, please update.');
        RETURN FALSE;
          end if;
        end if;

        -- Check on PO Description being NULL, s not allowed -- PLF0087
        select count(*)
          into l_nls
          from m_sys.m_po_header_nls
         where poh_id = p_poh_id
           and nls_id = MPCK_LOGIN.NLS_ID; -- SC0448 Thua May2016
        -- SC0448 Thua May2016     and short_desc is NULL;
        if l_nls > 0 then
          -- SC0448 Thua May2016 if exists,then ok
          NULL;
        else
          RAISE_APPLICATION_ERROR(-20000,
                      'ERROR- PO-Description is empty, please update.');
          RETURN FALSE;
        end if;

        /* Check on unprintable characters in PO_description, is not allowed -- SC_0491 */
        select length(description), description
          into l_po_num_length, l_string
          from m_sys.m_po_header_nls
         where poh_id = p_poh_id
           and nls_id = MPCK_LOGIN.NLS_ID;
        l_unprintable := 0;
        for i in 1 .. l_po_num_length loop
          if ascii(substr(l_string, i)) < 32 or
         ascii(substr(l_string, i)) > 126 then
        l_unprintable := l_unprintable + 1;
          end if;
        end loop;
        if l_unprintable > 0 then
          RAISE_APPLICATION_ERROR(-20000,
                      'ERROR- PO description has unprintable chars, please update.');
          RETURN FALSE;
        end if;

        -- Check on unprintable characters in PO_short_description, is not allowed -- SC_0491
        select length(short_desc), short_desc
          into l_po_num_length, l_string
          from m_sys.m_po_header_nls
         where poh_id = p_poh_id
           and nls_id = MPCK_LOGIN.NLS_ID;
        l_unprintable := 0;
        for i in 1 .. l_po_num_length loop
          if ascii(substr(l_string, i)) < 32 or
         ascii(substr(l_string, i)) > 126 then
        l_unprintable := l_unprintable + 1;
          end if;
        end loop;
        if l_unprintable > 0 then
          RAISE_APPLICATION_ERROR(-20000,
                      'ERROR- PO short descr has unprintable chars, please update.');
          RETURN FALSE;
        end if;
        /* */

        -- Check on length of Client-PO-number, is max 25 pos -- HAG_0503
        select nvl(length(client_po_number), 0)
          into l_spaces
          from m_sys.m_po_headers
         where poh_id = p_poh_id;
        if l_spaces < 26 then
          NULL;
        else
          RAISE_APPLICATION_ERROR(-20000,
                      'ERROR- Client-PO-Number is longer than 25, please update.');
          RETURN FALSE;
        end if;

        /* Check on invalid expediting and inspection level value -- PLF0086-Hou0775 */
        if l_order_type <> 'SC' then
          -- PLF-0087 do not test this on sub-contracts
          select EXPED_ILV_ID, ILV_ID
        into l_exped_ilv_id, l_ilv_id
        from m_sys.m_po_headers
           where poh_id = p_poh_id;
          if l_exped_ilv_id in (5694) then
        -- 5694=DEFAULT
        RAISE_APPLICATION_ERROR(-20000,
                    'ERROR- Retired Expediting Level found, please change.');
        RETURN FALSE;
          end if;
          if l_ilv_id in (5695) then
        -- 5695=DEFAULT
        RAISE_APPLICATION_ERROR(-20000,
                    'ERROR- Retired Inspection Level found, please change.');
        RETURN FALSE;
          end if;
        end if;

        -- Check on change of PO-number, is not allowed -- SC_0350/368
        -- Also load base_poh_id in its variable for later use
        select po_number, base_poh_id
          into l_po_num_now, l_base_poh_id
          from m_sys.m_po_headers
         where poh_id = p_poh_id;
        select po_number
          into l_po_num_base
          from m_sys.m_po_headers
         where poh_id = l_base_poh_id;
        if l_po_num_now <> l_po_num_base then
          RAISE_APPLICATION_ERROR(-20000,
                      'ERROR- Order Number change not allowed, requery and reset.');
          RETURN FALSE;
        end if;

        -- check to make sure PO has lines or other cost, if not then fail HAG_0503
        select count(*)
          into l_line_count
          from m_sys.m_po_line_items
         where poh_id in (select poh_id
                from m_po_headers
                   where base_poh_id = l_base_poh_id);
        select count(*)
          into l_other_cost_count
          from m_sys.m_used_other_costs uoc
         where uoc.pk_id in (select poh_id
                   from m_po_headers
                  where base_poh_id = l_base_poh_id)
           and uoc.term_type = 'PO';
        if l_line_count = 0 and l_other_cost_count = 0 then
          RAISE_APPLICATION_ERROR(-20000,
                      'ERROR- Order has no PO-lines or Other-Cost, not allowed.');
          RETURN FALSE;
        end if;

        -- Check on PO-number having '-MR-' in the string, is not allowed -- SC_0350/368
        -- check project default
        begin
          select nvl(substr(min(d.parm_value), 1, 1), 'Y')
        into l_cbi_po
        from M_APPL_PARM p, M_PPD_DEFAULTS d, M_PO_HEADERS poh
           where p.parm_id = d.parm_id
         and p.parm_code = 'ZP_CBI_PO'
         and parm_value != './.'
         and nvl(d.dp_id, poh.dp_id) = poh.dp_id
         and d.proj_id = poh.proj_id
         and poh.poh_id = p_poh_id;
        exception
          when no_data_found then
        l_cbi_po := 'Y';
        null;
        end;
        if l_cbi_po = 'Y' and l_po_num_now like '%-MR-%' then
          RAISE_APPLICATION_ERROR(-20000,
                      'ERROR- PO-Number contains -MR- that indicates req, requery and change.');
          RETURN FALSE;
        end if;

        -- IncoTerm
        if l_order_type <> 'SC' then
          -- PLF-0087 do not test this on sub-contracts, set for INCOTERM, DELPLACE Aand ROUTING METHOD
          select count(*)
        into l_incoterm
        from m_sys.m_po_line_items pli
           where pli.poh_id = p_poh_id
         and frt_id is null;
          if l_incoterm = 0 then
        NULL;
          else
        RAISE_APPLICATION_ERROR(-20000,
                    'ERROR-All POLines should have a valid INCOTERM: ');
        RETURN FALSE;
          end if;
          -- Delivery Place
          select count(*)
        into l_delv_place
        from m_sys.m_po_line_items pli
           where pli.poh_id = p_poh_id
         and freight_value is null;
          if l_delv_place = 0 then
        NULL; --PCEZ
          else
        RAISE_APPLICATION_ERROR(-20000,
                    'ERROR-All POLines should have valid DELIVERYPLACE');
        RETURN FALSE;
          end if;
          --Routing Method on Shipment Lines
          select count(*)
        into l_routing_method
        From m_sys.M_ITEM_SHIPS s, m_sys.m_po_line_items i
           where i.poh_id = p_poh_id
         and s.poli_id = i.poli_id
         and rm_id is null;
          if l_routing_method = 0 then
        NULL;
          else
        RAISE_APPLICATION_ERROR(-20000,
                    'ERROR-All Shipment Lines should have valid ROUTING METHOD');
        RETURN FALSE;
          end if;
        end if; -- end exclusion of SC orders

        /* SC_0362  move test on line_number away from general section, only do test when project interfaces to JDE

        -- PO_Lines, number of lines and format
        select count(*)
          into l_pos_subpos_count
          from m_sys.m_po_line_items poli
         where poli.poh_id = p_poh_id
           and (poli.poli_pos > 949 or poli.poli_sub_pos > 999); -- SC-0341 changed 998 to 949
        if l_pos_subpos_count = 0 then
          NULL; --PCEZ
        else
          RAISE_APPLICATION_ERROR(-20000, 'ERROR-Too many POLines,max is 949'); -- SC-0341  changed 998 to 949
          RETURN FALSE;
        end if;
        end of SC_0362 chenge */

        -- PO Issue Date - HOUSTON-0033
        select nvl(to_char(po_issue_date, 'DD-MON-YYYY'), '31-APR-3000')
          into l_po_issue_date
          from m_sys.m_po_headers poh
         where poh.poh_id = p_poh_id;
        if l_po_issue_date = '31-APR-3000' then
          RAISE_APPLICATION_ERROR(-20000, 'ERROR-PO Issue Date is null');
          RETURN FALSE;
        else
          NULL;
        end if;

        -- PO exped/insp level  INC1109215
        select nvl(EXPED_ILV_ID, 0),nvl(ILV_ID, 0)
         into l_exped_lv, l_insp_lv
          from m_sys.m_po_headers poh
         where poh.poh_id = p_poh_id;
        if l_exped_lv = 0 then
          RAISE_APPLICATION_ERROR(-20000, 'ERROR- Expediting level is null');
          RETURN FALSE;
        end if;

        if l_insp_lv = 0  then
          RAISE_APPLICATION_ERROR(-20000, 'ERROR- Inspection level is null');
          RETURN FALSE;
        end if;
        --

    -- Check Routing Method is entered or not -- THUA TASK0139926

        v_error_message := 'Routing Method not found';
        v_poli_pos := 0;
            SELECT MIN(p.poli_pos)
            INTO v_poli_pos
            FROM m_sys.m_item_ships s, m_sys.m_po_line_items p
            WHERE s.poli_id IN (SELECT MAX(i.poli_id) poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL GROUP BY i.parent_poli_id
                               UNION
                               SELECT i.poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NULL
                               MINUS
                               SELECT DISTINCT i.parent_poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL)
                AND s.rm_id IS NULL
                AND s.poli_id = p.poli_id;

            IF v_poli_pos IS NOT NULL THEN
                --v_error_message := 'MAR-MP038 #1' || p_action || '#2Routing Method is#3' || v_poli_pos;  -- Agreement cannot be approved as Routing Method is not specified for item
                RAISE_APPLICATION_ERROR(-20000, v_error_message);
                RETURN FALSE;
            END IF;

----

        -- CBI161335 Thua 20Jul2018 Validate budget_provided
        Begin
          select nvl(poh.budget ,0)
        into l_budget
        from m_sys.m_po_headers  poh
           where poh.poh_id = p_poh_id;

          select v.attr_value
        into l_budget_provided
        from m_sys.m_used_values v,
             m_sys.m_attrs       a
           where v.used_type = 'PO'
         and v.pk_id = p_poh_id
         and a.attr_id = v.attr_id
         and a.attr_code = 'BUDGET_PROVIDED';

       exception when no_data_found then
         l_budget_provided := null;

       End;

       if l_budget_provided is not null then
        if l_budget_provided = 'Y'  then
            if l_budget = 0 then
              RAISE_APPLICATION_ERROR(-20000,
               'ERROR- Please ENTER Suppl. Budget.                  .');
              RETURN FALSE;
           end if;
        elsif l_budget_provided = 'N'  then
           if l_budget <> 0 then
              RAISE_APPLICATION_ERROR(-20000,
            'ERROR- Please Change Budget Provided.               .');
              RETURN FALSE;
           end if;
        end if;
       else
        RAISE_APPLICATION_ERROR(-20000,
         'ERROR-Budget Provided is not Y or N, please update.         .');
        RETURN FALSE;
       end if;


        -- JDE Interface flag exists for project
        Select count(*)
          into l_jde_int_flag
          from m_abb_sys.spm_jde_project_defaults jpd, m_sys.m_po_headers poh
         where jpd.proj_id = POH.proj_id
           and jpd.jde_interface_flag = 'Y'
           and poh.poh_id = p_poh_id;
        If l_jde_int_flag = 1 then
          select counterpart
        into l_counterpart
        from m_abb_sys.spm_jde_project_defaults jpd, m_sys.m_po_headers poh
           where jpd.proj_id = POH.proj_id
         and poh.poh_id = p_poh_id; --SC_0368 pcez jul14

          -- Project or Discipline deafult set to NO ?
          begin
        select min(d.parm_value)
          into l_jde_disc_int
          from M_APPL_PARM p, M_PPD_DEFAULTS d, M_PO_HEADERS poh
         where p.parm_id = d.parm_id
           and p.parm_code = 'ZJ_JDE_INT'
           and parm_value != './.'
           and nvl(d.dp_id, poh.dp_id) = poh.dp_id
           and d.proj_id = poh.proj_id
           and poh.poh_id = p_poh_id;
          exception
        when no_data_found then
          l_jde_disc_int := 'Y';
          null;
          end;
          if l_jde_disc_int = 'Y' then
        --Here can test matters that are NOT to be influenced by the PO header level flag so users can not go around it
        -- Setting at PO level stops PO to interface to JDE. This attribute can be used to stop spec ific PO's to interface to JDE.

        Begin
          select v.attr_value -- Tyler0013 Thua remove default to 'Y'
            into l_interface_switch_po
            from m_sys.m_used_values v,
             m_sys.m_attrs       a,
             m_sys.m_po_headers  poh
           where v.used_type = 'PO'
             and v.pk_id = poh.poh_id
             and a.attr_id = v.attr_id
             and a.attr_code = 'JDE_INTF_PO'
             and poh.poh_id = p_poh_id;
        exception
          when no_data_found then
            l_interface_switch_po := NULL; -- Tyler0013 Thua
            null;
        End;

        --Tyler0013 Thua
        if NVL(l_interface_switch_po, 'NULL') not in ('Y', 'N') then
          RAISE_APPLICATION_ERROR(-20000,
                      'ERROR-Interface PO is not Y or N, please update');
          RETURN FALSE;
        end if;
        --
        if l_interface_switch_po = 'Y' then
          -- checks to be done when the PO is to be issued to JDE !!!!

          /* SC_0362  move test on line_number now only runs when project is interfacing to JDE.
          Later we will add the test on Contract being Virtual or Not,, but is for later tracker
            NOTE: Test is also in the part AFTER PO_header interface flag,, is OK..  when we want the buyer to allow for
          more than 949 lines by switching off the interface flag on the PO then just remove this test here... */

          -- PO_Lines, number of lines and format
          select count(*)
            into l_pos_subpos_count
            from m_sys.m_po_line_items poli
           where poli.poh_id = p_poh_id
             and (poli.poli_pos > 949 or poli.poli_sub_pos > 999)
             and poli.poli_unit_price <> 0.0; -- SC_0376   lines with a amount do not cout, do not go to JDE.
          if l_pos_subpos_count = 0 then
            NULL; --PCEZ
          else
            RAISE_APPLICATION_ERROR(-20000,
                        'ERROR-Maximum Priced PO-Line number is 949. ');
            RETURN FALSE;
          end if;
          -- end of SC_0362

          -- Support_Center_0368
          -- check attribute JDE_PURCH_CONTRACT is overwrite contract,
          -- when value exists then update all accounts on po-lines and other_cost
          Begin
            select nvl(v.attr_value, 'X')
              into l_purchase_contract
              from m_sys.m_used_values v,
               m_sys.m_po_headers  poh,
               m_sys.m_attrs       a
             where v.used_type = 'PO'
               and v.pk_id = poh.poh_id
               and a.attr_id = v.attr_id
               and a.attr_code = 'JDE_PURCH_CONTRACT'
               and poh.poh_id = p_poh_id;
          exception
            when no_data_found then
              l_purchase_contract := 'X';
              null;
          end;
          if l_purchase_contract <> 'X' then
            -- first see if it deviates from suppl 0, is not allowed
            select nvl(v.attr_value, 'X')
              into l_prior_contract
              from m_sys.m_used_values v,
               m_sys.m_po_headers  poh,
               m_sys.m_attrs       a
             where v.used_type = 'PO'
               and v.pk_id = poh.poh_id
               and a.attr_id = v.attr_id
               and a.attr_code = 'JDE_PURCH_CONTRACT'
               and poh.poh_id = (select base_poh_id
                       from m_sys.m_po_headers
                      where poh_id = p_poh_id);
            if l_purchase_contract <> l_prior_contract then
              RAISE_APPLICATION_ERROR(-20000,
                          'ERROR-Override Contract is not equal to value on prior supplements.');
              RETURN FALSE;
            end if;

            -- value given and equal to earlier value, need to check and update the po-lines and other_cost
            l_replace_acc1 := -1;
            l_replace_acc2 := 0;
            for c1r in c1 loop
              -- check and update po_lines
              l_job_id := 0;
              if c1r.account like l_purchase_contract || '%' then
            null; -- no need to update, account belongs to purchase contract
              else
            l_replace_acc1 := 1;
            select count(*)
              into l_job_id
              from m_sys.m_jobs
             where job_number =
                   replace(c1r.account,
                       substr(c1r.account,
                          1,
                          instr(c1r.account, '.') - 1),
                       l_purchase_contract)
               and proj_id = c1r.proj_id;
            if l_job_id = 1 then
              select job_id
                into l_job_id
                from m_sys.m_jobs
               where job_number =
                 replace(c1r.account,
                     substr(c1r.account,
                        1,
                        instr(c1r.account, '.') - 1),
                     l_purchase_contract)
                 and proj_id = c1r.proj_id;
              update m_sys.m_po_line_items
                 set job_id = l_job_id
               where poli_id = c1r.poli_id;
            else
              l_replace_acc2 := l_replace_acc2 + 1;
            end if;
              end if;
            end loop;
            for c2r in c2 loop
              -- now check and update other_cost
              l_job_id := 0;
              if c2r.account like l_purchase_contract || '%' then
            null; -- no need to update, account belongs to purchase contract
              else
            select count(*)
              into l_job_id
              from m_sys.m_jobs
             where job_number =
                   replace(c2r.account,
                       substr(c2r.account,
                          1,
                          instr(c2r.account, '.') - 1),
                       l_purchase_contract)
               and proj_id = c2r.proj_id;
            if l_job_id = 1 then
              select job_id
                into l_job_id
                from m_sys.m_jobs
               where job_number =
                 replace(c2r.account,
                     substr(c2r.account,
                        1,
                        instr(c2r.account, '.') - 1),
                     l_purchase_contract)
                 and proj_id = c2r.proj_id;
              update m_sys.m_used_other_costs
                 set job_id = l_job_id
               where uoc_id = c2r.uoc_id;
            else
              l_replace_acc2    := l_replace_acc2 + 1;
              l_missing_account := replace(c2r.account,
                               substr(c2r.account,
                                  1,
                                  instr(c2r.account, '.') - 1),
                               l_purchase_contract);
            end if;
              end if;
            end loop;
            if l_replace_acc1 > 0 then
              -- override to be done
              if l_replace_acc2 > 0 then
            -- not all accounts where found
            RAISE_APPLICATION_ERROR(-20000,
                        'WARNING-Override Contract applied but not all replacement accounts found.');
            RETURN FALSE;
              end if;
            end if;
          end if;
          --end SC-0368

          -- Check PO number to be max 22 positions when old project, for all projects since 01-sep-2013 length may be 25
          select length(po_number)
            into l_po_num_length
            from m_sys.m_po_headers
           where poh_id = p_poh_id;
          select installed_at
            into l_proj_date
            from m_sys.m_projects proj, m_sys.m_po_headers poh
           where proj.proj_id = POH.proj_id
             and poh.poh_id = p_poh_id;
          if l_proj_date < to_date('01-sep-2013', 'dd-mm-yyyy') then

            if l_po_num_length < 23 then
              NULL; --PCEZ
            else
              RAISE_APPLICATION_ERROR(-20000,
                          'ERROR PO-Number may not be longer than 22 positions.');
              RETURN FALSE;
            end if;
          else
            if l_po_num_length < 26 then
              NULL; --PCEZ
            else
              RAISE_APPLICATION_ERROR(-20000,
                          'ERROR PO-Number may not be longer than 25 positions.');
              RETURN FALSE;
            end if;
          end if;

          -- Support center-0368
          -- Check on presence of match_type, is not allowed -- SC_0350/368
          if l_order_type <> 'SC' then
            -- PLF-0087 do not test this on sub-contracts, set for INCOTERM, DELPLACE Aand ROUTING METHOD

            begin
              select attr_value
            into l_match_type_now
            from m_sys.m_used_values v, m_sys.m_attrs a
               where v.used_type = 'PO'
             and v.pk_id = p_poh_id
             and a.attr_id = v.attr_id
             and a.attr_code = 'JDE_MATCH_TYPE';
            exception
              when no_data_found then
            RAISE_APPLICATION_ERROR(-20000,
                        'ERROR- Match Type not given, please update.');
            RETURN FALSE;
            end;
          end if;

          -- Support center-0036
          -- Check on change of match_type, is not allowed -- SC_0350/368
          if l_order_type <> 'SC' then
            -- PLF-0087 do not test this on sub-contracts, set for INCOTERM, DELPLACE Aand ROUTING METHOD
            select attr_value
              into l_match_type_init
              from m_sys.m_used_values v, m_sys.m_attrs a
             where v.used_type = 'PO'
               and v.pk_id = l_base_poh_id
               and a.attr_id = v.attr_id
               and a.attr_code = 'JDE_MATCH_TYPE';
            if l_match_type_now <> l_match_type_init then
              RAISE_APPLICATION_ERROR(-20000,
                          'ERROR- Match Type change not allowed, requery and reset.');
              RETURN FALSE;
            end if;
          end if;

          --Test on Po-number used before on other POH_ID and interfaced to JDE with success
          select count(*)
            into l_used_before_count
            from m_abb_sys.spm_jde_int_F4301z1       z,
             m_abb_sys.spm_jde_int_process_items i
           where z.vr01 in ((select po_number
                      from m_sys.m_po_headers
                     where poh_id = p_poh_id),
                    (select po_number || '-00'
                       from m_sys.m_po_headers
                      where poh_id = p_poh_id))
             and z.record_id <> (select base_poh_id
                       from m_sys.m_po_headers
                      where poh_id = p_poh_id)
             and i.process_id = z.process_id
             and i.status = 'C'; -- Support center-0341

          if l_used_before_count > 0 then
            RAISE_APPLICATION_ERROR(-20000,
                        'ERROR-This PO-Number has been used before, requery and modify.');

            RETURN FALSE;
          end if;
          -- End support center-0036

          -- Currency code
          select count(*)
            into l_currency
            from m_sys.m_po_headers poh, m_sys.m_po_line_items pli
           where poh.poh_id = pli.poh_id
             and pli.poh_id = p_poh_id
             and poh.currency_id <> pli.currency_id
             and poh.currency_id in (select unit_id from m_units);
          if l_currency = 0 then
            NULL; --PCEZ
          else
            RAISE_APPLICATION_ERROR(-20000,
                        'ERROR-Some POLines Currency does not match header currency - JDE.');

            RETURN FALSE;
          end if;

          -- Account Code
          --first see if we need to do checks on accounts.
          --Parameter ZJ_ACC_REQ is set to Y when account is mandatory
          select substr(max(d.parm_value), 1, 1)
            into l_acc_required
            from M_APPL_PARM p, M_PPD_DEFAULTS d
           where p.parm_id = d.parm_id
             and p.parm_code = 'ZX_ACC_REQ'
             and parm_value != './.'
             and d.proj_id = (select proj_id
                    from m_sys.m_po_headers
                       where poh_id = p_poh_id);
          --
          -- No need to check ZX_ACC_REQ as we only get purchase reqs released to Procurement
          -- and the Account code mandatory check is done at Req Approval
      --  if l_acc_required = 'Y' then

          -- Support center-0035:  Added following code
          -- Check the number of Contracts used on this PO
          -- PLF0086-Hou0775,, for Elba,, need multiple contracts on a PO, JDE says is OK so test will from now on
          -- only check for multiple PROJECTS on a PO,, that is accounting system projects, not spm-projects.
          select count(*)
            into l_project_count
            from (select distinct project
                from m_abb_sys.SPM_JDE_INT_ACCOUNTS a,
                 (select job_id
                    from m_sys.m_po_line_items i -- SC_0341  use MV view, not table to check whole PO, all supplements
                   where poh_id in
                     (select distinct POH_ID
                        from m_sys.m_po_headers
                       where base_poh_id = l_base_poh_id) -- Support center-0341
                  union
                  select uoc.job_id
                  -- Singapore-0035a 31Jan11 from m_sys.MV_PO_OTHER_COSTS UOC
                    from m_sys.M_USED_OTHER_COSTS UOC
                   WHERE uoc.pk_id in
                     (select distinct POH_ID
                        from m_sys.m_po_headers
                       where base_poh_id = l_base_poh_id) -- Support center-0341
                     AND TERM_TYPE = 'PO') i,
                 m_sys.m_jobs j
               where a.account = j.job_number
                 and j.job_id = i.job_id);

          if l_project_count > 1 then
            RAISE_APPLICATION_ERROR(-20000,'ERROR-Multiple acct projects per PO not allowed') -- Support center-0341
            ;
            RETURN FALSE;
          else
            NULL;
          end if;
          -- end support center-0035

          --Account Code on PO-Lines
          select count(*)
            into l_poli_account
            from m_sys.m_po_line_items poli
           where poli.poh_id = p_poh_id
             and nvl(poli.job_id, 0) not in
             (select job_id
                from m_sys.m_jobs
               where proj_id = (select proj_id
                          from m_sys.m_po_headers
                         where poh_id = p_poh_id));

          if l_poli_account > 0 then
            RAISE_APPLICATION_ERROR(-20000,
                        'ERROR-Not all PO-lines have a account-code.');
            RETURN FALSE;
          else
            select count(*)
              into l_jde_deleted_acc
              from m_sys.m_jobs j
             where (field1 like '%DELETED%' or field2 <> 'Y')
               and job_id in (select poli.job_id
                    from m_sys.m_po_line_items poli
                       where poli.poh_id = p_poh_id);

            if l_jde_deleted_acc = 0 then
              NULL;
            else
              select count(*)
            into l_max_poli_count
            from m_po_line_items
               where poh_id = p_poh_id;

              l_jdedel_account := '';
              FOR C3_REC in C3 LOOP
            i                := i + 1;
            l_jdedel_account := c3_rec.job_number;
            IF i > l_max_poli_count THEN
              EXIT;
            END IF;
              END LOOP;
              RAISE_APPLICATION_ERROR(-20000,
                          'ERROR-Account on Line(s) deleted/unchargeable ' ||
                          l_jdedel_account);
              RETURN FALSE;
            end if;
          end if;

          -- Account Code on Other Cost lines
          select count(*)
            into l_poli_account
            from m_sys.m_used_other_costs uoc
           where uoc.pk_id = p_poh_id
             and uoc.term_type = 'PO'
             and nvl(uoc.job_id, 0) not in
             (select job_id
                from m_sys.m_jobs
               where proj_id = (select proj_id
                          from m_sys.m_po_headers
                         where poh_id = p_poh_id));

          if l_poli_account > 0 then
            RAISE_APPLICATION_ERROR(-20000,
                        'ERROR-Not all Other Cost lines have an account-code.');
            RETURN FALSE;
          else
            select count(*)
              into l_jde_deleted_acc
              from m_sys.m_jobs j
             where (field1 like '%DELETED%' or field2 <> 'Y')
               and job_id in (select uoc.job_id
                    from m_sys.m_used_other_costs uoc
                       where uoc.pk_id = p_poh_id
                     and uoc.term_type = 'PO');

            if l_jde_deleted_acc = 0 then
              NULL;
            else
              select count(*)
            into l_max_poli_count
            from m_used_other_costs
               where pk_id = p_poh_id
             and term_type = 'PO';

              l_jdedel_account := '';
              FOR C4_REC in C4 LOOP
            i                := i + 1;
            l_jdedel_account := c4_rec.job_number;
            IF i > l_max_poli_count THEN
              EXIT;
            END IF;
              END LOOP;
              RAISE_APPLICATION_ERROR(-20000,
                          'ERROR-Account on Other Cost  deleted/unchargeable ' ||
                          l_jdedel_account);
              RETURN FALSE;
            end if;
          end if;
          -- end if;

          -- Business Has second thoughts,,  so disable this check for now (PCEZ May22, 2014)
          --Make sure that first two positions of account code are equal, allow just one discipline in a PO.  --SC_0368
          /* select count(*)
            into l_cc_disc_count
            from (select distinct substr(cost_code, 1, 2)
                from (select distinct substr(j.job_number,
                             length(j.job_number) - 4,
                             2) cost_code -- assumes cost_codeis last 7 positions of account
                    from m_sys.m_po_line_items pol, m_sys.m_jobs j
                   where pol.poh_id in
                     (select poh_id
                        from m_sys.m_po_headers
                       where base_poh_id = l_base_poh_id)
                     and j.job_id = pol.job_id));
          if l_cc_disc_count > 1 then
            RAISE_APPLICATION_ERROR(-20000,
                        'ERROR-Cost codes on PO-lines are across disciplines. (Fist 2 pos of CC)');
            RETURN FALSE;
          end if; */

          --A JDE_Vendor_id must be found for the SPM Vendor and Currency_code of the POother
          Begin
            select nvl(sjv.jde_vendor_id, 0)
              into l_jde_vendorid
              from m_abb_sys.spm_jde_vendors sjv,
               m_sys.m_po_headers        poh,
               m_sys.m_units             c
             where sjv.company_id = poh.company_id
               and sjv.currency_code = c.unit_code
               and c.unit_id = poh.currency_id
               and poh.poh_id = p_poh_id
               and nvl(sjv.counterpart, 'CBI') = l_counterpart;
          exception
            when others then
              l_jde_vendorid := 0;
              null;
          end;

          if l_jde_vendorid <> 0 then
            NULL; --PCEZ
          else
            RAISE_APPLICATION_ERROR(-20000,
                        'ERROR-valid JDE VendorID not found or duplicate exists.');
            RETURN FALSE;
          end if;
          --A JDE_Buyer_id must be found for the SPM Buyer on the PO
          if l_counterpart like 'CBI%' then
            -- sc_0368  other parties do not neet buyer_id
            Begin
              select nvl(jde_buyer_id, 0)
            into l_jde_buyerid
            from m_abb_sys.spm_jde_buyers sjb, m_sys.m_po_headers poh
               where sjb.spm_buyer = poh.buyer
             and poh.poh_id = p_poh_id;
            exception
              when no_data_found then
            l_jde_buyerid := 0;
            null;
            end;

            if l_jde_buyerid <> 0 then
              NULL; --PCEZ
            else
              RAISE_APPLICATION_ERROR(-20000,
                          'ERROR-Buyer is not registered with JDE_Buyer_ID.');
              RETURN FALSE;
            end if;

          end if;
          --A Valid Match_Type must be found for the PO
          -- SC_0368  changed from LS and PP to 2W
          if l_order_type <> 'SC' then
            -- PLF-0087 do not test this on sub-contracts, set for INCOTERM, DELPLACE Aand ROUTING METHOD
            Begin
              select nvl(v.attr_value, 'X')
            into l_match_typ
            from m_sys.m_used_values v,
                 m_sys.m_po_headers  poh,
                 m_sys.m_attrs       a
               where v.used_type = 'PO'
             and v.pk_id = poh.poh_id
             and a.attr_id = v.attr_id
             and a.attr_code = 'JDE_MATCH_TYPE'
             and upper(attr_value) in ('2W', '3W')
             and poh.poh_id = p_poh_id;
            exception
              when no_data_found then
            l_match_typ := 'X';
            null;
            end;
            if l_match_typ = 'X' then
              RAISE_APPLICATION_ERROR(-20000,
                          'ERROR- MatchType is not 2W or 3W, requery and change.');
              RETURN FALSE;
            end if;
          end if;

          -- On 2W match we want to see at least 1 progress payment line
          if l_order_type <> 'SC' then
            -- PLF-0087 do not test this on sub-contracts, set for INCOTERM, DELPLACE Aand ROUTING METHOD
            select count(*)
              into l_prog_payments
              from m_sys.m_att_ppes
             where pk_type = 'POH'
               and pk_id = p_poh_id;
            if l_match_typ = '2W' and l_prog_payments < 1 then
              RAISE_APPLICATION_ERROR(-20000,
                          'ERROR- MatchType 2W but no Progress Payment Lines exist.');
              RETURN FALSE;
            end if;

            -- Hague-0509 On 3W match we want to see no PPE lines at all
            select count(*)
              into l_prog_payments
              from m_sys.m_att_ppes
             where pk_type = 'POH'
               and pk_id = p_poh_id;
            if l_match_typ = '3W' and l_prog_payments > 0 then
              RAISE_APPLICATION_ERROR(-20000,
                          'ERROR- MatchType 3W while Progress Payment Lines exist.');
              RETURN FALSE;
            end if;
          end if;

          -- Now test on PO and OC cost value lower than paid amount in JDE, if then block approval
          -- only do for 2way match order ..SC_0537 // CBI137555
          if l_match_typ = '2W' then
              select tot_matl_cost
                 into l_tot_spm_amount      from m_sys.m_po_headers
                  where poh_id = p_poh_id;
              select nvl(number_value,0)
            into l_paid_amount
            from m_sys.m_used_values uv, m_sys.m_attrs at
               where uv.used_type = 'PO'
             and uv.pk_id = p_poh_id
             and at.attr_id = uv.attr_id
             and at.attr_code = 'JDE_PAID_AMOUNT';
            if l_paid_amount > l_tot_spm_amount then
              RAISE_APPLICATION_ERROR(-20000,
                          'ERROR-JDE Paid amount > New SPM PO total amount.');
              RETURN FALSE;
            end if;
          end if;

              -- for now leave the testing of Other Cost out,, not so simple and probably not an issue
              -- discuss with GALT
              -- issue is that we use ROWNUM to create the PO-Line Num,, how to get that done when selecting only
              -- the records that belong to this supplement?  PCEZ  SC_0537  Aug 2017
              /* for c2p in c2 loop -- now test other cost lines
            begin
              select decode(PDFEA,
                    0,
                    (PDAEXP - PDAOPN),
                    (PDFEA - PDFAP)) / 100
                into l_paid_amount
                from cbidta.f4311@jdeprod
               where pddoco = l_doco
                 and pdlnid = 950 * 1000 + c2p.poli_sub_pos;
            exception
              when others then
                -- something not OK, JDE probably not on-line or PO did not Verify, ignore for this test
                l_paid_amount := 0; -- just to prevent error to occur
            end;
            if l_paid_amount <> 0 and c2p.cost_value < l_paid_amount then
              RAISE_APPLICATION_ERROR(-20000,
                          'ERROR-JDE Paid > new other cost amt for  ' ||
                           '950.' ||
                          to_char(rownum));
              RETURN FALSE;
            end if;
              end loop; */

          -- Valid AP_Payment_Terms_code
          Begin
            select nvl(v.attr_value, 'X')
              into l_payment_terms
              from m_sys.m_used_values v,
               m_sys.m_attrs       a,
               m_sys.m_po_headers  poh
             where v.used_type = 'PO'
               and v.pk_id = poh.poh_id
               and a.attr_id = v.attr_id
               and a.attr_code = 'JDE_PAY_TERMS'
               and poh.poh_id = p_poh_id;
          exception
            when no_data_found then
              l_payment_terms := 'X';
              null;
          end;

          if l_payment_terms <> 'X' then
            NULL; --PCEZ
          else
            RAISE_APPLICATION_ERROR(-20000,
                        'ERROR-No Valid Payment Terms defined.');
            RETURN FALSE;
          end if;

          -- Other cost may only be created at the PO_header level
          select count(*)
            into l_other_costs
            from m_sys.m_used_other_costs o, m_sys.m_po_line_items i
           where i.poh_id = p_poh_id
             and o.pk_id = i.poli_id
             and o.term_type = 'PLI';

          if l_other_costs = 0 then
            NULL; --PCEZ
          else
            RAISE_APPLICATION_ERROR(-20000,
                        'ERROR-Other Cost found on PO-lines, not allowed.');
            RETURN FALSE;
          end if;
          -- Other cost may not exceed 999 lines
          select count(*)
            into l_other_costs_count
            from m_sys.m_used_other_costs o, m_sys.m_po_line_items i
           where i.poh_id = p_poh_id
             and o.pk_id = i.poli_id
             and o.term_type = 'PO';

          if l_other_costs_count < 1000 then
            NULL;
          else
            RAISE_APPLICATION_ERROR(-20000,
                        'ERROR-Too many Other Cost lines, max 999.');
            RETURN FALSE;
          end if;

          --SC_0368 PCEZ Apr-2014
          --Test on Supplier updated
          select count(*)
            into l_sup_use_count
            from m_abb_sys.spm_jde_int_F4301z1
           where an8 <> l_jde_vendorid
             and record_id = l_base_poh_id;
          if l_sup_use_count > 0 then
            -- other supplier used before
            RAISE_APPLICATION_ERROR(-20000,
                        'ERROR-Supplier change, update in JDE, then ask Support to Sync hist in SPM.');
            RETURN FALSE;
          end if;

          --Test on Currency updated
          select unit_code
            into l_currency_code
            from m_sys.m_units
           where unit_id = (select currency_id
                      from m_sys.m_po_headers
                     where poh_id = p_poh_id);

          select count(*)
            into l_cur_use_count
            from m_abb_sys.spm_jde_int_F4301z1
           where CRCD <>
             m_pck_po_custom.convert_unit(l_proj_id, l_currency_code)
             and record_id = l_base_poh_id;
          if l_cur_use_count > 0 then
            -- other currency used before
            RAISE_APPLICATION_ERROR(-20000,
                        'ERROR-Currency changed, update in JDE, then ask Support to Sync history in SPM');
            RETURN FALSE;
          end if;
          -- end of SC_0368

          -- SC_0491  test po lines UOM on validity using function convert_unit
          select count(*)
            into l_line_count
            from m_sys.m_po_line_items pol, m_sys.m_units u
           where pol.poh_id = p_poh_id
             and u.unit_id = pol.qty_unit_id
             and m_pck_po_custom.convert_unit(pol.proj_id, u.unit_code) =
             'XXX';
          if l_line_count > 0 then
            RAISE_APPLICATION_ERROR(-20000,
                        'ERROR-Invalid UOM found, contact support -- ' ||
                        p_poh_id);
            RETURN FALSE;
          end if;
          RETURN TRUE; -- all is fine, can continue with PO approval
        else
          m_pck_m.ml('WARNING - interface switch po is N. Po cannot be interfaced. POH_ID...',
                 99);
          RETURN TRUE;
        end if;

          else
        m_pck_m.ml('WARNING - interface JDE Discipline default is set to N. PO cannot be interfaced. POH_ID...',
               99);
        RETURN TRUE;
          end if;
        else
          m_pck_m.ml('WARNING - JDE interface flag is N. Po cannot be interfaced. POH_ID...',
             99);
          RETURN TRUE;
        end if;
        m_pck_m.ml('END - PRE PO APPROVAL CHECKS..POH_ID ', 99);
        /* */
    END IF;
  END agreement_approval;

  /*
  || ****************************************************************************
  ||
  || check_rfa
  || =========
  ||
  || Intended for checking whether setting of checkbox 'Ready for Approval' is
  || allowed.
  ||
  || If a value <> 0 is returned an error message is raised and data
  || will be rolled back.
  ||
  || ****************************************************************************
  */
  FUNCTION check_rfa(p_poh_id  IN m_po_headers.poh_id%TYPE,
                     p_rfa_ind IN m_po_headers.ready_for_approval_ind%TYPE)
    RETURN NUMBER IS
    v_po_number m_po_headers.po_number%TYPE;
    v_base_poh_id m_po_headers.base_poh_id%TYPE;


  BEGIN
    -- 16-Dec-2019 8.2 - 1 Added 7.1 procedures.
    IF m_pck_ppd_defaults.get_value('ZO_MDR_PJ') = 'MERGE' THEN

        SELECT    po_number
        INTO    v_po_number
        FROM    m_sys.m_po_headers
        WHERE    poh_id = p_poh_id;

        mdr_oc_check (p_poh_id);

        IF INSTR(v_po_number,'-ZZ-') > 0 OR INSTR(v_po_number,'-FI-') > 0 THEN
            RETURN 0;
        ELSE
            RETURN mdr_check_agreement (p_poh_id, 'flagged as RfA');
        END IF;


    ELSe
        RETURN 0;
    END IF;

  END; /* check_rfa */

  /*
  || ****************************************************************************
  ||
  || check_print_order
  || =================
  ||
  || Intended for checking whether button 'Print Agreement' is to be activated
  || in screen P.50.07, folder 'Agreement'.
  ||
  || If NULL is returned the button will be disabled; otherwise the return value
  || is regarded as being the name of a report for that screen A.60.71 will then
  || be called when pressing the button.
  ||
  || ****************************************************************************
  */
  FUNCTION check_print_order(p_poh_id IN m_po_headers.poh_id%TYPE)
    RETURN VARCHAR2 IS
    l_READY_FOR_APPROVAL_IND m_po_headers.READY_FOR_APPROVAL_IND%TYPE;
    l_approved_date          m_po_headers.approved_date%TYPE;
  BEGIN
    RETURN NULL;

    /* SELECT poh.READY_FOR_APPROVAL_IND, poh.approved_date INTO l_READY_FOR_APPROVAL_IND,l_approved_date
      FROM M_po_headers poh
      WHERE poh.poh_id = p_poh_id;

    IF l_READY_FOR_APPROVAL_IND = 'N' OR l_approved_date IS NOT NULL THEN

      RETURN NULL;
    END IF;

     RETURN 'P50R11'; */
  END check_print_order; /* check_print_order */

  FUNCTION check_print_up(p_poh_id IN m_po_headers.poh_id%TYPE)
    RETURN VARCHAR2 IS
  BEGIN
    RETURN NULL;
    -- RETURN 'P50R09';
  END;

  /*
  || ****************************************************************************
  ||
  || check_print_draft
  || =================
  ||
  || used in P5007, execute CIP
  ||
  || ****************************************************************************
  */
  FUNCTION check_print_draft(p_poh_id IN m_po_headers.poh_id%TYPE)
    RETURN VARCHAR2 IS
  BEGIN
    RETURN NULL;
    -- RETURN 'P50R09';
  END; /* check_print_order */

  /*
  || ****************************************************************************
  ||
  || check_set_issue_date
  || ====================
  ||
  || Called before setting the issue date by pressing the corresponding button
  || in screen P.50.07.
  ||
  || ****************************************************************************
  */
  FUNCTION check_set_issue_date(p_poh_id IN m_po_headers.poh_id%TYPE)
    RETURN BOOLEAN IS
    v_po_number m_po_headers.po_number%TYPE;
  BEGIN
        IF m_pck_ppd_defaults.get_value('ZO_MDR_PJ') = 'MERGE' THEN
        SELECT    po_number
        INTO    v_po_number
        FROM    m_po_headers
        WHERE    poh_id = p_poh_id;

        mdr_oc_check (p_poh_id);

        IF INSTR(v_po_number,'-ZZ-') > 0 OR INSTR(v_po_number,'-FI-') > 0 THEN
            RETURN TRUE;
        ELSE
            IF mdr_check_agreement (p_poh_id, 'issued') = 1 THEN
              RETURN FALSE;
            ELSE
              RETURN TRUE;
            END IF;
        END IF;
      ELSE
        RETURN TRUE;

      END IF;
  END; /* check_set_issue_date */

  /*
  || ****************************************************************************
  ||
  || post_set_issue_date
  || ===================
  ||
  || Called after setting the issue date by pressing the corresponding button
  || in screen P.50.07.
  ||
  || Attention: This procedure must contain a COMMIT if data are updated.
  ||
  || ****************************************************************************
  */
  PROCEDURE post_set_issue_date(p_poh_id IN m_po_headers.poh_id%TYPE) IS
  BEGIN
    NULL;
  END; /* post_set_issue_date */

  /*
  || ****************************************************************************
  ||
  || check_rev_app_allowed
  || =====================
  ||
  || Intended for checking whether reverse of order approval is allowed.
  ||
  || ****************************************************************************
  */
  FUNCTION check_rev_app_allowed(p_poh_id IN m_po_headers.poh_id%TYPE)
    RETURN BOOLEAN IS
    l_count number;
  BEGIN
    -- HOU_0863
    --  user may only Reverse Approval on PO when the PO was actually nopt issued to JDE.
    /*  GALT meeting decided not to do this. Users still haveto go to Key User  PCEZ Aug 2016

    -- Is PO in the Queue with status 'I' or 'P' ?  If not then do nothing, let user go an reverse
    select count(*)
      into l_count
      from m_abb_sys.spm_jde_int_process_items
     where secondary_id = p_poh_id
       and process_type = 'PO';
    if l_count = 0 then
      -- nothing to do, is not in JDE queue  at all
      RETURN TRUE;
    end if;
    select count(*)
      into l_count
      from m_abb_sys.spm_jde_int_process_items
     where secondary_id = p_poh_id
       and process_type = 'PO'
       and status in ('I', 'P');
    if l_count = 1 then
      RETURN TRUE;
    end if;
    -- what remains is entries in the queue that have been completed,, then do not allow Reverse approval
    RAISE_APPLICATION_ERROR(-20000,
                            'PO already sent to JDE, can not reverse approval');
    RETURN FALSE;   */

    RETURN TRUE; --default

  END; /* check_rev_app_allowed */

  /*
  || ****************************************************************************
  ||
  || post_reverse_approval
  || =====================
  ||
  || Called after the approval of an order has been successfully reversed.
  ||
  || Attention: This procedure must contain a COMMIT if data are updated.
  ||
  || ****************************************************************************
  */
  PROCEDURE post_reverse_approval(p_poh_id IN m_po_headers.poh_id%TYPE) IS
  BEGIN
    NULL;
  END; /* post_reverse_approval */

  /*
  || ****************************************************************************
  ||
  || default_account
  || ===============
  ||
  || Intended for filling PO header with a default account code.
  ||
  || Attention: This procedure should not contain a COMMIT because calling
  ||            procedure performs it. (All database inserts/updates are to be
  ||            performed or none at all.)
  ||
  || ****************************************************************************
  */
  PROCEDURE default_account(p_poh_id IN m_po_headers.poh_id%TYPE) IS
  BEGIN
    NULL;
  END; /* default_account */

  /*
  || ****************************************************************************
  ||
  || execute_cip
  || ===========
  ||
  || Intended for executing the CIP called by button 'Calculate Tax'
  || of screen P.50.07 Maintain Orders
  ||
  || Attention: This procedure should not contain a COMMIT because calling
  ||            procedure performs it. (All database inserts/updates are to be
  ||            performed or none at all.)
  ||
  || ****************************************************************************
  */
  PROCEDURE execute_cip(p_poh_id IN m_po_headers.poh_id%TYPE) IS
  BEGIN
    NULL;
  END; /* execute_cip */

  /*
  || ****************************************************************************
  ||
  || exec_general_cip
  || ================
  ||
  || Intended for executing the CIP called by button 'Execute CIP'
  || of screen P.50.07 Maintain Orders
  ||
  || Attention: This procedure should not contain a COMMIT because calling
  ||            procedure performs it. (All database inserts/updates are to be
  ||            performed or none at all.)
  ||
  || ****************************************************************************
  */
  PROCEDURE exec_general_cip(p_poh_id IN m_po_headers.poh_id%TYPE) IS
  BEGIN
NULL;

  END; /* exec_general_cip */

  /*
  || ****************************************************************************
  ||
  || import_pb_items_cip
  || ===================
  ||
  || Change history:
  ||
  || When          Who             What
  || -----------   -------------   ----------------------------------------------
  || 26-Sep-2008   MKordt          Created (V-ID 3453)
  ||
  || ****************************************************************************
  */
  PROCEDURE import_pb_items_cip(p_poh_id IN m_po_headers.poh_id%TYPE) IS
  BEGIN
    NULL;
  END import_pb_items_cip;

  /*
  || ****************************************************************************
  ||
  || post_approval
  || =============
  ||
  || Called after an order has been successfully approved.
  ||
  || Attention: This procedure must contain a COMMIT if data are updated.
  ||
  || ****************************************************************************
  */
  PROCEDURE post_approval(p_poh_id IN m_po_headers.poh_id%TYPE) IS
    cursor c1 is
      select item_ship_id,
             ish.ident,
             mobile_id, -- PLF0087
             attr_value,
             pol.proj_id -- PLF0087
        from m_po_line_items    pol,
             m_item_ships       ish,
             M_REQ_LI_TO_POLIS  rp,
             M_REQ_TO_BOMS      rb,
             M_attrs            at,
             m_list_pos_values  lpv,
             m_sys.m_mobile_map mm
       where pol.poh_id = p_poh_id
         and ish.poli_id = pol.poli_id
         and rp.poli_id = pol.poli_id
         and rb.rli_id = rp.rli_id
         and lpv.lp_id = rb.lp_id
         and at.attr_id = lpv.attr_id
         and at.attr_code = 'MP_BARCODE'
         and mm.map_id(+) = item_ship_id
       order by item_ship_id;
    l_ident_count number; -- plf0087
    l_ident       number; --plf0087
  BEGIN
    -- 16-Dec-2019 8.2 - 1 Added 7.1 procedures.
    IF m_pck_ppd_defaults.get_value('ZO_MDR_PJ') = 'MERGE' THEN

        -- Commented because manual order logic is changed.
        --assign_manual_order_number (p_poh_id);
        NULL;

    ELSE
        -- Use of this CIP procedure by CB
        -- Peter van Zaalen, Dec 05, 2015
        -- We here check all related item_ships to have a barcode in m_sys.m_mobile_map
        -- That table is related to MobileScan and we look for barcodes as valuein attribite MP_BARCODE
        -- on the PO line related BOM Positions

        /* plf0087 */
        --first delete all entries in m_mobile_map that relate to this POH_ID
        delete from m_sys.m_mobile_map
         where map_id in
           (select item_ship_id
              from m_sys.m_item_ships ish, m_sys.m_po_line_items pol
             where pol.poh_id = p_poh_id
               and ish.poli_id = pol.poli_id);

        for c1r in c1 loop
          begin
        select count(*)
          into l_ident_count
          from (select distinct ident
              from m_item_ships ish, m_mobile_map mm
             where ish.item_ship_id = mm.map_id
               and mm.proj_id = c1r.proj_id
               and mm.code_name = c1r.attr_value);
        if l_ident_count = 1 then
          select ident
            into l_ident
            from m_item_ships ish, m_mobile_map mm
           where ish.item_ship_id = mm.map_id
             and mm.proj_id = c1r.proj_id
             and mm.code_name = c1r.attr_value;
        end if;

        if l_ident_count = 0 or (l_ident_count = 1 and l_ident = c1r.ident) then
          insert into m_sys.m_mobile_map
            (mobile_id, map_id, code_name, proj_id)
          values
            (m_seq_mobile_id.nextval,
             c1r.item_ship_id,
             c1r.attr_value,
             c1r.proj_id);
        end if;
        /* plf0087 */
          exception
        when others then
          NULL;
          end;
        end loop;
        commit; -- as requested by INGR
    END IF;
  END; /* post_approval */

  /*
  || ****************************************************************************
  ||
  || delete_order
  || ============
  ||
  || Intended for the execution of a CIP when deleting an order.
  ||
  || Attention: This procedure should not contain a COMMIT because calling
  ||            procedure performs it. (All database inserts/updates are to be
  ||            performed or none at all.)
  ||
  || ****************************************************************************
  */
  PROCEDURE delete_order(p_poh_id IN m_po_headers.poh_id%TYPE) IS
  v_olives_invoice                VARCHAR2(100);
    v_base_poh_id                    m_po_headers.base_poh_id%TYPE;
    v_poh_id                        m_po_headers.poh_id%TYPE;
    v_po_supp                        m_po_headers.po_supp%TYPE;
    v_inv_po_supp                    m_po_headers.po_supp%TYPE;
    v_rowcount                        NUMBER        DEFAULT 0;

    --Ruby One MDR--
    mdr_fin_sys_   VARCHAR2(255);

    CURSOR Check_Fin_Sys IS
        SELECT  MDR_CUST.MDR_GET_ATTR_VALUE(proj_id, poh_id, 'PO', 'MDR_FIN_SYS')
        FROM m_sys.m_po_headers
        WHERE poh_id = p_poh_id;
    --End One MDR--

  BEGIN

    --Ruby One MDR to filter for ORACLE only--
    OPEN  Check_Fin_Sys;
    FETCH Check_Fin_Sys INTO mdr_fin_sys_;
    CLOSE Check_Fin_Sys;

    -- 16-Dec-2019 8.2 - 1 Added 7.1 procedures.
    IF (m_pck_ppd_defaults.get_value('ZO_MDR_PJ') = 'MERGE') AND ((mdr_fin_sys_ = 'ORACLE') OR (mdr_fin_sys_ = 'OLIVES')) THEN

        BEGIN
            SELECT COUNT(*)
              INTO v_rowcount
              FROM m_sys.m_po_headers
                 WHERE poh_id = p_poh_id;

            IF NVL(v_rowcount, 0) > 0 THEN
              SELECT MAX(base_poh_id), MAX(po_supp)
            INTO v_base_poh_id, v_po_supp
            FROM m_sys.m_po_headers
               WHERE poh_id = p_poh_id;

              BEGIN
            SELECT MAX(olives_instance || '-' || invoice_control), MAX(agreement_id)
              INTO v_olives_invoice, v_poh_id
              FROM interface.invoice_headers
             WHERE base_poh_id = v_base_poh_id
                        AND invoice_status NOT LIKE '%REVERSAL%';  -- to exclude reversal invoices
              EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_olives_invoice := NULL;
              END;

              -- If there is an invoice check if it related to current rev
              IF NVL(v_olives_invoice, '#$%') <> '#$%' THEN
            SELECT MAX(po_supp)
              INTO v_inv_po_supp
              FROM m_sys.m_po_headers h
             WHERE poh_id = v_poh_id;

            IF NVL(v_inv_po_supp, 0) < NVL(v_po_supp, 0) THEN
              v_olives_invoice := NULL;
            END IF;
              END IF;
            END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_olives_invoice := NULL;
            END;

            IF NVL(v_olives_invoice, '#$%') <> '#$%' THEN
                RAISE_APPLICATION_ERROR(-20000, 'MAR-MP028 #1' || v_olives_invoice);
            ELSE
                v_rowcount := 0;

                /*SELECT COUNT(*)
                  INTO v_rowcount
                  FROM interface.mdr_exported_ocs
                 WHERE pk_id = p_poh_id;

                IF NVL(v_rowcount, 0) > 0 THEN
                    -- Set status to deleted so Interface can re-export
                    UPDATE interface.mdr_exported_ocs
                       SET oc_status = 'DELETED'
                     WHERE pk_id = p_poh_id;
                END IF;*/
                v_rowcount := 0;

            /*    SELECT COUNT(*)
                  INTO v_rowcount
                  FROM interface.mdr_exported_agreements
                 WHERE poh_id = p_poh_id;

                IF NVL(v_rowcount, 0) > 0 THEN
                    -- Set status to deleted so Interface can re-export
                    UPDATE interface.mdr_exported_agreements
                       SET order_status = 'DELETED'
                     WHERE poh_id = p_poh_id;
                END IF;*/
            END IF;
    END IF;


  END; /* delete_order */

  /*
  || ****************************************************************************
  ||
  || renumber_pos
  || ============
  ||
  || Intended for renumbering the positions of order line items.
  ||
  || ****************************************************************************
  */
  PROCEDURE renumber_pos(p_poh_id IN m_po_headers.poh_id%TYPE) IS

    l_poli_id  m_po_line_items.poli_id%TYPE;
    l_poli_pos m_po_line_items.poli_pos%TYPE;

    CURSOR all_lines IS
      SELECT poli_id
        FROM m_po_line_items
       WHERE poh_id = p_poh_id
       ORDER BY poli_pos DESC;

  BEGIN

    UPDATE m_po_line_items
       SET poli_pos = -poli_pos
     WHERE poh_id = p_poh_id;

    l_poli_pos := 0;

    OPEN all_lines;
    FETCH all_lines
      INTO l_poli_id;

    WHILE all_lines%FOUND LOOP
      l_poli_pos := l_poli_pos + 1;

      UPDATE m_po_line_items
         SET poli_pos = l_poli_pos
       WHERE poli_id = l_poli_id;

      FETCH all_lines
        INTO l_poli_id;
    END LOOP;

    CLOSE all_lines;

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      IF all_lines%ISOPEN THEN
        CLOSE all_lines;
      END IF;

      /* ERROR in procedure RENUMBER_POS */
      RAISE_APPLICATION_ERROR(-20000,
                              'MAR-25353 #1RENUMBER_POS ' ||
                              SUBSTR(sqlerrm, 12) || ' ' || sqlcode);

  END; /* renumber_pos */

  /*
  || ****************************************************************************
  ||
  || assigned_rlis
  || =============
  ||
  || Intended for getting all requisition line items assigned to an
  || order line item.
  ||
  || With the standard installation a string is generated in which r_code,
  || r_supp, rli_pos and rli_sub_pos of each assigned requisition line item
  || are concatenated.
  ||
  || Example:
  ||
  || The following requisition line items are assigned to an order line item:
  ||
  || ER       Suppl      Pos     Sub
  || ------   -----      ---     ---
  || PIPE-1     0        3       1
  || PIPE-1     1        3       1
  || PIPE-2     0        5       1
  ||
  || The generated string will be:
  ||
  || PIPE-1/0/3/1;PIPE-1/1/3/1;PIPE-2/0/5/1;
  ||
  ||
  || WARNING: When customizing this function you should not enlarge the length
  ||          of field req_name.
  ||
  || ****************************************************************************
  */
  FUNCTION assigned_rlis(p_poli_id IN m_po_line_items.poli_id%TYPE)
    RETURN VARCHAR2 IS

    req_name VARCHAR2(2000) := '';

    /* ---------------------------------------- */
    /* Cursor for finding order for predecessor */
    /* ---------------------------------------- */
    CURSOR rltp_cur IS
      SELECT r.r_code, r.r_supp, rli.rli_pos, rli.rli_sub_pos
        FROM m_reqs r, m_req_line_items rli, m_req_li_to_polis rltp
       WHERE rltp.poli_id = p_poli_id
         AND rli.rli_id = rltp.rli_id
         AND r.r_id = rli.r_id;

    rltp_rec rltp_cur%ROWTYPE;

  BEGIN

    IF NOT rltp_cur%ISOPEN THEN
      OPEN rltp_cur;
    END IF;

    FETCH rltp_cur
      INTO rltp_rec;

    /* -------------------------------------------- */
    /* Loop for all assigned requisition line items */
    /* -------------------------------------------- */
    WHILE rltp_cur%FOUND LOOP
      req_name := req_name || rltp_rec.r_code || '/' || rltp_rec.r_supp || '/' ||
                  rltp_rec.rli_pos || '/' || rltp_rec.rli_sub_pos || ';';
      FETCH rltp_cur
        INTO rltp_rec;
    END LOOP;

    CLOSE rltp_cur;

    RETURN req_name;

  EXCEPTION
    WHEN OTHERS THEN
      IF rltp_cur%ISOPEN THEN
        CLOSE rltp_cur;
      END IF;

      req_name := '';

      RETURN req_name;
  END; /* assigned_rlis */

  /*
  || ****************************************************************************
  ||
  || get_po_status
  || =============
  ||
  || Getting agreement status, including color and priority information.
  ||
  || This is meant to be used for a complete agreement cycle whereas functions
  || get_suppl_status and get_suppl_delv_status are to be used for status
  || information on supplement level.
  ||
  || Change history:
  ||
  || When          Who             What
  || -----------   -------------   ----------------------------------------------
  || 28-Nov-2014   NRiedel         Reduced number of statuses for performance
  ||                               reasons and getting data just once
  ||
  || ****************************************************************************
  */
  FUNCTION get_po_status(p_poh_id IN m_po_headers.poh_id%TYPE)
    RETURN m_type_status IS

    l_status    VARCHAR2(50);
    l_color     VARCHAR2(50);
    l_priority  INTEGER;
    l_po_status m_type_status;

    max_poh_id               m_po_headers.poh_id%TYPE;
    l_approved_date          m_po_headers.approved_date%TYPE;
    l_recv_acknowledge_date  m_po_headers.recv_acknowledge_date%TYPE;
    l_po_issue_date          m_po_headers.po_issue_date%TYPE;
    l_ready_for_approval_ind m_po_headers.ready_for_approval_ind%TYPE;
    l_tech_eval_comp_date    m_po_headers.tech_eval_comp_date%TYPE;
    l_creation_date          m_po_headers.creation_date%TYPE;
    l_proj_id                m_po_headers.proj_id%TYPE;
    l_order_type             m_po_headers.order_type%TYPE;
    l_po_close_date          m_po_headers.po_close_date%TYPE;
    delayed_ind              VARCHAR2(1);

  BEGIN

    l_status   := '';
    l_color    := '';
    l_priority := 99;

    SELECT MAX(poh_id)
      INTO max_poh_id
      FROM m_po_headers
     WHERE base_poh_id = p_poh_id;

    SELECT approved_date,
           recv_acknowledge_date,
           po_issue_date,
           ready_for_approval_ind,
           tech_eval_comp_date,
           creation_date
      INTO l_approved_date,
           l_recv_acknowledge_date,
           l_po_issue_date,
           l_ready_for_approval_ind,
           l_tech_eval_comp_date,
           l_creation_date
      FROM m_po_headers
     WHERE poh_id = max_poh_id;

    SELECT proj_id, order_type, po_close_date
      INTO l_proj_id, l_order_type, l_po_close_date
      FROM m_po_headers
     WHERE poh_id = p_poh_id;

    /* ---------------------------- */
    /* Check if agreement is closed */
    /* ---------------------------- */
    IF l_po_close_date IS NOT NULL THEN
      l_status   := 'Closed';
      l_color    := 'Green';
      l_priority := 9;

      /* ------------------------------------ */
      /* Check if agreement has been received */
      /* ------------------------------------ */
      --   IF l_status IS NULL THEN
      --      IF l_approved_date IS NOT NULL
      --     AND m_pck_receive.get_outstanding(p_poh_id) = 0
      --      THEN
      --         l_status   := 'Received';
      --         l_color    := 'Green';
      --         l_priority := 7;
      --      END IF;
      --   END IF;

      /* ---------------------------------- */
      /* Check if agreement is acknowledged */
      /* ---------------------------------- */
    ELSIF l_recv_acknowledge_date IS NOT NULL THEN
      l_status   := 'Acknowledged';
      l_color    := 'Brown';
      l_priority := 8;

      /* ---------------------------- */
      /* Check if agreement is issued */
      /* ---------------------------- */
    ELSIF l_po_issue_date IS NOT NULL THEN
      l_status   := 'Issued';
      l_color    := 'Purple';
      l_priority := 7;

      /* ------------------------------------ */
      /* Check if agreement has been approved */
      /* ------------------------------------ */
    ELSIF l_approved_date IS NOT NULL THEN
      l_status   := 'Approved';
      l_color    := 'Black';
      l_priority := 6;

      /* ------------------------------------------------------------ */
      /* Check if agreement is pending approval or ready for approval */
      /* ------------------------------------------------------------ */
    ELSIF l_ready_for_approval_ind = 'Y' THEN

      /* --------------------------- */
      /* Approval sequence available */
      /* --------------------------- */
      IF m_pck_aprv_seq.get_seq_defined_ind(l_proj_id,
                                            CASE l_order_type WHEN 'MP' THEN 'PO' ELSE
                                            l_order_type END,
                                            max_poh_id) = 'Y' THEN
        l_status   := 'Pending Approval';
        l_color    := 'Blue';
        l_priority := 5;

        /* ------------------------- */
        /* Without approval sequence */
        /* ------------------------- */
      ELSE
        l_status   := 'Ready for Approval';
        l_color    := 'Plum';
        l_priority := 4;
      END IF;

      /* -------------------------------------------------- */
      /* Check if agreement has passed technical evaluation */
      /* -------------------------------------------------- */
    ELSIF l_tech_eval_comp_date IS NOT NULL THEN
      l_status   := 'TE Passed';
      l_color    := 'Orange';
      l_priority := 3;

      /* ----------------------------- */
      /* Check if agreement is delayed */
      /* ----------------------------- */
    ELSIF SYSDATE - l_creation_date > 14 THEN
      l_status   := 'Delayed';
      l_color    := 'Red';
      l_priority := 1;

      /* ------------------------------------------ */
      /* Status "Open" in case no status set so far */
      /* ------------------------------------------ */
    ELSE
      l_status   := 'Open';
      l_color    := 'Black';
      l_priority := 2;
    END IF;

    l_po_status := m_type_status(l_status, l_color, l_priority);

    RETURN l_po_status;

  END;

  /*
  || ****************************************************************************
  ||
  || get_suppl_status
  || ================
  ||
  || Getting the status of the given agreement supplement.
  ||
  || Change history:
  ||
  || When          Who             What
  || -----------   -------------   ----------------------------------------------
  || 28-Nov-2014   NRiedel         Changed the statuses for performance
  ||                               reasons
  ||
  || ****************************************************************************
  */
  FUNCTION get_suppl_status(p_poh_id IN m_po_headers.poh_id%TYPE)
    RETURN VARCHAR2 IS

    l_proj_id                m_po_headers.proj_id%TYPE;
    l_base_poh_id            m_po_headers.base_poh_id%TYPE;
    l_order_type             m_po_headers.order_type%TYPE;
    l_po_close_date          m_po_headers.po_close_date%TYPE;
    l_approved_date          m_po_headers.approved_date%TYPE;
    l_ready_for_approval_ind m_po_headers.ready_for_approval_ind%TYPE;
    l_recv_acknowledge_date  m_po_headers.recv_acknowledge_date%TYPE;
    l_po_issue_date          m_po_headers.po_issue_date%TYPE;
    l_tech_eval_comp_date    m_po_headers.tech_eval_comp_date%TYPE;
    l_creation_date          m_po_headers.creation_date%TYPE;

    l_status VARCHAR2(255);

  BEGIN

    SELECT proj_id,
           base_poh_id,
           order_type,
           approved_date,
           recv_acknowledge_date,
           po_issue_date,
           po_close_date,
           ready_for_approval_ind,
           tech_eval_comp_date,
           creation_date
      INTO l_proj_id,
           l_base_poh_id,
           l_order_type,
           l_approved_date,
           l_recv_acknowledge_date,
           l_po_issue_date,
           l_po_close_date,
           l_ready_for_approval_ind,
           l_tech_eval_comp_date,
           l_creation_date
      FROM m_po_headers
     WHERE poh_id = p_poh_id;

    IF l_order_type = 'CO' THEN
      SELECT order_type
        INTO l_order_type
        FROM m_po_headers
       WHERE poh_id = l_base_poh_id;
    END IF;

    /* ---------------------------- */
    /* Check if agreement is closed */
    /* ---------------------------- */
    IF l_po_close_date IS NOT NULL THEN
      l_status := 'Closed';

      /* ---------------------------------- */
      /* Check if agreement is acknowledged */
      /* ---------------------------------- */
    ELSIF l_recv_acknowledge_date IS NOT NULL THEN
      l_status := 'Acknowledged';

      /* ---------------------------- */
      /* Check if agreement is issued */
      /* ---------------------------- */
    ELSIF l_po_issue_date IS NOT NULL THEN
      l_status := 'Issued';

      /* ------------------------------------ */
      /* Check if agreement has been approved */
      /* ------------------------------------ */
    ELSIF l_approved_date IS NOT NULL THEN
      l_status := 'Approved';

      /* ------------------------------------------------------------ */
      /* Check if agreement is pending approval or ready for approval */
      /* ------------------------------------------------------------ */
    ELSIF l_ready_for_approval_ind = 'Y' THEN

      /* --------------------------- */
      /* Approval sequence available */
      /* --------------------------- */
      IF m_pck_aprv_seq.get_seq_defined_ind(l_proj_id,
                                            CASE l_order_type WHEN 'MP' THEN 'PO' ELSE
                                            l_order_type END,
                                            p_poh_id) = 'Y' THEN
        l_status := 'Pending Approval';

        /* ------------------------- */
        /* Without approval sequence */
        /* ------------------------- */
      ELSE
        l_status := 'Ready for Approval';
      END IF;

      /* -------------------------------------------------- */
      /* Check if agreement has passed technical evaluation */
      /* -------------------------------------------------- */
    ELSIF l_tech_eval_comp_date IS NOT NULL THEN
      l_status := 'TE Passed';

      /* ----------------------------- */
      /* Check if agreement is delayed */
      /* ----------------------------- */
    ELSIF SYSDATE - l_creation_date > 14 THEN
      l_status := 'Delayed';

      /* ------------------------------------------ */
      /* Status "Open" in case no status set so far */
      /* ------------------------------------------ */
    ELSE
      l_status := 'Open';
    END IF;

    RETURN l_status;

  END;

  /*
  || ****************************************************************************
  ||
  || get_suppl_delv_status
  || =====================
  ||
  || Getting the delivery status of the given agreement supplement.
  ||
  || ****************************************************************************
  */
  FUNCTION get_suppl_delv_status(p_poh_id IN m_po_headers.poh_id%TYPE)
    RETURN VARCHAR2 IS

    l_delv_status VARCHAR2(255);

  BEGIN

    /* --------------- */
    /* Delivery status */
    /* --------------- */
    IF m_pck_mscm.get_received_ind(p_poh_id) = 'Y' THEN
      l_delv_status := 'Received';

    ELSIF m_pck_mscm.get_shipped_ind(p_poh_id) = 'Y' THEN
      l_delv_status := 'Shipped';

    ELSE
      l_delv_status := '-';
    END IF;

    RETURN l_delv_status;

  END;

  /*
  || ****************************************************************************
  ||
  || get_tree_column_label
  || =====================
  ||
  || Getting label for custom column in agreements tree.
  ||
  || ****************************************************************************
  */
  FUNCTION get_tree_column_label RETURN VARCHAR2 IS

  BEGIN

    RETURN NULL;

  END;

  /*
  || ****************************************************************************
  ||
  || get_tree_column_value
  || =====================
  ||
  || Getting value for custom column in agreements tree.
  ||
  || ****************************************************************************
  */
  FUNCTION get_tree_column_value(p_poh_id IN m_po_headers.poh_id%TYPE,
                                 p_nls_id IN m_po_header_nls.nls_id%TYPE)
    RETURN VARCHAR2 IS

  BEGIN

    RETURN NULL;

  END;

  /*
  || ****************************************************************************
  ||
  || check_values
  || ============
  ||
  || ****************************************************************************
  */
  PROCEDURE check_values(p_poh_id  IN m_po_headers.poh_id%TYPE,
                         p_kind_of IN VARCHAR2,
                         p_title   OUT VARCHAR2,
                         p_result  OUT VARCHAR2) IS
  BEGIN
    /* p_title := 'Unequal Values';

    p_result := '111
                 222
                 333'  ;
                 NULL;  */
    NULL;

  END check_values;

  /*
  || ****************************************************************************
  ||
  || update_values
  || =============
  ||
  || ****************************************************************************
  */
  PROCEDURE update_values(p_poh_id IN m_po_headers.poh_id%TYPE,
                          kind_of  IN VARCHAR2) IS
  BEGIN

    NULL;

  END;

  /*
  || ****************************************************************************
  ||
  || check_po_number
  || ===============
  ||
  || ****************************************************************************
  */
  PROCEDURE check_po_number(p_poh_id IN m_po_headers.poh_id%TYPE)

   IS
  BEGIN

    NULL;

    --'MAR-30321' Agreement Number not valid.

  END check_po_number;

  /*
  || ****************************************************************************
  ||
  || create_pack_log
  || ===============
  ||
  || ****************************************************************************
  */
  PROCEDURE CREATE_PACK_LOG(p_poh_id IN M_po_headers.poh_id%TYPE,
                            p_text   IN VARCHAR2,
                            p_action IN VARCHAR2,
                            p_commit IN VARCHAR2 DEFAULT 'Y') IS
  BEGIN
    --  INSERT INTO fw_PACK_LOGS (POH_ID , TEXT , ACTION_DATE, action)
    --    VALUES (p_poh_id, p_text, SYSDATE, p_action )   ;

    IF p_commit = 'Y' THEN
      COMMIT;
    END IF;

  END;

  /* 7.0.5 05Apr2011 */
  /* 7.0.8 08Jun2013 */
  /*
    || ****************************************************************************
    ||
    || get_order_type
    || =============+
    ||
    || Lookup function for order_type to use in a DECODE statement.
    ||
  */
  /* 7.1.3 SC-0417 01Aug2015 No longer need
    FUNCTION get_order_type(p_poh_id IN m_po_headers.poh_id%TYPE)
      RETURN VARCHAR2 IS
      p_return m_po_headers.order_type%TYPE;
    BEGIN
      IF p_poh_id IS NULL THEN
        RETURN(NULL);
      END IF;

      SELECT MAX(P.order_type)
        INTO p_return
        FROM m_sys.m_po_headers p
       WHERE p.poh_id = p_poh_id;

      RETURN(p_return);
    EXCEPTION
      WHEN OTHERS THEN
        RETURN(NULL);
    END get_order_type;
  */

  /*
  || ****************************************************************************
  ||
  || post_apply_prices
  || =================
  || This procedure is called after a price has been applied from a quote summary,
  || order or price agreement to the given order.
  || A commit must be performed to apply the changes to the database.
  || ****************************************************************************
  */
  PROCEDURE post_apply_prices(p_poh_id       IN m_po_headers.poh_id%TYPE,
                              p_qs_id        IN m_quote_summaries.qs_id%TYPE,
                              p_price_poh_id IN m_po_headers.poh_id%TYPE,
                              p_CPRT_ID      IN m_prices.CPRT_ID%TYPE) IS
  BEGIN

    NULL;

  END post_apply_prices;

  FUNCTION convert_unit(p_proj_id IN varchar2, in_unit IN varchar2)
    RETURN varchar2 IS
    out_unit      varchar2(10);
    l_count       number;
    l_counterpart varchar2(10);
    l_unit_group  m_unit_groups.ug_code%type;
  BEGIN
     -- 16-Dec-2019 8.2 - 1 Added 7.1 procedures.
   IF m_pck_ppd_defaults.get_value('ZO_MDR_PJ') <> 'MERGE' THEN
        select nvl(counterpart, 'CBI')
          into l_counterpart
          from m_abb_sys.spm_jde_project_defaults
         where proj_id = p_proj_id;
        select count(*)
          into l_count
          from m_sys.m_interfaces      int,
           m_sys.m_unit_interfaces ui,
           m_sys.m_units           u
         where ui.interface_id = int.interface_id
           and int.interface_code = l_counterpart
           and u.unit_code = in_unit
           and ui.unit_id = u.unit_id;
        if l_count = 1 then
          select unit_interface_code
        into out_unit
        from m_sys.m_interfaces      int,
             m_sys.m_unit_interfaces ui,
             m_sys.m_units           u
           where ui.interface_id = int.interface_id
         and int.interface_code = l_counterpart
         and u.unit_code = in_unit
         and ui.unit_id = u.unit_id;
        else
          -- did not find a conversion using counterpart so try again using the default JDE interface_code
          select unit_interface_code
        into out_unit
        from m_sys.m_interfaces      int,
             m_sys.m_unit_interfaces ui,
             m_sys.m_units           u
           where ui.interface_id = int.interface_id
         and int.interface_code = 'JDE'
         and u.unit_code = in_unit
         and ui.unit_id = u.unit_id;
        end if;

        select nvl(min(UG.ug_code), '-1')
          into l_unit_group
          from m_sys.m_units ut, m_sys.m_unit_groups ug
         where ut.unit_code = in_unit
           and ut.ug_id = ug.ug_id;

        if l_counterpart = 'CBI' and length(out_unit) > 2 and
           l_unit_group <> 'CURRENCY' then
          out_unit := 'XXX';
        end if;
        RETURN out_unit;
    ELSE
        RETURN in_unit;
    END IF;
  EXCEPTION
    WHEN others THEN
      out_unit := in_unit;
      return out_unit;
  END CONVERT_UNIT;

END m_pck_po_custom;
/