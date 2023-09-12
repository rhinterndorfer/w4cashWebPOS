create or replace package body pack_webpos
as
    function open_place(
      p_place_id in varchar2,
      p_lockby in varchar2
      )
    return clob
    is
        l_content blob;
        l_clob clob;
        l_varchar VARCHAR2(32767);
        l_start PLS_INTEGER := 1;
        l_buffer PLS_INTEGER := 32767;
        l_lockcnt number;
        l_errm VARCHAR2(32000);
        l_place_name varchar2(1024);
    begin
        BEGIN
            BEGIN
                select name into l_place_name from places where id = p_place_id;
                insert into sharedtickets (id, name, content, lockby)
                values (
                    p_place_id
                    , l_place_name
                    , utl_raw.cast_to_raw('{"m_sId":"'||SYS_GUID()||'","tickettype":0,"m_iTicketId":0,"m_dDate":"'||to_char(sysdate,'dd.mm.yyyy hh24:mi:ss')||'","attributes":{},"m_aLines":[],"m_aLinesSorted":[],"payments":[],"m_info":"'||l_place_name||'"}')
                    , p_lockby
                );
            EXCEPTION WHEN OTHERS THEN
                NULL;
            END;
            
            
            -- lock place
            update sharedtickets
            set lockby = p_lockby
            where 1=1
                and lockby is null
                and id = p_place_id;
            
            -- check lock
            select count(id)
            into l_lockcnt
            from sharedtickets
                where 1=1
                    and lockby = p_lockby
                    and id = p_place_id;
            
            if l_lockcnt = 1
            then             
            
                SELECT content
                into l_content 
                FROM sharedtickets
                where 1=1
                    and id = p_place_id;
                
                IF l_content is null THEN
                    return null;
                ELSE
                    DBMS_LOB.CREATETEMPORARY(l_clob, TRUE);
        
                    FOR i IN 1..CEIL(DBMS_LOB.GETLENGTH(l_content) / l_buffer)
                    LOOP
                        l_varchar := UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SUBSTR(l_content, l_buffer, l_start));
            
                        DBMS_LOB.WRITEAPPEND(l_clob, LENGTH(l_varchar), l_varchar);
                        l_start := l_start + l_buffer;
                    END LOOP;
                    
                    return l_clob;
                END IF;
            else
            
                DBMS_LOB.CREATETEMPORARY(l_clob, TRUE);
                select '{"error": true, "errmsg":"Tisch ist bereits geöffnet von '||lockby||'"}'
                into l_varchar
                FROM sharedtickets
                where 1=1
                    and id = p_place_id;
                    
                DBMS_LOB.WRITEAPPEND(l_clob, LENGTH(l_varchar), l_varchar);
                return l_clob;
            end if;
        EXCEPTION
            WHEN OTHERS THEN
                l_errm := SQLERRM;

                DBMS_LOB.CREATETEMPORARY(l_clob, TRUE);
                select '{"error": true, "errmsg":"'||l_errm||'"}'
                into l_varchar
                FROM dual;
                    
                DBMS_LOB.WRITEAPPEND(l_clob, LENGTH(l_varchar), l_varchar);
                return l_clob;
        END;
        
    end;
    
    function get_ticket_product(
        p_place_id in varchar2,
        p_product_id in varchar2,
        p_amount number,
        p_lockby in varchar2
    )
    return clob
    is
        l_clob clob;
        l_varchar VARCHAR2(32767);
    begin
        DBMS_LOB.CREATETEMPORARY(l_clob, TRUE);
        
        select 
                '{"m_sTicket": "-",'
                || '"m_iLine":-1,'
                || '"multiply":' || to_char(p_amount,'FM9999999990D009999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''') || ','
                || '"multiplyClone":0,"multiplyCloneValid":true,'
                || '"price":' || to_char(p.pricesell,'FM9999999990D009999999999', 'NLS_NUMERIC_CHARACTERS = ''.,''') || ','
                || '"tax":{'
                || '"id":"'||t.id||'",'
                || '"name":"'||t.name||'",'
                || '"taxcategoryid":"'||t.category||'",'
                || '"validfrom":"'||to_char(t.validfrom,'dd.mm.yyyy hh24:mi:ss')||'",'
                || '"rate":' || to_char(t.rate,'FM90D09999', 'NLS_NUMERIC_CHARACTERS = ''.,''') || ','
                || '"cascade":false'
                || '},'
                || '"attributes":{'
                || '"product.sort":"'|| to_char(c.catorder,'FM0000000000') ||'",'
                || '"product.unit":"'|| NVL(p.unit,'x')  ||'",'
                || '"product.taxcategoryid":"'||t.category||'",'
                || '"product.com":"'|| case when NVL(p.iscom,0) = 0 then 'false' else 'true' end ||'",'
                || '"Place":"'|| (select name from places where id = p_place_id) ||'",'
                || '"product.categoryid":"'|| p.category ||'",'
                || '"product.name":"'|| p.name ||'"'
                || '},'
                || '"productid":"'|| p.id ||'",'
                || '"unit": "'|| NVL(p.unit,'x')  ||'"'
                || '}'
        into l_varchar
        FROM products p
            inner join
                taxes t 
                on p.taxcat = t.category
            inner join
                products_cat c
                on p.id = c.product
        where 1=1
            and p.id = p_product_id;
                    
        DBMS_LOB.WRITEAPPEND(l_clob, LENGTH(l_varchar), l_varchar);
        return l_clob;
    end;
    
    procedure save_place(
      p_place_id in varchar2,
      p_lockby in varchar2,
      p_place_content in clob,
      p_place_state in varchar2
      )
    as
        l_blob blob;
        l_lockcnt number;
    begin
        select count(id)
        into l_lockcnt
        from sharedtickets
            where 1=1
                and lockby = p_lockby
                and id = p_place_id;
        if l_lockcnt = 0 then
            raise_application_error(-20000,'Tisch ist nicht gesperrt!');
        end if;
        
        
        l_blob := APEX_WEB_SERVICE.CLOBBASE642BLOB (p_clob => p_place_content);
        if l_blob is not null then
            update sharedtickets
            set content = l_blob
                ,lockby = null
            where id = p_place_id
                and lockby = p_lockby;
        else
            raise_application_error(-20000,'Keine Daten übermittelt!');
        end if;
    end;



end pack_webpos;