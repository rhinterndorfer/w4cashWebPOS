create or replace package body pack_auth
as

    
    /**
    */
    function custom_authenticate
      (
        p_username in varchar2,
        p_password in varchar2
      )
      return boolean
    is
      l_password        varchar2(100) ;
      l_id              varchar2(100) ;
      l_boolean         boolean;
    begin
      apex_debug.message(p_message => 'Begin custom_authenticate for user ' || p_username, p_level => 4) ;
      -- First, check to see if the user is in the user table and look up their password
      select id
        into l_id
        from people
       where UPPER(name) = UPPER(UTL_URL.unescape(p_username))
        and (apppassword is null
            or apppassword = 'empty:');
      
      
      
      if l_id is not null then
        return true;
      else
        return false;
      end if;
    exception
    when no_data_found then
      return false;
    end custom_authenticate;
    
    
    /**
    */
    procedure post_authenticate(
        p_username in varchar2,
        out_user_id out number,
        out_time_zone out varchar2
    )
    is
      l_id         number;
    begin
      select id
        into l_id
        from people
       where upper(name) = upper(UTL_URL.unescape(p_username));
      out_user_id := l_id;
    end post_authenticate;

end pack_auth;