create or replace package pack_webpos
as
  function open_place(
      p_place_id in varchar2,
      p_lockby in varchar2
      )
    return clob;

  procedure save_place(
      p_place_id in varchar2,
      p_lockby in varchar2,
      p_place_content in clob,
      p_place_state in varchar2
      ) ;
      
  function get_ticket_product(
        p_place_id in varchar2,
        p_product_id in varchar2,
        p_amount number,
        p_lockby in varchar2
  )
  return clob;

end pack_webpos;