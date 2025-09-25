CREATE OR REPLACE PACKAGE BODY M_SYS.M_PCK_CONFIG_CUSTOM IS
/*
|| ****************************************************************************
||
|| Author:      Nicole Riedel
||
||
|| Purpose:     Contains all procedures and functions for configurable screens
||              which can be customized
||
|| Change history:
||
|| When           Who             What
|| -----------    -----------     ---------------------------------------------
|| 10-Dec-2003    NRiedel         Created
|| 19-Jan-2005    NRiedel         Added function get_cycle_approved_ind
||                                (6.1, build 1)
|| 11-Feb-2005    NRiedel         Tuning of get_cycle_approved_ind (6.1, build 2)
|| 30-Jan-2007    NRiedel         Added function get_cip_label (6.2.3, build 1)
|| 30-NOV-2010    THUA            Added funtions TR1.. to TR7.. to use for
||                                 the traffic extract
|| 11-May-2011    THUA            7.0.5 code verification
|| 19-Nov-2012    SD              CR_MA18248. Invoice Handling    (7.0.8, build 1)
|| 02-Jan-2013    THUA            support center-0252:  Tuning queries
|| 08-Jun-2013    THUA            7.0.8 code verification
|| 22-Nov-2017    THUA            CBI120718 Created function get_fabr_ident
|| 16-Dec-2019          Added new procedures from 7.1
|| 08-Jan-2020          Commented INTERFACE Schema objects
|| 20-Oct-2020    RFERDIANTO      INC1049320 Added GET_MDR_FIN_SYS and Added GET_MDR_FIN_SYS_POH
|| 31-Mar-2021    RFERDIANTO      INC110789 Add Functions for Client Req Number and Client PO Number
|| 07-Jan-2022    RFERDIANTO      INC1246611 Add few functions for P2001 screen
|| ****************************************************************************
*/

/*
|| ****************************************************************************
||
|| version
|| =======
||
|| This procedures delivers the version information for building the version
|| view.
||
|| ****************************************************************************
*/
PROCEDURE version
   (version                  OUT VARCHAR2,
    build                    OUT VARCHAR2,
    lmod                     OUT DATE,
    name                     OUT VARCHAR2,
    text                     OUT VARCHAR2
   )
IS
BEGIN
   version := '8.2.0';       /* version for which the package was changed */
   BUILD   := '1';           /* change within one version */
   lmod    := to_date('16.12.19','DD.MM.YY'); /* date of last change */
   NAME    := 'MDR';          /* person that made last change */
   text    := 'added 7.1 procedures';    /* comment about change */
 END version;

/*
|| ****************************************************************************
||
|| get_company_name
|| ================
||
|| Example for a function for suppliers.
||
|| ****************************************************************************
*/
FUNCTION get_company_name
   (p_sup_id                  m_suppliers.sup_id%TYPE)
RETURN m_companies.company_name%TYPE
IS

   l_company_name             m_companies.company_name%TYPE;

BEGIN

   SELECT c.company_name
     INTO l_company_name
     FROM m_companies c,
          m_suppliers sup
    WHERE sup.sup_id = p_sup_id
      AND c.company_id = sup.company_id;

   RETURN l_company_name;

EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;          /* get_company_name */

/*
|| ****************************************************************************
||
|| get_cycle_approved_ind
|| ======================
||
|| Function for returning an indicator whether orders not approved so far
|| exist for the given order cycle.
||
|| Change history:
||
|| When           Who             What
|| -----------    -----------     ---------------------------------------------
|| 11-Feb-2005    NRiedel         Tuning
||
|| ****************************************************************************
*/
FUNCTION get_cycle_approved_ind
   (p_poh_id                  m_po_headers.poh_id%TYPE)
RETURN VARCHAR2
IS

   l_approved_ind             VARCHAR2(1);
   l_cycle_approved_ind       VARCHAR2(8);

BEGIN

   SELECT NVL(MAX('N'),'Y')
     INTO l_approved_ind
     FROM dual
    WHERE EXISTS (SELECT 1
                    FROM m_po_headers poh
                   WHERE m_pck_po_suppl.get_cycle_start(poh.poh_id) = p_poh_id
                     AND poh.approved_date IS NULL
                 );

   IF l_approved_ind = 'Y' THEN
      l_cycle_approved_ind := 'Approved';
   ELSE
      l_cycle_approved_ind := 'Open';
   END IF;

   RETURN l_cycle_approved_ind;

EXCEPTION
   WHEN OTHERS THEN
      RETURN 'Open';
END;          /* get_cycle_approved_ind */

/*
|| ****************************************************************************
||
|| get_cip_label
|| =============
||
|| Function for returning the label for a CIP.
|| ****************************************************************************
*/
FUNCTION get_cip_label
   (p_cip_name                m_config_details.cip_name%TYPE)
RETURN VARCHAR2
IS
   cip_label                  VARCHAR2(50);

BEGIN

    cip_label := NULL;
    IF UPPER(p_cip_name) = 'GET_COMPANY_NAME' THEN
        cip_label := 'Company Name';
    ELSIF UPPER(p_cip_name) = 'GET_FABR_IDENT' THEN
        cip_label := 'Fabr Ident ';
    ELSIF UPPER(p_cip_name) = 'GET_CYCLE_APPROVED_IND' THEN
        cip_label := 'Approval Status';
    /* 16-Dec, McDermott added from 7.1 */
    ELSIF UPPER(p_cip_name) = 'GET_ECL_NUMBER' THEN
        cip_label := 'ECL Number';
    ELSIF UPPER(p_cip_name) = 'GET_ECL_NUMBER_PO' THEN
        cip_label := 'Max ECL Number';
    ELSIF UPPER(p_cip_name) = 'GET_EXP_LIC' THEN
        cip_label := 'Export License';
    ELSIF UPPER(p_cip_name) = 'GET_FLOAT_FAO_ROS' THEN
        cip_label := 'Float';
    ELSIF UPPER(p_cip_name) = 'GET_POH_ATTR_1_VALUE' THEN
        cip_label := 'PO Attribute 1';
    ELSIF UPPER(p_cip_name) = 'MDR_GET_END_USER' THEN
        cip_label := 'End User';
    ELSIF UPPER(p_cip_name) = 'MDR_GET_INCOTERM' THEN
        cip_label := 'Inc Delv Point';
    ELSIF UPPER(p_cip_name) = 'MDR_GET_IRI_DESCRIPTION' THEN
        cip_label := 'Item Description';
    /*****--Commented as part of SPM 8.2 consolidation - CG
    ELSIF UPPER(p_cip_name) = 'MDR_GET_PO_INTERFACE_STATUS' THEN
        cip_label := 'PO Interface Status';    *********/
    ELSIF UPPER(p_cip_name) = 'MDR_GET_LAST_APPROVED_REV' THEN
        cip_label := 'Approved Rev';
    /*****--Commented as part of SPM 8.2 consolidation - CG
    ELSIF UPPER(p_cip_name) = 'MDR_GET_MRR_INTERFACE_STATUS' THEN
        cip_label := 'MRR Interface Status';    *********/
    ELSIF UPPER(p_cip_name) = 'MDR_GET_POLI_DESCRIPTION' THEN
        cip_label := 'Item Description';
    ELSIF UPPER(p_cip_name) = 'MDR_GET_PO_STATUS' THEN
        cip_label := 'PO Status';
    ELSIF UPPER(p_cip_name) = 'MDR_GET_PO_STATUS_DATE' THEN
        cip_label := 'PO Status Date';
    ELSIF UPPER(p_cip_name) = 'MDR_GET_PO_TYPE' THEN
        cip_label := 'PO Type';
    ELSIF UPPER(p_cip_name) = 'MDR_GET_RLI_DESCRIPTION' THEN
        cip_label := 'Item Description';
    ELSIF UPPER(p_cip_name) = 'MDR_GET_SUPPLIER_NAME' THEN
        cip_label := 'PO Supplier';
    ELSIF UPPER(p_cip_name) = 'MDR_GET_RLI_AC_STATUS' THEN
        cip_label := 'A/C Status';
    ELSIF UPPER(p_cip_name) = 'MDR_GET_POLI_AC_STATUS' THEN
        cip_label := 'A/C Status';
    ELSIF UPPER(p_cip_name) = 'MDR_GET_REQ_AC_STATUS' THEN
        cip_label := 'A/C Status';
    ELSIF UPPER(p_cip_name) = 'MDR_GET_PO_AC_STATUS' THEN
        cip_label := 'A/C Status';
    ELSIF UPPER(p_cip_name) = 'GET_EXPEDITOR' THEN
        cip_label := 'Expeditor';
    ELSIF UPPER(p_cip_name) = 'GET_IRC_ISH_PO_QTY' THEN
        cip_label := 'POLI Qty';
   ELSIF UPPER(p_cip_name) = 'GET_MDR_FIN_SYS' THEN
        cip_label := 'MDR Finance System';
   ELSIF UPPER(p_cip_name) = 'GET_MDR_FIN_SYS_POH' THEN
        cip_label := 'MDR Finance System';
    /* end of 16-Dec, McDermott added from 7.1 */
