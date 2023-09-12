create or replace package pack_auth
as
  /**
  * Custom authenticate
  *
  * @param p_username  username
  * @param p_password  password
  */
  function custom_authenticate(
      p_username in varchar2,
      p_password in varchar2)
    return boolean;


  /**
  * Post authenticate
  *
  * @param p_username  
  * @param out_user_id  
  * @param out_first_name  
  */
  procedure post_authenticate(
      p_username in varchar2,
      out_user_id out number,
      out_time_zone out varchar2) ;


end pack_auth;