/* 11May2011 7.0.5 THUA */
/* 08Jun2013 7.0.8 THUA */
   ELSIF substr(UPPER(p_cip_name),1,2) = 'TR' THEN
       begin
          SELECT OCN.SHORT_DESC
          into cip_label
          FROM M_SYS.M_OTHER_COSTS OC, M_SYS.M_OTHER_COST_NLS OCN
          WHERE PROJ_ID = user
          AND upper(OC_CODE) LIKE upper(p_cip_name)
          AND OC.OC_ID = OCN.OC_ID
          AND OCN.NLS_ID = mpck_login.current_nls_id;
       end;
/* */
   ELSIF UPPER(p_cip_name) IN ('GET_CLIENT_REQ_NO', 'GET_CLIENT_REQ_NO_FROM_POLI', 'GET_CLIENT_REQ_NO_FROM_ISH') THEN
        cip_label := 'Client Req No';
   ELSIF UPPER(p_cip_name) IN ('GET_CLIENT_POH_NO', 'GET_CLIENT_POH_NO_FROM_RN', 'GET_CLIENT_POH_NO_FROM_MRR') THEN
        cip_label := 'Client PO No';
   ELSIF UPPER(p_cip_name) = 'GET_P2001_ORACLE_SITE_ID' THEN
        cip_label := 'Oracle Supplier Site ID';
   ELSIF UPPER(p_cip_name) = 'GET_P2001_ORACLE_SITE_CODE' THEN
        cip_label := 'Oracle Supplier Site Code';
   ELSIF UPPER(p_cip_name) = 'GET_P2001_LEGACY_POVENDOR' THEN
        cip_label := 'Olives Legacy PO Vendor';
   ELSIF UPPER(p_cip_name) = 'GET_P2001_JDE_VENDOR_ID1' THEN
        cip_label := 'JDE Vendor 1';
   ELSIF UPPER(p_cip_name) = 'GET_P2001_JDE_VENDOR_ID2' THEN
        cip_label := 'JDE Vendor 2';
   ELSIF UPPER(p_cip_name) = 'GET_P2001_JDE_VENDOR_ID3' THEN
        cip_label := 'JDE Vendor 3';
   ELSIF UPPER(p_cip_name) = 'GET_P2001_JDE_VENDOR_ID4' THEN
        cip_label := 'JDE Vendor 4';
   ELSIF UPPER(p_cip_name) = 'GET_P2001_JDE_VENDOR_ID5' THEN
        cip_label := 'JDE Vendor 5';
   END IF;

   RETURN cip_label;

END;          /* get_cip_label */

/*
|| ****************************************************************************
||
|| get_poh_attr_1_value
|| ======================
||
|| Function for returning value of an attribute_1 of POH
||
|| Change history:
||
|| When           Who             What
|| -----------    -----------     ---------------------------------------------
|| 19-Nov-2012    SD          CR_MA18248. Invoice Handling
||
|| ****************************************************************************
*/
FUNCTION get_poh_attr_1_value
   (p_ivc_id                  m_invoices.ivc_id%TYPE)
RETURN VARCHAR2
IS

   l_attr_value              VARCHAR2(255);
BEGIN

   SELECT m_pck_configs.get_attr_value('P5007',poh_id,1,'POH','PO')
   INTO      l_attr_value
   FROM      m_invoices
   WHERE  ivc_id = p_ivc_id;

   RETURN l_attr_value;

EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;          /* get_poh_attr_1_value */

/* 16-Dec, McDermott added from 7.1 */
FUNCTION get_ecl_number
       (p_item_ship_id                  m_sys.m_item_ships.item_ship_id%TYPE)
    RETURN VARCHAR2
    IS
        p_return                         m_sys.m_commodity_codes.attr_char2%TYPE;
        v_attr_set                         NUMBER    :=    0;
    BEGIN
        SELECT MAX(cc.attr_char2)
          INTO p_return
          FROM m_sys.m_item_ships ish, m_sys.m_idents idt, m_sys.m_commodity_codes cc
         WHERE ish.ident = idt.ident
           AND cc.commodity_id = idt.commodity_id
           AND ish.item_ship_id = p_item_ship_id;

        return p_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END; /*get_ecl_number*/


    FUNCTION get_ecl_number_po
       (p_poli_id                       m_sys.m_po_line_items.poli_id%TYPE)
    RETURN VARCHAR2
    IS
        p_return                         m_sys.m_commodity_codes.attr_char2%TYPE;
        v_attr_set                         NUMBER    :=    0;
    BEGIN
        SELECT MAX(cc.attr_char2)
          INTO p_return
          FROM m_sys.m_po_line_items poli, m_sys.m_idents idt, m_sys.m_commodity_codes cc
         WHERE poli.ident = idt.ident
           AND cc.commodity_id = idt.commodity_id
           AND poli.poli_id = p_poli_id;

        return p_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END; /*get_ecl_number_po*/


    FUNCTION get_exp_lic
       (p_item_ship_id                  m_sys.m_item_ships.item_ship_id%TYPE)
    RETURN varchar2
    IS
        p_return                         m_sys.m_po_line_items.export_license_number%TYPE;
    BEGIN
        SELECT MAX(poli.export_license_number)
          INTO p_return
          FROM m_sys.m_item_ships ish, m_sys.m_po_line_items poli
         WHERE poli.poli_id = ish.poli_id
           AND ish.item_ship_id = p_item_ship_id;

        return p_return;

    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END; /*get_exp_lic*/



    FUNCTION get_float_FAO_ROS
        (p_item_ship_id                 m_sys.m_item_ships.item_ship_id%type)
    RETURN NUMBER
    IS
        p_return                         number            :=        null;
        aux_aos                         date            :=        null;
    BEGIN
         -- Check if material has been received
        SELECT ish_actual_on_site_date
          INTO aux_aos
          FROM m_sys.mvp_ish_workload isw
         WHERE isw.item_ship_id = p_item_ship_id;

        IF aux_aos IS NULL THEN
            SELECT ish_req_site_date - ish_forecasted_date_aos
              INTO p_return
              FROM m_sys.mvp_ish_workload isw
             WHERE isw.item_ship_id = p_item_ship_id;
        ELSE
            SELECT ish_req_site_date - ish_actual_on_site_date
              INTO p_return
              FROM m_sys.mvp_ish_workload isw
             WHERE isw.item_ship_id = p_item_ship_id;
        END IF;

        RETURN p_return;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN NULL;
    END; /*get_float_FAO_ROS*/


    -- Get Agreement Supplier
    FUNCTION mdr_get_supplier_name
       (p_poh_id                  m_sys.m_po_headers.poh_id%TYPE)
    RETURN m_sys.m_companies.company_name%TYPE
    IS
        v_sup_id                        m_sys.m_po_headers.sup_id%TYPE;
        v_company_name                    m_sys.m_companies.company_name%TYPE;
    BEGIN
        SELECT NVL(sup_id, 0)
          INTO v_sup_id
          FROM m_sys.m_po_headers
         WHERE poh_id = p_poh_id;

        IF NVL(v_sup_id, 0) > 0 THEN
            v_company_name := get_company_name (v_sup_id);
        END IF;
        RETURN v_company_name;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN 'ERROR: ' || SQLERRM;
    END mdr_get_supplier_name;


    -- Get Last Approved Rev of Agreement
    FUNCTION mdr_get_last_approved_rev
       (p_poh_id                          m_sys.m_po_headers.poh_id%TYPE)
    RETURN m_po_headers.po_supp%TYPE
    IS
        v_base_poh_id                    m_sys.m_po_headers.base_poh_id%TYPE;
        v_po_supp                        m_sys.m_po_headers.po_supp%TYPE;
        v_approved_date                    m_sys.m_po_headers.approved_date%TYPE;
        v_rowcount                        NUMBER;
    BEGIN
        SELECT base_poh_id
          INTO v_base_poh_id
          FROM m_sys.m_po_headers
         WHERE poh_id = p_poh_id;

        SELECT COUNT(*)
          INTO v_rowcount
          FROM m_sys.m_po_headers
         WHERE base_poh_id = v_base_poh_id
           AND approved_date IS NOT NULL;

        IF NVL(v_rowcount, 0) > 0 THEN
            SELECT MAX(po_supp)
              INTO v_po_supp
              FROM m_sys.m_po_headers
             WHERE base_poh_id = v_base_poh_id
               AND approved_date IS NOT NULL;
        END IF;

        RETURN v_po_supp;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN NULL;
    END mdr_get_last_approved_rev;


    -- Get Agreement Status
    FUNCTION mdr_get_po_status
       (p_poh_id                          m_sys.m_po_headers.poh_id%TYPE)
    RETURN VARCHAR2
    IS
        v_po_status                        VARCHAR2(255);
        v_item_with_qty                    NUMBER;
        v_total_price                    m_sys.m_po_total_costs.total_price%TYPE;
        v_base_poh_id                    m_sys.m_po_headers.base_poh_id%TYPE;
        v_latest_poh_id                    m_sys.m_po_headers.base_poh_id%TYPE;
    BEGIN
        SELECT base_poh_id
          INTO v_base_poh_id
          FROM m_sys.m_po_headers
         WHERE poh_id = p_poh_id;

        SELECT MAX(poh_id)
          INTO v_latest_poh_id
          FROM m_sys.m_po_headers
         WHERE base_poh_id = v_base_poh_id;

        SELECT MAX(total_price)
          INTO v_total_price
          FROM m_sys.m_po_total_costs
         WHERE poh_id = v_latest_poh_id;

        SELECT MAX(SIGN(poli_qty))
          INTO v_item_with_qty
          FROM m_sys.m_po_line_items
         WHERE poli_id IN (SELECT MAX(i.poli_id) poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL GROUP BY i.parent_poli_id
                           UNION
                           SELECT i.poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NULL
                           MINUS
                          SELECT DISTINCT i.parent_poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = v_base_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL);

        IF NVL(v_item_with_qty, 0) = 0 AND NVL(v_total_price, 0) = 0 THEN
            v_po_status := 'CANCELLED';
        ELSE
            SELECT NVL2(po_close_date, 'CLOSED', NVL2(po_issue_date, 'ISSUED', NVL2(approved_date, 'APPROVED', NVL2(rfa_date, 'FROZEN', 'CONFIRMED'))))
              INTO v_po_status
              FROM m_sys.m_po_headers
             WHERE poh_id = v_latest_poh_id;
        END IF;

        RETURN v_po_status;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN SUBSTR('ERROR: ' || SQLERRM, 1, 254);
    END mdr_get_po_status;


    -- Get Agreement Status Date
    FUNCTION mdr_get_po_status_date
       (p_poh_id                  m_sys.m_po_headers.poh_id%TYPE)
    RETURN VARCHAR2
    IS
        v_po_status_date            VARCHAR2(255);
        v_base_poh_id                    m_sys.m_po_headers.base_poh_id%TYPE;
        v_latest_poh_id                    m_sys.m_po_headers.base_poh_id%TYPE;
    BEGIN
        SELECT base_poh_id
          INTO v_base_poh_id
          FROM m_sys.m_po_headers
         WHERE poh_id = p_poh_id;

        SELECT MAX(poh_id)
          INTO v_latest_poh_id
          FROM m_sys.m_po_headers
         WHERE base_poh_id = v_base_poh_id;

        SELECT NVL2(po_close_date, po_close_date, NVL2(po_issue_date, po_issue_date, NVL2(approved_date, approved_date, NVL2(rfa_date, rfa_date, lmod))))
          INTO v_po_status_date
          FROM m_sys.m_po_headers
         WHERE poh_id = v_latest_poh_id;

        RETURN v_po_status_date;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN SUBSTR('ERROR: ' || SQLERRM, 1, 254);
    END mdr_get_po_status_date;


    -- Get Agreement Type
    FUNCTION mdr_get_po_type
       (p_poh_id                          m_sys.m_po_headers.poh_id%TYPE)
    RETURN VARCHAR2
    IS
        v_order_type                    VARCHAR2(255);
        v_base_poh_id                    m_sys.m_po_headers.base_poh_id%TYPE;
        v_latest_poh_id                    m_sys.m_po_headers.base_poh_id%TYPE;
    BEGIN
        SELECT base_poh_id
          INTO v_base_poh_id
          FROM m_sys.m_po_headers
         WHERE poh_id = p_poh_id;

        SELECT MAX(poh_id)
          INTO v_latest_poh_id
          FROM m_sys.m_po_headers
         WHERE base_poh_id = v_base_poh_id;

        SELECT order_type
          INTO v_order_type
          FROM m_sys.m_po_headers
         WHERE poh_id = v_latest_poh_id;

        RETURN v_order_type;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN SUBSTR('ERROR: ' || SQLERRM, 1, 254);
    END mdr_get_po_type;


    -- Get Requisition End User
    FUNCTION mdr_get_end_user
       (p_inv_receipt_id         m_sys.m_inv_receipts.inv_receipt_id%TYPE)
    RETURN VARCHAR2
    IS
        v_attr_id                    m_sys.m_attrs.attr_id%TYPE;
       v_rowcount number := 0;
       v_return varchar2(2000) := null;
    BEGIN
        BEGIN
            SELECT attr_id
              INTO v_attr_id
              FROM m_sys.m_attrs
             WHERE attr_code = 'END_USER';
        EXCEPTION
            WHEN OTHERS THEN
                v_attr_id := NULL;
        END;

        IF NVL(v_attr_id, 0) > 0 THEN
            SELECT COUNT(DISTINCT uv.attr_value)
              INTO v_rowcount
              FROM m_sys.m_inv_receipts ir, m_sys.m_item_ships ish, m_sys.m_req_li_to_polis rpos, m_sys.m_used_values uv
             WHERE ir.item_ship_id = ish.item_ship_id (+)
               AND ish.poli_id = rpos.poli_id (+)
               AND rpos.r_id = uv.pk_id (+)
               AND uv.used_type = 'ER'
               AND uv.attr_id = v_attr_id
               AND uv.attr_value IS NOT NULL
               AND ir.inv_receipt_id = p_inv_receipt_id;

            IF NVL(v_rowcount, 0) = 1 then
                SELECT DISTINCT uv.attr_value
                  INTO v_return
                  FROM m_sys.m_inv_receipts ir, m_sys.m_item_ships ish, m_sys.m_req_li_to_polis rpos, m_sys.m_used_values uv
                 WHERE ir.item_ship_id = ish.item_ship_id (+)
                   AND ish.poli_id = rpos.poli_id (+)
                   AND rpos.r_id = uv.pk_id (+)
                   AND uv.used_type = 'ER'
                   AND uv.attr_id = v_attr_id
                   AND uv.attr_value IS NOT NULL
                   AND ir.inv_receipt_id = p_inv_receipt_id;

            ELSIF NVL(v_rowcount, 0) > 1 then
                v_return := 'Multiple';
            END IF;
        END IF;

      RETURN v_return;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN NULL;
    END mdr_get_end_user;


    -- Get Agreement Incoterm
    FUNCTION mdr_get_incoterm
       (p_poh_id                      m_sys.m_po_headers.poh_id%TYPE)
    RETURN VARCHAR2
    IS
        v_attr_id                    m_sys.m_attrs.attr_id%TYPE;
        v_rowcount                     number := 0;
        v_return                     varchar2(2000) := null;
    BEGIN
        BEGIN
            SELECT attr_id
              INTO v_attr_id
              FROM m_sys.m_attrs
             WHERE attr_code = 'DELV_POINT';
        EXCEPTION
            WHEN OTHERS THEN
                v_attr_id := NULL;
        END;

        SELECT COUNT(DISTINCT uv.attr_value)
          INTO v_rowcount
          FROM m_sys.m_used_values uv,
                (SELECT poli_id
                   FROM (SELECT MAX(i.poli_id) poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = p_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL GROUP BY i.parent_poli_id
                         UNION
                         SELECT i.poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = p_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NULL
                         MINUS
                         SELECT DISTINCT i.parent_poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = p_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL)) i
         WHERE uv.pk_id = i.poli_id
           AND uv.used_type = 'POLI'
           AND uv.attr_value IS NOT NULL
           AND uv.attr_id = v_attr_id;

        IF NVL(v_rowcount, 0) = 1 then
            SELECT DISTINCT uv.attr_value
              INTO v_return
              FROM m_sys.m_used_values uv,
                    (SELECT poli_id
                       FROM (SELECT MAX(i.poli_id) poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = p_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL GROUP BY i.parent_poli_id
                             UNION
                             SELECT i.poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = p_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NULL
                             MINUS
                             SELECT DISTINCT i.parent_poli_id FROM m_sys.m_po_line_items i, m_sys.m_po_headers h WHERE h.base_poh_id = p_poh_id AND i.poh_id = h.poh_id AND i.parent_poli_id IS NOT NULL)) i
             WHERE uv.pk_id = i.poli_id
               AND uv.used_type = 'POLI'
               AND uv.attr_value IS NOT NULL
               AND uv.attr_id = v_attr_id;

        ELSIF NVL(v_rowcount, 0) > 1 then
            v_return := 'Multiple';
        END IF;

      RETURN v_return;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN NULL;
    END mdr_get_incoterm;

    /*****--Commented as part of SPM 8.2 consolidation - CG - 08 Jan 2020**
    -- Get Agreement Interface Status
    FUNCTION mdr_get_po_interface_status
       (p_poh_id                      m_sys.m_po_headers.poh_id%TYPE)
    RETURN VARCHAR2
    IS
        v_return                     varchar2(2000) := null;
    BEGIN
        BEGIN
            SELECT INITCAP(record_status) || ' ' || last_update
              INTO v_return
              FROM interface.mdr_exported_agreements
             WHERE poh_id = p_poh_id
               AND poli_id = 0
               AND uoc_id = 0;
        EXCEPTION
            WHEN OTHERS THEN
                v_return := 'Not Exported';
        END;

      RETURN v_return;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN NULL;
    END mdr_get_po_interface_status;
    **********************************************************/
    /*****--Commented as part of SPM 8.2 consolidation - CG - 08 Jan 2020**
    -- Get MRR Interface Status
    FUNCTION mdr_get_mrr_interface_status
       (p_mrr_id                      m_sys.m_matl_recv_rpts.mrr_id%TYPE)
    RETURN VARCHAR2
    IS
        v_return                     varchar2(2000) := null;
    BEGIN
        BEGIN
            SELECT INITCAP(record_status) || ' ' || last_update
              INTO v_return
              FROM interface.mdr_exported_mrrs
             WHERE mrr_id = p_mrr_id
               AND inv_receipt_id = 0
               AND osd_id = 0;
        EXCEPTION
            WHEN OTHERS THEN
                v_return := 'Not Exported';
        END;

      RETURN v_return;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN NULL;
    END mdr_get_mrr_interface_status;
    **********************************************************/


    -- Get Requisition Line Item Description
    FUNCTION mdr_get_rli_description
       (p_rli_id                      m_sys.m_req_line_items.rli_id%TYPE)
    RETURN VARCHAR2
    IS
        v_return                     varchar2(2000) := null;
        v_prefix                     m_sys.m_used_values.attr_value%TYPE := null;
        v_suffix                     m_sys.m_used_values.attr_value%TYPE := null;
        v_replace                     m_sys.m_used_values.attr_value%TYPE := null;
    BEGIN
        SELECT MAX(attr_value)
          INTO v_prefix
          FROM m_sys.m_used_values
         WHERE used_type = 'ERLI'
           AND attr_id = (SELECT attr_id FROM m_sys.m_attrs where attr_code = 'MDR_PREFIX_DESCRIPTION')
           AND attr_value IS NOT NULL
           AND pk_id = p_rli_id;

        SELECT MAX(attr_value)
          INTO v_suffix
          FROM m_sys.m_used_values
         WHERE used_type = 'ERLI'
           AND attr_id = (SELECT attr_id FROM m_sys.m_attrs where attr_code = 'MDR_SUFFIX_DESCRIPTION')
           AND attr_value IS NOT NULL
           AND pk_id = p_rli_id;

        SELECT MAX(attr_value)
          INTO v_replace
          FROM m_sys.m_used_values
         WHERE used_type = 'ERLI'
           AND attr_id = (SELECT attr_id FROM m_sys.m_attrs where attr_code = 'MDR_REPLACE_DESCRIPTION')
           AND attr_value IS NOT NULL
           AND pk_id = p_rli_id;

        IF NVL(v_replace, '#$%') <> '#$%' THEN
            v_return := v_replace;
        ELSE
            SELECT MAX(m_sys.m_pck_std_custom.ident_desc(ident))
              INTO v_return
              FROM m_sys.m_req_line_items
             WHERE rli_id = p_rli_id
               AND ident IS NOT NULL;

            v_return := NVL(v_prefix, '') || NVL(v_return, '') || NVL(v_suffix, '');
        END IF;

        RETURN v_return;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN NULL;
    END mdr_get_rli_description;


    -- Get PO Line Item Description
    FUNCTION mdr_get_poli_description
       (p_poli_id                      m_sys.m_po_line_items.poli_id%TYPE)
    RETURN VARCHAR2
    IS
        v_return                     varchar2(2000) := null;
        v_prefix                     m_sys.m_used_values.attr_value%TYPE := null;
        v_suffix                     m_sys.m_used_values.attr_value%TYPE := null;
        v_replace                     m_sys.m_used_values.attr_value%TYPE := null;
    BEGIN
        SELECT MAX(attr_value)
          INTO v_prefix
          FROM m_sys.m_used_values
         WHERE used_type = 'POLI'
           AND attr_id = (SELECT attr_id FROM m_sys.m_attrs where attr_code = 'MDR_PREFIX_DESCRIPTION')
           AND attr_value IS NOT NULL
           AND pk_id = p_poli_id;

        SELECT MAX(attr_value)
          INTO v_suffix
          FROM m_sys.m_used_values
         WHERE used_type = 'POLI'
           AND attr_id = (SELECT attr_id FROM m_sys.m_attrs where attr_code = 'MDR_SUFFIX_DESCRIPTION')
           AND attr_value IS NOT NULL
           AND pk_id = p_poli_id;

        SELECT MAX(attr_value)
          INTO v_replace
          FROM m_sys.m_used_values
         WHERE used_type = 'POLI'
           AND attr_id = (SELECT attr_id FROM m_sys.m_attrs where attr_code = 'MDR_REPLACE_DESCRIPTION')
           AND attr_value IS NOT NULL
           AND pk_id = p_poli_id;

        IF NVL(v_replace, '#$%') <> '#$%' THEN
            v_return := v_replace;
        ELSE
            SELECT MAX(m_sys.m_pck_std_custom.ident_desc(ident))
              INTO v_return
              FROM m_sys.m_po_line_items
             WHERE poli_id = p_poli_id
               AND ident IS NOT NULL;

            v_return := NVL(v_prefix, '') || NVL(v_return, '') || NVL(v_suffix, '');
        END IF;

        RETURN v_return;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN NULL;
    END mdr_get_poli_description;


    -- Get Item Receipt Item Description
    FUNCTION mdr_get_iri_description
       (p_inv_receipt_id        m_sys.m_inv_receipts.inv_receipt_id%TYPE)
    RETURN VARCHAR2
    IS
       v_rowcount                 NUMBER := 0;
       v_poli_id                m_sys.m_po_line_items.poli_id%TYPE;
       v_return                 VARCHAR2(2000) := null;
    BEGIN
        SELECT MAX(ish.poli_id)
          INTO v_poli_id
          FROM m_sys.m_inv_receipts ir, m_sys.m_item_ships ish
         WHERE ir.item_ship_id = ish.item_ship_id (+)
           AND ir.inv_receipt_id = p_inv_receipt_id;

        IF NVL(v_poli_id, 0) <> 0 THEN
            v_return := mdr_get_poli_description(v_poli_id);
        END IF;

      RETURN v_return;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN NULL;
    END mdr_get_iri_description;


    -- Get A/C Status
    FUNCTION mdr_get_ac_status
       (p_used_type                 m_sys.m_used_values.used_type%TYPE,
        p_pk_id                      m_sys.m_used_values.pk_id%TYPE)
    RETURN VARCHAR2
    IS
        v_return                     VARCHAR2(255);
        v_rowcount                    NUMBER;
        v_entity                     m_sys.m_used_values.attr_value%TYPE;
        v_account_type                m_sys.m_used_values.attr_value%TYPE;
        v_job                         m_sys.m_used_values.attr_value%TYPE;
        v_sub_function                m_sys.m_used_values.attr_value%TYPE;
        v_feature                     m_sys.m_used_values.attr_value%TYPE;
        v_job_number                m_sys.m_jobs.job_number%TYPE;
        v_job_id                    m_sys.m_jobs.job_id%TYPE;
        v_field6                    m_sys.m_jobs.field6%TYPE;
    BEGIN
        SELECT MAX(attr_value)
          INTO v_entity
          FROM m_sys.m_used_values
         WHERE used_type = p_used_type
           AND attr_id = (SELECT attr_id FROM m_sys.m_attrs where attr_code = 'MDR_ENTITY')
           AND attr_value IS NOT NULL
           AND pk_id = p_pk_id;

        SELECT MAX(attr_value)
          INTO v_account_type
          FROM m_sys.m_used_values
         WHERE used_type = p_used_type
           AND attr_id = (SELECT attr_id FROM m_sys.m_attrs where attr_code = 'MDR_ACCOUNT_TYPE')
           AND attr_value IS NOT NULL
           AND pk_id = p_pk_id;

        SELECT MAX(attr_value)
          INTO v_job
          FROM m_sys.m_used_values
         WHERE used_type = p_used_type
           AND attr_id = (SELECT attr_id FROM m_sys.m_attrs where attr_code = 'MDR_JOB')
           AND attr_value IS NOT NULL
           AND pk_id = p_pk_id;

        SELECT MAX(attr_value)
          INTO v_sub_function
          FROM m_sys.m_used_values
         WHERE used_type = p_used_type
           AND attr_id = (SELECT attr_id FROM m_sys.m_attrs where attr_code = 'MDR_SUB_FUNCTION')
           AND attr_value IS NOT NULL
           AND pk_id = p_pk_id;

        SELECT MAX(attr_value)
          INTO v_feature
          FROM m_sys.m_used_values
         WHERE used_type = p_used_type
           AND attr_id = (SELECT attr_id FROM m_sys.m_attrs where attr_code = 'MDR_FEATURE')
           AND attr_value IS NOT NULL
           AND pk_id = p_pk_id;

        IF NVL(v_entity, '#$%') = '#$%' AND NVL(v_account_type, '#$%') = '#$%' AND NVL(v_job, '#$%') = '#$%' AND NVL(v_sub_function, '#$%') = '#$%' AND NVL(v_feature, '#$%') = '#$%' THEN
            v_return := 'NOT DEFINED';
        ELSE
            v_job_number := v_entity || '-' || v_account_type || '-' || v_job || '-' || v_sub_function || '-' || v_feature || '-%';

            SELECT MAX(job_id), MAX(field6), COUNT(*)
              INTO v_job_id, v_field6, v_rowcount
              FROM m_sys.m_jobs
             WHERE job_number LIKE v_job_number;

            IF NVL(v_job_id, 0) <> 0 THEN
                IF v_field6 = 'NO' THEN
                    v_return := 'OPEN';
                ELSE
                    v_return := 'CLOSED';
                END IF;
            ELSE
                v_return := 'INVALID';
            END IF;
        END IF;

        RETURN v_return;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN v_return;
    END mdr_get_ac_status;


    -- Get Requisition A/C Status
    FUNCTION mdr_get_req_ac_status
       (p_r_id                      m_sys.m_reqs.r_id%TYPE)
    RETURN VARCHAR2
    IS
    BEGIN
        RETURN mdr_get_ac_status ('ER', p_r_id);
    END mdr_get_req_ac_status;


    -- Get Requisition Line Item A/C Status
    FUNCTION mdr_get_rli_ac_status
       (p_rli_id                      m_sys.m_req_line_items.rli_id%TYPE)
    RETURN VARCHAR2
    IS
        v_return                     VARCHAR2(255);
        v_r_id                        m_sys.m_reqs.r_id%TYPE;
    BEGIN
        v_return := mdr_get_ac_status ('ERLI', p_rli_id);
        IF NVL(v_return, '#$%') = 'NOT DEFINED' THEN
            SELECT r_id
              INTO v_r_id
              FROM m_sys.m_req_line_items
             WHERE rli_id = p_rli_id;

            v_return := mdr_get_ac_status ('ER', v_r_id);
        END IF;
        RETURN v_return;
    END mdr_get_rli_ac_status;


    -- Get PO A/C Status
    FUNCTION mdr_get_po_ac_status
       (p_poh_id                      m_sys.m_po_headers.poh_id%TYPE)
    RETURN VARCHAR2
    IS
    BEGIN
        RETURN mdr_get_ac_status ('POH', p_poh_id);
    END mdr_get_po_ac_status;


    -- Get PO Line Item A/C Status
    FUNCTION mdr_get_poli_ac_status
       (p_poli_id                      m_sys.m_po_line_items.poli_id%TYPE)
    RETURN VARCHAR2
    IS
        v_return                     VARCHAR2(255);
        v_poh_id                    m_sys.m_po_headers.poh_id%TYPE;
    BEGIN
        v_return := mdr_get_ac_status ('POLI', p_poli_id);
        IF NVL(v_return, '#$%') = 'NOT DEFINED' THEN
            SELECT poh_id
              INTO v_poh_id
              FROM m_sys.m_po_line_items
             WHERE poli_id = p_poli_id;

            v_return := mdr_get_ac_status ('PO', v_poh_id);
        END IF;
        RETURN v_return;
    END mdr_get_poli_ac_status;

/* End of 16-Dec, McDermott added from 7.1 */

/* 11May2011 7.0.5 THUA */
/* 08Jun2013 7.0.8 THUA */
/*
|| ****************************************************************************
||
||  tr1_of
|| ================
||
|| Example for a function for trafic ocean freight
||
|| ****************************************************************************
*/
FUNCTION TR1_OF
   (p_csd_id                  m_cargo_ship_details.csd_id%TYPE)
RETURN m_used_other_costs.cost_value%TYPE
IS

   l_cost_value             m_used_other_costs.cost_value%TYPE;

BEGIN

   SELECT UOC.COST_VALUE
     INTO l_cost_value
   FROM   M_OTHER_COSTS OCS, M_USED_OTHER_COSTS UOC,
-- Support center-0252 Jan13 Thua  M_SYS.MVP_CSD_WORKLOAD CW
          M_CARGO_SHIP_DETAILS CW     -- Support center-0252 Jan13 Thua
   WHERE upper(OCS.OC_CODE) = 'TR1_OF'-- Support center-0252 Jan13 Thua
     AND UOC.OC_ID  = OCS.OC_ID
     AND UOC.TERM_TYPE = 'RN'
     AND UOC.PK_ID = CW.RELN_ID
     AND UOC.PROJ_ID = CW.PROJ_ID     -- Support center-0252 Jan13 Thua
     AND CW.CSD_ID = p_csd_id;


   RETURN l_cost_value;

EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;          /* TR1_OF */

/*
|| ****************************************************************************
||
||  tr2_lf
|| ================
||
|| Example for a function for trafic land freight
||
|| ****************************************************************************
*/
FUNCTION TR2_LF
   (p_csd_id                  m_cargo_ship_details.csd_id%TYPE)
RETURN m_used_other_costs.cost_value%TYPE
IS

   l_cost_value             m_used_other_costs.cost_value%TYPE;

BEGIN

   SELECT UOC.COST_VALUE
     INTO l_cost_value
   FROM   M_OTHER_COSTS OCS, M_USED_OTHER_COSTS UOC,
-- Support center-0252 Jan13 Thua M_SYS.MVP_CSD_WORKLOAD CW
          M_CARGO_SHIP_DETAILS CW      -- Support center-0252 Jan13 Thua
   WHERE upper(OCS.OC_CODE) = 'TR2_LF' -- Support center-0252 Jan13 Thua
     AND UOC.OC_ID  = OCS.OC_ID
     AND UOC.TERM_TYPE = 'RN'
     AND UOC.PK_ID = CW.RELN_ID
     AND UOC.PROJ_ID = CW.PROJ_ID      -- Support center-0252 Jan13 Thua
     AND CW.CSD_ID = p_csd_id;

   RETURN l_cost_value;

EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;          /* TR2_LF */


/*
|| ****************************************************************************
||
||  tr3_af
|| ================
||
|| Example for a function for trafic air freight
||
|| ****************************************************************************
*/
FUNCTION TR3_AF
   (p_csd_id                  m_cargo_ship_details.csd_id%TYPE)
RETURN m_used_other_costs.cost_value%TYPE
IS

   l_cost_value             m_used_other_costs.cost_value%TYPE;

BEGIN

   SELECT UOC.COST_VALUE
     INTO l_cost_value
   FROM   M_OTHER_COSTS OCS, M_USED_OTHER_COSTS UOC,
-- Support center-0252 Jan13 Thua M_SYS.MVP_CSD_WORKLOAD CW
          M_CARGO_SHIP_DETAILS CW         -- Support center-0252 Jan13 Thua
   WHERE upper(OCS.OC_CODE) = 'TR3_AF'    -- Support center-0252 Jan13 Thua
     AND UOC.OC_ID  = OCS.OC_ID
     AND UOC.TERM_TYPE = 'RN'
     AND UOC.PK_ID = CW.RELN_ID
     AND UOC.PROJ_ID = CW.PROJ_ID         -- Support center-0252 Jan13 Thua
     AND CW.CSD_ID = p_csd_id;

   RETURN l_cost_value;

EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;          /* TR3_AF */

/*
|| ****************************************************************************
||
||  tr4_ep
|| ================
||
|| Example for a function for trafic export packing
||
|| ****************************************************************************
*/
FUNCTION TR4_EP
   (p_csd_id                  m_cargo_ship_details.csd_id%TYPE)
RETURN m_used_other_costs.cost_value%TYPE
IS

   l_cost_value             m_used_other_costs.cost_value%TYPE;

BEGIN

   SELECT UOC.COST_VALUE
     INTO l_cost_value
   FROM   M_OTHER_COSTS OCS, M_USED_OTHER_COSTS UOC,
-- Support center-0252 Jan13 Thua M_SYS.MVP_CSD_WORKLOAD CW
          M_CARGO_SHIP_DETAILS CW       -- Support center-0252 Jan13 Thua
   WHERE upper(OCS.OC_CODE) = 'TR4_EP'  -- Support center-0252 Jan13 Thua
     AND UOC.OC_ID  = OCS.OC_ID
     AND UOC.TERM_TYPE = 'RN'
     AND UOC.PK_ID = CW.RELN_ID
     AND UOC.PROJ_ID = CW.PROJ_ID       -- Support center-0252 Jan13 Thua
     AND CW.CSD_ID = p_csd_id;

   RETURN l_cost_value;

EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;          /* TR4_EP*/

/*
|| ****************************************************************************
||
||  tr5_sh
|| ================
||
|| Example for a function for trafic Storage/Handling
||
|| ****************************************************************************
*/
FUNCTION TR5_SH
   (p_csd_id                  m_cargo_ship_details.csd_id%TYPE)
RETURN m_used_other_costs.cost_value%TYPE
IS

   l_cost_value             m_used_other_costs.cost_value%TYPE;

BEGIN

   SELECT UOC.COST_VALUE
     INTO l_cost_value
   FROM   M_OTHER_COSTS OCS, M_USED_OTHER_COSTS UOC,
-- Support center-0252 Jan13 Thua M_SYS.MVP_CSD_WORKLOAD CW
          M_CARGO_SHIP_DETAILS CW       -- Support center-0252 Jan13 Thua
   WHERE upper(OCS.OC_CODE) = 'TR5_SH'  -- Support center-0252 Jan13 Thua
     AND UOC.OC_ID  = OCS.OC_ID
     AND UOC.TERM_TYPE = 'RN'
     AND UOC.PK_ID = CW.RELN_ID
     AND UOC.PROJ_ID = CW.PROJ_ID       -- Support center-0252 Jan13 Thua
     AND CW.CSD_ID = p_csd_id;

   RETURN l_cost_value;

EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;          /* TR5_SH */

/*
|| ****************************************************************************
||
||  tr6_br
|| ================
||
|| Example for a function for trafic brokage
||
|| ****************************************************************************
*/
FUNCTION TR6_BR
   (p_csd_id                  m_cargo_ship_details.csd_id%TYPE)
RETURN m_used_other_costs.cost_value%TYPE
IS

   l_cost_value             m_used_other_costs.cost_value%TYPE;

BEGIN

   SELECT UOC.COST_VALUE
     INTO l_cost_value
   FROM   M_OTHER_COSTS OCS, M_USED_OTHER_COSTS UOC,
-- Support center-0252 Jan13 Thua M_SYS.MVP_CSD_WORKLOAD CW
          M_CARGO_SHIP_DETAILS CW       -- Support center-0252 Jan13 Thua
   WHERE upper(OCS.OC_CODE) = 'TR6_BR'  -- Support center-0252 Jan13 Thua
     AND UOC.OC_ID  = OCS.OC_ID
     AND UOC.TERM_TYPE = 'RN'
     AND UOC.PK_ID = CW.RELN_ID
     AND UOC.PROJ_ID = CW.PROJ_ID       -- Support center-0252 Jan13 Thua
     AND CW.CSD_ID = p_csd_id;

   RETURN l_cost_value;

EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;          /* TR6_BR */


/*
|| ****************************************************************************
||
||  tr7_de
|| ================
||
|| Example for a function for trafic destination
||
|| ****************************************************************************
*/
FUNCTION TR7_DE
   (p_csd_id                  m_cargo_ship_details.csd_id%TYPE)
RETURN m_used_other_costs.cost_value%TYPE
IS

   l_cost_value             m_used_other_costs.cost_value%TYPE;

BEGIN

   SELECT UOC.COST_VALUE
     INTO l_cost_value
   FROM   M_OTHER_COSTS OCS, M_USED_OTHER_COSTS UOC,
-- Support center-0252 Jan13 Thua M_SYS.MVP_CSD_WORKLOAD CW
          M_CARGO_SHIP_DETAILS CW       -- Support center-0252 Jan13 Thua
   WHERE upper(OCS.OC_CODE) = 'TR7_DE'  -- Support center-0252 Jan13 Thua
     AND UOC.OC_ID  = OCS.OC_ID
     AND UOC.TERM_TYPE = 'RN'
     AND UOC.PK_ID = CW.RELN_ID
     AND UOC.PROJ_ID = CW.PROJ_ID       -- Support center-0252 Jan13 Thua
     AND CW.CSD_ID = p_csd_id;

   RETURN l_cost_value;

EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;          /* TR7_DE */
/* */


/*
|| ****************************************************************************
||
|| get_fabr_ident
|| ================
||
|| function to get company ident for Fabrication item
||
|| ****************************************************************************
*/
FUNCTION get_fabr_ident
   (p_poli_id        m_po_line_items.poli_id%TYPE)
RETURN m_ident_companies.ic_code%TYPE
IS
   l_ident               m_idents.ident%type;
   l_ident_code          m_idents.ident_code%type;
   l_ic_code             m_ident_companies.ic_code%type;
   l_seq                 m_ident_companies.seq%type;
   l_company_id          m_companies.company_id%type;

BEGIN
   select i.ident, i.ident_code into l_ident , l_ident_code
   from m_sys.m_po_line_items poli, m_sys.m_idents i
   where poli.poli_id = p_poli_id and poli.ident = i.ident;

   select nvl( (select max(seq) from m_ident_companies
                where ident= l_ident
                and proj_id = m_pck_admin.current_proj_id group by proj_id),
               (select max(seq) from m_ident_companies
                where ident= l_ident  and proj_id = 'GLOBAL' group by proj_id)
             )  into l_seq
   from dual;


   select distinct c.company_id  into l_company_id
      from m_sys.m_ppd_defaults pd ,
            m_sys.m_appl_parm pa  , M_SYS.m_companies c
       where pa.parm_id = pd.parm_id and c.company_code = pd.parm_value
         and ((pd.proj_id = m_pck_admin.current_proj_id )
              or
              ( pd.proj_id =
               (select distinct pg_code
                from m_project_product_disciplines
                where proj_id=m_pck_admin.current_proj_id
                )
                and pd.proj_id = m_pck_admin.current_proj_id
              )

             )
        and pa.parm_code = 'ZO_MAP_FAB';

   select  M_PCK_STD_CUSTOM.GET_C_IDENT (l_ident, l_ident_code, l_company_id)  into l_ic_code from dual;

   if l_ic_code = l_ident_code then
      l_ic_code := null;
   end if;

   RETURN l_ic_code;


EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END;   /* get_fabr_ident */


/*
|| ****************************************************************************
||
|| get_expeditor
|| ======================
||
|| Function for returning expeditor assigned to the agreement.
||
|| Change history:
||
|| When           Who             What
|| -----------    -----------     ---------------------------------------------
|| 06-Jan-2020    McDermott       Added
||
|| ****************************************************************************
*/
FUNCTION get_expeditor
   (p_mrr_id                  m_matl_recv_rpts.mrr_id%TYPE)
RETURN VARCHAR2
IS

   l_expediter        m_sys.m_po_headers.expediter%TYPE;
   l_cycle_approved_ind       VARCHAR2(8);

BEGIN

    SELECT    expediter
    INTO    l_expediter
    FROM    m_sys.m_po_headers poh,
        m_sys.m_matl_recv_rpts mrr
    WHERE    mrr.poh_id = poh.poh_id
    AND    mrr.mrr_id = p_mrr_id;

    RETURN l_expediter;

EXCEPTION
   WHEN OTHERS THEN
      RETURN 'ERROR'||SQLERRM;
END;          /* get_expeditor */


/*
|| ****************************************************************************
||
|| get_irc_ish_po_qty
|| ======================
||
|| Function for returning expeditor assigned to the agreement.
||
|| Change history:
||
|| When           Who             What
|| -----------    -----------     ---------------------------------------------
|| 06-Jan-2020    McDermott       Added
||
|| ****************************************************************************
*/
FUNCTION get_irc_ish_po_qty
   (p_inv_receipt_id                  m_inv_receipts.inv_receipt_id%TYPE)
RETURN NUMBER

IS
    v_poli_qty m_po_line_items.poli_qty%TYPE;
BEGIN

    SELECT    poli.poli_qty
    INTO    v_poli_qty
    FROM    m_sys.m_item_ships ish,
        m_sys.m_inv_receipts irc,
        m_sys.m_po_line_items poli
    WHERE    irc.inv_receipt_id = p_inv_receipt_id
    AND    irc.item_ship_id = ish.item_ship_id
    AND    ish.poli_id = poli.poli_id;

    RETURN    v_poli_qty;
EXCEPTION
WHEN OTHERS THEN
    RETURN -1;
END;


FUNCTION get_mdr_fin_sys
   (p_r_id                  m_reqs.r_id%TYPE)
RETURN VARCHAR2
IS
   mdr_fin_sys_    VARCHAR2(255);

   CURSOR Get_MDR_FIN_SYS IS
      SELECT attr_value
      FROM    m_sys.m_used_values
      WHERE   pk_id = p_r_id
      AND     used_type = 'ER'
      AND     proj_id = (SELECT proj_id FROM m_sys.m_reqs WHERE r_id = p_r_id)
      AND     attr_id = (SELECT MAX(attr_id) FROM m_sys.m_attrs WHERE attr_code='MDR_FIN_SYS');

BEGIN
    OPEN  Get_MDR_FIN_SYS;
    FETCH Get_MDR_FIN_SYS INTO mdr_fin_sys_;
    CLOSE Get_MDR_FIN_SYS;

    IF (mdr_fin_sys_ IS NOT NULL) THEN
       RETURN mdr_fin_sys_;
    ELSE
       RETURN NULL;
    END IF;
END;


FUNCTION get_mdr_fin_sys_poh
   (p_poh_id                  m_po_headers.poh_id%TYPE)
RETURN VARCHAR2
IS
   mdr_fin_sys_    VARCHAR2(255);

   CURSOR Get_MDR_FIN_SYS IS
      SELECT attr_value
      FROM    m_sys.m_used_values
      WHERE   pk_id = p_poh_id
      AND     used_type = 'PO'
      AND     proj_id = (SELECT proj_id FROM m_sys.m_po_headers WHERE poh_id = p_poh_id)
      AND     attr_id = (SELECT MAX(attr_id) FROM m_sys.m_attrs WHERE attr_code='MDR_FIN_SYS');

BEGIN
    OPEN  Get_MDR_FIN_SYS;
    FETCH Get_MDR_FIN_SYS INTO mdr_fin_sys_;
    CLOSE Get_MDR_FIN_SYS;

    IF (mdr_fin_sys_ IS NOT NULL) THEN
       RETURN mdr_fin_sys_;
    ELSE
       RETURN NULL;
    END IF;
END;



FUNCTION GET_CLIENT_REQ_NO
   (p_r_id                  m_reqs.r_id%TYPE)
RETURN VARCHAR2
IS
   attr_value_    VARCHAR2(255);

   CURSOR Get_Attr_Value IS
      SELECT attr_value
      FROM    m_sys.m_used_values
      WHERE   pk_id     = p_r_id
      AND     used_type = 'ER'
      AND     proj_id   = (SELECT proj_id FROM m_sys.m_reqs WHERE r_id = p_r_id)
      AND     attr_id   = (SELECT MIN(attr_id) FROM m_sys.m_attrs WHERE attr_code='CLIENT_REQ_NO');

BEGIN
    OPEN  Get_Attr_Value;
    FETCH Get_Attr_Value INTO attr_value_;
    CLOSE Get_Attr_Value;

    IF (attr_value_ IS NOT NULL) THEN
       RETURN attr_value_;
    ELSE
       RETURN NULL;
    END IF;
END;


FUNCTION GET_CLIENT_POH_NO
   (p_poh_id                  m_po_headers.poh_id%TYPE)
RETURN VARCHAR2
IS
   attr_value_    VARCHAR2(255);

   CURSOR Get_Attr_Value IS
      SELECT attr_value
      FROM    m_sys.m_used_values
      WHERE   pk_id     = p_poh_id
      AND     used_type = 'PO'
      AND     proj_id   = (SELECT proj_id FROM m_sys.m_po_headers WHERE poh_id = p_poh_id)
      AND     attr_id   = (SELECT MIN(attr_id) FROM m_sys.m_attrs WHERE attr_code='CLIENT_PO_NO');

BEGIN
    OPEN  Get_Attr_Value;
    FETCH Get_Attr_Value INTO attr_value_;
    CLOSE Get_Attr_Value;

    IF (attr_value_ IS NOT NULL) THEN
       RETURN attr_value_;
    ELSE
       RETURN NULL;
    END IF;
END;


FUNCTION GET_CLIENT_POH_NO_FROM_RN
   (p_reln_id                  m_release_notes.reln_id%TYPE)
RETURN VARCHAR2
IS
   attr_value_    VARCHAR2(255);

   CURSOR Get_Attr_Value IS
      SELECT attr_value
      FROM    m_sys.m_used_values
      WHERE   pk_id     = (SELECT poh_id FROM m_sys.m_release_notes WHERE reln_id = p_reln_id AND ROWNUM <2)
      AND     used_type = 'PO'
      AND     proj_id   = (SELECT proj_id FROM m_sys.m_release_notes WHERE reln_id = p_reln_id)
      AND     attr_id   = (SELECT MIN(attr_id) FROM m_sys.m_attrs WHERE attr_code='CLIENT_PO_NO');

BEGIN
    OPEN  Get_Attr_Value;
    FETCH Get_Attr_Value INTO attr_value_;
    CLOSE Get_Attr_Value;

    IF (attr_value_ IS NOT NULL) THEN
       RETURN attr_value_;
    ELSE
       RETURN NULL;
    END IF;
END;


FUNCTION GET_CLIENT_POH_NO_FROM_MRR
   (p_mrr_id                  m_matl_recv_rpts.mrr_id%TYPE)
RETURN VARCHAR2
IS
   attr_value_    VARCHAR2(255);

   CURSOR Get_Attr_Value IS
      SELECT attr_value
      FROM    m_sys.m_used_values
      WHERE   pk_id     = (SELECT poh_id FROM m_sys.m_matl_recv_rpts WHERE mrr_id = p_mrr_id AND ROWNUM <2)
      AND     used_type = 'PO'
      AND     proj_id   = (SELECT proj_id FROM m_sys.m_matl_recv_rpts WHERE mrr_id = p_mrr_id)
      AND     attr_id   = (SELECT MIN(attr_id) FROM m_sys.m_attrs WHERE attr_code='CLIENT_PO_NO');

BEGIN
    OPEN  Get_Attr_Value;
    FETCH Get_Attr_Value INTO attr_value_;
    CLOSE Get_Attr_Value;

    IF (attr_value_ IS NOT NULL) THEN
       RETURN attr_value_;
    ELSE
       RETURN NULL;
    END IF;
END;



FUNCTION GET_CLIENT_REQ_NO_FROM_POLI
   (p_poli_id                 m_po_line_items.poli_id%TYPE)
RETURN VARCHAR2
IS
   attr_value_    VARCHAR2(255);

   CURSOR Get_Attr_Value IS
      SELECT attr_value
      FROM    m_sys.m_used_values
      WHERE   pk_id     = (SELECT r_id from m_sys.m_req_li_to_polis where poli_id=p_poli_id AND ROWNUM <2)
      AND     used_type = 'ER'
      AND     proj_id   = (SELECT proj_id FROM m_sys.m_po_line_items WHERE poli_id = p_poli_id)
      AND     attr_id   = (SELECT MIN(attr_id) FROM m_sys.m_attrs WHERE attr_code='CLIENT_REQ_NO');

BEGIN
    OPEN  Get_Attr_Value;
    FETCH Get_Attr_Value INTO attr_value_;
    CLOSE Get_Attr_Value;

    IF (attr_value_ IS NOT NULL) THEN
       RETURN attr_value_;
    ELSE
       RETURN NULL;
    END IF;
END;


FUNCTION GET_CLIENT_REQ_NO_FROM_ISH
   (p_item_ship_id            m_item_ships.item_ship_id%TYPE)
RETURN VARCHAR2
IS
   attr_value_    VARCHAR2(255);

   CURSOR Get_Attr_Value IS
      SELECT attr_value
      FROM    m_sys.m_used_values
      WHERE   pk_id     = (SELECT r_id from m_sys.m_req_li_to_polis a, m_sys.m_item_ships b where a.poli_id=b.poli_id AND b.item_ship_id=p_item_ship_id AND ROWNUM <2)
      AND     used_type = 'ER'
      AND     proj_id   = (SELECT proj_id FROM m_sys.m_item_ships WHERE item_ship_id = p_item_ship_id)
      AND     attr_id   = (SELECT MIN(attr_id) FROM m_sys.m_attrs WHERE attr_code='CLIENT_REQ_NO');

BEGIN
    OPEN  Get_Attr_Value;
    FETCH Get_Attr_Value INTO attr_value_;
    CLOSE Get_Attr_Value;

    IF (attr_value_ IS NOT NULL) THEN
       RETURN attr_value_;
    ELSE
       RETURN NULL;
    END IF;
END;


FUNCTION get_P2001_Oracle_Site_ID
   (p_sup_id                  m_suppliers.sup_id%TYPE)
RETURN VARCHAR2
IS
   oracle_supplier_site_id_  VARCHAR2(255);

   CURSOR Get_Data IS
      SELECT (SELECT attr_value
              FROM m_sys.m_used_values uv
              WHERE uv.used_type = 'COM'
              AND   uv.pk_id     = c.company_id
              AND   attr_id      = (SELECT MIN(attr_id) FROM m_sys.m_attrs WHERE attr_code = 'ORACLE_SUPPLIER_SITE_ID')) oracle_supplier_site_id
      FROM m_sys.m_suppliers s, m_sys.m_companies c
      WHERE s.sup_id     = p_sup_id
      AND   s.company_id = c.company_id;

BEGIN
   OPEN  Get_Data;
   FETCH Get_Data INTO oracle_supplier_site_id_;
   CLOSE Get_Data;

   RETURN oracle_supplier_site_id_;
EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;


FUNCTION get_P2001_Oracle_Site_Code
   (p_sup_id                  m_suppliers.sup_id%TYPE)
RETURN VARCHAR2
IS
   oracle_supplier_site_code_  VARCHAR2(255);

   CURSOR Get_Data IS
      SELECT (SELECT attr_value
              FROM m_sys.m_used_values uv
              WHERE uv.used_type = 'COM'
              AND   uv.pk_id     = c.company_id
              AND   attr_id      = (SELECT MIN(attr_id) FROM m_sys.m_attrs WHERE attr_code = 'ORACLE_SUPPLIER_SITE_CODE')) oracle_supplier_site_code
      FROM m_sys.m_suppliers s, m_sys.m_companies c
      WHERE s.sup_id     = p_sup_id
      AND   s.company_id = c.company_id;

BEGIN
   OPEN  Get_Data;
   FETCH Get_Data INTO oracle_supplier_site_code_;
   CLOSE Get_Data;

   RETURN oracle_supplier_site_code_;
EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;


FUNCTION get_P2001_Legacy_POVendor
   (p_sup_id                  m_suppliers.sup_id%TYPE)
RETURN VARCHAR2
IS
   povendor_  VARCHAR2(255);

   CURSOR Get_Data IS
      SELECT (SELECT attr_value
              FROM m_sys.m_used_values uv
              WHERE uv.used_type = 'SUP'
              AND   uv.pk_id     = p_sup_id
              AND   attr_id      = (SELECT MIN(attr_id) FROM m_sys.m_attrs WHERE attr_code = 'LEGACY_POVENDOR')) oracle_supplier_site_code
      FROM m_sys.m_suppliers s, m_sys.m_companies c
      WHERE s.sup_id     = p_sup_id
      AND   s.company_id = c.company_id;

BEGIN
   OPEN  Get_Data;
   FETCH Get_Data INTO povendor_;
   CLOSE Get_Data;

   RETURN povendor_;
EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;


FUNCTION get_P2001_JDE_Vendor_ID1
   (p_sup_id                  m_suppliers.sup_id%TYPE)
RETURN VARCHAR2
IS
   jde_group_  VARCHAR2(50);

   CURSOR Get_Data IS
      SELECT jde_vendor_id||'|'||currency_code
        FROM (
            SELECT rownum orderseq, jde_vendor_id, currency_code, counterpart
            FROM (
                SELECT jde_vendor_id, currency_code, counterpart, lmod
                FROM m_abb_sys.spm_jde_vendors
                WHERE company_id= (SELECT company_id FROM m_sys.m_suppliers WHERE sup_id = p_sup_id)
                ORDER BY lmod) A
            ORDER BY rownum
        )
        WHERE orderseq = 1;
BEGIN
   OPEN  Get_Data;
   FETCH Get_Data INTO jde_group_;
   CLOSE Get_Data;

   RETURN jde_group_;
EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;

FUNCTION get_P2001_JDE_Vendor_ID2
   (p_sup_id                  m_suppliers.sup_id%TYPE)
RETURN VARCHAR2
IS
   jde_group_  VARCHAR2(50);

   CURSOR Get_Data IS
      SELECT jde_vendor_id||'|'||currency_code
        FROM (
            SELECT rownum orderseq, jde_vendor_id, currency_code, counterpart
            FROM (
                SELECT jde_vendor_id, currency_code, counterpart, lmod
                FROM m_abb_sys.spm_jde_vendors
                WHERE company_id= (SELECT company_id FROM m_sys.m_suppliers WHERE sup_id = p_sup_id)
                ORDER BY lmod) A
            ORDER BY rownum
        )
        WHERE orderseq = 2;
BEGIN
   OPEN  Get_Data;
   FETCH Get_Data INTO jde_group_;
   CLOSE Get_Data;

   RETURN jde_group_;
EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;

FUNCTION get_P2001_JDE_Vendor_ID3
   (p_sup_id                  m_suppliers.sup_id%TYPE)
RETURN VARCHAR2
IS
   jde_group_  VARCHAR2(50);

   CURSOR Get_Data IS
      SELECT jde_vendor_id||'|'||currency_code
        FROM (
            SELECT rownum orderseq, jde_vendor_id, currency_code, counterpart
            FROM (
                SELECT jde_vendor_id, currency_code, counterpart, lmod
                FROM m_abb_sys.spm_jde_vendors
                WHERE company_id= (SELECT company_id FROM m_sys.m_suppliers WHERE sup_id = p_sup_id)
                ORDER BY lmod) A
            ORDER BY rownum
        )
        WHERE orderseq = 3;
BEGIN
   OPEN  Get_Data;
   FETCH Get_Data INTO jde_group_;
   CLOSE Get_Data;

   RETURN jde_group_;
EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;

FUNCTION get_P2001_JDE_Vendor_ID4
   (p_sup_id                  m_suppliers.sup_id%TYPE)
RETURN VARCHAR2
IS
   jde_group_  VARCHAR2(50);

   CURSOR Get_Data IS
      SELECT jde_vendor_id||'|'||currency_code
        FROM (
            SELECT rownum orderseq, jde_vendor_id, currency_code, counterpart
            FROM (
                SELECT jde_vendor_id, currency_code, counterpart, lmod
                FROM m_abb_sys.spm_jde_vendors
                WHERE company_id= (SELECT company_id FROM m_sys.m_suppliers WHERE sup_id = p_sup_id)
                ORDER BY lmod) A
            ORDER BY rownum
        )
        WHERE orderseq = 4;
BEGIN
   OPEN  Get_Data;
   FETCH Get_Data INTO jde_group_;
   CLOSE Get_Data;

   RETURN jde_group_;
EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;

FUNCTION get_P2001_JDE_Vendor_ID5
   (p_sup_id                  m_suppliers.sup_id%TYPE)
RETURN VARCHAR2
IS
   jde_group_  VARCHAR2(50);

   CURSOR Get_Data IS
      SELECT jde_vendor_id||'|'||currency_code
        FROM (
            SELECT rownum orderseq, jde_vendor_id, currency_code, counterpart
            FROM (
                SELECT jde_vendor_id, currency_code, counterpart, lmod
                FROM m_abb_sys.spm_jde_vendors
                WHERE company_id= (SELECT company_id FROM m_sys.m_suppliers WHERE sup_id = p_sup_id)
                ORDER BY lmod) A
            ORDER BY rownum
        )
        WHERE orderseq = 5;
BEGIN
   OPEN  Get_Data;
   FETCH Get_Data INTO jde_group_;
   CLOSE Get_Data;

   RETURN jde_group_;
EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END;


END;
/
